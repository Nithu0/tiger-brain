# Kildepolitikk: TED som verifikator, ikke hovedkilde — 2026-10-11

Kontekst: operatørbeslutning — TED har utgåtte/mismatchende saker mot Doffin. TED skal bli
verifikator + kildehenvisning; hovedkilder = norske, oppdaterte portaler.

## 1. Dagens henting (kodekartlegging — FACT, lest fra kilde 2026-10-11)

- `crm/src/lib/sources/ted.ts` — TED v3 API, keyless, `organisation-country-buyer=NOR`.
  Jobb `ingest-ted`, cron `5 * * * *` (hver time). Felt-liste verifisert mot live API 2026-09-26/27 (kommentarer i filen).
- `crm/src/lib/sources/doffin.ts` + `doffinWebclient.ts` + `doffinEnrich.ts` — Doffin public API v2
  (med nøkkel) eller doffin.no webclient (uten nøkkel, i bruk nå — ingen `DOFFIN_API_KEY` lokalt).
  Jobb `ingest-doffin`, cron `*/30 6-22` + `0 0-5,23` (hvert 30. min på dagtid, hver time natt).
- Upsert (`crm/src/lib/tenders/upsert.ts`) er idempotent per **(source, externalId)** — TED og
  Doffin skriver alltid to *separate* rader for samme anskaffelse, aldri overskrivning. Det finnes
  altså ikke noe "vinner ved konflikt" i dag — hver kilde er sin egen sannhet for sin rad.
- **Kryss-kilde-kobling finnes allerede**, men er ikke dedup: `crm/src/lib/tenders/related.ts`
  (`pickRelated`/`findRelatedTender`) setter `relatedTender` på en Doffin/TED-tvilling når samme
  tittel + samme kjøper + frist innen ±1 dag. To rader forblir i databasen, men linket til samme
  rot. RESULT/CHANGE-varsler kobles via `procedureId` der TED har det; Doffin har det sjelden
  (feltet er markert ASSUMPTION/uverifisert i `doffin.ts`).

## 2. Produksjonstall — **UNKNOWN, ikke målt i denne sesjonen**

Ingen `.env`/DB-tilgang i dette worktreet (ingen credentials lokalt, ingen prod-DB-tunnel satt opp
innen 10-minutters-budsjettet). Jeg gjetter ikke på tall — her er de eksakte spørringene å køre mot
prod-Postgres for å få de fire tallene operatøren ba om:

```sql
select source, count(*) from tenders group by source;                         -- TED vs Doffin volum
select count(*) from tenders where "relatedTender" is not null;               -- antall koblede tvillinger
select count(*) from tenders
  where source = 'ingest-ted' and deadline < now() and status = 'ACTIVE';     -- TED-rader m/utløpt frist, feil status
```
TODO (eier: hvem har prod-adgang): kjør disse, lim resultatet inn her under en ny dato.

## 3. Hvem er "tensile" og "hyyr"? (web, 2026-10-11)

- `FACT`: **Hyyr** er en reell, voksende norsk KGV/KAV-anskaffelsesplattform (AI-drevet), med
  100+ offentlige oppdragsgivere og 40 % av kommuner / 67 % av fylkeskommuner som bruker den som
  offisielt KGV/KAV-system per H1 2026. Kilde: anskaffelser24.no, 2026-07-15, "Hyyr firedobler
  veksttakten etter anbudsseire"; hyyr.no.
- `HYPOTHESIS` (ikke bekreftet av operatør): "tensile" = feilhørt/feilskrevet **TendSign**
  (Visma TendSign, nå del av Mercell-konsernet sammen med EU-Supply). Fonetisk nærliggende på norsk
  tale. Ingen treff på "tensile" som egennavn i anbudsbransjen — `UNKNOWN` om operatøren mente noe
  annet; bør bekreftes med operatøren direkte før vi bygger mot feil navn.
- `FACT`: Mercell er den dominerende KGV-verktøyleverandøren i Norge (konkurransegjennomføring,
  dokumentnedlasting, tilbudsinnlevering); TendSign og EU-Supply er Mercell-produkter. Kilde:
  dinanbudshjelp.no, jorpex.com/guides/find-tenders-norway (2026), anbud365.no.

## 4. API / gjenbruksvilkår per portal — teknisk vs juridisk holdt separat (CLAUDE.md §7)

| Portal | Teknisk tilgjengelig | Gjenbruksvilkår (kommersielt) |
|---|---|---|
| Doffin | FACT: offentlig API v2 + keyless webclient (allerede i bruk i repoet) | UNKNOWN — ikke undersøkt denne sesjonen; Doffin er lovpålagt kunngjøringsregister, antagelig friere, men ikke verifisert |
| TED | FACT: v3 API, keyless (i bruk) | EU-register, vanligvis åpne data — ikke re-verifisert nå |
| Mercell / TendSign / EU-Supply | UNKNOWN om det finnes et offentlig/åpent API for tredjeparter | `FACT` (2026-10-11, get.mercell.com/no-no/ressurssenter/vilkar-og-betingelser-mts-norge): Mercells MTS-vilkår sier data fra tjenesten ikke selges eller gis til andre parter. `FACT` (Visma Software-bruksvilkår): data fra Visma-API kan ikke videreformidles/selges til tredjepart utover intern bruk i integrert applikasjon. Konklusjon: selv om et API skulle finnes, tyder vilkårene på at kommersiell gjenbruk/videresalg av uttrukne anbudsdata **ikke** er dekket — juridisk sjekk må gjøres før noe bygges, ikke etterpå. |
| Hyyr | UNKNOWN — fant ingen offentlig API-dokumentasjon i søk (kun leverandørportal for innlevering + arkivfunksjon nevnt) | UNKNOWN — ingen vilkår funnet |

Ingen av disse fire er undersøkt grundig nok til et bygge-vedtak. Dette er et research-spike, ikke en leveranse.

## 5. Minste konkrete grep: "er denne fortsatt aktiv"-sjekk mot Doffin

Forslag: for hver anskaffelse vi viser (uansett opprinnelig kilde), slå opp Doffin-id (når
`relatedTender`/tittel+kjøper gir treff, eller når raden selv er Doffin) og sjekk status/deadline
live før den rendres i UI. Faller saken ut av Doffins aktive treffliste eller har `status != ACTIVE`
med passert frist → skjul/merk som utløpt.

**Størrelse:** liten. Doffin-klienten (`doffin.ts`/`doffinWebclient.ts`) og statusfeltet
(`deriveStatus` i `common.ts`) finnes allerede — dette er ikke nytt API-arbeid. Jobben er:
(a) en batch-sjekk i en ny/utvidet cron-task som slår opp hver `ACTIVE`-tender med passert
visningsfrist mot Doffin og nedgraderer status, estimat **0.5–1 dag**; eller (b) en synkron
sjekk ved render for et lite utvalg, enklere men tregere — ikke anbefalt i stor skala.
Avhenger av at Doffin faktisk har en treffbar lookup for TED-opprinnelige saker uten
Doffin-id — der må koblingen gå via `relatedTender`/tittel-heuristikk i `related.ts`, som allerede
finnes men ikke er 100 % dekkende (ASSUMPTION, procedureId sjelden tilgjengelig fra Doffin).
