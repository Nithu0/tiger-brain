# Brief-dekning i triage-køen — målt mot produksjon

**Dato:** 2026-10-11 · **Pane:** data-1 · **Oppdrag:** dispatch fra code-1, inbox/data-1.md
**Metode:** ren lesing mot Railway-prosjektet `anbud`, miljø `production` (PostgreSQL 18.6, base `railway`).
Spørringene kjørte via `railway ssh -s Postgres` med `SET default_transaction_read_only = on`.
Ingen skriving, ingen kodeendring, ingen migrasjon. Ingen legitimasjon er lest eller skrevet ut.

**Kødefinisjon brukt** (kopiert fra `queueWhere`, `crm/src/lib/triage.ts:220-232`):
`decision = 'UNDECIDED'` og `status IN ('spotted','screening')` og (`tender.deadline > now()` eller frist mangler).

---

## Konklusjon

Panelet «Om anskaffelsen» vil stå nesten tomt for de mulighetene operatøren åpner først.
Årsaken er ikke brief-generatoren. Den kjører. Årsaken er at `documents` i produksjon har **null rader**,
og uten dokumenttekst finnes det ingenting å sitere fra. Feltene får verdi fra Doffin-kunngjøringen,
men sitat- og sidehenvisningslaget er i praksis ubygd.

Ikke bygg panelet rundt sitater og kildehenvisninger før dokumentinntaket gir rader.

---

## 1. De 20 nyeste mulighetene (oppdraget slik det var formulert)

Sortert på `opportunities.created_at DESC`, filtrert på kødefinisjonen over.

FACT: alle 20 er tomme. Null briefer, null krav.

| Mål | Verdi |
|---|---|
| Muligheter i utvalget | 20 |
| Med brief | 0 |
| Krav totalt i utvalget | 0 |

De 20 nyeste er opprettet mellom 2026-10-09 08:30 og 2026-10-10 07:30. De er altså nyinntatt
og ikke berørt av noen agent ennå.

**Merk:** `created_at`-sortering er ikke det operatøren ser. Triage-køen sorteres av `sortQueue`
(`crm/src/lib/triage.ts:232-250`): NO_FIT sist, så `priorityScore` synkende, så frist stigende.
Måling på «de 20 nyeste» treffer derfor systematisk de minst bearbeidede radene. Jeg målte begge.

## 2. Topp 20 slik operatøren faktisk ser køen

Samme filter, sortert som `sortQueue`. `fakta` = antall faktafelt med både `value` og `quote`
av 11 mulige. `krit` = tildelingskriterier med vekt av totalt antall.

| id | score | frist | brief | fakta | krit | kval | sikk | risk | omfang | anbefaling | krav | m/sitat | m/side |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 415 | 67 | 11-02 | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 12 | 0 | 0 |
| 19 | 67 | 11-03 | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 0 | 0 | 0 |
| 440 | 66 | 11-02 | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 4 | 0 | 0 |
| 8 | 66 | 11-03 | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 0 | 0 | 0 |
| 577 | 66 | 11-05 | ja | 1/11 | 0/0 | 0 | 0 | 2 | mangler | investigate | 0 | 0 | 0 |
| 699 | 66 | 11-09 | ja | 1/11 | 0/0 | 0 | 0 | 0 | mangler | investigate | 1 | 1 | 0 |
| 109 | 66 | – | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 2 | 0 | 0 |
| 354 | 64 | – | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 0 | 0 | 0 |
| 95 | 63 | 10-20 | ja | 1/11 | 0/0 | 0 | 1 | 10 | mangler | investigate | 15 | 0 | 0 |
| 39 | 63 | – | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 0 | 0 | 0 |
| 51 | 63 | – | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 0 | 0 | 0 |
| 390 | 63 | – | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 0 | 0 | 0 |
| 413 | 63 | – | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 0 | 0 | 0 |
| 452 | 63 | – | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 0 | 0 | 0 |
| 821 | 62 | 11-13 | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 0 | 0 | 0 |
| 221 | 62 | – | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 10 | 0 | 0 |
| 634 | 61 | – | ja | 2/11 | 0/0 | 0 | 0 | 2 | mangler | investigate | 2 | 2 | 0 |
| 814 | 60 | 10-15 | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 0 | 0 | 0 |
| 293 | 60 | 10-22 | ja | 1/11 | 0/0 | 0 | 0 | 9 | mangler | investigate | 12 | 0 | 0 |
| 314 | 60 | 10-27 | nei | 0/0 | 0/0 | 0 | 0 | 0 | mangler | – | 8 | 0 | 0 |

