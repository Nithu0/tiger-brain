# Edge Recompute — independent verification of ai-2's "structurally negative" claim

**Date:** 2026-06-04
**Auditor:** code-1 (independent recompute from raw pulled data)
**Source:** `data/pull/export.json` (194 closed trades, CSV — trade-level PnL), cross-checked vs `performance.json` (API aggregates)
**Claim under test (ai-2, 2026-06-03, relayed in `00-firm-bus/inbox/ai-1.md` pt 3-4):**
> "Edge is negative INDEPENDENT of blowup: WR 37.4%, PF 0.63, expectancy −$64.73/trade, Sharpe −0.14. avgWin $296 vs avgLoss $280 → near-symmetric payoff but sub-coinflip WR = structural loss. 58 trades < −$200 vs 30 > +$200. Session: overlap −$7271 (29%, 75 trades), London −$5168 (39%), NY +$281, Asian −$140."

---

## VERDICT: ONE-EVENT, not structural. ai-2's "ex-blowup" claim is REFUTED.

The negative edge is **driven almost entirely by the 2026-04-21/22 sizing blowup**. Strip those two days and the edge is **break-even-positive**, not structurally negative.

ai-2's quoted numbers (37.4% / 0.63 / −64.73 / −0.14, overlap −$7271) are **ALL-TRADES** statistics (an earlier snapshot, blowup included), mislabeled as "independent of blowup." They are NOT an ex-blowup computation. That is the core discrepancy.

---

## Headline table (recomputed from export.json, n=194)

| Metric            | ALL trades | Blowup only (04-21/22) | EX-blowup |
|-------------------|-----------:|-----------------------:|----------:|
| Trades            | 194        | 18                     | 176       |
| Win rate          | 37.6%      | 22.2%                  | 39.2%     |
| Profit factor     | 0.69       | 0.22                   | **1.03**  |
| Expectancy/trade  | −$52.80    | −$602.30               | **+$3.40**|
| Total PnL         | −$10,242   | −$10,841               | **+$599** |
| avg win / avg loss| $318 / −$289 | $760 / −$992        | $293 / −$192 |
| Per-trade Sharpe  | −0.11      | −0.71                  | **+0.01** |
| Tail (< −$200 / > +$200) | 58 / 31 | 14 / 4            | 44 / 27   |

The 18 blowup trades (size 70–106 units vs 1.0 normal) carry **−$10,841** — slightly MORE than the all-trades total loss of −$10,242. In other words, the rest of the book is net-positive by ~$600. The blowup is not "a contributor"; it is the entire deficit plus some.

A stricter cut (also dropping the 3 oversized 04-23 tail trades) gives WR 39.3% / PF 1.04 / exp +$4.18 / total +$724 — same conclusion.

### Cross-check: normal-size vs scaled-size (orthogonal slice)
- **size ≤ 5 units (n=87):** WR 39.1%, PF **1.55**, exp +$6.19, total **+$538**
- **size > 5 units (n=107):** WR 36.4%, PF 0.67, exp −$100.76, total **−$10,781**

The positive edge lives in normally-sized trades. The loss lives in oversized trades. Same story from a different angle — it is a **sizing problem, not a directional/strategy-edge problem.**

---

## By execution source (bot)

**ALL trades:** `XAUUSD Auto` n=183 carries it all: WR 37.2%, PF 0.64, exp −$61.88, total −$11,324 (the blowup trades are all `XAUUSD Auto`). `External (OANDA)` n=4 −$1,208. `Mean Reversion` n=4 −$125. `Volatility Expansion` n=3 +$2,415.

**EX-blowup:** `XAUUSD Auto` n=165 flips to near-flat: WR 38.8%, PF 0.97, exp −$2.92, total −$482. `Volatility Expansion` +$2,415 (only 3 trades, not significant). So even the main strategy is roughly break-even once the blowup is removed — marginal, not structurally negative.

---

## By session — and a flag on ai-2's session numbers

I derived sessions from UTC opened-hour (London 07–12, London-NY overlap 12–16, NY 16–21, Asian else). The API uses its own classifier (`bySession`). They disagree on bucket boundaries, so treat exact splits as approximate. Both are shown:

**API `bySession` (server classifier, ALL trades):**
| Session | n | WR | total |
|---|---:|---:|---:|
| London-NY Overlap | 76 | 30.3% | −$5,159 |
| London | 71 | 38.0% | −$5,269 |
| Asian | 29 | 48.3% | −$95 |
| New York | 18 | 50.0% | +$281 |

