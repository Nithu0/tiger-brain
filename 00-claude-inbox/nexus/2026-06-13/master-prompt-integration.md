# Master Prompt → Nexus integration spec

Date: 2026-06-13
Author: Claude (analysis + spec only — no code written)
Source ask: Karri's "Gold AI Master Prompt" — every signal passes 5 filters (Macro, Market structure, Volume, ML, Risk). Design how they integrate into Nexus's EXISTING decision architecture. Reuse Prism + the gate stack; do not build a parallel system.

Status: SPEC for Karri review. Strategy/risk-touching pieces (the two new gates + the conviction weights) go through `docs/strategy/proposals/` before activation. The 3 analytical-input additions (structure/volume/ML facts) are learning-infra / observability and can be built without strategy sign-off, but stay default-OFF and shadow-only until their conviction weight is reviewed.

---

## TL;DR

The master prompt is NOT a new decision system. Nexus already has the exact shape Karri describes:

- A **multi-engine conviction synthesizer** (Prism / `conviction/`) that fuses weighted engines into a tiered score.
- A **gate stack** (`strategy-blade.ts` + `gates/new-gates.ts`) that hard/soft-blocks entries.

The 5 filters map onto this as **3 new analytical inputs + 2 new gates**, plus reuse of what already exists. Concretely:

| Filter | Already in Nexus | Genuine addition |
|---|---|---|
| 1. Macro | `macro` engine + `macro-event` agent + `event-policy` | — (covered; one small gate-wiring) |
| 2. Market structure | `structure` engine *slot exists but has no publisher*; session-range (ORB/range-context) | **NEW: market-structure fact** (POC/VAH/VAL/value-area) → publishes `xauusd.analysis.structure` |
| 3. Volume | FVG + liquidity-sweep detector | **NEW: VPA fact** (volume confirmation / accumulation-distribution) folded into structure or technical evidence |
| 4. ML | regression-predictor (mean-R per regime×session), criteria-confidence, conviction itself | **NEW: meta-label score** as a conviction weight/engine input |
| 5. Risk | full gate stack, event-policy, shield risk-veto, daily-cap | **NEW: min-R:R gate** + **event-risk gate wiring** (the calendar exists; just no pre-entry R:R / news-blackout *gate* in the per-signal path beyond event-policy) |

So: **3 new facts/engines (structure, VPA, ML meta-label) + 2 new gates (min-R:R, event-risk-confirm).** Everything else is reuse.

---

## The existing architecture (ground truth)

### Conviction / Prism layer
- `apps/worker/src/firm/conviction/{index,types,scoring,config,adapters}.ts`
- `apps/worker/src/firm/managers.ts` → `prismSynthesis()` is the consumer.

Fusion mechanism (`scoring.ts:computeTieredConviction`):
- 7 declared engines: `macro, technical, structure, sentiment, intermarket, momentum, session`.
- Each engine emits a `StandardEngineOutput { signal(-1..1), confidence(0..1), regime_fit, source_quality, … }`.
- Engines grouped into **3 tiers**: direction (macro, structure) @0.45, timing (technical, momentum) @0.35, confirmation (sentiment, intermarket) @0.20. `session` is context-only (multiplier).
- Per-engine contribution = `signal × confidence × (regime_weight × perf_multiplier × regime_fit)`.
- Total = tier-weighted sum × session_multiplier × (0.5 + 0.5·regime_fit_avg), clamped [-1,1].
- Soft conviction gates: `minDirection / minTiming / minTotal` (env-overridable).

Extension point for a new engine: add to `EngineName` + `TIER_MEMBERSHIP` (types.ts), add weights to `BASE_WEIGHTS` + all 4 `REGIME_WEIGHTS` maps (config.ts), add an adapter read in `buildStandardEngineSet` (adapters.ts). Prism picks it up automatically.

**Key finding:** `structure` is ALREADY a declared direction-tier engine, and `adapters.ts` ALREADY reads `xauusd.analysis.structure` (with a synthesized fallback from technical+portfolio context). **There is no publisher for that topic.** So the market-structure filter is a half-wired slot waiting for a producer — not a new engine to invent.

