# Branch reconciliation plan — `node-migration-nexus` ↔ `main`

Analysis only. No commits, no merge executed. Date: 2026-06-04.
Merge-base: `28242f0`. Railway deploys `main`.

## TL;DR

- **Direction is inverted from the task framing.** `node-migration-nexus` is **19 ahead / 39 behind** `main` (not 39/19). Main has moved on far more than the branch. The branch is the *stale* side for most of the codebase.
- **Recommended path: (c) cherry-pick the 3–4 high-value stranded features to `main` as individual PRs**, same as the circuit breaker was done. Do NOT do a big-bang merge of the branch into main, and do NOT rebase the whole branch.
- **6 real conflicts**, all localized and mechanical. The branch's strategy code does **not** overlap main's biggest new work (FVG strategy, strategy-state DB persistence, lib/env resolver) at all.
- **Single biggest risk:** `strategy-execution.ts` and `orchestrator.ts` **auto-merge with NO conflict markers**, but both sides edited the *same money-near functions* (`maybeExecuteProposal()` — which on main now hosts the hard position-size circuit breaker at lines 934–943, the last broker safety check). A textually-clean auto-merge here can silently reorder or bypass the circuit breaker. This must be eyeballed by Karri, not trusted to git.

---

## 1. Commit inventory

### Ahead — 19 commits on `node-migration-nexus` NOT on `main` (all authored by Nithu0 / ai-1+ai-2 sessions)

| SHA | Type | Who | Summary |
|---|---|---|---|
| e1edfac | fix | ai-2 | shadow outcome filter + sizing characterization tests |
| 8ddb445 | docs | ai | rescind prinsipp 6 (continuous learning governance) |
| 5341fb3 | feat | ai-2 | /learning dashboard panel + /shadow/forward-test endpoint (read-only) |
| 3f35f2a | docs | ai | Railway Worker 230-var inventory |
| 7ec793c | feat | ai-2 | learning-loop primers + shadow forward-test (default OFF) |
| 37e3da8 | feat | ai | ORB replay runner → ohlcv_candles + M1 backfill |
| 1370ea2 | docs | ai | hard-loss bundle env docs + proposal statuses |
| **685164a** | **feat** | **ai-1** | **operator manual-control: live close/modify-SL/modify-TP (default OFF, audited)** ← the live 404 |
| **7110e5c** | **feat** | **ai-1** | **session-breakout selectable SL methodology (SESSION_BREAKOUT_SL_MODE)** |
| **cc02426** | **fix** | **ai-1** | **regime-direction: null-reason logging + flat-band so trend gate isn't a silent no-op** |
| c387dcb | test | ai | decision-cycle/portfolio-brain/briefing coverage + hot-path indexes |
| a9e54f3 | perf | ai | batch N+1 layer-1 lookup in backfillClosedTrades |
| 6e0d103 | docs | ai-1 | proposal: live position manual control |
| 66baa89 | fix | ai | node-compose DATABASE_URL from .env (H1) |
| ec657b2 | chore | ai | sandbox-up.sh + firm8.kdl _bin path fix |
| 310831c | fix | ai | hard-loss sweep: demo crash guard + ORB risk guard + fail-loud gates |
| 9006592 | feat | ai | node-migration: derive-lessons fix + node compose + kill dead URLs |
| 1871260 | fix | ai | 2026-05-25 observability+security sweep |
| ba855dd | docs | ai | 2026-05-24 sweep — C3 gate verified |

**High-value stranded (money-near / operator-visible):** `685164a` (manual-control — fixes the live 404), `7110e5c` (session SL), `cc02426` (regime fix). Everything else is observability / docs / tests / infra (low-risk, can ride along).

### Behind — 39 commits on `main` NOT on the branch (mostly Karri's cleanup wave + FVG)

