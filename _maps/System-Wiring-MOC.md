---
tags: [moc, system, wiring]
type: moc
created: 2026-07-13
verified: 2026-07-13
---

# System-Wiring-MOC — hvordan alt faktisk snakker sammen

Verifisert koblingskart per **2026-07-13** (workflow `w7c1cutap`, 7 lesere + critic,
alle koblinger sjekket mot kildekode/kjørende prosesser — ikke docs).
Full analyse: [[2026-07-13_system-wiring-deep-analysis]].
Statuskoder: **LIVE** = kjører automatisk · **MANUAL** = finnes, må trigges · **DEAD** = ubrukt/ødelagt.

## Kjerneloopen (Memory-OS) — LIVE ende-til-ende

```
Claude-sesjon (Stop-hook)
  → session-capture.sh → memory.db verbatim_exchanges     (13 4xx rader)
brain-orchestrator.service (systemd, G4 PÅ)
  → nightly-distill → agent_tasks (brain-orchestrator.db)
brain-worker.service (systemd)
  → distillDay (Haiku) → memory_objects (13 3xx, 100 % bge-m3-embeddet, dim 1024)
  → embedBatch → Ollama bge-m3 (lokal, pinnet av ollama-keepwarm.timer)
Claude-sesjon (SessionStart-hook)
  → global-session-context.sh → rag-recall.sh → hybrid BM25+vektor recall
```

- Substrat: `~/.claude/projects/-home-nithu-code/state/memory.db` (188 MB) — se [[Memory-MOC]]
- Recall: hybrid-først siden 2026-07-13 (før: tvunget BM25-only; FTS5-bindestrek-bug fikset samme dag) — se [[RAG-MOC]]
- Backup: `litestream.service` (kontinuerlig, kun samme disk)
- Kjente hull: distill tar kun "yesterday" — ingen catch-up for dager maskinen var av (09.07 ble backfillet manuelt 13.07)

## Ingestion (G6) — LIVE per 2026-07-13

```
12-youtube/_queue/*.url + 13-github-repos/_queue  ← menneske/pane dropper filer
  → queue-watcher (brain-orchestrator, G6 PÅ) → agent_tasks (role=ingest)
  → brain-worker → drainYoutubeQueue / drainGithubQueue → notat + verbatim-capture
```

- **KUN `*.url`-filer med enkeltvideo-URL** konsumeres (se [[Youtube-MOC]]); kanaler/playlists → `_queue/_manual/`
- Var død 23.06–13.07: `.txt`-lister kunne aldri konsumeres + `yt-dlp ENOENT` i systemd-PATH (begge fikset 13.07)
- `14-books/_queue` overvåkes IKKE (drainBook-seam finnes, mappen står ikke i DEFAULT_QUEUE_DIRS)

## Session-kontekst (hver pane, hver sesjon) — LIVE

`~/.claude/settings.json` hooks:

| Hook | Kjede |
|---|---|
| SessionStart | `global-session-context.sh` → GOALS-parse + CURRENT-STATE + CHARTER §3 + cost-brief + toolbox + RAG-recall + inbox-tail (kun siste 1200 bytes!) |
| SessionStart | `firm-capture-session-id.sh` (per-rolle auto-resume) |
| Stop | thesis-autopush (kun Master-oppgave) · nexus `distill.sh` (kun ai-assistent) · `gen-current-state.sh` · `session-capture.sh` |
| statusLine | `firm-statusline.sh` (rolle via prosess-ancestry → låsefil) |

## Firm-koordinering — delvis LIVE

- [[CHARTER]]-regler injiseres i hver sesjon (LIVE)
- `feed.md` appendes av paner + `firm-inbox-watch.sh` (LIVE, men 188 KB uten rotasjon; ~350 av 1180 linjer er støy)
- `inbox/<role>.md` + watcher-banner (LIVE i firm-paner)
- **PRESENCE.md er DØD** (ingen writer siden 13.05 — CHARTER regel 1 peker på en fil ingen skriver)
- **firm-task-claim/complete.sh finnes IKKE på HEAD** (kun commit 194b100) — 10-tasks-livssyklusen har aldri vært brukt
- `firm-heartbeat.sh` + `pane-status/` = DEAD (bygget, aldri wiret)
- Launchere: `firm`/`firmt`/`firmz`/`skole` (alias finnes) · `gull`/`salg` (script finnes, alias mangler i bashrc) — se [[Tools-MOC]]

## GPU + agent-fabrikk — mest DEAD/idle

- **Vast RTX 4090 (instans 42212247): ~$289/mnd, i praksis IDLE** (0 % util, 261 requests på 3 uker; egen audit sa SHOULD-PAUSE 25.06). Operatør-beslutning utestående.
- `vast-job.sh` on-demand (auto-destroy verifisert) — brukt én gang. PII-ruting i `firm-job-run.sh` er solid og fail-closed.
- Hermes: gateway LIVE (Telegram, kun operatør), men **Docker-sandbox nede** (Docker Desktop av) og kanban-dispatcher aldri brukt (0 tasks).
- Remote-executors: bygget, ikke enablet (operatør-gated).
- Lokal Ollama (CPU): LIVE og den eneste GPU/LLM-ressursen i faktisk daglig bruk (bge-m3-embedding + recall).

## Overvåkning — tynn

- `nexus-watch.sh` (cron 30 min hverdager) — eneste automatiske helsevakt, kun Nexus
- `brain-doctor.sh` / `brain-status.sh` / `cost-guard.sh` / `flag-drift.mjs` / `brain-retention.sh` — alle MANUAL, ingen schedule
- **Ingen** varsling for failed agent_tasks / stale heartbeats; dashboardet (apps/api) importerer ingen brain-pakker
- Forensisk vindu: journal ~1 døgn + agent_tasks prunes etter 7 d — feil forsvinner sporløst

## Kunnskapsgrafen (denne vaulten)

- Innganger: [[00-DASHBOARD]] → [[01-CURRENT-FOCUS]] → denne + prosjekt-MOC-er ([[Nexus-MOC]], [[Packages-MOC]], [[Memory-MOC]], [[RAG-MOC]], [[TOOLBOX-MOC]], [[Youtube-MOC]], [[Decisions-MOC]])
- `00-claude-inbox/` = 771 notater (60 % av vaulten), nesten helt ulenket — rapport-dump, ikke graf. Promote-lifecycle brukes ikke i skala.
- Orphan-klynger: `12-youtube/transcripts` (26 notater, 0 innlenker), `_library`, `14-books`, `06-investment-research`
- **Obsidian git-sync: brutt 10.06–13.07** (33 dager, 103 ucommittede filer) — lokal checkpoint tatt 13.07; hvorfor plugin-sync stoppet er uavklart

## Verktøy-oppslag

Kanonisk roster: [[TOOLBOX-MOC]] · `command-center/docs/ops/FIRM-TOOLBOX.md` · `_bin/tools-roster.txt`.
Mekanisk vault-kart: [[SYSTEM-MAP]] (claude-context/).

## Endringslogg

- 2026-07-13: Opprettet fra dyp-analyse. Samme dag fikset: hybrid-recall-flip + FTS5-bug, G6 yt-kø (.txt→.url + systemd-PATH), distill-backfill 09.07, rot-arkivering, dashboard-refresh.
