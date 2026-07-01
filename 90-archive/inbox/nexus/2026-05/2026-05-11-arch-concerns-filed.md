---
tags: [nexus, ops, architecture, concerns, audit, 2026-05-11]
date: 2026-05-11
session: architecture-concern-hunt
---

# Architecture concerns from 2026-05-11 audit — filed

## What was filed

5 systemic concerns surfaced during the architecture-concern-hunt round were filed as docs in the repo. 1 is strategy-domain (Karri review), 4 are ops-domain (operator-call). All are doc-only — no code changes, no push.

### Strategy proposal (Karri)

1. **`docs/strategy/proposals/2026-05-11_processed_signals_persistence.md`** — `processedSignalIds` in-memory only → duplicate-trade risk on worker restart. Filed as strategy because duplicate live trades = position-management strategy decision (sized off duplicate fresh state, bypasses dailyLossLimit check). Two-step proposal (persist + rehydrate, then alert-on-dupes). Includes 5 reviewer questions for Karri on mark-before vs mark-after, rehydration window, idempotency key, etc.

### Ops concerns

2. **`docs/ops/concerns/2026-05-11_inmemory_cleanup_timers.md`** — `lastRetentionRunDate` + `lastMemoryCleanupDate` reset on restart. Cleanups re-run; idempotent; trivial DB load. LOW severity. Option-A fix = persist to `firm_state`. No money impact.
3. **`docs/ops/concerns/2026-05-11_firm_state_upsert_race.md`** — `firm_state` upsert pattern has no version column / advisory lock. Today single-threaded so latent. Real race surface = Railway flapping deploys + foundation-monitor cooldown / operator-brief delivery. MED. Lean fix: advisory lock on the two compare-and-update sites.
4. **`docs/ops/concerns/2026-05-11_discord_webhook_stall.md`** — 5s timeout on synchronous Discord webhook POSTs can stall cycle in Discord-outage scenarios. MED. Lean fix: fire-and-forget wrapper with 2s timeout + instrument `webhook_post_duration_ms`. Layer 2 (queue+backoff) deferred.
5. **`docs/ops/concerns/2026-05-11_pg_client_outdated.md`** — `pg ^8.12.0` is 11mo old; advisories + idle-conn issue on Railway. MED. Two-step: bump within 8.x, then add `idleTimeoutMillis: 30_000` on Pool construction.

## Karri Discord send status: HELD

Current time: 17:48 UTC (19:48 CEST). Work-hours auto-send window is 07-15 UTC. **Outside window** — held per `feedback_auto_send_karri.md` rule "outside work hours: hold + send next morning".

Action item for me: send `processed_signals_persistence` to Karri next morning (~07-08 UTC tomorrow 2026-05-12) using the 8-section embed structure from `reference_strategy_reviewer.md`. Webhook URL on file.

## Commit

Single commit, doc-only:
```
docs(ops+strategy): file 5 architecture-level concerns from 2026-05-11 audit
```

SHA: see commit log after run.

## Why these were filed vs implemented

Per operator-prinsipp #4 (foundation-først) and Karri-review protocol: anything with money-impact goes through proposal flow first. Concern #1 has money-impact (duplicate trades) → Karri. Concerns #2-5 are pure infra/observability/security → ops/concerns (operator-call). No implementation until operator green-lights individually.

## Open questions for next session

- Run the audit query `SELECT signal_id, COUNT(*) FROM trades WHERE created_at > NOW() - INTERVAL '30 days' GROUP BY signal_id HAVING COUNT(*) > 1` to measure whether duplicate-trade incidents have actually happened. Result will sharpen concern #1's severity claim.
- Operator decision on whether to bundle ops concerns #2-5 into a single "infra hardening" sprint or stagger them.
- Karri questions in concern #1 should be addressed before any implementation begins.