### Gate stack
- `apps/worker/src/firm/strategy-blade.ts` → `evaluateStrategySignal()` runs gates sequentially, short-circuit on first hard-reject.
- `apps/worker/src/firm/gates/new-gates.ts` → unified bundle of 5 gates (risk_level, scalp_overlap_asia, ranging_conviction, entry_stack_cooldown, session_block); all default-OFF, soft-log by default to `gate_decisions` table.
- Independent gates: sl_cooldown, regime_direction, daily_trade_cap, cross_strategy_direction_flip.
- **event-policy** module already produces BLACKOUT / PRE_EVENT_CAUTION / POST_EVENT_SETTLING and is wired into the blade (`STRATEGY_BLADE_EVENT_POLICY`, default-on when blade on). Sets size multiplier, hard-blocks on BLACKOUT.
- **shield risk-veto** already blocks on extreme risk.

Gate extension point: two patterns — (A) add a case to `new-gates.ts` bundle (name + env-flag + eval block + GateInput field), or (B) standalone module `gates/<name>.ts` with `evaluate*()` + `is*Enabled()`, wired into `strategy-blade.ts` in order, fail-open on error, persisted to `gate_decisions`.

**Key finding:** event-risk blocking EXISTS (event-policy). What's ABSENT in the gate path: a **minimum R:R ratio gate** (no TP/SL ratio check before entry — confirmed absent). GateInput today has no entry/SL/TP fields.

### Firm-agents (advisory layer)
- `macro-event` agent → `xauusd.macro.events` (reads `economic_events` calendar, severity QUIET/NORMAL/ACTIVE/HOT). Feeds event-policy + risk context. EXISTS.
- `risk-advisor` → advisory only, never blocks (operator-prinsipp 1).
- `regression-predictor` → daily mean-R / win-rate per (strategy, regime, session) cell → firm_memory + `/predictions` API. EXISTS — this IS the ML historical-probability layer; it just doesn't feed conviction yet.

### Market-structure / volume / ML inputs (gap audit)
- Market structure: session high/low PRESENT (`orb/range-detector.ts`, `range-context.ts`, `session-breakout/`). POC/VAH/VAL/value-area/volume-profile **ABSENT**.
- Volume: FVG + liquidity-sweep PRESENT (`fvg-detector.ts`), OHLCV+volume persisted (`raw-data-persistence.ts`). OBV / accumulation-distribution / volume-confirmation **ABSENT**.
- ML: regression-predictor (mean-R cells) + criteria-confidence (binary) + conviction (weighted) PRESENT. A **meta-label score feeding conviction weight ABSENT** — the predictor's output is observability/API, not a conviction input.

---

## Per-signal 5-filter flow (mapped onto existing architecture)

This is one coherent flow that reuses blackboard → conviction → gate stack. Read top-to-bottom = the life of one candidate signal.

```
                          ┌─────────────────────────────────────────────┐
   FACT / ANALYSIS LAYER  │  (blackboard publishers, run on cycle)       │
   (engines for Prism)    └─────────────────────────────────────────────┘

 [F1 MACRO]    macro-engine → xauusd.analysis.macro            (EXISTS)
               macro-event agent → xauusd.macro.events         (EXISTS)
 [F2 STRUCT]   *NEW* market-structure fact → xauusd.analysis.structure
               (POC/VAH/VAL/value-area from OHLCV; reuses range-context)
 [F3 VOLUME]   fvg-detector (FVG+sweep)                        (EXISTS)
               *NEW* VPA evidence (vol-confirm / accum-distrib)
               → folded into structure fact's evidence OR technical engine
 [F4 ML]       regression-predictor (mean-R per regime×session) (EXISTS)
               *NEW* expose its predicted_win_rate / predicted_r
               as a meta-label score
 [F1 also]     technical, sentiment, intermarket, momentum, session (EXIST)

                              │
                              ▼
        ┌───────────────────────────────────────────────────┐
        │  PRISM SYNTHESIS  (conviction/scoring.ts)          │
        │  fuses engines → tiered conviction score           │
        │                                                    │
        │  Tier DIRECTION : macro + structure(NEW publisher) │
        │  Tier TIMING    : technical(+VPA evidence)+momentum│
        │  Tier CONFIRM   : sentiment + intermarket          │
        │  ML META-LABEL  : *NEW* multiplies engine confidence│
        │                   or rides as perf-multiplier       │
        └───────────────────────────────────────────────────┘
                              │  conviction passes soft gates?
                              ▼
        ┌───────────────────────────────────────────────────┐
        │  STRATEGY-BLADE GATE STACK (strategy-blade.ts)     │
        │  sequential, short-circuit on first hard-reject    │
        │                                                    │
        │  1. sl_cooldown / regime_direction / daily_cap …   │ (EXISTS)
        │  2. EVENT POLICY  (BLACKOUT/CAUTION)               │ (EXISTS = F1/F5)
        │  3. *NEW* event-risk-confirm gate                  │ (F1/F5: explicit
        │       "no trade inside high-impact window"         │  per-signal check
        │       — thin wrapper asserting event-policy state) │  on macro-event)
        │  4. shield risk-veto (extreme risk)               │ (EXISTS = F5)
        │  5. new-gates bundle (risk_level, ranging_conv …) │ (EXISTS = F5)
        │  6. *NEW* min_rr gate  (R:R ≥ 2, ≤1% risk)        │ (F5: genuine gap)
        │  7. forge exposure check                          │ (EXISTS = F5)
        └───────────────────────────────────────────────────┘
                              │  all pass?
                              ▼
                    DECISION → Execution Manager → OANDA
```

