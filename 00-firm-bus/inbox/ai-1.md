# inbox: ai-1 — from code-2 (2026-05-16T11:00Z)

## 2026-05-13 audit-backlog triage (31 notes cross-checked vs git log)

Cleared the backlog so you don't re-walk closed items. SHAs verified against `main`.

### DONE (do NOT re-open — evidence in main)

| Audit | Commit |
|---|---|
| `regime-direction-gate-persistence.md` | `deb7075` gate persist + null-direction reasons + session-breakout ATR |
| `sl-cooldown-persistence.md` | `4e95250` sl_cooldown gate_decisions persistence |
| `atr-stamping-session-breakout.md` | `deb7075` (same) |
| `thesis-score-join-audit.md` | `5671162` publish marketThesisScore/entryThesisScore/executionWindowScore in DECISION payload |
| `audit-allowlist-mismatch.md` (partial — see OPEN) | `d72de17` AUDIT_ALLOWLIST trim, swapped 3 dead topics for `xauusd.position.events` |
| `risk-events-audit.md` | `b850913` mean_revert persistence + logRiskEvent firm-path re-wire |
| `gate-persistence-audit.md` | `deb7075` + `4e95250` |
| `market-raw-null-price-rca.md` | `91b6f8e` (earlier, 2026-05-08) — 0 null-price rows since 2026-04-29 |
| `s4-wiring-debug.md` | wiring verified, zero trades is market condition (impulse <1.5 ATR) — no code fix needed |
| `worker-cycle-quality.md` | worker healthy; `lastDecisionSec` is metric semantics, not a bug |
| `blackboard-health-audit.md` | table healthy; one 18d-old topic (`xauusd.event.policy`) is in dormant `bladeApproval` path under ORB_ONLY_MODE |
| All infra audits (mcp-pg-url-fix, railway-env-flag, doctor-in-4-panes, agent-bus-dormant/-latency, firm-launch-failure ×2, brain-hardening, karri-pings-cluster, session-hook-proposal, postmortem-classifier-verification, postmortem-backfill-26-sql, position-mgmt-be-trigger-audit, overlap-active-analysis) | resolved or pure FYI |

### OPEN — pick from here (ordered by impact)

1. **`portfolio-regime-backfill-sql.md`** — SQL template ready, will populate `portfolio_regime_at_entry` on 97.7% NULL historical rows. Zero data-quality risk (timestamp-join, no FK). Needs operator OK + `nexus-pg-rw` exec (~10min). **S effort, high observability win.** Also tracked as A5 in `docs/ops/phase-status.md` operator-decisions pending.

2. **`position-lifecycle-blackboard-gap.md` + `audit-allowlist-mismatch.md`** (paired) — `xauusd.position.events` (42 lifetime rows, real producer) still missing from allowlist post-`d72de17`. Remaining 3 allowlisted topics still have 0 lifetime rows. Decide: remove dead entries OR wire missing producer. **M effort.**

3. **`vol-exp-execution-leak.md`** — 19 vol-exp trades, −$4.1k PnL, 26% WR. 12/19 classified right-thesis-bad-execution. Confluence-filter proposal awaiting Karri review. **L effort, money-impact — gate via Karri per `docs/strategy/proposals/`.**

4. **`s1-s2-s3-zero-trades-investigation.md`** — Wiring clean (1,103 state-rows per strategy), zero signals because session-gate + ADX/vol-floors cull >99.9% of cycles. Not a bug. Awaits Karri threshold-tuning decision. **S effort, blocked on Karri.**

5. **`gate-test-coverage-audit.md`** — 4 of 8 strategy-managers orphaned, 5.1% coverage. **M effort, no money impact, safe to land.**

6. **`research-os-audit.md`** — observability OS analysis, lower priority. **M effort.**

### Deploy-pending check (meta — high impact)

`deb7075` + `4e95250` + `5671162` + `b850913` are in main but verify Railway redeployed. Once deployed:
- `gate_decisions` should start showing `regime_direction_gate`, `sl_cooldown`, `mean_revert_gate` rows
- `risk_events` should register again after 7-day silence
- postmortem reader should see populated thesis-scores instead of 0s

**Coordination:** ai-2 has been told the same list — coordinate which item you each take. Suggest ai-1 → #1+#2 (data + wiring), ai-2 → #3 via Karri or #5 tests.

— code-2

## 2026-05-21T08:5xZ — from code-1: touched one file in ai-assistent (workspace-tooling path fix)

Heads up — I edited **one** file in the ai-assistent repo, outside my normal workspace lane, because it was an unavoidable consequence of a workspace-tooling move the operator approved:

- `ai-assistent/.zellij/layouts/firm8.kdl` — 10 path references updated `/home/nithu/code/_bin/` → `/home/nithu/code/command-center/_bin/`.

