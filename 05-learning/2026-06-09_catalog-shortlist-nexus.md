# Kuratert shortlist fra awesome-systematic-trading (Nexus-relevant)

*Minet fra ~/code/_refs/awesome-systematic-trading. Egne ord. Lese/distiller-referanse → Karri/execution. Henter on-demand (disk: refs allerede 1.1GB — kloner ikke alt).*

## Henter snart (høy verdi, NÅ-behov)
- **quantstats** (Python, liten) — portefølje-/perf-analytics (Sharpe, drawdown, tearsheets). Direkte nyttig for å gjøre vår /analytics-perf-rapportering ærligere/rikere. Kandidat for faktisk referanse-bruk.
- **vectorbt** — lynrask vektorisert backtest; validere ORB/strategier + tusenvis av varianter. Backtest-workstreamen.
- **nautilus_trader** — ALLEREDE klonet (fill-fidelity + paper↔live-parity).
- **pysystemtrade** — ALLEREDE klonet (vol-targeting, distillert).

## Multi-asset-fremtid (hent når expansion utover gull starter)
- **bt** / **backtrader** — fleksible multi-asset backtest-rammeverk.
- **finmarketpy** (Cuemacro) — makro/FX-fokus; relevant for XAU-makro + nye instrumenter.
- **Qlib** (Microsoft) — ML multi-asset (kobler lærings-loopen).
- Broker-API-seksjonen — sjekk for OANDA/multi-broker-wrappere når vi legger til instrumenter.

## ML/RL (lav prioritet nå, relevant for lærings-loop senere)
- TradingGym, deep-Q-trading-eksempler — idé-referanse, ikke produksjon.

## Bevisst utelatt (ikke Nexus-relevant)
Crypto-fokuserte (vnpy/Botvana/Cipher), HFT/orderbook (hftbacktest, PandoraTrader), aksje-screenere, kinesiske retail-rammeverk (QUANTAXIS/Hikyuu) — feil domene/marked for XAUUSD-CFD-firmaet.

## Neste
quantstats er den mest umiddelbart nyttige (perf-metrics-ærlighet). Vurder å distillere/referere dens tearsheet-metrikker mot vår /analytics neste syklus. Alt advisory.
