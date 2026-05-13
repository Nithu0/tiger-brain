# A1 — persistRegimeDirectionDecision (observability)

**Date:** 2026-05-13 (Round 3)
**Scope:** instrumentation-only. No behavior change. Karri-compliant.

## Problem

`regime_direction_gate` had **no persist-to-DB helper**. Decisions lived only in `BladeDecision.checks` in-memory. Even with `REGIME_DIRECTION_GATE_ENABLED=true`, the gate was invisible in `gate_decisions`. Sibling `daily_trade_cap` already had `persistDailyCapDecision()` — I mirrored that pattern.

## Files modified

- `apps/worker/src/firm/strategy-blade.ts`
  - **L36–40:** added `type RegimeDirectionGateDecision` to the gate import.
  - **L133–177 (regime-direction block):** inserted a `persistRegimeDirectionDecision(...)` call right after `evaluateRegimeDirectionGate(...)` (mirrors timing of daily-cap's persist — before the reject branch).
  - **L433–476 (new helper, appended above `_internal` export):** added `persistRegimeDirectionDecision()` — INSERTs into `gate_decisions` with `gate_name='regime_direction_gate'`.

No edits to `gates/regime-direction-gate.ts` itself (kept pure-logic as documented in its header).

## Persist signature

```ts
async function persistRegimeDirectionDecision(
  db: Pool,
  cycleId: string | null,
  strategyId: string,
  direction: "long" | "short",
  regime: string | null,
  regimeDirection: RegimeDirection,
  decision: RegimeDirectionGateDecision,
): Promise<void>
```

Writes to `gate_decisions` columns: `id` (randomUUID), `decision_cycle_id`, `symbol='XAUUSD'`, `gate_name='regime_direction_gate'`, `would_reject`, `hard_rejected`, `reason`, `context` (JSONB).

**Context payload:** `{ strategyId, direction, path: "strategy_blade", regime, regimeDirection, detail: decision.reason }` — enough for Karri to audit rejection clusters before tuning.

## Deviation from daily_trade_cap pattern

- **Extra fields in signature:** `regime` and `regimeDirection` — daily-cap doesn't need market context. Regime-direction's whole point is the regime/direction tuple, so they go in context JSON for diagnostic value.
- **`hardRejected == wouldReject`:** same as daily-cap (we only persist when env flag is on; soft-log mode = flag off = no persist call at all).
- **`reason` column:** populated from `decision.reason` for both allow (e.g. `"with_trend"`, `"not_mean_reversion_strategy"`) AND reject cases. Daily-cap only stores a reason on reject (null otherwise). Storing allow-reasons too gives a richer audit trail — gate behaviour analyser can see "why did it allow" without re-running the logic.

That last point is the only meaningful divergence. Justification: zero cost (one TEXT column), big upside for forensics.

## Verification

```
cd apps/worker && npx tsc --noEmit
→ clean (no output)
```

Tests:
```
node --test src/firm/gates/regime-direction-gate.test.ts src/firm/strategy-blade.test.ts
→ 36/36 pass
```

Pre-existing test failure in `daily-trade-cap-gate.test.ts` (SQL regex mismatch from a parallel agent's edit to daily-cap's query) is **unrelated** to this work — flagged for main thread.

## Not done (per instructions)

- No `git add`, no `git commit`. Files left modified for main-thread review.
- No new tests for the persist helper itself. Pattern matches daily-cap, which also has no dedicated persist-helper unit test (covered indirectly by strategy-blade integration tests).
