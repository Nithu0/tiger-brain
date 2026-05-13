---
date: 2026-05-13
type: audit
project: nexus
status: open
---

# Blackboard health audit — 2026-05-13

Read-only investigation of `blackboard` pub-sub table. Cadence per topic = component liveness proxy.

## Headline

- **Table size**: 343 MB (33 distinct topics).
- **Retention**: 0 rows older than 30 days → TTL is in fact pruning, despite memory note that `RETENTION_ENABLED` default OFF. `xauusd.retention.report` has 50 lifetime rows + ran last at 09:35 UTC today, so retention pass IS running in this env.
- **Active 24h**: 27 topics with traffic; ~709 cycles in 24h (approx 1 cycle / 122s).
- **Silent expected topics** (in `docs/ref/blackboard-topics.md` but 0 rows lifetime): 11.
- **Stale-but-published** (>7d): only `xauusd.event.policy` (18d 12h staleness, 3089 rows lifetime).

## 1. Top 24h cadence

| Topic | n | last |
|---|---:|---|
| xauusd.signal.rejected | 3208 | 11:22Z |
| xauusd.market.raw | 1418 | 11:22Z |
| xauusd.market.events | 1418 | 11:22Z |
| xauusd.breakout-continuation.state | 709 | 11:22Z |
| xauusd.macro.fred | 709 | 11:22Z |
| xauusd.analysis.{macro,risk,technical} | 709 ea | 11:22Z |
| xauusd.market.execution_conditions | 709 | 11:22Z |
| xauusd.portfolio.context | 709 | 11:22Z |
| xauusd.pullback-continuation.state | 709 | 11:22Z |
| xauusd.session-break.state | 709 | 11:22Z |
| xauusd.trend-following.state | 709 | 11:22Z |
| xauusd.vol-expansion.state | 709 | 11:22Z |
| xauusd.mean-reversion.state | 367 | 11:22Z (first row 00:44 today — recently turned on?) |
| xauusd.risk.advisory | 232 | 11:21Z |
| xauusd.narrative.dominant | 47 | 11:22Z |
| xauusd.retention.report | 26 | 09:35Z |
| xauusd.market_research.summary | 15 | 10:18Z |
| xauusd.manager.decisions | 11 | 12.5 17:44Z |
| xauusd.session-break.signal | 9 | 12.5 18:01Z |
| xauusd.vol-expansion.signal | 8 | 12.5 17:44Z |
| xauusd.postmortem.reports | 4 | 12.5 19:57Z |
| xauusd.execution.reports | 3 | 12.5 17:35Z |
| xauusd.breakout-continuation.signal | 2 | 12.5 16:01Z |
| xauusd.journal.daily | 1 | 12.5 22:10Z |
| xauusd.position.events | 1 | 12.5 17:42Z |

## 2. Stale-but-historically-published (>7d)

| Topic | lifetime n | last_seen | staleness |
|---|---:|---|---|
| `xauusd.event.policy` | 3089 | 2026-04-24 22:26Z | **18d 12h** |

Only one. `xauusd.event.policy` is listed as expected in `docs/ref/blackboard-topics.md` — high-impact news state. Publisher hasn't fired in 18 days; either event-policy module disabled, or news pipeline dead.

## 3. Expected topics with 0 rows EVER (silent components)

Cross-referenced against `docs/ref/blackboard-topics.md`. Topic appears in doc but never in DB:

- `xauusd.macro.events` — macro-event firm-agent (env-gated)
- `xauusd.cio.review` — CIO advisory (doc notes advisory-only, no consumers)
- `xauusd.operator.brief` — operator-brief agent (doc: Discord delivery direct, not topic)
- `xauusd.challenge.bear`, `xauusd.challenge.timing`, `xauusd.challenge.no_trade` — challenge agents
- `xauusd.manager.requests` — Prism/Blade fan-out (advisory-only)
- `xauusd.analysis.news` — analyst interpretation (doc lists `news` as expected)
- `xauusd.analysis.structure` — consumer-only per doc (confirmed)
- `xauusd.analysis.technical.{trend,momentum,meanrev}` — env-gated `SPLIT_TECHNICAL_SIGNALS=true`, presumed OFF
- `xauusd.position.opened`, `xauusd.position.closed` — lifecycle events on AUDIT_ALLOWLIST -> never written? Suspicious; orchestrator allowlist suggests these SHOULD fire on opens/closes
- `xauusd.execution.fills` — per-fill audit events; on AUDIT_ALLOWLIST -> also never written
- `xauusd.portfolio.exposure_check` — Forge sizing decisions; consumed by `cio/review.ts:113` + operator-readiness probe -> consumers see nothing

