---
tags: [nexus, strategy, vol-expansion]
type: atomic
created: 2026-05-08
---

# Strategy-Vol-Expansion

Volatility-expansion strategy. Trades when ATR is expanding — current ATR ≥ ratio × historical ATR. Lives in `apps/worker/src/firm/vol-expansion/`.

**Status: OFF by default.** Activation: `VOL_EXPANSION_ENABLED=true`. **Currently observe-only — has 0 closed trades.**

## What it does

Detects volatility regime shift and rides the expansion. Bet that once ATR is meaningfully elevated, directional moves persist long enough to capture R:R ~ 1:2.86.

## When it triggers

- Current 5h ATR ≥ 1.3 × prior 15h ATR
- Direction inferred from local price posture
- Spread + slippage acceptable for H1-ATR-anchored stops

## Key thresholds (90d OANDA backtest 2026-04-26)

- ATR ratio threshold = 1.3 (current 5h ATR ≥ 1.3 × prior 15h ATR)
- SL = 0.7 × H1-ATR(14)
- TP = 2.0 × H1-ATR(14)  → R:R 1:2.86
- WR ≈ 38%
- +$528 over 90d

The lower WR is balanced by the bigger R:R — small win rate, big winners.

## Files

- `apps/worker/src/firm/vol-expansion/config.ts`
- `apps/worker/src/firm/vol-expansion/index.ts`
- `apps/worker/src/firm/vol-expansion/vol-exp-manager.ts`
- `apps/worker/src/firm/vol-expansion/vol-exp-manager.test.ts`

## Current state

Listed in `phase-status.md` "Utsatt" (deferred): observer-only, has 0 closed trades. Triggers haven't fired in current observation window. Would need a window of ATR-expansion regimes plus operator OK kjør to activate.

## Related

- [[Strategy-ORB]] — flagship, LIVE
- [[Strategy-Scalp-Overlap]] — TIER 3 sibling
- [[Strategy-Session-Breakout]] — TIER 3 sibling
- [[Module-Fact-And-Analysis-Agents]] — provides ATR / regime classification
- [[Foundation-Gate]] — required-green before activation
- [[Strategy-Proposal-Workflow]] — [[Karri]] reviews threshold changes
- [[Operator-Principles]] — prinsipp 1 (no auto-disable) + prinsipp 4 (foundation-først)
