# Backtest / replay capability audit — Nexus XAUUSD

Date: 2026-06-03
Author: ai-2 (systems-architect audit)
Question: can we "see a live backtest on everything" — replay strategies against stored historical bars to validate logic (not just forward-paper)?

---

## TL;DR verdict

**Partially buildable-soon, but NOT in its current shape.** There is a real, working bar-replay engine for ORB only (`apps/api/src/backtest/runner.ts`), but it is a *re-implementation* of the strategy, not the live code path, and it reads from a table (`backtest_xauusd_m1`) that does not exist in the schema and has no ingest. The other ~10 strategies (TF/MR/BC/scalp/session/vol-exp) cannot be replayed at all because their entry/exit logic is tangled with live runtime state (blackboard, wall-clock `new Date()`/`Date.now()`, module-level mutable counters, live network candle fetches).

**The single biggest blocker is not "no stored bars" and not "no clock" — it is that strategy decision logic is not pure/replayable.** Every live strategy reads `board.latest(...)`, calls `fetchCandles()` (a live OANDA/TwelveData HTTP call with no time parameter), and uses `new Date()` / `Date.now()` directly. You cannot feed them a historical bar and get the decision they *would* have made. The ORB backtest "solves" this only by re-coding ORB a second time — which means it validates a *copy* of the logic, not the logic that actually trades.

---

## (a) What backtest capability exists today

### Real, working: ORB-only re-implemented replay
- **`apps/api/src/routes/backtest.ts:295-355`** — `POST /backtest` inserts a `backtests` row, then synchronously calls `runBacktest(...)` and stores the equity curve in `results`. This is real, not a stub.
- **`apps/api/src/backtest/runner.ts:393-471`** — `runBacktest()` is a genuine bar-replay: loads M1 candles, resamples to the requested timeframe (`resample()` at :158), groups by London/NY session (`groupBySession()` :182), and walks each session for the ORB break→SL/TP/EOS exit (`simulateSession()` :229-350). Pure in-process, no DB writes, no OANDA calls. Produces equity curve, win rate, R-multiples, max drawdown.
- It is an explicit TypeScript **port of `scripts/backtest-orb.mjs`** (runner.ts:6-8), and only the base ORB path — scalp_A/scalp_C, HTF and vol-expansion pre-filters are deliberately NOT ported.

### Two fatal caveats on that "real" engine
1. **Wrong data source.** `runBacktest` reads `FROM backtest_xauusd_m1` with columns `mid_o/mid_h/mid_l/mid_c, complete` (runner.ts:134-142). That table is **not** in `packages/shared/src/db/schema.ts`, not in any migration, and not written by any script (grep: only reference is runner.ts itself). It will throw `No M1 candles in backtest_xauusd_m1...` (runner.ts:402) on every call unless someone manually created+populated it out-of-band. By contrast the *actual* working script `scripts/backtest-orb.mjs:240` reads from `ohlcv_candles` (or live OANDA). So the API route is wired to a phantom table.
2. **It's a parallel re-implementation, not the live path.** The live ORB decision lives in `apps/worker/src/firm/orb/orb-manager.ts:evaluateORBEntry()`. The runner re-derives range/breakout/exit independently. Any divergence between the two (e.g. the live `computeFitScore` 5-criteria gate at orb-manager.ts:196, trend filter at :87, daily cap at :82, midpoint-SL mode at :276) is **not** reflected in the backtest. So the backtest validates an idealized ORB, not what trades.

### The "analytics dashboard" half of backtest.ts is honest paper-trade reporting, not backtesting
- `GET /backtest` (backtest.ts:24-293) is pure forward-paper analytics: it aggregates `simulated_orders` by strategy/session/regime/close-reason. It even self-declares the gap at backtest.ts:281: *"No backtesting against historical data yet — results show only live paper-trading performance."* This matches the `/explorer/weaknesses` self-audit.

### Other strategies: zero replay capability
None of TF, MR, BC, scalp-overlap, session-breakout, vol-expansion have any replay path through the API engine. There are one-off tuning scripts (`scripts/backtest-strategies.mjs`, `backtest-scalp-*.mjs`, `backtest-vol-exp-*.mjs`) but those are bespoke per-strategy re-implementations, same as backtest-orb.mjs — not the live modules.

