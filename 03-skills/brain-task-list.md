---
name: brain-task-list
description: List workspace-wide tasks from 10-tasks/ filtered by status
tier: brain
project_scope: workspace
when_to_use: operator types "/brain tasks" OR wants overview of active work OR before claiming a task
inputs:
  - name: status
    type: string
    required: false
    default: open
  - name: owner
    type: string
    required: false
  - name: project
    type: string
    required: false
outputs:
  - tasks: array-of-Task
  - count: number
harness_tools: [Bash]
system_tools: [curl, jq, ls]
auto_invocable: false
created: 2026-05-25
created_by: operator
confidence: 0.8
validation_passes: 0
version: 0.1.0
related: ["[[SKILL_REGISTRY_SPEC]]", "[[AGENT_ORCHESTRATION_SPEC]]", "[[Tasks-MOC]]"]
tags: [skill, brain, tasks]
---

## Purpose

Single-call overview of every workspace task currently in flight. Surfaces tasks from `~/Obsidian/Brain/10-tasks/` (front-matter-indexed by the command-center task service) filtered by status, owner, and project. The skill is the canonical "what's on the board" view used before claiming work, during daily standup-with-self, and at end-of-day handoff. Replaces operator's manual `ls 10-tasks/` + open-each-file workflow with one structured table that includes SLA countdowns so claimable, near-deadline tasks rise to the top.

## When to use

- Operator types `/brain tasks` in any firm-launcher pane to see the active backlog
- Before claiming a new task — verify the task is still `open` and `owner=unclaimed`
- End-of-day handoff — list `in-progress` tasks per pane to write into `handoffs/`
- Morning briefing — list `blocked` tasks the operator needs to unblock
- **Anti-patterns:** do not use as a write-path (use the task-create endpoint instead); do not use for archived tasks (`status=done` is supported but old `done` tasks live in `90-archive/` and aren't indexed); never poll this in a tight loop (refresh ≥ 30s)

## Inputs

| Arg | Type | Required | Default | Notes |
|---|---|---|---|---|
| `status` | string | no | open | One of `open`, `in-progress`, `blocked`, `done` |
| `owner` | string | no | — | Firm-bus role (e.g. `code-1`, `ai-2`) or `unclaimed` |
| `project` | string | no | — | Project slug (e.g. `nexus`, `thesis`, `as`) |

## Steps

1. Parse `status` (default `open`); reject values outside the enum
2. Build query string `?status=<status>` and append `&owner=<owner>` + `&project=<project>` only when provided
3. GET `http://127.0.0.1:3100/api/brain/tasks<querystring>` with no body
4. Parse JSON response — expected shape: `{ tasks: [{ task_id, title, owner, project, status, created_at, claimed_at?, sla_seconds? }], count: <int> }`
5. For each task, compute SLA countdown: `(claimed_at + sla_seconds) - now` in human-readable form (e.g. `4h 12m left`, `OVERDUE 1d 3h`, `no-sla`)
6. Render a table with columns: `task_id | title | owner | project | sla-countdown`
7. Flag claimable tasks (`status=open` AND `owner=unclaimed`) with a leading `[CLAIM]` marker so they stand out
8. Print `count` footer; if `count == 0`, print "no tasks match" and exit clean
9. On HTTP 503, fall back to local listing: `ls -lt ~/Obsidian/Brain/10-tasks/*.md | head -20` with a "API unavailable" note

## Tools / commands

```bash
# All open tasks (default)
curl -sS "http://127.0.0.1:3100/api/brain/tasks?status=open" \
  | jq -r '.tasks[] | [.task_id, .title, .owner, .project] | @tsv' \
  | column -t -s $'\t'

# In-progress tasks owned by code-1
curl -sS "http://127.0.0.1:3100/api/brain/tasks?status=in-progress&owner=code-1" \
  | jq '.'

# Blocked tasks across nexus
curl -sS "http://127.0.0.1:3100/api/brain/tasks?status=blocked&project=nexus" \
  | jq -r '.tasks[] | "[\(.task_id)] \(.title) (owner=\(.owner))"'

# Fallback when API is down
ls -lt ~/Obsidian/Brain/10-tasks/*.md | head -20
```

## Pitfalls

- SLA computation requires `claimed_at` — old tasks created before the field existed (pre-2026-05-20) won't have it; default to `no-sla` rather than printing garbage
- `done` status — only recently-closed tasks (last 7 days) are indexed; older `done` tasks live in `90-archive/` and need a separate query (out of scope for this skill)
- Owner aliases — `unclaimed`, `null`, and missing field all mean "no owner"; normalize before display so the table doesn't show three different empty states
- HTTP 503 — task service unavailable; fall back to `ls 10-tasks/` so operator still gets a partial view
- Stale cache — the task index rebuilds every 60s; a task you just created may not appear immediately

## Validation checks

1. GET returns HTTP 200 with `tasks` array and `count` int
2. `count == len(tasks)` (server-side consistency)
3. Every task has `task_id`, `title`, `owner`, `project`, `status` populated
4. SLA countdown renders without throwing on missing `claimed_at` / `sla_seconds`
5. Weekly spot-check: pick one rendered `task_id`, open `10-tasks/<task_id>.md`, confirm frontmatter matches the rendered row

## Example usage

```
/brain tasks
```

Sample output:

```
task_id        title                                     owner       project        sla-countdown
T-20260524-007 [CLAIM] refactor regime detector          unclaimed   nexus          no-sla
T-20260524-011 wire RAG_ENGINE_SPEC C1-4 stub            code-1      command-center 2h 41m left
T-20260523-019 backtest XAUUSD breakout overlap          ai-1        nexus          OVERDUE 4h 12m
T-20260525-001 thesis chapter 4 draft v2                 unclaimed   thesis         no-sla

count: 4
```

Filtered to claimable work only:

```
/brain tasks status=open owner=unclaimed
```

Per-project view at end-of-day:

```
/brain tasks status=in-progress project=command-center
```

## Related

- [[SKILL_REGISTRY_SPEC]]
- [[AGENT_ORCHESTRATION_SPEC]]
- [[Tasks-MOC]]
- [[multi-agent-dispatch]]
- [[brain-recall]]
