# LANE 2 — VERIFY backtest Phase 0 (commit 37e3da8)

Date: 2026-06-04
Scope: READ-ONLY audit. ORB replay runner repoint to `ohlcv_candles` + M1 backfill script.
Files: `apps/api/src/backtest/runner.ts`, `scripts/backfill-backtest-m1.mjs`, `packages/shared/src/db/schema.ts`, `apps/worker/src/firm/raw-data-persistence.ts`, `apps/worker/src/firm/orb/orb-manager.ts` + `config.ts`.

## VERDICT

**Plumbing is correct. The science is not yet trustworthy.**

(a) Column mapping — CORRECT. (b) Backfill SQL — CORRECT, but it CANNOT RUN from this box (firewall). (c) ORB divergence — LARGE; the backtest does NOT reflect live behaviour and will overstate trade count / mislead on edge. (d) Live worker persists ONLY 15min — table has ZERO 1min rows, so every backtest throws until backfill lands.

Net: Phase 0 fixed the "throws on a nonexistent table" bug and replaced it with a clean named-error empty path. But the table is empty for the runner's default timeframe, the backfill can't be run locally, and the ported ORB logic diverges materially from live. Do not present any number this produces as "live ORB edge".

---

## (a) Column / DDL match — PASS

DDL (`schema.ts:826-837`): `symbol, timeframe, candle_time, open, high, low, close, volume, recorded_at`; PK `(symbol, timeframe, candle_time)`.

- Runner SELECT (`runner.ts:160-167`): `candle_time, open, high, low, close` WHERE `symbol=$1 AND timeframe=$2 AND candle_time BETWEEN`. All columns exist; `parseFloat` on NUMERIC text is correct (pg returns NUMERIC as string). No mismatch.
- Default symbol `XAUUSD` (`runner.ts:48`) == DDL default. Default source timeframe `1min` (`runner.ts:49`).
- No silent-empty risk from a column typo. The only empty-results risk is data absence (see d) and the timeframe-string value (see c-minor).

## (b) backfill-backtest-m1.mjs — LOGIC PASS, EXECUTION BLOCKED

INSERT (`backfill:154-156`) targets the exact 8 columns + the exact 3-col conflict target. `symbol`/`timeframe` default to `XAUUSD`/`1min` — consistent with what the runner reads by default. OANDA `mid` OHLC → open/high/low/close, `complete`-only filter, `::timestamptz` with explicit ISO. Idempotent via `ON CONFLICT DO NOTHING`. `--dry-run` skips the pool entirely. This is sound.

Pagination: cursor = last bar time + 1s, stops on `batch.length < 5000`, empty batch, cursor past endTime, or 500-page safety. Correct for OANDA's 5000-count cap. Minor: the `from`-only request (no `to`) means OANDA returns up-to-5000 bars forward from cursor and the loop post-filters `t > endTime` — fine, just slightly wasteful on the final page.

BLOCKER (infra): the script connects with `new Pool({ connectionString: DATABASE_URL })` to Postgres directly. Per `pull-nexus-data.sh` header, **this network firewalls 5432/58688 + SSH:22; only HTTPS/443 to the Railway API is allowed.** So the backfill as written CANNOT run from the operator's local box. It must run somewhere with DB reach (Railway shell / one-off Railway job / a box on the allowed network). There is currently NO HTTP ingest path for M1 candles.

Minor bugs (non-blocking):
- `backfill:122-126` — if a page returns >0 bars but they were ALL filtered (`t > endTime`), `added=0` and the progress line is skipped, but the loop still advances cursor correctly; harmless.
- No explicit gap/weekend reporting — OANDA simply returns no bars over the weekend; fine, but the operator gets no "N expected vs M fetched" sanity number.

## (c) ORB divergence: runner re-impl vs live orb-manager.ts — LARGE, backtest will lie

The runner is a port of `scripts/backtest-orb.mjs` (base ORB only), NOT a call into the live path. Concrete divergences (runner = `runner.ts:simulateSession`, live = `orb-manager.ts` + `config.ts` + `state-machine.ts`):

1. **Retest requirement.** Live `ORB_CONFIG.requireRetest` defaults TRUE (`config.ts:52`); live only fires on retest unless disabled, and `entryType` reflects break vs retest. Runner enters on the FIRST close beyond the range (`runner.ts:282-294`), pure break, no retest concept. → runner takes trades live would skip, and at a different price.

2. **Momentum filter.** Live requires a momentum/body-ratio confirmation (`ORB_MIN_BODY_RATIO` 0.6, `state-machine.ts:185 checkMomentumFilter`, criterion `momentum_strong ≥ 60`). Runner has none.

3. **Pre-move exhaustion + ATR expansion.** Live gates on `preMoveExhausted` (`ORB_PRE_MOVE_MAX_PCT`) and `checkAtrExpansion` (`ORB_ATR_EXPANSION_FACTOR`). Runner has neither.

4. **Trend filter.** Live rejects long-in-bearish / short-in-bullish vs `xauusd.analysis.technical.direction` (`orb-manager.ts:87-96`). Runner has no structure filter at all.

5. **Fit-score hard gate.** Live rejects `fitScore < 40` (`orb-manager.ts:100`) and computes a 5-criteria confidence. Runner trades every qualifying breakout.

