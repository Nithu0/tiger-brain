# Karri-brief: kunnskapsbasert forbedrings-grunnlag for Nexus (konsolidert)

*ai-2 syntese (egne ord) av 4 kilder: Carver *Advanced Futures* + *Systematic Trading*-rammeverket (pysystemtrade), nautilus_trader, *Successful Algorithmic Trading*. ADVISORY — Karri eier alle beslutninger. Klar til å sendes Karri når ai-1s ADX/ATR-data er live (da har vi inputene forslagene trenger).*

## Prioritert (treffer Nexus' faktisk diagnostiserte svakheter)

### P1 — Vol-targeting-sizing (motgift mot 04-21-blowupen)
Problem: `size = dollarRisk / SL-avstand` → trang $4 SL ga 106u.
Forslag: bytt nevneren fra stop-avstand til ATR-basert cash-volatilitet (størrelse ∝ 1/volatilitet). Behold max-units-breakeren (#61/#67) som hardt tak. Tre uavhengige kilder (Carver, pysystemtrade, Halls-Moore/Kelly) støtter dette.
Forutsetning: ATR live (INDICATOR_OANDA_FALLBACK når ai-1s ADX-fix lander).
Karri-beslutning: formel + mål-volatilitet + om vi går gradvis (shadow først).

### P2 — Paper-execution-fidelity (ærligere lærings-signal)
Problem: paper fyller på eksakt pris; ingen spread/slippage → paper-PnL optimistisk → mater calibration/lessons feil.
Forslag: spread-modell (kjøp ask/selg bid fra OANDA) + slippage-modell (kalibrert mot fill-drift-loggen). Penge-nært (endrer simulert PnL) → Karri.

### P3 — Out-of-sample-disiplin på autotune (overfitting-vakt)
Problem: SAFE_AUTO_APPLY kan overfitte på tynt/blowup-skjevt utvalg.
Forslag: Karris ±20%/min-30-bounds er god start; legg til OOS-validering før tunede vekter får full vekt. Optimisation-bias er den klassiske fellen her.

### P4 — Gradert forecast (mot 0-wouldFire/binær fire)
Forslag: la strategiene gi gradert forecast (-N..+N) → posisjon skalert av styrke, kombinert på tvers. Større arkitektur-endring; lavere hast, høyt tak.

## Status / neste
Grunnlaget er forankret i 4 kilder (detaljer: `05-learning/2026-06-09_*`). P1+P2 er konkret nok til proposals så snart ADX/ATR er live. Ingenting implementert — venter Karri + operator.
