# Nexus full-state audit — 2026-05-11

Read-only sweep of production Postgres + `/health`. Source: `mcp__nexus-pg__query` (read-only role) + `curl https://api-production-b660.up.railway.app/health` (unauth). `/diagnostic/broker` and `/operator/*` require Bearer token (not accessible from this thread).

Time of audit: 2026-05-11 12:23Z. Today is sunday — London/NY pre-open data only.

---

## TL;DR per subsystem

| Subsystem | Status | One-liner |
|---|---|---|
| Trading loop core | 🟡 | Cycle running (cycleNo=7, 7s), but `simulated_orders.strategy_id` and conviction-/regime-stamping all NULL on every order — metadata layer broken |
| Agent bus | 🔴 | Only 2 departments active (`research`, `journaling`). Review-queue avg claim latency = 24h (max 70h). Discord delivery 0/49 artifacts in 7d |
| Data ingestion | 🟢 | `xauusd.market.raw` 21s old, all `analysis.*` topics firing on every cycle. `news`/`sentiment` topics absent on the blackboard but live in their own tables |
| Persistence / cleanup | 🟡 | DB 576 MB. `blackboard` 81k rows (342 MB), `sentiment_snapshots` 142 MB — no TTL evidence. Growth is bounded by activity, but no retention job visible |
| Health endpoints | 🟢 | `/health` all-green: db 4ms, broker demo 92ms, balance 92245, recon driftCountUnresolved=0 |
| Latency hot spots | 🔴 | Review-queue tasks idle 5-70h before claim; researcher runs are fine (~20s) |

---

## 1. Trading loop core

| Metric | Value | Status | Evidence |
|---|---|---|---|
| simulated_orders 24h | 4 (1 open, 3 closed) | 🟢 | last opened 10:15Z, last closed 11:23Z |
| simulated_orders 7d | 31 closed, PnL **-832.86** USD | 🟡 | wins 13 / losses 18 |
| `strategy_id` populated | **0/31 (NULL)** | 🔴 | Every order has `strategy_id=NULL`, `desk=NULL`, `execution_source=NULL`, `regime_at_entry=NULL` |
| `decision_cycle_id` populated | 31/31 | 🟢 | OK |
| Conviction stamping (`thesis_quality_score`, `conviction_total`, `entry_conviction_score`) | **0/31** | 🔴 | All NULL in 7d sample |
| ORB metadata (`orb_range_id`, `orb_metadata`) | 0/31 | 🔴 | Even on ORB-fired trades |
| signals 7d (firm-strategy topic) | 31 (vol-exp 23, session-break 6, orb 2) | 🟢 | vol-expansion clearly dominant |
| `gate_decisions` 24h | 16 rows, 4 unique events | 🔴 | Was 2.1k/day in April. Now 4 gate-rows per signal only — gate-result writes mostly silenced |
| `blade_decisions` 24h | 4 (all approved) | 🟢 | 3 strategies fired |
| `blade_decisions` 7d daily | 4 → 1 → 9 → 9 → 3 → 8 | 🟢 | Cadence fluctuates but present |
| `postmortems` 24h | 4 | 🟢 | All 4 trades got postmortem |
| `postmortems` 7d split | 17 RIGHT_THESIS_BAD_EXECUTION / 14 CORRECT_THESIS | 🟡 | `cleanliness`, `entry_score`, `execution_score` all NULL — only `market_score` and `summary` populated |
| Close-reason 7d mix | OANDA_SL_TP 20 (-2526), STALE_TRADE_EXIT 9 (+204), reconcile 2 (+1489) | 🔴 | SL/TP losing big; stale-exit modest positive — strategy edge currently negative |
| `worker:heartbeat` | cycleNo=7, dur=7062ms, lastError=null | 🟢 | Fresh |

**Verdict**: cycle is RUNNING but writing crippled metadata. Postmortems + simulated_orders are missing all the high-value per-trade context — that breaks calibration + learning loops downstream.

---

## 2. Agent bus

| Metric | Value | Status |
|---|---|---|
| `agent_tasks` 24h split | research 4 done / review 4 done + 1 in_progress | 🟡 |
| `agent_tasks` 7d departments | only **journaling + research** | 🔴 |
| Research drainer | last_run 12:19Z, latency ~20s | 🟢 |
| Review queue (claude-opus, journaling) | **avg claim latency 85,920 s (24h), max 252,955 s (70h)** | 🔴 |
| Research queue claim latency | avg 616s, max 7258s | 🟡 (above SLA but functional) |
| `agent_results` 24h | 8 total. research cost $0.001, tokens_in 126/out 404 avg | 🟢 (Gemini Flash) |
| `agent_results` review cost | $0.00, tokens_in=0/out=0 | 🟡 (review writes empty token stats — likely metadata-only ack) |
| `agent_artifacts` 24h | 8 attached | 🟢 |
| `agent_artifacts.discord_delivery_status` 7d | **0 delivered / 49 NULL** | 🔴 known double-gate (`DISCORD_LEGACY_ENABLED` likely off) |
| Firm-agent last-runs | risk-advisor 12:19Z, regression-predictor 12:15Z, narrative 12:08Z, market-research 12:08Z, trade-critic 11:57Z | 🟢 |
| daily-journal last_run | **2026-05-09 23:29Z** (2 days stale) | 🔴 |
| `agent_lessons` total | **0 rows** | 🟡 (firehose Phase B landed but dormant — known) |
| `agent_knowledge` total | 0 rows | 🟡 |
| Silent agents | postmortem-critic, calibration-writer, anything outside the 5 active firm-agents | 🔴 |

