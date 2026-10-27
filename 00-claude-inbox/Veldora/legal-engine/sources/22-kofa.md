# 22 — KOFA-avgjørelser (Klagenemnda for offentlige anskaffelser)

Kartlagt av researchagent 2026-10-15, **og de bærende påstandene etterprøvd av admin-1 i egen
terminal samme dag** (kommandoene står under). Dette er beslutningsgrunnlaget for issue 018 / gate B3.

## Kanalen er bekreftet, og den er åpen

| Forhold | Målt verdi | Hvordan |
|---|---|---|
| WP REST-liste | `https://www.klagenemndssekretariatet.no/wp-json/wp/v2/sak` → **HTTP 200**, `application/json`, ingen nøkkel | `curl -I`, admin-1 2026-10-15 |
| Antall saker | **`x-wp-total: 5022`** | samme kall |
| Nyeste sak | **2026/2262**, `date 2026-10-14T13:08:18` | `?per_page=1&orderby=date&order=desc` |
| Eldste sak | `2003/1` (agentens måling) | REST-paginering |
| robots.txt | Tillater alt relevant: bare `/wp/wp-admin/` og `/content/uploads/wpforms/` er `Disallow`, og Yoast-blokken avslutter med en tom `Disallow:` (= tillatt) | `curl .../robots.txt`, admin-1 |
| `kofa.no` | **`Disallow: /`** — skrapes aldri. Koden vår treffer KNSE, ikke kofa.no. Det er riktig | `curl https://kofa.no/robots.txt`, admin-1 |

**Presisering jeg fant som agenten ikke tok:** REST-objektene har et `acf`-felt, men det er **tomt**
på de sakene jeg stakk ut (2026/2262, 2026/2216, 2026/2188, 2022/1663, 2022/1665 — alle `acf: {}`).
Den strukturerte metadataen (Saken gjelder · Regelverk · **Avgjørelse** · Avsluttet · Status) ligger
altså i HTML-tabellen på sakssiden, ikke i REST-svaret. Det betyr at **utfallet brudd/ikke-brudd må
hentes fra sakssiden** — presis slik koden vår alt gjør (`kofa/page.ts` → `kofa/decision.ts`). Ingen
snarvei via REST alene.

## Rettighetsgrunnlaget er fortsatt uavklart — og det finnes ingen bedre kilde

- **KNSE sier ingenting om gjenbruk.** Verken personvernerklæringen eller taushetspliktsiden omtaler
  lisens, gjenbruk eller maskinell bruk av avgjørelsene. `KOFA_LICENSE_URL` i koden vår peker på
  åndsverkloven § 14 — det er **vår antakelse**, ikke et sitert vilkår fra kilden.
- **Lovdata fører samme avgjørelser** på `lovdata.no/register/kofa`, men **bak innlogging/Pro** (403).
  Det er et *annet* rettsforhold enn det nøkkelfrie NLOD-datasettet — og NLOD-datasettet dekker
  uansett ikke KOFA-praksis.
- **Ingen offentlig datasett-vei:** verken data.norge.no eller DFØ har et KOFA-datasett.

Altså: enten henter vi fra KNSE på vår egen vurdering av åndsverkloven § 14, eller vi lar KOFA ligge.
Det finnes ikke et tredje, «rent» alternativ. **Det er beslutningen operatøren må ta, og juristen bør
bekrefte § 14-antakelsen før noe av dette brukes utad.**

## GDPR: ingen anonymisering

`FACT` (agentens stikkprøver i 2019, 2025 og 2026): **fulle navn** på både innklaget oppdragsgiver
(kommune/etat) og klager (leverandør) står i sakstittel, HTML-metadata og PDF-tekst. Personvern-
erklæringen dekker eInnsyn-journalen, ikke avgjørelsene. Dette gjelder uavhengig av at vi nå er et
internt verktøy — lagring av personopplysninger krever behandlingsgrunnlag uansett, og det er en
egen vurdering ved siden av opphavsretten.

## Dekning: historikken er et valg, ikke en grense

`KOFA_BACKFILL_FROM_YEAR` i `crm/src/config/kofa.ts:12` setter gulvet til 2017. Teknisk er alt
tilbake til 2003/1 tilgjengelig. Gulvet er altså en bevisst avgrensning (regelverksskiftet 2017), og
kan senkes uten ny kode hvis juristen vil ha eldre praksis.

## Skjemafelt (`data/sources/kofa.json`)

| Felt | Verdi |
|---|---|
| id · name · provider | `kofa` · KOFA-avgjørelser · Klagenemndssekretariatet (KNSE) |
| url | klagenemndssekretariatet.no → kofa → innkomne/avgjorte saker |
| feed_url | `https://www.klagenemndssekretariatet.no/wp-json/wp/v2/sak` (verifisert 200, 2026-10-15) |
| access_method | WP REST-liste → sakside (HTML-tabell med utfall) → PDF for avgjorte saker |
| authentication | ingen |
| cost | gratis |
| latency | løpende; nyeste sak i REST var samme døgn |
| completeness | 5 022 saker; eldste `2003/1`; kodens gulv er 2017 |
| historical_access | full historikk teknisk tilgjengelig |
| technically_fetchable | **GREEN** — REST, sakside og PDF alle 200; PDF tekstuttrekkbar i 2019/2025/2026 |
| storage_rights / analysis_rights / ai_processing_rights | **ASSUMPTION** (åndsverkloven § 14, vår egen tolkning — kilden sier intet) |
| redistribution_rights | **UNKNOWN** — registrert, blokkerer ikke intern bruk nå (B1 = internt verktøy) |
| gdpr_implications | **FACT**: ingen anonymisering, fulle navn på leverandør og oppdragsgiver i PDF og HTML |
| licence_status | UNKNOWN hos KNSE; Lovdata har samme praksis bak Pro (403) |
| owner · next_action | operatør · ta B3-beslutningen; jurist bekrefter § 14-antakelsen før utadrettet bruk |

## Slik ville vi koblet den (ingen endring gjort)

Alt er bygget: `crm/src/lib/legal/kofa/{robots,plan,page,decision,build,citations,polite,run}.ts`,
cron `0 5 * * *` i `jobs/registry.ts:157`, og verten ligger alt i allowlisten i `crm/src/lib/http.ts`.
**Det gjenstår ingen kode — bare beslutningen.** Og når den tas: senk eller behold 2017-gulvet
bevisst, og skriv behandlingsgrunnlaget for personopplysningene inn i ARCHITECTURE §10 samtidig.
