# Audit — blade_gate_stack.md distillation (round 4)

**Date**: 2026-05-13
**Target**: `~/Obsidian/Brain/_library/trading/concepts/blade_gate_stack.md`
**Length**: 697 words (frontmatter included; prose ~640) — within 500-700 target

## Source files read

1. `apps/worker/src/firm/strategy-blade.ts` (476 lines, full read)
2. `apps/worker/src/firm/gates/new-gates.ts` (full read)
3. `apps/worker/src/firm/gates/sl-cooldown-gate.ts` (grep'd for env flags)
4. `apps/worker/src/firm/gates/regime-direction-gate.ts` (grep'd)
5. `apps/worker/src/firm/gates/daily-trade-cap-gate.ts` (grep'd)
6. `apps/worker/src/firm/gates/mean-revert-gate.ts` (grep'd)
7. `docs/ref/entry-gates.md` (head, cross-check on Trinn A + FASE 5 names)

## Env flag inventory verified against source

| Gate | Flag | Default | File |
|---|---|---|---|
| Master | `STRATEGY_BLADE_ENABLED` | false | strategy-blade.ts:81 |
| sl_cooldown | `SL_COOLDOWN_ENABLED` | false | sl-cooldown-gate.ts:57 |
| regime_direction | `REGIME_DIRECTION_GATE_ENABLED` | false | regime-direction-gate.ts:64 |
| daily_trade_cap | `DAILY_TRADE_CAP_ENABLED` | false | daily-trade-cap-gate.ts:85 |
| event_policy | `STRATEGY_BLADE_EVENT_POLICY` | true | strategy-blade.ts:224 |
| risk_veto | `STRATEGY_BLADE_RISK_VETO` | true | strategy-blade.ts:251 |
| new_gates (parent) | `STRATEGY_BLADE_NEW_GATES` | true | strategy-blade.ts:268 |
| forge_exposure | `STRATEGY_BLADE_FORGE_CHECK` | true | strategy-blade.ts:330 |
| risk_level (new-gate) | `RISK_LEVEL_HARD_GATE_ENABLED` | false | new-gates.ts:112 |
| scalp_overlap_asia | `SCALP_OVERLAP_ASIA_BLOCK` | false | new-gates.ts:113 |
| ranging_conviction | `RANGING_CONVICTION_GATE_ENABLED` | false | new-gates.ts:114 |
| entry_stack_cooldown | `ENTRY_STACK_COOLDOWN_ENABLED` | false | new-gates.ts:115 |
| session_block | `SESSION_BLOCK_ENABLED` | false | new-gates.ts:116 |
| mean_revert | `MEAN_REVERT_GATE_ENABLED` | false | mean-revert-gate.ts:56 |
| Soft-log persist | `NEW_GATES_SOFT_LOG_ENABLED` | true | new-gates.ts:236 |

## Concepts covered per spec

- [x] What Strategy Mini-Blade is — TIER 3 thin safety layer between PROPOSAL and EXECUTION
- [x] Master switch behaviour (bypass when false; env-independent gates still run)
- [x] Gate inventory in execution order (sl_cooldown → regime_direction → daily_trade_cap → master-gate → event → risk-veto → new-gates bundle → forge)
- [x] Shadow-mode pattern (`hardFlags = false` default; would_reject persisted; not blocked)
- [x] Round 2 finding: 24 would_reject vs 4 hard_reject last 7d
- [x] Persist-helper pattern — three variants (`persistGateDecisions`, `persistDailyCapDecision`, `persistRegimeDirectionDecision`); A1 fix today
- [x] Failure modes — silent gate, premature hard-block, env-coupling, fail-closed
- [x] Cross-refs — defensive software / circuit-breaker / layered-veto / foundation gate

## Frontmatter

Set exactly per spec: `relevance_to_nexus: 5`, `claude_priority: P0`, `status: distilled`, tags include `library, concept, blade, gates, shadow-mode, architecture`.

## Notes / deviations

- Spec said "6-7 layers" — actual count is 7 master-stack gates (sl_cooldown, regime_direction, daily_trade_cap, event_policy, risk_veto, new_gates, forge) plus the 5 sub-gates inside `new_gates` bundle. Documented both layers explicitly in the table.
- Added `session_block` (5th new-gate, from Karri 11.5 tap-analyse) — not in spec list but present in code.
- Added mean_revert gate as a tangential cross-reference (called from strategy-execution, not strategy-blade itself).
- Did **not** include S4 commit SHA or specific shadow-data numbers beyond round 2 forensics figure operator supplied.

## Status

Distillation landed. No further action needed unless operator wants threshold-tuning data added in a follow-up round.
