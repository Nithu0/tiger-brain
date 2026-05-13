---
date: 2026-05-13
type: bug-investigation
project: nexus
status: open
---

# Thesis-score JOIN audit — TIER 3 silently writes 0/100

## TL;DR

Postmortems show market_score/entry_score/execution_score uniformly 0 or NULL for **100% of recent firm-driven trades**, not ~50% as suspected. The reported "decisionCycleId JOIN misses sometimes" was a red herring — the JOIN actually succeeds for recent firm-path trades, **but the DECISION on the other end of the JOIN has no thesis-score fields to read**.

Root cause: the TIER 3 execution path (`apps/worker/src/firm/strategy-execution.ts`) publishes `xauusd.manager.decisions` DECISION messages that omit `marketThesisScore`, `entryThesisScore`, `executionWindowScore`. The postmortem reader (`apps/worker/src/firm/postmortem.ts:108-110`) defaults each missing number to 0. Since 17.4 the legacy `managers.ts` blade-trading-manager (which DID populate those fields) has been gated off (`LEGACY_XAUUSD_EXECUTION_ENABLED=false`), so the entire firm fleet now writes blank thesis scores.

## Miss rate (7-day window)

| Metric | Count | Note |
|---|---|---|
| Total postmortems | 92 | — |
| market_score = 0 | 28 | recent firm-path trades (30%) |
| market_score IS NULL | 64 | older oanda_import + legacy (70%) |
| market_score > 0 | **0** | **0% scored correctly** |
| entry_score IS NULL | 92 | 100% missing |
| execution_score IS NULL | 92 | 100% missing |

Of the **29 firm-path trades** closed in 7 days (`execution_source = 'firm_strategy'`):
- 28/29 (97%) have `decision_cycle_id` stamped on `simulated_orders`
- 4/29 had cycle_id forwarded to `postmortems.cycle_id` (older hook code)
- 24/29 had cycle dropped in older hook code — already fixed at `postmortem-hook.ts:186` (`r.decision_cycle_id ?? null`)
- **0/29 have positive thesis scores**, despite 24/29 finding the correct DECISION via cycle_id JOIN

So the JOIN is NOT the limiting factor. The DECISION payload itself is empty.

## Evidence

Last 16 `xauusd.manager.decisions` rows (24h):

```sql
SELECT agent, state->>'decision', state->>'marketThesisScore' AS m,
       state->>'entryThesisScore' AS e, state->>'executionWindowScore' AS x
FROM blackboard WHERE topic = 'xauusd.manager.decisions'
ORDER BY timestamp DESC LIMIT 16;
```

→ every row: `m = null, e = null, x = null`. Agents: `strategy-execution` (approve) + `strategy-blade` (reject). Strategies: scalp-overlap, vol-expansion, session-breakout. 100% NULL.

`xauusd.manager.synthesis`: **0 messages in last 24h.** The legacy Prism synthesis pipeline (`managers.ts:257`) isn't running.

`simulated_orders.thesis_quality_score`: 0/28 populated for recent firm-path trades. The wire-through at `strategy-execution.ts:619` reads `sState?.thesisQualityScore ?? sState?.marketThesisScore` as flat fields, but `managers.ts:276` publishes `state.thesis.thesisQualityScore` (nested). Even if synthesis were alive, the path is wrong.

## Code map

- **Reader (silent-zero default)**: `apps/worker/src/firm/postmortem.ts:108-110`
  ```ts
  const marketThesisScore = tradeDecision?.state.marketThesisScore as number ?? 0;
  const entryThesisScore = tradeDecision?.state.entryThesisScore as number ?? 0;
  const executionWindowScore = tradeDecision?.state.executionWindowScore as number ?? 0;
  ```

- **Writer A — legacy, FULL fields**: `apps/worker/src/firm/managers.ts:632-647` (blade-trading-manager) — gated off by `LEGACY_XAUUSD_EXECUTION_ENABLED=false` since 17.4.

- **Writer B — TIER 3, EMPTY fields**: `apps/worker/src/firm/strategy-execution.ts:866-872`
  ```ts
  state: { decision: "APPROVED", direction, strategy, orderId, cycleId }
  ```
  No thesis scores.

- **Hook**: `apps/worker/src/firm/postmortem-hook.ts:128, 186` correctly forwards `decisionCycleId`. JOIN side is fine.

- **Synthesis nested-field gotcha**: `managers.ts:276` publishes `state.thesis = {thesisQualityScore, ...}` (nested). `strategy-execution.ts:619` reads `sState?.thesisQualityScore` (flat). Independent bug — would mask the wire-through even if synthesis were running.

## Proposed minimal fix

Two layers:

1. **Stop the bleeding (observability-only, no money impact)** — in `strategy-execution.ts:866` extend the APPROVED-DECISION state with the already-captured `thesisQualityScore` (line 613-622) and proposal-derived entry/execution scores. Also fix the nested-path read at line 619: `sState?.thesis?.thesisQualityScore ?? sState?.thesisQualityScore ?? sState?.marketThesisScore`. ~15 LoC. **Can ship without Karri review** — pure read-back of existing data, no strategy logic change.

2. **Real fix (Karri-gated)** — each TIER 3 strategy manager (`scalp-manager.ts`, `vol-exp-manager.ts`, `session-break-manager.ts`, `orb-manager.ts`) needs to publish its own market/entry/execution score on the PROPOSAL, derived from setup quality + session fit. `strategy-execution.ts` then forwards them into the DECISION. This is a per-strategy scoring-schema decision → strategy proposal.

3. **Parallel investigation** — why is `xauusd.manager.synthesis` dead in TIER 3 mode? Either Prism should be running alongside TIER 3, or TIER 3 should be self-sufficient. Currently neither.

**Recommendation**: ship #1 immediately (observability-only), file #2 as `docs/strategy/proposals/2026-05-13_tier3_thesis_scores.md` for Karri, run #3 as a separate orchestrator-side audit.

## Open questions for operator/Karri

- Is Prism's `xauusd.manager.synthesis` supposed to be alive in TIER 3 mode, or deliberately bypassed when `LEGACY_XAUUSD_EXECUTION_ENABLED` flipped off?
- What scoring schema should each TIER 3 strategy use for market/entry/execution scores?
- Until thesis-scores are populated, every postmortem-driven feedback loop (failure-class classifier, agent_lessons, postmortem_streaks scaling) is operating on garbage. How urgent is the fix vs the 0-day strategy proposal queue?
