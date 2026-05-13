---
title: Mean Reversion (S4) — Nexus xau-mean-reversion lens
source: Nexus codebase + S4 proposal + Chan + Connors
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 5
claude_priority: P0
tags: [library, strategy, mean-reversion, s4, chan, connors, rsi]
status: distilled
---

# Mean Reversion (XAUUSD, Nexus S4 lens)

## Archetype (50 words)

Bet that price reverts to a moving anchor (rolling mean, recent VWAP, or pre-impulse level) after a fast displacement. Opposite of trend-follow: enter against the most recent impulse, take small reward relative to anchor distance, exit fast. Edge comes from the cross-sectional fact that most short-horizon moves are statistically over-reactions.

## Why XAUUSD has mean-revert windows (70 words)

Gold's tape alternates between trending regimes and chop/exhaustion phases. Three reliable MR windows: (1) post-news exhaustion — Fed/CPI prints cause $30-60 impulses that overshoot fair value within 30-60 min, then unwind; (2) profit-taking off psychological levels ($4700, $4650) where US-funds book gains in NY session; (3) Asia chop — thin volume keeps price oscillating around H1 VWAP because no one is positioning directionally. S1/S2/S3/Vol-Exp lose money in all three; S4 is built for them.

## The Nexus implementation (8-gate pipeline)

`apps/worker/src/firm/mean-reversion/mean-reversion-manager.ts`, wired at `orchestrator.ts:430` Step 1i.

1. `MEAN_REVERSION_ENABLED=true` env-gate
2. Cooldown 60 min + daily cap 2
3. Session ∈ `{NY_CONTINUATION, LONDON_ACTIVE}` (Asia blocked — chop without volume = false signals)
4. ATR / ADX / RSI available
5. **ADX < 25** — only chop/ranging, never trend
6. **Impulse ≥ 1.5 × ATR** over last 2 H1 candles
7. **RSI extreme**: <40 for LONG, >60 for SHORT (looser than classic 30/70 — backtest preferred more setups over rare-extreme purity)
8. Confirmation candle: OFF (redundant with RSI)

Entry = OPPOSITE of impulse direction. SL = entry ± **0.75 × ATR** (tight — MR moves fast or fails). TP = entry ± **2.25 × ATR** for R:R 1:3. Time-stop 6h. Risk 0.5%/trade.

## Anti-correlation design (the portfolio point)

S4 is the only counter-trend strategy among S1/S2/S3/Vol-Exp/Session-Breakout (all continuation). Live 11.5 + 12.5 (2 of last 10 trading days) saw continuation-strategies stack SLs because every entry got rebounded. S4 would have LONGed those bottoms. The ADX<25 gate is the structural defense against firing during trend-continuation; a cross-strategy `mean-revert-gate` (PR #22, `b31fbae`) blocks continuation-strategies when S4 likely fires — verify no portfolio fights itself by entering LONG (S4) and SHORT (Vol-Exp) on the same impulse.

## Sweet-spot tuning context (PR #24, 13.5)

MVP config (R:R 1:1.5, RSI 30/70, ADX≤30, 2.5 ATR impulse, NY-only) gave 2 trades / 6 mo — useless. Sweet-spot loosened the entry filters (1.5 ATR, RSI 40/60, +London session), tightened SL (1.5 → 0.75 ATR) and pushed TP wide (1.5R → 3.0R). Backtest claim: **n=54, WR 51.9%, PF 2.56, Net +$608, MaxDD $95** on 2867 H1 candles. Karri verbal-approved same day (`8c6bcba`). Live activated `MEAN_REVERSION_ENABLED=true` 13.5 ~00:44 UTC.

## Single biggest live risk

**News-block is not implemented.** Karri review question #5 (block before FOMC/NFP/CPI) is unanswered. Mean-reversion logic assumes the impulse is exhaustion, not a fresh repricing — news creates fresh repricings that keep going. A 2.5 ATR move into NFP can produce another 2 ATR after, and S4 will LONG into a continuing crash. Existing macro-calendar agent provides the signal; gluing it into gate 0 is unblocked work. Until then, monitor first 30 days for SL streaks around macro prints.

## Cross-references

- **Chan ch 2** — Ornstein-Uhlenbeck half-life of reversion. If gold's H1 half-life is >6h, the 6h time-stop is mis-sized. Worth measuring on Nexus's live tape; the sweet-spot is empirical, not OU-derived.
- **Chan ch 3** — Bollinger MR with z-score-proportional sizing. Nexus uses fixed 0.5% — Chan would scale up at z=2.5 vs z=1.5. Future enhancement.
- **Connors RSI(2)** — classic 2-period RSI <10 / >90 on daily closes for swing MR. Nexus uses 14-period H1 at 40/60 (much looser, intraday horizon). Same logic, different timescale.
- **Raschke "Turtle Soup"** — failed-breakout fade, structurally identical archetype (fade the impulse). Worth re-reading when wiring trend-PAUSE detection that Karri flagged.
