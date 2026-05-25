---
name: worktree-spawn-cleanup
description: Create a new git-worktree for a task (spawn) OR GC stale worktrees (cleanup) via firm-worktree scripts
tier: brain
project_scope: workspace
when_to_use: starting an isolated Conductor-style task branch, OR weekly GC of dead worktrees; keywords "new worktree", "isolate branch", "cleanup worktrees", "GC branches", "spawn task tree"
inputs:
  - name: action
    type: string
    required: true
  - name: repo
    type: string
    required: false
    default: cwd
  - name: slug
    type: string
    required: false
  - name: age_days
    type: number
    required: false
    default: 7
outputs:
  - worktree_path: string
  - branch_name: string
  - cleaned_count: number
  - kept_count: number
tools_required: [Bash, Read]
cost_estimate: low
cache_strategy: none
auto_invocable: false
created: 2026-05-25
created_by: operator
confidence: 0.7
validation_passes: 0
related: ["[[SKILL_REGISTRY_SPEC]]", "[[AGENT_ORCHESTRATION_SPEC]]", "[[2026-05-25-brain-upgrade-plan]]"]
tags: [skill, brain, worktree, git, conductor, firm-launcher]
---

## Purpose

Wrap the `firm-worktree-spawn.sh` and `firm-worktree-cleanup.sh` scripts as a single name-invocable skill with three actions: `spawn` (create `.worktrees/claude/<slug>/` + branch `claude/<slug>`), `cleanup` (GC worktrees with no commits in > N days), `list` (enumerate active worktrees per repo). This is the Conductor-pattern's day-one primitive — each non-trivial task spawns its own isolated worktree so panes don't trample each other.

## When to use

- Starting a non-trivial task that needs an isolated branch (avoid main-branch contention)
- Weekly cleanup pass to remove abandoned worktrees (prevents `.worktrees/` bloat)
- Auditing active worktrees per repo before a bigger change
- **Anti-patterns:** do not spawn for one-line fixes (overhead); do not cleanup with `--force` on dirty worktrees (data loss); do not spawn with slugs already in use (branch collision)

## Inputs

| Arg | Type | Required | Default | Notes |
|---|---|---|---|---|
| `action` | string | yes | — | One of: `spawn`, `cleanup`, `list` |
| `repo` | string (path) | no | cwd | Path to git repo |
| `slug` | string | no | — | Required for `spawn`; kebab-case task identifier |
| `age_days` | number | no | 7 | For `cleanup`: GC worktrees with no commits in > N days |

## Steps

### spawn

1. Validate `repo` is a git repo (`git -C <repo> rev-parse --git-dir`)
2. Validate `slug` is kebab-case + unused (`git -C <repo> branch --list "claude/<slug>"` empty)
3. Invoke `firm-worktree-spawn.sh claude <repo> <slug>`
4. Script creates `<repo>/.worktrees/claude/<slug>/` + branch `claude/<slug>` from current HEAD
5. Return `worktree_path` and `branch_name`

### cleanup

1. List all worktrees: `git -C <repo> worktree list --porcelain`
2. For each worktree under `.worktrees/claude/`, check last commit date
3. If last commit < `age_days` ago: keep
4. If dirty (uncommitted changes): skip + log warning
5. If clean + stale: invoke `firm-worktree-cleanup.sh --age-days N` (where N is the input age threshold)
6. Script runs `git worktree remove` + `git branch -D claude/SLUG` per stale entry (SLUG matched from the worktree being cleaned)
7. Return `cleaned_count` and `kept_count`

### list

1. Run `git -C <repo> worktree list` and parse output
2. Return enumeration with path, branch, HEAD sha, last-commit-date

## Tools / commands

```bash
# Spawn
/home/nithu/code/command-center/_bin/firm-worktree-spawn.sh claude /home/nithu/code/command-center brain-engine-rag

# Cleanup
/home/nithu/code/command-center/_bin/firm-worktree-cleanup.sh --age-days 7

# List
git -C /home/nithu/code/command-center worktree list
```

## Pitfalls

- Dirty worktree — `cleanup` refuses to remove uncommitted changes; resolve manually first
- Branch-conflict (slug collision) — `spawn` aborts if `claude/<slug>` already exists; pick fresh slug
- `.worktrees/` directory permission issues — verify owner is operator + writable
- Worktree path inside a path that gets `rm -rf`'d (e.g. node_modules-style purge) — keep `.worktrees/` at repo root
- Detached HEAD source — `spawn` from a detached HEAD creates a branch without upstream; remember to set `--track origin/main` on first push
- Force-cleanup on a worktree with operator's WIP — never use `--force` flag without explicit operator request

## Validation checks

1. For `spawn`: `git -C <repo> worktree list` includes new entry; new directory exists; branch `claude/<slug>` created
2. For `cleanup`: `cleaned_count` matches actually-removed entries; `kept_count + cleaned_count` = pre-existing total
3. For `list`: output rows match `git worktree list --porcelain` raw count
4. No dirty worktree was removed (cross-check `git status` per skipped path)
5. No branch outside `claude/<slug>` namespace was touched

## Example usage

```
/skill worktree-spawn-cleanup action=spawn repo=/home/nithu/code/command-center slug=brain-engine-rag
```

Weekly cleanup:

```
/skill worktree-spawn-cleanup action=cleanup repo=/home/nithu/code/command-center age_days=7
```

List active:

```
/skill worktree-spawn-cleanup action=list repo=/home/nithu/code/ai-assistent
```

## Related

- [[SKILL_REGISTRY_SPEC]]
- [[AGENT_ORCHESTRATION_SPEC]]
- [[2026-05-25-brain-upgrade-plan]]
- [[multi-agent-dispatch]]
- [[OBSIDIAN_BRAIN_STRUCTURE]]
