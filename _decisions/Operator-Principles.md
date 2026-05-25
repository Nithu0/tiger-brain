---
title: Operator Principles
type: decision
date: 2026-05-25
status: stub — points to CLAUDE.md
related: [[2026-05-25-brain-upgrade-plan]]
tags: [decision, operator, principles, stub]
---

# Operator Principles — stub

Authoritative source for operator principles is `~/.claude/CLAUDE.md` (global). Project-specific principles live in per-project `<repo>/CLAUDE.md` files.

This stub exists for wikilink completeness in specs that reference `[[Operator-Principles]]`. Future expansion: collect the canonical principle set here as an immutable summary (separate from the evolving CLAUDE.md files).

Key principle categories (from `~/.claude/CLAUDE.md`):
- Safety: operator-gated irreversible actions
- Communication: short prose, terse, honest, no emojis unless asked
- Push-gate: OK kjør before EVERY push
- Secret handling: never print .env, never read ~/.ssh
- Parallel-by-default: TaskCreate + dispatch parallel agents

Stub created 2026-05-25 by D-8.
