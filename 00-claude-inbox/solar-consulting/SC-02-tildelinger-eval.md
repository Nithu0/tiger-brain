# SC-02 — tildelinger: dobbelttelling og dekning før/etter

Beslutningen dette tjener: kan gjenutlysningsradaren svare på «hvilke IT-kontrakter kommer ut på
nytt de neste 12 månedene, og hvem vinner dem i dag?» med data i stedet for antakelser?

| Måling | Grunnlag | Rådata |
|---|---|---|
| **FØR** | `FACT` Produksjon, read-only, 2026-10-16 (kode `fae0ddd`) | [`sc02-awards-dekning-FOER-2026-10-16.txt`](sc02-awards-dekning-FOER-2026-10-16.txt) |
| **ETTER** | `FACT` om koden, *ikke* om prod: read-only eksport av prod 2026-10-16T08:27Z lastet inn i en lokal database. SC-02-jobbene ble kjørt på kopien: `awards-backfill` med `AWARDS_DEDUP_APPLY=1`, så `supplier-brreg-match` (live Brreg), så `awards-backfill` igjen | [`sc02-awards-dekning-ETTER-lokalkopi-2026-10-16.txt`](sc02-awards-dekning-ETTER-lokalkopi-2026-10-16.txt) |
| **ETTER + rå-arkiv** | Som ETTER, men rebaset på SC-01 og med `raw-notices` fylt lokalt: 213 ekte Doffin-notiser for kopiens Doffin-kunngjøringer, hentet 2026-10-17. Slik blir det i prod når rå-arkivet har hentet notisene | [`sc02-awards-dekning-ETTER-raaarkiv-lokalkopi-2026-10-17.txt`](sc02-awards-dekning-ETTER-raaarkiv-lokalkopi-2026-10-17.txt) |
| Plan per rad | Jobbens egne `award-merges`-rader fra kjøringen på den lokale kopien (rekey / merge / remove med grunn og ny nøkkel) | [`sc02-awards-dedup-plan-2026-10-16.csv`](sc02-awards-dedup-plan-2026-10-16.csv) |

Reproduser FØR (og ETTER i prod når koden har kjørt der):
`./scripts/baseline/run-awards-dekning.sh <FOER|ETTER>` (railway ssh, `SET TRANSACTION READ ONLY`).

`TODO` (paal-1): ETTER i prod måles når SC-01 er merget og første kjøring med `AWARDS_DEDUP_APPLY=1`
er godkjent. Den kommer som eget artefakt og erstatter ikke tallene under.

## 1. Andelen tildelinger med kontraktsslutt, verdi og org.nr.

| | FØR (prod) | ETTER (lokal kopi) | ETTER + rå-arkiv |
|---|---|---|---|
| Rader i `awards` | 642 | **385** | 385 |
| …IT (CPV 72/48) | 104 | 62 | 62 |
| **contractEnd** | 0 / 642 (0,0 %) | 90 / 385 (23,4 %) | **208 / 385 (54,0 %)** |
| …IT | 0 / 104 (0,0 %) | 10 / 62 (16,1 %) | **30 / 62 (48,4 %)** |
| **verdi** | 76 / 642 (11,8 %) | **84 / 385 (21,8 %)** | 84 / 385 |
| …IT | 14 / 104 (13,5 %) | 18 / 62 (29,0 %) | 18 / 62 |
| **org.nr.** | 543 / 642 (84,6 %) | **361 / 385 (93,8 %)** | 361 / 385 |
| …IT | 92 / 104 (88,5 %) | 58 / 62 (93,5 %) | 58 / 62 |

Med rå-arkivet: 111 `FACT_DATE` (oppgitt sluttdato), 97 `FACT_COMPUTED`, 177 uten. 129 rader har oppgitt varighet og 171 oppgitt fornyelse.
Uten rå-arkivet er kontraktsslutt alltid `FACT_COMPUTED` i ETTER: oppgitt signeringsdato + oppgitt varighet for en
delkontrakt. Det forutsetter at kontrakten starter ved signering. Notatet sier det («antar oppstart =
inngåelse»), og radaren merker slike datoer `ASSUMPTION` med middels sikkerhet. Bare en oppgitt
sluttdato eller startdato gir `FACT`. Ingen rad har `FACT_DATE`, fordi ingen eksisterende rad har en sluttdato i dataene vi
lagrer. Doffin-sluttdatoene ligger bare i det fulle eForm-treet, og det kommer med rå-arkivet
(SC-01). Kolonnen «ETTER + rå-arkiv» viser effekten: 90 → 208 rader.

Verdi-økningen skyldes nesten bare dedup (nevneren krymper), ikke nye verdier. TED-verdier gir
mer når rå-arkivet lagrer TED-feltene (`TED_AWARD_FIELDS` i `lib/sources/tedAward.ts`):
`FACT` målt live 2026-10-16, 271 av 566 verdiløse rader (33 av 90 IT) får en TED-verdi. Av de
271 er 148 rammeavtale-tak (BT-709) og ikke kontraktsverdier, og summert gir de for stort marked.

## 2. Dobbelttelling

| | FØR | ETTER |
|---|---|---|
| Overtallige rader, samme anskaffelse + leverandør fra ulike kunngjøringer | 132 (20,6 %) | **0** |
| Samme leverandør som både org.nr.-rad og navnerad i én anskaffelse | 61 | **0** |
| Duplikate `dedupKey` | — | **0** |

