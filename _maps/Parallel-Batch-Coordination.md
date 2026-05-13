---
type: workflow
status: active
created: 2026-05-11
---
# Parallel-Batch-Coordination

Multi-Claude pattern: operator runs 2–4 parallel Claude terminals against the same repo, coordinated via a shared spec doc with disjoint file ownership.

## Mechanics
1. Lead session writes `docs/ops/parallel-<slug>-YYYY-MM-DD.md` with: goal, per-terminal file ownership (disjoint paths), interface contracts, integration checkpoint.
2. Operator launches additional Claude sessions, pastes spec.
3. Each terminal commits in its lane; cross-terminal context forwarded by transcript paste.
4. Integration commit lands last after `tsc --noEmit` per workspace.

## When to use
Default per `feedback_default_parallel_subagents.md`: any non-trivial multi-file task. Recent example: 12-commit dashboard + firm-agent activation 2026-05-03.

## Source
- `parallel_batch_pattern.md` memory
- `docs/ops/multi-claude-parallel.md` runbook
- [[Runbook-Multi-Agent-Dispatch]]

Linked to: [[Workflows-MOC]], [[OK-Kjor-Autonomous-Execute]], [[Firm-Up-Max-Mode]], [[Decision-Stack-Deliveries]]
