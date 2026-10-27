# FIRM v2 — strategisk plan (rev 2): 1 hovedagent + 7 spesialister

Bestilt av operatør 2026-07-27. Rev 2 samme kveld: pane 4 er **regnskapsfører-agenten**
(Pål-virksomheten), ikke grossist-generisk — operatørens presisering.

Kontekst: master LEVERT, jobbsøk FERDIG → thesis-1 og soking-1 pensjoneres. Ny GPU-boks
live (NO 4090, ~$270/mnd) med bekreftet Railway-trafikk. Strategisk hovedspor:
**Pål-relasjonen** — Pål solgte 120 AS-er i fjor; CRM-plattformen hans (aslisten-crm) er
navet vi bygger, utvider og etter hvert kommersialiserer. Plattformen = varig posisjon
hos Pål og nøkkel til managed-AI-ops-inntektslinjen (jf. project_managed_ai_ops:
Pål først, vei mot 50k/mnd).

## 1. Situasjonsbilde (det jeg legger til grunn)

| Prosjekt | Status | Behov fremover |
|---|---|---|
| **Pål-virksomheten**: aslisten-crm | I PROD (godkjenningsflyt, dokumentlås, offentlig skjemalenke; feiljakt-pakke deployet 23.07) | Hovedspor: drift + utvidelse + kommersialisering |
| **Pål-virksomheten**: grossist-plattform | 14 briefs, fase 0–3 pågår (Per-caset) | Bygges videre under samme agent — samme kunde-økosystem |
| **Pål-virksomheten**: RefiPrep | MVP i repo | Reaktiveres når Pål-sporet trenger den |
| Nexus (ai-assistent) | Live trading, GPU-max merget, læringsloop fase 2/3 | 2 paner — penger + læring |
| command-center/Brain | 24/7 daemons, memory ~13.7k objekter, hybrid RAG | Drift + GPU-ROI + brain×GPU |
| AS-regnskap (eget) / Personlig / salg | Lav kadens, PII-streng | Samles i admin-1 |
| Master-oppgave / Søking | FERDIG | Arkiveres (90-archive-konvensjon) |
| GPU-boks 46026731 | Live, underutnyttet | Bærende last + ROI-måling |

## 2. Ny pane-struktur (8 paner, 4×2-gridden beholdes)

| Pane | Rolle | Domene | Modell-baseline | Faste verktøy/skills/MCP |
|---|---|---|---|---|
| 1 | **orch** (hovedagent) | Intake → dekomponering → ruting via firm-bus → verifisering → minne | **Fable 5** | Alle MCP-er, Workflow, code-review, TaskCreate, CHARTER-vokter, push-gate |
| 2 | **nexus-1** | Trading-kjernen (strategi/risk/eksekvering) | Fable ved strategi, Opus fast ellers | trading-knowledge, pull-nexus-data, Railway CLI, github MCP, Karri-proposal-flyt |
| 3 | **nexus-2** | Læringsloop + GPU-bærende last (worker-agents, HLE, labels) | Opus fast | GPU-endepunktet, gpu-usage-report, HLE-tooling |
| 4 | **regnskap-1** (regnskapsfører-agenten) | HELE Pål-virksomheten: aslisten-crm (drift/utvidelse/kommersialisering), grossist-plattform, RefiPrep, alt Pål trenger | Fable produkt/arkitektur, Opus bygging | aslisten-crm-repo + prod-tilgang (cloudflared), grossist-briefs (AS/docs), pnpm/vitest, playwright MCP, regnskaps-domenekunnskap (purreregler/MVA/frister), PII-STRENG: kundedata aldri leid GPU, kode aldri i AS-mappa |
| 5 | **infra-1** | command-center, brain-daemons, systemd, launchers, deploy, Vast-drift | Opus fast | vast CLI, railway CLI, systemd, brain-doctor, vast-job, ops-infra-subagent |
| 6 | **tools-1** (NY) | Verktøysjef: finne/teste/integrere verktøy, skills-forfatting, roster-vedlikehold | Opus fast + Haiku-subagenter | gh CLI (repo-søk), MCP-registre, skill-creator, TOOLBOX-MOC, sandbox-testing |
| 7 | **data-1** | Brain-innhold: ingest-køer, distill-kvalitet, RAG-eval, Obsidian-graf, GPU-batch | Opus fast + GPU for bulk | obsidian MCP, yt-dlp-pipeline, brain-engineer/data-pipeline-subagenter |
| 8 | **admin-1** | EGET AS-regnskap, personlig, salg/call-center, ad-hoc | Haiku/Opus-mix | ClickUp/Gmail/Drive/ms365 MCP, PII-bindinger |

Kolonnemapping: col1 orch/infra-1 · col2 nexus-1/nexus-2 · col3 regnskap-1/tools-1 · col4 data-1/admin-1.

### regnskap-1 — strateginotat (hvorfor denne panen er nr. 4-prioritet)

- **Kundegrunnlaget:** 120 solgte AS-er/år hos Pål = 120 potensielle brukere av flyten
  aslisten-crm digitaliserer (stiftelse → dokumenter → godkjenning → regnskap). Hver
  forbedring i CRM-en skalerer over hele porteføljen hans.
