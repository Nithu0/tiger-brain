---
date: 2026-05-11
project: nexus
type: audit
topic: oanda-reconciliation
status: investigation
---

# OANDA Reconciliation Audit — 2026-05-11

## TL;DR

- /health says `reconciliation.ok=true`, drift=0, `balanceDelta=$13.62`.
- That $13.62 is the operator-relevant unexplained gap (OANDA $92646.08 vs expected $92632.46).
- Last `oanda_backfill` row is **2026-04-28** — 13 days ago. Not because backfill stopped running; the orchestrator runs it every cycle. It's because there's been **nothing new to backfill** since then (the section-3 sync path has been catching every close).
- The reconciliation system has 1 table (`oanda_sync_drift`) + 1 column convention (`execution_source='oanda_backfill'` rows in `simulated_orders`). No purpose-built `reconciliation_runs` table — every cycle is implicit, only mutations are observable.
- $13.62 most-likely cause: **OANDA daily-financing on the trade that crossed UTC midnight** (id `2ad8de2c…`, opened 2026-05-08, closed 2026-05-10, duration ~57h → 2 financing accruals). Plus rounding from `realizedPL` precision.

---

## 1. Current state (snapshot)

`GET /health` (excerpt):
```
reconciliation: {
  ok: true,
  driftCountUnresolved: 0,
  lastBackfillIso: '2026-04-28T17:40:09.618Z',
  balanceDelta: 13.62,
  expectedBalance: 92632.46
}
broker.balance: 92646.08
```

Computed: `expected = STARTING_BALANCE + SUM(simulated_orders.pnl WHERE closed)` = `100000 + (-7367.54) = 92632.46`. Confirmed against DB.

Open trades: 1 (id `a5a0f7d4…`, short 9 XAU @ $4669.76, oanda_trade_id=1087, opened 08:52:59Z today).

`oanda_sync_drift` table: exists (`to_regclass='oanda_sync_drift'`), but the read-only Postgres role lacks SELECT — so /health and /operator/status drift counts use a `GRANT`ed role. Drift records are mutated by `oanda-sync.ts::recordDrift` on pnl-drift or size-drift detection only.

---

## 2. Reconciliation tables + data model

There is **no `reconciliation_runs` ledger**. The system is mutation-based, not append-only.

| Table | Role | Notes |
|---|---|---|
| `simulated_orders` | Trade truth source | `status`, `pnl`, `close_reason`, `oanda_trade_id`, `execution_source` |
| `oanda_sync_drift` | Per-(trade, field) drift records | Fields: `trade_id`, `field` ('pnl'\|'size'\|'closed_status'), `db_value`, `oanda_value`, `detected_at`, `resolved_at`. UPSERT on (trade_id, field). |
| (no `reconciliation_runs`) | — | Sync timing/results are log-only; not persisted |
| (no `account_ledger` / `financing_charges`) | — | Daily OANDA financing is **not booked into the DB**. This is the gap. |

`execution_source` legend in `simulated_orders`:
- `null` — most rows (strategy-executed; bridge fills `oanda_trade_id` later)
- `oanda_backfill` — inserted by `backfillClosedTrades()` (3 rows, all 2026-04-28)
- `oanda_import` — inserted by section 5 of `syncOandaPositions` when a OANDA trade has no DB row (0 rows currently)
- `firm_blade` — 6 rows, 23–24.4

---

## 3. Code flow (one paragraph)

`apps/worker/src/firm/orchestrator.ts:217` calls `syncOandaPositions(db)` **every cycle** (Step 0a, before fact-collection). That function in `apps/worker/src/firm/oanda-sync.ts`:
1. Probes broker reachability (BROKER_STATE_CHANGED event on transition).
2. Reads OANDA open trades + DB open positions.
3. For DB-open rows whose `oanda_trade_id` no longer appears on OANDA → mark closed, use `realizedPL` via 3-step lookup (singleton → closed-list → tx-history-sinceid), record drift if drift detected.
4. Section 7: `backfillClosedTrades(db)` — `getClosedTrades(200)` and INSERT any whose oanda_trade_id isn't already in the DB. **Every cycle, idempotent.**
5. Section 8: PnL-reconcile every 10th cycle for the last 50 closed trades; UPDATE + drift-record on >$0.01 mismatch.

Cadence: orchestrator tick = whatever `runCycle()` is wrapped in (no explicit interval flag found here; likely loops continuously, with intra-cycle waits). Effectively **continuous reconciliation**; "last backfill" is misleading because it timestamps the last *insert*, not the last *check*.

---

## 4. What does the $13.62 represent? (hypothesis)

Top candidates, ranked by likelihood:

**1) OANDA financing on the multi-day trade `2ad8de2c…` (MOST LIKELY)**
- Long 12 XAU, opened 2026-05-08 13:34Z, closed 2026-05-10 22:43Z.
- ~57 hours open → crossed UTC midnight twice → 2 daily-financing accruals.
- `realizedPL` returned by OANDA on close includes financing-at-close, but **OANDA balance** ticks each day the financing-accrual transaction posts (TRANSFER\_FUNDS / DAILY_FINANCING tx-type). If the close's `realizedPL` only reflects the close-event line item and not the prior-day accruals (depends on OANDA's accounting per instrument), the difference shows up as balance > expected.
- Magnitude check: XAU long-financing on practice ≈ ~$0.02-0.06/unit/day. 12 × 2 days = ~$0.5-1.5. Doesn't fully explain $13.62 alone, but contributes.

