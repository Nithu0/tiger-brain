# Sweep — Learning infra (2026-06-03 ship) verification

Date: 2026-06-04
Scope: READ-ONLY audit of commits `7ec793c` (learning primers + shadow forward-test) and `5341fb3` (/learning dashboard + /shadow/forward-test endpoint).
Method: source read + node:test run (33/33 pass) + tsc (worker + api clean). No live DB query run.

---

## TL;DR verdict

| Piece | Verdict |
|---|---|
| (a) `calibrationMode()` + orchestrator wiring | **Works** — correctly behaviour-neutral at default; SAFE_AUTO_APPLY apply-path is correctly gated. BUT see CRITICAL-1: the whole calibration path is dead under current `ORB_ONLY_MODE=true` production config. |
| (b) `recordForwardTestSnapshots` / `trackForwardTestOutcomes` | **Works (unverifiable-without-live for actual row writes)** — code path is correct, no-op when off, schema matches DDL, runs independent of ORB_ONLY. No runtime bug found. |
| (c) `/calibration/status` + `/shadow/forward-test` routes | **Works** — correct SELECTs, both guarded against missing tables, auth covered by global hook (no bypass). One semantic gap (CRITICAL-2). |
| (d) `/learning` dashboard | **Works (with a misleading signal)** — wired to real endpoints; but the "engine multiplier diverged → LEARNING ACTIVE" branch is permanently dead because the API hardcodes multipliers to 1.0 (BUG-3). |

No crash-level / null-deref / bad-SQL / schema-mismatch bugs in the two commits. The issues are **inertness and misleading observability**, not breakage.

---

## (a) calibrationMode() + orchestrator

`apps/worker/src/firm/calibration.ts:43-49` — reads `CALIBRATION_MODE`, validates against the 4-member enum, defaults to `RECOMMEND_ONLY`, falls back to `RECOMMEND_ONLY` on unrecognised value. Correct fail-safe.

Behaviour-neutrality at default:
- Session-level: `runCalibration(db, mode)` only writes `calibration_log` rows with `applied = (mode === "SAFE_AUTO_APPLY")`. In RECOMMEND_ONLY → `applied=false`, no profile mutation (`getActiveProfile` returns baseline only; the SAFE_AUTO_APPLY override is a TODO comment, calibration.ts:353-357). ✅ neutral.
- Engine-level: `calibration.ts:332-335` maps `SAFE_AUTO_APPLY → "APPLY"`, everything else `→ "RECOMMEND_ONLY"`. `calibrate-weights.ts:87-90,112-116` only calls `setEnginePerformanceMultipliers()` when `mode === "APPLY"`. In RECOMMEND_ONLY → multipliers never touched. ✅ neutral.

SAFE_AUTO_APPLY correctness: deltas bounded (`BOUNDS` table calibration.ts:77-85; engine `maxDelta`/`PERF_MULT_BOUNDS` in calibrate-weights), apply requires `sampleCount >= minSamples` and `|delta| > 0.005`. Logical and bounded. ✅

### CRITICAL-1 — calibration never runs in current production (ORB_ONLY_MODE=true)
`orchestrator.ts:718`: `if (!orbOnlyMode && this.cycleCount % 20 === 0) runCalibration(...)`.
`docs/ref/feature-flags.md:74` documents production `ORB_ONLY_MODE = true`, and explicitly: "bypasses ... periodic calibration."
→ Under the current production flag set, **`CALIBRATION_MODE` has zero effect**. Both session-level and engine-weight calibration are gated behind `!orbOnlyMode`. The "learning primer" the commit advertises ("makes the learning loop READY") is inert in the config Nexus actually runs. Flipping `CALIBRATION_MODE=SAFE_AUTO_APPLY` would do nothing until `ORB_ONLY_MODE=false`. Not a code bug — a real activation gap that undercuts the stated goal. Must be surfaced before anyone thinks they've "turned on learning."

---

## (b) shadow forward-test (worker)

