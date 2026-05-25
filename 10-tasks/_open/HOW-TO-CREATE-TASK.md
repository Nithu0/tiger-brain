---
title: How to create a task
type: howto
created: 2026-05-25
related:
  - "[[AGENT_ORCHESTRATION_SPEC]]"
  - "[[Tasks-MOC]]"
  - "[[Runbook-Brain-Upgrade-Workflow]]"
tags: [howto, task, queue]
---

# How to create a task

1. Pick a task-id: `T-YYYY-MM-DD-NNN` (NNN = next sequence number that day, 001/002/...)
2. Create a file: `T-YYYY-MM-DD-NNN-<short-slug>.md`
3. Use the template from `[[00-templates/task]]` or copy frontmatter from existing example like `[[T-2026-05-25-001-rag-semantic-chunker]]`

## Minimum required frontmatter
```yaml
---
task_id: T-2026-05-25-XXX
title: One-line task description
from: operator
to: <role-or-unclaimed>
owner: unclaimed
project: <command-center | nexus | thesis | ...>
branch: <role>/<short-slug>
files_allowed:
  - path/glob/here/**
objective: What success looks like
expected_output:
  - bullet list
tests:
  - npm test command or similar
rollback: revert PR
status: open
sla_seconds: 14400
priority: low | medium | high
spec_blocker: optional spec wikilink
related:
  - "[[some-spec]]"
tags: [task, project]
---
```

## Body sections (required)
- ## Purpose
- ## Acceptance criteria
- ## Implementation notes
- ## Test plan
- ## Files to create
- ## Notes

## Claiming + completing
- `firm-task-claim.sh T-YYYY-MM-DD-XXX` (claim — moves to `_in-progress/`)
- `firm-task-complete.sh T-YYYY-MM-DD-XXX` (complete — opens draft PR, moves to `_done/`)
- Push requires operator OK kjør per CLAUDE.md

## Related
- Spec: `[[AGENT_ORCHESTRATION_SPEC]]`
- MOC: `[[Tasks-MOC]]`
- Runbook: `[[Runbook-Brain-Upgrade-Workflow]]`