FACT: 5 av 20 har brief. Der briefen finnes, er 1–2 av 11 faktafelt komplette.
Ingen av de 20 har et eneste tildelingskriterium. Ingen har sidehenvisning på noe krav.
Alle fem anbefalingene er `investigate`.

## 3. Faktafelt — dekning over alle 56 briefer i basen

«Komplett» betyr at både `value` og `quote` er satt, altså at panelet kan vise verdien *og* vise hvor den kommer fra.

| Faktafelt | Har verdi | Har sitat | Komplett | Komplett % |
|---|---|---|---|---|
| oppdraget | 56 | 56 | 56 | 100 |
| kontraktstype | 9 | 9 | 9 | 16 |
| tilbudsfrist | 47 | 1 | 1 | 2 |
| kontraktsstart | 1 | 1 | 1 | 2 |
| cpv | 56 | 0 | 0 | 0 |
| oppdragsgiver | 56 | 0 | 0 | 0 |
| prosedyre | 44 | 0 | 0 | 0 |
| verdi | 28 | 0 | 0 | 0 |
| kontraktslengde | 20 | 0 | 0 | 0 |
| sporsmalsfrist | 0 | 0 | 0 | 0 |
| vedstaelsesfrist | 0 | 0 | 0 | 0 |

Mønsteret er skarpt: feltene som kan hentes fra kunngjøringen har verdi, men ingen sitat.
`oppdraget` er det eneste som er komplett, og det er fordi teksten er sitatet.

## 4. Seksjoner i `briefs.content` (n = 56)

| Seksjon | Antall briefer | % |
|---|---|---|
| risks > 0 | 51 | 91 |
| requirementsSnapshot > 0 | 35 | 63 |
| security > 0 | 7 | 13 |
| qualification > 0 | 2 | 4 |
| awardCriteria > 0 | 1 | 2 |
| omfang finnes i det hele tatt | 0 | 0 |
| recommendation.lean satt | 56 | 100 |

FACT: alle 56 briefer har `recommendation.lean = 'investigate'` og `model = claude-sonnet-5-5`.
Anbefalingsfeltet er alltid utfylt og alltid likt. Det skiller ingen anbud fra noe annet,
så i panelet bærer det null informasjon.

FACT: `omfang` finnes ikke på en eneste rad. Feltet er nyere enn `BRIEF_VERSION`, som fortsatt
står på `brief-1`, så versjonsnummeret kan ikke brukes til å avgjøre hvilke felt en rad har.

## 5. Krav i hele køen

| Mål | Verdi |
|---|---|
| Muligheter i køen | 783 |
| Herav med brief | 52 (6,6 %) |
| Herav med minst ett krav | 58 (7,4 %) |
| Krav totalt | 269 |
| Krav med `obligation` | 269 (100 %) |
| Krav med `source_quote` | 90 (33 %) |
| Krav med `source_ref.kind` | 90 (33 %) |
| Krav med `source_ref.page` | 0 (0 %) |

## 6. Rotårsak

FACT: tabellen `documents` i produksjon har **0 rader**.

