# Nexus learning-loop — evidence base (operator output-contract, 4 sections)

_thesis-2 (researcher, operator-directed), 2026-07-03. Read-only forensic; NO flag flipped, NO nexus code edited. Code-side from workflow `wcaii29az` (193 agents, 10 subsystems, 3-lens adversarial verify). Trade-side (Section 2 + §3 live values) pending codex-3/4 live-DB pull. Companion: `2026-07-01_bleed-diagnosis-and-fix-plan.md`, `2026-07-03_OUTPUT-CONTRACT.md`._

## ACCEPTANCE VERDICT — NOT ready for auto-learning (proven, code-side)
The bar: explain ONE trade raw-data → param-source → scoring → gate → sizing → outcome → learning-feedback. **We cannot, today.** On the executing TIER-3 path `entry_snapshot` is never written, `engine_scores` are absent (`TIER3_ENGINE_ATTRIBUTION_ENABLED` default-OFF), and sizing-lineage + dissent are never persisted. The learning loop reaches a live decision through at most ONE wire — engine multipliers under `SAFE_AUTO_APPLY` — and that wire is fed by an empty/`no_trade`-poisoned outcome set with an inverted correct-label, and is frozen at 1.0 in the default `RECOMMEND_ONLY` mode. Every other path (lessons, session thresholds, meta-label) is write-only / dead-wired. The exit side (`CONVICTION_FLIP_EXIT`/`DEGRADE_CUT`) is entirely dead under `ORB_ONLY_MODE`. **Do not actuate auto-learning until the flight-recorder (§4) makes one trade fully explainable and the P0/P1 wires are proven safe.**

Counts: 43 confirmed defects — P0:6, P1:17, P2:17, P3:3. Gates: bug-fix 17, operator-flip 13, karri 13.

---
## Section 1 — P-ranked defect register
_learning_impact: blocks-learning | blocks-gate | observability-only. trade_example: codex fills real ids in §2; defects marked STRUCTURAL are dead-wire/default-off and need no single trade._

### P0

**[P0] `session-calibration-write-only-dead-wire`**  ·  _calibration-autotune_  ·  impact: **blocks-learning**  ·  gate: karri-proposal  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: All session-level 'learning' (postmortem win/loss, failure-class, win-rate branches) is computed and logged but never changes any live trade threshold, even in SAFE_AUTO_APPLY.
- evidence: getActiveProfile (apps/worker/src/firm/calibration.ts:362-366) unconditionally returns getBaselineProfile with a 'would query the calibration_profiles table' TODO and has ZERO non-test/non-node_modules callers (grep confirmed). The trade gate reads getSessionThresholds(window.state) (apps/worker/src/firm/orchestrator.ts:311), which is built from static session-window baselines + an env cold-start delta only (apps/worker/src/firm/session-window.ts:299-314) — no path from calibration_log/calibration_profiles. Recommendations are only INSERTed to calibration_log (apps/worker/src/firm/calibration.ts:311-322).
- money-risk: Naive fix (auto-applying logged session recs to live thresholds) can loosen/tighten the entry gate without human review, changing exposure and risking a self-reinforcing tighten-loop.
- minimal fix: Wire getActiveProfile (apps/worker/src/firm/calibration.ts:362) and the orchestrator threshold read (orchestrator.ts:311) to load the latest applied calibration_profiles row for the session; until wired, force the SAFE_AUTO_APPLY session path to a no-op.
- test that proves fix: calibration.test.ts: insert a calibration_profiles row overriding marketThesisThreshold for session window 'LONDON', then assert getActiveProfile('LONDON') returns the override, not getBaselineProfile('LONDON'). Currently returns baseline unconditionally.
- trade example: STRUCTURAL

**[P0] `stale-abs-atr-thresholds-default-off`**  ·  _data-inputs-parameters_  ·  impact: **blocks-gate**  ·  gate: operator-flip  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Volatility bucketing uses absolute-$ ATR thresholds (extreme>12, high>7, low<3) calibrated when gold was ~$2000; gold now trades ~$4200, so the same % volatility yields ~2x absolute ATR and normal conditions are tagged NOISY_CHAOTIC/high. The price-relative fix (ATR_PCT_THRESHOLDS_ENABLED) exists but defaults OFF.
- evidence: apps/worker/src/firm/vol-thresholds.ts:50-52 (flag default false), :88-90 (absolute defaults 12/7/3), header :12-18 measured 32% extreme + 54% high, 0 trades/3d; portfolio-brain.ts:157 classifyVolatility feeds regime, :170-174 extreme->NOISY_CHAOTIC poor tradeability
- money-risk: Enabling %-thresholds lets many more candidates through the regime gate (fewer NOISY_CHAOTIC labels), materially increasing trade frequency/exposure.
- minimal fix: Set ATR_PCT_THRESHOLDS_ENABLED=true (apps/worker/src/firm/vol-thresholds.ts:50 default false); path already unit-tested.
- test that proves fix: vol-thresholds.test.ts: classifyVolatility with price=4200 and atr=8 returns 'high'/'normal' (atr/price ~0.19%) when flag on, but 'extreme' (8<12? no, >7 => high; use atr=13) — assert the same %-vol at price 4200 is NOT bucketed 'extreme' with flag on whereas the absolute path buckets it extreme. Concretely: atr=13,price=4200 -> flag-on bucket != 'extreme'; flag-off (abs) -> 'extreme'.
- trade example: STRUCTURAL

**[P0] `adx-null-oanda-fallback-default-off`**  ·  _data-inputs-parameters_  ·  impact: **blocks-gate**  ·  gate: operator-flip  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Twelve Data /adx (and /atr) 404 for XAU/USD and return null silently. The OANDA local-compute fallback (INDICATOR_OANDA_FALLBACK_ENABLED) defaults OFF, so ADX is permanently null in production. Every ADX-gated regime branch (TRENDING, LOW_VOLATILITY, RANGING) requires adx!=null and is therefore never taken.
- evidence: apps/worker/src/services/market-data.service.ts:38-43 (fallback default false), :468 fetchADX returns null; portfolio-brain.ts:146 reads indicators.adx, :175 TRENDING needs adx!=null && adx>30, :180 LOW_VOL needs adx!=null, :185 RANGING needs adx!=null — all dead when adx null, regime collapses to MIXED_NO_EDGE or NOISY_CHAOTIC
- money-risk: Enabling the fallback makes ADX non-null, unlocking TRENDING/RANGING branches and the trend-following strategies they gate, opening a whole trade class that was previously suppressed (new exposure).
- minimal fix: Set INDICATOR_OANDA_FALLBACK_ENABLED=true (apps/worker/src/services/market-data.service.ts:38 default false); Wilder math already in indicators.ts.
- test that proves fix: market-data.test.ts: mock Twelve Data /adx -> null and OANDA candles present with fallback flag on; assert fetchADX() returns a finite number (not null). Then portfolio-brain-regime.test.ts: with adx=32 the regime resolves TRENDING (portfolio-brain.ts:175), unreachable when adx null.
- trade example: STRUCTURAL

**[P0] `tier3-attribution-flag-default-off`**  ·  _engine-attribution_  ·  impact: **blocks-learning**  ·  gate: operator-flip  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: The actually-executed trades (TIER-3 bridge path, the executing path since the 2026-04-24 pivot) write NO engine_scores rows unless a flag is on, so the calibration outcome set has essentially zero real win/loss rows for executed trades.
- evidence: strategy-execution.ts:1182 gates the entire decision-time recordCycleSnapshot for the TIER-3 open path behind envBool("TIER3_ENGINE_ATTRIBUTION_ENABLED", false) (default OFF, read per-call). The comment at strategy-execution.ts:1160-1180 states plainly that with it OFF the executed trades 'ran on a DISJOINT cycle population and carried zero engine attribution — the engine-weight calibration was optimizing an always-empty outcome set.' The only other writer, managers.ts:693, records the Prism/Blade conviction snapshot for cycles that then get markCycleAsNoTrade'd (managers.ts:704).
- money-risk: None — recording engine_scores for executed trades is observability; it does not change gating or sizing.
- minimal fix: Operator sets TIER3_ENGINE_ATTRIBUTION_ENABLED=true so recordCycleSnapshot on the TIER-3 open path fires (apps/worker/src/firm/strategy-execution.ts:1182).
- test that proves fix: After flip, SQL: SELECT count(*) FROM engine_scores WHERE trade_id IS NOT NULL AND created_at > now()-interval '1 day' > 0 (currently 0). Equivalent unit assert via auditCycleEngineAttribution(cycleId).linked > 0 for a cycle that opened a TIER-3 trade.
- trade example: STRUCTURAL

**[P0] `engine-weights-apply-only-under-safe-auto-apply`**  ·  _engine-attribution_  ·  impact: **blocks-learning**  ·  gate: operator-flip  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Engine performance multipliers are computed but never actually applied unless the global calibration mode is SAFE_AUTO_APPLY; the default is RECOMMEND_ONLY, so the multipliers stay at 1.0 and engines are never reweighted.
- evidence: calibration.ts:334-335 sets engineMode = mode === "SAFE_AUTO_APPLY" ? "APPLY" : "RECOMMEND_ONLY". calibrationMode() defaults to RECOMMEND_ONLY (calibration.ts:49) and runCalibration's mode param defaults to RECOMMEND_ONLY (calibration.ts:139). In calibrate-weights.ts:115-118 'applied' requires mode==="APPLY", and the actual setEnginePerformanceMultipliers call is guarded by mode==="APPLY" (calibrate-weights.ts:140).
- money-risk: Flipping to SAFE_AUTO_APPLY lets computed multipliers reach conviction scoring, changing which engines dominate and therefore trade selection/sizing — a real exposure change (guardrails minSamples=30, +/-20% exist).
- minimal fix: Set CALIBRATION_MODE=SAFE_AUTO_APPLY (apps/worker/src/firm/calibration.ts:49 default RECOMMEND_ONLY) so engineMode maps to APPLY (calibration.ts:334-335).
- test that proves fix: engine-attribution/calibrate-weights.test.ts: run calibrateEngineWeights({mode:'APPLY',minSamples:30}) over a seeded winning-engine scorecard and assert setEnginePerformanceMultipliers is called and getEnginePerformanceMultiplier(engine) != 1.0; with mode RECOMMEND_ONLY it stays 1.0.
- trade example: pending codex §2

