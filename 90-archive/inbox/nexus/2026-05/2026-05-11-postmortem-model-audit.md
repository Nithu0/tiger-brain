---
date: 2026-05-11
project: nexus
type: audit-and-fix
status: applied (awaiting OK kjør for push)
---

# Postmortem classifier audit — 2026-05-11

## Trigger

Scalp-overlap loss analysis 2026-05-11: 3 SHORT trades on `xau-scalp-overlap`
in a TRENDING-UP regime all got auto-tagged `RIGHT_THESIS_BAD_EXECUTION`.
Evidence says these were wrong-thesis (counter-trend), not execution failures.

Trade IDs in scope:
- `205dd6ad-eafe-4698-8d2d-bbe171293d8d` (-$401, SHORT, TRENDING)
- `02d3d403-c1e4-46c4-bd7d-eb7b37f470f1` (-$364, SHORT, TRENDING)
- `f64feec4-9cab-45b1-86a6-9ab7d5a04f32` (-$293, SHORT, TRENDING)

Plus 4 more in the prior 24h all bucketed the same way regardless of regime / direction. 10 of 12 recent closed losses had the identical `RIGHT_THESIS_BAD_EXECUTION` tag — strong sampling-bias signal.

## Classifier type

**Rule-based** in `apps/worker/src/firm/postmortem.ts` (`runEnhancedPostmortem`, lines 69-150). LLM is present but only writes a free-text `aiReview` blob (line 333-344). The LLM blob does NOT influence the `FailureClass` enum that downstream agents/dashboards consume.

→ This is a wiring problem, not a strategy-domain prompt problem. Fix is in ops territory; no Karri review needed.

## Inputs visible to the classifier (BEFORE fix)

From the trade row args:
- `direction`, `entryPrice`, `closePrice`, `pnl`, `closeReason`, `originalRiskPoints`

From the blackboard (read by classifier itself):
- `xauusd.manager.decisions` — pulled the FIRST APPROVED in last hour (not matched by cycle id; arbitrary when many strategies trade in parallel)
- `xauusd.manager.synthesis` (only for management classifier, not failure class)
- `xauusd.analysis.technical` (only used for department scoring — NEVER for failure class)
- `xauusd.analysis.news` (only department scoring)

## Inputs MISSING from the classifier

1. `decision_cycle_id` — trade row had it (`simulated_orders.decision_cycle_id`), hook never forwarded it, classifier picked an arbitrary `APPROVED` decision → `marketThesisScore`, `executionWindowScore`, `wasChasing`, `wasChaotic` all defaulted to 0/false in 100% of sampled postmortems
2. `portfolio_regime_at_entry` — captured on trade row, never read by classifier
3. `xauusd.analysis.technical.direction` — read for scoring, not for classification
4. `xauusd.analysis.macro.direction` — never read at all by postmortem
5. `OANDA_SL_TP` as an SL-like close — line 126 only checked `"SL_HIT"`; OANDA-synced closes (the production-default path since 17.4) never reached the WRONG_THESIS branch
6. `firm_memory.regime` — written as `undefined` (line 388 pre-fix), so all postmortem rows had `regime=null` regardless of actual entry regime

## Decision flow that produced the bug

For the three SHORT trades:
- `isWin=false` → enters loss branch
- `directionCorrect` via `priceLaterMovedRight` heuristic returned mixed
- `closeReason='OANDA_SL_TP'` ≠ `'SL_HIT'` → WRONG_THESIS branch SKIPPED
- `wasChasing=false`, `wasChaotic=false` (defaulted, no decision matched) → both branches skipped
- `executionWindowScore=0 < 50` → fired RIGHT_THESIS_BAD_EXECUTION

For ALL recent losses with `marketThesisScore=0` defaulting, the same fall-through happens — explains the 100% RIGHT_THESIS_BAD_EXECUTION rate.

## Decision: applied (pure wiring)

Six edits, no behavior change to strategies or trading logic, no prompt changes:

1. `postmortem.ts` — accept `decisionCycleId` on `trade` param; prefer match-by-cycle when looking up the decision row
2. `postmortem.ts` — fetch `portfolio_regime_at_entry` from the trade row at classification time
3. `postmortem.ts` — read `xauusd.analysis.technical` and `xauusd.analysis.macro` for direction inputs
4. `postmortem.ts` — add `counterTrend` check (regime∈{TRENDING,BREAKOUT} AND tech.direction != trade.direction) → fires WRONG_THESIS regardless of close_reason. Catches the scalp-overlap-loss case directly
5. `postmortem.ts` — recognize `OANDA_SL_TP` as an SL-like close alongside `SL_HIT` for the direction-wrong branch
6. `postmortem.ts` — pass `marketRegimeAtEntry` to `writeFirmMemory.regime` instead of `undefined`; add 6 audit fields to `evidence` so misclassifications are debuggable from SQL
7. `postmortem-hook.ts` — forward `r.decision_cycle_id` into the `trade` object

## Verification

- `tsc --noEmit` clean (apps/worker)
- `postmortem-hook.test.ts` — 8/8 pass
- `postmortem-r-multiple.test.ts` — 9/9 pass
- `retention.test.ts` + `status-report.test.ts` + `agent-trigger.test.ts` — 47/47 pass

## Restoration scope

This is restoration-of-intended-behavior: the data was always there (regime captured on trade row 2026-04-xx; tech-analyst publishes since cognitive-OS shipped), but the classifier's read-paths were never wired. No strategy logic changed. No money-impact thresholds touched.

## Backfill question

The 10+ wrong-tagged historical rows can be re-classified by replaying postmortem against the trade rows (regime is on the row, analyst snapshots from that minute are still in `agent_messages`). NOT done in this fix — backlog item if operator wants the firm_memory to retroactively reflect.

## Commit pending

```
fix(postmortem): wire regime + analyst-direction into classifier inputs

Per scalp-overlap loss analysis 2026-05-11: classifier auto-tagged
3 SHORT trades in trending-UP market as RIGHT_THESIS_BAD_EXECUTION.
Evidence says wrong-thesis (counter-trend, regime mismatch).
Classifier was missing analyst-snapshot inputs.

Restoration-of-intended-behavior. No strategy logic change.
```

No push yet. Awaiting "OK kjør".
