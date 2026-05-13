---
tags: [nexus, module, shield, forge, exposure]
type: atomic
created: 2026-05-08
---

# Module-Exposure-And-Shield

Owner: Shield + Forge. Two siblings sharing the gate-and-veto layer of the firm decision path.

## What they do

**Forge (`exposure/`)** — env-gated exposure caps (`EXPOSURE_MAX_*`), drawdown limits, `performPortfolioCheck`. Hard cap on how much risk is open at once.

**Shield (`event-policy/`)** — graduated high-impact news state machine: `CLEAR` → `PRE_EVENT_CAUTION` → `BLACKOUT` → `POST_EVENT_SETTLING`. Vetoes new entries during high-impact windows.

Together: they sit between Blade's proposal and the entry-thesis. Either can veto.

## Key files

- `apps/worker/src/firm/exposure/`
- `apps/worker/src/firm/event-policy/`
- `apps/worker/src/firm/firm-epoch.ts` — drawdown grenser, epoch filter
- `apps/worker/src/firm/gates/` + `apps/worker/src/firm/gate-impact.ts` — gate decision logging

## Decision path role

Sequence in `runCycle()`:
> Blade proposal → Challenge round → **Shield veto** → **Forge exposure check** → Blade decision gates → Entry thesis

If Shield says no (news blackout), the trade dies here. If Forge says no (exposure cap, drawdown limit), the trade dies here. Both decisions logged to `gate_decisions` for [[Foundation-Gate]] rule 4.

## Inputs / outputs

- **Reads**: news calendar, current open exposure, account balance, regime, env caps
- **Writes**: `gate_decisions` rows (the soft-log + would_reject signal) — feeds [[Foundation-Gate]] rule 4

## Operator-principle binding

Operator-principle 1 (no auto-disable) means Shield reports + vetoes per cycle, but never disables a strategy permanently. See [[Operator-Principles]].

## Related

- [[Module-Orchestrator]] — sequences these gates
- [[Module-Blackboard]] — Shield publishes event-policy state
- [[Strategy-ORB]] — has its own news-blackout in addition
- [[Foundation-Gate]] — rule 4 (gate maturity) feeds from `gate_decisions`
- [[Module-Position-Management]] — exposure tracking interlocks
- [[gate-decisions-state]] — living-state for the table Shield/Forge feeds
- [[When-Gate-Goes-Silent]] — decision-tree when `gate_decisions` stops growing
