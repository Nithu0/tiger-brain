---
title: On-prem AI-infrastruktur — strategi og teknisk plan
date: 2026-05-24
status: v1.0 draft
author: code-2 (integrator) + 10 spesialist-agenter
tags: [business, strategy, onprem-ai, refi, hardware, security]
---

# On-prem AI-infrastruktur — strategi og teknisk plan

Generert 2026-05-24 av 10 parallelle spesialist-agenter (CTO, Security, Hardware, Facility, Product, Refi, Business, Sales, Compliance, Execution) + integrasjon. Seksjon 3-11 er hver agents leveranse, lett redigert. Seksjon 1, 2, 12, 13 er integrator-syntese på tvers.

Alle tall er estimater og må verifiseres mot leverandør/jurist/marked før beslutning.

---

## 1. Executive Summary

Du har en sjelden kombinasjon: teknisk kapasitet bevist via command-center, varm pilotkunde i refi-aktøren, Norge mangler en troverdig on-prem AI-leverandør for SMB, og regulatorisk landskap (GDPR, EU AI Act, bransje-konsesjoner) gir varig moat mot Microsoft Copilot og OpenAI.

Anbefalingen fra alle 10 agenter konvergerer på fem punkter:

**(a) Start på Tier 1 hardware (~54k NOK).** Lei cloud-GPU uke 1-3 mens hardware leveres. 2x brukt RTX 3090 (48GB samlet VRAM) + Ryzen 9 + 128GB RAM kjører Qwen 2.5 72B Q4 stabilt. Hele soft-stacken (vLLM + Qdrant + Caddy + ZFS) kan valideres uten å brenne kapital.

**(b) Bygg generell sensitiv-dokument-AI, ikke "refi-AI".** Bruk refi-aktøren som **første pilot**, ikke som produkt-definisjonen. Refi alene = regulatorisk konsentrasjons-risiko + smal exit + "refi-AI"-stempel som låser deg ut av advokat/HMS/eiendom-segmenter. Dette er den eneste anbefalingen som er enstemmig på tvers av alle 10 agenter.

**(c) Pilot-fastpris 75-150k NOK, 6-8 uker, ekte kontrakt — ikke vennetjeneste.** Refi-, Sales-, Business- og Execution-agent uavhengig enige.

**(d) Auth + audit-trail + PII-egress-filter fra dag 1.** Ikke "senere" — pilot-blokkere.

**(e) 2 timer jurist innen uke 2.** Refi-bruks utløser to ikke-forhandlingsbare spørsmål før første kundedata: (1) blir du medformidler under låneformidlingsloven? (2) refi = high-risk under EU AI Act?

**Realistisk ARR år 1: ~750k NOK** (Business: pessimistisk 350k, realistisk 750k, optimistisk 1.4M). Dekker solo-lønn + Karri deltid med tynn buffer.

**Bør du bygge dette?** Ja, betinget av fire ting i seksjon 13. Kjør disiplinert: én bruks-case, én kunde, én tier, før eskalering. Tier 4 (~7.5M NOK hardware) er **ikke** "neste steg" — separat finansierings-beslutning som krever 2-3M ARR.

---

## 2. Min anbefalte retning

Bygg et **"on-prem dokument-AI"-produkt** (generell kjerne) med **refi-modul som første go-to-market**. Plattform-formen er strategisk; refi er taktisk pilot-vehicle.

**Produkt-definisjon (1 setning):** "Norsk on-prem AI-server som leser, klassifiserer, sammenstiller og automatiserer dokument-tunge prosesser i regulerte SMB-er — uten at data forlater bedriftens nettverk."

**Første pakke å selge:** Refi-Co-Pilot (Pakke 1 i Product-agent). Fastpris pilot 75-150k, 6 uker, konvertering til 25k/mnd leasing eller 15k/mnd drift.

**Andre/tredje pakke:** Kontorhjernen (generell SMB), Suverenitets-boksen (regulerte). Begge gjenbruker 80 % av Tier 1-stacken.

**Posisjonering:** "Norsk-eid, on-prem, GDPR-trygg AI for sensitive dokumenter." Ikke konkurranse mot OpenAI/Anthropic på modell-kapasitet — konkurranse på data-suverenitet + bransje-spesifikk arbeidsflyt + lokal support.

**12-måneders bilde:**

- **Q2 2026 (mai-aug):** Tier 1 oppe, pilot signert med refi-aktør, pilot levert med målt verdi.
- **Q3 2026:** Pilot konvertert til løpende. 2 nye piloter. Tier 2 hardware når 2. pilot signert.
- **Q4 2026:** 3 løpende kunder. Karri på 30 %. Første referansecase publisert med kundens OK.
- **Q1 2027:** 5+ kunder, ARR ~1M. Vurder første heltidsansatt.

**Hva du IKKE bygger i år 1:** Multi-tenant SaaS-portal. Egen finetune-pipeline. Mobil-app. White-label. Markedsplass. Disse er distraksjoner som har drept liknende prosjekter.

---

## 3. Teknisk arkitektur (CTO-agent)

### 3.1 LLM runtime
**Vinner: vLLM** for produksjons-inferens. Ollama som dev-/eksperiment-runtime på siden.

vLLM gir 5-20x throughput over llama.cpp på samme GPU takket være PagedAttention + continuous batching, har OpenAI-kompatibel API ut av boksen, støtter AWQ/GPTQ/FP8, og håndterer multi-tenant via request-batching uten egen kode. TGI er likeverdig teknisk men har mistet momentum. SGLang er raskere på structured output / agent-loops — vurder som tillegg om 6 mnd. llama.cpp er nydelig for CPU-fallback, men skalerer ikke flertenant. Ollama wrapper llama.cpp og er suverent for "operator prøver en modell på laptop", men ikke for produkt.

### 3.2 Modeller
- **Primær generativ: Qwen 2.5 72B Instruct (AWQ-Q4)** — best åpen modell på flerspråklig/norsk slutten 2025 (caveat: må re-evalueres på norske refi-dokumenter). ~40 GB VRAM, kjører på 2x RTX 3090 / 1x A6000 / 1x RTX 6000 Ada.
- **Sekundær: Llama 3.3 70B Instruct (AWQ-Q4)** — sterk reasoning, dårligere norsk enn Qwen, bedre tool-calling-stabilitet.
- **Norsk-spesialisert: NorMistral-11B / NorwAI-Mistral-7B** for ren norsk klassifisering, NER på personnummer/org.nr, oppsummering av kortere dokumenter. Kjører i FP16 på 24 GB.
- **Liten arbeidshest: Qwen 2.5 7B / 14B** for klassifisering, ruting, struktur-ekstraksjon — kalles 10-100x oftere enn 72B.
- **Embeddings: bge-m3** — multilingual, 8k context, dense + sparse + colbert i én modell.
- **Reranker: bge-reranker-v2-m3** — billig kvalitetsløft på toppen av hybrid retrieval.
- **Kvantisering: AWQ-Q4 standard.** Q8/FP8 kun hvis VRAM tillater og evaluering viser tap på Q4.

Mistral Large er research-lisens → utelukket fra produkt. Nemotron-70B er engelsk-tung.

### 3.3 Vektorbase
**Vinner: Qdrant.** Rust, single-binary deploy, native hybrid (BM25 + dense + sparse), HNSW + scalar/binary quantization, payload-filter er førsteklasses (kritisk for "kun dokumenter tilhørende sak X / kunde Y" i refi-flyt). Skalerer fra én node til cluster uten arkitekturendring.

pgvector kun for små collections (<100k vektorer) og metadata-joins. Weaviate: GraphQL-friksjon. Milvus: overkill før 10M+ vektorer.

Hybrid: **BM25 + bge-m3 + bge-reranker (rerank top-50 til top-10).** Qdrant gjør de to første natively.

### 3.4 OS + virtualisering
**Én GPU-node nå: Ubuntu 24.04 LTS bare-metal + Docker + NVIDIA Container Toolkit.** Ingen hypervisor-overhead på GPU passthrough. ZFS-on-root via Ubuntu installer.

**Multi-node senere: Proxmox VE** på CPU/storage-noder. GPU-noder forblir bare-metal — GPU passthrough i Proxmox er gjørmete vedlikehold.

### 3.5 Container/orchestration per tier
- **Tier 1 (1 GPU-node):** docker-compose. Én fil i git, ingen scheduler-magi.
- **Tier 2 (1 GPU + 1 storage/CPU-node):** docker-compose + systemd per node.
- **Tier 3 (2-3 noder, første teammate):** K3s. Single-binary K8s, fungerer med GPU operator, gir ingress/secrets/HA-kontrollplan.
- **Tier 4 (multi-tenant produkt):** K3s i HA-modus eller RKE2 om compliance krever CIS-baseline.

### 3.6 Database
**Postgres 16 + pgvector for metadata/struktur. Qdrant separat for vektorer.**

Schemas: `auth`, `documents`, `cases`, `audit` (immutable, partitionert per måned), `agents`.

Migration: **Atlas** for hastighet (deklarativ schema-diff). Backup: **pgBackRest** med full + differential + WAL.

