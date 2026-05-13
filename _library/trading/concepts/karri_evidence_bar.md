---
title: Karri's evidence bar — what counts and what doesn't
source: 24-proposal harvest + Karri verbal-approval audit trail
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 5
claude_priority: P0
tags: [library, concept, reviewer, karri-owned, evidence, proposal-bar]
status: distilled
---

# Karri's evidence bar

Karri reviews money-impact changes for Nexus. He does not publish a written rubric — the bar is reconstructed from 24 proposals (2026-05-08 → 2026-05-13): what got approved, what got parked, what he asked Claude to re-instrument. This is the working enforcement model. Apply it on every proposal before filing.

## What counts as evidence

- **≥6 months of OANDA H1 data**, replayed by the actual entry/exit logic (not theoretical edge math). S1/S2/S3/S4 all cleared this bar before the live-flag flipped.
- **≥30 closed trades** in the backtest sample. This is Karri's soft floor for any "statistical" claim (operator-prinsipp #6, mirrored by Karri's approval pattern).
- **Sweet-spot tuning commit referenced** — parameter sweep + composite test, defaults landed as a separate commit before activation. PR #24 (vol-exp sweet-spot) and the `// Sweet-spot 2026-05-12` comments in `pullback-continuation/config.ts` are the canonical examples; Karri's original S3 ADX≥25 produced zero trades, so the tuned default ADX≥20 is the load-bearing change.
- **Per-trade instrumentation**: WR, R-multiple, MFE/MAE per trade, session breakdown, regime breakdown, $/trade. Aggregate "60% WR" without distribution is not evidence.
- **Walk-forward or out-of-sample slice** — a single backtest period that also functions as the tuning set is suspect. Sweet-spot tuning + a held-out window beats one-shot fits.
- **Funnel rejection-tagging deployed FIRST**, then 14 days of shadow logs, then threshold proposal. Vol-expansion throttle review explicitly bounced for this reason: "instrument first, decide later."
- **Convergence of multiple independent analyses** pointing to the same conclusion (tap1 + tap2 + Claude) — counts as corroboration even when N is small.

## What does NOT count

- A single in-sample backtest with no held-out window.
- Theoretical edge math without trade simulation (Sharpe-on-paper, no replay).
- Threshold tuning proposed before rejection-tagging exists — Karri sends it back every time.
- "60% WR over N=12" without MFE/MAE / session / regime breakdown.
- "While we're here" stacked changes — must be one focused diff per PR.
- Behaviour changes without a named env-flag (default OFF) and a 30-second rollback path.

## The structural-problem override

Small samples (N=3-4) are acceptable when the problem is structural, not statistical:

- **R:R math is broken** at the strategy level (e.g. SL/TP geometry guarantees negative expectancy at the observed WR).
- **MFE = $0 across all observed trades** — the thesis is simply not playing out, regardless of N.
- **Acute incident** (catastrophic loss day) + **convergence of independent analyses** all pointing at the same failure mode. The 11.5 regime_direction_gate landed on this basis: 28 vol-exp + 4 scalp-overlap trades, sub-30 sample, approved because 3 independent post-mortems agreed and the day's bleed was structural.
- **Post-impulse blind**, "memory loop", "loss compounding" — Karri's named structural failure modes. Each bypasses the 30-trade floor.

The override is not a free pass: the proposal must still file the env-flag, the rollback path, and the open questions. Structural means "act now, instrument in parallel", not "skip the doc".

## Claude checklist (apply before filing)

- [ ] Backtest period ≥6 months OANDA H1?
- [ ] Closed trades ≥30 (or structural-override invoked with explicit rationale)?
- [ ] Sweet-spot tuning commit referenced (SHA + parameter table)?
- [ ] Funnel rejection-tagging deployed FIRST if the proposal touches a threshold?
- [ ] Env-flag default-OFF with named `*_ENABLED` knob and 30-second rollback?

## Worked examples

- **Clears the bar**: PR #24 vol-exp sweet-spot tuning — 6mo OANDA H1 replay, parameter sweep, MFE/MAE per trade, defaults landed as separate commit before live flip, behind `MEAN_REVERSION_ENABLED=false` default.
- **Karri would push back**: a proposal saying "raise vol-exp ATR threshold from 1.15 to 1.30 because the last 12 trades lost". No rejection-tagging, no held-out slice, threshold-only, N below floor, no structural rationale. He sent the equivalent back as `vol_expansion_throttle_review` → "instrument 14d first."

## When in doubt

FILE the proposal with `Status: evidence pending` rather than skipping it — Karri prefers a written record over a silent omission, and the audit trail is what lets verbal approvals stick.
