# Oppgave 7 — packages/audit

## Levert

- @grossist/audit med tenant-bundet PostgresAuditLog; companyId kommer fra
  TenantDb.ctx, ikke fra event-input.
- PostgreSQL-migrasjon med audit.chain_head singleton, audit.events, pgcrypto
  SHA-256, idempotensnøkkel og atomisk SELECT FOR UPDATE append-funksjon.
- ENABLE ALWAYS statement-trigger som avviser UPDATE, DELETE og TRUNCATE, i
  tillegg til revokerte runtime-mutasjonsprivilegier.
- Verifier som kontrollerer sekvenshull, canonical JSON, dokumentkolonner,
  predecessor-hash, event-hash, database-head og ekstern checkpoint.
- audit verify --company ... [--json] [--expected-head ...].
- Enhetstester for gyldig kjede, manipulert payload, manglende rad, ukjent
  versjon, head/checkpoint og ugyldig JSON.
- Docker-Postgres-test for parallell append, idempotens, mutasjonsvern og
  manipulasjonsdeteksjon.

## Verifisering

- corepack pnpm --filter @grossist/audit run build — grønn.
- corepack pnpm --filter @grossist/audit run test:unit — 6/6 grønn.
- corepack pnpm exec eslint packages/audit/src packages/audit/test — grønn.
- corepack pnpm build — grønn.
- corepack pnpm test — 230 tester grønne; 13 eksisterende DB-tester og
  3 audit-Postgres-tester ble hoppet over uten Docker.
- Eksplisitt test:integration forsøkt med Docker-tilgang, men Docker-daemonen
  finnes ikke på maskinen. Integrasjonen er derfor ikke erklært
  runtime-verifisert.
- Full workspace-lint feiler i eksisterende .next parser-problemer og
  packages/db/test/type-enforcement.ts; audit-filer lintes separat grønt.

## Handoff

packages/db må inkludere packages/audit/migrations/0001_audit_log.sql i
company-migrasjonssettet før tenant-provisionering forventes å opprette
audit-tabellene automatisk. Ingen andre agenters pakker ble endret med vilje.
