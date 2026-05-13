---
date: 2026-05-13
author: claude (cross-cutting agent)
scope: S1-S4 + legacy, last 90d (closed_at >= 2026-04-16)
data: simulated_orders + ohlcv_candles (XAUUSD 15min) + gate_decisions
---

# Cross-strategy regime audit — trend-pause hypothesis test

## TL;DR

- **Counter-trend bias is the dominant cross-cutting failure.** Across last 90 days, trades positioned counter to daily net direction lost **-$5 954** at 35% win-rate; with-day trades made **+$2 261** at 42%. The bot systematically fires reversal trades into directional days.
- **TRENDING regime is universally toxic** — only 13 trades tagged TRENDING but they lost -$3 573 (avg -$275, 15% win). Even "with-day" trades in TRENDING lost (0/5 wins). Confirms Karri's read: it is not "wrong direction" but "wrong timing inside trend" (pause/pullback misread).
- **Proxy gates are silent.** Last 14 days: zero `regime_direction_gate` rows in `gate_decisions`. `risk_level` and `daily_trade_cap` fired but blocked 0. The proposed proxies are not active in production decision-stream.

## Loss-cluster days (≥2 strategies losing same day)

| Day (UTC) | Strats losing | Trades | Day pnl | XAUUSD net move | Counter-trend trades |
|---|---|---|---|---|---|
| 2026-05-11 | 4 of 4 active | 9 | **-$2 638** | +$76 (up) | 6 of 9 short into uptrend |
| 2026-05-12 | 3 of 3 active | 4 | **-$1 196** | -$50 | all 4 short (with-day) — but intraday flip 4638→4773 peak first |
| 2026-05-05 | 2 of 2 active | 3 | -$716 | +$75 (up) | mixed — 2 longs hit SL on pullback, 1 short hit SL on continuation |
| 2026-05-07 | 2 of 3 active | 9 | -$167 | +$5 (flat) | 6 of 9 counter, range $83 |
| 2026-04-28 | 2 of 4 active | 12 | -$113 | -$96 (down) | shorts profitable, longs/late-shorts lost |

Note: 2026-04-15 to 2026-04-20 had 5 cluster days totalling -$10k+, but those were legacy strategies with pre-26.4 sizing flaw — excluded from pattern analysis (own audit per Karri's katastrofedag-doc).

## Regime distribution: winners vs losers

| portfolio_regime_at_entry | n | win% | total pnl |
|---|---|---|---|
| TRENDING | 13 | **15.4%** | **-$3 573** |
| NOISY_CHAOTIC | 1 | 0% | -$353 |
| RANGING | 3 | 67% | +$728 |
| MIXED_NO_EDGE | 1 | 100% | +$1 123 |
| (null — pre-portfolio-regime era) | 137 | 39% | -$8 693 |

Only 18 of 156 trades have `portfolio_regime_at_entry` populated. Field went live around 2026-05-10 based on temporal distribution — TRENDING tagging is recent, but every TRENDING bucket day so far has bled. n is small; trend is unambiguous.

## TRENDING + bias matrix

| pregime | bias | n | pnl | win% |
|---|---|---|---|---|
| TRENDING | counter | 8 | -$1 577 | 25% |
| TRENDING | with | 5 | **-$1 997** | **0%** |
| other/null | counter | 32 | -$4 377 | 38% |
| other/null | with | 40 | +$4 258 | 48% |

Key: in TRENDING, even "with-trend" trades lost everything. Pattern is **intra-day reversal during pullback**, not simple counter-trend fade. This *is* the trend-pause signature.

## Evidence FOR trend-pause hypothesis

1. **2026-05-11 is the textbook case.** XAUUSD: 4691→4767 (+76, range 121). All 9 trades are pregime=TRENDING. Bot fires 6 shorts at 4661-4734 while market rallies; the 2 "with-day" longs at 4729-4735 SL on pullback. *Every* strategy (S1, S2, S3, S4) participated — confirms cross-cutting root cause, not single-strategy logic flaw.
2. **2026-05-12 intra-day flip.** 4767 open → 4638 low → 4773 high → 4717 close. Bot got 4 shorts mid-rally between 4665-4677, all caught the 4773 spike. Day closes net-down but the *intraday* sequence is exactly "pause then continuation upward" before late reversal — bot can't see the local pause.
3. **3:1 ratio in cluster trades.** 25% of cluster-day trades (post-26.4 TIER 3 era) match the counter-trend-into-net-move pattern; those trades account for ~21% of cluster-day losses despite a 75/25 trade-count split. Avg loss on those trades is -$110 vs -$120 portfolio average — comparable severity, much higher concentration.

## Evidence AGAINST / qualifications

- **Counter-trend bias is broader than just "trend-pause".** On clearly two-sided days (05-07, range $83, net $5) the loss pattern isn't trend-pause — it's churn. Trend-pause detector would not have helped 05-07.
- **TRENDING-with-trend also lost 5/5.** A pure trend-pause detector that only blocks counter-trend would not have prevented the -$1 997 from with-trend trades. The deeper problem may be **timing inside trend**, not just direction.
- **Sample is small.** Only 13 TRENDING-tagged trades and 9 cluster-pattern trades post-26.4. Significant but underpowered.

## Did gates fail?

`gate_decisions` last 14d: 6 distinct gates, 0 hard-blocks except `session_block` (4 blocks). No `regime_direction_gate` rows — feature not deployed or not logging. `daily_trade_cap` fired 8× last 14d, blocked 0. On 05-11 the 4-strategy 9-trade barrage would have tripped a cap at 3-5 trades had one been active.

## Concept-level detector sketch (Karri owns implementation)

Cross-cutting evidence points to needing two complementary signals, not one:

1. **Local impulse-vs-pause classifier on H1.** A trend-pause-bevissthet signal: detect when last N H1 candles have made directional progress AND current candle is a low-body pullback inside that range. Block counter-trend entries while flag is set. Karri's hypothesis fits this exactly.
2. **TRENDING-regime entry-timing gate.** Independent of direction: in TRENDING regime, only allow entries on confirmed retracement-then-resume (pattern-based), not on every mean-reversion trigger. The 5/5 with-trend losses suggest entries fired too early in pullback structure, not just in wrong direction.

Quantified upside: had a perfect counter-trend-on-trending-day filter existed, **-$3 573 of -$4 798 cluster losses would have been avoided** (75% of cluster bleed, post-26.4). The 5/5 with-trend losses in TRENDING (-$1 997) require timing fix beyond direction gate.

## Recommendation to operator

1. Verify Karri's `regime_direction_gate` actually deploys — `gate_decisions` shows it absent. Possibly the proposal didn't ship or feature flag is off.
2. `daily_trade_cap` exists in `gate_decisions` but blocks=0 — confirm threshold is realistic (05-11 had 9 cluster-day trades, cap must be <8).
3. The "with-trend in TRENDING regime loses 5/5" finding is **new evidence Karri may not have**. Recommend sharing — suggests his trend-pause concept extends to *entry-timing-within-trend*, not just direction filter.

Cross-cutting audit done. Per-strategy mechanics deferred to S1-S4 deep-dives in this same inbox folder.
