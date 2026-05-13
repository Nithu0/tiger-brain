---
title: Conviction-score — composite signal-strength + Karri's open calibration question
source: Nexus codebase + Karri's open Q#2 + Carver
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 4
claude_priority: P1
tags: [library, concept, conviction, karri-owned, calibration]
status: distilled
---

# Conviction-score

A composite scalar in [-1, +1] that Blade computes per cycle as "how strongly does the firm collectively want this trade." Karri's open Q#2 (round-2 corpus): **is this scalar actually predictive of edge, or noise dressed up as a number?** Until calibration data lands, the score is observed but does not move money.

## What it is

Lives in `apps/worker/src/firm/conviction/` (`scoring.ts`, `adapters.ts`, `config.ts`). `computeTieredConviction()` is pure — no DB, no side effects — and takes:

1. `StandardEngineOutput[]` — one entry per engine (macro, technical, structure, sentiment, intermarket, momentum, session), built by `buildStandardEngineSet()` from blackboard messages.
2. `regime` from Portfolio Brain → resolved to BASE/TRENDING/RANGING/HIGH_VOLATILITY weight maps.
3. `sessionMultiplier` (0..1.2) from Session Engine.

Three tiers (`TIER_MEMBERSHIP`): **direction** (macro, structure), **timing** (technical, momentum), **confirmation** (sentiment, intermarket). Each engine contributes `signal * confidence * weight * regime_fit`, normalized per tier to [-1, +1]. Tiers are weighted (`direction 0.45, timing 0.35, confirmation 0.20`) then scaled by `sessionMultiplier * (0.5 + 0.5 * regime_fit_avg)`. Clamp to [-1, +1].

Soft gates (env-overridable): `CONVICTION_MIN_DIRECTION=0.18`, `CONVICTION_MIN_TIMING=0.12`, `CONVICTION_MIN_TOTAL=0.20`. Advise but do not veto — Blade still runs its hard gates.

## Where it's used

- **Persistence**: `strategy-execution.ts` stamps `trades.entry_conviction_score` (0..1, Blade's `proposal.confidence`) and `trades.conviction_total` (-1..+1, tiered output) at fill. NULL pre-2026-05-11 metadata-strip fix `0ad348f`; 138 historical rows still need backfill.
- **Postmortem**: `postmortem.ts:250` reads `entry_conviction_score` for closed-trade analytics.
- **Sizing**: NOT consumed. `risk-sizing.ts` is conviction-blind; sizing depends only on `*_RISK_PCT` env vars.
- **Gating**: only the internal soft tier-gates. No external code blocks on the total.

Today conviction is a **passenger** — recorded, not acted on. Karri's Q#2 decides whether to promote it.

## Karri's open question (Q#2)

Does `entry_conviction_score` quartile 4 (top 25 %) win more often / produce more $/trade than quartile 1 (bottom 25 %)?

- **Monotonic Q1<Q2<Q3<Q4** → calibrated → promote to sizing per `2026-05-11_conviction_quartile_position_sizing.md` (multipliers `{Q1:0.5, Q2:0.75, Q3:1.0, Q4:1.25}`, daily-loss-cap unchanged).
- **Flat / non-monotonic** → noise → do NOT use for sizing.
- **Inverted (Q1 > Q4)** → red flag, composite is structurally broken.

## The Phase 1 dashboard

`apps/dashboard/src/app/analytics/conviction/page.tsx` is the observation-only widget. Backed by `/analytics/conviction-quartiles` (`apps/api/src/routes/analytics.ts:299`) which buckets closed trades into Q1/Q2/Q3/Q4 by `entry_conviction_score` and returns per-strategy x per-quartile WR + $/trade + count + avg score. Windows 7/30/90/365d. No behaviour change — exists to make Q#2 answerable.

## Why 30+ days

Operator-prinsipp #6 sets a 30-day minimum before any conviction-driven behaviour change. Karri's bar is stricter — ≥30 closed scored trades **per strategy** with regime breakdown. `phase-status.md` row 228 gates conviction-as-hard-control on ≥100 logged trades with `conviction_total`. Current state (2026-05-13): two days of clean post-fix data. Sample size is **insufficient** — any conviction-threshold proposal before mid-June is jumping the gun.

## Anti-patterns Claude should avoid

- Do NOT propose `CONVICTION_MIN_*` threshold changes before the quartile dashboard shows real monotonicity. "Feels too loose" is not evidence.
- Do NOT double-count: conviction is built from the same engines that already feed entry-gates. Adding a conviction gate ON TOP of a structure/momentum gate prices the same observation twice.
- Do NOT extrapolate `{0.5, 0.75, 1.0, 1.25}` multipliers as approved — proposal status is still `pending`.
- Do NOT silently change `TIER_WEIGHTS` or `BASE_WEIGHTS` — old persisted scores become non-comparable, breaking the calibration sample. File a proposal.
- Do NOT confuse `entry_conviction_score` (Blade proposal, 0..1) with `conviction_total` (tiered, -1..+1). Both persist.

## Cross-references

- **Carver, *Systematic Trading* ch. 7-9** — forecast combination. Carver's scaled forecast (cap ±20) is the same idea: subsystem signals → weighted composite → sizing. Carver's own evidence bar is years of data per instrument, which contextualizes why 30 days is the bare minimum.
- **Bayesian decision theory** — conviction-as-posterior: engines are likelihoods, weights are priors, regime_fit is a context-conditional discount. Calibration question = is the posterior well-calibrated (an 0.8 trade wins ~80 %).
- **Project docs**: `docs/strategy/proposals/2026-05-11_conviction_quartile_position_sizing.md`, `docs/ref/analytics.md`, `apps/worker/src/firm/conviction/`.
- **Library**: `karri_evidence_bar.md`, `foundation_gate_tier3.md`.
