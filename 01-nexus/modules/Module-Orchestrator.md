---
tags: [nexus, module, orchestrator]
type: atomic
created: 2026-05-08
---

# Module-Orchestrator

Owner: Nexus (the firm's stage manager). Lives in `apps/worker/src/firm/orchestrator.ts`. Single function `runCycle()` is the canonical decision path — when in doubt, read it top-to-bottom.

## What it does

Adaptive cycle loop with session-aware cadence. Schedules every step in order: fact agents → analysis agents → portfolio brain → Prism synthesis → maturity gate → Blade proposal → challenge round → Shield veto → Forge exposure → Blade decision gates → entry thesis → DECISION published → execution manager → OANDA → position manager → postmortem on close.

The orchestrator has **no opinion on markets**. All opinions come from specialists ([[Module-Fact-And-Analysis-Agents]], strategy modules, [[Module-Exposure-And-Shield]]). It only orders.

## Key files

- `apps/worker/src/firm/orchestrator.ts` — the cycle runner, `runCycle()`
- `apps/worker/src/firm/session-window.ts` + `london-time.ts` — session-aware cadence
- `apps/worker/src/firm/cold-start-config.ts` — cold-start delta thresholds during early days

## Inputs / outputs

- **Reads**: env flags, session window, cold-start state
- **Calls**: every other module in the firm decision path
- **Writes**: nothing directly; modules write via [[Module-Blackboard]]

## Cycle ordering details

Step 1b is [[Module-ORB]] (range detector every cycle, state ticks when valid, manager evaluates on CONFIRMED). The CIO meta-observer step runs near the end and is observation-only — cannot override gates. [[Module-Agent-Bus]] AGENT_TRIGGER hook fires after CIO when `AGENT_TRIGGER_PUBLISH_ENABLED=true` (default off).

## Related

- [[Module-Blackboard]] — how steps publish/subscribe
- [[Module-Position-Management]] — runs every cycle on open trades, regardless of new entries
- [[Module-Postmortem]] — runs on trade close
- [[Strategy-ORB]] — primary strategy hook into the cycle
- [[Foundation-Gate]] — prerequisites for changing cycle behaviour
- [[OK-Kjor-Gate]] — every push that touches `runCycle()` requires explicit approval
- [[Operator-Principles]] — prinsipp 1 (no auto-disable) + 5 (OK-kjør-gate) bind orchestrator changes
- [[Truth-Hierarchy]] — `runCycle()` itself is the canonical truth; this note merely points

## Operator-principle binding

`firm/{orb,scalp-overlap,session-breakout,vol-expansion,strategy-execution,strategy-blade,orchestrator}` are the seven trading-loop prefixes. Codex / Claude review-runner refuses to touch them without `TRADING_LOOP_OK` in the prompt. See [[Module-Agent-Bus]].
