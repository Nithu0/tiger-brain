# WF PR-Triage (READ-ONLY) — 2026-06-08

Lane: pr-triage. No merges, closes, rebases, or pushes performed. Recommendations only.
Main HEAD at triage time: `6e35118a` (PR #79 merged).

## TL;DR per-PR

| PR | Title | Base | Mergeable | Recommendation |
|----|-------|------|-----------|----------------|
| #78 | entry-quality fixes SB/scalp/ORB (ai-1) | main | CLEAN | **HOLD for ai-1 + Karri** — strategy entry code; not my call. Mergeable now but needs Karri sign-off on strategy proposal doc. |
| #75 | stability: flag-parse hardening + /health weekend | main | CONFLICTING (1 file) | **REBASE** — trivial conflict (apps/api/package.json test-registry). Content still net-new + valuable. |
| #60 | node-migration + security sweep | main | CONFLICTING (19 files) | **REBASE (big)** — substantial but valuable; some real code conflicts. Split or resolve carefully. |
| #53 | T9 proposal: remove reversi | cleanup/lean-system | CLEAN | **RETARGET base → main** then merge. Base branch already absorbed into main. |
| #52 | T11 integration tests | cleanup/lean-system | CONFLICTING (1 file) | **RETARGET base → main + rebase** — trivial conflict (worker package.json). |
| #50 | T6 NaN/bounds guards | cleanup/lean-system | CONFLICTING (2 files) | **RETARGET base → main + rebase** — package.json + managers.ts. |
| #28 | C3 cross-strategy direction-flip gate | main | CONFLICTING | **CLOSE — superseded by main.** |

## Key cross-cutting finding

`cleanup/lean-system` was **already merged into main** via PR #56 (2026-06-03, merge into main). It now has **0 commits not in main** (fully absorbed). PRs #53/#52/#50 still target it as base — a stale, fully-merged branch. Their *content* is NOT yet on main, so they're still valid work; they just need base retargeted to `main` (and a rebase for the two that conflict).

## Per-PR detail

### #78 — entry-quality (feat/entry-fixes-all) — HOLD (ai-1 + Karri)
- 11 files, +169/-2, 1 commit. mergeStateStatus CLEAN, MERGEABLE.
- Touches strategy entry managers: `orb/orb-manager.ts`, `scalp-overlap/scalp-manager.ts`, `session-breakout/session-break-manager.ts` + configs, plus proposal doc `docs/strategy/proposals/2026-06-08_entry-fixes-all-strategies.md`.
- All changes claimed default-off (new `SB_NO_CHASE_ATR` default 0, `VOL_EXP_NO_CHASE_ENABLED` etc.), 1154/1154 tests green.
- **My lane constraint:** this is ai-1's PR + strategy/risk territory (Karri owns). I do NOT opine on the strategy logic. Triage verdict: mechanically mergeable, but gated on Karri approval of the proposal doc before merge. Defer to ai-1.

### #75 — stability follow-up (fix/stability-followup) — REBASE
- 12 files, +247/-16, 2 commits. CONFLICTING.
- Conflict: **only `apps/api/package.json`** — the `test` script line. Both main and the PR added test files to the registry concurrently (main added `health.test.ts`; PR's version has `risk-snapshot.test.ts` + `weaknesses-firm-activity.test.ts`). Trivial union-merge resolution.
- Content value: hardens 8 master flags (`RETENTION_ENABLED`, `FLOW_WATCHER_ENABLED`, `FOUNDATION_MONITOR_ENABLED`, `FIREHOSE_DIGEST_ENABLED`, `AGENT_LESSONS_ENABLED`, `LESSON_DERIVATION_ENABLED`, `DEMO_AUTO_DEGRADE_ENABLED`, `DISCORD_CLARITY_ENABLED`) onto shared `envBool`. main already has `envBool` (PR #72 D1) but these 8 flags were missed — verified still raw-parsed risk. **/health weekend tolerance is genuinely NOT on main yet** (grep confirms absent) — net-new.
- Recommendation: rebase onto main (resolve the one package.json line by keeping all test files), then merge. Behaviour-neutral, all flags default-OFF.

### #60 — node-migration (node-migration-nexus) — REBASE (large)
- 100 files, +9918/-227, 25 commits. CONFLICTING — **19 conflicted files** on dry-run merge.
- Conflicts include real code, not just churn: `apps/worker/src/firm/calibration.ts`, `position-management/manager.ts`, `services/market-data.service.ts`, `polygon-fallback.service.ts`, `apps/api/src/routes/calibration.ts`, `backtest/runner.ts`, `derive-lessons.mjs`, plus both package.json test-registries and several docs.
- PR body acknowledges "main diverged +27 (PR #56/#57/#58)... resolve on merge" — that divergence has grown further since.
- Overlap risk: claims "/health weekend-aware" — same feature as #75. If #75 lands first, dedupe in #60's rebase. Also touches `session-breakout/config.ts` which #78 (ai-1) also touches → coordinate ordering.
- Recommendation: rebase onto current main. Given 19 conflicts + 9.9k lines, consider splitting (security-sweep commits + derive-lessons fix are independently valuable and smaller). Money-safety claim: no strategy/risk/gate change, BROKER_MODE untouched — consistent with my read of the file list. Needs a careful human/agent resolution pass; do not auto-merge.

### #53 — T9 remove-reversi proposal (cleanup/t9-proposal-doc) — RETARGET → main
- 1 file, +155, docs-only (`docs/strategy/proposals/2026-06-02_t9_remove_reversi.md`). Not on main yet.
- Dry-run merge into main: **CLEAN.**
- Recommendation: retarget base from `cleanup/lean-system` to `main`, then it merges cleanly. Pure proposal doc (Karri territory for the actual reversi-removal decision, but the doc itself is safe to land). NB: a `docs/strategy/proposals/2026-06-08_remove-reversi.md` exists in the working tree (another lane's WIP) — check for content overlap/dupe before landing.

### #52 — T11 integration tests (cleanup/t11-integration-tests) — RETARGET + rebase
- 4 files, +305/-1, test-only (`test-integration/env-toggle|lib-env|restart-state.test.ts`). Not on main.
- Conflict: **only `apps/worker/package.json`** (test registry). Trivial.
- Recommendation: retarget base → main, rebase the one package.json line. Tests only, safe.

### #50 — T6 NaN/bounds guards (cleanup/t6-nan-guards) — RETARGET + rebase
- 4 files, +60/-6. Not on main (`lib/nan-guard.test.ts` absent on main).
- Conflicts: `apps/worker/package.json` (registry) + `apps/worker/src/firm/managers.ts` (real code — bounds-guards on WORKER_CONCURRENCY + regime SL/TP).
- NOTE: regime SL/TP guards touch risk-adjacent values. Behaviour-neutral guards (NaN→fallback) are fine, but if any bound changes an effective threshold, that's Karri territory — verify on rebase the guards only reject NaN/out-of-range, not retune defaults.
- Recommendation: retarget base → main, rebase, review managers.ts conflict carefully for the risk-adjacency above.

### #28 — C3 cross-strategy direction-flip gate — CLOSE (superseded)
- 5 files, +605/-1, 1 commit. CONFLICTING.
- **The gate already landed on main** via a separate commit `46434cf` ("feat(gates): cross-strategy direction-flip gate (Karri C3 — shadow + hard modes)"). File `apps/worker/src/firm/gates/cross-strategy-direction-flip-gate.ts` exists on main.
- PR #28's head `45ec672c` is NOT an ancestor of main → the equivalent work was re-landed independently, leaving #28 as a stale duplicate (hence the conflict on the gate file itself + package.json).
- Recommendation: **close as superseded by main.** Before closing, a 2-min diff of #28's gate vs main's version would confirm no unique logic was dropped — but functionally the C3 gate is live on main.

## Ordering suggestion (if operator approves a merge pass)
1. #53 (clean docs) → 2. #52, #50 (small test/guard, retarget+trivial rebase) → 3. #75 (stability, trivial rebase) → 4. #78 (after Karri OK, ai-1 drives) → 5. #60 (big rebase, dedupe /health weekend + session-breakout vs whatever landed) → close #28.

## Constraints honored
- No merges/closes/rebases/pushes executed. Local dry-run merges only, all aborted; working tree restored (pre-existing uncommitted WIP from another lane preserved untouched).
- Did not edit any ADX/regime/indicator code (ai-1 owns). Did not edit strategy/risk/gate logic. No Railway env touched.
