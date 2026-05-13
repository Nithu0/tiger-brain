---
type: workflow
status: live
created: 2026-05-11
---
# Strategy-Proposal-Pipeline

Money-impact changes (thresholds, risk-sizing, gate logic, new strategy modules, position-management defaults) flow through this pipeline before implementation.

## Flow
1. Claude writes proposal at `docs/strategy/proposals/YYYY-MM-DD_<slug>.md` using template at `proposals/README.md`.
2. Operator forwards to [[Karri]] via Discord webhook with structured embed.
3. Claude waits for operator-confirmed approval. No implementation until then.
4. On approval: implement, update proposal status to `implemented` with commit SHA, archive when stale.

## Counter-signal
"Bare fix det" / "kjør på" inline = implement directly + file retroactive proposal as `Status: implemented (approved-verbally)`.

## What does NOT need a proposal
Bug fixes restoring intended behaviour, observability, refactors with no behaviour change, backfills.

Linked to: [[Workflows-MOC]], [[Decisions-MOC]], [[Decision-Strategy-Review-Pipeline]], [[Karri]], [[Strategy-Proposal-Workflow]], [[Operator-Principles]]
