---
tags: [nexus, strategy, orb]
type: atomic
created: 2026-05-08
---

# Strategy-ORB

Opening Range Breakout on XAUUSD. The flagship strategy. **Status: LIVE** (`ORB_ENABLED=true`).

The strategy view of when/why this fires. Implementation lives in [[Module-ORB]].

## What it does

Detects the opening range during the first 15-30 min of London session (08:00-08:30 London / 07:00-07:30 UTC). When a M15 candle CLOSES outside the range with sufficient momentum, takes a directional trade. SL on the opposite side of the range; TP at 2R.

## When it triggers

- Range size between 0.5×ATR and 3.0×ATR (not too tight, not too wide)
- M15 close outside range (CLOSE not wick — wick fakeouts are ORB-killer #1)
- ADX ≥ 20 (some directional strength)
- No high-impact news within 30 min
- Asia session consumed ≤60% of ADR (pre-move filter)
- No failed breakout in the same direction in the last 4h
- No already-open same-direction position (anti-stacking)

## Key thresholds (env-gated)

- `ORB_ENABLED=true` — master flag
- `ORB_ONLY_MODE=true` — bypass full Prism synthesis pipeline
- Range window 08:00-08:30 London (configurable)
- AGGRESSIV (default) vs KONSERVATIV entry — env-toggle for retest entry

Full env-flag list in `_repo-docs/ref/feature-flags.md`.

## Decision history

ORB Master Plan adopted 2026-04-24 (`docs/strategy/orb-master-plan.md`). All-in pivot: 12 legacy modules disabled via env flags (challenge-agents, LLM-briefings, postmortem-LLM, memory-recall, CIO dispatcher, market-pulse, macro-analyst, news-analyst, split-technical, prism-synthesis, tiered-conviction, new-gates). First trade target 2026-04-27 London Open.

Roadmap (after ≥30 live trades): BOS reversal, trailing-after-1.5R, time-of-day filter, volume confirmation, FVG confluence — each behind its own env flag, default OFF.

## Current state

LIVE since 2026-04-25. Cold-start delta active: `FIRM_COLD_START_MODE=true`, `FIRM_COLD_START_THRESHOLD_DELTA=-13`, `FIRM_COLD_START_MATURITY_DELTA=-15`. Position-management interlocks ON (see [[Module-Position-Management]]).

## Related

- [[Module-ORB]] — implementation files
- [[Module-Orchestrator]] — step 1b in cycle
- [[Module-Position-Management]] — manages ORB positions post-fill
- [[Module-Exposure-And-Shield]] — Shield news-blackout interlocks
- [[Foundation-Gate]] — gate for ORB tuning
- [[Strategy-Promotion-Workflow]] — how ORB graduated
- [[Strategy-Proposal-Workflow]] — Karri reviews tuning proposals