### 3.7 Storage-arkitektur
- **Hot (modeller, aktiv DB, vektorindeks):** NVMe Gen4, ZFS mirror, recordsize 128k for modeller / 16k for Postgres, compression=lz4.
- **Warm (rå dokumenter, logs):** SATA SSD, ZFS RAIDZ2 (3+ disker), compression=zstd-3.
- **Cold (backup, arkiv):** HDD, ZFS RAIDZ2/mirror-stripe, compression=zstd-9, dedup AV.

ZFS gir snapshots, send/receive, ARC, scrub, kompresjon, kryptering — alt i én pakke. btrfs RAID5/6 fortsatt utrygt.

### 3.8 Backup (3-2-1)
- **Lokal kopi 1:** ZFS snapshots hver 15. min hot, hver time warm. `sanoid` for retention (24h hver time, 30d daglig, 12m månedlig).
- **Lokal kopi 2:** `zfs send | zfs receive` til cold-pool nattlig via `syncoid`.
- **Off-site:** **restic → Hetzner Storage Box (EU/Falkenstein)** primær, **Backblaze B2** sekundær. restic gir client-side encryption.
- **RPO:** 15 min (hot), 1 t (warm), 24 t (off-site).
- **RTO:** 1 t enkelt-tjeneste, 8 t full node, 24 t total-katastrofe.
- **Restore-test:** automatisert månedlig restore + checksum-verify. Backup uten testet restore = ingen backup.

### 3.9 Overvåkning
Prometheus + Grafana + Loki + Alertmanager + node_exporter + cAdvisor + nvidia-gpu-exporter + postgres_exporter + qdrant `/metrics` + blackbox_exporter.

Alarmer til operator via ntfy/Discord (ikke auto-action per global policy):
- GPU temp >85°C, VRAM >95 % i >5 min, ECC errors
- Disk SMART pre-fail, ZFS pool DEGRADED, fri kapasitet <15 %
- Postgres replikasjon-lag, lange queries >30s
- vLLM p99 latency, request queue depth, OOM-restart
- Backup-job missed eller restore-test failed
- Cert expiry <14d

### 3.10 Reverse-proxy
**Vinner: Caddy.** Auto-TLS via DNS-01 for interne domener, deklarativ Caddyfile, HTTP/3 default. TLS: DNS-01 challenge mot Let's Encrypt for `*.internt-domene.no`. Intern step-ca som backup-CA for mTLS mellom tjenester.

### 3.11 Agent-orkestrering
**Utvid command-center med LangGraph-runtime-pakke; ikke adopter Letta/CrewAI som rammeverk.**

Command-center har allerede router/executor/agents. LangGraph gir graph-state, checkpointing, human-in-the-loop, persistens — alt verdt for refi-flyt. Pakk LangGraph som en executor-engine bak eksisterende router-API.

### 3.12 Build-rekkefølge
1. **Uke 1:** Ubuntu 24.04 + ZFS root, NVIDIA-driver + CUDA + Container Toolkit, Docker, Caddy, Tailscale. Smoke-test: vLLM + Qwen 2.5 7B.
2. **Uke 1:** Postgres + pgvector + Qdrant i compose, pgBackRest mot lokal pool.
3. **Uke 2:** vLLM med Qwen 2.5 72B AWQ, bge-m3 embedding-server, bge-reranker. Last-test.
4. **Uke 2:** Prometheus + Grafana + Loki + alle exporters, ntfy/Discord-alarmer.
5. **Uke 3:** restic mot Hetzner Storage Box, sanoid/syncoid, første restore-test.
6. **Uke 3:** Caddy + Let's Encrypt DNS-01, intern-domene oppe, step-ca mTLS.
7. **Uke 4:** Command-center integrasjon — LangGraph-engine + Qdrant-retriever-tool, første end-to-end refi-dokument-flyt.
8. **Mnd 2:** Andre node (storage/CPU), Proxmox, flytt backup-target og Loki.
9. **Mnd 2:** Audit-log partitionering, immutable WORM-snapshot på cold-pool.
10. **Mnd 3:** K3s pilot på node 2-3, første Helm-chart (Qdrant), multi-tenant namespace-isolasjon.

### 3.13 Logisk topologi
Fem VLAN-er, alle terminert i firewall:

- **mgmt (10.10.0.0/24):** IPMI, switch-mgmt, Proxmox-UI, ssh-bastion.
- **ai-compute (10.10.10.0/24):** GPU-noder, vLLM, embedding, Qdrant, Postgres. Ingen direkte internett-ut.
- **services (10.10.20.0/24):** Caddy, command-center, agent-orchestrator, monitoring.
- **klient (10.10.30.0/24):** operator + teammate-laptops.
- **gjest + IoT (10.10.40.0/24, 10.10.50.0/24):** fullstendig isolert.

Default-deny mellom alle nett, eksplisitte allow-regler dokumentert i git.

---

## 4. Sikkerhetsarkitektur (Security-agent)

Trusselmodell: opportunistisk kriminell + målrettet konkurrent + revisjonskrav fra kunde. IKKE statlig aktør.

### 4.1 Tilgangsmodell
WireGuard-konsentrator på OPNsense (UDP 51820). Bak WG: intern jump-host (kun SSH + auditd). Alle AI-tjenester nås via jump-host, ALDRI direkte fra WG-subnet til compute. Reduserer ekstern angrepsflate fra "alt eksponert" til "én UDP-port som ser død ut + én SSH bak den".

### 4.2 Identitet og 2FA
- SSH: ed25519-nøkler, `PasswordAuthentication no`, `PermitRootLogin no`.
- **YubiKey 5 (2 stk per person — primær + backup i safe)** for sudo (`pam_u2f`), WireGuard-konfig, jump-host SSH.
- PAM: `pam_u2f` for sudo + login, `pam_faillock` (5 forsøk, 15 min lockout).
- Recovery-koder: papir, bankboks + forseglet konvolutt hjemme. ALDRI digitalt utenom Bitwarden.
- Teammate: egen Linux-bruker, egen WG-peer, egen YubiKey. Ingen delte kontoer.

### 4.3 RBAC
Linux-grupper: `ops` (operator, full sudo), `dev` (teammates, sudo til app-tjenester), `client-ro` (read-only på eget tenant-data), `svc-*` (per service-account, ingen shell).

App-nivå: hver klient = egen Postgres-schema + egen MinIO-bucket + egen modell-cache-prefix. Row-level security i Postgres som backup. Operator-tilgang logges som "operator-impersonation-event".

### 4.4 Disk-kryptering
LUKS2 på ALT persistent. Argon2id KDF. **Clevis + Tang for compute-noder** (unattended reboot uten passphrase). Tang kjører på OPNsense-boksen. Passphrase-fallback i bankboks.

NVMe SED alene: **ikke bruk** (kjente bypass). LUKS over SED OK men lite ekstra. Backup-disker: LUKS2 med egen passphrase (IKKE samme som system).

### 4.5 Brannmur + segmentering
OPNsense på dedikert boks. VLAN-design som i 3.13. Default-deny mellom alle. Tillatte flows:
1. `client-dmz` → `ai-compute:8000/tcp` (kun inference)
2. `ai-compute` → `storage:5432/tcp` + `:9000/tcp`
3. `jump-host` → alle VLAN på SSH:22 + mgmt
4. `mgmt` → internett kun for apt/dnf-mirror (whitelist)
5. `ai-compute` → internett DENY by default; whitelist for modell-nedlasting (HuggingFace) som åpnes manuelt + lukkes etter
6. `iot` → kun NTP + vendor-IP
7. `guest` → kun internett, deny RFC1918
8. All inter-VLAN-trafikk logges

### 4.6 Audit-logging
Logges: SSH-auth, sudo (alle kommandoer via `pam_tty_audit`), systemd-unit start/stop, container-create/destroy, hver LLM-prompt + response-metadata, dokument-tilgang, eksport.

Sentral: separat syslog-host (egen disk, kun rsyslog/journald-remote). Append-only via `chattr +a` + ZFS-snapshots. Daglig hash-chain rotert til S3 Glacier med Object Lock (WORM).

Retention: 90 dager hot, 2 år cold (operator-valg — flagget Compliance for GDPR vs revisjonskrav).

### 4.7 Backup + DR (sikkerhets-krav)
- Ingen backup forlater huset ukryptert. restic/borg med separat repo-key.
- 3-2-1: lokal NAS + ekstern disk (rotert månedlig til bankboks) + off-site (Hetzner).
- Restore-test kvartalsvis, dokumentert.
- Recovery krever 2FA (YubiKey for å hente repo-key fra Bitwarden).
- Repo-keys: 2-av-3 Shamir mellom operator-YubiKey, bankboks, teammate-YubiKey.

### 4.8 Secret management
- **Nå (solo):** SOPS + age, key i YubiKey PIV-slot, secrets kryptert i git-repo.
- **Ved 2-3 teammates:** bytt til Vault (self-hosted, OSS), auto-unseal via Tang.

