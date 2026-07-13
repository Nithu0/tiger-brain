# Nexus Audit — Stage (8) Backtesting

**Date:** 2026-06-15
**Scope:** Is the backtester robust enough to validate hypotheses?
**Verdict: WEAK** — real, honest, reproducible infrastructure exists, but it only covers ORB, and it validates a *re-implementation* of ORB rather than the live code path. It cannot validate hypotheses for the other ~10 strategies, and even for ORB it does not test what actually trades live.

---

## What exists (the good)

- **Real runner:** `apps/api/src/backtest/runner.ts` (504 lines). Bar-replay simulation of the base ORB path.
- **Route + storage:** `apps/api/src/routes/backtest.ts` — `POST /backtest` creates a row, runs synchronously, stores results JSON.
- **DB table:** `backtests` defined in `packages/shared/src/db/schema.ts:235`. UUID PK, `config`, `assumptions`, `results JSONB`, `warnings TEXT[]`, `status`, `date_from/to`, `timeframe`, `created_at`/`finished_at`.
- **Candle source:** `ohlcv_candles` (schema.ts:826), M1 mid candles. Live DB confirmed **174,087** 1min XAUUSD candles spanning **2025-12-14 → 2026-06-12** (~6 months). Real OANDA data, not synthetic.
- **Backfill:** `scripts/backfill-backtest-m1.mjs` — pulls M1 from OANDA, `ON CONFLICT DO NOTHING` (idempotent, never overwrites a closed candle).
- **CLI variant:** `scripts/backtest-orb.mjs` (695 lines, read-only) — the original; the API runner is described as a "faithful TypeScript port" of it.
- **Live state:** `backtests` table has **6 rows** (5 complete, 1 failed), all `strategy_name='orb'`, created 2026-05-21 → 2026-06-14. So it's actually being run, not dead code.

---

## 1. COVERAGE — re-implementation, ORB-only

**Re-implementation, NOT shared code.** The runner's own header is honest about it (runner.ts:30-32):

> "this runner validates a faithful *re-implementation* of the ORB rules, not the live `orb-manager.ts` code path. A Phase-1 refactor to share a pure core is tracked separately and intentionally NOT done here."

Live ORB is a multi-file state machine: `orb-manager.ts`, `range-detector.ts`, `state-machine.ts`, `momentum-filter.ts`, `pre-move-filter.ts`. The backtester ports only the base breakout+range+walk-exit. Header explicitly excludes (runner.ts:5-7): scalp_A/scalp_C, HTF filter, vol-expansion pre-session filter, and (implicitly) the momentum-filter, pre-move-filter, and all firm-level entry gates (Trinn A / FASE 5, daily-trade-cap, regime gates, sizing modifiers). **So the backtest's ORB ≠ the live ORB.** A passing backtest does not mean the live strategy behaves the same way, and vice-versa.

**ORB-only.** `meta.strategy` is hardcoded to `"orb"` (runner.ts:494). There is no dispatch on `strategy_name` — whatever name you POST, it runs ORB logic. All 6 live rows are `orb`. The other firm strategies (mean-reversion, vol-expansion, session-breakout, breakout-continuation, scalp-overlap, FVG, trend-following, reverse-at-sl) **cannot be backtested at all.** This is the single biggest gap: most of the firm has zero historical validation path.

---

## 2. LOOKAHEAD BIAS — mostly clean, one intrabar caveat

Walked the replay loop (runner.ts:255-376):

- **Formation range** = high/low over the 30-min formation window only (lines 265-272). Computed from past bars. OK.
- **Breakout scan** iterates `watchCandles` forward, breaks on first `close > high` / `close < low` (lines 282-294). Close-based, no future peeking. OK.
- **Entry** is on the breakout bar's close (line 302-303). OK.
- **Exit walk starts at `breakoutIdx + 1`** (line 316) — does NOT use the breakout bar itself for SL/TP fills, so **no same-bar entry+exit lookahead.** Good — this is the most common backtest sin and it's avoided.
- Indicators are not computed over the full series; range is windowed. No global-series leakage.

**The one real caveat — intrabar resolution / SL-before-TP:** on each exit bar, SL is checked before TP unconditionally (long: lines 318-331; short: 332-346). If a single bar straddles both levels (low ≤ SL AND high ≥ TP), it always books **SL_HIT**. At 5m/15m resample this is a meaningful fraction of bars. This is *pessimistic* (conservative — counts the loss), so it's the honest direction of error, not optimistic lookahead. But it is an intrabar-resolution limitation: the truth (did SL or TP hit first?) is unknowable from OHLC alone and the runner doesn't drop to M1 to resolve it even though M1 is available. Verdict: no optimistic lookahead, but intrabar fills are approximated, biased toward losses.

