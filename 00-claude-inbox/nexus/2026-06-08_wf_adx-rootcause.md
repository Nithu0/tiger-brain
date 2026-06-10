# WF lane: adx-rootcause — deep-trace `strategy_states.market.adx/atr` null (READ-ONLY, for ai-1)

Date: 2026-06-08
Author: wf worker (read-only diagnosis; no code edited)
For: ai-1 (owns the ADX/regime P0 fix)
Constraint honored: did NOT edit any ADX/regime/indicator code.

## TL;DR

The OANDA indicator fallback **is working** — ADX/ATR are computed and actively
drive trade decisions right now. The null in `strategy_states.market.adx/atr`
(and in every per-strategy `indicators.adx/atr14`) is **NOT a data/fallback
failure — it is a publish-shape / serialization bug** at two distinct layers:

1. **Top-level `market.adx`/`market.atr`** in `/firm/strategy-states` reads
   fields that are **never published at the top level of `xauusd.market.raw`**.
   They live nested under `state.indicators.*`. So they are structurally always
   null regardless of the fallback.
2. **Per-strategy `indicators.adx`/`atr14`** are published as
   `result.signal?.adx ?? null` — i.e. **only populated on the success path**.
   On every *reject* path `signal` is null, so adx/atr14 publish as null even
   though the strategy computed real values (and used them to reject).

Live proof the fallback works (fresh pull 2026-06-08, LONDON_ACTIVE):
- `mean-reversion` reject = `adx_too_high: 43.8 > 25` → real ADX=43.8 computed.
- `pullback-continuation` reject = `pullback_too_deep: 16.49 ATR > 2` → real ATR.
- yet both rows publish `indicators.adx=null`, `indicators.atr14=null`.
- `market.price` is non-null but `market.adx/atr` null (see layer-1 below).

So ai-1 should NOT chase fetchADX/fetchATR/insufficient-bars/deployed-code-drift.
Those are fine. This is purely the publish-side surfacing of already-computed values.

---

## Trace 1 — top-level `market.adx/atr` (the literal `strategy_states.market` object)

**Reader:** `apps/api/src/routes/firm-memory.ts:445-449`
```ts
const market = {
  price: typeof marketState?.price === "number" ? marketState.price : null,
  atr:   typeof marketState?.atr   === "number" ? marketState.atr   : null,  // L447
  adx:   typeof marketState?.adx   === "number" ? marketState.adx   : null,  // L448
};
```
`marketState` = latest single row of `xauusd.market.raw` (L437-439, `ORDER BY timestamp DESC LIMIT 1`).

**Writers to `xauusd.market.raw` (two, disjoint shapes):**
- `runPriceFeed` — `apps/worker/src/firm/fact-agents.ts:42-55`
  publishes `state: { price, eurusd, spy, ... }` → **top-level `price`, NO adx/atr**.
- `runTechnicalFacts` — `apps/worker/src/firm/fact-agents.ts:85-96`
  publishes `state: { indicators: { adx, ema20, ema50, atr, ... } }`
  → **adx/atr nested under `indicators`, NO top-level adx/atr, NO price**.

Both publish to the SAME topic every cycle. `LIMIT 1` grabs whichever wrote last.
The reader looks for `marketState.adx` / `marketState.atr` at the TOP LEVEL, which
**neither writer ever produces.** Hence top-level `market.adx/atr` is always null,
and `market.price` is non-null only because the price-feed row happens to be the
latest at query time.