### 4.9 Supply chain
- Pip: `pip-tools` med hash-pinning, egen devpi-mirror.
- Npm: `npm ci` med lockfile, `npm audit signatures`.
- Docker: egen registry (Harbor), kun signerte images (cosign verify), pinnet til digest.
- Modell-weights: SHA256 verifisert mot HuggingFace + sekundær kilde. Pull-script som verifiserer + lagrer lokalt.
- Dependabot/Renovate, auto-merge KUN for patch på dev-dependencies.

### 4.10 Fysisk sikkerhet (ærlig)
Hjemme: låst kontorrom, serverskap med lås, kamera utenfor rommet, alarm med dør- og bevegelsessensor.

**Ærlig:** stopper opportunistisk innbrudd, ikke målrettet aktør. Evil-maid mens du sover er reell — derfor TPM+Tang+passphrase-lag. Når pilot starter: flytt til colo eller låst kontor med adgangskontroll.

### 4.11 Hva er FORTSATT svakt
- **Sosial engineering:** ingen teknisk fiks. YubiKey motstår credential-phish, ikke session-hijack post-auth.
- **Evil-maid mens du sover:** TPM-PCR hjelper, sofistikert aktør med tid vinner.
- **Din egen laptop kompromittert:** hele modellen faller. Laptop er kun SSH-klient + YubiKey, ingen sensitive filer lokalt.
- **GPU side-channel multi-tenant:** ikke flere kunders inferens på samme GPU samtidig før MIG-partisjonering er verifisert.
- **Ekstern API (Anthropic/OpenAI):** **skal ikke brukes for klient-data.** Kun for operator-interne dev-spørsmål.
- **LLM-output-lekkasje:** ingen cross-tenant fine-tune. Output-filter for PII-mønstre.
- **Jailbreaks på eldre modeller:** patch-kadens, ikke pin til 12 mnd gammel checkpoint.
- **Brann/flom hjemme:** off-site backup er svaret; oppetid ryker i dager.

### 4.12 Minimum baseline før første kunde-pilot
1. WireGuard + jump-host + OPNsense med VLAN-segmentering, pen-testet (egen nmap fra guest-VLAN — verifiser default-deny).
2. LUKS2 + Clevis/Tang, recovery-passphrase i bankboks, restore-test gjennomført.
3. YubiKey 2FA på SSH + sudo + WG-config, recovery-koder eksternt.
4. Sentral audit-log med WORM-rotering + 30-dagers retention minimum, hash-chain verifisert.
5. Tenant-isolering i app (Postgres RLS + egne MinIO-buckets) + dokumentert at operator-impersonation logges separat.

Punkt 1-5 er ikke-forhandlingsbart før første kundedata.

---

## 5. Konkret handleliste (Hardware-agent) — 4 tiers

Alle priser estimater per mai 2026, eks. mva, må verifiseres mot leverandør.

### 5.1 Tier 1 — MVP / "vise noe i morgen"

Single workstation under skrivebordet. Llama 3.1 70B Q4_K_M (~40GB) på 2x 3090 tensor-parallel.

| Komponent | Antall | Spec | Pris NOK |
|---|---|---|---|
| Chassis | 1 | Fractal Define 7 XL | 2 500 |
| CPU | 1 | AMD Ryzen 9 7950X (16C/32T) | 6 500 |
| Hovedkort | 1 | ASUS ProArt X670E-Creator (2x PCIe 5.0 x8, 10G NIC) | 6 000 |
| GPU | 2 | Brukt RTX 3090 24GB (eBay-EU/Finn) | 2x 8 000 = 16 000 |
| RAM | 4 | 32GB DDR5-5600 non-ECC (128GB total) | 6 000 |
| NVMe | 2 | Samsung 990 Pro 2TB PCIe 4.0 (RAID0) | 3 600 |
| SSD | 1 | Samsung 870 EVO 4TB SATA | 3 200 |
| HDD | 1 | Seagate IronWolf 8TB | 2 200 |
| Switch | 1 | Mikrotik CRS305-1G-4S+IN (4x SFP+) | 2 200 |
| Router | — | Eksisterende + VLAN | 0 |
| UPS | 1 | APC Back-UPS Pro 1500VA | 2 800 |
| Kjøling | — | 6x Noctua NF-A14 | 1 500 |
| PDU | 1 | APC P8 overspenningsstrip | 600 |
| Kabler | — | 2x CAT6a, 2x DAC SFP+ | 800 |
| **Total** | | | **~54 000** |

- **Strøm:** idle 180-220W / last 750-850W / topp 950W
- **Støy:** 45-50 dB ved 1m
- **Kontorrom:** Ja, plassér under skrivebord

### 5.2 Tier 2 — Sterk prototype / kunde-demo

Single 4U server. Qwen 72B Q5/Q6 + 2-3 samtidige brukere.

| Komponent | Antall | Spec | Pris NOK |
|---|---|---|---|
| Chassis | 1 | Supermicro CSE-743TQ-1200B-SQ (super quiet, 1200W redundant) | 12 000 |
| CPU | 1 | AMD Threadripper PRO 7965WX (24C, 128 PCIe lanes) | 28 000 |
| Hovedkort | 1 | ASUS Pro WS WRX90E-SAGE SE | 14 000 |
| GPU | 1 | **RTX 6000 Ada 48GB** (blower) | 75 000 |
| RAM | 8 | 32GB DDR5-5600 ECC RDIMM (256GB) | 24 000 |
| NVMe | 2 | Samsung 9100 Pro 4TB PCIe 5.0 (RAID1) | 9 000 |
| SSD | 4 | Samsung 870 EVO 4TB (RAID10) | 12 800 |
| NAS | 1 | Synology DS1522+ + 5x 8TB IronWolf SHR-2 | 19 000 |
| Switch | 1 | MikroTik CRS326-24G-2S+RM | 4 500 |
| Router/FW | 1 | Protectli VP2420 + OPNsense | 7 500 |
| UPS | 1 | Eaton 5PX 1500VA RT2U | 8 500 |
| Rack | 1 | StarTech 18U lukket, 1000mm | 6 500 |
| Kjøling | — | Rack-fans + portabel AC | 3 000 |
| PDU | 1 | APC AP7921B switched | 5 500 |
| NIC | 1 | Intel X710-DA2 (2x 10G SFP+) | 3 500 |
| Kabler | — | 6x CAT6a, 3x DAC | 1 800 |
| **Total** | | | **~258 000** |

- **Strøm:** idle 280W / last 950-1100W / topp 1250W
- **Støy:** 52-55 dB
- **Kontorrom:** Med tiltak (eget hjørne, dør lukket)

Trade-off: én GPU = SPOF. 2x L40S 48GB (~280k) dobler strøm/varme/støy uten å åpne 70B fp16 (krever 160GB+ VRAM).

### 5.3 Tier 3 — Seriøs kontor-lab / første kunde-pilot

2-node mini-cluster. 70B fp16 mulig (2x H100 = 160GB). 10-20 samtidige brukere.

| Komponent | Antall | Spec | Pris NOK |
|---|---|---|---|
| GPU-node chassis | 1 | Supermicro AS-4125GS-TNRT (4U, EPYC) | 55 000 |
| GPU-node CPU | 2 | AMD EPYC 9354 (32C, Genoa) | 76 000 |
| GPU | 4 | 2x H100 80GB PCIe + 2x L40S 48GB | **780 000** |
| RAM (GPU-node) | 12 | 64GB DDR5-4800 ECC RDIMM (768GB) | 78 000 |
| NVMe hot | 4 | Kioxia CM7-V 3.84TB U.3 PCIe 5.0 (RAID10) | 72 000 |
| Tjeneste-node | 1 | Supermicro 1U, EPYC 9124, 128GB, 2x 2TB NVMe | 65 000 |
| NAS | 1 | TrueNAS Mini R + 12x 16TB Exos + 2x NVMe SLOG | 95 000 |
| Switch data | 2 | MikroTik CRS510-8XS-2XQ (25G/100G) | 28 000 |
| Switch mgmt | 1 | MikroTik CRS328-24P-4S+RM | 6 500 |
| Router/FW | 1 | Netgate 6100 eller bygd OPNsense | 18 000 |
| UPS | 2 | Eaton 9PX 6000VA RT3U + EBM | 76 000 |
| Rack | 1 | APC NetShelter SX 42U + akustisk dempning | 22 000 |
| Kjøling | 1 | Split AC 3.5 kW dedikert rom | 25 000 |
| PDU | 2 | APC AP8941 switched metered | 24 000 |
| NIC | 2 | Mellanox ConnectX-6 Dx 2x 25G | 17 000 |
| Kabler, KVM, sikkerhet | — | DAC, fiber, kamera, rack-lås | 26 000 |
| **Total** | | | **~1 463 500** |

- **Strøm:** idle 800W / last 3 800-4 500W / topp 5 200W
- **Støy:** 65-72 dB
- **Kontorrom:** **Nei** — krever eget rom med AC + 2x 16A kurser

Reduksjon: drop L40S = ~1.28M. Verifiser H100-pris brutalt; brukt-marked svinger.

### 5.4 Tier 4 — Mini-datasenter (5+ kunder)

