---
tags: [nexus, ops, retention, ttl, database]
type: atomic
created: 2026-05-11
---

# Retention-Policy

Canonical living doc for Nexus database retention. Source code: `apps/worker/src/firm/retention.ts`. Reference doc in-repo: `docs/ref/retention.md`.

## Why this exists

Four tables grow unbounded:

- `blackboard` — every fact/interpretation/decision/postmortem (~342 MB as of 11.5)
- `sentiment_snapshots` — sentiment fetches (~142 MB)
- `jobs` — BullMQ-style lifecycle (~21k rows)
- `trade_strategy_snapshots` — per-cycle strategy snapshot for retrospective queries (~17k rows)

Without TTL, Railway Postgres storage climbs forever. With TTL, steady-state is bounded.

## Policy

| Table | Subset | TTL | Permanent? |
|---|---|---|---|
| `blackboard` | volume topics (`xauusd.market.raw`, `xauusd.market.events`, `xauusd.macro.fred`) | 30d | no |
| `blackboard` | audit allowlist (decisions, executions, positions, postmortems, event policy, daily journal) | — | **yes** |
| `blackboard` | everything else (analysis, manager.synthesis, strategy *.state, advisory-only) | 90d | no |
| `sentiment_snapshots` | all | 30d | no |
| `jobs` | `status='done'` | 7d | no |
| `jobs` | `status='failed'` | 30d | no |
| `jobs` | pending / queued / running | — | **yes** (shouldn't accumulate) |
| `trade_strategy_snapshots` | all | 90d | no |

Audit-grade blackboard topics (the "permanent" row above): `xauusd.manager.decisions`, `xauusd.execution.reports`, `xauusd.execution.fills`, `xauusd.position.opened`, `xauusd.position.closed`, `xauusd.event.policy`, `xauusd.postmortem.reports`, `xauusd.journal.daily`. **NEVER deleted by retention.** Mirrors `BLACKBOARD_AUDIT_ALLOWLIST` in `firm/orchestrator.ts`.

## Schedule

- Runs **once per UTC calendar day** via orchestrator self-check (`lastRetentionRunDate !== todayUtcIso`).
- Gated by `RETENTION_ENABLED=true` (default **false**).
- 6 bounded DELETE queries per pass, all indexed.

## Activation

1. Set `RETENTION_ENABLED=true` on the **Worker** service in Railway (orchestrator lives in worker, not API).
2. First pass fires next orchestrator cycle.
3. Observability: `[firm/retention]` log line + blackboard topic `xauusd.retention.report` (one message per pass with row counts + errors).

Roll back: set `RETENTION_ENABLED=false`. No redeploy.

## Env knobs (all optional)

| Var | Default |
|---|---|
| `RETENTION_BLACKBOARD_VOLUME_DAYS` | 30 |
| `RETENTION_BLACKBOARD_ANALYSIS_DAYS` | 90 |
| `RETENTION_SENTIMENT_DAYS` | 30 |
| `RETENTION_JOBS_DONE_DAYS` | 7 |
| `RETENTION_JOBS_FAILED_DAYS` | 30 |
| `RETENTION_TRADE_STRATEGY_SNAPSHOTS_DAYS` | 90 |

Non-positive / non-numeric values fall back to defaults.

## Failure semantics

- Per-table error isolation — one DELETE failing doesn't block others.
- Errors captured in `RetentionReport.errors[]` + emitted via `logWarn`.
- Retention **never throws** out of the orchestrator cycle.

## Estimated freed storage (steady-state)

- ~200 MB blackboard (volume topics dominate)
- ~50 MB sentiment_snapshots
- small recovery on jobs + trade_strategy_snapshots

## Operator-prinsipper alignment

- [[Operator-Principles]] **prinsipp #2** (data skal aldri stoppes) → TTL only trims old data; no agents/persistence disabled.
- [[Operator-Principles]] **prinsipp #3** (små ryddende justeringer kan være automatiske) → retention is a janitor, not a behaviour change.
- [[Operator-Principles]] **prinsipp #5** ([[OK-Kjor-Gate]]) → Railway flip = operator decision, not Claude's.

## Sync requirement

The audit allowlist exists in three places — keep them in sync:

1. `apps/worker/src/firm/orchestrator.ts` → `BLACKBOARD_AUDIT_ALLOWLIST`
2. `apps/worker/src/firm/retention.ts` → `BLACKBOARD_PERMANENT_TOPICS`
3. `docs/ref/blackboard-topics.md` (canonical doc)

Test `topic constants: audit-grade allowlist matches blackboard-topics.md set` will fail if (2) drifts from the canonical set.

## Related

- [[Operator-Principles]]
- [[OK-Kjor-Gate]]
- `docs/ref/retention.md` (in-repo reference)
- `docs/ref/blackboard-topics.md` (topic registry)
- `docs/ref/feature-flags.md` (env-var table)
