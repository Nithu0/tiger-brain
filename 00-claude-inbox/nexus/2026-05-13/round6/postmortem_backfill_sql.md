# Postmortem backfill SQL — 15–29.4 unlabeled losers

**Status: READY TO EXECUTE — operator review required**
**Do NOT execute until Karri signs off classifier rule. Operator must paste manually (mcp__nexus-pg-rw is read-only per 13.5 discovery).**

---

## Why this exists

Postmortem-hook (`apps/worker/src/firm/postmortem-hook.ts`) only stamps rows where `closed_at > NOW() - INTERVAL '7 days'`. It went live 30.4. Result: 63 losing XAUUSD trades closed between 15.4–29.4 have no `postmortems` row — Karri's ML training set is missing all of pre-launch losers, which would bias toward post-30.4 regime if used as-is.

## Schema notes (verified 13.5)

- **`postmortems`** — PK `id` (text). Cols: `trade_id`, `cycle_id`, `classification` NOT NULL, `cleanliness`, `pnl`, `market_score`, `entry_score`, `execution_score`, `summary`, `full_reasoning`, `session_at_close`, `created_at`. No unique on `trade_id`, no FK to `simulated_orders`. No `id LIKE '%-pm-backfill'` rows exist → suffix is safe.
- **`simulated_orders`** — `postmortem_run_at` is the live-loop's "already processed" flag; we set it to mirror runtime behaviour.
- **Live classifier source of truth**: `apps/worker/src/firm/postmortem.ts:69–232`. Live mirror to `postmortems` row in `postmortem-hook.ts:170–203`.

## Data quality of the 63 rows

| Field | Populated |
|---|---|
| `close_reason` | 63/63 |
| `peak_price` (MFE) | 7/63 |
| `atr_at_entry` | 1/63 |
| `original_risk_points` | 1/63 |
| `portfolio_regime_at_entry` | 1/63 |
| `decision_cycle_id` | 1/63 |

Translation: for 62 of 63 rows we have only `(direction, entry, close, pnl, close_reason)`. MFE-based rules (RTBE, BAD_INVALIDATION-via-MFE) cannot fire — no peak. Counter-trend regime rule cannot fire — no regime snapshot. We must classify on what we have, conservatively.

## close_reason distribution

| close_reason | n |
|---|---|
| OANDA_BACKFILL | 51 |
| OANDA_SL_TP | 9 |
| OANDA_EXTERNAL | 2 |
| STALE_TRADE_EXIT | 1 |

## Classifier rule (retro, conservative)

Mirrors the live classifier where possible. NO MFE/regime/decision context → degrade rules cleanly to closest live-equivalent:

1. `close_reason='OANDA_EXTERNAL'` → **EXTERNAL_CLOSE** (exact match to live, line 177).
2. `close_reason='STALE_TRADE_EXIT'` → **NO_TRADE_SHOULD_HAVE_WON** (live ELSE branch when no thesis-quality signal available).
3. SL-like close (`OANDA_SL_TP` or `OANDA_BACKFILL`) AND `|pnl| < 20` → **RIGHT_THESIS_BAD_INVALIDATION** (live line 224: small-loss SL bucket).
4. SL-like close AND `|pnl| ≥ 20` → **WRONG_THESIS** (live: SL-hit + direction-correct check; without MFE we cannot tell direction-correct, but a large-loss SL after no recovery is the textbook WRONG_THESIS proxy used by live rule line 205).

**Bias notes** (must flag to Karri before training):
- Backfill rows have no decision context → all backfill losers go to WRONG_THESIS or BAD_INVALIDATION. Real classifier would have routed some to BAD_TIMING / BAD_EXECUTION if `wasChasing`/`wasChaotic` had been recorded. Treat the backfill window as lower-resolution labels.
- No `marketThesisScore` → `market_score`/`entry_score`/`execution_score` will be NULL for all 63 rows.
- `cycle_id` NULL for 62/63.

## Distribution of retro labels

