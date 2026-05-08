---
tags: [moc, tools, capabilities]
type: moc
created: 2026-05-08
---

# Tools-MOC

What Claude can actually do inside this brain. Pattern-match every task against this roster **before** proposing a manual workaround. Roster is the binding session-start habit per [[Decisions-MOC]] (decision 2026-05-08).

## Registered MCPs

| MCP | What it enables | Detail |
|---|---|---|
| [[MCP-nexus-pg]] | Postgres SELECT, read-only | Audit queries, reconciliation checks against the Nexus DB. |
| [[MCP-nexus-pg-rw]] | Postgres full SQL (DELETE / UPDATE / INSERT) | Cleanups, backfills, and migrations operator approves explicitly. |
| [[MCP-n8n]] | n8n cloud workflow CRUD | Create / edit / test workflows. WF#1 LIVE; WF#2 / WF#3 in setup. Trial plan = MCP-only, no REST. |
| [[MCP-obsidian]] | This vault, scoped writes | Write to `00-claude-inbox/` + `_promote-candidates/`; read elsewhere. Activated via Local REST API plugin. |
| [[MCP-clickup]] | Tasks, lists, docs, time-tracking | Operator-managed; confirm before assuming what's tracked there. |
| [[MCP-google-drive]] | File read / write / search | Shared docs, exporting reports, audit uploads on request. |
| [[MCP-ms365]] | Calendar / mail / Teams | OAuth flow first; not yet integrated into recurring workflows. |

## Built-in capability classes

- **Bash** — curl webhooks, git, npm, npx tsc, file operations.
- **Agent / parallel sub-agents** — default for non-trivial multi-file work.
- **WebFetch / WebSearch** — docs lookups, library research.
- **ScheduleWakeup / CronCreate** — recurring polls, scheduled audits.

## Project endpoints I can curl

- `/health` — DB / broker / blackboard / worker / reconciliation status (no auth).
- `/diagnostic/broker` — full OANDA fetch attempt + advice.
- `/operator/*`, `/firm-agents/*` — auth via `Authorization: Bearer $API_KEY` (operator pastes per session).

## What Claude CAN'T do (and the fix)

- **Read `.env.local`** — deny rule in `.claude/settings.json`. Operator pastes the needed value once per session.
- **`git push origin main`** — harness blocks direct push. Operator runs `! git push origin main` themselves.
- **Modify Railway env / restart services** — no Railway MCP installed; operator does it manually.
- **Send Telegram** — no creds; mobile control flows via [[WF-1-telegram-orchestrator]].

See also: [[Workflows-MOC]] for how these tools chain into operator workflows, [[Decisions-MOC]] for the binding "use the roster" rule, [[Memory-MOC]] for where the roster lives across sessions.
