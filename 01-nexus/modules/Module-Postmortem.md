---
tags: [nexus, module, postmortem, atlas]
type: atomic
created: 2026-05-08
---

# Module-Postmortem

Owner: Atlas. Lives in `apps/worker/src/firm/postmortem.ts` plus `postmortem-hook.ts` and `postmortem-r-multiple.ts`.

## What it does

Fires on every trade close. Classifies the trade across three dimensions:

- **Thesis** — was the entry thesis correct?
- **Management** — did position-management decisions help or hurt?
- **Event-aware** — did news / event windows affect outcome?

Computes per-engine PnL + accuracy scoring (`engine-attribution/`), feeds back into perf multipliers consumed by [[Module-Fact-And-Analysis-Agents]] conviction. Writes structured rows into the firm memory (`firm_memory.ts`).

## Key files

- `apps/worker/src/firm/postmortem.ts` — classifier + scoring
- `apps/worker/src/firm/postmortem-hook.ts` — hook from orchestrator (runs 5 closes per cycle, has 7-day backlog catchup)
- `apps/worker/src/firm/postmortem-r-multiple.ts` — R-multiple computation
- `apps/worker/src/firm/engine-attribution/` — per-engine PnL scoring
- `apps/worker/src/firm/firm-memory.ts` — memory writes

## Inputs / outputs

- **Reads**: close events from [[Module-Blackboard]], trade row from `simulated_orders`, regime/conviction at entry
- **Writes**: `firm_memory` rows, engine-attribution updates, `gate_decisions` audit

## History

Pre-2026-04-21, `runEnhancedPostmortem` was only called from legacy `bot-cycle.ts` which had been off for XAUUSD since 17.4 — postmortems silently weren't running. The hook into orchestrator landed 21.4 evening; the catchup chews 5 closes per cycle.

## Related

- [[Module-Orchestrator]] — calls the hook each cycle
- [[Module-Position-Management]] — produces close events
- [[Module-Reconciliation]] — postmortem accuracy depends on accurate close PnL from OANDA, see [[Reconciliation]]
- [[Strategy-Promotion-Workflow]] — postmortem stats decide promotion to live
- [[Module-Notifications]] — postmortem summaries surface in morning briefing
- [[Operator-Principles]] — prinsipp 1 (postmortem reports, never auto-disables a strategy)
- [[Foundation-Gate]] — postmortem write-rate feeds gate observability
- [[When-Agent-Stalls]] — if Atlas (postmortem worker) stalls, use this decision-tree
