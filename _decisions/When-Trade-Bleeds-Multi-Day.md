---
type: decision-tree
trigger: closed PnL negative ≥3 consecutive days OR cumulative loss > 5% of equity in a week
autonomy_level: report
---
# When Trade Bleeds Multi-Day

## Trigger
Operator asks "why are we bleeding?" or morning briefing shows ≥3 red days in a row, OR cumulative drawdown crosses a soft threshold (-$1k on demo, -3% on live).

This is a money-impact pattern. Default posture: **investigate + report, do not auto-modify gates or sizing.**

## Diagnose order
1. **Confirm the bleed**: `SELECT day, sum(realized_pnl), count(*) FROM simulated_orders WHERE closed_at IS NOT NULL GROUP BY day ORDER BY day DESC LIMIT 14;` via [[MCP-nexus-pg]].
2. **Close-reason breakdown per day**: are we hitting `OANDA_SL_TP` (broker stop) or `STALE_TRADE_EXIT` (time-out) or `MANAGED_EXIT`? Different root causes.
3. **Win-rate vs avg-loss split**: did win-rate drop, OR did avg loss grow? The "Bigger Losses, Same Frequency" pattern (2026-05-04 → 2026-05-10) was a stop-sizing story, not a setup-selection story.
4. **Per-strategy attribution**: if `strategy_id` is NULL on all trades → metadata-stamping is broken first, fix that before anything else (see [[When-Doc-Drifts-From-Code]] sibling pattern: metadata fixes go via [[Runbook-Post-Deploy-Verification]]).
5. **Regime audit**: was the regime tag at entry consistent with strategy fit? Check `regime_at_entry` distribution.
6. **News blackout audit**: did any of the losing trades open inside a Shield blackout window that should have vetoed? If yes → Shield bug, not strategy bug.
7. **Compare with prior 7d**: same-strategy, same-regime, prior week. The delta tells you whether it's a regime change or a code regression.

## Action by classification
- **Pure observability gap** (e.g. `strategy_id` NULL on every row) → fix locally + commit + push (no money-impact behaviour change). NO operator wait beyond [[OK-Kjor-Gate]]. See [[Runbook-Post-Deploy-Verification]].
- **Code regression** (recent commit broke a stop / managed-exit path) → fix locally, file bug-fix-not-strategy-change note, commit + push.
- **Strategy-touch** (proposed change to stop-size, R-multiple, exit logic) → [[When-Strategy-Change-Tempting]] applies. File proposal in `docs/strategy/proposals/`, auto-send Karri during work hours.
- **Schema / risk-sizing** change → flag operator decision; do not implement until explicit "OK kjør" on the specific change.
- **Irreversible** (e.g. wipe trade history, force-close positions) → "OK kjør"-gate REQUIRED + explicit acknowledgement.

## What never auto-fires
- Auto-disabling a strategy from a losing streak ([[Operator-Principles]] rule 1).
- Reducing risk-per-trade without operator-OK.
- Closing open positions outside the position-management loop.

## Examples from past sessions
- **2026-05-04 → 2026-05-10 bleed**: -$2,089 cumulative across 5 days. Diagnosis showed (a) all 28 trades had `strategy_id`/`execution_source` NULL — metadata stamping broken, and (b) avg-loss grew from -$210 to -$348 while win-rate held at 45%. Stop-sizing story, not setup story. Filed both fixes; metadata stamp pushed same day, sizing proposal sent to Karri.
- **2026-05-11 scalp-overlap regime-mismatch**: three back-to-back SHORT entries by `xau-scalp-overlap` in a strictly trending-UP market, -$1,058 in 28 minutes. Conviction did NOT protect (highest-conviction trade = worst PnL). Root cause: strategy fired its mean-reversion playbook in `portfolio_regime_at_entry=TRENDING` where it is structurally counter-edge. Postmortem auto-classifier mislabelled them `RIGHT_THESIS_BAD_EXECUTION` — actually wrong-thesis. Routed to Karri as regime-gate proposal. Full analysis: [[scalp-overlap-losses-2026-05-11]]. **Lesson**: when the same direction stops out ≥3× in a short window, assume regime-mismatch first, not setup-quality variance — pull `portfolio_regime_at_entry` distribution before anything else.
- See `00-claude-inbox/nexus/2026-05-11-pnl-bleed-analysis.md` for the full Q1-Q4 template.

## Linked
[[Operator-Principles]] · [[Foundation-Gate]] · [[Truth-Hierarchy]] · [[When-Strategy-Change-Tempting]] · [[When-Doc-Drifts-From-Code]] · [[Runbook-Post-Deploy-Verification]] · [[Module-Postmortem]] · [[Karri]] · [[scalp-overlap-losses-2026-05-11]]
