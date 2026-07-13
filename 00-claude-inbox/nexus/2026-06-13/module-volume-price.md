# Module spec — Volume Price Analysis (VPA / Wyckoff) for Nexus XAUUSD

Date: 2026-06-13
Author: Claude (analysis + spec only — no code changed)
Status: PROPOSAL / spec. Trade-altering pieces gate via Karri before live.
Scope: teach Nexus to read smart-money footprints — absorption, stop-hunts,
false breakouts, accumulation/distribution, effort-vs-result — and feed that as
a confirmation/veto signal into conviction.

---

## TL;DR

- **Nexus already has the structural half of VPA** (FVG zones, liquidity-sweep
  detection, false-breakout context via session-breakout/ORB confirmation). It
  does NOT have the volume half wired in — and it wrongly believes it has no
  tick-volume at all.
- **Volume verdict:** real volume does NOT exist on OANDA spot gold. But OANDA
  candles DO carry **tick-volume** (tick-count per bar), and Nexus is *already
  fetching and persisting it* to `ohlcv_candles.volume` every cycle — it's just
  never read back for analysis. Tick-volume is a usable proxy for *activity /
  effort* (well-correlated with real futures volume intraday on liquid FX/metals),
  good enough for effort-vs-result and climax/absorption flags. It is NOT good
  enough for true Wyckoff order-flow or delta/footprint. Be honest about that
  ceiling.
- **#1 first piece:** a pure `volume-price` analysis module that reads tick-volume
  from candles and emits a **VPA confluence score** (effort-vs-result + sweep +
  false-breakout flags) as an OBSERVABILITY FACT first, then a confirmation/veto
  the strategies can opt into. Zero trade behaviour change on day 1. Highest value
  because it unlocks an already-collected, currently-wasted data stream.

---

## 1. What Nexus already has (existing vs new)

### Already built (structural footprints — the price half of VPA)

| Capability | Where | Notes |
|---|---|---|
| **FVG / imbalance zones** | `apps/worker/src/firm/fvg-detector.ts` (filter) + `apps/worker/src/firm/fvg/fvg-manager.ts` (strategy) | 3-candle gap detection, fill-tracking, retest entry with touch-then-reject **confirmation** (the 2026-06-04 edge). Both default OFF. |
| **Liquidity-sweep / stop-hunt detection** | `fvg-detector.ts` → `detectLiquiditySweeps()` | High-sweep / low-sweep: price takes a swing level then closes back inside, `reversedAfter` flag. This IS stop-hunt logic. Used by `entry-thesis.ts` as a penalty/warning. |
| **False-breakout context** | `session-breakout/session-break-manager.ts`, `orb/orb-manager.ts` | Breakout strategies require a CLOSE outside range (not a wick) + confirmation TF — that's structural fakeout filtering. Plus `signal-filters/` Donchian-break + MFI confluence. |
| **Effort-vs-result proxy (partial)** | `signal-filters/index.ts` → `computeMFIFromCandles()` | Money Flow Index, **but** uses candle-RANGE as the volume proxy — explicit comment: *"Vi har ikke faktisk tick-volume"*. This is the wrong assumption (see §2). |
| **Tick-volume in the data model** | `services/oanda.service.ts` (`OandaCandle.volume`), `services/market-data.service.ts` (`Candle.volume?`), persisted in `raw-data-persistence.ts` → `ohlcv_candles.volume` (`packages/shared/src/db/schema.ts:834`) | Real tick-volume is fetched, mapped, and **written to Postgres every cycle**. It is accumulating history right now. Nothing reads it back for analysis. |

### Not built (the volume half — this module)

- No effort-vs-result using **actual tick-volume** (only the range-proxy MFI).
- No **climax / absorption** detection (high volume + small result = absorption;
  high volume + large result = effort that succeeded).
- No **accumulation/distribution** structure read (sideways range + volume
  character over time).
- No **volume-confirmed** flavour of the existing sweep/false-breakout flags
  (a sweep on a tick-volume spike is a far stronger trap signal than a quiet one).
- No single **VPA conviction signal** on the blackboard that strategies/prism can
  consume as confirmation or veto.

**Overlap assessment:** ~60% of the *structure* already exists. The new module
should NOT re-implement gap/sweep geometry — it should **import** the existing
detectors and add the volume dimension on top, then publish one consolidated VPA
fact. This keeps it a focused diff, not a "while we're here" rebuild.

---

## 2. Data honesty — can VPA work on spot gold?

**Short answer: partially, with an honest ceiling. Use tick-volume; don't pretend
it's real volume.**

### The limitation (real)
- OANDA XAUUSD is spot OTC. There is **no centralized volume** — no consolidated
  tape, no real contract count. Anna Coulling's VPA and classic Wyckoff assume
  *real* exchange volume.
