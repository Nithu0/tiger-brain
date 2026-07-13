# Nexus Audit — Stage 5: EVALUATION (does it measure strategies objectively?)

Date: 2026-06-15
Scope: Does the system compute the operator's required metrics, per-strategy and per-regime/session, in a single objective scorecard, and can it compare a NEW strategy version vs the PREVIOUS one with accept/reject on a threshold?

Verdict source: code read + LIVE Postgres row counts (nexus-pg-rw, data current to 2026-06-14).

---

## TL;DR verdict

**Overall: WEAK.** The system computes most headline metrics and breaks them down by session/regime, and the pipelines are POPULATED with live recent data (not empty shells). BUT:

1. There is **no single canonical per-strategy scorecard** — evaluation is scattered across 3+ endpoints with **inconsistent / mathematically wrong formulas** (profit factor is computed two different, both partly wrong, ways).
2. **Strategy-version comparison is MISSING entirely.** No table, no code path, and live proof: all 8 strategies are `version=1` and have never been incremented. The `version` column is echoed in API responses and read by nothing.
3. Per-strategy sample sizes are **too small to evaluate** (max 44 closed trades, most 5-23), so even the metrics that exist are statistically meaningless per strategy.
4. The "learning loop" (calibration) tunes session thresholds + engine weights, NOT strategy versions — and it acts on session/engine aggregates, never on a strategy-vs-strategy or version-vs-version basis.

The key question — *"can the system objectively say strategy X is better/worse than last week with numbers?"* — **No.** It can say "strategy X had win-rate Y over the last 30d" (globally, small-n), but it cannot compare to a prior version because no prior version is ever recorded, and there is no accept/reject mechanism.

---

## 1. Per-metric findings

Legend: EXISTS = computed & wired; WEAK = computed but flawed/partial/not-per-strategy; MISSING = not computed.

| Metric | Status | Where | Per-strategy? | Per-regime/session? |
|---|---|---|---|---|
| **Win rate** | EXISTS | `analytics.ts:122`; `strategies.ts:319`; `strategies-compare.ts:190` | Yes (compare + detail) | Yes (analytics bySession; strategies.ts session/regime/dow blocks) |
| **Profit factor** | WEAK (wrong math) | `analytics.ts:123` (correct: grossProfit/grossLoss); `strategies.ts:320` (WRONG: avgWin/avgLoss = payoff ratio, mislabeled profitFactor); `analytics.ts:199` hardcoded `profitFactor: 0` | Partial | Global only in analytics |
| **Average win** | EXISTS | `analytics.ts:128`; `strategies.ts:154,259` | Yes | No (global per strategy) |
| **Average loss** | EXISTS | `analytics.ts:129`; `strategies.ts:155,260` | Yes | No |
| **Risk/reward (avg R)** | WEAK | `strategies-compare.ts:71` AVG(result_r); detail uses avgWin/avgLoss proxy | Yes | No. AND result_r is NULL on most rows (see §4) |
| **Max drawdown** | EXISTS | `analytics.ts:84-86` (equity %); `strategies.ts:173-185` (per-strategy peak-to-trough); `strategies-compare.ts:121-132` | Yes | Global per strategy |
| **Number of trades** | EXISTS | everywhere (COUNT) | Yes | Yes |
| **Expectancy** | WEAK | `analytics.ts:124` (= mean PnL, OK); `strategies.ts:321` (winRate*avgWin - lossRate*avgLoss, OK-ish) | Yes | Global only |
| **Session / time-of-day** | EXISTS | `analytics.ts:109-118` (bySession); `strategies.ts:190-226` (session + day-of-week, strategy-scoped); engine scorecards `scorecardsBySession` | Yes | Yes — strongest area |
| **High/low volatility perf** | WEAK | No explicit vol-bucket P&L. Closest: regime breakdown `strategies.ts:243` + `conviction-quartiles` `analytics.ts:308`. `atr_at_entry` is stored but never bucketed for win-rate-by-vol. | Partial (regime proxy) | regime ≈ vol proxy |
| **Spread/slippage sensitivity** | MISSING (as a metric) | `spread_at_entry` column reserved "v2" (`oanda-sync.ts:142`, unused). fill-quality agent (`fill-quality.ts`) is an LLM-prose agent behind `FIRM_AGENT_FILL_QUALITY_ENABLED` (default OFF) — produces narrative, not a metric. Paper slippage is a fixed session-bucket model (`explorer.ts:306`), not measured against fills. No "win-rate vs spread" computed anywhere. | No | No |
| **Strategy-version comparison** | **MISSING** | No table, no code. `strategies.version` read only for display (`strategies.ts:47,306`); all rows = version 1 (live). | — | — |

---

## 2. Single objective scorecard? — NO

Evaluation is **scattered across at least three independent implementations** that disagree:

- `/analytics/performance` (`analytics.ts`) — global firm-wide; correct profit-factor math; no per-strategy.
- `/strategies/:id` (`strategies.ts`) — per-strategy; **profitFactor = avgWin/avgLoss (WRONG)**.
- `/strategies/compare` (`strategies-compare.ts`) — cross-strategy; uses avg_r + Sharpe, no profit factor or expectancy at all.
- `engine-attribution/scorecards.ts` + `aggregates.ts` — a real, well-built per-ENGINE scorecard (8 metrics, composite performanceScore, by session, by regime) — but it scores the 4 conviction ENGINES (macro/structure/sentiment/intermarket), **not the trading strategies**. Different unit of analysis.
- `signal-scorecard/scorecard-recorder.ts` — per-SIGNAL 5-filter shadow record; 3 of 5 filters are `unavailable` ("module not built yet"); behind `SIGNAL_SCORECARD_ENABLED` (default OFF); live table has **4 rows**.

