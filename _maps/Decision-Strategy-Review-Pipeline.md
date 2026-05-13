---
type: decision
status: binding
decided: 2026-05-08
---
# Decision: Strategy review pipeline

Any change with money-impact — thresholds, risk sizing, gate logic, new strategy modules, position-management defaults — goes through `docs/strategy/proposals/YYYY-MM-DD_<slug>.md` and waits for [[Karri]] approval before implementation.

## Why
Operator owns ops/infra; their teammate owns strategy/risk. Splitting domains keeps each reviewer focused on what they're best at and prevents Claude from optimising one dimension (e.g. "more trades = more data") while breaking another (risk of ruin). Bedrock for [[Foundation-Gate]] rule integrity.

## Flow
1. Claude writes proposal using template at `docs/strategy/proposals/README.md`.
2. Operator sends to Karri via Discord (webhook in memory `reference_strategy_reviewer.md`).
3. Karri reviews + responds.
4. Operator confirms approval in-session.
5. Claude implements + commits with proposal-slug in commit message + updates proposal status to `implemented (commit <sha>)`.
6. Archive once verified live and stable.

## Status lifecycle
`proposed` → `approved` → `implemented (commit <sha>)` → `archived`.

## Counter-signal — retroactive proposal
If operator says "bare fix det" or "kjør på" inline for what would normally need a proposal: implement directly, then file the proposal retroactively as `Status: implemented (approved-verbally)`. The audit trail must still exist; the gate just moves from before → after.

## What does NOT need a proposal
- Bug fixes that restore intended behaviour.
- Observability (logs, metrics, dashboards).
- Refactors with no behaviour change.
- Backfills of missing data.

Linked to: [[Decisions-MOC]], [[Strategy-Proposal-Workflow]], [[Strategy-Proposal-Pipeline]], [[Karri]], [[Foundation-Gate]]