| Komponent | Antall | Notat | Pris NOK |
|---|---|---|---|
| GPU-noder | 3 | Supermicro 8U HGX-klasse | 540 000 |
| GPU | 12 | H100 80GB SXM5 (4 per node) | **3 840 000** |
| CPU | 6 | EPYC 9554 64C (2 per node) | 390 000 |
| RAM | 36 | 64GB DDR5 ECC × 12 × 3 = 2.3 TB | 234 000 |
| NVMe per node | 12 | Kioxia CM7 7.68TB U.3 | 384 000 |
| Storage-server | 1 | TrueNAS R50, 24x 30TB SAS + 4x NVMe | 380 000 |
| Tjeneste-noder | 2 | 1U EPYC 9254 HA | 190 000 |
| Switch data | 2 | NVIDIA Spectrum SN3700 / Arista 7050X3 | 440 000 |
| Switch storage | 2 | MikroTik CRS520 100G | 76 000 |
| Switch mgmt | 1 | MikroTik CRS354 | 12 000 |
| Router/FW HA | 2 | Netgate 8200 par + CARP | 64 000 |
| UPS | 2 | Eaton 9PX 11kVA + 2x EBM | 190 000 |
| Generator-prep | 1 | Manuell transfer-switch | 25 000 |
| Rack | 2 | APC NetShelter SX 48U | 56 000 |
| Kjøling | 1 | Dedikert 10-12 kW precision (Stulz/Vertiv) | 180 000 |
| PDU | 4 | APC AP8965 3-fase 400V | 112 000 |
| Bygg-strøm | — | 32A 3-fase ny kurs (elektriker) | 80 000 |
| NIC | 12 | NVIDIA ConnectX-7 200G | 90 000 |
| Kabler, KVM | — | OM4 fiber, 200G DAC | 60 000 |
| Sikkerhet + brann | — | Adgang, kamera, Novec/IG-541, miljø | 120 000 |
| **Total** | | | **~7 463 000** |

- **Strøm:** idle 2.8 kW / last 9-11 kW / topp 13.5 kW
- **Støy:** 78-85 dB
- **Kontorrom:** Absolutt nei. Eget DC-rom, 3-fase, brannvarsling, adgangskontroll.

3M-cap-versjon (1 node 4x H100 SXM + skikkelig facility) ≈ 3.2M.

### 5.5 Anbefaling
**Start på Tier 1.** Begrunnelse:
1. Ingen betalende kunder ennå. 70B Q4 på 2x 3090 validerer hele soft-stacken.
2. 54k er gjenvinnbart — 3090 selges videre uten tap.
3. Tier 2 utløses av første konkrete kunde-LOI, ikke håp.
4. Tier 3 krever facility-investering — ikke kjøp H100 før rommet finnes.
5. Tier 4 er separat finansierings-beslutning som krever ~2-3M ARR.

**Migrasjonssti:** Tier 1 → 6 mnd validering → Tier 2 ved første betalende kunde → Tier 3 først når 3+ kunder gir forutsigbar inntekt og du har dedikert serverrom klart.

---

## 6. Rom og infrastruktur (Facility-agent)

Per tier:

### 6.1 Tier 1 — MVP (~1 kW)
- **Rom:** min 8 m², komfortabelt 10-12 m². Vanlig dør.
- **Strøm:** 1x 16A-kurs holder. Egen kurs anbefalt. RCD type A.
- **Varme:** ~1 kW — som én panelovn.
- **Kjøling:** Vinter åpent vindu. Sommer mobil AC 2.5 kW (4-8k).
- **Støy:** 40-50 dB. OK i leilighet, naboer merker ingenting.
- **Brann:** 6 kg pulver- eller 2 kg CO2-håndslukker. Røykvarsler.
- **Sikring:** Vanlig dørlås.
- **Funker i kontorrom?** Ja, helt uproblematisk.
- **MÅ-ha:** Egen kurs, slukker, røykvarsler, UPS, støvfilter.

### 6.2 Tier 2 — Sterk prototype (~3 kW)
- **Rom:** min 12 m², komfortabelt 15-18 m².
- **Strøm:** 2x 16A-kurser på forskjellige faser, direkte fra sikringsskap. RCD type A.
- **Varme:** 2.5-3 kW.
- **Kjøling:** Mobil AC 3.5 kW (8-12k) til høst. Sommer: split AC 5 kW (15-25k installert) anbefales.
- **Støy:** 50-60 dB. Vegg-til-vegg-naboer kan høre vifte-sus.
- **Brann:** 6 kg pulver + 2 kg CO2. Røykvarsler med push.
- **Sikring:** Sylinderlås, kabel-skap låst hvis utleielokale.
- **Funker i kontorrom?** Ja, men varmen blir merkbar uten AC.
- **MÅ-ha:** 2 separate kurser, AC, UPS-er, overspenningsvern, **næringsforsikring** (hjemforsikring dekker ofte ikke >50-100k).

### 6.3 Tier 3 — Kontor-lab (~6-9 kW)
- **Rom:** min 15 m², komfortabelt 20-25 m², dør 90 cm.
- **Strøm:** **3-fase 3x16A blir aktuelt her** — be el-installatør. RCD type B (DC-feilstrøm fra inverter-PSU).
- **Varme:** 6-8 kW.
- **Kjøling:** Mobil funker IKKE. Split AC 7-9 kW (35-60k) ELLER portabel server-AC 8 kW (60-120k). Frikjøling om vinter halverer AC-tid.
- **Støy:** 60-70 dB. Naboleilighet klager. Næringslokale: OK.
- **Brann:** 2 kg CO2 (ikke pulver — ødelegger elektronikk). Aspirerende røykdetektor anbefalt.
- **Sikring:** Sylinderlås + kabinett-lås + dør-sensor til alarm.
- **Funker i vanlig 10-15 m² kontorrom?** Marginalt. Øvre grense for hjemme/kontor.

### 6.4 Tier 4 — Mini-datasenter (15-25 kW)
- **Rom:** min 20 m², tak 2.7 m, dør 100 cm, betonggulv.
- **Strøm:** 3-fase 32A/63A — **kommunalt nett blir blocker** i eldre næringsbygg med 3x25A-hovedsikring. Sjekk hovedinntak FØR planlegging.
- **Varme:** 15-22 kW. Industriell.
- **Kjøling:** Dedikert presisjons-AC / in-row 20-25 kW (150-400k installert). Frikjøling kan dekke 60-70 % av året i Norge.
- **Støy:** 70-85 dB. Skal IKKE være i samme bygg som boliger.
- **Brann:** Gass-slukker (Novec 1230 / IG-541, 80-200k). Aspirerende røykdetektor. Pulver og vann er ute.
- **Sikring:** Sikret dør (RC2+), kabinett-lås, kamera, alarm.
- **Funker i hjem/kontor?** **Nei.**
- **Når flytte:** Hvis kontinuerlig >8-10 kW, støy >65 dB med dør lukket, 2+ rack-monterte GPU-servere, eller naboklage.
- **Hvor lete:** Industri-/lager-naboleilighet (1500-3500/m²/år), liten businesspark, **colocation som mellomsteg** (Bulk Infrastructure, Green Mountain, Digiplex — fra ~8-15k/mnd/rack estimat).

### 6.5 Tverrgående terskler — over i ekte serverrom

| Trigger | Terskel |
|---|---|
| Total kW kontinuerlig | >8-10 kW |
| Støy m/dør lukket | >65 dB |
| Antall GPU-servere | >2 rack-monterte |
| Strømnett | Krever >3x16A eller hovedinntak må oppgraderes |
| Forsikring | Verdi >200-300k og hjemforsikring dekker ikke |
| Naboklager | Første klage = signal |

Krysser to: begynn aktivt å lete. Krysser fire: flytt før neste hardware-innkjøp.

---

## 7. Produktpakker (Product-agent)

### 7.1 Pakke 1 — Refi-Co-Pilot

- **Målgruppe:** Finansrådgivere, refi-meglere, regnskapsførere med refi. 2-20 ansatte, omsetning 5-40 MNOK.
- **Problem:** Rådgiveren bruker 70 % av tiden på dokumentbehandling, ikke rådgivning.
- **Verdiforslag:** Saksbehandlingstid 6t → <1t per refi, full sporbarhet, dokumenter ut av huset = null.
- **Inkludert:** Vår node (RTX 4090/5090, 64-128 GB RAM, kryptert SSD); Qwen2.5-VL 72B + bge-m3; 4 agenter (klassifiserer, tall-ekstraktor, sammendrag-/saksnotat-generator, avviks-flagger); dokumenttyper: skattemelding, lønnsslipp, kontoutskrift, gjeldsbrev, panteattest, takst, årsregnskap, A-melding; dashboard + audit-log; 5-10 brukere, 2 TB.
- **Automatiseres:** OCR + klassifisering, tall-ekstrahering, førsteutkast saksnotat, sjekkliste per bank, sammenligning mot tidligere saker.
- **Mennesker fortsatt:** Kundedialog, endelig kredittvurdering, valg av bank/produkt, signering, regulatorisk ansvar, QC av AI-utdrag, atypiske saker.
- **Pris (estimat):** Engangs 180-250k + månedlig 8-15k. ELLER leasing 18-25k/mnd × 36 mnd.
- **Demo:** 15 min — operator drar mappe inn, viser klassifisering + ekstrahering live, genererer saksnotat, trekker ut nettverkskabelen midt-demo, viser audit-log.
- **First-customer-fit:** Svært høy (operatorens kontakt).