### Filter-by-filter mapping

**Filter 1 — Macro (USD, real rates, bonds, central banks):**
- Maps to existing `macro` engine (direction tier) + `intermarket` engine (EUR/SPY/TLT/USO) + `macro-event` agent + `event-policy`.
- Already-covered. The only addition is the event-risk *gate* (Filter 5) that makes "no trade before high-impact news" an explicit per-signal hard check rather than only a size-multiplier in event-policy.

**Filter 2 — Market structure (POC/VAH/VAL/session range):**
- Session range: covered (range-context / ORB).
- POC/VAH/VAL/value-area: **genuine gap.** Add a market-structure fact that computes value-area from persisted OHLCV+volume and **publishes the already-consumed `xauusd.analysis.structure` topic**. This lights up the existing `structure` engine slot in conviction (no scoring change — the slot and adapter already exist; today it runs on a synthesized fallback).

**Filter 3 — Volume (confirms move? accumulation/distribution?):**
- FVG + sweep: covered (entry-risk warnings).
- Volume confirmation / accum-distrib: **genuine gap.** Cheapest integration: compute a VPA evidence signal (volume-vs-average on the breakout candle, simple A/D slope) and attach it as **evidence inside the market-structure fact** (Filter 2's publisher) — value-area + volume are naturally one "structure" read. Avoids a brand-new engine and a config/weight rebalance. Alternatively, a dedicated `volume` engine if Karri wants it weighted independently (heavier change — needs BASE_WEIGHTS + 4 regime maps rebalanced).

**Filter 4 — ML (historical probability, meta-label, expected return):**
- regression-predictor already computes `predicted_win_rate`, `predicted_r` per (strategy, regime, session). **genuine gap = it doesn't influence the decision.**
- Minimal integration: feed the predictor's win-rate/expected-R as a **meta-label multiplier** on conviction. Two clean options that reuse existing machinery:
  - (a) `setEnginePerformanceMultipliers()` already exists and is bounded 0.70–1.20 — drive it from the predictor's per-cell edge (e.g., low predicted win-rate → multiplier < 1.0). Zero new engine; pure config overlay. **Recommended — smallest change.**
  - (b) a dedicated `ml` confirmation-tier engine whose `signal`/`confidence` = predicted edge. More explicit, but needs the weight-map rebalance.
- Either way the predicted edge can also be surfaced to the **min-R:R gate** as the "expected return" leg.

**Filter 5 — Risk (R:R ≥ 2, max 1% risk, no trade before high-impact news):**
- Max 1% risk: already enforced by Forge sizing.
- No-trade-before-news: covered by event-policy; **add explicit event-risk-confirm gate** for an auditable per-signal hard reject (thin wrapper over event-policy state).
- R:R ≥ 2: **genuine gap.** Add `min_rr` gate. Requires threading entry/SL/TP into GateInput (today absent). Standalone module pattern (B), default-OFF, soft-log first, env `MIN_RR_GATE_ENABLED` + `MIN_RR_RATIO` (default 2.0). Optionally combine predicted-R (Filter 4) so it's "min R:R AND positive expected return."

---

## Already-covered vs the 5 genuine additions

**Already covered (reuse, do NOT rebuild):**
- Multi-engine conviction synthesis (Prism) — the whole fusion layer.
- macro + intermarket engines, macro-event agent, economic-events calendar.
- event-policy (BLACKOUT / pre-event caution / size multiplier).
- shield risk-veto, daily-cap, regime-direction, sl-cooldown, ranging-conviction gates.
- FVG + liquidity-sweep volume read.
- session-range / ORB market structure.
- regression-predictor (the ML historical-probability engine — built, just not wired into the decision).
- Forge 1%-risk sizing.

**The 5 genuine additions:**
1. **Market-structure fact** (POC/VAH/VAL/value-area) → publishes the already-consumed `xauusd.analysis.structure` topic. (Filter 2)
2. **VPA volume-confirmation evidence** (volume-vs-avg, accum/distrib slope) — attached to the structure fact, not a standalone engine. (Filter 3)
3. **ML meta-label → conviction**: drive `setEnginePerformanceMultipliers()` (or a small `ml` engine) from regression-predictor's predicted edge. (Filter 4)
4. **min-R:R gate** (`MIN_RR_GATE_ENABLED`, `MIN_RR_RATIO=2.0`) — needs entry/SL/TP in GateInput. (Filter 5)
5. **event-risk-confirm gate** — thin per-signal hard-reject wrapper over existing event-policy state, for auditability. (Filter 1/5)

Of these, #1 and #2 are one workstream (one publisher), #3 is a config overlay, #4 and #5 are two small gates. **Net: ~1 new fact-publisher + 1 config wiring + 2 gates.** No new decision system.

---

## Minimal-integration path (ordered, lowest-risk first)

Build order chosen so each step is shadow/observable before it can touch a trade, and the trade-altering pieces land last (and gated through Karri):

1. **Market-structure fact publisher** (Filter 2 + 3). New cycle producer computing value-area (POC/VAH/VAL) + VPA evidence from persisted OHLCV+volume; publishes `xauusd.analysis.structure`. Lights up the dormant `structure` engine slot. Pure analytical input — no gate, no trade change. Default-OFF flag; observe its signal vs outcomes for a week.
   - Files: new `apps/worker/src/firm/market-structure/` producer; consumed by existing `conviction/adapters.ts` (no adapter change needed — topic already read).
2. **ML meta-label overlay** (Filter 4). Wire regression-predictor's per-cell predicted win-rate/expected-R into `setEnginePerformanceMultipliers()` (bounded 0.70–1.20). Shadow-log the multiplier before letting it modulate live; this is the one input that *changes conviction*, so the activation switch goes through Karri (it alters trade selection).
   - Files: small bridge in `predictions/regression-predictor.ts` → `conviction/config.ts`.
3. **event-risk-confirm gate** (Filter 1/5). Standalone gate asserting event-policy state ≠ BLACKOUT for the signal's symbol/time; soft-log first. Mostly duplicates event-policy intent but gives a per-signal auditable row in `gate_decisions`. Low risk.
   - Files: new `gates/event-risk-gate.ts`, wired in `strategy-blade.ts`.
4. **min-R:R gate** (Filter 5). Thread entry/SL/TP into `GateInput`; new `gates/min-rr-gate.ts`; `MIN_RR_GATE_ENABLED` default-OFF, `MIN_RR_RATIO=2.0`. Soft-log → gate-impact analysis → Karri review → activate. Optionally AND with predicted-R > 0 (uses #2). This is a real trade-blocking change → Karri-gated.
   - Files: `gates/min-rr-gate.ts`, GateInput extension in `new-gates.ts`, wiring in `strategy-blade.ts`.

Activation discipline (per operator-prinsipper): #1 and #3 are observability/learning-infra → can be built + run shadow freely. #2's live-modulation switch and #4's hard-block are trade-altering → file a `docs/strategy/proposals/` doc for Karri, observe in soft-log/shadow first, then operator flips the env var. Every piece behind its own env flag, instant rollback.

### What NOT to do
- Do not build a parallel "5-filter scorer." The filters are not equal-weight serial booleans in Nexus's design — they're weighted engines + gates. Forcing a literal 5-stage AND-chain would discard the regime-aware weighting Prism already does.
- Do not add `volume` as a standalone engine first. Fold VPA into the structure fact; only promote to its own engine if Karri wants independent weighting (it forces a full weight-map rebalance).
- Do not let the ML overlay swing beyond the existing 0.70–1.20 perf-multiplier bounds — keep meta-labeling as a tilt, not a veto.

---

## Open questions for Karri
1. Filter 3 (volume): fold VPA into the structure fact (my recommendation), or a standalone weighted `volume` engine?
2. Filter 4 (ML): perf-multiplier overlay (smallest) vs dedicated `ml` confirmation engine (more explicit). Which does he want as the canonical meta-label surface?
3. min-R:R: is 2.0 the hard floor, and should it AND with predicted-R>0, or is R:R alone sufficient?
4. POC/VAH/VAL window: per-session value-area, rolling N-hour, or daily? Drives the market-structure fact's computation.
