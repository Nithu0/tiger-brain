# Module spec — Market Structure (Auction Market Theory / Market Profile)

**Source book:** *Mind Over Markets* (Dalton) — Market Profile / Auction Market Theory
**Nexus module name:** `market-structure` (publishes to `xauusd.analysis.structure`)
**Author:** Claude (Market Structure module owner in Karri's 5-book mapping)
**Date:** 2026-06-13
**Status:** ANALYSIS + SPEC ONLY — no code written. Strategy/risk-impacting parts gate through Karri.

Target concepts the AI should learn: Value Area High (VAH), Value Area Low (VAL), Point of Control (POC), Initial Balance (IB), Trend Day vs Balance Day, Auction Market Theory.
Output the AI should produce: where the market is in balance, where large players are likely active, breakout/reversal levels.

---

## 1. What Nexus already has (and the overlap)

**Headline: there is NO market-profile / volume-at-price / value-area / POC / TPO logic anywhere in the worker.** This is greenfield computation. Grep across `apps/worker/src` for `value.?area|point.?of.?control|POC|market.?profile|volume.?at.?price|TPO|initial.?balance` returns nothing functional (one incidental text hit in `mean-reversion-manager.ts`). Every range concept in the codebase is **pure OHLC extremes** (`max(high)`/`min(low)`), never a volume distribution. Volume is on the candle type but is currently **stored and never consumed for analysis**.

What exists that is *adjacent* (and what it does NOT do):

| Existing thing | File | What it computes | Overlap vs Market Profile |
|---|---|---|---|
| Session-breakout prior-session range | `apps/worker/src/firm/session-breakout/session-break-manager.ts` → `computeSourceRange()` | `max(high)`/`min(low)` of prior session (Asia→London→NY chain), 1h or 15min candles | **Range edges only.** No POC, no value area, no volume weighting. A profile would say *where inside that range price spent time* — this says only the outer box. Complementary, not duplicative. |
| ORB opening range | `apps/worker/src/firm/orb/range-detector.ts` | Opening-window high/low (London 08:00–08:30, NY 14:30–15:00), 5min candles → `OpeningRange{high,low,width,state}` | **This IS conceptually the Initial Balance** (first-hour range), but only as a box, and only a 30-min window, not Dalton's 60-min IB. Reusable as IB seed; needs widening to 60 min + volume context. |
| Regime classifier | `apps/worker/src/firm/portfolio-brain.ts` → `classifyRegime()` | Reads ADX+ATR from `xauusd.analysis.technical`, emits `TRENDING/RANGING/BREAKOUT/...` | **ADX-derived**, not structure-derived. `RANGING` is the nearest proxy to a "balance day" but it's a lagging momentum read, not "price is rotating around a developing POC." Market Profile gives a *structural, leading* version of the same call (trend-day vs balance-day) and would feed/cross-check this. |
| Trend direction sub-classifier | `apps/worker/src/firm/regime-direction.ts` → `classifyRegimeDirection()` | H4 close-move or EMA20-slope → UP/DOWN/null | Pure price, no volume, no structure. Orthogonal. |
| Conviction "structure" engine | `apps/worker/src/firm/conviction/adapters.ts` → `buildStandardEngineSet()` | Currently **synthesizes** a structure signal from EMA20/50 + portfolio bias because no real structure source exists | **This is the hole this module fills.** The adapter already reads topic `xauusd.analysis.structure` first and only falls back to the EMA synthesis when it's absent. Publish to that topic and the conviction layer consumes it with zero wiring changes. |

**Verdict on overlap:** genuinely new computation, but it slots cleanly *alongside* existing range logic (adds the "where did price trade, weighted by activity" layer the box-ranges lack) and *into* the existing structure-engine slot that is currently faked from EMAs.

---

## 2. Data-feasibility verdict (XAUUSD / OANDA) — be honest

**Market Profile, done properly, needs a per-price activity distribution.** Classic Market Profile uses TPO (time-price-opportunity) counts; modern volume-profile uses real traded volume at each price. We have neither cleanly:

- **OANDA spot XAUUSD has no real volume.** OANDA is an OTC dealer; the `volume` field on candles is **tick-count** (number of price updates in the bar), not contracts/lots traded. It is a *proxy for activity*, correlated with real volume but not it.
- **No tick data / no native volume-at-price feed.** We get OHLCV candles only.
- **M1 is fetchable but not stored.** `fetchCandles("XAUUSD","1min",N)` works against OANDA (granularity `M1` is supported). But `persistCandles()` in `raw-data-persistence.ts` **hardcodes `tf="15min"`** and keeps only ~10 closed bars per cycle — so there is **no M1 history**. M1 is fetch-on-demand only today.

**Can we approximate VAH/VAL/POC from candle data? Yes — with two honest caveats:**

1. **TPO-style approximation (recommended, robust):** Bucket price into bins (e.g. $0.25 or $0.50 for gold). For each M1 (or M5) candle, distribute its [low, high] range across the bins it spans and increment each bin's count by **1 (pure TPO)** or by **candle volume / bins-spanned (tick-volume-weighted)**. The histogram's mode = **POC**; expand outward from POC until 70% of total is captured = **value area**, its edges = **VAH/VAL**. This is the standard candle-based profile approximation used industry-wide when tick data is absent. It is *good enough* to locate balance and the high-activity price — which is exactly the output spec asks for.

2. **Tick-volume weighting is a proxy, not truth.** Weighting bins by OANDA tick-volume biases the POC toward where *price updated most*, which on a dealer feed tracks real activity reasonably but can be distorted around news spikes (many ticks, little real size). **Mitigation:** compute both an unweighted TPO profile and a tick-volume-weighted profile; if their POCs diverge by more than ~$2, lower confidence and flag `poc_disagreement`. Treat the volume-weighted POC as a hint, the TPO POC as the spine.

**Bottom line:** Full institutional volume profile = NOT feasible (no real volume). A **TPO + tick-volume-hybrid session profile = feasible and faithful enough** to produce "where is balance, where are large players likely active, where are breakout/reversal levels." We must be honest in the published `thesis`/`source_quality` that this is a tick-derived approximation, not exchange volume.

---

## 3. Implementation plan — the `market-structure` module

### Inputs
- `fetchCandles("XAUUSD", "5min", N)` for the developing/current RTH session (Phase 1). M5 is already persisted-adjacent and cheap; gives ~78 bars over a 6.5h NY session.
- Phase 2: `fetchCandles("XAUUSD","1min",N)` for finer POC resolution + a small M1 backfill job (since `persistCandles` only does 15min today, the module fetches M1 on demand for the current session rather than depending on stored history).
- Session boundaries reuse the existing session-window config (ORB/session-breakout `config.ts` already define London/NY/Asia bounds in London-decimal hours).

### Computation
1. **Build the session profile.** Choose tick size `PROFILE_TICK_SIZE` (default $0.25). For each candle in the session, distribute across price bins between its low and high; increment by 1 (TPO) and separately by `volume/binsSpanned` (volume-weighted). Maintain two histograms.
2. **POC** = price bin with max count (compute for both histograms; report TPO-POC as primary, flag divergence).
3. **Value area (VAH/VAL)** = expand from POC outward (the standard "take the larger of the two adjacent bins" walk) until cumulative count ≥ `PROFILE_VALUE_AREA_PCT` (default 0.70) of total. VAH = top edge, VAL = bottom edge.
4. **Initial Balance (IB)** = high/low of the first 60 minutes of the session (reuse/extend ORB's range-detector; ORB's 30-min window is a seed but Dalton's IB is 60 min).
5. **Trend-day vs balance-day classification** (the Dalton output):
   - **Balance day:** price rotating, range development stays roughly within ~2× IB, POC near session mid, value area overlaps prior session's value area substantially.
   - **Trend day:** range extends well beyond IB (range > ~2× IB), one-directional, POC drifts in the trend direction, little overlap with prior value area, late-session value migration.
   - Emit `dayType ∈ TREND_UP | TREND_DOWN | BALANCE | NEUTRAL_DEVELOPING` with a confidence.
6. **Large-player / breakout-reversal levels** (the actionable geometry):
   - VAH / VAL = balance edges → **reversal-fade levels** on a balance day, **breakout-trigger levels** on a trend day.
   - POC = magnet / mean-reversion target where large players are likely active.
   - Prior-session VAH/VAL/POC carried forward as reference (overlap test for trend-vs-balance).
   - "Open relative to prior value" (open above/below/inside prior VA) — Dalton's primary daily-bias tell.

### Outputs — blackboard fact (mirrors `analysis-agents.ts` exactly)
Publish via `board.publish()` matching the existing analysis-agent shape:

```
topic:       "xauusd.analysis.structure"     // dedicated topic the conviction adapter already reads first
messageType: "INTERPRETATION"
department:  "prism"
agent:       "market-structure"
symbol:      "XAUUSD"
state: {
  direction,                 // -1..+1 derived from dayType + open-vs-value (so the conviction adapter can read state.direction)
  dayType,                   // TREND_UP | TREND_DOWN | BALANCE | NEUTRAL_DEVELOPING
  poc, vah, val,             // current session
  pocVolumeWeighted,         // hint; flag poc_disagreement if |poc - pocVolumeWeighted| > 2
  ib: { high, low, width },
  priorSession: { poc, vah, val },
  openRelativeToPriorValue,  // ABOVE | BELOW | INSIDE
  valueAreaOverlapPct,       // vs prior session — low overlap supports trend-day
  inBalance: boolean,        // "where the market is in balance"
  reversalLevels: [vah, val],
  breakoutLevels: [vah, val, ibHigh, ibLow],
  poc_disagreement: boolean,
  approximation: "tpo+tickvol",   // honesty flag — not exchange volume
}
confidence,  thesis,  evidenceFor[], evidenceAgainst[], invalidators[],
urgency, sourceRefs[], requestedBy: null, respondingTo: null, nextAction
```

Register the agent in `runAllAnalysisAgents(board, db)` alongside the other analysis agents.

### How it feeds conviction / Prism
- The conviction adapter `buildStandardEngineSet()` (`conviction/adapters.ts`) **already reads `xauusd.analysis.structure` first** and only synthesizes a fake structure signal from EMAs when that topic is absent. So once we publish, `adaptFromBoardMessage("structure", structureMsg, ...)` consumes `state.direction` + `confidence` automatically. **Zero wiring change to land a real structure engine.**
- `structure` is a **direction-tier** engine (`TIER_MEMBERSHIP.structure = "direction"` in `conviction/types.ts`), so it contributes to `direction_score` in `computeTieredConviction()` — invoked by `prismSynthesis()` in `managers.ts`, called from `orchestrator.ts` `runCycle()`.
- **Regime cross-check (Phase 2, gated):** feed `dayType` back to Portfolio-Brain so a structural TREND/BALANCE read can corroborate or override the ADX-derived regime (which is often blind because ADX 404s on Twelve Data for XAU). This *changes trade decisions* → goes through Karri before activation.

### Phasing
- **Phase 1 — observability only, no trade impact (build freely):** compute TPO+tickvol session profile on M5, publish the full fact to `xauusd.analysis.structure` but behind a flag that the conviction adapter still treats as *advisory* — OR publish to a shadow topic `xauusd.analysis.structure.shadow` first so it logs/dashboards without touching conviction. Validate POC/VAH/VAL look sane vs the chart for ~1–2 weeks. This is pure learning-infra → runs immediately per prinsipp 6.
- **Phase 2 — feed conviction (gated):** flip the structure engine to consume the real fact; add M1 resolution + prior-session-overlap day-typing; optionally feed `dayType` to Portfolio-Brain. Anything that alters the conviction/regime that drives trades is a **strategy change → proposal to Karri** before activation.

Everything behind env flags (`MARKET_STRUCTURE_ENABLED`, `MARKET_STRUCTURE_FEEDS_CONVICTION`, `PROFILE_TICK_SIZE`, `PROFILE_VALUE_AREA_PCT`), default OFF, revertable in 30s.

---

## 4. The single highest-value piece to build first

**The session POC + Value Area (VAH/VAL) computed from a TPO+tickvol M5 histogram, published as an observability-only fact to `xauusd.analysis.structure(.shadow)`.**

Why this first:
- It is the **spine** — `dayType`, breakout/reversal levels, open-vs-value bias, and the conviction signal all derive from the POC/VA. Nothing else in the module is meaningful without it.
- It directly answers the core output the spec asks for: *where the market is in balance* (the value area) and *where large players are likely active* (the POC). Those two numbers are 80% of Dalton's actionable content.
- It is **zero-risk to ship** (observability only, prinsipp-6-free), validates the data-feasibility assumption on real OANDA data before any trade wiring, and lands into a slot (`xauusd.analysis.structure`) that the conviction layer is *already* waiting to consume — so the path from "validated histogram" to "real direction-tier engine replacing the EMA fake" is a single gated flag flip, not a rebuild.

Build POC/VA first, prove it on live data, then everything else (IB, day-typing, conviction feed) hangs off it.

---

### Key file references
- Blackboard publish contract: `apps/worker/src/firm/blackboard.ts` (`BoardMessage`, `publish()`)
- Analysis-agent pattern to mirror: `apps/worker/src/firm/analysis-agents.ts` (`runTechnicalAnalysis`, `runAllAnalysisAgents`)
- Candle type + fetch + volume field: `apps/worker/src/services/market-data.service.ts` (`Candle`, `fetchCandles`)
- Existing range logic to reuse/extend: `apps/worker/src/firm/orb/range-detector.ts` (IB seed), `apps/worker/src/firm/session-breakout/session-break-manager.ts` (prior-session range)
- Conviction insertion point: `apps/worker/src/firm/conviction/adapters.ts` (`buildStandardEngineSet` — reads `xauusd.analysis.structure`), `conviction/types.ts` (`structure` = direction tier), `conviction/scoring.ts`, `managers.ts` (`prismSynthesis`)
- Regime cross-check target: `apps/worker/src/firm/portfolio-brain.ts` (`classifyRegime`)
- Candle persistence gap (M1 not stored): `apps/worker/src/firm/raw-data-persistence.ts` (`persistCandles`, hardcoded 15min)
