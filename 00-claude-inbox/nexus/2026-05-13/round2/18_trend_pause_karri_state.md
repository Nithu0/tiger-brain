---
date: 2026-05-13
author: claude (round-2 agent 18 — state extractor, NOT solution proposer)
scope: organize what Karri has stated about trend-pause-bevissthet; identify data we hold to answer his open question; do NOT extend the hypothesis
owner: Karri (strategy)
constraint: per memory project_trend_pause_concept.md — "Don't propose own implementation — Karri reviewing this concept"
---

# Trend-pause-bevissthet — state of Karri's thinking

## Purpose of this doc

Karri owns the concept. This doc consolidates **what he has stated**, **what data we already have to test it**, **what currently exists as proxy** (and the round-2 forensics on those proxies), and **what is open for his next review session**. It does NOT contain a Claude-authored detector design. Next step belongs to Karri.

---

## What Karri has stated

Direct extractions (memory + katastrofedag-analyse + proposal review threads):

1. **Rotproblem-claim (12.5 memory `project_trend_pause_concept.md`):**
   > "All 3 verste dager (21.4, 22.4, 6.5) deler samme rotproblem — boten gjenkjenner ikke trend-pause/konsolidering, og flipper retning under pausen, catches false reversal."

2. **Mekanisme-claim (same memory):**
   > "Sterk H1+ trend → kort pause / range-bound → bot leser pause som mean-reversion opportunity → fyrer counter-trend → trend gjenopptas → trade SL'es."

3. **Cross-cutting-claim:** Karri identified this not as a single-strategy bug but as a missing **regime-state primitive** shared by legacy + TIER 3. Per katastrofedag-analyse-2026-05-12.md §"LÆRDOM" #1:
   > "Alle 3 katastrofer = strategien har ikke 'vet jeg er i trend / chop / pause?'-state. Når trend pauser, blir den blind."

4. **Proxy-claim:** Until a dedicated trend-pause-classifier exists, Karri authorized two proxies as partial mitigation: `regime_direction_gate` (blocks counter-trend mean-reversion in TRENDING regimes) and `daily_trade_cap` (caps total exposure). Both proxies are env-gated, default-OFF, awaiting his explicit activation.

5. **Reservation-claim:** Karri has explicitly NOT committed to a specific detector design. The concept is open for his framing. Memory: "Long-term: investigate dedicated trend-pause-classifier."

---

## What data we already have to answer his question

The detector question is empirically testable from existing tables. **Time range: 2026-04-16 → 2026-05-13** (152 closed trades, 25 trading days).

| Table / source | Fields | Use for testing trend-pause |
|---|---|---|
| `simulated_orders` | `opened_at`, `closed_at`, `direction`, `entry_price`, `exit_price`, `pnl_net`, `portfolio_regime_at_entry`, `risk_level_at_entry`, `strategy_id`, `execution_source` | Per-trade outcomes, regime tag at entry, with/counter-trend bias |
| `ohlcv_candles` (XAUUSD, 15min + 1H) | OHLC, volume | Reconstruct local impulse-vs-pause structure around each entry |
| `gate_decisions` | `gate_name`, `decision`, `would_reject`, `cycle_id`, `created_at` | What gates have observed last 30d (currently 6 gates writing rows) |
| `cycle_states` / blackboard archive | `portfolio.context.state.regime`, `regimeDirection` (post-2026-05-11) | Regime + direction tagging on each cycle |
| `processed_signals` | All raw signals before approval | Counter-factual: which signals would a trend-pause-detector have blocked? |

**Coverage gap:** `portfolio_regime_at_entry` only populated for 18 of 156 trades (field went live ~2026-05-10). For pre-2026-05-10 trades we must re-derive regime from cycle-state archive or candle data. Karri may want to backfill the column before deciding.

**Quantified evidence (from round-1 agent-5 cross-strategy audit, `05_cross_strategy_regime.md`):**
- TRENDING-regime trades (n=13, post-tag): 15.4% win, -$3 573 net
- **TRENDING + with-trend bias: 0/5 winners, -$1 997** ← the "even with-trend loses" signature that points to *timing-inside-trend*, not just direction
- Counter-trend on TRENDING-day, cluster trades: ~75% of post-26.4 cluster losses (-$3 573 of -$4 798)
- 2026-05-11 textbook day: 9 trades all pregime=TRENDING, 6 shorts into +$76 rally, all 4 active strategies participated

---

## What's currently implemented as proxy

### Proxy 1: `regime_direction_gate`

- **Code:** `apps/worker/src/firm/regime-direction.ts` + `gates/regime-direction-gate.ts`, wired in `strategy-blade.ts:133`
- **Proposal:** `docs/strategy/proposals/2026-05-11_regime_direction_gate.md` — Status `pending` (Karri review)
- **Mechanism:** Classifies H4 direction (UP/DOWN via close-move default, ema-slope optional) → hard-rejects mean-reversion signals counter to direction in TRENDING regimes
- **Round-2 forensics (agent 11, `11_regime_direction_gate_forensics.md`):**
  - Gate is deployed in code but `REGIME_DIRECTION_GATE_ENABLED` env-flag is unset on Railway worker → default `false` → gate body never executes → 0 rows in `gate_decisions`
  - There is no soft-log/observe-only path; flag-flip activates hard rejection immediately
  - Observability gap: even when flag is ON, the gate currently only `checks.push(...)` in memory; no `gate_decisions` row written (no `persistRegimeDirectionDecision()` helper exists)
