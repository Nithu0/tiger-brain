---
name: brain-task-complete
description: Complete a task — commits locally + opens draft PR + moves to _done/. Push gated per CLAUDE.md
tier: brain
project_scope: workspace
when_to_use: operator finished work on a claimed task OR before push-gate review
inputs:
  - name: task_id
    type: string
    required: true
  - name: message
    type: string
    required: false
outputs:
  - commit_sha: string
  - pr_url: string
  - completed_at: string
harness_tools: [Bash]
system_tools: [git, gh]
auto_invocable: false
created: 2026-05-25
created_by: operator
confidence: 0.8
validation_passes: 0
version: 0.1.0
related:
  - "[[SKILL_REGISTRY_SPEC]]"
  - "[[AGENT_ORCHESTRATION_SPEC]]"
  - "[[Tasks-MOC]]"
  - "[[Runbook-Sample-Task-Walkthrough]]"
  - "[[brain-task-claim]]"
tags: [skill, brain, tasks, complete]
---

## Purpose

Operator-facing wrapper around `~/code/command-center/_bin/firm-task-complete.sh`. Closes out a task previously claimed via `brain-task-claim`: commits dirty working-tree changes locally, attempts a `gh pr create --draft` (only if the branch is already pushed — never auto-pushes per CLAUDE.md "OK kjør before every push"), moves the task file from `_in-progress/` to `_done/`, stamps completion frontmatter (`status: done`, `completed_at`, `completed_by=$FIRM_ROLE`), and appends a one-liner receipt to `~/Obsidian/Brain/00-firm-bus/feed.md` so peer panes can see the handoff. The script is best-effort throughout: missing git, missing gh, no upstream, or a non-repo cwd each downgrade to a clear warning instead of failing the whole completion.

## When to use

