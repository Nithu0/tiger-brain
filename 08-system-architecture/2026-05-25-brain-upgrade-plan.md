---
title: Workspace-wide Brain Upgrade — Audit, Target, Parallell-todo
date: 2026-05-25
status: v1.4 draft — fase 11+12 EXECUTE komplett, sprint 1 SHIPPED
author: code-2 + 10 parallelle inspeksjons-agenter
related:
  - "[[2026-05-24-onprem-ai-strategi]]"
  - "[[Nexus-MOC]]"
  - "[[command-center]]"
tags: [system-architecture, brain, conductor, hermes, distillation, parallel-agents]
---

# Workspace-wide Brain Upgrade

> **Premise:** Operator vil bygge et privat, autonomt AI-OS inspirert av Conductor (parallelle isolerte agent-worktrees) + Hermes Agent (persistent memory, auto-skills, scheduled, multi-model routing) + structured distillation (paper 2603.13017v1). Mye er allerede bygget. Dette dokumentet er audit + target + parallell-todo, ikke implementasjon. Implementasjon krever OK kjør per modul.

---

## §0 TL;DR

**Hva eksisterer allerede (sterkt):**
- **command-center Slices 1–13 code-complete + Slice 14a (Railway) i gang.** Multi-engine (Claude + OpenAI), 6 desk-agents (Atlas/Cipher/Shield/Prism/Forge/Blade), approval-gate, audit-log, terminal-orchestrator, web UI med 8-pane konsoll. 341/341 tester grønne.
- **Nexus (ai-assistent) ER allerede en Conductor+Hermes-implementasjon.** `FirmOrchestrator` (adaptiv 60–180s cycle), `agent_tasks`+`agent_results`+`agent_audit` tabeller (Postgres FOR UPDATE SKIP LOCKED, idempotency-key, SLA), `firm_state` KV (restart-survivable), `research-drainer` (in-process LLM-dispatch m/ rate-limit-quota), 70+ blackboard-topics, 4 `agent-trigger` triggere (LOSS_STREAK / NEW_POSTMORTEM / REGIME_FLIP / GATE_SPIKE), `postmortem.ts` auto-genererer lessons.
- **Brain (Obsidian)**: 20+ MOC-filer, 17 runbooks, 15 dato-stemplede decisions, immutable `_decisions/`, firm-bus (feed/PRESENCE/inbox) som async multi-pane substrat, sterke YAML-frontmatter-konvensjoner, sanity.sh + path-guard CI.
- **research-os**: Pydantic→SQLite én-serializer-pattern, sitatgraf-tabell, quote-anchored LLM-verifikasjon m/ caching, regex→konfidens-filter→manuell promote, multi-source merge-by-DOI.

**Hva mangler eller er svakt:**
1. **Structured distillation** (paper) er ikke implementert noe sted — gull-mulighet for brain-retrieval.
2. **Git-worktree per agent** finnes som opsjonell `--codex`-modus, men er ikke default. Conductor-stilen krever det.
3. **Skill-registry** finnes ikke — bare `trading-knowledge` i `~/.claude/skills/`. Hermes-stil auto-skill-creation mangler helt.
4. **YouTube + GitHub ingestion** er greenfield — bare en tom `_library/youtube/` placeholder.
5. **Brain-folders OPPRETTET 2026-05-25 (fase 2):** `03-skills/`, `12-youtube/` (var planlagt `06-youtube` — renumberet pga 06-AS-kollisjon), `13-github-repos/` (var planlagt `07-github-repos` — renumberet pga 07-personlig-kollisjon), `09-retrospectives/`, `10-tasks/`, `00-templates/`.
6. **Distillation-loop bakover fra command-center-handlinger til brain-notater** finnes ikke (det er hooket til ~/Obsidian/Brain/00-command-center/audit/ daglig, men ikke distillation, bare dump).
7. **No closed-loop learning pipeline** for ikke-trading-domener. Nexus har `postmortem.ts` → lesson. Resten av workspace gjør det ikke.
8. **Dashboard-gap**: agent-per-agent status matrix, cross-pane activity heatmap, memory-write audit, operator-decision-queue.

**Hovedanbefaling — LIFT, ikke REINVENT:** Nexus er allerede Conductor+Hermes for trading. command-center bør **løfte Nexus-patterns inn i en generic `@cc/brain-orchestrator`** (FirmOrchestrator-pattern, agent_tasks queue, agent-trigger), og brain bør **løfte research-os' two-stage extraction + Nexus' postmortem-loop** for å bli self-learning. Bygg ikke fra null.

---

## §1 Audit — hva som faktisk er i workspace per 2026-05-25

### 1.1 command-center (`/home/nithu/code/command-center`)

| Slice | Status | Hva |
|---|---|---|
| 1 | done | Foundation, dashboard-shell, command queue, approval-gate |
| 2 | done | AI Router (intent → ProposedCommand m/ prompt-caching) |
| 3 | done | Executor worker (2s poll, firm-bus handoff + safe-exec) |
| 4 | done | WebSocket broadcast (commands/git/presence) |
| 5 | done | PWA + web push (VAPID) |
| 6 | done | Agent desks (Atlas/Cipher/Shield/Prism/Forge/Blade m/ role+tool-allowlist) |
| 7 | done | GitHub integrasjon (PRs/branches/CI/issues/commits) |
| 8 | done | Cross-machine sync (Litestream + multi-operator audit) |
| 9 | done | Developer flow (commit suggestions, issue drafts, activity feed) |
| 10 | done | Mobile nav + Brain Layer (read-only Obsidian) |
| 11 | done | Terminal Orchestrator (8-pane konsoll + dispatch + inbox-watcher) |
| 12 | done | Auth (HMAC tokens + per-operator passord + opt-in via AUTH_SECRET) |
| 13 | done | Multi-engine (`@cc/engines` Claude+OpenAI) |
| 14a | in progress | Railway hosting — env-guards landed, db-dispatch + 4 filer portet, Postgres-ready, 341/341 grønne |

**Sterkt:** Router→Desk-dispatch fungerer, approval-gate auditert, 33 testfiler, multi-operator-attribusjon (`audit_log.operator + .machine`), firmBusHandoff route, `dispatchToDesk()` multi-engine.

**Mangler:** Skill-registry, memory-distillation, git-worktree-orkestrering (kun reads git status), scheduled background jobs (kun executor-poll), parallel sub-agent dispatch (desks er sekvensielle).

### 1.2 Nexus / ai-assistent (`/home/nithu/code/ai-assistent`) — ALREADY a Conductor

| Komponent | Plass | Hva |
|---|---|---|
| `FirmOrchestrator` | `apps/worker/src/firm/orchestrator.ts` | Adaptiv cycle (60–180s per session-window), 16 firm-moduler + 10 firm-agents per tick |
| `agent_tasks` queue | `packages/shared/src/db/schema.ts` | Postgres queue m/ FOR UPDATE SKIP LOCKED, idempotency_key, deadline_at, sla_seconds |
| `agent_results` + `agent_audit` | samme schema | Hermes-style task-resultat + who-did-what audit |
| `research-drainer` | `apps/worker/src/firm/agent-bus/research-drainer.ts` | In-process LLM-dispatch (Gemini) m/ rate-limit-quota, retry-counter, SLA-reaper |
| `agent-trigger` | `apps/worker/src/firm/agent-bus/agent-trigger.ts` | 4 triggere (LOSS_STREAK→research, NEW_POSTMORTEM→review, REGIME_FLIP→research, GATE_SPIKE→review). Idempotent per fingerprint |
| `firm_state` KV | Postgres `firm_state` tabell | Restart-survivable cooldown/heartbeat/daily-pass-markers |
| Blackboard | `apps/worker/src/firm/blackboard.ts` | 70+ topic-typer, TTL-managed |
| `postmortem.ts` | `apps/worker/src/firm/` | Auto-genererer lessons fra closed-loop events (trade close → classify → department-score → firm_memory) |
| `agent_lessons` | `packages/shared/src/agent-lessons.ts` | Fingerprint-dedup, multi-proposer voting via sample_size++, 5 status-transisjoner (proposed→approved→archived/drifted) |
| Learning ledger | `docs/ops/learning-ledger.md` | Markdown m/ OPEN/REOPENED/VERIFIED/BLOCKED-seksjoner, parses av session-start hook |

**Verdi for workspace-brain:** Disse patterns kan løftes 1-til-1. `FirmOrchestrator` → generic `BrainOrchestrator`. `agent_tasks` → generic task-kø. `postmortem` → generic event-handler. Learning ledger → workspace-wide verification backlog.

### 1.3 Obsidian Brain (`/home/nithu/Obsidian/Brain`)

