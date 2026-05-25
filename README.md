---
tags: [moc, hub]
type: moc
created: 2026-05-08
updated: 2026-05-13
---

# 🐯 tiger-brain

> Personal second-brain for operator [@Nithu0](https://github.com/Nithu0). Obsidian vault + GitHub-tracked knowledge graph. Companion to project repos: [`ai-assistent`](https://github.com/Nithu0/ai-assistent) (Nexus XAUUSD trading firm), [`Master-oppgave`](https://github.com/Nithu0/Master-oppgave) (NTNU thesis).

**Status:** v0.1.0 share-ready · [`SYSTEM-AUDIT`](./SYSTEM-AUDIT.md) 9/10 · sanity 8/8 green · 17 commits · 351 notes

**Are you a teammate?** Start with [`WELCOME.md`](./WELCOME.md) → [`TEAMMATE-ONBOARDING.md`](./TEAMMATE-ONBOARDING.md) → [`BRAIN-RULES.md`](./BRAIN-RULES.md).

**Want the same 8-tab firm command + brain hooks as operator?** Run `bash firm-launcher/install.sh` after cloning. See [`firm-launcher/README.md`](./firm-launcher/README.md).

**Are you Karri?** See [`KARRI-DAY-1.md`](./KARRI-DAY-1.md) for the 3-minute setup.

**Are you Claude?** Read [`claude-context/START-HERE.md`](./claude-context/START-HERE.md) before doing anything.

**Are you the operator?** See [`READY-TO-SHARE.md`](./READY-TO-SHARE.md) and [`OPERATOR-NEXT-STEPS.md`](./OPERATOR-NEXT-STEPS.md).

**What is this, really?** [`WHAT-IS-THE-BRAIN.md`](./WHAT-IS-THE-BRAIN.md) — the architecture of the brain ecosystem.

**Curious about the architecture?** [`WHAT-IS-THE-BRAIN.md`](./WHAT-IS-THE-BRAIN.md) + [`SHARED-INSTANCE-MODEL.md`](./SHARED-INSTANCE-MODEL.md) — how the brain works across multiple machines.

---

# Brain — Home

Personal second brain for operator Nithu. Knowledge graph + thinking layer companion to GitHub repos (which remain the source of truth for code and ops docs).

This note is the **central hub**. Everything else hangs off here. In Graph View, this is the densest cluster — every domain MOC links back.

## 2026-05-25 — Brain Upgrade (workspace-wide AI-OS)

This vault is now part of a workspace-wide AI brain with structured memory distillation, advanced+agentic RAG retrieval, skill registry, YouTube/GitHub ingestion, and parallel agent orchestration.

**New top-level folders (additive — existing folders untouched):**
- `03-skills/` — reusable skills (SKILL.md files) per Hermes-style 3-tier registry
- `08-system-architecture/` — plan + 7 specs + eval-set + integration notes
- `09-retrospectives/` — weekly roll-ups (YYYY-WNN.md)
- `10-tasks/` — workspace-wide task backlog (_open/_in-progress/_blocked/_done)
- `12-youtube/` — distilled YouTube notes (verbatim transcripts in `_library/` only)
- `13-github-repos/` — scored GitHub repo notes (license-guarded)
- `00-templates/` — note-type templates

**New MOCs in `_maps/`:**
System-Architecture, Memory, RAG, Skills, Tasks, Youtube, Github-Repos, Retrospectives.

**Operator runbooks (in `_runbooks/`):**
- `Runbook-Brain-Upgrade-Workflow.md` — daily ops guide
- `Runbook-Sample-Task-Walkthrough.md` — task lifecycle walkthrough
- `Runbook-Brain-Preflight-Checklist.md` — gate activation safety

**Plan + architecture:** [[2026-05-25-brain-upgrade-plan]] (v1.1 draft, 10 modules)

**Backing code:** `/home/nithu/code/command-center/packages/` (skill-registry, youtube-ingest, github-discovery, rag-engine, _template, integration-tests). Push-gated per CLAUDE.md.

**Sister doc:** [[2026-05-24-onprem-ai-strategi]] (private on-prem AI infrastructure strategy).

## Domain MOCs

- [[Nexus-MOC]] — XAUUSD trading firm: strategies, agents, ops, deploy state.
- [[Thesis-MOC]] — Master's thesis on battery electrolyte ML (NTNU).
- [[Business-MOC]] — Side projects, ventures, financial planning.
- [[Career-MOC]] — Roles, applications, skills, network.
- [[Learning-MOC]] — Courses, papers, deep-dives, reading notes.

## Meta MOCs (cognitive OS layer)

- [[Tools-MOC]] — what Claude can do here (MCPs, endpoints, capabilities).
- [[Memory-MOC]] — how Claude's memory is layered across global / workspace / project / per-session.
- [[People-MOC]] — humans + AI roles in the network (Karri, advisor, Claude, Gemini).
- [[Decisions-MOC]] — binding architectural and operational decisions log.
- [[Workflows-MOC]] — recurring workflows (firm-up, parallel-batch, OK kjør gate).

## Conventions

- All cross-references use `[[wiki-links]]` so Graph View renders them as edges.
- Stub-links to notes that don't exist yet are intentional — they appear orange in Graph View as "to-write" prompts.
- Frontmatter `tags:` always present. `type: moc` for index notes, `type: atomic` for leaf notes.
- Inbox-first writing pattern: see [[Workflows-MOC]] → "Promote workflow".

## Layout reference

See `_maps/_README` for MOC conventions and `00-claude-inbox/_README` for the Claude write zone.

## CI

| Check | Status |
|---|---|
| brain-checks | ![brain-checks](https://github.com/Nithu0/tiger-brain/actions/workflows/brain-checks.yml/badge.svg) |
| path-guard | ![path-guard](https://github.com/Nithu0/tiger-brain/actions/workflows/path-guard.yml/badge.svg) |
| secrets-scan | ![secrets-scan](https://github.com/Nithu0/tiger-brain/actions/workflows/secrets-scan.yml/badge.svg) |

## Auto-sync

This vault uses Obsidian Git plugin for live multi-machine sync:
- Auto-pull every 2 min
- Auto-commit every 2 min
- Auto-push every 5 min

Config at `.obsidian/plugins/obsidian-git/data.json`. Both operator + collaborators get the same defaults.

See [`_runbooks/Runbook-Obsidian-Git-Sync.md`](./_runbooks/Runbook-Obsidian-Git-Sync.md).
