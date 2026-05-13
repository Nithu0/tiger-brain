# Postmortem enum reachability — proposal to wire BAD_TIMING

Round 6 / C4 follow-up. Round 5 audit (`postmortem_tag_audit.md`) showed 3 of 6 `FailureClass` enums never emitted across 49 PMs:
`RIGHT_THESIS_BAD_TIMING`, `RIGHT_THESIS_BAD_INVALIDATION`, `NO_TRADE_SHOULD_HAVE_WON`.
RTBE swallows 90.3% of labeled losers — a monoculture that masks distinct failure modes.

Source: `apps/worker/src/firm/postmortem.ts:168-232`.

## Why each enum is currently unreachable in practice

### 1. `RIGHT_THESIS_BAD_TIMING` (line 213)
Only reachable via `wasChasing === true`. `isChasing` is set in `entry-thesis.ts:162` as `adx > 50` — a single, narrow proxy. In 49 PMs not a single one tripped this gate. ADX > 50 is rare on M5 XAUUSD, and the firm's strategies (vol-exp, ORB, session-breakout) tend to fire on regime *transitions* where ADX is climbing through 25–35, not already past 50. The branch exists, the condition almost never trips.

### 2. `RIGHT_THESIS_BAD_INVALIDATION` (line 225)
Only reachable when `Math.abs(pnl) < 20`. Default risk in production puts SL at ~1.5×ATR, which translates to ~$30–80 PnL on a typical XAUUSD loser. So losses < $20 are essentially position-sizing rounding noise, not invalidation quality signals. Branch is dead by construction.

### 3. `NO_TRADE_SHOULD_HAVE_WON` (line 228)
The final-else branch. Only reached if NOT counter-trend, NOT directionally-wrong+SL, NOT chasing, NOT chaotic, executionWindowScore ≥ 50, AND |pnl| ≥ 20. In a properly-gated decision pipeline this combination is rare — every trade was approved with execution score ≥ 50. The name is also wrong: this hook only fires after a close, never on no-trade. The label "should have won" is meaningless here.

## Proposed BAD_TIMING wiring (highest leverage per round 5 audit)

Replace the `wasChasing` check with a richer composite. Concrete criteria for `RIGHT_THESIS_BAD_TIMING`:

> Trade direction was correct (peak_price moved favorably ≥ 1×ATR from entry) BUT was reversed before TP. Implies thesis right, entry mistimed (entered too late OR too early relative to the reversal).

Operational signals available in `simulated_orders` + management events:
- `peak_price` — best favorable price since open (already read at line 289).
- `entry_price`, `direction`, `atr_at_entry` — already in scope.
- `opened_at`, `session_at_entry` — DB columns, would need to add to the existing query at line 248.

### Implementation sketch (~20 LOC)

In the loser branch around line 205, add a new gate BEFORE the `executionWindowScore < 50` check:

```ts
// MFE-based timing check: did price move our way before reversing?
// Compute only when we have peak_price + atr.
const mfePoints = trade.direction === "long"
  ? (peakPrice ?? trade.entryPrice) - trade.entryPrice
  : trade.entryPrice - (peakPrice ?? trade.entryPrice);
const mfeAtrRatio = atrAtEntry && atrAtEntry > 0 ? mfePoints / atrAtEntry : null;

// Direction was correct (MFE ≥ 1×ATR) but trade still closed for a loss.
// Either entered too late (gave back the move) or too early (got stopped on
// retest before continuation). Either way: thesis right, timing wrong.
if (!counterTrend && mfeAtrRatio != null && mfeAtrRatio >= 1.0) {
  failureClass = "RIGHT_THESIS_BAD_TIMING";
  lessons.push(
    `Price moved ${mfeAtrRatio.toFixed(2)}×ATR favorably (peak $${peakPrice?.toFixed(2)}) ` +
    `before reversing — thesis right, timing off`
  );
  lessons.push("Review entry trigger sequencing: too late on chase, or too early on retest");
}
```

Requires plumbing `peakPrice` + `atrAtEntry` from the management-classify block (line 256-289) up to the failure-class branch. Easiest path: hoist the SELECT at line 248 above the loser-branch, share the values.

`wasChasing` branch becomes a *secondary* signal that augments the lesson text but no longer the sole gate.

## Test cases needed

1. `peak_price >= entry + atr` on a losing LONG → BAD_TIMING (new path).
2. `peak_price < entry + atr` on a losing LONG with directionCorrect=false + SL → WRONG_THESIS (unchanged).
3. Counter-trend short in TRENDING regime, peak moved favorably → still WRONG_THESIS (counterTrend gate first, unchanged).
4. Missing peak_price OR missing atr → falls through to legacy path (unchanged).
5. Win path → still CORRECT_THESIS (unchanged).

## Expected distribution impact

Hand-spot-check on round 5 data: 16/28 RTBE trades have peak_price > entry+1×ATR in `simulated_orders`. If accurate, BAD_TIMING would absorb ~57% of the current RTBE bucket, splitting the monoculture roughly RTBE 41% / BAD_TIMING 47% / WRONG 10% / other 2%. Needs SQL verification before final commit.

BAD_INVALIDATION and NO_TRADE_SHOULD_HAVE_WON stay unreachable in this proposal — recommend deprecating both from the enum in a separate cleanup, OR rewiring them with concrete criteria once BAD_TIMING ships and we see what's left.

## Operator decision

Bug-fix vs. Karri proposal:

- **Argument for bug-fix scope**: no behavior change in trading loop, only postmortem labeling becomes more granular. Existing RTBE consumers (`trade-critic.ts`, `strategy-tuner.ts`, `daily-journal.ts`) feed text into LLM prompts — they receive richer tag, no logic change.
- **Argument for Karri proposal**: postmortem tags ARE downstream-consumed by LLM advisory agents, and Karri may want to define the criteria himself (e.g. 0.8×ATR vs 1.0×ATR threshold). Cohort shape changes downstream training data once `agent_lessons` is activated.

**Recommendation**: file as Karri proposal. The 1.0×ATR threshold is the kind of arbitrary number he should bless. Low urgency — observability hardening, not a money-impact change. Auto-send during work hours per `feedback_auto_send_karri.md`.

Branch suggestion: `feat/postmortem-bad-timing-enum-wiring`.
