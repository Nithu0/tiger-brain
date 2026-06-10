# Distillert (egne ord, advisory): pysystemtrade vol-targeting sizing → Nexus

*Syntese av Carvers rammeverk slik det er implementert i pysystemtrade (`systems/positionsizing.py`). GPL → kun lært tilnærming, ingen kode kopiert. Hjelpemiddel for Karri-sizing-arbeid, ikke implementert.*

## Kjeden (slik pysystemtrade bygger en posisjon)
1. **Daglig cash-vol-mål** — velg hvor mange valuta-enheter risiko per dag du sikter på (f.eks. konto × årlig vol-mål, omregnet til daglig). Dette er «hvor mye skal denne posisjonen ÅNDE per dag».
2. **Instrumentets daglige %-volatilitet** — estimer (EWMA av nylige bevegelser). For Nexus: vi har ATR allerede.
3. **Instrumentets cash-volatilitet** = pris × block-verdi × %-vol × FX → «hvor mange valuta-enheter beveger 1 enhet av instrumentet seg per dag».
4. **Volatilitets-scalar** = (daglig cash-vol-MÅL) / (instrumentets cash-volatilitet) → basis-posisjonen som treffer risiko-målet. **Dette er kjernen: størrelse ∝ 1/volatilitet.**
5. **Skaler med forecast** = vol-scalar × (kombinert forecast / forecast-cap). Sterkt signal → større (opp til cap), svakt → lite.

## Hvorfor dette er motgiften mot Nexus-blowupen (04-21)
- Nexus i dag: `size = dollarRisk / stopLossPoints`. Nevneren er STOP-AVSTAND (vilkårlig, kan være trang) → trang $4 SL = 106 units.
- pysystemtrade: nevneren er INSTRUMENTETS VOLATILITET. En trang stop påvirker IKKE størrelsen — bare volatiliteten gjør. Størrelse blir bundet av hvor mye XAU faktisk beveger seg, ikke av hvor man tilfeldigvis la stopen.
- **Konkret for Karri:** bytt sizing-nevneren fra stop-avstand til en ATR-basert cash-volatilitet (vi har ATR via INDICATOR_OANDA_FALLBACK når ai-1s ADX-fix lander). Behold max-units-breakeren som hardt tak. Da er både den strukturelle årsaken (oversizing oppstår ikke) OG halen (breaker) dekket.

## Tilleggsmønstre verdt å merke
- **Forecast-cap:** posisjon kappes ved et forecast-tak → ingen enkelt-signal kan gi ekstrem posisjon. (Nexus mangler dette — binær fire.)
- **Subsystem → portefølje:** hver strategi sizes til SITT vol-mål, så vektes på tvers → samlet risiko styres på porteføljenivå, ikke per-trade. Relevant siden Nexus kjører flere strategier samtidig.
- **FX-omregning:** ikke relevant for XAUUSD (allerede USD-kvotert), men greit å vite at rammeverket håndterer det.

## Status
Karri-grunnlag klart: vol-targeting-sizing er nå dokumentert både konseptuelt (Carver-bok) og i implementasjon (pysystemtrade). Konkret nok til en sizing-proposal når ai-1s ADX/ATR-data er live. Advisory — Karri eier beslutningen.
