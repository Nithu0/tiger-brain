---
tags: [meta, claude-context]
type: meta
created: 2026-05-11
updated: 2026-07-13
---

# SYSTEM-MAP — mechanical map of the vault

Companion to [[START-HERE]] and [[RULES]]. Tells Claude what lives where.
For hvordan systemene SNAKKER sammen (hooks, daemons, køer): [[System-Wiring-MOC]].

## Folder list

| Path | Purpose |
|---|---|
| `README.md` | Vault hub, entry point for humans |
| `00-DASHBOARD.md` | Top-level dashboard, operator-owned |
| `01-CURRENT-FOCUS.md` | Operator's "what I'm doing now" |
| `00-claude-inbox/` | Claude write zone (~770 filer), rapporter per prosjekt — stort sett ulenket fra grafen |
| `00-firm-bus/` | Inter-pane koordinering: [[CHARTER]], feed.md, inbox/<role>.md |
| `00-command-center/` | Command-center-notater (kontrollplan) |
| `01-nexus/` | Nexus XAUUSD trading firm — [[Nexus-MOC]] |
| `02-thesis/` | NTNU master's thesis (battery electrolyte ML) |
| `03-business/`, `04-career/`, `05-learning/` | Domene-notater (egne MOC-er) |
| `03-skills/` | Skill-registry 3-tier + [[TOOLBOX-MOC]] (kanonisk verktøy-roster) |
| `06-AS/`, `07-personlig/` | AS-regnskap · personlig (PII — aldri leid GPU) |
| `06-investment-research/` | Investering (mangler MOC) |
| `08-system-architecture/` | Specs + planer (brain-upgrade, node-migration) |
| `10-tasks/` | Task-livssyklus `_open/_in-progress/_done` — per 2026-07-13 ALDRI brukt (claim-scripts ikke på HEAD) |
| `12-youtube/` | Ingestion-kø + transcripts — [[Youtube-MOC]]; kø tar KUN `*.url` enkeltvideo |
| `13-github-repos/` | GitHub-discovery-kø (samme mønster) |
| `14-books/` | Bok-kø — IKKE overvåket av queue-watcher ennå |
| `_library/` | Rå-materiale (transcripts m.m., mest ulenket) |
| `90-archive/` | Archived (NOT current) — inkl. `root-2026-05/` (mai-sprint-filene) |
| `_decisions/` | Append-only decision-trees — [[Decisions-MOC]] |
| `_maps/` | MOC-lag, strukturell indeks — best koblede mappe |
| `_runbooks/` | Operasjonelle prosedyrer |
| `_promote-candidates/` | Notes being polished for promotion |
| `claude-context/` | This folder — Claude's read-first context |
| `handoffs/` | Day-end handoffs across sessions/machines |

## Where Claude reads

Everywhere. Priority order: `claude-context/` → `00-DASHBOARD.md` → `01-CURRENT-FOCUS.md` → [[System-Wiring-MOC]] → relevant project MOC in `_maps/` → project subtree → inbox.

## Where Claude writes

Primært `00-claude-inbox/<project>/` og egne sesjonsnotater; MOC-/dashboard-vedlikehold når operatør ber om det. `_promote-candidates/` only when explicitly asked. See [[RULES]] "Write zone".

## Source-of-truth pointers

- **Nexus code** — `/home/nithu/code/ai-assistent`
- **Nexus live status** — `/home/nithu/code/ai-assistent/docs/ops/phase-status.md`
- **Thesis code** — `/home/nithu/code/Master-oppgave` (LaTeX) + `Master-oppgave/battery-electrolyte-predictor` (ML pipeline — NB: nestet, ikke toppnivå)
- **Brain-produktet (kode)** — `/home/nithu/code/command-center/packages/` (orchestrator, worker, memory-engine, rag-engine m.fl.)
- **Automatisering** — `/home/nithu/code/command-center/_bin/` + `~/.claude/settings.json` (hooks) + `~/.config/systemd/user/` (daemons)
- **Memory-substrat** — `~/.claude/projects/-home-nithu-code/state/memory.db`

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
├── 00-claude-inbox/         <- Claude write zone (rapport-dump)
├── 00-firm-bus/             <- pane-koordinering (CHARTER, feed, inbox)
├── 00-command-center/
├── 01-nexus/ … 08-system-architecture/
├── 10-tasks/  12-youtube/  13-github-repos/  14-books/
├── 90-archive/              <- NOT current
├── _decisions/  _maps/  _runbooks/  _library/
└── _promote-candidates/  handoffs/
```

Sist oppdatert: 2026-07-13 (fra dyp-analyse `w7c1cutap`; forrige 2026-05-11 — da fantes ikke firm-bus, command-center-mappa, kø-mappene eller memory-OS-runtimen)
