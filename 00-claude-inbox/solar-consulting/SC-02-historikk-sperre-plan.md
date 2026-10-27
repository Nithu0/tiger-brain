# SC-02 — plan for å åpne historikk-sperren

paal-1, 2026-10-18. Beslutningen planen tjener: skal `awards-backfill` få bygge tildelinger fra de
33 729 kunngjøringene historikk-backfillen (SC-01) hentet inn, slik at gjenutlysningsradaren kan
svare på «hvilke IT-kontrakter kommer ut de neste 12 månedene»?

**Grunnlag:** `FACT` for en lokal kopi av prod, hentet med read-only `pg_dump` 2026-10-18 00:35
(tenders, lots, raw_notices, buyers, suppliers, awards, award_merges; ingen brukere). Kopien er
lastet inn i en engangs-PostgreSQL 18.6 med migrert skjema fra main. Koden er grenen
`sc-02-historikk-sperre` (48e21b2, ikke pushet). Tallene sier hva koden gjør med prod-dataene,
ikke hva som har skjedd i prod.

## 1. Hva som trengs før env-endringen

I dag er sperren en konstant i koden (`AWARDS_INCLUDE_HISTORY = false`), og
`AWARDS_HISTORY_MAX_PER_RUN` brukes ikke. **En env-endring alene gjør ingenting.** PR-en på
`sc-02-historikk-sperre` må merges først:

- `AWARDS_INCLUDE_HISTORY=true|1` åpner sperren. Er variabelen ikke satt, er sperren lukket som før,
  så den kan lukkes igjen uten ny kode.
- `AWARDS_HISTORY_MAX_PER_RUN` er taket per kjøring (standard 2000). Historiske anskaffelser
  plukkes med nyeste resultatkunngjøring først, og bare de som har vinner, men ingen tildeling ennå.
- `npm run awards:historikk-tilbake` er tørrkjøring som standard. `--apply` arkiverer hver
  historikk-tildeling i `award-merges` (snapshot) og sletter den.
- Tester: 21 grønne i de berørte filene, tsc 0. Full suite og PR venter på Actions (fakturering).

## 2. Anslag (målt på kopien)

| | Tall |
|---|---|
| Én natt (`MAX_PER_RUN=2000`, apply på) | 280 s, 2 000 historiske anskaffelser, **5 411 nye tildelinger**, 1 990 nye leverandører |
| Hele historikken på én gang | 1 042 s (17 min), 13 792 historiske anskaffelser, **22 229 nye** (totalt 27 638 med første natt) |
| Tildelinger etter full historikk | **28 025** (fra 387) |
| …med contractEnd | 2 874 (10,3 %), hvorav 2 680 `FACT_DATE` |
| …med verdi | 21 476 (76,6 %), men se forbehold 3 |
| Dedup på historikken | 2 arkivert. Doffin- og TED-kopien slås sammen i planleggingen, så det oppstår nesten ingen dubletter |
| Nye leverandører | 6 778, mange uten org.nr. (TED-navn) |

Med tak 2000 tar det 7 netter. Hele historikken på én gang tar 17 minutter, så taket er en
sikkerhetsmargin og ikke en nødvendighet.

## 3. Radaren etter full historikk (kopien, `radar-expiry` 2026-10-18)

**9 535 gjenutlysninger innen 12 måneder, hvorav 1 538 IT: 88 høy sikkerhet, 2 middels, 1 448 lav.**

Topp 20 IT etter viktighet:

