---
date: 2026-05-13
type: audit
project: nexus
status: open
---

# Gate persistence audit — 2026-05-13

Read-only audit. Background: 2 gates in last week (regime_direction_gate, sl_cooldown) had same persistence bug — evaluated but didn't write `gate_decisions` rows. Audit checks for same class across all gates.

## Method

1. Listed `apps/worker/src/firm/gates/*.ts`
2. Traced every `INSERT INTO gate_decisions` call back to source gate
3. Cross-referenced live DB (`SELECT gate_name, COUNT(*) FROM gate_decisions GROUP BY gate_name`)

## Persistence writers (only 4 in the entire codebase)

| Writer | File | Gates it persists |
|---|---|---|
| `persistGateDecisions()` | `gates/new-gates.ts:230` | risk_level, scalp_overlap_asia, ranging_conviction, entry_stack_cooldown, session_block |
| `persistDailyCapDecision()` | `strategy-blade.ts:406` | daily_trade_cap |
| `persistRegimeDirectionDecision()` | `strategy-blade.ts:449` | regime_direction_gate |
| `persistSlCooldownDecision()` | `strategy-blade.ts:494` | sl_cooldown |

## Live DB state (gate_decisions GROUP BY gate_name)

| gate_name | rows | most_recent (UTC) |
|---|---:|---|
| risk_level | 1987 | 2026-05-12 17:35 |
| scalp_overlap_asia | 1987 | 2026-05-12 17:35 |
| ranging_conviction | 1987 | 2026-05-12 17:35 |
| entry_stack_cooldown | 1965 | 2026-05-12 17:35 |
| daily_trade_cap | 8 | 2026-05-12 17:35 |
| session_block | 8 | 2026-05-12 17:35 |
| (regime_direction_gate) | 0 | — |
| (sl_cooldown) | 0 | — |
| (mean_revert) | 0 | — |

Note: `most_recent` 12.5 17:35 is consistent across all rows — likely a recent Railway redeploy with no live trading since (weekend or restart). Volume gap (8 vs 1987) for `session_block`/`daily_trade_cap` is expected — those only persist when their own flag is on AND the cycle hits the relevant branch.

## Classification

### GREEN — persistence wired + rows visible (6)

- `risk_level`
- `scalp_overlap_asia`
- `ranging_conviction`
- `entry_stack_cooldown`
- `session_block`
- `daily_trade_cap`

### YELLOW — persistence wired but 0 rows (2, both expected for the moment)

- `regime_direction_gate` — fix landed `deb7075` (today 09:35 CET). 0 rows until Railway picks up the deploy and live cycles run with `REGIME_DIRECTION_GATE_ENABLED=true`. Re-check after next deploy.
- `sl_cooldown` — peer agent adding persistence right now. Will go GREEN once their PR lands + flag is on. Re-check after deploy.

### RED — no persistence call (1, same bug class as sl_cooldown)

- **`mean_revert`** — `apps/worker/src/firm/gates/mean-revert-gate.ts`. Called from `strategy-execution.ts:447` via `evaluateMeanRevertGate(...)`. Decision is logged via `logInfo` + `shadow()`, but NEVER writes a `gate_decisions` row (no `persistMeanRevertDecision()` exists, no call to `persistGateDecisions()`). Shipped today in `b31fbae` ("feat(gates): cross-strategy mean-revert-gate (Task D MVP)"). Default OFF (`MEAN_REVERT_GATE_ENABLED=false`) so no impact yet, but same class as the sl_cooldown bug — the moment operator flips this flag on, the gate will silently block trades with zero audit trail in `gate_decisions`.

## Not gates in the audit sense (info, not bugs)

The following are inline checks in `strategy-blade.ts` that predate the `gate_decisions` audit pattern and were never intended to persist there. Logged for completeness:

- `event_policy` (`strategy-blade.ts:232`) — inline news-blackout check, no DB write.
- `risk_veto` (`strategy-blade.ts:260`) — inline shield-risk check, no DB write.
- `master` — bypass marker when `STRATEGY_BLADE_ENABLED=false`.

If operator wants full audit coverage on these too, that's a separate piece of work — but they don't fit the "same bug class as sl_cooldown" pattern because they were never claimed to persist.

## Recommended action (no edits applied — operator-gated)

1. Add `persistMeanRevertDecision(db, cycleId, strategyId, direction, decision)` to `strategy-blade.ts` mirroring the other three single-decision persisters, OR
2. Move `evaluateMeanRevertGate` call from `strategy-execution.ts` into `strategy-blade.ts` and persist it next to the other three Karri-proposal gates. Option 2 is cleaner — keeps all gate persistence in one file.

Either fix is small (~30 LOC) and follows the existing pattern exactly. No schema change needed (`gate_decisions` already accepts arbitrary `gate_name`).

## Open questions for operator

- Mean-revert-gate landed without a `docs/strategy/proposals/` doc per `b31fbae` — was this approved verbally? If yes, file retroactively.
- Should we add a foundation-monitor rule that flags "gate code shipped without persistence" automatically, so this doesn't recur?