**[P0] `lesson-loop-dead-wire`**  ·  _nexus-lesson-loop_  ·  impact: **blocks-learning**  ·  gate: karri-proposal  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: The entire derive→promote→inject pipeline terminates in two ADVISORY-ONLY agents. No lesson ever changes a gate, sizing, veto, or entry decision, so the firm can process unlimited trades and its actual trading behavior never changes.
- evidence: apps/worker/src/firm/agent-lessons/client.ts:7 states 'The trading loop (runCycle) does NOT import this module yet.' Only consumers of buildLessonContext are risk-advisor.ts:114 and trade-critic.ts:74 (grep confirms no others). risk-advisor publishes to blackboard xauusd.risk.advisory (risk-advisor.ts:141-166) and is 'ADVISORY ONLY... does not block, does not close, does not mutate' (risk-advisor.ts:8-9,230); trade-critic only INSERTs into firm_memory (trade-critic.ts:99-111). grep for xauusd.risk.advisory in gate/sizing/execution code returns nothing.
- money-risk: Naive wire-in of lessons into the gate/sizing path acts on WR-only, statistically-noisy lessons (see defects 19/36), which can systematically down-weight profitable cohorts — a self-reinforcing bad-policy loop.
- minimal fix: Behind a Karri-gated default-off flag, wire approved anti_pattern/pattern lessons (or their structured hypotheses) from agent-lessons/client.ts into the gate/sizing decision so a high-consistency segment lesson can reject or size a candidate.
- test that proves fix: New integration test in the gate path: with the flag on and an approved anti_pattern lesson stored for segment (regime=RANGING,session=ASIA), a matching candidate is rejected (or sized down) by the gate; with the flag off it is unaffected.
- trade example: STRUCTURAL


### P1

**[P1] `engine-weights-learn-on-empty-outcome-set`**  ·  _calibration-autotune_  ·  impact: **blocks-learning**  ·  gate: karri-proposal  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Engine performance multipliers (the ONLY path where calibration changes real trade behavior) are optimized against trades that carry no engine attribution, so the money-outcome learning signal is structurally absent.
- evidence: Scorecard money metrics win_rate_when_strong / pnl_contribution / drawdown_contribution require a trade outcome joined onto engine_scores rows (apps/worker/src/firm/engine-attribution/aggregates.ts:75-79), but engine_scores are written only by recordCycleSnapshot on the Prism/Blade path while trades are opened by TIER-3 on DISJOINT cycles — documented as 'ENGINE-BLIND OPEN ... engine_scores=0 ... NO engine attribution' (apps/worker/src/firm/orchestrator.ts:896-917). Unlinked snapshot rows become outcome='no_trade' (apps/worker/src/firm/orchestrator.ts:938), for which pnl is NULL→0 and win/loss CASEs are NULL/excluded.
- money-risk: None directly — this is an attribution-linkage gap; it becomes money-risky only once multipliers are APPLIED on the corrupted set (covered by defect 5/9).
- minimal fix: Unify the cycle population: attribute TIER-3 opens to their engine snapshot so engine_scores rows carry trade_id+win/loss outcome (apps/worker/src/firm/engine-attribution/aggregates.ts:75-79 join has data); tracked in docs/strategy/proposals/2026-06-23_engine-blind-tier3-opens.md.
- test that proves fix: After a TIER-3 trade closes, SQL: SELECT count(*) FROM engine_scores WHERE outcome IN ('win','loss') AND trade_id IS NOT NULL AND closed_at > now()-interval '1 day' > 0 (currently 0 — only no_trade rows). Unit: auditCycleEngineAttribution(cycle).linked > 0.
- trade example: pending codex §2

**[P1] `tier3-attribution-flag-default-off`**  ·  _conviction-scoring_  ·  impact: **blocks-learning**  ·  gate: operator-flip  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: The trades the firm actually executes (TIER-3 / ORB strategy bridge) carry ZERO engine attribution, so engine_scores never receive a trade_id or win/loss outcome for real trades.
- evidence: apps/worker/src/firm/strategy-execution.ts:1180 — the only place the executed TIER-3 open path writes engine_scores (recordCycleSnapshot at 1191) is wrapped in `if (envBool("TIER3_ENGINE_ATTRIBUTION_ENABLED", false))`, default OFF. The Prism/Blade writer (managers.ts:693) runs on a DISJOINT cycle population; orchestrator.ts:908-917 logs ENGINE-BLIND OPEN and confirms 'executed trades carry ZERO engine attribution' verified against prod-DB.
- money-risk: None — enabling attribution only writes engine_scores rows; no gate/sizing effect.
- minimal fix: Set TIER3_ENGINE_ATTRIBUTION_ENABLED=true so the TIER-3 open path writes recordCycleSnapshot (apps/worker/src/firm/strategy-execution.ts:1180).
- test that proves fix: After flip, auditCycleEngineAttribution(cycleId).linked > 0 for a TIER-3-opening cycle; SQL: SELECT count(*) FROM engine_scores WHERE trade_id IS NOT NULL AND created_at > now()-interval '1 day' > 0.
- trade example: STRUCTURAL

**[P1] `calibration-mode-default-recommend-only`**  ·  _conviction-scoring_  ·  impact: **blocks-learning**  ·  gate: operator-flip  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Learned engine performance multipliers are computed and logged every calibration run but NEVER applied to scoring — perfMult stays frozen at neutral 1.0 forever.
- evidence: calibration.ts:44-49 defaults CALIBRATION_MODE to RECOMMEND_ONLY; calibration.ts:334-335 maps that to engineMode=RECOMMEND_ONLY; calibrate-weights.ts:115-118 sets `applied = mode==="APPLY" && ...` (always false otherwise) and 140-144 only calls setEnginePerformanceMultipliers when mode==="APPLY". So getEnginePerformanceMultiplier() (config.ts:119-120) always returns PERF_MULT_BOUNDS.neutral=1.0.
- money-risk: Flipping applies perfMult into scoring.ts:53, changing engine weights and therefore conviction/selection — real exposure change.
- minimal fix: Set CALIBRATION_MODE=SAFE_AUTO_APPLY (apps/worker/src/firm/calibration.ts:44-49 default RECOMMEND_ONLY).
- test that proves fix: conviction config: after an APPLY calibration run over a seeded scorecard, getEnginePerformanceMultiplier(engine) (apps/worker/src/firm/conviction/config.ts:119-120) returns != PERF_MULT_BOUNDS.neutral(1.0); RECOMMEND_ONLY leaves it at 1.0.
- trade example: pending codex §2

**[P1] `backfill-correct-label-inverted`**  ·  _conviction-scoring_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: The per-engine `correct` label written on trade close is wrong for a whole quadrant of outcomes and marks most wrong engines NULL instead of FALSE, corrupting the directional-accuracy learning signal.
- evidence: apps/worker/src/firm/engine-attribution/recorder.ts:228-234. For a losing SHORT trade ($4/$5/$6 all false), a bullish engine (signal>0, which was RIGHT because price rose) hits `WHEN NOT $4 AND NOT $5 AND NOT $6 AND signal>0 THEN FALSE` — labeled wrong; a bearish engine (signal<0, actually wrong) falls to ELSE NULL. In the longWin/longLoss/shortWin quadrants the opposite-signal (wrong) engines also fall to ELSE NULL instead of FALSE. The stated intent (comment 213-217: correct = win&sign-matches OR loss&sign-opposes) is not implemented.
- money-risk: Inverted ground-truth on losing shorts teaches the opposite lesson; once multipliers APPLY it up-weights wrong-side engines — a self-reinforcing bad-policy loop.
- minimal fix: Rewrite the CASE at apps/worker/src/firm/engine-attribution/recorder.ts:228-234: add a shortLoss ($7) boolean, emit TRUE for shortLoss+signal>0, and FALSE (not NULL) for any non-zero signal not satisfying the correctness rule.
- test that proves fix: Per-quadrant test on backfillOutcomeForTrade: losing SHORT (pnl<0) row with a bullish engine (signal>0) asserts correct=TRUE (currently FALSE); a winning LONG row with a bearish engine (signal<0) asserts correct=FALSE (currently NULL). Cover all 8 (direction x win/loss x sign) combinations.
- trade example: pending codex §2

**[P1] `cold-start-gates-default-off`**  ·  _data-inputs-parameters_  ·  impact: **blocks-gate**  ·  gate: operator-flip  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: Cold-start loosening switches all default to legacy/off: FIRM_COLD_START_MODE=false, FIRM_NORMALIZATION_MODE=legacy, FIRM_COLD_START_MATURITY_DELTA=0. With them off, thesis must clear the internal maturity gate (60) before Blade is ever invoked; on cold data it exits Prism with synthesisId=null.
- evidence: apps/worker/src/firm/cold-start-config.ts:68-73 (mode default false), :120-123 (maturity delta forced 0 when mode off); session-window.ts:301 (thresholds unchanged when mode off); decision-cycle.ts:245 & :299 (maturity + quality gates only relax via the delta)
- money-risk: Lowering the maturity gate lets thesis mature and open trades on thin/immature data, increasing exposure to lower-confidence entries during the collection window.
- minimal fix: Set FIRM_COLD_START_MODE=true and FIRM_COLD_START_MATURITY_DELTA=-15 (bounded [-20,0]) during collection (apps/worker/src/firm/cold-start-config.ts:68-73,120-123); revert after 50+ engine_scores.
- test that proves fix: cold-start-config.test.ts: with FIRM_COLD_START_MODE=true, maturityDelta()== -15 (0 when off); decision-cycle then passes the maturity gate at raw maturity 45 (60-15) where it previously exited with synthesisId=null (decision-cycle.ts:245).
- trade example: STRUCTURAL

**[P1] `no-trade-rows-poison-directional-accuracy`**  ·  _engine-attribution_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: no_trade rows are counted in directional_accuracy even though the aggregates WHERE-clause comment claims they are skipped, so the primary accuracy objective is dominated by circular abstention self-grades rather than real predictive accuracy.
- evidence: directional_accuracy = AVG(CASE WHEN correct IS TRUE THEN 1 WHEN correct IS FALSE THEN 0 ELSE NULL END) at aggregates.ts:74 only skips rows where correct IS NULL. But markCycleAsNoTrade sets correct to a non-NULL TRUE/FALSE via CASE WHEN ABS(signal)*confidence < 0.3 (recorder.ts:364-367), so no_trade rows are NOT skipped. The aggregates.ts:55-56 comment explicitly relies on 'the correct-IS-NULL skip in directional_accuracy to ignore orphan/no_trade rows' — an invariant the code does not hold.
- money-risk: Tautological no_trade self-grades dominate directional_accuracy; once multipliers APPLY the firm reweights engines on a metric decoupled from P&L — bad-policy risk (inert until apply on).
- minimal fix: Add AND outcome<>'no_trade' to the directional_accuracy CASE at apps/worker/src/firm/engine-attribution/aggregates.ts:74 (or set no_trade correct to NULL in recorder.ts:364), keeping helpful_no_trade_count as the sole no_trade channel.
- test that proves fix: aggregates.test.ts: seed 2 real win/loss rows (correct TRUE/FALSE) plus 10 no_trade rows with correct=TRUE; assert directional_accuracy for the engine equals the value over ONLY the 2 real rows (currently pulled toward ~1.0 by the no_trade rows).
- trade example: pending codex §2

