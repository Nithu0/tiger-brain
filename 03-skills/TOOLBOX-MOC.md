---
title: TOOLBOX MOC — hele verktøykassen
folder: 03-skills
created: 2026-06-22
updated: 2026-06-22
purpose: Master-oversikt (Map of Content) over ALT verktøy i operatørens AI-OS — skills, subagenter, MCP-er, plugins, firm-scripts. CURRENT (installert) + PROPOSED (utvidelser). Organisert etter kategori og prosjekt. Recall-bar via obsidian-ingest.
related:
  - "[[README]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[reference_available_tools]]"
sources:
  - "command-center/docs/ops/toolbox-inventory.md (verifisert 2026-06-22)"
  - "command-center/docs/ops/TOOLBOX.md (RAM/infra, verifisert 2026-06-14)"
  - "live: claude mcp list, ~/.claude/{agents,skills,plugins}, command-center/_bin/ (2026-06-22)"
tags: [toolbox, moc, skills, subagents, mcp, plugins, firm-scripts, tooling, index]
---

# TOOLBOX MOC — hele verktøykassen

Master-indeks over alt verktøy i AI-OS-en: **skills, subagenter, MCP-er, plugins, firm-scripts**. Hver oppføring har: hva, hvorfor, hvilket prosjekt, hvordan-aktivere, vet-status.

> [!info] Hvordan lese statusene
> - **LIVE** — installert og verifisert på disk / via live-kommando på denne maskinen (WSL).
> - **NEEDS-AUTH** — wired, men krever en OAuth/secret-handling fra operatør før bruk.
> - **PROPOSED** — utvidelse, ikke installert. Krever operatør-handling. Vet-status sier om jeg anbefaler den.
> - **REJECT** — vurdert og frarådet (med begrunnelse). Ikke legg til.
>
> Verifiser på nytt når MCP-er/plugins/agenter endres — denne oversikten råtner. Sist verifisert 2026-06-22.

> [!warning] Bindende rammer (gjelder hele denne oversikten)
> - Maksimal autonomi = **alltid-på verktøy + proaktiv recall + selv-verifisering**, IKKE auto-push / auto-trade / gate-fjerning.
> - **"OK kjør"-gate** før hver push. Operatør-gatede handlinger (trades, migrasjoner, sletting, force-push, secrets, dotfiles) krever eksplisitt godkjenning.
> - **No-auto-disable**: health-checks RAPPORTERER, operatør bestemmer. cost-guard disabler aldri en jobb selv.
> - Aldri print/commit secret-verdier. Aldri les `.env` / `.git/config` / `~/.ssh`.

---

## 0. Hurtig-status (TL;DR)

| Kategori | LIVE | NEEDS-AUTH | PROPOSED | REJECT |
|---|---|---|---|---|
| MCP-servere | 6 (filesystem, fetch, playwright, obsidian, ClickUp, Drive) | 1 (ms365) | 2 (github, firecrawl) | — |
| Subagenter | 10 (alle `model: inherit`) | — | 0 (dekningen er god) | — |
| Skills (bruker) | 2 (humanizer, trading-knowledge) | — | superpowers `--scope user` | — |
| Skills (prosess via plugin) | 13 (superpowers, kun nexus-scope) | — | — | — |
| Plugins | 3 (superpowers, context7, ralph-wiggum — alle nexus-scope) | — | frontend-design | **claude-mem** |
| Firm-scripts | ~40 i `command-center/_bin/` | — | — | — |
| Infra-daemoner | brain-orchestrator, brain-worker, ollama, litestream | — | — | grafana/loki/prometheus → **node, ikke WSL** |

**Største faktiske gap akkurat nå:** (1) plugins er bare scope-et til `ai-assistent`, ikke de andre 5 prosjektene; (2) github + firecrawl MCP er wired-klare men mangler PAT/key; (3) ms365 mangler OAuth. Alle tre er operatør-gatede.

---

## 1. MCP-servere

Verifisert via `claude mcp list` 2026-06-22. On-demand stdio-MCP-er spawner ved bruk (0 RAM idle); remote-MCP-er bruker 0 lokal RAM.

