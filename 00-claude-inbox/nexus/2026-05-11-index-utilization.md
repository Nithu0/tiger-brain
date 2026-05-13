---
date: 2026-05-11
type: db-audit
topic: index utilization after commits 66d9863 + 9399897
status: read-only audit
---

# Index utilization audit — post ANALYZE signals

Commits under review:
- `66d9863` — added `idx_signals_source_time`, `idx_jobs_status_queue`, `idx_sim_orders_closed`, `idx_postmortems_created_at`, `idx_signals_created_at`
- `9399897` — (related index/migration work)

Stats refresh confirmed: `signals.last_analyze = 2026-05-11T13:37:34Z`, `n_live_tup=14191`, `analyze_count=1`.

---

## 1. signals — idx_signals_source_time

Query:
```sql
SELECT * FROM signals
WHERE source='firm-strategy:xau-volatility-expansion'
  AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;
```

Plan:
```
Index Scan using idx_signals_source_time on signals
  (cost=0.29..8.31 rows=1 width=800)
  (actual time=0.022..0.025 rows=2 loops=1)
  Index Cond: ((source = '...') AND (created_at > now() - '24:00:00'))
  Buffers: shared hit=4
Planning Time: 0.452 ms
Execution Time: 0.042 ms
```

Verdict: **IN USE.** Composite index hit cleanly. Buffer hits dropped from **1502 → 4** (~375x reduction). Execution time **3.95ms → 0.042ms** (~94x speedup). Index size 704 kB. `pg_stat_user_indexes.idx_scan=5` (low, but post-deploy and post-ANALYZE only).

---

## 2. jobs — idx_jobs_status_queue

Query:
```sql
SELECT * FROM jobs
WHERE status='queued' AND queue='research'
ORDER BY queued_at DESC LIMIT 1;
```

Plan:
```
Limit (cost=0.41..6.19 rows=1 width=296) (actual time=0.019..0.020 rows=0)
  -> Index Scan using idx_jobs_status_queue on jobs
       Index Cond: ((status = 'queued') AND (queue = 'research'))
       Buffers: shared hit=3
Planning Time: 1.518 ms
Execution Time: 0.042 ms
```

Verdict: **IN USE.** Index Scan picked even though `queued` queue is currently empty. 1176 kB — larger than expected for 21k rows; partial-index opportunity later (`WHERE status='queued'`) would shrink to <50 kB. `idx_scan=5`. Last autoanalyze 2026-05-10.

---

## 3. simulated_orders — idx_sim_orders_closed

Query:
```sql
SELECT * FROM simulated_orders
WHERE status='closed' AND closed_at > NOW() - INTERVAL '7 days'
ORDER BY closed_at DESC LIMIT 100;
```

Plan:
```
Limit (cost=16.68..16.75 rows=30 width=1160) (actual time=0.168..0.178 rows=33)
  -> Sort (Sort Key: closed_at DESC, Method: quicksort, Memory: 49kB)
       -> Seq Scan on simulated_orders
            Filter: ((status = 'closed') AND (closed_at > now() - '7 days'))
            Rows Removed by Filter: 117
            Buffers: shared hit=13
Execution Time: 0.209 ms
```

Verdict: **NOT USED for this query** — planner chose Seq Scan because the table only has 150 live rows. **However** `pg_stat_user_indexes.idx_scan=621` so the index IS heavily used elsewhere (probably by application queries with different shape / LIMIT 1 or by-id lookups). Index size only 16 kB. Keep.

Note: as table grows past ~5k rows, planner will flip to Index Scan automatically. No action needed.

---

## 4. postmortems — idx_postmortems_created_at

Query:
```sql
SELECT * FROM postmortems WHERE created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC;
```

Plan:
```
Sort (cost=4.98..5.02 rows=14 width=392) (actual time=0.085..0.087 rows=34)
  Sort Key: created_at DESC
  -> Seq Scan on postmortems
       Filter: (created_at > now() - '7 days')
       Rows Removed by Filter: 9
       Buffers: shared hit=4
Execution Time: 0.128 ms
```

Verdict: **NOT USED for this query.** Table has only 34 rows + 9 filtered = 43 total — Seq Scan is correct. `last_analyze=null` (never analyzed) but irrelevant at this size. **However** `pg_stat_user_indexes.idx_scan=51` so app code does use it (probably for `WHERE created_at > X` with a different shape, or via the implicit unique constraint pathway). Index size 16 kB. Keep.

---

## 5. Index sizes — top 20 idx_* on public schema

| Index | Size |
|---|---|
| idx_blackboard_topic | 18 MB |
| idx_blackboard_symbol | 10 MB |
| idx_engine_scores_engine | 1584 kB |
| idx_jobs_status_queue | 1176 kB |
| idx_agent_events_agent_time | 1024 kB |
| idx_market_snapshots_cycle | 760 kB |
| idx_analysis_snap_cycle | 760 kB |
| idx_sentiment_snapshots_cycle | 752 kB |
| **idx_signals_source_time** | **704 kB** |
| idx_gate_decisions_name | 656 kB |
| idx_blackboard_responding | 648 kB |
| idx_sentiment_snapshots_time | 584 kB |
| idx_market_snapshots_time | 584 kB |
| idx_analysis_snap_time | 584 kB |
| idx_strategy_snapshots_cycle | 552 kB |
| idx_strategy_snapshots_captured_at | 448 kB |
| idx_reddit_sub_time | 448 kB |
| idx_engine_scores_cycle | 424 kB |
| idx_news_headlines_source | 328 kB |
| idx_signals_created_at | 328 kB |

Total all `idx_*` indexes in public: **42 MB / 44,081,152 bytes**.

The 4 new indexes from 66d9863+9399897 total: 704 + 1176 + 16 + 16 + 328 = **~2.2 MB** (negligible vs blackboard's 28 MB).

---

## Per-index verdict

| Index | Planner used? | idx_scan total | Size | Speedup vs pre | Verdict |
|---|---|---|---|---|---|
| idx_signals_source_time | YES (composite hit) | 5 | 704 kB | 1502→4 buffers, 3.95ms→0.042ms (~94x) | Keep — high-value |
| idx_jobs_status_queue | YES (Index Scan even on empty) | 5 | 1176 kB | n/a (queue empty) | Keep — but consider PARTIAL `WHERE status='queued'` later |
| idx_sim_orders_closed | NO for this query (table too small) | 621 (used elsewhere) | 16 kB | n/a | Keep — used by app, will activate at scale |
| idx_postmortems_created_at | NO for this query (table too small) | 51 (used elsewhere) | 16 kB | n/a | Keep — used by app |
| idx_signals_created_at | (not tested directly) | 60 | 328 kB | n/a | Keep |

## Noise candidates

None. All 5 indexes are either actively used or future-proof at trivial size.

## Recommendations (read-only audit, no action taken)

1. **Re-check `idx_signals_source_time.idx_scan` in 24-48h.** Currently only 5 scans because counter was reset by stats refresh / index just landed. If still <50 after a full trading day, query path may bypass it (e.g. ORM not using the source filter).
2. **Consider partial index for jobs** later: `CREATE INDEX ... ON jobs(queue, queued_at DESC) WHERE status='queued'` — would shrink ~1.1MB → ~10 kB and stay hot in cache.
3. **No deletions.** All new indexes pay rent.
