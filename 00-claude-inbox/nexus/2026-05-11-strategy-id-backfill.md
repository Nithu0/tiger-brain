# Strategy-id backfill — STOPPED, not executed

**Date:** 2026-05-11
**Trigger:** commit `0ad348f` fix for NULL `strategy_id` / `execution_source` / `atr_at_entry` / `entry_conviction_score` in `simulated_orders` since `e15b67a`.
**Outcome:** **STOPPED before any writes.** Two blockers; details below.

---

## Blocker 1: pg-rw MCP is read-only

The `mcp__nexus-pg-rw__query` tool refuses writes:

```
> SHOW transaction_read_only;
on
> UPDATE simulated_orders SET strategy_id=strategy_id WHERE id='__nonexistent__';
MCP error -32603: cannot execute UPDATE in a read-only transaction
```

`default_transaction_read_only=off` server-side, but the MCP server forces the session into a read-only transaction. The tool description ("Run a read-only SQL query") matches. No writes possible from Claude.

**Operator fix paths:**
- Reconfigure the `nexus-pg-rw` MCP server to issue `SET TRANSACTION READ WRITE;` after `BEGIN`, or remove the read-only enforcement
- Run the UPDATE statements manually via `psql` / Railway DB shell using the script in "Proposed UPDATE" below
- Bypass MCP and use a worker-side maintenance script

## Blocker 2: Task premise is off — only 59 of 138 rows are bug-window

| Row class | Count | `decision_cycle_id` | `signal_id` | Recoverable? |
|---|---|---|---|---|
| Bug-window, has cycle + signal | 41 | yes | yes | yes (signals.source + blackboard PROPOSAL) |
| Bug-window, signal only | 18 | NULL | yes | partial (strategy/exec/conv from signals; no ATR) |
| Pre-bug legacy (Apr 16-22) | 79 | NULL | NULL | NO data path — predate firm-strategy bridge |

Commit dates:
- `e15b67a` — 2026-04-26 23:52 (bug introduced — TIER 3 strategy bridge added but UPDATE missing 4 columns)
- `0ad348f` — 2026-05-11 12:36 (fix)

The 79 "legacy" rows opened 2026-04-16 to 2026-04-22 — all from one bot, 4+ days BEFORE `e15b67a`. They never had this metadata wired because the strategy bridge didn't exist yet. They are NOT victims of the bug-fix commit. The commit message claims "138 of 138" but the actual bug-attributable count is 59.

Recommendation: scope the backfill to the 59 in-bug-window rows and leave the 79 legacy rows alone (or backfill them with a `legacy_pre_e15b67a` sentinel if downstream analytics chokes on NULL).

---

## Phase 1 results (read-only diagnostic, complete)

### Schema confirmation

- `simulated_orders` has `decision_cycle_id`, `signal_id`, `strategy_id`, `execution_source`, `atr_at_entry`, `entry_conviction_score`, `portfolio_regime_at_entry`.
- `signals` has `id`, `bot_id`, `market`, `direction`, `confidence` (0–100 scale!), `rationale`, `source` (e.g. `firm-strategy:xau-volatility-expansion`), `created_at`. NO `decision_cycle_id`, NO `atr`, NO `regime`.
- `blackboard` has `decision_cycle_id`, `topic`, `state` (jsonb) — PROPOSAL messages on `xauusd.{vol-expansion,session-break,scalp,orb}.signal` carry `state.atr` / `state.atr14` / `state.strategy` / `confidence` (0–1).

### Pre-state snapshot (full table)

```sql
SELECT COUNT(*) FILTER (WHERE strategy_id IS NULL) AS null_strategy,
       COUNT(*) FILTER (WHERE execution_source IS NULL) AS null_exec,
       COUNT(*) FILTER (WHERE atr_at_entry IS NULL) AS null_atr,
       COUNT(*) FILTER (WHERE entry_conviction_score IS NULL) AS null_conv,
       COUNT(*) FILTER (WHERE portfolio_regime_at_entry IS NULL) AS null_portreg,
       COUNT(*) FILTER (WHERE strategy_id IS NULL AND execution_source IS NULL) AS null_both,
       COUNT(*) AS total
FROM simulated_orders;
```

| total | null_strategy | null_exec | null_atr | null_conv | null_portreg | null_both |
|---|---|---|---|---|---|---|
| 147 | 144 | 138 | 141 | 141 | 136 | 138 |

