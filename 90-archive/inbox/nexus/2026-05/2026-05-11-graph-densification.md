---
type: claude-inbox
date: 2026-05-11
topic: graph-densification
round: 1
---
# Graph densification — 2026-05-11

Strengthens the Obsidian knowledge graph at `/home/nithu/Obsidian/Brain/` so the brain becomes more navigable for autonomous decisions. Focused on the four canonical targets: [[Foundation-Gate]], [[Operator-Principles]], [[Truth-Hierarchy]], [[Karri]].

## Baseline → after

Backlink counts (files containing at least one wiki-link to the target):

| Target | Before | After | Delta | Multiplier |
|---|---|---|---|---|
| [[Foundation-Gate]] | 37 | 49 | +12 | 1.32× |
| [[Operator-Principles]] | 53 | 69 | +16 | 1.30× |
| [[Truth-Hierarchy]] | 11 | 39 | +28 | **3.55×** |
| [[Karri]] | 15 | 29 | +14 | **1.93×** |

The weakest target ([[Truth-Hierarchy]], 11 inbound) went from "barely integrated" to "well integrated" — every audit / verification / state doc now points to it. [[Karri]] now reaches every strategy + every strategy-touching module.

## Notes touched (28 total)

### Modules (10)
- `01-nexus/modules/Module-Orchestrator.md` — added Operator-Principles + Truth-Hierarchy
- `01-nexus/modules/Module-Blackboard.md` — added Operator-Principles + Retention-Policy
- `01-nexus/modules/Module-Postmortem.md` — added Operator-Principles + Foundation-Gate + When-Agent-Stalls
- `01-nexus/modules/Module-Reconciliation.md` — added Operator-Principles + Truth-Hierarchy + sibling op-doc
- `01-nexus/modules/Module-Notifications.md` — added Operator-Principles + discord-delivery-state
- `01-nexus/modules/Module-ORB.md` — added Operator-Principles + Strategy-Proposal-Workflow (→ Karri)
- `01-nexus/modules/Module-Position-Management.md` — added Operator-Principles + metadata-stamping-state + When-Trade-Bleeds-Multi-Day
- `01-nexus/modules/Module-Exposure-And-Shield.md` — added gate-decisions-state + When-Gate-Goes-Silent
- `01-nexus/modules/Module-Fact-And-Analysis-Agents.md` — added Truth-Hierarchy + Foundation-Gate
- `01-nexus/modules/Module-Agent-Bus.md` — added 3 living-state edges + Karri

### Strategies (5)
- `01-nexus/strategies/Strategy-ORB.md` — added Operator-Principles + Truth-Hierarchy + direct Karri
- `01-nexus/strategies/Strategy-Scalp-Overlap.md` — added Karri + Operator-Principles
- `01-nexus/strategies/Strategy-Session-Breakout.md` — added Karri + Operator-Principles
- `01-nexus/strategies/Strategy-Vol-Expansion.md` — added Karri + Operator-Principles
- `01-nexus/strategies/Strategy-Promotion-Workflow.md` — added Karri + Truth-Hierarchy + When-Strategy-Change-Tempting + Module-Postmortem

### Operations (5)
- `01-nexus/operations/Foundation-Gate.md` — added Truth-Hierarchy + When-Foundation-Rule-Goes-Yellow + Karri + foundation-gate-state
- `01-nexus/operations/Reconciliation.md` — added Operator-Principles + Truth-Hierarchy
- `01-nexus/operations/Position-Management-Operations.md` — added Operator-Principles + Truth-Hierarchy + metadata-stamping-state + Karri
- `01-nexus/operations/Demo-Mode.md` — added Truth-Hierarchy + When-Foundation-Rule-Goes-Yellow
- `01-nexus/operations/Strategy-Proposal-Workflow.md` — added Truth-Hierarchy + Runbook-Karri-Proposal-Send + When-Strategy-Change-Tempting
- `01-nexus/operations/OK-Kjor-Gate.md` — added When-Operator-Says-Kjor-Pa + Runbook-Push-Cycle
- `01-nexus/operations/Karri.md` — added Foundation-Gate + Runbook-Karri-Proposal-Send + When-Strategy-Change-Tempting + Truth-Hierarchy
- `01-nexus/operations/Operator-Principles.md` — added Karri + Truth-Hierarchy + Strategy-Proposal-Workflow + When-Operator-Says-Kjor-Pa

