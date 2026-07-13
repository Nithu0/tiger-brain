# Nexus verify-sweep — 2026-06-14 (Sat)

Read/verify-only. Independent corroboration of ai-2's findings, post M1-backfill (174k 1min rows).
Exercised live over HTTPS/443 + DB via nexus-pg-rw MCP + code-read on `main`.

## Environment caveats (read first)
- **Live API build = `7215cff2`** (from `/health`). Local `main` HEAD = `d04ca97`. So **live is BEHIND local main** — the prompt's "7215cff2 = main HEAD" is stale. Code-reads below were done on local `main` (d04ca97); where the 3 blockers are concerned the logic is unchanged between the two, but flag/behavior on live reflects 7215cff2.
- Today is **Saturday** → XAUUSD market closed. This dominates the "is it trading" picture (see §6).
- API service has only 44 env vars; **behavior flags live on the `Worker` service (246 vars)**. Earlier "flags not found" was looking at the wrong service.

## 1. Backtest — WORKS (YES)
M1 unlock holds. Three windows, all `status=complete` with real summaries:

| window | tf | trades | winRate | totalR | maxDD | sessionsEval |
|---|---|---|---|---|---|---|
| 2026-04-15 → 06-12 | 15m | 12 | 50% | **-0.84** | 34.73 | 84 |
| 2026-05-01 → 05-31 | 15m | 6 | 50% | -0.01 | 25.06 | 42 |
| 2026-05-15 → 06-12 | 5m | 6 | 33.3% | -1.92 | 22.88 | 40 |

Real trades generated off backfilled candles, not empty/zero. Backtest engine + M1 data path is functional. (Edge is slightly negative on ORB alone over this window — that's a strategy observation, not a pipeline failure.)

## 2. meta-label / eval — LIVE but EMPTY
- `GET /meta-label/eval` → `available:true`, `report.n=0`, `verdict:"insufficient-data"`. featureKeys present (conviction_total, conviction_direction, regime_code, session_code, adx, atr_norm_stop, rsi, macro_delta).
- `GET /meta-label/scores` → `available:true`, `count:0`, `scores:[]`.
- DB: `trade_labels`=0, `meta_label_scores`=0, `signal_scorecards`=0.
- **Why empty:** not a missing flag — the recorder functions have no call-sites (see B1) AND the scorecard recorder is gated behind a rarely-hit branch (see B3). There is **no `META_LABEL_*` / `LABELER` env var on Worker**, so "flip the labeler flag" is not the fix; the wiring itself is absent in code. Endpoints will keep returning insufficient-data until B1/B3 are wired.

## 3. structure + VPA shadow facts — ON and PUBLISHING (contradicts prompt)
Prompt assumed these are default-OFF. **Live they are ON:** `MARKET_STRUCTURE_ENABLED=true`, `VPA_ANALYSIS_ENABLED=true` (Worker). And both are publishing right now (last 2026-06-14 10:07):
- `market-structure` → INTERPRETATION on `xauusd.analysis.structure.shadow`
- `volume-price-analyst` → FACT on `firm.volume-price.state`

So shadow facts ARE flowing. No flip needed. (They publish low-volume — 1 msg/cycle each — but they are live, not dormant.)

## 4. min-rr gate — DORMANT, not "clean-and-running"
- No `MIN_RR_GATE_ENABLED` env var exists on Worker; **0 `min_rr` rows in `gate_decisions`**. Active gates: risk_level (2118), ranging_conviction, scalp_overlap_asia, entry_stack_cooldown, mean_revert, daily_trade_cap, sl_cooldown, session_block, regime_direction_gate.
- ai-2's "min-rr is the one clean module" is true only as "it has no bugs because it isn't running." It is OFF, not GREEN-and-exercising. Don't read it as a working safety rail in live.

## 5. ai-2's 3 blockers — ALL CONFIRMED TRUE
**B1 (TRUE)** — `recordShadowScore` + `scoreFeatures` defined in `apps/worker/src/firm/meta-label/scorer.ts:74,93`; workspace-wide grep finds only the definitions + one doc-comment, **0 production call-sites**. Dead code; nothing computes/hands a score to the recorder. Corroborated by meta_label_scores=0 in DB.

**B2 (TRUE — and worse)** — `apps/worker/src/firm/event-policy/state-machine.ts:19-28`: `SELECT ... FROM economic_events WHERE impact='high' AND event_at BETWEEN now()±90min ... LIMIT 1`. **No currency predicate.** A high-impact event in ANY currency drives the XAUUSD EventPolicyState (blackout/caution/sizing). DB confirms the table holds high-impact NZD/EUR/GBP/AUD/CAD/CNY/CHF rows that would all fire. Extra data-quality trap: USD is stored as both `US` (13) and `USD` (8), so even a naive `currency='USD'` fix would miss most US rows.

**B3 (TRUE)** — `apps/worker/src/firm/orchestrator.ts:712`, nested inside `if (thesis.thesisQualityScore >= boostedThresholds.marketThesis)` (line 699), itself inside the trade-allowed/portfolio gate (line 691). `recordSignalScorecard` only fires when thesis quality clears threshold + Blade ran. Corroborated by signal_scorecards=0 in DB.

## 6. /health + worker cycling + trading
- `/health` = **status ok**. db ok (37ms), broker ok demo balance 89288.68, worker ok (heartbeat 220s, cycle 8.6s, ~2 cycles/hr), agents ok, reconciliation ok (0 unresolved drift, balanceDelta 38.37).
- Worker **is cycling** — FACT/INTERPRETATION/SYNTHESIS publishing at 10:07 today.
- **Trading:** DECISION + PROPOSAL stopped 2026-06-12 17:59 (Fri close). Reason = **WEEKEND** (`session_not_allowed: WEEKEND` on every strategy in signal-rejection-log). This is correct behavior, not a fault. Last full trading day Fri 06-12 had **418 decisions / 422 proposals / 1 execution**. Weekdays trade actively; weekends are flat by design.
- One strat (vol-expansion) also self-gates on `ATR ratio 0.74 < threshold 1.3` — note the ATR threshold is still rejecting there; if a recent "ATR-threshold fix" was meant to loosen this, verify it landed on the live build (live=7215cff2, may predate the fix).

## Bottom line
- Backtest: **YES**, works, real numbers (e.g. -0.84R / 12 trades on the full ORB window).
- meta-label eval: **live endpoint, empty (insufficient-data)** — blocked by code (B1/B3), not by a flag.
- 3 blockers: **B1 TRUE, B2 TRUE, B3 TRUE** (all independently confirmed in code + DB).
- Firm health: **healthy + cycling**; not trading right now **only because it's the weekend**; traded normally Friday.
- Corrections to prompt assumptions: structure+VPA are ON (publishing), not OFF; min-rr is OFF/dormant, not a running clean gate; live build trails local main.
