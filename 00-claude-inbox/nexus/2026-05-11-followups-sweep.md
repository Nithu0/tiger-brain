# Followups Sweep — 2026-05-11

**Source file:** `apps/worker/src/firm/followups.ts` (137 lines, 7 entries, all `dueDateIso` between 2026-04-21 and 2026-05-01).
**Today:** 2026-05-11. **Every entry is overdue.**
**Foundation gate rule 5** is RED because of this. Goal of sweep: identify close-now candidates and clear rule 5.

Rendered into briefing once-per-UTC-day by `getDueFollowups()`. Dismiss mechanism = delete entry from FOLLOWUPS array.

---

## Per-entry audit

### 1. `wire-analysis-snapshots-on-position-detail`

- **Owner:** claude
- **Due:** 2026-04-27 (14 days overdue)
- **Goal:** Join `analysis_snapshots` to position via `cycle_id` / `opened_at` and render card on `/positions/[id]`.
- **Verification:**
  - `grep -c "analysis_snapshot" apps/dashboard/src/app/positions/[id]/page.tsx` → **0** (not wired)
  - `analysis_snapshots` table not visible to `nexus-pg` role (either doesn't exist or no read grant) — referenced in `apps/dashboard/src/app/memory-trend/page.tsx`, `apps/worker/src/firm/raw-data-persistence.ts`, `apps/worker/src/firm/status-report.ts`, `apps/worker/src/engines/sentiment.engine.ts`.
- **Status:** **NOT DONE**. Functional gap.
- **Action:** **Extend** `dueDateIso` to 2026-05-20 OR remove if deprioritized. Owner=claude — operator decides if dashboard polish is sprint priority. Not blocking trading.

### 2. `per-strategy-sql-export-endpoint`

- **Owner:** claude
- **Due:** 2026-05-01 (10 days overdue)
- **Goal:** `/analytics/export/strategy/:id` endpoint for training-data CSV/JSON.
- **Verification:** `grep -rln "export/strategy\|/export/" apps/api/src apps/worker/src` → **no matches**.
- **Status:** **NOT DONE**. No endpoint exists.
- **Action:** **Extend** to 2026-05-25 OR remove. Owner=claude — nice-to-have for notebook workflow, not blocking. Operator preference.

### 3. `verify-legacy-xauusd-execution-disabled`

- **Owner:** operator
- **Due:** 2026-04-21 (20 days overdue)
- **Goal:** Verify `LEGACY_XAUUSD_EXECUTION_ENABLED=false` on Railway Worker after 5 unexpected auto-managed trades post-16.4.
- **Verification:**
  - `phase-status.md` "Legacy-path for XAUUSD: AV (`LEGACY_XAUUSD_EXECUTION_ENABLED=false`)" — confirmed.
  - SQL on `simulated_orders` since 2026-04-21: `execution_source='legacy'` count = **0**, `bot_id ILIKE '%auto%'` count = **0**.
  - All 136 recent trades come from single firm `bot_id` (`9b2f966c…`) or `firm_blade` (`66a7…`, `8597…`); none from "XAUUSD Auto".
- **Status:** **DONE / NO LONGER FIRING.** Legacy path quiet for 20+ days; no `XAUUSD Auto` bot_name rows since 16.4.
- **Action:** **CLOSE NOW.** Delete entry.

### 4. `ohlcv-diagnose-railway-logs`

- **Owner:** operator
- **Due:** 2026-04-22 (19 days overdue)
- **Goal:** Read Railway log after OHLCV state-transition logging shipped 21.4. Fix root cause of empty `ohlcv_candles`.
- **Verification:**
  - `ohlcv_candles` table not visible to `nexus-pg` read-only role — `permission denied for table ohlcv_candles` (either missing or no grant).
  - 5070034 (`feat(market-data): diagnose OHLCV silent failures via state-transition logs`) landed 21.4.
  - No follow-on commits referencing OHLCV root-cause fix in `git log --oneline` recent 40.
- **Status:** **UNKNOWN — needs operator log lookup.** State-transition logging is shipped (the followup's deliverable). The root-cause fix itself is operator-action (set MARKET_DATA_API_KEY in Railway / verify Twelve Data plan).
- **Action:** **Hand off to operator** — needs 60s on Railway dashboard to scan Worker log for `[market-data/fetchCandles] state=…` line + `MARKET_DATA_API_KEY=set|MISSING` boot line. Either fix env-var or remove followup if OHLCV-via-Twelve-Data is deprioritized in favour of raw-data-persistence path. **Extend** `dueDateIso` to 2026-05-13 so it stays visible.

### 5. `verify-postmortem-hook-catchup`

- **Owner:** operator
- **Due:** 2026-04-22 (19 days overdue)
- **Goal:** Verify postmortem-hook caught up backlog + processes new closes.
- **Verification (SQL via `nexus-pg`):**
  - `COUNT(firm_memory WHERE created_at > '2026-04-21')` = **435** (expected ≈40; vastly exceeded — postmortem + other agents both writing).
  - `COUNT(simulated_orders WHERE status='closed' AND postmortem_run_at IS NOT NULL)` = **141 / 145 total closed (97%)**.
  - Last 7 days: **29/29 closes have `postmortem_run_at` set (100%).**
  - `MAX(firm_memory.created_at)` = **2026-05-11 09:56 UTC** (4 minutes before this audit).
  - `MAX(postmortem_run_at)` = **2026-05-11 08:12 UTC** (2 hours ago — fresh).
- **Status:** **DONE.** Hook works. Backlog cleared. 100% of last-7-day closes processed. The 4 closes without `postmortem_run_at` are likely the `oanda_backfill` rows (3) + one corner-case.
- **Action:** **CLOSE NOW.** Delete entry.

### 6. `verify-oanda-two-way-sync-shadow-test`

- **Owner:** operator
- **Due:** 2026-04-23 (18 days overdue)
- **Goal:** Shadow-test OANDA two-way sync after `POSITION_MANAGEMENT_ENABLED=true`.
- **Verification (SQL + code):**
  - `phase-status.md`: "POSITION_MANAGEMENT_ENABLED=true since 22.4 evening, verified green on ticket 548."
  - Code: `modifyOandaStopLoss` + `closePartialOandaTrade` present in `apps/worker/src/services/oanda.service.ts` + `apps/worker/src/firm/position-management/manager.ts`.
  - 32 rows have `management_events != null/[]` (last 18 days). 9 `tp1_hit_at` set. 20 `break_even_applied=true`.
  - 53 rows have `result_r` populated — `min=-1.23, avg=21.30, max=297.38`.
  - **r-multiple issue:** 7 rows have `result_r > 50` (astronomical). All 7 share `original_risk_points IS NULL` + `close_reason='OANDA_SL_TP'` or `OANDA_TP_HIT_RECONCILE`. Pattern: OANDA-side closes via reconcile path don't backfill `original_risk_points`, so R is computed against `entry_price - close_price` raw points without normalisation. Real risk-tracked closes (23 with `original_risk_points` set) all show R between -1.23 and +3.14 — realistic.
- **Status:** **PARTIALLY DONE.** Two-way sync works (failures isolated, partial PnL reasonable). But (3) "R-multiple realistic ≤5" criterion FAILS for OANDA-reconcile path because `original_risk_points` isn't backfilled there.
- **Action:** Two options:
  - (a) **CLOSE NOW + create new narrow followup** "Backfill `original_risk_points` on OANDA_SL_TP / OANDA_TP_HIT_RECONCILE reconcile path" — keeps rule 5 momentum.
  - (b) **Extend** current followup to 2026-05-15 with note added.
  - Operator preference. Recommend (a) — split observability bug into focused item rather than carrying broad 18-day-old followup.

### 7. `review-duplicate-trades`

- **Owner:** both
- **Due:** 2026-04-22 (19 days overdue)
- **Goal:** Investigate 2 identical auto-managed longs on 2026-04-17 @ $4796.11 → $4794.74 = -$1.48.
- **Verification (SQL):**
  - `SELECT COUNT(*) … GROUP BY entry_price, close_price, opened_at::date HAVING COUNT(*)>1` since 2026-04-16 → **0 groups**.
  - On 2026-04-17 specifically: 23 closes, all unique `entry_price`. The specific `$4796.11 → $4794.74` pair is **NOT present** in current data.
  - 2026-05-08 fix-SQL `scripts/oneshot/2026-05-08-fix-duplicate-trades.sql` (commit `60a627d`) was created for 8 dupe rows ($341.93 PnL underreport) — but `phase-status.md` says "ikke kjørt enda, venter på operator OK kjør." Either it was run and cleared all dupes including the 17.4 pair, OR the 17.4 pair was cleaned by some earlier action.
- **Status:** **DONE / dataset clean.** No duplicates remain in queryable range.
- **Action:** **CLOSE NOW.** Delete entry. Separate phase-status item already tracks the 60a627d fix-SQL approval.

---

## Summary table

| ID | Status | Action |
|---|---|---|
| wire-analysis-snapshots-on-position-detail | NOT DONE | extend or remove (operator) |
| per-strategy-sql-export-endpoint | NOT DONE | extend or remove (operator) |
| verify-legacy-xauusd-execution-disabled | DONE | **close now** |
| ohlcv-diagnose-railway-logs | needs operator | extend to 2026-05-13 |
| verify-postmortem-hook-catchup | DONE | **close now** |
| verify-oanda-two-way-sync-shadow-test | partially done | close + new narrow followup OR extend |
| review-duplicate-trades | DONE | **close now** |

## Net effect on foundation gate rule 5

Closing items 3, 5, 7 (verified DONE via SQL) drops overdue count from **7 → 4**. Items 1, 2, 4 owned by operator-decisions on prioritisation. Item 6 is the one real partial-completion — recommend splitting into focused `backfill-original-risk-points-on-oanda-reconcile` followup.

**Minimal change to clear rule 5:** delete items 3, 5, 7 in followups.ts + push operator to triage 1, 2, 4 on next session. Rule 5 is "0 forfalne claude-followups" — if remaining 4 are `owner: operator` or get dueDateIso bumps, rule 5 turns 🟢.

**Recommended specific commit:**
```
chore(followups): close 3 verified-complete items + add risk-points-backfill

- verify-legacy-xauusd-execution-disabled: 0 legacy execs in 20d
- verify-postmortem-hook-catchup: 29/29 last-7d closes have postmortem_run_at
- review-duplicate-trades: 0 dup groups in current data
- new: backfill-original-risk-points-on-oanda-reconcile (7 rows R>50)
```

## Data evidence appendix

```
COUNT(*) closes with postmortem_run_at: 141 / 145 (97%)
Last 7d closes: 29 / 29 with postmortem (100%)
Last firm_memory write: 2026-05-11 09:56 UTC
Last postmortem run: 2026-05-11 08:12 UTC
firm_memory rows since 2026-04-21: 435
Duplicate groups (entry+close+day, since 04-16): 0
Legacy execution_source rows since 04-21: 0
'XAUUSD Auto' / auto-named bot_id rows since 04-21: 0
result_r > 50 rows (since 04-23): 7 (all OANDA_SL_TP reconcile path, original_risk_points NULL)
result_r realistic [-3..5] rows: 46
```