The 3 `oanda_backfill_*` sentinel rows have `strategy_id='oanda_backfill'` / `execution_source='oanda_backfill'` — protected by `execution_source IS NULL` predicate.

### Bug-window snapshot (opened_at ≥ 2026-04-26 22:00 UTC)

| Subset | Count |
|---|---|
| Total bug-window rows | 62 |
| NULL_both | 59 |
| With cycle | 41 |
| With signal_id | 59 |

### Join validation

- `signals.id = simulated_orders.signal_id`: **59/59 = 100%** of bug-window NULL rows match
- `blackboard.decision_cycle_id = simulated_orders.decision_cycle_id AND message_type='PROPOSAL'`: **41/41 = 100%** of bug-window NULL rows that have a cycle
- Distinct `signals.source` values on bug-window matches: `firm-strategy:xau-volatility-expansion` (37), `firm-strategy:xau-session-breakout` (13), `firm-strategy:xau-orb` (5), `firm-strategy:xau-scalp-overlap` (4)
- `signals.confidence` is on **0–100 scale**, `blackboard.confidence` is **0–1 scale**. The fix writes `proposal.confidence` (0–1). Conversion: `entry_conviction_score = signals.confidence / 100.0` to match the fix.

### Recoverable values per column

| Column | Bug-window 41 (cycle+signal) | Bug-window 18 (signal only) | Legacy 79 |
|---|---|---|---|
| `strategy_id` | YES (blackboard `state.strategy` OR `replace(signals.source,'firm-strategy:','')`) | YES (from signals.source) | NO |
| `execution_source` | YES (literal `'firm_strategy'`) | YES | NO |
| `entry_conviction_score` | YES (blackboard `confidence` or `signals.confidence/100`) | YES (signals.confidence/100) | NO |
| `atr_at_entry` | partial — vol-expansion only (`state.atr14`), scalp `state.atr`; session-break/ORB stay NULL (matches live) | NO (no blackboard reachable) | NO |
| `portfolio_regime_at_entry` | NO (blackboard `xauusd.portfolio.context` not present on these cycles, 0/41) | NO | NO |

Portfolio_regime is the most affected gap. Per fix doc, that column is only filled live from blackboard with 300s freshness — those snapshots have rotated out / been TTL'd for these cycles. No retroactive recovery path. Skip per task constraint ("Do not do best-effort approximate backfills on financial data").

---

## Proposed UPDATE (NOT executed — needs RW DB access)

Run via `psql` or RW DB shell. Each UPDATE filters defensively with `strategy_id IS NULL AND execution_source IS NULL` so re-running is idempotent and the 3 `oanda_backfill` sentinels are untouched.

### Step 1 — single-strategy dry-run (vol-expansion, 37 rows expected)

```sql
BEGIN;
UPDATE simulated_orders so
   SET strategy_id = replace(s.source, 'firm-strategy:', ''),
       execution_source = 'firm_strategy',
       entry_conviction_score = s.confidence / 100.0
  FROM signals s
 WHERE s.id = so.signal_id
   AND so.strategy_id IS NULL
   AND so.execution_source IS NULL
   AND so.opened_at >= '2026-04-26 22:00:00+00'
   AND s.source = 'firm-strategy:xau-volatility-expansion';
-- Verify ~37 rows
SELECT COUNT(*) FROM simulated_orders
 WHERE strategy_id='xau-volatility-expansion'
   AND execution_source='firm_strategy'
   AND opened_at >= '2026-04-26 22:00:00+00';
-- If clean: COMMIT;  else: ROLLBACK;
```

### Step 2 — wide UPDATE (all 59 rows: strategy/exec/conv)

```sql
BEGIN;
UPDATE simulated_orders so
   SET strategy_id = replace(s.source, 'firm-strategy:', ''),
       execution_source = 'firm_strategy',
       entry_conviction_score = COALESCE(so.entry_conviction_score, s.confidence / 100.0)
  FROM signals s
 WHERE s.id = so.signal_id
   AND so.strategy_id IS NULL
   AND so.execution_source IS NULL
   AND so.opened_at >= '2026-04-26 22:00:00+00';
-- Expect ~59 rows updated
SELECT COUNT(*) FROM simulated_orders
 WHERE execution_source = 'firm_strategy'
   AND opened_at >= '2026-04-26 22:00:00+00';
-- If clean: COMMIT;
```

