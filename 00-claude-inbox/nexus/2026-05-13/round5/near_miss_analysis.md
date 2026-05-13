# Near-miss analysis — hvilken strategi er nærmest å fyre? (24h)

**Generated:** 2026-05-13
**Window:** siste 24t blackboard.signal.rejected
**Status:** observasjons-rapport. Ingen tuning foreslås — terskelendringer går via Karri (`feedback_strategy_changes_review.md`).

---

## TL;DR — ranking nærmest-til-fyring

| Rank | Strategi | Closest-gate | Best near-miss | Pct margin | Forklaring |
|---|---|---|---|---|---|
| 1 | **S1 Trend-Following** | `adx_too_low` | **ADX 21.2 vs 22** | **3.6%** | 12 cycles på 21.2 — én ADX-tick fra entry |
| 2 | **S3 Pullback-Continuation** | `adx_too_low` | ADX 16.2 vs 20 | 19.0% | ADX-rangering 14.9-19 (vol_expansion også røde) |
| 3 | **S4 Mean-Reversion** | `rsi_not_overbought` | RSI 50.5 vs 60 | 15.8% | RSI sitter rundt 46-50, strukturelt under |
| 4 | **Vol-Exp (legacy)** | `ATR ratio` | 1.23 vs 1.30 | 5.4% | 7 cycles på 1.23, ellers 0.56-1.00 |
| 5 | **S2 Breakout-Cont.** | `no_clean_breakout` / `no_valid_range` | binary | — | Ikke kvantitativ near-miss — bryter ikke H1-range |
| 6 | **Session-Breakout** | n/a | n/a | — | 6 av 8 rejects = portfolio-cap (1/1) → strategien fyrte 12.5 og holder en posisjon. Ikke et signal-problem |
| — | **Scalp-Overlap** | n/a | n/a | — | 0 rejection-events 24h — state-topic ikke publishet. Enten OFF eller pre-`signal-rejection-log`-gated |

**Closest single setup right now:** S1 Trend-Following har sittet på ADX 21.2 (i 12 sykluser) — `0.8 ADX-poeng` fra threshold 22. Det er det smaleste hullet i hele firmaet.

---

## Per-strategi detaljer

### S1 — xau-trend-following (710 rejects/24h)

Top non-session rejection-stages, sortert etter margin:

| Gate | Observed | Threshold | Margin (abs) | Margin (%) | Occurrences |
|---|---|---|---|---|---|
| adx_too_low | 21.2 | 22 | 0.8 | **3.6%** | 12 |
| adx_too_low | 21.1 | 22 | 0.9 | 4.1% | 1 |
| adx_too_low | 20.3 | 22 | 1.7 | 7.7% | 10 |
| adx_too_low | 20.2 | 22 | 1.8 | 8.2% | 4 |
| adx_too_low | 19.0-19.2 | 22 | ~3.0 | 13.6% | 21 |
| vol_expansion_below_min | 0.81 | 1.05 | 0.24 | 22.9% | 36 |
| pullback_too_deep | 1.50 ATR | 0.8 | 0.7 | 87.5% (far) | 14 |
| no_chase | 1.82-2.94 ATR | 1.8 | 0.02-1.14 | 1-63% | 17 |

**Dominant blocker:** ADX (regime ikke trender hardt nok). ~28% av 710 rejects er ADX-relaterte. Sekundær: vol_expansion + no_chase.

S1 har også de tetteste no_chase-rejectsene: `dist 1.82 ATR > 1.8` (1.1% margin) — én tick fra å passere.

### S2 — xau-breakout-continuation (709 rejects/24h)

Non-session blockers er binære (ikke kvantitativ margin):

| Reason | Occurrences |
|---|---|
| no_valid_range | 111 |
| no_clean_breakout | 102 |

Markedet bryter ikke ut av identifisert H1-range. Ingen "near-miss"-kvantifisering tilgjengelig fra reason-strengen — krever shadow-log payload deep-dive.

### S3 — xau-pullback-continuation (710 rejects/24h)

| Gate | Observed | Threshold | Margin (%) | Occurrences |
|---|---|---|---|---|
| adx_too_low | 16.2 | 20 | 19.0% | 29 |
| adx_too_low | 15.5 | 20 | 22.5% | 25 |
| adx_too_low | 15.3 | 20 | 23.5% | 25 |
| vol_expansion_below_min | 0.79 | 1.05 | 24.8% | 36 |
| adx_too_low | 14.9 | 20 | 25.5% | 14 |
| vol_expansion_below_min | 0.70 | 1.05 | 33.3% | 55 |
| pullback_too_deep | 6.52-7.78 ATR | 2.0 | 226-289% | 70 |

