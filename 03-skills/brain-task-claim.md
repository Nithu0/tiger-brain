---
name: brain-task-claim
description: Claim a task from 10-tasks/_open/ — moves to _in-progress/, stamps frontmatter, sets git branch
tier: brain
project_scope: workspace
when_to_use: operator types "/brain task-claim" OR sees an open task they want to take OR before starting work on a feature
inputs:
  - name: task_id
    type: string
    required: false
  - name: list
    type: bool
    required: false
    default: true
outputs:
  - claimed_task_id: string
  - branch: string
  - file_path: string
harness_tools: [Bash]
system_tools: [git]
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
tags: [skill, brain, tasks, claim]
---

## Purpose

Operator-facing wrapper around `~/code/command-center/_bin/firm-task-claim.sh`. Bridges the pane-side firm workflow with the task backlog described in AGENT_ORCHESTRATION_SPEC §10.1 + §11: a Claude pane that wants to take work from `~/Obsidian/Brain/10-tasks/_open/` calls this skill, which atomically moves the task file to `_in-progress/`, stamps frontmatter (`status`, `claimed_at`, `claimed_by=$FIRM_ROLE`), and — if the frontmatter declares a `branch:` — checks out (or creates) that branch in the current working directory. LOCAL-only: never pushes, never touches remote. Replaces operator's previous habit of manually grepping `_open/` and editing frontmatter by hand.

## When to use

- Operator types `/brain task-claim` in any firm-launcher pane (list mode) or `/brain task-claim <id>` (claim mode)
- A sub-agent finishes its current chunk and is ready to pick up the next backlog item
- Before starting a new feature/fix — call list-mode first to see if a matching task already exists in `_open/`
- Pre-flight after a fresh `firm` launch when the pane's `$FIRM_ROLE` is set and operator wants to be productive
- **Anti-patterns:** do not call from a pane with dirty git state (branch checkout will warn and skip); never claim a task already in `_in-progress/` (the script refuses with a duplicate-destination error); never call with `FIRM_ROLE=unknown` for real work (audit trail becomes useless); never push or open a PR from this skill — that is `brain-task-complete`'s job

## Inputs

| Arg | Type | Required | Default | Notes |
|---|---|---|---|---|
| `task_id` | string | no | — | Exact id (`T-2026-05-25-001`) or filename prefix. Omit to list available tasks |
| `list` | bool | no | true | When `task_id` is absent, list-mode is the effective default behaviour |

## Steps

1. If `task_id` is empty → invoke list-mode: `~/code/command-center/_bin/firm-task-claim.sh` (no args). The script enumerates `_open/*.md`, prints `task_id  objective` per file, exits 0
2. If `task_id` is provided → invoke claim-mode: `~/code/command-center/_bin/firm-task-claim.sh <task_id>`
3. Script finds matching `_open/<task_id>*.md` (exact, suffix, or prefix match). Errors out if not found and re-suggests list-mode
4. Script reads frontmatter (`task_id`, `branch`, `objective`, `files_allowed`, `expected_output`, `sla_seconds`, `status`) before the move
5. Atomic move: `mv _open/<file>.md _in-progress/<file>.md`. If destination already exists, abort (likely already claimed)
6. In-place frontmatter rewrite on the destination: `status: in-progress`, `claimed_at: <ISO-UTC>`, `claimed_by: $FIRM_ROLE`
7. If frontmatter declares `branch:` and `git` is available + cwd is a git repo: checkout existing branch OR `git checkout -b <branch>`. Failures are warnings, not fatal
8. Script prints confirmation block (`task_id`, `objective`, `branch`, `files_allowed`, `expected_output`, `sla_seconds`, status transition, `branch_status`, destination path) and suggests `firm-task-complete.sh <id>` as the next step

## Tools / commands

```bash
# List open tasks in 10-tasks/_open/
~/code/command-center/_bin/firm-task-claim.sh

# Claim a specific task (exact id)
~/code/command-center/_bin/firm-task-claim.sh T-2026-05-25-001

# Claim with filename-prefix match (when slug is appended)
~/code/command-center/_bin/firm-task-claim.sh T-2026-05-25-001

# Inspect after-claim state
ls ~/Obsidian/Brain/10-tasks/_in-progress/
git branch --show-current
```

## Pitfalls

- `Task '<id>' not found in _open/` → typo in id, or already claimed by a peer pane; run list-mode to confirm
- `Destination already exists` → another pane raced ahead and claimed this task; check `_in-progress/` for the active claimer
- `FIRM_ROLE not set` warning → pane was not launched via firm-launcher; claim still proceeds but `claimed_by` is recorded as `unknown` (bad for audit)
- `exists but checkout failed (working tree dirty?)` → uncommitted changes block the branch switch; stash or commit first, then `git checkout <branch>` manually (the frontmatter is already stamped)
- `cwd is not a git repo` → pane is sitting in a non-repo dir (e.g. `~/Obsidian/Brain`); cd into the target repo before claiming if `branch:` matters
- Frontmatter rewrite failure → leaves file in `_in-progress/` half-claimed (status fields may be missing). Manually edit the frontmatter or move back to `_open/` if needed

## Validation checks

1. After claim, `~/Obsidian/Brain/10-tasks/_in-progress/<id>*.md` exists; `_open/<id>*.md` no longer exists
2. `grep -E '^(status|claimed_at|claimed_by):' <file>` shows `in-progress`, ISO timestamp, and `$FIRM_ROLE`
3. If `branch:` was declared, `git branch --show-current` matches the declared value (or a warning was surfaced)
4. Script exit code is 0; non-zero indicates either not-found, duplicate destination, or missing `_open/` directory
5. Append a one-liner to `~/Obsidian/Brain/00-firm-bus/feed.md` (manual or via complete-step) confirming the claim — sanity-check that peers can see it

## Example usage

```
/brain task-claim
```

Sample list-mode output:

```
Available tasks in _open/
─────────────────────────────────────────────────────────────
  T-2026-05-25-001  Wire skill-registry scan.ts to chokidar watcher
  T-2026-05-25-002  Backfill SKILL.md frontmatter for 5 default skills
  T-2026-05-25-003  Add AT-1 acceptance test fixture (19 skills)

Claim: firm-task-claim.sh <task-id>
```

Claim-mode:

```
/brain task-claim T-2026-05-25-002
```

```
OK    Claimed T-2026-05-25-002 for code-2

  task_id:         T-2026-05-25-002
  objective:       Backfill SKILL.md frontmatter for 5 default skills
  branch:          skill/T-2026-05-25-002-backfill-frontmatter
  files_allowed:   03-skills/brain-distill-daily.md, 03-skills/youtube-ingest.md
  expected_output: 5 SKILL.md files valid per brain skills validate
  sla_seconds:     3600
  status:          open → in-progress
  claimed_at:      2026-05-25T14:32:11Z
  claimed_by:      code-2
  branch_status:   created and checked out new 'skill/T-2026-05-25-002-backfill-frontmatter'
  location:        /home/nithu/Obsidian/Brain/10-tasks/_in-progress/T-2026-05-25-002-backfill.md

Complete with: firm-task-complete.sh T-2026-05-25-002
```

## Related

- [[SKILL_REGISTRY_SPEC]]
- [[AGENT_ORCHESTRATION_SPEC]]
- [[Tasks-MOC]]
- [[Runbook-Sample-Task-Walkthrough]]
- [[brain-task-complete]]
