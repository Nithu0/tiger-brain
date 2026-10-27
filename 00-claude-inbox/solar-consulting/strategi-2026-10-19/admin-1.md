# Offisielle API-er: hva de gir, og hva de *ikke* gir (admin-1, 2026-10-19)

Kilder er hentet 2026-10-19. Tall fra prod er read-only (`crm/scripts/baseline/strategi-api-dekning.sql` → `admin-1-dekning-2026-10-19.txt`).
Merking: **DOKUMENTERT** = står i kunngjøring eller kilde · **ETTERSPURT** = krav i anbud · **ANTAKELSE**.

## Bunnlinjen
**Ingen offentlig API lar en leverandør levere tilbud eller kommunisere med kjøpere.** Tilbud går via KGV (Mercell, TendSign, EU-Supply). Doffins Notices API sender bare *kunngjøringer* for oppdragsgivere og krever DFØ-godkjenning. Dialogporten og Fiks kan bare *sendes* av offentlige tjenesteeiere eller i kommunale fagprotokoller. Alt verdifullt for oss er **innhenting**.

## Kilde for kilde
| Kilde | Gir | Tilgang | Inn/ut | Bruker vi i dag? | Nytt og verdifullt |
|---|---|---|---|---|---|
| **Doffin Public API** | søk, full kunngjøring per id (`/download`, eForms-XML, ANTAKELSE om formatet), resultater og vinnere | nøkkel, ingen godkjenning (30 søk/min, 10 nedlastinger/min) | innhenting | ja, søk | **`/download`**. Flytt henting per id dit fra webclient-API-et |
| Doffin webclient-API | det samme | uten nøkkel, **udokumentert**, ingen vilkår funnet | innhenting | **ja** (`doffinWebclient.ts`) | risiko: kan endres uten varsel. Behold som reserve, eller få DFØ til å bekrefte skriftlig |
| Doffin Notices API | innsending og validering av kunngjøringer | DFØ-godkjenning (KGV-leverandører) | **innsending, men bare kunngjøringer** | nei | ikke relevant for tilbud |
| eForms-SDK-NOR | felt-ID-er, kodelister, norske skjemaer under terskel (E2–E4) | åpen (GitHub) | – | nei | deterministisk parsing av XML-en, også under terskel |
| TED Search + bulk | søk (anonymt) og daglige/månedlige XML-pakker. Fri gjenbruk, også kommersielt | åpen | innhenting | søk: ja | **bulkpakker**, som tetter 2025-hullet billig |
| KS Fiks (IO / Protokoll) | maskin-til-maskin i fagdomener (arkiv, plan, matrikkel, barnevern) | Maskinporten + `ks:fiks` + *kommunen* oppretter integrasjonen. «Ingen API for å opprette integrasjoner» | innsending, men bare i fagprotokoller | nei | **ingen markedsinnsikt, ingen kjøperkanal.** Først relevant når et produkt skal integreres hos en kommune |
| Fiks kontokatalog | konto per orgnr og meldingstype | innlogging (JWT) | – | nei | ingen leverandørfelt |
| Felles datakatalog (data.norge.no) | API-er og datasett per offentlig virksomhet (1 072 datatjenester) | åpen, 10 kall/min | innhenting | nei | svake hint om plattform, ingen leverandørdata |
| Maskinporten / ID-porten | token / innlogging | avtale, selvbetjent, gratis | – | nei | bare en inngangsbillett når et konkret API gir oss tilgang |
| Altinn Dialogporten | dialoger fra tjenesteeier til virksomhet | lese: Maskinporten/ID-porten. Sende: bare offentlig tjenesteeier | lese | nei | ingen kjøperkanal for anbud funnet (UNKNOWN om noen kjøpere bruker det) |
| Microsoft Graph / Entra | egen e-post, kalender og SharePoint | app i egen tenant, gratis | inn og ut | nei | **høy:** fange anbudskorrespondanse i egen innboks og koble den til mulighet. Når ikke kjøperens systemer |