Det forklarer hver enkelt observasjon over. `source_ref.page` forutsetter et dokument med sidetall.
Tildelingskriterier, kvalifikasjonskrav og sikkerhetskrav står i konkurransegrunnlaget, ikke i
kunngjøringen. Uten dokumenttekst kan brief-generatoren bare lese kunngjøringen, og da får den
verdier uten sitater. De 33 % av kravene som har `source_quote` har også `source_ref.kind`,
ASSUMPTION: de er merket `notice`, ikke `document`.

Dokumentdekning er tools-1 sin lane i dagens dispatch. Jeg har ikke gått videre inn i den.

### Pipeline-ferskhet

| Mål | Verdi |
|---|---|
| Nyeste mulighet opprettet | 2026-10-10 07:30 |
| Nyeste brief generert | 2026-10-11 09:38 |
| Eldste brief generert | 2026-10-04 23:06 |
| Nyeste krav opprettet | 2026-10-07 23:05 |
| Muligheter opprettet siste 7 døgn | 337 |
| Briefer generert siste 7 døgn | 56 |

Brief-jobben kjørte så sent som i dag, men den tar inn 56 mens inntaket leverer 337 i samme uke.
Kravuttrekket har ikke skrevet en rad siden 7. oktober.

## 7. De tre feltene som oftest er tomme

Oppdraget ba om tre. Rangert etter hvor mye de ødelegger for panelet:

1. **`source_ref.page` på krav** — 0 av 269 i hele køen. Et krav kan ikke spores til en side i noe dokument.
2. **`awardCriteria`** — 1 av 56 briefer har noen i det hele tatt, og ingen av de 20 øverste i køen.
   Et anbudspanel uten tildelingskriterier mangler det operatøren faktisk vurderer på.
3. **`quote` på faktafeltene** — 10 av 11 felt ligger under 20 % komplett, sju av dem på null.
   Panelet kan vise tall, men ikke belegge dem.

Rett bak: `sporsmalsfrist` og `vedstaelsesfrist` er tomme på alle 56 briefer, og `omfang` finnes ikke på noen rad.

## 8. Hva dette betyr for panelet

Bygget slik det er skissert vil «Om anskaffelsen» for de 20 øverste i køen vise:
tittel og oppdragstekst, en risikoliste på de fem som har brief, en anbefaling som alltid sier
`investigate`, og ellers tomme felt. For de 15 uten brief vises ingenting.

Anbefaling, ASSUMPTION om hva operatøren vil med panelet:

- La hvert felt ha en eksplisitt tom-tilstand som sier *hvorfor* det er tomt, ikke bare blank.
  «Ikke hentet ut ennå» og «finnes ikke i kunngjøringen» er to forskjellige ting for operatøren.
- Ikke vis `recommendation.lean` før den kan si noe annet enn `investigate`.
- Vent med sitat- og sidehenvisnings-UI til `documents` har rader. I dag vil det bare vise tomme felt.
- Hvis panelet skal demonstreres i dag, bruk en mulighet med brief (id 95, 293, 577, 634 eller 699),
  ikke toppen av køen.

## 9. Avgrensninger

- UNKNOWN: hvorfor `documents` er tom. Jeg har ikke undersøkt dokumentinntaket, det ligger i tools-1 sin lane.
- UNKNOWN: om kravuttrekkets stopp 7. oktober er en feil eller bare mangel på dokumenter å trekke fra.
- Målt på produksjon slik basen sto 2026-10-11 rundt kl. 12 UTC. Tallene flytter seg når jobbene kjører.
- `fit_score`/`priority_score` er gjengitt avrundet i tabell 2.
- Jeg replikerte `sortQueue` i SQL. Den virkelige sorteringen skjer i TypeScript etter at Payload har
  hentet radene, så rekkefølgen i tabell 2 kan avvike noe fra UI ved likt score og lik frist.

## Spørringene

Lagret i sesjonens scratchpad, ikke i repoet: `q1_per_opp.sql`, `q2_per_felt.sql`, `q3_totaler.sql`,
`q4_ui20.sql`, `q5_felt.sql`, `q6b.sql`. Alle er rene SELECT-er med read-only-transaksjon.
