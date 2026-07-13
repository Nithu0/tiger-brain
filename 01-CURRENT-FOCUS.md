---
tags: [focus, meta, status]
type: meta
created: 2026-05-11
updated: 2026-07-13
---

# 01-CURRENT-FOCUS

What operator is actually working on **right now**. One file. Keep it honest.

> When this drifts, fix it in this file — don't scatter status across notes.

## Primary focus

**Nexus — demo-mode, læringsloop + GPU-leveranse under verifisering.**

- CALIBRATION_MODE=RECOMMEND_ONLY siden 27.06, SAFE_AUTO_APPLY OFF, mults=1.0. Live-capital flip er operatør-gated.
- GPU+læringsloop-leveranse merget 11.07 (PR #228–#234, flag-gated/behavior-neutral) — operatør-flip-liste i `00-claude-inbox/ai-assistent/2026-07-11_gpu-laeringsloop-leveranse.md`.
- Læringsloop-evidensbase + per-trade provenance-monitor: `00-claude-inbox/nexus/2026-07-03_learning-loop-evidence-base.md` (flight-recorder-spec §4; code-2 venter på ai-1s entry_snapshot).
- Live truth: `ai-assistent/docs/ops/phase-status.md` (mirror: [[01-nexus/runtime/Phase-Status-Pointer]]). Related: [[Nexus-MOC]], [[Decisions-MOC]].

## Secondary

**Master-oppgave — chapters in flight.**

- Active drafting in `Master-oppgave/` (LaTeX/Overleaf), code/results fra nestet `battery-electrolyte-predictor/`.
- Auto-push hook aktiv for thesis-repoet only.
- MOC: [[Thesis-MOC]].

## Workspace-meta — command-center + brain

**Brain-autonomien er I DRIFT** (se [[System-Wiring-MOC]] for hele koblingskartet):

- `brain-orchestrator.service` + `brain-worker.service` kjører 24/7 (systemd --user). **G4 nightly-distill + G6 queue-watcher: PÅ.** C1-9 task-persistence landet og verifisert (agent_tasks, heartbeats, lease/reaper).
- Memory-loop lukket: capture (Stop-hook) → distill (Haiku, nightly) → embed (lokal Ollama bge-m3, keepwarm) → recall (SessionStart, hybrid BM25+vektor siden 13.07).
- Gjenstående svakheter (fra dyp-analysen 13.07): ingen distill-catch-up for dager maskinen er av · ingen automatisk varsling av failed tasks · brain-worker kjører tsx fra src (bør bygges til dist) · vault-notater nesten ikke embeddet (86 av ~1260).
- **Node-migration**: penger→MVP→hardware (~aug 2026) står. Brain kjører lokalt/cloud-først og migreres uendret. Kanon: [[2026-06-03-node-migration-MOC]].
- **Vast-boksen (~$289/mnd) er idle** — PAUSE-beslutning hos operatør.

## Aktive prosjekt-tråder (6)

| Prosjekt | Tråd nå | Eier-pane |
|---|---|---|
| Nexus | Læringsloop-verifisering + GPU-flip-liste; ingen live-flip uten "OK kjør" | `ai-1`, `ai-2` |
| Master-oppgave | Kapittel-drafting + figur-pipeline | `thesis-1` |
| Søking fulltid | Scrape-agent PAUSET siden 14.06 (bevisst? sjekk conductor.timer) | `soking-1` |
| Business | Managed AI-ops (Pål/RefiPrep først), leadgen | `code-1`/`code-2` |
| AS | Regnskap + inntekt-oppfølging | `as-1` |
| Personlig | Lav aktivitet (personal-1-pane droppet fra firm-oppsettet 11.07) | — |

Workspace-meta (cross-cutting fixes, brain hygiene, runbooks) ligger på `code-1` + `code-2`.

## Multi-Claude operating model (firm)

`firm` (alias) → `command-center/_bin/firm-wt-split.sh`: 8 Claude-paner i 4×2-grid + åpner automatisk 8 Codex-paner i eget vindu (`FIRM_NO_CODEX=1` for å slippe; på 16 GB RAM lukker operatør Codex-vinduet ved behov). Pane-navn i WT-tittel + Claude statusLine (`rolle · prosjekt`).

| Pane | Rolle | Prosjekt | cwd |
|---|---|---|---|
| V1 | `code-1` | workspace | `~/code` |
| V2 | `code-2` | workspace | `~/code` |
| V3 | `ai-1` | nexus | `~/code/ai-assistent` |
| V4 | `ai-2` | nexus | `~/code/ai-assistent` |
| H1 | `thesis-1` | master-oppgave | `~/code/Master-oppgave` |
| H2 | `as-1` | AS | `~/code/AS` |
| H3 | `soking-1` | soking-fulltid | `~/code/Søking fulltid` |
| H4 | `personal-1` | personlig | *(droppet 11.07 — trengs ikke)* |

Fokus-launchere (én om gangen): `skole` (4×thesis) · `gull` (4×nexus, alias mangler i bashrc) · `salg` (3×call-center, alias mangler).

### Koordinering

- Felles buss: `00-firm-bus/feed.md` (én linje per event). Regler: [[CHARTER]] §3 (injiseres i hver sesjon).
- Per-pane inbox: `00-firm-bus/inbox/<role>.md` — handoffs. NB: session-start viser kun siste 1200 bytes; les hele fila ved tvil.
- Lange rapporter → `00-claude-inbox/<project>/`, aldri i `feed.md`.
- Day-end handoffs → `handoffs/`.
- PRESENCE.md er død (ingen writer) — bruk feed-online-linjer inntil videre.

## Parked / not now

- Remote-autonomy executors (Telegram→pane): bygget, ikke enablet (operatør-gated).
- Hermes kanban-dispatcher: aldri brukt; Docker-sandbox krever at Docker Desktop kjører.
- 14-books-køen: ikke overvåket av queue-watcher ennå.
- Learning backlog — capture in inbox, don't promote unless directly relevant.

## Active TODOs

1. **Operatør-beslutning:** Vast-boksen ($289/mnd, idle siden juni) — pause/destroy eller wire reell last (Nexus-worker local-vei)?
2. **Operatør:** hvorfor stoppet Obsidian Git-plugin-syncen 10.06? (Lokal checkpoint tatt 13.07; push av vault + command-center venter på "OK kjør".)
3. Distill-catch-up (dager uten memory_objects) + failed-task-varsling i morning-briefing — code-2.
4. brain-worker: bygg dist + pek uniten på artefakt (vekk fra tsx/src i delt checkout) — code-2.
5. Vault-notat-backfill til memory.db (1260 notater, ~7 % dekket) — kost-estimat før kjøring.
6. `gull`/`salg`-aliaser i ~/.bashrc (operatør, dotfiles er gated).

---

Sist oppdatert: 2026-07-13 (forrige 2026-05-14/06-03; oppdatert fra dyp-analyse `w7c1cutap` — G4/G6 er PÅ, ikke OFF som forrige versjon sa)