### 7.2 Pakke 2 — Dokument-AI for SMB ("Kontorhjernen")

- **Målgruppe:** SMB 10-50 ansatte, omsetning 15-100 MNOK. Byggentreprenør, mellomstor produksjon, eiendomsforvalter, importør/grossist.
- **Problem:** Kontoplan i Tripletex/Fiken, kontrakter i SharePoint, HMS-perm i hyllen — ingen finner noe.
- **Verdiforslag:** Én søkbar AI-assistent for alle bedriftens dokumenter, lokalt, med bilagsmatching + kontraktsoppslag.
- **Inkludert:** Mindre node (RTX 4090, 64GB) eller hybrid; Llama 3.3 70B + bge-m3 + OCR; 3 agenter (bilag-matcher mot Tripletex/Fiken API, kontrakt-oppslag, generell Q&A); web-UI + Slack/Teams; 10-30 brukere, 1 TB.
- **Automatiseres:** Bilagskontering-forslag, kontrakts-varsling, "hvor står det at..."-søk, generering møtereferat fra opptak.
- **Mennesker:** Endelig kontering, kontraktsforhandling, HMS-runder, eksterne beslutninger.
- **Pris:** Engangs 120-180k + 5-9k/mnd. Leasing 12-16k/mnd.
- **First-customer-fit:** Lav for refi-aktør. Sannsynlig pakke #2 i pipeline.

### 7.3 Pakke 3 — On-prem AI-node ("Suverenitets-boksen")

- **Målgruppe:** Bedrifter som juridisk/kontraktuelt ikke kan bruke sky-AI. 5-100 ansatte. Forsvars-underleverandører, advokater, private helse-aktører, finansforetak, kommuner.
- **Problem:** Behov for moderne AI, men sky utelukket av regulering/kontrakt.
- **Verdiforslag:** Komplett AI-stack i en boks som aldri snakker ut, dokumentert sikkerhetsarkitektur, NSM-vennlig.
- **Inkludert:** Hardware-boks (1U eller mini-tower); RTX 5090 eller 2x 4090; redundant disk, HW-kryptering, tamper-evident; kundens valg av åpen modell; generisk agent-rammeverk; air-gap-modus, signert oppdaterings-stick; full audit; 24t support; kvartalsvise sikkerhetsoppdateringer; 5-50 brukere, 4 TB.
- **Pris:** Engangs 250-400k + 12-20k/mnd. Dyrere fordi det inkluderer sikkerhets-/compliance-dokumentasjon.
- **Demo:** 20 min teknisk gjennomgang for IT-sjef + sikkerhetsansvarlig.
- **First-customer-fit:** Lav for refi. Lang salgssyklus (6-12 mnd). Krever referansekunde.

### 7.4 Pakke 4 — HMS-/Teknisk-rapport-agent ("Felt-skriveren")

- **Målgruppe:** Entreprenør, industri, olje-service, havbruk. 20-150 ansatte.
- **Verdiforslag:** Snakk inn observasjonen på telefonen i felt, få ferdig HMS-/avviks-/ukerapport før du er tilbake på kontoret.
- **Inkludert:** Node + mobilapp synker over VPN; Whisper-large + Llama 3.3 + bilde-modell; 3 agenter (tale-til-rapport, foto-klassifiserer, ukerapport-aggregator); integrasjon SharePoint, evt. Infobric/HMSReg; 20-100 brukere, 2 TB.
- **Pris:** Engangs 150-220k + 6-10k/mnd. Leasing 14-18k/mnd.
- **First-customer-fit:** Null for refi-aktør. **Park til 2027** med mindre entreprenør spør spesifikt.

### 7.5 Anbefaling
**Lanser Pakke 1 (Refi-Co-Pilot) først.** 4-6 ukers bygge-tid, 2-4 mnd til første pengende kunde. Pakke 2 nummer to (80 % gjenbruk av stack). Pakke 3 nummer tre. **Drop Pakke 4 i 2026.**

---

## 8. Refi-nisjeanalyse (Refinansiering-agent)

### 8.1 Typisk prosess (10 steg)
1. Lead inn (skjema/telefon/henvisning)
2. Innledende kvalifisering
3. Samtykke + dokumentinnhenting (BankID, lønnsslipp 3 mnd, skattemelding, kontoutskrifter 3-6 mnd, gjeldsoversikt, takst)
4. Økonomisk kartlegging (DTI, betjeningsevne, sikkerhet)
5. Bank-shortlist + søknadspakker (3-15 banker)
6. Innsending (manuelle portaler/e-post; noen få API)
7. Oppfølging
8. Tilbudssammenligning
9. Anbefaling + signering (BankID)
10. Etterkontroll + arkiv (5-10 år)

### 8.2 Per steg — automatiseringsgrad

| Område | Auto-grad | Tid spart/sak |
|---|---|---|
| Dokumentinnhenting + OCR + klassifisering | **Høy** | 30-60 min |
| Kundedialog (kvalifisering, status) | Middels | 20-40 min |
| Oppsummering økonomi (DTI, gjeldsbilde) | **Høy** (verifisert) | 45-90 min |
| Sjekklister | **Full** | 15-30 min |
| Kredittdokumentasjon-utdrag | **Høy** | 30-60 min |
| Søknadsforberedelse per bank | Middels | 20-40 min/bank |
| Oppfølging (e-post-parsing) | **Høy** | 30-60 min |
| CRM | **Full** | — |
| Varsler | **Full** | 10-20 min |
| Risikovurdering / KYC-flag | Lav-Middels | 15-30 min |
| Standardiserte rapporter | **Høy** | 20-40 min |
| Real-time dashboard | **Full** | — |

**Realistisk total besparelse:** 4-7 timer manuelt arbeid per case → 1-2 timer menneske-tid (verifikasjon, forhandling, råd). **60-75 % redusert tid, ikke 95 %.**

### 8.3 Hva kan IKKE automatiseres fullt
- Endelig kredittvurdering og rådgivning (finansforetaksloven/låneformidlingsloven)
- Bank-relasjon og forhandling (menneske-kapital)
- Komplekse cases (skilsmisse, sykdom, gjeldsordning, nær-konkurs)
- Edge-cases i dokument-forståelse (uleselig scan, manglende historikk, selvstendig næringsdrivende)
- Identitetsverifisering (BankID-prosesser)
- Etisk skjønn og pris-følsom rådgivning

### 8.4 Regulatorisk (domene-spesifikt — overlapp med §11)
- **Finansforetaksloven + låneformidlingsloven (2022):** Hvis aktør formidler lån → krever Finanstilsynet-konsesjon eller tilknytning. **AI-operatør kan bli ansett som medformidler** hvis systemet aktivt anbefaler bank.
- **Finanstilsynets rundskriv om låneformidling:** god forretningsskikk, dokumentert rådgivning, interessekonflikt-håndtering.
- **Hvitvaskingsloven:** Aktør har selvstendig rapporteringsplikt. AI MÅ overflate flagg, ikke skjule dem.
- **Finansavtaleloven:** Frarådingsplikt ved svak betjeningsevne — AI kan ikke "glatte over".
- **Klage-/erstatningsrisiko:** AI gir feil tall → kunde får dårlig refi → krav mot rådgiver. AI-leverandør kan også få regresskrav.

### 8.5 Data som må beskyttes ekstra
Personnummer, lønnsslipper/skattemelding/kontoutskrifter, BankID-tokens, helseopplysninger, kredittscore + bank-avslag, familie-/samlivsstatus.

### 8.6 Top-10 risikoer
1. LLM hallusinerer tall fra kontoutskrift → feil DTI
2. Multi-tenant feil (RAG-feil med feil filter)
3. Dokument-eksport ut av on-prem ved uhell
4. Manglende audit-trail når kunde klager 2 år senere
5. Aktør "pensjoneres" → uklart hvem som har rådgiver-ansvar
6. AI glir fra refi-råd til investeringsråd (verdipapirhandelloven)
7. Modell-bias (selvstendig, innvandrere, enslige forsørgere) — diskrimineringsrisiko
8. Backup-korrupsjon (ransomware → 5 års kundedata tapt)
9. Klient-personell stoler for mye på AI, slutter å verifisere
10. Operatør blir de-facto låneformidler ved skala uten konsesjon

### 8.7 Trygt system-design
- **Human-in-the-loop ufravikelig** for alt med tall som går til kunde eller bank
- Personnummer-maskering i alle logger og UI utenom autorisert visning
- Append-only audit log + hash-kjede
- Eksport = audit-event + kvitterings-PDF + mottaker-bekreftelse
- Read-only LLM-agent vs write-agent; sistnevnte = 2-personer over terskel
- **Tall regnes med deterministisk Python, ikke LLM**. LLM forklarer, kalkulator produserer.
- Templates for bank-søknader = låste maler med utfylte felt
- Tydelig juridisk merking: "Beslutningsstøtte — ikke kredittrådgivning. Endelig vurdering signert av [navn, konsesjon]"
- Egress-kontroll: ingen ekstern LLM-API. iptables + DNS-blokk.
- PII-scanning før all ekstern logg

