# Autonom watch — FØRSTE ÅPNE MARKED 2026-06-07T22:34Z (ai-2)

session: ASIA_OBSERVE, tradeAllowed=true (marked åpnet ~22:00 UTC). Pris 4317.23. Første mulighet til å verifisere aktiveringene live.

## Aktiverings-verifisering
- **(d) shadow forward-test: BITER ✓** — enabled=true, **130 cycles** logget siste 2d, 5 strategier. Mekanismen fanger. (wouldFire=0 over 130 cycles — se anomali under.)
- **(a) ADX/ATR: FORTSATT NULL** — adx=null, atr=null selv med marked åpent + INDICATOR_OANDA_FALLBACK_ENABLED=true. KAN være for tidlig (~30min etter åpning; ADX trenger ~29+ M1-bars). MÅ re-sjekkes neste syklus (~02:34 UTC). Hvis fortsatt null da = fallbacken biter IKKE (bug eller deploy). Regime-gatene er blinde inntil dette løses.
- **(c) calibration: DISKREPANS** — /calibration/status viser `mode=RECOMMEND_ONLY, autoApply=false, multipliers=1.0` SELV OM Worker har `CALIBRATION_MODE=SAFE_AUTO_APPLY`. Årsak: endepunktet leser process.env på **API-servicen**, der flagget IKKE er satt (kun på Worker). → /learning-panelet villeder (viser recommend_only mens workeren faktisk kan auto-apply). Multipliers=1.0 = ingen apply ennå (trolig <30 samples). FIX: sett CALIBRATION_MODE=SAFE_AUTO_APPLY på API-servicen òg (eller la endepunktet lese worker-modus fra firm_state).
- **(b) RISK_LEVEL-gate: ingen nye blokk ennå** — risk_events har kun gamle rader (06-02 NEWS_BLACKOUT, 04-10 daily-loss). For tidlig (få cycles siden åpning).

## Anomali å følge
- **0 wouldFire over 130 forward-test-cycles.** Enten stille marked (helg/asia-observe) ELLER over-blokkering (gatene stopper alt — risikoen vi flagget). Kan ikke skille ennå. Følg om wouldFire forblir 0 inn i London/NY.
- trend-following viser fortsatt enabled=true i strategy_states (men ingen trades — trolig stale display).

## Trades
Ingen nye siden 06-05 (199 rader). ASIA_OBSERVE = observasjonsfase, ingen entries ennå. Ingenting å skanne for tap/clamps.

## Handling (operator)
1. Sett `CALIBRATION_MODE=SAFE_AUTO_APPLY` på **API**-servicen så panelet viser sannhet.
2. Følg ADX neste syklus — hvis fortsatt null ved London open = fallback-bug, eskaler.
