---
type: decision-tree
trigger: an analysis or audit yields a "we should change X" suggestion where X has money-impact
autonomy_level: send-to-karri
---
# When Strategy Change Tempting

## Trigger
Claude (or operator) reasons toward a change that has **money-impact** — modifies trading behaviour, position sizing, gate thresholds, R-multiples, strategy entry/exit logic, regime classification, or risk caps. This includes well-meaning "obvious wins" from a bleed analysis.

Examples:
- "Stop is too tight, let's widen from 1.0R to 1.2R"
- "Strategy-X loses in regime Y, let's disable it there"
- "Foundation rule 2 threshold is too strict, loosen to $100"
- "Let's add a new strategy module" (any new strategy)
- "Position-management partials should be at 1.5R instead of 1.0R"

## What is NOT a strategy change (so does NOT need a proposal)
- Bug fixes that restore intended behaviour (e.g. metadata stamping that was silently NULL).
- Observability additions (new metrics, new logs, new dashboard pages).
- Refactors with no behaviour change.
- Backfills (recompute historical data with already-shipped logic).
- Doc / `.env.example` / CLAUDE.md updates.

## Karri-spor (binding, [[Decision-Strategy-Review-Pipeline]])
1. **Claude writes proposal** in `/home/nithu/code/ai-assistent/docs/strategy/proposals/YYYY-MM-DD_<slug>.md` using template at `docs/strategy/proposals/README.md`.
2. **Fields required**: title, reviewer (always `Karri`), status (`proposed`), context, current behaviour, proposed change, money-impact estimate, rollback plan, test coverage.
3. **Auto-send to Karri via Discord webhook** during work hours 09-17 CET (per `feedback_auto_send_karri.md`). Outside hours: hold until next morning, do not page. Use [[Runbook-Karri-Proposal-Send]].
4. **Status track**: `proposed → approved → implemented (with commit SHA) → archived`. Never skip approved.
5. **Counter-signal**: if operator says "bare fix det" / "kjør på" inline, implement directly BUT still file the proposal retroactively as `Status: implemented (approved-verbally)` for audit trail.

## Diagnose order (before writing the proposal)
1. **Is the analysis correct?** Reproduce the SQL / numbers. Half of "obvious wins" disappear on re-check.
2. **Is the change reversible in 30 seconds?** It must be — that's the rollback-safety rule. Behind env-var, not hardcoded.
3. **Is there a smaller fix?** Often the bleed is a code bug ([[When-Trade-Bleeds-Multi-Day]]) not a strategy change. Try that first.
4. **Money-impact estimate**: rough +/- $ per week if the change had been live for the audit period. If you can't estimate, the proposal isn't ready.

## What never auto-fires
- Implementing a strategy change without Karri-approved status, even if Claude thinks it's obvious. Per [[Operator-Principles]] + `feedback_strategy_changes_review.md`.
- Auto-disabling a strategy from a losing streak ([[Operator-Principles]] rule 1).
- Sending the Discord page outside 09-17 CET window.

## Examples from past sessions
- **Stop-sizing proposal (2026-05-11)**: bleed analysis suggested R-multiple change. Filed `docs/strategy/proposals/2026-05-11_<slug>.md`, auto-sent Karri during work hours. Held implementation until approved.
- **TIER 3 four-strategy parallel deploy**: each strategy went through proposal → approved → implemented → archived flow per `tier3-deploy-26april.md`.

## Linked
[[Operator-Principles]] · [[Decision-Strategy-Review-Pipeline]] · [[Karri]] · [[Foundation-Gate]] · [[Runbook-Karri-Proposal-Send]] · [[When-Trade-Bleeds-Multi-Day]] · [[When-Foundation-Rule-Goes-Yellow]] · [[Strategy-Proposal-Workflow]]
