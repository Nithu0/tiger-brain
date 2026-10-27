# Trade-forensics fullanalyse — 2026-08-14

Populasjon: 288 closed `simulated_orders`. 159 karantene (korrekt, dekomponert 132+7+20, null feilekskluderte). 129 "rene" — hvorav 23 skjulte artefakter → reelt læringskorpus ~106. Alle 129 dømt individuelt (2 dommere), kryss-tabulert her. mfe_r er NULL for samtlige 288 (peak_price_true aldri satt), så 20 av 48 tapsklassifiseringer hviler på 6h-post-move-proxy — RETNINGSFEIL/TIMING-skillet er støy nær grensen.

Tall under bruker `r_true` = result_r, korrigert til r_check for de 23 artefaktradene og NULL der risk_points<0.5 (BE-overskrevet stop).

## 1. Hovedtall

- Netto clean PnL: **-4 955 USD** (129 trades). Tap-trades: 53 stk, **-50.1R / -18 400 USD**. GOD_TRADE: 29 stk, **+12 844 USD**.
- Verdict-fordeling (dommere): GOD_TRADE 29, SCRATCH 36, RETNINGSFEIL 36, TIMINGFEIL 7, TIMING_SVAK 5, EXEC_ARTEFAKT 16.

## 2. Trender i feil og rett

### Per strategi (n / avg r_true / sum PnL)
| Strategi | n | avgR | PnL | Kjennetegn |
|---|---|---|---|---|
| xau-volatility-expansion | 38 | -0.56 | -4 686 | Taps-motoren. 13 retningsfeil, flest short mot TRENDING opp |
| xau-session-breakout | 33 | -0.12 | -1 138 | 20/33 SCRATCH — 50-75pt SL gir mini-size, kan verken vinne eller tape |
| xau-mean-reversion | 33 | +0.04 | +302 | Bimodal: 11 GOD (mest RANGING) mot 11 retningsfeil (mest Asia-longs) |
| xau-fvg | 8 | -0.24 | +114 | SL 0.7-4pt i ATR 9-18 = stoppes på støy; motsatt: mikro-TP la 47R på bordet |
| xau-htf-trend | 6 | +0.48 | +2 290 | 5W/0L clean. Eneste strategi uten reelle tap. n for liten for bevis |
| xau-scalp-overlap | 6 | -0.32 | -537 | Revenge-klynger (3 shorts på 20 min 11.05) |
| xau-orb | 5 | -0.63 | -1 300 | Verst per trade, n=5 |

### Per sesjon (normalisert)
OVERLAP er eneste positive: +0.27 avgR, +5 407 USD (22 trades, 9 GOD). ASIA -1 616 USD der alle 8 retningsfeil er MR-longs. NY -2 028, LONDON -277. **UNKNOWN: 39/129 trades mangler sesjonslabel (-6 443 USD)** — labelingen røk et sted, og to navnekonvensjoner (asia vs ASIA_OBSERVE) lever side om side.

### Per portefølje-regime
TRENDING: -0.61 avgR, -5 603 USD, 13 retningsfeil — systemet shorter opptrend. RANGING: +0.18 avgR, +3 021 USD, 11 GOD. Regime-feltet ER informativt; retningsgaten respekteres bare ikke.

### Per uke
Uke 17 (htf-trend-æraen): +0.48 avgR. Uke 19: -0.52 (8 retningsfeil). **Uke 20: 1W/14L, -0.87 avgR, -4 306 USD** — verste uken, re-entry-klynger uten cooldown. Sommeren (uke 25-30) rundt null, uke 32 +1.56 (5W/0L), uke 31/33 -0.7ish. Ingen læringstrend synlig — ukene svinger med regimet, ikke med kalibreringen.

### GOD_TRADE-profilen (n=29)
MR i RANGING (11), OVERLAP-sesjon (9), htf-trend (4). Median hold 27 min, median risk_points **10.9 vs 7.3 hos timing-taperne** — vide stops vinner, trange stoppes på støy. Median ATR 9.7. Ingenting tyder på at conviction-score plukket dem (se §5).