| Folder | Status | Bruk |
|---|---|---|
| `00-DASHBOARD.md` + `00-CONTROL-PANEL.md` + `01-CURRENT-FOCUS.md` | strong | Operator orientering |
| `00-claude-inbox/<project>/` | strong | Inbox-lifecycle: draft→inbox→promote→repo |
| `00-firm-bus/` | strong | Multi-pane substrat (feed/PRESENCE/inbox) |
| `00-command-center/` | strong | Daglige audit-dumps fra command-center |
| `01-nexus/` … `07-personlig/` | strong | Per-prosjekt MOCs + runtime-state |
| `_decisions/` | strong | 15 immutable dato-stemplede decisions |
| `_maps/` | strong | 20+ MOC-filer, sterk wikilink-disiplin |
| `_runbooks/` | strong | 17 operasjonelle prosedyrer |
| `_library/youtube/` | placeholder | Tom — konvensjon dratt opp 2026-05-13, ikke fylt |
| `_library/raw/` | sparse | Lite innhold |
| `03-skills/` | **OPPRETTET 2026-05-25 i fase 2** | SKILL.md per role + reusable procedures; 5 initielle filer landet (brain-distill-daily, youtube-ingest, github-discover, multi-agent-dispatch, worktree-spawn-cleanup) |
| `12-youtube/` | **OPPRETTET 2026-05-25 i fase 2** | Var planlagt `06-youtube/` — renumberet til 12 pga kollisjon m/ `06-AS/`. Inneholder `_queue/` for operator-URLs |
| `13-github-repos/` | **OPPRETTET 2026-05-25 i fase 2** | Var planlagt `07-github-repos/` — renumberet til 13 pga kollisjon m/ `07-personlig/`. Inneholder `_queue/` for "search:..." dropper |
| `08-system-architecture/` | **opprettet 2026-05-25 (fase 1)** | Denne fila + 7 specs i `specs/` + eval-sett i `eval/` |
| `09-retrospectives/` | **OPPRETTET 2026-05-25 i fase 2** | Per-uke roll-up; 2026-W22.md landet som første instans + mal-mønster |
| `10-tasks/` | **OPPRETTET 2026-05-25 i fase 2** | Workspace-wide task-backlog parses av BrainOrchestrator; 3 pilot-tasks landet i `_open/` |
| `00-templates/` | **OPPRETTET 2026-05-25 i fase 2** | 8 templates (atomic/moc/skill/retrospective/task/memory-object/youtube-note/github-repo-note) brukt av firm-task-claim |

**Konvensjoner som funker:**
- YAML-frontmatter: `tags`, `type`, `created`, `status`, `author`
- Wikilinks `[[Note]]` only, ingen markdown-lenker
- MOC-pattern: hvert domene har én MOC som ankerpunkt
- Dato-stempel-filnavn for tidskritisk innhold (`YYYY-MM-DD-slug.md`)
- `_promote-candidates/` som staging før repo-migrering

**Mangler:**
- Stable IDs (kun wikilinks — fragilt ved eksport)
- Dead-link auto-deteksjon (sanity.sh sjekker per-push, ikke kontinuerlig)
- Distilled-vs-verbatim split — kun løs konvensjon via `_library/` (kilde) vs domain-MOCs (distillert)
- Auto-distillation-hook fra command-center actions → brain notes

### 1.4 firm-bus / firm-launcher

| Komponent | Status |
|---|---|
| `firm-tab-init.sh` | strong — exports FIRM_ROLE/PROJECT/COLOR/TAB_OPENED_AT |
| `firm-wt-split.sh` | default — 8 panes i én WT-tab |
| `firm-wt-tabs.sh` + `firm-zellij.sh` | fallbacks |
| 8-pane mapping | code-1/2 (workspace), ai-1/2 (nexus), thesis-1, as-1, soking-1, personal-1 |
| `firm-worktree-spawn.sh` | finnes, men brukes kun ved `--codex`-flag — **ikke default** |
| `firm-inbox-watch.sh` | 5s polling per pane på inbox-fil-vekst |
| feed.md latency | 2–5 min async (Obsidian Git plugin) |

**Stort gap mot Conductor:** ingen task-state machine, ingen task-id, ingen merge-back-protokoll, ingen lease/locking, ingen rollback-plan per task. Inbox-blokker er ren markdown uten frontmatter.

### 1.5 research-os (`/home/nithu/code/research-os`)

Mindre repo, men har gode patterns:
- `asdict_for_db()` — én Pydantic→SQLite serializer
- `AuditClaim`-tabell: chapter/section/line_no/claim_text/citekeys/status/notes
- `verification/llm_verify.py` — quote-anchored verdicts m/ ephemeral cache
- `extraction/battery.py` — regex → `FactCandidate(field, value_num, unit, evidence, confidence)` m/ konservativ default-konfidens
- `discovery/merge.py` — dedupe per DOI/title med `Hit.merge_from()`

### 1.6 Eksisterende skill / agent / scheduling

| Surface | State |
|---|---|
| `~/.claude/skills/` | Kun `trading-knowledge` (en SKILL.md) |
| `~/.claude/agents/` | Folder eksisterer ikke |
| Per-prosjekt `.claude/skills/` | Ingen |
| 13 system-skills (verify/code-review/loop/schedule/run/init/review/security-review/claude-api/update-config/keybindings-help/fewer-permission-prompts/trading-knowledge) | Injectes per session-start, ingen disk-registry |
| Brain runbooks som de-facto skills | 17 stk i `_runbooks/` — ikke auto-invokable |
| Conductor (systemd timer) | Bare for `Søking fulltid/agent/conductor.{service,timer}` — daglig job-scrape 07:00 |
| Andre cron/scheduled | Ingen |

### 1.7 YouTube + GitHub ingestion

**Greenfield.** Ingen yt-dlp, ingen whisper-pipeline, ingen GitHub-discovery, ingen scraper-infrastruktur. Playwright finnes som test-dep i to repos (ikke ingestion). Bare `gh status` i master-oppgave. Bygg fra null.

### 1.8 Dashboards + observability

| Wishlist | Status |
|---|---|
| Active agents | partial — `FirmAgentsWidget` viser counts, ikke per-agent breakdown |
| Branch/worktree | exists — `/api/git/status` per prosjekt |
| Current objective | exists — `01-CURRENT-FOCUS.md` |
| TODO progress | partial — Brain markdown-liste, ikke live-board |
| Last action | exists — feed.md siste 25–50 linjer rendres i "Feed" tab |
| Blocker | partial — `readiness`-endpoint surfacer execution-blockers, ikke kontinuerlig blocker-hotline |
| Memory writes | **missing** — distillation/promotion ikke audited noe sted |
| Tests passing/failing | partial — Nexus `/health.cyclesPerHour`, command-center har ikke build-heartbeat |
| Merge/review status | exists — GitHub-tab + PRList |
| System health | exists — HealthBadge + Nexus SystemHealthIndicator |

### 1.9 Inbox/koordinasjon-state (sjekket 2026-05-25T10:00Z)

- code-2 inbox: én entry siden 24.5 (kvittering, ingen oppgaver)
- code-1: stille, ingen aktivt arbeid
- ai-1 inbox: Karri pulled 401-fix + on-prem AI strategy (HTTP 204 levert 2026-05-24T15:24Z)
- ai-2, thesis-1, as-1, soking-1, personal-1: alle har "ready to commit"-arbeid, ingen blokkere
- PRESENCE.md: sparse (mekanikken populerer ikke per pane-start)
- feed.md: clean, ingen koordinasjon-asks flagget
- **Konklusjon: klar bane for workspace-wide brain-upgrade. Ingen merge-konflikter, ingen dangling dispatches.**

---

## §2 Target arkitektur — moduler

### Module A — Brain Orchestrator (`@cc/brain-orchestrator`)

Generic adaptiv cycle-loop, løftet fra Nexus' `FirmOrchestrator`. Bor i command-center.

```
packages/brain-orchestrator/
  src/
    orchestrator.ts            # adaptive cycle loop (idle 5min, active 30s)
    task-claim.ts              # FOR UPDATE SKIP LOCKED claiming
    sla-reaper.ts              # zombify stale in_progress rows
    state-kv.ts                # restart-survivable cooldown/heartbeat (mirrors firm_state)
    triggers/
      stale-task.ts            # publish review-task hvis open-task > N dager
      dead-link.ts             # publish fix-task hvis brain har broken wikilinks
      youtube-queue.ts         # publish ingest-task hvis ny URL i 12-youtube/_queue/
      github-discovery.ts      # publish ingest-task hvis ny query i 13-github-repos/_queue/
      memory-distill.ts        # publish distill-task nightly på dagens command-center actions
```

**Hva som ikke skal lages på nytt:** all schema-tabellene allerede definert i Nexus `packages/shared/src/db/schema.ts`. Løft til `command-center/packages/shared` eller importer.

### Module B — Memory Engine (Two-Tier per paper 2603.13017v1)

```
packages/memory-engine/
  src/
    distill.ts                 # exchange → MemoryObject (LLM-distill m/ surviving vocabulary)
    schema.ts                  # MemoryObject type med 4 paper-felter + back-ref
    retrieval/
      hybrid.ts                # cross-layer: BM25(verbatim) + HNSW(distilled) + CombMNZ
      embedding.ts             # bge-m3 (lokal, ikke OpenAI for sensitivt) eller all-MiniLM lokalt
    storage/
      verbatim.ts              # full transcript som SQLite blob + indexed FTS
      distilled.ts             # MemoryObject-rows + vektor (sqlite-vss eller separat Qdrant)
```

