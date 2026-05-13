---
tags: [nexus, module, blackboard]
type: atomic
created: 2026-05-08
---

# Module-Blackboard

Typed pub/sub messaging layer between firm agents. Lives in `apps/worker/src/firm/blackboard.ts`. The "shared blackboard" half of the firm metaphor — every agent reads/writes here instead of calling each other directly.

## What it does

Holds typed messages keyed by topic. Agents publish; downstream agents subscribe. Decouples `runCycle()` ordering from data flow. [[Module-Orchestrator]] never inspects content — just runs steps in order; data moves via blackboard.

## Key files

- `apps/worker/src/firm/blackboard.ts` — the topic store + typed envelopes
- See `docs/ref/blackboard-topics.md` in `_repo-docs/` for the full topic list

## Topics (selected)

- `xauusd.orb.range`, `xauusd.orb.state`, `xauusd.orb.signal` — see [[Module-ORB]] and [[Strategy-ORB]]
- Fact / analysis topics — see [[Module-Fact-And-Analysis-Agents]]
- Decision topics from Blade / Shield / Forge — feed into [[Module-Position-Management]]
- Postmortem hook reads close events — see [[Module-Postmortem]]

## Inputs / outputs

- **Reads**: nothing
- **Writes**: stores typed envelopes by topic
- **Used by**: every firm module — fact agents, analysis agents, ORB, scalp-overlap, session-breakout, vol-expansion, position management, postmortem

## Why it exists

Without a blackboard, every agent would import every other agent and the dependency graph would spiral. Typed envelopes give compile-time guardrails on what each topic carries, while keeping the runtime loosely coupled.

## Related

- [[Module-Orchestrator]] — sequences steps that read/write blackboard
- [[Module-Fact-And-Analysis-Agents]] — heaviest writers
- [[Module-ORB]] — publishes three topics
- [[Module-Postmortem]] — reads close events
- [[Module-Notifications]] — subscribes to typed events for Discord delivery
- [[Operator-Principles]] — prinsipp 2 (data never stops) binds blackboard writes during cleanups
- [[Retention-Policy]] — audit allowlist on blackboard topics enforced via retention
