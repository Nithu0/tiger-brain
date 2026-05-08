---
tags: [nexus, ops, karri, reviewer]
type: atomic
created: 2026-05-08
---

# Karri

Operator's strategy / risk reviewer. Stub — full context lives in operator memory `reference_strategy_reviewer.md`.

## Role

Karri owns strategy and risk. Operator owns ops and infra. Any money-impact change goes to Karri for review before implementation. See [[Strategy-Proposal-Workflow]].

## How proposals reach Karri

1. Claude writes the proposal in `docs/strategy/proposals/YYYY-MM-DD_<slug>.md`. Set `Reviewer: Karri`.
2. Operator forwards to Karri via `#strategy-review` Discord channel (webhook stored in operator's local memory only — never in this vault).
3. Karri reviews async; may approve, push back, or request changes.
4. Operator confirms approval back to Claude.

## Related

- [[Strategy-Proposal-Workflow]] — the canonical flow
- [[Strategy-Promotion-Workflow]] — Karri approval is a prerequisite
- [[Operator-Principles]] — prinsipp 4 + 5
- [[Nexus-MOC]]