## 3. Verdikjede-attribusjon (53 tap)

| Ledd | n | tapt R | tapt USD |
|---|---|---|---|
| gate: regime-retning ikke håndhevet (kandidat) | 11 | -10.7 | -3 563 |
| signal: rent retningsvalg | 13 | -10.2 | -3 706 |
| entry/stop-geometri (timing, for stram SL) | 8 | -8.2 | -1 868 |
| gate: Asia-sesjon MR-longs | 7 | -7.1 | -2 974 |
| gate: cooldown/re-entry <60 min etter tap | 5 | -5.0 | -2 030 |
| data/attribusjon (artefakt-maskerte tap) | 5 | -4.0 | -2 209 |
| exit/exec (slippage/helgegap forbi stop) | 2 | -2.8 | -1 330 |
| gate: conviction-gulv (score ≤0.3 tatt likevel) | 2 | -2.0 | -720 |

Lesning: **gate-leddet eier 25 trades / -24.9R / -9 287 USD — halvparten av alt tap** sitter i trades en eksisterende eller foreslått gate skulle blokkert. Signal-leddet (ekte feilanalyse ingen gate kunne reddet) er bare -10.2R. Management er IKKE et reelt tapsledd: alle 6 mgmt-flaggede er SCRATCH med pnl ~0 — TP1-partial-pnl bokføres ikke (bokføringshull, ikke dårlig management). CONVICTION_FLIP_EXIT netto +263 USD (kutter vinnere OG redder tap, ca. nøytral). STALE_TRADE_EXIT netto +78 USD over 20 trades — fungerer som nødbrems.

## 4. Broker/exec-tap vs analyse-tap (operatorens spørsmål)

- **Analyse (retning + timing + gates): ~-43.3R / ~-14 861 USD = 81 % av brutto tap-USD.**
- **Broker/exec reelt: ~-1.0R / ~-460 USD (2.5 %).** Slippage/gap forbi stop på 4 trades (ce91f971 -1.6R, 2ad8de2c helgegap -1.23R, 346a75c2, e89e06ed) = -0.97R utover planlagt -1R, ~-423 USD; OANDA-netting-kollisjoner ~-35 USD. Fill-latency max 587 ms, spread max 1.02 — eksekveringen er frisk.
- **Data/attribusjon: -4.0R / -2 209 USD reelle tap maskert som noe annet** + korpus-bias på **+10.5R falsk positiv result_r fordelt på 12 taps-rader** som SAFE_AUTO_APPLY leser i dag. Pengene i disse var analyse-tap; data-laget eier feilklassifiseringen.

Konklusjon: broker er ikke problemet. Systemet taper på retningsvalg og manglende gate-håndhevelse, og lærer av delvis forgiftede tall.

## 5. "Hvorfor valgte vi den retningen" — er conviction informativ?

Nei, den er støy og delvis invertert:

- entry_conviction_score: RETNINGSFEIL avg **0.594** / GOD_TRADE avg **0.536** / TIMING avg 0.708 (median 0.6/0.6/0.7). Tapere scorer HØYERE enn vinnere.
- Binning: score 0.8-1.0 → **2W / 15L, avg -0.58R**. Score <0.2 → 3W/1L (+0.48R). Toppen av skalaen er anti-signal.
- conviction_total (n=59): RETNINGSFEIL -0.022 vs GOD +0.003 — riktig fortegn men mikroskopisk skille, og NULL i 70/129.
- conviction_direction — feltet som skulle SVART på retningsspørsmålet — er persistert i **6 av 129 trades**. Datagrunnlaget for spørsmålet finnes ikke.
- thesis_quality_score: normalisert avg 67 (GOD) vs 62 (RETNINGSFEIL), median 60 begge — svak, og 17 rader har fortsatt u-normaliserte 6000/7000-verdier.

En 0.2-conviction-trade (a5dc8687) ble tatt med full størrelse mot trenden og tapte -1R. Score-gaten er dekorativ og sizing bruker den ukritisk.

