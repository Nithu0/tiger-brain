# Codex Phase 2a Production Readiness Assessment

**Date:** 2026-05-11  
**Verdict:** WAIT-30D  
**Air-gap status:** Hardened (7-prefix guard verified in both runners)  
**Auto-merge:** No (PR opener requires manual merge)

---

## 1. Air-gap robustness (7-prefix trading-loop guard)

**Status: HARDENED**

Both scripts share identical guards at code-level:

**Codex runner** (`scripts/agent-codex-runner.mjs` lines 90–98):
```javascript
const TRADING_LOOP_PREFIXES = [
  "apps/worker/src/firm/orb/",
  "apps/worker/src/firm/scalp-overlap/",
  "apps/worker/src/firm/session-breakout/",
  "apps/worker/src/firm/vol-expansion/",
  "apps/worker/src/firm/strategy-execution",
  "apps/worker/src/firm/strategy-blade",
  "apps/worker/src/firm/orchestrator",
];
```

Enforcement: `enforceTradingLoopGuard()` (lines 271–285) runs **before** spawning codex. Refuses unless task prompt contains literal `TRADING_LOOP_OK` marker.

**PR opener** (`scripts/agent-pr-opener.mjs` lines 66–74, applied at open time):
- Extracts touched files from diff via `extractTouchedFiles()`
- Re-checks against identical 7 prefixes
- If match found → records `pr_skipped` reason=`trading_loop_guard`, does NOT open PR
- Defense-in-depth: codex-runner already refused, but if the guard drifts, PR opener catches it

**Allowed without marker:** Everything outside the 7 prefixes (docs, config, tests, non-firm modules).

**Blocked without marker:** Any `context_refs` pointing at the 7 paths + any task whose diff touches them.

---

## 2. PR review path

**Status: NO AUTO-MERGE (safe pattern)**

Sequence:
1. Codex runner creates diff, stores in `agent_artifacts` (kind=diff), marks task done
2. Auto-emits `role=review` task (if `AGENT_AUTO_REVIEW=true`, default yes)
3. Claude review-runner evaluates diff, sets `agent_results.review_verdict` to one of: `approved|changes_requested|rejected`
4. **PR opener ONLY runs on approved tasks** (line 115 of agent-pr-opener.mjs: `WHERE r.review_verdict = 'approved'`)
5. When PR opened, it requires human review on GitHub before merge — no auto-merge webhook configured
6. Operator explicitly merges after reading diff + review notes

**Critical safeguard:** PR body (lines 248–252) states:
> "**Operator merge required.** This PR was opened automatically because the Claude review verdict was `approved`, but per operator-prinsipp 5 ("OK kjør" gate before each push) and the agent-bus charter, **no auto-merge**."

This is correctly gated. No deal-breaker.

---

## 3. Failure modes

**Case: Codex generates broken code**

| Scenario | Handler | Outcome |
|---|---|---|
| `codex exec` returns exit code ≠0 | Catch at line 153–155: throw + catch block → worktree removed, task marked `failed` | ✅ Safe: no orphan branch |
| Diff captures but `tsc --noEmit` fails (if runner invoked it) | Would happen inside the worktree; codex would still return 0. Diff would be captured, review task emitted. Claude would see broken TS in diff + likely `changes_requested`. | ⚠️ Partial: relies on reviewer catching it |
| Tests fail inside worktree | Same as above — doesn't block diff capture; reviewer catches. | ⚠️ Partial: review must be thorough |
| PR opener crashes mid-git-commands | Lines 191–213 have no try-catch around git/gh commands. If `git push` succeeds but `gh pr create` crashes, branch exists on origin but PR entry is not created. Audit trail incomplete. | 🔴 **Gap:** orphan branch possible |
| Worktree exists but diff is empty | Handled: status='partial', summary='codex completed but produced no edits'. No review task emitted (line 228: `if (AUTO_REVIEW && diff.trim())`). | ✅ Safe |

**Gap identified:** PR opener (lines 191–213) lacks error handling around git operations. If any step fails after checkout, the worktree is left in an inconsistent state. Remediation: wrap in try-catch, record failure + audit event, do NOT proceed to next step.

---

## 4. Cost cap in place

**Status: NO CAP**

Token tracking fields exist in schema (`cost_usd`, `tokens_in`, `tokens_out`) but:
- Codex runner **hardcodes all to 0** (lines 202, 370)
- No actual cost calculation from `codex` CLI output
- No rate-limit check, no daily budget enforcement, no hard cutoff

**Risk:** If operator enables on Railway without understanding Codex token pricing, an uncapped loop of high-token-cost tasks could accumulate before someone notices.

**Remediation needed before prod:** 
- Parse `codex` CLI stderr/stdout for token count + pricing info
- Implement per-role daily budget in env vars (e.g., `AGENT_CODEX_DAILY_BUDGET_USD=50`)
- Refuse new tasks if daily total exceeded (check at `claimNextTask` time)