- Operator finishes the work described by a claimed task and wants to package it for review
- Pre-push-gate: produce a draft PR locally so reviewer (Karri or operator) can inspect before the `OK kjør` push
- End-of-pane-session cleanup: any `_in-progress/` task you actually finished should be completed (not just left)
- Following a successful `verify` skill run that confirmed the change works for the user
- **Anti-patterns:** do not complete a task whose tests are failing (fix first; the script will happily commit broken code); do not complete from a different `FIRM_ROLE` than the claimer (script warns but proceeds — audit trail becomes confusing); never use this to push to remote (it deliberately won't, by design); do not call with secrets in `--message` (commit message lands in git history forever)

## Inputs

| Arg | Type | Required | Default | Notes |
|---|---|---|---|---|
| `task_id` | string | yes | — | Exact id or filename-prefix match against `_in-progress/<id>*.md` |
| `message` | string | no | auto: `<id>: <objective>` | Commit message; passed via `--message "<msg>"` (or `-m`) |

## Steps

1. Parse `task_id` (required) and optional `--message "<msg>"` from skill args; error 2 on missing id
2. Locate `_in-progress/<task_id>*.md` (exact, suffix, or prefix match). Error 1 if not found
3. Read frontmatter snapshot: `task_id`, `branch`, `objective`, `claimed_by`. Warn if `claimed_by != $FIRM_ROLE`
4. If cwd is a git repo and `git status --porcelain` is non-empty: `git add -A` + `git commit -m "<msg>"` (auto-generated message if not provided). Pre-commit hook failures surface as warnings
5. If `gh` is installed AND current branch has an upstream tracking ref: `gh pr create --draft --title "<id>: <objective>" --body "<task metadata>" --head <branch>`. Otherwise emit "operator OK kjør needed to push first" notice
6. `mkdir -p _done/` and `mv _in-progress/<file>.md _done/<file>.md`. Abort if destination exists
7. In-place frontmatter rewrite on destination: `status: done`, `completed_at: <ISO-UTC>`, `completed_by: $FIRM_ROLE`
8. Append one-liner to `~/Obsidian/Brain/00-firm-bus/feed.md`: `- <ISO> <role>: task <id> done (PR-ready, awaiting push-gate)`
9. Print summary block (`task_id`, `objective`, `claimed_by`, `completed_by`, `completed_at`, `commit` status, `pr` status, `feed` status, destination path)

## Tools / commands

```bash
# Complete with auto-generated commit message
~/code/command-center/_bin/firm-task-complete.sh T-2026-05-25-002

# Complete with explicit message
~/code/command-center/_bin/firm-task-complete.sh T-2026-05-25-002 \
  --message "skill-registry: backfill SKILL.md frontmatter for 5 default brain skills"

# Inspect after-complete state
ls ~/Obsidian/Brain/10-tasks/_done/ | tail
git log -1 --oneline
gh pr list --draft --author "@me"
tail -5 ~/Obsidian/Brain/00-firm-bus/feed.md
```

## Pitfalls

- `Task '<id>' not found in _in-progress/` → claim step was skipped, or task was already completed; check `_done/`
- `git commit failed (hook? pre-commit?)` → pre-commit hook (lint, test, format) blocked the commit; fix the issue and rerun. Per CLAUDE.md never use `--no-verify`
- `gh CLI not installed` → `pr` step is skipped cleanly; install `gh` or open the PR manually from the GitHub web UI after the operator OK-kjør push
- `branch '<x>' has no upstream` → branch never pushed to remote; per CLAUDE.md "OK kjør before every push" the script refuses to push for you. Get operator approval, then `git push -u origin <branch>` and rerun (or open PR manually)
- `claimed_by='<x>' but current role='<y>'` warning → someone else claimed it; proceed only if you have explicit context (otherwise the audit trail looks like role-spoofing)
- `Destination already exists` in `_done/` → a stale duplicate from an earlier completion; rename or delete the conflicting file before retrying
- Tests failing locally → `verify` skill should have caught this; do NOT complete a task whose verification did not pass — the user-experience bar from CLAUDE.md applies

## Validation checks

1. After completion, `_done/<id>*.md` exists; `_in-progress/<id>*.md` no longer exists
2. `grep -E '^(status|completed_at|completed_by):' <done-file>` shows `done`, ISO timestamp, and `$FIRM_ROLE`
3. If git repo was clean before run: `git log -1 --format=%s` matches the supplied or auto-generated commit message
4. If branch had upstream + gh installed: `gh pr list --draft --head <branch>` returns one row, status `DRAFT`
5. `tail -1 ~/Obsidian/Brain/00-firm-bus/feed.md` shows the new completion line with correct role + task id
6. Script exit code 0 on success; exit 1 on lookup failure, exit 2 on bad args

## Example usage

```
/brain task-complete T-2026-05-25-002 --message "skill-registry: backfill 5 default SKILL.md files"
```

Sample output:

```
OK    Local PR-ready. Push when operator OKs.

  task_id:        T-2026-05-25-002
  objective:      Backfill SKILL.md frontmatter for 5 default skills
  claimed_by:     code-2
  completed_by:   code-2
  completed_at:   2026-05-25T15:48:09Z
  commit:         committed: skill-registry: backfill 5 default SKILL.md files
  pr:             draft PR opened for 'skill/T-2026-05-25-002-backfill-frontmatter'
  feed:           appended to /home/nithu/Obsidian/Brain/00-firm-bus/feed.md
  location:       /home/nithu/Obsidian/Brain/10-tasks/_done/T-2026-05-25-002-backfill.md
```

Push-gate-blocked variant (no upstream):

```
OK    Local PR-ready. Push when operator OKs.

  commit:         committed: T-2026-05-25-002: Backfill SKILL.md frontmatter for 5 default skills
  pr:             branch 'skill/T-2026-05-25-002-backfill-frontmatter' has no upstream — operator OK kjør needed to push first
  feed:           appended to /home/nithu/Obsidian/Brain/00-firm-bus/feed.md
```

## Related

- [[SKILL_REGISTRY_SPEC]]
- [[AGENT_ORCHESTRATION_SPEC]]
- [[Tasks-MOC]]
- [[Runbook-Sample-Task-Walkthrough]]
- [[brain-task-claim]]
