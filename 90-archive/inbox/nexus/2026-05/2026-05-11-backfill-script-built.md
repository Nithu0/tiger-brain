# 2026-05-11 — strategy_id backfill script built (NOT EXECUTED)

**Status:** Script + runbook landed locally. NO SQL run. NO push.

## Artifacts

- Script: `/home/nithu/code/ai-assistent/scripts/oneshot/run-strategy-id-backfill-11may.mjs`
- Runbook: `/home/nithu/code/ai-assistent/scripts/oneshot/README-2026-05-11-strategy-id-backfill.md`
- Commit SHA: `67f1dfca95c39bef62f846b502d6ddf02e2d8321` (local main, not pushed)
- `node --check` result: SYNTAX OK

## Source diagnostic

`/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-strategy-id-backfill.md`

## Script behaviour

Pattern copied verbatim from `run-dedupe-08may.mjs`:

- Default mode: `BEGIN; ... ROLLBACK;` — dry-run, prints what WOULD happen.
- `CONFIRM=YES`: `BEGIN; ... COMMIT;` — permanent.
- URL-redacted logs (host shape only, never user/pass).
- Pre-state + post-state snapshots inside the same tx.
- Per-strategy distribution printed before commit decision.
- JSON summary printed at the end.
- Exit 0 on success, 1 on error.

## SQL inside the tx

1. **Step 1 (the ~59-row update):** joins `signals` on `signal_id` to set
   `strategy_id` (`REGEXP_REPLACE(s.source, '^firm-strategy:', '')`),
   `execution_source = 'firm_strategy'`, and `entry_conviction_score =
   COALESCE(prev, s.confidence/100.0)`. Predicate: `strategy_id IS NULL AND
   execution_source IS NULL AND opened_at >= '2026-04-26 22:00:00Z'`.
2. **Step 2 (~29-row ATR backfill):** sets `atr_at_entry = (s.state->>'atr')::numeric`
   where `signals.state.atr` is set.

Predicates are defensive — re-runnable + skips `oanda_backfill_*` sentinels
automatically.

## Out of scope (matches diagnostic recommendation)

- 79 pre-bug legacy rows (no signal_id) — separate concern.
- `portfolio_regime_at_entry` — blackboard snapshots already TTL'd.

## Operator commands

```bash
# Dry-run (paste real DATABASE_URL):
DATABASE_URL='postgresql://...@trolley.proxy.rlwy.net:58688/railway' node scripts/oneshot/run-strategy-id-backfill-11may.mjs

# Commit (only after dry-run looks right):
DATABASE_URL='postgresql://...@trolley.proxy.rlwy.net:58688/railway' CONFIRM=YES node scripts/oneshot/run-strategy-id-backfill-11may.mjs
```

## Expected dry-run output

- `step1_rows_updated`: **59**
- `step2_rows_updated`: **~29**
- bug-window NULL deltas: strategy −59, exec −59, conv −59, atr −~29

## Not done

- Did not push (operator-gated).
- Did not run the SQL (operator runs it).
- Did not include the unrelated `apps/worker/src/firm/strategy-execution.ts`
  edit that was already in the working tree — commit kept scoped to oneshot.
