# Autotune / SAFE_AUTO_APPLY bounds verification — 2026-06-07

Repo: /home/nithu/code/ai-assistent @ main (2b2d2ce). READ/VERIFY ONLY.
Data: data/pull/calibration_status.json + nexus-pg (read-only) calibration_log / engine_scores.

## TL;DR

- **Applying? NO.** Live `CALIBRATION_MODE = RECOMMEND_ONLY`. `autoApplyActive=false`. Premise that "SAFE_AUTO_APPLY is flipped on" is **NOT** reflected in production.
- **Within bounds? YES (vacuously).** Bounds code is correct + enforced, but nothing is being applied — all 7 engine multipliers = 1.0, `multipliersSource=null` (engine calibrator has never persisted a value).
- **Current sample size feeding calibration: 0** in the last 14 days. `engine_scores` writes stopped 2026-04-24 (firm is ORB-only; the firm-wide engine pipeline is dormant).
- **Noise-chasing risk: NONE right now** (inert). Latent risk if flipped today = the relevant code-level guard (engine calibration) is SKIPPED under ORB_ONLY_MODE, so it would not chase noise either — it simply wouldn't run.
- **30s rollback: INTACT.** Single Worker env var (`CALIBRATION_MODE`), no code; unrecognised/unset → RECOMMEND_ONLY fail-safe.

## 1. Code path + bounds enforcement (Karri PR #68 / item B 2026-06-05)

Chain: `orchestrator.ts:724` → `runCalibration(db, calibrationMode())` every 20 cycles
→ `calibration.ts:334-344`: `SAFE_AUTO_APPLY` maps engineMode=`APPLY`, passes
`minSamples: 30` and `maxDeviationFromNeutral: 0.20`
→ `calibrate-weights.ts:calibrateEngineWeights` → `boundedNextMultiplier`.

Guards verified in `calibrate-weights.ts`:
- **≥30-sample gate** (`:115-118`): `applied = mode==="APPLY" && card.sampleCount >= minSamples && Math.abs(next-current) > 0.005`. Thin samples → applied=false. Correct.
- **±20% deviation cap** (`boundedNextMultiplier :74-91`): per-run delta cap (0.08) → global `PERF_MULT_BOUNDS` [0.70,1.20] → then clamps to `[neutral-0.20, neutral+0.20]` = **[0.80, 1.20]**. Note the Karri cap is the binding floor (raises 0.70 → 0.80); ceiling unchanged at 1.20.
- Unit tests cover both gates: `calibrate-weights.test.ts:37-48` (floor→0.80, ceiling@1.20, in-band passthrough). 9 tests.

Bounds are real and would be enforced **if** APPLY ran. They are not currently exercised.

## 2. Live data

`data/pull/calibration_status.json` (HTTP 200):
```
calibrationMode: RECOMMEND_ONLY
autoApplyActive: false
multipliersNeutral: true
multipliersSource: null          # engine calibrator never persisted -> never applied
engineMultipliers: macro/technical/structure/sentiment/intermarket/momentum/session = 1.0 each
```

DB (nexus-pg):
- `calibration_log`: 342 rows, **all** `mode=RECOMMEND_ONLY`, `applied=false`. **Last entry 2026-04-25.** Zero `engine_multiplier.*` rows ever (engine-level calibrator has never produced output).
- `engine_scores`: 18,534 rows all-time, range 2026-04-15 → **2026-04-24** (stopped). **0 rows in last 14 days.**

Why dormant: `orchestrator.ts:724` runs calibration only `if (!orbOnlyMode && cycleCount % 20 === 0)`. Firm is ORB-only, so `runCalibration` is skipped entirely — matches the April cutoff for both `calibration_log` and `engine_scores`.

## 3. Noise-chasing risk

- Current state: inert (RECOMMEND_ONLY + ORB-only skip + empty sample window). No re-weighting is happening; `scoring.ts` multiply is a no-op with all multipliers at 1.0.
- If `CALIBRATION_MODE=SAFE_AUTO_APPLY` were flipped **while ORB-only**: still no effect — the calibration call is gated out at the orchestrator. So no thin-sample chasing via this path.
- If ORB-only were also lifted AND SAFE_AUTO_APPLY on: the ≥30/engine gate + ±20% cap would bind. With the historically thin/blowup-skewed window, the realistic outcome is most engines stay at applied=false (sub-30 samples) rather than a large drift. The cap limits any single engine to ±20% from neutral and ≤0.08/run. Residual concern Karri already flagged: 30 samples/engine is still small and `performanceScore` can be blowup-dominated — but the deviation cap bounds the damage. Not chasing anything today.

## 4. Rollback path (30s)

`docs/ref/feature-flags.md:76` documents `CALIBRATION_MODE`. Rollback = set Worker env `CALIBRATION_MODE=RECOMMEND_ONLY` (or unset). `calibration.ts:45-49`: unrecognised/missing → RECOMMEND_ONLY fail-safe. No code change, revertable in one Railway var flip. **Intact.** (Operator-gated action — Claude does not flip Railway vars.)

## Verdict line

Applying: **NO** (RECOMMEND_ONLY live). Within bounds: **YES** (vacuous — nothing applied; bounds code correct + tested). Sample size feeding calibration: **0** in 14d (engine_scores stopped 2026-04-24, firm is ORB-only). Noise-chasing risk: **none currently** (inert; engine calibration is skipped under ORB_ONLY_MODE even if the flag were flipped).