### Step 3 — ATR backfill for vol-expansion + scalp (subset of 41)

```sql
BEGIN;
UPDATE simulated_orders so
   SET atr_at_entry = COALESCE(
     so.atr_at_entry,
     (b.state->>'atr14')::numeric,
     (b.state->>'atr')::numeric
   )
  FROM blackboard b
 WHERE b.decision_cycle_id = so.decision_cycle_id
   AND b.message_type = 'PROPOSAL'
   AND b.topic IN ('xauusd.vol-expansion.signal','xauusd.scalp.signal')
   AND so.atr_at_entry IS NULL
   AND so.opened_at >= '2026-04-26 22:00:00+00'
   AND ((b.state->>'atr14') IS NOT NULL OR (b.state->>'atr') IS NOT NULL);
-- Expect ~28 rows for vol-exp + ~1 for scalp = ~29
SELECT strategy_id, COUNT(*) FROM simulated_orders
 WHERE atr_at_entry IS NOT NULL
   AND opened_at >= '2026-04-26 22:00:00+00'
 GROUP BY 1;
-- If clean: COMMIT;
```

### NOT recommended: `portfolio_regime_at_entry`

The blackboard data needed isn't present on the cycle (0/41 cycles have `xauusd.portfolio.context`). Don't backfill — leaves NULL, downstream analytics already know to treat as missing. If operator wants a sentinel, fill with `'unknown_pre_fbdf1b3'` for the 5 rows where it was set live and `'unknown_pre_0ad348f'` for the rest, but that's pure bookkeeping.

---

## Post-state verification SQL (re-run after the COMMITs)

```sql
-- A. Per-strategy counts in the bug window
SELECT strategy_id, execution_source, COUNT(*) AS n,
       COUNT(*) FILTER (WHERE atr_at_entry IS NOT NULL) AS with_atr,
       COUNT(*) FILTER (WHERE entry_conviction_score IS NOT NULL) AS with_conv
  FROM simulated_orders
 WHERE opened_at >= '2026-04-26 22:00:00+00'
   AND execution_source = 'firm_strategy'
 GROUP BY 1,2 ORDER BY 3 DESC;

-- B. Whole-table NULL recount
SELECT COUNT(*) FILTER (WHERE strategy_id IS NULL) AS null_strategy,
       COUNT(*) FILTER (WHERE execution_source IS NULL) AS null_exec,
       COUNT(*) FILTER (WHERE atr_at_entry IS NULL) AS null_atr,
       COUNT(*) FILTER (WHERE entry_conviction_score IS NULL) AS null_conv,
       COUNT(DISTINCT strategy_id) AS distinct_strats
  FROM simulated_orders;

-- C. Sanity check oanda_backfill sentinels untouched
SELECT id, strategy_id, execution_source FROM simulated_orders
 WHERE id LIKE 'oanda_backfill_%';
-- Expected: 3 rows, all with strategy_id='oanda_backfill'
```

Expected post-state for the bug window:
- `xau-volatility-expansion`: 37 rows, ~28 with ATR
- `xau-session-breakout`: 13 rows, 0 with ATR (state.atr is NULL live)
- `xau-orb`: 5 rows, 0 with ATR (ORB has no ATR in state)
- `xau-scalp-overlap`: 4 rows, ~1 with ATR

Expected whole-table NULL deltas after Step 2 + Step 3:
- `null_strategy`: 144 → 85 (−59)
- `null_exec`: 138 → 79 (−59)
- `null_conv`: 141 → 82 (−59)
- `null_atr`: 141 → ~112 (−29 vol-exp + scalp)
- `null_portreg`: unchanged (136) — not backfilled

---

## Confidence

**Stopped.** No writes performed. Diagnostic complete and matches the fix commit's data-flow exactly. Operator action needed:
1. Resolve pg-rw MCP read-only enforcement OR run UPDATEs manually via psql.
2. Confirm scope: 59-row bug-window backfill (recommended), or include 79 legacy rows as `legacy_unknown` sentinel (not recommended unless analytics breaks).

Once the writes land, the 79 legacy rows + 5 still-NULL `portfolio_regime_at_entry` will be the only remaining NULL gaps and should be documented as known-unknowns.
