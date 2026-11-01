# Codex prod-readiness blocker #3 — autoclean terminal-state worktrees

**Date**: 2026-05-11
**Status**: shipped in commit `3289c52` (stacked with blocker #1 daily-invocation cap)
**Blocker source**: Codex prod-readiness review (3 of 3)

## Problem

Successful Codex dispatches left their git worktrees on disk under
`worktrees/agent-<task-id>`. Operator had to `git worktree remove --force`
manually after PR merges. Over time, dozens of orphan directories
accumulated, bloating the repo checkout.

## Approach

**Option A: cleanup-on-claim** (chosen). At drain-start of every
`agent-codex-runner.mjs` invocation, sweep `WORKTREE_ROOT` and remove
worktrees whose task has reached a terminal state.

Rejected: a separate cleanup cron — adds infra; piggybacking on the
existing runner pays a small constant cost (~one `SELECT` per worktree)
and runs as often as the runner does.

## Implementation

`scripts/agent-codex-runner.mjs`:

- Imports `readdir` from `node:fs/promises`.
- New env var `AGENT_CODEX_AUTOCLEAN_ENABLED` (default `true`; set
  `=false` to keep worktrees for forensics).
- New helper `cleanupTerminalWorktrees()`:
  - `readdir(WORKTREE_ROOT)` — handles ENOENT gracefully.
  - For each `agent-<taskid>` directory: `SELECT status FROM agent_tasks
    WHERE id=$1`.
  - If status is `done` / `failed` / `cancelled`: `git worktree remove
    --force <path>`.
  - Orphans (no DB row) and active tasks (`queued` / `in_progress`)
    left alone.
  - All errors logged + swallowed — cleanup must never block dispatch.
- Called once at start of main(), after `mkdir(WORKTREE_ROOT)`, before
  the claim loop.
- Schema-correct statuses verified against
  `packages/shared/src/db/schema.ts:1183` (not the prescriptive
  `merged`/`pr-opened`/`completed` from the task spec — those are not
  real statuses in `agent_tasks`).

~60 lines added (function + env-var + doc-block + call site).

## Verify

- `node --check scripts/agent-codex-runner.mjs` clean.
- Walked through the flow on paper: ENOENT guard, non-agent-prefixed
  entries skipped, orphans skipped, active tasks skipped, only terminal
  tasks removed, errors logged-not-thrown.

## Commit

`3289c52 feat(codex): daily-invocation cap for Codex Phase 2a runner` —
note: a parallel agent stacked the autoclean work into the same commit
as the blocker-#1 daily-cap; commit message acknowledges the stacking.

## Operator action

None. Default ON. Disable on Railway with
`AGENT_CODEX_AUTOCLEAN_ENABLED=false` if forensics needed.

## Related

A separate operator-runnable forensics sweeper exists at
`scripts/firm/codex-worktree-sweep.mjs` (untracked at time of this note).
Defense in depth: in-runner autoclean for the steady state, the sweep
script for orphans / failed dispatches operator wants to keep around.