**Schema (paper-tro):**

```typescript
interface MemoryObject {
  id: string;                          // UUIDv7
  created_at: string;                  // ISO
  project: string;                     // "nexus" | "thesis" | "command-center" | ...
  source_type: "conversation" | "code_change" | "youtube" | "github_repo" | "document" | "manual_note" | "terminal_log";
  exchange_core: string;               // LLM, 1-2 setninger ("commit message")
  specific_context: string;            // LLM, ett distinguishing technical detail ("the diff")
  room_assignments: Array<{            // LLM, 1-3 thematic rooms
    type: "file" | "concept" | "workflow";
    key: string;
    label: string;
  }>;
  files_touched: string[];             // regex-ekstrahert (ikke LLM)
  entities: string[];                  // navn, funksjoner, env-vars, errors
  decisions: string[];                 // hva ble bestemt
  unresolved_questions: string[];      // åpne tråder
  next_actions: string[];              // strukturelle TODOs
  source_ref: {                        // back-ref til verbatim
    conversation_id?: string;
    file_path?: string;
    ply_start?: number;
    ply_end?: number;
    commit_sha?: string;
    url?: string;
  };
  confidence: number;                  // 0-1, fra distill-LLM
  expires_at?: string;                 // staleness marker (f.eks. for runtime-state)
}
```

**Retrieval-strategi (lock til hva paper viser virker):** Cross-layer `BM25-FTS(verbatim) + HNSW(distilled.specific_context) / CombMNZ`. Pure-distilled bare som fallback. Aldri kast verbatim — paper viser 91% nDCG@10 forblir, men ALDRI vis distilled til operator, kun bruk som retrieval-index.

### Module C — Obsidian Brain folder-restruktur

Additivt — ingen sletting, kun nye folders + dokumenterte konvensjoner.

```
/home/nithu/Obsidian/Brain/
  03-skills/                           # NY — SKILL.md per agent-role + reusable procedures
    Brain-Distill-Daily.md
    Youtube-Ingest.md
    Github-Discover.md
    Multi-Agent-Dispatch.md
    Worktree-Spawn-Cleanup.md
    ... (mer etterhvert)
  12-youtube/                          # NY — én note per video, frontmatter m/ kanal/dato/url
    Lex-Fridman/2026-04-12-some-talk.md
    _queue/                            # operator dropper URL her, BrainOrchestrator plukker
  13-github-repos/                     # NY — én note per interessant repo
    anthropics-claude-code.md
    conductor-build.md
    _queue/                            # operator dropper "search:..." her
  08-system-architecture/              # OPPRETTET 2026-05-25
    2026-05-25-brain-upgrade-plan.md   # denne fila
  09-retrospectives/                   # NY — per-uke roll-up av handoffs + session-summaries
    2026-W22.md
  10-tasks/                            # NY — workspace-wide task-backlog (parses av BrainOrchestrator)
    _open/
    _done/
    _blocked/
```

**Konvensjoner per ny folder:** YAML-frontmatter m/ `type` + `tags` + `created`, wikilink til relevant MOC, dato-stempel filnavn. Skal være lett-parsable av BrainOrchestrator (frontmatter→struct).

### Module D — Skill registry

Tre-tier:

1. **`~/.claude/skills/<name>/SKILL.md`** — workspace-wide
2. **`<repo>/.claude/skills/<name>/SKILL.md`** — project-local (auto-loaded når Claude starter i repo)
3. **`/home/nithu/Obsidian/Brain/03-skills/<name>.md`** — operator-reference + auto-discovered av BrainOrchestrator (frontmatter `auto_invocable: true`)

SKILL.md-template (per Hermes-stil):

```markdown
---
name: brain-distill-daily
description: Nightly run — distill yesterday's command-center actions + Claude conversations into MemoryObjects
when_to_use: cron 03:00 lokal, ELLER på manual /brain distill
inputs: { date: YYYY-MM-DD }
outputs: count_new_objects + count_promoted_to_brain
tools: [@cc/memory-engine, brain-write]
pitfalls: ikke distill 00-firm-bus/feed.md (low-signal), aldri overskriv verbatim
validation: stikkprøve 5 random objects per uke for surviving-vocabulary
example: /skill brain-distill-daily date=2026-05-24
---

# Brain Distill Daily

[steps...]
```

### Module E — YouTube Ingest pipeline

```
packages/youtube-ingest/
  src/
    fetch.ts          # yt-dlp wrapper (transkripsjon hvis tilgjengelig)
    whisper.ts        # fallback hvis no transcript
    distill.ts        # LLM → 12-youtube/<kanal>/<dato-slug>.md frontmatter
    skill-extract.ts  # LLM → forslag til SKILL.md hvis videoen lærer prosedyre
```

**Pipeline:** URL i `12-youtube/_queue/`-fil → BrainOrchestrator (`trigger:youtube-queue`) → `agent_tasks` (role:ingest, payload:url) → `youtube-ingest`-worker → distillert note + (valgfri) skill-stub.

**Anti-pattern:** dump ALDRI full transcript i 12-youtube/-noten — store den i `_library/youtube/<kanal>/<dato-slug>/transcript.txt` (verbatim layer), notér bare metadata + 4-felt-distillat.

### Module F — GitHub Discovery pipeline

```
packages/github-discovery/
  src/
    search.ts          # gh search repos --topic --stars (m/ rate-limit-tracking i firm_state)
    score.ts           # relevance + activity + license + risk
    extract.ts         # fetch README + package.json/Cargo.toml/pyproject + 3-5 nøkkelfiler
    distill.ts         # LLM → 13-github-repos/<owner-name>.md frontmatter
    skill-extract.ts   # LLM → forslag til adopt-tasks for vår codebase
```

**Pipeline:** "search:..."-fil i `13-github-repos/_queue/` → BrainOrchestrator → `agent_tasks` (role:research, payload:query) → `github-discovery`-worker → distillert repo-note + (valgfri) implementation-tasks i `10-tasks/_open/`.

**Sikkerhet:** **Aldri** clone+run. Bare metadata + README + manifest-filer. Lisens-felt blokkerer GPL hvis vår dependency-policy krever det. Ingen executable code-loading.

### Module G — Hybrid Retrieval

```
packages/retrieval/
  src/
    index-builder.ts   # bygg BM25-FTS over verbatim + HNSW over distilled (rebuild nightly)
    query.ts           # natural-language → hybrid (BM25(V) + HNSW(D), CombMNZ rerank)
    cli.ts             # /brain recall "find that thing about worktrees and distillation"
```

**Standardquery-flow:** operator skriver vag query → top-10 distilled hits → renderes som `[exchange_core] → [source_ref backlink]`. Operator klikker → leser verbatim (aldri distilled). MRR-mål: 0.70+ på operator-eval-sett (10 vague queries kuratert månedlig).

### Module H — Background routines (BrainOrchestrator scheduled triggere)

| Routine | Cadence | Output |
|---|---|---|
| `nightly-memory-distill` | 03:00 | Distill gårsdagens actions → MemoryObjects → 03/06/07 brain |
| `repo-health-audit` | weekly | TS errors, dead deps, outdated `phase-status.md` → 09-retrospectives/ |
| `dead-link-check` | weekly | Broken wikilinks → 10-tasks/_open/ |
| `stale-task-detect` | daily | Tasks > 14 dager open → ping operator via 00-firm-bus/inbox/ |
| `skill-extract-from-success` | per task done | LLM evaluer om success-pattern → SKILL.md-stub |
| `github-discovery-drain` | hourly | Plukk `13-github-repos/_queue/` → `agent_tasks` |
| `youtube-ingest-drain` | hourly | Plukk `12-youtube/_queue/` → `agent_tasks` |
| `weekly-arch-review` | søndag 22:00 | Sammenlign `08-system-architecture/` mot faktisk kode → drift-rapport |

Alle routines er REPORT-only — aldri auto-fix. Per operator-prinsipp.

### Module I — Conductor-style worktree-as-default

Endre `firm-wt-split.sh` til å lage worktree per pane som default (ikke kun `--codex`). Hver pane får:
- Branch `<role>/scratch-YYYY-MM-DD-NN` (auto-generated, kan rebrandes på demand)
- `firm-task-claim.sh <task-id>` plukker fra `10-tasks/_open/` → flytter til `_in-progress/` → setter branch-navn = task-id
- `firm-task-complete.sh` → commit + push + open PR + flytt task til `_done/`
- Cleanup-job (BrainOrchestrator routine) GC'er worktrees > 7d uten kommit

**Frontmatter for inbox-dispatch (oppgrader):**

```markdown
---
task_id: T-2026-05-25-001
from: operator
to: code-2
objective: oppgrader brain m/ memory-engine
branch: code-2/brain-memory-engine
files_allowed: [packages/memory-engine/**, 08-system-architecture/**]
expected_output: TS pkg + tests grønne + PR opened
tests: npm -w @cc/memory-engine test
rollback: revert PR
status: dispatched
sla_seconds: 86400
---

## human-readable task-beskrivelse
```

