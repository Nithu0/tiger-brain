# paal-1 — Onboarding v2 (2026-07-28)

Fullstendig kartlegging av Pål-økosystemet per operatør-ordre (dispatch orchestrator-1 2026-07-28T15:03Z).
Metode: 4 parallelle Explore-agenter (aslisten-crm arkitektur + drift/PII, grossist-plattform, refi-doc-agent) + egen lesing av FIRM-V2-SPEC.md og ROLE-MAP.md.

## TL;DR

- **aslisten-crm er en fungerende v1** — hele hovedløkka (henvendelse → kundeskjema → mangler-løkke → dokumentgenerering → godkjenning → Altinn-handoff) er implementert og testet (53 tester, inkl. 21 fiendtlige scenarier). Kodebasen er bevisst minimal: ~3 100 linjer, Next.js 15 + SQLite, ingen ORM/kø/multi-tenancy.
- **Ingenting er deployet.** Railway-konfig og Dockerfile ligger klare, men ingen deploy er utført og ingen prod-URL finnes. Blokkeringen er dels operatør-gate (prod-deploy), dels svar fra Pål (10 avklaringsspørsmål i README, særlig hans ekte Word-maler).
- **4 prod-blokkere funnet** før pilot: (1) `/api/inbound` er fail-open uten `CRM_INBOUND_SECRET`, (2) WAL-backup-fella (crm.db 4 KB, crm.db-wal 3,7 MB — naiv kopi mister alt), (3) PII-løftet i `extract.ts` («fnr sendes ALDRI til LLM») er ikke håndhevet i kode, (4) `/api/health` lekker saksantall uautentisert.
- **grossist-plattform**: all kjent kode finnes og er testet (~234 tester), men kun én commit, ingen remote, ingen CI, brutt docker-compose, og hele `apps/api/` + mye annet ligger utracket. Backup-risiko.
- **refi-doc-agent**: solid MVP+ (FastAPI/SQLite, 89 tester, gjennomført sikkerhetsdesign) men **ikke engang git-initialisert**, og har i dag null kobling til aslisten-økosystemet.
- **Foreslått ETT aktivt mål**: gjøre aslisten-crm pilot-klar (herding av de 4 blokkerne + deploy-forslag til operatør + malpakke-flyt for Påls ekte maler).

---

## 1. aslisten-crm (hovedspor)

### 1.1 Stack og form

Next.js 15 (App Router, standalone-bygg) + React 19, better-sqlite3 rett mot `data/crm.db` (WAL), håndskrevet SQL med prepared statements, egen forover-migrator (`src/db/index.ts:22-39`, 2 migrasjoner, 11 tabeller). Docxtemplater+PizZip for DOCX, JSZip for dokumentpakke, zod for AI-uttrekk-validering. Vitest. Ingen ORM, ingen kø, én bruker (Pål). ~3 144 linjer TS/TSX/SQL, 14 commits (22.–27. juli), main = origin/main (github.com/Nithu0/aslisten-crm), rent tre, null TODO/FIXME i koden.

### 1.2 Datamodell (migrations/0001 + 0002)

`contacts` (person/virksomhet, tlf/e-post/adresse/fødselsdato) — `companies` (orgnr UNIQUE, brreg-roller/regnskapstall som JSON, `api_raw` rå respons) — `cases` (saksnr `AS-ÅÅÅÅ-NNNN`, 15-verdis status-CHECK, kjøper/selger, pris, skjema-token m/14d utløp, altinn-referanse) — `case_parties` (rolle + aksjer/eierandel før/etter) — `company_changes` (endringsønsker, alltid `approved=0` inntil manuell godkjenning) — `documents` (utkast/godkjent/signert, sha256, `locked`) — `messages` (kanal/retning/rå tekst/uttrekk) — `automation_runs` (full automatiseringslogg, 15 typer) — `approvals` — `tasks` — `doc_templates` (DOCX-malregister m/versjonering og case_type-filter).

### 1.3 Kjerneflyt og statusmaskin

