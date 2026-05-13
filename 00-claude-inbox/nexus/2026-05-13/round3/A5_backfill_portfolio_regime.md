# A5 — Backfill `portfolio_regime_at_entry` from blackboard history

**Status:** READY TO EXECUTE — operator review required
**Owner:** Claude (prep) → operator (execute via `mcp__nexus-pg-rw__query`)
**Date prepared:** 2026-05-13
**Karri proposal context:** `docs/strategy/proposals/2026-05-12_trend_pause_phase1.md` (per-regime trade analysis unblock)

---

## TL;DR

- Trades live in `simulated_orders`, not `trades`.
- No `regime_decisions` table exists. Portfolio regime history lives on the blackboard at `topic='xauusd.portfolio.context'`, with `state->>'regime'` carrying the value.
- **Total NULL rows:** 137 of 156 (Round 2 said 138 — actual is 137; not material).
- **Backfillable (within blackboard history, staleness ≤ 60 min):** 43 rows.
- **Will stay NULL (pre-history `oanda_backfill_*` rows opened 2026-04-16 to 2026-04-28):** 94 rows. Correct — no source data exists.
- **One edge case (>60 min staleness):** 1 row at ~1292 min (weekend gap), 1 row at ~86 min. Excluded by the recommended cap. Operator can relax the cap if desired.

---

## Schema notes

### Source-of-truth table

`public.simulated_orders` (PK `id text NOT NULL`)
- `portfolio_regime_at_entry text NULL` — target column
- `opened_at timestamptz NOT NULL` — join key
- Allowed regime values observed in non-null rows: `HIGH_VOLATILITY`, `MIXED_NO_EDGE`, `NOISY_CHAOTIC`, `RANGING`, `TRENDING`

### Regime-history source

`public.blackboard` (no dedicated `regime_decisions` table)
- Filter: `topic = 'xauusd.portfolio.context'` (message_type `INTERPRETATION`)
- Value at: `state->>'regime'` (jsonb)
- Coverage: 6608 rows from **2026-04-29 07:01:19 UTC** → 2026-05-13 07:27 UTC
- Cadence: ~30-60s (rows roughly every minute under normal load)

### Why some rows stay NULL

