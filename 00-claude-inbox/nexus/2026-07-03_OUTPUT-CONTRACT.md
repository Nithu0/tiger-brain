# Output contract — learning-loop evidence base (operator-locked 2026-07-03)

_Binding structure for the deliverable. Assembled from workflow `wcaii29az` (code-side) + codex-3/4 live-DB pull (trade-side). thesis-2 assembles; nothing flipped/edited until this evidence base exists._

## Acceptance criterion (the bar)
If we CANNOT explain ONE trade from raw data → parameter source → scoring → gate → sizing → outcome → learning-feedback, the system is NOT ready for auto-learning. Do not optimize the model yet. First prove whether the learning loop affects decisions, and whether it does so safely.

## Section 1 — P-ranked defect register
Per defect: `subsystem` · `failure_mode` (concrete) · `trade_id/example` · `evidence` (DB row + file:line) · `learning_impact` (blocks: learning | sizing | gate | observability-only) · `money_risk` (can it raise exposure/loss? vector) · `minimal_fix` · `test_that_proves_fix` · `owner` (ai-1 | code-2 | codex).

## Section 2 — Per-trade forensic summary, last 7d, LOSERS FIRST
Per loser: why the trade was taken · which engine/multiplier dominated · was multiplier ≠ 1.0 active? · did the multiplier move sizing OR the decision? · minimal counterfactual that flips to no-trade · was lesson/meta-label/postmortem AVAILABLE before the trade? · was it ACTUALLY used in the decision?  (source: codex live-DB via the per-trade forensic prompt.)

## Section 3 — Learning-loop truth table (hard confirmation)
| Question | Answer | Evidence |
|---|---|---|
| CALIBRATION_MODE live value | (codex/ai-1) | calibration_log applied-rows |
| SAFE_AUTO_APPLY live state | (codex/ai-1) | firm_state engine_multipliers:current ≠ 1.0? |
| Does lesson-injection enter scoring/gating? | (code) | agent-lessons/* + scoring/gate readers |
| Do engine multipliers affect LIVE sizing? | (code) | conviction/scoring.ts:53 |
| Does meta-label affect live trade/no-trade or only logging? | (code) | meta-label/* readers |
| Can rollbacks actually reverse impact? | (code+DB) | env revert + firm_state reset path |

## Section 4 — Monitor spec = per-trade FLIGHT RECORDER
Minimum fields (every one, per trade): `trade_id` · `timestamp` · `symbol` · `side` · `size` · `final_decision` · `final_score` · `gate_result` · `dominant_engine` · `engine_scores_snapshot` · `engine_multipliers_snapshot` · `calibration_mode` · `safe_auto_apply_state` · `lesson_injected` (bool) · `lesson_source` · `parameter_lineage` (with file:line) · `counterfactual_no_trade_threshold` · `expected_outcome` · `actual_outcome` · `postmortem_link` · `meta_label_score` · `fields_missing`. For each: source table/file:line + alreadyCaptured (bool) + minimal new capture if not.

## Data-ownership split
- **Code-side (thesis-2 via workflow):** Section 1, Section 3 (code rows), Section 4 (schema + captured-vs-missing).
- **Trade-side (codex-3/4, has DB):** Section 2, Section 3 live values (CALIBRATION_MODE, SAFE_AUTO_APPLY, multiplier≠1.0 incidence).
- thesis-2 merges both into the final doc. Gaps stay explicitly marked "NOT CAPTURED / pending codex" — never guessed.
