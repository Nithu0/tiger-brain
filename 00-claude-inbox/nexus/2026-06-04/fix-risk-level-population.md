# Fix: risk_level_at_entry population (data-quality, NOT a strategy change)

Date: 2026-06-04
Branch: node-migration-nexus
Scope: data-quality / observability. NO gate behaviour or default changed.
Trigger: Karri flagged RISK_LEVEL_HARD_GATE can't be re-enabled because
`risk_level_at_entry` is NULL on ~150/173 trades. "Fix the population FIRST."

## Root cause of the ~86% NULL rate

Two compounding bugs, both in `apps/worker/src/firm/strategy-execution.ts`
(the TIER 3 entry-stamp path). The producer itself is fine.

1. **Producer/consumer cycle-ordering mismatch (the dominant cause).**
   - Producer: `runRiskAnalysis` (analysis-agents.ts:553) publishes
     `xauusd.analysis.risk` with `state.riskLevel` — always a non-null value
     (`normal|elevated|high|extreme`). It runs in the orchestrator's
     **Step 2** (`runAllAnalysisAgents`, orchestrator.ts:594).
   - Consumer: `runStrategyExecution` reads that topic and stamps it, but runs
     in **Step 1f** (orchestrator.ts:571) — BEFORE Step 2.
   - So every entry reads the **previous cycle's** risk message, aged by one
     `fullCycleIntervalMs`.
   - That interval is 30–120s in active sessions but **300s / 600s / 3600s** in
     low-liquidity / off-hours / closed sessions (session-window.ts:227,230,233,236).
   - The old read window was `latest("xauusd.analysis.risk", 300)`. Whenever the
     cycle interval met/exceeded 300s, the prior message had already aged past
     the 300s SQL window → `latest()` returned `null` → NULL stamp. This exactly
     matches an ~86% NULL rate skewed toward off-peak sessions.

2. **Silent null + a redundant, test-breaking re-check.**
   - The block had an empty `catch {}` and **no else branch**: missing/stale =>
     NULL with zero log. Invisible. (The sibling `portfolio.context` block one
     section up DOES warn — the risk block never got the same treatment.)
   - It also re-checked `riskMsg.freshnessSeconds <= 300` after `latest()` had
     already filtered by maxAge in SQL — redundant in prod, and it silently
     dropped the value whenever `freshnessSeconds` was unset/over-window.

## The fix (data-only; gate untouched)

`strategy-execution.ts`, the `xauusd.analysis.risk` read block (was lines
845–850):
- Widened the read window 300s → 600s (`RISK_LEVEL_FRESHNESS_SEC = 600`) to
  match the `portfolio.context` block above. The `latest()` SQL maxAge is the
  real freshness guard.
- Dropped the redundant `freshnessSeconds <= 300` re-check.
- Added explicit WARN branches: (a) message present but `riskLevel` field empty,
  (b) message missing within the window, (c) read threw. NULL is now VISIBLE
  per operator-prinsipp 1 (report, don't guess).
- The value still flows into BOTH stamp paths unchanged:
  - OANDA-fill UPDATE param `$10` (`risk_level_at_entry`)
  - paper-only UPDATE param `$5` (`risk_level_at_entry`)
  - legacy alias `regime_at_entry` continues to mirror it.

Note: this widens coverage materially but does not make 3600s closed-market
entries always populate (one cycle of 3600s still > 600s). That's acceptable —
the market is closed, no real entries fire there; the WARN now makes any genuine
gap auditable instead of silent. If Karri later wants 100%, the clean fix is to
reorder analysis before strategy-execution OR publish risk at cycle start; that
is a cycle-ordering change and was intentionally NOT done here (out of scope,
could shift other consumers' timing).

## What was NOT touched (verified)

- `RISK_LEVEL_HARD_GATE_ENABLED` flag — unchanged (still default false,
  gates/new-gates.ts:112).
- Gate evaluation logic — `git diff HEAD apps/worker/src/firm/gates/new-gates.ts`
  is empty.
- `strategy-blade.ts` risk-gate wiring — empty diff.
- Producer `analysis-agents.ts` — untouched.
- No env var, no default, no threshold changed.

## Files + lines changed

- `apps/worker/src/firm/strategy-execution.ts` — replaced the
  `xauusd.analysis.risk` read block (previously ~845–850): widened window,
  removed re-check, added 3 WARN branches + explanatory comment.
- `apps/worker/src/firm/strategy-execution.test.ts` — +3 node:test cases:
  1. stamps `risk_level_at_entry` (=elevated) + legacy `regime_at_entry` mirror
     when `analysis.risk` present.
  2. stamps NULL **and** emits a WARN (captured via `console.warn`) when the
     topic is missing.
  3. no-regression: risk stamp doesn't shift strategy_id/execution_source/atr/
     conviction off their param indices.

## Verification

- `cd apps/worker && npx tsc --noEmit`: my two files compile clean (0 errors).
  The only tsc errors in the tree are pre-existing notifications WIP
  (formatter.ts / topic-freshness.ts / types.ts) that were uncommitted before
  this task and are unrelated — confirmed by stashing them (errors moved with
  the stash).
- `cd apps/worker && npm test`: **1167 pass / 0 fail** (was 1164 before; +3 new).
  New tests confirmed running + green; WARN observed in test output for paths
  without a risk message.

## Handoff note

The handoff doc path Karri referenced
(`docs/ops/handoff-nithu-3-risk-tasks-2026-06-04.md`) does not exist in the repo
at task time — only the two May handoffs are present in docs/ops/. Worked from
the task brief directly. Worth confirming the doc lands / the other 2 risk tasks.

NO commit / push / Railway per instruction.