---

## 3. COSTS — spread modeled, slippage not

- **Spread:** modeled. `spreadUsd` default **0.3** USD, applied to entry (worse fill): long `+spread`, short `-spread` (runner.ts:302-303, DEFAULT_PARAMS line 67). Configurable via `config.spreadUsd`.
- **Slippage:** NOT modeled as a separate term. The `assumptions` blob labels it `slippageModel: "fixed-spread-usd"` (backtest.ts:316) — i.e. spread doubles as the only cost. No SL/TP slippage on exit (exits fill exactly at slPrice/tpPrice, lines 319-345). For gold, 0.3 USD fixed spread is plausible for calm conditions but understates news/rollover spread widening and exit slippage. Costs are present but optimistic on the exit side.

---

## 4. REPRODUCIBILITY + VERSIONING — strong

- **Deterministic:** same inputs → same outputs. No RNG anywhere; pure function of (candles, params). Candle source is append-only/idempotent. Re-running an identical window reproduces the result.
- **History preserved:** every `POST /backtest` INSERTs a **new UUID row** (backtest.ts:303-319). Nothing is overwritten — results, config, assumptions, warnings, date range, timeframe all stored per run. The 6 live rows show distinct windows/timeframes retained side by side. This satisfies "store results without overwriting history."
- **Assumptions logged** per row (fillModel, slippageModel, spreadModel, notes) — good provenance hygiene.
- **Config logged** per row so you can see what params produced a result.
- Caveat: there is no explicit `strategy_version` / git-SHA column — versioning is by config + date, not by code version. Since the logic is re-implemented and rarely changes, low risk today, but a code change to `runner.ts` would silently change results of identical configs with no version trail.

---

## 5. Can it answer "does v2 beat v1 over the same 90 days"?

**Partial yes — but only for ORB param variants, not for code/strategy versions.**

- You CAN run two configs (e.g. `tpR=2` vs `tpR=3`, or different `rangeMin/Max`) over the **same** `date_from/date_to` and compare the stored `summary` (winRate, totalR, avgR, maxDrawdown). Same period for both is enforced by you passing identical dates; the runner does not couple period to version, so a fair same-period A/B is possible. The 15m rows over 2026-04-30→2026-05-30 etc. show this is in practice being used for window/timeframe comparison.
- You CANNOT compare "ORB v2 logic vs v1 logic" because there's no version dimension and only one logic path. And you cannot compare two *different strategies* (all rows are ORB).
- You CANNOT validate that any backtested edge transfers to live, because the backtested ORB omits the live gates/filters.

So: yes for ORB hyperparameter sweeps over a fixed window; no for strategy-vs-strategy or live-fidelity validation.

---

## Bottom line

Not a broken backtester — it avoids the classic optimistic-lookahead trap, models spread, is deterministic, and stores immutable per-run history with logged assumptions. That's better than most retail setups and the honesty in the code comments is a genuine positive.

But as a **hypothesis-validation engine for a learning system, it is WEAK**:
1. Covers **1 of ~11 strategies** (ORB). The firm's learning loop has no historical validation path for the rest.
2. Even ORB is a **re-implementation** missing the live filters/gates → backtest results do not predict live behaviour. The page's own trust-warning admits "No backtesting against historical data yet" for live trades, and the `assumptions` warn paper≠live.
3. Exit fills are intrabar-approximated (SL-before-TP) and exit slippage is unmodeled.

For the firm to claim it "learns," it needs (a) a shared pure-core so backtest == live, and (b) per-strategy backtest dispatch. Until then, backtesting can tune ORB knobs but cannot validate the firm's hypotheses in general.

### Evidence index
- `apps/api/src/backtest/runner.ts` — runner; re-impl caveat (L30-32), exit loop SL-before-TP (L316-347), spread (L302-303), hardcoded strategy "orb" (L494).
- `apps/api/src/routes/backtest.ts` — POST inserts new UUID row (L303-340), assumptions blob (L313-318), trust warnings (L278-291).
- `packages/shared/src/db/schema.ts:235` — `backtests` DDL; `:826` — `ohlcv_candles` DDL.
- `scripts/backfill-backtest-m1.mjs` — idempotent M1 backfill.
- `scripts/backtest-orb.mjs` — original CLI the runner is ported from.
- Live DB: 6 backtests rows (all orb, 5 complete/1 failed); 174,087 M1 candles 2025-12-14→2026-06-12.
