---
date: 2026-05-11
tags: [nexus, vol-expansion, instrumentation, karri-proposal, phase-1]
status: implemented
proposal: docs/strategy/proposals/2026-05-11_vol_expansion_throttle_review.md
commit: f347b37
---

# Vol-expansion Phase 1 rejection-stage instrumentation

Per Karri proposal `2026-05-11_vol_expansion_throttle_review.md`. Phase 1 = instrumentation only, NO threshold change.

## What was implemented

5-stage rejection tagging on `xau-volatility-expansion` (and incidentally the other 3 firm strategies via the shared funnel — keeps the SQL filter narrow per Karri's spec, but data exists for the whole funnel if we ever want comparative analysis).

| Stage | Where instrumented | Reasons captured |
|---|---|---|
| 1. blackboard-publish | `vol-exp-manager.ts` `evaluateVolExpEntry()` wrapper | disabled, daily-cap, cooldown, insufficient candles, ratio<threshold, ATR unavailable |
| 2. blade-evaluation | `strategy-execution.ts` early returns + `shadow()` `pre-check` | no direction, missing price levels, invalid SL/TP distances, size→0 |
| 3. gate-rejection | `strategy-execution.ts` `shadow()` `mini-blade` | mini-Blade rejected (exposure, event-policy, risk-veto, new-gates) |
| 4. portfolio-cap | `strategy-execution.ts` `shadow()` `daily-loss` + `cap-reached` | per-strategy max-open, daily-loss-limit, tryOpenPosition null (bot cap / risk gate) |
| 5. execution-fail | `strategy-execution.ts` `shadow()` `oanda-reject` | OANDA refused order (size, margin, API error) |

## Files touched

- `apps/worker/src/firm/signal-rejection-log.ts` (new — defensive publisher + ShadowBlockStage→RejectionStage map)
- `apps/worker/src/firm/signal-rejection-log.test.ts` (new — 8 unit tests)
- `apps/worker/src/firm/vol-expansion/vol-exp-manager.ts` (Stage 1 wiring)
- `apps/worker/src/firm/strategy-execution.ts` (Stages 2–5 via shadow piggy-back + early-return tagging)
- `apps/worker/package.json` (added test to runner)

## Defensive contract

- `publishSignalRejection()` swallows all errors. Validated by `never throws when board.publish throws` test.
- All call-sites use `void publishSignalRejection(...)` — fire-and-forget. No critical path awaits the rejection log.
- Topic message `expiresInSeconds: 30*24*3600` (30d) so 14d query window has full coverage with margin.

## Verify

- tsc: clean (worker workspace)
- tests: 496/496 pass (was 488 before — added 8 from `signal-rejection-log.test.ts`)
- commit: `f347b37`
- No env-flag. No behavioural change. No DB migration.

## 14d verification SQL (run via `mcp__nexus-pg__query`)

```sql
SELECT
  state->>'stage'  AS stage,
  state->>'reason' AS reason,
  COUNT(*)         AS n
FROM blackboard
WHERE topic = 'xauusd.signal.rejected'
  AND state->>'strategy_id' = 'xau-volatility-expansion'
  AND timestamp > NOW() - INTERVAL '14 days'
GROUP BY stage, reason
ORDER BY COUNT(*) DESC;
```

Per-stage rollup (use this for the Karri rollup):

```sql
SELECT
  state->>'stage' AS stage,
  COUNT(*)        AS n
FROM blackboard
WHERE topic = 'xauusd.signal.rejected'
  AND state->>'strategy_id' = 'xau-volatility-expansion'
  AND timestamp > NOW() - INTERVAL '14 days'
GROUP BY stage
ORDER BY COUNT(*) DESC;
```

Sanity check (do we see ANY rows after deploy?):

```sql
SELECT COUNT(*) FROM blackboard
WHERE topic = 'xauusd.signal.rejected'
  AND timestamp > NOW() - INTERVAL '1 hour';
```

## Next steps

1. Operator deploys to Railway (no env-var needed — instrumentation is on by default).
2. Wait 24h, run sanity-check SQL — confirm rows are being written. If COUNT=0, look at worker logs for "signal-rejection-log" warnings (there shouldn't be any — defensive swallow).
3. Wait 14d (target ~2026-05-25), run the full SQL above.
4. Forward output to Karri via Discord webhook for Phase 2 threshold-decision.

## Sample Phase 2 hypotheses to test against

(From proposal, lines 60–66 — re-list here for Karri's reference when the data lands.)

- 80%+ at `blackboard-publish` reason="ratio < threshold" → producer's BBW/ratio floor too high — lower it.
- 80%+ at `blackboard-publish` reason matching cooldown → cooldown_min too long — lower it.
- 80%+ at `gate-rejection` → mini-Blade is the choke; drill into which gate (event-policy, new-gates, etc.).
- 80%+ at `portfolio-cap` → producer is too eager OR caps are too tight — Karri decides which.
- 80%+ at `execution-fail` → OANDA-side issue; not a strategy-design problem.

Per operator-prinsipp 6: 30+ closed trades + explicit Karri-OK before any threshold flip. This file ends at "report, don't act".
