# wf-replenish-4 — trend-following strategy-state staleness

**Date:** 2026-06-08
**Lane:** replenish-4 (surfaced by overblock-vs-dormant anomaly check)
**Branch:** `fix/wf-replenish-4-strategy-stale-flag` (commit 845d34b)
**Verdict:** NOT a code bug. False alarm rooted in a misleading observability proxy. Operator config is intentional; shipped an observability fix so the alarm can't recur.

## Symptom

`/firm/strategy-states` reported trend-following with:
- `enabled: true`
- `lastEvaluatedAt: 2026-06-06T17:16:54Z` (Saturday)
- `ageSeconds: 151010` (~42h)
- `rejectReason: "session_not_allowed: WEEKEND"` — persisting into Monday's London-active session.

All four other strategies (breakout-continuation, pullback-continuation, mean-reversion, volatility-expansion) showed `ageSeconds: 44` — fresh, evaluated that cycle.

## Root cause (two distinct things)

1. **Intentional operator config, not a bug.** `TREND_FOLLOWING_ENABLED=false` on the Worker service (verified via `railway variables --service Worker --kv`). The other four strategy flags are `=true`. The orchestrator early-exits TF at `if (isTrendFollowingEnabled())` (`apps/worker/src/firm/orchestrator.ts:485`), identical pattern to every other strategy. So `evaluateTrendFollowingEntry` never runs → no new state row → the blackboard row stays frozen at the last time TF actually ran, which was Saturday during WEEKEND. Hence the stale "session_not_allowed: WEEKEND". There is NO eval-cadence/refresh bug in the strategy or orchestrator — disabled strategies correctly do nothing.

2. **Real observability bug (the thing that triggered the false alarm).** `/firm/strategy-states` derives `enabled = row ? true : null` (`apps/api/src/routes/firm-memory.ts`). That field only means "this topic has *ever* published a state row," NOT "the env flag is currently on." Blackboard rows are never deleted, so a strategy turned OFF keeps reading `enabled: true` with a frozen `rejectReason` forever. The API process cannot read Worker env (separate Railway service), so it cannot show the true flag state. The anomaly check ("overblock-vs-dormant") saw enabled:true + old reason and inferred an over-block / cadence bug.

## Fix shipped (observability only — Claude-owned, not strategy/risk)

Added a read-only `stale` boolean to each strategy on `/firm/strategy-states`:
- `stale = ageSeconds > STRATEGY_STATE_STALE_SECONDS` (default 300s, ~10x the ~30s cycle so a single skipped cycle doesn't trip it).
- `stale: true` → not re-publishing (disabled on worker, or worker stalled).
- `stale: false` → actively evaluating.
- `stale: null` → never evaluated (no row).

This lets the dashboard / anomaly-check distinguish a genuinely active strategy from a frozen `enabled:true` row left by a disabled strategy, without needing worker env. Threshold env-tunable.

**Constraints honoured:** no trade logic / gates / indicator code touched (ai-1 owns ADX/regime — I did read-only diagnosis only). Purely additive JSON field; default threshold preserves current behaviour; behaviour-neutral on deploy. Did NOT flip any Railway env. Did NOT push or merge.

**Files (all on the branch, 3 files, +156/-1):**
- `apps/api/src/routes/firm-memory.ts` — `stale` field + threshold note
- `apps/api/src/routes/firm-memory-strategy-stale.test.ts` — 4 app.inject tests (fresh / stale / never-evaluated / env override)
- `apps/api/package.json` — register the test

**Verification:** `tsc --noEmit` clean on apps/api; `npm test` 32/32 pass (incl. 4 new). Husky pre-commit ran tsc green.

## Operator decision needed

- **Is trend-following meant to be OFF?** `TREND_FOLLOWING_ENABLED=false` is the current Railway state. If TF is supposed to be live, that's an operator flip (gated — I do not flip env). If it's intentionally parked, no action; the new `stale` flag will keep the dashboard honest.
- Optional follow-up (not built): dashboard `StrategyEvaluatorPanel` could render the `stale` flag (grey-out / "disabled?" badge) so disabled strategies don't look like they're actively blocking. Left for a UI lane.

## Shared-worktree note

The repo working tree is shared across the parallel lanes and other agents switch branches under me mid-session (my commit briefly landed on a transiently-checked-out `main`; I moved it to the lane branch with `git branch -f` + `git reset --hard` back to the prior main HEAD `bdd773e`, then `git stash apply`-restored the other lanes' uncommitted working-tree changes). main was NOT advanced. Cross-lane uncommitted work was preserved (stash kept as backup, applied not popped).
