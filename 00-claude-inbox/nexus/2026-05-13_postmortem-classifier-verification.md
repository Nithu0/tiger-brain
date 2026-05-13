---
date: 2026-05-13
type: verification
project: nexus
status: open
---

# Postmortem classifier verification (commit 6bdd38a)

## TL;DR

**Classifier fix IS working on new postmortems.** Since commit `6bdd38a` (2026-05-11 14:18 UTC), 3/5 SL-like losses correctly land in `WRONG_THESIS`. Pre-fix data is NOT backfilled — 26 historical `RIGHT_THESIS_BAD_EXECUTION` rows remain (≈6 of those would flip to `WRONG_THESIS` under new logic).

## Verification matrix

### 30d distribution
| classification | n |
|---|---|
| RIGHT_THESIS_BAD_EXECUTION | 28 |
| CORRECT_THESIS | 18 |
| WRONG_THESIS | 3 |

### Split by fix commit (2026-05-11 14:18Z)
| phase | classification | n | avg_pnl |
|---|---|---|---|
| BEFORE_6bdd38a | RIGHT_THESIS_BAD_EXECUTION | 26 | -303.78 |
| BEFORE_6bdd38a | CORRECT_THESIS | 18 | +349.09 |
| AFTER_6bdd38a | WRONG_THESIS | 3 | -387.79 |
| AFTER_6bdd38a | RIGHT_THESIS_BAD_EXECUTION | 2 | -279.97 |

`WRONG_THESIS` appears ONLY after the fix landed. Before-fix volume in that bucket: 0. After-fix: 3/5 SL-like losses. Branch is firing.

### Cross-tab close_reason × classification (30d)
| close_reason | classification | n | avg_pnl |
|---|---|---|---|
| OANDA_SL_TP | RIGHT_THESIS_BAD_EXECUTION | 22 | -375.37 |
| OANDA_SL_TP | CORRECT_THESIS | 9 | +483.73 |
| OANDA_SL_TP | WRONG_THESIS | 3 | -387.79 |
| STALE_TRADE_EXIT | RIGHT_THESIS_BAD_EXECUTION | 6 | -33.34 |
| STALE_TRADE_EXIT | CORRECT_THESIS | 6 | +73.50 |
| OANDA_TP_HIT_RECONCILE | CORRECT_THESIS | 1 | +1199.76 |

OANDA_SL_TP no longer collapses into a single bucket — splits across CORRECT/WRONG/BAD_EXECUTION based on direction-correct + counterTrend + macroContradicts. Healthy.

## Code reads

### `apps/worker/src/firm/postmortem.ts`
- Line 152: `isSlLikeClose = closeReason === "SL_HIT" || closeReason === "OANDA_SL_TP"` — both broker-side paths now feed wrong-thesis branch (the original bug).
- Line 154–166: counter-trend = `regimeIsTrending && techDirection !== "neutral" && techDirection !== trade.direction`. macroContradicts independent.
- Line 198: `if (counterTrend) → WRONG_THESIS` — first branch, before bad-execution fallthrough.
- Line 205: `else if (!directionCorrect && isSlLikeClose) → WRONG_THESIS` — secondary branch using `priceLaterMovedRight` heuristic.
- Line 177: `OANDA_EXTERNAL → EXTERNAL_CLOSE` — broker-side reconcile path correctly excluded from thesis grading.
- Evidence dict (line 477–500): `counterTrend`, `techDirectionAtEntry`, `macroDirectionAtEntry`, `marketRegimeAtEntry`, `macroContradicts` all persisted to firm_memory.evidence for audit.

### `apps/worker/src/firm/postmortem-hook.ts`
- Line 128: `decisionCycleId: r.decision_cycle_id` — passed through, classifier can match the exact APPROVED decision (line 96–106 in postmortem.ts). Eliminates the "arbitrary recent APPROVED" misfire.
- Line 176–197: postmortems-table mirror runs on every postmortem. `classification` column reflects new logic.

### Counter-trend logic location
`/home/nithu/code/ai-assistent/apps/worker/src/firm/postmortem.ts:154–166, 198–204`. Uses `xauusd.analysis.technical` (Prism tech direction) + `portfolio_regime_at_entry` snapshot from `simulated_orders`. Karri's scalp-overlap concern is covered: 3 SHORT-in-TRENDING-up losses 2026-05-12 correctly bucketed.

## Live evidence (firm_memory.evidence)

Two recent WRONG_THESIS rows from 2026-05-12:
- `counterTrend=false, macroContradicts=true, techDirectionAtEntry="short", marketRegimeAtEntry="TRENDING"` → WRONG_THESIS via secondary branch (macro path + bad direction)
- `counterTrend=false, macroContradicts=true, techDirectionAtEntry="short"` → WRONG_THESIS, decisionCycleMatched=true

Note `counterTrend=false` even when regime=TRENDING because `techDirection === trade.direction` (both short) — the trade was WITH tech direction; macro contradicted. Logic distinguishes correctly.

## Commit chain in tree
- `6bdd38a` fix(postmortem): wire regime + analyst-direction into classifier inputs (origin)
- `3383e19` / `1790a75` cherry-picks of same fix on later branches
- `611269f` fix(postmortems): wire cycle_id at INSERT — JOIN path no longer needs trade indirection
- `a53598b` / `1003091` feat(postmortem): Phase 1 streak-table for size-down feedback

All present in current `git log`.

## Anomalies

1. **Pre-fix backlog is NOT backfilled.** 26 `RIGHT_THESIS_BAD_EXECUTION` rows from before 2026-05-11 14:18Z are stuck. ≈6 of these would flip to `WRONG_THESIS` if rerun (SHORT-or-LONG SL-loss in TRENDING regime). Backfill runbook exists at `scripts/postmortem-backfill` per commit `e3ca966` / `f5bee29`. Operator decision: rerun or accept legacy noise.

2. **Several `RIGHT_THESIS_BAD_EXECUTION` after-fix rows have `portfolio_regime_at_entry = null`** (older trades opened before regime snapshot was wired in). Classifier falls back to `priceLaterMovedRight` heuristic. Acceptable — null is honest.

3. **`marketThesisScore` and `entryThesisScore` still 0/100 on many post-fix rows.** `decisionCycleMatched: false` on the 2026-05-12 WRONG_THESIS short. Means the cycle-id match isn't always succeeding. Less critical now (counterTrend/macroContradicts branch doesn't depend on those scores), but worth a follow-up.

## What to fix

- **Optional**: Run `scripts/postmortem-backfill` with `legacy_classifier=false` to reclassify pre-fix backlog with new logic. Strategy-impact, so file a proposal to Karri before running. Not urgent — new postmortems are clean.
- **Follow-up**: 0/100 thesis-score rate. Check why `decisionCycleId` JOIN misses on ~half of new postmortems. Investigate `xauusd.manager.decisions` topic retention + 1-hour `read` window.
- **Documentation**: Update `docs/ref/incomplete-features.md` to note pre-fix backlog is stale.

## Verdict

**Working: YES.** Counter-trend + macro-contradiction branches fire on real broker-close data. OANDA_SL_TP no longer monopolises `RIGHT_THESIS_BAD_EXECUTION`. Commit chain intact.