**2) Cumulative `realizedPL` rounding (also likely)**
- `simulated_orders.pnl` is stored DECIMAL with 2 decimals (e.g. `7.31000` truncated from OANDA's `7.3091`). With 145 closed rows, accumulated rounding can easily reach $5-15.

**3) Trade(s) closed during a worker outage AND outside the last 200 closed-trades window**
- `backfillClosedTrades` fetches only `getClosedTrades(200)`. If a worker outage spanned long enough that closes scrolled past 200, those rows are silently missed forever. Unlikely here because last backfill insert was 2026-04-28 and the recent volume is ~45 closes since — well under 200.

**4) Manual broker action (manual close on phone, manual deposit/withdrawal)**
- Should show as `oanda_import` or backfill row. None present.

**Recommendation:** open `/v3/accounts/{id}/transactions?type=DAILY_FINANCING` since 2026-04-28 and sum amounts. That number minus rounding-drift ≈ $13.62 confirms hypothesis (1)+(2).

---

## 5. Backfill cadence — manual vs scheduled

**Scheduled (implicitly).** `backfillClosedTrades` runs **every orchestrator cycle** (Step 0a → Section 7). There is no cron, no off-hours job. The "lastBackfillIso" field is **misleadingly named**: it's the most-recent `closed_at` of the most-recent `execution_source='oanda_backfill'` row — i.e. *the last time backfill actually inserted a row*. It does NOT reflect "last time the backfill code ran".

This explains the 2-week-old timestamp: section-3 of sync (the regular close-detection path) has been winning every race since 2026-04-28, leaving nothing for the backfill section to insert. **That's healthy behaviour, surfaced as a misleading alarm.**

Manual fallback: `scripts/firm/reconcile-oanda.mjs` (213 lines). Used after the 4-mai #880 incident. Not auto-scheduled.

---

## 6. Dashboard widget — `/readiness`

`apps/dashboard/src/components/balance-reconciliation-widget.tsx` polls `/operator/status` + `/positions/stats` every 15s. Shows:
- OANDA balance / DB cumulative PnL / Initial balance
- **Expected balance** (initial + db pnl)
- **Delta** (oanda - expected), colour-coded: green ≤ $10, yellow > $10, red > $50
- Drift entries (from `reconciliation.driftCountUnresolved`)
- "Last backfill" + "Backfill rows" — uses the same misleading `closed_at` timestamp

With current state ($13.62 delta) the widget renders **yellow** with text "Delta exceeds $10 — minor drift; usually swap/financing or rounding." That comment was prescient — exactly the leading hypothesis.

---

## 7. Gaps in the recon flow

1. **`lastBackfillIso` is mislabelled.** It's "last inserted backfill row's close timestamp", not "last backfill run". Operator-facing health field implies a stale cron — there is no cron. Fix: rename to `lastBackfillInsertIso` and add a separate `lastSyncCycleIso` that ticks every cycle (or reuse `worker.lastHeartbeatSec`).

2. **No financing/swap ledger.** `simulated_orders.pnl = realizedPL` on close, but OANDA daily-financing transactions post to balance independently between open and close. There is no DB record of these. Any trade open across UTC midnight introduces an unaccounted gap. Fix: pull `/v3/accounts/{id}/transactions?type=DAILY_FINANCING` periodically (e.g. daily) and persist to a new `oanda_financing` table; include in expected-balance computation.

3. **Backfill window is hardcoded at 200.** A multi-day worker outage during a burst could lose closes forever. Bound is sound, but no alert if `getClosedTrades(200)` returns 200 (saturated). Fix: detect saturation, widen one-time, and Discord-alert.

4. **`reconciliation_runs` table missing.** No append-only audit trail of sync runs. Hard to investigate "was the worker syncing 9 hours ago?". Fix: minimal `reconciliation_runs(cycle_no, started_at, finished_at, mismatches_count, error)`; row per cycle; rotate >30 days.

5. **`oanda_sync_drift` permissions.** Read-only MCP role lacks SELECT. Audit-from-Claude is blind. Fix: `GRANT SELECT ON oanda_sync_drift TO <ro_role>`.

6. **Tolerance bounds for "ok".** `rollupStatus` only flags reconciliation as degraded if `|balanceDelta| > 100`. The widget uses $50 / $10. Two thresholds, two messages — pick one canonical band per principle 1 (report-only, no auto-action).

7. **No "expected NAV" comparison.** Expected balance ignores unrealized PnL on the open trade. NAV-vs-(expected + unrealizedPL) would catch entry-price drift, which today only `drift-monitor.ts` checks (and only on-demand via status-report).

---

## 8. Numbers, for the record

- Closed trades: 145 (136 with `execution_source=null`, 3 oanda_backfill, 6 firm_blade)
- Cumulative pnl: -$7367.54 (gross gain $16628.95, gross loss -$23996.49)
- Open: 1 (short 9 XAU @ $4669.76)
- Last close: 2026-05-11 08:12Z
- Last backfill insert: 2026-04-28 17:40Z
- Multi-day trades (closed): 1 (the 2026-05-08 → 2026-05-10 long)
- Overnight trades (closed): 2

---

## 9. Operator decision points

1. Set `STARTING_BALANCE` env explicitly (currently uses default 100000 per `initialBalanceSource='default'` path). Confirm 100000 matches the actual practice-account seed.
2. Decide on financing-ledger build vs. accept-and-document drift band.
3. Approve `GRANT SELECT ON oanda_sync_drift TO <ro_role>` so audits like this can read drift rows directly.

No actions taken — strictly investigation per principle 1 + 5.

— Claude (audit thread, 2026-05-11)
