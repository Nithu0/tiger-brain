---
title: Tasks-MOC
type: moc
created: 2026-05-25
purpose: Index of workspace-wide task backlog folder structure, lifecycle, frontmatter contract, and supporting tooling
related: [[2026-05-25-brain-upgrade-plan]]
tags: [moc, tasks, backlog, orchestration, workflow]
---

# Tasks-MOC

Curated index of `10-tasks/` — the workspace-wide task backlog. Each task is a single `.md` file with structured frontmatter (`task_id`, `owner`, `files_allowed`, `exit_criteria`, `sla`, `status`). Tasks move through lifecycle folders (`_open/` → `_in-progress/` → `_done/`, with `_blocked/` as a side-branch). The BrainOrchestrator (Module A per [[2026-05-25-brain-upgrade-plan]]) parses frontmatter for triggers: stale (past SLA), blocked (resolution-needed), ready-to-promote. This MOC indexes folder structure, the lifecycle contract, and the supporting CLI tools.

## Folder structure

| Subfolder | Purpose |
|---|---|
| `_open/` | Unclaimed tasks ready for any agent to claim |
| `_in-progress/` | Claimed tasks currently being worked |
| `_blocked/` | Tasks stuck pending external dependency or operator decision |
| `_done/` | Completed tasks (retained for retrospectives + audit; never delete) |

See [[10-tasks/README]] for naming convention (`T-YYYY-MM-DD-NNN-<short-slug>.md`), required frontmatter fields, and the full anti-pattern list.

## Pilot tasks

*B-9 sub-agent will populate this section with the initial pilot batch (T-2026-05-25-001 through T-2026-05-25-NNN) once that sub-agent lands. As of this MOC's creation timestamp, all four lifecycle folders are empty — task backlog has not been seeded yet.*

Expected pilot scope per [[2026-05-25-brain-upgrade-plan]]: BrainOrchestrator skeleton, distillation hook prototype, skill-registry bootstrap, recall-eval baseline run, worktree-default decision, integration-notes consolidation.

## Task lifecycle

Binding contract — see [[AGENT_ORCHESTRATION_SPEC]] §11 (frontmatter v2):

1. Operator (or orchestrator) creates task in `_open/` with full frontmatter (`task_id`, `title`, `created`, `owner`, `files_allowed`, `exit_criteria`, `sla`, `status: open`).
2. Agent runs `firm-task-claim.sh <task-id>` → file moves to `_in-progress/`; `claimed_by` + `claimed_at` stamped; `status: in-progress`.
3. Agent works strictly within `files_allowed` scope (scope creep is an anti-pattern).
4. If blocked: agent moves file to `_blocked/`, sets `blocker` field with a one-line description; orchestrator surfaces to operator.
5. On completion: `firm-task-complete.sh <task-id>` → verifies `exit_criteria` are met, moves to `_done/`, sets `status: done`.
6. Orchestrator periodically scans for stale (past SLA) or blocked tasks; reports to operator via firm-bus feed.

## Tools

- `firm-task-claim.sh` — *stub: B-5 sub-agent writes this in parallel; will live in `command-center/_bin/` alongside the existing firm-launcher scripts; signature `firm-task-claim.sh <task-id>`; idempotent; stamps `claimed_by = $FIRM_ROLE` from the calling pane.*
- `firm-task-complete.sh` — *stub: B-5 sub-agent writes this; signature `firm-task-complete.sh <task-id>`; runs exit-criteria verification (test commands, file existence, grep-checks per task) before moving to `_done/`; fails loud if any criterion is unmet.*

## Related

- [[2026-05-25-brain-upgrade-plan]] — Module A (BrainOrchestrator) consumes the task backlog as its primary work-source.
- [[AGENT_ORCHESTRATION_SPEC]] — binding spec for frontmatter v2, claim/complete contract, and SLA semantics.
- [[01-CURRENT-FOCUS]] — operator's active focus; pilot tasks should track 1:1 to current-focus items.
- [[10-tasks/README]] — full subfolder reference + frontmatter field list + anti-patterns.
- [[Github-Repos-MOC]] — `github-discover` task-proposal gate (per GITHUB §7.5) auto-files candidate tasks into `_open/`.
- [[handoffs/]] folder — end-of-day handoff notes complement the task backlog (handoffs = state; tasks = work-units).
- [[Retrospectives-MOC]] — weekly roll-up pulls `_done/` + `_blocked/` entries into the Tasks-completed / Tasks-blocked sections.
- [[Runbook-Multi-Agent-Dispatch]] — operational procedure for parallel work; tasks define scope, dispatch executes it.
- [[Skills-MOC]] — `multi-agent-dispatch` skill is the natural way to fan out a single task across multiple panes.
- [[System-Architecture-MOC]] — parent context for why this backlog exists (Conductor-style isolated-task model).
- [[Youtube-MOC]] — ingest pipeline can propose follow-up tasks (per YOUTUBE §4 "Suggested tasks" section) into `_open/`.

## Open questions

- **Claim race**: two agents call `firm-task-claim.sh` on the same `task-id` simultaneously — does the script use `git mv` + commit-atomic, file-lock, or first-write-wins? B-5 sub-agent decides.
- **Exit-criteria DSL**: free-form string list vs. structured (shell-cmd / file-exists / grep-match)? AGENT_ORCHESTRATION_SPEC §11 leaves this open.
- **SLA escalation**: when a task crosses SLA, does orchestrator auto-move to `_blocked/` or just notify? Defaults to notify-only per operator's no-auto-disable principle ([[Operator-Principles]]).
- **`_done/` retention**: indefinite for audit, or quarterly archive to `90-archive/tasks/<YYYY-Q>/`? Mirror the inbox retention pattern.