**[P1] `trainer-features-constant-zero`**  ·  _meta-label_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: The trained meta-label model learns from only 2 of its 8 features; the other 6 (regime, session, ADX, RSI, macro, conviction_direction) are silently constant 0 for every training row, so the model has almost no information about WHY a trade won or lost.
- evidence: apps/worker/src/firm/meta-label/train-model.ts:90-99 projects features via so.entry_snapshot->>'convictionDirection'/'regimeCode'/'sessionCode'/'adx'/'rsi'/'macroDelta', each wrapped in COALESCE(...,0). But the writer apps/worker/src/firm/managers.ts:949-1018 never stores those top-level keys: it writes nested conviction.direction (not 'convictionDirection'), string conviction.regime + portfolioRegime (no numeric 'regimeCode'), string session (no 'sessionCode'), and no adx/rsi/macroDelta anywhere. All six JSON lookups return NULL → 0. Only conviction_total (column entry_conviction_score) and atr_norm_stop (columns atr_at_entry/original_risk_points) carry signal. Note conviction_direction IS available as column so.conviction_direction (managers.ts:1034) but the trainer reads it from JSON instead.
- money-risk: None currently — the model output is discarded (defect 14/33), so a crippled fit changes no trade; risk only materialises if the model is later wired to sizing.
- minimal fix: Read convictionDirection from column so.conviction_direction and write adx/rsi/regimeCode/sessionCode/macroDelta into entry_snapshot at trade-open (apps/worker/src/firm/managers.ts:949-1018), then point train-model.ts:90-99 SQL at those real sources.
- test that proves fix: train-model.test.ts: over a seeded set of closed trades in distinct regimes/sessions, assert the projected feature matrix has variance — e.g. COUNT(DISTINCT regime_code) > 1 and COUNT(DISTINCT adx) > 1 (currently all 0 via COALESCE(...,0)).
- trade example: STRUCTURAL

**[P1] `model-output-dead-end`**  ·  _meta-label_  ·  impact: **blocks-learning**  ·  gate: karri-proposal  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Even a well-trained model changes nothing: its P(win) is computed and immediately thrown away, and no code path reads the model or its scores to gate, size, or alter any trade.
- evidence: apps/worker/src/firm/orchestrator.ts:782 `await scoreShadowCandidate(this.db, candidateFeatures, synthesisId).catch(() => {})` — result awaited and discarded. Grep across apps/worker/src shows the only consumers of meta_label_scores / meta_label_models are the writer (scorer.ts) and the trainer (train-model.ts); nothing in the decision/sizing path reads them.
- money-risk: A naive wire-in that vetoes/scales on an uncalibrated P(win) changes trade selection/sizing and could suppress winners — needs shadow A/B first.
- minimal fix: Behind its own Karri-gated flag, add a consumer that reads the latest model P(win) at apps/worker/src/firm/orchestrator.ts:782 (currently awaited-and-discarded) to veto/scale low-probability candidates, with shadow-vs-live logging.
- test that proves fix: New decision-path test: with the consumer flag on and a candidate whose scoreShadowCandidate P(win) < threshold, assert the candidate is vetoed or its size scaled down; with the flag off the candidate proceeds unchanged.
- trade example: STRUCTURAL

**[P1] `calibration-mode-recommend-only-never-applies`**  ·  _nexus-decision-formation_  ·  impact: **blocks-learning**  ·  gate: operator-flip  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: Calibration runs every 20 cycles but in the default mode every recommendation is logged with applied=false; engine multipliers and session thresholds never change the live decision.
- evidence: apps/worker/src/firm/calibration.ts:44-50 defaults CALIBRATION_MODE to RECOMMEND_ONLY when unset/invalid; the comment (calibration.ts:33-35) states multipliers 'stay neutral (1.0).' calibrate-weights.ts:115-118 makes applied require mode==='APPLY' (SAFE_AUTO_APPLY). runCalibration is invoked at orchestrator.ts:879-882 with calibrationMode().
- money-risk: Flip feeds learned adjustments into live scoring/thresholds — the master switch for all runtime self-adjustment, so exposure can change (Karri bounds exist).
- minimal fix: Set CALIBRATION_MODE=SAFE_AUTO_APPLY (apps/worker/src/firm/calibration.ts:44-50); note inert until the session-wire defect (id 1) is also fixed.
- test that proves fix: calibrate-weights.test.ts: mode APPLY over a seeded scorecard produces applied=true rows and a non-neutral multiplier; SQL after flip: SELECT count(*) FROM calibration_log WHERE applied=true AND created_at > now()-interval '1 day' > 0.
- trade example: STRUCTURAL

**[P1] `new-gates-softlog-dead-behind-master`**  ·  _nexus-gate-stack_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: The 5 richest entry gates (risk_level, scalp_overlap_asia, ranging_conviction, entry_stack_cooldown, session_block) never write their soft-log evidence in the default configuration, so the 'pre-activation evidence' table stays empty for them.
- evidence: strategy-blade.ts:289-295 early-returns (finalize) when STRATEGY_BLADE_ENABLED=false — the map's own default. The only call to evaluateNewGates + persistGateDecisions is strategy-blade.ts:374/390, inside Gate 3 (strategy-blade.ts:342), which is unreachable after that early return. managers.ts:575-587 confirms the old always-run call was removed, making strategy-blade the single call site. new-gates.ts:1-14 docstring promises 'soft-log (default ON) writes to gate_decisions ... a full week of soft-log before activation', and new-gates.ts:244 gates persistence only on NEW_GATES_SOFT_LOG_ENABLED — but that flag is dead code while the whole block sits behind the master switch. The master's sub-flags default true when master on (strategy-blade.ts:298,325,342,404), so an operator cannot turn soft-log on without simultaneously hard-enabling forge/risk_veto/event_policy.
- money-risk: A careless hoist could also hard-enable forge/risk_veto/event_policy sub-gates (they default true when master on) and block real trades; the correct soft-log-only hoist is inert.
- minimal fix: Hoist the evaluateNewGates + persistGateDecisions block above the STRATEGY_BLADE_ENABLED early return (apps/worker/src/firm/strategy-blade.ts:289-295), gating persistence solely on NEW_GATES_SOFT_LOG_ENABLED (apps/worker/src/firm/gates/new-gates.ts:244).
- test that proves fix: strategy-blade.test.ts (or gates/new-gates.test.ts): with STRATEGY_BLADE_ENABLED=false and NEW_GATES_SOFT_LOG_ENABLED=true, running a cycle writes gate_decisions rows for risk_level/scalp_overlap_asia/ranging_conviction/entry_stack_cooldown/session_block. SQL: SELECT count(*) FROM gate_decisions WHERE gate_name='risk_level' > 0.
- trade example: pending codex §2

**[P1] `foundation-rule4-execute-candidate-deadlock`**  ·  _nexus-gate-stack_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: In the default all-flags-off posture the firm is permanently locked out of ever recommending a gate activation: gate_decisions is empty -> foundation goes RED -> the activation recommender is hard-blocked.
- evidence: foundation-monitor.ts:151-155 returns Rule-4 state RED with 'gate_decisions empty' when no rows exist. worst() at foundation-monitor.ts:232-238 collapses any RED rule to whole-foundation RED. status-report.ts:675 sets foundationBlocks when state is RED/YELLOW, and status-report.ts:681 requires !foundationBlocks && totalEvals>=100 before EXECUTE_CANDIDATE can fire. Because every gate only persists when its own flag (or master) is ON (strategy-blade.ts:113,156,257; strategy-execution.ts:793; and Defect 1), the default config writes nothing, so foundation is stuck RED forever.
- money-risk: Returning YELLOW instead of RED unblocks the activation recommender; if paired with thin evidence it could recommend hard-activating a gate that blocks live trades.
- minimal fix: In apps/worker/src/firm/foundation-monitor.ts:151-155 return state UNKNOWN/YELLOW (not RED) when gate_decisions is empty by design, so worst() (foundation-monitor.ts:232-238) does not force whole-foundation RED; and/or seed via the soft-log hoist (defect 16).
- test that proves fix: foundation-monitor.test.ts: evaluate Rule-4 against a DB with zero gate_decisions rows and assert state !== 'RED' (currently 'RED'); assert worst([...rules]) is not forced RED solely by the empty table.
- trade example: pending codex §2

**[P1] `all-master-gates-default-off`**  ·  _nexus-lesson-loop_  ·  impact: **blocks-learning**  ·  gate: operator-flip  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Every stage of the loop is behind a default-OFF env flag, and derivation/injection need TWO flags each. In the default configuration nothing is derived, promoted, or injected — the loop is fully inert.
- evidence: AGENT_LESSONS_ENABLED default false (client.ts:26-28); injection needs master AND LESSON_INJECTION_ENABLED (both default false) (injection.ts:35-40); derivation needs AGENT_LESSONS_ENABLED AND LESSON_DERIVATION_ENABLED (derive-lessons.mjs:76-82); LESSON_AUTO_PROMOTE_ENABLED default off no-ops (auto-promote-lessons.mjs:42-44,186-195).
- money-risk: Enabling derivation only is trade-inert (writes proposed lessons); risk arises only if injection/auto-promote are also flipped (separate money-gated step).
- minimal fix: Operator enables AGENT_LESSONS_ENABLED (client.ts:26-28) + LESSON_DERIVATION_ENABLED (derive-lessons.mjs:76-82) to accumulate proposed lessons; leave injection/auto-promote off.
- test that proves fix: deriver-injection.integration.test.ts style: after enabling both flags and running the deriver over seeded closed trades, SQL: SELECT count(*) FROM agent_lessons WHERE status='proposed' AND created_at > now()-interval '1 day' > 0.
- trade example: STRUCTURAL

