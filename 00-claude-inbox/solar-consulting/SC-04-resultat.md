# SC-04 resultat: slår ikke baseline

`FACT` Kjørt én gang 2026-10-16T09:02Z, kode `dce0554`, manifest
`3d6e21c0b2a502dc5aaa5d21c80d17fd1a2cd72d8a0f1222efd4125ddad76948`, fixture sha256 `db0536bf…`.
Portene står i [SC-04-FORHANDSREGISTRERING.md](SC-04-FORHANDSREGISTRERING.md) (`da01de7`).
Rådata: [`sc04-dev-2026-10-16.txt`](sc04-dev-2026-10-16.txt) og [`sc04-test-2026-10-16.txt`](sc04-test-2026-10-16.txt).
Metode og valg: [ADR-0020](../../../../decisions/ADR/ADR-0020-triagemodell-sc04.md).

**Port 3: slår ikke baseline.** Køen sorteres ikke etter modellen, og ingenting går i prod.

## Hva som ble testet

Den låste regelen valgte `A-scope` på dev: Platt-skalering av scope regnet fra snapshotet.
**Det er en monoton transformasjon av scope.** Rangeringen er den samme som for scope, så parret
AUC-differanse mot `scope_score` er ~0 per konstruksjon. Det eneste som kan skille dem, er at
modellen regner scope fra snapshot-teksten mens baselinen er `live_scope_score`. Port 1 kunne i
praksis ikke nås. Det modellen faktisk kunne tilføre, var kalibrering, og det er spørsmålet port 2 stiller.

## Tall

| Sett | Rader (ja/nei) | AUC modell | AUC `scope_score` live | Δ | nedre 90 % | Brier modell | Brier baseline |
|---|---|---|---|---|---|---|---|
| **Port-settet** (frosset, inkl. 2 anchored) | 18 (8/10) | 0,450 | 0,519 | −0,069 | −0,200 | 0,351 | 0,348 |
| Uten anchored | 16 (7/9) | 0,444 | 0,579 | −0,135 | −0,262 | 0,348 | 0,338 |
| Bare konkurranse, **ikke målbart** (8 ja < 10) | 14 (8/6) | 0,500 | 0,604 | −0,104 | −0,250 | 0,433 | 0,406 |
| Dialog | 4 (0/4) | udefinert | udefinert | — | — | — | — |

Baselinen på test er `live_scope_score`: dagens scope-modell brukt på rader den ikke er tunet mot.
Operatøren så ikke det tallet da beslutningen ble tatt (scope ble ikke snapshottet). Rekonstruerte
rader finnes ikke i porten, fordi ingen testrad har et snapshottet scope.

## Hvorfor det gikk som det gikk

1. **Snapshotet mangler tekst etter 14.10.** `FACT`: 11 av 18 testrader har tomt `snapshot.summary`
   (median lengde 0, mot 463 tegn på dev, der 32 av 109 er tomme). Scope regnet fra snapshotet blir
   derfor 0 på 17 av 18 testrader, og modellen gir samme sannsynlighet (0,138) til nesten alle. Den
   rangerer ikke, den gjetter basisraten. Årsaken er `UNKNOWN`. Mulige forklaringer er at briefen
   ikke ble generert eller at sammendraget ikke var klart da beslutningen ble tatt. Dette eier SC-03 eller brief-pipelinen.
2. **Basisraten flyttet seg.** ja-andelen er 28 % i dev og 44 % i test. En Platt-skalering fra dev
   undervurderer da systematisk (bøtta 0,0–0,2 har 47 % ja). Kalibreringsgevinsten som kunne gitt
   port 2, overførte seg ikke.
3. **Baselinen selv ligger på myntkast i test.** `live_scope_score` har AUC 0,519 på port-settet.
   Ved 8 ja er standardfeilen rundt ±0,14, så 0,678 fra 13.10 og 0,519 i dag kan begge være støy.
   Men ingenting i testen støtter at `scope_score` skiller ja fra nei på nye beslutninger.

## Læringskurven (dev): når skiller rikere modeller seg fra scope?

10 × 5-fold CV. n treningsrader trekkes fra hver trenfold, og valideringsfoldene er de samme:

| n tren (≈ ja) | A-scope | B-struct4 | E-struct4+emb |
|---|---|---|---|
| 20 (6) | 0,777 | 0,716 | 0,687 |
| 30 (8) | 0,791 | 0,760 | 0,725 |
| 45 (12) | 0,797 | 0,783 | 0,752 |
| 60 (17) | 0,799 | 0,782 | 0,774 |
| 75 (21) | 0,800 | 0,793 | 0,769 |
| 87 (24) | 0,787 | 0,786 | 0,764 |

B tar igjen A rundt 87 rader, men går ikke forbi. E med embeddings stiger fortsatt og ligger
0,02 under ved 87. **Ingen rikere modell skiller seg fra scope innenfor de 109 beslutningene som
finnes.** Når de gjør det, er `UNKNOWN`: kurvene krysser ikke, så et punkt kan ikke ekstrapoleres
ærlig. Det kurven viser, er at scope-signalet er mettet allerede ved ~45 rader. Flere beslutninger
hjelper bare hvis snapshotet bærer et signal scope ikke har.

`ASSUMPTION`: dev-tallene for scope er optimistiske, fordi reglene ble justert mot 97 av disse
beslutningene (PR #144, #147). Læringskurven favoriserer derfor A.

## Hva som gjenstår (ikke gjort, krever andre)

- Finn ut hvorfor `snapshot.summary` er tom på 11 av 18 beslutninger etter 14.10 (SC-03 / brief).
  Uten tekst i snapshotet kan ingen tekstbasert modell læres eller evalueres.
- Snapshot `scope_score` og kvalifikasjonsstatus ved beslutning, så neste evaluering har en ekte
  «det operatøren så»-baseline og en feature som i dag bare finnes som `live_req_*`.
- pgvector (issue 019) er ikke bygget, fordi embedding-likheten ikke ga lift på dev.
- Neste evaluering bør vente på minst én ny beslutningsøkt med fulle snapshots, ikke på et bestemt antall.

## Notat til neste modellrunde (orchestrator-1, 2026-10-16 14:3x)

- Prod-profilen lærer prekvensielt, også av testrader (admin-1, SC-03d). Fra kl. 11:23Z 16.10 er `snap_priority_score` derfor ikke lenger en ren holdout-baseline.
- Når SC-04 kjøres igjen, bruk `profileComputedAt`/`profileN` fra suggestion, og rapporter priorityScore-baselinen på test som «prekvensiell, ikke holdout».
- `scope_score` er ikke påvirket.
