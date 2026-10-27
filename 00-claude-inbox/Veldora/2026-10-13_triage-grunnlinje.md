# Triage-grunnlinje (autoritativ)

`FACT` Målt mot produksjon read-only 2026-10-13T08:42Z, kode `6cc89c2`.
Rådata: [`triage-baseline-2026-10-13.txt`](triage-baseline-2026-10-13.txt).
Reproduser: `cd projects/anbud/crm && ./scripts/baseline/run-triage-baseline.sh`
(krever `railway link --project anbud --environment production`; hele SQL-en kjører i en
transaksjon med `SET TRANSACTION READ ONLY`, så Postgres avviser skriving på serversiden).

Denne filen er grunnlinjen alt annet måles mot. Endrer et tall seg, kjør skriptet på nytt og
legg et nytt datert artefakt ved siden av — ikke rediger tallene her uten en kjøring bak dem.

## 1. Hvor mange saker ligger i køen

| Størrelse | Tall | Kilde (tag i artefaktet) |
|---|---|---|
| Kunngjøringer totalt | 1750 | `QUEUE_TENDERS` |
| Muligheter totalt | 907 | `QUEUE_TOTAL` |
| **Køkvalifiserte** (UNDECIDED + spotted/screening + frist i framtiden eller ukjent) | **758** | `QUEUE_ELIGIBLE` |
| …fordelt: spotted 759 · declined 64 · expired 49 · screening 35 | 907 | `QUEUE_STATUS` |

Kø-predikatet speiler `crm/src/lib/triage.ts:queueWhere` (359-371).

## 2. Hvor mange har en menneskelig ja/nei

| | Tall | Andel |
|---|---|---|
| Beslutninger totalt | **105** | — |
| ja (STRONG_BID 24 + BID 6) | **30** | 28,6 % |
| nei (NO_BID) | **69** | 65,7 % |
| undersøk (INVESTIGATE) | 6 | 5,7 % |

Basisraten for ja blant ja/nei er **30/99 = 30,3 %**; mot alle 105 er den 28,6 %. Begge brukes
nedenfor der det er relevant — oppgi alltid hvilken.

Etikettene er **to arbeidsøkter**, ikke en tidsserie: 11.10 → 72, 12.10 → 24, 13.10 → 7,
09.10 → 1, 04.10 → 1 (`DEC_PER_DAY`). Random K-fold lekker øktkontekst; bruk tids-splitt.

Feltdekning (`DEC_FIELD_COVERAGE`): `confidence` 103/105 · `agent_verdict` 104/105 ·
`duration_ms` 103/105 · `snapshot` 105/105 · `primary_reason` 105/105.
`agent_verdict` (`DEC_VERDICT`): vet-ikke 45 · riktig 25 · **for-høy 24** · **for-lav 10**
→ 59 retningsgivende kalibreringsetiketter. Ingen kode leser dem.

Nei-årsaker (`DEC_REASON_NEI`): scope 39 · competence-gap 13 · not-a-tender 6 · too-large 5 ·
qualification 3 · deadline 2 · other 1. **`core-fit` er ikke en nei-årsak** — den står på 23
STRONG_BID. Tabellen i issue 050 er ikke filtrert på NO_BID.

Tidsbruk (`DEC_SECONDS`, snitt): INVESTIGATE 621 s · BID 249 s · NO_BID 207 s · STRONG_BID 156 s.
Én falsk positiv i køen koster ~3,5 minutter operatørtid. Det er prisenheten for presisjon.

## 3. Scope-sporenes faktiske treff

Scope-kategori er **ikke et filter i dag**: kun valgfritt `?kategori=`, av som standard
(`lib/triage.ts:367`), og sporene endrer aldri ingest eller fitScore (`config/tracks.ts:3-6`).
Tallene under er derfor **kontrafaktiske** — hva et filter ville gjort — målt mot kategorien
produksjonen faktisk beregnet (`SCOPE_CONFUSION`):

|  | BEHOLDT | KUTTET |
|---|---|---|
| ja (30) | 26 | **4 → 13,3 % av ja tapt** |
| nei (69) | 21 | **48 → 69,6 % av nei kuttet** |
| undersøk (6) | 4 | 2 |

Presisjon for ja blant beholdte: 26/51 = **51,0 %** mot basisrate 28,6 % → **lift 1,78×**.
Recall 86,7 %. Spart tid: 48 × 207 s ≈ **2,8 timer per 105 saker**.

Ja/nei per kategori (`SCOPE_PER_CAT`): fagsystem 13/11 · utvikling-ki 8/7 · undersokelser 2/1 ·
rapportering 1/0 · dokument-ai 1/1 · oversettelse 1/0 · solenergi 0/1 · utenfor-scope 4/48.
Køen (`SCOPE_QUEUE_DIST`): 809/907 = **89,2 % utenfor-scope**.

**Dette bekrefter code-1 (69,6 % nei kuttet, 13,3 % ja tapt).** PR #144s «8 av 30 ja (27 %)» er **ikke** et metodefeil-artefakt — det var riktig for koden PR #144 målte på. Samme dag utvidet PR #147 (`1f4f761`, «widen utvikling-ki coverage, evaluated against the 97 decisions») sporet med `ux`, `brukeropplevelse`, `tjenestedesign`, `artificial intelligence` og digitaliserings-ord, nettopp for å hente tilbake ja-er som falt utenfor. Issue 050s statuslinje er derfor bare utdatert — den er skrevet før fiksen som landet etter den. Akseptkriteriet bør vurderes mot dagens 13,3 %, ikke mot 27 %. (Se rettelsen 13.10 nederst for målingen som avkreftet min første forklaring.)

