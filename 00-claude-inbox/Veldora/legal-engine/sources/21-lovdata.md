# Kilde 21 — Lovdata (api.lovdata.no/v1/publicData), fase 2

Hentedato for alt under: 2026-10-15. Dekker **bare** det `20-BRIEF` ba om utover det alt verifiserte
(`prd/juridisk-assistent.md:64-66`, `09-institusjonell-kunnskap.md:15-24`). Registrerer som **egen
rad** `lovdata-api`, separat fra eksisterende `data/sources/lovdata.json` (id `lovdata`), som dekker
`lovdata.no` (web, RED) — de to er ulike rettsforhold hos samme leverandør, jf. regel §2.

## 0. Bekreftelse av det alt verifiserte

`GET https://api.lovdata.no/v1/publicData/list` → **200, ingen nøkkel**, verifisert live nå
(curl, 2026-10-15T17:56Z). Stemmer fortsatt. Men listen har **fire** filer, ikke to — de to
tidligere unavngitte er Lovtidend-arkivene (se §1).

## 1. Hva de fire datasettene faktisk inneholder

| Fil | Str. (komprimert) | Innhold | Dekning |
|---|---|---|---|
| `gjeldende-lover.tar.bz2` | 5,8 MB | Konsolidert *gjeldende* lovtekst, én XML per lov (`nl/nl-20160617-073.xml`) | Kun ikrafttrådt tekst i dag. **Opphevede lover er ikke med** |
| `gjeldende-sentrale-forskrifter.tar.bz2` | 21 MB (223 MB utpakket) | Konsolidert *gjeldende* forskriftstekst, inkl. FOA (`sf-20160812-0974.xml`), forsyningsforskriften | Kun sentrale forskrifter — **lokale/kommunale forskrifter er ikke med** |
| `lovtidend-avd1-2026.tar.bz2` | 1,5 MB | **Ny i denne kartleggingen.** 1104 filer, én HTML/XML per kunngjort endringslov/-forskrift i 2026, f.eks. `lti/2026/nl-20260123-001.xml`. Hver fil har `Kunngjort`, `I kraft fra`, `Endrer` (liste over hvilke dokumenter den endrer) | Kronologisk kunngjøringsarkiv, **ikke** konsoliderte snapshots |
| `lovtidend-avd1-2001-2025.tar.bz2` | 69 MB | Samme struktur, 2001–2025 | Historisk kunngjøringsarkiv tilbake til 2001 |

Dommer, forarbeider (Prop./Innst./Lovvedtak — kun *nevnt* i metadata, selve dokumentet er ikke med),
rundskriv og veiledere er **eksplisitt utenfor** publicData. Bekreftet ved nedlasting og utpakking
av `lovtidend-avd1-2026.tar.bz2` (1104 filer inspisert, curl 2026-10-15).

## 2. Versjonshistorikk — hovedspørsmålet

- **Gjeldende-datasettene** gir bare «ikrafttredelse av siste endring» for *hele dokumentet*,
  kopiert til hvert ledd. **Ingen versjon per paragraf/ledd.** (Alt verifisert tidligere,
  `09-institusjonell-kunnskap.md:24` — bekreftes, ikke gjort om.)
- **Nytt funn:** Lovtidend-arkivene (2001–2025 + løpende 2026) er **kunngjøringsarkivet**, ikke
  konsoliderte snapshots. Hver fil er selve endringsakten («Lov om endringer i …») med dato for
  kunngjøring og ikrafttredelse, og en liste over hvilke RefID-dokumenter den endrer. Dette er
  **råmaterialet** man i prinsippet kunne spilt kronologisk for å rekonstruere en historisk
  paragrafversjon — men datasettet gjør ikke den rekonstruksjonen for oss. Det krever egen
  diff-motor som leser endringsaktene og anvender dem i tidsrekkefølge. Ikke bygget, ikke testet.
  `HYPOTHESIS`, ikke `FACT`.
- `/v1/documentHistory/<refID>` (nevnt i `api.lovdata.no/docs`) ga **404** på to plausible ID-format
  uten autentisering (curl 2026-10-15). Kan ikke avgjøre om 404 betyr «finnes ikke i publicData» eller
  «feil ID-format» — `UNKNOWN`, ikke testet med konto (forbudt, regel §2).
- `/v1/search` krever **Basic Auth** (401 uten nøkkel, bekreftet) — altså et betalt/kontobasert
  endepunkt, ikke del av de fire frie datasettene.
- **Konklusjon:** vi kan fortsatt ikke svare «hva sa § 24-8 den datoen tilbudet ble levert» fra de
  frie datasettene alene. Lovtidend-arkivet er en teoretisk vei dit, ikke en løsning i dag.