| # | Kontrakt | Oppdragsgiver | Slutt | Forventet utlysning | Verdi (NOK) | Nåværende leverandør(er) |
|---|---|---|---|---|---|---|
| 1 | Rammeavtale IT-konsulenttjenester 2024 | Husbanken | 2024-09 | 2024-03 | 3 000 000 000 | Bekk, Bouvet m.fl. |
| 2 | Kompetansepartner sky, Sykehuspartner | Sykehusinnkjøp HF | 2024-12 | 2024-06 | 320 000 000 | Accenture |
| 3 | Automatikk og feltutstyr for BAS | NTNU | 2025-03 | 2024-09 | 140 000 000 | Schneider Electric, Bravida |
| 4 | Forhandler av programvare | Sikt | 2025-07 | 2025-01 | 320 000 000 | Atea |
| 5 | Kjøp og sikker avhending av IT-infrastruktur | Norsk nukleær dekommisjonering | 2026-02 | 2025-08 | 200 000 000 | Move AS |
| 6 | Lisenspartner | Rogaland fylkeskommune | 2026-02 | 2025-08 | 220 000 000 | Crayon |
| 7 | Rammeavtale ny serverinfrastruktur | Skatteetaten | 2026-03 | 2025-09 | 130 000 000 | Proact IT Norge |
| 8 | Konsulentbistand innen IKT | DSB | 2026-03 | 2025-09 | 1 560 000 000 | Crayon, IT Consult, Alv, Holte m.fl. |
| 9 | Prosjekt- og prosjekteringsledelse | Oslo kommune, Boligbygg | 2026-04 | 2025-10 | 187 200 000 | Sweco, AFRY, Novaform |
| 10 | IKT-utstyr 2024 | Alta kommune | 2026-05 | 2025-11 | 250 000 000 | Eltele |
| 11 | Lisenser og lisensforvaltning | Viken Vest Innkjøpssamarbeid | 2026-06 | 2025-12 | 268 000 000 | Crayon |
| 12 | Rådgivningstjenester eiendom | Politiets fellestjenester | 2026-06 | 2025-12 | 800 000 000 | Sweco, Norconsult, AFRY |
| 13 | IT-utstyr og tjenester | Stiftelsen Tradebroker | 2026-06 | 2025-12 | ukjent | Dustin |
| 14 | Sikkerhetstesting, rammeavtale | Bærum kommune | 2026-09 | 2026-03 | 200 000 000 | Mnemonic, Netsecurity, Kovert, Defendable |
| 15 | Sikkerhetsovervåking (SOC) | Gjøvik kommune | 2026-09 | 2026-03 | 500 000 000 | Defendable |
| 16 | TEK-konsulent, rammeavtale | Avinor | 2026-12 | 2026-06 | ukjent | Ework, Netcompany |
| 17 | Microsoft lisensforhandler | Oslo kommune, UKE | 2027-05 | 2026-11 | 640 000 000 | Crayon |
| 18 | Digitale læremidler til skoler | Karmøy kommune | 2026-06 | 2025-12 | 70 000 000 | Skolon |
| 19 | IT-konsulenter innen prosessforbedring | Vestland fylkeskommune | 2026-09 | 2026-03 | ukjent | Avo Consulting |
| 20 | IT-konsulenter innen utviklingstjenester | Vestland fylkeskommune | 2026-10 | 2026-04 | 36 000 000 | Atea, Bouvet |

Alle 20 har høy sikkerhet (`FACT`: oppgitt sluttdato i kunngjøringen) og kilde per rad i radaren.

## 4. Forbehold (si fra før dette brukes kommersielt)

1. **Verdiene er ofte rammeavtale-tak, ikke kontraktsverdi.** Husbanken på 3 mrd. og DSB på 1,56
   mrd. er tak. `importance` vekter verdi (log-skala), så tak løfter rader opp i lista. Forslag:
   merk tak-verdier (`valueKind`) og dem dem ned i `importance`. Den endringen er ikke gjort.
2. **IT-filteret slipper inn ikke-IT.** #9 (prosjekteringsledelse) og #12 (rådgivning eiendom)
   har CPV 72 eller 48 et sted i kunngjøringen. `isItCpv` ser på CPV-prefiks alene. Forslag: krev
   IT som hoved-CPV, eller bruk scope-kategorien fra SC-04.
3. **Kontrakter som har passert sluttdato, står fortsatt i lista** (#1–#4, slutt 2024–2025). Det
   skjer fordi en oppgitt fornyelse gir +24 mnd (`ASSUMPTION`) i vinduet. De kan være forlenget,
   allerede utlyst på nytt eller avsluttet. Sjekk mot Doffin før noen handler på dem.
4. **contractEnd er bare 10 % for historikken.** De fleste historiske notisene oppgir varighet, men
   mangler signeringsdato i det vi lagrer, og TED-historikken har ingen datoer. 1 448 av 1 538
   IT-rader er derfor `ASSUMPTION`/lav sikkerhet.
5. **Brreg-køen vokser.** 6 778 nye leverandører, mange uten org.nr. `supplier-brreg-match` tar 200
   per natt, så det tar uker. Kontrollkøen kan bli lang.

## 5. Tilbakerulling (testet på kopien)

`npm run awards:historikk-tilbake` (tørrkjøring) fant 27 638. `--apply` arkiverte og slettet alle
på 30 min. Basen var tilbake på **387 tildelinger (384 med nøkkel)**, nøyaktig som før.
`award-merges` fikk 27 638 nye `remove`-rader med snapshot, så tilbakerullingen kan selv
reverseres. Leverandørene historikken opprettet, blir liggende med `wins = 0`. De er harmløse og
kan ryddes senere.

Rekkefølge ved tilbakerulling i prod: lukk sperren først (fjern `AWARDS_INCLUDE_HISTORY`), deretter
`-- --apply`. Ellers bygger nattkjøringen radene opp igjen.

## 6. Forslag til rekkefølge

1. Merge PR-en `sc-02-historikk-sperre` (venter på Actions/fakturering).
2. `AWARDS_INCLUDE_HISTORY=true`, `AWARDS_HISTORY_MAX_PER_RUN=2000` (orchestrator-1 setter env).
3. Første natt: mål med `run-awards-dekning.sh` og forvent omtrent +5 400 tildelinger. Er avviket
   over ±10 %, stopp og meld.
4. Etter 7 netter, eller ved å heve taket: radaren og eval mot tallene over.
5. Egne små PR-er for forbehold 1 og 2 før topp 20 brukes utad.
