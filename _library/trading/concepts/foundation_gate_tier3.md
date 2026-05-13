---
title: Foundation Gate + TIER 3 — Nexus architectural binding rules
source: Nexus CLAUDE.md + docs/ops/new-strategy-gate.md + TIER 3 archive
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 5
claude_priority: P0
tags: [library, concept, foundation-gate, tier3, operator-binding, architecture]
status: distilled
---

# Foundation Gate + TIER 3 — Nexus architectural binding rules

Two intertwined commitments that govern every strategy-touching decision in Nexus. Both are repo-enforced (lives in code + docs) so every Claude session honours them regardless of which machine or which operator-mood started the conversation.

## Foundation Gate — the 5-rule pre-flight

Before any new strategy is added (or an existing one is aggressively tuned), ALL five must be green. One red → STOP, regardless of who asks. Source: `docs/ops/new-strategy-gate.md`, enforced by `firm/foundation-gate.ts`.

1. **No KRITISKE open issues** — `docs/ops/phase-status.md` "Åpne problemer" has zero `hastegrad=KRITISK` rows.
2. **Position-management synced** — `POSITION_MANAGEMENT_ENABLED=true` on Railway Worker (requires OANDA two-way sync landed).
3. **Deploy health** — last 3 Worker builds successful on Railway, no failed builds in last 48h.
4. **At least one hard-gate has mature data** — a row in `gate_decisions` with ≥7 days of evaluations and ≥50 rows, consistent pattern.
5. **No overdue claude-followups** — `firm/followups.ts` has 0 entries with `dueDateIso <= today` AND `owner ∈ {claude, both}`.

**Why it exists**: Nexus is in early perfection-phase. Existing strategies are "proven roughly profitable". Adding new ones while the foundation has open problems is inverted priority — widens the failure surface without fixing what already drifts. Stacking complexity on a broken foundation = expensive surprises.

**What is NOT gated**: bug-fixes restoring intended behaviour, observability, disabling a strategy (safety first), tuning thresholds (own observation round still required), flipping a mature gate's enforcement.

## TIER 3 — the 4-strategy parallel deploy

Operator overrode ORB-only pivot on 26.4 and deployed 4 strategies in parallel: **ORB, scalp-overlap, session-breakout, vol-expansion**. Each lives in its own firm module under `apps/worker/src/firm/`, publishes to its own `xauusd.<strategy>.signal` topic, and is routed by `firm/strategy-execution.ts` through `firm/strategy-blade.ts` (shared hard-gate evaluator) to OANDA.

Architectural consequence: `ORB_ONLY_MODE=true` now means "bypass Prism+Blade synthesis pipeline" — NOT "only ORB runs". Each strategy has its own swim-lane (own `maxOpenPositions`, own `dailyLossLimitUsd`, own `riskPercent`). The original Blade-Prism pipeline (Fact → Analysis → Portfolio Brain → Prism synthesis → Blade proposal → Challenge → Shield → Forge → Decision) remains code-present but bypassed.

This replaces the original "synthesis-then-execute" model with **cross-strategy approval at execution time** — each strategy proposes independently; the shared gate stack approves or rejects each one.

## Operator-prinsipper that constrain everything

Binding across all sessions, all machines. Override requires explicit in-session operator word AND documentation in `docs/ops/phase-status.md` → "Midlertidige unntak".

1. **No auto-disable** of strategies, gates, or flags based on anomaly detection. Health-checks REPORT (Discord, morning briefing). Operator decides handling.
2. **Data never stops.** Even mid-cleanup: fact-agents, analysis-agents, persistence tables keep writing. Cleanup changes WHAT is kept, not WHETHER something is written.
3. **Foundation-first.** No new strategy work if any of the 5 gate-rules is red.
4. **"OK kjør" gate** before every push. No exceptions.
5. **Selvfiks/autotune is LONG-term.** Not before 30+ days of data + explicit operator OK. Until then: report, don't act.

## Why this matters to Claude

- When asked for a strategy change: check foundation-gate state FIRST. If any rule red, respond with the RØD template from `new-strategy-gate.md` — refuse work regardless of who's asking, including operator-under-pressure. The gate exists because past sessions cut corners and paid.
- When symptoms look bad (drawdown, weird gate-rejects, regime mismatch): REPORT to Discord / morning briefing. Do NOT propose auto-disable. Operator decides handling.
- When proposing tuning: file a proposal under `docs/strategy/proposals/` for Karri's review. Don't ship money-impacting changes without his sign-off — even if foundation is green.
- When seeing TIER 3 logs: remember each strategy is independent; cross-strategy correlation (e.g. all 4 long simultaneously = portfolio over-exposure) is the exposure-cap's job, not the strategy's.