| MCP | Status | Hva / hvorfor | Hvilket prosjekt | Hvordan aktivere | Vet-status |
|---|---|---|---|---|---|
| `filesystem` | **LIVE** ✔ | Fil-lese/skrive scoped til `/home/nithu/code` | Alle | Allerede koblet | KEEP — kjernen |
| `fetch` | **LIVE** ✔ | Hent URL-innhold (`uvx mcp-server-fetch`) | Research, Søking, thesis | Allerede koblet | KEEP |
| `playwright` | **LIVE** ✔ | Headless browser — scraping + UI-verifisering. La frontend-craft *drive og se* command-center-dashbordet | command-center, Søking (scrape) | Allerede koblet (Chromium ~300 MB kun mens åpen) | KEEP |
| `obsidian` | **LIVE** ✔ | Direkte Brain-vault-tilgang via MCP. (Var `✘ Failed` i inventory-doc 14.06, men self-healed — `✔ Connected` 22.06.) | Brain/alle | Allerede koblet | KEEP — men brain redigeres uansett trygt direkte via filsystem |
| `claude.ai ClickUp` | **LIVE** ✔ (remote) | Tasks, lister, docs, time-tracking — operatørens PM | AS, Søking, command-center | Allerede koblet | KEEP — bekreft hva som faktisk spores før antakelser |
| `claude.ai Google Drive` | **LIVE** ✔ (remote) | Drive fil-lese/skrive/søk/kopier | AS (regnskap/kvittering), thesis | Allerede koblet | KEEP |
| `claude.ai ms365` | **NEEDS-AUTH** ! (remote) | MS365 kalender/mail/Teams | Personlig, AS | Kjør `authenticate`-flow (OAuth) | KEEP — operatør fullfører auth |
| `github` | **PROPOSED** | PR/branch/CI-handlinger fra Claude. Remote HTTP-transport (IKKE docker `.sig`-imaget som feilet) | command-center, nexus, alle med GitHub | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/ --header "Authorization: Bearer <PAT>"` — operatør limer fine-grained PAT | ANBEFAL — lav risiko, 0 lokal RAM. Operatør-gated (PAT) |
| `firecrawl` | **PROPOSED** | Crawl-til-markdown web-scraping for research-agenter. Binær finnes allerede på PATH | research-os, Søking, investment-research | `claude mcp add firecrawl firecrawl-mcp --env FIRECRAWL_API_KEY=<key>` — operatør limer key | ANBEFAL — on-demand, lav risiko. Operatør-gated (key) |

> [!note] Døde DB-MCP-er — ikke kast bort tid
> `nexus-pg` / `nexus-pg-rw` (Postgres) er DØDE på operatørens primærnett (egress-brannmur slipper kun 443). Arbeidskanal mot nexus-prod = `bash pull-nexus-data.sh` over HTTPS. Ikke re-wire direkte-DB-MCP der. Ingen Railway-MCP heller — env/restart mot prod er manuelt + operatør-gated uansett.

---

## 2. Subagenter

`~/.claude/agents/*.md` — 10 tilpassede, alle `model: inherit`. Dispatch proaktivt og parallelt på disjunkte filer (parallell-by-default). Dekningen er god; **ingen PROPOSED-mangler identifisert**.

| Agent | Verktøy | Hva / hvorfor | Primært prosjekt |
|---|---|---|---|
| `backend-api` | Read/Edit/Write/Bash/Grep/Glob | Typed Fastify v5 API-er + better-sqlite3 data-lag (Postgres-swap inneslutt per ADR-002) | command-center |
| `brain-engineer` | samme | Brain-substratet: `@cc/memory-engine`, `@cc/rag-engine`, `@cc/brain-orchestrator` (memory/RAG/distill/recall) | command-center/Brain |
| `code-reviewer` | Read/Grep/Glob/Bash | Adversarisk READ-ONLY review (korrekthet, sikkerhet, forenkling) før commit | Alle |
| `data-pipeline` | +WebFetch/WebSearch | Ingestion/ETL: Brain-køer, research-os paper-pipeline, Søking job-scrape | research-os, Søking, Brain |
| `frontend-craft` | +WebFetch | Restrained UI: Next.js 15 + Tailwind + SWR (Linear/Vercel-estetikk) | command-center |
| `ml-scientist` | +WebSearch | Python ML for masteroppgaven (solid-state-elektrolytter) + research-os | thesis, research-os |
| `ops-infra` | Read/Edit/Write/Bash/Grep/Glob | code-2 ops-lane: systemd, WSL, launchers, backup, migrasjon, CI, deploy, MCP-setup | command-center/infra |
| `refactor-simplifier` | samme | Atferdsbevarende forenkling — reduser duplisering/kompleksitet (ikke bugjakt/features) | Alle |
| `researcher` | Read/Grep/Glob/Bash/WebFetch/WebSearch | READ-ONLY web+repo-research, adversarisk verifisert + sitert | Alle |
| `test-engineer` | Read/Edit/Write/Bash/Grep/Glob | vitest (TS) + pytest (Py) som treffer reelle kodebaner | Alle |

---

## 3. Skills

### 3a. Innebygde slash-skills (denne harness-sesjonen) — LIVE
Tilgjengelig via `Skill`-verktøyet uten installasjon: `humanizer`, `code-review`, `security-review`, `verify`, `run`, `deep-research`, `loop`, `schedule`, `update-config`, `keybindings-help`, `fewer-permission-prompts`, `simplify`, `claude-api`, `init`, `review`.

> [!tip] code-review + security-review finnes allerede innebygd
> Ikke installer plugin-duplikater (`code-review`, `pr-review-toolkit`, `security-guidance`) med mindre du vil ha deres egne ekstra-kommandoer. De innebygde dekker kjernebehovet.

### 3b. Bruker-installerte skills (`~/.claude/skills/`) — LIVE

| Skill | Versjon | Hva / hvorfor | Prosjekt | Vet-status |
|---|---|---|---|---|
| `humanizer` | 2.7.0 | Fjern AI-skrive-signaturer (inflated symbolism, rule-of-three, em-dash, AI-vokabular). Git-tracked. | Alle operatør-vendte docs | KEEP — kjør på all prosa |
| `trading-knowledge` | 0.2.0 | Ruter til operatørens Obsidian trading-bibliotek ved Nexus-domeneord (strategy/gate/ORB/XAUUSD/S1-S4/regime) FØR svar | nexus | KEEP — domene-guard |

### 3c. Prosess-skills via superpowers-plugin — LIVE (men kun nexus-scope)
13 skills: `brainstorming`, `dispatching-parallel-agents`, `executing-plans`, `finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`, `subagent-driven-development`, `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `using-superpowers`, `verification-before-completion`, `writing-plans`, `writing-skills`.

⚠️ **Scope-gap:** installert `scope: project` mot `ai-assistent` — IKKE aktiv i de andre 5 prosjektene. Se §4 PROPOSED for re-install.

### 3d. Brain-skill-registry (`~/Obsidian/Brain/03-skills/*.md`) — LIVE (Tier-3, navne-invokerbare)
`brain-recall`, `brain-distill-daily`, `brain-task-claim`, `brain-task-complete`, `brain-task-list`, `github-discover`, `youtube-ingest`, `multi-agent-dispatch`, `worktree-spawn-cleanup`. Underfoldere: `_proposed/` (tom nå), `_archived/`, `_system/`. Frontmatter-kontrakt + workflow i [[README]].

---

## 4. Plugins

`~/.claude/plugins/installed_plugins.json` — 3 installerte, **alle `scope: project` mot `ai-assistent`** (kun aktiv i nexus-repoet, ikke workspace-globalt).

| Plugin | Versjon | Hva / hvorfor | Scope nå | Vet-status |
|---|---|---|---|---|
| `superpowers@claude-plugins-official` | 6.0.3 | Prosess-disiplin-skills (§3c) | nexus | KEEP. **PROPOSED:** re-installer `--scope user` for å få prosess-skills i alle 6 prosjekter. Operatør-gated valg. |
| `context7@claude-plugins-official` | unknown | Live bibliotek/framework-docs på forespørsel | nexus | VERIFISER — cache-mappe har vært tom; bekreft at den faktisk laster docs før du stoler på den |
| `ralph-wiggum@claude-code-plugins` | 1.0.0 | Loop-til-ferdig agent-runner (commands + hooks) | nexus | KEEP |

### Tilgjengelige men IKKE installerte (i registrerte marketplaces)
`claude-plugins-official` har bl.a.: `frontend-design`, `code-review`, `code-simplifier`, `code-modernization`, `feature-dev`, `pr-review-toolkit`, `security-guidance`, `skill-creator`, `mcp-server-dev`, `plugin-dev`, `hookify`, `session-report`, `ralph-loop`, `claude-md-management`, + diverse `*-lsp` språkservere (typescript, pyright, rust-analyzer, gopls, clangd).

### PROPOSED-plugin

| Plugin | Hva / hvorfor | Prosjekt | Hvordan | Vet-status |
|---|---|---|---|---|
| `frontend-design` | Egne kommandoer/skills for UI-arbeid. Reelt gap for command-center-dashboardet | command-center | `claude plugin install frontend-design@claude-plugins-official` (vurder `--scope user`) | ANBEFAL (lav risiko). `frontend-craft`-subagenten dekker noe av samme intensjon, men plugin-en gir egne kommandoer. Operatør-gated. |

### REJECT-plugin

> [!danger] claude-mem — IKKE legg til
> **Vet-status: REJECT.** Overlapper direkte med eksisterende `memory.db` + `@cc/rag-engine` + `@cc/memory-engine` + Obsidian-as-brain + `rag-recall.sh`/`session-capture.mjs`. To konkurrerende memory-substrat = splittet recall, dobbel capture, uklart hvem som eier sannheten. Memory-loopen ble nettopp lukket (audits 2026-06-19/06-21). Ikke innfør en rival. (Finnes heller ikke i de registrerte marketplaces.)

---

## 5. Firm-scripts (`command-center/_bin/`) — code-2-lane

> [!warning] Lane-regel: `command-center/_bin/` eies av code-2. Ikke destruktivt-rediger.

### Launchers (deler `firm-tab-init.sh`-kontrakten)
| Script | Hva |
|---|---|
| `firm-tab-init.sh` | Per-pane init: eksporterer `FIRM_ROLE`/`FIRM_PROJECT`, logger til firm-bus feed, execs claude |
| `firm-wt-split.sh` | 8 paner i én WT-tab (split-view, default) — alias `firm`/`nx` |
| `firm-wt-tabs.sh` | 8 separate WT-tabs (fallback) — alias `firmt` |
| `firm-zellij.sh` | zellij-fallback hvis WT feiler — alias `firmz` |
| `firm-tmux.sh` | tmux-variant av firm-gridden |
| `skole-wt-split.sh` | 4 paner mot Master-oppgave (thesis-fokus) — alias `skole` |
| `gull-wt-split.sh` | 4 paner mot nexus/GOLD (trading-dypdykk) — alias `gull` |
| `salg-wt-split.sh` | 3 paner mot call-center-ai-demo (salgsplattform) — alias `salg` |

### Koordinering / firm-bus
`firm-heartbeat.sh`, `firm-inbox-watch.sh`, `firm-statusline.sh`, `firm-session-context.sh`, `global-session-context.sh` (session-start kontekst), `firm-capture-session-id.sh`, `firm-git-snapshot.sh`, `mission.sh` (background-mission-ledger + native job-status).

### Worktrees
`firm-worktree-spawn.sh`, `firm-worktree-list.sh`, `firm-worktree-cleanup.sh`.

### Brain / memory / RAG
`rag-recall.sh` (+`.ts`) — session-start top-N distilled memories via `@cc/rag-engine` hybrid; `skill-recall.sh` (+`.ts`); `backfill-memory.{mjs,sh}`; `session-capture.{mjs,sh}`; `gen-current-state.sh`; `brain-doctor.sh`; `firm-brain-ensure.sh`; `brain-{up,down,status,retention}.sh`; `brain-install-systemd.sh`.

### Ingestion
`youtube-ingest.sh`, `github-discover.sh`.

### Kostnad / compute
`cost-guard.sh` + `cost-guard-api.sh` + `cost-log.sh` (REPORT-ONLY ukentlig spend-sjekk — disabler ALDRI en pod/jobb selv); `vast-run.sh`, `eval-rag-real.sh`.

### Backup / migrasjon / maskin-bootstrap
`backup-local.sh`, `restore-local.sh`, `bootstrap-new-machine.sh`, `capture-machine-manifest.sh`, `make-collaborator-bundle.sh`, `quarantine.sh` (flytt-ikke-slett), `wire-secret-mcps.sh`.

### Task-livssyklus
`firm-task-claim.sh`, `firm-task-complete.sh`.

---

## 6. Infra-daemoner + RAM-bærekraft

> [!warning] Boksen er RAM-kritisk
> WSL: 9.7 GB total, ~0.8 GB fri, 4 GB swap (1.4 GB i bruk). Regel: **on-demand på WSL; 24/7-daemoner går til noden** (dedikert 24/7 lokal GPU-node, Tailscale-only, ~Aug 2026).

**KEEP på WSL nå (berettigede residenter):** brain-orchestrator + brain-worker (systemd --user, kjerne-autonomi = produktet), ollama (~30 MB idle, modell-RAM kun ved inferens), litestream (SQLite-replikering for `agent_tasks`/`firm_state`), on-demand MCP-er (§1), remote MCP-er (0 lokal RAM).

**DEFER til noden (kjør IKKE 24/7 på WSL):** grafana, loki, promtail, open-webui, caddy (alle ikke-installert — la det være). prometheus + node-exporter er installert men STOPPED — disable til noden finnes:
```bash
sudo systemctl disable prometheus prometheus-node-exporter   # operatør-gated (sudo)
```

**Allerede tilgjengelig, bruk NÅ:** `mise` (toolchain — `mise use -g node@24`), `litestream` (`litestream databases` / `restore`), `uv` (`uv tool install <x>` — unngå PEP 668-veggen), `playwright MCP` (driv+se dashbordet).

---

## 7. Oversikt etter prosjekt

| Prosjekt | Mest relevante verktøy |
|---|---|
| **command-center / Brain** | backend-api, frontend-craft, brain-engineer, ops-infra subagenter; alle firm-scripts; playwright MCP; github MCP (proposed); frontend-design (proposed) |
| **nexus (XAUUSD trading)** | `trading-knowledge`-skill; superpowers/context7/ralph-wiggum (installert her); `pull-nexus-data.sh` (DB-MCP er død); gull-launcher |
| **thesis (ML elektrolytter)** | ml-scientist, data-pipeline, researcher subagenter; fetch MCP; Drive MCP; skole-launcher |
| **research-os** | data-pipeline, researcher, ml-scientist; fetch + firecrawl (proposed) MCP |
| **AS / RefiPrep (finans)** | ClickUp MCP, Drive MCP (regnskap/kvittering); ms365 (proposed auth); `packages/refiprep` |
| **Søking fulltid** | data-pipeline (job-scrape), playwright + firecrawl (proposed) MCP, ClickUp (CRM) |
| **Personlig** | ms365 (proposed auth) for kalender; ClickUp |

---

## 8. Operatør-handlinger som venter (alle gatede)

1. **github MCP** — lim fine-grained PAT (§1). Lav risiko, høy nytte for command-center/nexus.
2. **firecrawl MCP** — lim API-key (§1). Nytte for research/Søking.
3. **ms365** — fullfør OAuth `authenticate`-flow (§1).
4. **superpowers `--scope user`** — gjør prosess-skills tilgjengelig i alle 6 prosjekter (§4).
5. **frontend-design plugin** — installer for command-center UI-arbeid (§4).
6. **prometheus/node-exporter** — `systemctl disable` til noden finnes (§6, sudo).
7. **context7** — verifiser at den faktisk laster docs (cache har vært tom) (§4).

Ingen av disse utfører jeg autonomt: PAT/key/secrets, dotfile/alias-redigering, sudo og prod-handlinger er operatør-gatede.

---

## Related
- [[README]] — skill-registry-konvensjoner (Tier-3, frontmatter, workflow)
- [[2026-05-25-brain-upgrade-plan]] — 10-modul arkitektur
- command-center/docs/ops/toolbox-inventory.md — faktisk-tilstand (kilde)
- command-center/docs/ops/TOOLBOX.md — RAM/infra-bærekraft (kilde)