`firm-inbox-watch.sh` parser frontmatter og kan dispatche til `firm-task-claim.sh` automatisk hvis `auto_claim: true`.

### Module J — Dashboard upgrade (`apps/web` extensions)

Nye pages:
- `/brain/recall` — query-felt + hybrid retrieval results
- `/brain/memory` — siste 100 MemoryObjects (filterbar per project/source_type)
- `/brain/skills` — registry-view (alle tre tiers)
- `/brain/tasks` — workspace-wide task-board (parser `10-tasks/`)
- `/brain/routines` — BrainOrchestrator scheduled-routines status + last-run
- `/brain/rag` — agentic-RAG playground (operator skriver query, ser reasoning-trace + retrieved chunks + citations)

Nye widgets på `/`:
- AgentMatrix (16 Nexus + 6 desks + N brain-workers — alle med last-tick + last-error)
- OperatorDecisionQueue (live "hva må operator OK kjør på akkurat nå")
- MemoryWriteFeed (siste 20 distillation-events)
- CrossPaneHeatmap (8 panes × 8 prosjekter — siste handling)
- RagQueryLatency (p50/p95 per tier, siste 24h)

---

### Module K — RAG (Advanced + Agentic) — utvider Module B

Tre tiers, alle bygget på top av `MemoryObject`-schema (§2.B):

**Tier 1 — Naive RAG (baseline):**
- Chunking: faste paragraph-splits (fallback)
- Embedding: bge-m3 (multilingual, støtter norsk) — lokal via `@huggingface/transformers`
- Storage: sqlite-vss (in-process, lav ops-kost)
- Retrieval: top-K cosine similarity
- Generation: augmented prompt + citations
- Brukes som fallback når Tier 2/3 svikter

**Tier 2 — Advanced RAG (primær):**
- **Semantic chunking:** LLM-as-chunker (Claude Haiku 4.5) splitter på topic-grenser, ikke char-count. Fallback: sentence-window m/ nltk-style boundary-detection.
- **Strukturell chunking via paper 2603.13017v1:** distillation ER chunking — én MemoryObject per exchange m/ 4 paper-felter.
- **Hybrid retrieval:** BM25-FTS5 over verbatim + HNSW over distilled `specific_context` + CombMNZ fusion (paper-bevist beste resultat, MRR 0.759).
- **Re-ranking:** bge-reranker-v2-m3 (lokal cross-encoder) re-scorer top-50 → top-10.
- **Citation enforcement:** hver generert respons MÅ inkludere `[ref:source_id]` per påstand. Generation rejecter output uten refs.

**Tier 3 — Agentic RAG (komplekse queries):**
- Drevet av Claude Opus 4.7 (eller lokal Qwen 72B når on-prem AI deployed).
- Loop: query → retrieve → evaluate (LLM scorer relevance av hver chunk 0-1) → decide (sufficient? needs more? wrong direction?) → refine query OR generate.
- Max 3 iterasjoner (hard cap — anti infinite-loop).
- Output: svar + reasoning-trace (auditable, lagres som MemoryObject av source_type "agentic_recall").
- Brukes for: komplekse multi-hop queries, eksplorativ research, cross-domain syntese.

**Pipeline:**

```
packages/rag-engine/
  src/
    chunking/
      semantic.ts          # LLM-as-chunker (Haiku, topic-boundary)
      sentence.ts          # fallback: sentence windowing
      structured.ts        # paper 2603.13017v1: distill → MemoryObject (chunking IS distillation)
    embedding/
      bge-m3.ts            # lokal model via @huggingface/transformers
      provider.ts          # fallback OpenAI text-embedding-3-large hvis lokal ikke tilgjengelig
    storage/
      sqlite-vss.ts        # in-process, default
      qdrant.ts            # on-prem AI integration (lazy import, kun aktivert ved env-flagg)
    retrieval/
      hybrid.ts            # BM25 + HNSW + CombMNZ
      rerank.ts            # bge-reranker-v2-m3 cross-encoder
    agentic/
      loop.ts              # iterative retrieve-evaluate-decide-generate
      evaluator.ts         # LLM scorer chunk-relevance
      planner.ts           # avgjør refine-query vs generate vs abort
    generation/
      augment.ts           # bygger prompt med chunks + citation-tokens
      cite.ts              # enforcer [ref:X] i output, regex-validates
  examples/
    naive-query.ts
    advanced-query.ts
    agentic-query.ts
  tests/
    *.test.ts              # 80%+ coverage mål
```

**Query routing-tiers:**

| Query-type | Tier | Latens-mål | Notes |
|---|---|---|---|
| `/brain recall "vague memory"` | T2 | < 3s | Default for operator-facing recall |
| `/brain ask "complex question"` | T3 | < 30s | Multi-hop, eksplorativt |
| Background distill (nightly) | T2 | n/a | Batch |
| Verbatim quote lookup | T1 | < 500ms | Fast path for eksakt phrase |

**Personvern (binding):** All ingestion/embedding/rerank kjører **LOKALT som default**. OpenAI/Anthropic kun for distillation-LLM + agentic-loop-LLM. Sensitive data (refi-docs, regnskap, helse) går aldri til ekstern API → tvinger fram on-prem stack per `[[2026-05-24-onprem-ai-strategi]]` for produksjon-bruk.

**Anti-patterns (binding):**
- Aldri ship Tier 1 alene som default — for lav kvalitet per paper
- Aldri la agentic loop kjøre > 3 iterasjoner (kost + latens)
- Aldri embed OpenAI/Anthropic-keys inn i vector store — embeddings skal kunne re-computes lokalt
- Aldri slett verbatim source — distilled er index, source er sannhet
- Aldri vis distilled til operator som svar — kun bruk som retrieval-routing

---

## §3 Prompt-utbedringer (operator's mega-prompt)

Operator's prompt er ambisiøs og solid, men kan strammes for å unngå at agenter dobbelter eller blir for generiske. Konkrete forbedringer:

### 3.1 Eksplisitt LIFT-over-INVENT

**Legg til i prompten:**
> "Before designing any new module, check if Nexus (ai-assistent) or research-os already implements an equivalent pattern. If yes, LIFT and generalize rather than build from scratch. Specifically: FirmOrchestrator, agent_tasks queue, agent-trigger, postmortem-derive-lessons, research-os' two-stage extraction, learning-ledger Markdown format."

Uten denne instruksjonen vil agenter bygge fra null.

### 3.2 Konkret scope-cap per agent

Operator's prompt sier "10 parallel workstreams" men spesifiserer ikke hva hver agent IKKE skal røre. Conductor-stil krever `files_allowed`-allowlist. Legg til:

> "Each agent gets an explicit `files_allowed` glob-pattern. Operations outside the allowlist are blocked. Default: `packages/<module-name>/**` + `08-system-architecture/**`. Never touch Nexus prod (`apps/worker/src/firm/`), thesis dataset (`battery-electrolyte-predictor/data/`), or any `.env*` files."

### 3.3 Eksplisitt success-criteria per modul

Operator's deliverable-liste er output-orientert. Legg til input-orientert:

> "Each module's spec MUST include: (a) acceptance test command, (b) MRR or count-metric the module is graded on, (c) failure mode that triggers operator-alert. Without these, the module ships invisible."

### 3.4 Anti-hype filter (særlig viktig for YouTube)

> "Hype filter: when ingesting YouTube videos, the distill MUST flag (a) un-evidenced claims, (b) marketing language, (c) tools that overlap with what we already have. Mark `confidence: 0.X` low. Re-process queue if confidence < 0.5."

### 3.5 Sikkerhet — utvid

Per CLAUDE.md eksisterer secret-handling. Legg til for nye moduler:

> "GitHub discovery: never clone+execute. Only metadata + README + manifest files. License-check blocks GPL-incompatible repos. Block any repo with `install_script` or `postinstall` in package.json from auto-extraction. YouTube: never re-publish full transcripts; keep verbatim local-only."

### 3.6 Closed-loop learning eksplisitt

> "Every module MUST emit a learning-event on task complete OR fail. Event schema: `{task_id, module, outcome, surprising_finding?, suggested_skill?}`. BrainOrchestrator routes surprising_findings to 09-retrospectives/ and suggested_skills to 03-skills/_proposed/."

### 3.7 Norsk/engelsk-mix

Operator's prompt er engelsk. Per CLAUDE.md skal output være norsk. Legg til:

> "Operator commentary, brain notes, and inbox messages: Norwegian Bokmål. Code, technical specs, README, and SKILL.md: English (so they're portable + searchable). YAML frontmatter: English keys, content can be either."

### 3.8 Ikke-fjerning av eksisterende patterns

> "BRAIN STRUCTURE: additive only. `_decisions/`, `_maps/`, `_runbooks/`, `_library/` are load-bearing — do not relocate. New folders (`03-skills/`, `12-youtube/`, `13-github-repos/`, `09-retrospectives/`, `10-tasks/`, `00-templates/`) are added alongside. Cross-link new ↔ old via wikilinks."

---

## §4 Parallell-todo lister

Konvensjon: alle tasks får `T-2026-05-25-NNN` ID. Branch-navn `<role>/<short-slug>`. Operator OK kjør per lane før branch lages.