**Verdict**: bus skeleton runs, but the review-loop is essentially dead (Opus worker `atlas-2474-mp0zidi8` claims in bursts every ~24h). daily-journal hasn't run for 2 days. Discord delivery has been silently inert for 7+ days.

---

## 3. Data ingestion

| Topic | Last seen | n / 24h | Status |
|---|---|---|---|
| xauusd.market.raw | 21s ago | 884 | 🟢 |
| xauusd.market.events | <1m | 884 | 🟢 |
| xauusd.market.execution_conditions | <1m | 442 | 🟢 |
| xauusd.macro.fred | <1m | 442 | 🟢 |
| xauusd.analysis.technical | <1m | 442 | 🟢 |
| xauusd.analysis.macro | <1m | 442 | 🟢 |
| xauusd.analysis.risk | <1m | 442 | 🟢 |
| xauusd.portfolio.context | <1m | 442 | 🟢 |
| xauusd.scalp/session-break/vol-expansion.state | <1m | 442 each | 🟢 |
| xauusd.risk.advisory | <3m | 150 | 🟢 |
| xauusd.narrative.dominant | 14m | 24 | 🟡 (slow, but agent fires) |
| xauusd.market_research.summary | 4h | 14 | 🟡 |
| xauusd.orb.state | 2h | 28 | 🟢 (state-machine sleeping outside session) |
| xauusd.orb.signal | 2h | 1 | 🟢 |
| xauusd.session-break.signal | 3.5h | 1 | 🟢 |
| xauusd.vol-expansion.signal | 5.6h | 2 | 🟢 |
| xauusd.manager.decisions | 2h | 4 | 🟢 |
| xauusd.postmortem.reports | 1h | 4 | 🟢 |
| xauusd.execution.reports | 2h | 4 | 🟢 |
| xauusd.position.events | 1h | 2 | 🟢 |
| xauusd.analysis.news / .sentiment | — | **0 ever** | 🔴 News + Reddit pipelines write to their own tables but DO NOT publish to blackboard |
| xauusd.analysis.flow / .cot / .calibration | — | 0 | 🔴 Either dormant or not implemented |
| xauusd.regime | — | 0 | 🟡 (regime carried in `xauusd.portfolio.context` and inferred — no canonical topic) |

`engine_scores`: 18,534 rows total, **last write 2026-04-24** — confidence-engine writebacks STOPPED 17 days ago.
`calibration_log`: 342 rows, **last 2026-04-25** — calibration writer dormant.

---

## 4. Persistence + cleanup

| Table | Rows | Size | TTL? | Status |
|---|---|---|---|---|
| blackboard | 81,166 | 342 MB | none visible; 14-day window only | 🟡 grows ~9k/day on weekdays |
| sentiment_snapshots | 10,246 | 142 MB | unknown (no access) | 🟡 14MB/1k — large blobs, may need cap |
| signals | 31 live / 14,188 total | 13 MB | none | 🟡 small but old data retained |
| agent_events | 1,725 | 12 MB | (no read access) | 🟡 |
| analysis_snapshots | 10,228 | 10 MB | (no read access) | 🟡 |
| trade_strategy_snapshots | 17,657 | 8.7 MB | (no read access) | 🟡 |
| bot_runs | 0 | 8.5 MB | bloat from dead rows | 🔴 needs VACUUM FULL |
| engine_scores | 0 live / 18,534 dead | 8.4 MB | writes stopped 24 Apr | 🔴 needs VACUUM + investigation |
| market_snapshots | 10,248 | 6.4 MB | unknown | 🟢 |
| jobs | 21,200 | 6.2 MB | none visible | 🟡 |
| gate_decisions | 16 live / 7,874 total | 4 MB | none | 🟡 |
| reddit_subreddit_snapshots | 14,730 | 3.7 MB | unknown | 🟢 |
| news_headlines | 6,139 | 2.2 MB | unknown | 🟢 |
| firm_memory | 449 (346 postmortem + 102 regime) | n/a | unknown | 🟢 small |
| agent_lessons | **0** | n/a | dormant | 🟡 |
| agent_knowledge | **0** | n/a | dormant | 🟡 |

Total DB: **576 MB**. No table is in actual runaway. Top growth candidates: `blackboard` (~9k rows/active day) and `sentiment_snapshots` (high per-row size).

---

## 5. Health endpoints

`GET /health` (2026-05-11 12:23Z):