- What OANDA's candle `volume` field actually is: **tick count** — the number of
  price updates OANDA's pricing engine emitted during the bar. It reflects *one
  broker's* feed activity, not market-wide traded contracts.

### Why tick-volume is still usable (the honest upside)
- On liquid instruments, **tick-count correlates strongly with real volume
  intraday** (widely documented for FX/index futures; r typically ~0.7–0.9 on
  liquid sessions). XAUUSD is liquid during London/NY. So tick-volume is a sound
  proxy for **activity / participation / effort** — which is exactly what
  effort-vs-result and climax detection need.
- Crucially, the VPA primitives we want are **relative, not absolute**: "this
  bar's volume vs the trailing-N average", "is the breakout bar on rising or
  falling volume", "did the sweep happen on a volume spike". Relative tick-volume
  survives the OTC limitation far better than any absolute interpretation.

### Where it breaks down (don't oversell)
- **No order-flow / delta / footprint.** Can't see aggressive buyers vs sellers,
  bid/ask absorption at a level, or true Wyckoff spring/upthrust *with volume
  signature* at the tape level. Tick-volume is symmetric (doesn't know direction
  of the aggressor).
- **Broker-specific + session-skewed.** Tick frequency depends on OANDA's feed and
  on volatility; quiet Asia vs frantic NFP bars aren't comparable in raw counts.
  Everything must be **normalized** (z-score / percentile vs same-session-of-day
  baseline), never raw thresholds.
- **Wyckoff phase analysis (accumulation/distribution over days)** is the weakest
  fit — possible as a coarse heuristic, not as faithful Wyckoff. Flag low
  confidence.

### Is a real-volume proxy available (COMEX GC)?
- **Not on current feeds.** We have OANDA (spot, tick-volume) + Twelve Data
  (price, occasional volume field, but plan-tier flaky for XAU) + optional Polygon
  fallback. None of these gives us **COMEX GC futures volume** today.
- **Polygon** (already wired as a dormant fallback, `POLYGON_FALLBACK_ENABLED`)
  *does* have futures + real aggregate volume on paid tiers — a GC futures volume
  series could become a genuine real-volume confirmation overlay **if operator
  upgrades the Polygon plan**. Flag this as a future Phase 3 enhancer, not a
  dependency. Operator has authorized paying for premium tiers when justified;
  this is a candidate but only after Phase 1 proves tick-volume earns its keep.
- COMEX volume also lags (no true real-time consolidated tape without an exchange
  data subscription) and trades a different (futures) instrument with its own
  roll/session quirks. Useful as confirmation, not as the primary signal.

**Verdict line for the operator:** *Yes, a meaningful subset of VPA works on spot
gold using OANDA tick-volume as an effort/participation proxy — effort-vs-result,
climax/absorption, volume-confirmed sweeps and false-breakouts. True order-flow
Wyckoff (delta, footprint, faithful phase analysis) does not, and shouldn't be
promised. We already collect the tick-volume; we just don't use it.*

---

## 3. Implementation plan — `volume-price` module

New dir: `apps/worker/src/firm/volume-price/` following the existing module shape
(`config.ts` + `volume-price-analyzer.ts` + `index.ts` + `.test.ts`). Pure
functions for everything; the analyzer is side-effect free and testable on candle
arrays. All env-gated, all default OFF, behaviour-neutral until flipped.

### Design principles
- **Reuse, don't rebuild:** import `detectLiquiditySweeps` and FVG geometry from
  `fvg-detector.ts`; import breakout/range context where needed. The module's new
  job is *the volume layer + consolidation into one VPA score*.
- **Everything normalized:** all volume reads are relative (z-score or percentile
  vs trailing-N and vs same-hour-of-day baseline), never raw tick thresholds.
- **Report before it acts:** Phase 1 publishes a FACT only. No strategy consumes
  it for entry decisions until Phase 2, and even then only behind per-strategy
  opt-in flags (operator-prinsipp 1 + learning-infra-vs-strategy boundary —
  capture/observability is free, trade-altering veto goes through Karri).

### Phase 1 — Volume primitives + VPA FACT (observability only) — FREE, ship now
Pure analyzer over recent candles (15m + H1), emitting a `VPAAnalysis`:
- `relVolume` — current bar tick-volume vs trailing-N mean (z-score + percentile).
- `effortVsResult` — bar's tick-volume (effort) vs its true-range/close-progress
  (result). High effort + tiny result near a level = **absorption**. High effort +
  big result = **successful effort** (continuation-supportive).