Currently: **budget mechanism absent.**

---

## 5. Task queue: how do code-tasks get enqueued?

**Status: MANUAL ONLY**

Sources of tasks:
- `scripts/agent-task.mjs create` (local CLI, operator invokes)
- `scripts/firm/ralph.mjs --role=blade` (local zellij pane, operator runs manually)
- Phase 5: `apps/worker/src/firm/agent-bus/agent-trigger.ts` would auto-emit on 4 signals (`loss_streak`, `new_postmortem`, `regime_flip`, `gate_spike`), but gated behind `AGENT_TRIGGER_PUBLISH_ENABLED=false` (default off, not deployed)

**Current state:** No automatic task emission on prod. Operator must manually queue each task. Activation does not immediately fire — needs explicit task creation.

**Risk: Low** — no runaway producer until Phase 5 and explicit operator flip.

---

## 6. Worktree cleanup

**Status: PARTIAL**

Cleanup happens:
- **On dispatch failure:** `safeWorktreeRemove()` called (line 170), hard-force removes worktree + branch
- **On dispatch success:** Worktree **remains on disk** (intentional, for inspection + PR opening)

After PR is merged:
- Worktree on disk is stale (pointing at detached HEAD from task creation time)
- Operator must manually `git worktree remove --force worktrees/agent-<id>` when done
- OR they accumulate indefinitely

**Gap identified:** No automatic cleanup post-merge. Over time (if operator forgets), worktrees directory could fill disk. Mitigation: add a `--cleanup-all-merged` flag to a cron job or manual script.

**Risk: Medium** — not immediate, but operational toil + potential disk-full incident if many tasks created over weeks.

---

## 7. Rollback procedure

**Status: CLEAN (30 seconds)**

```
1. Set AGENT_BUS_ENABLED=false on Railway → runner refuses to drain
2. Wait for in-flight tasks to finish (max 10 min given 600s timeout)
3. No new tasks claimed after step 1
4. Existing PRs remain open (manual close + restore refs as needed)
```

Optional cleanup:
```sql
DELETE FROM agent_tasks WHERE status='queued' AND role='code';
DELETE FROM agent_artifacts WHERE kind='diff' AND created_at < NOW() - INTERVAL '1 day';
```

Codex code itself is already dormant (not imported into worker), so no deploy needed to rollback.

**Risk: Low** — clean gate, no state locked into prod.

---

## Decision Matrix

| Criterion | Status | Blocker? |
|---|---|---|
| Air-gap guard operational | ✅ Hardened | No |
| Auto-merge gated | ✅ Requires human approve | No |
| Failure mode: orphan branch on PR crash | 🔴 Unhandled | **YES** |
| Cost cap in place | ❌ Missing | **YES** |
| Orphan worktree cleanup | ⚠️ Manual post-merge | No (operational toil) |
| Runaway task producer | ✅ No auto-emit yet | No |
| Rollback path clear | ✅ Yes (30s) | No |

---

## Verdict: WAIT-30D

**Activate Phase 2a on Railway when:**
1. ✅ Cost tracking + daily budget hardened (add token capture from codex CLI + env-var gate)
2. ✅ PR opener wrapped in try-catch to prevent orphan branches (add error audit + rollback logic)
3. ✅ Post-merge worktree cleanup automated (add cron script or flagged cleanup in runner)
4. ✅ Foundation gate fully green (currently 4/5; rule 2 + 4 pending data)
5. ✅ ≥3 days of Phase 3 (firm-agents) stable on prod with zero anomalies

**Timeline:** Production activation eligible ~2026-05-18 (7 days from now) if:
- Cost cap PR lands this week
- PR opener error handling lands this week
- Foundation rule 2 sees first metadata-stamped trade (expected next session-open)
- No Codex-related incidents in local test loop

---

## Top 3 Concerns

1. **Cost runaway:** No cap means operator could burn $ unknowingly if loop produces many high-cost tasks. Token accounting is 100% stubbed. **BLOCKER.**

2. **PR opener robustness:** If git/gh command fails mid-sequence, orphan branch + incomplete audit trail. Adds manual cleanup burden + audit gaps. **BLOCKER for prod confidence.**

3. **Worktree disk accumulation:** Over weeks, failed cleanup on operator side could fill `/tmp` or repo disk if many tasks created. Monitor early deployments closely.

---

## Recommendation for Operator

**Max-power mode is correctly gated.** Air-gap is hardened. Pattern is safe. But:
- Do NOT flip `AGENT_BUS_ENABLED=true` on Railway this week.
- Land 2 PRs: (1) cost cap + token capture, (2) PR opener error handling.
- Run local tests against those before prod flip.
- Deploy to prod with `AGENT_BUS_ENABLED=true` on or after 2026-05-18 + foundation rule 2 green.
- First week on prod: monitor `agent_results` for error rows daily. Any error → pause (`AGENT_BUS_ENABLED=false`) + triage.
