# Module spec — Macro / Intermarket Analysis (gold's relationships)

**Source frame:** Murphy, *Intermarket Analysis*. Teach Nexus gold's macro relationships — Gold↔USD, Gold↔real rates, Gold↔bonds, Gold↔inflation, Gold↔risk-appetite — and turn them into (a) a bullish/bearish macro bias, (b) news filtering, (c) risk derisking before CPI/NFP/FOMC.

**Date:** 2026-06-13. **Status:** ANALYSIS + SPEC ONLY. No code written. Strategy/risk pieces here are Karri-gated.

---

## TL;DR

Nexus already has most of the intermarket *plumbing* — FRED (DGS10, DTWEXBGS, T10YIE, real-10Y derived), a macro-analyst, an economic-calendar table, and a full 4-state event-policy state machine that already blocks entries in a blackout window. What's missing is (1) **calibration of the calendar feed** (it's `economic_events`, fed by Finnhub which is OFF by default; the live producer for the event-policy topic is dormant under ORB_ONLY_MODE → the blackout gate may be running on stale data), (2) a **single coherent macro-bias score** that fuses USD/real-rates/risk instead of the current EUR-USD-+-TLT heuristic, and (3) **VIX / risk-appetite series** (not fetched at all).

**The #1 first piece is not "build a bias score" — it's making the event-risk gate actually fire on fresh data before CPI/NFP/FOMC.** It's the most safety-positive, lowest-risk, and partly already built. Bias-scoring is phase 2+ and is trade-altering → Karri.

---

## 1. What Nexus already has (existing vs missing)

### EXISTING — plumbing is largely there

| Component | Path | Status | What it gives us |
|---|---|---|---|
| **FRED service** | `apps/worker/src/services/fred.service.ts` | ACTIVE (gated on `FRED_API_KEY`), 6h cache | DFF (fed funds), DGS10 (10Y nominal), DTWEXBGS (broad USD index), T10YIE (10Y breakeven inflation), **real-10Y = DGS10 − T10YIE derived**. Publishes `xauusd.macro.fred`. This is the single most important gold driver and it's already live. |
| **Macro-analyst (Prism)** | `apps/worker/src/firm/analysis-agents.ts:~401` | ACTIVE (`MACRO_ANALYSIS_ENABLED=true`) | Scores EUR/USD (>1.10 bull / <1.06 bear), TLT (>95 bull / <80 bear), real-10Y (>2% headwind / <0% tailwind). Publishes `xauusd.analysis.macro`, conf ~55%. Direction = sign of summed score. |
| **Macro-event agent (Cipher)** | `apps/worker/src/firm/agent-bus/firm-agents/macro-event.ts` | DORMANT (`FIRM_AGENT_MACRO_EVENT_ENABLED=false`) | Hourly; reads next-24h high-impact events from `economic_events`, Gemini-summarizes cluster, QUIET/NORMAL/ACTIVE/HOT severity → Discord. Advisory only, never blocks. |
| **Event-policy state machine** | `apps/worker/src/firm/event-policy/{state-machine,rules,types}.ts` | ACTIVE (`STRATEGY_BLADE_EVENT_POLICY=true`) | The real prize. 4 states: CLEAR / PRE_EVENT_CAUTION (60m, size×0.75, thr×1.10, high-conv-only) / BLACKOUT (±5m, entries OFF, size×0) / POST_EVENT_SETTLING (30m, size×0.50, thr×1.20). Calibration-overlayable. Consumed by strategy-blade entry gate + risk-advisor. |
| **Calendar fact + macro-regime fact** | `apps/worker/src/firm/fact-agents.ts` (`runCalendarFact`, `runMacroRegimeFact`) | ACTIVE | Calendar-fact reads `economic_events` in (now−30m, now+4h), sets `blackout=true` + invalidators on nearby high-impact. Macro-regime-fact republishes FRED snapshot. |
| **Finnhub calendar service** | `apps/worker/src/services/finnhub-calendar.service.ts` | ACTIVE code, OFF by default (`FINNHUB_API_KEY` unset) | `refreshUsdHighImpactEvents()` (30-day USD high-impact upsert), `nearUsdHighImpactEvent(ts, window)`, dedupe-upsert into `economic_events`. Backtest notes: CPI-pre-skip saved $687/6mo, PCE-window +$208/trade. |
| **Forex Factory calendar** | (data-sources.md Tier 3, `nfs.faireconomy.media`) | available, free | Alternative calendar source for FOMC/NFP/CPI. |
| **Engine vote slot `macro` + `intermarket`** | `engine-multipliers.ts`, `conviction/scoring.ts` | ACTIVE | The 7-engine tiered vote already reserves a `macro` engine (direction tier, base wt 0.22) and `intermarket` engine (confirmation tier, 0.13). Slots exist; they're fed by the heuristic macro-analyst today. |
| **DIRECTION_MODE neutralizer** | `apps/worker/src/firm/managers.ts:112-135` | ACTIVE | **Relevant: this currently zeroes macro.** See §4. |

