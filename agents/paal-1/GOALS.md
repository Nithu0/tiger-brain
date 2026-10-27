# paal-1 — GOALS

## Aktivt mål (trapp-trinn 1: stabil intern drift hos Pål)

Få aslisten-crm i daglig reell bruk hos Pål: han kjører ekte saker gjennom plattformen
og admin-tiden per AS-salg faller målbart.

### Done-kriterier
- [ ] Pål har testet hele løpet selv på live-demoen og gitt tilbakemelding
- [ ] Påls 4 ekte Word-maler lastet opp i malregisteret (/maler) og verifisert
- [ ] E-postleverandør avklart → innboks-mottak koblet på /api/inbound
- [ ] Første EKTE sak kjørt ende-til-ende (henvendelse → skjema → dokumenter → godkjenning → Brønnøysund → fullført)
- [ ] Hosting-beslutning tatt (Railway vs lokal PC m/named tunnel — docs/lokal-drift.md)

### Neste trinn (låst opp av avklaringer)
Purre-/frist-/MVA-varselmodul (gjenbruk policy-motor-designet fra grossist-arkitekturen) →
WooCommerce-webhook (butikkordre → sak) → signeringsadapter → standardisering (trinn 3).

## Sekundært
- Grossist-plattform: pakkene er bygget (lisens, db, policy, audit, m365, gateway, update);
  venter på Per-kartlegging/gjenopptak. Ikke aktiv bygging nå.
- RefiPrep: forretningssiden i dvale til operatør reaktiverer.

Oppdatert 2026-07-27 — paal-1 (etablert fra as-1 per FIRM v2 F1).
