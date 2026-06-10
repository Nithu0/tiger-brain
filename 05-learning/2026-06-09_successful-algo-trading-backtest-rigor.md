# Distillert (egne ord, advisory): backtest-rigor → Nexus validerings-gap

*Syntese av "Successful Algorithmic Trading" (Halls-Moore). Egne ord. Knytter sammen sizing/fidelity-notene → validerings-disiplin for Karri/backtest-arbeid. Ikke implementert.*

## Backtest-biasene å vokte (direkte relevante nå som autotune+lessons lærer)
- **Look-ahead bias** — bruke data du ikke hadde i sanntid. Event-drevet backtest (prosesser bar-for-bar) hindrer det; vektorisert er rask men lett å lekke fremtid inn i.
- **Optimisation/overfitting bias** — tune til historikk → faller fra hverandre live. **Mest akutt for oss:** SAFE_AUTO_APPLY autotune kan overfitte på tynt/blowup-skjevt utvalg. Karris ±20%/min-30-bounds er nettopp motgiften — men out-of-sample-disiplin trengs før vi stoler på tunede vekter.
- **Survivorship bias** — mindre relevant for single-instrument XAU, men relevant når vi utvider til multi-asset.

## Event-driven vs vektorisert (= vårt backtest-arkitektur-valg)
Boka argumenterer for event-drevet backtest fordi den (a) unngår look-ahead, (b) modellerer transaction cost/slippage realistisk, (c) lar SAMME kode kjøre backtest→live. Det er nøyaktig nautilus' parity-poeng + motgiften mot at vår ORB-runner re-implementerer ORB (validerer en kopi). → støtter Phase-1 rene decide()-kjerner + event-drevet validering.

## Metrikker + kostnader
- **Sharpe + max drawdown** som primær-metrikker (vi har dette delvis i /analytics; quantstats-shortlisten kan rikere det).
- **Transaction cost + slippage MÅ inn i backtest/paper** ellers overstates edge (= nautilus-fidelity-noten + vårt paper-vs-live-gap). Konsistent budskap på tvers av kildene.

## Kelly / sizing
Boka bruker Kelly for posisjons-størrelse (med haircut, fordi full Kelly er for aggressiv). Samme retning som vol-targeting (Carver) — størrelse styrt av edge+volatilitet, ikke stop-avstand. Forsterker sizing-proposalen til Karri.

## Syntese på tvers av kunnskapsbasen (for Karri)
Fire kilder peker nå samme vei: (1) vol-targeting-sizing (Carver/pysystemtrade), (2) gradert forecast (Carver), (3) execution-fidelity m/ slippage+spread (nautilus), (4) backtest-rigor: event-drevet + OOS + kostnader (denne). Til sammen et koherent grunnlag for å fikse Nexus' diagnostiserte svakheter (04-21-sizing, paper-vs-live-gap, overfitting-risiko i autotune). Alt advisory → Karri eier beslutningene.
