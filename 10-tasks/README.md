---
title: Workspace Task Backlog
folder: 10-tasks
created: 2026-05-25
purpose: Workspace-wide task backlog; each task is a .md with frontmatter; BrainOrchestrator parses for stale/blocked triggers
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[AGENT_ORCHESTRATION_SPEC]]"
tags: [tasks, backlog, orchestration, workflow]
---

## Purpose

This folder is the workspace-wide task backlog. Each task is a single `.md` file with structured frontmatter (`task_id`, `owner`, `files_allowed`, `exit_criteria`, `sla`, `status`). Tasks move through a lifecycle of folders: `_open/` → `_in-progress/` → `_done/` (with `_blocked/` as a side-branch). The BrainOrchestrator parses task frontmatter for triggers — stale tasks (no update past SLA), blocked tasks (resolution-needed), and ready-to-promote tasks. Two CLI tools manage state: `firm-task-claim.sh` moves a task from `_open/` to `_in-progress/` and stamps the claimer; `firm-task-complete.sh` moves to `_done/` and verifies exit criteria.

## Subfolders

| Subfolder | Purpose |
|---|---|
| `_open/` | Unclaimed tasks ready for any agent to claim |
| `_in-progress/` | Claimed tasks currently being worked |
| `_blocked/` | Tasks stuck pending external dependency or operator decision |
| `_done/` | Completed tasks (retained for retrospectives + audit) |

## Naming convention

`<task-id>-<short-slug>.md` — e.g. `T-2026-05-25-001-brain-orchestrator-skeleton.md`. Task ID format: `T-YYYY-MM-DD-NNN` where NNN is a zero-padded daily counter.

## Frontmatter convention

Required fields per spec (see [[AGENT_ORCHESTRATION_SPEC]]):

- `task_id` — matches the `T-...` prefix in filename
- `title` — short human-readable title
- `created` — YYYY-MM-DD
- `owner` — agent role or operator (e.g. `code-1`, `ai-2`, `operator`)
- `files_allowed` — array of glob patterns the task may touch
- `exit_criteria` — array of testable conditions for completion
- `sla` — duration (e.g. `4h`, `2d`)
- `status` — `open` | `in-progress` | `blocked` | `done`
- `claimed_by` — agent role (null until claimed)
- `claimed_at` — ISO timestamp (null until claimed)
- `blocker` — string description (only when status=blocked)
- `tags` — topical tags

## Workflow

1. Operator (or orchestrator) creates task in `_open/` with full frontmatter
2. Agent runs `firm-task-claim.sh <task-id>` → file moves to `_in-progress/`, `claimed_by` + `claimed_at` stamped
3. Agent works the task within `files_allowed` scope
4. If stuck: agent moves file to `_blocked/`, sets `blocker` field
5. On completion: `firm-task-complete.sh <task-id>` → verifies exit_criteria, moves to `_done/`
6. Orchestrator periodically scans for stale (past SLA) or blocked tasks; reports to operator

## Anti-patterns

- Tasks without `exit_criteria` (cannot verify done)
- Tasks without `files_allowed` (scope creep risk)
- Manual file moves bypassing claim/complete scripts (bypasses verification)
- Tasks that touch production/money without operator gate (binding: operator-only)
- Deleting tasks from `_done/` (retrospective + audit trail loss)

## Related

- [[2026-05-25-brain-upgrade-plan]]
- [[AGENT_ORCHESTRATION_SPEC]]
- [[SKILL_REGISTRY_SPEC]]
- [[OBSIDIAN_BRAIN_STRUCTURE]]