`recordForwardTestSnapshots` (shadow-log.ts:336-403):
- `isShadowForwardTestEnabled()` defaults OFF (`?? "false"`, only `"true"` enables). Early-return → zero queries when off. ✅ truly no-op.
- Iterates `strategiesToCapture().filter(enabled)` — same canonical list as the existing snapshot path. Builds a single multi-row parameterised INSERT (15 cols × N strategies). Column list matches DDL exactly. ✅ schema-matched (verified vs `packages/shared/src/db/schema.ts:1563`).
- `state_snapshot` cast `$N::jsonb` with `JSON.stringify(state)` or null. ✅
- Wrapped in try/catch → `logWarn` + `{recorded:0}`, never throws into the loop (prinsipp 2). ✅
- `extractForwardTestRow` coerces non-finite to null (tested), handles null state, ORB vs shouldTrade heuristic. ✅
- `board.latest(topic, 300)` = 300s freshness window; `BoardMessage.state`/`.confidence` exist on the type. ✅ type-safe.

`trackForwardTestOutcomes` (shadow-log.ts:411-486):
- No-op when flag off. ✅
- Scans `outcome='pending' AND entry_price IS NOT NULL` (matches partial index `idx_shadow_fwd_pending`). ✅
- Reuses pure `resolveShadowOutcome`. Handles non-resolvable rows (no SL/TP/direction) → only ever flips to `expired` (guard line 462), writes `outcome_price=null, pnl=0` for those. ✅
- `fetchPrice` null → logs + skips, returns scanned count. ✅

Wired in orchestrator Step 1e (record, line 554) and Step 1g (track, line 589), **outside** the `orbOnlyMode` gate. So unlike calibration, forward-test WILL run in current ORB_ONLY production once `SHADOW_FORWARD_TEST_ENABLED=true`. ✅

Verdict: **works**; actual row-writes unverifiable without a live run/flag-flip, but no runtime/SQL/schema bug. 7 new forward-test unit tests pass.

### Minor (b-1) — forward-test is heavy when on
One blocking `await board.latest()` per enabled strategy per cycle (up to 8 sequential awaits) plus one INSERT, every cycle. Non-fatal, but not "zero overhead when on." Could be parallelised (`Promise.all`). Tag: infra (low pri).

---

## (c) API routes

`/calibration/status` (calibration.ts:109-168):
- `agent_lessons` GROUP BY status wrapped in `.catch(() => empty)`. ✅ guarded.
- `calibration_log` SELECT wrapped in `.catch`. ✅
- `engineMultipliers` — **hardcoded to 1.0** for 7 engine names (lines 136-140). Honest comment explains the API can't see in-worker multipliers. See BUG-3 for the downstream consequence.
- Auth: covered by global `onRequest` hook (`apps/api/src/plugins/auth.ts`); not in PUBLIC_PREFIXES → requires Bearer when `API_KEY` set. **No auth bypass.** ✅

`/shadow/forward-test` (shadow.ts:194-264):
- Whole body in try/catch → returns `{enabled:false, strategies:[], totals:{...}}` on any error incl. missing table. Never 500. ✅
- SELECT uses correct outcome enum (`tp_hit`/`sl_hit`/`pending`/`expired`) matching what the worker writes. ✅
- `days` clamped 1..365, NaN→1. ✅
- Auth: same global hook. ✅

### CRITICAL-2 (semantic, pre-existing — flag for awareness)
The OLDER shadow routes `/shadow/per-strategy` (shadow.ts:38-40) and `/shadow/comparison` (shadow.ts:150-152) filter `outcome IN ('win','loss')`, but `shadow_signals.outcome` is written as `tp_hit`/`sl_hit`/`expired`/`pending` (ShadowOutcome type, shadow-log.ts:34). So those two endpoints return **all-zero wins/losses/R forever** — the shadow-vs-actual comparison is silently broken. NOT introduced by these two commits (pre-existing), but it sits right next to the new forward-test route and the new /learning page tells the same data story. Worth fixing while the area is hot. Tag: infra (bug fix, no behaviour change → no proposal needed).

