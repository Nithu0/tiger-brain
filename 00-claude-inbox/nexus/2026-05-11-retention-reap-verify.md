---
type: inbox-note
created: 2026-05-11T14:00Z
status: needs-operator-decision
tags: [retention, jobs, fk-constraint, p0]
---

# 2026-05-11 — Retention reap verification post-`09dd027`

## TL;DR

**Reap did NOT happen.** `09dd027` correctly fixed `'done'` → `'completed'` so the DELETE now matches the right rows — but the DELETE itself is blocked by `bot_runs_job_id_fkey`. Zero of the ~19,462 stranded jobs were reaped. Backlog grew slightly to 19,465.

## What I checked

1. Latest 3 `xauusd.retention.report` blackboard rows (last ~1h):
   - **13:55:50Z** — `deleted={all zero}`, `errors=["jobs-done: ... violates foreign key constraint bot_runs_job_id_fkey on table bot_runs"]`
   - **13:33:00Z** — same as above
   - **12:53:00Z** — `deleted={all zero}`, `errors=[]` (first pass with the fix, but still 0 — likely transaction silently rolled back; FK error surfaced from 13:33Z onward)

2. Jobs status distribution:
   - `completed` = **21,185**
   - `failed` = 38
   - `processing` = 1
   - `queued` = 1

3. Stranded completed jobs (age > 7d): **19,465** (was 19,462 pre-fix per state note → grew by 3, expected drift)

4. Sentiment + blackboard reap eligibility:
   - `sentiment_snapshots`: 10,360 rows, oldest 2026-04-27 (14d) → 0 eligible for 30d reap until ~2026-05-27
   - `blackboard xauusd.market.raw*`: 13,541 rows, oldest 2026-04-27 → 0 eligible
   - `blackboard` overall: 82,651 rows, oldest 2026-04-15 (26d) → 0 eligible
   - So all 0s on sentiment/blackboard are **legitimate** (no rows aged in yet)

## Root cause

```
FK: bot_runs.job_id REFERENCES jobs(id)
    No ON DELETE clause → defaults to NO ACTION
```

Of the 19,465 stranded:
- **13,500** are referenced by a `bot_runs` row (FK blocks)
- **5,965** are unreferenced (could delete today)

Postgres aborts the entire DELETE on first FK violation → 0 rows deleted, not even the safe 5,965.

## Cadence concern (secondary)

Retention reports show 3 passes within ~1h (12:53, 13:33, 13:55). Design is "once per UTC-day" per `lastRetentionRunDate` guard in retention.ts header. Either:
- Worker restarted multiple times (each restart resets the guard) — likely given recent deploys
- The guard isn't behaving as documented

Will settle on its own once the worker stops cycling. Flag for follow-up if it persists past 24h.

## Storage delta estimate

- `jobs` table: 7,336 kB total. Even full reap of all 19,465 rows ≈ 3.9 MB freed.
- Real disk wins are still ahead: `blackboard` (342 MB) + `sentiment_snapshots` (143 MB) reap-in around 2026-05-15 → 2026-05-27.
- FK fix is **cleanliness > storage** in the short term.

## Decision needed (operator + maybe Karri)

Choose one path for unblocking the jobs reap:

| Option | Risk | Effort | Reaps |
|---|---|---|---|
| A) Migration: `ALTER ... ON DELETE CASCADE` | Medium — losing `bot_runs` history with deleted jobs | 1 migration + redeploy | All 19,465 |
| B) Migration: `ALTER ... ON DELETE SET NULL` | Low — keeps `bot_runs` rows, severs job link | 1 migration + redeploy + nullable column | All 19,465 |
| C) Retention pre-step: delete matching `bot_runs` first | Same as A but in code | Code change in retention.ts | All 19,465 |
| D) Retention filter: only delete `jobs` with no `bot_runs` ref | Lowest — touches nothing | Code change in retention.ts | Only 5,965 (13,500 stay forever) |

My recommendation: **Option B** (`ON DELETE SET NULL`). Preserves `bot_runs` audit rows (which seem to be the run-history table), just drops the back-pointer to a job that no longer exists. Cleanest semantically. Needs operator-OK because it's a schema migration on prod. No money-impact, so probably no Karri review needed — but flag it to him as FYI.

## Next steps (when operator decides)

1. Operator chooses option A/B/C/D.
2. If migration: write SQL in `apps/worker/migrations/`, redeploy, wait one retention cycle, verify.
3. If code-only (D): change `retention.ts` jobs-done branch to add `AND NOT EXISTS (SELECT 1 FROM bot_runs WHERE job_id = jobs.id)`, redeploy.
4. Verify `jobs(status='completed' AND age>7d)` drops to ~steady-state churn.
5. Update `runtime-state/retention-state.md` status → 🟢.

Linked: [[retention-state]], [[Operator-Principles]], [[production-loop-state]]
