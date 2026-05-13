---
type: reference
status: live
created: 2026-05-11
---
# Global-CLAUDE-md

The operator-baseline CLAUDE.md file at `~/.claude/CLAUDE.md`. Auto-loads on every Claude Code session, every project, every device.

## What lives there
- Operator identity (Norwegian technical operator, multi-project)
- Communication style rules (terse, NO/EN mix, no emojis, "OK kjør" autonomous-execute triggers)
- Safety rules (operator-gated irreversible actions, no auto-disable, push-gate)
- Secret-handling policy (allowed: `.env.example`; never: `.env*`, `~/.ssh`, `.git/config`)
- Cross-repo discipline (no context pollution between projects)
- Tool-roster habit (pattern-match before manual workarounds)
- Strategy/risk change pipeline pointer
- Default-to-parallel-agents directive
- Memory hierarchy explainer

## Authority
Top of the [[Truth-Hierarchy]] for cross-project rules. Overridden only by project-specific CLAUDE.md when scope is local.

## How to read
First file Claude reads at session start (after harness defaults). Memory files in `~/.claude/projects/<slug>/memory/` load on top of it.

Linked to: [[Memory-MOC]], [[Operator-Principles]], [[Truth-Hierarchy]]
