---
date: 2026-05-11
project: nexus
type: ops-log
status: applied
script: scripts/oneshot/run-readonly-grant-11may.mjs
script_commit: 9ea8bb6
operator_authorization: "KJØR PÅ"
---

# GRANT SELECT to `claude_readonly` — applied

## Summary

Ran `run-readonly-grant-11may.mjs` against Railway Postgres on 2026-05-11.
DRY-RUN succeeded, COMMIT succeeded, MCP verification passed. The
`claude_readonly` role now has `SELECT` on all 53 public tables, plus default
privileges for future tables/sequences created by the connecting role.

## Auth

Provided DATABASE_URL still works (URL was not rotated since prior session).

## Dry-run result (mode = ROLLBACK)

- public_table_count: 53
- already_accessible_before: 20
- missing_before: 33
- newly_granted_in_tx: 33
- still_missing_after_in_tx: 0

## Commit result (CONFIRM=YES)

Identical numbers to dry-run; tx COMMITted.

Steps executed inside the single transaction:
1. `GRANT USAGE ON SCHEMA public TO claude_readonly`
2. `GRANT SELECT ON ALL TABLES IN SCHEMA public TO claude_readonly`
3. `GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO claude_readonly`
4. `ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO claude_readonly`
5. `ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON SEQUENCES TO claude_readonly`

## Newly granted tables (33)

agent_events, analysis_snapshots, backtests, bot_runs, bot_status_history,
cross_asset_snapshots, department_scores, economic_events, incidents, jobs,
llm_results, macro_series, market_snapshots, narrative_clusters, news_events,
news_headlines, notifications, oanda_sync_drift, ohlcv_candles, pending_signals,
provider_assessments, reddit_posts, reddit_subreddit_snapshots, risk_events,
sentiment_snapshots, shadow_signals, strategies, system_snapshots,
team_changelog, team_requests, trade_lineage, trade_strategy_snapshots,
workflow_events.

(Note: spec mentioned "32 previously-denied tables"; actual count via
`has_table_privilege` was 33. Difference is +1 — non-blocking.)

## Verification (via `mcp__nexus-pg__query`)

All previously-denied probes succeeded:

| Table | `COUNT(*)` |
|---|---|
| `analysis_snapshots` | 10,261 |
| `ohlcv_candles` | 1,155 |
| `strategies` | 8 |
| `agent_events` | 24,605 |

Before the grant, these would have returned `permission denied`.

## Operator action needed

None. Migration is permanent; no Railway env flips, no service restart, no
follow-up commits required from the operator side.

## URL / secret handling

`DATABASE_URL` was provided in-session only. Not logged. The script's
`maskUrl()` redacts user:password, so any console output retains only the
`postgresql://<redacted>@host:port/db` shape. This note contains no secret.