Intake (`src/lib/cases.ts:140-259`): kanal → regex-uttrekk (valgfri Claude-forbedring bak `CRM_AI_EXTRACT`) → kontakt-match på tlf/e-post *kun ved navnetreff* (delt `post@byrå.no` blander ikke personer) → gjenbruk av aktiv sak eller ny → brreg-oppslag → `computeMissing()` → status.

```
NEW → WAITING_FOR_CUSTOMER (mangler) | NEEDS_REVIEW (komplett)
WAITING_FOR_CUSTOMER → (skjema komplett) WAITING_FOR_APPROVAL → (godkjent) READY_FOR_ALTINN → SUBMITTED_TO_ALTINN → COMPLETED
                                                              → (avvist) NEEDS_REVIEW
```

To låser: saker forbi skjemastadiet nedgraderes aldri (ny kundemelding bare logges; skjema-innsending → 409), og gamle nettleserfaner kan ikke sette en fremskreden sak tilbake (PRE_FORM-guard). 7 av 15 statuser (bl.a. WAITING_FOR_SIGNATURE, REGISTERED) er forberedt i skjemaet men settes ikke av noen kodesti ennå.

Dokumentproduksjon: `generateDocuments()` (`src/lib/documents.ts`) — låste dokumenter blokkerer ALL regenerering; opplastede DOCX-maler (docxtemplater m/egendefinert parser for `{{company.name}}`-stier, `[MANGLER: felt]`-nullGetter, XML-tag-stripping før variabeluttrekk) med fallback til 4 innebygde HTML-maler; sha256 + generasjonssuffiks; krysskontroll av `[MANGLER]` + orgnr-konsistens på tvers av dokumenter; ZIP-pakke per sak; maladmin på `/maler` m/testdokument-generering.

### 1.4 Tester

53 tester / 3 filer, alle mot temp-DB + mocket brreg: 20 realistiske scenarier, 21 fiendtlige (XSS, SQL-i-tekst, prompt injection, ugyldige/utløpte tokens, statusnedgradering, 100k-tegns melding, unicode), 5 regresjoner (fra feiljakt-committen `457d412`), 1 DOCX-ende-til-ende. Hull: ingen tester på React-komponenter, server actions (godkjenn/avvis/Altinn), middleware/auth eller ZIP-ruten. Ingen E2E.

### 1.5 Drift og deploy — status: IKKE deployet

To dokumenterte spor (README/docs/lokal-drift.md): (A) lokalt hos Pål m/named tunnel mot `skjema.aslisten.no`, (B) Railway (Dockerfile node:22-slim, `railway.json` m/healthcheck `/api/health`, volum `/data`, EU). Ingen CI, ingen `.github/`, aldri prod-bygget. Auth: HTTP Basic (fail-closed 503 i prod uten creds); kundeskjema unntatt bak engangs-token (24 random bytes, 14d); `/api/inbound` bak delt hemmelighet. Kundeflate/admin skilt i route-grupper + separate layouts. Ingen e-post/SMS/WhatsApp-utsending — Pål kopierer meldingsmal manuelt (CopyMessage).

### 1.6 PII-flater og funn (viktigst)

Lagres: navn, tlf, e-post, adresse, **fødselsdato** (ikke fnr — skjemaet ber eksplisitt ikke om det), kjøpesum, rå meldingstekst, rå brreg-responser (inkl. rollehaveres fødselsdato i `companies.api_raw`), genererte dokumenter på disk (`data/documents/…` — 10 saksmapper ligger der nå). Eksterne tjenester: data.brreg.no (kun orgnr ut), api.anthropic.com (bak flagg, av som default), tunnel-leverandør (ser trafikk i TLS-terminering).

