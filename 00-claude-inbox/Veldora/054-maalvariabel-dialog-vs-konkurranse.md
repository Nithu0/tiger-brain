# 054: Målvariabelen blander «vil by på» med «verdt å svare på i en dialog»
Type: HITL
Status: open
Priority: laering
Blocked-by: ingen (men gater alle rangeringsoppgaver)

## Hvorfor

`FACT` (målt i prod 2026-10-13, 105 beslutninger, `crm/eval/sakstype-kryss-2026-10-13.txt`,
skript `crm/scripts/baseline/sakstype-kryss.sql`): fordelt på kildens eget felt
`tenders.notice_type`:

| Sakstype | Beslutninger | ja | nei |
| --- | --- | --- | --- |
| COMPETITION (tildeling å vinne) | 60 | 17 | 39 |
| PLANNING (veiledende kunngjøring / markedsdialog) | 45 | 13 | 30 |

**13 av 30 ja — 43 % — er førkonkurranse-dialog.** Et ja der er en relasjonshandling: det finnes
ingen kontrakt å vinne. Et ja på en COMPETITION er en intensjon om å levere tilbud.

`FACT` `sideOf` (`crm/src/config/decisionReasons.ts:70-71`) mapper
`STRONG_BID|BID|INVESTIGATE → approve` og `NO_BID → reject`, og `DecisionRecord.approve` er
`boolean|null` (`crm/src/lib/learning/types.ts:47`). `buildProfile`
(`crm/src/lib/learning/profile.ts:156-203`) ser derfor **ingen forskjell** på de to. Lifts,
`proposedRules` og preferanseleddet på ±10 priority-poeng (`crm/src/lib/scoring/priority.ts:298`)
læres på en blandet målvariabel.

`FACT` Populasjonen er dessuten **inkonsistent i dag**: `isLearnable` (`profile.ts:41`) ekskluderer
rader med årsakskoden `not-a-tender`, og alle 6 slike rader er PLANNING **og alle er nei**. Seks
dialoger er altså korrekt utelatt, mens 13 andre dialoger trener profilen som konkurranser. Samme
sakstype, to behandlinger, avhengig av om operatøren tilfeldigvis krysset `not-a-tender`.

`FACT` PLANNING er 202 av 1750 kunngjøringer (11,5 %) men 45 av 105 beslutninger (43 %) —
dialoger triageres ~4× så ofte som andelen tilsier. **Årsaken er `UNKNOWN`** og er et
operatørspørsmål, ikke noe som kan måles fram (se § Spørsmål til operatøren).

Dette er ikke en tellefeil. Det er en feil i **hva modellen lærer**, og den gjelder 43 % av
ja-ene. Derfor gater den rangeringsarbeidet: enhver ny score vil bli validert mot en målvariabel
som blander to utfall.

Beslektet: [053](053-dialoger-og-rfi.md) løser det samme skillet i **triagen** (merking, visning).
Denne saken er **læringssiden**: hva målvariabelen skal være. 053 kan lande uten 054, men 054 bør
bruke 053s merking når den finnes, ikke innføre en konkurrerende.

## What to build

Ikke én modell — ett skille, og det gjøres i to trinn fordi datavolumet er lite.

1. **Del populasjonen** (lite, deterministisk, ingen modellendring): `buildProfile` lærer bare på
   `notice_type = 'COMPETITION'`. Det gir 56 lærbare rader (17 ja / 39 nei) i stedet for 99
   blandede. Dialoger beholdes i basen og i triagen, men påvirker ikke preferanseleddet.
2. **Gi dialoger sin egen behandling** i stedet for å arve konkurranse-profilen: enten en egen,
   enklere regel (sakstype + fagområde), eller ingen lært justering i det hele tatt til det finnes
   nok rader. `ASSUMPTION` — med 13 ja holder det ikke til en egen profil; det bør måles, ikke antas.
3. **Slutt å kollapse gradene** samtidig: `INVESTIGATE → approve` (`decisionReasons.ts:70`) gjør
   «undersøk» til «vil by på». 6 rader i dag, men skillet er gratis å bevare og dyrt å gjenopprette.

Rekkefølgen er bevisst: trinn 1 er en linje i `learnableRecords` og kan måles mot nullmålingen med
én gang. Trinn 2 og 3 er beslutninger, ikke kode.

## Acceptance criteria

- [ ] `buildProfile` læres på en populasjon der sakstype er eksplisitt, ikke tilfeldig (ingen rad
      er inne bare fordi `not-a-tender` ikke ble krysset).
- [ ] `profile.n` rapporterer hvilken populasjon den gjelder, så 30-terskelen ikke blir
      sammenlignet på tvers av to ulike utvalg.
- [ ] Målt mot `crm/eval/fixtures/tender-decisions-2026-10-13.json` **før og etter**: hvordan
      flytter lift og preferanseleddet seg når dialogene tas ut? Tallet rapporteres, uansett
      fortegn. Blir det dårligere, er det også et svar.
- [ ] Ingen endring i hva operatøren ser i triagen (dette er læringssiden; 053 eier visningen).

## Spørsmål til operatøren (HITL — derfor er saken ikke AFK)

Dialoger triageres fire ganger så ofte som andelen i korpuset tilsier. Tre forklaringer med helt
ulik konsekvens, og bare operatøren vet hvilken:

1. **De er lettere å vurdere** (kortere tekst, mindre krav) → da er overrepresentasjonen en
   artefakt av tidsbruk, og vektingen bør ikke lære av den.
2. **De dukker opp høyere i køen** → da er det køsorteringen som skaper mønsteret, og vi lærer av
   vårt eget UI.
3. **Du prioriterer relasjonsbygging bevisst** → da er et dialog-ja et *mål*, ikke støy, og det
   skal ha sin egen rangering og sitt eget suksessmål — ikke arve konkurranse-profilen.

`FACT` til sammenligning: INVESTIGATE tar 621 s i snitt mot NO_BID 207 s, så «lettere å vurdere»
er ikke åpenbart sant for alle typer (`crm/eval/triage-baseline-2026-10-13.txt`, `DEC_SECONDS`).

## Kilder

- `crm/eval/sakstype-kryss-2026-10-13.txt` (tagger `SAKSTYPE`, `ENHET`, `LAERBAR`, `SAKSTYPE_KO`)
- `crm/eval/triage-baseline-2026-10-13.txt` (`DEC_SECONDS`, `DEC_BY_SIDE`)
- `crm/src/lib/learning/profile.ts:41,156-203` · `crm/src/config/decisionReasons.ts:70-71`
- `crm/src/lib/learning/types.ts:47` · `crm/src/lib/scoring/priority.ts:298`
- Reproduser: `cd projects/anbud/crm && ./scripts/baseline/run-triage-baseline.sh --sql sakstype-kryss.sql`