- **Status for Karri:** intent matches his hypothesis; not yet live in production; observability hole means impact will not be auditable until a separate logging commit lands

### Proxy 2: `daily_trade_cap`

- **Code:** `apps/worker/src/firm/gates/daily-trade-cap-gate.ts`, commit `b8195b9`
- **Proposal:** `docs/strategy/proposals/2026-05-12_daily_trade_cap.md` — Status `implemented (env-gated, default-off — awaiting Karri activation)`
- **Mechanism:** Hard cap on cross-strategy daily trade count, default `DAILY_TRADE_CAP=6`. Catches "overtrading days" (6 of 7 days with ≥8 trades historically ended in net loss, -$13 225 total)
- **Live status (per agent 5 audit):** `daily_trade_cap` has 8 rows in `gate_decisions` last 14d but blocked 0 — flag is `true` somewhere in the chain but threshold has never been hit
- **Note:** this proxy is *complementary*, not a trend-pause detector. It catches volume even when bias is mixed (e.g. 22.4 chop). Karri framed it as "kapps total exposure", not "addresses the pause concept directly"

---

## The questions Karri still needs to answer

These are open. Claude does NOT pre-answer.

1. **Definition.** What technically counts as a "trend-pause"? Range-contraction inside a directional H1 sequence? Low-body candles after impulse? Bollinger-band narrowing after expansion? Karri has not committed to a primitive.
2. **Timescale.** Detector evaluated on which timeframe — M15, H1, or composite? The katastrofedag mechanism reads as H1-trend / M15-pause but this is an inference, not Karri's statement.
3. **Trend-pause vs trend-flip.** How does the detector distinguish pause (trend resumes) from genuine reversal (trend flips)? This is the harder question; a counter-trend block during a real flip would block the new direction's first valid trades.
4. **With-trend loss problem.** Round-1 agent-5 finding: TRENDING-with-trend lost 5/5 (-$1 997). Karri's stated hypothesis is *direction-flip during pause*; it does not directly explain why with-trend trades also lose in TRENDING regime. Does the concept need extension to **entry-timing within trend** (pullback structure), or is this a separate problem?
5. **Activation policy.** Once a detector exists, is it a hard gate (block all counter-trend signals while pause-flag is set), a soft filter (size-down), or a regime-state input fed to strategies?
6. **Proxy activation order.** Karri has both proxies pending. Should `regime_direction_gate` and `daily_trade_cap` be activated together, sequentially, or held until the dedicated detector ships?

---

## What Claude can prepare for Karri's next review session

Pure data-preparation tasks. None of these require new logic or design decisions; they assemble evidence Karri can read.

1. **Annotated trade log** — every closed trade since 26.4 with: portfolio_regime, regime_direction (back-derived from cycle archive where missing), with/counter-trend bias, candle structure ±30min around entry (M15 high-low-close sequence)
2. **Candle overlay for the 5 worst loss-cluster days** — H1 + M15 candles for 21.4, 22.4, 5.11, 5.12, 6.5 with trade entries marked, so Karri can eyeball where "pause" structure visually starts/ends
3. **Regime-direction backfill** — populate `portfolio_regime_at_entry` for pre-2026-05-10 trades from cycle-state archive (~138 trades currently NULL) so cross-cutting stats stop being underpowered
4. **Proxy-impact counter-factual** — given current env-flag state (both proxies off), simulate what `gate_decisions` would have written if both had been ON since 26.4. Pure replay, no behavior change.
5. **`processed_signals` mining** — which signals fired in TRENDING regimes counter to direction? Counter-factual block-list for Karri to inspect
6. **Observability fix for `regime_direction_gate`** — add `persistRegimeDirectionDecision()` mirroring `persistDailyCapDecision()` so the gate writes audit rows when flag flips. **Pure observability, no decision-logic change.** Operator-approved category per CLAUDE.md ("observability does NOT need a proposal").

These are all read-only or observability-only. They give Karri the substrate for his next decision without committing to a detector shape.

---

## Next step is Karri's, not ours.

Operator memory binding: `project_trend_pause_concept.md` → "Don't propose your own implementation — Karri reviewing this concept." This doc deliberately stops at organizing the state. The detector primitive, the timescale choice, the activation policy, and the relationship between pause-detection and with-trend-timing all belong to Karri's next pass.

Recommended hand-off: send Karri this doc + agent-5's cross-strategy audit + agent-11's regime_direction_gate forensics. Three documents, ~3500 words combined, give him: the hypothesis as stated, the data confirming the pattern, and the proxy state. He decides definition + design.
