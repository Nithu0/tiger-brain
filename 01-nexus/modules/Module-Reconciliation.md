---
tags: [nexus, module, reconciliation, oanda-sync]
type: atomic
created: 2026-05-08
---

# Module-Reconciliation

OANDA two-way sync + drift monitor. Lives in `apps/worker/src/firm/oanda-sync.ts` and `apps/worker/src/firm/drift-monitor.ts`.

## What it does

**oanda-sync.ts** — bidirectional sync between OANDA (truth) and `simulated_orders` (DB). Pulls trade closes from OANDA, writes back PnL, links UUIDs to `oanda_trade_id`. Has a tx-history fallback (3-step lookup) shipped 2026-05-04 to handle issue #880.

**drift-monitor.ts** — REPORT-ONLY. Compares DB-implied balance vs OANDA balance every cycle. Surfaces deltas to morning briefing. Operator decides handling (operator-principle 1: no auto-disable).

## Key files

- `apps/worker/src/firm/oanda-sync.ts`
- `apps/worker/src/firm/drift-monitor.ts`
- `scripts/backfill-oanda-history.mjs` — historical backfill (the source of the 8 duplicate rows in `_repo-docs/ops/oanda-reality-audit-08may.md`)

## Known issues — see [[Reconciliation]] for the operator-facing view

- 8 duplicate rows from backfill (ticket IDs 438, 444, 452, 458, 464, 502, 542, 548). Both UUID + `oanda_backfill_<id>` rows present. Net effect: DB shows ~$342 less loss than OANDA reality.
- "Import unmatched OANDA trade" branch needs `bots WHERE status='running'` returning a row. Under TIER 3 = 0 rows, so unmatched OANDA trades silently dropped (~$731 of unexplained delta).
- `MANUAL_GHOST_CLOSE` / `MANUAL_NO_OANDA` rows write `pnl=0` even when OANDA balance moved.
- `STALE_TRADE_EXIT` rows have `size=0` after close — analytics that recompute PnL from `(close-entry) × size` see 0.

## Dashboard

`/readiness` page → BalanceReconciliationWidget consumes drift-monitor output.

## Related

- [[Reconciliation]] — operator-facing audit findings + fix plan
- [[Module-Postmortem]] — depends on accurate close PnL
- [[Module-Position-Management]] — interlocks via `POSITION_MANAGEMENT_ENABLED`
- [[Live-Endpoints]] — `/health` returns reconciliation status
- [[Foundation-Gate]] — open MEDIUM issues here block rule 1
