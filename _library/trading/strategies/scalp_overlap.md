---
title: Scalp-overlap (session-overlap mean reversion) — Nexus xau-scalp-overlap lens
source: Nexus codebase + 11.5 13:14 forensics + Raschke Turtle Soup
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 5
claude_priority: P0
tags: [library, strategy, scalp-overlap, mean-reversion, session-overlap, raschke]
status: distilled
---

# Scalp-overlap (session-overlap mean reversion, Nexus lens)

## What "session-overlap scalping" is (60 words)

A mean-reversion archetype that only fires during a session-overlap window — most commonly London-NY (12-16 UTC) or Asia-London (07-09 UTC). Inside the window: wait for an RSI extreme (oversold/overbought) on a fast timeframe (5m/15m), fade it with a tight ATR-stop and a 1.5-2x ATR target. The window is the filter; the indicator is the trigger.

## Why XAUUSD's overlap windows produce edge (in theory)

Two-session overlap is when two desks are both at the screen — London still open, NY just in. Volume spikes 2-3x the surrounding hours, but on most days that incremental flow is **two-sided liquidity provision**, not a directional bet. Result: range *contracts* relative to its volatility — tight intraday channels around a drift. RSI excursions to 25/75 inside such a channel mean-revert with positive expectancy in backtests (Nexus 90d OANDA: WR ~51%, +0.20R/trade at SL=1.0x ATR, TP=1.75x ATR). The strategy is *betting on the regime*, not on price.

## Nexus entry trigger + gates (from `scalp-manager.ts`)

- **Window**: UTC decimal hour in [12.0, 16.0). Core window 13.0-15.0 boosts confidence.
- **Trigger**: RSI(14) on 15m. <=25 -> LONG, >=75 -> SHORT.
- **Stop**: 1.0 x ATR(14) on 15m. Target: 1.75 x ATR. R:R 1:1.75.
- **Caps**: 3 trades/day, 5-min cooldown between signals, no stacking while open.
- **Confidence criteria (5/5 binary)**: RSI >=3pt past trigger, ATR in [$1.50, $6.00], in core 13-15 window, daily room remaining.
- **Invalidator (declared but not enforced)**: `"Strong trend overrides mean-reversion — caller should check regime"`.

## What 11.5 13:14 actually revealed

The strategy fired **3 SHORTs in 19 minutes** ($4720, $4727, $4735) inside an ~$80 USD impulse leg. All three hit SL. PnL: -$1058. Forensic point: **every gate the strategy owned was green**. RSI was >75 (deeper each time — criterion `rsi_strength` passed harder). ATR was in band. Window was core. Daily room available. The strategy did *exactly what its rules said* — the rules were just blind to a trending regime layered on top of the overlap window.

**The bug is not in scalp-overlap.** The bug is the missing layer above it:
- No **regime-direction gate** — if H1 trend is up, block fresh SHORTs from any mean-rev strategy.
- No **cross-strategy stack-cooldown** — three SHORT entries within 19 min, each $7 higher, should have been one trade max.
- No **trend-pause detector** (Karri's 12.5 hypothesis — the actual root cause across S1/S3/scalp).

The strategy was correctly disabled via `SCALP_OVERLAP_ENABLED=false` (proposal `2026-05-11_scalp_overlap_observe_only.md`) — observe-only until regime-direction gate is live.

## Where it inherently fails

Every mean-reversion strategy fails the same way: when the impulse continues. Session-overlap scaling has two compounding failure modes:

1. **Trending overlap days** — NY open in a strong-USD or geopolitics regime turns the overlap into a continuation window, not a contraction window. RSI sits at extreme for hours, not minutes.
2. **News inside the window** — FOMC, NFP-revisions, gold-specific catalysts at 14:00 UTC flip the volume-spike from two-sided to one-sided. The strategy's premise (volume = liquidity provision) inverts to (volume = directional flow).

Both modes look identical from inside the strategy: deep RSI, ATR in band, window green. It cannot self-diagnose.

## Cross-references

- **Linda Raschke — *Street Smarts* (Turtle Soup)**: the canonical failed-breakout fade. Raschke's setup is structurally what scalp-overlap is *trying* to be — fade an extreme into a contracted regime. But Raschke explicitly requires the *prior 20-day high* was broken by no more than a thin margin and then *rejected within 2 bars*. Nexus's pure-RSI trigger has no equivalent rejection-confirmation candle. Adding a 1-bar rejection filter (close back inside the prior 15m range) would be Raschke-faithful and would likely have skipped all three 11.5 entries.
- **Robert Carver — *Systematic Trading***: filter-speed combinations. Carver's rule: when stacking filters of similar speed (RSI 15m + ATR 15m + window 15m horizon), correlation between filters is high — they all say "yes" or "no" together, so you get **fewer independent signals than the count suggests**. Nexus's 5-criterion confidence score double-counts: `rsi_strength` and `core_overlap_window` and `atr_floor` are not independent. A truly diversifying filter must be *slower* (H1 regime) or *orthogonal* (cross-asset DXY direction). Until that exists, the 5/5 confidence is theatre.
- **Crabel — NR4/NR7**: similar range-contraction philosophy, but Crabel measures contraction *in the price action itself* (4-day narrowest range), not by proxy (session window). Nexus could harden the premise by requiring the prior H1 range to actually be sub-median before fading inside it.

## Operational notes

- Re-activation gate per Karri 11.5: regime-direction-gate live + SL-cooldown live + session-block live. Then flip `SCALP_OVERLAP_ENABLED=true`.
- State-snapshots (`xauusd.scalp.state`) keep emitting while disabled — preserves data for retrospective evaluation.
- Sample size is tiny (4 historical matched trades, 1W/3L = 25% WR) — disable is precautionary, not statistically conclusive. The regime-direction logic matters more than the strategy itself.
