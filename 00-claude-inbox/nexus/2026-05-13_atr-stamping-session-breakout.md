---
date: 2026-05-13
type: bug-investigation
project: nexus
status: open
---

# session-breakout atr_at_entry NULL — diagnosis

## TL;DR

Session-breakout did not compute or attach ATR until commit `deb7075` (13.5 09:35 CET / 07:35 UTC). The audited trade `a5dc8687` (12.5 17:35Z) ran on pre-fix code so the producer never put `atr` in `proposal.state`; the consumer (`strategy-execution.ts:745`) read `proposal.state.atr ?? proposal.state.atr14`, both undefined, and stamped NULL. The fix is already on `origin/main` — needs deploy + the next live SB trade to confirm.

## Architecture

Two layers must cooperate:

- **Producer** (`session-break-manager.ts`) — must fetch ATR + put it on `signal.atr` and `proposal.state.atr`.
- **Consumer** (`strategy-execution.ts:745-750`) — reads `proposal.state.atr ?? proposal.state.atr14` and writes `simulated_orders.atr_at_entry`.

Other strategies for reference:

| strategy | producer field | consumer read |
|---|---|---|
| vol-expansion | `signal.atr14` (REQUIRED, returns noTrade if null) | `proposal.state.atr14` |
| scalp-overlap | `signal.atr` | `proposal.state.atr` |
| session-breakout | `signal.atr` (added in `deb7075`) | `proposal.state.atr` |
| ORB | none | NULL by design |

## Timeline

- `e15b67a` (26.4 23:52) — TIER 3 path created without strategy_id / execution_source / atr_at_entry stamping; affected vol-exp + SB + scalp + ORB.
- `0ad348f` (11.5 12:36) — `strategy-execution.ts` started reading `state.atr ?? state.atr14` and writing them. Vol-exp's existing `signal.atr14` immediately worked. SB had no `atr` field, so still NULL.
- `deb7075` (13.5 09:35 / 07:35 UTC) — SB manager added `fetchATR(...)` + attached to `signal.atr` + state. Cited the same audit this task came from.
- Trade `a5dc8687` (12.5 17:35Z) pre-dates `deb7075` by ~14 h — explains NULL.

## Counts (last 30 d)

```
strategy_id              total  null_atr
xau-session-breakout       14        14
xau-volatility-expansion   41        37
xau-scalp-overlap           7         4
xau-orb                     5         5
(NULL strategy_id)         86        80
oanda_backfill              3         3
```

Vol-exp: 37/41 NULL because most pre-date `0ad348f` (consumer fix 11.5). Since 11.5 14:00 UTC, 4/6 vol-exp trades got ATR stamped (the two NULLs in the gap are 11.5 04:16 + 06:47 UTC — both pre-deploy of `0ad348f`).

SB: 14/14 NULL because the producer-side fix is from today (`deb7075`) and no SB trade has fired since then.

## Code path verified

`apps/worker/src/firm/session-breakout/session-break-manager.ts:374`

```ts
const atr = await fetchATR("XAUUSD", "1h", SB_CONFIG.atrPeriod).catch(() => null);
...
const signal: SBSignalOutput = {
  ...,
  atr: atr != null && atr > 0 ? atr : null,
};
await board.publish({
  ...,
  state: { ...signal, strategy: "xau-session-breakout" },
});
```

`apps/worker/src/firm/strategy-execution.ts:745-750`:

```ts
const proposalAtrRaw = (proposal.state.atr ?? proposal.state.atr14) as number | undefined;
const atrAtEntry = typeof proposalAtrRaw === "number" && Number.isFinite(proposalAtrRaw)
  ? proposalAtrRaw : null;
```

Pre-`deb7075` SB proposals had neither `state.atr` nor `state.atr14` → consumer wrote NULL. After `deb7075`, SB publishes `state.atr` → consumer stamps it.

## Deploy status

- `deb7075` is on `origin/main` (verified via `git log origin/main`).
- Local `f0a25c0` is ahead of origin/main with an unrelated zellij feature — does not affect ATR.
- No SB trade has opened since 07:35 UTC (London-watch starts 08:00 London = 07:00 UTC; NY-watch from 13:30 UTC). Next SB trade after Railway picks up `deb7075` will be the verification.

## Is ATR computed but not attached, or not computed?

Pre-fix: **not computed at all** in the SB producer. The SB SL/TP are range-derived, so the strategy never needed ATR for its own math — and nobody had wired the observability fetch until `deb7075`.

## Minimal fix

Already landed in `deb7075`. No further code change needed. Verification:

1. Confirm Railway worker has redeployed (check `/health` build SHA or worker logs for new `deb7075`-only log line: `H1 ATR(14) unavailable — proceeding with entry, atr_at_entry will be NULL` when Twelve Data is down, or new SB-trade row with non-null `atr_at_entry`).
2. After next SB trade fires, re-run the audit query — that row should have `atr_at_entry` populated.

If next SB trade is STILL NULL after `deb7075` deploy → investigate `fetchATR("XAUUSD", "1h", 14)` reliability (Twelve Data outage or rate-limit). The code falls back to NULL silently (`.catch(() => null)`) so the strategy still trades — operator-prinsipp 1 (report, don't fabricate).

## Adjacent (out-of-scope, flagged for awareness)

- 80/86 NULL-strategy_id rows in 30 d are legacy execution paths (managers.ts / pre-firm-strategy). Not part of this audit, but they share the NULL-atr_at_entry pattern.
- Vol-exp's 4 NULLs *after* `0ad348f` deploy (11.5 14:00 UTC) — only 2 actual NULLs in the post-fix window (11.5 04:16 + 06:47), both pre-deploy. Behaviour is correct.
