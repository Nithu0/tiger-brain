---
title: Volatility Expansion archetype (Nexus xau-volatility-expansion lens)
source: Nexus codebase + Karri-approved proposal
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 5
claude_priority: P0
tags: [library, strategy, volatility-expansion, karri-approved]
status: distilled
---

# Volatility Expansion (XAUUSD, Nexus lens)

## What it is (50 words)

Take an ATR-ratio of recent vs prior bars. When recent volatility spikes meaningfully above its trailing baseline (ratio crosses a threshold), enter in the direction of the most recent bar's body, stopped with a tight ATR-multiple, targeting a wider ATR-multiple. Bet that fresh expansion has follow-through.

## Why XAUUSD specifically (60 words)

Gold trades in long, low-volatility regimes punctuated by news-driven impulse bursts (Fed prints, geopolitics, USD lurches). Once the regime breaks, intraday ranges roughly double for hours, not minutes — so a per-cycle ATR-ratio fires reliably and the breakout has runway. Equity index futures mean-revert faster on the same trigger; gold's structural illiquidity gives the move more legs.

## Entry trigger (precise, from `vol-exp-manager.ts`)

- **Indicator**: ATR-ratio = mean(H1 high-low, last 5) / mean(H1 high-low, prior 15). NB: simple per-candle range, not Wilder's — chosen to match the backtest implementation.
- **Threshold**: ratio >= 1.30 (`VOL_EXP_RATIO`).
- **Direction**: sign of last H1 body (close > open => long).
- **Stop**: 0.7 x H1-ATR(14) (Wilder's, fetched from Twelve Data).
- **Target**: 2.0 x H1-ATR(14) — R:R ~1:2.86.
- **Cooldown**: 240 min between signals; daily cap 4 trades.

## What Karri specifically validated

The **sweet-spot config** (ratio 1.3, SL 0.7 x ATR, TP 2.0 x ATR, cooldown 240 min) survived a 90-day OANDA backtest at WR ~38%, mean PnL +$528. Karri approved it for live deploy 26 April. **The testable claim**: positive expectancy across the 90d window despite low WR, because R:R 1:2.86 + ATR-spike timing produces enough big winners to swamp the 62% losers. Walk-forward gave +$1013 / +$489 / -$236 across three 60d windows — edge is real but regime-dependent.

## Where it fails

- **Post-impulse mean-reversion**: when 2+ ATR has already moved in the signaled direction within ~90 min, continuation probability drops sharply. Live 12 May: two SHORTs fired *after* a $58 (2.5 ATR) fall was nearly complete, then got walked into a $40 rebound. Now gated by `meanRevertBlockEnabled`.
- **Chasing**: entries fired 50%+ into the impulse have negative expectancy — short SL distance, long TP distance, no runway. Gated by `noChaseEnabled` (max 2.0 ATR from impulse start).
- **NY-session SL**: 0.7 x ATR is smaller than 1x NY-session ATR (~$22) in absolute dollars — normal swings hit SL. Session-aware widening (1.2 x ATR in NY) under flag.
- **Borderline confluence**: trades firing on only 3/5 internal criteria (often failing `ratio_not_extreme` + `cooldown_deep` together) lose at much higher rate. Min-confluence gate raises floor to 3 default, configurable up to 5.
- **Regime mismatch**: trend-pause windows (Karri's hypothesis 12.5) produce the ATR spike without follow-through — the strategy has no dedicated trend-pause detector yet.

## Cross-references

- **Crabel — *Day Trading with Short Term Price Patterns and Opening Range Breakout***: the ORB and "range expansion" lineage. Nexus's ratio threshold is structurally Crabel's NR4/NR7 logic inverted (expansion vs contraction trigger).
- **Carver — *Systematic Trading* / *Leveraged Trading***: ATR-based position sizing and R-multiple targeting. Carver argues volatility-targeting is the prerequisite for any breakout system. Nexus's risk-per-trade is fixed % but SL/TP are pure ATR — half-Carver.
- **Connors — ATR Expansion / TRIN-style filters**: similar one-bar trigger philosophy; Connors typically pairs with mean-reversion gate, which Nexus has belatedly added (mean-revert-block).
- **Kaufman — *Trading Systems and Methods* ch. on volatility breakouts**: warns that volatility breakouts decay quickly without trend confirmation. Nexus's `trend_agreement` criterion (last 3 H1 same direction) is precisely Kaufman's filter.

## Operational notes

- Strategy ID: `xau-volatility-expansion`. Files: `apps/worker/src/firm/vol-expansion/`.
- Default OFF; activated via `VOL_EXPANSION_ENABLED=true`.
- As of 13 May this is the only Nexus strategy with PF >= 1 over the firm's 27d live life — but live sample N=37 trades, WR 49%, +$59 avg. Approaching the 30+ closed threshold for autotune but not there yet (operator-principle #6).