### MISSING / weak

- **VIX / risk-appetite series** — not fetched anywhere. SPY is opportunistically in the Twelve Data batch; Fear&Greed (alternative.me, crypto) and Reddit are sentiment proxies but no equity-vol or credit-spread risk gauge. Gold↔risk-appetite is the weakest of the five relationships in the current build.
- **A single coherent macro-bias score.** Today macro "bias" is a loose sum of EUR/USD + TLT + real-10Y inside the analyst. No normalized −1..+1 bias that fuses USD direction, real-rate direction, and risk regime with documented weights. The Murphy relationships aren't encoded as relationships — they're three independent thresholds.
- **Correlation-awareness.** No rolling Gold↔DXY / Gold↔real-rate correlation tracking, so the system can't tell when the normal inverse relationship has decoupled (e.g. crisis regimes where gold and USD both rise). Murphy's whole point is regime-dependent correlation.
- **Calendar freshness guarantee.** `economic_events` is fed by Finnhub (OFF) or the legacy TradingEconomics script (manual/dead) or Forex Factory (available but wiring unconfirmed). The event-policy producer topic was found 40+ days stale in the 2026-06-04 audit (producer dormant under ORB_ONLY_MODE). **The blackout gate is only as good as the table behind it, and the table may be empty/stale.**

---

## 2. Data availability

