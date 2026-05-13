# Cross-day compare: 11.5 vs 12.5 vs 13.5 — is today legitimately quiet or system-blind?

Generated 2026-05-13 09:20 Oslo. Data pulled live from `nexus-pg` (blackboard + simulated_orders). Window: 22:00 UTC of prior day → 22:00 UTC of stated day (i.e. full Oslo midnight-to-midnight). 13.5 is partial (00:00–09:20 Oslo).

## TL;DR

**Today is legitimately quiet — and additionally the system is correctly silent for the regime detected. Not blind.**

The market is genuinely range-bound: ADX 14–21 (well below trend-strategy thresholds of 20/22), ATR ~6.5 (vs 8.8 yesterday), realized intraday range only $34 (vs $94–$126 the previous two days). Regime detector reports RANGING 92% of the time today, which disables `trend_macro` + `momentum_breakout` and only enables `range_reversion` + `scalping`. The two enabled strategies are correctly rejecting their own setups (mean-reversion: impulse-too-small; pullback/trend-following: ADX-too-low) because the prerequisites just aren't there. Zero proposals today is not a bug; it's the gates doing their job.

Caveat: it's still only 09:20 Oslo. London open could deliver volatility expansion and flip the picture. No reason to intervene yet.

## Day-by-day table

| Metric | 11.5 (catastrophe) | 12.5 | 13.5 (so far, 09:20) |
|---|---|---|---|
| Trades opened | 9 | 4 | **0** |
| Total PnL | −$2638 | −$1196 | $0 |
| Portfolio regime (mode) | TRENDING (597) | TRENDING (350), HIGH_VOL (328) | **RANGING (190)** vs TRENDING 65 |
| Realized intraday range (USD) | $94.50 | $125.74 | $34.36 (partial) |
| Avg ATR (1m technical) | 8.79 | 8.78 | **6.66** |
| Avg ADX | 38.4 | 30.9 | **23.1** (min 13.7, max 42 — last reading 14.0) |
| Signal PROPOSALS | 15 (4 strategies) | 19 (3 strategies) | **0** |
| Signal REJECTIONS | 10 | 2837 | 1381 |
| Top rejection reason | ATR ratio too low | session_blocked, ATR-ratio, vol_expansion below | **session_not_allowed (635)**, ATR-ratio (283), no_clean_breakout (101), adx_too_low (~250) |
| Enabled managers (current) | trend_macro, momentum_breakout, scalping | mixed | **range_reversion, scalping** |

Rejection rate per-cycle is broadly comparable between 12.5 and 13.5 (1381 / 282 context-msgs today ≈ 4.9 rejects/cycle vs 12.5's 2837 / 711 ≈ 4.0). Today is not "spiking" rejections — it's the same gates firing on cleaner data. Crucially, today has **zero proposals reaching the gate**: strategies are bailing out at the state-publish step (`shouldTrade: false`) before they even emit a proposal. That's by design when ADX < 20 / impulse < 1.5 ATR / range-too-wide-or-narrow.

## 11.5 catastrophe-day 15:14 cluster context

Trades 5–7 (xau-scalp-overlap shorts at 15:14:31 / 15:19:59 / 15:33:04) executed into ADX 32 → 35 (peaking) with ATR climbing 9.9 → 10.6 — a genuine trend extension. All 9 trades on 11.5 tagged `portfolio_regime_at_entry = TRENDING`. The scalp-overlap shorts faded a real impulse rally (price 4717 → 4733) — that's the "trend-pause" gap Karri flagged on 12.5. Now backfilled, the data confirms it: A5 enrichment showed every trade was placed during a confirmed trending regime, ATR rising, ADX rising. So the failure was strategy selection (scalp-overlap counter-trending a strong trend), not regime misclassification.

## Top 2 hypotheses for zero trades today

1. **Legitimate regime mismatch (most likely)** — Market is in a tight $34 range with declining ATR (6.5) and ADX collapsing toward 14. Detector says RANGING; gates correctly disable trend strategies. The two enabled strategies (range_reversion, scalping) each require an impulse or ADX condition that current price action doesn't satisfy. State topics confirm:
   - `mean-reversion.state`: `impulse_too_small: 1.33 ATR < 1.5` (need a thrust to fade)
   - `pullback-continuation.state`: `adx_too_low: 15.1 < 20`
   - `trend-following.state`: `adx_too_low: 15.1 < 22`
   - `breakout-continuation.state`: `no_clean_breakout`
   - `vol-expansion.state`: `ATR ratio 0.65 < threshold 1.3`
   - `session-break.state`: `Range too wide ($88.66)` — opening range exceeded width cap (could be a tunable; flag for Karri but not a bug)
   - Worker is alive: 6048 blackboard events since 22:00 UTC, last event 9:19:58. Portfolio context publishing every ~1 min. Data flowing, decisions firing, just no positive triggers.

2. **Session-gate over-restriction (worth a sanity-check, not urgent)** — 635 of 1381 rejections today are `session_not_allowed` — the largest single category. That's partly normal early-Oslo overhead (ASIA_PREPARE_FOR_LONDON / LONDON_OPENING_RANGE block until ~10:00–10:30 CET). But combined with `session-break`'s "Range too wide $88.66" rejection it's worth verifying that the session-window logic isn't dropping us into an over-cautious posture today specifically. Not a smoking gun — same gates ran 12.5 and produced 4 trades — but the interaction of high session-block rate + low ADX means a single session unlock without an ADX recovery still won't produce signals.

## Recommendation

Hold. Don't loosen anything mid-session. Re-check at 11:30 Oslo (London open + 1h) and again at 15:30 Oslo (NY open + 30m). If by 16:00 Oslo we still have zero proposals AND ADX has crossed 22 in a confirmed trending direction, then dig into why momentum_breakout / trend_macro didn't fire. Until then this is the system doing exactly what we asked it to do on a quiet morning.

Data sources: `blackboard` (xauusd.portfolio.context, xauusd.signal.rejected, xauusd.analysis.technical, xauusd.*.state), `simulated_orders`.