---

## (b) The single biggest blocker

**Strategy entry/exit decisions are NOT pure functions of market state — they are entangled with live runtime, so they cannot be replayed offline.** Concretely, every live strategy manager:

- Reads cross-agent state from the in-memory blackboard: e.g. ORB `board.latest("xauusd.analysis.technical", 300)` (orb-manager.ts:87), `board.latest("xauusd.portfolio.context", 300)` (:211). That state is reconstructed live each cycle and is not persisted in replayable form keyed to bar-time.
- Pulls candles via a **time-less live network call**: `fetchCandles("XAUUSD","1h",60)` (trend-following-manager.ts:~220) → `apps/worker/src/services/market-data.service.ts:146` which hits OANDA/TwelveData for the *latest* N bars. There is no `asOf`/clock parameter — you cannot ask it "what were the last 60 bars as of 2026-04-12 14:30".
- Uses wall-clock directly: `new Date()` / `Date.now()` / `getLondonLocalTime()` for session windows, cooldowns, daily-cap resets (orb-manager.ts:51-53 `resetDailyCountIfNeeded`; trend-following-manager.ts:75-91 `todayCount`/`lastSignalAt`/`Date.now()`).
- Holds **module-level mutable state** that accumulates across the live process: `todayOrbTradeCount`/`lastResetDate` (orb-manager.ts:46-47), `todayCount`/`lastResetDate`/`lastSignalAt`/`lossesByDirection` (trend-following-manager.ts:75-78). A replay would need to reset and drive these deterministically.

Stored bars are NOT the blocker: `ohlcv_candles` exists (schema.ts:826) and is populated every cycle (raw-data-persistence.md), and OANDA can backfill M1/M5 directly (backtest-orb.mjs:260 already paginates 5000-bar OANDA pulls). History is thin and 15-min granularity in-DB (candles.ts:8 "table only stores 15-min"), but acquiring bars is the easy part.

---

## (c) Minimal concrete plan to get "replay any strategy over stored history"