6. **SL mode.** Live default `slMode="opposite"` (range edge) — matches runner's `slPrice = low/high`. BUT live also supports `midpoint` (`config.ts:50`, `orb-manager.ts:276-283`); if prod runs midpoint, the runner's SL/risk/R are simply wrong. Runner hardcodes opposite-side only.

7. **TP.** Live emits TP1/TP2/TP3 at 1R/2R/3R with multi-level position management. Runner models a single TP at `tpR` (default 2R) and one all-or-nothing exit. Different P&L distribution entirely.

8. **Daily cap.** Live caps at `maxTradesPerDay=5` and marks TRADED (no re-entry until explicit stop-out re-arm, `orb-manager.ts:166-176`). Runner takes at most ONE trade per session per day (first breakout only) — different cap semantics; on choppy days live can re-enter on stop-out, runner never does.

9. **Intrabar SL/TP ambiguity.** Runner walks resampled (15min default) candles and checks SL before TP within the same bar (`runner.ts:316-347`). On a bar that touched both, it always assigns SL first → pessimistic but arbitrary; live execution is tick-driven. The coarser the resample, the worse this bias.

**Quantified risk:** runner has effectively ZERO of live's entry gates (retest, momentum, pre-move, ATR, trend, fit≥40). It will fire far MORE trades than live and at break (not retest) prices, with a single 2R TP vs live's 3-level management. Any winrate/expectancy it reports is for a *different, looser strategy*. Useful as a range-mechanics sanity check; NOT as a proxy for live ORB edge. The commit's own caveat is honest but understates how many gates are missing.

Minor (c): live `confirmationTf` default is `5m` (`config.ts:46`); backtest default resample is `15m` (`backtest.ts:306`). Even the bar granularity the breakout is detected on differs.

## (d) Does live persist 1min? NO — only 15min

`raw-data-persistence.ts:471`: `const tf = "15min";` — `persistCandles` fetches and UPSERTs ONLY 15min bars. Module docstring (`:15`) confirms "closed 15-min bars". There is no 1min writer anywhere in the worker.

Consequences:
- Runner default `BACKTEST_CANDLE_TIMEFRAME="1min"` → query returns 0 rows → `runBacktest` throws the named-backfill error (`runner.ts:427-433`). So out-of-the-box, EVERY backtest fails until M1 is backfilled.
- The 15min bars that DO exist are written as timeframe `"15min"`; the backtest creation route defaults the row `timeframe` to `"15m"` (`backtest.ts:306`), but that string is the resample TARGET (parsed to 15 min), not the source filter — so it does not accidentally match. If someone sets `BACKTEST_CANDLE_TIMEFRAME=15min` to use existing data, `resample` would no-op (tf 15 → 15) and it'd run on real data, but on only ~10 most-recent bars per cycle of coverage with gaps — not a contiguous series. Not a substitute for M1 backfill.

---

## NEW TASKS

- **[infra] Provide a DB-reachable place to run the M1 backfill.** The script connects to Postgres directly (port 5432/58688) which is firewalled locally (HTTPS/443-only per `pull-nexus-data.sh`). Options: (1) `railway run node scripts/backfill-backtest-m1.mjs --from=.. --to=..` against the API/worker service, or (2) a one-off Railway job. Document the chosen path in `docs/ops/`. Until then the backfill is unrunnable and the runner throws on every call.
- **[infra/operator] Decide M1 source-of-truth.** Either (a) backfill OANDA M1 into `ohlcv_candles` once per test window (current design), or (b) add a continuous 1min writer to the worker so the table self-populates. (a) is cheaper now; (b) removes the manual step. Operator/Karri call.
- **[operator] Backfill is additive but writes prod DB.** `INSERT ... ON CONFLICT DO NOTHING` into the live `ohlcv_candles` — idempotent and non-destructive, but it IS a write to the production table. Gate per operator-prinsipp before first real (non-dry-run) execution. Recommend `--dry-run` first to confirm fetch counts.
- **[Karri] ORB backtest does not reflect live behaviour — do not act on its numbers yet.** Runner is missing retest, momentum/body-ratio, pre-move, ATR-expansion, trend filter, fit≥40 gate, midpoint-SL option, and 3-level TP management. It will overstate trade frequency and model a looser strategy. This is exactly the kind of trade-altering inference that routes through Karri. Phase 1 (share a pure ORB core between live + runner) should be specced/reviewed before any backtest output informs sizing/gates.
- **[Karri/dev] Phase 1: extract a pure ORB decision core** so `orb-manager.ts` and the runner call the SAME entry/exit logic (params from `ORB_CONFIG`, incl. `slMode`, `requireRetest`, `confirmationTf`). Until then label all runner output "ORB-mechanics sanity, not live edge".
- **[dev, low] Backfill: emit an expected-vs-fetched bar-count sanity line** (trading-minutes in window minus weekends vs `candles.length`) so silent gaps are visible.
- **[dev, low] Runner: intrabar SL-before-TP is an arbitrary pessimistic tie-break** on coarse resampled bars; note it in the result `meta` or finer-grain the conflicted-bar handling once M1 is available.

## What is NOT broken (so it doesn't get re-litigated)
- Column/DDL mapping, conflict target, NUMERIC parsing: all correct.
- Identifier injection guard on table name (`SAFE_IDENT`) + env-rollback design: sound.
- Empty-data path now names the exact backfill command instead of 500-ing: good DX.
- Backfill pagination + idempotency: correct.