### 4.1 code-1 lane (10 parallelle subagents) — fokus: command-center orchestrator + brain-engine

| # | Task | Files allowed | Exit |
|---|---|---|---|
| C1-1 | `packages/brain-orchestrator/` skeleton — lift FirmOrchestrator generic | `packages/brain-orchestrator/**` | adaptive cycle compiles, 1 dummy trigger fires |
| C1-2 | `packages/memory-engine/` skeleton — schema + distill.ts (LLM call) | `packages/memory-engine/**` | MemoryObject schema, distill returns valid struct for sample input |
| C1-3 | `packages/memory-engine/` storage — verbatim FTS + distilled rows | samme | better-sqlite3 FTS5 index built, write+read roundtrip test |
| C1-4 | `packages/memory-engine/` retrieval — hybrid BM25+HNSW | samme | recall test på 10 query corpus, MRR > 0.6 |
| C1-5 | `packages/retrieval/cli.ts` — `/brain recall "..."` command | `packages/retrieval/**` + `apps/cli/**` | CLI returns top-5 m/ source-ref |
| C1-6 | `apps/web/app/brain/recall/page.tsx` — UI for hybrid retrieval | `apps/web/app/brain/**` | rendert page, kaller /api/brain/recall |
| C1-7 | `apps/api/src/routes/brain.ts` — REST endpoints (recall/memory/skills/tasks) | `apps/api/src/routes/brain.ts` + tests | 4 endpoints + 4 tests grønne |
| C1-8 | `packages/brain-orchestrator/triggers/nightly-distill.ts` | `packages/brain-orchestrator/src/triggers/**` | cron-tick driver distillation av forrige dags `audit_log` |
| C1-9 | Migration: `audit_log` → emit `agent_tasks(role:distill)` rows | `packages/sync/migrations/**` | migration applies, idempotent |
| C1-10 | Tests: 80% coverage på memory-engine + brain-orchestrator | `**/*.test.ts` | npm test grønn, coverage report |

**Dependencies (kritisk):** C1-1 → C1-8 → C1-9. C1-2 → C1-3 → C1-4 → C1-5 → C1-6. C1-7 trenger C1-2+C1-3 før den kan kalle dem.

### 4.2 code-2 lane (10 parallelle subagents) — fokus: ingestion + brain folders + skills

