# WF lane replenish-2 — MR adx-surfacing regression guard

Date: 2026-06-08
Lane: replenish-2 (surfaced by adx-rootcause)
Task: extend mean-reversion manager test to assert `indicators.adx` is surfaced on the `adx_too_high` reject path (regression guard).
Branch: `fix/wf-replenish-2-mr-adx-surface` (commit `5527eb6`)
Verdict: DONE — guard added, plus the underlying observability bug it would have caught was found and fixed (behaviour-neutral).

## Root finding (diagnosis)

In `apps/worker/src/firm/mean-reversion/mean-reversion-manager.ts`, the `publishState` FACT payload read:

```
adx: result.signal?.adx ?? null,
```

On the `adx_too_high` reject (and every other reject) `result.signal` is `null`, so the published `state.adx` was **always null on the exact gate ADX tripped**. The dashboard StrategyEvaluator panel (`apps/dashboard/docs/strategy-evaluator-todos.md`, the "adx — sanity gate, should be LOW" column) therefore showed `adx=unknown` for ADX-driven rejects. `rsi` and `impulseAtr` were already plumbed via the `extras` object (commits `9aac16a`, `43615e4`); `adx` had been missed.

So a naive "assert adx is surfaced" test would have FAILED against the pre-fix code — the test could not be added without first fixing the surfacing. I fixed it as observability-only (no trade-decision logic touched).

## Changes (commit 5527eb6, 2 files)

Source `mean-reversion-manager.ts`:
- Added `adx?: number | null` to `MRStateExtras` (interface now exported).
- Set `extras.adx = adx` right after indicators are fetched (alongside the existing `extras.rsi = rsi`), i.e. before the ADX gate — so reject paths carry the value.
- `publishState` now reads `adx: result.signal?.adx ?? extras.adx ?? null` (success path still prefers signal-derived).
- Extracted the FACT state object into a new **pure exported** `buildMRState(result, extras)`; `publishState` calls it. This is the testable seam — the codebase deliberately avoids `mock.module` (flaky across node versions, per `drift-monitor.test.ts` comment), so a pure builder is the right way to unit-test the contract without mocking market-data fetches.

Test `mean-reversion-manager.test.ts` — 3 new regression tests:
1. `buildMRState: surfaces adx on adx_too_high reject path (signal=null)` — the core guard: asserts `state.adx === 34.2`, not null.
2. `buildMRState: adx is null when no signal AND no extras.adx (pre-indicator reject)` — cooldown/cap/session rejects (before indicators fetched) stay null, don't crash.
3. `buildMRState: prefers signal.adx over extras on success path` — success path uses signal-derived adx + impulseAtr mirror.

## Behaviour-neutrality / constraints

- No env flag added: the change only fills a FACT-state field that was incorrectly null. The field is consumed by the dashboard only — NOT by any trade-decision gate. So it is behaviour-neutral on deploy and not a strategy/risk/gate change (no Karri proposal needed).
- I did NOT edit ADX/regime/indicator computation code (ai-1's lane). The change is in the MR manager's state-publishing wiring + its test. Diagnosis of the ADX read path was read-only.

## Verification

- `tsc --noEmit` (apps/worker): clean (also passed husky pre-commit).
- MR test file: 17/17 pass (14 existing + 3 new).
- Full worker suite (`npm test`): **1178/1178 pass** (was 1175).

## Branch hygiene note (for coordinator)

A transient collision occurred: branch/worktree state is shared across parallel lanes in this single worktree. My first commit briefly landed on a branch named `fix/wf-replenish-1-strategy-states-adx-from-h1` (which was sitting at main's HEAD with zero other commits). I moved the commit to a dedicated `fix/wf-replenish-2-mr-adx-surface` branch and reset `fix/wf-replenish-1-...` back to `main` — so no other lane's work was disturbed. There were also unrelated uncommitted working-tree edits (`apps/api/src/routes/firm-memory.ts`, `apps/worker/src/services/sentiment-sources.service.ts`, `docs/ref/env-vars.md`) bleeding in from parallel lanes; I did NOT touch or commit them — my commit contains exactly the 2 mean-reversion files.

Recommendation: parallel lanes sharing ONE worktree is risky (branch/worktree races). Consider git worktrees per lane next run.
