# LANE 4 — Regime-direction gate audit (READ-ONLY)

Date: 2026-06-04
Branch: node-migration-nexus
Question: Does `regime_direction_gate` actually bite? Is the ~97.7% null-rate root cause confirmed, and does cc02426's flat-band fix it?

## TL;DR

- **Root cause of the null-rate: CONFIRMED, and it is upstream of everything cc02426 touched.** `regimeDirection` is only ever computed when `regime === "TRENDING"`. Regime can only become `TRENDING` when `adx > 30`. **ADX is `null` in production** because it is sourced exclusively from Twelve Data (`fetchADX`), which 404s for XAU/USD. With ADX null, regime never reaches TRENDING → direction classifier is never called → direction is null with reason `not_trending`. Live pull (today) confirms `adx=null`, `atr=null` across every strategy and in `xauusd.market.raw`.
- **cc02426 does NOT fix the dominant null-path.** Its WARN-triage and flat-band live *inside* the `if (regime === "TRENDING")` branch — code that is almost never reached. It improves diagnosability of the *minority* TRENDING-but-flat cases and guards against float-noise phantoms. It does not, and was not claimed to, address the `not_trending` majority. The commit message itself says root cause is "unconfirmed pending Railway logs" — those logs will mostly stay silent because the branch barely executes.
- **Does the gate bite? NO — and even if flipped on, it would be a near-total no-op in the current data regime.** `evaluateRegimeDirectionGate` returns `allow` whenever `regimeDirection` is null (`reason: "direction_unknown"`). Since direction is null ~always, the gate passes everything. The M15 EMA-fallback (`599a052`, default OFF) is the only thing that could make it bite without fixing ADX — and it is not enabled.

## The two conflated "97.7%" numbers (important)

phase-status.md and the round-3 forensics mix two different measurements under one number. They are not the same failure:

1. **`portfolio_regime_at_entry IS NULL` on 97.7% of positions** (phase-status L211) — a *persistence/observability* gap on the positions table. Partly addressed going-forward by `deb7075` (A1) and a not-yet-run backfill (A5).
2. **`regimeDirection=null` on ~97.7% of TRENDING-context blackboard messages** (regime-direction.ts L41-43, the number cc02426 cites) — the *decision-time* signal. This is the one Lane 4 cares about.

