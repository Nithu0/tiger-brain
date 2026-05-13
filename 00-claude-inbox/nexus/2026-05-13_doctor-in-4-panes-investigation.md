---
date: 2026-05-13
type: investigation
project: workspace
status: open
---

# `/doctor` flashed in 4 of 8 panes on `firm` launch — root cause

## Observation

Operator ran `firm` (the 8-pane WT split-view via `/home/nithu/code/_bin/firm-wt-split.sh`).
4 panes flashed Claude's `/doctor` diagnostic output then it disappeared; the other 4
started normally.

## Pane layout (from `firm-wt-split.sh`)

| Pane | Role     | CWD                              |
|------|----------|----------------------------------|
| 1    | code-1   | `/home/nithu/code`               |
| 2    | code-2   | `/home/nithu/code`               |
| 3    | ai-1     | `/home/nithu/code/ai-assistent`  |
| 4    | ai-2     | `/home/nithu/code/ai-assistent`  |
| 5    | ai-3     | `/home/nithu/code/ai-assistent`  |
| 6    | ai-4     | `/home/nithu/code/ai-assistent`  |
| 7    | thesis-1 | `/home/nithu/code/Master-oppgave`|
| 8    | thesis-2 | `/home/nithu/code/Master-oppgave`|

The 4 `ai-*` panes are exactly the 4 that ran in `/home/nithu/code/ai-assistent`.
This directory is the only one with a `.mcp.json`.

## Most likely cause

`/home/nithu/code/ai-assistent/.mcp.json` declares the `nexus-pg` MCP server with
`${NEXUS_READONLY_PG_URL}` substitution. The env var is NOT declared in
`.env.example` (grep returned empty), and Claude Code's session loader cannot
resolve it. Claude Code surfaces unresolved/failing MCP servers as a startup
notification that includes the `/doctor` health panel, briefly auto-rendered then
cleared once the session prompt takes over.

Eliminated alternatives:
- **No `/doctor` text** in `~/.claude/settings.json`, `firm-tab-init.sh`,
  `firm-session-context.sh`, `firm-wt-split.sh`, or
  `scripts/hooks/session-start.sh`.
- **SessionStart hook is benign** — `session-start.sh` only dumps repo context;
  `firm-session-context.sh` only dumps firm-bus feed; neither outputs `/doctor`.
- Stop hooks fire on session end, not start.
- code-* / thesis-* panes do not load `.mcp.json` (no such file in their CWDs),
  consistent with them booting cleanly.

## Recommended action (operator-facing)

1. Set `NEXUS_READONLY_PG_URL` in `/home/nithu/code/ai-assistent/.env.local`
   (operator action — I can't read or write `.env.local`). Use the read-only
   Postgres role's connection string from the Railway dashboard. Format:
   `postgresql://<readonly_user>:<pw>@<host>:5432/<db>?sslmode=require`.
2. Also add `NEXUS_READONLY_PG_URL=` (empty value, name only) to
   `.env.example` so the next operator sees it declared. I can do that — small
   non-money change.
3. Re-run `firm`. The 4 ai-* panes should boot without the `/doctor` flash.

## If setting the env var does NOT fix it

Fallback hypothesis: Claude Code may be flashing `/doctor` because the firm-launch
SessionStart hook adds context that triggers Claude's first-session health panel.
In that case, check `~/.claude/cache/` and the `claude-code` version's release
notes for behaviour changes around MCP-server failure UX. Tab-init currently exec's
`claude --dangerously-skip-permissions`; no other flags. Nothing in our scripts
invokes `/doctor` directly.

## Files inspected (read-only)

- `/home/nithu/.claude/settings.json`
- `/home/nithu/code/_bin/firm-wt-split.sh`
- `/home/nithu/code/_bin/firm-tab-init.sh`
- `/home/nithu/code/_bin/firm-session-context.sh`
- `/home/nithu/code/ai-assistent/scripts/hooks/session-start.sh`
- `/home/nithu/code/ai-assistent/.mcp.json`
- `/home/nithu/code/ai-assistent/.env.example` (no `NEXUS_READONLY_PG_URL`)

No code edits made.