(Contrast: the richer `/firm/market-state` endpoint at firm-memory.ts:180-253 reads
the *technical interpretation* row and correctly digs into `state->'indicators'->>'adx'`
— that path is fine; it's a different endpoint.)

## Trace 2 — per-strategy `indicators.adx/atr14` (the real P0 — what regime/gates see surfaced)

**Reader:** `apps/api/src/routes/firm-memory.ts:486` — `indicators: state ?? null`
i.e. the per-strategy `indicators` object IS each strategy's published state row verbatim.

**Indicator source is fine:** strategies read H1 ADX/ATR from blackboard topic
`xauusd.market.h1-indicators` via `readH1Indicators()` (`h1-indicators.ts:40-55`),
published once/cycle by `runTechnicalFactsH1` (`fact-agents.ts:125-151`) which calls
`fetchADX("XAUUSD","1h")` / `fetchATR("XAUUSD","1h",14)` → OANDA fallback. All three
fact agents ARE wired: `runAllFactAgents` (`fact-agents.ts:344-348`) invokes
runPriceFeed + runTechnicalFacts + runTechnicalFactsH1; orchestrator calls
`runAllFactAgents` (`orchestrator.ts:16`). No wiring gap.

**The drop happens in each strategy's `publishState`** — adx/atr14 are read from
`result.signal?.*`, which is null on every reject. The "observability extras"
plumbing that exists for rsi/impulse/pullback was never extended to adx/atr14:

| Strategy | Extras interface (missing adx/atr14) | publishState drop site |
|---|---|---|
| mean-reversion | `MRStateExtras` mean-reversion-manager.ts:141-144 (rsi, impulseAtr only) | `:420-421` `adx: result.signal?.adx ?? null`, `atr14: result.signal?.atr14 ?? null` |
| trend-following | `TFStateExtras` trend-following-manager.ts:191-194 (pullbackDepth, regimeAllowed only) | `:521-522` |
| pullback-continuation | `PCStateExtras` pullback-continuation-manager.ts:241-246 (rsi, impulseAtr, pullbackDepthAtr, regimeAllowed) | `:542-543` |
| breakout-continuation | **no extras param at all** — `publishState(board, result)` breakout-continuation-manager.ts:593 | `:608-610` `atrCurrent/atrRatio/adx: result.signal?.* ?? null` |

For mean-reversion, `adx` is computed at `:190-191` and drives the reject at `:205-207`
(`adx_too_high`), but `extras` (created empty at `:155`) is never populated with it, and
publishState reads `result.signal?.adx` (null on reject). Same structure in TF
(`adx_too_low` at `:252`), PC, BC (`no_valid_range` at `:376`, after adx/atr14 resolved at `:354-357`).

---

## SURGICAL FIX SPEC (for ai-1) — pure observability, behaviour-neutral

This does NOT change any trade decision — it only surfaces values already computed.
Two independent fixes. Recommend a default-OFF flag is NOT needed (pure read-surface),
but if ai-1 wants belt-and-suspenders, gate the layer-1 nested read behind a flag.

### Fix A — top-level market.adx/atr in strategy-states endpoint
File: `apps/api/src/routes/firm-memory.ts:445-449`
Read from the nested `indicators` object that `runTechnicalFacts` actually writes,
preferring the technical row. Replace L445-449 with a lookup that digs into
`state.indicators` AND, because two writers share the topic, query the technical row
explicitly rather than `LIMIT 1` on the shared topic. Minimal change:
```ts
const ind = (marketState?.indicators as Record<string, unknown> | undefined);
const market = {
  price: typeof marketState?.price === "number" ? marketState.price : null,
  atr:   typeof ind?.atr === "number" ? ind.atr : null,
  adx:   typeof ind?.adx === "number" ? ind.adx : null,
};
```
CAVEAT for ai-1: because `LIMIT 1` on `xauusd.market.raw` alternates between the
price-feed row (has price, no indicators) and the technical row (has indicators, no
price), the single-row read will still flap. The robust fix is two queries — one
`...market.raw AND state ? 'price'` for price, one `...market.raw AND state ? 'indicators'`
(or read the dedicated technical/h1-indicators topic) for adx/atr. Mirror the existing
`/firm/market-state` query at firm-memory.ts:180 which already reads the technical row
correctly. RECOMMEND: source top-level market.adx/atr from `xauusd.market.h1-indicators`
(canonical, single-writer, what strategies actually consume) for consistency with the
per-strategy values.

### Fix B — per-strategy indicators.adx/atr14 on reject paths (the P0)
For each of the 4 strategies, (1) add `adx`/`atr14` to the *StateExtras interface,
(2) set `extras.adx = adx; extras.atr14 = atr14;` immediately after they are resolved
from `readH1Indicators`, (3) fall back to extras in publishState.

mean-reversion (`mean-reversion-manager.ts`):
- L141-144 add to `MRStateExtras`: `adx?: number | null; atr14?: number | null;`
- after L191 (`adx = h1.adx;`) add: `extras.adx = adx; extras.atr14 = atr14;`
  (place AFTER the null-guard at L198 if you only want non-null surfaced, or before
  to surface even the null — either is behaviour-neutral)
- L420-421 → `adx: result.signal?.adx ?? extras.adx ?? null,`
  `atr14: result.signal?.atr14 ?? extras.atr14 ?? null,`

trend-following (`trend-following-manager.ts`):
- L191-194 add `adx`/`atr14` to `TFStateExtras`
- after adx/atr14 are resolved (~L240 region, the `indicator_unavailable` guard is L240)
  set `extras.adx`/`extras.atr14`
- L521-522 → `?? extras.adx ?? null` / `?? extras.atr14 ?? null`

pullback-continuation (`pullback-continuation-manager.ts`):
- L241-246 add `adx`/`atr14` to `PCStateExtras`
- set extras after H1 read (~L290 region)
- L542-543 → `?? extras.adx ?? null` / `?? extras.atr14 ?? null`

breakout-continuation (`breakout-continuation-manager.ts`):
- Needs an extras param introduced. Add `interface BCStateExtras { adx?: number|null;
  atrCurrent?: number|null; atrRatio?: number|null; }`; thread it through `softReject`
  + `publishState(board, result, extras)` (currently `publishState(board, result)` at L593).
- set `extras.adx = adx; extras.atrCurrent = atr14;` after L357 (post H1 read).
- L608-610 → `?? extras.atrCurrent ?? null` / `?? extras.adx ?? null` (atrRatio is
  only known on success — leave as-is or compute earlier).

### Verification ai-1 should run
- `cd apps/worker && npx tsc --noEmit` then `npm test` (existing h1-indicators.test.ts +
  per-strategy manager tests guard the shapes — extend mean-reversion test to assert
  `adx` is surfaced on the `adx_too_high` reject path).
- After deploy: `bash pull-nexus-data.sh` → `strategy_states.json` should show
  `mean-reversion.indicators.adx ≈ 43.x` matching its reject reason, and top-level
  `market.adx/atr` non-null during an active session.

## What is NOT broken (so ai-1 doesn't waste cycles)
- fetchADX/fetchATR OANDA fallback (`market-data.service.ts:346-412`) — working;
  `mean-reversion adx_too_high: 43.8` proves it returns real values.
- `isIndicatorOandaFallbackEnabled()` gate (`:38-43`) — INDICATOR_OANDA_FALLBACK_ENABLED=true
  confirmed effective.
- insufficient-bars guards (`indicators.ts:46-152`, `computeATR` needs period+1,
  `computeADX` needs 2*period+1) — fetch margins are period*4+1 / period*5+1, ample.
- Fact-agent wiring (`runAllFactAgents` → orchestrator) — intact.
- `readH1Indicators` / `H1_INDICATORS_TOPIC` consumer — intact.

The only defect is the publish-shape mismatch (Fix A) + reject-path signal-gated
surfacing (Fix B). Both pure-observability; no regime/gate/trade-decision change.
