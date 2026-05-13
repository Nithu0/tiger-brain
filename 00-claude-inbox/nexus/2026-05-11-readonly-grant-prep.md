---
project: nexus
date: 2026-05-11
tags: [postgres, mcp, readonly, oneshot, audit]
status: prepared (awaiting operator run)
---

# 2026-05-11 — Read-only role GRANT prep (`claude_readonly`)

Per full-state audit 2026-05-11: the MCP-bound role `claude_readonly` could
only SELECT 20/52 public tables. Audit-named denied tables confirmed missing:
`analysis_snapshots, agent_events, sentiment_snapshots, trade_strategy_snapshots,
news_headlines, reddit_posts, reddit_subreddit_snapshots, market_snapshots,
oanda_sync_drift`.

## Confirmed role name

`claude_readonly` — from `docs/ops/firehose-setup.md` line 10
(`CREATE ROLE claude_readonly LOGIN PASSWORD ...`). Memory file
`firehose_phase_a_b_landed.md` matched.

## Full denied-list (probed via `has_table_privilege`)

32 tables missing SELECT (in addition to the 20 currently accessible):

```
agent_events
analysis_snapshots
backtests
bot_runs
bot_status_history
cross_asset_snapshots
department_scores
economic_events
incidents
jobs
llm_results
macro_series
market_snapshots
narrative_clusters
news_events
news_headlines
notifications
oanda_sync_drift
ohlcv_candles
pending_signals
provider_assessments
reddit_posts
reddit_subreddit_snapshots
risk_events
sentiment_snapshots
shadow_signals
strategies
system_snapshots
team_changelog
team_requests
trade_lineage
trade_strategy_snapshots
workflow_events
```

Currently accessible (20): `agent_artifacts, agent_audit, agent_knowledge,
agent_lessons, agent_results, agent_tasks, blackboard, blade_decisions, bots,
calibration_log, calibration_profiles, engine_scores, firm_memory, firm_state,
gate_decisions, orb_ranges, orb_setups, postmortems, signals, simulated_orders`.

This matches the firehose-setup GRANT list exactly — the original GRANT was
explicit per-table, so every table added after Phase A creation date has
been invisible to `claude_readonly`.

## Probe SQL used

```sql
SELECT c.relname AS table_name,
       has_table_privilege('claude_readonly',
                           'public.' || c.relname, 'SELECT') AS can_select
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r','p')
  AND n.nspname = 'public'
ORDER BY c.relname;
```

Run via `mcp__nexus-pg__query`. Result: 20 `true`, 32 `false`.

## Artefacts written

| Path | Purpose |
|---|---|
| `scripts/oneshot/grant-readonly-select-11may.sql` | Raw SQL — `GRANT SELECT ON ALL TABLES` + `GRANT SELECT ON ALL SEQUENCES` + `ALTER DEFAULT PRIVILEGES` for future tables. Idempotent. |
| `scripts/oneshot/run-readonly-grant-11may.mjs` | Safe runner — single transaction, default ROLLBACK, prints pre/post `has_table_privilege` rows + newly-granted list. Requires `CONFIRM=YES` to commit. Mirrors `run-dedupe-08may.mjs` pattern. |
| `scripts/oneshot/README-2026-05-11-readonly-grant.md` | Runbook. |

`node --check`: passed.

## Operator run

```bash
# Dry-run (default, ROLLBACK):
DATABASE_URL='postgresql://<owner>:...@HOST:PORT/railway' \
  node scripts/oneshot/run-readonly-grant-11may.mjs

# Commit:
DATABASE_URL='postgresql://<owner>:...@HOST:PORT/railway' CONFIRM=YES \
  node scripts/oneshot/run-readonly-grant-11may.mjs
```

`DATABASE_URL` MUST connect as a role that **owns** the public tables
(superuser or the Railway-app owner). `claude_readonly` cannot grant to
itself.

## Caveats

- `ALTER DEFAULT PRIVILEGES` applies only to objects created by the
  connecting role. If Railway's worker app uses a different owner role,
  future tables created by that role still won't auto-grant. The runner
  flags this via `still_missing_tables_in_tx`. Fix path: re-run as that
  role, or run the ALTER DEFAULT PRIVILEGES `FOR ROLE <app-owner>` variant.
- No behaviour change for trading, worker, or Foundation gate — purely
  read-only grant. Skip strategy/risk proposal flow.

## Post-COMMIT verification

In a Claude session, query a previously-denied table via `nexus-pg`:

```
SELECT count(*) FROM news_headlines;
SELECT count(*) FROM sentiment_snapshots;
SELECT count(*) FROM agent_events;
```

All three should return integers (was: `permission denied`).