| retro_class | n | avg_pnl | worst_pnl |
|---|---|---|---|
| RIGHT_THESIS_BAD_INVALIDATION | 38 | -10.44 | -16.13 |
| WRONG_THESIS | 22 | -753.32 | -1714.81 |
| EXTERNAL_CLOSE | 2 | -383.00 | -399.53 |
| NO_TRADE_SHOULD_HAVE_WON | 1 | -8.91 | -8.91 |
| **OTHER** | **0** | — | — |

No row falls through to OTHER — full coverage.

## Dry-run preview (first 10 rows)

```text
id                  direction  pnl       close_reason     retro_class                     closed_at
oanda_backfill_41   long       -11.73    OANDA_BACKFILL   RIGHT_THESIS_BAD_INVALIDATION   2026-04-16 13:52:15
oanda_backfill_45   long       -9.27     OANDA_BACKFILL   RIGHT_THESIS_BAD_INVALIDATION   2026-04-16 13:52:15
oanda_backfill_33   long       -12.66    OANDA_BACKFILL   RIGHT_THESIS_BAD_INVALIDATION   2026-04-16 13:52:18
oanda_backfill_37   long       -13.14    OANDA_BACKFILL   RIGHT_THESIS_BAD_INVALIDATION   2026-04-16 13:52:20
oanda_backfill_25   long       -10.39    OANDA_BACKFILL   RIGHT_THESIS_BAD_INVALIDATION   2026-04-16 13:52:40
oanda_backfill_29   long       -9.96     OANDA_BACKFILL   RIGHT_THESIS_BAD_INVALIDATION   2026-04-16 13:52:40
oanda_backfill_21   long       -11.15    OANDA_BACKFILL   RIGHT_THESIS_BAD_INVALIDATION   2026-04-16 13:52:40
oanda_backfill_17   long       -9.60     OANDA_BACKFILL   RIGHT_THESIS_BAD_INVALIDATION   2026-04-16 13:52:41
oanda_backfill_13   long       -11.39    OANDA_BACKFILL   RIGHT_THESIS_BAD_INVALIDATION   2026-04-16 13:52:41
oanda_backfill_9    long       -12.85    OANDA_BACKFILL   RIGHT_THESIS_BAD_INVALIDATION   2026-04-16 13:52:50
```

To rerun the dry-run yourself (read-only, safe):

```sql
SELECT o.id, o.direction, ROUND(o.pnl::numeric,2) AS pnl, o.close_reason,
  CASE
    WHEN o.close_reason='OANDA_EXTERNAL' THEN 'EXTERNAL_CLOSE'
    WHEN o.close_reason='STALE_TRADE_EXIT' THEN 'NO_TRADE_SHOULD_HAVE_WON'
    WHEN o.close_reason IN ('OANDA_SL_TP','OANDA_BACKFILL') AND ABS(o.pnl)<20 THEN 'RIGHT_THESIS_BAD_INVALIDATION'
    WHEN o.close_reason IN ('OANDA_SL_TP','OANDA_BACKFILL') THEN 'WRONG_THESIS'
    ELSE 'OTHER' END AS retro_class
FROM simulated_orders o
LEFT JOIN postmortems p ON p.trade_id=o.id
WHERE o.status='closed' AND o.market='XAUUSD' AND o.pnl<0
  AND p.id IS NULL
  AND o.closed_at >= '2026-04-15' AND o.closed_at < '2026-04-30'
ORDER BY o.closed_at ASC;
```

## Transactional INSERT (paste into Railway DB)

