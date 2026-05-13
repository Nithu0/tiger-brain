---
date: 2026-05-13
type: rca
project: nexus
status: open
---

# market.raw null-price RCA (deferred from 07.5)

## TL;DR

**Already fixed — one day after the deferred note.** Root cause was patched 2026-05-08 in commit `91b6f8e` (one day after the API-side workaround `7d497c3` on 05-07). Zero null-price rows in blackboard table going back to earliest data (2026-04-29, 6 831 price-feed rows). No remaining action needed on the writer side. One follow-up: API workaround `7d497c3` is now defensive-only and could be cleaned up.

## Quantification

Query against `blackboard` (topic=`xauusd.market.raw`, only rows that carry a `price` key — i.e. the price-feed publishes, not the technical-indicator publishes):

| Day | price-feed rows | null_price |
|---|---:|---:|
| 2026-05-13 | 377 | 0 |
| 2026-05-12 | 709 | 0 |
| 2026-05-11 | 708 | 0 |
| 2026-05-10 | 27 | 0 |
| 2026-05-09 | 25 | 0 |
| 2026-05-08 | 695 | 0 |
| 2026-05-07 | 707 | 0 |
| 2026-05-06 | 721 | 0 |
| ... back to 2026-04-29 | | 0 |

Total: **0 / 6 831** null-price rows ever in current retention window. **Rate: 0.00%.**

Note: low row counts on 05-09/05-10 are weekend (market closed); 05-13 partial day. Schema correction vs. brief: column is `timestamp` (not `created_at`) and JSON is `state` (not `payload`).

## Root cause (historical)

Pre-fix path in `apps/worker/src/firm/fact-agents.ts:runPriceFeed()`:

```ts
const snapshot = await fetchMarketSnapshot();
if (!snapshot.gold) return;     // only guarded the parent
await board.publish({ ..., state: { price: snapshot.gold.price, ... } });
```

`fetchMarketSnapshot()` could return a truthy `snapshot.gold` object whose `.price` was `null`/`NaN`/`Infinity` under three conditions:
1. **Cold-start / partial fetch** — twelvedata responded but XAUUSD field was missing.
2. **Upstream provider hiccup** — twelvedata returned the wrapper but a degraded inner row.
3. **(Theoretical, not observed)** test/dry-run path injecting a stub object.

Result: blackboard row written with `state.price = null`. Downstream consumers (unrealized-PnL query in `apps/api/src/routes/positions.ts`) took latest-by-timestamp and broke when the latest happened to be the bad row.

## Fix (already shipped)

Commit `91b6f8e` (Fri May 8 09:50:49 +0200) added a finite-number guard in `runPriceFeed`:

```ts
const price = snapshot.gold.price;
if (typeof price !== "number" || !Number.isFinite(price)) {
  logWarn("raw-data", "skip-publish", "price not finite: " + String(price));
  return;
}
```

Skip-and-log rather than persist. Next cycle retries from a clean slate. Matches operator's "small janitorial fixes can be automatic" principle (no behavior change to trading loop, no auto-disable).

## Follow-up proposal (minor)

The API-side workaround `7d497c3` (added `state->>'price' IS NOT NULL` to both PnL query sites in `apps/api/src/routes/positions.ts`) is now defensive-only — the writer cannot emit null rows. Two options:

**A. Keep as defense-in-depth** (recommended). The filter costs nothing, and protects against future regressions or out-of-band writes (replay, manual SQL, n8n workflow). No action.

**B. Remove the filter** to keep the API query minimal. Not worth the churn given option A is free.

Recommendation: **leave both layers in place, mark this RCA closed.**

## Verification suggestion

Add a cheap morning-briefing check: count null-price rows in `xauusd.market.raw` over last 24h, alert if > 0. Cost: one extra COUNT query in the existing briefing path. Catches any regression instantly. (Operator decides whether to wire — this is REPORT-only, not auto-disable.)

## Sources

- `apps/worker/src/firm/fact-agents.ts:25-66` (current guarded `runPriceFeed`)
- commit `91b6f8e` (writer-side fix, 2026-05-08)
- commit `7d497c3` (API-side workaround, 2026-05-07)
- blackboard query: 0 null-price rows across 6 831 samples since 2026-04-29
