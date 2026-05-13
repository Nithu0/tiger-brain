---
tags: [moc, nexus, trading]
type: moc
created: 2026-05-08
---

# Nexus-MOC

Central map for the Nexus domain. Nexus is an autonomous XAUUSD (spot gold) trading firm running on OANDA practice — multiple specialized agents on a shared blackboard, narrow responsibilities, bounded safety rails. Currently demo-mode, calibrating before live-capital flip.

Repo lives at `/home/nithu/code/ai-assistent`. Live truth always lives in `apps/worker/src/firm/orchestrator.ts:runCycle()` and `docs/ops/phase-status.md`. This MOC just points.

## Brain (decision trees + runbooks)

Autonomous-decision scaffolding added 2026-05-11. Read these before asking the operator — they cover the recurring patterns.

**Decision-trees** (`_decisions/` — when X happens, do Y):
- [[When-Trade-Bleeds-Multi-Day]] · [[When-Gate-Goes-Silent]] · [[When-Agent-Stalls]] · [[When-Doc-Drifts-From-Code]] · [[When-Foundation-Rule-Goes-Yellow]] · [[When-Operator-Says-Kjor-Pa]] · [[When-Strategy-Change-Tempting]] · [[When-Quota-Blocks-Pipeline]] · [[When-Day-Hits-Overtrading-Pattern]]

**Runbooks** (`_runbooks/` — how to execute):
- [[Runbook-Push-Cycle]] · [[Runbook-Karri-Proposal-Send]] · [[Runbook-Backfill-Script-Pattern]] · [[Runbook-Multi-Agent-Dispatch]] · [[Runbook-Post-Deploy-Verification]] · [[Runbook-Quota-Upgrade]]

**Living runtime-state** (`01-nexus/runtime-state/` — one doc per subsystem, refreshed per session):
- [[discord-delivery-state]] · [[gemini-pipeline-state]] · [[codex-pipeline-state]] · [[gate-decisions-state]] · [[metadata-stamping-state]] · [[firm-agents-state]] · [[foundation-gate-state]] · [[production-loop-state]] · [[retention-state]] · [[local-mirror-safety-state]] · [[SNAPSHOT]] (one-page truth)

**Session summaries**: [[2026-05-11_full_session]] — 12-round max-mode push: foundation-gate 5/5 first time, metadata-strip fix, Gemini Tier-1, Codex Phase 2a live, ~50 commits, 478/478 tests. Linked also via [[scalp-overlap-losses-2026-05-11]] (worked example feeding [[When-Trade-Bleeds-Multi-Day]]).

## Modules

The 10 firm modules — orchestrator coordinates, opinion comes from specialists.

- [[Module-Orchestrator]] — stage manager; `runCycle()` schedules every step in order
- [[Module-Blackboard]] — typed pub/sub messaging between agents
- [[Module-Fact-And-Analysis-Agents]] — Prism: pull raw data, publish typed analyses
- [[Module-ORB]] — Opening Range Breakout detector + state machine + manager
- [[Module-Position-Management]] — Blade lifecycle: break-even, partials, trailing, stale
- [[Module-Exposure-And-Shield]] — Forge + Shield: exposure caps, news blackout, vetoes
- [[Module-Postmortem]] — Atlas: trade classification + firm memory writes
- [[Module-Reconciliation]] — OANDA two-way sync + drift monitor
- [[Module-Notifications]] — Discord morning briefing + typed events
- [[Module-Agent-Bus]] — dormant multi-model orchestration scaffolding

## Strategies

Currently TIER 3 — four strategies parallel, all behind env flags.

- [[Strategy-ORB]] — Opening Range Breakout, London 08:00 — flagship, LIVE
- [[Strategy-Scalp-Overlap]] — RSI mean-reversion during London-NY overlap
- [[Strategy-Session-Breakout]] — break of prior session range at London/NY open
- [[Strategy-Vol-Expansion]] — enter when ATR expansion ratio ≥ 1.3
- [[Strategy-Promotion-Workflow]] — how strategies graduate shadow → live

## Gates and risk

- [[Foundation-Gate]] — five rules that must be green before any new strategy
- [[OK-Kjor-Gate]] — operator-approval gate before every push / activation
- [[Operator-Principles]] — six binding prinsipper (no auto-disable, data never stops, etc)
- [[Strategy-Proposal-Workflow]] — `docs/strategy/proposals/` flow, [[Karri]] reviews

## Operations

- [[Reconciliation]] — broker vs DB sync; how the audit found the $1,073 delta
- [[Demo-Mode]] — currently `DEMO_AUTO_DEGRADE_ENABLED=false`, report-only
- [[Position-Management-Operations]] — what the master switch turns on
- [[Phase-Status-Pointer]] — never duplicate live state here; read repo file

## Live-state

- [[Live-Endpoints]] — Railway URLs for `/health`, `/diagnostic/broker`, `/operator/*`, `/firm-agents/*`
- [[Phase-Status-Pointer]] — single source of truth lives in repo

## Pending decisions

- Foundation-gate rule 4 (gate-data maturity) tracking — see [[Foundation-Gate]]
- Agent Bus activation gated on foundation green + OK kjør — see [[Module-Agent-Bus]]
- Reconciliation cleanups awaiting operator-approved SQL — see [[Reconciliation]]

See also `_repo-docs/` symlink for full repo docs from inside the vault.
