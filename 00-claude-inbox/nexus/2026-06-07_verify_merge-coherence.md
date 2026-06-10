# Merge-coherence verification — main after rapid ai-1 + ai-2 merges

Date: 2026-06-07
Scope: READ-ONLY skeptic audit of `main` (HEAD `2b2d2ce`, in sync with origin) after PRs #61/#65/#67/#68/#69/#70/#71/#72 + breaker/bounds/backfills/learning-infra/envBool/FVG.

## Verdict: COHERENT (with one minor accuracy gap)

Hard evidence:
- `tsc --noEmit` clean on all 3 workspaces (shared, worker, api) → no dangling imports, no references to deleted/renamed symbols, no broken `envBool` import.
- Worker tests **1148/1148** green; API **14/14** green. Matches the #72 commit claim.
- All 77 worker + 3 api test files in `package.json` test scripts exist; **zero missing, zero duplicates**. (PR #67 `1181910` had already removed the 6 non-existent test files that were breaking CI.)

## CHECK 1 — Duplicate / competing implementations: NONE found
- **Two backfills are complementary, not competing.** PR #69 (`b6f3919`) writes `risk_level_at_entry` on the INSERT path for NEW imports (`lookupRiskLevelAtTime`). The size backfill (`95b9096`, Section 7b in `oanda-sync.ts`) repairs ALREADY-CLOSED `size=0` rows from OANDA units. Different regions of the same file, explicitly cross-referenced in the commit msg. No double-apply.
- **Single circuit breaker.** `positionSizeCircuitBreaker` defined once (`strategy-execution.ts:117`), one call site (`:986`). PR #61 added it; PR #67 changed reject→clamp in place. No duplicate.
- **Multiplier bounds + persistence coexist.** `calibrate-weights.ts` carries BOTH `boundedNextMultiplier` (PR #68 `5f309a7`) and `persistEngineMultipliers` (PR `d4c2506`) — neither merge clobbered the other (lines 74/113 + 24/182).
- **Single env-helper set.** One canonical `envBool` in `packages/shared/src/env.ts:27`; `envEnabledUnlessFalse/Falsy` exist only in `apps/worker/src/firm/lib/env.ts` (intentional default-ON idiom from PR #58, not duplicated). Worker re-exports shared `envBool`. No competing copies.

## CHECK 2 — envBool unification (#72): MOSTLY landed; commit claim is OVERSTATED
The #72 commit (`08b74f6`) claims "Replace 48 bare === \"true\" master-flag reads (worker + api)". **Three env master-switches were NOT migrated** and still use raw strict `env.X === "true"` with NO trim/lowercase — i.e. the exact silent-OFF bug #72 set out to kill (`TRUE`/`1`/`yes`/trailing-space → reads as OFF):

- `apps/worker/src/firm/retention.ts:114` — `env.RETENTION_ENABLED === "true"`
- `apps/worker/src/firm/flow-watcher/index.ts:62` — `env.FLOW_WATCHER_ENABLED === "true"`
- `apps/worker/src/firm/foundation-monitor.ts:97` — `env.FOUNDATION_MONITOR_ENABLED === "true"`

Confirmed #72 did not touch these files (last-touched by unrelated commits). Three more flags use trim+lowercase but still only accept literal `true` (no `1/yes/on`): `shadow-log.ts:262`, `trend-following/config.ts:138` (`TF_BLOCK_TUE_SHORT`), `strategy-execution.ts:1003` (`STRATEGY_EXEC_PAPER_ONLY`) — lower severity (whitespace/case already handled).

Impact: LOW. All three default-OFF, so behaviour is unchanged unless an operator sets a non-canonical value (`TRUE`/`1`/trailing space) and expects ON. None are in the `flag-echo.ts` boot-visibility list, so a mis-typed flip on these stays invisible. Not a merge incoherence — it's an incomplete sweep + an inaccurate commit message. No default silently flipped (verified: all migrated reads kept `false` default; helper falls back to caller default).

## CHECK 3 — Half-merged / orphaned code: NONE
tsc-clean across all workspaces is the proof (a dangling import or deleted-symbol reference would fail compile). Shared `index.ts` correctly exports both new modules (`envBool`, `engine-multipliers`).

## CHECK 4 — Merge commits: no silent reverts
15 merges reviewed. The overlapping-file pair (`calibrate-weights.ts` touched by both #68 bounds and the multiplier-persistence PR) retains BOTH edits. No merge dropped one side's change.

## CHECK 5 — package.json test scripts: clean
Worker 77 refs / 77 unique / 0 missing. API 3 refs / 3 unique / 0 missing.

## Recommendation (no action taken — read-only)
Optional follow-up for ai-1/ai-2: migrate the 3 raw-strict reads (`RETENTION_ENABLED`, `FLOW_WATCHER_ENABLED`, `FOUNDATION_MONITOR_ENABLED`) to `envBool(..., false)` to actually fulfil #72's stated scope, and correct the #72 commit's "48 reads" claim. Pure observability/config-hardening, no trade-behaviour change, no Karri gate. Not urgent (all default-OFF).
