# S4 Mean-Reversion — deep-dive 2026-05-13

**Status:** LIVE i demo (Railway `MEAN_REVERSION_ENABLED=true`, aktivert natt til 13.5, ca 00:44 UTC). Sweet-spot tuned config (PR #24, `310054c`). Approved-verbally av Karri, ikke skriftlig backtest-review.

## TL;DR

S4 er den eneste **counter-trend** strategien i porteføljen (S1/S2/S3/Vol-Exp/Session-Breakout er alle continuation). Wired in `orchestrator.ts:430` Step 1i, kun env-gate. **Per 07:02 UTC: 0 proposals, 0 trades, 106 cycles — alle rejected på `session_not_allowed` (Asia + London-prep)**. Live-data starter når LONDON_ACTIVE fyrer (~08:00 UTC). Konfigurert R:R 1:3, tight SL (0.75×ATR), basert på 54-trade 6mo backtest med WR 51.9% / PF 2.56 / +$608.

## Mekanikk (8-gates pipeline)

`apps/worker/src/firm/mean-reversion/mean-reversion-manager.ts`. Sjekker hard i rekkefølge:
1. `MEAN_REVERSION_ENABLED=true` (live)
2. Cooldown 60min + daily-cap 2/dag
3. Session ∈ `{NY_CONTINUATION, LONDON_ACTIVE}` — sweet-spot la til London (54 trader vs 12 med kun NY)
4. ATR/ADX/RSI tilgjengelig
5. **ADX < 25** (kun chop/ranging — ikke trend)
6. **Impulse ≥ 1.5 ATR** over siste 2 H1-candles (range high-low / ATR)
7. **RSI ekstrem**: <40 for LONG, >60 for SHORT (vesentlig løsere enn klassisk 30/70)
8. Confirmation-candle: **OFF** som default (var for streng kombo med RSI)

Entry = OPPOSITE av impulse-retning. SL = entry ± 0.75×ATR. TP = entry ± 2.25×ATR (R:R 1:3). Time-stop 6 timer. Risk 0.5% per trade.

## Sweet-spot tuning (PR #24 vs MVP) — hva endret seg

Backtest fant MVP-config (R:R 1:1.5, RSI 30/70, ADX≤30, 2.5 ATR impulse, NY-only) ga kun **2 trades på 6 mnd**. Skiftet til R:R 1:3 + løsere RSI + tightere SL + +London + lavere impulse-bar:

| Param | MVP | Sweet-spot | Effekt |
|---|---|---|---|
| Impulse ATR | 2.5 | **1.5** | flere setups |
| ADX max | 30 | **25** | kun chop |
| RSI long/short | 30/70 | **40/60** | løsere |
| SL ATR | 1.5 | **0.75** | tight |
| TP R-mult | 1.5 | **3.0** | asymmetri |
| Time-stop | 4h | 6h | tålmodighet |
| Confirm candle | ON | **OFF** | redundant med RSI |
| Sessions | NY | NY+London | volum |

Backtest claim: **n=54, WR 51.9%, Net +$608, PF 2.56, MaxDD $95** på 2867 H1 candles (ca 6 mnd). **Karri har ikke lagt skriftlig review-notat — kun verbal approval samme dag som tuning ble committed (`8c6bcba` markerte status implemented).**

## Live observation per 07:02 UTC 13.5

Postgres `blackboard` (agent='mean-reversion-manager'):
- **106 FACT messages**, 0 PROPOSAL
- Reject-breakdown (alle session-filter):
  - `session_not_allowed: ASIA_PREPARE_FOR_LONDON` — 47
  - `session_not_allowed: ASIA_OBSERVE` — 40
  - `session_not_allowed: LONDON_PREPARE` — 14
  - `session_not_allowed: LONDON_OPENING_RANGE` — 5
- `simulated_orders` med `strategy_id='xau-mean-reversion'`: **0 rows**
- `trade_strategy_snapshots` med strategy='xau-mean-reversion': **0 rows** (S4 ikke wired inn i snapshot-capture per nå — `Step 1e2` kommentar nevner "all 4 firm-strategies" — sjekk om S4 ble lagt til)

Gate 3 (session) er første hard-stop og fyrer ~98% av cycles utenfor London/NY. Forventet — S4 sover i Asia. Ingen rejects fra ADX/impulse/RSI ennå, så vi vet ikke om gate 5-7 fungerer på live data før første London-cycle.

## Archetype-korrelasjon (risk #1)

S4 er **anti-korrelert med resten av porteføljen by design**. Det er hele poenget (mitigerer 11.5+12.5 katastrofedager). Men det betyr også:

- **På trend-dager** (S1/S2/S3/Vol-Exp/Session-Breakout fyrer + tjener) vil S4 enten ikke fyre (ADX>25 blokker) eller fyre mot trenden og ta SL. ADX<25-gate er forsvaret — verifiser i live-data at den faktisk holder S4 ute når continuation-strategiene er aktive.
- **Mean-revert dag = S4 alene-vinner mens resten taper.** Net portfolio-effekt avhenger av størrelsesforhold. S4 risk 0.5%, max 2 trades/dag, R:R 1:3 → max +3% / -1% per dag. Continuation-strategiene kjører høyere volum, så S4 demper, ikke offsetter helt.
- **Conflict-windowing finnes ikke ennå:** S4 fyrer uavhengig av om continuation-strategi nettopp åpnet posisjon. Cross-strategy `mean-revert-gate` ble lagt til i `b31fbae` (PR #22) — men den blokkerer continuation-strategier når S4 antagelig vil reversere, ikke omvendt. Verifiser at S4 ikke åpner LONG samtidig som Vol-Exp åpner SHORT på samme impulse.

## Hva å overvåke første 30 dager

1. **Første LONDON_ACTIVE-cycle:** sjekk at gate 5-7 (ADX/impulse/RSI) faktisk evalueres på live indicators (ikke timeouter).
2. **Signal→trade conversion:** PROPOSAL fired? Strategy-execution-bridge converted to `simulated_orders`? `strategy_id='xau-mean-reversion'`? Risk-sizing 0.5%?
3. **WR drift:** backtest sa 51.9% / PF 2.56. Live første 20 trader: hvis WR <40% eller 3 SL på rad → vurder pause. Proposalen nevner "3 SL på rad" som rollback-trigger.
4. **Correlation matrix:** når S4 trader, hva sa S1/S2/S3 samtidig? `trade_strategy_snapshots` skal fange det — bekreft at S4 er inkludert i `Step 1e2`-capture (kommentaren sier "4 firm-strategies", ikke 5).
5. **News-events:** proposalen flagget FOMC/NFP/CPI risk. Ingen news-block implementert — Karri review-spørsmål #5 står ubesvart.
6. **Daily cap utility:** 2 trades/dag er konservativt. Hvis live-data viser <1 trade/dag → cap er ikke binding. Hvis live-data viser cap hit ofte → kanskje per-session cap (1 London, 1 NY) er bedre.

## Pekere

- Code: `apps/worker/src/firm/mean-reversion/{config,mean-reversion-manager,index}.ts`
- Tests: `mean-reversion-manager.test.ts` (12/12 green)
- Orchestrator: `apps/worker/src/firm/orchestrator.ts:430` Step 1i
- Exec: `apps/worker/src/firm/strategy-execution.ts:147-152` (risk 0.5%, daily-loss $500)
- Proposal: `docs/strategy/proposals/2026-05-13_strategi_4_mean_reversion.md`
- Cross-gate: `apps/worker/src/firm/gates/` (PR #22 `b31fbae`)
- Dashboard: `apps/dashboard/src/app/signals/page.tsx:39` (MEAN-REV fuchsia badge)
