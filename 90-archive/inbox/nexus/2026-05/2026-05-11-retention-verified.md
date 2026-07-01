---
date: 2026-05-11
project: nexus
type: inbox
status: verified-with-bug
flag: RETENTION_ENABLED=true
build: ee6a8abb
---

# Retention verified — works, but jobs-completed branch is dead code

## Summary

Operator flipped `RETENTION_ENABLED=true` on Railway worker. Verification at T+~10min:

- Build deployed: `ee6a8abb` (latest retention commit).
- First retention pass fired at `2026-05-11T12:53:00.685Z`.
- Report published to `xauusd.retention.report` on blackboard.
- `errors: []`, `enabled: true`, no exceptions.
- All `deleted.*` counts = 0 (expected — no rows old enough yet), EXCEPT see bug.

## Bug found — jobs status mismatch

`retention.ts:236` deletes from `jobs` `WHERE status = 'done'`. The worker writes `status = 'completed'` (`apps/worker/src/index.ts:28` on BullMQ `worker.on("completed")` event). So the completed-jobs branch will never delete anything.

Current state: 19,462 `completed` rows older than 7d are stranded. Without a fix, jobs table just keeps growing.

The `failed`-jobs branch is fine (schema value matches). Other 4 tables (blackboard, sentiment_snapshots, trade_strategy_snapshots) are correct — they were not yet eligible at first run.

## Recommendation

Small fix, no behaviour-change risk:

1. `retention.ts:236`: `status = 'done'` → `status = 'completed'`
2. `retention.ts:44` (docstring): same string update for consistency.
3. `retention.test.ts:248` + fixtures: bump `'done'` → `'completed'`.

Not a strategy/risk change — pure bug-fix restoring intended behaviour. Per CLAUDE.md, "bug fixes that restore intended behaviour" do NOT need a proposal. Operator-OK to ship and next-day run will reap ~19k rows.

## Living state doc

`/home/nithu/Obsidian/Brain/01-nexus/runtime-state/retention-state.md` (NEW).

## Verification queries used

```sql
-- Build commit
curl /health | jq -r '.build.commit'  -- ee6a8abb

-- Report present
SELECT timestamp, state FROM blackboard
 WHERE topic='xauusd.retention.report'
 ORDER BY timestamp DESC LIMIT 5;

-- Eligible-for-delete sanity check
SELECT status, COUNT(*) FILTER (WHERE COALESCE(finished_at, queued_at) < NOW() - INTERVAL '7 days') AS over_7d
  FROM jobs GROUP BY status;
-- => completed=19462 (should be deleted, not), failed=38, processing=1, queued=0
```

## Verdict

WORKING (with one known bug). Safe to leave flag on. Bug-fix recommended for next sprint commit.
