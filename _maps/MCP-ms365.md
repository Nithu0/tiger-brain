---
type: mcp
status: setup-required
scope: calendar-mail-teams
created: 2026-05-11
---
# MCP-ms365

Microsoft 365 MCP — calendar, mail, Teams. Tool names: `mcp__claude_ai_ms365__*`.

## What it enables
- OAuth-gated access to operator's MS365 tenant.
- Auth flow: `authenticate` → operator clicks link → `complete_authentication`.

## When to reach for it
- Calendar lookups ("når har jeg neste advisor-møte").
- Mail drafting (operator reviews before send).
- Teams message review for context on a pinged task.

## Status
Auth flow exposed, **not yet integrated into recurring workflows**. Requires per-session re-auth until refresh-token handling is wired.

## Boundaries
- Never auto-send mail or Teams messages — operator approval per message.
- Don't print mail bodies into transcripts that may leave the device.

## Source
`reference_available_tools.md` memory.

Linked to: [[Tools-MOC]], [[Decision-Tools-Roster-Habit]]
