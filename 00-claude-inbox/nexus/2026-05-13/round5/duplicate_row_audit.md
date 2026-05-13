# Duplicate-row audit — `simulated_orders` (OANDA backfill collisions)

**Date:** 2026-05-13
**Trigger:** F5 (MEDIUM) in `operator-decisions` audit — lesson-loop precondition.
**Author:** Claude (round 5 forensic)

---

## TL;DR

- **Active duplicates: 0.** Every row with a non-null `oanda_trade_id` is unique on that key as of 2026-05-13. The 8 historical pairs (tickets 438, 444, 452, 458, 464, 502, 542, 548) were already cleaned by oneshot SQL on 2026-05-08 — commit `60a627d`, runbook `scripts/oneshot/run-dedupe-08may.mjs`, $341.93 PnL correction.
- **Most recent duplicate (historical):** ticket 548, dual-row 2026-04-22 17:27:52 UTC. Already deleted. Backfill row `oanda_backfill_548` retained as canonical.
- **Root cause (re-occurrence vector still latent):** UUID-side row gets `closed` via a non-OANDA path WITHOUT ever having had `oanda_trade_id` populated → Section 7's idempotency check (`SELECT id FROM simulated_orders WHERE oanda_trade_id = $1`) finds no match → INSERTs a `oanda_backfill_<id>` twin. Historic UUID rows with NULL `oanda_trade_id`: 3, all status=closed, all `pnl=0`, reasons `MANUAL_GHOST_CLOSE` / `MANUAL_NO_OANDA` (operator-resolved orphans, not at risk).
- **Lesson-loop unblock:** Safe to activate IF lesson-loop joins on `oanda_trade_id IS NOT NULL` and excludes `execution_source='oanda_backfill'` from training (it already pairs with proper-side rows in current data). Recommend an idempotency hardening in `oanda-sync.ts` before turning lesson-loop on, to close the latent re-occurrence path.

---

## Sample (worst historical pair — ticket 548)

Before 08.5 cleanup (reconstructed from audit doc + SQL header):

| Field | UUID row (deleted) | Backfill row (kept) |
|---|---|---|
| `id` | `<uuid>` (now gone) | `oanda_backfill_548` |
| `oanda_trade_id` | NULL at backfill time | `548` |
| `pnl` | small (lifecycle estimate, pre-realizedPL-fix) | `232.06` (OANDA realizedPL) |
| `opened_at` | within ~35ms of backfill | `2026-04-22 17:27:52.665 UTC` |
| `close_reason` | (varied) | `OANDA_EXTERNAL` |
| `execution_source` | NULL or lifecycle path | `oanda_backfill` |

Total impact across 8 tickets: DB `SUM(pnl)` went from `-6028.68` to `-6370.61` after dedupe.

---

## Forensic queries (executed)

1. Duplicate pairs by `oanda_trade_id`, last 60 days → **0 rows**.
2. Duplicate pairs all-time → **0 rows**.
3. Cross-join of UUID rows vs `oanda_backfill_%` rows on `(market, direction, size, entry_price)` within 600s window → **0 rows**.
4. UUID rows with `oanda_trade_id IS NULL` last 30 days → 3 rows, all `pnl=0`, all manual-ghost-close, harmless to lesson-loop.
5. Row counts by id-type: backfill=82 (Apr 16–28, all `oanda_trade_id` set), uuid=73 (Apr 23–May 12), import=1, "other"=1. No overlap on `oanda_trade_id`.

---

## Code path — where duplicates came from

`apps/worker/src/firm/oanda-sync.ts`, Section 7 (`backfillClosedTrades`, lines 410–470):

- Pulls 200 most-recent OANDA-closed trades.
- For each, idempotency check at line 424: `SELECT id FROM simulated_orders WHERE oanda_trade_id = $1`.
- If no row → INSERT `oanda_backfill_<tradeId>`.

The check is correct ONLY when every previously-written row for that trade has `oanda_trade_id` populated. Historically, lifecycle and legacy execution paths wrote UUID rows WITHOUT setting `oanda_trade_id` (the field was added in commit `a794d64`, post-hoc on existing trades). When those rows got auto-closed (stale-exit, manual-ghost-close, or pnl=0 sentinels), the trade never got linked back to OANDA via Section 4's open-row matcher — Section 4 filters on `WHERE status='open'`. Result: the backfill writer treated those tickets as net-new and inserted twins.

The behaviour today: Section 4 (lines 257–283) sets `oanda_trade_id` on any open UUID row whose entry-price + direction matches an OANDA open trade within $2. That closes the window going forward as long as the row is reconciled while still `status='open'`. The latent gap is the race where a row gets `closed` before any sync cycle touches it.

---

## Recommended fix (bug-fix scope, ship-ready)

**Direction:** harden Section 7's idempotency to also catch unlinked closed UUID rows by `(opened_at, direction, entry_price)` triangulation, not just `oanda_trade_id`.

Concrete patch sketch in `backfillClosedTrades`:

```ts
// Existing oanda_trade_id check first (cheap, exact).
// If miss, also check closed UUID rows that lack oanda_trade_id but
// match opened_at within 5s + same direction + entry_price within $1.
// On match: UPDATE the row's oanda_trade_id (link), don't INSERT a twin.
```

This keeps Section 7 idempotent against any future re-occurrence of the
race that produced the 8 cleaned pairs, without changing trading-loop
behaviour. Pure observability/data-integrity fix.

**Scope classification:** bug-fix (`docs/strategy/proposals` NOT required per CLAUDE.md — "bug fixes that restore intended behaviour"). Recommend filing a short proposal anyway for audit trail, given lesson-loop dependency.

**Pre-merge tests to add:**
1. Seed a UUID row with NULL `oanda_trade_id`, status=closed, matching opened_at/direction/entry — assert backfill links instead of duplicating.
2. Seed a UUID row with NULL `oanda_trade_id` but mismatched price — assert backfill inserts twin (current behaviour for genuinely-unrelated rows).

---

## Lesson-loop activation decision

- Data is clean (verified).
- Re-occurrence risk is low (Section 4 closes the live window) but not zero (closed-before-sync race).
- **Recommendation:** ship the Section 7 hardening, then activate lesson-loop. Without the hardening, a single backfill race in production re-poisons the dataset between cleanups.

---

## Files touched / referenced

- `/home/nithu/code/ai-assistent/apps/worker/src/firm/oanda-sync.ts` (Sections 4, 7)
- `/home/nithu/code/ai-assistent/scripts/oneshot/2026-05-08-fix-duplicate-trades.sql` (historical cleanup)
- `/home/nithu/code/ai-assistent/scripts/oneshot/run-dedupe-08may.mjs` (runner)
- `/home/nithu/code/ai-assistent/scripts/oneshot/README-2026-05-08-dedupe.md` (runbook)
- Commits: `60a627d` (dedupe), `588eb9b` (filter backfill from live PnL), `a794d64` (oanda_trade_id column).
