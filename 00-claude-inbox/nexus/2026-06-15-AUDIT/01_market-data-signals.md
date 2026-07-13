# Nexus learning-loop audit — Stage 1 (Market Data) + Stage 2 (Signals)

Date: 2026-06-15. Auditor: Claude (critical/evidence-based). DB reachable via `mcp__nexus-pg-rw__query` (live Postgres). Row counts and freshness below are from the live DB, not inferred from code.

---

## VERDICTS

- **Stage 1 — Market data ingestion: EXISTS (with gaps).** Candles + indicator/cross-asset snapshots are persisted live, fresh to today, multi-month history. Gaps: no spread/bid-ask capture anywhere; only 15min candles maintained live (1min is a stale backfill); volume is TwelveData/OANDA-sourced and unreliable for spot gold.
- **Stage 2 — Signal generation/logging: EXISTS (strong).** `shadow_signals` logs every proposal (fired + blocked) with direction/entry/SL/TP/confidence/thesis/criteria AND tracks simulated outcome + R-multiple. `gate_decisions` logs gate-level rejections with regime/conviction/session context. This is a real learning substrate, not just an executed-trade log.
- **Reconstruction ("what fired, when, why, what did market look like"): WEAK.** All the pieces exist but **cannot be joined by id** — the signal-side cycle id and the market-snapshot cycle id are different UUIDs (verified: 0 join matches). Reconstruction is only possible by timestamp-proximity, which is fragile.

---

## STAGE 1 — MARKET DATA

### Tables
| Table | Rows | Max timestamp | Status |
|---|---|---|---|
| `ohlcv_candles` (15min) | 3,472 | candle_time 2026-06-15 20:00Z | FRESH |
| `ohlcv_candles` (1min) | 174,087 | candle_time 2026-06-12 20:59Z | **STALE (3+ days), backfill only** |
| `market_snapshots` | 28,219 | recorded_at 2026-06-15 20:26Z | FRESH |
| `cross_asset_snapshots` | (exists) | — | secondary |
| `analysis_snapshots` | (exists) | — | analyst output per cycle |
| `news_headlines` / `sentiment_snapshots` / `reddit_*` | populated | — | side channels |

### How it's fetched
- `apps/worker/src/firm/orchestrator.ts:267 runCycle()` → Step 1 `runAllFactAgents` → Step 1a `persistRawSnapshots` (orchestrator.ts:429).
- `apps/worker/src/firm/raw-data-persistence.ts:470 persistCandles()` — **hardcoded `tf = "15min"`, fetches last 10 candles each cycle**, UPSERT `ON CONFLICT DO NOTHING`. So only 15min is maintained live; the 1min 174k rows have no live writer (confirmed by grep) → backfill, now stale.
- Source priority in `apps/worker/src/services/market-data.service.ts:233 fetchCandles`: **OANDA primary** (the broker, line 243), TwelveData fallback (line 292), Polygon rescue. Good — candles come from the broker we actually trade against.
- Cadence ~60s. `market_snapshots` shows ~680 rows/day on weekdays (06-08..06-11), dropping to 30–57 on the 06-13/14 weekend — consistent with a real ~1/min loop that idles on closed markets. No alarming gaps inside trading days.
- Persistence is env-gated `RAW_DATA_PERSIST_ENABLED` (default true) and is verified ON (rows landing today).

### What IS captured
- OHLC + volume (`ohlcv_candles`, raw-data-persistence.ts:528).
- Per-cycle price + indicators: rsi, macd, bbands, stochastic, adx, ema20/50, atr (`market_snapshots`, schema.ts:770).
- Cross-assets: eurusd, spy, uso, tlt, silver (same row).
- News headlines, fear/greed, reddit sentiment as side channels.