**Most concerning of the silent set**:
- `xauusd.position.{opened,closed}` + `xauusd.execution.fills` — these are on the orchestrator AUDIT_ALLOWLIST (lines 64-66) yet 0 lifetime rows. Either never wired up to publish, OR all writes go through `xauusd.execution.reports` (3 rows in 24h) + `xauusd.position.events` (1 row in 24h) and the lifecycle topics are simply dead naming.
- `xauusd.portfolio.exposure_check` — operator-readiness `topicProbe` is checking a topic that has NEVER been published. Probe at `apps/api/routes/operator-readiness.ts:352` is presumably always returning stale.

## 4. Undocumented topics observed in DB (not in `docs/ref/blackboard-topics.md`)

- `xauusd.breakout-continuation.{signal,state}` — TIER-3 module not enumerated in doc
- `xauusd.pullback-continuation.state` — same
- `xauusd.trend-following.state` — same
- `xauusd.mean-reversion.state` — same (first row 2026-05-13 00:44Z — recently turned on)
- `xauusd.signal.rejected` — high-volume rejection topic (3208 rows/24h), not documented
- `xauusd.research.quota_paused` — last 2026-05-11 13:50Z, 2 rows lifetime

Action: update `docs/ref/blackboard-topics.md` to enumerate the new TIER-3 strategy modules + `xauusd.signal.rejected` + `xauusd.research.quota_paused`.

## 5. Retention / TTL state

- 0 rows older than 30 days. `MIN(timestamp)` over the >30d filter is NULL.
- `xauusd.retention.report` had 26 publishes in last 24h + ran most recent at 09:35Z. Retention is ACTIVE in this env.
- Memory note `firehose_phase_a_b_landed.md` claims `RETENTION_ENABLED` default OFF — either that note is out-of-date, or the env has `RETENTION_ENABLED=true` flipped on prod. Worth confirming.

## 6. Size

`pg_total_relation_size('blackboard')` = **343 MB**.

For approx 700 cycles/day across ~15 high-cadence topics that fits a ~30-day retention window. Not concerning for now; track week-over-week.

## 7. Recommendations (REPORT-only, per operator principle #1)

1. **Confirm `xauusd.event.policy` publisher**: 18d silence with 3089 lifetime rows means it WAS active recently. Grep code for the publisher; either re-enable or strike from doc.
2. **Resolve `xauusd.position.{opened,closed}` / `xauusd.execution.fills` discrepancy**: doc says they're on audit allowlist, DB says zero writes. Either publishers were never wired or topics renamed mid-stream. Inspect `firm/orchestrator.ts:64-66` callers.
3. **Update `docs/ref/blackboard-topics.md`** to document `signal.rejected`, `research.quota_paused`, and 4 new TIER-3 strategy state topics (breakout-continuation, pullback-continuation, trend-following, mean-reversion).
4. **Verify `RETENTION_ENABLED` actual env state** vs memory note (config drift).
5. **`xauusd.portfolio.exposure_check` consumer expects no data** — operator-readiness probe at 300/900s thresholds will perpetually flag stale; either publisher needs wiring or probe should be removed.

## Queries used

```sql
-- column is `timestamp` not `created_at`
SELECT topic, COUNT(*), MIN(timestamp), MAX(timestamp)
FROM blackboard WHERE timestamp > NOW() - INTERVAL '24 hours'
GROUP BY 1 ORDER BY 2 DESC;

SELECT topic, COUNT(*), MAX(timestamp), NOW() - MAX(timestamp) AS staleness
FROM blackboard GROUP BY 1 ORDER BY MAX(timestamp) DESC;

SELECT MIN(timestamp), COUNT(*) FROM blackboard
WHERE timestamp < NOW() - INTERVAL '30 days';

SELECT pg_size_pretty(pg_total_relation_size('blackboard'));
```
