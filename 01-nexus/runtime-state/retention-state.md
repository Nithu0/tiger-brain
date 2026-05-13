---
type: living-state
subsystem: retention-ttl
last_verified: 2026-05-11T15:30Z
status: 🟢
---

# Retention TTL Pass — Living State

Daily TTL pass that prunes blackboard volume topics + `sentiment_snapshots` + `jobs` + `trade_strategy_snapshots`. Per [[Operator-Principles]] rule 2: data NEVER stops — retention only prunes low-value memory rows.

## Current state (verified 2026-05-11T14:20Z)

- **Flag**: `RETENTION_ENABLED=true` on Railway worker — **LIVE**
- **Build commit**: `a2f1cbc8` (4 commits after `711a254`; FK-safe filter active)
- **FK-safe filter `711a254` (2026-05-11T16:05Z local commit)**: jobs-done + jobs-failed DELETEs now have `AND NOT EXISTS (SELECT 1 FROM bot_runs WHERE job_id = j.id)`. **VERIFIED REAPING.**
- **First post-fix reap: 2026-05-11T14:12:42Z — `jobsDone=5965`, `errors=[]`.** Matches forensic prediction exactly.
- **Status post-reap**: unreferenced completed jobs >7d old = **0**. Referenced still 13,500 (pending operator schema decision).

## Verified reap (the 14:12Z pass)

```
ranAt:    2026-05-11T14:12:37.588Z
enabled:  true
deleted:
  blackboardVolume:        0   (cohort not aged to 30d yet)
  blackboardAnalysis:      0   (cohort not aged to 90d yet)
  sentimentSnapshots:      0   (oldest 14d — not aged to 30d yet)
  jobsDone:             5965   ← FK-safe filter reaped exactly the unreferenced cohort
  jobsFailed:              0   (no aged failures past 30d)
  tradeStrategySnapshots:  0   (not aged to 90d yet)
errors:   []
```

## Recent changes

- 2026-05-11: `09dd027` — fixed jobs-done deletion path; `'done'` → `'completed'` on `retention.ts:236` + `:44` + test fixtures
- 2026-05-11 kveld: `RETENTION_ENABLED=true` flipped on Railway
- 2026-05-11T14:00Z verify pass: FK blocker discovered — reap not yet effective
- 2026-05-11T16:05Z `711a254` — FK-safe `NOT EXISTS` filter on jobs-done + jobs-failed branches
- **2026-05-11T14:12:42Z** — first post-deploy retention run **REAPED 5,965 unreferenced jobs, zero errors**. Verified.

## Policy (per topic-class)

| Target | Retention | Notes |
|---|---|---|
| `blackboard` volume topics (`market.raw`, `events`, `macro`) | 30d | Oldest row 2026-04-15 (26d) — first reap due ~2026-05-15 |
| `blackboard` analysis/strategy topics | 90d | First reap due ~2026-07 |
| `blackboard` decisions / postmortems / `execution.reports` | **permanent** | Audit + lesson-loop signal, never pruned |
| `sentiment_snapshots` | 30d | Oldest row 2026-04-20 (21d) — no rows >30d yet; over_14d=3,800 / total=10,378 |
| `jobs` (status=completed) | 7d | **FK-safe filter LIVE** — unreferenced 5,965 reaped 14:12Z. Referenced 13,500 stay pending operator schema decision |
| `jobs` (status=failed) | 30d | Same FK-safe filter; 38 failed rows currently, irrelevant scale |
| `jobs` (status=pending/queued/processing) | **kept** | Never prune queued work (1 queued, 1 processing currently) |
| `trade_strategy_snapshots` | 90d | Per-trade context — keep until lesson-loop digests |

## Health indicators

- Daily `xauusd.retention.report` row appears on blackboard ✅
- Zero errors in retention-pass report payload ✅ (14:12Z post-fix run)
- After first post-fix pass: `jobs(status='completed')` count drops by 5,965 ✅ (from ~21k down to 15,224)
- Trading-loop heartbeat unaffected (retention fire-and-forget) ✅

## Current jobs state (post-reap)

| status | count |
|---|---|
| completed | 15,224 |
| failed | 38 |
| processing | 1 |
| queued | 1 |

