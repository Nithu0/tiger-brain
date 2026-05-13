---
tags: [meta, claude-context]
type: meta
created: 2026-05-11
---

# SYSTEM-MAP — mechanical map of the vault

Companion to [[START-HERE]] and [[RULES]]. Tells Claude what lives where.

## Folder list

| Path | Purpose |
|---|---|
| `README.md` | Vault hub, entry point for humans |
| `00-DASHBOARD.md` | Top-level dashboard, operator-owned |
| `01-CURRENT-FOCUS.md` | Operator's "what I'm doing now" |
| `00-claude-inbox/` | Claude write zone (107 files), raw thinking by project |
| `01-nexus/` | Nexus XAUUSD trading firm notes |
| `02-thesis/` | NTNU master's thesis (battery electrolyte ML) |
| `03-business/` | Business notes |
| `04-career/` | Career notes |
| `05-learning/` | Learning notes |
| `90-archive/` | Archived (NOT current) |
| `_decisions/` | 8 append-only "when X, do Y" decision-trees |
| `_maps/` | 46 MOCs + meta, structural index |
| `_runbooks/` | 6 runbooks (operational procedures) |
| `_promote-candidates/` | Notes being polished for promotion |
| `claude-context/` | This folder — Claude's read-first context |

## Where Claude reads

Everywhere. Priority order: `claude-context/` → `00-DASHBOARD.md` → `01-CURRENT-FOCUS.md` → relevant project MOC in `_maps/` → project subtree → inbox.

## Where Claude writes

Only `00-claude-inbox/<project>/` and own session notes. `_promote-candidates/` only when explicitly asked. See [[RULES]] "Write zone".

## Source-of-truth pointers

- **Nexus code** — `/home/nithu/code/ai-assistent`
- **Nexus live status** — `/home/nithu/code/ai-assistent/docs/ops/phase-status.md`
- **Thesis code** — `/home/nithu/code/Master-oppgave` (LaTeX) + `/home/nithu/code/battery-electrolyte-predictor` (ML pipeline)
- **Thesis live status** — Overleaf + repo `CLAUDE.md`

## Companion files in ~/.claude/

- `~/.claude/CLAUDE.md` — global operator baseline (loads every session)
- `/home/nithu/code/CLAUDE.md` — workspace meta (points to projects)
- `/home/nithu/code/<project>/CLAUDE.md` — project-specific
- `~/.claude/projects/-home-nithu-code/memory/MEMORY.md` — per-project memory index
- `~/.claude/projects/-home-nithu-code/memory/reference_available_tools.md` — tool roster (check before workarounds)

## Vault layout (ASCII)

```
Brain/
├── README.md
├── 00-DASHBOARD.md
├── 01-CURRENT-FOCUS.md
├── claude-context/          <- you are here
│   ├── START-HERE.md
│   ├── RULES.md
│   ├── SYSTEM-MAP.md
│   └── CURRENT.md
├── 00-claude-inbox/         <- Claude write zone
├── 01-nexus/                <- XAUUSD trading firm
├── 02-thesis/               <- NTNU battery ML
├── 03-business/
├── 04-career/
├── 05-learning/
├── 90-archive/              <- NOT current
├── _decisions/              <- append-only
├── _maps/                   <- MOCs (operator-owned)
├── _runbooks/
└── _promote-candidates/
```

Sist oppdatert: 2026-05-11
