---
tags: [nexus, module, position-management, blade]
type: atomic
created: 2026-05-08
---

# Module-Position-Management

Owner: Blade (lifecycle). Lives in `apps/worker/src/firm/position-management/`. Runs every cycle for every open trade — independent of new-entry logic.

## What it does

Once a trade is open, this module owns its lifecycle:

- **Break-even** — moves SL to entry after +1R
- **Partial TPs** — 50% closed at +1R, 25% at +2R
- **Regime-aware trailing** — trails under M15 swing-lows (long) / over swing-highs (short) after +1.5R; behaviour depends on regime classification
- **Stale-trade kill** — `STALE_EXIT_TRENDING_MINUTES=150` triggers exit on stale trades (env-tunable)
- **Conviction degradation** — exits early if conviction signal degrades

## Key files

- `apps/worker/src/firm/position-management/` — module index + sub-files
- Reads trade rows from `simulated_orders`
- Writes close events back via [[Module-Blackboard]] → [[Module-Postmortem]]

## Master switch

`POSITION_MANAGEMENT_ENABLED=true` on Railway since 2026-04-22 evening. Verified green on ticket 548 the morning after. Foundation-gate rule 2 ([[Foundation-Gate]]) requires this flag true.

Operations view: see [[Position-Management-Operations]] for the live state and verification trail.

## Inputs / outputs

- **Reads**: open trades from DB, regime classification from analysis-agents, conviction signals
- **Writes**: SL/TP modifications via OANDA execution, close events on partial/full exits
- **Triggers**: [[Module-Postmortem]] on close

## Related

- [[Module-Orchestrator]] — runs position-management every cycle
- [[Module-Postmortem]] — fires on closes from this module
- [[Module-Reconciliation]] — verifies DB position state matches OANDA
- [[Position-Management-Operations]] — operator-facing view
- [[Strategy-ORB]] — primary client of position-management features
- [[Foundation-Gate]] — rule 2 binding