S3 deler ADX-readings med S1 men har lavere threshold (20 vs 22). Likevel langt unna i 24h. `pullback_too_deep` på 6-7 ATR = price har dratt langt; ikke en marginal.

### S4 — xau-mean-reversion (254 rejects/24h)

| Gate | Observed (best) | Threshold | Margin (%) | Occurrences |
|---|---|---|---|---|
| rsi_not_overbought | 50.5 | 60 | 15.8% | 1 |
| rsi_not_overbought | 50.1 | 60 | 16.5% | 2 |
| rsi_not_overbought | 49.9 | 60 | 16.8% | 1 |
| rsi_not_overbought | 47.0-50.5 (range) | 60 | 16-22% | ~50 |
| impulse_too_small | 1.49 ATR | 1.5 | 0.7% | 1 |
| impulse_too_small | 1.31-1.40 ATR | 1.5 | 7-13% | 12 |

**Spesielt funn:** impulse-detection traff 1.49 ATR én gang — 0.7% under threshold 1.5. Men det skjedde bare **1 gang** mens RSI-gate fortsatt blokkerer. RSI sitter strukturelt på 46-50 → markedet er ikke overbought/oversold i dag.

S4 fant aldri en oversold-setup i 24h (alle 80+ RSI-rejects er "not_overbought" = SHORT-siden). Ingen LONG mean-revert kandidater.

### Vol-Expansion (legacy)

ATR-ratio distribusjon (708 rejects):

| Bucket | Count |
|---|---|
| 1.07-1.23 (nær) | 13 |
| 0.93-1.00 | ~201 |
| 0.65-0.81 | ~340 |
| <0.65 | ~36 |

Beste single near-miss: 1.23 vs 1.3 (5.4% margin), 7 occurrences. Volatilitet er strukturelt lav i dag.

### Session-Breakout (legacy)

8 rejects total, 6 er `per-strategy cap reached (1/1)` — strategien holder allerede en posisjon (sannsynligvis fra 12.5). Ikke et signal-problem.

### Scalp-Overlap

Null rejection-events 24h. State-topic `xauusd.scalp-overlap.state` ikke synlig i blackboard. Enten master flag OFF eller manager gater før `signal-rejection-log` kobles inn. Krever separat investigation hvis Karri vil vurdere scalp-aktivering.

---

## Highest-leverage relaxation candidate (data-surfacing, ikke forslag)

**Strategi:** S1 Trend-Following
**Gate:** `adx_too_low`
**Observasjon:** 12 sykluser blokkert på ADX 21.2 (0.8 poeng under), ytterligere 11 på 20.2-21.1 (1-2 poeng under). Hvis ADX-threshold hypotetisk gikk 22→20, ville ~37 av siste 24h-rejects blitt sluppet gjennom til neste gate (sannsynligvis vol_expansion/no_chase deretter — så ikke alle blir trades). Marginen er den smaleste i hele porteføljen.

**Caveat:** S1's nåværende ADX 22 er forsvart i `apps/worker/src/firm/trend-following/config.ts` som "trend-styrke nok til høy WR". Senking risikerer fyring i sidewise. Backtest + Karri-review kreves før noen endring.

**Ikke en relaxation-forslag — bare hvor den marginale signalet sitter akkurat nå.**

---

## Hvor neste live-trade sannsynligvis kommer fra

Basert på 24h-data, om markedet skifter regime de neste 12h:

1. **Hvis ADX stiger 1 poeng** → S1 trigger (forutsatt vol_exp + no_chase også klarer seg). Mest sannsynlig.
2. **Hvis volatilitet eksploderer (ATR ratio >1.3)** → Vol-Exp fyrer. Krever et større event (CPI/Fed-news/geopolitikk).
3. **Hvis kraftig nedgangsbevegelse + RSI <30** → S4 LONG. Eller motsatt (RSI >60 + impulse-fade) → S4 SHORT.
4. **Hvis ny H1-range bryter rent** → S2.
5. S3 trenger både trend (ADX>20) OG vol-expansion + en pullback i 0.2-2.0 ATR — strengeste kombi, lavest sannsynlighet i dagens regime.

---

## Files referenced

- `/home/nithu/code/ai-assistent/apps/worker/src/firm/signal-rejection-log.ts` — 5-stage taxonomy
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/trend-following/config.ts` — S1 thresholds
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/pullback-continuation/config.ts` — S3 thresholds
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/mean-reversion/config.ts` — S4 thresholds
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/breakout-continuation/config.ts` — S2 thresholds
- `/home/nithu/code/ai-assistent/docs/strategy/proposals/2026-05-13_strategi_4_mean_reversion.md` — S4 spec

Method: SQL extract on `blackboard.topic='xauusd.signal.rejected'`, last 24h, regex-parsed `observed < threshold` from reason strings, computed `(threshold - observed) / threshold * 100`.
