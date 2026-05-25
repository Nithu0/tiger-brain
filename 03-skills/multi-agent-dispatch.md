---
name: multi-agent-dispatch
description: Fan out a task to N parallel firm-bus agents via command-center orchestrator API; collects receipts in feed.md
tier: brain
project_scope: workspace
when_to_use: operator wants the same intent executed in parallel across multiple panes; keywords "dispatch to all", "parallel agents", "fan out", "ask all panes", "broadcast task"
inputs:
  - name: intent
    type: string
    required: true
  - name: roles
    type: string
    required: false
    default: all-8
  - name: parallel
    type: bool
    required: false
    default: true
  - name: timeout_seconds
    type: number
    required: false
    default: 28800
outputs:
  - dispatch_id: string
  - roles_targeted: array
  - receipts_received: array
  - missing_receipts: array
tools_required: [Bash, Read, Write]
cost_estimate: low
cache_strategy: ephemeral
auto_invocable: false
created: 2026-05-25
created_by: operator
confidence: 0.7
validation_passes: 0
related: ["[[SKILL_REGISTRY_SPEC]]", "[[AGENT_ORCHESTRATION_SPEC]]", "[[2026-05-25-brain-upgrade-plan]]"]
tags: [skill, brain, dispatch, parallel, firm-bus]
---

## Purpose

Issue a single intent to multiple firm-bus roles in parallel via the command-center terminal orchestrator. The skill posts to `/api/terminals/dispatch`, which routes the intent into each target role's `00-firm-bus/inbox/<role>.md`. Each pane's inbox-watcher picks it up and the operator (or agent in that pane) acts. Receipts surface back via `feed.md`. This is the canonical workspace-wide broadcast primitive — operator already does it manually via per-pane inbox writes; this skill standardizes it.

## When to use

- Need the same audit/check/scan performed across multiple projects
- Asking peers in parallel ("all code panes verify X")
- Broadcast operator-decision-request to multiple session contexts
- **Anti-patterns:** do not use for distinct per-pane tasks (use direct inbox-write per role); never dispatch irreversible actions without per-role OK kjør; never auto-dispatch to ai-1/ai-2 (Nexus prod — operator-trigger only)

## Inputs

| Arg | Type | Required | Default | Notes |
|---|---|---|---|---|
| `intent` | string | yes | — | The single intent/question/task body |
| `roles` | string (comma-sep) | no | all-8 | Subset of: code-1, code-2, ai-1, ai-2, thesis-1, as-1, soking-1, personal-1 |
| `parallel` | bool | no | true | If false, sequential with await-on-each |
| `timeout_seconds` | number | no | 28800 | 8h default (per firm-bus fallback) |

## Steps

1. Validate `intent` is non-empty and doesn't contain secret-like patterns (regex check for `.env`, API keys)
2. Resolve `roles` — split comma-separated or expand `all-8` to canonical list
3. Generate `dispatch_id` of form `T-YYYYMMDD-NNN` (date plus sequential 3-digit counter within day)
4. POST to command-center: `POST /api/terminals/dispatch` with `{dispatch_id, intent, roles, parallel}`
5. Command-center writes intent block (with frontmatter `task_id`, `from`, `to`, `objective`, `sla_seconds`) to each `00-firm-bus/inbox/<role>.md`
6. Skill polls `00-firm-bus/feed.md` for lines containing `dispatch_id` (receipts emitted as `[<role>] received <dispatch_id>`)
7. After `timeout_seconds` OR all receipts received, return summary
8. Missing receipts appear in `missing_receipts` output (operator decides re-dispatch)

## Tools / commands

```bash
# Dispatch via API
curl -sS -X POST http://localhost:3001/api/terminals/dispatch \
  -H 'content-type: application/json' \
  -d '{
    "dispatch_id": "T-2026-05-25-042",
    "intent": "audit current TS errors and report top 3",
    "roles": ["code-1", "code-2"],
    "parallel": true
  }'

# Watch feed for receipts
tail -F /home/nithu/Obsidian/Brain/00-firm-bus/feed.md | grep T-2026-05-25-042
```

## Pitfalls

- Pane offline — fallback timeout 8h, then mark in `missing_receipts`
- Inbox-collision when multiple dispatches hit same minute — orchestrator stamps with second-precision and dispatch_id; collisions are visual only
- Roles that overlap on a single pane (rare) — orchestrator dedupes by role
- Sensitive intent — pre-flight regex blocks dispatch if intent contains likely secrets
- `feed.md` lag — Obsidian Git plugin sync is 2-5 min; for tight loops use direct file-tail not API-only

## Validation checks

1. `dispatch_id` returned and uniquely formatted
2. Each targeted role's `00-firm-bus/inbox/<role>.md` has the intent block appended (file mtime advanced)
3. Skill returns within `timeout_seconds`
4. `receipts_received` count ≤ `roles_targeted` count
5. Audit `feed.md` for receipt lines containing `dispatch_id`

## Example usage

```
/skill multi-agent-dispatch intent="audit current TS errors and report top 3" roles=ai-1,ai-2,thesis-1
```

Broadcast to all 8:

```
/skill multi-agent-dispatch intent="report your current blocker, one line each"
```

Sequential mode:

```
/skill multi-agent-dispatch intent="dry-run npm test, report pass/fail" parallel=false
```

## Related

- [[SKILL_REGISTRY_SPEC]]
- [[AGENT_ORCHESTRATION_SPEC]]
- [[2026-05-25-brain-upgrade-plan]]
- [[worktree-spawn-cleanup]]
- [[OBSIDIAN_BRAIN_STRUCTURE]]
