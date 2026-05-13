---
title: Strategy Mini-Blade gate-stack — TIER 3 safety architecture
source: Nexus apps/worker/src/firm/strategy-blade.ts + gates/ + round 2 forensics
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 5
claude_priority: P0
tags: [library, concept, blade, gates, shadow-mode, architecture]
status: distilled
---

# Strategy Mini-Blade gate-stack

## What it is

The **Strategy Mini-Blade** (`apps/worker/src/firm/strategy-blade.ts`) is a focused cross-strategy approval layer that sits between a strategy's **PROPOSAL** and the actual OANDA **EXECUTION**. Every firm strategy (xau-orb, xau-scalp-overlap, xau-session-breakout, xau-vol-expansion, and now S4 mean-reversion) calls `evaluateStrategySignal()` before `tryOpenPosition`.

It replaces the original TIER 1-2 Blade-Prism synthesis pipeline. TIER 3 deliberately drops Prism synthesis and challenge-agents in favour of a **thin safety-gate layer**: forge exposure, Shield risk-veto, event-policy, plus a bundle of newer gates. Each gate is independently env-toggleable so operator can enable layer-by-layer rather than flip the whole stack.

## Master switch

`STRATEGY_BLADE_ENABLED` (default **false**). When off, the master-dependent gates (forge, risk-veto, event-policy, new-gates bundle) bypass and the trade ships straight through. The master flag is checked **after** the env-independent gates run — see next section.

## Gate inventory (execution order)

| # | Gate | Env flag | Master-dependent? |
|---|---|---|---|
| 1 | `sl_cooldown` | `SL_COOLDOWN_ENABLED` | No — runs standalone |
| 2 | `regime_direction` | `REGIME_DIRECTION_GATE_ENABLED` | No — runs standalone |
| 3 | `daily_trade_cap` | `DAILY_TRADE_CAP_ENABLED` | No — runs standalone |
| 4 | `event_policy` (news blackout) | `STRATEGY_BLADE_EVENT_POLICY` | Yes (default true) |
| 5 | `risk_veto` (Shield extreme) | `STRATEGY_BLADE_RISK_VETO` | Yes (default true) |
| 6 | `new_gates` bundle | `STRATEGY_BLADE_NEW_GATES` | Yes (default true) |
| 7 | `forge_exposure` (cross-strategy cap) | `STRATEGY_BLADE_FORGE_CHECK` | Yes (default true) |

The `new_gates` bundle (step 6) contains five sub-gates, each with its own hard-flag (default **false**):

- `risk_level` — `RISK_LEVEL_HARD_GATE_ENABLED`
- `scalp_overlap_asia` — `SCALP_OVERLAP_ASIA_BLOCK`
- `ranging_conviction` — `RANGING_CONVICTION_GATE_ENABLED`
- `entry_stack_cooldown` — `ENTRY_STACK_COOLDOWN_ENABLED`
- `session_block` — `SESSION_BLOCK_ENABLED`

The mean-revert gate (`MEAN_REVERT_GATE_ENABLED`) lives in `gates/mean-revert-gate.ts` and is invoked from strategy-execution alongside the blade.

## The shadow-mode pattern

This is the **core architectural idea**. New gates ship with `hardFlags = false`:

```ts
hardRejected: wouldReject && hardFlags.<gate_name>
```

The gate fully **computes** the would-reject decision and **persists it** to the `gate_decisions` table (`would_reject = true`, `hard_rejected = false`) — but does **not actually block the trade**. This gives a minimum 14d of shadow-log before activation so we can tune thresholds against real data rather than guesswork.

**Round 2 forensics (last 7d)**: 24 `would_reject` vs 4 `hard_reject`. Gates are observing correctly but only sl_cooldown + regime_direction + daily_trade_cap have been promoted to hard-block. The other five new-gates are still in shadow.

## The persist-helper pattern

Every gate **must** write a row to `gate_decisions`. The audit trail is the only way to assess gate quality before enforcement.

- `new-gates.ts` exposes `persistGateDecisions(db, cycleId, bundle, context)` — batched insert, one row per evaluation.
- `daily-trade-cap` and `regime_direction` use bespoke `persistDailyCapDecision` / `persistRegimeDirectionDecision` helpers in `strategy-blade.ts`.
- All persist calls are non-fatal: `.catch(() => {})` — audit logging must never take down a trading cycle.
- **A1 fix today (round 2)**: regime_direction was missing its persist call, so the gate was running blind. Fixed — every gate now emits an audit row.

`gate_decisions` schema: `(id, decision_cycle_id, symbol, gate_name, would_reject, hard_rejected, reason, context jsonb)`.

## Failure modes Claude must NOT introduce

1. **Silent gate** — skipping `persistGateDecision(...)`. If no audit row, the gate is invisible to forensics and operator cannot tune it.
2. **Hard-block before shadow data** — flipping a new gate's hard-flag without ≥14d of `would_reject` data. We have no idea if the threshold matches reality until then.
3. **Coupling env-independent gates to `STRATEGY_BLADE_ENABLED`** — sl_cooldown, regime_direction, and daily_trade_cap must run regardless of the master. Operator's mental model: each cooldown/cap is an isolated safety lever.
4. **Fail-closed on lookup errors** — every gate falls back to "allow" on DB / blackboard errors. A broken `firm_state` table must never stop trading.

## Cross-references

- **Defensive software / circuit-breaker pattern** — each gate is independently flagged, independently rollback-able, instant off via Railway env.
- **Layered-veto pattern** — first failed gate short-circuits the rest; no gate ever overrides another's reject. See `finalize()` helper.
- **Foundation gate** (`docs/ops/new-strategy-gate.md`) — strategy-level prerequisite; the blade gate-stack is the per-cycle runtime equivalent.
