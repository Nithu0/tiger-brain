---
title: System-wiring dyp-analyse
date: 2026-07-13
author: code-2 (workflow w7c1cutap — 7 parallelle lesere + completeness-critic, 560k tokens, alle koblinger verifisert mot kildekode/kjørende prosesser)
tags: [analyse, wiring, brain, gpu, obsidian]
related: "[[System-Wiring-MOC]]"
---

# System-wiring dyp-analyse — 2026-07-13

Bestilling: «gå gjennom koblingen av systemet — hvordan ting snakker sammen; koble bedre i Obsidian; mer stabilt system som vet hvilke verktøy som finnes; gode ML-tilganger; bruk GPU-en effektivt.»

Navigerbart koblingskart: [[System-Wiring-MOC]]. Dette dokumentet er evidensen + beslutningsgrunnlaget.

## TL;DR

Kjernen (memory-loopen) er **reelt i drift og bedre enn docs sier** — C1-9 er landet, G4/G6 er PÅ, 13 333 objekter er 100 % bge-m3-embeddet. Men systemet «tenkte» dårligere enn det kunne: vektorindeksen ble aldri brukt automatisk (hardkodet BM25-fallback + en FTS5-bug som drepte hybrid-lanen stille), ingestion var død i 20 dager (filformat + PATH), én distill-dag var permanent tapt, og Obsidian-git-syncen har vært brutt i 33 dager uten at noe varslet. Rundt kjernen står mye ferdigbygget men u-tilkoblet kapasitet (presence, task-livssyklus, remote-executors, kanban, Vast-boksen til $289/mnd idle).

**Fikset i dag (13.07):** hybrid recall PÅ (FTS5-bug + fallback-flip, commit `c64f6fb`) · distill-backfill 09.07 (22 objekter gjenskapt) · G6-ingestion reparert e2e (23 videoer i kø; .txt→.url + `yt-dlp` i systemd-PATH) · dashboards/SYSTEM-MAP/Youtube-MOC oppdatert fra mai- til juli-virkelighet · [[System-Wiring-MOC]] opprettet · 12 stale rot-filer arkivert · lokal git-checkpoint av vaulten.

## 1. Hva som faktisk er LIVE (verifisert, ikke fra docs)

| Kjede | Mekanisme | Bevis |
|---|---|---|
| Capture | Stop-hook → session-capture → memory.db verbatim | logg t.o.m. 11.07, 13 4xx rader |
| Distill | orchestrator (G4=1) → agent_tasks → worker → Haiku distillDay | journal 05:03 13.07, done-rader |
| Embed | memory-engine → Ollama bge-m3 lokal (keepwarm-timer) | 13333/13333 vektorer, dim 1024 |
| Recall | SessionStart-hook → rag-recall (hybrid fra i dag) | målt 0,9–1,3 s varm |
| Ingest | G6 queue-watcher → ingest-task → drainYoutube/Github | enqueue+complete 21:14 i dag |
| Firm-kontekst | SessionStart → GOALS+CURRENT-STATE+CHARTER+recall+inbox-tail | settings.json + script lest |
| Nexus-vakt | cron nexus-watch hvert 30. min | crontab + fersk watch.log |
| Backup | litestream (memory.db, kontinuerlig) | service aktiv — men KUN samme disk |

## 2. Hovedfunn (verifisert av ≥2 uavhengige lesere + critic)

1. **Vektorindeksen var aldri i automatisk bruk.** `RAG_RECALL_FORCE_FALLBACK=1` hardkodet i session-hooken, OG hybrid-lanen krasjet uansett stille på FTS5-syntaks for alle queries med bindestrek (`code-2`, `command-center` — dvs. alltid). → Fikset: token-sanitering i `rag-recall.ts` + hybrid-først med BM25-fallback. Målt 0,9 s varm.
2. **2026-07-09 var permanent tapt fra det distillerte korpuset** (22 rader, task failed 3/3 «Connection error», ingen retry-mekanisme, bevis prunes ~17.07). → Backfillet i dag: 22 memory_objects gjenskapt. Strukturelt hull består: nightly tar kun «yesterday» — maskin av >24 t = nytt hull.
3. **G6-ingestion var død ende-til-ende:** køen inneholdt kun `.txt`-lister drainen aldri kan konsumere, og da gyldige `.url`-filer kom inn feilet alt på `spawn yt-dlp ENOENT` (systemd-PATH mangler `~/.local/bin`). → Begge fikset; 23 videoer requeuet.
4. **Obsidian git-sync brutt siden 10.06** (33 dager, 103 ucommittede filer). Shared-instance med Karri + eneste off-disk-kopi av vaulten var de facto nede. Ingen helsesjekk fanget det. → Lokal checkpoint-commit tatt; push + plugin-diagnose hos operatør.
5. **Null automatisk synlighet for autonomi-feil:** dashboardet (apps/api) importerer ingen brain-pakker; failed tasks/stale heartbeats varsles ingen steder; journal ~1 døgn + 7d-prune = feil forsvinner sporløst. Bryter i praksis «health-checks REPORT»-prinsippet.
6. **Vast RTX 4090: ~$289/mnd mot ~null last.** 261 requests på 3 uker, 0 % util nå; egen audit sa SHOULD-PAUSE 25.06. NB: én ukjent klient-IP (152.55.177.65) fikk 200-er mot `/v1/chat/completions` i dag — identifiser før pause. Memory-påstanden «trading dashboard/api LIVE på GPU» stemmer ikke (ingen node-app/docker på boksen).
7. **Bygget-men-aldri-tilkoblet-klassen:** PRESENCE.md (ingen writer; CHARTER-regel peker på den), firm-task-claim/complete.sh (finnes kun i commit `194b100`, ikke HEAD — 10-tasks-livssyklusen fiktiv), firm-heartbeat + pane-status, remote-executors (by design, gated), Hermes kanban (0 tasks noensinne), Docker-sandbox (Docker Desktop av), flag-drift.mjs + brain-retention.sh + cost-guard.sh (ingen schedule), eval-harness (aldri re-kjørt mot 13k-korpus).
8. **Obsidian-grafen:** 60 % av vaulten (00-claude-inbox, 771 notater) ulenket; dashboards var 8 uker stale og faktuelt gale (sa G4/G6 OFF — de er PÅ); Youtube-MOC beskrev en pipeline som ikke matchet koden; orphan-klynger (transcripts, _library, 14-books). → Dashboards/MOC-er fikset i dag; inbox-lenking er større jobb (se §4).
9. **brain-worker kjører tsx fra `src/` i delt checkout** — en peer som redigerer brain-worker/src kan velte 24/7-daemonen. Orchestrator kjører bygget dist; worker bør også.
10. **ML-dekning:** vault-notater nesten ikke i minnet (86 av ~1260 = 7 %); research-os har 357 MB/164 PDF-er med `sections=0, extracted_facts=0` (pipeline bygget, aldri kjørt); Søking-scrapen stille siden 14.06.

