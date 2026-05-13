# S1 Deep Dive — Trend-Following Core (`xau-trend-following`)

**Forfatter:** Claude (deep-dive 13.5)
**Strategi-ID:** `xau-trend-following`
**Modul:** `apps/worker/src/firm/trend-following/`
**Live siden:** 2026-05-11 22:54 UTC (`TREND_FOLLOWING_ENABLED=true`)

---

## TL;DR

- **S1 har IKKE tapt penger nylig — den har 0 trades på 90 dager, 0 trades siden live-aktivering.** 844 evaluations på 7 dager, alle endte i reject. WR/PnL-spørsmålet er ikke besvarbar fra prod-data — kun fra Karri's 6mo backtest (17 trades, 41% WR, +$322, PF 2.33).
- **Reject-fordeling (7d):** 55.6% SESSION_BLOCK (sterkest "OVERLAP_ACTIVE" n=199 + ulike out-of-session-buckets), 27.1% VOL_BELOW_MIN (ATR-ratio 0.55–0.86 mot krav 1.05), 7.5% ADX_TOO_LOW (18.3–21.2 mot krav 22), 7.0% PULLBACK_TOO_DEEP (1.5–2.8 ATR mot tak 0.8), 1.9% NO_CHASE. Null trades passerte pipeline. Karri's trend-pause-hypotese kan **ikke** testes på S1 fordi det ikke finnes losses å analysere.
- **Anbefalt analyse-neste-steg (ikke kode):** kjør 14-dagers reject-narrowness-rapport — flagg om S1 strukturelt aldri kommer til å fyre med gjeldende filter, eller om markedet bare har vært ugunstig 11.5–13.5. Hvis null trades fortsetter i 14 dager, er problemet "for restriktive filtere", ikke "dårlig WR".

---

## Hva S1 ER

**Arketype:** Trend-following / pullback continuation (continuation, ikke counter-trend).

**Filer:**
- `apps/worker/src/firm/trend-following/trend-following-manager.ts` — entry-evaluation, publish til `xauusd.trend-following.signal`
- `apps/worker/src/firm/trend-following/config.ts` — env-flags + sweet-spot defaults
- `apps/worker/src/firm/trend-following/trend-following-manager.test.ts` — 15 unit-tests
- Integrert via `orchestrator.ts` Step 1f og `strategy-execution.ts` (PROPOSAL-consumer entry)
- Strategy-execution config: `maxOpenPositions=1`, `dailyLossLimitUsd=$800`, `riskPct=0.5%`

**Hard filter pipeline (10 trinn, alle må passere):**
1. EMA20 > EMA50 + slope > 0 + price > EMA20 (LONG-side; mirror for SHORT)
2. ADX(14) ≥ 22 (sweet-spot, ned fra 25)
3. ATR-ratio ≥ 1.05 (sweet-spot, ned fra 1.15)
4. Session i {`LONDON_ACTIVE`, `NY_CONTINUATION`, `ASIA_OBSERVE`}, blokkert i {`OVERLAP_ACTIVE`, `NY_OPENING_RANGE`}
5. Cooldown ≥ 60 min siden siste signal
6. ≤ 3 trades i dag
7. ≤ 2 losses per retning i dag
8. Pris < 1.8 × ATR fra EMA20 (no-chase)
9. Pullback dybde 0.2–0.8 ATR (sweet-spot)
10. Bullish/bearish rejection-candle

**Exit:** SL 0.75 × ATR (TIGHT — sweet-spot, ned fra 1.5), TP 4R, BE +0.5R, trail 1.0 × ATR etter +1R, time-stop 8 timer.

## Baseline (Karri 6mo backtest 12.5)

Per `docs/strategy/proposals/2026-05-12_strategi_1_trend_following_core.md` + handoff 11.5:
- **17 trades / 6mo** (OANDA H1, 2025-11-12 → 2026-05-11)
- **WR 41.2% / Net +$322 / PF 2.33 / MaxDD $104**
- Suksess-kriterier (14d live): Net ≥ 0, WR ≥ 45%, max-consec-loss ≤ 3, ingen enkeltdag > $1000 tap, 2–4 trades/uke.

## Live vs baseline (12.5 → 13.5)

**Live-tid:** ~33 timer (siden 11.5 22:54 UTC til 13.5 07:04 UTC).

| Metrikk | Backtest 6mo | Live 33t |
|---|---:|---:|
| Evaluations | n/a | 844 |
| `shouldTrade=true` | n/a | **0** |
| Signals publish | n/a | 0 |
| Trades opened (`simulated_orders`) | 17 | **0** |
| Win rate | 41.2% | n/a (no sample) |
| Net PnL | +$322 | $0 |

S1 har bidratt **null** til 12.5 tap-dagen ($−1195). Hele −$1195 stammer fra vol-exp + session-breakout (per handoff 13.5). Hvis operator opplever at "S1 taper", er det enten (a) sammenblanding med vol-exp som er en søsken-strategi med samme tematikk, eller (b) frustrasjon over manglende positiv contribution.

