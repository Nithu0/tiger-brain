# Distillert (egne ord): Carvers vol-targeting / risk-scaling — anvendt på Nexus

*Advisory-kunnskap for å hjelpe Karri tenke riktig om sizing/strategi. IKKE en implementerings-ordre. Syn_tese i egne ord, ikke bok-tekst.*

## Kjerne-idé: størrelse skal styres av VOLATILITET, ikke av stop-avstand
Carvers rammeverk sizer hver posisjon slik at dens FORVENTEDE risiko-bidrag treffer et fast risk-mål, ved å dele risk-målet på instrumentets volatilitet:
  posisjon ∝ (kapital × årlig risk-mål) / (instrumentets annualiserte volatilitet × kontraktverdi)
→ Størrelse blir OMVENDT proporsjonal med volatilitet: høy-vol = mindre posisjon, lav-vol = større. Den «kjenner» hvor mye instrumentet faktisk beveger seg.

## Hvorfor dette er motgiften mot 04-21-blowupen
Nexus sizer i dag = dollarRisk / SL-avstand. En trang $4 SL ga 106 units (fordi liten nevner → enorm størrelse). Det er **stop-avstand-drevet**, ikke volatilitet-drevet — så en vilkårlig trang SL blåser opp posisjonen.
Vol-targeting hadde sized på XAUs FAKTISKE volatilitet (ATR-basert), ikke på den trange SL-en → posisjonen ville vært langt mindre og bundet, helt uavhengig av hvor stop-en tilfeldigvis lå.
- max-units-breakeren (PR #61/#67) er en HARD takhatt — fanger ekstremer.
- vol-targeting er den STRUKTURELLE fiksen — gjør at oversizing aldri oppstår i utgangspunktet.
→ #1 sak å reise med Karri om sizing-policy: bytte/komplettere SL-avstand-sizing med ATR/vol-targeting. (Vi har allerede ATR fra INDICATOR_OANDA_FALLBACK når ai-1 fikser ADX.)

## Andre overførbare konsepter
- **Forecast-skalering:** kombiner signaler til én gradert forecast og skaler posisjon etter STYRKE (svakt signal → liten posisjon). Nexus' binære fire/no-fire kan gjøres gradert.
- **Risk-allokering på tvers av strategier:** de 30 er ment å kjøre SAMMEN med risiko fordelt — ikke én stor bet. Relevant siden Nexus kjører flere strategier samtidig.
- **Vol-estimat:** bruk eksponentielt vektet nylig volatilitet som sizing-input (vi har ATR-infra).

## Nexus-relevante strategi-familier (Carver gir testede regel-spesifikasjoner)
- Slow/fast trend following (Nexus: trend-following) · Fast mean reversion (Nexus: mean-reversion) · Breakout (Nexus: session-breakout/breakout-continuation) · Vol-regime-veksling (Nexus: vol-expansion).
- Mindre direkte (futures-spesifikt, Nexus er XAUUSD spot/CFD): carry, calendar, cross-instrument spreads.

## Hvordan dette brukes
- Når vi/Karri fikser sizing eller en strategi: dette er referansen for «hva er den riktige måten». Vol-targeting-poenget er konkret nok til en Karri-proposal (komplement til breakeren).
- Resten av boka distilleres progressivt (autonome sykluser) inn i Brain.