**[P1] `signal-is-winrate-not-expectancy`**  ·  _nexus-lesson-loop_  ·  impact: **blocks-learning**  ·  gate: karri-proposal  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Lesson type, confidence, outcome_score, and the auto-promote consistency gate are ALL derived purely from win-rate, ignoring PnL magnitude. A high-WR-but-net-losing segment is labeled 'pattern → favor_or_size_up' and a low-WR-but-net-winning segment is labeled 'anti_pattern → reject_or_size_down'.
- evidence: wr=wins/n and confidence=consistency*sample-factor (derive-lessons.mjs:134,142-143); thresholds are WR-only (derive-lessons.mjs:151,169); outcomeScore=-1+2*wr (derive-lessons.mjs:160,178); auto-promote consistency is recovered from outcome_score, i.e. WR only (auto-promote-lessons.mjs:75-108). net_pnl/avg_pnl are computed (derive-lessons.mjs:116-117) but used only in rationale text, never in any gate.
- money-risk: If wired, WR-only labels mark high-WR net-losing cohorts as 'favor/size up' and low-WR net-winning cohorts as 'reject/size down' — directly negative learning.
- minimal fix: In buildLessonForCluster (scripts/firehose/derive-lessons.mjs:133-160,151,169) require net_pnl sign to agree with the WR-based pattern/anti_pattern label, and add the same expectancy check to the auto-promote gate.
- test that proves fix: Unit test importing buildLessonForCluster: a cluster with wr=0.75 but net_pnl<0 must NOT return type 'pattern'/action 'favor_or_size_up' (currently does); a wr=0.4, net_pnl>0 cluster must not be labeled anti_pattern/reject.
- trade example: pending codex §2

**[P1] `sample-size-counts-runs-not-trades`**  ·  _nexus-lesson-loop_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Stored sample_size is set to literal 1 on insert and incremented by 1 on every re-derivation run via ON CONFLICT, so it measures 'number of daily cron runs that saw this cluster', not number of trades. The auto-promote observation gate keys on this corrupted column.
- evidence: proposeLesson inserts sample_size=1 then 'ON CONFLICT DO UPDATE SET sample_size = agent_lessons.sample_size + 1' (derive-lessons.mjs:408,410-412); confidence is recomputed from cluster.n each run (derive-lessons.mjs:143,414) so confidence and sample_size diverge. auto-promote gates minObservations on row.sample_size (auto-promote-lessons.mjs:91) and pre-filters/orders by it (auto-promote-lessons.mjs:136).
- money-risk: Promotion gate is satisfied by daily-run repetition, not trade evidence; once lessons are wired it promotes stale small clusters as if evidence-backed.
- minimal fix: In proposeLesson's INSERT/ON CONFLICT (scripts/firehose/derive-lessons.mjs:408-412) set sample_size = EXCLUDED trade count (cluster.n) instead of agent_lessons.sample_size + 1.
- test that proves fix: Integration: run the deriver twice over the same 5-trade cluster (same fingerprint); assert SELECT sample_size FROM agent_lessons WHERE fingerprint=$1 == 5 (currently 2 after two runs, and grows +1 per run).
- trade example: pending codex §2

**[P1] `stale-decision-context-1h-window`**  ·  _postmortem-change-verification_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Every postmortem for a trade held (or backlogged) longer than ~1 hour classifies against the WRONG decision's thesis scores, or defaults them to 0, so the primary learning artifact (firm_memory lessons + postmortems table) is mislabeled.
- evidence: apps/worker/src/firm/postmortem.ts:150 reads xauusd.manager.decisions with maxAgeSeconds=3600, and :192-195 read technical/macro at 3600s. blackboard.ts:113,120 implement that as `timestamp > NOW() - INTERVAL '3600 seconds'` (1h). postmortem-hook.ts:97 selects trades closed within 7 days and :100 batches 5/cycle, so by run-time the entry-DECISION is usually >1h old. postmortem.ts:151-160: matchByCycle then null and the fallback `recentDecisions.find(APPROVED)` grabs an arbitrary DIFFERENT trade's decision; :162-164 then set marketThesisScore/entryThesisScore/executionWindowScore from that wrong row (or 0), feeding :240-241,274-277 classification and win-quality lessons.
- money-risk: None directly — corrupts the firm_memory/postmortems learning artifact; lessons are advisory so no immediate exposure change.
- minimal fix: In apps/worker/src/firm/postmortem.ts:150-160 match the DECISION by decision_cycle_id from the durable simulated_orders row (already passed in) instead of the 1h blackboard window; widen/remove maxAgeSeconds=3600 for the cycle-match read.
- test that proves fix: postmortem.test.ts: a trade whose entry DECISION is 3h old still resolves ITS OWN marketThesisScore/entryThesisScore (non-zero, from its decision_cycle_id) rather than an arbitrary APPROVED row's scores or 0.
- trade example: pending codex §2

**[P1] `tier3-engine-attribution-flag-off`**  ·  _telemetry-provenance_  ·  impact: **blocks-learning**  ·  gate: operator-flip  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: The live execution path (TIER-3 strategy bridge, active since the 2026-04-24 pivot) writes engine_scores only when TIER3_ENGINE_ATTRIBUTION_ENABLED is on; it defaults OFF, so the actually-executed trades record ZERO engine attribution rows.
- evidence: apps/worker/src/firm/strategy-execution.ts:1180 gates recordCycleSnapshot behind envBool("TIER3_ENGINE_ATTRIBUTION_ENABLED", false). orchestrator.ts:908-917 already logs 'ENGINE-BLIND OPEN' as the verified live reality; recorder.ts:260-262 notes prod-DB 2026-06-23 had the 3 most-recent TIER-3 opens each with 0 engine_scores. The Prism/Blade snapshot (managers.ts:693) runs on a cycle population that mostly does NOT open trades.
- money-risk: None — writes engine_scores rows only; no gate/sizing effect.
- minimal fix: Operator sets TIER3_ENGINE_ATTRIBUTION_ENABLED=true (apps/worker/src/firm/strategy-execution.ts:1180 envBool default false).
- test that proves fix: After flip, orchestrator 'ENGINE-BLIND OPEN' warnings drop and SQL: SELECT count(*) FROM engine_scores WHERE trade_id IS NOT NULL AND created_at > now()-interval '1 day' > 0; auditCycleEngineAttribution.linked > 0 per opening cycle.
- trade example: pending codex §2

**[P1] `correct-label-case-broken`**  ·  _telemetry-provenance_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: backfillOutcomeForTrade's SQL CASE that sets engine_scores.correct is wrong for 5 of 8 outcome/sign combinations: short-losing trades are INVERTED (bullish engines marked FALSE though price rose = they were right), and wrong-side engines on winning trades get NULL instead of FALSE.
- evidence: apps/worker/src/firm/engine-attribution/recorder.ts:219-243. Only longWin($4), longLoss($5), shortWin($6) are passed; shortLoss is never given. Line 232 'WHEN NOT $4 AND NOT $5 AND NOT $6 AND signal>0 THEN FALSE' fires exactly on short-losses and marks bullish engines FALSE (should be TRUE). longWin+signal<0, longLoss+signal>0, shortWin+signal>0, shortLoss+signal<0 all fall to ELSE NULL (should be FALSE).
- money-risk: Systematically mislabeled ground-truth; once multipliers APPLY, engine-weight calibration learns the opposite lesson on losing shorts and never penalizes wrong-side engines on winners.
- minimal fix: In apps/worker/src/firm/engine-attribution/recorder.ts:219-243 pass all four outcome booleans (add shortLoss $7) and rewrite the CASE so correct = (win AND sign-matches) OR (loss AND sign-opposes), with complementary branches returning FALSE not NULL.
- test that proves fix: recorder unit test over all 8 (direction x win/loss x signal-sign) combos: losing-short bullish engine -> TRUE, wrong-side engines on winners -> FALSE (not NULL). Assert no non-zero-signal engine is left NULL after backfillOutcomeForTrade.
- trade example: pending codex §2


### P2

**[P2] `recommendations-anchored-to-static-baseline-non-cumulative`**  ·  _calibration-autotune_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: Every recommendation deltas from the hardcoded BASELINE_PROFILES value, not the live/last-applied value, so learning can never accumulate beyond a single bounded step and the log shows identical old→new rows each run.
- evidence: currentValue and the clampDelta anchor both use baseline.* (e.g. apps/worker/src/firm/calibration.ts:215-216, 227-228, 248-249, 263-264); getBaselineProfile returns static literals (apps/worker/src/firm/calibration.ts:98-133,188). clampDelta caps a single step (apps/worker/src/firm/calibration.ts:88-94).
- money-risk: None currently — the session apply path is a no-op (defect 1); non-cumulative deltas only under-correct once wired.
- minimal fix: Anchor currentValue and clampDelta on the most-recent APPLIED calibration value from calibration_log/calibration_profiles instead of getBaselineProfile literals (apps/worker/src/firm/calibration.ts:215-216,227-228,248-249,263-264).
- test that proves fix: calibration.test.ts: with a prior applied marketThesisThreshold = baseline+3 in calibration_log, a second run on the same WRONG_THESIS failure proposes new_value = baseline+6 (compounds within bounds), not baseline+3 again.
- trade example: pending codex §2

**[P2] `applied-flag-lies-for-session-params`**  ·  _calibration-autotune_  ·  impact: **observability-only**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: Under SAFE_AUTO_APPLY the session-parameter recommendations are logged with applied=true even though no code applies them, so the operator/dashboard sees 'autotune applied' for changes that had no effect.
- evidence: apps/worker/src/firm/calibration.ts:319 writes applied = (mode === 'SAFE_AUTO_APPLY') for every session recommendation, while (per defect 1) getActiveProfile/getSessionThresholds never consume them.
- money-risk: None — inert/observability; the false applied=true only masks defect 1, no decision effect.
- minimal fix: At apps/worker/src/firm/calibration.ts:319 set applied=true only when a session parameter is genuinely written to live thresholds; until the apply path exists, log session recs as applied=false.
- test that proves fix: calibration.test.ts: under CALIBRATION_MODE=SAFE_AUTO_APPLY with no session apply path wired, assert the inserted calibration_log session-parameter row has applied=false (currently true).
- trade example: pending codex §2

**[P2] `regime-fit-and-baseweights-never-learned`**  ·  _conviction-scoring_  ·  impact: **blocks-learning**  ·  gate: karri-proposal  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Two of the three factors in every engine's effective weight (base_weight and regime_fit) are hand-set constants the learning loop never touches; only perfMult adapts, and only within ±0.30/+0.20.
- evidence: Effective weight = baseWeight * perfMult * regime_fit (scoring.ts:52-58). regime_fit comes from the hardcoded heuristic table regimeFitFor() at adapters.ts:103-119 ('Static constants, NOT learned'); baseWeight comes from hand-set REGIME_WEIGHTS at config.ts:13-57. calibrateEngineWeights only ever writes perfMultipliers (config.ts:105-117), bounded to 0.70-1.20 (config.ts:96-100).
- money-risk: A Karri-gated learner that moves regime base weights / regime_fit from outcomes changes conviction and therefore selection/sizing per regime — real exposure change.
- minimal fix: Propose (Karri) a calibration path that adjusts regime-specific base weights and/or regime_fit from per-regime scorecards (scorecardsByRegime, apps/worker/src/firm/engine-attribution/aggregates.ts:171-188), not just the scalar perfMult (config.ts:105-117).
- test that proves fix: New test: given a RANGING scorecard where momentum underperforms, the learner writes a regime_fit/base weight for (momentum,RANGING) that differs from the static regimeFitFor() table (adapters.ts:103-119) / REGIME_WEIGHTS (config.ts:13-57).
- trade example: STRUCTURAL

