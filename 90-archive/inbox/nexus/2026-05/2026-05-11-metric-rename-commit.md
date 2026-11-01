---
date: 2026-05-11
project: nexus
kind: observability-fix
commit: 588eb9b
status: shipped (local, awaiting OK-kjør for push)
audit_ref: audit-2026-05-11 (recon-audit + strategy-regime-fit)
---

# Metric rename + PnL backfill filter — 2026-05-11

Two observability bugs from the 2026-05-11 audit, fixed in one commit. **No behaviour change in the trading loop.** Pure rename + query-layer filter.

## Bug 1 — `lastBackfillIso` was misleading operators

### Symptom
`/health` and `/operator/status` exposed `reconciliation.lastBackfillIso`, surfaced in the dashboard `BalanceReconciliationWidget` as "Last backfill". Value was ~2 weeks old → triggered operator alarm despite being healthy.

### Root cause
The field was the most-recent `closed_at` on a row tagged `execution_source='oanda_backfill'`. That's "row-insert time", not "job-run time". `backfillClosedTrades()` runs every orchestrator cycle (Step 0a → Section 7 in `oanda-sync.ts`); a stale timestamp just means inline close-detection caught everything before the sweep needed to. Healthy, but the label panicked.

### Fix
| File | Change |
|---|---|
| `apps/api/src/routes/health.ts` | Renamed field `lastBackfillIso` → `lastBackfillRowIso`. Added second field `lastSyncCycleIso` = `GREATEST(MAX(closed_at), MAX(opened_at))` across ALL rows. JSDoc explains why stale-backfill is healthy. |
| `apps/api/src/routes/operator.ts` | Same rename + new `lastSyncCycleIso` query. Kept legacy aliases `lastBackfillAt` and `backfillRowCount` for back-compat (the dashboard widget had always read the legacy names, which were never actually emitted — so the row had always shown "—"). |
| `apps/dashboard/src/components/balance-reconciliation-widget.tsx` | Reads new fields (with legacy fallback). Added "Last sync cycle" row above "Last backfill row". Tooltips explain the semantics. |

### Live-DB verification
```
last_backfill_row  = 2026-04-28T17:40:09Z   ← stale (panic-trigger)
last_any_activity  = 2026-05-11T10:15:31Z   ← fresh (real heartbeat)
```
Exactly the diagnosis — and now both are visible separately.

## Bug 2 — PnL widgets poisoned by `oanda_backfill` rows

### Symptom
Per audit: dashboard "Total PnL" panels sum across all `execution_source`, including pre-firm OANDA-sync rows.

### Live-DB before vs after (cumulative, all-time)
```
pnl_all       = $-7,367.54   (145 rows incl 3 backfill)
pnl_live      = $-6,615.40   (142 rows, backfill excluded)  ← new headline
pnl_backfill  = $-752.14     (3 rows)
```

**Delta in operator-facing PnL: +$752 (less negative).**

Note: this is **smaller than the prompt's audit numbers** (79 rows / -$10,797). Only 3 backfill rows exist in prod right now. The prompt's numbers must be from an earlier DB state or different audit window. Flagging for operator review (see "Uncertain" below).

For the headline 7d-window the delta is **$0** (no backfill rows in last 7 days). The fix matters most for the cumulative all-time / equity-curve widgets.

### Fix
| File | Change |
|---|---|
| `apps/api/src/routes/metrics.ts` | `/metrics/overview` `total_pnl` now excludes `execution_source='oanda_backfill'`. This is the field powering the sidebar, home page, console, morning, warroom — the most-visible PnL number. |
| `apps/api/src/routes/positions.ts` | `/positions/stats` and `/positions/pnl-history` accept `mode=live` (default) or `mode=all`. Default flipped to `live`. Response gained `backfillPnl` field so reconciliation callers can add it back to get cumulative-balance numbers without a 2nd call. |
| `apps/dashboard/src/lib/api.ts` | `positionStats()` accepts optional `mode` param. `PositionStatsResponse.backfillPnl` typed as optional. |
| `apps/dashboard/src/components/balance-reconciliation-widget.tsx` | Pins `mode=all` so OANDA-vs-DB math stays correct. (Backfill rows DID move broker balance — they're real OANDA trades; reconciliation must include them.) |

### What was deliberately NOT changed
- `apps/api/src/routes/health.ts:285` `cumulativePnl` for `expectedBalance` — same reason as reconciliation widget. Backfill trades moved real balance, must stay in reconciliation sum.
- `/operator/status` `executionSources` array — that's the per-source breakdown, backfill should be visible there by design.
- All worker-side PnL queries (drawdown, daily-pnl, challenge service, etc.) — these gate live trading off recent activity windows, where backfill rows aren't a factor. Out of scope for "fix dashboard noise". Worth a follow-up audit if any of these turn out to be poisoned.

## Verification

- `tsc --noEmit` clean across all three workspaces (api, dashboard, worker)
- DB query confirms diagnosis numbers
- Commit: `588eb9b`
- NOT pushed (awaits "OK kjør")

## Uncertain / flagged for operator review

1. **Audit numbers don't match prod state.** Prompt said 79 backfill rows / -$10,797. Live DB shows 3 rows / -$752. Possible explanations: different DB instance audited, different cutoff date, audit was wrong, or someone cleaned up backfill rows between audit and now. Worth checking the original audit doc.
2. **Back-compat aliases (`lastBackfillAt`, `backfillRowCount`).** The dashboard widget's old code read field names that were never actually emitted. That means the "Last backfill" row in the widget had been broken (showing "—") since deploy. I kept the legacy alias keys in the API response in case any other consumer reads them. Can remove in a follow-up after confirming nothing else reads them.
3. **`/positions/stats` mode-default change.** This is a breaking API contract change for any external caller (n8n? cron job?) that summed `totalPnl`. Anything outside the dashboard that hits `/positions/stats` will now silently get live-only PnL. If that's a problem, callers can pass `?mode=all`.
4. **Worker-side PnL queries not touched.** Drawdown/challenge/risk service all `SUM(pnl)` without filtering. They use short time windows so probably immune in practice, but I didn't audit each one. Flag for a future pass.

## Files touched

```
apps/api/src/routes/health.ts
apps/api/src/routes/metrics.ts
apps/api/src/routes/operator.ts
apps/api/src/routes/positions.ts
apps/dashboard/src/components/balance-reconciliation-widget.tsx
apps/dashboard/src/lib/api.ts
```
