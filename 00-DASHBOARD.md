---
tags: [dashboard, meta]
type: meta
created: 2026-05-11
updated: 2026-07-13
---

# 00-DASHBOARD

Single-screen overview. If you opened the vault and don't know where to go — start here.

## Brain System (workspace-wide AI-OS)

> Workspace-wide AI brain: memory distillation + hybrid/agentic RAG + skill registry + YouTube/GitHub ingestion + parallel agent orchestration. Operator-facing usage: [[Runbook-Brain-Upgrade-Workflow]].

- **Koblingskart (hvordan alt snakker sammen):** [[System-Wiring-MOC]] ← start her for systemforståelse
- **Plan:** [[2026-05-25-brain-upgrade-plan]] · **Architecture map:** [[System-Architecture-MOC]]
- **Subsystems:** [[Memory-MOC]] · [[RAG-MOC]] · [[Skills-MOC]] · [[Tasks-MOC]] · [[Youtube-MOC]] · [[Github-Repos-MOC]] · [[Retrospectives-MOC]]
- **Live tracking:** `~/Obsidian/Brain/00-firm-bus/feed.md`
- **Status (2026-07-13):** kjerneloopen er I DRIFT — `brain-orchestrator.service` + `brain-worker.service` (systemd --user) kjører 24/7 med **G4 nightly-distill PÅ** og **G6 queue-watcher PÅ**. memory.db: ~13 400 verbatim + ~13 350 distillerte objekter, 100 % bge-m3-embeddet (dim 1024). Session-recall er hybrid BM25+vektor siden 13.07. C1-9 task-persistence LANDET (agent_tasks + heartbeats verifisert i drift).

## Prosjekter (6 aktive)

| Prosjekt | Hva | MOC / pointer |
|---|---|---|
| **Nexus** | XAUUSD prop-firm trading system, demo-mode | [[01-nexus/Nexus-MOC]] · runtime: [[01-nexus/runtime/Phase-Status-Pointer]] → `ai-assistent/docs/ops/phase-status.md` |
| **Master-oppgave** | NTNU master, ML for solid-state battery electrolytes | [[02-thesis/Thesis-MOC]] → `Master-oppgave/` (+ nestet `battery-electrolyte-predictor/`) |
| **Søking fulltid** | Aktiv jobb-søking (post-master) | [[04-career/Active-Job-Search-MOC]] |
| **Business / strategi** | Managed AI-ops-produkt + leadgen | [[03-business/Business-MOC]] |
| **AS** | Regnskap, inntekt, drift av AS | [[06-AS/AS-MOC]] |
| **Personlig** | Effektivitet, mat, trening, vaner | [[07-personlig/Personlig-MOC]] |

Hver pane i `firm`-launcheren peker på én av disse — se [[01-CURRENT-FOCUS]] for gjeldende pane-layout.

## Quick links

- [[01-CURRENT-FOCUS]] — what operator is actually working on this week
- [[System-Wiring-MOC]] — verifisert koblingskart (hooks, daemons, køer, GPU)
- [[BRAIN-RULES]] — operating rules for vault (humans + Claude)
- [[claude-context/START-HERE|Claude START-HERE]] — entry point for Claude Code sessions
- [[TOOLBOX-MOC]] — kanonisk verktøy-/skill-roster (sjekk FØR manuelle workarounds)
- [[00-command-center/README]] — workspace-wide control plane (`/home/nithu/code/command-center`)

## Health & ops

- Dyp-analyse av systemkoblingen: [[2026-07-13_system-wiring-deep-analysis]] (00-claude-inbox/command-center/)
- Manuelle helsesjekker: `_bin/brain-doctor.sh` (memory-loop) · `_bin/brain-status.sh` · `journalctl --user -u brain-orchestrator -u brain-worker`
- Automatisk vakt: kun `nexus-watch.sh` (cron, Nexus). Failed agent_tasks varsles IKKE automatisk ennå.
- Historiske audits/incidents: `90-archive/root-2026-05/`

## Today's gates

- **Foundation gate state**: live truth in `/home/nithu/code/ai-assistent/docs/ops/phase-status.md`. Vault mirror: [[01-nexus/runtime/Phase-Status-Pointer]]. Do not duplicate state here.
- Nexus live-capital flip er operatør-gated; CALIBRATION_MODE=RECOMMEND_ONLY siden 27.06 — se [[01-CURRENT-FOCUS]].
- Brain-gates G4 + G6: **PÅ i drift** (flippet 2026-06-08, verifisert 2026-07-13). Gjenstående operatør-gate: G3 worktree-default.
- Vast GPU-boks (~$289/mnd, idle): PAUSE/BEHOLD-beslutning utestående — se [[System-Wiring-MOC]] §GPU.

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
- Run `bash scripts/sanity.sh` before every push — local equivalent of CI.

---

Sist oppdatert: 2026-07-13 (forrige 2026-05-14 — 8 uker drift; oppdatert fra dyp-analyse `w7c1cutap`)
