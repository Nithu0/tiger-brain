# Distillert (egne ord, advisory): nautilus fill/slippage-fidelity → Nexus paper-vs-live-gap

*Syntese av nautilus_traders tilnærming (LGPL → lært, ingen kode kopiert). Adresserer sweep-funnet: Nexus paper-execution mangler slippage/spread → paper-PnL overstater ekte. Hjelpemiddel for Karri/execution-arbeid, ikke implementert (endrer simulert PnL → penge-nært → Karri/operator-beslutning).*

## Nautilus' fidelity-modell (3 lag)
1. **FillModel** — probabilistisk fill: `prob_fill_on_limit` (sannsynlighet for at en limit-ordre faktisk fylles når markedet hviler på prisen — ikke garantert) + `prob_slippage` (sannsynlighet for at en market-ordre slipper ett tick dårligere). Modellerer at fills er usikre, ikke perfekte.
2. **LatencyModel** — simulerer forsinkelse mellom ordre-innsending og børs-prosessering, så backtest «betaler» samme latency som live.
3. **FeeModel** — commission/avgifter per fill.

## Parity-prinsippet (kjernen, = vårt andre gap)
Backtest-motoren og live-motoren deler SAMME strategi-kode → null kode-endring mellom backtest og live. Det er motgiften mot «paper validerer en kopi, ikke det som faktisk trader» (som vår ORB-backtest-runner gjør i dag).

## Konkret for Nexus (forslag → Karri/operator, ikke implementert)
Nexus paper-execution fyller i dag på eksakt pris (sweep: ingen slippage/spread-modell → paper-PnL optimistisk; gull-spread $0.30–0.70, slippage $0.50–2.00 per trade ikke regnet med). Mønster å adoptere:
- **Spread-modell:** fyll entry/exit på riktig side av spread (kjøp på ask, selg på bid) fra OANDA-feed.
- **Slippage-modell:** sannsynlighet for fill ett tick/X dårligere på market-ordre (env-gated, kalibrer mot ekte fills via vår fill-drift-logging).
- **Hvorfor penge-nært:** dette endrer SIMULERT PnL → som mater calibration + lessons → påvirker hva systemet lærer. Derfor Karri/operator-beslutning, ikke en ai-2-build. Men det gjør paper ærligere → bedre lærings-signal.
- **Parity-langsiktig:** når backtest-Phase-1 (rene decide()-kjerner) gjøres, bør samme execution-fidelity-modell brukes i både backtest, paper og (justert) live.

## Status
Execution-fidelity-grunnlag dokumentert (konsept + nautilus-impl). Konkret nok til en Karri/operator-proposal når vi tar paper-realisme-arbeidet. Advisory.
