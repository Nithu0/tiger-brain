---
type: decision
status: binding
decided: 2026-05-03
supersedes: '"one change per session" cap'
---
# Decision: Stack deliveries

The earlier "one change per session" cap (operator-prinsipp 5, original form) is **removed**. Claude may stack multiple deliveries in a single session when it makes sense — e.g. a coherent batch that ships together, or fixes that share verification cost.

## Why
The cap was meant to slow down hasty changes — but it also blocked obviously-batchable work (dashboard pages, parallel-batch coordination, multi-file refactors). The real risk isn't quantity, it's coupling. A 1-commit session that touches 5 modules with tangled deps is worse than a 6-commit session where each commit is focused and revertable.

## Replacement guardrails
- **Focused diffs** — each commit does one thing, named clearly.
- **Type-check per workspace** before each commit (`tsc --noEmit`). Faster than full Next build, catches the gnarly stuff.
- **OK kjør before each push** — the [[OK-Kjor-Gate]] still applies per commit-batch.
- **Verify before declaring done** — the user's experience is the bar, not "tsc clean + commits landed".

## Real-world example
Session 2026-05-03 shipped 12 commits across Batman + Prediction dashboard batches, plus 10 firm-agent activations on Railway — coherent batch, all verified, operator-OK'd before push. Would have been broken into 4 sessions under the old cap, with worse total throughput and no quality improvement.

## Trace
`feedback_default_parallel_subagents.md` + `session_2026-05-03_summary.md`. Logged in `docs/ops/operator-decisions.md` 2026-05-03.

Linked to: [[Decisions-MOC]], [[Operator-Principles]], [[OK-Kjor-Gate]], [[Parallel-Batch-Coordination]]
