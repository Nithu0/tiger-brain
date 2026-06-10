# Post-aktiverings-verifisering — 2026-06-07 (ai-1, 10 agenter)

Operator: "alt er flippa letsgoooo." Verifisering på ekte data (443-kanal, live build 2b2d2ce=HEAD).

## HARD SANNHET: "alt er flippa" er i stor grad kosmetisk — lærings-loopen KJØRER IKKE

Tre uavhengige brudd gjør lærings-halvdelen inert uansett env-flagg:

1. **Auto-promo (#73) er IKKE merget** → koden er ikke i live build → `LESSON_AUTO_PROMOTE_ENABLED` leses av ingenting. Placebo.
2. **Derivation KRASJER nattlig (exit-1) i 17 dager** (2026-05-22→06-07). Ingen nye lekser siden 21.5. Produsenten er død i prod — trenger Railway worker-stderr (`[derive-lessons] fatal:`) for å pinne årsaken (443 kan ikke hente den).
3. **Injection på, men 0 godkjente lekser** (3 proposed, alle <0.5 conf + feil role-tag) → injiserer "".
4. **Autotune SAFE_AUTO_APPLY er IKKE aktiv** — live er RECOMMEND_ONLY; OG `orchestrator.ts:724` skipper kalibrering helt under `ORB_ONLY_MODE` + 0 ferske samples. Å flippe den under ORB_ONLY = no-op.

→ "Kontinuerlig læring" kjører ikke. Karris ±20%/min30-bounds er korrekte men har aldri fyrt.

## Det som FAKTISK ble armet (begge beskyttende — verifiser mandag)
- **RISK_LEVEL_HARD_GATE**: lest inline ved decision-time (99% populert der, ikke den stale lagrede kolonnen), would_reject ~60%, men hard_rejected=0 fordi 0 sykluser har kjørt etter flip (helg). Mandag: query `gate_decisions hard_rejected>0` etter London open.
- **Circuit-breaker**: live + clamper (ikke reject, PR #67). Ingen clamp siden flip (helg, ingen trades). Per-trade-only (aggregat-tak mangler). Ved dagens XAU-pris binder notional-cap før units (106u→56u).

## Batch-2 gates (fra gate_decisions = aktiv)
AKTIVE: sl_cooldown (rejecter), mean_revert_block (4 rejects/7d), regime_direction_gate + daily_trade_cap (armet, 0 rejects), blade new-gates, session_block. AV: cross_strategy_direction_flip, null_direction_block. UKJENT (trenger env): funnel_drain, vol-exp-filtre, TF_ADX 22→20, H14-configs.

## STRANDEDE fikser (mine, ALDRI merget til main — lever kun på node-migration-nexus)
- **`2bf96ba` honest /explorer/weaknesses + expectancy-clamp** → dashboardet LYVER FORTSATT live ("no bots running, signal 2862 min old") og clampen er ikke deployet. PR #65 tok søsken-arbeidet men ikke disse 690 linjene. Cherry-pick til main (ren observability, trygt).
- `c6a6b03` backtest-15min-runbar + `a9e54f3` oanda N+1. node-migration-nexus = PR #60, 25 foran/65 bak — for langt bak til wholesale-merge; cherry-pick Tier-A, arkiver resten.

## Andre funn
- **FVG bløler −$1.2k/11 trades**, dominant live-driver — Karris WIP, ikke i flip-batchen. Til Karri.
- **vol-exp no-chase** (Karri-godkjent 28.5, "ready") — kanskje aldri flippet; høyest-verdi u-flippede (−$4.1k vol-exp-bleed).
- **Worker sykler 1/t** (men helg — verifiser mandag at det er idle-helg, ikke stuck).

## Attribusjons-felle
Injection + autotune flytter begge conviction → kan ikke skilles i /learning. Begge er tilfeldigvis inerte nå. **Ikke godkjenn noen lekse de første 48t** så autotune (når den faktisk kjører) er attribuerbar.

## Topp-handlinger
1. Cherry-pick strandede observability-fikser → main (ai-1, trygt). Dashboardet slutter å lyve.
2. Merge #73 (operator) + bestem auto-promo-terskel → auto-promo blir reell.
3. Pull Railway worker-stderr 04:0x UTC → fiks derivation-krasjen (ellers produseres ingen lekser uansett).
4. ORB_ONLY_MODE blokkerer kalibrering — til Karri (er det tilsiktet?).
5. Verifiser vol-exp-no-chase faktisk flippet.
6. Mandag: re-kjør denne sjekken etter London open — da testes flippene faktisk.