## Hva vi kan i dag med egne data (prod, 2026-10-19)
- **Kunngjøringer:** ~110 000 med full råkopi. Doffin har 17–18 000 per år for 2021–2024 og TED ~10 000 per år.
- **Hull i 2025:** 45 fra Doffin og 0 fra TED. Det er det største hullet, og det rammer alle analyser av «hva skjer nå».
- **Tildelinger:** 387, hvorav 95 med verdi, fordelt på 322 leverandører. Tynt for leverandørmarkedet.
- **DOKUMENTERT systemnavn i kunngjøringstekst:**

  | System | Treff | Kjøpere |
  |---|---|---|
  | Visma | 135 | 71 |
  | Visma Profil | 106 | 53 |
  | Microsoft 365 | 88 | 40 |
  | Unit4 | 59 | 25 |
  | Noark | 51 | 24 |
  | Tietoevry | 27 | 19 |
  | Gerica | 24 | 13 |
  | Acos | 24 | 15 |
  | Public 360 | 14 | 11 |
  | KS Fiks | 11 | 5 |

  «Elements» (109) er usikker, fordi ordet også er vanlig engelsk. Listen over navn er vår (ANTAKELSE). Treff betyr at systemet er nevnt, ikke nødvendigvis at det er i bruk.

## Hull
1. Ingen åpen kilde sier *hvilken kommune som bruker hvilket fagsystem*. Den beste er **Kommunal Rapports Leverandørdatabase**, med leverandørreskontro per kommune (FACT via KS FoU-rapport feb. 2026), men den krever betalt abonnement og pris er UNKNOWN. KS FoU-rapporten selv er åpen og gir markedsandeler: Visma Enterprise 50–70 % på ERP, og ACOS/Tieto/Sikri 20–40 % hver på eByggesak (FACT).
2. 2025 mangler i egne data.
3. Lisensen for Doffin-API-et er UNKNOWN (TED er fri).

## Beste mulighet: «Bytte-radar for kommunale fagsystemer»
- **Hva:** kombinere kontraktsutløp og varighet (allerede bygget i SC-02-radaren), DOKUMENTERTE systemnavn i 110 000 kunngjøringer (eForms-SDK-parsing gir felt i stedet for tekstsøk) og markedsandelene i KS-rapporten. Spørsmålet er *hvem som sannsynligvis anskaffer eller bytter et forvaltningssystem de neste 12 månedene, og hva de har i dag.*
- **Hvorfor:** det treffer nøyaktig scope-anbefalingen (kommunale forvaltningssystemer er den eneste klyngen med gjentatte ja, se TRE-SCOPES-BESLUTNING). Det kan selges som innsikt til leverandører uavhengig av egne tilbud, og det gjenbruker radar og råarkiv. Ingen parallell løsning.
- **Datagrunnlag:** egne kunngjøringer og tildelinger (finnes), TED-bulk for 2025 (åpen) og KS-rapporten (åpen). Kommunal Rapport er valgfritt og betalt.
- **Kostnad (ANTAKELSE):** ~1 uke (bulk-backfill 2025 + `/download`-parsing med SDK-NOR + kobling i radaren). Abonnement: UNKNOWN.
- **Verdi:** UNKNOWN i kroner. Mål som kan sjekkes: antall kjøpere med forventet utskifting innen 12 måneder og kjent dagens system. I dag finnes 71 kjøpere med Visma-omtale og 24 med Noark som grunnlag.
- **Risiko:**
  - En omtale er ikke det samme som bruk. Skill DOKUMENTERT fra ANTAKELSE i alle visninger.
  - Webclient-avhengigheten (se over).
  - Doffin-lisensen er ukjent før data selges videre. **Avklar med DFØ før salg.**

## Anbefalte neste steg (ingen kode i denne runden)
1. Send e-post til DFØ: vilkår og lisens for Public API, og om webclient er tillatt. Skriftlig svar.
2. Backfill 2025 fra TED-bulk + Doffin Public API.
3. Graph mot egen anbudsinnboks (lav kostnad, høy nytte).
4. Lavere prioritet: Fiks, Dialogporten og Maskinporten, til en kunde eller et API krever dem.
