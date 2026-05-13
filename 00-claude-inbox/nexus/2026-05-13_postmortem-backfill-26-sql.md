---
date: 2026-05-13
type: backfill-proposal
project: nexus
status: pending-operator-paste
---

# Postmortem backfill — 26 pre-fix RIGHT_THESIS_BAD_EXECUTION rows

Pre-fix classifier (before commit `6bdd38a`, 2026-05-11 14:18Z) defaulted any
non-win to `RIGHT_THESIS_BAD_EXECUTION` whenever `marketThesisScore`/
`executionWindowScore` were `0` (cycle-matching bug) AND counter-trend
detection didn't exist. New classifier adds `counterTrend` upgrade using
`portfolio_regime_at_entry` + blackboard `tech.direction`/`macro.direction`
at postmortem time.

## Schema findings

`postmortems` columns: `id, trade_id, cycle_id, classification, cleanliness,
pnl, market_score, entry_score, execution_score, summary, full_reasoning,
session_at_close, created_at`. **No JSON / metadata / tags column.** Option A
needs a migration first.

## Affected rows: 26 (confirmed)

22 of 26 closed via `OANDA_SL_TP`, 4 via `STALE_TRADE_EXIT`. Regime mix:
13 TRENDING, 4 NOISY_CHAOTIC, 4 HIGH_VOLATILITY/RANGING, 1 NULL. **18 of 26
were entered in TRENDING/BREAKOUT regimes** — these are the candidates the new
classifier might flip if tech/macro directions contradicted the trade.

## Option B feasibility — NOT clean

New classifier needs `techDirection` + `macroDirection` from blackboard
`xauusd.analysis.technical` / `xauusd.analysis.macro` at postmortem time
(`apps/worker/src/firm/postmortem.ts:138-143`). Those snapshots are **not
persisted on the trade row**. We'd need to replay historical blackboard state
per trade_id — possible if `blackboard_messages` retention covers May 1–11,
but adds replay infra. Not worth it for 26 rows.

## Recommendation: Option A (mark legacy)

Add a `legacy_classifier` boolean column, set `TRUE` for the 26 rows. Audits
+ analytics SQL filters them out / treats them as "pre-fix, skeptical". Zero
data destruction, fully reversible.

## SQL to paste — Railway Postgres console

```sql
-- Step 1: preview (verify 26 rows)
SELECT id, trade_id, classification, pnl, session_at_close, created_at
FROM postmortems
WHERE created_at < '2026-05-11 14:18:00Z'
  AND classification = 'RIGHT_THESIS_BAD_EXECUTION'
ORDER BY created_at DESC;

-- Step 2: migration (add column, idempotent)
ALTER TABLE postmortems
  ADD COLUMN IF NOT EXISTS legacy_classifier BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_postmortems_legacy_classifier
  ON postmortems (legacy_classifier)
  WHERE legacy_classifier = TRUE;

-- Step 3: backfill (transactional)
BEGIN;

  -- Preview count inside txn (should print 26)
  SELECT COUNT(*) AS will_update
  FROM postmortems
  WHERE created_at < '2026-05-11 14:18:00Z'
    AND classification = 'RIGHT_THESIS_BAD_EXECUTION'
    AND legacy_classifier = FALSE;

  -- Mark
  UPDATE postmortems
     SET legacy_classifier = TRUE
   WHERE created_at < '2026-05-11 14:18:00Z'
     AND classification = 'RIGHT_THESIS_BAD_EXECUTION'
     AND legacy_classifier = FALSE;

  -- Verify (should also print 26)
  SELECT COUNT(*) AS marked
  FROM postmortems
  WHERE legacy_classifier = TRUE;

COMMIT;
```

If the verify counts don't match 26 (e.g. someone re-ran the classifier
in-between), `ROLLBACK;` instead of `COMMIT;` and re-investigate.

## Follow-ups (operator decides)

1. Update analytics dashboards to filter `legacy_classifier = TRUE` from
   thesis-quality stats (or surface as a separate bucket "pre-fix data").
2. Code change: persist `tech_direction_at_entry` + `macro_direction_at_entry`
   on `simulated_orders` so future classifier improvements can re-run
   offline. Separate proposal — strategy-adjacent, route via Karri.
3. If we ever do Option B re-classification, the prereq is #2 + a
   `blackboard_messages` replay script. Out of scope today.

## Risks

- Adding a column on a hot table is fast in Postgres (no rewrite, NOT NULL
  with DEFAULT FALSE since PG 11+). Should complete in ms.
- New code paths writing postmortems will default `legacy_classifier = FALSE`
  — correct.
- Reversible: `UPDATE postmortems SET legacy_classifier = FALSE WHERE ...`
  or `ALTER TABLE postmortems DROP COLUMN legacy_classifier;`.