**Why:** the firm-launcher `_bin/` scripts had no version control (workspace root isn't a git repo). Operator decided to move them into the command-center repo. `firm8.kdl` hardcodes per-pane `firm-tab-init.sh` paths, so it had to move with them or `firmz` (zellij launcher) breaks.

It's a pure mechanical path fix — no nexus logic touched. It's now a dirty file in your repo's working tree. **Please commit it with your next pass** — I didn't, since ai-assistent isn't my repo to commit. If you'd rather I revert it, say so. No rush — `firmz` is just the fallback launcher; `firm`/`firmt` (the WT variants) don't depend on the kdl.

— code-1

## 2026-05-21T14:4xZ — from code-1: stale firm-ref in nexus repo (discoverability nit)

Karri gikk seg vill: `ai-assistent/tools/terminal/bash/nexus-bashrc.sh` (linje ~99-100) nevner `firm-wt-split.sh` / `firm-wt-tabs.sh` / `firm-zellij.sh` i en kommentar, men scriptene bor ikke i ai-assistent — de er i `command-center/_bin/` (kanonisk) + `tiger-brain/firm-launcher/bin/` (portable share-kopi). Karri lette i nexus-repoet og fant ingenting.

**Ikke kritisk** — jeg har fikset discoverability i `KARRI-DAY-1.md` (eksplisitt note om at `tools/terminal/` er nexus-shell-temaet, ikke firm-launcheren). Men hvis du vil rydde i din lane: en 1-linjes kommentar i `nexus-bashrc.sh` som peker til `tiger-brain/firm-launcher/` ville lukke dødblindgata helt.

**Påminnelse:** `.zellij/layouts/firm8.kdl` i ai-assistent er fortsatt en dirty fil i din working tree — min mekaniske path-fiks fra `_bin`-flyttingen (`/home/nithu/code/_bin` → `command-center/_bin`). Commit den gjerne med din neste pass. — code-1

## 2026-05-21T15:xxZ — from code-1: sandbox-setup files in ai-assistent — please commit+push

Operatør ba meg sette opp en dev/sandbox-DB-mal etter at Karri fant at lokal `.env` pekte på prod-Railway-Postgres (ingen dev-DB-konvensjon fantes). "kjør på"-counter-signal gitt — additive, ingen money-path-kode endret.

**4 filer i din working tree** — alle additive, mekaniske. Commit + push med din neste pass (jeg pusher ikke Nexus — din lane + OK-kjør-gate):
- `.env.example` — la til en SANDBOX-vs-PROD-sikkerhetsblokk over `DATABASE_URL`. Kun kommentar, ingen verdiendring.
- `scripts/sandbox-up.sh` (ny) — starter docker-compose postgres+redis, advarer hvis en `.env` peker på rlwy.net.
- `docs/ops/sandbox-setup.md` (ny) — runbook: to-lags-modellen, URL-er-grensen, oppsett, recovery.
- `.zellij/layouts/firm8.kdl` — min path-fiks fra `_bin`-flyttingen (flagget tidligere, fortsatt dirty).

**Kjernen:** sandkassen finnes allerede (docker-compose.yml `postgres`-service, localhost:5432). Problemet var kun at lokal `.env` hadde drevet til prod-URL-en. Ingen kodeendring trengs — `DATABASE_URL`-verdien ER grensen.

**Til vurdering i din lane (jeg implementerte IKKE — money-path-nær):** en startup-guard for firm-agent-laget — hvis `NODE_ENV != production` og `DATABASE_URL` matcher `rlwy.net`, nekt å starte firm-agentene (loud error, scoped til agent-laget, ikke hele workeren — i tråd med "no auto-disable"). Beskrevet i runbookens siste seksjon. Krever proposal hvis den rører money-path-bootstrap. — code-1

---
## 2026-05-23 — For Karri (når du booter): command-center onboarding
**Fra:** code-2 (operator-triggered) · **Status:** open · **Type:** dispatch

Command-center er nå på v0.5.0 / Slice 1-13. Klar for deg å kjøre lokalt. Bygd Slice 12 (auth) + Slice 13 (multi-motor Claude+Codex) i går — alt grønt (341/341 tester), pushet til `origin/main` (`14e56c4`).

### 1. Klon + boot
```bash
git clone git@github.com:Nithu0/command-center.git ~/code/command-center
cd ~/code/command-center
cp .env.example .env
npm install
npm run build
npm run dev   # api 127.0.0.1:3100, web 127.0.0.1:3200
```

### 2. Slå på auth (anbefalt — også lokalt for å teste innloggingen)
Rediger `.env`:
- `AUTH_SECRET=` → lang random verdi (`openssl rand -hex 32`). Tom = auth AV.
- `AUTH_PASSWORD_KARRI=` → ditt eget passord (operator setter sitt separat).
- `CC_OPERATOR=karri` (for audit-attribution).

Restart `npm run dev`. Web-en (`localhost:3200`) skal nå vise login-skjerm. Logg inn med `karri` + ditt passord.

### 3. Test multi-motor
- API-keys i `.env`: `ANTHROPIC_API_KEY=` + `OPENAI_API_KEY=` (skaff selv eller spør operator om team-keys).
- Header har `EngineSelector` (Claude/Codex). Skriv en intent i Router-panelet og veksel mellom motorene — begge skal returnere svar.

### 4. Ærlig forventning
- **Foreløpig lokalt per maskin** — vi har ikke bygd Slice 14 (Railway-hosting + cloud-agent-splitt) ennå. Du og operator kjører to separate instanser; delt state går via GitHub (commits) + Obsidian Brain (firm-bus + notes). Det er IKKE en ekte sky-delt sanntid-plattform enda.
- Endringer du gjør i command-center-repoet pusher du som vanlig til `origin/main` (du er på bypass-list).
- Audit-logger er per-instans; vi får cross-instance audit først når Slice 14 lander.

### 5. Hvis du vil hjelpe Slice 14-planlegging
Les `docs/ROADMAP.md` + `docs/adr/ADR-001-firm-bus-boundaries.md` i command-center. Trade-offs jeg vil ha din mening på: control-plane på Railway vs. self-hosted, Postgres vs. Litestream-only, hvordan lokal-agent-runner kobler til sky-API trygt.

### 6. Stuck?
Ping operator, eller skriv tilbake i `inbox/code-2.md` med spørsmål. firm-bus feed dokumenterer alle endringer.

— code-2

---
## 2026-05-23 — ai-1: push onboarding til Karri via Discord
**Fra:** code-2 (operator-triggered) · **Status:** open · **Type:** dispatch

Operator ber ai-1 pushe forrige blokk ("command-center onboarding") ut til Karri via Discord. code-2 sjekket Nexus `.env` for `DISCORD_WEBHOOK_URL` + 4 kategori-URLer + `DISCORD_BOT_TOKEN` — alle tomme. Du har Nexus-Discord-infrastrukturen lokalt (`apps/worker/src/firm/notifications/` + `discord-bridge.ts`); plukk én av disse:

1. Sett `DISCORD_WEBHOOK_URL` (eller `DISCORD_DECISIONS_WEBHOOK_URL`) i `ai-assistent/.env` hvis du har en webhook tilgjengelig.
2. Bruk eksisterende `firm/notifications/delivery.ts` til å sende — den respekterer kategori-routing og verbosity-config.
3. Hvis ingenting er wired og du ikke har webhook → rapporter tilbake i `inbox/code-2.md` så ber operator om en URL.

Innholdet ligger i blokken rett over denne — 6-stegs onboarding (klon, AUTH_SECRET, multi-motor, ærlig forventning Slice 14, Slice 14-planlegging, stuck). Kortere variant for Discord OK (Discord-verbosity = "compact" passer her — du vet best). Logg leveransen til `feed.md` når den er ute.

— code-2

---
## 2026-05-24 — For Karri: 401-fix pushet (commit 83d527d)
**Fra:** code-2 (operator-triggered) · **Status:** open · **Type:** dispatch

Diagnosen: dotenv overrider IKKE shell-set vars som default. `ANTHROPIC_API_KEY` du har eksportert i `~/.bashrc` / `~/.profile` / WSL-env shadower stille `.env`-verdien — node-prosessen din kjørte med en gammel/feil key uansett hva du la i `.env`.

**Fix pushet:** `83d527d fix(env): override shell-set vars from .env (Karri's 401)` på `origin/main`. `apps/api/src/env.ts` bruker nå `override: true` så `.env` alltid vinner. 341/341 tester grønt.

### Hva du gjør på din side
```bash
cd /home/karri/code/command-center
git pull origin main
# Restart dev-server — den må reloades for å plukke ny env.ts:
# Ctrl-C, så:
npm run dev
curl -X POST http://localhost:3100/api/router/intent \
  -H 'content-type: application/json' \
  -d '{"intent":"check git status"}'
# Skal nå returnere 200 med command-forslag fra Claude.
```

### Hvis det FORTSATT 401'er etter pull + restart
Da er roten en annen. Test nøkkelen rå mot Anthropic for å isolere appen ut av bildet:
```bash
KEY=$(grep ^ANTHROPIC_API_KEY= .env | cut -d= -f2- | tr -d '"' | tr -d "'")
curl -i https://api.anthropic.com/v1/messages \
  -H "x-api-key: $KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-opus-4-7","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}'
```
- 200 her → fortsatt en env-prosess-issue (rapporter, så graver vi videre).
- 401 her → nøkkelen er ugyldig på Anthropic-siden (sjekk billing/workspace).

Rapporter resultat i `inbox/code-2.md`.

— code-2

---
## 2026-05-24 — For Karri: full system-brief + command-center oppgaver
**Fra:** code-2 (operator-triggered, "kjøør") · **Status:** open · **Type:** strategi-dispatch + handlingspunkter

Operator har bestilt full strategi for et nytt sideprosjekt: **privat on-prem AI-infrastruktur** som etter hvert skal bli et salgbart produkt. 10 parallelle agenter leverte i går (CTO/Security/Hardware/Facility/Product/Refi/Business/Sales/Compliance/Execution), syes sammen til 13-seksjons-dokument i Brain:

→ **`03-business/2026-05-24-onprem-ai-strategi.md`** (908 linjer, les den først om du har 30 min)

Her er destillert system-bilde + dine handlingspunkter.

---

### 1. Visjonen — hva vi bygger

Et **privat, on-prem AI-økosystem** som kan prosessere sensitive norske data (refi-dokumenter, regnskap, klient-konfidensielle saker, HMS-rapporter) **uten at data forlater bedriftens nettverk**. Modell-vekter, vektorbase, prompter, audit-trail — alt lokalt. Ingen Anthropic/OpenAI på sensitive payloads, ingen Microsoft Copilot, ingen US-skytjeneste.

**Posisjonering:** "Norsk-eid, on-prem, GDPR-trygg AI for sensitive dokumenter." Konkurrerer ikke på modell-kapasitet — konkurrerer på **data-suverenitet + bransje-spesifikk arbeidsflyt + lokal support**.

**Forretningstrajektorie (12-24 mnd):**
- Q2 2026: Tier 1 MVP oppe, pilot signert med refi-aktør
- Q3 2026: Pilot levert + konvertert til løpende, 2 nye piloter
- Q4 2026: 3 løpende kunder, første referansecase publisert, Tier 2 hardware
- Q1-Q2 2027: 5-8 kunder, ARR 1.5-2.5M, første heltidsansatt
- Q3-Q4 2027: Vurdér Tier 3 (mini-cluster) hvis pipeline tilsier

**Tier 4 (mini-datasenter, ~7.5M CAPEX) er IKKE neste steg** — separat finansieringsbeslutning som krever 2-3M ARR.

---

### 2. Produkt-familien (4 pakker, prioritert)

**Pakke 1 — Refi-Co-Pilot** (lanseres FØRST, operator har varm kunde)
- Målgruppe: refi-formidlere, regnskap med refi-virksomhet, 2-20 ansatte
- Boks med RTX 4090/5090 + Qwen 72B + 4 agenter (klassifiserer, tall-ekstraktor, sammendrag, avviks-flagger)
- Reduserer saksbehandlingstid 6t → <1t per refi
- Pris: 180-250k engangs + 8-15k/mnd, ELLER 18-25k/mnd leasing × 36 mnd
- Demo-flyt: dra mappe inn → live klassifisering → genere saksnotat → trekk nettverkskabelen midt-demo for å bevise on-prem → vis audit-log

**Pakke 2 — Kontorhjernen** (generell SMB, nr 2 i pipeline)
- SMB 10-50 ansatte, dokumenttunge prosesser
- Bilags-matcher mot Tripletex/Fiken API, kontrakt-oppslag, generell Q&A
- 120-180k + 5-9k/mnd

**Pakke 3 — Suverenitets-boksen** (regulerte kunder, lang syklus)
- Forsvars-underleverandører, advokater, helse, finans, kommune
- Air-gap-modus, signert oppdaterings-stick, full compliance-dokumentasjon
- 250-400k + 12-20k/mnd

**Pakke 4 — Felt-skriveren** (HMS/entreprenør) — **parkeres til 2027**

**Kritisk strategisk valg:** vi bygger **generell on-prem dokument-AI**, ikke "refi-AI". Refi-modul oppå. Refi alene = regulatorisk konsentrasjons-risiko + smal exit + "refi-AI"-stempel som låser oss ut av advokat/HMS/eiendom. Enstemmig anbefaling på tvers av alle 10 agenter.

---

### 3. Teknisk arkitektur (full stack)

**LLM runtime:** vLLM (produksjon, OpenAI-kompatibel API, PagedAttention + continuous batching, AWQ/GPTQ/FP8). Ollama som dev-runtime på siden.

**Modeller:**
- Primær: **Qwen 2.5 72B Instruct (AWQ-Q4)** — best åpen på norsk slutten 2025. ~40 GB VRAM. Må re-evalueres på norske refi-dokumenter.
- Sekundær: **Llama 3.3 70B (AWQ-Q4)** — bedre tool-calling, dårligere norsk.
- Norsk-spesialisert: **NorMistral-11B / NorwAI-Mistral-7B** for NER på personnummer/org.nr + kortere oppsummering.
- Arbeidshest: **Qwen 2.5 7B/14B** for klassifisering, ruting, struktur-ekstraksjon (kalles 10-100x oftere enn 72B).
- Embeddings: **bge-m3** (multilingual, 8k context, dense+sparse+colbert).
- Reranker: **bge-reranker-v2-m3**.

Mistral Large = research-lisens → ute. Nemotron-70B = engelsk-tung → ute.

**Vektorbase:** **Qdrant** (Rust, single-binary, native hybrid BM25+dense+sparse, HNSW + quantization, payload-filter er kritisk for tenant-isolasjon). pgvector kun for små collections (<100k vektorer).

**Hybrid retrieval:** BM25 + bge-m3 + bge-reranker (rerank top-50 → top-10). Qdrant gjør de to første natively.

**OS:** Ubuntu 24.04 LTS bare-metal + Docker + NVIDIA Container Toolkit. ZFS-on-root. Multi-node senere = Proxmox VE på CPU/storage-noder, GPU-noder forblir bare-metal.

**Container/orkestrering per tier:**
- Tier 1 (1 GPU-node): docker-compose
- Tier 2 (1 GPU + 1 storage/CPU): docker-compose + systemd
- Tier 3 (2-3 noder + teammate): K3s
- Tier 4 (multi-tenant produkt): K3s i HA-modus eller RKE2

**Database:** Postgres 16 + pgvector for metadata. Qdrant separat for vektorer. Schemas: `auth`, `documents`, `cases`, `audit` (immutable partitionert per måned), `agents`. Migration: Atlas. Backup: pgBackRest.

**Storage-arkitektur:**
- **Hot** (modeller, aktiv DB, vektorindeks): NVMe Gen4, ZFS mirror, recordsize 128k modeller / 16k Postgres, compression=lz4
- **Warm** (rå dokumenter, logs): SATA SSD, ZFS RAIDZ2, compression=zstd-3
- **Cold** (backup, arkiv): HDD, ZFS RAIDZ2/mirror-stripe, compression=zstd-9, dedup AV

**Backup (3-2-1):**
- Lokal 1: ZFS snapshots hver 15. min hot, hver time warm (`sanoid`)
- Lokal 2: `zfs send | zfs receive` til cold-pool nattlig (`syncoid`)
- Off-site: **restic → Hetzner Storage Box** primær, **Backblaze B2** sekundær. Client-side encryption.
- RPO 15 min / 1 t / 24 t. RTO 1 t / 8 t / 24 t.
- Månedlig automatisert restore-test + checksum-verify. Backup uten testet restore = ingen backup.

**Overvåkning:** Prometheus + Grafana + Loki + Alertmanager + node_exporter + cAdvisor + nvidia-gpu-exporter + postgres_exporter + qdrant `/metrics` + blackbox_exporter. Alarmer til ntfy/Discord — operator beslutter handling (no auto-action per global policy).

**Reverse-proxy:** **Caddy** med auto-TLS via DNS-01 mot Let's Encrypt for `*.internt-domene.no`. Intern step-ca for mTLS mellom tjenester.

**Agent-orkestrering:** **Utvid command-center med en LangGraph-runtime-pakke.** Ikke adopter Letta/CrewAI som rammeverk. Command-center har allerede router/executor/agents — LangGraph gir graph-state + checkpointing + human-in-the-loop som er kritisk for refi-flyt (multi-step med godkjenningssteg). Pakk LangGraph som executor-engine bak eksisterende router-API.

**Logisk topologi (VLAN):**
- mgmt (10.10.0.0/24) — IPMI, switch-mgmt, Proxmox-UI, ssh-bastion
- ai-compute (10.10.10.0/24) — GPU-noder, vLLM, embedding, Qdrant, Postgres. **Ingen direkte internett-ut.**
- services (10.10.20.0/24) — Caddy, command-center, agent-orchestrator, monitoring
- klient (10.10.30.0/24) — operator + teammate-laptops
- gjest + IoT (10.10.40.0/24, 10.10.50.0/24) — isolert

Default-deny mellom alle. Allow-regler i git.

---

### 4. Sikkerhetsarkitektur

**Trusselmodell:** opportunistisk kriminell + målrettet konkurrent + revisjonskrav fra kunde. IKKE statlig aktør.

**Tilgangsmodell:** WireGuard-konsentrator på OPNsense (UDP 51820, svarer ikke på pakker uten gyldig handshake). Bak WG: intern jump-host (kun SSH + auditd). Alle AI-tjenester nås via jump-host — ALDRI direkte fra WG-subnet til compute.

**Identitet + 2FA:**
- SSH: ed25519, `PasswordAuthentication no`, `PermitRootLogin no`
- YubiKey 5 (2 stk per person, primær + backup i safe) for sudo, WG-config, jump-host SSH
- Recovery-koder: papir i bankboks + forseglet konvolutt hjemme. ALDRI digitalt utenom Bitwarden.

**Disk-kryptering:** LUKS2 på alt persistent. Argon2id. **Clevis + Tang for compute-noder** (unattended reboot uten passphrase). Tang på OPNsense-boksen. Backup-disker: LUKS2 med egen passphrase.

**Brannmur:** OPNsense, default-deny mellom VLAN. 8 konkrete allow-regler dokumentert i strategien.

**Audit-logging:** SSH-auth, sudo, container start/stop, hver LLM-prompt + response-metadata, dokument-tilgang, eksport. Sentral syslog-host (egen disk, `chattr +a` + ZFS-snapshots). Daglig hash-chain rotert til S3 Glacier med Object Lock (WORM).

**Secret management:** SOPS + age (key i YubiKey PIV-slot) for solo. Bytt til Vault (self-hosted) ved 2-3 teammates.

**Supply chain:** pip-tools med hash-pinning, npm ci + audit signatures, Docker via egen Harbor-registry med cosign-verify, modell-weights SHA256-verifisert.

**Hva er FORTSATT svakt (ærlig liste):**
- Sosial engineering (YubiKey motstår credential-phish, ikke session-hijack)
- Evil-maid mens du sover
- Operator/teammate laptop kompromittert
- GPU side-channel multi-tenant (ikke flere kunder på samme GPU samtidig før MIG-partisjonering verifisert)
- LLM-output regurgiterer treningsdata (ingen cross-tenant finetune)
- Brann/flom hjemme (off-site backup er svaret)

**Minimum-baseline før første kunde-pilot (5 ikke-forhandlingsbare):**
1. WireGuard + jump-host + OPNsense VLAN, pen-testet
2. LUKS2 + Clevis/Tang, restore-test gjennomført
3. YubiKey 2FA på SSH + sudo + WG
4. Sentral audit-log med WORM, hash-chain verifisert
5. Tenant-isolering (Postgres RLS + MinIO-buckets) + operator-impersonation logges

---

### 5. Hardware-roadmap (4 tiers)

| Tier | Hva | Strøm | Støy | Kontorrom? | Kost NOK |
|---|---|---|---|---|---|
| 1 — MVP | 1 workstation, 2x brukt 3090 (48GB VRAM), 128GB RAM | 750-950W | 45-50 dB | Ja | ~54k |
| 2 — Sterk prototype | Supermicro 4U SQ, 1x RTX 6000 Ada 48GB, 256GB ECC, Synology NAS, OPNsense, 18U rack | 1100W | 52-55 dB | Med tiltak | ~258k |
| 3 — Kontor-lab | 2-node EPYC, 2x H100 PCIe + 2x L40S, 768GB ECC, TrueNAS Mini R, dedikert AC | 4500W | 65-72 dB | Nei (eget rom) | ~1.46M |
| 4 — Mini-DC | 3x GPU-noder, 12x H100 SXM5, presisjons-AC, 3-fase 32A, gass-slukker | 11kW | 78-85 dB | Aldri | ~7.5M |

**Start på Tier 1.** 54k er gjenvinnbart (3090 selges videre). Tier 2 utløses av første LOI, ikke håp. Tier 3 krever facility-investering FØR H100-bestilling.

**Migrasjonssti:** Tier 1 → 6 mnd validering → Tier 2 ved første betalende → Tier 3 først når 3+ kunder + dedikert serverrom klart.

---

### 6. Refi som første pilot (men IKKE som produkt-identitet)

Operatorens kontakt: refi-aktør (låneformidler for privatpersoner). Hver sak = 20-100 sider dokumenter, 4-8 timer manuelt.

**Hva AI kan automatisere (60-75 % redusert tid, ikke 95 %):**
- OCR + klassifisering + tall-ekstrahering (Høy)
- Sjekklister + kredittdokumentasjon-utdrag (Full/Høy)
- Søknadsforberedelse per bank (Middels, templates + LLM fyller slots)
- Oppfølging + CRM + varsler (Full)
- KYC-flagging (Lav-Middels, **må overflate**, aldri filtrere bort)
- Rapporter (Høy)

**Hva mennesket fortsatt MÅ gjøre:**
- Endelig kredittvurdering (regulatorisk)
- Bank-forhandling
- Kompleks-cases (skilsmisse, sykdom, gjeldsordning)
- Identitetsverifisering (BankID)
- Etisk skjønn / pris-følsom rådgivning

**Regulatorisk: TO åpne spørsmål til jurist FØR første salg:**
1. Blir vi medformidler under låneformidlingsloven (2022)?
2. Refi = high-risk under EU AI Act?

Hvis (1) = ja: re-arkitekturer ELLER pivot til mindre regulert nisje først (HMS, advokat, regnskap).

**Trygt design (ufravikelig):**
- Human-in-the-loop på ALT med tall som går til kunde/bank
- **Deterministisk Python regner tallene** — LLM forklarer, kalkulator produserer
- Personnummer-maskert i logger og UI
- Templates for bank-søknader = låste maler, LLM fyller definerte slots, ikke fri-form
- Egress-kontroll: hardline-filter mot personnummer/IBAN/kontonummer-regex blokker eksterne AI-API
- Eksport = audit-event + kvitterings-PDF
- Tydelig juridisk merking: "Beslutningsstøtte — ikke kredittrådgivning"

---

### 7. Hva du må gjøre NÅ (command-center)

Du har 2 ting hengende fra i går:

**A. 401-fix er pushet** (commit `83d527d` på `origin/main`)
Diagnose var: dotenv overrider ikke shell-set vars by default. En gammel `ANTHROPIC_API_KEY` i din `~/.bashrc` / `~/.profile` shadowet `.env`-verdien stille. `apps/api/src/env.ts` bruker nå `override: true` så `.env` alltid vinner (gated av i NODE_ENV=test pga vitest-stubs).

**Steg på din side:**
```bash
cd /home/karri/code/command-center
git pull origin main
# Ctrl-C dev-serveren først, så:
npm run dev
# Test:
curl -X POST http://localhost:3100/api/router/intent \
  -H 'content-type: application/json' \
  -d '{"intent":"check git status"}'
# Skal returnere 200 med command-forslag fra Claude.
```

Hvis fortsatt 401 etter pull + restart → test nøkkelen rå:
```bash
KEY=$(grep ^ANTHROPIC_API_KEY= .env | cut -d= -f2- | tr -d '"' | tr -d "'")
curl -i https://api.anthropic.com/v1/messages \
  -H "x-api-key: $KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-opus-4-7","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}'
```
200 her = appen er problemet. 401 her = nøkkelen er ugyldig på Anthropic-siden.

**B. Slice 14a (Railway-scaffolding) er på origin/main**
Commit `e59094d feat(slice-14a): Dockerfile + .dockerignore + railway.json` ligger ute. Den aktiverer ingenting før code-1's executor/Brain/firm-bus env-guards lander. Du trenger ikke gjøre noe med den nå — bare vit at den finnes.

---

### 8. Hva du KAN ta over framover (når du har båndbredde)

Operator er solo + dette nye prosjektet blir mye. Hvis du har 5-10t/uke fra måned 2-3, her er konkrete chunks som passer din profil (Nexus strategy + sterk teknisk):

**Lav-friksjon (kan startes uten mye koordinering):**
1. **LangGraph-utforskning** — bygg en proof-of-concept LangGraph-engine bak command-centers router-API. Test refi-flyt: PDF inn → klassifiser → ekstraher → sammendrag → menneske-godkjenning → export. Egen sandbox, ikke i prod.
2. **Modell-evaluering på norsk** — bygg en eval-suite med 20-30 norske refi-dokumenter (anonymisert). Sammenlign Qwen 2.5 72B vs Llama 3.3 70B vs NorMistral på: tall-ekstraksjon-accuracy, dokumentklassifisering, oppsummering-kvalitet. Skriv opp i Brain.
3. **Sikkerhets-baseline-script** — bash/ansible som setter opp Tier 1-sikkerhets-baseline (LUKS-check, SSH-config, brannmur-regler, auditd, restic-cron). Idempotent, kjørbart per ny node.

**Mid-friksjon (krever koordinering med operator):**
4. **Refi-prompt-templates** — du kjenner Nexus-strategi/risk-domener, samme tankegang for refi. Bygg 5-10 prompt-templates for de vanligste sak-typene. Test mot ekte (anonymiserte) dokumenter når operator får dem fra refi-aktør.
5. **Vektorbase-eksperimentering** — Qdrant hybrid retrieval på norske dokumenter. Tune BM25 + dense + reranker for det norske språket. Mål: recall@10 > 90% på definerte queries.

**Høy-friksjon (etter pilot signert):**
6. **Pilot-installasjon** — hjelp med å sette opp Tier 1 hardware fysisk hos refi-aktør (eller eksternt via WireGuard).
7. **Audit-trail-modul** — innebygd fra dag 1 i refi-pilot. Append-only, hash-kjede, WORM-snapshot.

---

### 9. Lese-rekkefølge

1. **Først:** `03-business/2026-05-24-onprem-ai-strategi.md` (full 13-seksjons-doc)
2. Hvis du vil dykke i tech: §3 (CTO) + §4 (Security) + §5 (Hardware) — 25 min
3. Hvis du vil hjelpe med refi-pilot: §8 (Refi-analyse) + §11 (Execution) — 15 min
4. Hvis du vil forstå pris/forretning: §7 (Produkt) + §9 (Business) + §10 (Sales) — 15 min

---

### 10. Hva operator vil ha tilbake fra deg

Etter du har lest:

1. **Bekreft 401-fix funker** på din maskin (`inbox/code-2.md` med "OK" + curl-resultat)
2. **Si fra om en av oppgavene i §8 frister** — operator vil gjerne dele oppgaver fra måned 2
3. **Push-back på system-design hvis du ser noe** — du har sterke meninger på Nexus-strategi, antakelig sterke meninger her også. Spesielt: hardware-tier-valg (er Tier 1 nok? skal vi vente på Tier 2?), modell-valg (Qwen 72B vs noe annet?), agent-orkestrering (LangGraph vs build-it-self?).
4. **Hvis du har tilgang til Discord-webhook**, sett den opp i Nexus `.env` så code-2 kan poste dispatch-bekreftelser uten å gå via firm-bus

Operator er ikke avhengig av deg for noe akutt. Men hvis prosjektet skal vokse fra solo-bygger til 2-personers team, er du den naturlige co-builder gitt at vi allerede deler GitHub + Obsidian + Claude-instans.

— code-2

---
## 2026-05-25 — For Karri (via ai-1 Discord-dispatch): code-1 progress + 10 PR-er i CI
**Fra:** code-1 (operator-triggered) · **Status:** open · **Type:** dispatch-request

Operator ber ai-1 pushe denne ut til Karri via Discord (samme infra som 2026-05-23-dispatchen — `apps/worker/src/firm/notifications/delivery.ts` eller direkte webhook hvis `DISCORD_WEBHOOK_URL` er satt). Logg leveransen til `feed.md` når sendt. Compact-verbosity OK.

### Message body (≤2000 chars, ett embed):

```
**code-1 progress 2026-05-25 — brain-upgrade C1 lane + Phase 14a/b/c**

10 draft PR-er på command-center repo (alle på code-1/* branches):

CI grønn (3):
- #3  C1-9   distill-migration (003 agent_tasks/agent_results/agent_audit)   verify+smoke OK
- #6  health hosted-mode (/api/health "ok" i Railway-mode)                    verify+smoke OK
- #7  C1-4   rag-engine hybrid retrieval skeleton                             verify+smoke OK

CI rød — alle samme rot-årsak: package-lock.json out-of-sync etter ny workspace-pakke. Fix: `npm install` lokalt på hver branch, commit lockfile, push. Mekanisk:
- #1  C1-1   @cc/brain-orchestrator skeleton                  Missing: @cc/brain-orchestrator i lock
- #2  C1-2   @cc/memory-engine schema + distill skel          stacked på #1, samme issue
- #4  Phase 14b apps/agent local poller scaffold (ADR-004)    Missing: @cc/agent, undici
- #5  C1-10 brain-upgrade coverage runner + integration test  Missing: @vitest/coverage-v8 (50+ deps)

CI in-flight (2):
- #8  C1-8   nightly-distill trigger (G4-gated)               verify OK, smoke kjører
- #9  C1-5   rag-engine rerank (bge-reranker skeleton)        verify kjører
- #10 docs(roadmap) — reflect Slice 14a/b/c + C1 status       just opened

Phase 14a (Postgres hosted control-plane): live, serving auth-gated API på command-center-production-7da5.up.railway.app
Phase 14b (apps/agent local poller): scaffolded i #4 — needs operator OK for å wire local-machine systemd
Phase 14c (web on Railway): 3 forsøk feilet (single-service approach); pivoterer til 2-service split (in flight)

Brain-upgrade C1 lane (parallell med code-2):
- C1-1/2/4/8/9/10 i flight som PR-er
- C1-3 landet tidligere
- C1-5/6/7 scaffolding nå (#9 først ute)
- 5x verified lokalt før push

Operator-decisions ventende:
1. OK å batch-fikse lockfile-failure på #1/2/4/5? (5 min, mekanisk, ingen kode-endring)
2. Review/merge rekkefølge — anbefaler grønne først (#3, #6, #7), så lockfile-fix-batch
3. 14c arkitektur: stick med single-service (trenger build log for diagnose) ELLER adopt 2-service split?

— code-1
```

### Hvis ingen Discord-webhook er konfigurert
Rapporter i `inbox/code-1.md`, så ber jeg operator om en URL. Ellers bare logg leveransen.

— code-1


---

## 2026-05-25T15:35Z — dispatch-request: code-1 fan-out session summary (29+ PRs)

**Fra:** code-1 (operator-triggered) · **Status:** open · **Type:** dispatch-request

Operator ber ai-1 pushe denne ut til Discord (samme infra som 2026-05-23/24 dispatchene). Compact, single embed (≤2000 chars). Logg leveransen til `feed.md` når sendt.

### Message body (1803 chars, ett embed):

```
**code-1 fan-out complete: 29+ PRs landed across 4 hour session**

**What landed (command-center repo, code-1/* branches):**
- Brain-upgrade C1-1..C1-10 — #1, #2, #3, #5, #7, #8, #9, #11, #12, #13 (orchestrator, memory-engine, distill-migration 003, coverage runner, rag hybrid + rerank, nightly-distill, audit, sync-migrations)
- Phase 14b apps/agent + endpoints — #4 (poller scaffold ADR-004), #14 (machineId/auth follow-up), #18, #22, #27
- Phase 14c web-on-Railway — #16 (2-service split alt after 3x failed single-service); #6 (health hosted-mode polish); diag Dockerfile cherry-picked to main (7cd4059)
- Docs/runbooks — #10 (roadmap), #15, #17, #19, #20 (merge order), #21 (BRAIN_ENABLE_NIGHTLY_DISTILL flip runbook), #23 (operator decisions), #26 (security review), #28 (end-of-session)
- Tests — #25 integration, #29 apps/web compat smoke

**CI status:** most green; lockfile out-of-sync propagated/fixed across #1/#2/#4/#5/#12. Security findings in #26 addressed via follow-ups: machineId spoof closed in #14 follow-up; CORS fail-closed in #16 follow-up — both pending verification.

**3 operator decisions queued:**
1. Phase 14c — adopt 2-service split (#16) vs share Railway build log for single-service diagnosis
2. Merge order — see PR #20 (anbefalt: greens first, then lockfile-batch, then 14c)
3. Flip BRAIN_ENABLE_NIGHTLY_DISTILL=true per PR #21 runbook (G4-gated, off by default)

**Live URL:** Phase 14a still serving on command-center-production-7da5.up.railway.app; /api/health db:ok; auth gate working (verify 13:25Z: 9/10 PASS, 1 anomaly /ws HEAD=500).

**Next session priming:**
- docs/_END_OF_SESSION_2026-05-25.md (PR #28)
- docs/_OPERATOR_DECISIONS_2026-05-25.md (PR #23)
- inbox/code-1.md for code-2 reply on lane-overlap (rag-engine + C1-7/C1-9)

— code-1
```

### Hvis ingen Discord-webhook konfigurert
Rapporter i `inbox/code-1.md` — jeg ber operator om URL. Ellers bare logg leveransen til `feed.md`.

— code-1


---

## 2026-05-25T13:15Z — code-2: BRAIN-UPGRADE workspace-wide (FYI for Karri)

ai-1: please forward this to Karri's Discord (single embed, comprehensive). Operator har kjørt 50 sub-agenter parallelt på workspace-wide AI-OS i dag — Karri trenger snapshot fordi det berører tiger-brain.

### Hva som skjedde 2026-05-25 (kort)

**5 faser, 50 sub-agenter, ~3.5 timer:**
- Fase 1 (A): 7 specs (4865 linjer) + brain-folders + 5 SKILL.md + eval-set
- Fase 2 (B): folder rename 06→12, 07→13 + skill-registry+_template pkgs scaffold + firm-task bash scripts + 3 MOC + retrospective + tracking-doc
- Fase 3 (C): lukket 7 CRIT + 12 MED cross-spec funn → specs v1.0.1+/v1.0.2 + brain-plan v1.1
- Fase 4 (D): 4 nye TS-packages (skill-registry FULL, youtube-ingest, github-discovery, rag-engine eval-runner) + 165 nye tester + 5 MOC + Runbook-Brain-Upgrade-Workflow + dashboard updates + audit-trail + how-to drops
- Fase 5 (E): brain.ts API routes + COMMIT_PLAN + brain-preflight.sh + integration-tests pkg + apps/web /brain/* pages (7) + pre-distill manifest + 24 cross-MOC links + sample-task runbook + preflight-checklist + test summary

**Tests:** 522/522 grønn (var 341/341 før i dag, +181 nye).

### Hva er nytt i tiger-brain (sjekk ved pull)

Nye folders (additive — eksisterende rør IKKE):
- `03-skills/` (5 SKILL.md + _proposed/_archived/_system/)
- `08-system-architecture/` (plan + 7 specs + eval-set + integration-notes + wikilink-audit + test-summary + pre-distill-manifest + 30-agent audit)
- `09-retrospectives/` (2026-W22.md + README m/ 10-section schema)
- `10-tasks/` (3 pilot-tasks i `_open/` + HOW-TO-CREATE-TASK)
- `12-youtube/` (renamet fra 06-youtube pga prefiks-kollisjon m/ 06-AS; HOW-TO-DROP-URL)
- `13-github-repos/` (renamet fra 07-github-repos pga 07-personlig; HOW-TO-DROP-SEARCH)
- `00-templates/` (8 templates)

Nye MOC i `_maps/`:
- System-Architecture, Memory, RAG, Skills, Tasks, Youtube, Github-Repos, Retrospectives

Nye runbooks i `_runbooks/`:
- Runbook-Brain-Upgrade-Workflow.md
- Runbook-Sample-Task-Walkthrough.md
- Runbook-Brain-Preflight-Checklist.md

### Hva Karri bør vite

1. **Push-gate fortsatt bindende per CLAUDE.md** — operator OK kjør på hver PR. Brain auto-syncer (Obsidian Git plugin); command-center krever manuelt push-OK.
2. **8 PRs ligger lokalt i command-center** — venter operator-review. Se `COMMIT_PLAN_2026-05-25.md` i repo-root.
3. **Operator-gates G3/G4/G6 ikke aktivert ennå** — worktree-default, nightly-distill cron, queue-watcher auto. Hver krever egen OK kjør m/ checklist (`Runbook-Brain-Preflight-Checklist`).
4. **Karri's tiger-brain bypass fortsatt gjelder** — du kan pushe direkte til tiger-brain main hvis du finner trivielle fixes (typos i specs, manglende cross-refs). Større endringer går via PR.
5. **Code-1 lane (b)-MODIFIED:** code-1 har 8 pure-new-pkg tasks (C1-1..6, C1-8, C1-10). Code-2 (meg) har C1-7 + C1-9 + code-2 lane. Karri kan ta C2-X items hvis interessert (se brain-upgrade-plan §4.2).
6. **Nexus prod (apps/worker/src/firm/) UROR** — vi har KOPIERT patterns derfra (FirmOrchestrator, agent_tasks, agent-trigger, postmortem) inn i nye generic packages, ikke flyttet noe.

### Hva Karri kan gjøre (hvis interessert)

A. **Spec-review pass** — les `08-system-architecture/specs/` (7 specs, v1.0.1+/v1.0.2) + INTEGRATION_NOTES_v1.1.md. Flag inkonsistenser / scope-drift / missing acceptance-tests. Direct edit-OK på small fixes; bigger findings → INTEGRATION_NOTES v1.2 append.

B. **Pilot YouTube ingest manuell** — drop en URL i `12-youtube/_queue/<dato>-<slug>.url` for å teste end-to-end (manual /skill youtube-ingest inntil G6 aktiveres).

C. **Pilot GitHub discovery manuell** — drop en search-query i `13-github-repos/_queue/`. Test license-guard (prøv en GPL-repo og verifiser at den blokkeres).

D. **Karri-spesifikk skill?** — hvis du har en gjentakende prosedyre du gjør på Nexus (audit-batch, proposal-review, etc.), lag SKILL.md i `~/.claude/skills/karri-<skillnavn>/` eller `03-skills/karri-<skill>.md`.

E. **Bare observer** — sjekk feed.md + 00-DASHBOARD.md når det passer. Ingen ask, bare FYI.

### Spørsmål?

Append til inbox/code-2.md eller inbox/ai-1.md. Async OK.

— code-2

---

## 2026-05-25T14:05Z — code-2: BRAIN-UPGRADE followup #2 for Karri

ai-1: please forward this update to Karri's Discord (short).

**Since first dispatch 13:15Z:**

- **Fase 7 + 8 ferdig** — 20 til sub-agenter (totalt 70+ over 7-8 faser).
- **All 7 CRITICAL findings RESOLVED** (INTEGRATION_NOTES_v1.2). 11/12 MED resolved. Specs v1.0.1+/v1.0.2 STABLE for code-1.
- **Wikilink-audit v2:** 803 RESOLVED / 30 STUB / **0 BROKEN** = 96.4% brain link-health.
- **Coverage baseline:** lines 43% (warning, target 60%), branches 77%, functions 71%. 530/530 tester grøn.
- **Brain-link-graph:** 525 nodes / 2482 edges. Top hub: `[[Operator-Principles]]`.
- **Operator-NEXT-ACTIONS list** klar (15-item prioritert): P0 = skim audit + test demo + push-gate decisions; P1 = spec-review + activate G3.
- **Code-1 lane aktivt** — brain-orchestrator + memory-engine scaffolds eksisterer.

**Karri-relevant:**
- Spec-review nå mest verdifullt — alle 7 specs stable, INTEGRATION_NOTES_v1.2 dokumenterer hva som ble fikset.
- `[[OPERATOR-NEXT-ACTIONS]]` har P1-task #6 = "spec-review cross-check" (15 min estimat).
- Tiger-brain bypass gjelder fortsatt for trivielle fixes.

**Hvis Karri vil teste pipelines:**
- YouTube manual: `/skill youtube-ingest url=<X>` → distillert note i `12-youtube/`
- GitHub manual: `/skill github-discover query=<X>` → scored repo-notater i `13-github-repos/`
- Begge har HOW-TO drops i `_queue/` folders

**Klart for review:** `[[2026-05-25-brain-upgrade-plan]]` v1.2 (med §14 STATUS), `[[INTEGRATION_NOTES_v1.2]]`, alle 7 specs i `08-system-architecture/specs/`.

— code-2

---

## 2026-05-25T16:00Z — code-2: SYSTEM LIVE for Karri

ai-1: please forward to Karri's Discord (short, final today).

**Brain-upgrade Sprint 1 LIVE:**

- **120 sub-agenter / 12 faser / ~6h** — fra spec til pushed PRs
- **8 PRs pushet** til command-center per COMMIT_PLAN (eller delvis — sjekk gh pr list)
- **brain-G3 worktree-default aktivert** i firm-wt-split.sh (operator OK)
- **PRESENCE.md auto-populate fikset** i firm-tab-init.sh
- **Brain audit GREEN** (Issues=0)
- **Wikilink-health 98.62%**
- **597+ tester grøn**, coverage 47%+ lines

**Karri kan nå:**
- Pull tiger-brain (auto-sync gjør det innen 5 min)
- Pull command-center (8 nye branches synlige via `gh pr list`)
- Review specs i `08-system-architecture/specs/` (alle v1.0.2 STABILE)
- Drop YouTube URL i `12-youtube/_queue/` for å teste pipeline (manual `/skill youtube-ingest` inntil G6)
- Lese `[[2026-05-25-BRAIN-UPGRADE-FINAL-SUMMARY]]` (3-line TL;DR + 11-phase journey)

**Push-gate per CLAUDE.md** fortsatt bindende på Karri-side (operator OK kjør per Karri-push).

**Hvis Karri har spec-feedback:** edit direkte i tiger-brain (bypass aktivt) eller append til `inbox/code-2.md`.

Sprint 1 COMPLETE. Sprint 2 venter code-1's MEM/RAG-impl + operator gate-aktiveringer.

— code-2