Dominant themes (authored mostly by `karri`):
- **FVG strategy** (new module): 9884d6d, abdb0aa (confirmation-entry), 43e7d8a + scripts/_fvg_backtest*.mjs (evidence), merges #62/#63.
- **Hard position-size circuit breaker** (PR #61): 2e5cdbf / fff86c4 / 0f4cb44 — the blowup guard.
- **T1–T10 lean-system cleanup wave** (PRs #45–#48, #56–#59): strategy-state DB persistence (ffe68bf, be31867), env-resolver `lib/env.ts` (9197b8c, e4fcba5 = T8 `envEnabledUnlessFalsy`), flow-watcher T10 (19b5271), attribution T2+T3 (11c2863, 0800941, b4eeb37), truth-layer (3fc776e), webhook timeout fix (f1408a3), drift auto-resolve (ca80cad).
- **Strategy tuning** (Karri, proposal-backed): TF M1 reversal-confirm (dd1af69), per-strategy direction-filter / kill-zones (b705c74), TF no_trend LONG override (5d980ae), pullback-continuation min-range (862fd4c).
- **Docs/handoff:** ff3da70 (handoff to Nithu on 3 risk-tasks), proposals.

All 39 are legitimately on main and already deployed. The branch must *receive* these, not overwrite them.

---

## 2. Conflict analysis

13 files touched on both sides. `git merge-tree` dry-run → **6 real conflicts + 7 clean auto-merges**. The 7 auto-merges include two that are textually clean but semantically dangerous.

### Hard conflicts (git emits markers — 6 files)

| File | Risk | Main side did | Branch side did |
|---|---|---|---|
| **`apps/worker/package.json`** | LOW (mechanical) | Added FVG/strategy-state/flow-watcher/lib-env tests to `test` script | Added session-window/demo-mode/orb/operator-control/decision-cycle/portfolio-brain/briefing tests + `--experimental-test-module-mocks` flag | → **union both test lists**; keep main's larger list + branch's extra files + the mocks flag. |
| **`apps/worker/src/firm/session-breakout/config.ts`** | **MEDIUM** | Converted config to **getter** syntax, imports `envFloat` etc. **from `../lib/env`** (T8) | Added SL-methodology params as plain object props, defines `envFloat` as a **local function** in the file | → duplicate-symbol risk. Resolution: keep main's import, drop branch's local `envFloat`, port branch's `slAtrCapMult`/`slSwing*` params into main's getter object. |
| **`apps/worker/src/firm/position-management/manager.ts`** | LOW | Added `import { envEnabledUnlessFalsy }` | Added `import { isPositionOperatorLocked }` | → **keep both imports.** |
| **`apps/worker/src/firm/oanda-sync.test.ts`** | LOW (4 hunks) | Test additions | a9e54f3 batch-lookup test changes | → combine; run tests after. |
| **`apps/worker/src/firm/orb/orb-manager.test.ts`** | LOW (add/add, 1 hunk) | New test file content | New test file content | → reconcile both test bodies. |
| **`apps/worker/src/firm/strategy-execution.test.ts`** | LOW (1 hunk) | Circuit-breaker tests | Branch test changes | → combine; the source-side review (below) matters more. |

### Clean auto-merges that REQUIRE manual review (no markers — git stays silent)

| File | Why dangerous |
|---|---|
| **`apps/worker/src/firm/strategy-execution.ts`** | **HIGHEST RISK.** Both sides edit `maybeExecuteProposal()`. On main this function now contains the **hard position-size circuit breaker (lines 934–943)** — the last safety check before the broker. Branch edits the same function (proposal-execution path, hunks @869–934). Git interleaves them textually but cannot verify the circuit breaker still runs *before* execution and isn't bypassed. **Karri must read the merged function end-to-end.** |
| **`apps/worker/src/firm/orchestrator.ts`** | Both sides add imports + edit the `FirmOrchestrator` class body (branch @252–262 / @507–543; main @334–346 / @495–520). Adjacent edits in `runCycle`-adjacent code. Auto-merged; verify cycle ordering is intact (CLAUDE.md flags `runCycle()` as ground truth). |
| `apps/worker/src/firm/oanda-sync.ts` | Both edited; branch added N+1 batch (a9e54f3), main added drift-resolve. Auto-merged — verify the batch lookup still sees main's attribution changes. |
| `strategy-snapshot.ts`, `orb/orb-manager.ts`, `position-management/manager.ts` (source), `session-break-manager.ts` | Auto-merged cleanly; lower stakes but include in test run. |

### Non-overlap (reassuring)

The branch does **NOT** touch `fvg/*`, `strategy-state/*`, or `lib/env.ts` — main's three largest new subsystems. So the merge surface is much smaller than the raw 39/19 divergence suggests.

---

## 3. Reconciliation strategies + trade-offs

### (a) Merge `node-migration-nexus` → `main` (one big PR)
- **Pros:** single operation; nothing left stranded; preserves branch history.
- **Cons:** drags 19 commits (13 of which are docs/tests/infra) plus the 6 conflicts AND the 2 silent-auto-merge money-near files through in one reviewable unit. Karri has to validate the circuit-breaker interaction inside a 13-file-overlap diff. Hard to bisect if Railway misbehaves post-deploy. Highest blast radius on a money-near `main`.
- **Verdict:** rejected — too much couples to the one PR that touches the broker path.

### (b) Rebase the branch onto `main`
- **Pros:** linear history; branch ends up ahead-only.
- **Cons:** **worst option here.** Replaying 19 commits over 39 means re-resolving the same conflicts *up to 19 times* (each touching commit replays against new main). The session-breakout config getter/local-func clash and the strategy-execution function will conflict repeatedly. High chance of a silently-wrong intermediate state. Also rewrites shared branch history (ai-1/ai-2 both work here) → force-push hazard. Operator-gated and discouraged.
- **Verdict:** rejected.

### (c) Cherry-pick the high-value stranded features to `main` as individual PRs  ✅ RECOMMENDED
- **Pros:** mirrors the proven circuit-breaker workflow (PR #61). Each feature gets its own small, reviewable, revertable-in-30s PR. Karri reviews money-near changes in isolation with the circuit breaker visible. Railway deploys incrementally; easy bisect. The 13 low-risk docs/test/infra commits can be batched into one "housekeeping" PR or skipped. Leaves `node-migration-nexus` to be retired or re-based later at leisure once main has the features.
- **Cons:** 3–4 PRs instead of 1; each cherry-pick of `cc02426`/`7110e5c`/`685164a` will still hit its local conflict (session-breakout config; strategy-execution region) but **scoped to that one feature**, which is exactly what you want for review. Slightly more ceremony.
- **Verdict:** safest given (1) Railway deploys main, (2) money-near systems, (3) the proven precedent, (4) the branch is the *stale* side so a wholesale merge would mostly be re-importing stuff main already has.

---

## 4. Concrete ordered steps — RECOMMENDED PATH (c). DO NOT EXECUTE; operator/Karri gate each PR.

> Each PR is `main` → feature branch → cherry-pick → resolve → `tsc` + `cd apps/worker && npm test` → "OK kjør" → push → PR. Money-near PRs (2,3) auto-send proposal to Karri per CLAUDE.md.

**PR-1 — regime-direction fix `cc02426` (fix, highest operator value, lowest risk)**
1. `git checkout main && git pull && git checkout -b fix/regime-direction-flatband`
2. `git cherry-pick cc02426`
3. Likely clean (regime-direction.ts/.test.ts are branch-only on the source side). If `strategy-execution.ts` is pulled in, **review that the circuit breaker still precedes execution** ⚠️.
4. typecheck + worker tests must stay green. Open PR. Karri reviews (it changes a trade gate's behaviour — was a silent no-op, now logs + flat-band).

**PR-2 — session-breakout SL methodology `7110e5c` (feat, money-near, Karri-gated)**
1. branch from main: `feat/session-breakout-sl-mode`
2. `git cherry-pick 7110e5c`
3. **CONFLICT in `session-breakout/config.ts`** ⚠️: main uses getter syntax + `import {envFloat} from "../lib/env"`; this commit adds a local `envFloat` + plain props. **Resolution:** delete the cherry-picked local `envFloat`, re-express `slAtrCapMult`, `slAtrFloorMult`, `slFloorUsd`, `slSwingBufferAtrMult`, `slSwingLookback` as getters using main's imported helpers. Keep `SESSION_BREAKOUT_SL_MODE` default = `range_edge` (no behaviour change).
4. Also reconcile `session-break-manager.ts` + its test if pulled.
5. Proposal `docs/strategy/proposals/2026-05-13_session_breakout_sl_method.md` already exists → set Status accordingly. Karri-gated (SL methodology = risk).

**PR-3 — operator manual-control `685164a` (+ dep `6e0d103` doc) (feat, write-side to broker, Karri-gated, fixes live 404)**
1. branch `feat/operator-manual-control`
2. `git cherry-pick 685164a` (proposal doc 6e0d103 can ride or be its own trivial commit)
3. Pulls in branch-only files mostly: `apps/api/src/lib/operator-control.{ts,test.ts}`, `apps/api/src/routes/positions.ts`, `firm/position-management/operator-control.{ts,test.ts}`, dashboard `positions/[id]`, Sidebar, api.ts.
4. **CONFLICT in `position-management/manager.ts`** ⚠️ (import line — keep both: `envEnabledUnlessFalsy` AND `isPositionOperatorLocked`). Verify `manager.ts` source auto-merge didn't drop the operator-lock check.
5. Confirms feature flags `MANUAL_POSITION_CONTROL_ENABLED` / `MANUAL_SL_WIDEN_ALLOWED` default OFF (they use raw `=== "true"`, safe). **Note martingale guard:** `MANUAL_SL_WIDEN_ALLOWED` must stay OFF/gated — operator memory flags SL-widening as martingale; route to Karri.
6. After deploy, the live `/positions/.../close|modify` 404 resolves.

**PR-4 (optional) — housekeeping batch (docs/tests/infra, low risk)**
- Cherry-pick or `git checkout origin/node-migration-nexus -- <file>` for: 3f35f2a (var inventory), 8ddb445 (governance doc), c387dcb (test coverage), a9e54f3 (perf), 66baa89 (compose fix), ec657b2 (sandbox), 1871260/ba855dd/310831c (sweeps), 37e3da8 (backtest), shadow/learning observability (7ec793c, 5341fb3, e1edfac, 1370ea2).
- These are default-OFF observability + docs + tests. Can be one PR or dropped. The shadow/learning endpoints are read-only per prinsipp 6 (rescinded) — safe to land without Karri.

**PR-5 (after 1–3 land) — retire or re-sync the branch**
- Once cc02426/7110e5c/685164a are on main, `node-migration-nexus` can be merged main→branch (fast-forward-ish) or reset, so ai-1/ai-2 continue on a branch that contains main's FVG/strategy-state/circuit-breaker work. This closes the divergence permanently. Operator-gated.

### Conflicts the operator/Karri MUST resolve by hand (checklist)
1. ⚠️ **`strategy-execution.ts`** — silent auto-merge; verify circuit breaker (lines ~934–943 on main) still runs *before* broker execution inside `maybeExecuteProposal()`. (Triggered by PR-1 if it pulls the file; definitely review in any merge.)
2. ⚠️ **`session-breakout/config.ts`** — getter-vs-local-`envFloat` clash; port branch SL params into main's getter style (PR-2).
3. ⚠️ **`orchestrator.ts`** — silent auto-merge; verify `runCycle` ordering intact (any PR pulling it).
4. **`position-management/manager.ts`** — keep both imports; verify operator-lock check present (PR-3).
5. **`apps/worker/package.json`** — union the two `test` script lists + keep `--experimental-test-module-mocks` flag (any PR; required for green tests).
6. **`oanda-sync.test.ts` / `orb-manager.test.ts` / `strategy-execution.test.ts`** — combine test bodies; run `npm test` to confirm 478+ stays green.

---

## Answers to the 4 asks

1. **Inventory:** above (19 ahead all Nithu0/ai sessions; 39 behind mostly Karri cleanup + FVG).
2. **Conflicts:** 6 hard + 2 silent money-near auto-merges; characterized above.
3. **Recommendation:** **(c) cherry-pick high-value features as individual PRs** — safest for a money-near `main` that Railway deploys; mirrors the circuit-breaker precedent.
4. **Ordered steps + checklist:** above. Not executed.
