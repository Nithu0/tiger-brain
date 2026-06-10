# Git hygiene — node-migration-nexus disposition + branch cleanup

**Date:** 2026-06-08
**Scope:** READ-ONLY analysis. No git mutation executed. All commands below are PROPOSALS for operator to run after "OK kjør".
**Repo:** `/home/nithu/code/ai-assistent`, branch `main` @ `4e25db6`.

> Note: `git fetch` over SSH failed (`github.com:22` no route — WSL/network). `gh` (HTTPS) works fine. Analysis uses local refs; `origin/main` snapshot lagged local `main` by 2 commits (`fab56f3`, `4e25db6`) which are the cloud-alerts work — treat local `main` as authority.

---

## 1. Still-stranded on node-migration-nexus (NOT on main)

`node-migration-nexus` @ `c8e137e` (last commit 2026-06-05) is **25 ahead / 73 behind** main. `git cherry main node-migration-nexus` confirms both 2026-06-07 candidates are still `+` (no patch-equivalent on main):

| Commit | Subject | On main? | Still valuable? |
|---|---|---|---|
| `c6a6b03` | feat(backtest): ORB replay runnable on existing 15min data + actionable empty-data error + runbook | **NO** | **YES** |
| `a9e54f3` | perf(oanda-sync): batch N+1 layer-1 lookup in backfillClosedTrades | **NO** | **YES** |

**Verification (genuinely absent, not superseded):**
- `c6a6b03`: main's `apps/api/src/backtest/runner.ts:49` still has `const CANDLE_TIMEFRAME = process.env.BACKTEST_CANDLE_TIMEFRAME ?? "1min"` — the broken default that throws "no data" because the firm only persists 15min. `docs/ops/backtest-runbook.md` does **not exist** on main. So the runnable-today fix + runbook are genuinely stranded.
- `a9e54f3`: main's `apps/worker/src/firm/oanda-sync.ts` has **no** `oanda_trade_id = ANY($1)` batch query — the N+1 (up to 200 per-row SELECTs) is still present. Genuinely stranded.