**Prod-blokkere (funn fra denne kartleggingen):**
1. **`/api/inbound` fail-open** (`app/api/inbound/route.ts:11`): tom `CRM_INBOUND_SECRET` → endepunktet helt åpent (hvem som helst kan opprette saker + trigge brreg/Anthropic-kall). Motsatt konvensjon av middleware. → gjør fail-closed.
2. **WAL-backup-fella**: `data/crm.db` er 4 KB, `crm.db-wal` 3,7 MB — WAL sjekkpunktes aldri; naiv kopi av crm.db mister praktisk talt alle data. → checkpoint-rutine + backup-script.
3. **PII-løfte ikke håndhevet**: kommentar i `src/lib/extract.ts:6` sier fnr aldri sendes til LLM, men det finnes ingen maskering — første 5000 tegn rå kundetekst går ordrett til Anthropic når flagget er på. → fnr-regex-redaksjon før API-kall (11 siffer m/D-nummer-varianter).
4. **`/api/health` lekker saksantall** uautentisert. → returnér `{ok:true}` uten telling.
   I tillegg: ingen rate limiting på åpne endepunkter, ingen GDPR-sletting/arkivering (bevisst utsatt, men må inn før reell drift), Basic auth skal per docs byttes til ordentlig auth m/2FA før produksjon.

### 1.7 Åpne avhengigheter på Pål

10 avklaringsspørsmål i README venter på svar — kritisk: hans faktiske Word-maler (malmotoren er klar for dem), domenevalg (crm/skjema.aslisten.no), hostingvalg.

---

## 2. grossist-plattform (rask oversikt)

pnpm-monorepo, ~234 tester over 30 filer. Leveranser verifisert på plass: `packages/db` (tenant-isolasjon via database-per-selskap + branded contexts, 15 tester), `model-gateway` (81), `policy` (65), `license` + `infra/license-server` (13+4), `connectors/m365` (19), `visma-global`, `audit`, `mcp-tools`, `update-client`, `infra/backup`, tynn `apps/web`, `apps/api` (Fastify, healthz, **ingen tester, helt utracket**).

**Risiko/hull:** kun ÉN commit (`cfe8080`), **ingen remote** → alt fra flere agenters arbeid ligger ubackupet lokalt; 74 udelte endringer i treet (inkl. hele apps/api, audit-kildekode, docker-compose.yml); `.gitignore` mangler `.next/`; **ingen CI**; docker-compose refererer `infra/docker/*` som ikke finnes (kun postgres kan kjøre); root-README 6 linjer; arkitekturspec ligger utenfor repoet; healthz-portmismatch update-client (3000) vs api (3001). Neste naturlige trekk: commit av utracket kode + .gitignore-fiks (lokalt), remote-opprettelse + push er operatør-gated.

## 3. refi-doc-agent (rask oversikt)

Norsk dokumentflyt-verktøy for refinansieringssaker (partner = behandlingsansvarlig, appen = databehandler). Python 3.11/FastAPI/SQLite/htmx, ~5 000 linjer, 89 tester. Sikkerhetsdesign håndhevet i kode: talluttrekk deterministisk (aldri LLM), `REFI_ALLOW_REAL_DATA=0` default (403 på opplasting), `LLM_BACKEND=off` default (null egress), Fernet-kryptering, append-only audit.

**Risiko/hull:** **ikke git-initialisert** (null historikk/backup — største hull), bank-profiler er uverifiserte plassholdere, default modell-ID `claude-opus-4-8` er ugyldig og feiler ved `LLM_BACKEND=anthropic`, README-arkitekturtre utdatert, jurist/DPA/DPIA-forutsetninger uoppfylt før reell data. Ingen kobling til aslisten-crm/RefiPrep i kode eller docs i dag — koblingen er kun konseptuell (samme kundeøkosystem).

---

## 4. PRODUKTKART — Påls virksomhet

Kontekst: Pål solgte ~120 AS-er i fjor. Trapp per FIRM-V2-SPEC: stabil intern drift → utvide funksjonalitet → standardisere → multi-tenant kommersielt.

