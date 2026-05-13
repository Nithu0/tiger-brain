---
tags: [meta, claude-context]
type: meta
created: 2026-05-11
---

# START-HERE — Claude entry point

## What this vault is

Operator Nithu's personal second-brain (Obsidian, mixed Norwegian/English). Holds long-running context for Nexus (XAUUSD trading firm), the NTNU master's thesis (battery electrolyte ML), business, career, and learning. Live truth for code lives in repos at `/home/nithu/code/`, not here.

## Read these in order

1. [[RULES]] — binding rules for Claude in this vault
2. [[BRAIN-RULES]] — operator's vault-wide conventions
3. [[00-DASHBOARD]] — top-level pointers to current focus
4. [[01-CURRENT-FOCUS]] — operator's "what I'm doing now"
5. [[CURRENT]] — Claude-readable current-state pointer (this folder)
6. Project MOC for the active project (e.g. [[Nexus-MOC]] or [[Thesis-MOC]])

## Source-of-truth precedence

When sources disagree:

1. **Code** (`/home/nithu/code/ai-assistent`, `/home/nithu/code/Master-oppgave`) — wins always
2. **`docs/ops/phase-status.md`** in the repo — wins over brain notes
3. **Brain notes** — context, history, thinking; never authoritative for current state

If a brain note contradicts code or phase-status, code wins. Flag the conflict.

## Archive vs current

`90-archive/` and any file with `status: archived` in frontmatter is historical. Never quote as current state. If it's the only source, say "archived note, may be stale".

## Inbox vs promoted

- `00-claude-inbox/` — raw Claude thinking, low signal-to-noise, not authoritative
- `_promote-candidates/` — being polished, still not authoritative
- Repo docs (in `/home/nithu/code/<repo>/docs/`) — committed truth

## How to handle conflicting notes

Newer wins by `updated:` frontmatter field, falling back to git mtime. Always flag the conflict explicitly. If material to the current task, ask the operator before acting.

## How to work on Nexus safely

- Always check `pwd` and `git remote -v` before any edit
- Work in `01-nexus/` subtree only; do not edit `02-thesis/` or other projects without explicit go-ahead
- Never auto-disable strategies, gates, or flags based on anomaly detection — report, don't act
- Money-impact changes go through `docs/strategy/proposals/` review (see project CLAUDE.md)

## How to update _decisions/

Decision-tree files in `_decisions/` are append-only logs. Add a new row; never delete or rewrite past rows. If a past decision is reversed, add a new row referencing the old one.

## How to write a handoff

Use the format in `prompts/CLAUDE-HANDOFF-PROMPT.md`. File the new handoff in `handoffs/` with a date prefix (`YYYY-MM-DD-<slug>.md`).

## When to ask before doing

Stop and ask for explicit "OK kjør" before:

- Any change to global vault structure (folder renames, MOC restructure, archive moves)
- Any file in `claude-context/`, `_decisions/`, `.github/`, `scripts/`
- Any push, rebase, force-push
- Anything irreversible (delete, overwrite without backup)
- Promoting inbox notes → repo docs

Sist oppdatert: 2026-05-11
