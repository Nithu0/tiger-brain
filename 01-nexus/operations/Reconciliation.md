---
tags: [nexus, ops, reconciliation]
type: atomic
created: 2026-05-08
---

# Reconciliation

Operator-facing view of broker (OANDA) vs DB sync. Implementation in [[Module-Reconciliation]]. Latest audit: `_repo-docs/ops/oanda-reality-audit-08may.md`.

## The 2026-05-08 audit numbers

Read-only audit by operator after spotting the mismatch:

```
OANDA balance     = $93,650.19
Starting balance  = $100,000.00 (assumed; verify via OANDA / first deposit)
Implied loss      = $-6,349.81
DB sum(pnl)       = $-5,276.54  (147 rows status='closed', market='XAUUSD')
Implied DB balance= $94,723.46
Unexplained delta = +$1,073.27   (DB shows LESS loss than OANDA reality)
```

## Top suspects (in order of magnitude / certainty)

1. **Duplicate rows from `scripts/backfill-oanda-history.mjs`** — 8 OANDA tradeIds have two DB rows each. Both rows are summed. Original UUID rows hold inaccurate tiny PnL; backfill rows hold the real OANDA realizedPL. Total double-count: **+$341.93** (DB underreports loss).
2. **OANDA-side trades that never reached DB** — the "import unmatched OANDA trade" branch in `oanda-sync.ts:242-246` requires `bots WHERE status='running'` returning a row. Under TIER 3 that returns 0 rows. Likely source of the remaining ~$731 unexplained delta.
3. **`MANUAL_GHOST_CLOSE` and `MANUAL_NO_OANDA` rows write `pnl=0`** even when OANDA balance moved. 3 rows; one with `size=446 units`.
4. **`STALE_TRADE_EXIT` rows have `size=0` after close** — analytics that recompute PnL from `(close - entry) × size` see 0 for these 14 trades ($+628.34 of PnL invisible to size-based recompute, though the canonical PnL is captured correctly via `realized_partial_pnl + finalExitPnl`).

## Verification (operator only — no token in this vault)

```
curl -s -H "Authorization: Bearer $OANDA_API_TOKEN" \
  "$OANDA_API_URL/v3/accounts/$OANDA_ACCOUNT_ID/trades?state=CLOSED&count=500&instrument=XAU_USD" \
  | jq '.trades | length, (map(.realizedPL|tonumber) | add)'
```

Compare against DB `sum(pnl)`.

## Status

Read-only audit. **No code changes. No data writes.** Cleanups await operator-approved SQL via the `nexus-pg-rw` MCP.

## Related

- [[Module-Reconciliation]] — implementation
- [[Module-Postmortem]] — depends on accurate close PnL; affected by these issues
- [[Foundation-Gate]] — open MEDIUM issues feed into rule 1 evaluation
- [[Live-Endpoints]] — `/health` returns reconciliation status
- [[OK-Kjor-Gate]] — cleanup SQL needs explicit approval
- [[Phase-Status-Pointer]] — full open-issues table lives there