### 8.8 PRO/CONTRA

**PRO:** Konkret betalende kunde. Dokumenttung = LLM-styrke. Sensitive data = on-prem-argumentet selger seg selv. Skalerbart til andre rådgivere. Liten pilot, få stakeholders. Operator har domene-tilgang gratis.

**CONTRA:** Regulatorisk risiko. Aktørens objektivitet kompromittert hvis han er pilot-bruker. Smal nisje = "refi-AI"-stempel. Bank-integrasjoner manuelle, endrer seg. Klagerisiko stor. "Pensjonere" aktøren urealistisk og juridisk farlig på 12-24 mnd. Margin presses (hvorfor ikke gå direkte til Lendo/Axo).

### 8.9 KONKLUSJON

**(b) Ja, men bygg ikke "refi-AI" — bygg generell sensitiv-dokument-AI og bruk refi som første pilot.**

Refi er ideelt som *pilot* fordi du har betalende bruker, klar ROI og ekte sensitive data å designe sikkerhets-arkitektur mot. Men å bygge produktet *som* refi-AI låser deg til regulert nisje med formidlingskonsesjons-risiko og smal exit. Den underliggende kapabiliteten — on-prem dokumentforståelse + strukturert ekstraksjon + audit-trail + human-in-the-loop — er like verdifull for revisjon, advokat, HR, helse, eiendom. Bygg kjernen vertikal-agnostisk; pakk refi-spesifikke templates/sjekklister/bank-koblinger som et *modul* oppå. Aktøren forblir domene-konsulent og signerende rådgiver — ikke "pensjonert", men frigjort fra manuelt arbeid.

---

## 9. Forretningsmodell og priser (Business-agent)

### 9.1 12 inntektsmodeller med pris

| Modell | Lav | Middels | Høy | Rytme | Margin |
|---|---|---|---|---|---|
| Engangsoppsett | 25k | 75k | 150k | Forskudd 50/50 | 60-75 % |
| Månedlig drift | 5k/mnd | 15k/mnd | 50k/mnd | Mnd forskudd | 70-85 % |
| Leasing AI-boks | 8k/mnd | 25k/mnd | 60k/mnd | Mnd, 24-36 mnd | 35-50 % |
| Betalt pilot | 50k | 150k | 300k | 50/50 | 50-65 % |
| Konsulenttimer | 1500/t | 2000/t | 2500/t | Etterskudd 30 d | 80-90 % |
| Skreddersydd agent | 75k | 175k | 400k | Milestone | 55-70 % |
| Dokumentautomatisering | 10k/mnd | 35k/mnd | 100k/mnd | Mnd | 70-85 % |
| Privat hosting | 15k/mnd | 50k/mnd | 150k/mnd | Mnd | 40-55 % |
| Opplæring | 25k/dag | 50k/dag | 75k/dag | Forskudd | 80-90 % |
| Sikkerhetsgjennomgang | 50k | 100k | 200k | 50/50 | 70-85 % |
| Vedlikehold | 10 % av oppsett | 20 % | 30 % | Årlig forskudd | 75-85 % |
| Revenue share | 10 % | 20 % | 30 % | Mnd etterskudd | Variabel |

### 9.2 Anbefalt kombinert modell

**Pakke A — "Pilot-til-leasing" (anbefalt for refi-aktør):**
150k pilot 8 uker → konvertering til Tier-2 leasing 25k/mnd × 36 mnd. LTV: 150k + 900k = 1.05M per kunde over 3 år.

**Pakke B — "Oppsett + managed":**
75k oppsett + 15k/mnd + 50k/år vedlikehold. LTV år 1: 305k.

**Pakke C — "Audit-til-oppsett":**
75k AI-audit → identifiserer 2-3 use-cases → 100k oppsett + 15k/mnd.

For solo: prioriter A.

### 9.3 Top 3 modeller å satse på først
1. **Betalt pilot (fastpris)** — finansierer læring, filtrerer seriøse kjøpere, gir referansecase.
2. **Månedlig drift/support** — MRR fra dag én etter pilot. Lock-in.
3. **Skreddersydd agent (fastpris)** — høy snittordre, gjenbruker komponenter.

### 9.4 Modeller å UNNGÅ år 1
- Ren konsulenttime som hovedmodell (tid mot tid, ingen skalering)
- Revenue share uten upfront (cash-flow-død)
- Privat hosting (krever stabilt drifts-setup)
- Leasing uten finansieringspartner (binder all cash)
- Dokumentautomatisering per-stk (krever måle-infra du ikke har)

### 9.5 Realistisk ARR år 1

**Pessimistisk (~350k):** 1 pilot 150k + 1 oppsett 75k + 1 audit 50k + drift 10k/mnd × 8 mnd. Dekker ikke heltids-lønn.

**Realistisk (~750k):** 1 stor pilot 200k (refi) + 1 mindre 100k + 1 audit 75k + 1 oppsett 75k + 1 leasing-konvertering 25k/mnd × 6 mnd + drift 12k/mnd × 8 mnd + 50k opplæring. Dekker solo + Karri-andel.

**Optimistisk (~1.4M):** 2 piloter + 2 oppsett + 2 leasing + 1 skreddersydd agent + audit + opplæring. Krever warm referral.

### 9.6 Når trenger operator co-founder/ansatte
- **MRR > 80k/mnd** (~5 løpende drifts-kunder)
- **3+ aktive piloter samtidig**
- **Omsetning år 1 > 600k** med pipeline 1.5M+ for år 2

Først teknisk leveranse-person (mid-level ML-engineer eller senior IT-konsulent), ikke selger. Operator beholder salg de første 18 mnd. Co-founder bare hvis kritisk komplementær kapasitet (f.eks. compliance-jurist).

---

## 10. Salgsstrategi (Sales-agent)

### 10.1 30-sekunders pitch

> "Jeg bygger AI-systemer som kjører lokalt hos kunden — ikke i skyen. Norske bedrifter som håndterer sensitive dokumenter — advokater, regnskap, refinansiering — får i dag ikke brukt ChatGPT eller Copilot på de viktigste dataene sine, fordi det bryter taushetsplikt eller GDPR. Jeg installerer en boks på kontoret deres som leser, sorterer og oppsummerer dokumenter automatisk. Data forlater aldri huset. En saksbehandler sparer typisk 8-15 timer i uka. Pilot på seks uker, fast pris."

### 10.2 2-minutters pitch

> "Takk for at du tok møtet. Jeg skal være kort på hva jeg gjør, så vil jeg heller høre om dere.
>
> Problemet jeg ser hos norske SMB-er som jobber dokumenttungt — refinansiering, regnskap, advokat, eiendom — er todelt. Én: folk drukner i PDF-er, e-poster, vedlegg og skjema som må leses, sjekkes og tastes inn. To: når de prøver å bruke ChatGPT eller Copilot for å løse det, stopper compliance dem. Kundedata, personnummer, taushetsbelagt informasjon kan ikke sendes til en amerikansk skytjeneste.
>
> Det jeg leverer er en AI-server som står fysisk hos kunden. Den leser inn dokumentene deres, forstår innholdet, og automatiserer det som i dag er manuelt — utfylling, sjekklister, sammendrag, søk på tvers av saker. Data forlater aldri kontoret. Ingen sky, ingen tredjepart, ingen databehandleravtale med utenlandsk leverandør.
>
> For eksempel: en refinansieringsrådgiver bruker i dag rundt 45 minutter på å sjekke en lånesøknad — hente ut inntekt, gjeld, sikkerhet fra ulike vedlegg. Med systemet jeg bygger gjør AI-en førsteutkastet på 3 minutter. Rådgiver kontrollerer og godkjenner. Tidsbruken faller med 70-80 prosent per sak.
>
> Jeg jobber med pilot-modell: én konkret prosess, seks uker, fast pris. Ingen abonnement før dere har sett at det funker på deres egne dokumenter.
>
> Det jeg lurer på fra dere: hvilken prosess i deres hverdag spiser mest tid uten å skape verdi?"

### 10.3 Pitch til refi-aktør

