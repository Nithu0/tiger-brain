---
date: 2026-05-13
type: backfill-proposal
project: nexus
status: pending-operator-approval
---

# Backfill `simulated_orders.portfolio_regime_at_entry`

## Current state

| metric | value |
|---|---|
| total rows | 156 |
| NULL `portfolio_regime_at_entry` | 137 (87.8%) |
| filled | 19 |
| NULL rows time span | 2026-04-16 → 2026-05-12 |

## Source-table discovery

- `analysis_snapshots` — NO regime/portfolio columns. Unusable as source.
- `trade_strategy_snapshots` — has `regime` (text), `captured_at`, `cycle_id`, `symbol`. 21184 rows with non-null regime, same enum values as `portfolio_regime_at_entry` (TRENDING / RANGING / HIGH_VOLATILITY / NOISY_CHAOTIC / MIXED_NO_EDGE / LOW_VOLATILITY).

## Join key analysis

- `decision_cycle_id` ↔ `cycle_id` join: **0 matches** (different cycle taxonomies — confirmed empirically).
- Symbol + timestamp-window: only viable path.

## Backfill yield estimate (dry-run)

| window | rows backfillable | still NULL after |
|---|---|---|
| ±10 min | 36 | 101 |
| ±30 min | 37 | 100 |

10-min window is the sweet spot. The 101 unreachable rows pre-date `trade_strategy_snapshots` persistence — no source data exists.

Sanity caveat: a few windows contain 2-3 distinct regimes (regime flipped during the ±10 min). Nearest-by-time is the chosen tiebreak.

## Proposed SQL (paste into Railway Postgres → Connect → Query)

Idempotent (only touches NULL rows). Safe to run multiple times.

```sql
BEGIN;

WITH candidate AS (
  SELECT
    s.id,
    (SELECT t.regime
       FROM trade_strategy_snapshots t
      WHERE t.symbol = s.market
        AND t.regime IS NOT NULL
        AND t.captured_at BETWEEN s.opened_at - INTERVAL '10 minutes'
                              AND s.opened_at + INTERVAL '10 minutes'
      ORDER BY ABS(EXTRACT(EPOCH FROM (t.captured_at - s.opened_at)))
      LIMIT 1) AS matched_regime
  FROM simulated_orders s
  WHERE s.portfolio_regime_at_entry IS NULL
)
UPDATE simulated_orders s
SET portfolio_regime_at_entry = c.matched_regime
FROM candidate c
WHERE c.id = s.id
  AND c.matched_regime IS NOT NULL;

-- Expected: UPDATE 36

-- Verify before COMMIT
SELECT
  COUNT(*) FILTER (WHERE portfolio_regime_at_entry IS NULL) AS still_null,
  COUNT(*) FILTER (WHERE portfolio_regime_at_entry IS NOT NULL) AS filled
FROM simulated_orders;
-- Expected: still_null=101, filled=55

COMMIT;
-- (or ROLLBACK if numbers look off)
```

## Risk notes

- **Semantic mismatch risk:** `trade_strategy_snapshots.regime` is the cycle-level regime (market regime detector output), while `portfolio_regime_at_entry` was intended to capture portfolio-level regime. In practice the 19 already-filled rows use the same enum, so the columns appear to be aliases. Karri should confirm semantic equivalence before backfill is treated as ground truth in analytics.
- **101 rows stay NULL** — no upstream source. Mark these as `pre-snapshot` cohort in any analysis (exclude or bucket separately).
- **Regime flip within ±10 min** — affects ~6 visible rows. Nearest-by-time wins; acceptable for retrospective bucketing, not for live decisions.
- **Idempotent** — re-running adds no rows (NULL filter shrinks each pass).

## Execution path

`nexus-pg-rw` MCP is read-only in practice despite the name. Operator paste route:

1. Railway dashboard → Postgres service → Connect → Query.
2. Paste the SQL block above (BEGIN…COMMIT).
3. Inspect the verification SELECT before COMMIT; ROLLBACK if `still_null != 101` or `filled != 55`.
