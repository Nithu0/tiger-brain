---
type: person
role: strategy-reviewer
project: nexus
---
# Karri — strategy/risk reviewer

Operator's teammate. Owns strategy/risk decisions on Nexus XAUUSD. Reviews all proposals filed at `docs/strategy/proposals/` before operator green-lights implementation.

## Workflow
1. Claude writes proposal doc in `docs/strategy/proposals/YYYY-MM-DD_slug.md` using template at `README.md`.
2. Operator sends to Karri via Discord (webhook in memory `reference_strategy_reviewer.md`).
3. Karri reviews + responds.
4. Claude implements only after operator confirms approval.

## Open proposals (per 2026-05-11)
- `break_even_trigger_lower` — 1.0R → 0.5R (~$3-6k/år potensial)
- `risk_pct_clamp` — defensive 5% hard cap
- `deprecate_simulated_orders_strategy_id_desk` — schema cleanup

All sent to Karri via Discord 2026-05-11 (HTTP 204 ✓). Awaiting review.

## Discord routing
Strategy/risk discussions via webhook (see `reference_strategy_reviewer.md`). Send only when operator triggers ("send det til Karri", "shoot melding").

Linked to: [[Operator-Nithu]], [[Nexus-MOC]], [[Operator-Principles]], [[Foundation-Gate]], [[Strategy-Proposal-Workflow]], [[Strategy-Promotion-Workflow]], [[Runbook-Karri-Proposal-Send]], [[When-Strategy-Change-Tempting]], [[Truth-Hierarchy]] (proposal docs in repo are canonical; vault mirrors)