## 6. Anbefalinger (rangert)

1. **[report-only-fiks] MFE-R-backfill 26.04–05.05**: rekalkuler result_r fra realisert exit for 21 rader (klasse X + fc359bcb), NULL + excluded der basis mangler (2 ghost-closes, MANUAL_NO_OANDA, TX886), avklar 53a898ea. Fjerner +10.5R falsk-positiv bias fra korpuset SAFE_AUTO_APPLY leser. SQL-skisse i artifacts_analysis.md.
2. **[report-only-fiks] Skriv-tids-guard i postmortem**: nekt persist når sign(result_r) ≠ sign(pnl) uten partials — hadde fanget hele klasse X.
3. **[report-only-fiks] Persistér original-SL og bokfør TP1-partials**: BE-trail overskriver stop_loss (9 rader risk_points=0, 4 med SL på feil side) og TP1-pnl bokføres ikke (6 rader) — R-statistikk på BE-trades er søppel til dette er fikset. Samme løft: fiks peak_price_true-pipelinen (NULL i 288/288) så mfe_r og taps-klassifisering blir reell, ikke proxy.
4. **[report-only-fiks] Sesjonslabeling**: 39/129 "unknown" + to navnekonvensjoner. Normaliser + backfill fra opened_at.
5. **[kalibrering — operatorbeslutning] Re-entry-cooldown**: 10 re-entries <60 min etter tap i samme strategi/retning, 6 tapte igjen (-5.0R / -2 030 USD). 30-60 min cooldown per strategi+retning etter SL-exit.
6. **[kalibrering — operatorbeslutning] Frys entry_conviction_score som gate/sizing-input** til den er rekalibrert — den er invertert på toppen (0.8-bin 2W/15L), og conviction_direction må faktisk persisteres før den kan brukes.
7. **[strategi — operator+Karri] Håndhev regime-retningsgate**: 11 mot-trend-tap i TRENDING (-10.7R / -3 563 USD), flest vol-expansion-shorts. Gaten finnes konseptuelt; den blokkerer ikke.
8. **[strategi — operator+Karri] Blokker Asia MR-longs**: 7 tap -7.1R / -2 974 USD; reversion kommer typisk først etter ~24t (6ade2110: -1R, 24h +6.4R).
9. **[strategi — operator+Karri] FVG SL/TP-geometri**: SL-gulv som ATR-fraksjon (ikke 0.5pt absolutt) — 8d3502fc stoppet på 1.25pt SL i ATR 11.5, pris +71R på 24t; og TP-skalering (4bba6a7d TP 1.7pt la 47R på bordet). Vide stops vinner i dette settet (median rp 10.9 hos GOD vs 7.3 hos timing-tap).
10. **[strategi — operator+Karri] Vol-expansion-gjennomgang**: verste strategi (-0.56 avgR, -4 686 USD, 13 retningsfeil) — mesteparten dekkes av 7+8, resten er signalfeil; vurder pause til gates er på. Session-breakout: SL 50-75pt gir mini-size og 20/33 scratch — enten riktig størrelse eller ikke ta traden.
11. **[strategi — operator+Karri] Ikke skaler htf-trend/OVERLAP ennå**: 5W/0L +2 290 USD ser ut som edgen, men n=6 — MinTRL-konklusjonen (ingen provbar edge) står.

## Forbehold

- mfe_r-proxy: minst 5 verdikter usikre der 2h- og 6h-snapshot peker motsatt vei; RETNINGSFEIL vs TIMING_SVAK er upresist nær 0.3-grensen.
- "gate (regime-retning, kandidat)" antar at TRENDING-regimet + tap = mot-trend; uten trend-retningsfelt i snapshotet er dette en heuristikk.
- Helgesmøring av post_move-targets (inntil 25t) kan farge 24h-tallene.
- Alt er paper (trust_label=paper); slippage-tallene er OANDA practice, ikke live.

Kilder: `scratchpad/forensics/` (FORMAT.md, aggregates.json, verdicts_*.jsonl, artifacts_analysis.md, SYNTHESIS.json).
