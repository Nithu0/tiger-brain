# Workspace dev-backlog → "ferdig bygd PC" (lokal 24/7 AI-node)

**Dato:** 2026-06-02 · **Lane:** code-2 (workspace) · **Trigger:** operator "let etter alt vi må gjøre, kom med nye oppgaver, mål = kjøre alt over på ferdig bygd PC. letsgooo"
**Metode:** 6 parallelle read-only survey-agenter over command-center, ai-assistent (Nexus), refi-doc-agent, research-os/Personlig/Søking, brain @cc-pakker. Cross-pane stand-down respektert (kun lest andres repoer).

> **Bindende rekkefølge (fra `AS/docs/EXECUTION-DASHBOARD.md`):** Penger først → MVP → hardware.
> Maskinen kjøpes AV cashflow (Lofoten/refi-pilot), realistisk **august**. Dev-arbeidet under
> gjør stacken *klar* så `docker compose up` på noden bare funker når boksen finnes. Det binder
> ingen kapital nå.

---

## 0. Hva noden faktisk skal kjøre (fra `AS/docs/hardware/install-runbook.md` Fase 7)

Ubuntu Server 24.04 → Docker → ett delt `corenet`-nett → delt **Postgres + Redis + Qdrant** →
command-center + Nexus + refi-doc-agent + Open WebUI/Ollama → alt bundet til **Tailscale-IP**, ingen
WAN-porter. GPU (brukt RTX 3060→3090) driver lokale modeller (bge-m3 embeddings, 7–14B LLM).

---

## 1. Status per surface (verifisert mot kode, ikke bare docs)

| Surface | Tilstand | Største node-gap |
|---|---|---|
| **command-center** | Slices 1–13 merged. Hele brain/MEM/RAG sprint-2 ligger i **~70 DRAFT PR-er, 0 merged**. 374 tester grønne på main. | **Railway-formet, ikke node-formet.** compose har KUN Postgres (bundet 127.0.0.1:5433), ingen app-service, ingen Redis/Qdrant, ingen corenet. entrypoint dreper container hvis Fastify dør (motsatt av 24/7). |
| **Nexus (ai-assistent)** | 3 sunne multi-stage Dockerfiles (api/worker/dashboard) finnes — **premisset "ingen Dockerfile" var feil**. compose bygger api+worker. 1005 tester grønne. | compose publiserer pg/redis/api på **0.0.0.0** (3 WAN-brudd); api hardkoder `host:"0.0.0.0"` (`apps/api/src/index.ts:166`); bundler egen pg/redis (skal være delt corenet); ingen dashboard-service i compose; ingen `.dockerignore`. 2 commits committed-men-ikke-pushet (OK-kjør-gate). |
| **refi-doc-agent** | **Funksjonell FastAPI-MVP**, lengre enn skjelett. 14/14 tester grønt, demo-er offline (PDF→klassifiser→sjekkliste→talluttrekk→e-postutkast). Tall er Python-only (aldri LLM) — juridisk vinn. | Ingen Dockerfile/compose. Ingen auth (serverer rå PDF-er til hvem som helst på porten). Ingen `REFI_ALLOW_REAL_DATA`-gate (plan krever syntetisk-only til jurist). LLM-default=anthropic (doc-tekst forlater maskin). Ikke git-init. |
| **research-os** | Komplett MVP-1 Typer-CLI (25 moduler, 8 tester, OpenAlex/Crossref/S2/Unpaywall). | Ikke en node-tjeneste (interaktiv CLI). Trenger bare evt. repoint DATABASE_URL. |
| **Personlig** | Dashboard-kode (597-l aggregator) + CLIs ferdig, men **all data tom**. Helsedata `07-personlig/` ER allerede i Brain `.gitignore` (ingen lekkasje — falsk alarm fra survey). | Ikke node-tjeneste. Blokkert på operator: fyll mål/mat-fase/1RM. |
| **Søking fulltid** | Fase-2 agent bygget (9 moduler, 3036 l): scanner (arbeidsplassen.no + finn.no), scorer, daily.py-orkestrator. Kjørbar, men manuell. | **Eneste rene node-tjeneste-kandidat**: nattlig scraper-cron. Lett (requests/bs4/openpyxl, ingen CUDA). |
| **Brain AI-OS** | Stor moden spec, ~70 DRAFT PR-er, **nesten ingenting merged**. 4 av 5 @cc-pakker tomme på main; kun skill-registry delvis landet. | **bge-m3 embedding-generering finnes IKKE i noen branch** — dette er den ekte GPU/node-avhengigheten. Resten er merge-train + G3/G4/G6-gates. |