- `climax` flag — extreme relVolume spike (buying/selling climax candidate).
- `volumeTrend` — is volume expanding or drying up over the last N bars
  (drying-up into a range = potential accumulation/distribution; expanding into a
  breakout = confirmation).
- Re-tags existing structure flags with volume: `sweepOnVolume` (a
  `detectLiquiditySweeps` hit that coincided with a tick-volume spike → high-conf
  stop-hunt), `breakoutVolumeConfirmed` vs `breakoutOnLowVolume` (low-volume break
  = likely false breakout).
- Consolidate into `vpaScore` (-100..+100: positive = smart-money footprints
  support the move/direction, negative = trap/absorption/exhaustion) + a
  `vpaSummary` string + per-component confidences.
- Publish as a blackboard FACT (topic `firm.volume-price.state`), wired into the
  transparency dashboard. **Zero trade impact.** Backfill-validate against the
  accumulating `ohlcv_candles.volume` history.
- Gate: `VPA_ANALYSIS_ENABLED` (default OFF; safe to flip — observability only).

### Phase 2 — Confirmation / veto into conviction — gates via Karri
- Expose `vpaScore` + flags to `entry-thesis.ts` (alongside the existing FVG
  penalty) and to prism synthesis as a **confidence modifier**:
  - **Veto/penalty:** entry into/against a fresh absorption zone, or a breakout on
    low volume (likely fake), or entering right after a volume-spike sweep against
    intended direction.
  - **Boost:** breakout with volume confirmation; entry aligned with
    successful-effort direction; sweep-then-reverse *on volume* in trade direction.
- Per-strategy opt-in flags (e.g. `SB_REQUIRE_VOLUME_CONFIRM`,
  `ORB_VOLUME_FILTER`) so each strategy adopts it independently after its own
  backtest. Default OFF.
- **Replace the range-proxy in `computeMFIFromCandles`** with real tick-volume when
  available (fall back to range-proxy when volume is null) — fixes the incorrect
  "we have no tick-volume" assumption. Small, validate it doesn't regress the
  SB MFI+Donchian backtest before flipping.
- Requires Karri review + backtest per strategy (trade-altering). File a proposal
  in `docs/strategy/proposals/`.

### Phase 3 — Optional real-volume overlay + coarse Wyckoff phase — later, gated
- If operator upgrades Polygon: add a COMEX **GC futures volume** series as a
  second, real-volume confirmation channel that cross-checks the tick-volume
  read (divergence between the two = lower confidence).
- Coarse accumulation/distribution **phase** heuristic over multi-day ranges
  (low-confidence label only; explicitly not faithful Wyckoff).
- Both gated, both Karri-reviewed, both default OFF.

### Safety / rollout
- Every piece behind its own env flag, all default OFF, 30-second revertable.
- Phase 1 is pure observability (operator can flip freely). Phases 2–3 touch trade
  decisions → Karri-gated, proposal doc, per-strategy backtest, then phased
  activation (never blind flip-all).
- Tests: pure analyzer unit tests on hand-built candle fixtures (absorption bar,
  climax bar, low-vol fake break, vol-confirmed break, vol-spike sweep) — exercise
  real pathways, keep the green count.

---

## 4. Highest-value feasible first piece

**Phase 1 `volume-price` analyzer + VPA FACT — specifically the `effortVsResult` +
`sweepOnVolume` + `breakoutVolumeConfirmed` flags, published as observability.**

Why this first:
1. **Unlocks data we already pay for and throw away.** Tick-volume is fetched,
   mapped, and persisted to `ohlcv_candles` every cycle but never analyzed. This is
   the cheapest high-leverage move in the whole module — no new feed, no new cost.
2. **Zero risk.** Pure functions + a FACT publish. No trade behaviour changes, so
   it ships free (no Karri gate), and we can validate the signal on accumulated
   history before letting it touch a single decision.
3. **It directly upgrades signals that already exist.** The current
   `detectLiquiditySweeps` and breakout-confirmation logic become materially
   stronger the moment they're tagged with "did this happen on a volume spike or in
   silence" — that's the single most decision-relevant VPA primitive and it's
   feasible today.
4. **It corrects a wrong assumption in the codebase** (`signal-filters` "we have no
   tick-volume"), which means future work builds on truth.

Concretely, first commit: `apps/worker/src/firm/volume-price/volume-price-analyzer.ts`
(pure) + config + tests, reading `Candle.volume`, importing `detectLiquiditySweeps`,
emitting `VPAAnalysis` with normalized relVolume + effortVsResult + the two
volume-tagged structure flags; wire a FACT publish + dashboard tile behind
`VPA_ANALYSIS_ENABLED` (default OFF). Validate against `ohlcv_candles` history
before proposing any Phase 2 conviction wiring to Karri.
