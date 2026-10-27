---
tags: [AS, grossist-plattform, leveranse]
type: session-report
created: 2026-07-21
author: as-1 (Claude)
---

# Grossist-plattform — leveranselogg 21.07.2026

Kontekst: masterprompt fra operatør (lokal AI-adminplattform for SMB-grossister; pilot
Per med to AS på én server; Pål = autorisert regnskapsfaglig kontroll). Demo skulle være
klar til Pål-møtet 22.07. Ingen kundedata/PII i denne noten.

## Levert (committet i AS-repoet, f98986b)

- **Konsept-demo** `AS/grossist-demo/index.html` — offline, én HTML-fil, syntetiske data.
  4 scenarioer (rutineordre nivå 3, avvik→nivå 4, reklamasjon m/purre-hold, prompt
  injection→karantene), purrerutine etter 2026-reglene, to adskilte selskaper, Påls
  kontrollgrunnlag, revisjonslogg, nullstill-knapp. Manus: `demo-manus.md`.
- **Arkitekturrapport** `AS/docs/grossist-nisje/2026-07-21-plattform-arkitektur.md` —
  8 web-verifiserte seksjoner: arkitektur/dataflyt (mermaid), stack (TS/Fastify, Next
  standalone, Postgres per selskap, pg-boss, Caddy, Authelia, sops/age, restic), MVP
  ~32 uker kveldstid, trusselmodell, hardware (~12–13k pilot + UPS/backup, driftskost
  normal ~2 650 kr/mnd), Visma Global (BAPI/partner — IKKE REST; produkt i
  vedlikeholdsmodus), Altinn/Maskinporten (MVA-innsending krever personlig ID-porten →
  innsending hos Pål), lisens (ed25519 offline-fil) + signert oppdatering,
  beslutningsliste (§11).
- **Intervju-delta**: Per-guiden fikk A–G (Visma/Power BI/lager/M365/nettverk/to-AS/
  backup), Pål-guiden fikk H–M (kontrollgrunnlag som kravspec, hans nivå 4-liste,
  feilhåndtering, tilgang, standardisering, prising).
- **Agent-utsending**: 14 briefs (`agent-oppgaver-plattform.md`) distribuert til
  firm-bus-inboksene (codex-1..8, code-1/2, ai-1/2, thesis-1, soking-1). Kritisk sti:
  codex-6 → fase 0 repo-skjelett.

## Kvalitetssikring

- Ultracode code-review (25 agenter, høy innsats): 10 bekreftede funn, alle fikset
  (tenant-lås i scenarioer, dynamisk purre-narrasjon, inkasso-duplikatvern,
  selskapsbytte-sperre under animasjon, toast-timer, tellerfiks). Re-verifisert i
  Playwright: 0 konsollfeil, alle flyter grønne.
- Sikkerhetssjekk manuelt (security-review-skillet krasjet på manglende remote):
  ingen eksterne ressurskall, ingen PII, ingen ekte navn i demoen.

## Infrastruktur-beslutninger (bekreftet av operatør 21.07 kveld)

- **GitHub**: all plattformkode i privat repo `Nithu0/grossist-plattform` (opprettet,
  tomt). AS-repoet forblir lokalt (PII — pushes aldri).
- **Docker**: compose er pakkeformatet fra fase 0; CI (Actions) → signerte images ved
  første push. Push-gate («OK kjør») gjelder fortsatt alle paner.
- **Obsidian**: leveranselogger som denne legges i `00-claude-inbox/AS/`.

## Neste

1. Per-møte i kveld (systemkartlegging m/delta A–G) → svar inn i guiden.
2. Pål-møte 22.07 (demo + H–M) → 5-linjers oppsummering fra Per-møtet tas med.
3. Visma-partner-avklaring (styrer fase 6).
4. Agentene bygger fase 0 → kategori 2–4 per avhengighetskartet i briefs-dokumentet.
