# PLAN: Doffin Public API som primærkilde (strategi §4.2). infra-1, 2026-10-19

Beslutningen planen informerer: skal ingest-doffin og history-backfill gå over fra det udokumenterte webclient-API-et til det dokumenterte, nøkkelbaserte Public API-et, med webclient som reserve?

## Hva API-et er (FACT, hentet 2026-10-19 fra DFØs utviklerportal, uten nøkkel)
Kilde: `https://dof-notices-prod-api.developer.azure-api.net/developer/apis/651eeff38be0c56022ac741d/operations` (portalens eget JSON).
- Base `https://api.doffin.no/public`. Auth er `Ocp-Apim-Subscription-Key` (header) eller `subscription-key` (query). Uten nøkkel: 401.
- **`GET /v2/search`**, høyst **30 kall/min** per abonnement, 429 med `Retry-After`.
  - Parametre: `numHitsPerPage` (maks 100), `page`, `sortBy` (PUBLICATION_DATE_ASC/DESC, …), `searchString`, `type` (13 typer, flervalg), `status`, `cpvCode`, `location`, `issueDateFrom` og `issueDateTo` (yyyy-mm-dd), `estimatedValueFrom/To`.
- **`GET /v2/download/{doffinId}`**, høyst **10 kall/min**. Svar 200 er `application/octet-stream` («The downloaded notice»), 404 er JSON.
- UNKNOWN: (1) formatet på download. HYPOTHESIS: eForms-XML (UBL), samme som sendes til TED. (2) Om søket har et tak på tilgjengelige treff, slik webclient har (1 000). (3) Vilkår, pris og gjenbruksrett. Det må avklares med DFØ, og det er operatørens sak.

## Hva vi har i dag
- `src/lib/sources/doffin.ts` har allerede en klient for `/v2/search` (`searchDoffin`, brukes av ingest-doffin når `DOFFIN_API_KEY` er satt). Den er aldri testet mot API-et (ingen nøkkel). Hit-mapperen deles med webclient-søket (felt verifisert 30.09).
- Detaljene (eForm: delkontrakter, vinnere, verdier, kriterier, kontraktsperiode) hentes fra webclientens `notices-api/notices/{id}` som et ferdig rendret **label-tre i JSON**. All detaljparsing (doffinWebclient.ts, eformLabels.ts, eformTerm, parseEformCriteria) leser dette treet.

## Konsekvens
**Detaljparsingen kan IKKE gjenbrukes rett.** Er download eForms-XML, trengs en XML-parser på eForms-BT-er (BT-13713 lot, BT-500 vinner, BT-720 verdi, BT-809/750 kriterier, BT-536/537/36 periode …). Det er en ny parser. Den blir riktigere (koder i stedet for oversatte labels, ingen språkproblemer som 2024-«Navn»-saken), men den er ikke liten.
- Søk kan byttes nesten uten ny kode: samme mapper, bare ny transport og grenser.

## Forslag i to trinn
1. **Trinn 1, søk (liten PR nå, bak flagg):**
   - `DOFFIN_PUBLIC_API_ENABLED` (av) og `DOFFIN_API_KEY`.
   - Når begge er satt, bruker ingest-doffin og history-backfill (vindu = `issueDateFrom/To`, `sortBy=PUBLICATION_DATE_ASC`, sider til tom) Public API til søk. Detaljene hentes fortsatt fra webclient.
   - Rate limiter: 30 søk/min (≥ 2,1 s mellom kall), 429 → `Retry-After`. Faller tilbake til webclient ved 401/403/5xx, og loggen sier hvorfor.
   - Tester: mapper mot fixture, limiter, fallback. Ingen ekte kall.
2. **Trinn 2, detaljer (etter nøkkel):**
   - Hent 5 notiser med download og se formatet.
   - Er det eForms-XML: egen parser `doffinEformXml.ts` som gir samme `MappedTender` og `NoticeCriterion` som i dag.
   - 10 nedlastinger/min betyr ~14 400/døgn. En full historikk-refetch (~95 000 Doffin) tar da ~6,6 døgn, mens inkrementell (~150/døgn) er uproblematisk.

## Hvordan vi måler at resultatet er likt (før noe byttes)
- Et utvalg på 200 Doffin-id-er, stratifisert på år (2021–2026), type (COMPETITION/RESULT/PLANNING) og språk (nb/en).
- Søk: for hvert vindu i utvalget, mengden id-er fra Public API mot webclient. Mål: identisk, og avvik listes.
- Detaljer (trinn 2): `MappedTender` fra XML-parser mot webclient-parser, felt for felt (lots, vinnere + org.nr., verdier, kontraktsslutt, kriterier). Toleranse: 0 avvik på nøkkelfelt. Avvik i labels og tekst dokumenteres. Resultatet går til `crm/eval/doffin-public-vs-webclient-<dato>.txt`.
- Kontroll som før: 0 kontaktfelt i raw_notices (XML har kontaktpunkt-BT-er som MÅ strippes, egen liste i stripContacts).

## Gates
- Ingen henting før nøkkelen finnes og operatøren har avklart vilkårene med DFØ. `data/sources/doffin.json` → `public-api-v2` oppdateres med vilkår, dato og rettighetsfelt FØR første kall.
- Trinn 1 kan merges med flagget av. Det gjør ingen kall.