| Cohort | Count |
|---|---|
| `completed` AND age > 7d | 13,500 |
| └─ referenced by `bot_runs.job_id` | 13,500 |
| └─ unreferenced (safe to delete) | **0** ✅ |

## Open issues

- [x] **P0** (mitigated 2026-05-11 `711a254` — verified reaping 14:12Z): FK `bot_runs_job_id_fkey` no longer blocks jobs reap
- [ ] **Follow-up (operator decision)**: how to reap the remaining 13,500 FK-referenced completed jobs. Options:
  - Add `ON DELETE CASCADE` to the FK (deletes bot_runs row with job)
  - Add `ON DELETE SET NULL` (keeps bot_runs row, severs link)
  - Pre-delete: retention deletes matching `bot_runs` rows first, then `jobs`
  - Leave as-is — table is only 7.3 MB, churn is manageable
  - Operator + Karri review needed → file a strategy proposal? (probably ops, no money-impact, so just operator-OK)
- [ ] Verify retention cadence: prior 3 passes in ~1h was denser than design "once per UTC-day" — check orchestrator wire-up
- [ ] 2026-05-15 (T+30d from first volume row 2026-04-15): first non-zero `blackboardVolume` delete
- [ ] 2026-05-20 (T+30d from first sentiment row 2026-04-20): first non-zero `sentimentSnapshots` delete
- [ ] 2026-07: first non-zero `blackboardAnalysis` delete (90d from oldest 2026-04-15)
- [ ] Consider adding retention for `agent_audit` / `agent_artifacts` / `agent_results` once Agent Bus volume grows

## FK forensics

```sql
SELECT conname, pg_get_constraintdef(oid)
FROM pg_constraint WHERE conname='bot_runs_job_id_fkey';
-- FOREIGN KEY (job_id) REFERENCES jobs(id)   ← no ON DELETE rule
```

## Storage delta estimate

- `jobs` reap freed ~5,965 rows × ~380 B = ~2.3 MB (tiny)
- `blackboard`: **342 MB** — biggest reap potential when 30d volume-topic rows age in (~2026-05-15)
- `sentiment_snapshots`: **143 MB** — second-biggest, first reap ~2026-05-20
- **Bottom line**: FK fix unblocked the churn-state hygiene path. Big wins are still 4-9 days out (blackboard + sentiment age-ins).

## Verification SQL

```sql
-- last retention run report
SELECT timestamp, state->'deleted' AS deleted, state->'errors' AS errors
FROM blackboard
WHERE topic = 'xauusd.retention.report'
ORDER BY timestamp DESC LIMIT 5;
```

```sql
-- unreferenced cohort (should stay 0 between reaps)
SELECT COUNT(*) FROM jobs
WHERE status='completed'
  AND COALESCE(finished_at, queued_at) < NOW() - INTERVAL '7 days'
  AND NOT EXISTS (SELECT 1 FROM bot_runs br WHERE br.job_id = jobs.id);
-- 2026-05-11T14:20Z: 0 ✅
```

## Rollback

`RETENTION_ENABLED=false` on Railway worker. 30 seconds, no code change. Next retention pass becomes no-op; pruned rows stay pruned (idempotent).

## What never auto-fires

- Pruning decisions / postmortems / `execution.reports` — permanent ([[Operator-Principles]] rule 2)
- Pruning pending jobs — queue-loss risk
- Manual SQL `DELETE` outside the retention codepath — operator-only via `nexus-pg-rw`
- Auto-promotion of retention rules to more aggressive without operator OK ([[Operator-Principles]] rule 1)
- **Schema change (FK ON DELETE rule)** — operator-gated migration ([[Operator-Principles]] rule 1)

## Operator principles respected

- **No auto-disable**: retention reports rows pruned; doesn't change trading behaviour ([[Operator-Principles]] rule 1)
- **Data never stops**: only memory-class rows pruned, not fact/analysis/persistence-tables ([[Operator-Principles]] rule 2)
- **Janitorial adjustments OK without operator-OK**: retention/TTL/dedupe falls in this bucket ([[Operator-Principles]] rule 3)
- FK schema change is **not** janitorial — needs operator-OK before migration

Linked to: [[Nexus-MOC]], [[Operator-Principles]], [[Module-Blackboard]], [[production-loop-state]], [[foundation-gate-state]], [[Truth-Hierarchy]]