```sql
BEGIN;

-- 1) Insert backfilled postmortem rows
INSERT INTO postmortems
  (id, trade_id, cycle_id, classification, cleanliness, pnl,
   market_score, entry_score, execution_score, summary, full_reasoning,
   session_at_close, created_at)
SELECT
  o.id || '-pm-backfill'                                                   AS id,
  o.id                                                                      AS trade_id,
  o.decision_cycle_id                                                       AS cycle_id,
  CASE
    WHEN o.close_reason = 'OANDA_EXTERNAL'                              THEN 'EXTERNAL_CLOSE'
    WHEN o.close_reason = 'STALE_TRADE_EXIT'                            THEN 'NO_TRADE_SHOULD_HAVE_WON'
    WHEN o.close_reason IN ('OANDA_SL_TP','OANDA_BACKFILL')
         AND ABS(o.pnl) < 20                                            THEN 'RIGHT_THESIS_BAD_INVALIDATION'
    WHEN o.close_reason IN ('OANDA_SL_TP','OANDA_BACKFILL')             THEN 'WRONG_THESIS'
    ELSE 'NO_TRADE_SHOULD_HAVE_WON'
  END                                                                       AS classification,
  NULL                                                                      AS cleanliness,
  o.pnl                                                                     AS pnl,
  NULL, NULL, NULL,                                                              -- scores unknown pre-30.4
  ('Retro backfill 2026-05-13: ' || o.close_reason || ' loss $' || ROUND(o.pnl::numeric,2))::text AS summary,
  'RETRO_BACKFILL_2026-05-13 (no decision context; classified from close_reason+pnl only)'        AS full_reasoning,
  NULL                                                                      AS session_at_close,
  NOW()                                                                     AS created_at
FROM simulated_orders o
LEFT JOIN postmortems p ON p.trade_id = o.id
WHERE o.status='closed' AND o.market='XAUUSD' AND o.pnl < 0
  AND p.id IS NULL
  AND o.closed_at >= '2026-04-15' AND o.closed_at < '2026-04-30'
ON CONFLICT (id) DO NOTHING;

-- 2) Stamp simulated_orders.postmortem_run_at so the live hook won't re-process
UPDATE simulated_orders
SET postmortem_run_at = NOW()
WHERE id IN (
  SELECT o.id
  FROM simulated_orders o
  LEFT JOIN postmortems p ON p.trade_id = o.id
  WHERE o.status='closed' AND o.market='XAUUSD' AND o.pnl < 0
    AND o.postmortem_run_at IS NULL
    AND o.closed_at >= '2026-04-15' AND o.closed_at < '2026-04-30'
);

-- 3) Verify counts BEFORE deciding to COMMIT
SELECT
  (SELECT COUNT(*) FROM postmortems WHERE id LIKE '%-pm-backfill')         AS inserted,
  (SELECT COUNT(*) FROM simulated_orders o
    LEFT JOIN postmortems p ON p.trade_id = o.id
   WHERE o.status='closed' AND o.market='XAUUSD' AND o.pnl < 0
     AND p.id IS NULL
     AND o.closed_at >= '2026-04-15' AND o.closed_at < '2026-04-30')        AS still_unlabeled;
-- Expected: inserted=63, still_unlabeled=0

-- If counts look right:
--   COMMIT;
-- Otherwise:
--   ROLLBACK;
ROLLBACK;  -- ← default safe; flip to COMMIT after inspecting counts above
```

## Edge cases needing manual classification later

None blocking. But flag these to Karri before treating labels as ML-ready:

1. **22 WRONG_THESIS rows** — labelled large-loss-SL. Without MFE, some may actually be RIGHT_THESIS_BAD_INVALIDATION that ran past invalidation. If MFE matters for the model, treat these as weak labels.
2. **The 7 rows with `peak_price` populated** — could be re-classified more precisely (RTBE if MFE > 0.5R then reversed). Skipped here to keep the backfill rule single-pass and reviewable.
3. **`oanda_backfill_*` ids** (51 rows) — predate firm-path. They lack `decision_cycle_id` so they will never join to `agent_events` / engine attribution. Karri should exclude these from cycle-context features.
4. **The 1 NO_TRADE row** (`166bec36…`, STALE_TRADE_EXIT, short, pnl -8.91) — peak shows price moved favourably first then reversed. Live classifier might have called this RIGHT_THESIS_BAD_INVALIDATION; conservative rule keeps NO_TRADE.

## Counts

- **Backfillable**: 63
- **Edge-case rows flagged for Karri review**: 23 (22 large-loss WRONG_THESIS + 1 STALE)
- **Rows that hit OTHER**: 0
