# C4 — Postmortem risk-feedback proposal (audit)

**Date:** 2026-05-13
**Agent:** Karri-curriculum agent, round 3
**Output:** `docs/strategy/proposals/2026-05-13_postmortem_risk_feedback.md`
**Status:** proposed, awaiting Karri

## Findings

- Writer-side reliable: `postmortem-hook.ts:163-203` inserts every close into `postmortems` table (`packages/shared/src/db/schema.ts:1059-1077`). Indexed on `(classification, created_at DESC)`.
- Classifier emits `RIGHT_THESIS_BAD_EXECUTION` from `postmortem.ts:217,221` when lifecycle-event signature matches.
- Existing consumers of `postmortems` (strategy-tuner, trade-critic, daily-journal) read for rapporter/lessons — **none** mutate risk-sizing. Confirmed dormant feedback loop.
- Bleed-data: 16/16 losers tagged `RIGHT_THESIS_BAD_EXECUTION` 06.5→10.5 (100%) vs 4/11 pre-bleed week (36%). Cluster signal real; classifier may be over-tagging via "no lifecycle events" fallback — shadow-mode catches this.

## Proposal differentiation vs `2026-05-11_postmortem_size_down_feedback.md`

The 05-11 proposal used "2 consecutive RIGHT_THESIS_BAD_EXECUTION" as trigger. This 05-13 proposal generalizes to **window-concentration** (T over W), gives Karri three window models (time / trades / hybrid), and three-mode env-flag (`off|shadow|active`) instead of binary on/off. Phase-1 streak table from 05-11 is already landed in observation-only — this builds on top, not orthogonal.

## Karri-owned knobs surfaced

T (threshold), W (window), M (multiplier), MIN_SAMPLE, RESET condition (first WIN / 2 WINS / time-elapsed / regime-change), tag-strict-vs-loose, order vs daily_trade_cap. All defaulted but flagged for his call.

## Evidence gate

14-day shadow log + historical backtest over `postmortems` table (data from 2026-04-19) before `MODE=active` flip. Per operator-prinsipp #6 (≥30d data for autotune).

## Rollback

`POSTMORTEM_RISK_FEEDBACK_MODE=off` env flip → instant. 3-mode stairway means every step revertable in 30s without code change. No DDL changes (table + index already exist).

## Not committed

Per instruction — file written to repo, not staged or committed. Karri-auto-send applies (Nordic work hours).
