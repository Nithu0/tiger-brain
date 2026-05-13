---
type: mcp
status: active
scope: read-write
---
# MCP-nexus-pg-rw

Full-SQL Postgres MCP wired to the Nexus production database via `@modelcontextprotocol/server-postgres`. Tool name: `mcp__nexus-pg-rw__query`.

## Purpose
DELETE / UPDATE / INSERT / DDL for cleanups, backfills, and one-off migrations that operator approves explicitly. Sister to [[MCP-nexus-pg]] (read-only).

## When to reach for it
- Memory-layer cleanup (dedupe, TTL enforcement, low-value pruning) per operator-prinsipp 3 — small janitorial tweaks are OK.
- Manual reconciliation patches operator has signed off on.
- Backfilling a column after a schema migration that left history blank.
- One-off corrections operator describes in plain text ("nuke the test rows from 2026-05-07 between 14:00 and 15:00").

## Hard gates
- **Operator-OK required for every write.** No exceptions, no "small enough to skip". Per [[Decision-No-Auto-Activation]] + [[Operator-Principles]] rule 1.
- No behavioural changes to the trading loop via SQL — code changes go through git + PR + [[Strategy-Proposal-Workflow]] when money-impact.
- Never use to "fix" what should be a worker code change. SQL fixes drift; code fixes stay.
- Run the equivalent SELECT first via [[MCP-nexus-pg]] to confirm scope (rows affected) before issuing the write.

## Audit
Every operator-approved write should be appended to `docs/ops/manual-sql-log.md` (date, statement, why, row-count) so future Claude can see what was done outside git history.

Linked to: [[Tools-MOC]], [[MCP-nexus-pg]], [[Operator-Principles]], [[Decision-No-Auto-Activation]]
