---
title: Opening Range Breakout (ORB) — Nexus xau-orb lens
source: Nexus codebase + Fisher (ACD) + Crabel
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 5
claude_priority: P0
tags: [library, strategy, orb, breakout, fisher, crabel]
status: distilled
---

# Opening Range Breakout (XAUUSD, Nexus lens)

## What it is (50 words)

Define a high/low range across the first 30 minutes of a session. Wait for a candle to CLOSE outside the range; that close is the directional signal. Stop on the opposite side of the range, target a multiple of range width. Mechanical, session-bound, range-derived risk — no LLM judgement layer.

## Why XAUUSD specifically (60 words)

Gold's M15 personality during the London (08:00 BST) and NY (14:30 BST) opens is range-respect followed by stop-hunter / breakout-trader collision. Range width self-calibrates to current volatility (auto-scales spread/slippage cost). The London-NY overlap concentrates flow into ~6 hours, so two formation windows cover the high-liquidity day. Outside-window noise is filtered for free.

## Nexus implementation (precise, from `apps/worker/src/firm/orb/`)

- **Formation**: 08:00–08:30 London local, plus 14:30–15:00 (NY). 5m candles establish `OR_high` / `OR_low`.
- **State machine**: ARMED → BROKEN → RETESTING → CONFIRMED → EXPIRED / INVALIDATED. Confirmation requires 5m CLOSE outside range (wicks ignored — "ORB-killer nr. 1" per master plan).
- **Hard gates**: range width ∈ [$3, $10] (`ORB_RANGE_MIN_USD`/`MAX`); breakout window ≤ 3h after formation; momentum filter body/range ≥ 0.6; pre-move filter blocks if Asia consumed >60% of ADR; ATR-expansion ratio ≥ 1.1 vs 20-bar avg.
- **Fit score (0–100, gate ≥40)** + **5 binary criteria** (range_sweet_spot, momentum_strong, retest_entry, atr_expanding, regime_aligned).
- **Trend filter**: rejects LONG in bearish market structure (and mirror) from `xauusd.analysis.technical`.
- **SL**: opposite side of range (or midpoint ± 0.3× for stramme ranges). **TP1/2/3** = range × multipliers. Daily cap 5 trades. Re-entry only on explicit stop-out, never auto-rearm (28.4 lesson: 4 shorts in 10 min on same OR_low).
- Master switch `ORB_ONLY_MODE=true` bypasses Prism + Blade entirely; signal routes direct to execution.

## What's been validated live

Adopted 24.4, first trade 27.4 with `ORB_ONLY_MODE=true`. Currently LIVE per phase-status.md table (`ORB_ENABLED=true`). Karri added `orb_observe_only` to TIER 1 proposals after a -$398 bleeding day — i.e. live edge has not held in current regime; observe-only flag merged but not flipped pending operator OK. Roadmap targets (45% WR / 1.5R by month 1, 50% / 1.7R by month 3) **not met** on the live data; concrete win-rate trail lives in `orb_setups` + `simulated_orders` tables, not yet auto-summarised.

## Where it fails

- **Range too narrow** (<$3 / <0.5× ATR): every wick prints a fake breakout. Hard min on width.
- **Range too wide** (>$10 / >3× ATR): exhaustion regime — breakout has no runway. Hard max.
- **News-driven impulse** before the close confirmation: turns the strategy into chasing. Pre-move filter (60% ADR threshold) is a proxy; dedicated news-blackout gate (≤30 min) per master plan but not visible in current config.
- **Trend-pause regimes** (Karri's 12.5 hypothesis): a clean breakout with ADX-momentum followed by stall, not continuation. Nexus has no dedicated trend-pause detector yet — `regime_direction_gate` proxies it.
- **Choppy retests**: state machine fix landed but operationally still vulnerable to multiple intraday entries on the same range when daily cap not yet exhausted.

## Cross-references

- **Fisher — *The Logical Trader* (ACD method)**: the canonical ORB framework. Nexus's "5m close outside range" is Fisher's A-up / A-down. Fisher's **pivot range** (3-day rolling) is not implemented — would give a higher-timeframe context filter for Nexus's session-only ranges. Fisher's failed-breakout playbook is the textbook source for the trend-pause-vs-flip distinction Karri is researching.
- **Crabel — *Day Trading with Short Term Price Patterns and Opening Range Breakout***: the empirical pattern catalogue. Crabel's **"stretch"** (avg of smaller of |open-high|, |open-low| over N days) is exactly the kind of self-calibrating range-width threshold Nexus hand-tunes via env vars. NR4/NR7 (narrow-range precursors) are Crabel's prediction that *tomorrow's* range will expand — Nexus could pre-filter trade days by NR4/NR7 the previous close.
- **Raschke & Connors — *Street Smarts* ("Turtle Soup")**: explicit failed-breakout fade. Directly relevant when ORB CONFIRMS but price snaps back inside range within 60–90 min — currently no fade module in Nexus, but operator's master plan flags `ORB_BOS_REVERSAL_ENABLED` as a future extension (Turtle Soup is the literature for it).
- **Carver — *Systematic Trading***: volatility-targeting and forecast scaling. Nexus's fit-score is a homegrown forecast-combination; Carver's framework would replace it with a properly capped/scaled forecast that integrates ORB + S4 + vol-expansion outputs cleanly.

## Operational notes

- Strategy ID: ORB. Module: `apps/worker/src/firm/orb/`. DB: `orb_ranges`, `orb_setups`, `simulated_orders` (with `entry_type`, `range_size_usd`, `result_r`, `orb_range_id`).
- Blackboard: `xauusd.orb.range`, `xauusd.orb.state`, `xauusd.orb.signal`.
- Rollback: `ORB_ENABLED=false` (or `ORB_ONLY_MODE=false` to restore Prism+Blade path).
- Live status 13.5: enabled but under Karri scrutiny pending `orb_observe_only` decision. Not in autotune (operator-principle #6 — needs 30+ days clean data).
