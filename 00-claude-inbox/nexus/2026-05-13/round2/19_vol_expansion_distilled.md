# 19 — Vol-Expansion distilled (first canonical library entry)

**Date:** 2026-05-13
**Source:** Round 2 curriculum-build pickup
**Output:** `_library/trading/strategies/volatility_expansion.md` (~500 words)

## What I extracted

The lesson covers six layers, sourced from concrete files in this repo (no fabrication):

1. **Archetype definition** — from the file-header docstring in `apps/worker/src/firm/vol-expansion/vol-exp-manager.ts:1-15` (cycle steps 1-7).
2. **XAUUSD-specific rationale** — synthesized from the strategy's design choice (H1 candles, ATR-ratio over short windows) plus operator memory about gold's regime structure. Not directly stated in any one doc.
3. **Exact entry trigger** — values pulled from `vol-expansion/config.ts:41-58` (`VOL_EXP_RATIO=1.3`, `recentWindow=5`, `historicalWindow=15`, `slAtrMult=0.7`, `tpAtrMult=2.0`, `cooldownMinutes=240`). The sweet-spot block in `config.ts:5-11` documents these came from the 90d backtest, 2026-04-26.
4. **Karri's validated claim** — sweet-spot config from `docs/ops/archive/tier3-deploy-26april.md:140-156`. Backtest numbers (WR 38.5%, +$528/90d, walk-forward +$1013 / +$489 / -$236) and the 26 April approval are documented there. No formal "approved" review comment exists in the original — the approval was operator-driven via the TIER 3 deploy decision.
5. **Failure modes** — extracted from the four 12 May post-mortem proposals: `vol_exp_no_chase_filter.md`, `vol_exp_mean_revert_block.md`, `vol_exp_session_sl_widening.md`, `vol_exp_confluence_filter.md`. All four are documented in `vol-exp-manager.ts:273-349` as implemented PR #17 fixes (default OFF).
6. **Cross-references** — Crabel, Carver, Connors, Kaufman. Connection to Nexus criteria (trend_agreement = Kaufman's confirmation filter) is my synthesis, not stated explicitly anywhere in repo.

## What was hard to find / missing

- **No formal "original proposal" doc** for `xau-volatility-expansion`. The strategy was born in commit `7801a6e` (26 April, TIER 3 batch deploy) without a `docs/strategy/proposals/YYYY-MM-DD_*.md` file — proposals as a process only began ~2026-05-08. The TIER 3 deploy report at `docs/ops/archive/tier3-deploy-26april.md` is the de-facto birth doc.
- **No explicit Karri review comments** for vol-exp itself — only for follow-up PR #17 improvements (12 May). The "Karri-approved" status is inferred from the TIER 3 operator-driven all-in deploy + the absence of any pushback in proposals/handoffs.
- **Live PF / round-1-audit numbers** for the "only PF >= 1" claim — not in repo. I trusted the task brief. The repo has the post-throttle audit numbers (37 trades, 49% WR, +$59 avg) in `2026-05-11_vol_expansion_throttle_review.md` which support but don't directly state "PF >= 1".
- **Backtest implementation detail** — the comment in `vol-exp-manager.ts:144-146` admits the ATR computation is simple per-candle range, not Wilder's, "to mirror the backtest". This is a leakage risk if someone later flips to Wilder's in code without re-running backtest. Worth flagging to Karri.
- **Connection to Crabel/Carver/Kaufman literature** — zero references in the codebase. My cross-refs are inferred-correct from standard volatility-breakout literature but should be operator/Karri-validated before being treated as canonical.

## Followup suggestions

- File a proposal-retro for vol-exp (`Status: implemented (approved-verbally) 2026-04-26`) so the audit trail matches today's standard.
- Confirm with Karri: is the "Karri-approved" tag accurate for the original config, or only for the PR #17 fixes? If the former, this lesson holds. If the latter, soften the title.
- Consider distilling each PR #17 fix as its own lesson once they have live data — they're explicit hypotheses with measurable expected impact.

## Workflow check (curriculum-building meta)

This took ~6 tool calls and ~10 min wall-time once context was loaded. Bottleneck was finding the birth doc (no `proposals/YYYY-MM-DD_vol_expansion.md` exists, so I had to fall back to git log + the TIER 3 deploy archive). For future strategy distillations, suggest a convention: even for pre-proposal-era strategies, backfill a stub proposal doc citing the deploy commit + sweet-spot table.