- **Kommersialiseringstrapp:** (i) Pål-intern drift stabil → (ii) utvide til hele
  arbeidsflyten hans (purring/frister/MVA-varsler — gjenbruk policy-motor-tenkingen fra
  grossist-arkitekturen) → (iii) multi-tenant + lisens → selges til andre
  regnskapsførere. Grossist-plattformens pakker (policy, audit, db-tenancy, lisens) er
  byggeklosser her — derfor samme agent.
- **Relasjonslogikk:** plattformen gjør oss til Påls faste teknologipartner («med den
  platformen har vi han når som helst framover» — operatør). Alt Pål ber om ruter orch
  til regnskap-1 med topp-prioritet.
- **Gates:** kundedata/PII aldri på leid GPU eller i eksterne tjenester; prod-deploys og
  DB-migreringer operatør-gated; Pål-synlige endringer verifiseres i prod før ferdig.

**Rutingprotokoll (firm-bus, uendret transport):** operatør snakker primært med orch.
orch skriver strukturert dispatch til `inbox/<pane>.md` (mål, kontrakt, ferdig-definisjon,
modell-/subagent-budsjett), panen svarer med feed-linje + inbox-kvittering. CHARTER
består: én eier per fil/pakke, eksplisitte pather, OK kjør-gate, feed append-only.
Hver pane har GOALS.md (ETT aktivt mål).

## 3. Modell- og token-økonomi (eskaleringsstige)

1. **GPU qwen3/bge-m3** (marginalkost ~0): bulk-klassifisering, førsteutkast, sammendrag,
   embeddings — KUN ikke-PII (memory.db/samtaler/AS-/CRM-kundedata aldri på leid GPU).
2. **Haiku 4.5**: mekaniske subagenter (ekstraksjon, formatering, fixtures, sveip).
3. **Opus 4.8 fast**: standard kodearbeid i spesialist-panene.
4. **Fable 5**: orch, arkitektur, penge-/risikobeslutninger, adversarial verify.

Regler: subagenter (opptil 10 per pane) arver minimal kontekst; workflows med
effort-differensiering; prompt-caching alltid; eskaler kun ved målbart kvalitetstap.

## 4. GPU-ROI live i plattformen

- **Collector** (infra-1): systemd-timer → caddy-access-log + ollama-log hver time →
  `gpu_requests` i command-center.db (ts, klientklasse, endpoint, modell, token-estimat).
- **Verdimodell**: request prises mot API-ekvivalent (8b→Haiku-pris, 30b→Sonnet-pris,
  bge-m3→embedding-pris) → «spart $» vs $0.369/t → netto ROI + break-even-grad, 7/30d.
- **Flater**: dashboard-side i command-center + daglig morgenbrief-linje + BRAIN-VARSEL
  m/ pause-anbefaling hvis 7d-ROI < 0.5× break-even (report-only, operatør beslutter).

## 5. Obsidian som aktiv hjerne × GPU

- **Nightly GPU-batch** (data-1): ikke-PII-strømmer (youtube, github, tool-docs, arkivert
  thesis) → qwen3:30b førsteutkast, Haiku-stikkprøver → lavere Anthropic-kost, høyere
  GPU-utnyttelse (synlig i ROI-panelet).
- **Brain-gartner** (ukentlig, data-1): MOC-refresh, lenkegraf-hull, stale-flagging,
  arkivering.
- **Grense**: distill av samtaledata forblir Anthropic/lokalt.

## 6. tools-1 — kontinuerlig verktøyjakt

Loop: gh-søk etter MCP/CLI/skills relevante for aktive GOALS → sandbox-test → skill +
TOOLBOX-MOC + tools-roster → ukentlig revisjonslinje i feed. Eier totaloversikten over
gh/railway/vast/wrangler/yt-dlp/pipx-flåten i én kanonisk inventarfil. Verktøy med brede
rettigheter fortsatt operatør-gated.

## 7. Nye prosjekter — konvensjon

`_bin/new-project.sh <navn>` (infra-1): `~/code/<navn>/` + CLAUDE.md + GOALS.md + docs/ +
memory-fil + Obsidian-mappe + rad i workspace-CLAUDE.md + projects.ts + launcher-mapping.
Ingen prosjekter uten registrering.

## 8. Kontinuerlig forbedring

Ukentlig retro-workflow (orch): token-kost, feil, manglende skills → to do-er til
tools-1/infra-1. Gjentatte prosedyrer → skills. Lærdommer → memory. CURRENT-STATE +
GOALS-sync i hver pane-bootstrap.

## 9. Utrullingsfaser

- **F1 Omrigging** (infra-1 + orch): launcher v3 (nye roller, inbox-migrering,
  sesjonskontinuitet), CHARTER v2, GOALS per pane, arkivering thesis/søking.
- **F2 GPU-ROI** (infra-1 + frontend-subagent): collector + dashboard + morgenbrief.
- **F3 Verktøysrevisjon** (tools-1): førstegangs-sweep → TOOLBOX v2.
- **F4 Brain×GPU** (data-1): nightly ikke-PII-batch + brain-gartner.
- **F5 Måling** (orch): retro-loop + 30-dagers GPU-verdikt.

## 10. Avklaringer før F1

1. Nye rollenavn krever migrering av inboxes/locks/sesjoner — anbefaler ja m/script. OK?
2. Salg/call-center under admin-1, eller egen fokus-launcher som før?
3. Codex-gridden: speile de nye 8 rollene, eller beholdes?
4. Master/søking: ren arkivering, eller holde noe varmt (onboarding ny jobb)?

— code-2 (påtroppende orch), 2026-07-27 rev 2
