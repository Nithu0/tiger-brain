# EXPLAIN ANALYZE audit — 2026-05-11

Read-only probe of seven hot-path queries against the live `nexus-pg` Postgres after the jobs-index landed earlier today. Goal: find next perf wins.

## Verdict per query

| # | Query | Current plan | Duration | Buffers | Verdict |
|---|---|---|---|---|---|
| 1 | `simulated_orders` closed last 7d (LIMIT 100) | Seq Scan (sort) | 0.20 ms | 13 hit | Fine — only 147 rows total; planner correctly skips `idx_sim_orders_closed`. Will flip to Index Scan as table grows. |
| 2 | `blackboard` topic + recent (LIMIT 10) | Index Scan `idx_blackboard_topic` | 0.08 ms | 8 hit | Optimal. 81k-row table served from index. No change. |
| 3 | `agent_tasks` queue poll (LIMIT 5) | Index Scan `idx_agent_tasks_status` | 0.04 ms | 1 hit | Optimal. Partial index on `(status, priority DESC, created_at)` is perfect for this. (Probe omitted FOR UPDATE — read-only role can't lock; rewritten without it.) |
| 4 | `signals` source + last 24h | **Seq Scan** (sort) | **3.95 ms** | **1502 hit** | **WIN.** 14,188 rows seq-scanned to find 2. No supporting index. **Recommend `idx_signals_source_time`.** |
| 5 | `agent_results` JOIN `agent_tasks` (last 24h, role=research) | Nested Loop / Seq Scan agent_results + Index Scan pk | 0.09 ms | 25 hit | Fine — agent_results only 79 rows. Will need a `(created_at)` index past ~10k rows. |
| 6 | `gate_decisions` last 1h | Index Scan `idx_gate_decisions_time` | 0.02 ms | 2 hit | Optimal. |
| 7 | `postmortems` recent (created_at last 7d) | **Seq Scan** | 0.05 ms | 4 hit | Tiny today (31 rows). **Will Seq Scan forever without `(created_at)`** — preempt before next 10x trade volume. (Probe used `trade_id` — original SQL used `order_id` which does not exist on this table.) |

## Detail — query 4 (the big one)

```text
Seq Scan on signals  (cost=0.00..1781.04 rows=1 width=807)
                     (actual time=2.242..3.918 rows=2.00 loops=1)
   Filter: ((source = 'firm-strategy:xau-volatility-expansion'::text)
            AND (created_at > (now() - '24:00:00'::interval)))
   Rows Removed by Filter: 14186
   Buffers: shared hit=1502
```

**Stats bombshell:** `pg_stat_user_tables.n_live_tup = 31` on `signals` (actual `COUNT(*) = 14188`). Table has **never been ANALYZE'd** (`last_analyze = NULL, last_autoanalyze = NULL`). Planner cost estimates are off by 458x. Index creation alone will flip the plan because index lookups are cheap regardless of cardinality estimate, but a manual `ANALYZE signals` post-deploy is still wise (operator action — not in this diff).

Likely cause: autovacuum threshold = `50 + 0.2 * n_live_tup` calculated from a stale n_live_tup of 31 → would need only ~57 changes to trigger, yet none has fired since table inception. Worth investigating separately (sister-issue: rows likely inserted with `WAL_LEVEL=minimal` truncate/copy path that bypasses stats, or table was created without autovacuum reaching it). Not blocking — the index fixes the symptom regardless.

## Recommended indexes (applied)

| # | Index | Table | Targets | Estimated speedup |
|---|---|---|---|---|
| 1 | `idx_signals_source_time` on `(source, created_at DESC) WHERE source IS NOT NULL` | signals | query 4 + strategy-execution loop + /signals + /threads + n8n WF#1 | **~50–200x** (1502 buffer hits → 5–10; 3.95 ms → <0.2 ms once table grows). At today's 14k rows the absolute win is small but per-cycle calls dominate. |
| 2 | `idx_signals_created_at` on `(created_at DESC)` | signals | "recent signals" feeds without source filter (/signals top, dashboard live tail) | ~30–50x. Composite #1 cannot serve these (composite leading-col rule). |
| 3 | `idx_postmortems_created_at` on `(created_at DESC)` | postmortems | classification dashboards + operator-brief recent-trades panel | Negligible today; preempts post-100x growth. |

All three added as additive `CREATE INDEX IF NOT EXISTS` entries in `packages/shared/src/db/schema.ts` (perf-audit follow-up block, after the earlier jobs-index entry).

## What I did NOT touch

- `simulated_orders` (147 rows — planner correctly skips index for now)
- `agent_results` / `agent_tasks` / `agent_audit` (all under 100 rows, fast already)
- `blackboard` / `gate_decisions` (already optimal)
- `agent_tasks_pkey` join filter on `role` — fine via PK lookup at this size; revisit if `agent_results` grows past 10k

## Followups (operator-gated)

1. Run `ANALYZE signals` manually on next deploy or via `nexus-pg-rw` if explicit operator sign-off — to refresh the stale stats so future queries pick up correct cardinality.
2. Investigate why autovacuum/analyze never fired on `signals` despite 14k rows. Consider explicit `ALTER TABLE signals SET (autovacuum_analyze_scale_factor=0.05)` analogous to the existing tuning on `agent_tasks`/`agent_artifacts`/`notifications` (line 1389–1391 of schema.ts).
3. Add a periodic `VACUUM ANALYZE` cron on hot tables — currently zero scheduled maintenance.
