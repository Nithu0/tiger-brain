# wf_panel-truth — learning-panel-truth fix (2026-06-08)

## Lane
learning-panel-truth (BUILD). Branch `fix/wf-panel-truth`, commit `20515cc`.

## Problem
/calibration/status reported `calibrationMode` from the API process's own `CALIBRATION_MODE` env. The WORKER is the process that actually runs the calibration loop; its env can differ. Symptom: panel showed RECOMMEND_ONLY while the worker was on SAFE_AUTO_APPLY and auto-applying multipliers (multipliersNeutral=false proved it). The learning panel lied.

## Fix (mirrors engine-multiplier-state pattern)
- `packages/shared/src/calibration-mode-state.ts` — shared contract: key `calibration_mode:current`, `CalibrationModeSnapshot`, pure build/parse/coerce helpers. Exported from shared index.
- `apps/worker/src/firm/calibration-mode-state.ts` — `persistCalibrationMode` (DB I/O only, never throws — prinsipp 2). Re-exports parser/key from shared.
- Worker persists its ACTIVE mode in two places:
  - orchestrator `start()` (boot) — covers ORB_ONLY_MODE (calibration skipped) and the pre-first-cycle window. Fire-and-forget.
  - top of `runCalibration` BEFORE the `if (mode==="OFF") return []` early-return — so even an OFF worker reports truthfully.
- `apps/api/src/routes/calibration.ts` — reads the persisted snapshot first, falls back to its own env only when the worker never wrote the row. Adds `calibrationModeSource` ("worker" | "api-env-fallback") provenance.
- `apps/dashboard/src/lib/api.ts` — added optional `calibrationModeSource` to `CalibrationStatusResponse` (back-compat optional).

## Safety
Behaviour-neutral observability. New firm_state KV row; writing it is inert, changes no trade decision. No new env flag needed. No strategy/risk/gate logic touched. Did NOT touch ADX/regime/indicator code (ai-1's lane).

## Verification
- tsc --noEmit clean: worker, api, dashboard, shared (shared built first).
- worker: 1157/1157 pass (+9 new tests in calibration-mode-state.test.ts).
- api: 30/30 pass, incl 2 new tests:
  - "worker-persisted mode WINS over API env (the bug fix)" — firm_state SAFE_AUTO_APPLY beats env RECOMMEND_ONLY, source=worker.
  - "no worker row → reports env with api-env-fallback source".
- husky pre-commit (tsc) passed on commit.

## Worktree resolution note (for reviewers)
The worktree has no own node_modules; `@ai-agent/shared` hoists to the MAIN repo's `packages/shared/dist`, which lacks the new export. To verify without polluting main source I created a worktree-local symlink `node_modules/@ai-agent/shared -> ../../packages/shared` (worktree's own freshly built dist) during tsc/tests/commit, then removed it. Working tree is clean. On merge to main, a normal `cd packages/shared && npm run build` regenerates the dist with the new exports — required before the worker/api builds will pass in main.

## Open / handoff
- No operator/Karri gate needed: pure observability, no flag, no trade change.
- Before deploy: shared must be rebuilt (standard for any shared change).