> "Dere har et skaleringsproblem som ikke løses med flere ansatte. Hver ny kunde betyr flere bilag, flere lånesøknader, flere dokumenter som må behandles manuelt. Marginene presses, og dere får ikke tatt inn flere kunder uten å ansette — og de ansatte dere har, bruker 60-70 prosent av tiden på dokumentbehandling istedenfor rådgivning.
>
> ChatGPT løser dette teknisk, men ikke juridisk. Personnummer, inntektsopplysninger, gjeldsregister — dette kan ikke lekke til en amerikansk leverandør, og kunden forventer at dere har tenkt gjennom det.
>
> Det jeg leverer er en lokal AI som leser bilag, lønnsslipper, lånedokumenter og skattemeldinger, og gjør førsteutkastet av den manuelle jobben. Klassifiserer, ekstraherer tall, sjekker mot regler, fyller inn skjema. Saksbehandler går fra å taste til å kontrollere. Realistisk: 8-15 timer spart per saksbehandler per uke.
>
> Det viktigste for dere strategisk: rollen til de ansatte endres fra dokumentbehandler til rådgiver. Det er der marginen ligger.
>
> Pilot-tilbud: én konkret prosess hos dere — for eksempel lånesøknad-screening eller bilagsmottak — automatisert på seks uker, fast pris. Jeg setter opp en server hos dere, trener den på deres dokumenter, og dere ser konkret før/etter på reelle saker. Hvis det ikke sparer dere minst fem timer per uke per bruker, betaler dere ingenting utover oppsettet."

### 10.4 Pitch til tekniske bedrifter / advokat-regnskap-eiendom
(Se full tekst i agent-leveranse — kjernepunkter: HMS/FDV-volum + sky-utelukket-av-kunder for tekniske; klient-konfidensialitet + autorisasjonsrisiko for advokat/regnskap.)

### 10.5 20 typer kunder
**Finans/rådgivning:** refi-formidlere, regnskapskontor (Tripletex/Fiken/PowerOffice), mindre revisjonsfirma, forsikringsmeglere.
**Juss/eiendom:** mindre advokatfirmaer, eiendomsmeglere, inkassobyråer.
**Helse/omsorg (privat):** privatklinikker (tannlege/fysio/psykolog), bedriftshelsetjenester.
**Teknisk/industri:** entreprenører, olje-/offshore-underleverandører, havbruk, industribedrifter med ISO.
**Offentlig-nær/regulert:** forsvars-underleverandører, kommunale foretak, interkommunale.
**Uventede:** kirkesamfunn lokalt, fagforeninger, idrettsforbund (politiattest), bedriftsadvokater in-house.

### 10.6 Første 10 segmenter operator bør teste konkret
1. Refi-aktøren operator kjenner (varm intro, smerten bekreftet)
2. 2-3 mindre regnskapskontor i Trondheim (NTNU-nettverk)
3. Ett mindre advokatfirma (familierett/eiendom — eier = beslutter)
4. Et HMS-konsulentselskap (kan bli forhandlerkanal)
5. Mellomstor entreprenør Nord-Vestlandet/Trøndelag
6. Havbruksselskap eller leverandør (Mattilsynet-dok)
7. Inkassobyrå (ekstremt dokumentintensivt)
8. Privatklinikk-kjede (helsedata kategorisk utelukker sky)
9. Eiendomsmeglerkontor (kontrakt + tilstandsrapport)
10. Forsvars-underleverandør (lang syklus, men referansevekt)

Start 1-4. Bruk 5-10 som parallelle samtaler.

### 10.7 Kundemøte-spørsmål

**Smerte:** "Hvor mye tid bruker en saksbehandler per uke på [dokumenttype]?" / "Hva ville dere fjernet hvis dere kunne?" / "Hvor mange flere saker kunne dere tatt hvis dokumentjobben ble halvert?"

**Data + sensitivitet:** "Hvor lagrer dere kundedata i dag?" / "Er det data dere bevisst IKKE bruker AI-verktøy på?" / "Hva sier compliance om ChatGPT/Copilot?" / "Har dere kunder som stiller krav om hvor data ligger?"

**Beslutning + budsjett:** "Hvem ville bestemt?" / "Hva ser typisk budsjett-prosess ut for nye verktøy?" / "Hva ville få deg til å si nei?" / "Hva bruker dere på dokumentbehandling i dag — lønn, lisenser, konsulenter?"

**Suksess:** "Hva ville vært tegnet på 90 dagers suksess?" / "Hvem internt må være fornøyd?" / "Finnes en sak-type dere ville prøvd det på først?"

### 10.8 Hvordan selge pilot uten å virke teknisk
- Snakk **timer og kroner**, ikke modeller og parametere
- Vis **før/etter på ekte dokumenter**, ikke arkitekturdiagrammer
- **Én håndfast leveranse, én prosess** ("automatiser lånesøknad-screening", ikke "vi bygger AI")
- **Lav-risiko ja:** begrenset scope + fast pris + sluttdato
- **La kunden eie outputen**

### 10.9 Anti-mønstre
- Pris/produkt før smerte bekreftet
- Tech-deep-dive i møte 1
- Sjargong ("RAG", "vector store", "embedding")
- Overlove automatisering
- Uklart ansvar når AI bommer
- **For lav pris:** under 80-100k for pilot signaliserer hobby
- Demoer på generiske data — bruk deres egne med NDA

### 10.10 Konkret salgsaksjon første 4 uker

**Uke 1:** SMS refi-aktør → møte innen 10 dager. Liste 30 potensielle fra nettverk. Send 10 personlige LinkedIn/e-post (ikke pitch — be om 20 min for å lære).

**Uke 2:** Refi-møte (2-min pitch + spørsmål fra §10.7). Be om 3 representative dokumenter. Send 10 nye meldinger. Bygg demo.

**Uke 3:** Møte 2 med refi-aktør — vis demo på deres dokumenter. "Hvor mye er dette verdt i uka?" — få et tall. Send pilot-tilbud innen 48t. 3-5 førstesamtaler fra pipeline.

**Uke 4:** Luk pilot-kontrakt. Send pilot-tilbud #2 og #3. Sett opp CRM (regneark).

Mål: én signert pilot, fire kvalifiserte samtaler, en pitch som sitter.

---

## 11. 30/60/90-dagers plan (Execution-agent)

### 11.1 Uke 1 — orientering og fundament

**Dag 1:** Skriv 1-siders intensjon i `~/Obsidian/Brain/01-onprem-ai/00-intensjon.md`. Sett budsjett-tak år 1 (eks. 150k egne + 100k lån). Bestem 15t/40t/uke. SMS refi-aktør → kaffe torsdag.

**Dag 2:** Book 2t advokat (GDPR + DPA + Finanstilsyn-touchpoint). List 3 bruks-case fra refi i `01-bruks-case.md`. Skriv Karri-rolle (5-10t/uke, måned 2).

**Dag 3:** Definér Tier 1-spec (BOM i `02-hardware-tier1.md`). Pris-sammenlign 3 leverandører. **Beslutt: kjøp Tier 1 nå ELLER lei cloud-GPU 30 dager.** Anbefaling: lei cloud først.

**Dag 4:** Bestill Runpod-konto (A100 40GB eller H100). Refi-møte med 4 spørsmål. Bestill OPNsense (~5-8k) hvis Tier 1 også bestilles.

**Dag 5:** Spinn opp Runpod-pod, `ollama run llama3.1:70b` svarer. Installer Qdrant. Klon command-center, identifiser gjenbrukbare moduler.

**Dag 6:** Last opp 3 anonymiserte refi-dokumenter, chunk + indekser. Query "Oppsummer kredittvurdering" → svar med kildehenvisning.

**Dag 7:** Ukesoppsummering. Oppdater budsjett (faktisk vs planlagt). Statusoppdatering til Karri.

### 11.2 Uke 2-4 (30 dager)

**Uke 2:** Bestill Tier 1 (leveringstid 1-2 uker). Skriv 2 prompt-templates. Bygg `RefiDocAgent` (PDF → ekstrahere → svare på 3 standardspørsmål). Jurist-møte. Første LinkedIn-post.

**Uke 3:** Web-UI på command-center (gjenbruk auth, ny `/refi-demo` route). Spill inn 5-min demo-video. Identifiser 15 potensielle kunder i `05-kundeliste.md`. Send 5 førstegangs-eposter.

**Uke 4:** Tier 1 mottatt. Sett opp OPNsense + workstation. Migrer fra cloud til lokal. Re-kjør demo lokalt — paritet. Pilot-tilbuds-mal (2 sider). 1-2 oppfølgings-møter. Send pilot-tilbud til refi-aktør (75k, 6 uker).

### 11.3 Måned 2-3 (90 dager)

**Måned 2:** Pilot signert innen 15. Karri onboardet 5-10t/uke. Tier 2-spec ferdig (bestilles når pilot-faktura kommer inn). Audit-trail-modul innebygd fra pilot-start. Backup-rutine operativ.

**Måned 3:** Pilot levert med målbar verdi (eks. "kuttet 12t/uke saksbehandling"). Case-study skrevet (2 sider, anonymisert ved behov). Tier 2 installert. 3 nye kundesamtaler. Konverterings-tilbud sendt til pilot-kunde (25-40k/mnd).

### 11.4 Første prototype
- Hardware: Cloud-GPU uke 1-3, Tier 1 uke 4+
- Modell: Llama 3.1 70B Q4 via Ollama (uke 1-3), vLLM når Tier 1
- RAG: PDF → `unstructured` parsing → chunk 512 t overlap 50 → Qdrant per kunde
- 2-3 agenter: `DocSummarizer`, `RegelverkChecker`, `KundeBrev-generator`
- 1 demo-flyt: refi-saksbehandling (last opp PDF → strukturert oppsummering + regelverk-flagg + kundebrev-utkast)
- Web-UI: command-center-fork med 3 routes (`/upload`, `/agents`, `/audit`)
- Kjøretid: 15 min uten kræsj