The other 23 commits on the branch are node-migration/security-sweep/node-compose infra that main has moved past via its own path; not in scope to rescue (operator already landed the relevant pieces through #65/#73/#74/#76 and the node-deploy work via command-center PR #77). Only the two above are isolated, still-valuable, non-strategy fixes.

---

## 2. Cherry-pick feasibility (simulated via `git merge-tree --write-tree`, read-only)

### c6a6b03 (backtest) — CLEAN
Cherry-pick simulation onto main produced a clean result tree, zero conflicts.
Files: `apps/api/src/backtest/{runner.ts,runner.test.ts}`, `apps/api/src/routes/backtest.ts`, `docs/ops/backtest-runbook.md` (+6 tests).

```
git checkout -b rescue/backtest-15min-runnable main
git cherry-pick c6a6b03
cd apps/api && npm test    # verify green
```
No conflicts expected. Pure API-side; no strategy/risk/gate/sizing change → no Karri proposal needed (observability/tooling).

### a9e54f3 (oanda-sync N+1) — ONE CONFLICT, test-file only
Cherry-pick simulation: production file `apps/worker/src/firm/oanda-sync.ts` **auto-merges clean**; conflict is confined to `apps/worker/src/firm/oanda-sync.test.ts` (main added tests in the same region this session).

```
git checkout -b rescue/oanda-sync-n1-perf main
git cherry-pick a9e54f3
# CONFLICT: apps/worker/src/firm/oanda-sync.test.ts  (likely the only conflicted file)
# resolve by keeping BOTH main's new tests and the 4 N+1 batch tests
git add apps/worker/src/firm/oanda-sync.test.ts
git cherry-pick --continue
cd apps/worker && npm test    # 478/478 + the +4 batch tests must stay green
```
Likely conflict file: **`apps/worker/src/firm/oanda-sync.test.ts`** (only). Behavior-identical perf fix; no strategy/risk/gate/sizing/BROKER_MODE change → no Karri proposal.

**Recommendation:** rescue BOTH via small focused PRs (or one combined `rescue/node-migration-stragglers` branch). c6a6b03 is free; a9e54f3 needs a 5-min test merge.

---

## 3. PR #60 (node-migration-nexus) disposition

**State:** OPEN, base `main`, mergeable UNKNOWN, 25 ahead / 73 behind, untouched since 2026-06-04.
Title: "Node migration: security sweep + node-compose + derive-lessons/N+1 fixes".

**Recommendation: CLOSE-AND-ARCHIVE** — but ONLY after the two cherry-picks in §2 land.
- The branch is 73 behind; merging it would drag in a huge stale delta and re-conflict against everything that landed in #65/#73/#74/#76 + cloud-alerts. Not worth re-basing.
- The derive-lessons + most security-sweep pieces it advertises already landed on main via other PRs.
- The only unique, still-valuable content is `c6a6b03` + `a9e54f3`. Once those are cherry-picked, nothing else on the branch needs rescuing.

**Proposed sequence (operator-gated):**
1. Cherry-pick c6a6b03 + a9e54f3 → small PR(s) → merge.
2. `gh pr close 60 --comment "Superseded — unique fixes (c6a6b03 backtest-15min, a9e54f3 oanda N+1) cherry-picked to main in #<NN>; remaining commits stale (73 behind) and landed via #65/#73/#74/#76 + command-center #77."`
3. Optionally keep the branch ref as an archive tag before deleting: `git tag archive/node-migration-nexus c8e137e` (so history is recoverable without an open PR). Branch delete is operator-gated.

Do NOT delete the branch until the tag exists and the cherry-picks are merged.

---

## 4. Other branch hygiene

### 4a. `worktree-agent-*` local branches (20) — SAFE TO PRUNE
All 20 are `ahead=0` vs main (merged/equivalent), leftover from this session's parallel-agent worktrees. 15 of their worktrees are already gone; 5 are still registered + **locked** (active followup work, see 4b). 
- Prune candidates: the 20 `worktree-agent-*` *branches* are safe once their worktree (if any) is removed. Proposal (operator-gated, branch delete = gated):
  ```
  git worktree prune
  git branch | grep '^  worktree-agent-' | xargs -r git branch -D    # after confirming none locked
  ```
  Caution: 5 are bound to locked worktrees — `git worktree list` shows which. Remove the worktree first or skip those branches.

### 4b. `followup/*` + `feat/cloud-alerts-v2` — NOT stale, leave alone
These 6 branches are **unmerged with real unique commits** AND tied to **locked active worktrees** — they are live in-progress this session, not the post-merge leftovers the task expected:
- `followup/audit-allowlist-trim` (2 ahead) — AUDIT_ALLOWLIST trim + thesis-scores wiring
- `followup/firm-signal-rejections-endpoint` (1) — /firm/signal-rejections endpoint
- `followup/health-cycles-per-hour` (1) — /health cyclesPerHour metric
- `followup/strategy-state-publisher-fields` (3) — strategy-state observability fields
- `followup/thesis-score-join` (1) — thesis-score DECISION payload
- `feat/cloud-alerts-v2` (1) — its single commit `3caeb0b` == main's `fab56f3` (cloud-alerts already landed); branch is otherwise behind main. **Effectively superseded** — safe to delete after operator confirms no extra work is staged on it.

These followups should each become a PR + merge, then auto-delete. Don't force-clean them now.

### 4c. `feat/cloud-alerts` (local, merged) — safe to delete
`main..feat/cloud-alerts` is empty (fully merged). `git branch -d feat/cloud-alerts` (gated).

### 4d. Stale open PRs against `cleanup/lean-system` base
`gh pr list` shows #28, #50, #52, #53 — three (#50/#52/#53) target base **`cleanup/lean-system`**, not main, and are old. #28 (C3 direction-flip gate) targets main but is a strategy gate → Karri's call. These are out of scope for this task but flagged: the `cleanup/lean-system` stack looks abandoned; recommend operator decide rebase-to-main-or-close in a separate pass.

### 4e. `backup/ai-1-pre-rebase-2026-05-21` @ `c0d6fb0` — keep
Intentional backup ref from a rebase. Low cost; keep until operator is sure it's not needed. Not git-hygiene noise.

---

## Summary (for relay)

- **Still-stranded + valuable:** `c6a6b03` (backtest 15min-runnable + runbook) and `a9e54f3` (oanda N+1 perf). Both genuinely absent from main, both verified not superseded.
- **c6a6b03 → cherry-pick CLEAN.** `a9e54f3 → cherry-pick conflicts only in `oanda-sync.test.ts`** (prod file auto-merges); keep both test sets.
- **PR #60 → close-and-archive** after the two cherry-picks land + tag `archive/node-migration-nexus`. Nothing else on the branch worth rescuing.
- **20 `worktree-agent-*` branches:** safe prune (all merged). **6 `followup/*` + cloud-alerts-v2:** live/superseded, leave for normal PR-merge-delete flow. Stale `cleanup/lean-system` PR stack flagged for a later pass.
- No mutation executed. All commands above are operator-gated proposals.