## 4. Hvor mange har verdi

| Populasjon | Med verdi | Andel | Tag |
|---|---|---|---|
| **Køkvalifiserte muligheter (758)** | **386** | **50,9 %** | `VALUE_QUEUE_ELIGIBLE` |
| Alle kunngjøringer (1750) | 949 | 54,2 % | `VALUE_TENDERS` |
| Beslutnings-snapshot (105) | 49 | 46,7 % | `VALUE_SNAPSHOT` |
| `opportunities.estimated_value` (907) | 70 | **7,7 %** | `VALUE_OPPS` |

**«Verdi finnes på ~1 av 5» er utdatert.** Den stammer fra 118/546 (21,6 %) målt 11.10
(`lib/brief.ts:256-258`); `verdi-backfill` og `verdi-tekstpromotering` har kjørt siden, og i dag
har **halvparten** av køen en verdi. Det som fortsatt er tomt er køkolonnen
`opportunities.estimated_value` (7,7 % mot kildens 54,2 %) — ser ut som et propageringshull;
skrivebanen er ikke lest, så årsaken er `UNKNOWN`.

## 5. Hva CPV faktisk skiller

Kontrafaktisk filter «behold saken hvis minst én kode treffer våre prefikser»
(72, 48, 79, 30, 64 + 09331, 09332, 45261215, 31712331 fra `config/verticals.ts`) —
`CPV_FILTER_CONFUSION`:

|  | BEHOLDT | KUTTET |
|---|---|---|
| ja (30) | **30** | 0 |
| nei (69) | **64** | 5 |
| undersøk (6) | 6 | 0 |

Presisjon 30/100 = **30,0 %** mot basisrate 28,6 % → **lift 1,05×**. CPV er ikke et svakt
filter, det er **ingen filter**: det kutter 5 av 69 nei. Konklusjonen i issue 050 er riktig;
tallet «~1 ja per 2 nei» undervurderer hvor ubrukelig det er.

Per divisjon, **kodeforekomster** (en sak bærer flere koder, så summene overstiger 105) —
`CPV_DIV`, divisjoner med ≥ 5 forekomster:

| Divisjon | ja | nei | ja-andel |
|---|---|---|---|
| 48 Programvare | 68 | 128 | 34,7 % |
| 72 IT-tjenester | 66 | 136 | 32,7 % |
| 79 Rådgivning | 15 | 30 | 33,3 % |
| 80 Utdanning | 3 | 6 | 33,3 % |
| 71 Arkitekt/teknisk | 2 | 19 | 9,5 % |
| 73 FoU | 1 | 13 | 7,1 % |
| 30 IT-maskinvare | **0** | 17 | 0 % |
| 33 Medisinsk | 0 | 11 | 0 % |
| 34 Transport | 0 | 9 | 0 % |
| 45 Bygg | 0 | 9 | 0 % |
| 75 Offentlig adm. | 0 | 7 | 0 % |
| 22 Trykk | 0 | 6 | 0 % |
| 38 Lab | 0 | 6 | 0 % |
| 90 Avfall/miljø | 0 | 5 | 0 % |

Våre tre tyngste divisjoner ligger alle **på** basisraten — de bærer ingen informasjon.
Divisjon **30 (IT-maskinvare) står i `VERTICAL_CONFIGS` med vekt 0,2 og har 0 ja / 17 nei**;
det er den ene CPV-regelen tallene faktisk gir grunnlag for å fjerne.

Skjemanote: CPV er ikke en kolonne. `tenders.cpvCodes` er et Payload hasMany-text-felt og ligger
i `tenders_texts (parent_id, path='cpvCodes', text)` — 9167 rader. Enhver CPV-analyse må gå dit.

## 6. Skiller dagens score ja fra nei? (`SCORE_AUC`)

| Score | AUC |
|---|---|
| `fitScore` | 0,577 |
| `priorityScore` | 0,549 |
| `winProbability` (wp-2) | 0,575 |
| `opportunities.scope_score` | **0,678** |

n_ja = 30, n_nei = 69. Ved 30 positive er 95 %-CI på AUC ca. ±0,11, så alt under ~0,61 er
**uskillbart fra myntkast**. Bare `scope_score` er utenfor støyen. Det samme regnestykket finnes
allerede i produksjon (`lib/learning/agreement.ts`, eksponert på `GET /triage/stats`); ingen
leser det.

## 7. Utfall fra leverte tilbud

Egne tilbud: `bid_drafts` = **1** (`OUTCOMES_OUR_BIDS`). Det finnes ingen utfallsetiketter fra
leverte tilbud, så ingenting kan læres fra utfall i dag, og kontekstuelle bandits er utelukket.
Markedstildelinger finnes derimot: `awards` = **552**, hvorav **498 har `bidder_count`**
(`OUTCOMES_MARKET_AWARDS`) — grunnlaget for konkurransefaktorer og base rates.

## Hva dette betyr for rangeringsarkitekturen (fase 5)

Ingen anbefaling her, bare grensene tallene setter:
1. 30 positive. Modellklasser tyngre enn ~5 trekk kan ikke valideres på dette settet.
2. To merkeøkter. Validering må være tids-splittet, ikke tilfeldig.
3. CPV er ikke et filter (lift 1,05×). Scope-evidens er det eneste målbare signalet (AUC 0,678).
4. Halvparten av køen har verdi — verdi kan brukes som trekk, men ikke forutsettes.
5. Ingen utfallsetiketter. Alt «læring fra faktiske utfall» er blokkert til tilbud registreres.