```
status: ok
build.commit: f9f92d01
db: ok (4ms)
broker: ok demo (92ms, balance 92245.12, configured)
blackboard: ok (lastMarketRawSec=48, lastDecisionSec=7652)  ← 2.1h since last firm-strategy decision
worker: ok (heartbeat 46s, cycleNo=7, durMs=7062, lastError=null)
reconciliation: ok (drift=0, lastSyncCycle 12:22Z, balanceDelta=13.62)
```

`/diagnostic/broker` and `/operator/readiness` return 401 — Bearer token not available to audit thread (`docs/ref/env-vars.md` references `API_KEY`).

---

## 6. Latency hot spots

| Lane | Avg | Max | Status |
|---|---|---|---|
| Research drainer claim→done | ~20s run / 616s claim-wait | 7258s claim-wait | 🟡 |
| Review (journaling/Opus) claim→done | 34s run / **85,920s claim-wait** | **252,955s** (~70h) | 🔴 |
| Worker cycle | 7062ms | — | 🟢 |
| Broker fetch | 92ms | — | 🟢 |
| DB ping | 4ms | — | 🟢 |
| Blackboard `market.raw` lag | 21-48s | — | 🟢 |

LLM cost (24h proxy from `agent_results`): $0.001 total via Gemini Flash research. Opus review tasks log $0 + 0 tokens — likely a metadata-write gap, NOT actual cost (Opus claims happen, but cost telemetry not flowing into agent_results).

---

## Operator action list

### 🔴 Silent / degraded (TOP 5)

1. **Per-trade metadata stamping broken** — `simulated_orders` has NULL for `strategy_id`, `desk`, `execution_source`, `regime_at_entry`, all conviction/orb scores. Postmortems missing entry/execution scores. Without these, calibration + classification cannot improve.
2. **Review/journaling worker stalls 5-70h between claims** — `atlas-2474-mp0zidi8` only wakes in bursts. SLA way out (default ~1h). Likely the worker daemon is offline or rate-gated; tasks pile and get drained in batches.
3. **Discord delivery silently inert** — 0/49 artifacts delivered. Known issue: `AGENT_DISCORD_DELIVERY_ENABLED=true` alone is inert without `DISCORD_LEGACY_ENABLED=true` (per memory `project_discord_delivery_dual_gate.md`).
4. **engine_scores + calibration_log frozen since 24-25 Apr** — confidence-engine post-trade writebacks and the calibration writer have been silent for 17 days. Postmortem pipeline isn't feeding either.
5. **gate_decisions cadence collapsed from 2100/day to ~12/day** — Either gate writes are gated on a code path that's now rarely entered, or only the 4 gates that ran on signal-evaluation are being written (others are skipped). Cycle gates now invisible to audit. `decision_cycle_id` NULL on every row.

### 🟢 Quick wins (≤1h)

1. **Flip `DISCORD_LEGACY_ENABLED=true` on Railway api+worker** — instantly unblocks 49 pending artifacts + ongoing Discord pings. (Operator-gated.)
2. **Restart / re-deploy the Opus review worker** — atlas-2474 is barely alive; bouncing it should drop journaling latency from 24h→<5m. Check Railway logs for `atlas` service status first.
3. **VACUUM FULL on `bot_runs` and `engine_scores`** — both have 0 live rows but 8MB of dead tuples. Bonus: investigate why engine_scores writes stopped 24 Apr (likely a code-path that was removed in the ORB/firm pivot).

### 📈 Tables to monitor for unbounded growth

| Table | Daily delta | Suggested TTL |
|---|---|---|
| blackboard | ~9k rows/active day, 342 MB total | 30 days for `xauusd.market.raw` + `.events`; 90 days for `analysis.*`, `manager.decisions`, `postmortem.reports`, `execution.reports` |
| sentiment_snapshots | unknown delta, 142 MB | Move blobs to compressed cold storage after 30 days; keep summary fields |
| jobs | 21k rows | TTL: 7 days for completed jobs, 30 days for failed |
| trade_strategy_snapshots | 17k rows, 8.7 MB | 90 days |
| market_snapshots | 10k rows | 60 days |

No table is currently growing unboundedly — but `blackboard` will hit 1 GB by ~July at current rate if no retention is added.

---

## Evidence pointers

- `simulated_orders` NULL-metadata: query `SELECT id, strategy_id, regime_at_entry, entry_conviction_score, thesis_quality_score FROM simulated_orders ORDER BY opened_at DESC LIMIT 10` — all post-2026-05-04 rows.
- Review-queue stall: `SELECT created_at, claimed_at, claimed_by FROM agent_tasks WHERE role='review' ORDER BY created_at DESC LIMIT 20`.
- Discord delivery zero: `SELECT discord_delivery_status, COUNT(*) FROM agent_artifacts WHERE created_at > now()-interval '7 days' GROUP BY 1`.
- engine_scores frozen: `SELECT MAX(created_at) FROM engine_scores` → 2026-04-24.
- gate_decisions collapse: `SELECT date_trunc('day', recorded_at), COUNT(*) FROM gate_decisions WHERE recorded_at > now()-interval '30 days' GROUP BY 1 ORDER BY 1 DESC` — 2.5k/day → 16/day.

End of audit.