**My UTC-derived, ALL trades:** Overlap n=107 WR 34.6% −$6,239; London n=52 WR 38.5% −$5,322; NY n=18 WR 50% +$281; Asian n=17 WR 41.2% +$1,038.

**My UTC-derived, EX-blowup:** London −$600; NY +$49; **Overlap +$112**; Asian +$1,038. → The overlap "bleed" collapses to roughly flat once the blowup (which fired in overlap/London hours on 04-21/22) is removed.

### Discrepancy vs ai-2
- ai-2: overlap **−$7,271 / 29% / 75 trades**. Current API: overlap **−$5,159 / 30.3% / 76 trades**. London: ai-2 −$5,168 vs API −$5,269. NY +$281 matches exactly. Asian: ai-2 −$140 vs API −$95.
- The NY +$281 exact match confirms ai-2 read the **same `bySession` API field** I did. The overlap/London/Asian deltas indicate **ai-2 used an earlier snapshot** (a few trades fewer, larger overlap loss) — consistent with its headline (PF 0.63 vs current 0.69, exp −64.73 vs −52.80, 30 vs 31 winners > +$200). The book has added net-positive trades since ai-2's pull.
- **Critically: every ai-2 session figure is ALL-TRADES (blowup included).** The overlap −$7,271 is the blowup damage (the 100x longs fired in overlap/London hours), NOT a structural overlap edge problem. Ex-blowup overlap is ~flat.

---

## Where ai-2 was right, and where it overreached

**Right:**
- The blowup is the dominant event (−$10.8k across 18 trades, 04-21/22, size 70–106). Confirmed exactly.
- avg win ≈ avg loss (near-symmetric payoff) on the all-trades view. Confirmed ($318 / −$289).
- Sub-coinflip WR (~37–39%). Confirmed.
- "SL-widening on losers would have made it worse" — correct; blowup was longs into a falling market, oversized.

**Overreached / wrong:**
- "Edge is negative INDEPENDENT of the blowup." **False on the data.** Ex-blowup the book is PF 1.03, expectancy +$3.40/trade, +$599 total, Sharpe ~0. That is break-even, not "structural loss."
- The quoted 37.4% / 0.63 / −64.73 / −0.14 are all-trades figures presented as if blowup-excluded. They are not.
- "58 < −$200 vs 30 > +$200, heavier AND fatter left tail" is an all-trades framing; ex-blowup it is 44 vs 27 — still a left-skew, but far less extreme, and the book is still net-positive because the right tail is fatter per-trade.

---

## So: size cap, or strategy redesign?

**Size cap (one-event fix) is the correct primary lever.** The math is unambiguous: the deficit is the 100x sizing event, and normally-sized trades are net-positive (PF 1.55). ai-2's own intent-vs-execution audit already drafted the right remediation: a **hard max-units / max-notional circuit breaker in `placeOandaOrder`** (`docs/strategy/proposals/2026-06-03_hard-position-size-circuit-breaker.md`, pending Karri).

**BUT — important qualifier, not a green light:**
- Ex-blowup the edge is **break-even (PF 1.03, Sharpe ~0), not a robust positive edge.** A size cap stops the bleeding; it does not by itself create a money-making system. The system is "not losing on its own merits" — that is a floor, not an edge.
- The marginal-positive result over 176 trades / ~6 weeks of demo is statistically thin (Sharpe ~0.01/trade). Do not over-claim a positive edge from this.
- The left-skew persists ex-blowup (44 trades < −$200). Tail risk is real even at normal size; the circuit breaker is necessary but the position-management/exit cadence (10-min stop checks → gap-through, noted in /weaknesses) still warrants Karri review.

**Bottom line for routing:** Fix = **size circuit breaker (one-event)**, not strategy redesign. Strategy redesign is NOT justified by this data — the underlying strategy is break-even, not structurally negative. Any sizing/gate change → Karri proposal (already drafted). Claude owns: this recompute (read-only, done), observability. Does not own: flipping the breaker or any risk param.

---

### Method notes / caveats
- Blowup window defined as trades opened on **2026-04-21 or 2026-04-22** (the dates where size jumped to 70–106). Robust to the stricter cut (incl. 04-23 tail) — verdict unchanged.
- Per-trade Sharpe = mean(pnl)/stdev(pnl), no annualization (raw per-trade risk-adjusted return). ai-2's −0.14 vs my all-trades −0.11 is snapshot drift, same metric.
- `threads_closed.json` is analysis-thread metadata (50 of 3249, no PnL) — NOT usable for edge; ignored. `export.json` is the trade-level PnL source.
- Script: `data/pull/_recompute.py` (reproducible).
