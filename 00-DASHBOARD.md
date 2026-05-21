---
tags: [dashboard, meta]
type: meta
created: 2026-05-11
---

# 00-DASHBOARD

Single-screen overview. If you opened the vault and don't know where to go — start here.

## Prosjekter (6 aktive)

| Prosjekt | Hva | MOC / pointer |
|---|---|---|
| **Nexus** | XAUUSD prop-firm trading system, demo-mode | [[01-nexus/01-nexus-MOC\|Nexus-MOC]] · runtime: [[01-nexus/runtime/Phase-Status-Pointer]] → `ai-assistent/docs/ops/phase-status.md` |
| **Master-oppgave** | NTNU master, ML for solid-state battery electrolytes | [[02-thesis/Thesis-MOC\|Thesis-MOC]] → `Master-oppgave/` + `battery-electrolyte-predictor/` |
| **Søking fulltid** | Aktiv jobb-søking (post-master) | [[04-career/Active-Job-Search-MOC\|Active-Job-Search-MOC]] *(eies av career-agent)* |
| **Business / strategi** | Lett ops/strategi-notater | [[03-business/Business-MOC\|Business-MOC]] |
| **AS** | Regnskap, inntekt, drift av AS | [[06-AS/AS-MOC\|AS-MOC]] *(eies av AS-agent)* |
| **Personlig** | Effektivitet, mat, trening, vaner | [[07-personlig/Personlig-MOC\|Personlig-MOC]] *(eies av personlig-agent)* |

Hver pane i `firm`-launcheren peker på én av disse — se [[_runbooks/firm-8-pane-2026-05-14]].

## Quick links

- [[01-CURRENT-FOCUS]] — what operator is actually working on this week
- [[BRAIN-RULES]] — operating rules for vault (humans + Claude)
- [[claude-context/START-HERE|Claude START-HERE]] — entry point for Claude Code sessions
- [[_runbooks/firm-8-pane-2026-05-14|firm 8-pane runbook]] — current multi-Claude operating model
- [[_runbooks/firm-launcher|firm-launcher v1 runbook]] — historical reference
- [[00-command-center/README]] — Workspace-wide control plane (Next.js+Fastify+SQLite at /home/nithu/code/command-center)

## Health & ops

- [[SYSTEM-AUDIT]] — most recent system audit
- [[SECURITY-INCIDENT-API-KEY]] — open security incident, awaiting operator decision
- [[OPERATOR-NEXT-STEPS]] — checklist for operator (gh setup, branch protection, secret-purge decision)
- [[FINAL-SHARING-CHECKLIST]] — pre-share verification before first push
- Latest snapshot: [[STATE-2026-05-13-FINAL]]

## Today's gates

- **Foundation gate state**: live truth in `/home/nithu/code/ai-assistent/docs/ops/phase-status.md`. As of 2026-05-11 the Foundation gate is **5/5 🟢** per phase-status. Vault mirror: [[01-nexus/runtime/Phase-Status-Pointer]]. Do not duplicate state here.
- Calibration must pass before any live-capital flip — see [[01-CURRENT-FOCUS]].
- Brain repo: target `Nithu0/tiger-brain` (private) — awaits GH UI create + push (see [[READY-TO-SHARE]] section 6)

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

Sist oppdatert: 2026-05-14