**[P2] `per-cycle-single-trade-attribution`**  ·  _conviction-scoring_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: A cycle that opens more than one trade attributes its single engine_scores snapshot to only the earliest trade; trades 2..N are permanently engine-blind.
- evidence: reconcileCycleTradeAttribution() picks `LIMIT 1 ... ORDER BY opened_at ASC` (recorder.ts:186-199) and auditCycleEngineAttribution sets partialAttribution when tradesThisCycle>1 (recorder.ts:314-323) but only WARNs. backfillOutcomeForTrade updates `WHERE trade_id = $1` (recorder.ts:235), so only the one stamped trade ever gets outcomed.
- money-risk: None — silent sampling loss in the attribution set; no direct trade effect.
- minimal fix: Fan the cycle conviction snapshot out per opened trade (one engine_scores set per trade_id) in reconcileCycleTradeAttribution (apps/worker/src/firm/engine-attribution/recorder.ts:186-199), or enforce single-open-per-cycle as an invariant.
- test that proves fix: recorder test: simulate a cycle that opens 2 trades; after reconcile+backfill, assert BOTH trade_ids have an engine_scores row with a non-null outcome (currently only the earliest-opened trade does).
- trade example: pending codex §2

**[P2] `no-outcome-feedback-into-vol-session-thresholds`**  ·  _data-inputs-parameters_  ·  impact: **blocks-learning**  ·  gate: karri-proposal  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: The vol buckets, session multipliers/thresholds and ATR calibration are all hardcoded constants. The only feedback learner, auto-tune, adjusts engine weights only and requires >=5 closed trades; nothing recalibrates the volatility/session/ATR parameters from realized outcomes.
- evidence: apps/worker/src/services/auto-tune.service.ts:37 (returns [] when <5 closed trades; only touches engine weights); vol-thresholds.ts:88-90 & :121 (static env constants); session-window.ts:247-283 (hardcoded per-window thresholds); session.engine.ts:20-52 (hardcoded UTC-hour multipliers)
- money-risk: An outcome-driven recalibration of regime/session/ATR thresholds directly changes which cycles are tradeable, so a naive loop could widen exposure or self-reinforce a mis-tuned regime.
- minimal fix: Propose (Karri) a shadow/proposal recalibration that fits ATR%/session thresholds from realized volatility and per-window hit-rate in engine_scores (apps/worker/src/firm/vol-thresholds.ts:88-90, session-window.ts:247-283), applied only after review.
- test that proves fix: New test: the recalibration job, fed a realized-vol distribution centred at 0.2% ATR, emits a PROPOSED ATR% threshold set distinct from the static defaults and logs it without mutating live thresholds (assert live constants unchanged).
- trade example: pending codex §2

**[P2] `high-volatility-regime-unreachable`**  ·  _data-inputs-parameters_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: The HIGH_VOLATILITY branch is effectively dead: it requires volatility==='high' && (adx ?? 25) > 25. When ADX is null the fallback 25 is not >25, so it never fires; and it sits after the extreme->NOISY_CHAOTIC branch. HIGH_VOLATILITY is essentially never emitted in production.
- evidence: apps/worker/src/firm/portfolio-brain.ts:190 `else if (volatility === "high" && (adx ?? 25) > 25)` — with adx null (the prod norm) 25>25 is false; :170-174 extreme already consumed above
- money-risk: Making the branch reachable emits HIGH_VOLATILITY, changing tradeability/regime gating for those cycles — a small trade-selection change.
- minimal fix: At apps/worker/src/firm/portfolio-brain.ts:190 change the null-ADX fallback so high vol is not silently excluded, e.g. `(adx ?? 26) > 25` or handle adx==null explicitly. Pure correctness fix.
- test that proves fix: portfolio-brain-regime.test.ts: with volatility='high' and adx=null, classifyRegime returns regime 'HIGH_VOLATILITY' (currently falls through to MIXED_NO_EDGE because 25>25 is false).
- trade example: pending codex §2

**[P2] `outcome-ignores-pnl-magnitude-and-contribution`**  ·  _engine-attribution_  ·  impact: **blocks-learning**  ·  gate: karri-proposal  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: outcome/correct reduce every trade to a binary sign-match, ignoring both P&L magnitude and the engine's contribution weight, so the default accuracy objective optimizes directional hit-rate rather than profitability.
- evidence: recorder.ts:211 sets outcome = pnl >= 0 ? 'win' : 'loss' (a +$1 win equals a +$500 win). recorder.ts:228-234 sets correct purely on signal sign vs trade direction, not weighted by contribution. directional_accuracy (aggregates.ts:74) and win_rate_when_strong (aggregates.ts:75-77) inherit this, and under the default 'accuracy' objective (aggregates.ts:106) performanceScore is dominated by (da-0.5) and (wrs-0.5), i.e. sign hit-rate.
- money-risk: Under the default 'accuracy' objective an engine right on many tiny trades and wrong on a few big losers gets up-weighted despite losing money net — bad-policy risk once multipliers APPLY.
- minimal fix: Karri proposal: switch ENGINE_OBJECTIVE to 'pnl' or use magnitude/contribution-weighted correctness in performanceScore (apps/worker/src/firm/engine-attribution/aggregates.ts:106,126) so the driving metric tracks realized P&L.
- test that proves fix: aggregates.test.ts: seed an engine with 8 tiny +$1 wins and 2 large -$300 losses; assert performanceScore under objective='pnl' is < neutral (currently > neutral under 'accuracy' because directional hit-rate is high).
- trade example: pending codex §2

**[P2] `tiered-conviction-permanently-observe-only`**  ·  _nexus-decision-formation_  ·  impact: **blocks-learning**  ·  gate: karri-proposal  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: The tiered conviction engine (the sole consumer of the learned engine-performance multipliers) is computed every cycle but is explicitly not a gate — it never blocks or sizes a trade.
- evidence: apps/worker/src/firm/managers.ts:196-200: 'Not yet a hard gate — batch 1 is observe-only so we can verify the scoring distribution before letting it block trades.' The conviction gate thresholds (config.ts:83-90) and perf multipliers (config.ts:119-133) only flow into computeTieredConviction, whose output is attached to synthesis state and read by observability, not execution.
- money-risk: Promoting tiered conviction from observe-only to a soft gate/size input means the learned multipliers finally move real trades — a deliberate money-affecting change.
- minimal fix: Karri proposal: promote computeTieredConviction from observe-only (apps/worker/src/firm/managers.ts:196-200) to an active soft gate/size input using the conviction thresholds (conviction/config.ts:83-90), after confirming the scoring distribution.
- test that proves fix: New gate test: with the conviction-gate flag on, a candidate whose tiered conviction is below the config.ts:83-90 threshold is sized down/blocked; with the flag off it only annotates synthesis state (current behaviour).
- trade example: STRUCTURAL

**[P2] `source-quality-frozen-dead-wire`**  ·  _nexus-decision-formation_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Weighted-evidence source-quality scores are documented as learned from historical accuracy but are a hardcoded const with no writer anywhere in the codebase.
- evidence: apps/worker/src/firm/decision-cycle.ts:98-115: DEFAULT_SOURCE_QUALITY is declared const with comments 'can be updated by postmortem learning' and 'Adjusted over time based on actual outcomes'; getSourceQuality only reads it. A repo-wide grep for setSourceQuality/updateSourceQuality returns no writer. calculateEvidenceWeight (decision-cycle.ts:131) multiplies rawConfidence by this frozen sourceQuality.
- money-risk: Low — a writer would shift Prism evidence weights that feed decisions; effect is indirect and bounded by rawConfidence multiplication.
- minimal fix: Implement a persisted source-quality updater fed by postmortem outcomes and have getSourceQuality read the persisted value instead of the frozen DEFAULT_SOURCE_QUALITY const (apps/worker/src/firm/decision-cycle.ts:98-115,131).
- test that proves fix: New test: after postmortem processes N losing outcomes attributed to a chronically-wrong source, getSourceQuality(source) returns a value below its DEFAULT and calculateEvidenceWeight for that source drops accordingly (currently constant).
- trade example: STRUCTURAL

**[P2] `meta-label-model-shadow-only-off`**  ·  _nexus-decision-formation_  ·  impact: **blocks-learning**  ·  gate: operator-flip  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: The trained meta-label P(win) ML model can never influence a trade — it is shadow-only and off by default.
- evidence: apps/worker/src/firm/orchestrator.ts:739-746: 'score P(win) and record it to meta_label_scores. Observability only — never gates/sizes a trade. Behind META_LABEL_SHADOW_ENABLED (default OFF).'
- money-risk: Enabling shadow is inert (parity logging only); promoting the model to a sizing/gate input would change exposure and is a separate Karri step.
- minimal fix: Interim: enable META_LABEL_SHADOW_ENABLED (apps/worker/src/firm/orchestrator.ts:739-746) to accumulate parity data; separately Karri-gate promotion to a sizing/gate input after calibration is validated.
- test that proves fix: After enabling shadow, SQL: SELECT count(*) FROM meta_label_scores WHERE created_at > now()-interval '1 day' > 0 (currently 0). meta-label/scorer.test.ts asserts scoreShadowCandidate persists a row when the flag is on.
- trade example: STRUCTURAL

