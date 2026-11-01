# Wire analysis_snapshots into /positions/[id]

Closed followup `wire-analysis-snapshots-on-position-detail` (14d overdue).

## Data audit (2026-05-11)

- `analysis_snapshots`: **10,141 rows**, oldest 2026-04-20, newest 2026-05-11 10:47 UTC.
- The analyst loop writes one row per orchestrator cycle (XAUUSD only at the moment).
- `simulated_orders`: 110 firm-loop trades since 2026-04-20; 47 carry a `decision_cycle_id`.
- **`cycle_id` exact-join matched 0 of 47** — ORB strategy stores slug ids like `orb-london-2026-05-11`, but the analyst publishes proper UUIDs. The two formats never overlap.
- **Proximity join (5-min window before `opened_at`) matched 102 of 110**. Lags are 5–199s for recent trades; the 8 misses are pre-firm-loop trades.

Conclusion: cycle_id was the design intent but in practice the join needs proximity as the workhorse and cycle_id as a high-confidence override when it does line up.

## Implementation

- New endpoint `GET /positions/:id/analysis-snapshot` in `apps/api/src/routes/positions.ts`. Returns the snapshot row + `matchedVia: "cycle_id" | "proximity"` + `lagSeconds`. Returns 200 + `null` when nothing matches (so legacy trades render nothing instead of a broken card).
- Client type + method in `apps/dashboard/src/lib/api.ts` (`AnalysisSnapshotResponse`, `api.positionAnalysisSnapshot`).
- `AnalysisSnapshotCard` rendered between `TradeContextCard` and `PostTradeReviewCard` in `apps/dashboard/src/app/positions/[id]/page.tsx`. Shows tech / news / macro: direction, score, confidence, thesis, evidence-for/against. Match-method + lag are surfaced in the card header so a 199s-lag proximity match is honest about itself.
- Snapshot fetch is its own `useQuery` with `staleTime: Infinity` — a point-in-time record never changes after capture.
- `wire-analysis-snapshots-on-position-detail` removed from `apps/worker/src/firm/followups.ts`.

## Verification

- `apps/api` tsc: clean.
- `apps/dashboard` tsc: clean.
- `apps/worker` tsc: clean.
- `followups.test.ts`: 5/5 assertions pass (node:test under vitest runner prints a "no suite found" warning, but all individual tests succeed).

## Commit

`34d5f3f feat(positions): show analysis-snapshot on position detail page` — single commit covering route + client + UI + followup removal. Not pushed (per "OK kjør"-gate).

## Notes for follow-up

- News fields on recent snapshots are all `null` in the sample I checked (last 5 rows: `news_direction=null, news_headline_count=null`). Macro and tech are populated. If news enrichment is meant to be running, that's a separate firehose-loop check — not in scope here. UI handles null cleanly (skips the news subsection).
- Same proximity strategy could be reused for the followup `per-strategy-sql-export-endpoint` since that one also wants `market_snapshots + analysis_snapshots + sentiment` joined per-trade.
