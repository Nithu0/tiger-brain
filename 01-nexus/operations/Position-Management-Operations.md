---
tags: [nexus, ops, position-management]
type: atomic
created: 2026-05-08
---

# Position-Management-Operations

Operator-facing view of the position-management master switch. Implementation: [[Module-Position-Management]].

## Master switch state

`POSITION_MANAGEMENT_ENABLED=true` on Railway Worker since 2026-04-22 evening. Verified green on ticket 548 the morning after. Foundation-gate rule 2 is GREEN.

What that flag turning ON gates:

- Break-even movement to entry after +1R
- Partial TPs (50% @ +1R, 25% @ +2R)
- Regime-aware trailing after +1.5R
- Stale-trade kill (`STALE_EXIT_TRENDING_MINUTES=150`)
- Conviction degradation early-exit

While the flag was OFF, trades just sat with their initial SL / TP and either got hit or stalled. The flip changed Nexus from "place trade and wait" into "manage trade through its lifecycle".

## OANDA two-way sync interlock

[[Module-Reconciliation]] (`oanda-sync.ts`) had to land first so that:
- Partial closes show up in DB after OANDA executes them
- Trailing-SL modifications persist back to DB
- Close PnL captured from `realizedPL` not from `(close-entry) × size`

The sync landed 2026-04-21 evening (one day ahead of plan). Position-management flag was flipped 22.4 evening after a 24-48h shadow-test was completed.

## Verification trail

- Ticket 548 was a STALE_TRADE_EXIT close. OANDA `realizedPL = $232.06`. DB `pnl = $232.06`. Matched to the cent.
- Worth noting: ticket 548 also became the first observation of the duplicate-row bug (UUID row + `oanda_backfill_548` row, both holding $232.06). See [[Reconciliation]].

## Related

- [[Module-Position-Management]] — implementation
- [[Module-Reconciliation]] — depends on it for sync correctness
- [[Foundation-Gate]] — rule 2 gates this
- [[Strategy-ORB]] — primary client; positions managed by this module
- [[OK-Kjor-Gate]] — flip required explicit approval
- [[Phase-Status-Pointer]] — full state lives there
