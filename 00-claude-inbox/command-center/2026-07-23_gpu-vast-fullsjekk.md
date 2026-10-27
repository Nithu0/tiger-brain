# GPU-fullsjekk (Vast RTX 4090, instans 42212247) — 2026-07-23

Bestilt av operatør: «fullstendig sjekk av gpuen, gjør den det den skal, vurder pause siden
den er så dyr — men hvis den gjør forbedringer, la den kjøre.»

## Hovedfunn: boksen er allerede nede — auto-stoppet av Vast 21.07 pga. tom kreditt

- `actual_status=exited`, `intended_status=stopped`. Endepunktet `194.14.47.19:22631`
  svarer ikke (verifisert i dag).
- Konto: **credit $0, balanse −$0.80**, `balance_threshold=-0.01` (aktiv) → Vast stopper
  instanser når saldoen krysser −$0.01. Siste GPU-fakturering sluttet ~21.07 ~10 UTC
  (estimert fra storage-fakturaen 22.07: 14,1 timer lagring fakturert).
- Siden da faktureres kun lagring: 32 GB × $0.333/GB/mnd ≈ **$10,66/mnd** (mot $289/mnd
  når den kjører).
- **Ingen har merket at den døde på 2 døgn.** Ingen feed-varsler, ingen alarmer — fordi
  ingenting bærende peker på den ennå (se under).

## Gjør den det den skal? (historisk verdi)

Nei. Dokumentert før stoppen:

- 13.07-dypanalysen: **261 requests på 3 uker, 0 % GPU-util** — ~$0,80 per request for
  last som ville kostet øre på Haiku-API. Anbefalingen da var SHOULD-PAUSE.
- 15.07-utnyttelsesanalysen: «kapasitet bygget, konsum mangler» — break-even-volumet
  (Nexus worker-agents mot GPU) sto AV.
- IP-bekymringen fra 13.07 er løst: 152.55.177.65 m.fl. var Railway-egress med gyldig
  token. Ingen breach.

## Men: forbrukssiden ble nettopp bygget ferdig

ai-1 merget 21.07 GPU-max-leveransen til Nexus main (PR #224/#245/#246/#247): worker-GPU-
router, firm-agents→GPU, deep-ruting qwen3:30b, dashboard-shell. **Alt venter på at
operatør flipper Railway-vars (OPERATOR-INSTRUKS.md i ai-assistent) og sier «verifiser
GPU»** — som nå vil feile, siden boksen er nede. Ironisk timing: konsumet som skulle
rettferdiggjøre boksen ble ferdig samme døgn som boksen døde.

## Ustabil mellomtilstand — å «la den stå» er ikke et alternativ

Med negativ saldo fortsetter lagringen å trekke (~$0,36/døgn), saldoen synker, og Vast
**sletter etter hvert stoppede instanser/disk ved vedvarende negativ saldo** — dvs.
disken (modeller + oppsett) ryker uansett på Vasts tidsplan hvis ingenting gjøres.
De −$0,80 må uansett gjøres opp.

## Anbefaling (operatør-beslutning, money-impact — jeg utfører ingenting)

**Destroy instansen, behold on-demand-sporet.** Begrunnelse mot operatørens egen regel
(«gjør den forbedringer → la den kjøre»): den har målt ~null forbedringer på 4 uker, og
ingenting i drift avhenger av den i dag (Hermes faller tilbake til Anthropic; Nexus-
flippene er ikke gjort; codex `-p gpu` og embed-tunnel er ubrukte). Alt på boksen er
gjenskapbart: modeller re-pulles på minutter (1 Gbps), oppsettet er dokumentert
(~10 min, jf. 13.07-rapporten), og `vast-job.sh` (auto-destroy verifisert) dekker
batch-behov uten stående kostnad.

- **Destroy:** `vastai destroy instance 42212247` + gjør opp −$0,80. Sparer $10,66/mnd
  og forhindrer ukontrollert sletting. Kostnad: ~10 min re-oppsett DEN dagen GPU trengs.
- **Alternativ — hvis du vil kjøre GPU-max-verifiseringen nå:** fyll på kreditt, start
  instansen igjen (`vastai start instance 42212247`), flipp Railway-vars per
  OPERATOR-INSTRUKS.md, si «verifiser GPU» til ai-1, og mål én uke reelt konsum med
  `_bin/gpu-usage-report.sh` før endelig behold/destroy-beslutning. NB restart-risiko:
  4090-en kan være utleid til andre (start blokkeres til den er ledig), og port-mappingen
  kan endres ved restart → Railway-vars må i så fall oppdateres uansett.
- On-prem-noden (~aug 2026, jf. node-migration) gjør uansett leid stående GPU overflødig.

## Kort svar på bestillingen

Den gjør ikke det den skal — den gjør ingenting, og gjorde nesten ingenting da den
kjørte. «Pausen» har allerede skjedd av seg selv (tom kreditt). Beslutningen som gjenstår
er destroy (anbefalt) eller kreditt+restart bundet til Nexus-flippene.

— code-2, 2026-07-23
