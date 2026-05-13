# Codex prod-readiness blocker #2 — PR-opener resilience

Date: 2026-05-11
Status: implemented (awaiting "OK kjør" before push)

## Problem

Per Codex Phase 2a prod-readiness review: `scripts/agent-pr-opener.mjs`
lines 191-213 lacked structured handling around the git + gh sequence.
Prior commit `fdb26c2` added basic try/catch (audit + agent_results.errors)
but three gaps remained:

1. No retry on `git push` (transient failures = full task retry on next drain).
2. No canonical `codex.pr_creation_failed` event — only `pr_failed_<step>` audit rows; nothing on the blackboard so firm-mirror dashboards + other agents couldn't react.
3. No path to clean up orphaned remote branches when `gh pr create` failed after a successful push.

## Failure paths now covered

| Where it dies | New behavior |
|---|---|
| `git commit` | `mkStepError` → `persistFailure` → audit `pr_failed_git_commit` + `codex.pr_creation_failed` + blackboard publish + agent_results.errors merge. Task stays eligible for next drain (idempotent — no `pr_opened` event). Re-throws. |
| `git push` (attempt 1) | One retry after `AGENT_PR_OPENER_PUSH_RETRY_BACKOFF_MS` (default 3000ms, bounded 500-60000). |
| `git push` (both attempts) | Same as commit-fail path. `pushedToRemote=false` → no orphan cleanup needed. |
| `gh pr create` | `pushedToRemote=true` → persistFailure runs. If `AGENT_CODEX_DELETE_BRANCH_ON_PR_FAIL=true` → `git push origin --delete <branch>` + audit `codex.pr_orphan_cleaned`. Default false → log warning, leave orphan for operator inspection. Re-throws. |
| `audit pr_opened` DB write after PR exists | Caught — PR exists on GitHub, task lacks `pr_opened` audit → next drain would re-attempt (known limitation, unchanged by this commit; documented in script header). |

## Blackboard event

Topic: `codex.pr_creation_failed`
Required-field schema is rich (NOT NULL on thesis/evidence/urgency/etc.), so
the publish fills sensible defaults:
- `urgency=high` (surfaces in dashboards)
- `confidence=1.0` (the failure itself is certain)
- `thesis` = one-liner with step + task ID + branch
- `state` jsonb carries: task_id, branch, step, exit_code, pushed_to_remote, stderr_snippet, runner
- `next_action` differs by `pushedToRemote`: inspect-or-delete vs. retry-on-next-drain
- `resolved=false`, no `expires_at` (operator must triage)

Blackboard publish is best-effort — failure logs a warning but doesn't mask the original error. Audit row is the source of truth.

## Files

- `/home/nithu/code/ai-assistent/scripts/agent-pr-opener.mjs` — +163/-20 (final 564 LOC)
- `/home/nithu/code/ai-assistent/.env.example` — +6 (two new env-var docs)

## Verify

- `node --check scripts/agent-pr-opener.mjs` → clean
- Paper trace of all 5 failure paths above → each leaves task in a recoverable state (no `pr_opened` audit) and emits structured forensics.

## Commit SHA

`12f5f93` — `fix(codex): PR-opener resilience — try-catch around git push + gh pr create`

## Operator action required

None for happy path — no behavior change. Activation when push approved:
- Leave `AGENT_CODEX_DELETE_BRANCH_ON_PR_FAIL` unset (default false) — orphans stay on remote, you decide whether to keep for forensics or delete manually.
- Flip to `true` if you'd rather the script auto-clean on `gh pr create` failures.

Closes Codex prod-readiness blocker #2. Blocker #1 (cost cap) is in flight on `scripts/agent-codex-runner.mjs`. Blocker #3 status: see Codex review doc.
