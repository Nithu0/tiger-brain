# Perf indexes — jobs + simulated_orders (2026-05-11)

## TL;DR

Per perf-audit 2026-05-11. Added two hot-path indexes to `DB_MIGRATIONS` in `packages/shared/src/db/schema.ts`. Idempotent (IF NOT EXISTS). All 428 worker tests still green. tsc clean across shared + worker.

## State before

```sql
SELECT indexname FROM pg_indexes WHERE tablename='jobs';
-- jobs_pkey   (only the primary key)
```

`pg_stat_user_tables` row estimates:

| table             | rows   |
| ----------------- | -----: |
| jobs              | 21 206 |
| blackboard        | 81 351 |
| simulated_orders  |    147 |
| agent_tasks       |     79 |
| signals           |     31 |

## Indexes added

### 1. `idx_jobs_status_queue` ON `jobs(status, queue, queued_at DESC)`

**Why**: 21k-row table had ONLY a pkey on `id`. Every read pattern in the codebase was forced into a seq scan:
- `apps/api/src/routes/jobs.ts` — `FROM jobs ORDER BY queued_at DESC LIMIT 50`
- `apps/api/src/routes/explorer.ts:222` — `WHERE status='failed' AND finished_at > NOW()-INTERVAL '1 hour'`
- `apps/api/src/routes/explorer.ts:354` — `WHERE queued_at > NOW()-INTERVAL '1 hour' GROUP BY status`
- `apps/api/src/routes/desks.ts:71` — `WHERE status='failed' ORDER BY finished_at DESC LIMIT 5`
- `apps/api/src/routes/metrics.ts:47` — `FROM jobs ORDER BY queued_at DESC LIMIT 20`

**Estimated speedup**: seq scan of 21k rows → index range scan. Roughly 30–50 ms/cycle saved across all the dashboards + the `/metrics` endpoint per audit estimate. Real impact compounds because `/jobs`, `/metrics`, `/explorer` get hit by the dashboard every ~10s.

**Hot UPDATEs (`SET status='processing' WHERE id=$1`) are already pkey-served** — no regression on the worker write path.

### 2. `idx_sim_orders_closed` ON `simulated_orders(closed_at DESC) WHERE status='closed'`

**Why**: `WHERE status='closed' AND closed_at > X` is the most repeated read pattern in the worker. Hits at:
- `firm/demo-mode.ts:47` (drawdown gate)
- `firm/exposure/drawdown.ts:53,66`
- `firm/postmortem-hook.ts:84`
- `firm/status-report.ts:181,257`
- `firm/strategy-execution.ts:163`
- `firm/agent-bus/firm-agents/strategy-tuner.ts:59`
- `firm/agent-bus/firm-agents/operator-brief.ts:67`
- `firm/agent-bus/agent-trigger.ts:87,119`
- `firm/firm-epoch.ts:90` (comment claims index existed — it did NOT)
- `agents/trading-manager.agent.ts:94` (legacy, retired but still referenced)

Existing indexes only covered:
- `idx_sim_orders_open` — open trades (partial WHERE status='open')
- `idx_simulated_orders_postmortem_pending` — closed + postmortem pending only

Neither helps the bulk "closed in last N hours" reads.

**Estimated speedup**: small in absolute ms (147 rows total today), but ratio compounds as table grows; this is the index the codebase has been *assuming* exists. Per `firm-epoch.ts:90` comment.

## Other tables checked — already optimal

- **`agent_tasks`** — `idx_agent_tasks_status` partial on (status, priority DESC, created_at) WHERE status IN ('queued','in_progress'). Queue-polling already covered.
- **`blackboard`** — `idx_blackboard_topic` on (topic, "timestamp" DESC) + `idx_blackboard_symbol`. Covers `WHERE topic=X AND timestamp > Y`. (Column is `timestamp`, not `created_at` — audit prompt had a minor naming drift.)
- **`signals`** — 31 rows. No index needed; ORDER BY created_at DESC LIMIT 1 against 31 rows is free.

## Verification

- `cd packages/shared && npx tsc --noEmit` — clean
- `cd apps/worker && npx tsc --noEmit` — clean
- `cd apps/worker && npm test` — 428 pass / 0 fail
- Migration is idempotent (`CREATE INDEX IF NOT EXISTS`) — safe to re-run.

## Deployment

`DB_MIGRATIONS` runs at startup in both API and worker (see `apps/worker/src/index.ts:47–49`):

```ts
for (const sql of DB_MIGRATIONS) {
  await db.query(sql);
}
console.log("DB migrations complete");
```

Railway will run these automatically on the next deploy of either service. No manual DDL needed. **First boot after deploy will take a few extra seconds** because `CREATE INDEX` (non-concurrent) on the 21k-row `jobs` table will hold a brief write lock — for a 21k-row table this is sub-second in practice.

If operator wants zero downtime, can manually run `CREATE INDEX CONCURRENTLY idx_jobs_status_queue ...` on the live DB before deploy — but for this table size it's unnecessary.

## Commit

See git log; touched only `packages/shared/src/db/schema.ts` (lines added at end of `DB_MIGRATIONS` array).

DO NOT push — awaiting operator review.
