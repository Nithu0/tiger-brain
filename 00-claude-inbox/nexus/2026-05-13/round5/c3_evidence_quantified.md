# C3 — Cross-Strategy Direction-Flip: Historical Evidence

**Date**: 2026-05-13
**Scope**: simulated_orders, last 60 days (2026-04-16 → 2026-05-12), 156 closed trades
**For**: Karri's review of proposal `2026-05-13_cross_strategy_direction_flip.md`
**Status**: QUANTIFY ONLY — no implementation recommendation. Karri-decide.

---

## TL;DR

The gate would have blocked **4–20 trade-pairs** depending on window (15–120 min). **At every window EXCEPT 60 min, the flip-pairs were net profitable in aggregate** — i.e. blocking them would have cost money, not saved it. The 60-min window shows the strongest case (flip combined PnL = −$1,119 on named-strategies-only), driven almost entirely by one strategy-pair: `xau-scalp-overlap` ↔ `xau-volatility-expansion` (9 flips, −$2,536 combined).

**If Karri wants to ship a gate, X=60 min on that specific strategy-pair is the only window with empirical support. A blanket cross-strategy flip-block fires too few times and kills too many winners to justify.**

Sample is small (n=156 trades, 16 flip-pairs at 60-min cumulative). Statistical power is limited; Karri should weight this accordingly.

---

## Method

For each closed trade A, found every later trade B by a *different* strategy opened within X minutes of A. Counted the (A,B) pair as a "flip" if `direction(A) ≠ direction(B)`. Combined PnL = pnl(A) + pnl(B). Strategy identity = `COALESCE(strategy_id, bot_id)` so legacy firm-default trades (UUID bot_ids, 80 trades, mostly −$10.8k) are included as their own "strategy". A second view excludes those to isolate named-strategy behavior.

Cumulative windows (pairs *within* X min), not disjoint buckets.

---

## Table — All strategies (incl. legacy UUID bot)

| X (min) | total pairs | flip pairs | flip % | flip combined PnL | flip pair WR | all-pair WR | wins killed | losses avoided |
|---|---|---|---|---|---|---|---|---|
| 15  | 15 | 4  | 26.7% | **+$284**  | 50.0% | 20.0% | +$335   | −$51    |
| 30  | 21 | 7  | 33.3% | **+$438**  | 57.1% | 28.6% | +$1,109 | −$671   |
| 60  | 33 | 16 | 48.5% | **−$290**  | 43.8% | 30.3% | +$4,122 | −$4,412 |
| 90  | 44 | 18 | 40.9% | **+$1,498**| 50.0% | 38.6% | +$5,910 | −$4,412 |
| 120 | 51 | 20 | 39.2% | **+$2,371**| 55.0% | 43.1% | +$6,783 | −$4,412 |

## Table — Named strategies only (excludes UUID bot + oanda_backfill)

| X (min) | total | flip pairs | flip combined PnL | flip WR | wins killed | losses avoided |
|---|---|---|---|---|---|---|
| 15  | 7  | 3  | +$322   | 66.7% | +$335   | −$13    |
| 30  | 12 | 6  | +$476   | 66.7% | +$1,109 | −$633   |
| 60  | 23 | 14 | **−$1,119** | 42.9% | +$3,255 | −$4,374 |
| 90  | 33 | 16 | +$669   | 50.0% | +$5,043 | −$4,374 |
| 120 | 40 | 18 | +$1,542 | 55.6% | +$5,916 | −$4,374 |

---

## Where the 60-min signal comes from

Flip-pair breakdown at X=60min (all strategies):

| strategy pair | flip pairs | combined PnL |
|---|---|---|
| xau-scalp-overlap ↔ xau-volatility-expansion | 9  | **−$2,536** |
| xau-scalp-overlap ↔ xau-session-breakout     | 3  | +$621 |
| oanda_backfill ↔ xau-volatility-expansion    | 2  | +$829 |
| xau-orb ↔ xau-scalp-overlap                  | 1  | +$15 |
| xau-orb ↔ xau-volatility-expansion           | 1  | +$781 |

**One strategy-pair dominates** (`scalp-overlap ↔ vol-expansion`, 9/16 flips, −$2,536 combined). The other flips at 60 min are net positive. A pair-specific gate would isolate the signal; a blanket gate dilutes it.

---

## Honest caveats

1. **Blocking flips kills wins too.** At 60 min the gate would have prevented +$3,255 of winning flip-pairs to save −$4,374 of losing ones — net +$1,119, but a 75% loss-avoidance / 25% win-killing ratio is fragile. At 90/120 min the trade-off inverts and the gate becomes net-negative.
2. **n=156 trades, ~16 flip-pairs at the "best" window.** This is exploratory, not statistically conclusive. Wider 95% CIs would overlap zero.
3. **Causation unproven.** A flip-pair losing in aggregate doesn't prove that *blocking* one of the two would have saved that loss — the surviving trade may still have lost on its own. The analysis assumes both trades are forfeit (the gate's actual semantics in the proposal — need to confirm with Karri).
4. **Strategy mix is uneven.** xau-volatility-expansion = 41 trades, xau-orb = 5. Most flip pairs involve vol-expansion by sheer trade volume; this may not reflect "regime-confused" pairs but just "the one strategy that fires a lot".
5. **Legacy UUID bot (80 trades, −$10.8k)** distorts the all-strategies view. Excluding it (named-strategies table) is probably the cleaner read for proposal purposes.

---

## Recommended X-window for Karri's proposal

**X = 60 minutes**, scoped to the `xau-scalp-overlap ↔ xau-volatility-expansion` pair specifically. That's where the empirical case sits. A blanket cross-strategy gate at any other window is not supported by these 60 days of data.

Operator-decide whether the evidence is strong enough to ship at all. Karri-decide whether pair-specific is acceptable scope, or whether more data should be collected before any gate.
