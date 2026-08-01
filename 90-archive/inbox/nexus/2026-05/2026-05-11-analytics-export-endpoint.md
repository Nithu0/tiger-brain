# 2026-05-11 — /analytics/export/strategy/:id endpoint

Closes the last overdue Claude-followup blocking Foundation Rule 5.

## What landed

New Fastify route in `apps/api/src/routes/analytics.ts`:

```
GET /analytics/export/strategy/:id?days=30
```

- Auth: reuses existing `registerAuth` Bearer pattern (no per-route plumbing).
- Validates `:id` against `strategies` table OR existing `simulated_orders.strategy_id` history. Unknown id → 400.
- `days` query param: default 30, clamped to [1, 365].
- Returns JSON array (empty array if no trades in window).

## Per-row shape

```
trade_id, decision_cycle_id, direction,
opened_at, closed_at, pnl, close_reason,
entry_price, close_price,
regime_at_entry, atr_at_entry, conviction_at_entry, thesis_quality_at_entry,
signal:        { id, direction, confidence, rationale } | null,
analysis_snapshot: {
  source: "cycle_id" | "proximity",
  recorded_at,
  tech_direction, tech_score, tech_confidence,
  news_direction, news_thesis,
  macro_direction, macro_score, macro_thesis
} | null,
postmortem:    { id, classification, cleanliness,
                 market_score, entry_score, execution_score, summary } | null,
firm_memory_count: number
```

## Join strategy

- `signals` ← `simulated_orders.signal_id` (LEFT JOIN, direct FK).
- `postmortems` ← `postmortems.trade_id = simulated_orders.id` (LEFT JOIN).
- `analysis_snapshots` ← exact `cycle_id` match first; per-row JS fallback
  to ±5min proximity by `opened_at` (mirrors `/positions/:id/analysis-snapshot`
  pattern). Source labelled `cycle_id` vs `proximity` so consumers know.
- `firm_memory` ← `COUNT(*) WHERE evidence->>'decision_cycle_id' = o.decision_cycle_id`.
  Soft join via JSONB key; no FK. Count only — keeps payload tight.

## Files modified

- `/home/nithu/code/ai-assistent/apps/api/src/routes/analytics.ts` — new endpoint appended.
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/followups.ts` — removed
  `per-strategy-sql-export-endpoint`, added `per-strategy-sql-export-csv`
  due 2026-06-01 as a follow-up for the CSV variant.

## No schema changes

No new tables, no migrations, no behavioural changes outside the new route.

## Verify

- `apps/api: tsc --noEmit` — clean.
- `apps/worker: tsc --noEmit` — clean (followups.ts edit only).
- `apps/worker/src/firm/followups.test.ts` — 5/5 pass (vitest quirk reports
  "no test suite" because the file uses bare `test()` not `describe()`,
  but all assertions run + pass).

## Followups state

Claude-owned items remaining (today = 2026-05-11):

| id | dueDateIso | overdue? |
|---|---|---|
| `per-strategy-sql-export-csv` | 2026-06-01 | no |
| `backfill-original-risk-points-on-oanda-reconcile` | 2026-05-18 | no |

Zero overdue Claude items. Foundation Rule 5 → green.

## Deferred / out of scope

- CSV output (tracked as separate followup).
- Dashboard typed shape in `apps/dashboard/src/lib/api.ts` — not needed yet,
  this is a notebook/data-pipeline route.
- Pagination — `days` cap of 365 is enough; can revisit if a strategy ever
  produces 10k+ trades in a year.

## Sample curl (once deployed)

```
curl -H "Authorization: Bearer $API_KEY" \
  "https://<api>/analytics/export/strategy/xau-volatility-expansion?days=30" \
  | jq '.[0] | keys'
```

Expected keys: `analysis_snapshot, atr_at_entry, close_price, close_reason,
closed_at, conviction_at_entry, decision_cycle_id, direction, entry_price,
firm_memory_count, opened_at, pnl, postmortem, regime_at_entry, signal,
thesis_quality_at_entry, trade_id`.