### (a) Dekket av CRM-en i dag
- Henvendelse-intake fra alle kanaler (manuelt lim-inn + `/api/inbound`-kontrakt), automatisk uttrekk + brreg-berikelse, mangel-beregning
- Kundeskjema med token-lenke, forhåndsutfylling, rød-markering av mangler
- Sak-livssyklus m/statusmaskin, godkjenningsgate (ingenting auto-godkjennes), oppgave-KPI, søk
- Dokumentproduksjon: DOCX-malmotor m/versjonering + 4 innebygde maler, låsing av godkjente dokumenter, ZIP-pakke, krysskontroll
- Altinn-handoff m/dyplenke og referansesporing (bevisst ikke API — Altinn tilbyr ikke innsendings-API for dette)

### (b) Neste utvidelser (prioritert)
1. **Pilot-herding** (funn 1.6) + deploy — forutsetning for alt annet.
2. **Påls ekte maler inn** i malmotoren (motoren klar; venter på filene).
3. **Purringer/frister**: `tasks`/`next_deadline` finnes i datamodellen men ingen påminnelsesmotor. Gjenbruk policy-motor-designet fra grossist (`packages/policy` — dunning/action-levels er allerede bygget og testet der) som mønster for en enkel frist-/purrejobb: kunde som ikke har svart på skjema etter N dager, saker med passert `next_deadline`, MVA-/Altinn-frister.
4. **Kanaladaptere** på `/api/inbound` (e-post først, WhatsApp senere) — kontrakten finnes.
5. **Signering** (WAITING_FOR_SIGNATURE-statusen er forberedt) og **arkivering/GDPR-sletting**.
6. **refi-doc-agent som søsterprodukt** mot samme kundemasse (dokumentinnsamling/mangelliste er samme mønster som CRM-ens mangler-løkke) — men først git-init + jurist-gate.

### (c) Multi-tenant-krav (kommersialiseringstrappen)
- **Tenant-isolasjon**: grossist-plattformens `packages/db`-modell (database-per-selskap + tvungen tenant-kontekst i typesystem+runtime) er fasiten; aslisten-crm er i dag én-tenant SQLite — riktig valg nå, men datamodellen bør holdes fri for antagelser om «én Pål» (f.eks. `assigned_to` default 'Pål').
- **Ordentlig auth** (multi-bruker, roller, 2FA) — Basic auth er eksplisitt midlertidig.
- **Maler per tenant** — `doc_templates` har allerede versjonering + scoping-mønster som generaliserer.
- **Audit** — `automation_runs` er en god start; grossist `packages/audit` (hash-kjedet) er oppgraderingsstien.
- **PII-gates**: kundedata ALDRI til leid GPU/eksterne tjenester (bindende); LLM-maskering må være kode, ikke kommentar, før noe multi-tenant.

---

## 5. Foreslått ETT aktivt mål (til GOALS.md)

**«Pilot-klar aslisten-crm»**: fiks de 4 prod-blokkerne (inbound fail-closed, WAL-checkpoint/backup, fnr-maskering før LLM, health-lekkasje) + legg fram deploy-forslag (Railway vs. lokal+named tunnel) for operatør. Ferdig = blokkerne fikset m/tester, deploy-beslutning forelagt operatør (selve deployen er operatør-gated), malpakke-flyt klar for Påls ekte maler.

Begrunnelse: alt i trappa (utvidelse → standardisering → multi-tenant) står bak «stabil intern drift hos Pål», og de fire funnene er konkrete, små og testbare.

## 6. Sekundært (ikke aktivt mål, men bør ikke glemmes)
- grossist: commit utracket kode + .gitignore-fiks lokalt; be operatør om remote (backup-risiko er reell).
- refi-doc-agent: `git init` + første commit (ren staging à la soking-1s sjekkliste) — lav innsats, fjerner største risiko.
- aslisten-crm: opprett `project_state.md` (gjort i denne onboardingen) og hold den autoritativ per FIRM-V2-SPEC §0.3.

---
*Kilder: 4 Explore-agentrapporter 2026-07-28 (aslisten-arkitektur, aslisten-drift/PII, grossist, refi) + FIRM-V2-SPEC.md rev A + ROLE-MAP.md. Ingen .env-verdier lest. Ingen push utført.*
