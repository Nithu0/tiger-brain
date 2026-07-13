# ADX fallback "landing" — deep-trace + verification endpoint

**Branch:** `fix/adx-fallback-land` (pushed, no PR — operator opens it)
**Commit:** `03b12cf`
**Date:** 2026-06-10

## TL;DR

The `INDICATOR_OANDA_FALLBACK_ENABLED` fallback (commit `2085fd7`) **is effective
with the flag on**. The full deep-trace shows ADX populates, regime reaches
TRENDING-with-direction, and the regime-direction classifier runs. **No bug keeps
ADX/regimeDirection null with the flag on.** The only real gap was *observability* —
no way to verify over 443 which source produced ADX, and no endpoint to read it.
Fixed both: source-tagging + `GET /operator/regime`.

## Deep-trace of the full path (verdict: effective)

The chain from raw candle to regime gate:

1. `runAllFactAgents` → `runTechnicalFacts` calls `fetchADX("XAUUSD","15min")`
   (`apps/worker/src/services/market-data.service.ts:389`).
2. With the flag on + `OANDA_API_TOKEN` set, `fetchADX` falls through Twelve Data's
   404 and calls `oandaOhlcForIndicator("XAUUSD","15min", 14*5+1=71)` →
   `fetchOandaCandles`. The OANDA granularity map (`oanda.service.ts:685`) maps
   `"15min"→"M15"`, `"1h"→"H1"`, `"4h"→"H4"` — **no interval mismatch**.
3. `computeADX(bars, 14)` (`indicators.ts:85`) needs `2*period+1 = 29` bars; the
   fetch yields ~70 complete bars → returns a real number. **Bar count is sufficient.**
4. `runTechnicalFacts` publishes it into `xauusd.market.raw` as `indicators.adx`.
5. `runTechnicalAnalysis` (`analysis-agents.ts:20`) reads that fact and republishes
   `indicators: ind` (adx preserved) to `xauusd.analysis.technical`.
6. `classifyRegime` (`portfolio-brain.ts:145`) reads `indicators.adx`; at `adx > 30`
   sets `regime = "TRENDING"` (`:175`).
7. TRENDING → `classifyTrendDirection()` → `fetchCandles("XAUUSD","4h",32)` →
   OANDA H4 (Twelve-Data-independent) → `classifyRegimeDirection` →
   `regimeDirection` UP/DOWN. 4h close-move needs >4 bars; 31 available. **Works.**
8. Published to `xauusd.portfolio.context` with `regimeDirection` +
   `regimeDirectionReason` (`portfolio-brain.ts:449`).

So: ADX → TRENDING → regimeDirection all populate with the flag on. The downstream
gate `REGIME_DIRECTION_GATE_ENABLED` (default OFF) then has a real direction to act on.

### Why it *looked* like it might be broken

- ADX null was the historical state (Twelve Data 404 + fallback OFF) → regime never
  TRENDING → gates were permanent no-ops. That's exactly what the flag fixes.
- We can't read Railway logs over 443, so "is it actually non-null now?" was
  unverifiable. That's the gap this branch closes — not a code bug.

## What I changed

### 1. Source tagging (observability, behaviour-neutral)
`apps/worker/src/services/market-data.service.ts`
- New per-`(indicator,interval)` recorder: `recordIndicatorSource` +
  `getLastIndicatorSource(indicator, interval)` returning
  `"twelvedata" | "oanda_fallback" | null`.
- `fetchADX` + `fetchATR` record the source on every resolution (incl. null).
- **Recording never changes the returned value** → flag-OFF behaviour byte-identical.

### 2. Publish source to the blackboard
`apps/worker/src/firm/fact-agents.ts` — `runTechnicalFacts` reads
`getLastIndicatorSource("adx"/"atr","15min")` after the fetches and adds
`adxSource`/`atrSource` to the published `indicators` state, so the API process
(separate deployable, can't see the worker's in-memory map) can read it.

### 3. Verification endpoint
`apps/api/src/routes/operator.ts` — new `GET /operator/regime` (inside
`operatorRoutes`, inherits global operator auth). Read-only, try/catch → neutral
payload, never 500.

**Response shape:**
```jsonc
{
  "generatedAtIso": "2026-06-10T...Z",
  "regime": "TRENDING" | "RANGING" | ... | null,
  "regimeDirection": "UP" | "DOWN" | null,
  "regimeDirectionReason": "ok_up" | "not_trending" | ... | null,
  "volatility": "low"|"normal"|"high"|"extreme"|null,
  "tradeability": "excellent"|"good"|"fair"|"poor"|"no_edge"|null,
  "adx": 34.2 | null,
  "atr": 5.1 | null,
  "adxSource": "twelvedata" | "oanda_fallback" | null,
  "atrSource": "twelvedata" | "oanda_fallback" | null,
  "fallbackActive": true,            // adx != null AND adxSource == "oanda_fallback"
  "portfolioContextAgeSec": 12,      // staleness of portfolio.context msg
  "indicatorFactAgeSec": 12,         // staleness of the indicator FACT
  "note": null                       // one-line cause when the chain is broken
}
```

- `regime/regimeDirection/...` ← latest `xauusd.portfolio.context` (portfolio-brain)
- `adx/atr/adxSource/atrSource` ← latest `xauusd.market.raw` row with `indicators`
- `fallbackActive: true` is the **positive signal the flip landed**.
- `note` examples: "no portfolio.context message — worker may be down or pre-deploy",
  "ADX null and no source recorded — fallback OFF or both providers empty".

## How to verify over 443

```
curl -s -H "Authorization: Bearer $API_KEY" \
  https://api-production-b660.up.railway.app/operator/regime | jq
```
Expect `adxSource: "oanda_fallback"` and `adx` non-null → fallback landed.
If `regime: "TRENDING"` and `regimeDirection` is UP/DOWN → the full chain works
and the regime-direction gate (when enabled) has a real signal.

> Note: `adxSource` only appears AFTER the worker redeploys with this commit
> (the field is added by `runTechnicalFacts`). Pre-deploy, the endpoint still
> returns regime/adx but `adxSource` will be null (older FACT shape).

## Tests

- Worker: **1201/1201** pass (5 new source-tracking tests in `market-data.test.ts`).
- API: **49/49** pass (6 new `/operator/regime` tests in `operator-regime.test.ts`,
  registered in `apps/api/package.json` test script).
- Both `tsc --noEmit` clean.

New API tests cover: 401 unauth, DB-throw fail-safe (neutral, never 500),
fallback-active (oanda_fallback → fallbackActive true), twelvedata source,
ADX-null diagnostic note, worker-down note.

## Files

- `apps/worker/src/services/market-data.service.ts` — source recorder + fetchADX/fetchATR wiring
- `apps/worker/src/firm/fact-agents.ts` — publish adxSource/atrSource
- `apps/api/src/routes/operator.ts` — GET /operator/regime
- `apps/api/src/routes/operator-regime.test.ts` — new test file
- `apps/api/package.json` — register the test
- `apps/worker/src/services/market-data.test.ts` — source-tracking tests

## Gate/strategy note

No proposal needed: pure observability + a bug-class fix that restores intended
behaviour. No trade-decision logic changed. The fallback flag itself
(`INDICATOR_OANDA_FALLBACK_ENABLED`) is already operator-set on the Worker and is
Karri's domain — untouched here.