### Runtime + runtime-state (8)
- `01-nexus/runtime/Phase-Status-Pointer.md` — added Truth-Hierarchy + Operator-Principles
- `01-nexus/runtime-state/foundation-gate-state.md` — added Truth-Hierarchy + When-Foundation-Rule-Goes-Yellow + Karri
- `01-nexus/runtime-state/gemini-pipeline-state.md` — added Truth-Hierarchy + When-Quota-Blocks-Pipeline + Quota-Upgrade + Foundation-Gate
- `01-nexus/runtime-state/codex-pipeline-state.md` — added Operator-Principles + OK-Kjor-Gate + Foundation-Gate + Truth-Hierarchy
- `01-nexus/runtime-state/local-mirror-safety-state.md` — added Truth-Hierarchy + Runbook-Backfill-Script-Pattern + OK-Kjor-Gate
- `01-nexus/runtime-state/discord-delivery-state.md` — added Truth-Hierarchy + Foundation-Gate
- `01-nexus/runtime-state/firm-agents-state.md` — added Operator-Principles + Truth-Hierarchy + When-Agent-Stalls
- `01-nexus/runtime-state/metadata-stamping-state.md` — added Operator-Principles + Truth-Hierarchy + When-Trade-Bleeds-Multi-Day
- `01-nexus/runtime-state/gate-decisions-state.md` — added Operator-Principles + Truth-Hierarchy + Module-Exposure-And-Shield

### Runbooks (3)
- `_runbooks/Quota-Upgrade.md` — added Operator-Principles + Truth-Hierarchy
- `_runbooks/Backfill-Script-Pattern.md` — added Truth-Hierarchy + Foundation-Gate + local-mirror-safety-state
- `_runbooks/Multi-Agent-Dispatch.md` — added Foundation-Gate + Truth-Hierarchy

### Decisions (2)
- `_decisions/When-Quota-Blocks-Pipeline.md` — added Foundation-Gate + Truth-Hierarchy + Karri + Quota-Upgrade
- `_decisions/When-Agent-Stalls.md` — added Truth-Hierarchy + Foundation-Gate

### Maps (3)
- `_maps/Foundation-Gate.md` — added Truth-Hierarchy + Karri + foundation-gate-state + When-Foundation-Rule-Goes-Yellow + Strategy-Promotion-Workflow
- `_maps/Truth-Hierarchy.md` — added Phase-Status-Pointer + Foundation-Gate + Reconciliation + When-Doc-Drifts-From-Code + Karri
- `_maps/Karri.md` — added Foundation-Gate + Strategy-Proposal-Workflow + Strategy-Promotion-Workflow + Runbook-Karri-Proposal-Send + When-Strategy-Change-Tempting + Truth-Hierarchy

## Top 3 newly-densified clusters

1. **Truth-Hierarchy cluster** — from 11 → 39 inbound. Now every audit / verification / living-state doc routes the operator's epistemic chain through it. Most-impactful single change: it was the canonical principle that wasn't part of the graph. Now it's load-bearing.

2. **Karri cluster** — from 15 → 29 inbound. Every strategy (ORB, Scalp-Overlap, Session-Breakout, Vol-Expansion) now links directly, not just via `Strategy-Proposal-Workflow`. Strategy-Promotion-Workflow + operations/Karri.md became proper hubs.

3. **Living-state cross-pollination** — runtime-state docs now form a denser internal mesh AND link back to all 4 canonical targets. Means: if Claude lands on `gemini-pipeline-state` first, two hops reach Foundation-Gate, Operator-Principles, Truth-Hierarchy, and the relevant decision-tree.

## Estimated backlink-density change

Average inbound count for the 4 target hubs: was (37+53+11+15)/4 = 29.0; now (49+69+39+29)/4 = 46.5. **+60% average density on the four canonical hubs.**

Counted in terms of new wiki-link *edges* (each `[[Target]]` insertion in a body = 1 edge): approx **70 net new edges** across 28 touched notes.

## Discipline observed

- No new notes created (per brief).
- No code commits (vault-only).
- All edits used Edit/replace, never Write.
- Links added only where genuinely relevant — no link-spam. Several modules (e.g. Module-ORB to Truth-Hierarchy) were declined because the relationship is indirect.

## Constraint not yet addressed

- `Foundation-Gate` has two notes resolving the same wiki-link: `01-nexus/operations/Foundation-Gate.md` (atomic) and `_maps/Foundation-Gate.md` (status-snapshot). Obsidian picks one ambiguously. Not fixed here — would require renaming and updating ~40 inbound references. Flag for future round.
- Same dual-resolution risk on `Karri`, `Operator-Principles`. Same trade-off. Future round candidates.

## Verification
- `grep -rln "\[\[<target>" --include="*.md"` run before/after for all 4 targets.
- Spot-checked a handful of edits via re-read.
