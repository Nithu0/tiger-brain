# A3 — `atr_at_entry` for `xau-session-breakout`

**Date:** 2026-05-13 (round 3)
**Task:** Make session-breakout record `atr_at_entry` on its trade rows
(pure observability bug — Karri needs ATR context for SL-method debate).

## Root cause

`strategy-execution.ts` line ~745 stamps `atr_at_entry` via:

```ts
const proposalAtrRaw = (proposal.state.atr ?? proposal.state.atr14) as number | undefined;
```

`xau-volatility-expansion` puts `atr14` in its signal state, `xau-scalp-overlap`
puts `atr` — both stamp correctly. `xau-session-breakout`'s `SBSignalOutput`
had neither field, so `proposal.state.atr` was always `undefined` →
`atr_at_entry = NULL` for every row in `trades`/`simulated_orders`.

The strategy did not compute ATR internally (SL/TP are range-derived), so
the fix had to add a parallel observability-only ATR fetch.

## Files modified

- `apps/worker/src/firm/session-breakout/config.ts`
  - Added `SB_CONFIG.atrPeriod` (env `SESSION_BREAKOUT_ATR_PERIOD`, default 14,
    bounds 5–50). Mirrors `VE_CONFIG.atrPeriod` convention.
- `apps/worker/src/firm/session-breakout/session-break-manager.ts`
  - Imported `fetchATR` from `market-data.service`.
  - Added `atr: number | null` to `SBSignalOutput`.
  - Fetched `fetchATR("XAUUSD", "1h", SB_CONFIG.atrPeriod)` right before
    constructing the signal (after criteria, before publish). Wrapped in
    `.catch(() => null)` so Twelve Data outages cannot block trading.
  - Included `atr` in `publishSessionBreakState`'s FACT row for symmetry
    with downstream snapshot analytics.

## ATR source

H1 ATR(14) via Twelve Data — same call shape vol-expansion uses
(`fetchATR("XAUUSD", "1h", 14)`). The strategy itself doesn't consume ATR;
it is captured purely as decision-context for the trade row. `strategy-
execution.ts` consumes it unchanged via the existing
`proposal.state.atr ?? proposal.state.atr14` pattern — no edits needed
there.

## TSC result

`cd apps/worker && npx tsc --noEmit` → **exit 0, clean.**

## Edge cases noted

1. **Twelve Data outage / rate-limit.** `fetchATR` returns `null` (or the
   `.catch` returns `null`). We log `H1 ATR(14) unavailable — proceeding
   with entry, atr_at_entry will be NULL` and proceed with the trade.
   `atr_at_entry` is left **NULL** on the row, not `0`. Reasoning: a `0`
   would silently corrupt any downstream `ATR-vs-risk` ratio (division by
   zero, or false "regime calm" signal). Per operator-prinsipp 1
   ("rapporter, ikke gjett"), missing → NULL.
2. **`atr <= 0` from API.** Treated identically to `null` → NULL on row.
3. **Strategy is OFF by default** (`SESSION_BREAKOUT_ENABLED`). No risk of
   live impact from the ATR call itself until operator flips the flag.
4. **Cost.** Adds one Twelve Data call per session-breakout signal cycle.
   Strategy fires ≤2 trades/day with internal caps + watch windows, so
   call volume is negligible.
5. **SL methodology unchanged.** This is observability only — SL still =
   opposite side of source range. Karri's SL debate now has the ATR
   numerator he needs for any "is the SL N×ATR wide?" comparison.

## Status

Files modified, NOT staged, NOT committed (per task instructions).
Ready for Karri review of any follow-on SL-method proposal.
