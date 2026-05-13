# Trade-log audit — empirisk sjekk av "god baseline + nylige tap"

**Dato**: 2026-05-13
**Datakilde**: `simulated_orders` (Postgres prod, read-only)
**Vindu**: 2026-04-16 → 2026-05-12 (alle `status='closed'` med `strategy_id IS NOT NULL`, ekskl `oanda_backfill`)
**N totalt (filtrert)**: 67 firm-trades

## TL;DR — er operators premiss sann?

**Delvis falsk.** Det er ingen "fundamentalt god baseline" i tilgjengelig firm-data. **All-time WR 37.3% / PF 0.87 / total PNL −$1 476** over 27 dager. Det som er sant er at det er **et regime-skifte rundt 2026-05-09**: før det leverte porteføljen netto pluss (WR 43%, PF ~1.3); etter har det kollapset til WR 8.3% / PF 0.00 / −$3 800 på én uke. Signifikans: z ≈ −2.13, p ≈ 0.03 (last7 vs prior), borderline gitt N=30 vs 37 — retningen er klar, magnituden er bekreftet, men sample er for liten til høy konfidens.

NB: 86 ekstra closed-rows har `strategy_id=NULL` (legacy/pre-firm pre-26.4). Disse er ikke inkludert siden de ikke kan attribueres til en strategi.

## All-time per strategi

| strategy_id | N | Wins | WR % | Avg PnL | Avg R | PF |
|---|---|---|---|---|---|---|
| xau-volatility-expansion | 41 | 18 | 43.9 | +$16 | 31.0* | 1.09 |
| xau-session-breakout | 14 | 4 | 28.6 | −$45 | 0.06 | 0.57 |
| xau-scalp-overlap | 7 | 3 | 42.9 | −$30 | −0.02 | 0.80 |
| xau-orb | 5 | 0 | 0.0 | −$260 | −0.30 | 0.00 |

\* avg_r forurenset av outliers — ikke vekt for mye.

**Mot baseline-claim i `docs/strategy/proposals/`:**
- S1 trend-following (spec WR 45–55%) → ikke deployed live ennå (default OFF per kommit-historie).
- S2 breakout (spec WR 35–45%) → ikke kjørt live.
- S3 pullback (spec WR 45–65%) → ikke kjørt live.
- `xau-volatility-expansion` (eneste strategi med PF≥1) ligger på WR 43.9% — innenfor "rimelig", men marginal.
- ORB: 0/5. Allerede flyttet til observe-only 12.5 (`770502f`).

## Uke-for-uke (alle strategier samlet, firm-trades kun)

| Uke (ISO start, Mon) | N | Wins | WR % | Total PnL | PF |
|---|---|---|---|---|---|
| 2026-04-27 | 27 | 11 | 40.7 | +$1 888 | 1.73 |
| 2026-05-04 | 28 | 13 | 46.4 | +$437 | 1.09 |
| 2026-05-11 | 12 | 1 | 8.3 | **−$3 801** | 0.00 |

Operator har allerede dokumentert "katastrofedager" (21.4, 22.4, 6.5) i `docs/ops/katastrofedag-analyse-12.5.md` (commit `d39c986`). Men **uke 19 (11.5 →) er verre enn alle tre dagene samlet** og er ikke fanget av den analysen.

## Per-strategi: last 7 dager vs forrige periode

| strategy_id | bucket | N | WR % | Total PnL |
|---|---|---|---|---|
| xau-volatility-expansion | last7 | 20 | 30.0 | −$2 996 |
| xau-volatility-expansion | prior | 21 | 57.1 | +$3 664 |
| xau-session-breakout | last7 | 5 | 20.0 | −$958 |
| xau-session-breakout | prior | 9 | 33.3 | +$327 |
| xau-scalp-overlap | last7 | 3 | 0.0 | −$1 058 |
| xau-scalp-overlap | prior | 4 | 75.0 | +$845 |
| xau-orb | last7 | 2 | 0.0 | −$760 |
| xau-orb | prior | 3 | 0.0 | −$540 |

Alle 4 strategiene har forverring i siste uke (orb er konstant taper). Det er ikke isolert til én strategi → systemisk regime/data-skifte, ikke strategi-spesifikk degradering.

## Signifikans

- Last 7d: WR 23.3% (n=30), Prior 20d: WR 48.6% (n=37)
- Pooled p̂ = 0.373, SE = 0.119
- **z = −2.13, p ≈ 0.033** (two-tailed) — statistisk signifikant ved α=0.05, men borderline. N er lavt: utfallet kan flippe på 3–5 nye trades.
- PnL-magnitude (−$3 801 én uke vs +$2 325 to uker) er en tydeligere signal-kanal enn WR alene.

## Regime-shift dato + sannsynlig årsak

**Inflection: 2026-05-08/09.** Daglig PnL var blandet men netto positiv 27.4–6.5; deretter 7 av 8 siste handelsdager rødt, akselererende.

Commits nær 8–10. mai som kan korrelere:
- `b8195b9` (08.5) — `daily_trade_cap` per Karri (env-gated default OFF) → null behavioral impact om OFF.
- `07f5d00` (08.5) — `sl_cooldown` (default OFF).
- `4c51309` (08.5) — `regime_direction_gate` (default OFF).
- `502bae1` (10.5) — vol-expansion Phase 1 rejection-stage instrumentation.
- `3d3777f / 219b117 / 8c43128` (12.5) — S1/S2/S3 lagt til (default OFF).

Ingen kode-endring i vinduet bytter åpenbart trading-atferd om alle gates er OFF. Mer sannsynlig: **eksogent marked-regime-skifte** (gull-volatilitet/trend i uke 19) som rammer alle 4 strategier samtidig. Stemmer med Karris trend-pause-hypotese (`project_trend_pause_concept.md`).

## Hva som ikke er besvart

- Rolling 30d × 6 måneder ikke mulig: datasettet starter 16.4 (27 dager totalt). Backtest-data i `backtests` ikke gjennomgått her.
- `strategy_id IS NULL` rows (n=86) ekskludert — kan inneholde signal for tidligere baseline om kilden kan utledes.
