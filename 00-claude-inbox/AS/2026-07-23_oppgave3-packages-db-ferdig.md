# Oppgave 3 FERDIG — packages/db (grossist-plattform)

Fra: code-2 · 2026-07-23 · Kun syntetiske data, ingen PII, ingen secrets.

## Levert

`~/code/grossist-plattform/packages/db/` (@grossist/db) — DB-laget per brief oppgave 3
og låste valg i arkitekturrapporten (separate Postgres-DBer per selskap, ikke RLS):

- **Migrasjonsloop**: to sett (`migrations/platform/`, `migrations/company/`);
  company-settet kjøres i loop mot N selskaps-DBer. Idempotent, sha256-sjekksum med
  TOVEIS drift-deteksjon (endret OG slettet fil), advisory-lock-serialisering,
  transaksjon per fil, `CREATE DATABASE` ved behov.
- **Tenant-kontekst i tre lag**:
  1. Kompilator: branded `TenantContext` — objekt-literals/strenger/PlatformContext
     avvises av tsc (bevist av `test/type-enforcement.ts` som kjøres som test).
  2. Runtime: `forTenant()` godtar kun kontekster utstedt av instansens egen
     `TenantRegistry.resolve()` (WeakSet) — deep-import-forfalskning kastes ut.
  3. Fysisk: hvert selskap egen DB; repo-spørringer KAN ikke nå annen tenant.
- **Repository-lag**: customers/orders/invoices v0 + tenant-scopet query-escape-hatch.
  Ordre-utkast med idempotensnøkkel (trusselmodell #7) + payload-fingerprint —
  gjenbrukt nøkkel med annen payload gir hard feil, aldri feil kundes ordre.
- **Rolle-herding**: `provisionCompanyRole()` gir rollen CONNECT på KUN egen DB og
  revokerer PUBLIC på platform/postgres/alle selskaps-DBer; `provisionCompany()`
  låser nye DBer fra fødselen. Reserverte navn (postgres/platform/template*) avvises.

## Verifisering

- **22/22 tester grønne** (11 unit, 1 kompilator-bevis, 10 integrasjon mot engangs
  Docker-Postgres 17): cross-tenant umulig på app-nivå OG rollenivå (inkl. at
  selskapsrolle nektes platform- og postgres-DB), forfalsket kontekst avvist,
  idempotens-konflikt kastet, drift begge veier, migrasjonsloop idempotent.
- Lint clean, pakke-bygg + rot-`tsc -b` grønt.
- Code-review (workflow, 31 agenter): 10 CONFIRMED funn — **alle 10 fikset** (bl.a.
  poolManager-escape-hatch fjernet, ssl:true nedgraderte stille TLS-verifisering,
  herding var opt-in og dekket ikke platform/postgres, énveis drift-sjekk,
  IT-flagg som kunne grønn-skippe cross-tenant-beviset i CI). +3 av de kappede
  småfunnene (escapeLiteral-hack, rolle-race, dobbel platform-migrering).

## Forbehold

- Docker Desktop var nede ved siste kontroll (samme runde som GPU?): siste
  re-kjøring av gjenbruks-modus (to fulle kjøringer mot samme vedvarende server
  etter harness-fiksen) gjenstår. Design er gjort kjøre-idempotent (unike
  selskaps-IDer per run). Én `pnpm --filter @grossist/db test` når Docker er oppe
  bekrefter.
- Repoet er ikke git-initialisert (fase 0-eier) — ingenting committet/pushet.
- Domain-pakken (oppgave 2) fantes ikke ved bygging; radtypene i repository-laget
  er bevisst v0-lokale og byttes til @grossist/domain-typer når den lander.

## Tillegg 2026-07-27T19:12:34Z

Docker-utfallet loest (wedged Docker Desktop-backend siden 21.07 — engine-VM Stopped mens prosessene levde; ren restart fikset). Gjenbruks-forbeholdet er LUKKET: to fulle integrasjonskjoeringer mot samme vedvarende Postgres, begge 10/10 groenne. Full suite 22/22. Repo-compose (dev-baseline, kun postgres; api/web bak profil "full") startet igjen; gamle grossist-platform_*-volumer ikke roert.
