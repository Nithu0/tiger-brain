# Distillert (egne ord, advisory): forecast-kombinering + trend/MR-regler — Nexus-vinkel

*Syntese i egne ord av systematiske prinsipper (ikke bok-tekst). Hjelpemiddel for å tenke riktig sammen med Karri; ikke implementerings-ordre.*

## 1. Forecast-rammeverket (det Nexus mangler mest)
Ideen: hver regel produserer en GRADERT forecast (f.eks. -20..+20) i stedet for binær fire/no-fire. Forecast skaleres så gjennomsnittlig absoluttverdi er konstant (sammenliknbar på tvers av regler), kombineres vektet til én samlet forecast, og kappes ved et tak så ekstreme signaler ikke gir ekstrem posisjon. Posisjon = forecast × vol-target-størrelse (fra vol-targeting-noten).
- **Nexus-relevans:** Nexus' strategier gir i dag binær entry. Å gå gradert (forecast-styrke → posisjons-størrelse) ville: (a) ta små posisjoner på svake signaler, (b) naturlig kombinere flere strategier i stedet for at de fyrer uavhengig. Stor potensiell oppside for det «0 wouldFire / alt-eller-ingenting»-mønsteret vi ser. → Karri-tema (strategi-arkitektur), ikke noe vi rører selv.

## 2. Trend-following (Nexus kjører dette)
- Flere hastigheter samtidig (rask + treg EWMA-crossover), hver vol-normalisert til en forecast, så kombinert. Ikke én enkelt MA-crossover.
- Trend-styrke skalerer posisjon (sterk trend → større, innenfor tak). Lange OG korte.
- **Nexus:** vår trend-following er enkeltsignal/binær. Carvers «flere hastigheter + styrke-skalering» er et testet oppgraderings-mønster. Advisory til Karri.

## 3. Fast mean reversion (Nexus kjører dette)
- Måler avvik fra likevekt i VOLATILITETS-enheter (ikke absolutte pips) → forecast mot bevegelsen. Vol-normalisering er nøkkelen (samme som sizing-poenget).
- «Safer» variant legger på filtre (ikke mean-revert MOT en sterk trend) — direkte relevant for vår over-blokk/dormant-diskusjon: MR skal stå av i sterk trend.
- **Nexus:** vår mean-reversion + mean_revert_gate gjør noe liknende; Carver bekrefter retningen (vol-normalisert avvik + trend-filter). Advisory.

## 4. Regime-bevissthet
Trend og mean-reversion er motsatte; å allokere mellom dem etter regime (trend vs range) er et kjernepoeng. Knytter rett til vår regime-direction-gate + ADX-arbeidet (ai-1) — når ADX/regime faktisk biter, er regime-betinget strategi-allokering det neste naturlige steget. Advisory.

## Oppsummert for Karri-samtaler
Tre konkrete ting denne boka støtter: (1) vol-targeting-sizing (egen note), (2) gradert forecast i stedet for binær fire, (3) regime-betinget allokering trend↔MR. Alle tre er strategi-arkitektur → Karri eier beslutningen; dette er kunnskaps-grunnlaget.

*Gjenstår å distillere: breakout/value/acceleration-detaljer, dynamic optimisation, carry (mindre Nexus-relevant). Tas i senere sykluser.*