---

## 2. Konsolidert backlog — gruppert etter spor, prioritert

### SPOR A — Node-readiness (gjør stacken kjørbar på boksen). Eier: code-1/code-2 (workspace)
Kritisk sti til ett integrert `docker compose up`: A1→A2→A3→A4, så A8 (data), så A9 (backup).

| # | Oppgave | Repo | Effort | Hvorfor |
|---|---|---|---|---|
| **A1** | Lag node-stack-skjelett: `/opt/stack/data/` compose med delt **Postgres+Redis+Qdrant**, ett eksternt `corenet`-nett, bundet Tailscale-IP/intern, secrets via `/run/secrets` | ny (node-repo el. command-center/deploy/) | S | Ingenting snakker sammen uten dette (runbook Fase 7.1) |
| **A2** | Legg `networks: { corenet: { external: true } }` + fest alle services i begge repo-compose | command-center, Nexus | S | Apper må finne pg/redis/qdrant på navn |
| **A3** | Legg en **app-service** i command-centers compose (har kun Postgres i dag) via eksisterende Dockerfile, `DB_DRIVER=pg`, app-port bundet Tailscale-IP. Avkople Railway-only-antakelse | command-center | M | Appen kan ikke `docker compose up` i dag |
| **A4** | Fjern WAN-publish (5432/6379/3000) → intern/Tailscale-IP; gjør api-listen-host konfigurerbar (ikke hardkodet 0.0.0.0) | Nexus | S | 3 WAN-eksponerings-brudd (ai-1/ai-2 eier) |
| **A5** | Erstatt hardkodet `user:password` i Nexus-compose med Docker secrets / chmod-600 .env-ref | Nexus | M | Secret-in-VCS-lekk på noden (ai-1/ai-2 eier) |
| **A6** | Dockerfile + compose-service for refi-doc-agent på corenet, `data/` som volume, prod-bind (ikke `--reload --host 0.0.0.0`) | refi-doc-agent | S–M | Ingen container-artefakter i dag |
| **A7** | `.dockerignore` i Nexus (+ verifiser command-center) | Nexus, cc | S | node_modules/.git/worktrees bloat |
| **A8** | Datamigrasjon: `pg_dump` gamle hoster → restore til delt Postgres; cc kjør `migrate-sqlite-to-pg.ts` + flip `DB_DRIVER=pg` | cc, Nexus | M | 24/7 multi-writer trenger pg, ikke embedded sqlite |
| **A9** | Backup: nattlig pg_dump-cron + Qdrant-snapshot + restic/borg av volumes til disk-2/off-site; **test én restore** | node-nivå | M | Runbook Fase 8 er helt greenfield (0 backup-verktøy finnes) |
| **A10** | Prosess-supervisor for 24/7 (systemd unit / `restart: unless-stopped` for api+web) + UPS graceful-shutdown (`nut`) | node-nivå | M | cc entrypoint er Railway-formet (dreper seg selv) |
| **A11** | Verifiser `BROKER_MODE=demo` + `DEMO_AUTO_DEGRADE_ENABLED=false` bakt i node-env; ingen live OANDA-URL | Nexus | S | Må aldri auto-switche til live (binding) |

### SPOR B — Brain AI-OS merge-train + GPU (det noden gjør "smart"). Eier: code-1/code-2
| # | Oppgave | Effort | Gate | Hvorfor |
|---|---|---|---|---|
| **B1** | Triage de ~70 DRAFT-PR-ene: dedupe C1/C2-kollisjoner (brain.ts, sync-migration, rag-engine bygget dobbelt), velg kanonisk, close resten, definer merge-tog | L | — | Sprint-2 er 100% un-merged + delvis duplisert; ingenting shipper før dette |
| **B2** | Land fundament-PR-er: workspace-lockfile, memory-engine (skel+storage+distill), sync-migration 003, **wire de 6 nye pakkene inn i root build/typecheck** | M | — | Pakkene bygger/typechecker ikke i CI som de står |
| **B3** | **Implementer `embedding/bge-m3.ts`** (lokal modell via transformers/Ollama) — finnes IKKE i noen branch | L | — | RAG kan lagre/spørre vektorer men ikke *produsere* dem. Ekte node/GPU-avhengighet |
| **B4** | Land rag-engine ekte lanes (hybrid/rerank/agentic) som erstatter PRNG-stubs; eksponer HTTP-routes (`/api/rag`,`/api/memory`,`/api/skills` finnes ikke) | L | — | main shipper kun deterministiske stubs i dag |
| **B5** | Bygg/kjør recall eval-set, bevis MRR ≥0.6 | M | G4 | Hard precondition for nightly-distill + "primær retrieval" |
| **B6** | Merge brain-orchestrator + register `worktree-gc` + queue-triggers | M | G3/G6 | Runtime som driver alt; låser opp G3-default-flip + G6 |
| **B7** | Land youtube-ingest + github-discovery, wire `_queue/`-watcher bak `BRAIN_QUEUE_WATCHER_ENABLED` | L | G6 | Queue-dirs er klare; ingestion er operator-synlig payoff |

