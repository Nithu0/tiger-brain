# A2 — null_reason tagging for classifyTrendDirection

**Date**: 2026-05-13 (round-3 forensics, observability-only)
**Status**: implemented locally, NOT committed (per task spec)
**Goal**: every null-return from the regime-direction classifier now carries a distinct, queryable tag so we can identify which of the 5+ null-paths drives 97.7% of TRENDING blackboard messages having `regimeDirection=null`.

## Reason-tag enumeration (11 total, 9 distinct null-paths)

Added as discriminated string-union `RegimeDirectionReason` in `regime-direction.ts`:

| Tag | Where | Meaning |
|---|---|---|
| `ok_up` | classifier success | direction = "UP" |
| `ok_down` | classifier success | direction = "DOWN" |
| `not_trending` | portfolio-brain skip | regime !== TRENDING, classifier never invoked |
| `candles_empty` | portfolio-brain + classifier | fetchCandles() returned `[]` |
| `fetch_error` | portfolio-brain catch | fetchCandles() threw |
| `candles_not_array` | classifier defensive | !Array.isArray(candles) — should never fire in prod |
| `candles_too_short_close_move` | close_move | length <= CLOSE_MOVE_LOOKBACK (4) |
| `candles_too_short_ema_slope` | ema_slope | length < EMA_PERIOD + EMA_SLOPE_WINDOW (26) |
| `non_finite_close` | both methods | NaN/Infinity in any close used in calc |
| `flat_close_move` | close_move | latest_close === past_close (exact tie) |
| `flat_ema_slope` | ema_slope | EMA(latest) === EMA(past) (slope ≈ 0) |

The prior code had 5 textual null-returns in `regime-direction.ts` and 2 more in `portfolio-brain.classifyTrendDirection` (`candles_empty` early-exit + catch) — confirmed 7 distinct paths, expanded to 9 null reasons by separating method-specific too-short / flat paths and adding `not_trending` for the upstream skip.

## Files modified (4)

1. **`apps/worker/src/firm/regime-direction.ts`** — exported new `RegimeDirectionReason` union + `RegimeDirectionResult` interface. Changed `classifyRegimeDirection`, `classifyByCloseMove`, `classifyByEmaSlope` return type from `RegimeDirection` (`"UP"|"DOWN"|null`) to `RegimeDirectionResult` (`{ direction; reason }`). Logic identical.
2. **`apps/worker/src/firm/portfolio-brain.ts`** — `RegimeAssessment` interface gained `regimeDirectionReason: RegimeDirectionReason`. `classifyRegime` now captures both direction and reason; logs `[firm.portfolio-brain] regime-direction null in TRENDING regime — reason=<tag>` at info-level on every null. `classifyTrendDirection` rewritten to return `{ direction, reason }`. Blackboard publish includes `regimeDirectionReason` field (persisted via JSON state column).
3. **`apps/worker/src/firm/regime-direction.test.ts`** — all 8 cases rewritten to assert on `r.direction` and `r.reason` separately. New assertions specifically exercise each reason tag.
4. (no change needed to `gates/regime-direction-gate.ts` — wire format `regimeDirection` field unchanged, only sibling `regimeDirectionReason` added)

## Caller-update list

- `strategy-blade.ts:138` — still reads `state.regimeDirection`, unchanged wire format. New `regimeDirectionReason` is a passive sibling field; gate can opt in later.
- `regime-direction-gate.ts` — input type unchanged, still takes raw `RegimeDirection`. No update needed.
- All other 18 consumers of `xauusd.portfolio.context` read only `state.regime` — no change required.
- `strategy-blade.test.ts` / `regime-direction-gate.test.ts` — mock `regimeDirection` field directly; unaffected.

## Persistence

`blackboard.publish` serialises `state` to JSON (column `blackboard.state`). The new field flows through automatically — no migration needed. Query path:

```sql
SELECT state->>'regimeDirectionReason' AS reason, COUNT(*)
FROM blackboard
WHERE topic='xauusd.portfolio.context'
  AND state->>'regime'='TRENDING'
  AND timestamp > NOW() - INTERVAL '24 hours'
GROUP BY reason ORDER BY 2 DESC;
```

Also: every null-path now produces a queryable Railway log line `regime-direction null in TRENDING regime — reason=<tag>` even before blackboard messages accumulate.

## tsc result

```
cd apps/worker && npx tsc --noEmit
→ exit 0 (clean)
```

Test run: **539/539 green** (up from 478 — repo's grown; counted from `npm test` in apps/worker).

## What this does NOT do

- No logic change — `regimeDirection` field on blackboard carries the same values as before. Gate behaviour unchanged.
- No DB migration. State column is JSONB, accepts the new key automatically.
- Files left modified, NOT staged or committed (per task spec).