## 3. GPU-strategi (bestillingens «bruk GPU-en effektivt»)

Realiteten: den eneste ML-ressursen i daglig bruk er **lokal CPU-Ollama** (bge-m3-embedding + recall) — og den dekker behovet godt. Den leide 4090-en står idle til $9,6/dag.

Anbefaling (operatør-beslutning):
- **Pause/destroy Vast-boksen**, behold on-demand `vast-job.sh` (auto-destroy verifisert; alt på boksen gjenskapes på ~10 min per jobb). Alternativ hvis beholdes: wire Nexus-workerens firm-agents mot den (eneste realistiske vedvarende last).
- Rangerte batch-jobber som faktisk gir verdi:
  1. **Vault-backfill til memory.db** (1260 notater, LOKAL — vault har PII-mapper): natt-jobb, Haiku-distill-kost må estimeres først (forrige backfill: $42).
  2. **research-os PDF-ekstraksjon** (164 PDF-er, non-PII, thesis-verdi): CPU-bundet, kan gå på Vast on-demand.
  3. **YouTube-drain + Whisper-on-Vast** for caption-løse (non-PII, eksplisitt OK for leid GPU) — køen kjører nå.
  4. corpus-IDF-verifisering (minutt-jobb lokalt).
- IKKE re-embed korpuset — allerede 100 % bge-m3 (står feilaktig som åpent i eldre docs).

## 4. Gjenstående arbeid (prioritert)

**P0 — stabilitet (code-2, ingen gate):**
- Distill-catch-up: enqueue alle datoer med verbatim-rader uten memory_objects (fjerner av-natt-hull permanent).
- Failed-task + stale-heartbeat-rapport inn i brain-doctor/morning-briefing (report-only).
- brain-worker → bygget dist i uniten.

**P1 — koordinering:**
- PRESENCE: enten én printf-linje i firm-tab-init (peer-fil — koordiner med code-1) eller endre CHARTER-regel 1 til feed-online-linjer.
- Cherry-pick `194b100` (firm-task-claim/complete) eller fjern referansene fra CLAUDE.md + skills.
- Inbox-rotasjon ved boot (arkiv + trunkér; watcher tåler shrink) + rydd __TS__-heredoc-lekkasjen i thesis-1-inboksen.
- feed.md-rotasjon (>30 d → 90-archive) + slutt å skrive watch-receipts til feed.

**P2 — tenke bedre:**
- Inbox-lenking i skala: ukentlig distill-pass som lenker nye 00-claude-inbox-notater opp til MOC-er (kan kjøres av brain-worker som egen task-rolle).
- Re-kjør rag-eval mot 13k-korpuset med ekte bge-m3 (harness finnes: `npm run eval`).
- MOC-er for 06-investment-research + 14-books; 14-books inn i DEFAULT_QUEUE_DIRS.

**Operatør-gated:**
- Vast pause/destroy (etter IP-identifisering) — sparer ~$289/mnd.
- Push av command-center (nå 5 upushede commits: 3×code-1 + statusline-fix + recall-fix `c64f6fb`) og av Brain-vaulten — «OK kjør».
- Obsidian Git-plugin-diagnose (hvorfor stoppet auto-sync 10.06?).
- `gull`/`salg`-aliaser + Docker Desktop-oppstart hvis Hermes-sandbox skal leve.

## 5. Metode

Workflow `w7c1cutap`: 7 parallelle read-only-lesere (brain-pakker, scripts/hooks, obsidian-topologi, memory-os, gpu-hermes, firm-bus, ml-muligheter) med krav om kode-verifisering av hver kobling, + completeness-critic som stikkprøvde de viktigste påstandene og fant 7 selvmotsigelser + 9 udekkede områder (bl.a. git-syncen — analysens viktigste enkeltfunn kom fra criticen). Udekket fortsatt: Tailscale-status (ikke installert), Railway-runtime for apps/api, MCP-lagets helsetilstand, Windows-host-avhengigheter (Docker Desktop, wt.exe, WSL-reboot-oppførsel for systemd --user).