Akseptanse: alle 132 + 61 er én rad hver, eller én rad per delkontrakt (12 anskaffelser med flere
delkontrakter). `DUP_SAME_NOTICE|17|25` i ETTER er leverandører som vant flere delkontrakter. Det
er riktig: nøkkelen er anskaffelse + delkontrakt + leverandør.

## 3. Hva som skjer med de 642 radene

| Handling | Rader | Grunn |
|---|---|---|
| rekey | 366 | beholdes, får `dedupKey` |
| merge | 185 + 4 | dublett av en annen rad (Doffin-resultat + TED-kopi, navnerad + org.nr.-rad). De 4 kom i andre kjøring, etter at Brreg-oppslaget ga org.nr. |
| **remove** | **88** (16 IT) | **tilbyder, ikke vinner** (se §4) |
| keep | 3 | award 262 (VISMA ENTERPRISE AS), 263 (Fire Fighting Systems AS), 264 (Cefem AS): kunngjøringen har i dag ingen delkontrakter eller vinnere, så dedup kan ikke forklare raden og rører den ikke |
| nye | 16 + 4 | vinnere som manglet: delkontrakt-rader, og rader for leverandører Brreg-oppslaget slo sammen |

Ingenting slettes uten spor. Hver handling skrives først til `award-merges` med hele den gamle
raden som snapshot. Med `AWARDS_DEDUP_APPLY` av (standard) skrives bare planen, og eksisterende
tildelinger endres ikke.

## 4. Funn: Doffin-parseren tar med tapende tilbydere som vinnere

`FACT` (prod-eksport + live TED, 2026-10-16): `doffinWebclient.ts parseEform` setter
`results[].winners` til alle «Offisielt navn» i resultatblokken (block0510). Av 97 navn som står
på en delkontrakt men ikke i noen vinnerblokk (block05100601), er 94 TED-tilbydere og 0
TED-vinnere. Dagens `awards` har derfor 88 falske tildelinger. SC-02 leser bare vinnerblokkene
(`lib/awards/plan.ts`). Selve parserfeilen rettes i SC-01 (trading-1). Første ekte kjøring av
dedup venter på den, ellers lager parseren radene på nytt.

## 5. Brreg-oppslag (leverandører uten org.nr.)

`FACT` lokal kopi, live Brreg 2026-10-16. Første forsøk (alle 93 uten org.nr.): 6 auto, 73 til
kontroll (60 `merge_needed`) og 14 uten treff. 60 av de 73 var navnerader som dedup allerede har
tømt for tildelinger. Jobben og køen ser derfor bare på leverandører med `wins > 0`. Etter dedup
ble det 27 kandidater: 4 auto, 9 til kontroll (0 `merge_needed`) og 14 uten treff. Tersklene er
`ASSUMPTION` (`lib/suppliers/brregMatch.ts`), og alle auto-treff hadde navnescore 1,0. Et org.nr.
funnet ved navneoppslag gir `provenance.confidence = medium`. Bare et org.nr. som står i
kunngjøringen gir `high` (353 high / 29 medium etter kjøringen).

## 6. Radaren på dette grunnlaget

`FACT` lokal kopi med rå-arkiv, `radar-expiry` 2026-10-17: 21 gjenutlysninger innen 12 måneder,
3 IT (2 høy, 1 middels sikkerhet):

| # | Kontrakt | Oppdragsgiver | Nåværende leverandør | Slutt | Forventet utlysning | Sikkerhet | Kilde |
|---|---|---|---|---|---|---|---|
| 1 | Dynamic Purchasing System – System Development | Registerenheten i Brønnøysund | TWODAY AS | 2026-12-31 (oppgitt; fornyelse maks 6 oppgitt, lengde ikke strukturert) | fra 2026-06 | høy, FACT | Doffin 2026-115880, TED 705439-2026 |
| 2 | Consultancy services for the design of an integration system | DFØ | Sopra Steria AS | 2027-01-31 (oppgitt) | fra 2026-07 | høy, FACT | Doffin 2026-116087, TED 715425-2026 |
| 3 | Replacement of existing PLCs at Matre research station | Havforskningsinstituttet | Normatic AS | 2028-01-01 (signering + 15 mnd) | fra 2027-07 | middels, ASSUMPTION | Doffin 2026-115459, TED 687577-2026 |

Verdiene (9,4 / 6,5 / 2,9 MNOK) er tildelt verdi fra Doffin. «Forventet utlysning» er alltid
`ASSUMPTION` (slutt − 6 mnd). Når den allerede er passert, kan kontrakten komme når som helst, eller
den kan være forlenget med opsjon.

**Topp 20 IT er ikke i dataene ennå.** Det skyldes ikke koden, men at alle tildelinger i prod er fra
2026. Kontrakter med 2–4 års løpetid som går ut de neste 12 månedene, ble tildelt i 2021–2024.
Historikk-backfillen i SC-01 henter dem, og den kjører `awards-backfill` med `rootIds` i batcher.
Historikk-sperren `AWARDS_INCLUDE_HISTORY` (config/ingest.ts) er fortsatt lukket og må åpnes ved en
egen beslutning.
