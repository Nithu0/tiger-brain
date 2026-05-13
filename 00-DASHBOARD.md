---
tags: [dashboard, meta]
type: meta
created: 2026-05-11
---

# 00-DASHBOARD

Single-screen overview. If you opened the vault and don't know where to go — start here.

## Active projects

| Project | What | Status pointer |
|---|---|---|
| **Nexus** | XAUUSD prop-firm trading system, currently demo-mode | [[01-nexus/runtime/Phase-Status-Pointer]] -> `ai-assistent/docs/ops/phase-status.md` |
| **Thesis** | NTNU master's, ML for solid-state battery electrolytes | [[Thesis-MOC]] -> `Master-oppgave/` + `battery-electrolyte-predictor/` |
| Business | Lighter ops/admin notes | [[Business-MOC]] |
| Career | Career-track notes | [[Career-MOC]] |
| Learning | Notes from courses, papers, deep dives | [[Learning-MOC]] |

## Quick links

- [[01-CURRENT-FOCUS]] — what operator is actually working on this week
- [[BRAIN-RULES]] — operating rules for vault (humans + Claude)
- [[claude-context/START-HERE|Claude START-HERE]] — entry point for Claude Code sessions
- [[Nexus-MOC]] · [[Thesis-MOC]] · [[Decisions-MOC]] · [[Workflows-MOC]]

## Today's gates

- **Foundation gate state**: live truth in `ai-assistent/docs/ops/phase-status.md`. Vault mirror: [[01-nexus/runtime/Phase-Status-Pointer]]. Do not duplicate state here.
- Calibration must pass before any live-capital flip — see [[01-CURRENT-FOCUS]].

## Where am I writing right now?

- Brain-dumps, drafts, half-thoughts -> [[00-claude-inbox/README|00-claude-inbox]] (see lifecycle there)
- Active work context -> [[01-CURRENT-FOCUS]]
- Anything load-bearing for a project -> the project's own repo (not here)

## How this vault works in 60 seconds

- **Inbox first**: dump in `00-claude-inbox/<project>/`, promote later — don't optimize on write.
- **MOCs** (`_maps/`) are curated index pages; atomic notes link up to a MOC.
- **Source of truth lives in code repos**, not the vault. Vault holds context, decisions, and pointers.
- **`_decisions/`** = immutable decision log. **`_runbooks/`** = how-to. **`_promote-candidates/`** = staging before repo docs.
- **`90-archive/`** = cold storage; nothing is deleted, just moved.
- **Claude reads** `claude-context/` + project CLAUDE.md files. Don't put secrets anywhere.

---

Sist oppdatert: 2026-05-11