### 11.5 Første demo (15 min)
- **Min 0-2:** Kontekst. On-prem. Vis OPNsense med null utgående trafikk.
- **Min 2-5:** Last opp 3 dokumenter. Ekte format.
- **Min 5-10:** AI-flyt. Strukturert svar med kildehenvisning. Vis audit-log samtidig.
- **Min 10-12:** Wow. "Skriv kundebrev som forklarer avslag basert på § X." → 80 % klart utkast.
- **Min 12-13:** Vis at samme prompt mot ChatGPT ville lekket data.
- **Min 13-15:** CTA. Pilot 6 uker, 75k. Beslutning innen 10 dager.

### 11.6 Bygg vs kjøp

**Bygg selv:** Agent-orkestrering (command-center utvidet), dokument-pipeline tilpasset refi, domene-prompter, UI for demo/drift, audit-trail-modul, onboarding-script.

**Kjøp/bruk ferdig:** Modell-runtime (Ollama → vLLM), Qdrant, Postgres, restic + Hetzner, OPNsense, hardware, **refi-aktør som domenekonsulent** (timepris eller revenue-share), jurist (timepris), regnskap (Fiken).

### 11.7 Hva UNNGÅ å bygge år 1
Egen finetune-pipeline, GPU-orkestrering på tvers av noder, marketplace/SaaS-portal, egen modell-trening, white-label, multi-tenant sky, iOS/Android-apper, mer enn 1-2 ekstern integrasjon per kunde, egen autentiserings-løsning (bruk Authelia/Keycloak), eget overvåknings-stack.

### 11.8 Måleparametre — spores ukentlig
- Antall kundesamtaler avholdt (mål >3/uke fra uke 3)
- Antall pilot-tilbud sendt (mål >1/uke fra uke 4)
- Tid bygging vs salg (% — mål min 40 % salg fra uke 3)
- Brent kapital + runway i måneder
- Tekniske mål: queries/dag, MB/dag, oppetid
- Avgjørelser flagget for jurist (mål 0 åpne >2 uker)
- LinkedIn-poster (mål 1/uke fra uke 2)
- Karri-timer (fra måned 2: 5-10t/uke)

### 11.9 Top 5 tiltak operator gjør i uke 1
1. **SMS refi-aktør i dag** — book kaffe denne uka, 4 spørsmål klare.
2. **Book jurist** — 2t innen 10 dager, ikke utsett.
3. **Lei cloud-GPU dag 4** — ikke vent på hardware-levering. Prototype kjører innen 72t.
4. **Skriv intensjon + budsjett-tak i Obsidian dag 1** — uten dette flyter scope.
5. **Send 5 førstegangs-eposter fredag uke 2** — selv om prototype ikke er ferdig. Salg starter før produkt.

---

## 12. Risikoer på tvers — top-20

Sammenstilt fra alle 10 agenter. Mottiltak per punkt.

### 12.1 Forretningsmessig
1. **Refi-aktør blir vennetjeneste uten kontrakt** → min 50k, helst 75k, skriftlig fra dag 1.
2. **"Refi-AI"-stempel låser deg ut av andre vertikaler** → bygg generell dokument-AI, refi som modul.
3. **Aktørens objektivitet kompromittert** (han er både pilot + operator-rådgiver) → hold ham som domene-konsulent, ikke beslutter på system-design.
4. **For lav pris signaliserer hobby** → ikke under 50k pilot, ikke under 1500/t konsulent.
5. **Ingen referansecase = ingen pipeline-multiplikator** → skriftlig OK om publisering før pilot starter.

### 12.2 Regulatorisk
6. **Operatør blir de-facto låneformidler ved skala** → spørsmål 4 til jurist FØR første salg.
7. **EU AI Act high-risk for refi** → spørsmål 8 til jurist.
8. **Klage etter feil AI-utdrag** → human-in-the-loop tvang + 4-øye-godkjenning + signert disclaimer.
9. **Datatilsynet-sak (RAG som "behandling")** → DPIA før første kundedata.
10. **AML-flag skjult av AI** → blocker, ikke filter — AI MÅ overflate, aldri filtrere bort.

### 12.3 Teknisk/operativ
11. **LLM hallusinerer tall fra kontoutskrift** → deterministisk Python regner, LLM forklarer.
12. **Multi-tenant data-lekkasje** → én GPU per tenant, separat schema + bucket, RLS som backup.
13. **Eksterne AI-APIer på sensitive data ved feil** → egress-firewall + PII-detektor hardline.
14. **Backup-korrupsjon / ransomware** → restic + Hetzner + månedlig restore-test dokumentert.
15. **Modell-output lekker treningsdata** → ingen cross-tenant finetune i år 1. Stock + RAG.

### 12.4 Personlig/organisatorisk
16. **Operator brenner ut alene** → Karri 5-10t/uke fra måned 2, fast sync.
17. **Teknisk perfeksjon før kundesamtale** → ring kunde i uke 1, ikke uke 8.
18. **Tier 4-fantasering før Tier 1 leverer verdi** → 7.5M CAPEX krever 2-3M ARR.
19. **Overlove automatisering** → kalibrér i hver demo: "AI utkast, menneske godkjenner".
20. **Sosial engineering / phishing** → YubiKey overalt, recovery i bankboks, separat dev-laptop.

---

## 13. Konklusjon

**Bør du bygge dette?** Ja, betinget av fire ting:

1. **Du dropper "pensjonere refi-aktør"-narrativet.** Han er din domene-konsulent + co-skribent + signerende rådgiver. Hans rolle endres fra dokumentbehandler til rådgiver — det er produktet, ikke automatisering av ham.

2. **Du går jurist før kunde.** 2t innen uke 2, faktura 5-15k. Hvis spørsmål 4 (låneformidlings-konsesjon) svarer "du blir medformidler ved skala": re-arkitekturer ELLER pivot til mindre regulert nisje (HMS, advokat, regnskap først).

3. **Du holder scope smal.** Én bruks-case, én kunde, én tier første 6 mnd. Tier 3-4-diskusjon er distraksjon. Du har ikke tjent retten ennå.

4. **Du behandler refi som pilot, ikke produkt-identitet.** Bygg generell on-prem dokument-AI; refi-modul oppå. Enstemmig anbefaling på tvers av alle 10 agenter.

### Første versjon (Tier 1 MVP)

- **Hardware:** 1 workstation, 2x brukt RTX 3090 (48GB samlet VRAM), 128GB RAM, 4TB NVMe RAID1, 8TB HDD backup. **~54k NOK.**
- **Software:** Ubuntu 24.04 + ZFS + Docker + vLLM (Qwen 2.5 72B AWQ-Q4) + bge-m3 + Qdrant + Postgres + Caddy + command-center-fork som UI.
- **Rom:** Vanlig kontorrom 10-15 m², 1x 16A-kurs, UPS, slukker, røykvarsler.
- **Sikkerhet:** WireGuard + jump-host + LUKS + YubiKey + audit-log + PII-egress-filter.
- **Bruks-case:** Refi-dokument-flyt med 3 agenter (klassifiserer, ekstraktor, sammendrag).

### Time-to-first-paid

- **Uke 1:** SMS refi-aktør, book møte, lei cloud-GPU, ring jurist.
- **Uke 2:** Jurist-svar, pilot-tilbud-mal, refi-demo på cloud.
- **Uke 3-4:** Tier 1 mottatt, lokal demo, pilot-tilbud sendt.
- **Uke 5-8:** Pilot signert + start.
- **Uke 13-14:** Pilot levert + case-study + konverterings-tilbud.

### Horisont

- **Q4 2026:** 2-3 løpende kunder, 750k-1M kumulativ omsetning, en levende referansecase, Tier 2 på vei.
- **Q4 2027:** 5-8 kunder, ARR 1.5-2.5M, første heltidsansatt, vurdere Tier 3 hvis pipeline tilsier.

**Tier 4 er ikke i kart enda.** 7.5M CAPEX = separat finansieringsrunde, ikke organisk vekst.

Gå.

---

## Vedlegg — agent-roster og kilder

Generert via 10 parallelle general-purpose subagenter, koordinert fra code-2 (operator-triggered, dispatchet 2026-05-24). Hver agent var streng på sitt scope; integrator (code-2) reconciler kryss-tråder i seksjon 1, 2, 12, 13.

Agent-mapping:
- §3 — CTO-agent (a6ba867f...)
- §4 — Security-agent (a1b438c3...)
- §5 — Hardware-agent (afc3d5eb...)
- §6 — Facility-agent (a27c98b6...)
- §7 — Product-agent (ab0d8a62...)
- §8 — Refinansiering-agent (ad4de997...)
- §9 — Business-agent (ae9861b8...)
- §10 — Sales-agent (a6670e22...)
- §11 — Execution-agent (ab99abab...)
- §12-13 — Integrator-syntese (code-2)

Alle agent-IDer er logget i firm-bus feed for sporbarhet.
