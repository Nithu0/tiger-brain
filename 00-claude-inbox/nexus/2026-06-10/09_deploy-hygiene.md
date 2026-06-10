# Deploy hygiene audit — Nexus XAUUSD

Date: 2026-06-10
Scope: READ/ANALYSIS + safe git inspection only. No merges/pushes/prunes performed — all actions below are PROPOSALS for operator.

---

## 1. Deployed == current?

**YES.** Live build `f4bfadf` == `origin/main` HEAD == `f4bfadf` (`Merge PR #92: narrow risk-gate to high+extreme`). Deployed = current. Verified after `git fetch origin`.

Caveat (not a deploy problem, a workspace-hygiene note): the **main checkout is NOT on `main`**. The primary working dir `/home/nithu/code/ai-assistent` is on branch `fix/firehose-script-path` (`676c222`), which is *behind* origin/main (it predates ~27 commits of main; main itself has merged past it). `origin/main` (f4bfadf) is checked out in the locked agent worktree `agent-a424eb780b4d0f190`. Local `main` branch ref is stale at `4ffbe52` (ahead 4 / behind 27). None of this affects the deployed artifact, but the main pane is not where you'd expect.

---

## 2. Two stranded fixes — still absent? still worth it?

Both **STILL ABSENT** from origin/main. Both **still worth landing** — verified main does NOT already contain equivalent content.

### a9e54f3 — perf(oanda-sync): batch N+1 layer-1 lookup
- **Still relevant: YES.** Confirmed main's `backfillClosedTrades()` STILL runs the per-row N+1 pattern: `for (const t of closedTrades) { ... SELECT id FROM simulated_orders WHERE oanda_trade_id = $1 LIMIT 1 }`. The fix replaces this with a single `WHERE oanda_trade_id = ANY($1)` batched query + Set lookup. Real perf win on reconcile/backfill paths.
- **Conflict risk: MEDIUM.** Clean dry-run cherry-pick onto origin/main CONFLICTS in **`apps/worker/src/firm/oanda-sync.test.ts`** only (`oanda-sync.ts` auto-merges clean; the file has drifted in main via 95b9096 size-backfill + b6f3919 risk_level backfill, but not in the layer-1 region). One test-file conflict to resolve by hand.
- **Recipe:**
  ```bash
  git checkout main && git pull        # get to f4bfadf
  git checkout -b rescue/oanda-n1-perf
  git cherry-pick a9e54f3
  # resolve conflict in apps/worker/src/firm/oanda-sync.test.ts (keep both: batched-assertion + main's newer cases)
  git add apps/worker/src/firm/oanda-sync.test.ts && git cherry-pick --continue
  cd apps/worker && npm test          # confirm green before push
  ```