The honest minimal version is **not** "make every live module replayable" (that's a multi-week refactor of 10+ stateful managers). It's: (1) fix the ORB engine that already exists so it actually runs, then (2) introduce a thin pure-core seam so strategies can be replayed without rewriting them twice.

### Phase 0 — make the existing ORB engine actually work (0.5–1 day)
- Create + populate the M1 table the runner expects, OR repoint the runner at `ohlcv_candles`.
- Recommended: add `backtest_xauusd_m1` to `packages/shared/src/db/schema.ts` (mirror columns `mid_o/h/l/c, complete`), and add an ingest script `scripts/backfill-m1.mjs` that paginates OANDA `XAU_USD M1` (logic already exists in backtest-orb.mjs:260-309) into it.
- Files: `packages/shared/src/db/schema.ts` (+table), new `scripts/backfill-m1.mjs`, optionally `apps/api/src/backtest/runner.ts:134` (repoint).
- Result: `POST /backtest` for ORB returns a real equity curve. This alone clears the literal `/explorer/weaknesses` complaint for one strategy.

### Phase 1 — extract pure decision cores (the real work; ~5–8 days for 4 strategies)
- For each strategy, factor the *decision math* into a pure function `decide(bars, indicators, params, virtualState) -> Signal | null` with NO `board`, NO `new Date()`, NO module-level state, NO network. Clock + state become explicit arguments.
- ORB is the cheapest (its math is already isolated and twice-implemented — collapse the two). TF/MR/BC follow. Live managers become thin wrappers that gather live inputs and call the pure core; the backtest harness gathers historical inputs and calls the *same* core. This kills the "validates a copy" problem.
- Files: `apps/worker/src/firm/{orb,trend-following,mean-reversion,breakout-continuation}/*-core.ts` (new pure modules) + refactor the existing managers to delegate. Add unit tests pinning core == old behaviour.
- Effort dominated by untangling blackboard reads (need to define what market-state each strategy truly consumes and snapshot it per-bar from `ohlcv_candles` + computed indicators).

### Phase 2 — generic replay harness + UI (~2–3 days)
- Generalize `runBacktest` from ORB-hardcoded to "load bars → per bar, compute indicators + synthetic blackboard state → call strategy core → walk fills with the existing SL/TP/EOS walker." Reuse the resample/equity-curve/drawdown code already in runner.ts:158-471.
- Wire dashboard so the existing `backtests` table + `GET /backtest` surface real historical equity curves alongside the paper-trade analytics. Drop the trustWarning at backtest.ts:281.
- Files: `apps/api/src/backtest/runner.ts` (generalize), dashboard backtest page.

**Total to "replay the 4 core strategies over stored history": ~8–12 engineering-days**, front-loaded on Phase 1 purity extraction. Phase 0 alone (ORB-only, real data) is <1 day and immediately removes the headline weakness for the flagship strategy.

> Note: This is strategy-logic-adjacent. Phase 0 (data plumbing) and the Phase 1/2 *infrastructure* are Claude-owned (pipeline that CARRIES validation). But the moment a replay result is used to change a threshold/gate, that's Karri's call per the strategy-change protocol. Building the replay engine = infra; acting on its output = strategy.

---

## (d) Honest alternative if the above is not wanted soon

If 8–12 days of purity refactor isn't worth it right now, the pragmatic alternatives, in order:

1. **Keep + harden the per-strategy script backtesters** (`scripts/backtest-*.mjs`). They already exist, already read `ohlcv_candles`/OANDA, and already produce equity curves. Lowest effort: just document them as the sanctioned offline-validation path and run them per tuning iteration. Downside: they re-implement each strategy (the exact "validates a copy" flaw), so they drift from live unless disciplined.
2. **Shadow-mode forward-testing** (already partly built): `apps/worker/src/firm/shadow-log.ts` records would-be entries that gates blocked. Extend this to record *every* strategy's hypothetical entry every cycle regardless of gate, then score them forward. This validates the *actual live logic* (no re-implementation) at the cost of waiting real-time for data to accumulate — no historical replay.
3. **External backtester (vectorbt / backtesting.py / TradingView)** for fast parameter sweeps on ORB-style rules. Good for "is there an edge at all" sanity checks; useless for validating *Nexus-specific* gate/blackboard logic because none of that exists outside this codebase. Treat as a directional cross-check, not validation.

**Recommendation:** Do Phase 0 now (<1 day, real ORB replay, kills the headline weakness honestly), then decide on Phase 1 based on whether Karri wants replay-driven tuning across TF/MR/BC. Until Phase 1 lands, lean on shadow-mode (#2) for the strategies that can't replay, because it tests the real code path rather than a copy.

---

## Key file:line references
- `apps/api/src/routes/backtest.ts:24-293` — forward-paper analytics (NOT backtest); self-admits gap at :281
- `apps/api/src/routes/backtest.ts:295-355` — real `POST /backtest` → runBacktest
- `apps/api/src/backtest/runner.ts:131-150` — loads from phantom `backtest_xauusd_m1`
- `apps/api/src/backtest/runner.ts:229-350,393-471` — genuine ORB bar-replay (port of script)
- `apps/worker/src/firm/orb/orb-manager.ts:46-53,82-99,211` — live ORB: mutable state + wall-clock + blackboard reads
- `apps/worker/src/firm/trend-following/trend-following-manager.ts:75-91,~220` — same live-coupling pattern
- `apps/worker/src/services/market-data.service.ts:146` — `fetchCandles()` time-less live network pull
- `packages/shared/src/db/schema.ts:235-253` — `backtests` table (real); :826 `ohlcv_candles` (real, 15min only); `backtest_xauusd_m1` absent
- `scripts/backtest-orb.mjs:240` — working script reads `ohlcv_candles`/OANDA (the runner should too)

## Caveat
DB was unreachable from this sandbox (`EHOSTUNREACH` on nexus-pg MCP), so exact row counts / history depth in `ohlcv_candles` and existence of `backtest_xauusd_m1` could not be confirmed live. Conclusions are from schema/code/migration evidence: the M1 table has no DDL or ingest in-repo, so it is almost certainly empty or absent in prod.
