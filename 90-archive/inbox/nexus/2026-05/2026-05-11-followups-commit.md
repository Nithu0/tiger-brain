# Followups cleanup — 2026-05-11

**Commit:** `1bb20f8 chore(followups): close 3 verified-complete + narrow oanda-two-way`
**File:** `apps/worker/src/firm/followups.ts`
**tsc --noEmit (apps/worker):** clean (no output, exit 0)
**Pushed:** NO (held per operator policy — awaits "OK kjør")

## Before state — 7 entries in FOLLOWUPS[]

| id | owner | dueDateIso | status |
|---|---|---|---|
| wire-analysis-snapshots-on-position-detail | claude | 2026-04-27 | leave (real gap) |
| per-strategy-sql-export-endpoint | claude | 2026-05-01 | leave (maybe superseded by nexus-pg MCP) |
| verify-legacy-xauusd-execution-disabled | operator | 2026-04-21 | DELETE (verified: 0 legacy rows since 2026-04-21) |
| ohlcv-diagnose-railway-logs | operator | 2026-04-22 | leave (out of claude hands) |
| verify-postmortem-hook-catchup | operator | 2026-04-22 | DELETE (verified: 141/145 closed have postmortem_run_at; 100% last 7d) |
| verify-oanda-two-way-sync-shadow-test | operator | 2026-04-23 | REPLACE with narrower backfill task |
| review-duplicate-trades | both | 2026-04-22 | DELETE (deduped 08.5, 0 groups remaining) |

## After state — 4 entries in FOLLOWUPS[]

| id | owner | dueDateIso | overdue today (2026-05-11)? |
|---|---|---|---|
| wire-analysis-snapshots-on-position-detail | claude | 2026-04-27 | YES (14d) |
| per-strategy-sql-export-endpoint | claude | 2026-05-01 | YES (10d) |
| ohlcv-diagnose-railway-logs | operator | 2026-04-22 | YES (19d) |
| backfill-original-risk-points-on-oanda-reconcile | claude | 2026-05-18 | NO (future, +7d) |

**Overdue count today:** 3 (was 7)
- claude: 2 (wire-analysis-snapshots, per-strategy-sql-export)
- operator: 1 (ohlcv-diagnose-railway-logs)
- both: 0

The new `backfill-original-risk-points-on-oanda-reconcile` is dated future (2026-05-18) so it does not count as overdue.

## New followup spec (added)

```ts
{
  id: "backfill-original-risk-points-on-oanda-reconcile",
  title: "Backfill original_risk_points on OANDA reconcile-path rows",
  detail:
    "Backfill original_risk_points on rows where close_reason IN ('OANDA_SL_TP'," +
    "'OANDA_TP_HIT_RECONCILE') and original_risk_points IS NULL — affects 7 historical rows + " +
    "future reconcile inserts. NULL risk causes astronomical R values in postmortem/analytics.",
  dueDateIso: "2026-05-18",
  owner: "claude",
}
```

**Rationale:** the broader `verify-oanda-two-way-sync-shadow-test` was over-scoped — the sync itself works (operator confirmed Worker logs clean, no systematic OANDA failures). Only narrow gap remaining: 7 rows where the reconcile-path inserter forgot to populate `original_risk_points`, which then explodes R-multiples in downstream analytics. Replacement followup pins exactly that work with a +7d due date.

## Foundation Rule 5 impact

Before: 7 overdue claude/operator/both — Rule 5 = RED.
After: 3 overdue (2 claude + 1 operator out-of-hands).

The 2 remaining claude items (`wire-analysis-snapshots`, `per-strategy-sql-export`) are real functional gaps left for future pickup; not verifiable as complete. Rule 5 likely still RED unless operator considers `per-strategy-sql-export` superseded by nexus-pg MCP (would drop claude-overdue to 1).

## Audit references (SQL run by earlier agent)

1. `verify-legacy-xauusd-execution-disabled`: `SELECT COUNT(*) FROM simulated_orders WHERE execution_source='legacy' AND opened_at > '2026-04-21'` → 0
2. `verify-postmortem-hook-catchup`: 141/145 closed orders have non-null `postmortem_run_at`; last-7d coverage = 100%
3. `review-duplicate-trades`: dedupe ran 2026-05-08; duplicate-group count = 0

## Not pushed

Per `~/.claude/CLAUDE.md` rule "`OK kjør`-gate before every push": holding `1bb20f8` locally until operator clears.