These got merged rhetorically into "direction-blindness 97.7%". The decision-time null (#2) has a cleaner, confirmable cause than the comment implies (which lists 5 candle-failure reasons as if the candle fetch were the suspect). **The real cause is one level up: regime almost never equals TRENDING, so the classifier with all those reasons never runs.** When it does NOT run, the reason is `not_trending` — which is not even in the cc02426 data-failure WARN list.

## Production path (traced)

Producer:
- `fact-agents.ts:74` `runTechnicalFacts` → `fetchADX("XAUUSD","15min")` and `fetchADX("XAUUSD","1h")`.
- `market-data.service.ts:321` `fetchADX` is **Twelve-Data-only**, no OANDA fallback, `if (!res.ok) return null`. XAU/USD 404s on Twelve Data (documented at `market-data.service.ts:152-153`). → ADX = null on both timeframes.
- ADX null published to `xauusd.market.raw` / `xauusd.analysis.technical`.

Regime:
- `portfolio-brain.ts:136 classifyRegime` reads adx from `xauusd.analysis.technical` indicators (L145). All `TRENDING/RANGING/LOW_VOLATILITY` branches are gated on `adx != null`. With adx null they all fall through → regime = default `MIXED_NO_EDGE` (or a volatility-derived bucket if ATR is present, but ATR is also null in the live pull).
- The portfolio-brain test itself documents this: `portfolio-brain.test.ts:68` "empty blackboard → MIXED_NO_EDGE default ... regimeDirectionReason = not_trending".

Direction:
- `portfolio-brain.ts:212` `if (regime === "TRENDING") { classifyTrendDirection() }`. **This is the gate on the gate.** Not TRENDING → `regimeDirection=null`, reason `not_trending`. The H4 candle fetch (`fetchCandles("XAUUSD","4h",32)`, which *does* work via OANDA — "4h"→"H4" maps correctly at oanda.service.ts:741) is never even attempted.

Consumer:
- `strategy-blade.ts:153,161` reads `regimeDirection` off `xauusd.portfolio.context`, calls `evaluateRegimeDirectionGate`.
- `gates/regime-direction-gate.ts:150` null direction → `allow / direction_unknown`. Gate is a pass-through.

## Live data (pull over 443, 2026-06-04 ~16:14Z)

`data/pull/strategy_states.json`:
- `regime.portfolio = "HIGH_VOLATILITY"` (NOT TRENDING) → direction not computed.
- `market.atr = null`, `market.adx = null`.
- All 6 strategies: `adx=null`, `atr=null`, `direction=null`.

`data/pull/risk_snapshot.json`: no regime/direction fields (not exposed there).
`data/pull/threads_closed.json` (50 rows): does not expose `portfolioRegimeAtEntry` via API, so the positions-table null-rate (#1 above) can't be re-measured over 443. Direct DB (`nexus-pg` MCP) is firewalled — `EHOSTUNREACH 66.33.22.236:58688`, only 443 works — so the blackboard `regimeDirection` distribution couldn't be re-counted directly this session. The live snapshot + code path are sufficient to confirm the mechanism.

## Verdict

- **Null-rate root cause: CONFIRMED** = ADX-null (Twelve Data XAU/USD 404, no fallback) → regime never TRENDING → direction never computed (`not_trending`). This is structural, not float-noise, not candle-fetch.
- **Does the gate bite now: NO.** Default OFF; and even ON it would no-op because direction is null ~always. cc02426 did not change this.
- **cc02426 assessment:** behaviour-neutral diagnostics + a correct-but-rarely-reached float-noise guard. It logs/guards the wrong (minority) layer. Honest commit msg ("unconfirmed"), but the framing points investigators at candle-fetch reasons when the actual cause is the regime classifier upstream.

## Cross-ref: Karri trend-pause hypothesis

This gate is a *proxy* for trend-pause detection (`project_trend_pause_concept.md`: "Når trend pauser, blir den blind"). The irony: the proxy is itself blind for a more basic reason — it has no trend *direction* because it has no ADX to even decide there IS a trend. The gate cannot detect "trend pause" when it cannot detect "trend". Fixing ADX is a prerequisite for the trend-pause work to have any signal to act on. Do not propose the gate logic as the trend-pause solution; route to Karri (he owns this).

## NEW TASKS

**[infra] T1 — Add OANDA (or computed) ADX fallback to `fetchADX`.** This is THE fix. ADX null is the single point of failure feeding regime → direction → the gate, AND it independently null-routes the TRENDING regime classification for ALL strategies (every strategy in the live pull shows adx=null / regimeAllowed=false consequences). Mirror the OANDA-first pattern already used by `fetchCandles`. Compute ADX(14) from OANDA H1/M15 candles locally (we already fetch OANDA candles successfully). Pure data-plumbing, no trade-decision change → Claude can do this directly. Highest leverage of anything in this lane.

**[infra] T2 — Make regime-direction NOT gate on `regime === "TRENDING"`, OR widen the TRENDING criterion.** Even with ADX fixed, direction is only computed in TRENDING; RANGING/HIGH_VOLATILITY trades still fire direction-blind. Consider computing direction unconditionally (the H4 fetch already works) and letting the gate decide relevance. Behaviour-relevant for the gate's reach → file as proposal for Karri, but the *computation* (capture/observability) side Claude can land default-OFF.

**[infra] T3 — Add an end-to-end test that exercises the real null-path.** Current tests (`regime-direction.test.ts`, `portfolio-brain.test.ts`) only prove the pure classifier and the `not_trending` default. None asserts the production failure (adx-null → not_trending → gate allow). Add a test that feeds adx=null and asserts the whole chain no-ops, so a future ADX fix is provably the thing that unblocks the gate.

**[infra] T4 — Add a health-check that REPORTS ADX-null rate.** Per operator-prinsipp (health reports, never auto-disables): surface "% of cycles with adx=null" in the morning briefing. If this had existed, the 97.7% would have been caught months ago instead of via a forensics dig. No behaviour change.

**[Karri] T5 — Decide whether the M15 EMA-fallback (`599a052`, `REGIME_DIRECTION_M15_FALLBACK_ENABLED`) should be the interim direction source until T1 lands.** It is the only built path that makes the gate bite without fixing ADX. It is a trade-decision-altering switch → Karri-gated. Frame: "do we want a coarser M15-EMA direction NOW, or wait for proper ADX+H4 direction (T1)?"

**[Karri] T6 — Re-validate the gate's value claim.** phase-status L277 claims "+$2-3k protection / 30d". That estimate assumed the gate fires. Since it has fired 0 times (5 gates in shadow-mode, L213: "Ingen av disse har stoppet en trade siden deploy"), the claim is untested. Re-derive after T1/T5 with real direction data.

**[operator] T7 — Flip decision, gated behind T1.** Do NOT enable `REGIME_DIRECTION_GATE_ENABLED` until ADX is non-null in prod (verify via T4 health-check or `/firm/strategy-states` showing adx != null). Enabling it now buys nothing (it can't bite) and creates false confidence that counter-trend mean-reversion is being blocked.

**[operator/infra] T8 — Re-check the broader Twelve-Data XAU/USD outage blast radius.** `fetchADX/fetchRSI/fetchMACD/fetchBBands/fetchStochastic/fetchATR/fetchEMA` are ALL Twelve-Data-only with silent `return null`. The live pull shows atr also null. This is bigger than one gate — multiple regime/strategy inputs are silently null. Audit which of these have OANDA/computed fallbacks and which are dead. (Likely a separate lane, flag it.)
