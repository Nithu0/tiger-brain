---
type: runbook
trigger: any non-trivial task that splits cleanly across independent files / sub-tasks
autonomy_level: fix-locally
---
# Runbook: Multi-Agent-Dispatch

How to fan out across parallel sub-agents. Default to parallel agents for non-trivial work per `feedback_default_parallel_subagents.md` (binding 2026-05-08).

## Sizing rule of thumb
- **5 agents**: typical sweep — doc updates, MOC backfills, env-var sync, parallel test fixes. Most sessions.
- **10 agents**: bigger batch — multi-page dashboard scaffold, multi-module typecheck-fix, parallel audit (PnL, recon, schema, deps, gates, agents in parallel). Operator's "max mode" default.
- **15 agents**: rare — when the operator has typed "BYGG ALT" / "max" AND the work splits into 15 truly disjoint sub-tasks. Diminishing returns past this.
- **1 agent (no fanout)**: trivial single-step work, or strictly sequential work where step N depends on step N-1.

## Decision: fanout or not?
Fan out IF:
- The sub-tasks are file-disjoint (or read-only on shared files).
- The sub-tasks don't depend on each other's output mid-flight.
- The work would take ≥30 min sequential.
- The operator has typed "kjør på" / "kjør alle" / "max" / "BYGG ALT".

Don't fan out IF:
- One agent depends on another's commit landing.
- The work touches a tight set of overlapping files (merge conflicts).
- The task is truly one-shot (a single fix or query).

## Dispatch pattern
1. **TaskCreate first** — write the full TODO list before spawning. This is the contract each sub-agent reads. Single source of truth.
2. **Write a parallel-batch spec** at `docs/ops/parallel-<slug>-YYYY-MM-DD.md` per [[Parallel-Batch-Coordination]]:
   - Goal in one sentence.
   - File ownership per agent (disjoint paths).
   - Output format expected from each agent.
   - Verification step.
3. **Spawn N Agent calls in a single message**, one per sub-task, each pointing to the spec.
4. **Each agent returns a terse report** (under 400 words) to main thread.
5. **Main thread aggregates**: write inbox-note at `00-claude-inbox/nexus/YYYY-MM-DD-<slug>.md` summarising all sub-agent outputs.

## What each agent should always do
- Use absolute paths (no `cd`-then-relative; sub-agent CWD resets between bash calls).
- Read project CLAUDE.md if it didn't auto-load.
- Honour [[Operator-Principles]] — same rules as main thread.
- Return file paths used + verified state, not assumed state.
- Skip cross-agent coordination — that's the main thread's job via the spec doc.

## What never auto-fires
- Spawning agents without a TaskCreate / spec doc. They duplicate work or step on each other.
- Asking sub-agents to do money-impact decisions. Money-impact is operator + Karri territory.
- Spawning 15+ agents on diffuse work (token budget waste).

## Examples from past sessions
- **2026-05-03 Batman + Prediction batch day**: ~10 parallel agents shipped 12 commits / 4 dashboard pages / 10 firm-agents activations. Spec doc was `docs/ops/parallel-batman-prediction.md`.
- **2026-05-11 doc-sweep round 2** + **full-state audit**: 10 agents across the 7-domain matrix; outputs aggregated into single inbox notes.

## Linked
[[Parallel-Batch-Coordination]] · [[Operator-Principles]] · [[When-Operator-Says-Kjor-Pa]] · [[Runbook-Push-Cycle]] · [[Foundation-Gate]] · [[Truth-Hierarchy]]

Memory ref: `feedback_default_parallel_subagents.md`.