### Stage-1 GAPS (block learning)
1. **No spread / bid-ask captured anywhere.** `market_snapshots` stores a single `price`; `ohlcv_candles` has no spread column. For XAUUSD scalp/ORB strategies, spread is a first-order cost — you cannot learn "this setup loses after spread" from stored data.
2. **No tick data.** Lowest live granularity is 15min candles + 1/min indicator snapshots. Sub-minute structure (the timescale several firm strategies trade on) is not recoverable.
3. **1min candles stale** (last 2026-06-12) — any model that assumed 1min coverage is training on a frozen tail.
4. **Volume is suspect** for spot gold (TwelveData/OANDA synthetic), so volume-based features (VPA module) sit on weak input.
5. **15min-only live candle persistence** — no 5min/1h/4h series maintained, limiting multi-timeframe backtest from stored data (live strategies do fetch other TFs on the fly, but they aren't persisted for replay).

---

## STAGE 2 — SIGNALS

### Tables
| Table | Rows | Max timestamp | Notes |
|---|---|---|---|
| `signals` (legacy) | 14,210 | 2026-06-05 (mostly 2026-04) | **STALE — legacy path, superseded** |
| `shadow_signals` | 478 (76 fired / 402 blocked) | detected_at 2026-06-15 15:34Z | **PRIMARY signal log — fired + rejected** |
| `gate_decisions` | 9,354 | 2026-06-15 17:34Z | gate-level rejections, fresh |
| `pending_signals` | 0 | — | **empty / unused** |
| `v146_signal_decisions` | 87 | 2026-06-09 | secondary decision log, going stale |
| `simulated_orders` | (executed trades) | — | downstream of signals |

### Is EVERY signal logged (not just executed)?
**Yes, via `shadow_signals`** — `apps/worker/src/firm/shadow-log.ts:1` docstring + `apps/worker/src/firm/strategy-execution.ts:478 shadow()` helper. Every proposal from the firm strategies is inserted with `fired` boolean; blocked ones carry `block_stage` + `block_reason`. Live split: 76 fired / 402 blocked. Block stages (shadow-log.ts:27): pre-check, daily-loss, cap-reached, mini-blade, oanda-reject.

Columns (rich): strategy, cycle_id, proposal_id, fired, block_reason, block_stage, direction, entry_price, stop_loss, take_profit, confidence, criteria_passed, criteria_failed, thesis, detected_at, outcome, outcome_price, outcome_at, pnl_simulated_r.

**Outcomes ARE tracked** (orchestrator.ts:621 `trackShadowOutcomes` walks pending records vs live price): live counts tp_hit 168 / sl_hit 127 / expired 183. So shadow signals are not write-only — they get a labeled result + R-multiple. This is the single best learning asset in the first two stages.

### Gate-rejections
`gate_decisions` (schema.ts:742): gate_name, would_reject, hard_rejected, reason, **context JSONB** (sampled: direction, strategyId, sessionState, riskLevel, portfolioRegime, convictionTotal, thesisQualityScore). Written from `strategy-execution.ts`, `strategy-blade.ts`, `gates/new-gates.ts` etc. Fresh, 9.3k rows. Also a parallel `xauusd.signal.rejected` blackboard publish (strategy-execution.ts:503 `publishSignalRejection`).

### Stage-2 GAPS (block learning)
1. **Legacy `signals` table is dead** (last meaningful writes 2026-04, source `xauusd-engines-v3`). Anything querying `signals` for current behaviour is reading a corpse. Firm path uses `shadow_signals`. Two parallel signal stores is a footgun.
2. **shadow_signals only covers firm strategies** (ORB, scalp, session-break, vol-exp, FVG, mean-revert, trend-follow). Pre-proposal kills (a strategy that never emits because an upstream gate suppressed it) land in `gate_decisions`, not `shadow_signals` — the two funnels must be unioned to see the full rejection picture.
3. **`pending_signals` is empty** despite being a defined table — dead schema or a path that never fires.
4. **No regime/session/spread snapshot stored on the shadow_signals row itself.** Regime lives in `gate_decisions.context` and `market_snapshots`, not on the signal — so per-signal regime attribution needs a cross-table join (see below).
5. `v146_signal_decisions` going stale (last 06-09) — a third decision log adding fragmentation.

---

## RECONSTRUCTION TEST — "what fired, when, why, market state?"

- WHAT/WHEN/WHY/OUTCOME: **fully recoverable from `shadow_signals` alone** (direction, levels, confidence, thesis, block reason, tp/sl/expired, R). Verified on live rows.
- MARKET STATE at signal time: lives in `market_snapshots` (indicators) + `gate_decisions.context` (regime/conviction/session).
- **THE PROBLEM — ids do not join.** Verified live:
  - `shadow_signals.cycle_id` → `market_snapshots.cycle_id`: **0 matches**
  - `gate_decisions.decision_cycle_id` → `market_snapshots.cycle_id`: **0 matches**
  - Root cause is documented in code: orchestrator.ts:282 generates `orchestratorCycleId` (used for `market_snapshots`), but the signal/gate rows use a separate `decisionCycleId` minted later inside prismSynthesis / strategy_blade. They are different UUID spaces.
  - Net: you can only stitch signal ↔ market-state by **timestamp proximity** (detected_at vs recorded_at), which is lossy and fragile under the ~60s cadence. The clean id-join that the schema *looks* like it supports does not work.

**Verdict: WEAK.** All the data exists, but the join key that would make reconstruction trivial is broken. This is the highest-value, lowest-effort fix in the first two stages.

---

## TOP GAPS RANKED (for the learning loop)

1. **Broken cycle-id join** between signals/gates and market_snapshots (0 matches live). Unify on one cycle id, or stamp `orchestratorCycleId` onto shadow/gate rows. Without it, "signal + market context" must be timestamp-fuzzed.
2. **No spread/bid-ask ever stored** — blocks honest cost-aware learning for scalp/ORB.
3. **No tick / sub-15min persisted price** — strategies trade faster than the stored data resolution.
4. **Two/three parallel signal stores** (`signals` dead, `shadow_signals` live, `v146_signal_decisions` half-alive, `pending_signals` empty) — fragmentation + stale-corpse risk.
5. **1min candle feed stale** (06-12) and **volume unreliable** for spot gold.
6. **Regime/session not denormalised onto the signal row** — per-signal regime attribution needs cross-table joins that (per #1) don't cleanly work.

## What's genuinely good (don't lose this)
- `shadow_signals` logs fired + rejected with full thesis/criteria AND resolves outcomes to tp/sl/expired + R-multiple. That is a real labeled dataset for learning (295/478 resolved).
- `gate_decisions` captures the rejection funnel with regime/conviction context.
- Candles come from OANDA (the actual broker), with TwelveData/Polygon fallbacks — sound provenance.
- Raw persistence is live, fresh to today, multi-month deep, env-gated and non-fatal to the trading loop.