| # | Task | Files allowed | Exit |
|---|---|---|---|
| C2-1 | Opprett brain-folders + README-er per ny folder | `/home/nithu/Obsidian/Brain/{03-skills,12-youtube,13-github-repos,09-retrospectives,10-tasks}/**` | 5 nye folders + README per stk |
| C2-2 | `packages/youtube-ingest/` — yt-dlp wrapper + distill | `packages/youtube-ingest/**` | én test-URL → distillert note i 12-youtube/ |
| C2-3 | `packages/youtube-ingest/` whisper fallback + queue-watcher | samme | URL i _queue/ → task spawned innen 1h |
| C2-4 | `packages/github-discovery/` — search + score + extract | `packages/github-discovery/**` | en "search:react component library" → 3 distillerte repo-notater |
| C2-5 | `packages/github-discovery/` queue-watcher + license-guard | samme | GPL-repo blokkert m/ explicit log |
| C2-6 | `packages/skill-registry/` — discover + index alle SKILL.md | `packages/skill-registry/**` | finn alle SKILL.md i 3 tiers, returner JSON |
| C2-7 | Skriv 5 initielle SKILL.md i `03-skills/` (brain-distill, youtube-ingest, github-discover, multi-agent-dispatch, worktree-spawn) | `03-skills/**` | 5 filer m/ riktig frontmatter |
| C2-8 | `firm-wt-split.sh` — worktree-as-default modus + branch convention | `command-center/_bin/firm-wt-split.sh` | --worktree-default flag working, gjenstand-test |
| C2-9 | `firm-task-claim.sh` + `firm-task-complete.sh` scripts | `command-center/_bin/firm-task-*.sh` | claim → in_progress, complete → done + PR open |
| C2-10 | `apps/web/app/brain/{memory,skills,tasks,routines}/page.tsx` — 4 nye dashboard-pages | `apps/web/app/brain/**` | alle 4 sider rendrer, knyttet til /api/brain/* |

**Dependencies:** C2-1 før all annet (folders må eksistere). C2-7 trenger C2-1. C2-9 trenger C2-1 + Module I-konvensjon stabil. C2-10 trenger code-1's C1-7 (brain.ts API).

### 4.3 mine 10 sub-agents (ai-bench lane, ikke code-bench) — fokus: research, spec, content

| # | Task | Type | Output |
|---|---|---|---|
| A-1 | MEMORY_DISTILLATION_SPEC.md — full schema, retrieval modes, eval-set | spec | `08-system-architecture/specs/MEMORY_DISTILLATION_SPEC.md` |
| A-2 | AGENT_ORCHESTRATION_SPEC.md — task lifecycle, leasing, merge protocol | spec | `08-system-architecture/specs/AGENT_ORCHESTRATION_SPEC.md` |
| A-3 | OBSIDIAN_BRAIN_STRUCTURE.md — folder konvensjoner, frontmatter, link rules | spec | `08-system-architecture/specs/OBSIDIAN_BRAIN_STRUCTURE.md` |
| A-4 | YOUTUBE_INGESTION_SPEC.md — pipeline, anti-hype filter, copyright | spec | `08-system-architecture/specs/YOUTUBE_INGESTION_SPEC.md` |
| A-5 | GITHUB_DISCOVERY_SPEC.md — search, score, license-guard, security policy | spec | `08-system-architecture/specs/GITHUB_DISCOVERY_SPEC.md` |
| A-6 | SKILL_REGISTRY_SPEC.md — 3-tier discovery, auto-creation criteria | spec | `08-system-architecture/specs/SKILL_REGISTRY_SPEC.md` |
| A-7 | Pilot 10 vague-recall queries på eksisterende brain (eval-set for retrieval-tuning) | research | `08-system-architecture/eval/recall-eval-2026-05-25.md` |
| A-8 | Reverse-engineer Conductor's worktree lifecycle (les conductor.build docs hvis tilgjengelig, ellers infer fra navnekonvensjoner) | research | `13-github-repos/conductor-build.md` (placeholder + bekreft mot URL) |
| A-9 | Pilot YouTube ingest på 3 operator-relevante kanaler (manuell URL-liste, ikke automatisering) | content | 3 stk `12-youtube/<kanal>/<dato>.md` |
| A-10 | Skriv 09-retrospectives/2026-W21.md — roll-up av forrige uke (handoffs, decisions, gjennomførte tasks) | content | én retrospective-fil m/ format som blir mal |

**Disse 10 er research/spec/content — ikke kode.** Kan kjøres parallelt med code-1 og code-2 lanes. Output er filer i brain, ikke i repos.

### 4.4 Andre paner — anbefalt for å unngå overlap

| Pane | Anbefalt fokus mens code-1/2 jobber |
|---|---|
| ai-1 | Nexus normal drift (siden Karri sender proposals, og ai-1 håndterer trigger-publishing). Ikke involvert i brain-upgrade. |
| ai-2 | Test-coverage på Nexus gates (sin nåværende lane). Ikke involvert. |
| thesis-1 | Master-oppgave normal drift. Distillation-pilot fra thesis-conversations kan vente til Module B er stabil. |
| as-1, soking-1, personal-1 | Domain-arbeid uendret. Kan adopte brain-skill `update-config` for å sette opp deres egne `.claude/skills/`. |

---

## §5 Roadmap — 30-dagers fase-plan

### Uke 1 (2026-05-25 → 2026-05-31) — Foundations

- C2-1: brain folders (low risk, kan kjøres dag 1 etter OK kjør)
- A-1 til A-6: alle specs ferdig som referanse for kode-lanes
- C1-1: brain-orchestrator skeleton (kompileres, dummy-trigger fyrer)
- C1-2 + C1-3: memory-engine schema + storage

**Operator-gate uke 1:** OK kjør på folder-opprettelse + alle specs godkjent før noe touch'er kode.

### Uke 2 (2026-06-01 → 2026-06-07) — Memory + Retrieval

- C1-4: hybrid retrieval (target MRR > 0.6 på A-7 eval-set)
- C1-5: CLI `/brain recall`
- C2-2 + C2-3: YouTube ingest pipeline (med queue-watcher)
- A-9: pilot YouTube på 3 kanaler

**Operator-gate uke 2:** Recall MRR-test må bestås før Module B promotes til "primær retrieval-vei".

### Uke 3 (2026-06-08 → 2026-06-14) — Discovery + Skills + Tasks

- C2-4 + C2-5: GitHub discovery
- C2-6 + C2-7: skill registry + 5 initielle SKILL.md
- C2-8 + C2-9: worktree-as-default + task-claim/complete

**Operator-gate uke 3:** worktree-default må vise: 8 paner kan kjøre 8 tasks parallelt uten merge-conflict over 1 dag.

### Uke 4 (2026-06-15 → 2026-06-21) — Dashboard + Closure

- C1-6 + C1-7 + C2-10: alle brain-pages + API endpoints
- C1-8 + C1-9: nightly-distill trigger live
- C1-10: test coverage 80%+
- A-10 + ny 2026-W23 retrospective

**Operator-gate uke 4:** Full system end-to-end demo: operator skriver vague query → får brain-treff → klikker → ser verbatim → spawner ny task → 8 paner plukker → merge-back automatisk.

### Uke 5+ — Iterasjon

- Tuning av retrieval (per A-7 eval)
- Skill auto-creation fra successful tasks
- Brain dead-link weekly + stale-task daily
- Cross-pane heatmap + memory-write feed
- Optional: on-prem AI integrasjon (per `2026-05-24-onprem-ai-strategi.md` Tier 1)

---

## §6 OK-kjør-gates (binding — ingen handling før operator nikker)

> **Naming (H-10 reconcile, 2026-05-25):** alle gates i denne tabellen
> tilhører `brain-G*`-familien (brain-upgrade workflow-toggles). Søsterfamilien
> `infra-G*` (Litestream, LAN-auth, coverage enforcement) lever i
> command-center og surfaces av `/api/brain/decisions` — IKKE forveksles.
> Full disambiguation: [[2026-05-25-operator-gate-naming]].

| Gate | Hva | Hvorfor |
|---|---|---|
| brain-G1 | Opprett 5 nye brain-folders | Endrer vault-struktur — operator må OK |
| brain-G2 | Lift FirmOrchestrator-pattern inn i ny `@cc/brain-orchestrator` (kopier kode, generaliser) | Kopierer Nexus-IP til command-center — operator må OK |
| brain-G3 | Endre `firm-wt-split.sh` til worktree-default | Endrer hverdagslig pane-startup — operator må OK |
| brain-G4 | Aktiver nightly-distill-cron | Skriver til brain nattlig — operator må OK |
| brain-G5 | Hver PR fra code-1/code-2 lanes — ikke push uten OK kjør | Vanlig push-gate per CLAUDE.md |
| brain-G6 | YouTube + GitHub queue-watchere som plukker fra operator-droppe filer | Først kjøres manuelt på operator-tilstedeværelse, så auto kun etter 1 ukes verifisering |

**Ingen gate dekker:** spec-skriving (A-1 til A-6), eval-set-bygging (A-7), research-tasks (A-8). De kan kjøres uten OK kjør siden de bare leser + skriver til 08-system-architecture/.

---

## §7 Risiko-topp-10

1. **Nexus-kode-lift bryter Nexus prod.** Mitigation: lift som kopi, ikke flytting. Nexus-kode forblir untouched.
2. **Distillation kvalitet er dårligere enn paper hevder for vår domene.** Mitigation: A-7 eval-set først; ikke replace primær retrieval før MRR > 0.6.
3. **Vector-storage scope-creep.** Mitigation: start m/ sqlite-vss (in-process). Kun migrere til Qdrant hvis on-prem AI-prosjekt aktivert.
4. **Worktree-default forvirrer operator.** Mitigation: --legacy-flag for å falle tilbake til shared-cwd.
5. **YouTube/GitHub ingestion bruker for mye API-budsjett.** Mitigation: rate-limit per dag + cost-tracking i firm_state.
6. **Skill auto-creation produserer søppel.** Mitigation: auto-skills går til `03-skills/_proposed/`, operator må manuelt promote.
7. **Brain blir for stor for Obsidian.** Mitigation: 90-archive/ for filer > 6 mnd; `dataview`-plugin for cross-folder views.
8. **Dashboard-overhead på operator.** Mitigation: alle nye widgets er opt-in via toggle.
9. **Conductor-stil locking blokkerer operator-manuelle merges.** Mitigation: lease er advisory, ikke enforced. Operator kan alltid override.
10. **GitHub-discovery sniffer for mye repos.** Mitigation: dagligs cap på 50 search-calls + 20 extract-calls.

---

## §8 Hva som IKKE skal gjøres (anti-scope)

- Ikke rør Nexus prod (`apps/worker/src/firm/**` — read-only-lift kun for kopiering)
- Ikke endre `.env*` filer
- Ikke flytte `_decisions/`, `_maps/`, `_runbooks/`, `_library/`
- Ikke automate Discord-meldinger til Karri (operator-trigger only)
- Ikke installer nye system-pakker uten OK kjør
- Ikke deploy on-prem AI hardware før forretningsbeslutning per `2026-05-24-onprem-ai-strategi.md`
- Ikke koble brain til skyen — local-first, kun GitHub for backup
- Ikke commit secrets, ikke print .env-verdier

---

## §9 Definisjon av ferdig

Brain-upgrade er ferdig når operator kan:

1. Skrive `/brain recall "noe jeg snakket om i forrige uke"` i hvilken som helst pane → få topp-5 hits m/ source-ref i < 3 sek
2. Slippe en YouTube-URL i `12-youtube/_queue/` → få distillert note i 12-youtube/ innen 1h
3. Slippe en GitHub-søk i `13-github-repos/_queue/` → få 3 distillerte repo-notater innen 1h
4. Skrive en task til `10-tasks/_open/` → en av 8 paner plukker den, jobber i isolert worktree, åpner PR, flagger operator for OK kjør, og mergeer på OK
5. Se i `apps/web/brain/routines/` om alle scheduled routines har kjørt siste døgn
6. Se i `apps/web/brain/memory/` siste 100 distillation-events
7. Spørre brain hva som ble bestemt om noe → få MemoryObject m/ exchange_core + decisions + source_ref

Hver av disse er en akseptanse-test.

---

## §10 Neste handling — AKTIVERT ALT A 2026-05-25T10:15Z

Operator OK kjør: "LA OSS KJØØRE PÅ".

**Aktivert:** Full sving. Spec-lane (A-1 til A-10) starter umiddelbart parallelt. code-1 dispatch lagt i inbox/code-1.md med komplett C1-1 til C1-10 lane. code-2 (denne pane) holder spec + monitoring + integrasjon-lane.

**Push-gate står fortsatt:** ingen push uten eksplisitt OK kjør per PR. CLAUDE.md "OK kjør gate before every push" gjelder. Lokalt arbeid (skriving til brain, scaffolding av nye packages) trenger ikke gate.

**Operator-gate fortsatt binding for:**
- brain-G3 (worktree-as-default) — operator må OK før firm-wt-split.sh endres
- brain-G4 (nightly-distill cron) — operator må OK før cron-job aktiveres
- brain-G6 (queue-watchers auto-pickup) — operator må OK før watcher kjører uten manuelt-trigger

Alt annet kan kjøre lokalt + venter på push-gate per PR.

---

## §11 5× verifiserings-policy (binding per operator-direktiv)

Per "VERIFISER PÅ NYTT 5 GANGER SJEKK AT ALT KJØRER":

**For markdown-deliverables (specs, eval-sets, brain-notater):**
1. Read-back sjekk — alle påkrevde seksjoner present
2. Cross-link validering — alle `[[wikilinks]]` peker til ekte notater
3. Frontmatter YAML-syntax valid
4. Faktiske påstander cross-checked mot kilde (paper / Nexus-fil / repo-state)
5. Scope-cap respektert — ingen drift utenfor task-allowlist

**For kode (TS packages, scripts):**
1. `tsc --noEmit` clean
2. `npm test` × 5 ganger (catch flaky)
3. Lint clean (`npm run lint`)
4. Manual smoke-test (run example, observe output)
5. `git diff` audit — kun files_allowed touched

**For brain-strukturendringer (nye folders, README-er):**
1. Folder eksisterer + skrivbar
2. README har frontmatter + tag + minst ett wikilink
3. `_maps/` MOC oppdatert om relevant
4. `sanity.sh` (brain pre-push) green
5. ls-treet matcher §2.C target

**Failure-action:** hvis verifisering #N feiler, returner til steg #1 etter fix. Aldri ship med kjent feil.

---

*Sist oppdatert: 2026-05-25T10:15Z av code-2. Alt A aktivert. Module K (RAG advanced+agentic) lagt til per operator-direktiv. §11 verifiserings-policy bindende.*

---

## §12 STATUS — 2026-05-25T11:30Z — fase 1 (specs) ferdig

**Mine 10 sub-agenter (A-1 til A-10) leverte alle parallelt på 4-7 min:**

| Deliverable | Path | Lines |
|---|---|---|
| MEMORY_DISTILLATION_SPEC.md | `specs/` | 693 |
| AGENT_ORCHESTRATION_SPEC.md | `specs/` | 652 |
| RAG_ENGINE_SPEC.md | `specs/` | 853 |
| OBSIDIAN_BRAIN_STRUCTURE.md | `specs/` | 924 |
| YOUTUBE_INGESTION_SPEC.md | `specs/` | 614 |
| GITHUB_DISCOVERY_SPEC.md | `specs/` | 553 |
| SKILL_REGISTRY_SPEC.md | `specs/` | 576 |
| recall-eval-2026-05-25.md | `eval/` | 132 |
| **6 brain-folders + 9 subfolders + 6 READMEs + 8 templates** | brain-root | additivt |
| **5 SKILL.md** | `03-skills/` | 80-138 each |

Total: 4865 spec-lines + struktur. Hver agent kjørte egen 5× verify-pass før retur. Meta-verifisert med ls/wc.

**Open items for v1.1 integration:**

1. **bge-m3 embedding-dim = 1024, ikke 768.** A-7 fanget feilen i A-1's prompt-hint. RAG_ENGINE_SPEC har riktig (1024). MEMORY_DISTILLATION_SPEC bør justeres på neste pass — propager via send-message til A-1 eller manual Edit.

2. **Folder-numerering-kollisjon (RESOLVED 2026-05-25):** Nye folders delte opprinnelig tall-prefiks med eksisterende:
   - `03-skills/` ↔ `03-business/` (BEHOLDT — semantisk OK)
   - `06-youtube/` ↔ `06-AS/` → **renamet til `12-youtube/`**
   - `07-github-repos/` ↔ `07-personlig/` → **renamet til `13-github-repos/`**
   - Operator-decision: renumberte nye til 12/13 (krevde kun mv + folder-path-update i specs; wikilinks uberørt).

3. **Cross-spec wikilinks resolver nå** — alle 7 sibling specs eksisterer. A-7's note om stub-links er resolved.

4. **Templates klar** — `00-templates/` har 8 stk (atomic/moc/skill/retrospective/task/memory-object/youtube-note/github-repo-note). Kan brukes av `firm-task-claim.sh` straks det skrives.

5. **code-1 dispatch sendt** 2026-05-25T11:30Z til `inbox/code-1.md` med full C1-1 til C1-10 lane, files_allowed-allowlist, spec-blockers per task, dependencies, 5× policy, push-gate, operator-gates, anti-scope. Code-1 forventes plukke opp ved neste pane-interaksjon eller Obsidian Git pull (≤5min).

**Neste fase (etter code-1 ack):** implementasjon av C1-1 til C1-10 + code-2 lane (C2-1 ferdig via A-8/A-9; C2-2 til C2-10 venter på operator-OK før igangsetting). Spec-review pass: operator kan lese 7 specs i `specs/` og gi feedback før kode rolles ut.

**Brain-plan bumpes til v1.1 etter operator har lest § 1-11 + alle specs.**

---

## §13 STATUS — 2026-05-25T12:15Z — fase 2+3

**Fase 2 (B-agenter) komplett:** Folder rename utført (06→12, 07→13). Cross-refs i 12 filer (~56 edits). bge-m3 fix v1.0.1 (768→1024). packages/skill-registry/ (10 filer, 7/7 tester x5). firm-task-claim/complete bash (5/5 tester). 3 nye MOC i _maps/. 2026-W22 retrospective. packages/_template/ (349/349 root tests still grøn). 3 pilot-tasks. Operator-facing tracking-doc.

**Fase 3 (C-agenter) i gang:** B-2 INTEGRATION_NOTES_v1.1 fanget 7 CRITICAL + 12 MEDIUM + 9 NIT funn. 10 C-agenter dispatchet for fix. Specs forventes v1.0.2 innen 15 min.

**Code-1 lane:** dispatch sendt 2x (11:30Z, 11:45Z). Ack-status sjekkes av C-7.

**Open operator-gates fortsatt bindende:** brain-G3 worktree-default, brain-G4 nightly-distill cron, brain-G6 queue-watcher auto-pickup. Push-gate per PR per CLAUDE.md. (NB: ikke forveksles med `infra-G*`-familien i command-center — se [[2026-05-25-operator-gate-naming]].)

**Spec v1.0.x state:**
- MEMORY_DISTILLATION_SPEC.md → v1.0.2 (etter C-1)
- AGENT_ORCHESTRATION_SPEC.md → v1.0.1 (etter C-2)
- RAG_ENGINE_SPEC.md → v1.0.1 (etter C-3)
- SKILL_REGISTRY_SPEC.md → v1.0.1 (etter C-4)
- OBSIDIAN_BRAIN_STRUCTURE.md → v1.0.1 (hvis MEDIUMs, etter C-5)
- YOUTUBE_INGESTION_SPEC.md → v1.0.1 (samme)
- GITHUB_DISCOVERY_SPEC.md → v1.0.1 (samme)

**Acceptance for v1.1 promotion (operator-gate):**
- Alle 7 CRIT fix landed
- Alle 12 MED fix landed eller eksplisitt deferred
- Cross-spec wikilink-validator (C-10) bekrefter 0 broken refs
- Operator har lest INTEGRATION_NOTES_v1.1.md

---

## §14 STATUS — 2026-05-25T14:00Z — fase 4-7 komplett

**Fase 4 (D-agenter):** 4 nye TS-packages (skill-registry FULL, youtube-ingest, github-discovery, rag-engine eval-runner scaffold) + 165 nye tester + 5 nye MOC (Memory/RAG/Youtube/Github-Repos/Retrospectives) + Runbook-Brain-Upgrade-Workflow + 4 stub-specs + 00-DASHBOARD + 00-CONTROL-PANEL Brain System-seksjoner + 30-agent audit-trail + 3 how-to drops i queue folders.

**Fase 5 (E-agenter):** apps/api `/api/brain/*` routes (3 wired: skills/invoke/tasks; 4 stubbed 503) + COMMIT_PLAN_2026-05-25.md (8 PRs planlagt) + brain-preflight.sh (8 verification sections) + `packages/integration-tests/` (cross-pkg e2e) + apps/web `/brain/{recall,memory,skills,tasks,routines,rag}/` pages (7) + pre-distill-manifest (560 MemoryObjects target) + 24 cross-MOC wikilinks tilført + Runbook-Sample-Task-Walkthrough + Runbook-Brain-Preflight-Checklist + test-summary baseline 522/522.

**Fase 6 (F-agenter):** Karri-dispatch via ai-1 (brain-upgrade snapshot levert) + workspace `/code/CLAUDE.md` Brain System surface + `tiger-brain README.md` additive + `00-CHEAT-SHEET.md` (139 linjer single-page operator-referanse) + 2 nye SKILL.md (brain-recall + brain-task-list) + `12-youtube/_channels.yaml` + `13-github-repos/_topics.yaml` stub-allowlists + Runbook-Brain-Demo (210 linjer, 7-part 15-min walkthrough) + `scripts/brain-content-audit.sh` (7-kategori weekly hygiene) + `_maps/Packages-MOC.md` (17 packages katalogisert).

**Fase 7 (G-agenter):** brain-content-audit live-run (24 invalid YAML + 135 missing frontmatter + 90 broken wikilinks identifisert i older content; script step-5 bug funnet) + brain-preflight validation (6/6 typechecks PASS, 15/15 bash syntax PASS, 0 stale 06/07 refs) + wikilink-audit v2 (803 RESOLVED / 30 STUB / **0 BROKEN** = 96.4% — +155 resolved siden v1) + INTEGRATION_NOTES_v1.2 (**all 7 CRIT RESOLVED**, 11/12 MED RESOLVED, 3/9 NIT resolved) + OPERATOR-NEXT-ACTIONS.md (15-item P0-P3 prioritert) + 2 nye SKILL.md (brain-task-claim + brain-task-complete) + brain-link-graph.sh (525 nodes / 2482 edges JSON-dump) + OperatorDecisionQueue React-widget + `GET /api/brain/decisions` endpoint + coverage gate setup (warning-mode baseline 43.31% lines / 77.05% branches / 71.13% functions) + manual-ingest-doc tilført Runbook-Brain-Upgrade-Workflow.

**Test-state:** 530/530 grøn (var 341 pre-sprint, +189 nye tester).

**Spec-state:** 
- MEMORY_DISTILLATION_SPEC v1.0.2 (paper-true + sqlite-vec + agentic_recall+sensitive SourceType + extras)
- AGENT_ORCHESTRATION_SPEC v1.0.1 (skill-runner role + event-driven Trigger + worktree-gc + skill-extract-from-success triggers)
- RAG_ENGINE_SPEC v1.0.1 (verbatim_row_id, SemanticChunk.meta)
- SKILL_REGISTRY_SPEC v1.0.1 (array-of-objects schema match)
- OBSIDIAN_BRAIN_STRUCTURE v1.0.1 (4 MEDIUMs landed)
- YOUTUBE_INGESTION_SPEC v1.0.1 (e2e cross-ref tilført)
- GITHUB_DISCOVERY_SPEC v1.0.1 (e2e cross-ref tilført)
- INTEGRATION_NOTES_v1.2 — alle CRITs resolved, klart for code-1

**Brain-folder structure:**
- 03-skills/ (7 SKILL.md — 5 fra A-9, 2 fra F-5, 2 fra G-6) + _proposed/_archived/_system/
- 08-system-architecture/ (plan + 7 specs + eval-set + INTEGRATION_NOTES_v1.1+v1.2 + wikilink-audit+v2 + audit-report + preflight-report + cleanup-report + coverage-gap + test-summary + pre-distill-manifest + 30-agent-audit)
- 09-retrospectives/ (2026-W22.md + README)
- 10-tasks/ (3 pilot-tasks i _open/ + HOW-TO-CREATE-TASK + lifecycle subfolders)
- 12-youtube/ + _queue/ + HOW-TO-DROP-URL + _channels.yaml stub
- 13-github-repos/ + _queue/ + HOW-TO-DROP-SEARCH + _topics.yaml stub
- 00-templates/ (8 templates + README)

**Code-1 lane status:** brain-orchestrator/ + memory-engine/ scaffolds eksisterer (node_modules-nivå). Aktivt arbeid pågår per F-10 finding. C1-1 + C1-2 sannsynligvis først ut.

**Code-2 lane status:** alle code-2-eier-oppgaver landed. C1-7 (apps/api/brain.ts) + C1-9 (sync migrations) venter på code-1's MEM/RAG-packages stabilitet.

**Push-state:** brain auto-syncet via Obsidian Git plugin. Command-center: 8+ PRs lokalt ucommittet, venter operator OK kjør per CLAUDE.md push-gate.

**Operator-gates fortsatt bindende:** brain-G3 worktree-default, brain-G4 nightly-distill cron, brain-G6 queue-watcher auto. Hver krever checklist-walk per `[[Runbook-Brain-Preflight-Checklist]]`. (Disambiguation mot `infra-G*`-familien: [[2026-05-25-operator-gate-naming]].)

**Total sprint:** 70 sub-agenter, 7 faser, ~4.5 timer wall-clock. Alle deliverables 5×-verifisert per §11.

**Brain-plan bumpes til v1.2 draft.**

---

## §15 STATUS — 2026-05-25T15:05Z — fase 8-10 komplett

**Fase 8 (H-agenter):** audit-script bug fix (set -euo pipefail) + brain content cleanup (20 YAML fixes, 80% frontmatter-warning reduction via I-5 exemptions) + coverage gap analysis (top: executor-worker.ts 369 lines 0% → 93.6%) + Packages-MOC oppdatert + brain-plan §14 + audit v2 (YELLOW, was RED) + Karri followup #2 + /home/nithu/code/README.md opprettet + brain-link-graph insights (525n/2559e/209-broken/251-orphans) + OperatorDecisionQueue endpoint spec (caught operator-gate identity mismatch).

**Fase 9 (I-agenter):** operator-gate naming Option C decision (`infra-G*` vs `brain-G*`, kanonisk i `_decisions/`) + wikilink-reconciliation (true broken count = 78 / 113 placeholders / 58 documented stubs, 3 ulike telle-modeller forsonet) + 8 spec YAML fixes (v1.0.2 unified) + executor-worker tests (+23, 0%→93.6% lines, workspace 43%→45%) + audit exemption-list (frontmatter false-positives -82%) + 3 sample artifacts (MemoryObject JSON + YouTube + GitHub) + 80-agent audit-trail v2 + PRESENCE root-cause (missing impl i firm-tab-init.sh; operator-gated fix) + link-graph v2 IMPROVING (535n/2684e/+125 edges) + FINAL-SUMMARY single-page (145 linjer).

**Fase 10 (J-agenter):** residual YAML fix (FINAL-SUMMARY + presence-investigation) + meta-leakage fix (audit-reports wrap wikilinks i code-spans, brain-link-graph.sh oppdateres for code-block-aware scanning) + I-1 gate cascade til 9 deferred filer + ws.ts coverage push (target: 10-15 tester) + brain-decisions endpoint tester + brain-content-audit v3 + OPERATOR-NEXT-ACTIONS oppdatert m/ fase 8-9 findings + ARTIFACT_INDEX (full inventory) + wikilink-audit v3 + denne §15.

**Test-state:** 565+/565+ grøn (var 341 pre-sprint, +220 nye etter alle 10 faser).

**Coverage-state:** 
- Lines: 43.31% → 45.36% (etter I-4) → estimert 47%+ (etter J-4 ws.ts) → estimert 48%+ (etter J-5 brain-decisions)
- Branches: 77%+
- Functions: 71%+
- Mode: warning (ikke enforce — operator OK kjør for å flipe)

**Spec-state:** alle 7 specs **v1.0.2 unified** etter I-3's YAML-konvensjon-pass. INTEGRATION_NOTES v1.2 confirmed all 7 CRIT + 11/12 MED resolved.

**Brain link-health:** 96.4% i G-3 v2-scope (08-system-architecture, _maps, 03-skills, 10-tasks, 00-templates, 09-retrospectives). I-2 reconciliation viste at full-vault scope = 78 truly-broken edges (mest i older 00-claude-inbox). J-9 v3 audit pending.

**Brain content-audit:** Issues=1 (specs YAML, partially resolved in v3), Warnings=24 (frontmatter — down from 135 via I-5 exemptions, etter J-1 sannsynligvis 22). Operator-actionable list i audit-report-v3 (J-6).

**Operator-gates fortsatt bindende per I-1's Option C:**
- `brain-G3` worktree-default (brain-upgrade workflow)
- `brain-G4` nightly-distill cron
- `brain-G6` queue-watcher auto-pickup
- `infra-G3`/G4/G6 (command-center infrastructure — Litestream/LAN-auth/coverage; pre-eksisterende, ikke en del av brain-upgrade)
- Push-gate per PR (CLAUDE.md)
- PRESENCE.md fix (5-line append i firm-tab-init.sh, operator-OK kjør per I-8)

**Code-1 lane:** scaffolds for brain-orchestrator + memory-engine eksisterer (node_modules-nivå). Aktivt arbeid pågår. Code-1 ack 12:45Z + lane-split (b)-MODIFIED akseptert. Venter på 14c Railway verify før C1-1+C1-2 skeleton work.

**Code-2 lane:** 100 % deliverable-pass. Alle code-2-eier-oppgaver landed. C1-7 (apps/api/brain.ts) scaffolded m/ stubs av E-1 + utvidet av G-8. C1-9 (sync migrations) venter på code-1's orchestrator schema.

**Total sprint:** 100 sub-agenter, 10 faser, ~5.5 timer wall-clock.

**Brain-plan bumpes til v1.3 draft** etter fase 10 fullført.

**Sprint 1 COMPLETE.** Sprint 2 venter operator-OK på (a) commit + push 8 PRs per COMMIT_PLAN, (b) code-1 implementasjon av MEM/RAG, (c) operator-gate aktiveringer i sekvens brain-G3 → brain-G4 → brain-G6.

---

## §16 STATUS — 2026-05-25T16:30Z — fase 11+12 EXECUTE komplett

**Fase 11 (K-agenter — closure):** Lukket J-9's 9 broken wikilinks (3 code-spans + 2 ADR stubs + 2 frontmatter fixes), fixed siste YAML, brain-link-graph v3 (544n/2253e/31 broken/98.62% health), FINAL-SUMMARY oppdatert til 100 agenter, TOMORROW-walkthrough, audit.ts tester (+13, 0%→100%), audit v4 **GREEN** (Issues=0), SPRINT-1-COMPLETE formal closure, critical-path verify 9/10 paths green, operator-note i inbox/code-2.md.

**Fase 12 (L-agenter — EXECUTE):** **8 PRs pushet** som drafts (#57-64) per COMMIT_PLAN. brain-G3 worktree-default aktivert som opt-in flag i firm-wt-split.sh. PRESENCE.md auto-populate fikset (5-line append i firm-tab-init.sh, både kanonisk + brain mirror). 24 missing-frontmatter filer adressert (6 minimal-fm + 18 exempted via script-extension) — count 24→0. Final audits: content GREEN m/ 1 residual YAML (M-5 fikser), link-graph v4 (549n/2268e/32-broken/98.6%), wikilink-audit v4 (878R/11S/1B = 98.7%). Brain pushet f0215d5 (auto-sync hadde fallt etter — 103 filer / +16087 / -54 i commit). Karri "system live" dispatch sendt via ai-1. OPERATOR-NEXT-ACTIONS markert 4 items DONE.

**Test-state:** 597/597 grøn. Coverage 47.63% lines / 77.21% branches / 73.1% functions.

**Spec-state:** alle 7 specs v1.0.2 STABILE.

**Brain link-health:** 98.7% (var 94.3% v1).

**Operator-gates aktivert:**
- brain-G3 worktree-default — **OPT-IN** (default uendret; flag tilgjengelig via `firm --worktree-default`)
- PRESENCE.md auto-populate — **ACTIVE** (next pane spawn populerer presence-row)

**Operator-gates fortsatt pending:**
- brain-G4 nightly-distill cron (depends on code-1's memory-engine)
- brain-G6 queue-watcher auto-pickup (depends on G4 stable 1 uke)

**Code-1 lane:** scaffolds eksisterer (node_modules-nivå). Aktivt arbeid pågår. Acked (b)-MODIFIED lane-split.

**Total sprint:** 120 sub-agenter, 12 faser, ~6 timer wall-clock.

**Brain-plan bumpes til v1.4 draft.**

**Sprint 1: SHIPPED.** Sprint 2 venter: operator merger 8 draft-PRs etter review, code-1 lander MEM/RAG-impl, G4 + G6 activerer i sekvens.
