# Backtest capability — state after 37e3da8 (repoint to ohlcv_candles)

Date: 2026-06-04
Author: code session (read-only verification of ai-2's 2026-06-03 audit + post-37e3da8 state)
Question: operator wants "backtest hver trade." What works TODAY, what's the #1 blocker, what's the single next task.

---

## TL;DR

**Backtesting that works today: NONE end-to-end. ORB-only is now code-correct but data-blocked.**

Commit 37e3da8 fixed the right thing (runner no longer reads a phantom `backtest_xauusd_m1` table — it reads the real `ohlcv_candles`, env-configurable, injection-safe) and shipped a correct idempotent OANDA M1 backfill script. But `POST /backtest` for ORB still throws on every call, because the data it needs does not exist in the DB yet:

- The runner defaults to `BACKTEST_CANDLE_TIMEFRAME=1min`.
- The live firm only ever persists **`15min`** candles (`raw-data-persistence.ts:471`, hardcoded `tf="15min"`). It never writes 1min.
- So `SELECT ... WHERE timeframe='1min'` returns 0 rows → runner throws the "Run the backfill first" error.
- The backfill that would populate 1min (`scripts/backfill-backtest-m1.mjs`) **cannot run locally** — the DB is firewalled from this machine (confirmed: `EHOSTUNREACH 66.33.22.236:58688` on the nexus-pg MCP, same wall ai-2 hit; operator's own `pull-nexus-data.sh` header documents it: "direct DB ports 5432/58688 and SSH:22 are firewalled"). It must run **on Railway**.

Independently, today's live pull (`data/pull/weaknesses.json`, fetched 2026-06-04 18:17) shows the worker is **idle**: "No bots are currently running — platform is idle", "Last signal is 1522 min old (~25h)". So even the 15min candle stream is not currently being persisted. The self-audit still lists "No historical bar replay for backtesting" as an open weakness.

**Net: ai-2's audit was accurate; 37e3da8 advanced Phase 0 by ~half (code + backfill script landed) but Phase 0 is NOT done — the 1min data is not in the DB.**

---

## 1. What the ORB runner needs now, and is it present

After 37e3da8 (`apps/api/src/backtest/runner.ts`):
- Reads `ohlcv_candles` (default), columns `candle_time, open, high, low, close`, filtered `symbol='XAUUSD' AND timeframe='1min'`. Env overrides: `BACKTEST_CANDLE_TABLE / _SYMBOL / _TIMEFRAME`, identifier-validated against `/^[A-Za-z_][A-Za-z0-9_]*$/`. Rollback-safe.
- Resamples M1 → requested timeframe, groups by London/NY session, walks ORB break→SL/TP/EOS. Pure, no DB writes, no OANDA calls. Genuine equity curve / winRate / R / maxDD.
- Empty-data path now names the exact fix command instead of 500-ing.

Wiring is real: `POST /backtest` (`apps/api/src/routes/backtest.ts:326`) calls `runBacktest` and stores `results`.

**Is the data present?** Could not confirm row counts live (DB firewalled). But from code it is provably absent by default:
- Firm writes only `15min` (raw-data-persistence.ts:471). No code anywhere writes `1min` except the new backfill script, which has not been run on Railway.
- `ohlcv_candles` schema exists (`packages/shared/src/db/schema.ts:826`, PK `(symbol,timeframe,candle_time)` — matches the backfill's `ON CONFLICT`). The table is real; the 1min partition of it is empty.
- `followups.ts:53` carries a standing note that ohlcv_candles has even had **0 rows** historically (API-key/runtime issue) — consistent with the idle-worker state in today's pull.

**Two cheap unblock options** (operator picks):
- (a) Run `node scripts/backfill-backtest-m1.mjs --from=… --to=… ` **on Railway** (where DB + OANDA token are reachable) to populate 1min. Cleanest; gives true M1 granularity.
- (b) Set `BACKTEST_CANDLE_TIMEFRAME=15min` on the API service so the runner reads the 15min bars the firm already persists. Zero data work, but only if 15min history is actually non-empty (the idle-worker signal says it may be thin/stale) and accepts coarser 15min replay granularity.

---

## 2. Structural finding (ai-2): re-implementation + non-pure strategies — VERIFIED

- **Runner re-implements ORB; it does NOT call live `orb-manager.ts`.** Confirmed. The runner re-derives range/breakout/exit itself (runner.ts:255-376). The live ORB decision (`apps/worker/src/firm/orb/orb-manager.ts`) layers on a daily cap (`todayOrbTradeCount` module global, `:46,82`), `resetDailyCountIfNeeded()` using `new Date()` + `getLondonLocalTime()` (`:49-55`), and two blackboard reads (`board.latest("xauusd.analysis.technical",300)` `:87`; `"xauusd.portfolio.context"` `:211`). None of that is in the runner. So the backtest validates an idealized ORB copy, not what trades. (37e3da8's own commit msg admits this caveat.)
- **The other ~10 strategies have zero replay** because their logic is impure — reads blackboard, `new Date()`/`Date.now()`, module-level counters, and time-less live `fetchCandles()`. Confirmed by the same coupling pattern in orb-manager and the manager files ai-2 cited. No replay path exists for TF/MR/BC/scalp/session/vol-exp through the engine.

---

## 3. Is ai-2's recommended path correct? Highest-leverage step?

ai-2's plan (Phase 0 ohlcv_candles + Phase 1 extract pure `decide()` cores, with shadow-mode as the honest interim) is **correct and still the right shape.** Nothing in 37e3da8 changes the conclusion. Phase 1 (pure-core extraction across 4 strategies) remains the only way to get true historical replay of the *real* logic, and it remains ~8-12 eng-days, strategy-adjacent (infra is Claude's; acting on results is Karri's).

But there is a sharper near-term answer than "do Phase 0":

**The single highest-leverage step is to finish-and-turn-on the shadow forward-test, not to chase the ORB backtest.** Reason: the forward-test already tests the REAL live logic of ALL strategies, not a copy — and it is already built and wired.

---

## 4. Shadow forward-test (7ec793c) — does it test REAL logic? Faster path?

**Yes, and yes.** `recordForwardTestSnapshots()` (`apps/worker/src/firm/shadow-log.ts:336`) is called every orchestrator cycle (`orchestrator.ts:554`), with outcome resolution at `:589`. Per cycle it reads each enabled strategy's **actual published `.state` blackboard topic** (`strategy-snapshot.ts:37-47` lists all 8: ORB, scalp-overlap, session-breakout, vol-exp, breakout-continuation, mean-reversion, trend-following, pullback-continuation) and records its real hypothetical entry (would_fire, dir, entry/SL/TP, confidence, reject reason) + regime — **one row per strategy per cycle, even when nothing trades.** This is the genuine live `decide()` output, no re-implementation. Outcomes resolve forward vs spot SL/TP (coarse: spot mid, no intra-bar wick/slippage/spread).

This is **strictly better than the ORB backtest for "validate every trade"** on two axes: it covers all 8 strategies (vs 1), and it validates the real code path (vs a copy). Its only cost is it accumulates forward in real time — no historical replay. Given the operator wants continuous learning (prinsipp 6 rescinded 2026-06-03), forward-accumulation is acceptable and arguably preferred.

**It is default OFF** (`SHADOW_FORWARD_TEST_ENABLED`, shadow-log.ts:262). Turning it on is pure data-capture, no trade-behaviour change → Claude-owned per the learning-infra/strategy boundary, but it's a Railway env flip = operator action.

### Two bugs found while reading (both pre-existing, worth flagging)
1. **Outcome label mismatch in `/shadow` aggregates.** `shadow-log.ts` writes outcomes `'tp_hit'/'sl_hit'`, but `apps/api/src/routes/shadow.ts` `/shadow/per-strategy` (`:37-40`) and `/shadow/comparison` (`:152`) filter on `outcome IN ('win','loss')`. Those two endpoints will always report 0 shadow wins/losses/R. (The newer `/shadow/forward-test` endpoint uses the correct `'tp_hit'/'sl_hit'` labels — only the older shadow_signals aggregates are wrong.) Bug-fix, no proposal needed.
2. Worker is currently idle (today's pull) — neither shadow stream nor candle persistence is running right now regardless of flags. Needs the bots restarted before any capture flows.

---

## RECOMMENDATION

- **Backtesting that works today:** none end-to-end. ORB runner is code-correct but data-blocked (needs 1min in `ohlcv_candles`, which only exists after a Railway-side backfill; the firm only persists 15min).
- **#1 blocker:** the data plumbing — the runner reads `timeframe='1min'` but nothing populates 1min, and the backfill can only run on Railway (DB firewalled from local). Underneath that, the worker is currently idle so nothing is being captured at all.
- **Single recommended NEXT task (highest leverage):** flip `SHADOW_FORWARD_TEST_ENABLED=true` on the Railway Worker (after confirming bots are running again) + fix the `'win'/'loss'` vs `'tp_hit'/'sl_hit'` label bug in `shadow.ts`. This gives "validate every trade across all 8 strategies, real live logic" continuously, today, with no purity refactor. **Effort: ~1-2 hrs** (one Railway flip = operator; one ~10-line bug fix + test = Claude). 

  Then, as a parallel cheap win for the operator's literal "ORB backtest" ask: run `backfill-backtest-m1.mjs` on Railway for a recent window (or set `BACKTEST_CANDLE_TIMEFRAME=15min`). **Effort: ~1 hr operator-side.** This makes `POST /backtest` return a real ORB equity curve.

  Defer Phase 1 (pure-core extraction, ~8-12 days, Karri-gated for any tuning use) until the forward-test shows whether replay-driven tuning is even wanted.
