# 2026-05-11 — evaluateNewGates duplicate-call cleanup

## Decision

**Removed** the duplicate `evaluateNewGates` call from `apps/worker/src/firm/managers.ts:bladeApproval`. The active path in `apps/worker/src/firm/strategy-blade.ts:164` remains the single source of truth for new-gate evaluation, with each TIER 3 strategy passing its own dynamic `strategyId`.

## Why remove rather than fix

Two reasons the call was problematic, not just dormant:

1. The `bladeApproval` function is **synthesis-driven** — it has no proposal-level `strategyId`. The previous hardcoded value (`"xau-htf-trend"`, later changed to `"xau-scalp-overlap"` in f2688d6) was always wrong for a path that fires on the firm-wide thesis, not a single strategy.
2. Under `ORB_ONLY_MODE=true` (current prod, set in `orchestrator.ts:417`), the entire firm-decision pipeline including `bladeApproval` is bypassed by the gate at `orchestrator.ts:426`. The call was dormant. If `ORB_ONLY_MODE` flips back to false in the future, all 4 TIER 3 strategies still call `strategy-blade.ts` via `strategy-execution.ts:40` with correct dynamic strategyIds — so the legacy path's duplicate evaluation was never adding correct information, only persisting wrong gate-decision rows.

## What was removed

In `apps/worker/src/firm/managers.ts`:

- Import: `evaluateNewGates, persistGateDecisions` from `./gates/new-gates.js`
- Body of `bladeApproval`:
  - Step 7c comment block (Trinn A scaffold)
  - `portfolioContextMsg` / `portfolioRegime` re-fetch
  - `riskLevelForGate` / `convictionTotalForGate` derivations
  - `minutesSinceLastSameDirTrade` SQL lookup
  - `evaluateNewGates(...)` call with hardcoded `strategyId`
  - `persistGateDecisions(...)` fire-and-forget
  - Decision-tree branch `if (newGateBundle.anyHardRejected) → REJECTED`

Replaced with a single comment block referencing the removal and pointing to `strategy-blade.ts:164` + `docs/ref/known-issues.md`.

## Lines changed

- `apps/worker/src/firm/managers.ts`: ~68 lines removed (562–629 region + import + downstream consumer), 17 lines of explanatory comment added → net ~−51 LoC.
- `docs/ref/known-issues.md`: scalp_overlap_asia entry moved Open → Resolved with full 2-commit fix narrative.

## Verification

- `cd apps/worker && npx tsc --noEmit` — clean.
- Targeted tests:
  - `src/firm/gates/new-gates.test.ts` — pass
  - `src/firm/strategy-blade.test.ts` — pass
  - `src/firm/strategy-execution.test.ts` — pass
  - `src/firm/scalp-overlap/scalp-manager.test.ts` — pass
  - 49/49 passing.
- Full `npm test`: 1 pre-existing failure in `agent-bus/research-drainer.test.ts` (looking for `FOR UPDATE SKIP LOCKED` SQL pattern that isn't in the implementation). Unrelated to this change — file last modified in commit `aa4d9b6`, not touched in this session.

## Behavior impact

- **In current prod (ORB_ONLY_MODE=true)**: zero. `bladeApproval` is bypassed; the removed code never ran.
- **If ORB_ONLY_MODE=false re-enabled later**: one fewer reject layer in `bladeApproval` (the new-gates hard-reject branch is gone). The underlying decision logic — risk-veto, challenge-blocking, portfolio-block, market/entry-thesis thresholds — remains intact. Gate evaluation for any actual strategy entries continues via `strategy-blade.ts`.

## Commit

`refactor(managers): remove duplicate evaluateNewGates call (active path is strategy-blade)` — SHA recorded below after commit.

## Follow-ups

None required. Surface area reduced; no dormant duplicate logic to drift.