---

## (d) /learning dashboard

`apps/dashboard/src/app/learning/page.tsx` + `api.ts` (`calibrationStatus`, `shadowForwardTest`) + Sidebar entry (`/learning`, line 68). All wired to the real endpoints, react-query 60s refetch. Empty-states handled (no calibration log, forward-test off). tsc clean.

### BUG-3 — "LEARNING ACTIVE via diverged multiplier" is dead UI
`deriveLearningState` (page.tsx:14-36) sets ACTIVE if `autoApplyActive || diverged`, where `diverged = any |multiplier-1.0| > 0.001`. But the API **always** returns 1.0 for every multiplier (calibration.ts:139-140), so `diverged` is permanently false. Consequence: even when the worker has genuinely re-weighted engines under SAFE_AUTO_APPLY, the dashboard shows neutral multipliers and the "Engine multipliers have diverged" reason can never appear. The page still flips ACTIVE on the `autoApplyActive` flag, so it isn't fully broken — but the multiplier panel is decorative, not truthful. The page's own footnote (lines 273-275) admits this. Misleading observability for a panel whose whole job is honesty about whether learning is happening. Tag: infra.

---

## NEW TASKS (prioritised)

1. **[infra/operator] CRITICAL-1 — doc-or-fix the ORB_ONLY calibration gap.** Either (a) document loudly in phase-status.md + feature-flags.md + the /learning page that CALIBRATION_MODE is inert while ORB_ONLY_MODE=true, or (b) decide whether calibration *should* run in ORB_ONLY (currently bypassed by design — ORB has its own stats). Operator/Karri decision; do NOT change the gate unilaterally (money-near). Highest priority: prevents a false "we turned on learning" belief.

2. **[infra] BUG-3 + multiplier visibility.** Expose the worker's real engine multipliers to the API (worker writes current multipliers to a small state row / blackboard topic the API reads) so `/calibration/status` reports truth and the /learning "diverged" path works. Pure observability, no trade-behaviour change → no Karri proposal needed.

3. **[infra] Fix `/shadow/per-strategy` + `/shadow/comparison` outcome filter** (`'win','loss'` → `'tp_hit','sl_hit'`). Pre-existing silent zero-bug; bug-fix-restores-intended-behaviour → no proposal. Verify against live shadow_signals after fix.

4. **[infra, low] Parallelise the per-cycle `board.latest` reads in `recordForwardTestSnapshots`** (Promise.all) before flipping SHADOW_FORWARD_TEST_ENABLED, so the dense path doesn't add 8 serial awaits/cycle.

5. **[Karri/operator] Activation gating reminder.** `SHADOW_FORWARD_TEST_ENABLED` = pure observation, free to flip (capture only, no trade impact) per the learning-infra/strategy boundary. `CALIBRATION_MODE=SAFE_AUTO_APPLY` = trade-altering autotune → Karri review + operator-gate before flip. Confirm Karri is aware forward-test exists and is safe to enable for data collection.

6. **[infra, verify-after-enable] Once SHADOW_FORWARD_TEST_ENABLED is flipped, schedule a 30-60 min check** (periodic-verification cadence) that shadow_forward_test rows are actually landing (`SELECT count(*), max(detected_at) ... GROUP BY strategy`) and that the tracker resolves them — only way to confirm (b) end-to-end on real data.

---

## Verification evidence
- `node --test` (node:test, NOT vitest — repo uses node:test): `shadow-log.test.ts` + `calibration.test.ts` → 33 pass / 0 fail.
- `tsc --noEmit` worker + api → clean (0 lines).
- DDL match confirmed: INSERT columns vs `schema.ts:1563` shadow_forward_test, calibration_log (has `mode`+`applied`), agent_lessons (has `status`).
- Auth: global onRequest hook, new routes not in PUBLIC_PREFIXES → protected.