**[P2] `karri-gates-no-shadow-window`**  ·  _nexus-gate-stack_  ·  impact: **blocks-learning**  ·  gate: karri-proposal  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Four Karri gates offer no observe-before-block window: turning the flag on begins hard-rejecting live trades in the same instant it starts recording evidence.
- evidence: sl_cooldown persists only inside if(isSlCooldownEnabled()) and immediately blocks on !allowed (strategy-blade.ts:113,124-132); regime_direction same pattern (strategy-blade.ts:156,182-189); daily_trade_cap (strategy-blade.ts:257,264-273); mean_revert persists only if(isMeanRevertGateEnabled()) and returns executed:false (strategy-execution.ts:793-802). Persist helpers hard-code hardRejected==wouldReject (strategy-blade.ts:489,578,622) confirming there is no soft mode. Contrast cross-strategy-flip which has off|shadow|hard (strategy-blade.ts:211) and min_rr which is shadow-only (strategy-execution.ts:760-772).
- money-risk: Today activation == instant hard-block of live trades (no observe window); the fix (adding shadow mode) is inert — it persists would_reject without blocking.
- minimal fix: Add off|shadow|hard mode (persist would_reject without returning executed:false) to sl_cooldown, regime_direction, daily_trade_cap and mean_revert, mirroring cross-strategy-flip (apps/worker/src/firm/strategy-blade.ts:211; persist helpers :489,578,622 and strategy-execution.ts:793-802).
- test that proves fix: gates/sl-cooldown-gate.test.ts: in shadow mode, a would-reject cycle persists a gate_decisions row with wouldReject=true AND hardRejected=false and the gate returns allowed:true (currently hardRejected==wouldReject with no soft mode).
- trade example: STRUCTURAL

**[P2] `full-reject-probe-window-not-per-gate`**  ·  _nexus-gate-stack_  ·  impact: **observability-only**  ·  gate: bug-fix-no-gate  ·  owner: **code-2**  ·  2/3 lens
- failure mode: The self-monitoring probe that is supposed to catch a mis-activated gate (rejecting 100% of trades) can silently miss quiet gates and mis-count busy ones.
- evidence: probeGateFullReject (loss-and-activation-monitor.ts:250-256) selects ORDER BY recorded_at DESC LIMIT $1 across ALL gate_names combined, then GROUP BY gate_name and requires evals>=minEvals with rejects==evals (loss-and-activation-monitor.ts:263). A high-frequency gate (soft-log every cycle) fills the shared window, starving low-frequency gates so they never reach minEvals, while each gate's eval count is an arbitrary fraction of the global window rather than its own recent history.
- money-risk: None — health-check/alert only; a missed alert can let a bad activation persist but the probe itself makes no trade decision.
- minimal fix: Partition the probe window per gate_name via ROW_NUMBER() OVER (PARTITION BY gate_name ORDER BY recorded_at DESC) <= windowRows (or one query per gate) in probeGateFullReject (apps/worker/src/firm/notifications/loss-and-activation-monitor.ts:250-263).
- test that proves fix: loss-and-activation-monitor.test.ts: seed a high-frequency gate flooding the window plus a low-frequency gate at 100% reject over its own minEvals; assert the probe still flags the low-frequency gate (currently starved out of the shared window).
- trade example: pending codex §2

**[P2] `promotes-statistical-noise`**  ·  _nexus-lesson-loop_  ·  impact: **blocks-learning**  ·  gate: karri-proposal  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Auto-promotion approves a trade-influencing lesson at n>=8 with consistency>=0.8 and no significance/confidence-interval test. At ~2 trades/day, a 7-win/1-loss (87.5% WR) fluke in one coarse (regime,session,close_reason,hour) bucket clears the gate.
- evidence: MIN_SAMPLE=5 (derive-lessons.mjs:93), confidence reaches full weight at n>=8 (derive-lessons.mjs:143); auto-promote defaults minObservations=8, minConsistency=0.8 (auto-promote-lessons.mjs:57-58) with eligibility a pure threshold check (auto-promote-lessons.mjs:88-110). No binomial/CI test anywhere; the 'confidence' field is a lopsidedness heuristic, not statistical confidence.
- money-risk: Promotes small-n WR flukes as approved segment edges; once lessons are wired the firm acts on noise — worse than not learning.
- minimal fix: In evaluateEligibility (scripts/firehose/auto-promote-lessons.mjs:88-110) add a significance requirement (Wilson lower-bound on WR away from 0.5, or a materially higher real-trade minimum) before a cluster is auto-promotion-eligible.
- test that proves fix: Unit test importing evaluateEligibility: a row with n=8, 7W/1L (consistency 0.875) returns eligible=false because the Wilson lower bound on WR does not clear 0.5; a large consistent cluster returns eligible=true.
- trade example: pending codex §2

**[P2] `metric-ignores-excluded-from-learning`**  ·  _postmortem-change-verification_  ·  impact: **observability-only**  ·  gate: bug-fix-no-gate  ·  owner: **code-2**  ·  2/3 lens
- failure mode: The verification expectancy metric is computed over quarantined rows: it filters only firm-originated UUIDs, not the durable excluded_from_learning quarantine flag, contradicting its own FIRM-ROWS-ONLY invariant and every other learning read.
- evidence: change-verification.ts:105 computeMetric uses bare isFirmOriginatedSql() (firm-attribution.ts:67-68), NOT learningFilterSql() (firm-attribution.ts:108-110) which is the canonical learning predicate `excluded_from_learning IS NOT TRUE AND <firm uuid>`. postmortem.ts:629-634 sets excluded_from_learning=true on corrupt/poisoned rows precisely to keep them OUT of learning, but computeMetric's pnl aggregate (:118-128) still counts them.
- money-risk: None — the verification metric is measurement and its verdict is not consumed (defect 38); contamination affects a displayed number only.
- minimal fix: In computeMetric replace isFirmOriginatedSql() with learningFilterSql() (apps/worker/src/firm/change-verification/change-verification.ts:105) so excluded_from_learning rows are dropped like every other learning read.
- test that proves fix: change-verification.test.ts: seed one closed firm trade with excluded_from_learning=true and one without; assert computeMetric's n and sum_pnl count only the non-quarantined row (currently both).
- trade example: pending codex §2

**[P2] `verdict-never-consumed`**  ·  _postmortem-change-verification_  ·  impact: **observability-only**  ·  gate: karri-proposal  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Verification verdicts (helped/hurt) are display-only: no strategy, sizing, gate, or task path reads them; only two API status routes surface counts.
- evidence: Grep of change_verifications readers shows only learning-loop-status.ts:207-220 and learning-loop-state.ts:233 (both dashboards). change-verification.ts:12-15 states PURE MEASUREMENT (never touches sizing/gates), and wiring.ts:80-92 shows the calibration-apply hook is intentionally never invoked. No code branches on verdict='hurt' to revert or down-weight a change.
- money-risk: A naive auto-revert on 'hurt' could thrash strategy_versions or revert a correct change on noise — needs a guarded consumer design.
- minimal fix: Karri proposal defining a verdict consumer (auto-revert/flag a strategy_version that verifies 'hurt', or feed verdicts into the change-task backlog) instead of leaving change_verifications observability-only (apps/worker/src/firm/change-verification/wiring.ts:80-92 hook is intentionally never invoked).
- test that proves fix: wiring.test.ts: with the consumer flag on, a change_verifications row with verdict='hurt' causes its strategy_version to be flagged/reverted (assert a state change on the strategy_versions row); verdict='helped' leaves it active.
- trade example: STRUCTURAL

**[P2] `engine-multipliers-frozen-unless-safe-auto-apply`**  ·  _telemetry-provenance_  ·  impact: **blocks-learning**  ·  gate: operator-flip  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: Engine performance multipliers are only APPLIED when CALIBRATION_MODE=SAFE_AUTO_APPLY; the default mode is RECOMMEND_ONLY, so calibrateEngineWeights runs in RECOMMEND_ONLY and never writes multipliers back — they stay pinned at neutral 1.0.
- evidence: apps/worker/src/firm/calibration.ts:334-335 maps engineMode = mode==="SAFE_AUTO_APPLY" ? "APPLY" : "RECOMMEND_ONLY"; calibrationMode() at calibration.ts:44-49 defaults to RECOMMEND_ONLY. calibrate-weights.ts:115-118 only sets applied=true when mode==="APPLY".
- money-risk: Flip write-backs multipliers into conviction scoring, changing engine weighting and trade selection — real exposure change (guardrails minSamples=30, +/-20% exist).
- minimal fix: Set CALIBRATION_MODE=SAFE_AUTO_APPLY once attribution data is trustworthy (apps/worker/src/firm/calibration.ts:44-49,334-335).
- test that proves fix: calibrate-weights.test.ts: mode APPLY over a seeded scorecard sets applied=true and writes a non-neutral multiplier; getEnginePerformanceMultiplier(engine) != 1.0 afterward, whereas RECOMMEND_ONLY leaves 1.0.
- trade example: STRUCTURAL

**[P2] `regime-at-entry-aliased-to-risk-level`**  ·  _telemetry-provenance_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: simulated_orders.regime_at_entry is populated with the risk LEVEL, not the market regime — it is aliased to riskLevelAtEntry via COALESCE on every write path.
- evidence: apps/worker/src/firm/managers.ts:927 'const regimeAtEntry = riskLevelAtEntry;' then :1027 'regime_at_entry = COALESCE(regime_at_entry, $6)'. Same aliasing in strategy-execution.ts:1610 and :1636 (regime_at_entry = COALESCE(regime_at_entry, $17/$12) with regimeAtEntry sourced from risk level). The true market regime lives only in portfolio_regime_at_entry.
- money-risk: None — a mislabeled provenance column; no direct trade effect, but any regime-conditioned learning reading it is silently wrong.
- minimal fix: Stop aliasing: write portfolioRegimeAtEntry into regime_at_entry (apps/worker/src/firm/managers.ts:927,1027 and strategy-execution.ts:1610,1636), keeping risk level only in risk_level_at_entry (or deprecate the column and repoint readers at portfolio_regime_at_entry).
- test that proves fix: write-contracts.test.ts (or a managers open test): after opening a trade in a TRENDING market at LOW risk, assert simulated_orders.regime_at_entry == 'TRENDING' (a regime code) and risk_level_at_entry == 'LOW' — currently regime_at_entry holds the risk level.
- trade example: pending codex §2


### P3

**[P3] `strategy-params-static-tuner-off-and-proposal-only`**  ·  _nexus-decision-formation_  ·  impact: **blocks-learning**  ·  gate: operator-flip  ·  owner: **ai-1**  ·  3/3 lens
- failure mode: The live ORB/TIER-3 strategy parameters are static per-process env values, and the only agent that learns per-strategy tweaks is disabled by default and proposal-only.
- evidence: Strategy config is env+hardcoded defaults, 'static per process (no per-trade tuning)' at apps/worker/src/firm/strategy-execution.ts:331-397. The learner strategy-tuner.ts:27-29 is gated FIRM_AGENT_STRATEGY_TUNER_ENABLED default false, and strategy-tuner.ts:5-13 is 'PROPOSAL ONLY' writing to firm_memory/agent_artifacts for manual operator env edits.
- money-risk: Enabling the tuner is inert (proposals to firm_memory only); an applied auto-tune path would change risk%/daily-loss/ORB params and directly move exposure — must stay Karri-gated.
- minimal fix: Enable FIRM_AGENT_STRATEGY_TUNER_ENABLED (apps/worker/src/firm/strategy-tuner.ts:27-29) to generate proposals; separately design a bounded, Karri-gated applied parameter-update path.
- test that proves fix: After enabling, SQL: SELECT count(*) FROM agent_artifacts WHERE type LIKE '%strategy_tuner%' AND created_at > now()-interval '1 day' > 0 (proposals written to firm_memory/agent_artifacts), while live strategy-execution.ts:331-397 env params remain unchanged.
- trade example: pending codex §2