## 3. Betalt API / Lovdata Pro

- `api.lovdata.no/om-api-tjenesten`: «Lovdatas API er under stadig utvikling og flere endepunkter
  og datakilder tilbys mot betaling til innovasjonsformål» — **pris ikke publisert**, kontakt
  `marked@lovdata.no`. `UNKNOWN` pris.
- Lovdata Pro-siden (`lovdata.no/pro/om-lovdata-pro`) nevner kun «varslinger, merknader, utvalg
  mv.» for personbruker — dommer/forarbeider/kommentarer/historikk **ikke eksplisitt bekreftet**
  der (siden som ble hentet kan være en innloggingsvariant). `UNKNOWN`, lav tillit.
- Vilkår for maskinell/AI-bruk er **ulike per flate** — se §4.

## 4. Rettigheter — presist, to regimer

| Flate | Sitat (ordrett, hentet) | Betydning |
|---|---|---|
| `api.lovdata.no` (metabeskrivelse, hentet 2026-10-15) | «Benytt datagrunnlaget fritt for eksperimentering og forskning med KI» | Eksplisitt invitasjon til KI-bruk **av publicData** |
| `api.lovdata.no/om-api-tjenesten` | «Dataene er lisensiert under NLOD 2.0» | Fri gjenbruk, kildeangivelse, kommersielt og ikke-kommersielt |
| `lovdata.no/info/brukeravtale` (hentet 2026-10-15, bekrefter funn fra 2026-08-30) | «Du har ikke rett til å distribuere, publisere eller mangfoldiggjøre innholdet uten skriftlig tillatelse» + «Massenedlasting av innholdet er ikke tillatt» + **«Det er ikke tillatt å bruke innholdet til trening eller utvikling av KI-algoritmer»** (for åpne tjenester) | Forbud mot KI-trening gjelder **lovdata.no-visningen**, ikke publicData-filene |
| Samme side, unntaksklausul | Unntak for NLOD-lisensiert gjeldende lov/forskrift/Lovtidend-materiale, «forutsatt kildehenvisning», men «for større nedlastinger skal brukerne benytte åpne API-er» | Bekrefter at publicData er den *tiltenkte* veien for bulk, web-siden er det ikke |

**Internt nå (ADR-0010, B1 besvart):** `storage_rights: GREEN`, `analysis_rights: GREEN`,
`ai_processing_rights: GREEN` for `lovdata-api` (NLOD 2.0 + eksplisitt KI-invitasjon dekker lagring,
analyse og modellbruk av publicData-filene). `redistribution_rights: YELLOW` registrert, ikke
blokkerende nå — kildeangivelse er et krav NLOD stiller uansett, ikke en ekstra hindring.

## 5. Oppdatering og ferskhet

`lastModified` finnes **per fil** i `/list`-responsen (ikke ett globalt felt):
`gjeldende-sentrale-forskrifter` og `lovtidend-avd1-2026` begge `2026-10-15T01:31:00Z`,
`gjeldende-lover` og `lovtidend-avd1-2001-2025` begge `2026-10-13T01:31:00Z` — konsistent med
«hver natt» når noe faktisk er endret, ikke hver natt uforandret. `dataset_last_modified`-feltet vi
bruker i dag mapper direkte til dette. Ingen dokumentert SLA for *hvor raskt etter ikrafttredelse*
en endring er med — `UNKNOWN`, kun observert at dagens filer er 0–2 dager gamle.

## 6. Robusthet

Ingen endringslogg for API-et funnet (`UNKNOWN` — docs sier bare «This API is extended on a
regular basis through the addition of new methods»). `/swagger/v1/swagger.json` → 404 (ikke
offentlig, eller annen path). Filnavn-skjemaet (`nl-ÅÅÅÅMMDD-NNN.xml`, `sf-ÅÅÅÅMMDD-NNNN.xml`) er
stabilt mot det som alt er bygget (`tar.ts`, `parse.ts`).

## 7. Skjema