So there is a polished scorecard abstraction — but it is aimed at engines and signals, never unified into "one row per strategy with all required metrics." The closest to a strategy scorecard (`strategies-compare.ts`) is missing half the required metrics.

The same metric (profit factor) is computed correctly in one file and wrongly in another. That alone disqualifies "objective scorecard."

---

## 3. New-version vs previous-version accept/reject? — MISSING (the headline gap)

There is **no mechanism** that:
- snapshots a strategy's metrics at version N,
- runs version N+1,
- compares the two on these metrics,
- and accepts/rejects against a threshold.

Evidence:
- No `*_version`, `champion`, `challenger`, or `evaluation` table exists (checked information_schema).
- `strategies.version` column exists but is **never written/incremented** — live: all 8 strategies = `version 1`. It is read in exactly two places, both just to echo it in JSON.
- The only "A/B-shaped" infra is `shadow_forward_test` / `shadow_signals` (`shadow-log.ts`) — a would-have shadow of signals, gated by `SHADOW_FORWARD_TEST_ENABLED` (**default OFF**). It compares "shadow signal vs reality," not "strategy v2 vs v1."
- The calibration engine (`calibration.ts`) is the firm's actual "learning" loop. It adjusts **session thresholds** and **engine weights** from postmortems/engine_scores within bounded ranges. It does NOT version strategies, does NOT compare a tuned config against the prior config on a held-out metric, and applies changes by **rule** (e.g. "winRate < 0.35 over ≥5 trades → raise threshold by clamped delta"), i.e. heuristic/logic, not a measured improvement test. There is no rollback-if-worse.

So "improvement" is judged by **logic/rules** (calibration recommendations) and ultimately **operator/Karri vibes** (proposals), never by an automated before/after metric comparison with a pass/fail gate.

---

## 4. Are the tables populated, or empty shells? — MOSTLY POPULATED (live, recent)

Live counts (nexus-pg-rw, 2026-06-15; data current to 2026-06-14 22:00):

| Table | Rows | Note |
|---|---|---|
| simulated_orders (closed) | 209 | the trade ground truth |
| engine_scores | 26,334 | flowing daily; `outcome` 21,975 filled, `correct` 21,544 filled, **`pnl` only 642 (2.4%)** → pnlContribution metric is largely empty |
| department_scores | 776 | populated |
| firm_memory postmortems | 1,185 | populated (postmortem pipeline is alive) |
| calibration_log | 1,337 | populated; **158 applied**; modes seen: RECOMMEND_ONLY, SAFE_AUTO_APPLY, APPLY → autotune HAS fired |
| signal_scorecards | **4** | effectively empty (flag default OFF) |
| shadow_forward_test | (flag OFF) | not used for version compare |
| strategies | 8 | **all version=1** |

**Per-strategy closed-trade counts (the killer for objectivity):**
- (null/legacy) 86, xau-volatility-expansion 44, xau-session-breakout 23, xau-fvg 20, xau-mean-reversion 16, xau-scalp-overlap 7, xau-orb 5, xau-trend-following 5, oanda_backfill 3.

Even the busiest strategy has 44 closed trades total. Win-rate / profit-factor / expectancy on n=5..44 are noise. `result_r` (needed for R:R and Sharpe) is **NULL on whole strategies** (fvg 0/20, mean-reversion 0/16, trend-following 0/5) — so the R-based metrics silently return 0/null for those.

So: pipelines are real and live (good — this is NOT a Potemkin system), but the **evaluation substrate is too thin per strategy** and the **version-comparison substrate does not exist at all**.

---

## Bottom line

- The firm has genuine, live observability and a real (engine/session-level) calibration loop.
- It does NOT have an objective per-strategy scorecard (scattered + a wrong profit-factor formula in the per-strategy endpoint).
- It CANNOT compare strategy version N vs N-1 on metrics with an accept/reject threshold — there is no versioning event, no comparison code, no gate. "Better than last week" is answerable only as a noisy global number, never as a controlled version delta.
- Spread/slippage sensitivity is reserved-but-unbuilt; volatility-bucketed performance exists only as a regime proxy.

### Recommended fixes (for the operator/Karri, not yet implemented)
1. One canonical `GET /strategies/:id/scorecard` computing ALL required metrics with ONE correct profit-factor definition (grossProfit/grossLoss), reused by compare + detail. Kill the avgWin/avgLoss "profit factor" in strategies.ts:320.
2. Write a `strategy_version_metrics` snapshot on every config change (bump `strategies.version`), so version deltas become queryable.
3. A real accept/reject gate: define minimum-n + metric thresholds; until n is reached, label "insufficient data" instead of rendering noisy ratios.
4. Backfill `result_r` + `engine_scores.pnl` for strategies currently NULL, or the R/Sharpe/pnlContribution metrics stay dark.
5. Add volatility-bucketed (ATR-tertile) and spread-bucketed win-rate; `atr_at_entry` and `spread_at_entry` columns already exist.