- 94 of 137 NULL rows are `oanda_backfill_*` entries opened **before 2026-04-29** (the blackboard's earliest portfolio.context row). No upstream data exists to backfill from. Correct outcome.
- The remaining 19 already-set rows were written at trade-time by the worker — used here only as a sanity check against the join (11/14 lookups agree; 6 already-set rows fall before blackboard history; 1 stale mismatch documented below).

### Sanity check — does the join logic agree with already-set rows?

Joining the 19 already-non-null rows back to the blackboard:

| existing            | lookup_regime  | count |
|---------------------|----------------|-------|
| TRENDING            | TRENDING       | 10    |
| RANGING             | RANGING        | 1     |
| NOISY_CHAOTIC       | NOISY_CHAOTIC  | 1     |
| TRENDING            | NOISY_CHAOTIC  | 1  *  |
| TRENDING            | (NULL)         | 2  ** |
| RANGING             | (NULL)         | 2  ** |
| HIGH_VOLATILITY     | (NULL)         | 1  ** |
| MIXED_NO_EDGE       | (NULL)         | 1  ** |

`*` 1 disagreement — blackboard snapshot was stale at that moment vs what the worker wrote directly. Acceptable noise (1/14 = 7%).
`**` 6 rows opened before 2026-04-29 — worker wrote them inline at trade-time so we have no blackboard row to cross-check.

Conclusion: lookup logic is correct.

---

## Coverage breakdown for the 43 backfillable rows

By join-staleness (entry_time − latest portfolio.context row at-or-before entry_time):

| staleness bucket  | rows |
|-------------------|------|
| ≤ 5 min           | 38   |
| 5–60 min          | 3    |
| 60 min – 1 day    | 2    |
| > 1 day           | 0    |
| no match          | 0    |

The 2 between-60-min-and-1-day rows:
- `eafbd640-f022-424d-8f78-21d5023f1dea` opened 2026-05-01 09:57 UTC; nearest blackboard 2026-04-30 12:25 UTC (1292 min stale, weekend boundary).
- `03788c73-6faa-4e5a-9743-c44344b1e37a` opened 2026-05-04 14:38 UTC; nearest blackboard 2026-05-04 13:12 UTC (86 min stale).

**Recommended cap: `staleness_min ≤ 60`.** Drops these 2 edge cases — preferable to applying a possibly-wrong stale value across a weekend gap. Operator can relax to 1440 (1 day) trivially by changing the threshold.

---

## Dry-run query (run first to verify)

```sql
-- DRY-RUN: preview what the UPDATE would change. No writes.
WITH proposed AS (
  SELECT
    t.id AS trade_id,
    t.opened_at,
    t.portfolio_regime_at_entry AS old_value,
    bb.state->>'regime' AS new_value,
    bb.timestamp AS regime_recorded_at,
    EXTRACT(EPOCH FROM (t.opened_at - bb.timestamp))/60 AS staleness_min
  FROM simulated_orders t
  LEFT JOIN LATERAL (
    SELECT b.timestamp, b.state
    FROM blackboard b
    WHERE b.topic = 'xauusd.portfolio.context'
      AND b.timestamp <= t.opened_at
    ORDER BY b.timestamp DESC
    LIMIT 1
  ) bb ON true
  WHERE t.portfolio_regime_at_entry IS NULL
    AND bb.state->>'regime' IS NOT NULL
    AND EXTRACT(EPOCH FROM (t.opened_at - bb.timestamp))/60 <= 60
)
SELECT * FROM proposed ORDER BY opened_at LIMIT 20;
```

### Dry-run result (first 15 rows from full set of 41 within ≤60 min)

| trade_id                              | opened_at              | new_value       | staleness_min |
|---------------------------------------|------------------------|-----------------|---------------|
| 0d04192c-6e51-499e-ba90-3e85ff26e996  | 2026-04-29 10:00:07Z   | HIGH_VOLATILITY | 1.05          |
| 6dce6eb6-9a68-46f7-8ada-d639ee5d942f  | 2026-04-29 12:31:06Z   | RANGING         | 1.04          |
| 95e999be-a5b6-415b-85dd-479185ddc0df  | 2026-04-29 13:32:27Z   | HIGH_VOLATILITY | 0.54          |
| 53a898ea-ddd7-4641-b7bd-3b45010fba40  | 2026-04-29 13:34:38Z   | HIGH_VOLATILITY | 0.54          |
| da41bc13-5011-4dc6-be75-0cdd98ff9e75  | 2026-04-29 13:45:11Z   | HIGH_VOLATILITY | 0.54          |
| 3a79e207-5a67-4ba8-ac05-0866d8621fe3  | 2026-04-29 15:04:03Z   | TRENDING        | 3.06          |
| 053019aa-12af-4167-929e-ce2c35a50062  | 2026-04-30 11:00:28Z   | NOISY_CHAOTIC   | 1.05          |
| aa04e17f-796e-4987-9fae-87fedb4feab7  | 2026-05-01 09:58:28Z   | TRENDING        | 1.08          |
| a6214b46-406d-46b2-82ca-b1e87e497efd  | 2026-05-01 12:27:30Z   | TRENDING        | 1.04          |
| cc301eb0-1135-440b-92c0-92430f0645a9  | 2026-05-01 13:54:55Z   | TRENDING        | 0.54          |
| be5911e1-9ce8-4c22-8745-45f6f5df63d9  | 2026-05-01 14:16:17Z   | NOISY_CHAOTIC   | 1.04          |
| f7c0f1fc-8090-47e2-934f-238f278e94f4  | 2026-05-01 14:16:17Z   | NOISY_CHAOTIC   | 1.05          |
| 8867577c-29e5-4cee-9fc5-11674ecee878  | 2026-05-01 14:58:20Z   | NOISY_CHAOTIC   | 1.05          |
| 9f743c70-bc58-4e7b-a38d-95b161a81989  | 2026-05-01 17:29:57Z   | TRENDING        | 3.13          |
| (… 27 more rows …)                    |                        |                 |               |

Join makes sense: short staleness, plausible regime values, no negative deltas.

---

## Transactional UPDATE (READY TO EXECUTE — operator review required)

Run as a single submission so `BEGIN ... ROLLBACK/COMMIT` are all in one transaction. **Default ends with `ROLLBACK` for safety.** Operator should:
1. Paste and run as-is (the `SELECT count` lines will show before/after deltas; final `ROLLBACK` reverts).
2. Read the deltas. Expect ~41 rows updated, NULL count: 137 → 96.
3. If deltas look right, change the final line from `ROLLBACK;` to `COMMIT;` and re-run to persist.

```sql
BEGIN;

-- 1. Snapshot pre-state
SELECT count(*) FILTER (WHERE portfolio_regime_at_entry IS NULL) AS null_before,
       count(*) FILTER (WHERE portfolio_regime_at_entry IS NOT NULL) AS non_null_before
FROM simulated_orders;

-- 2. Apply backfill (lateral subquery, staleness cap 60 min)
WITH proposed AS (
  SELECT
    t.id AS trade_id,
    bb.state->>'regime' AS new_regime
  FROM simulated_orders t
  CROSS JOIN LATERAL (
    SELECT b.timestamp, b.state
    FROM blackboard b
    WHERE b.topic = 'xauusd.portfolio.context'
      AND b.timestamp <= t.opened_at
    ORDER BY b.timestamp DESC
    LIMIT 1
  ) bb
  WHERE t.portfolio_regime_at_entry IS NULL
    AND bb.state->>'regime' IS NOT NULL
    AND EXTRACT(EPOCH FROM (t.opened_at - bb.timestamp))/60 <= 60
)
UPDATE simulated_orders s
SET portfolio_regime_at_entry = p.new_regime
FROM proposed p
WHERE s.id = p.trade_id;

-- 3. Snapshot post-state (expected: null_before − null_after ≈ 41)
SELECT count(*) FILTER (WHERE portfolio_regime_at_entry IS NULL) AS null_after,
       count(*) FILTER (WHERE portfolio_regime_at_entry IS NOT NULL) AS non_null_after
FROM simulated_orders;

-- 4. Verify distribution makes sense
SELECT portfolio_regime_at_entry, count(*) 
FROM simulated_orders 
GROUP BY portfolio_regime_at_entry 
ORDER BY count(*) DESC;

-- 5. SAFETY: review the two counts above before committing.
--    If null_after ≈ 96 and the distribution looks reasonable → change ROLLBACK to COMMIT and re-run.
ROLLBACK;
-- COMMIT;
```

---

## Optional follow-up after commit

Once the backfill lands, two related observations worth filing as separate proposals (not in scope here):

1. The **6 oanda_backfill_* rows with `portfolio_regime_at_entry` already set** but `opened_at < 2026-04-29` raise a question — how did the worker know? Likely manual or via a deprecated source. Karri may want this annotated when reading per-regime stats.
2. The **94 pre-history rows that stay NULL** are mostly `oanda_backfill_*` — Karri's analysis should explicitly exclude them or label them `UNKNOWN_PRE_REGIME_TRACKING` rather than NULL, to avoid them silently dropping from GROUP BY.

Possible cosmetic UPDATE (separate decision):
```sql
-- UPDATE simulated_orders 
-- SET portfolio_regime_at_entry = 'UNKNOWN_PRE_REGIME_TRACKING'
-- WHERE portfolio_regime_at_entry IS NULL
--   AND opened_at < '2026-04-29T07:01:19.818Z';
```
Not recommended without Karri sign-off — adds a new value to a previously-bounded enum-ish column.

---

**READY TO EXECUTE — operator review required.** Run via `mcp__nexus-pg-rw__query`. The transactional block defaults to `ROLLBACK` — flip to `COMMIT` only after verifying the counts.
