# 2026-05-11 — strategy_id backfill: NOT applied (script bug)

## TL;DR

Dry-run from commit `67f1dfc` **aborted before COMMIT** because the script
references a column that doesn't exist in production schema. Step 1
(strategy_id/execution_source/entry_conviction_score on 59 rows) worked
inside the transaction, but the transaction then errored on Step 2 (ATR) and
rolled back. **No changes persisted.** Operator decision needed.

## What happened

- **Auth:** success (URL accepted, no rotation needed).
- **Pre-state (bug window from 2026-04-26 22:00 UTC):**
  - 59 rows with `strategy_id IS NULL` (matches expected 59)
  - 59 rows with `execution_source IS NULL`
  - 62 rows with `atr_at_entry IS NULL`
  - 62 rows with `entry_conviction_score IS NULL`
  - 62 total in bug window with status set
- **Step 1 (in-tx):** `UPDATE ... FROM signals` matched **59 rows** for
  strategy_id + execution_source + entry_conviction_score backfill. Good.
- **Step 2 (in-tx):** **ERROR: column `s.state` does not exist** — query
  references `signals.state->>'atr'`, but production `signals` table has no
  `state` column. Schema (8 cols only): id, bot_id, market, direction,
  confidence, rationale, source, created_at.
- **Outcome:** transaction errored → ROLLBACK → no rows changed.

## Root cause

Script author assumed `signals.state` JSONB existed (based on a different
schema or older mental model). ATR for these signals lives elsewhere
(actually `pending_signals.atr`), but joining `simulated_orders.signal_id ->
pending_signals.signal_id` returns **0 matches** in the bug window — those
pending_signal rows don't exist for these signal_ids. ATR cannot be
recovered from the DB for this window via the planned path.

## Pre-state vs. expected

| Metric                        | Expected | Actual | Match |
| ----------------------------- | -------- | ------ | ----- |
| NULL strategy_id              | ~59      | 59     | yes   |
| NULL execution_source         | ~59      | 59     | yes   |
| NULL atr_at_entry             | ~29 to fill | 62 (0 fillable) | NO |

Pre-state count of NULL strategy_id matches, so the "abort if mismatch"
guard does not trip — but Step 2's premise is broken.

## Operator decisions needed

Two paths forward, both safe:

1. **Patch script to drop Step 2 (ATR), keep Step 1 only.** Run with
   `CONFIRM=YES`. Backfills strategy_id/exec_source/conviction on 59 rows.
   ATR stays NULL for the 62 bug-window rows (no DB source available).

2. **Rewrite Step 2** to source ATR from another table if one exists.
   Quick audit suggested no usable join — see "Root cause" above. Likely
   not worth pursuing; ATR for closed orders is mostly observability.

Suggest path 1. Operator confirms → I patch script (`signals.state` block
removed), re-run dry → if clean, COMMIT.

## Operator action

- Confirm "drop Step 2, run Step 1 only" — I patch + commit fix.
- OR escalate to teammate for full rewrite of the recovery path.

No production data was changed. URL was masked in all logs (only
`<redacted>@trolley.proxy.rlwy.net:58688/railway` shape printed).
