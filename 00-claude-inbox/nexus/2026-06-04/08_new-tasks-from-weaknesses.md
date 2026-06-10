# New tasks from self-reported weaknesses + readiness — Nexus XAUUSD

Author: ai-1 (Claude) · 2026-06-04 · Repo: /home/nithu/code/ai-assistent
Source data: `data/pull/{weaknesses,readiness,risk_snapshot,strategy_states}.json` (pulled 2026-06-04 16:17Z)
Cross-ref: ai-2 reports 2026-06-03 (active-learning, backtest-capability, intent-vs-execution); `docs/ops/known-failures.md`; `docs/ops/phase-status.md`; recent commits through `8ddb445`.

Mandate: turn the system's self-reported weaknesses into a deduplicated NEW-task list, after reality-checking each against current code. Do NOT re-list items already fixed, already captured by ai-2, or already tracked in known-failures.

---

## Reality-check summary (what the self-audit got WRONG)

The `/explorer/weaknesses` endpoint (`apps/api/src/routes/explorer.ts:185-264`) hardcodes several "weaknesses" unconditionally and queries **legacy tables the firm/TIER-3 path no longer writes to**. Several reported items are now stale or false:

| Self-reported weakness | Reality | Verdict |
|---|---|---|
| "No slippage model in paper execution" (explorer.ts:254) | `paper-execution.service.ts:31-105` has a session-based slippage model (+volatility adj) | **FALSE — stale hardcode** |
| "No spread model" (explorer.ts:255) | Same file has session spread model; also a `spread-gate/` module exists | **FALSE — stale hardcode** |
| "No historical bar replay for backtesting" (explorer.ts:246) | Commit `37e3da8` repointed ORB runner to `ohlcv_candles` + added `scripts/backfill-backtest-m1.mjs` | **PARTIALLY FALSE** (ORB replay works now; other strategies still can't — ai-2 covered) |
| "No bots running — platform is idle" (explorer.ts:262) | Queries legacy `bots` table (status='running'); firm runs via cycle, not legacy bots. readiness.json freshness shows market/risk/portfolio topics flowing 149-153s ago | **MISLEADING — wrong table** |
| "Last signal is 1522 min old" (explorer.ts:214) | Queries legacy `signals` table; firm publishes to blackboard topics, not `signals` | **MISLEADING — wrong table** |

This meta-bug (a self-audit endpoint that reports false weaknesses + reads dead tables) is the single most important NEW finding — it actively misleads operator trust judgments. Captured as task #1.

Genuinely-real reported items kept: Polygon backup feed, QStash queue, single-worker/single-DB redundancy, demo-mode transparency, ~10-min SL check granularity, sub-agent status labels.

NEW findings NOT in any self-report and NOT in ai-2 reports:
- **Corrupted avgR/expectancy** in `risk-snapshot.json` (avgR=6.233 with 31.7% WR + buckets dominated by -1R losers — mathematically impossible). `result_r` outlier not clamped (task #2).
- **Blackboard freshness gaps** in readiness.json: `xauusd.event.policy` last-seen 2026-04-24 (~40d stale) despite being published in `managers.ts:435`; `xauusd.manager.decisions` 25h stale. No alerting fires (task #3).

---

## Prioritized NEW task list

### 1. Fix the self-audit endpoint — stop reporting false weaknesses + reading dead tables
- **Why it matters:** `/explorer/weaknesses` is operator's trust dashboard. It currently lies: claims no slippage/spread model (both exist), claims no bar replay (ORB replay landed), and reports "no bots / stale signals" by querying legacy `bots`+`signals` tables the firm path abandoned. This undermines every readiness judgment built on it.
- **Effort:** M
- **Lane:** Claude-infra-safe (read-side correctness, no trade behaviour)
- **Proposal drafted?** No
- **Files:** `apps/api/src/routes/explorer.ts:214,246,254,255,258-263`
- **Fix:** gate slippage/spread/backtest items on actual capability detection (or remove); repoint bot/signal-freshness to firm cycle/blackboard freshness (same source readiness.json uses), not legacy `bots`/`signals`.

### 2. Clamp/guard avgR + expectancy against degenerate result_r outliers
- **Why it matters:** risk-snapshot reports avgR=+6.233 and expectancy=+6.233R for a 31.7%-WR book whose histogram is dominated by -1R losers — internally inconsistent, so a single corrupted `result_r` (near-zero risk denominator the `3191016` guard missed) is dragging the mean. A falsely-positive expectancy is exactly the metric a live-flip decision keys on.
- **Effort:** S
- **Lane:** Claude-infra-safe (analytics correctness) — but the *threshold* of what counts as outlier is borderline; flag to Karri if it changes go-live gating.
- **Proposal drafted?** No
- **Files:** `apps/api/src/routes/risk-snapshot.ts:319-323,487` (avgR = totalR/n with no clamp); consider winsorizing or excluding |r|>N when computing avgR/expectancy, and surface an "outliers excluded: k" note.

### 3. Blackboard freshness alerting + investigate event-policy staleness
- **Why it matters:** readiness.json freshness shows `xauusd.event.policy` ~40 days stale and `xauusd.manager.decisions` 25h stale, yet event-policy is published every cycle (`managers.ts:435`). Either the publish path isn't firing in the current firm cycle or the probe reads a stale persisted snapshot. No alert fires — a dead analysis topic is invisible. Stale event-policy = news-blackout gating may be operating on 40-day-old state.
- **Effort:** M
- **Lane:** Claude-infra-safe (observability + bug investigation)
- **Proposal drafted?** No
- **Files:** `apps/worker/src/firm/managers.ts:432-438` (publisher), `apps/api/src/routes/*readiness*` (freshness probe). Add a "topic stale > threshold" line to morning digest.

### 4. Add Polygon backup market-data feed (single-point-of-failure on Twelve Data)
- **Why it matters:** real, confirmed (explorer.ts:190). If the primary feed fails, all strategies stop on stale candles. trustImpact: high. Currently 14/20 providers connected (readiness.json).
- **Effort:** M
- **Lane:** operator-action (add `POLYGON_API_KEY` in Integration Hub) + Claude-infra (wire fallback in market-data.service)
- **Proposal drafted?** No

### 5. Enable Railway Postgres backups (no DB backup = total history loss on failure)
- **Why it matters:** single Postgres instance, no backup/replica (explorer.ts:245). All training data + trade history is unrecoverable on DB failure. Pure infra-hygiene, cheap insurance before any live-capital flip.
- **Effort:** S
- **Lane:** operator-action (Railway dashboard — enable backups / add replica)
- **Proposal drafted?** No

### 6. Document the learning-loop + calibration env flags (under-documented load-bearing gates)
- **Why it matters:** ai-2 flagged that `feature-flags.md` documents only 2 flags while `AGENT_LESSONS_ENABLED`, `LESSON_DERIVATION_ENABLED`, `LESSON_INJECTION_ENABLED`, `CALIBRATION_MODE` are all absent despite being the gates that keep learning dark. NEW angle vs ai-2: scope strictly to the *doc* deliverable (ai-2 bundled it into a larger reactivation plan). The doc itself is zero-risk and unblocks the Karri proposal.
- **Effort:** S
- **Lane:** Claude-infra-safe (docs only)
- **Proposal drafted?** No
- **Files:** `docs/ref/feature-flags.md` (+ calibration-mode hardcode note re orchestrator.ts:696)

### 7. Add QStash (or in-process) retry-with-backoff for failed jobs
- **Why it matters:** real (explorer.ts:192). Failed jobs currently aren't retried with backoff — fragile orchestration. Lower priority than data-feed redundancy but a genuine reliability gap.
- **Effort:** M
- **Lane:** operator-action (add `QSTASH_TOKEN`) + Claude-infra (retry wiring), OR Claude-only if implemented as in-process backoff without the paid service.
- **Proposal drafted?** No

### 8. Hard max-units / max-notional circuit-breaker in placeOandaOrder
- **Why it matters:** ai-2's intent-vs-execution audit (recommended follow-up) showed the tight-SL × %risk × real-balance amplification vector that caused the Apr-21 ~106-unit blowup is *structurally intact* — only risk% was lowered. A param-level circuit breaker (reject if units > N × baseline) would catch a future re-trigger regardless of the formula. NEW as a discrete task (ai-2 listed it as a recommendation, not a tracked item).
- **Effort:** M
- **Lane:** Karri-strategy (money-near risk guard — needs proposal + review)
- **Proposal drafted?** No — should be filed in `docs/strategy/proposals/`

---

## Lower-priority / kept-but-deferred (real, but not top-8)

- **Single-worker redundancy** (explorer.ts:244) — operator-action, Railway scale; defer until live-capital.
- **Sub-agent status = role label, not live health** (transparency item) — UI honesty fix, S, Claude-infra; cosmetic.
- **~10-min SL/TP check granularity** (transparency item) — real gap-through risk; but increasing cycle frequency is money-near tuning → Karri. Note for live-flip readiness, not now.
- **Demo-mode PnL realism** (transparency) — inherent to demo; resolves on its own at live-flip + now partially mitigated by the slippage/spread model that already exists (#1 reality-check).

## Explicitly NOT re-listed (already covered)

- Generic strategy backtest/replay refactor → ai-2 backtest-capability report (Phase 0/1/2 plan).
- Learning-loop reactivation (derive/inject/calibrate flags) → ai-2 active-learning-plan (A-D activations).
- agent_lessons dead loop → `known-failures.md` (3-dead-point entry, reconciled 2026-06-01).
- strategy_id/desk NULL attribution → `known-failures.md` + fixed in `1dd9d6a`.
- Paper-path size recompute divergence (R1) + ghost-position window (R2) + no size-fidelity test (R3) → ai-2 intent-vs-execution report.
