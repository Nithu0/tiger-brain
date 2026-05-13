# C2 — Session-Breakout SL proposal audit

**Date:** 2026-05-13 (round 3)
**Proposal:** `docs/strategy/proposals/2026-05-13_session_breakout_sl_method.md`
**Reviewer:** Karri (status: proposed)

## What was written

Three-option proposal on `xau-session-breakout` SL methodology:

- **Option A** — Cap SL at min(range_edge, 1.0×ATR(14,H1)). Tightest behaviour wins.
- **Option B** — Swap to swing-based SL: last M15 swing ± 0.25×ATR_M15 buffer.
- **Option C** — Disable strategy pending 6mo backtest re-validation incl. current high-vol regime.

## Inputs read

- Template: `docs/strategy/proposals/README.md`
- Forensics: round2/15_session_breakout_sl_hunt.md (6 SL-hits, –$1111/30d, atr_at_entry NULL)
- Original deploy doc: `docs/ops/archive/tier3-deploy-26april.md` (90d backtest WR 45.9%, walk-forward W3 –$236, overfit-flag noted at deploy time)

## Key framing

- Spec-as-designed, **not** code bug → proposal-required per 2026-05-08 binding.
- A3 observability fix (`atr_at_entry` capture) **must land first** — without it, Option A/B cannot be benchmarked on live data.
- All three options gated via new env-flag `SESSION_BREAKOUT_SL_MODE` with default `range_edge` (= current). Zero-deploy-risk merge.
- Evidence requirement made strict: 6mo H1 backtest (must include 2025-11 → 2026-05), avg R > 0.05, WR > 45%, positive on last 60d sub-window, plus 30d live-replay before Railway-flip.

## Bias I did NOT bake in

Operator instruction was "present, don't pre-pick". Proposal does not recommend a winning option to Karri. Round-2 forensics author had biased toward Option B; I did not carry that bias into the proposal body. Personal lean is documented only in the parent return summary, not in the proposal Karri sees.

## Open items for Karri

- Which option (A/B/C) — or hybrid (A as quick-win, B as Phase 2)?
- Backtest acceptance criteria — are R>0.05/WR>45% strict enough?
- Should Option C be the interim default while A/B is backtested?

## Files touched

- Created: `docs/strategy/proposals/2026-05-13_session_breakout_sl_method.md`
- Created: this audit
- No commits, no Railway changes.

Word count: ~270.
