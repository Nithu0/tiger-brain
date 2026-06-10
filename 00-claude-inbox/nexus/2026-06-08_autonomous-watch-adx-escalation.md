# Autonom watch — ADX-ESKALERING 2026-06-08T08:29Z (ai-2)

session: LONDON_ACTIVE, tradeAllowed=true. Worker frisk (ok=true, 55 cyc/t, lastErr=null), markedsdata fersk (lastMarketRawSec=40), beslutninger ferske (lastDecisionSec=103). Alle flagg PÅ (INDICATOR_OANDA_FALLBACK / RISK_LEVEL_HARD_GATE / SAFE_AUTO_APPLY / SHADOW_FORWARD_TEST). Så infraen lever — men:

## CONFIRMED BUG: ADX/ATR fallback biter IKKE
- `strategy_states.market.adx=null, atr=null` i LONDON_ACTIVE, tross fersk markedsdata + `INDICATOR_OANDA_FALLBACK_ENABLED=true`. Ikke lenger "for tidlig" (markedet har vært åpent ~10t). 
- → regime kan ikke bli TRENDING → regimeDirection/regime-gatene forblir blinde. Hele poenget med fallbacken (PR #65) er ikke realisert live.
- **Hypotese for ai-1:** `strategy_states.market.adx` hentes trolig fra en path som IKKE går via den nye OANDA-fallbacken (fallbacken sitter i fetchADX/fetchATR i market-data.service, men feltet som fyller strategy_states/blackboard-technical-fact kan kalle en annen kilde, ELLER fallbacken returnerer null pga insufficient-bars-logikk selv med data). Trace: hvor settes `market.adx` i blackboard, og treffer den `INDICATOR_OANDA_FALLBACK`-grenen?

## CONFIRMED OK: autotune (SAFE_AUTO_APPLY) biter
- `/calibration/status`: multNeutral=FALSE (var True søndag) → workeren har applisert ikke-nøytrale engine-multipliers → SAFE_AUTO_APPLY-apply-pathen kjører live. Bounds (±20%/min-30) skal holde den trygg. Første live-bekreftelse.

## Å følge (ikke alarm ennå): 0 trades / 0 wouldFire
- 0 nye closed trades siden 06-05; shadow forward-test 1285 cyc, wouldFire=0. Beslutninger skjer (lastDecisionSec=103) men ingen entries.
- **Trolig den KJENTE dormante-strategi-tilstanden** (sweep 06-04: 5/6 firm-strategier fyrer nesten aldri; session-breakout 1 exec/8d) — IKKE nødvendigvis over-blokkering. KAN også være ADX-kaskade (regime-avhengige entries kan ikke evalueres uten ADX). Kan ikke skilles uten gate_decisions hard-reject-rate. ai-1: sjekk gate_decisions for å skille over-blokk vs no-setup.

## Cosmetic: calibration-mode-panel
- `/calibration/status` viser mode=RECOMMEND_ONLY fordi CALIBRATION_MODE bare er satt på Worker, ikke API-servicen. multNeutral=false avslører at den FAKTISK auto-applyer. Operator: sett CALIBRATION_MODE=SAFE_AUTO_APPLY på API òg for ærlig panel.

## Handling
1. **[ai-1, P0]** Debug hvorfor ADX-fallback gir null i aktivt marked med flagg på — trace blackboard `market.adx`-kilden vs INDICATOR_OANDA_FALLBACK-grenen.
2. [ai-1] Sjekk gate_decisions hard-reject-rate → over-blokk vs dormante strategier for 0-trades.
3. [operator] CALIBRATION_MODE på API-service (panel-sannhet).
