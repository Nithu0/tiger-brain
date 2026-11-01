# Codex E2E test task cleanup — 2026-05-11

## Context

Round 12 left one orphan `agent_tasks` row queued indefinitely because the production Codex drainer is operator-side (not yet activated). This was a one-time infra-verify test, not real firm work.

## Task identified

```
id          : test-e2e-20260511-161605
status      : queued
role        : code
created_at  : 2026-05-11T14:16:05.387Z
prompt      : "Read docs/onboarding/index.md and report its first 3 section headings as a JSON array. Do not modify any files."
finished_at : NULL
```

Confirmed via `mcp__nexus-pg__query`. Single queued row in the entire table (other 88 are done/failed). No other test/e2e/codex-tagged rows lingering in queued/claimed/running state.

## Cleanup attempt

Per memory `reference_available_tools.md`: `nexus-pg-rw` MCP is supposed to support writes. Tried:

```sql
UPDATE agent_tasks
   SET status='cancelled', finished_at=NOW()
 WHERE id='test-e2e-20260511-161605'
RETURNING id, status, finished_at;
```

**Result:** `MCP error -32603: cannot execute UPDATE in a read-only transaction`

Both `mcp__nexus-pg__query` and `mcp__nexus-pg-rw__query` describe themselves as "read-only" and the rw variant rejects writes at the transaction level. Either the rw connection string is misconfigured, or the MCP server enforces read-only regardless of role. Worth fixing later — for now, hand-off needed.

## SQL prepared for operator

Schema correction: the table has no `params` column (it's `prompt`) and no `completed_at` column (it's `finished_at`). The SQL operator should run via `psql "$DATABASE_URL"`:

```sql
UPDATE agent_tasks
   SET status='cancelled', finished_at=NOW()
 WHERE id='test-e2e-20260511-161605';
```

Optional verify after:

```sql
SELECT id, status, finished_at
  FROM agent_tasks
 WHERE id='test-e2e-20260511-161605';
```

Expected: 1 row, status='cancelled', finished_at = recent timestamp.

## Followup — nexus-pg-rw is read-only in practice

The `nexus-pg-rw` MCP claims write capability in operator memory but rejects UPDATE/DELETE/INSERT with `cannot execute UPDATE in a read-only transaction`. Every "ops cleanup operator approves" intended for that MCP currently has to fall back to operator-run psql. Worth a separate ticket to either:

- Reconfigure the rw MCP with a non-read-only role, or
- Update `reference_available_tools.md` to mark it read-only and stop suggesting it for writes.

## Status

- [x] Task located (id confirmed, status=queued)
- [ ] Task cancelled — **blocked on operator psql run** (SQL above)
- [x] No other lingering test/e2e tasks in queued/claimed/running

One-time test, no business impact, safe to leave queued until operator runs the UPDATE.