| Felt | Verdi |
|---|---|
| id | `lovdata-api` |
| name | Lovdata offentlige datasett (publicData) |
| provider | Stiftelsen Lovdata |
| url | https://api.lovdata.no/v1/publicData |
| feed_url | null (ingen push-feed; poll `/list`, sjekk `lastModified`) |
| access_method | REST, `GET /v1/publicData/list` + `GET /v1/publicData/get/<filnavn>` |
| authentication | Ingen (publicData). `/v1/search` og sannsynligvis `/documentHistory` krever konto |
| cost | Gratis (publicData). Betalt API «etter avtale», pris `UNKNOWN` |
| latency | Statiske filer, ~1–70 MB; ikke sanntid |
| completeness | Gjeldende lover + sentrale forskrifter + Lovtidend avd I 2001–2026. Ikke lokale forskrifter, ikke dommer, ikke forarbeider, ikke opphevede lover |
| historical_access | Delvis — kunngjøringsarkiv (Lovtidend) finnes, konsolidert per-paragraf-historikk gjør det ikke. `documentHistory` uklart/sannsynlig bak konto |
| technically_fetchable | GREEN |
| storage_rights | GREEN (intern bruk, NLOD 2.0) |
| analysis_rights | GREEN |
| redistribution_rights | YELLOW (kildeangivelse påkrevd; ikke blokkerende for internt verktøy) |
| ai_processing_rights | GREEN for publicData (eksplisitt KI-invitasjon). **RED/UNKNOWN for lovdata.no-visning** — egen rad |
| gdpr_implications | Ingen persondata i disse fire datasettene (kun lov-/forskriftstekst) |
| licence_status | NLOD 2.0, bekreftet |
| owner | Nithu |
| next_action | Hvis historisk «hva sa §X på dato Y» skal løses: evaluer om å bygge en diff-motor over Lovtidend-arkivet er verdt det, eller be om tilgang til `documentHistory` |

## 8. Hvordan vi ville koblet den

Allerede koblet for de to kjente filene (`STATIC_ALLOWED_HOSTS` i `crm/src/lib/http.ts:14` har
`api.lovdata.no`). Lovtidend-filene krever **ingen ny allowlist-linje** (samme host), men:
- `tar.ts` må utvides til å plukke `lovtidend-avd1-*.tar.bz2` i tillegg til de to den leser i dag
- `parse.ts` må få en egen gren for Lovtidend-XML-strukturen (`Kunngjort`/`Endrer`/`I kraft fra`) —
  annerledes skjema enn gjeldende-dokumentene
- ID-skjema: kunngjøringsakter får egen type, f.eks. `kunngjoring/lov/2026-01-23-1`, ikke
  `lov/<dato>-<nr>/§X` (de endrer paragrafer, de *er* ikke paragrafer)
- `sync.ts`s vakt (tom/halvert ⇒ stopp) gjelder uendret

## 9. UNKNOWN som står åpne

1. Hva `/v1/documentHistory` faktisk returnerer og om det er gratis — ikke testbart uten konto
2. Faktisk pris for betalt API/Lovdata Pro
3. Om Lovdata Pro inneholder dommer/forarbeider/kommentarer — siden hentet ga ikke klart svar
4. SLA for hvor raskt etter ikrafttredelse en endring ligger i `gjeldende-*`

## 10. Tillegg — verifisering av to antatte filnavn i `crm/src/config/legal.ts:21-25`

Begge tarballene lastet ned (samme publicData-endepunkt, ingen nøkkel) og `tar -tjf` listet, 2026-10-15:

| Kilde | Antatt sti (ASSUMPTION i koden) | Faktisk funnet | Resultat |
|---|---|---|---|
| offentleglova (`lov/2006-05-19-16`) | `nl/nl-20060519-016.xml` | `nl/nl-20060519-016.xml` — tittel «Lov om rett til innsyn i dokument i offentleg verksemd (offentleglova)» | **JA — bekreftet korrekt** |
| klagenemndforskriften (`forskrift/2002-11-15-1288`) | `sf/sf-20021115-1288.xml` | `sf/sf-20021115-1288.xml` — tittel «Forskrift om klagenemnd for offentlige anskaffelser» | **JA — bekreftet korrekt** |

Merk: `20021115`-prefikset finnes i **to** filer samme dag (`sf-20021115-1287.xml` er en annen
forskrift, om ansattrepresentasjon i helseforetak — ikke en treffusikkerhet, bare to forskrifter
kunngjort samme dato). `-1288` er verifisert ved tittel, ikke bare ved filnavn.

**Konklusjon til klagemodulen:** begge antatte stier er riktige. `ASSUMPTION`-kommentaren i
`crm/src/config/legal.ts:21-25` er nå motbevist som risiko — filnavnene stemmer, så
`legal.corpus.guard` skal ikke ha sviktet på disse to av den grunnen. Hvis offentleglova eller
klagenemndforskriften likevel mangler tekst i korpuset i dag, er årsaken noe annet enn feil
filnavn (f.eks. at synk aldri har kjørt for disse to, eller en parsefeil i selve dokumentet) —
det er ikke undersøkt her og bør sjekkes mot faktisk DB-innhold, ikke mot kildefilene.
