---
date: 2026-05-11
project: nexus
type: db-fix
status: shipped (committed, not pushed)
tags: [postgres, autovacuum, perf-audit, signals]
---

# ANALYZE signals + autovacuum tuning

## Problem

EXPLAIN ANALYZE audit (2026-05-11) found the `signals` table's planner stats
were wildly stale:

- `pg_stat_user_tables.n_live_tup` = **31**
- `SELECT COUNT(*) FROM signals` = **14,188**
- `last_analyze` = NULL, `last_autoanalyze` = NULL, `analyze_count` = 0

The table had **never** been analyzed since creation. As a result, the
planner picked Seq Scan over the freshly-added indexes from commit
`9399897` (`idx_signals_source_time`, `idx_signals_created_at`).

## Fix — two parts

### Part A — one-shot ANALYZE

Script: `scripts/oneshot/run-analyze-signals-11may.mjs`

Mirrors the safety pattern from `run-dedupe-08may.mjs` (DATABASE_URL gate,
masked URL logging, structured JSON summary). No transaction wrapper —
ANALYZE auto-commits and is fully idempotent.

**Ran against Railway prod DB (Pacific tunnel):**

| Stat | Before | After |
|---|---|---|
| `n_live_tup` | 34 | 14,191 |
| `actual COUNT(*)` | 14,191 | 14,191 |
| `n_dead_tup` | 0 | 4 |
| `last_analyze` | NULL | 2026-05-11T13:37:34.642Z |
| `analyze_count` | 0 | 1 |
| drift (actual − live) | 14,157 | 0 |

(Pre-snapshot showed 34 vs the audit's 31 — the live signal-producer added
~3 rows between audit and fix. Drift after = 0 confirms stats are now
synchronized.)

Elapsed: **351 ms.**

### Part B — autovacuum config migration

Added to `packages/shared/src/db/schema.ts` `DB_MIGRATIONS` array,
mirroring the existing pattern for `agent_tasks` / `agent_artifacts` /
`notifications`:

```sql
ALTER TABLE signals SET (
  autovacuum_vacuum_scale_factor = 0.05,
  autovacuum_analyze_scale_factor = 0.02
);
```

| Param | Default | New |
|---|---|---|
| `autovacuum_vacuum_scale_factor` | 0.20 (20%) | 0.05 (5%) |
| `autovacuum_analyze_scale_factor` | 0.10 (10%) | 0.02 (2%) |

Autoanalyze will now kick in at 2% row changes (~280 rows on current
14k table) vs the default 10% (~1400 rows). Idempotent — `ALTER TABLE
... SET (...)` is fine to re-run on every boot.

## Verification

- `cd packages/shared && npx tsc --noEmit` — clean (no output)
- `cd apps/worker && npm test` — **467/467 pass**, 0 fail
- Post-ANALYZE snapshot confirms `n_live_tup` matches actual COUNT.

## Verification SQL (for follow-up)

```sql
-- Confirm stats stay fresh going forward
SELECT relname, n_live_tup, n_dead_tup, last_analyze, last_autoanalyze,
       analyze_count, autoanalyze_count
FROM pg_stat_user_tables
WHERE relname = 'signals';

-- Confirm reloptions persisted
SELECT relname, reloptions
FROM pg_class
WHERE relname = 'signals';
-- expect: {autovacuum_vacuum_scale_factor=0.05,autovacuum_analyze_scale_factor=0.02}

-- Confirm planner now uses the indexes
EXPLAIN ANALYZE
SELECT * FROM signals
WHERE source = '<some-source>'
ORDER BY created_at DESC
LIMIT 50;
-- expect: Index Scan using idx_signals_source_time
```

## Operator action

**None.** The one-shot script has already been run. The autovacuum
migration auto-applies on next Railway worker boot (idempotent, runs
through the standard `DB_MIGRATIONS` array).

## Commit

`c686344` — chore(db): one-shot ANALYZE signals + autovacuum tuning

NOT pushed — awaiting "OK kjør" gate per project rules.
