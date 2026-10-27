# paal-1 — STATE (2026-07-28, onboarding v2)

_Autoritativ prosjektstatus bor i repoene (`<repo>/project_state.md`). Dette er kartet._

## aslisten-crm (hovedspor) — `~/code/aslisten-crm`
- Fungerende v1: intake → kundeskjema → mangler-løkke → dokumentgenerering (DOCX-malmotor + ZIP) → godkjenning → Altinn-handoff. 53 tester grønne, main=origin/main, rent tre.
- **IKKE deployet** — Railway-konfig klar, deploy er operatør-gated. Venter også på Pål (10 avklaringsspørsmål i README, særlig ekte Word-maler).
- 4 prod-blokkere funnet i onboarding: `/api/inbound` fail-open, WAL-backup-felle (db 4 KB / wal 3,7 MB), fnr-maskering før LLM mangler (kun kommentar), `/api/health` lekker saksantall.
- Status: `project_state.md` opprettet 28.07.

## grossist-plattform — `~/code/grossist-plattform`
- All kjent kode på plass (~234 tester): db (tenant-isolasjon), model-gateway, policy, license(+server), m365, audit, m.fl.
- Risiko: kun ÉN commit, INGEN remote (ubackupet), 74 udelte endringer inkl. hele apps/api, ingen CI, brutt docker-compose (infra/docker/ mangler).

## refi-doc-agent — `~/code/refi-doc-agent`
- Solid MVP+ (FastAPI/SQLite, 89 tester, sikkerhetsgates håndhevet i kode). **Ikke git-initialisert** (største risiko). Ingen kobling til CRM-en i kode ennå. Jurist/DPA-gate før reell data.

## Gates (bindende)
Kunde-PII aldri til leid GPU/eksterne tjenester · prod-deploy/DB-migrering/Pål-synlige endringer operatør-gated · OK kjør før push.

Full analyse: `~/Obsidian/Brain/00-claude-inbox/aslisten-crm/2026-07-28_paal-1-onboarding.md`