**[P3] `hard-gate-invisible-to-impact-after-activation`**  ·  _nexus-gate-stack_  ·  impact: **observability-only**  ·  gate: karri-proposal  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: Once a gate is hard-activated its ongoing value becomes unmeasurable, because the blocked trade never opens and the counterfactual join has nothing to join to.
- evidence: gate-impact.ts:95-98 INNER JOINs gate_decisions to simulated_orders on decision_cycle_id and only counts cycles where a trade actually opened (gate-impact.ts:8-10 comment). When a hard gate rejects (e.g. mean_revert returns executed:false at strategy-execution.ts:797-801, or the strategy-blade finalize paths), no simulated_orders row is created for that cycle, so those rejections drop out of computeGateImpact entirely.
- money-risk: None directly — a measurement blind spot; indirect risk is an undetected stale gate blocking winners after activation.
- minimal fix: Log an intended-trade stub for hard-rejected cycles (or periodically re-shadow activated gates) so computeGateImpact retains a counterfactual outcome stream (apps/worker/src/firm/gate-impact.ts:95-98 INNER JOIN currently drops rejected cycles).
- test that proves fix: gate-impact test: a cycle where mean_revert hard-rejects (no simulated_orders row created) still contributes a counterfactual entry to computeGateImpact for that gate (currently 0 rows survive the INNER JOIN).
- trade example: STRUCTURAL