## Reject-distribusjon (7d, 844 evals)

| Bucket | n | % |
|---|---:|---:|
| SESSION_BLOCK (alle session-rejects) | 469 | 55.6% |
| VOL_BELOW_MIN (ATR-ratio < 1.05) | 229 | 27.1% |
| ADX_TOO_LOW (< 22) | 63 | 7.5% |
| PULLBACK_TOO_DEEP (> 0.8 ATR) | 59 | 7.0% |
| NO_CHASE | 16 | 1.9% |
| PULLBACK_TOO_SHALLOW | 4 | 0.5% |
| no_trend (EMA-align fail) | 4 | 0.5% |

Time-of-day-mønster: Session-blokk dominerer 04–07 UTC (`*_PREPARE` / `OPENING_RANGE`) og 11–14 UTC (`OVERLAP_ACTIVE` etter London close + før NY-continuation). Vol-below dominerer 08–10 UTC (London) og 23–01 UTC (Asia thin). ADX-low + pullback-too-deep dominerer 02–03 og 15–17 UTC.

**Tolkning:** S1 evaluerer kontinuerlig, men "good-trend-window" (LONDON_ACTIVE eller NY_CONTINUATION + ADX ≥ 22 + ATR ≥ 1.05 + grunn pullback) har ikke truffet samtidig på 33 timer. Backtest predikerte 17 trades / 6mo = ~0.65/uke = ~0.1/dag → 33 timers null-frekvens ligger statistisk innenfor forventning, men nær null-tail.

## Karri's trend-pause-hypotese — ikke testbar på S1

Per memory `project_trend_pause_concept.md`: hypotesen er at boten misforstår trend-pauser som mean-reversion-muligheter og fyrer counter-trend. **S1 er strukturelt designet for å unngå dette** — den er continuation-only og krever ADX ≥ 22 + ATR-expansion + grunn pullback. Hypotesen gjelder vol-exp + (potensielt) S4 mean-reversion, ikke S1.

For S1 spesifikt er den motsatte risikoen relevant: **filter er så strenge at trender går forbi uten at S1 fanger dem**. Konkret: pullback 0.2–0.8 ATR er smalt; et XAUUSD-trend-marked kan retrace 1.0–1.5 ATR (sett i live-data: 59 evaluations med pullback 1.5–2.8 ATR) før neste leg up — S1 blokker disse mens vol-exp / S2 / S3 evt fanger dem.

## Anbefalt neste analyse-steg (kun analyse — ingen kode-endring)

1. **14-dagers reject-narrowness-rapport.** Kjør reject-bucket-aggregering 13.5 → 27.5. Hvis S1 fortsatt har 0 trades etter 14 dager mens backtesten predikerte ~1.3, må vi avgjøre om backtesten var optimistisk eller om filtrene er for stramme på live data. Karri eier beslutningen.
2. **Validér backtest-baseline mot samme periode i live.** Spør: hadde backtesten i de samme 33 timene 11.5–13.5 produsert trades? Kjør `scripts/firm/_sweep_strategi_1.mjs` på siste 7d OANDA H1 og sammenlign med live-rejects. Hvis backtest ville fyrt 1+ trade i samme vindu = en filter-divergens (live ATR/ADX/session-data ulikt backtest-input).
3. **Cross-check session-window classification.** 55.6% av rejects er session-blokk. Verifiser at `LONDON_ACTIVE` faktisk inkluderer perioden 08:00–11:00 UTC (live data viser at 08–10 UTC kommer gjennom session-gate men feiler på vol-expansion). DST + Norge-Storbritannia kan skvise vinduet.
4. **Pullback-tak diskusjon for Karri.** Live viser 59 evaluations med 1.5–2.8 ATR pullback. Hvis disse kandidatene ellers hadde passert (trend + ADX + vol), kunne S1 sannsynligvis hatt 5–10 trades på 33 timer med pullbackMax = 2.0. Spørsmål til Karri: hvor mye av backtest-baseline-WR er drevet av strikt 0.8-tak vs hvor mye av frekvens-tap koster det?

## Konklusjon

S1 "taper" ikke — den fyrer ikke. Operator's premiss "S1-S4 har gode baseline-WR men taper nylig" stemmer ikke for S1: 0 trades = 0 tap. Hvis operator føler at S1 ikke leverer, er det riktig — den har ikke levert noe, hverken positivt eller negativt. Spørsmålet å stille Karri er om filtrene er kalibrerte for det live-regimet vi faktisk er i (vol-ratio < 1.0 dominerer 27% av tiden, pullback > 0.8 ATR dominerer 7% av tiden), eller om de er kalibrerte for et historisk regime som backtesten 6mo speilet bedre enn live 33 timer.
