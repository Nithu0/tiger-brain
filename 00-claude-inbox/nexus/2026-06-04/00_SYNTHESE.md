# 10-agent sveip synthese — 2026-06-04 (ai-1)

Operator: "10 agenter, analyser, verifiser, finn nye oppgaver." Alt read/analyse, ingen money-mutasjon. Full rapporter: 01–10 i denne mappa.

## HOVEDFUNN (reframer operatørens frustrasjon)

**De harde tapene var ÉN hendelse, ikke en ødelagt strategi.**
- Blowup 2026-04-21/22 = REAL (ikke backfill-artefakt, agent 01): sizing-formelen `balance·risk%/stopDistance` ga 95–106 units (~12% konto-risiko/trade), OANDA fylte trofast. Ingen units/notional-tak fanget det.
- Strip de 18 blowup-tradene (agent 02, uavhengig reberegnet fra export.json n=194): resten = **PF 1.03, +$3.40/trade, +$599 total, break-even.** size≤5u: PF 1.55. size>5u: PF 0.67. Tapet er RENT sizing.
- ai-2s "ex-blowup negativ edge" (37%/0.63/−65) var feilmerket ALL-trades-tall (blowup inkludert). Korrigert.
- Ærlig forbehold: break-even ≠ robust positiv edge (tynn, venstreskjev, 6 ukers demo). Taket stopper blødningen; det skaper ikke edge alene.

**→ Fiksen er ÉN ting: et hardt size/notional circuit-breaker.** Ikke strategi-redesign. Ikke trange/vide stops. Ikke trege entries.

## VERIFISERT (mot/med ai-2)
- **Stops er BROKER-SIDE** (agent 09): OANDA server-side resting orders, fyrer på tick uavhengig av worker-cadence. "10-min gapping"-historien er FEIL — bare ~5.7% ($1870) av tap er gapping; −$1500-halen er sizing (stop_dist × size). Tighter cadence er IKKE fiksen.
- **Ingen size-cap finnes** (agent 04): exposure-modulen capper risk-%, ikke units, OG er kun wiret til LEGACY-stien — live-stien (`strategy-execution.ts`) bypasser den helt. `placeOandaOrder` clamper bare OPP til minimum.
- **5 nye lærings-commits grønne** (agent 03): worker 1157/1157, alle default-OFF/behaviour-neutral. ORB-backtest crasher ikke lenger MEN trenger 1min-data (kun 15min skrives) → Railway-backfill ELLER `BACKTEST_CANDLE_TIMEFRAME=15min`.
- **Batch-1 aktivering** (agent 07): REGIME_DIRECTION_GATE ✓ live, DAILY_TRADE_CAP ✓ live (skriver gate_decisions). MANUAL_POSITION_CONTROL på API = **NEI — API kjører stale deploy (e934e629) uten manual-control-rutene → 404.** Regime-gaten kan ikke bekreftes "biter" ennå (regime = HIGH_VOLATILITY nå, retning beregnes kun i TRENDING → korrekt no-op nå).

## NYE OPPGAVER funnet
- **/explorer/weaknesses LYVER** (agent 08): hardkoder allerede-fiksede svakheter + leser legacy `bots`/`signals`-tabeller. ~halve weaknesses.json er stale. (Forklarer agent 05s falske "worker idle" — /health viser worker frisk, syklus #260.)
- **Korrupt expectancy +6.233R @ 31.7% WR** (umulig) — korrupt result_r-outlier blåser opp nettopp metrikken en live-flip nøkkler på.
- `xauusd.event.policy` ~40d stale (news-blackout kan gate på gammel state, ingen alarm).
- Polygon backup-feed (single point of failure), Railway PG-backup (ingen backup nå).
- Shadow forward-test = raskeste "valider hver trade"-vei (8 strategier, ekte logikk) — flipp `SHADOW_FORWARD_TEST_ENABLED` + fiks label-bug ('win'/'loss' vs 'tp_hit'/'sl_hit' i shadow.ts).

## LÆRINGS-LOOP (agent 06)
Største blocker: proposed→approved promotering finnes IKKE (konsument leser kun status='approved', eneste vei er manuell `!lesson approve`). Selv med alle flagg på når 0 lessons en beslutning. Flagg: AGENT_LESSONS_ENABLED + LESSON_INJECTION_ENABLED (ikke AGENT_KNOWLEDGE).

## BLOKKERT PÅ KARRI (agent 10: hans svar finnes IKKE i filer — kun Discord)
Operator må lime inn Karris svar på: Batch-2 grupper A-D, læring (LESSON_INJECTION, CALIBRATION_MODE=SAFE_AUTO_APPLY, auto-promotering), size-breaker (cap-verdier, RISK_LEVEL_HARD_GATE, scalp 2.5%-justering).