### SPOR C — refi-doc-agent → pilot-trygg (nærmeste revenue-MVP). Eier: code-2 + operator
| # | Oppgave | Effort | Blokkerer pilot? |
|---|---|---|---|
| **C1** | Auth foran alle routes (HTTP basic / delt secret) | S | Ja |
| **C2** | Hard `REFI_ALLOW_REAL_DATA=0`-gate som blokkerer uploads til flippet | S | Ja (compliance — jurist-gate) |
| **C3** | Kryptering at-rest av uploads + retention/delete-policy | M | Ja (ekte data) |
| **C4** | Default til lokal LLM-backend (eller av) for ekte-data-runs; dokumenter data-egress-bryter | S | Ja (ekte data) |
| **C5** | Bredere talluttrekk-regler + surfacing av "low-confidence/unparsed" i UI | M | Nei (begrenser verdi) |
| **C6** | OCR (Tesseract) for skannede/bilde-docs | M–L | Nei (Fase 2) |
| **C7** | `git init` + første commit + push (OK-kjør-gate) | S | Nei |

### SPOR D — Søking-scraper som node-tjeneste. Eier: soking-1 + code-2
| # | Oppgave | Effort | Hvorfor |
|---|---|---|---|
| **D1** | Dockerfile + nattlig cron (~02:00 UTC) for `daily.py` på noden | S | Eneste rene node-service-kandidat; lett, ingen CUDA. Friske leads hver morgen |
| **D2** | Fase 3 Streamlit-CRM over `leads/stillinger.xlsx` (filtre: score/frist/sted/status) | L | `crm/`-mappa er tom; visuell payoff |

---

## 3. Foreslåtte NYE oppgaver (utover å lukke eksisterende gaps)

1. **`docs/deploy/node-stack/` i command-center** — kanonisk hjem for `/opt/stack`-compose-filene (data/proxy/cc/nexus/refi/openwebui), versjonert, så noden bygges fra repo, ikke fra hukommelse. Dette er den manglende limet mellom `install-runbook.md` (prosedyre) og repoene (kode). **(M)**
2. **Én `make node-up` / `deploy.sh`** som orkestrerer corenet→data→apper i riktig rekkefølge med helsesjekker. **(M)**
3. **Tailscale ACL-fil + binding-checklist-script** (`ss -tlnp`-verifisering at ingenting lytter på 0.0.0.0) som CI-gate. **(S)**
4. **Cloud-GPU MVB-runbook** (Runpod/Vast A100/4090) per control-core-plan §D — så refi-pilot kan leveres på cloud-GPU FØR boksen kjøpes. Dette er den faktiske kritiske stien til cash, ikke hardware. **(S)**
5. **Secrets-strategi for noden** — bestem Docker secrets vs sops/age vs chmod-600; ett mønster, dokumentert. Unngå Nexus' hardkodede compose-creds. **(S)**

---

## 4. Det som IKKE er dev-arbeid (operator/forretnings-gates — fra EXECUTION-DASHBOARD)
- Ring Trondheim-partner (Lofoten-aksept) · SMS regnskapsfører (refi-kaffe) · book jurist (2 spørsmål) · sjekk Altinn MVA-terminer + lever skattemelding · avklar NAV-dagpenger skriftlig.
- **Ingen hardware-kjøp før Lofoten-cash på konto + MVA satt av/ryddet, ELLER refi-pilot-forskudd inne.** Realistisk august.

## 5. Verifikasjons-notat
- Nexus HAR Dockerfiles (premiss korrigert). · command-center er Railway-formet (strukturell node-gap). · refi-doc-agent kjører faktisk (14/14, demo-et). · Brain sprint "SHIPPED" = i branches, ikke på default branch. · Personlig-helsedata ER allerede gitignored (falsk alarm rettet).
