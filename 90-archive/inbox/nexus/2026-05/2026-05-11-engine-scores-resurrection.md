---
date: 2026-05-11
project: nexus
type: investigation
status: root-cause-confirmed
related:
  - "[[2026-05-11-full-state-audit]]"
  - docs/ops/gate-silence-2026-05-08.md
---

# engine_scores + calibration_log silence — root cause

## TL;DR

Same root cause as `gate_decisions` silence: **`ORB_ONLY_MODE=true` pivot on 2026-04-25 (commit `8abb4bb`) bypasses both writers entirely.** Operator-controlled (architectural, not a regression). Recommendation: **document as known-limitation, no fix required** unless operator wants attribution data under ORB-only.

## Writers — exact locations

### engine_scores

- **Primary writer**: `apps/worker/src/firm/engine-attribution/recorder.ts:48` (`recordCycleSnapshot` — INSERT at decision time, one row per engine per cycle).
- **Outcome backfill**: same file, line 99 (`backfillOutcomeForTrade`) + line 135 (`markCycleAsNoTrade`).
- **Trade-id link**: `apps/worker/src/firm/managers.ts:1053` (UPDATE after Execution Manager opens position).
- **Sole call site for INSERT**: `apps/worker/src/firm/managers.ts:692` inside `bladeApproval()`.

### calibration_log

- **Primary writer**: `apps/worker/src/firm/calibration.ts:287` inside `runCalibration()`.
- **Engine-weight writer**: `apps/worker/src/firm/engine-attribution/calibrate-weights.ts:129` (called from `runCalibration`).
- **CIO writer**: `apps/worker/src/firm/cio/dispatcher.ts:141` (called from `runCIOIfDue`, gated by `NEXUS_CIO_ENABLED`).
- **Sole call site for `runCalibration`**: `apps/worker/src/firm/orchestrator.ts:491`.

## Gate / silence cause

### Both tables share the same kill-switch

`apps/worker/src/firm/orchestrator.ts:417`

```ts
const orbOnlyMode = process.env.ORB_ONLY_MODE === "true";

// Step 3+4: Synthesis + Decision pipeline — fully bypassed
const { synthesisId, thesis, direction, cycleId } = orbOnlyMode
  ? { synthesisId: null, thesis: null, direction: "neutral", cycleId: orchestratorCycleId }
  : await prismSynthesis(this.board, this.db);

if (!orbOnlyMode && synthesisId && thesis && isTradeAllowed(window.state) && portfolioGate) {
  // ... bladeApproval() is here — never called under ORB_ONLY_MODE
}

// Periodic calibration
if (!orbOnlyMode && this.cycleCount % 20 === 0) {
  runCalibration(this.db, "RECOMMEND_ONLY").catch(...);
}
```

When `ORB_ONLY_MODE=true`:
1. `bladeApproval` never runs → `recordCycleSnapshot` never called → no engine_scores INSERTs
2. `runCalibration` never runs → no calibration_log INSERTs from session/engine-weight calibrators

### Date alignment confirms the cause

- Last `engine_scores` row: **2026-04-24T22:26:19.220Z**
- Last `calibration_log` row: **2026-04-25T01:07:36.110Z**
- `ORB_ONLY_MODE` pivot commit (`8abb4bb`): **2026-04-25 21:56:49 +0200**
- ORB pivot strategy adopted: **2026-04-24** (per `docs/CONTEXT-MAP.md:82`)

Silence onset matches the pivot precisely.

### Strategy-blade path does NOT write engine_scores

`apps/worker/src/firm/strategy-blade.ts` and `strategies/*.ts` route through `runStrategyExecution` → `evaluateStrategySignal` (mini-Blade). **No call to `recordCycleSnapshot` anywhere in that path.** This is the same architectural gap that killed `gate_decisions` (already documented in `docs/ops/gate-silence-2026-05-08.md`).

## Bonus bug found (not the cause, but worth noting)

Two `INSERT INTO calibration_log` statements use column names that don't match the schema:

- `apps/worker/src/firm/engine-attribution/calibrate-weights.ts:130` — uses `current_value, recommended_value`
- `apps/worker/src/firm/cio/dispatcher.ts:142` — uses `current_value, recommended_value`

Actual schema columns: `old_value, new_value`. Both writes are wrapped in `try { ... } catch { /* optional */ }` so they silently swallow the `column does not exist` error. Currently unreachable (gated upstream by `ORB_ONLY_MODE` / `NEXUS_CIO_ENABLED`), but **will throw silently the moment those gates are flipped**.

`apps/worker/src/firm/calibration.ts:287` uses the correct column names (`old_value, new_value`).

## Recommendation

**No code fix required to "unbreak" the tables** — they're behaving correctly given the architecture. Options:

### Option A: Document as known-limitation (recommended)

Add to `docs/ops/known-failures.md` and `docs/ref/known-issues.md`:

> Under `ORB_ONLY_MODE=true`, `engine_scores` + `calibration_log` writers are bypassed. ORB strategies have their own stats module (`firm/orb/stats.ts`); engine attribution is firm-path only. Restoring data requires either (a) `ORB_ONLY_MODE=false` rollback or (b) wiring `recordCycleSnapshot` into `runStrategyExecution` (parallel to the `gate_decisions` fix sketched in `docs/ops/gate-silence-2026-05-08.md`).

### Option B: Wire writers into strategy-blade path (only if operator wants attribution under ORB)

Mirror the `persistGateDecisions` migration approach from `docs/ops/gate-silence-2026-05-08.md`:
1. Call `recordCycleSnapshot` inside `runStrategyExecution` after each strategy evaluates.
2. Add a `path` discriminator column to distinguish firm-path vs strategy-blade-path rows.
3. Move `runCalibration` outside the `orbOnlyMode` guard (it's read-only in RECOMMEND_ONLY mode anyway).

**This is a strategy/risk-adjacent change → requires teammate (Karri) review per project CLAUDE.md.** Do NOT implement without proposal.

### Bonus fix (column-name bug)

Safe to fix immediately — pure bug, both writers currently unreachable so impact is zero today but lurking. Two-line edit in `calibrate-weights.ts` + `dispatcher.ts`. NOT pushed in this investigation per instruction ("commit only if pure bug fix"). Pure bug → could commit, but operator should decide whether to roll it into a larger PR.

## Implementation status

- **Investigation**: complete
- **Code change**: none applied (matches "investigation only" directive)
- **Operator action required**: decide A vs B, then file proposal if B
- **No push**

## Files touched in this analysis

- Read: `apps/worker/src/firm/engine-attribution/recorder.ts`
- Read: `apps/worker/src/firm/calibration.ts`
- Read: `apps/worker/src/firm/orchestrator.ts` (lines 405-465, 486-495)
- Read: `apps/worker/src/firm/managers.ts` (lines 650-735)
- Read: `apps/worker/src/firm/cio/dispatcher.ts` (lines 120-160)
- Read: `apps/worker/src/firm/engine-attribution/calibrate-weights.ts` (lines 120-150)
- Queried: `engine_scores`, `calibration_log` via nexus-pg MCP
