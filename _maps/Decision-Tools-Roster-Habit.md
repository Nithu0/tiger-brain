---
type: decision
status: binding
decided: 2026-05-08
---
# Decision: Tools-roster habit

Before proposing a manual workaround to any task, Claude must pattern-match against the registered tools roster — `reference_available_tools.md` in project memory + [[Tools-MOC]] in this vault. If a tool exists that solves the task, use it. Don't reach for bash + grep when an MCP is one call away.

## Why
Operator has been setting up MCPs over months (nexus-pg, nexus-pg-rw, n8n, ClickUp, GDrive, MS365, obsidian, plus several webhooks). The investment is wasted if Claude defaults to "I can't" or "let me write a script" when a tool already covers it. This rule is binding because the failure mode is silent: operator doesn't know Claude is bypassing the roster unless they catch it.

## Operationalisation
- **Session start:** glance at `reference_available_tools.md` before starting non-trivial work. Same for project CLAUDE.md "Available MCPs + tools" section.
- **Same-session updates:** whenever a new MCP is added during the session, append it to `reference_available_tools.md` immediately. Stale roster = the rule eats itself.
- **"I can't" check:** if about to tell operator "I can't do X" — first verify no tool covers it, second propose the operator-fix path (e.g. "I can't read `.env.local`; paste the value once and I'll cache it for the session").

## Companion files
- `reference_available_tools.md` — per-project tool inventory (binding read).
- `docs/ref/claude-code-capabilities.md` — broader Claude Code feature reference.

Linked to: [[Decisions-MOC]], [[Tools-MOC]], [[MCP-nexus-pg]], [[MCP-nexus-pg-rw]], [[MCP-n8n]], [[MCP-obsidian]]
