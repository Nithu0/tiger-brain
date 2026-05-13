---
tags: [nexus, module, agent-bus]
type: atomic
created: 2026-05-08
---

# Module-Agent-Bus

Owner: Cross-firm (orchestrator). Lives in `apps/worker/src/firm/agent-bus/`. **Currently DORMANT.** Phase 0 + 1 + 2 + 3 + 4 + 5 code landed 2026-05-03, but `AGENT_BUS_ENABLED=false` on Railway and `runCycle()` does **not** import from `agent-bus/`.

## What it is

Multi-model orchestration scaffolding. Four typed tables in Postgres: `agent_tasks`, `agent_results`, `agent_artifacts`, `agent_audit`. Idempotent on boot. Typed envelopes shared at `packages/shared/src/agent-bus.ts`.

Roles:
- **Claude** — planner / review
- **Gemini** — research / narrative
- **Codex** — code worker (sandbox `workspace-write`, `git worktree`)

## Phases (all landed 03.5)

| Phase | What | Activation |
|---|---|---|
| 0 | Tables + typed envelopes, code unwired | `AGENT_BUS_ENABLED=false` |
| 1 | `scripts/agent-runner.mjs` research dispatcher (read-only) | gated, dev-verified locally |
| 2 | `scripts/agent-codex-runner.mjs` + `scripts/agent-review-runner.mjs` | dev-verified, blocks the seven trading-loop prefixes without `TRADING_LOOP_OK` |
| 3 | 5 firm-agent roles wired into `runCycle()` after CIO step | `FIRM_AGENTS_ENABLED=false` master kill + per-agent flag |
| 4 | Local firm-mirror via zellij + Ralph loops | `scripts/firm/start.sh`, `scripts/firm/ralph.mjs --role=<x>` |
| 5 | `agent-trigger.ts` publishes tasks on cycle-events (loss_streak, new_postmortem, regime_flip, gate_spike) | `AGENT_TRIGGER_PUBLISH_ENABLED=false` |

## Trading-loop guard

The seven prefixes `firm/{orb,scalp-overlap,session-breakout,vol-expansion,strategy-execution,strategy-blade,orchestrator}` are refused by codex-runner / review-runner unless prompt contains `TRADING_LOOP_OK`. Live-verified positive + negative scenarios.

## Activation gates

Activation on Railway requires:
- (a) [[Foundation-Gate]] rule 4 green
- (b) Explicit operator [[OK-Kjor-Gate]]
- (c) Cost budget previously required, now dropped per operator 03.5

## Related

- [[Module-Orchestrator]] — Phase 5 trigger fires after CIO step (when enabled)
- [[Foundation-Gate]] — rule 4 binding
- [[OK-Kjor-Gate]] — activation gate
- [[Operator-Principles]] — prinsipp 3 (small janitor jobs OK, behavioural changes need OK kjør) + prinsipp 6 (autotune deferred 30+ days)
- [[Strategy-Proposal-Workflow]] — code-worker tasks that touch strategy go through [[Karri]] proposals
- [[codex-pipeline-state]] — living-state for the Phase 2a code-drainer
- [[gemini-pipeline-state]] — living-state for the research-drainer
- [[local-mirror-safety-state]] — prod-DB guard for codex-runner + ralph loops
