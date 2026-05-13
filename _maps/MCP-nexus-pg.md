---
type: mcp
status: active
scope: read-only
---
# MCP-nexus-pg

Read-only Postgres MCP wired to the Nexus production database. Tool name: `mcp__nexus-pg__query`.

## Purpose
SELECT-only access for audits, reconciliation checks, and "what does the DB actually say right now" probes — without needing to open psql or write a one-off endpoint. Authentication is preset; operator does not paste creds per session.

## When to reach for it
- Cross-check API claims against the source-of-truth (`trades`, `positions`, `gate_decisions`, `prediction_logs`, `agent_observations`).
- Per-strategy stats (signals, orders, win-rate over N days).
- Reconciliation drift checks before bothering operator with "do we have a problem".
- Foundation-gate rule 4 evidence (gate_decisions row counts × strategy × day).

## Boundaries
- **Read-only.** For DELETE/UPDATE/INSERT use [[MCP-nexus-pg-rw]] — and only with explicit operator-OK per [[Decision-No-Auto-Activation]].
- Do NOT use for hot-path queries during a trading cycle — production reads belong in the worker code, not the Claude session.
- Treat returned rows as a snapshot, not a stream — re-query if state may have moved.

## Failure modes
If query returns empty unexpectedly: check schema name, check whether the table was recently renamed (e.g. `lastBackfillIso` → `lastBackfillRowIso` rename surfaced via this tool).

Linked to: [[Tools-MOC]], [[MCP-nexus-pg-rw]], [[Reconciliation]], [[Decision-Tools-Roster-Habit]]
