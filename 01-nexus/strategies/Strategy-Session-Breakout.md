---
tags: [nexus, strategy, session-breakout]
type: atomic
created: 2026-05-08
---

# Strategy-Session-Breakout

Trades breakouts of prior session ranges. Lives in `apps/worker/src/firm/session-breakout/`.

**Status: OFF by default.** Activation: `SESSION_BREAKOUT_ENABLED=true`.

## What it does

Two trigger windows:
- **London Open (08:00 London)** — break of the prior 16h "Asia" range
- **NY Open (14:30 London)** — break of the London session range (08:00-14:30)

SL is the opposite side of the source range. TP at 1.5× the risk distance.

## When it triggers

- Session-window crossing (London or NY open)
- Price breaks out of the prior session's range
- Risk-distance acceptable vs TP target

## Key thresholds (90d OANDA backtest 2026-04-26)

- TP_R = 1.5 (TP = 1.5 × risk distance)
- SL = opposite side of source range
- WR ≈ 46%
- Mean PnL ≈ +$440 over 90d

## Files

- `apps/worker/src/firm/session-breakout/config.ts`
- `apps/worker/src/firm/session-breakout/index.ts`
- `apps/worker/src/firm/session-breakout/session-break-manager.ts`
- `apps/worker/src/firm/session-breakout/session-break-manager.test.ts`

## Distinction from ORB

ORB ([[Strategy-ORB]]) builds a fresh opening range during the first 15-30 min of London and then waits for breakout of THAT range. Session-breakout uses the **prior** session's range as the breakout reference, and trades both London Open (Asia → London) and NY Open (London → NY).

## Current state

OFF on Railway. Part of the TIER 3 deploy 2026-04-26 alongside [[Strategy-Scalp-Overlap]] and [[Strategy-Vol-Expansion]]. Pending operator OK kjør for activation.

## Related

- [[Strategy-ORB]] — different breakout reference range
- [[Strategy-Scalp-Overlap]] — TIER 3 sibling
- [[Strategy-Vol-Expansion]] — TIER 3 sibling
- [[Module-Exposure-And-Shield]] — gate interlocks
- [[Foundation-Gate]] — required-green before activation
- [[Strategy-Proposal-Workflow]] — [[Karri]] reviews threshold changes
- [[Operator-Principles]] — prinsipp 1 (no auto-disable) + prinsipp 4 (foundation-først)