| Series | Best source | Status | Cost |
|---|---|---|---|
| **Real 10Y rate** (gold's #1 driver) | FRED DGS10 − T10YIE | ALREADY FETCHED | Free |
| **USD index (DXY-equiv)** | FRED DTWEXBGS (broad TWI) | ALREADY FETCHED | Free. True DXY (ICE) via Twelve Data `DXY`/Polygon if we want the tradable index vs the broad TWI. |
| **Nominal 10Y / 2Y / curve** | FRED DGS10, DGS2 | DGS10 fetched; DGS2 trivial add | Free |
| **Fed funds** | FRED DFF | ALREADY FETCHED | Free |
| **Inflation expectations** | FRED T10YIE (+ T5YIE) | T10YIE fetched | Free |
| **Bonds proxy** | TLT (Twelve Data) | fetched by analyst | metered (already paying) |
| **SPX / risk-on** | Twelve Data SPX/SPY batch | opportunistic | metered (already paying) |
| **VIX / equity vol** | Twelve Data `VIX`, or FRED `VIXCLS` (daily, EOD only) | **MISSING — add** | FRED VIXCLS free (daily lag); Twelve Data intraday metered |
| **Credit spreads (risk)** | FRED `BAMLH0A0HYM2` (HY OAS) | MISSING — optional | Free, daily |
| **Economic calendar (CPI/NFP/FOMC)** | Finnhub (have service, OFF) / Forex Factory (free) | needs activation | Finnhub free 60/min; FF free |

**Verdict:** ~90% of what we need is already fetchable for free via FRED, which is already wired. The only genuinely new fetch is a risk-appetite gauge — and FRED `VIXCLS` + `BAMLH0A0HYM2` give us both for free at daily resolution (fine for a slow macro-regime signal; we don't need intraday VIX for a bias). **No new paid tier required for the core build.** True intraday DXY/VIX would need Twelve Data/Polygon (already paid) — phase 3 nicety, not a blocker.

---

## 3. Implementation plan — `macro-intermarket` module

Proposed module: `apps/worker/src/firm/macro-intermarket/` (consolidates the scattered macro-analyst + macro-bias.engine + FRED-regime logic behind one public surface). Phased so the safety-positive, non-trade-altering parts ship first and the trade-altering bias-scoring waits on Karri.

### Phase 0 — Calendar freshness + event-gate verification (NON-trade-altering, ship now)
Make the *existing* event-policy gate trustworthy. No new behavior, just guarantee the data behind it is fresh.
- Activate a calendar feed: enable Finnhub (`FINNHUB_API_KEY`) **or** wire Forex Factory into `refreshUsdHighImpactEvents`. Operator-gated (API key / env).
- Add a daily refresh trigger (cron or orchestrator hourly) that keeps `economic_events` populated 30 days out for USD high-impact (CPI, NFP, FOMC, PCE).
- Add a **freshness probe**: if newest `economic_events.created_at` > 24h old OR table empty within ±7d of a known FOMC date, emit a Discord/briefing warning (report, don't auto-disable — operator-prinsipp 1).
- This is pure observability + data-plumbing → Claude-owned, no Karri gate.

### Phase 1 — Event-risk gate hardening (THE #1 PIECE — see §4)
The event-policy state machine already exists and already derisks. Phase 1 makes it *demonstrably* fire on CPI/NFP/FOMC. Detail in §4.

### Phase 2 — Macro-bias score (TRADE-ALTERING → Karri proposal required)
Replace the three-independent-thresholds heuristic with one normalized bias in [−1, +1]:
- `bias = w_usd·f(ΔDTWEXBGS) + w_rate·f(Δreal10Y) + w_risk·f(risk_regime) + w_infl·f(T10YIE_trend)`
- Sign convention: stronger USD → bearish gold; rising real rates → bearish gold; risk-off → bullish gold (flight-to-safety); rising inflation expectations → bullish gold.
- Each `f()` normalized by rolling z-score so the inputs are comparable.
- Output feeds the existing `macro` + `intermarket` engine slots (direction + confirmation tiers) with a confidence derived from input agreement (all four aligned → high conf; conflicting → low conf, near-neutral).
- **Correlation guard:** compute rolling 20-day Gold↔real-rate and Gold↔USD correlation; if correlation has decoupled from its normal sign, down-weight the bias (Murphy regime-shift handling). This stops the macro engine from voting confidently when the textbook relationship is temporarily broken.
- Because this changes the direction/conviction vote → **`docs/strategy/proposals/` doc, Reviewer: Karri, before implementation.**

### Phase 3 — Risk-appetite series + intraday (enhancement)
- Add FRED `VIXCLS` + `BAMLH0A0HYM2` for a real risk-off gauge (free, daily).
- Optionally intraday VIX/DXY via Twelve Data for faster risk-regime flips.
- Feed risk regime into both the bias score (Phase 2) and the event-policy defensiveHold logic.

### Phase 4 — Macro-event agent activation + correlation dashboard
- Flip `FIRM_AGENT_MACRO_EVENT_ENABLED` on (advisory Discord summaries before event clusters) — non-trade-altering, but gated on operator wanting the Discord volume.
- Dashboard panel: live macro-bias, the four sub-components, rolling correlations, next high-impact event countdown.

---

## 4. Highest-value first piece — Event-risk gate before high-impact news

**Why this first:** safety-positive (it *removes* risk, never adds a new trade-altering bias), partly already built (the state machine ships and is wired into the strategy-blade entry gate), free (FRED/Forex Factory), and directly delivers the brief's "risk before CPI/NFP/FOMC". It is the only piece that is both high-value and not trade-direction-altering, so it can ship without a Karri gate (it's a risk-reducing safety rail, not a sizing/threshold loosening — and it's behind the existing `STRATEGY_BLADE_EVENT_POLICY` flag, revertable in 30s).

**The gap it closes:** the event-policy BLACKOUT/PRE_EVENT_CAUTION states are correct and tested, but they read `economic_events`, and that table is fed by a calendar source that's OFF/dormant. So today the gate likely sees an **empty or 40-day-stale calendar** → it computes CLEAR through an actual FOMC and lets full-size entries through the worst liquidity window. The fix is data, not logic.

**Concrete deliverable:**
1. **Activate + keep-fresh** a USD high-impact calendar feed into `economic_events` (Finnhub via existing `refreshUsdHighImpactEvents`, or Forex Factory). Daily 30-day refresh. *(operator-gated: needs API key / env flip)*
2. **Freshness assertion** in the event-policy path: if the calendar is empty/stale when within 48h of a scheduled FOMC/CPI/NFP, fail *safe* — emit a loud Discord/briefing warning and (proposal to Karri) optionally treat unknown-but-likely-event windows as PRE_EVENT_CAUTION rather than CLEAR. The warning is non-gated; the fail-safe-to-caution behavior is trade-altering → Karri.
3. **A test that proves it fires:** seed `economic_events` with a synthetic FOMC at T, advance the clock across the window, assert the state machine transitions CLEAR→PRE_EVENT_CAUTION→BLACKOUT→POST_EVENT_SETTLING→CLEAR and that the strategy-blade entry gate actually rejects an entry inside BLACKOUT. (Exercises the real pathway, per user pref — not a smoke test.)
4. **Verification on live data:** after activation, watch the next real CPI/NFP and confirm in logs the gate entered BLACKOUT ±5m and no entry fired. Don't mark done until the symptom (full-size entry through a real high-impact event) is observably gone.

**Split by gate:**
- *Claude-owned, ship now:* calendar activation plumbing, freshness probe + Discord warning, the state-machine transition test, live verification. All non-trade-altering / observability / safety-rail.
- *Karri-gated:* the fail-safe-to-PRE_EVENT_CAUTION-on-unknown behavior, any change to the size/threshold multipliers, and all of Phase 2 bias-scoring.

---

## Relevant files (absolute)

- `apps/worker/src/services/fred.service.ts` — real-rate/USD/inflation source (live)
- `apps/worker/src/firm/event-policy/state-machine.ts` + `rules.ts` + `types.ts` — the gate (live)
- `apps/worker/src/firm/fact-agents.ts` — `runCalendarFact`, `runMacroRegimeFact`
- `apps/worker/src/services/finnhub-calendar.service.ts` — calendar feed (OFF by default)
- `apps/worker/src/firm/analysis-agents.ts` (~L401) — current heuristic macro-analyst
- `apps/worker/src/firm/agent-bus/firm-agents/macro-event.ts` — advisory event agent (dormant)
- `apps/worker/src/firm/managers.ts:112-135` — DIRECTION_MODE macro neutralizer (see below)
- `apps/worker/src/firm/conviction/scoring.ts` + `engine-multipliers.ts` — where macro/intermarket votes land
- `docs/ref/data-sources.md`, `docs/ref/feature-flags.md` — source + flag audit

## DIRECTION_MODE caveat (must address before Phase 2 has any effect)

`managers.ts:112-135`: when `DIRECTION_MODE=technical_only` (or `technical_only_ranging` in ranging regimes), macro **and** news directions are forced to `"neutral"` *before* weighted aggregation:

```
if (neutralizeMacroNews && (type === "macro" || type === "news")) dir = "neutral";
```

Rationale on record: macro/sentiment carry a permanent long-lean on gold (it's a hedge asset) → produced ~0 shorts even in falling markets, so technical_only lets price action set direction. **Implication:** if the live config is `technical_only`, a better Phase-2 macro-bias score will be computed and then thrown away. Any Phase-2 proposal to Karri must include either (a) un-neutralizing macro once the score is symmetric/short-capable, or (b) routing the macro bias only into conviction/sizing (not direction) while DIRECTION_MODE stays technical_only. The event-gate (#1 piece) is unaffected by this — it gates entries regardless of direction.
