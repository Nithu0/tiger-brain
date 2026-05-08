---
tags: [nexus, strategy, scalp-overlap]
type: atomic
created: 2026-05-08
---

# Strategy-Scalp-Overlap

Mean-reversion scalp strategy active during the London-NY overlap window (12:00-16:00 UTC). Lives in `apps/worker/src/firm/scalp-overlap/`.

**Status: OFF by default.** Activation: `SCALP_OVERLAP_ENABLED=true`.

## What it does

Enters on RSI extremes during the overlap window. Mean-reversion bet that price reverts toward the median while liquidity is highest. Exits on TP or SL, both ATR-anchored.

## When it triggers

- Time window: 12:00-16:00 UTC (London-NY overlap)
- RSI hits extremes (over/oversold)
- Spread + slippage acceptable for ATR-anchored stops

## Key thresholds (sweet-spot from 90d OANDA backtest 2026-04-26)

- SL = 1.0 × ATR(14)
- TP = 1.75 × ATR(14)  → R:R 1:1.75
- Backtest WR ≈ 51%
- Edge ≈ +0.20R per trade

## Files

- `apps/worker/src/firm/scalp-overlap/config.ts` — env-gated parameters
- `apps/worker/src/firm/scalp-overlap/index.ts` — module surface
- `apps/worker/src/firm/scalp-overlap/scalp-manager.ts` — entry/exit logic
- `apps/worker/src/firm/scalp-overlap/scalp-manager.test.ts` — tests

## Current state

OFF on Railway. Was deployed in TIER 3 batch 2026-04-26 alongside [[Strategy-Session-Breakout]] and [[Strategy-Vol-Expansion]] for parallel observation but is not currently activated.

The `scalp_overlap_asia` gate is observation-only at present and is flagged as a known design issue — the gate currently only evaluates inside the firm-blade-path, which means it would need to be moved to a cross-path hook before reliable activation. See `_repo-docs/ops/phase-status.md` "Åpne problemer".

## Related

- [[Strategy-Session-Breakout]] — TIER 3 sibling
- [[Strategy-Vol-Expansion]] — TIER 3 sibling
- [[Strategy-ORB]] — flagship, currently LIVE
- [[Module-Exposure-And-Shield]] — gate logging
- [[Foundation-Gate]] — required-green before activation
- [[Strategy-Proposal-Workflow]] — Karri reviews any threshold change