**[P3] `breakeven-counted-as-win`**  ·  _postmortem-change-verification_  ·  impact: **blocks-learning**  ·  gate: bug-fix-no-gate  ·  owner: **ai-1**  ·  2/3 lens
- failure mode: A flat trade (pnl==0) is classified CORRECT_THESIS and scores departments/challenge-agents as a win in postmortem, while the verification metric counts wins as pnl>0 — two inconsistent win definitions on the same data.
- evidence: postmortem.ts:139 isWin = trade.pnl >= 0 drives the CORRECT_THESIS branch (:237-241) and department/challenge scoring (:503-527, e.g. :523 challengeWasRight=!isWin). change-verification.ts:121 counts wins as `pnl > 0` and :145 win_rate = wins/n. postmortem-hook.ts:141 isSlClose etc. also key off pnl sign.
- money-risk: None — a scoring-convention inconsistency; biases scorecards/lessons on flat trades but no direct exposure change.
- minimal fix: Adopt one win convention (pnl>0 = win, pnl==0 = distinct breakeven bucket) across postmortem classification (apps/worker/src/firm/postmortem.ts:139), department/challenge scoring (:503-527), and computeMetric (change-verification.ts:121).
- test that proves fix: postmortem.test.ts: a trade with pnl==0 is NOT classified CORRECT_THESIS and does NOT mark objecting challenge-agents wrong (challengeWasRight stays consistent with computeMetric's pnl>0 definition).
- trade example: pending codex §2

---
## Section 2 — Per-trade forensic summary, last 7d LOSERS FIRST — PARTIALLY CLOSED (ai-1 aggregate 2026-07-07); per-trade table still OPEN
Owner was codex-3/4 — never delivered. ai-1's prod-DB sweep (`00-claude-inbox/ai-assistent/2026-07-07_full-analyse-gpu-laering-data.md`) closes the AGGREGATE level:
- **108 clean live trades 23.04→07.07: real net ≈ −$761** (raw `pnl` sum −$3,411.79 overstates loss 4.5× — partials booked separately: `realized_partial_pnl` +$2,650.69). 35.2% winners.
- Weekly since GPU-connect: 22.06 −$12.50 · 29.06 −$1,249.81 · 06.07 +$320. No trading decision has ever run on GPU (PR #211 never merged) — GPU cannot be causal either way.
- **Query traps for anyone re-running this:** `excluded_from_learning` is NULL on live rows → `NOT excluded_from_learning` filters out EVERYTHING; use `IS NOT TRUE`. Never sum `pnl` alone.
- Code-side prediction CONFIRMED at aggregate level: since 27.06 all trades ran with multipliers=1.0 (RECOMMEND_ONLY) — the learning loop influenced none of them.

Still OPEN (per-trade, losers-first, via `2026-07-03_per-trade-forensic-prompt.md`): per loser — why taken · dominant engine/multiplier · multiplier≠1.0 active (esp. in the 08–26.06 applied-window) · did it move sizing/decision · minimal counterfactual to no-trade · lesson/meta-label/postmortem available vs actually used. Note: postmortems have been dead since ~29.06 (see addendum), so "available before trade" will be NO for recent losers by defect, not by design.

---
## Section 3 — Learning-loop truth table
| Question | Answer (code-verified) | Evidence |
|---|---|---|
| Does lesson-injection enter scoring/gating? | **NO** — advisory prompt-injection to risk-advisor/trade-critic only; no gate/sizing reads it; master flags default-OFF | `lesson-loop-dead-wire`, `all-master-gates-default-off`, agent-lessons/client.ts:8 |
| Do engine multipliers affect LIVE sizing/scoring? | **ONLY under `SAFE_AUTO_APPLY`** (default `RECOMMEND_ONLY` → frozen 1.0). Even ON, outcome set is empty/`no_trade`-poisoned + correct-label inverted | `engine-weights-apply-only-under-safe-auto-apply`, `tier3-attribution-flag-default-off`, `no-trade-rows-poison-directional-accuracy`, scoring.ts:53 |
| Does meta-label affect live trade/no-trade? | **NO** — shadow-only, Prism-path only, never linked to live trade; trainer features constant-zero | `model-output-dead-end`, `trainer-features-constant-zero`, `meta-label-model-shadow-only-off` |
| Do session/threshold calibrations change live trades? | **NO** — `getActiveProfile()` returns baseline, 0 callers | `session-calibration-write-only-dead-wire` calibration.ts:362 |
| Exit-side conviction (flip/degrade-cut) live? | **NO** under `ORB_ONLY_MODE` — synthesis never published → never cuts | missed: `exit-conviction-degradation-engine-dead-under-orb-only` |
| Can rollbacks reverse impact? | **YES for the one live lever** (env revert + multipliers reset to 1.0 on restart; applied persist in firm_state until reset). Rest: nothing applied → nothing to revert | operator-decisions.md, calibrate-weights.ts |
| `CALIBRATION_MODE` live value | **`RECOMMEND_ONLY` since 2026-06-27** (auto-apply reverted; 374 applied-rows 08–26.06, then 0) — the P0 rec from `2026-07-01_bleed-diagnosis` is effectively in place | ai-1 prod-DB sweep, `2026-07-07_full-analyse-gpu-laering-data.md` §3 |
| `SAFE_AUTO_APPLY` state / multiplier≠1.0 incidence on losers | **OFF since 27.06** → multipliers neutral 1.0 now. Exposure window with applied≠neutral = 08–26.06 (374 rows). Per-loser incidence in that window still unquantified (needs the §2 per-trade pull) | ai-1 prod-DB sweep; calibration_log |

---
## Section 4 — Monitor spec = per-trade FLIGHT RECORDER
**Single highest-leverage build step:** extend the TIER-3 fill/paper UPDATE (`strategy-execution.ts:1592-1650`) to also populate the EXISTING `entry_snapshot` JSONB (`schema.ts:572`) with the same shape the Blade path already builds (`managers.ts:949-1010`). One write closes why/criteria/conviction-tiers/macro/range/dissent provenance for the executing path — no new table. Then add ONE read-only SQL VIEW `trade_provenance` LEFT JOINing simulated_orders → market_snapshots/gate_decisions/shadow_signals/engine_scores/meta_label_scores on `decision_cycle_id`.

Minimum fields (operator-locked) — captured today vs new:
| Field | Captured? | Source / how |
|---|---|---|
| trade_id | YES | simulated_orders.id (schema.ts:68) |
| timestamp | YES | opened_at / fill UPDATE strategy-execution.ts:1592 |
| symbol / side / size | YES | simulated_orders cols |
| final_decision | YES | execution path / decision row |
| final_score (conviction_total) | PARTIAL | schema.ts:691 — but usually a confidence*100 FALLBACK, not real synthesis (strategy-execution.ts:1131); add conviction_source flag |
| gate_result (ordered ledger) | NO | scattered across gate_decisions/blade_decisions/v146; add `gate_ledger[]` to entry_snapshot |
| dominant_engine | NO | derive from engine_scores; requires TIER3 attribution ON |
| engine_scores_snapshot | NO | engine_scores absent on executing path (TIER3_ENGINE_ATTRIBUTION_ENABLED off) |
| engine_multipliers_snapshot | NO | firm_state engine_multipliers:current at open; add to entry_snapshot |
| calibration_mode | NO | calibrationMode() at open; add field |
| safe_auto_apply_state | NO | derive from mode; add field |
| lesson_injected / lesson_source | NO | injection.ts result not persisted; add bool+source |
| parameter_lineage (file:line) | NO | sizing sub-object {balance,risk%,riskPctSource,chain,sizingMod,newsBoost,dollarRisk,sizeRaw} — all local at strategy-execution.ts:1247; add to entry_snapshot |
| counterfactual_no_trade_threshold | NO | compute at open: min delta on binding gate/threshold that flips to no-trade; store |
| expected_outcome (meta_label P(win)) | NO | meta_label_scores — Prism-shadow only; stamp trade_id (gated) |
| actual_outcome (result_r/close_reason) | YES | schema.ts:665,470 at close |
| postmortem_link | YES | postmortem.ts run per close (but reads 0/NULL scores on TIER-3 path) |
| was_clamped / original_size | NO | circuit breaker strategy-execution.ts:1288 logs only; set existing original_size col + flag |
| dissent[] (interference) | NO | union of would_reject gates + criteriaFailed + opposing engines + contradictionScore; add ledger |
| fields_missing | NO | monitor self-reports NOT-CAPTURED per trade |

**Influence method (Q4 — how much each factor drove it):** per-engine signed contribution = base×weight×perfMult×regimeFit, influence_share = contribution_i/Σ|contribution|; size via log-space factor shares ('news boost = +18% of size'); render as stacked bars. Caveat the monitor MUST show: perfMult frozen at 1.0 unless SAFE_AUTO_APPLY → label 'weights not applied'.
**Interference method (Q5 — what pushed back):** per-trade `dissent[]` = would_reject soft-veto gates + criteriaFailed + opposing (negative-contribution) engines + contradictionScore + near-miss risk_events, ranked by margin-to-threshold. Empty list = clean signal.
**Monitor surfaces:** extend `/explorer/trades` grid (add conviction_source, was_clamped, n_dissenting_gates, predicted_pwin, result_r) + `/explorer/trades/:id` 6-section provenance card + firm-wide engine-blind/clamp/adx-null health panel (report-only, no auto-disable) + CSV export of `trade_provenance` view (firm-originated only) + morning-briefing advisory counts.

---
## Appendix — completeness critic: the EXIT side is as dead as the entry side
Not in the 43 (entry-focused); found by the critic. These block learning on how trades are MANAGED/CLOSED:
- **`exit-conviction-degradation-engine-dead-under-orb-only`** — The entire exit-side conviction engine — CONVICTION_FLIP_EXIT and CONVICTION_DEGRADE_CUT — silently no-ops in prod. Under ORB_ONLY_MODE (prod default) prismSynthesis is skipped, so xauusd.manager.synthesis is never published; the position manager reads it, gets null, latestConvictionScore stays null, and evaluateDegradation returns immediately. Trades are NEVER cut or exited when conviction reverses. This is a whole decision engine that appears active in code but is a dead wire in the running config, and none of the confirmed defects (which cover ENTRY-side conviction/calibration) touch it.  
  _where:_ apps/worker/src/firm/orchestrator.ts:726-728 (orbOnly -> synthesisId:null, no synthesis published); apps/worker/src/firm/position-management/manager.ts:502-515 (board.latest('xauusd.manager.synthesis') -> null in prod); apps/worker/src/firm/position-management/lifecycle.ts:353-354 (latest==null -> return null) and 344-397 (flip/degrade logic gated on it)
- **`exit-quality-diagnostics-computed-then-discarded`** — classifyManagement computes a structured diagnostics object per closed trade (peakRMultiple = MFE efficiency / give-back, plus hadBreakEven/hadTrailing/hadStaleExit/hadFlipExit flags), but only the prose `.lessons[]` array is consumed by the postmortem and the structured `diagnostics` object is thrown away. Give-back and exit-quality — the single most important signal for tuning trailing/stale rules — is calculated every trade and never persisted as a queryable field; it evaporates into free-text lessons that feed the already-dead lesson loop.  
  _where:_ apps/worker/src/firm/position-management/classifier.ts:85-110 (peakRMultiple + diagnostics built) and 96-233 (only lessons returned/used); apps/worker/src/firm/postmortem.ts:336-350 (only managementResult.lessons pushed, diagnostics dropped)
- **`broker-side-exit-failures-invisible-to-learning`** — When OANDA rejects a full close, partial close, or SL-modify, the manager emits only a logWarn, strips the fields, and silently retries next cycle. Nothing structured is written: no risk_event, no gate_decision, no flag on the trade. A position whose break-even/trailing stop repeatedly fails to land at the broker keeps carrying unintended full risk with zero queryable provenance — the firm 'decides to retry' every cycle without recording that it is doing so, and post-hoc you cannot see the trade lost more than 1R because its BE stop never actually set.  
  _where:_ apps/worker/src/firm/position-management/manager.ts:196-205 (closeFull fail -> logWarn+return), 221-234 (partial fail -> strip+logWarn), 249-260 (SL modify fail -> strip+logWarn)
- **`tighten-only-degraded-management-not-recorded`** — On a bounded-stale price tick the manager runs restrictDecisionToTightenOnly, which silently DROPS PARTIAL_TP1/TP2/TP3 profit-takes (keeping only risk-reducing moves). No event or flag is persisted saying 'this cycle ran tighten-only and skipped a profit-take'. A trade that gives back profit because TP1 was suppressed on a stale tick looks, in the record, like a normal give-back — the causal origin (stale-price degraded management) is unrecoverable, so the give-back is mis-attributed to the trailing rules during learning.  
  _where:_ apps/worker/src/firm/position-management/manager.ts:465-487 (restrictDecisionToTightenOnly drops partial events, writes nothing) and 552-556 (applied with no provenance)
- **`postmortem-close-conviction-also-null-in-prod`** — The postmortem's management classification reads latest conviction from the same xauusd.manager.synthesis topic that is never published under ORB_ONLY_MODE, so latestConvictionScore is null at close-time in prod. Every entry-vs-close conviction comparison the postmortem tries to make is silently degraded to 'unknown', quietly disabling the conviction-decay-vs-outcome learning signal on the live path.  
  _where:_ apps/worker/src/firm/postmortem.ts:330-334 (board.latest('xauusd.manager.synthesis') -> null in prod); same dead source as orchestrator.ts:726-728

**Missing exit/management provenance (7):**
- No exit-time market/context bundle. The close UPDATE writes only close_price, close_reason, pnl, realized_partial_pnl, management_events — there is NO exit_cycle_id/orchestrator_cycle_id at close, and no spread_at_exit, atr_at_exit, session_at_exit, portfolio_regime_at_exit, or conviction_at_exit. Entry has a rich joinable bundle + market_snapshots row; exit has nothing joinable, so 'were we exiting into a bad regime/wide spread' is unanswerable. (manager.ts:288-308)
- No close-fill execution quality. brokerFullClose.price/realizedPnl is used for PnL but the slippage of the close fill vs signal/last price is never computed or stored, so exit-side slippage cannot be learned even though entry fill_latency_ms and spread_at_entry are captured. (manager.ts:280-308)
- No Maximum Adverse Excursion (MAE). Only peak_price = max FAVORABLE excursion is tracked; there is no worst-price / heat / max-adverse field. Without MAE you cannot learn stop-placement quality (how much heat a winner took, how close a loser came before reversing). (lifecycle.ts:434-437; DB has peak_price only)
- The inputs that actually DROVE a CONVICTION_FLIP_EXIT / DEGRADE_CUT (entryConviction, latestConviction, the synthesis message id/cycle that produced it) are buried inside the management_events JSONB blob, not first-class columns and not linked to any cycle or market_snapshot — so the exit's 'why now' cannot be joined to context the way the entry's whyNow can. (lifecycle.ts:360-393; manager.ts:270-308)
- Give-back / MFE-capture-efficiency (peakR vs realized R) is computed per trade in classifier.ts but never persisted as a structured per-trade field — it exists only transiently as a `diagnostics` object that the caller discards. (classifier.ts:85-110)
- The trailing/exit parameter ORIGIN is under-recorded: TRAILING_UPDATE logs the resolved mult but not which regime profile or CHAIN_TP1/2/3_ATR env override was active, and trailing distance is derived from atr_at_entry + regime_at_entry (both FROZEN at entry) with no record that current ATR/regime was ignored. A trade whose vol regime changed post-entry trails on a stale ATR with no provenance flag. (lifecycle.ts:186-206, 277-333; rules.ts resolveTrailingAtrMult/resolveChainTrailRules)
- No per-trade flag for degraded management mode (tightenOnly) or for a stripped/failed broker mutation — the two states where the manager knowingly did something other than the nominal rule are both unlogged at the row level. (manager.ts:227-234, 255-259, 465-487)

---
## Addendum 2026-07-09 — live-DB confirmations from ai-1's full sweep (2026-07-07)
Source: `00-claude-inbox/ai-assistent/2026-07-07_full-analyse-gpu-laering-data.md` (6 analysts, prod-DB + code, read-only). These EXTEND the 43-defect register with live-side defects the code-only workflow could not see, and they close the two §3 PENDING rows (merged above).

**GPU question — answered:** GPU serves ONLY Command Room-Chief (since 25.06) + dark HLE deep-answer. PR #211 (firm-agents → GPU) never merged (CONFLICTING, 22 commits behind). No trading/learning decision has ever run on GPU → the bleed is not GPU-causal; the only GPU effect is Chief latency 9s→2–4s.

**New live-side defects (candidates for §1 register, P0-class):**
- **postmortems-dead-since-2026-06-29** — 15 closes since 28.06, all stamped `postmortem_run_at`, only 1 postmortem row. Catch in `apps/worker/src/firm/postmortem-hook.ts:265-285` logs to Railway only and stamps run_at regardless → never retried. Starves lesson-derivation, calibration, analytics. Blocks: learning + observability. Owner: ai-1.
- **lesson-clustering-structurally-fragmented** — fdbdaa4 (15.06) added `entry_hour_utc` to lesson-cluster GROUP BY (`scripts/firehose/derive-lessons.mjs:112,125`); at ~1 trade/day the largest bucket reaches n=3 vs MIN_SAMPLE=5 → **0 lessons since 18.06, structural**. Auto-promote (n≥20) mathematically unreachable. `hypotheses` table has 0 rows ever (insert errors swallowed). Blocks: learning. Owner: ai-1 (Karri proposal — changes lesson content).
- **hle-import-frozen-2026-06-30** + **meta-label-train-cron-silent-since-30.06** — likely common cause = DB drops 30.06; fix branch `feat/hle-import-resilience` (2856344) pushed but NO PR. Owner: ai-1.
- **economic-events-stale-since-2026-05-17** — event-BLACKOUT gate computes CLEAR through FOMC/CPI/NFP and allows full size in event windows (`event-calendar-freshness.ts`); freshness alert also OFF. Money-risk: direct exposure increase. Owner: ai-1/operator.
- **hle-poison-labels-185R+23.8R** still label=1 in `hle_label_assignments`; 30.06 oneshot-SQL never run and only covers one row. Poisons anything computed on raw labels. Owner: ai-1 (operator-gated SQL).
- **sizing-vs-circuit-breaker-mismatch** — sizing engine produces sizes its own breaker rejects (maxUnits=80/300% notional, `strategy-execution.ts:177`): ~11 lost trades/6 weeks (~25% leakage). Owner: ai-1.

**Meta-label reality-check (updates §3 row 3 nuance):** 4 models WERE trained (daily cron until 30.06) — all verdict no-signal, negative Brier skill (−0.073 to −0.176) at n≈96. Nothing mechanical blocks training; the data has no learnable signal yet. MinTRL is INFINITE at Sharpe ≤ 0 — waiting proves nothing without an edge.

**Status of my 07-01 P0 recommendation:** CALIBRATION_MODE reverted to RECOMMEND_ONLY on 27.06 (before/independent of the rec) — the one live learning wire is now OFF. Remaining exposure window to audit per-trade: 08–26.06 (374 applied rows).