### c6a6b03 — feat(backtest): ORB replay runnable on 15min data + runbook
- **Still relevant: PARTIALLY — verify before landing.** The runbook `docs/ops/backtest-runbook.md` is ABSENT from main → that doc is pure-add, worth keeping. BUT the code premise has drifted: main's `backtest/runner.ts` was **repointed to `ohlcv_candles` + M1 backfill** (commits 42062e8, eda66ba) AFTER c6a6b03. c6a6b03's "runnable on existing 15min data" path may now be superseded by the M1/ohlcv runner. The cherry-pick applies CLEANLY (no conflicts — main hasn't touched these exact lines in a way git flags), but a clean apply does NOT mean semantically correct: it could re-introduce a 15min code path that the M1 repoint intentionally replaced.
- **Conflict risk: LOW (textual) / MEDIUM (semantic).** Recommend: land the **runbook doc** unconditionally; **review the runner.ts/backtest.ts hunks against the new ohlcv runner** before taking them — they may be redundant or regressive.
- **Recipe (doc-safe, code-gated):**
  ```bash
  git checkout main && git pull
  git checkout -b rescue/backtest-runbook
  git cherry-pick --no-commit c6a6b03
  # KEEP: docs/ops/backtest-runbook.md
  # REVIEW vs main's ohlcv/M1 runner before keeping: runner.ts, runner.test.ts, routes/backtest.ts
  #   git restore --staged apps/api/src/backtest/runner.ts ... if superseded
  git commit
  cd apps/api && npx tsc --noEmit
  ```

---

## 3. PR #60 (node-migration-nexus) disposition

- State: **OPEN**, mergeable: **CONFLICTING**. 25 commits ahead of main, **100 behind**. Last updated 2026-06-04. Title: "Node migration: security sweep + node-compose + derive-lessons/N+1 fixes".
- 100-commits-behind + CONFLICTING = a full merge is not viable; it would be a massive reconciliation against a main that has moved a long way.
- The two stranded fixes (a9e54f3, c6a6b03) live ON this branch — they are the still-valuable cargo. The branch head `c8e137e` (OANDA-computed ADX/ATR fallback, default OFF) may also be worth a look, plus the "security sweep" commits if any are unmerged.

**Disposition: RESCUE-FIRST, then close.** Do NOT blind-close — cherry-pick the still-valuable commits (per §2, plus audit c8e137e ADX/ATR fallback + security-sweep commits for anything unmerged), then close PR #60 with a comment pointing at the rescue branches/PRs. Archive the branch after (tag or just rely on PR history). A straight close would orphan a9e54f3's live N+1 fix.

Suggested follow-up: `git log --oneline origin/main..origin/node-migration-nexus` (25 commits) → triage each as {already-in-main-equiv / rescue / drop}.

---

## 4. Shared local working tree — uncommitted / orphaned work

**At audit START** the shared tree showed ~30 modified/deleted files (FVG config, firehose, derive-lessons, phase-status, proposals, etc.). **By mid-audit a parallel session committed them** — the tree is now clean except 3 untracked files. (The first `git status` snapshot was stale; a concurrent firm pane was mid-commit.)

**Remaining 3 untracked files — all byte-IDENTICAL to already-committed branch work (NOT lost, just duplicate copies left in the shared tree):**

| File | Identical to commit | Owning branch |
|---|---|---|
| `apps/api/src/routes/firm-memory-strategy-states.test.ts` | `626ab29` | `fix/wf-replenish-1-strategy-states-adx-from-h1` |
| `docs/strategy/proposals/2026-06-08_remove-reversi.md` | `e675335` | `docs/ops-brief-reversi-0608` |
| `docs/ops/2026-06-08_operator-action-brief.md` | `e675335` | `docs/ops-brief-reversi-0608` |

**Verdict: NO orphaned/lost work.** All three are safe to `rm` (their content is committed on the branches above) OR leave — they cause no harm. I did NOT touch them (owner: parallel sessions). Flag to the owning panes that their copies are dangling in the shared root.

Note: the main pane sitting on `fix/firehose-script-path` rather than `main` is the root cause of these phantom copies — parallel agents wrote files into the shared root while their real work lived in worktrees/branches.

---

## 5. Stale branches / worktrees to prune (PROPOSAL — operator-gated, destructive)

**Worktrees:** 20 active worktrees. Several are **LOCKED with live agent PIDs (1079, 1163, 1165)** — `agent-a424...`, `a7852...`, `a927...`, `aaea...`, `ac570...`, `ae215...`, `ae8ae...`, `aeea8...`. **DO NOT prune locked/live ones.**

Safe-prune candidates (unlocked, branch merged into origin/main):
- `agent-a04a57f99304852a5` (cleanup/t6-nan-guards — merged)
- `agent-a2e5311cddb8a7dcb` (docs/t7-doc-reconcile — merged)
- `agent-a33c1ed3d46c91ec3` (fix/regression-predictor-attribution — check merged)
- `agent-a9ced8b0d19ddadad` (detached, on origin/cleanup/t7-legacy-cleanup)
- `agent-af6b1faec8b70c20e` (integrate/t6-t11 — ahead 6/behind 27, NOT fully merged → keep)
- `/tmp/nexus-verify-952918`, `/tmp/wf-replenish-1`, `wf_396e626f-4a3-4`, `wf_396e626f-4a3-7`

Recommended (run ONLY after confirming no live agent owns them):
```bash
git worktree prune                       # drops worktrees whose dir is gone
git worktree list                        # re-verify nothing locked/live removed
# then per unlocked-merged worktree:
git worktree remove <path>
```

**Branches:** 33 `worktree-agent-*` / `worktree-wf_*` throwaway branches are merged into origin/main → prunable. Real WIP (DO NOT prune): the `fix/wf-replenish-*`, `feat/wf-knowledge-ingest-*`, `followup/*`, `cleanup/*`, `docs/*` set (~33 unmerged branches) — these are live parallel-session work.

```bash
# throwaway worktree-* branches only (merged):
git branch --merged origin/main | grep -E 'worktree-(agent|wf)' | xargs -r git branch -d
```

No remote-gone tracking branches found (nothing to prune from `: gone]`).

---

## Action summary for operator

1. Deployed == current: YES (f4bfadf).
2. Rescue a9e54f3 (N+1, MEDIUM conflict, test-file only) — still a real fix.
3. Rescue c6a6b03 runbook unconditionally; gate its runner code vs main's new ohlcv/M1 runner.
4. PR #60: rescue-first (25 ahead/100 behind, CONFLICTING) then close + archive — do not blind-close.
5. 3 dangling untracked files in shared root = duplicates of committed branch work, no loss. Owner panes should clean up.
6. Worktree/branch prune is destructive + several worktrees are LIVE-LOCKED — operator-gated; recipe above.
