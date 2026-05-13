---
type: architecture-pointer
status: resolved
created: 2026-05-11
target: docs/architecture/cross-project-fixes.md
---
# Cross-Project-Pollution-Audit

One-off audit (2026-05-08) of operator's three concurrent projects (Nexus / thesis / battery-electrolyte-predictor) for context bleed across Claude sessions.

## Findings
5 leaks identified, thesis → Nexus asymmetry (thesis CLAUDE.md previously pulled in Nexus content). Workspace `/home/nithu/code/CLAUDE.md` split to eliminate cross-project pollution.

## Fixes applied
- Workspace CLAUDE.md slimmed to project index only — no domain content.
- Per-project memory directories enforced under `~/.claude/projects/<slug>/`.
- Discovery rule: check `pwd` + `git remote -v` when project context ambiguous.

## Source
`docs/architecture/cross-project-fixes.md` (full audit + remediation).

Linked to: [[Decisions-MOC]], [[Operator-Principles]], [[Memory-MOC]]
