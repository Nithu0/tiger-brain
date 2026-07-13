# Gate-loosening verdict — risk_level + mean_revert (adversarial)

**Date:** 2026-06-13
**Author:** Claude (adversarial judge, READ/ANALYSIS ONLY)
**Re:** Karri proposal `2026-06-11_loosen_risk_level_meanrevert_gates.md` (uncommitted, judged from summary + live data)
**Data source:** live `/decision-funnel?days=45` + `/shadow/per-strategy` + `/shadow/recent` (prod API, demo broker, balance $89.3k)

---

## TL;DR

- **risk_level_high loosening: cautious YES to an A/B.** Live data corroborates Karri's n (~24 vs his 23) and the edge is genuinely robust — Wilson 95% CI on WR is [63%, 93%], floor well above the ~40% break-even. Smallest blast radius. Do this FIRST and alone.
- **mean_revert_block loosening: NO, not yet.** n=106 confirmed exactly, but the 44% WR Wilson CI is [35.2%, 53.8%] — the **lower bound sits BELOW break-even (40%)**. The edge is statistically indistinguishable from zero/negative. And this is the gate that exists because of the 04-21-style post-impulse blowups. Re-opening it for a coin-flip-grade edge is the single biggest risk in the whole proposal.
- **Biggest single risk:** the mean_revert edge Karri reports is a **cross-strategy aggregation artifact**. The +R is almost entirely on `xau-session-breakout` (a continuation strat where the gate is arguably mis-firing), while on the actual `xau-mean-reversion` strat the same blocks were *correctly* saving losses. Loosening globally to capture session-breakout's blocked R would also re-admit the genuine post-impulse counter-trend trades the gate was built to stop.

---

## 1. Independent sanity-check of the claims

### n counts — CONFIRMED (live funnel, 45d / 30d window)

| Gate | Karri's n | Live `would_reject` | Match? |
|---|---|---|---|
| risk_level_high | 23 | 24 (reason=`risk_level_high`; +2 `risk_level_elevated`) | yes (1-off = window edge) |
| mean_revert_block | 106 | 106 (reason=`mean_revert_block`, hardRejected=106) | exact |

Both numbers are real and current. No inflation. Note: the *whole* risk_level gate would-rejects 53 and hard-rejects 26 — Karri correctly scopes his claim to the `risk_level_high` subset (n~24), not the full gate. Good.

### risk_level_high: +1.02R @ 83% WR on n=23 — MEANINGFUL, not fragile

- Wilson 95% CI on WR = **[62.9%, 93.0%]**. Even the pessimistic floor (63%) is far above the ~40% break-even at the shadow resolver's 1.5R:1R payoff. The edge survives the small-n haircut.
- Caveat: the shadow outcome resolver appears to use fixed TP/SL R-multiples (rows resolve to uniform +1.5R or -1R, not path-realistic). So "+1.02R/trade" is a *clean-fill* estimate; real fills/slippage will shave it. But directionally this gate is over-blocking good trades. Believable.
- Cross-strat note: in the raw rows, `risk_level_high` blocks on `xau-session-breakout` were 18/18 @ 100% WR (+1.5R) — that's where the edge lives. On `xau-mean-reversion` the same block was 3/3 @ 0% WR (i.e. blocking was *correct* there). So the risk_level loosening, like mean_revert, is strategy-dependent — but its aggregate CI floor is high enough that an A/B is defensible.

### mean_revert_block: +0.52R @ 44% WR on n=106 — EDGE NOT ESTABLISHED

- Wilson 95% CI on WR = **[35.2%, 53.8%]**. The **lower bound (35.2%) is below the 40% break-even.** Statistically you cannot reject "this gate's blocked signals are break-even-or-worse." Karri's own "WR-fragile" label understates it: at this n the edge is not significant.
- The raw rows make it worse: the positive R is concentrated on `xau-session-breakout` short signals tagged "short signal aligns with impulse" — these resolved 100% WR in shadow. That is suspicious: it suggests the gate's *impulse-alignment* logic is firing on session-breakout continuation entries where the "mean-revert ahead" thesis doesn't hold, OR the shadow resolver is optimistic on those. Either way, the edge is not the gate being wrong about *mean-reversion risk* — it's the gate being applied to a *continuation* strategy.

---

## 2. The known history & tail risk (mean_revert)

The `mean_revert_block` gate (`apps/worker/src/firm/gates/mean-revert-gate.ts`) blocks signals where price has moved ≥2.0 ATR in 90 min and the signal direction *aligns with* that impulse — i.e. chasing into a stretched move that's statistically due to revert. This is the exact 04-21-class setup: enter late into an impulse, get the snap-back, eat a full stop (or worse if the reversal is violent).

**Worst case if loosened:** a post-impulse continuation trade goes through, the move reverts hard, and because impulse environments are high-ATR, the stop distance is wide and the reversal can gap past it. The shadow's "-1R" accounting hides this — real post-impulse reversals can be >1R adverse excursion before the stop fills, especially around the news-driven impulses this gate targets. The +0.52R "edge" is an average that includes these; the *tail* is what the gate was built to truncate, and an average-R backtest is exactly the wrong lens for a tail-risk gate.

**Verdict:** trading a not-statistically-significant +0.52R average against a re-opened fat left tail is a bad trade. Hold mean_revert.

---

## 3. Recommendation

### A/B: YES for risk_level, NO (defer) for mean_revert. Do them SEQUENTIALLY, not both.

Agree with the instinct that **risk_level is cleaner and smaller blast radius** — confirmed by the data (high CI floor, n~24 vs 106, fewer signals admitted per week so slower/safer accumulation). Start there.

### A/B design (risk_level_high first)

- **Mechanism is already built — no behavior flip needed to keep collecting.** The gate soft-logs every decision to `gate_decisions` (`would_reject` vs `hard_rejected`) and `shadow_signals` already resolves outcomes for blocked rows. So a **pure shadow A/B requires no live change at all**: keep `RISK_LEVEL_HARD_GATE_ENABLED=true`, let the would-reject rows accumulate resolved outcomes, and read the realized R off `shadow_signals` weekly. This is the zero-risk arm and it's already running.
- **If Karri wants a *live* arm** (actually take the trades to confirm fills/slippage don't kill the edge): flag stays **default-unchanged in code**; flip `RISK_LEVEL_HARD_GATE_ENABLED=false` on Railway only after operator OK. Rollback is a 30s env flip. Live arm only after the shadow arm clears the bar below.

### Required sample size + duration

- To detect a **+1.0R** edge (risk_level's claimed magnitude), sd≈1.4R, 80% power, α=.05: **~31 signals per arm.** risk_level_high produces ~24 blocks / 45d ≈ ~4/week. So **~8 weeks** of shadow accumulation to reach a real decision — OR faster if you accept the already-strong CI and treat the existing n=23 shadow set as the decision (it already clears break-even at 95%).
- Pragmatic call: the risk_level shadow evidence is *already* decisive (CI floor 63% >> 40%). I'd let it run **2–3 more weeks** to push n past ~35 for comfort, then decide. No need for 8 weeks unless you want the live-fill confirmation.
- For **mean_revert**, to detect the claimed **+0.5R**: **~123 signals per arm.** At ~106 blocks / 45d (~2.4/day) that's ~7–8 weeks *per arm* just to power the test — and the current n=106 already sits at CI floor below break-even. **Don't A/B it now. Re-evaluate only if a larger shadow sample lifts the WR CI floor above 40%.**

### Sequencing

1. risk_level_high shadow A/B (already live) → decide in 2–3 wks.
2. If risk_level loosening is approved and shows no regression after 2–3 wks live → *then* revisit mean_revert with the larger sample you'll have by then.
3. Never both at once — you'd lose attribution if the daily-trade-cap or circuit-breaker fires.

---

## 4. Cross-check: do the caps still contain a loosened gate? YES.

Confirmed downstream rails are independent of these two gates and remain ON:

- **Position-size circuit breaker** (`POSITION_SIZE_CIRCUIT_BREAKER_ENABLED=true`, default ON): clamps any trade to ≤80 units / ≤300% notional, called LAST before broker submit (`strategy-execution.ts:981`). Live shadow rows show it actively clamping (`size=64u notional=318% exceeds cap`). A loosened entry gate cannot produce an oversized position.
- **Per-strategy daily loss cap** ($800/strat, `daily_loss_reached`): live rows show it firing (`realized loss $1058 ≥ limit $800`). Caps per-strat bleed.
- **Portfolio daily-loss cap** (`daily_loss_cap_hit: PnL ≤ -$200`): live rows confirm active — firm-wide circuit breaker independent of entry gates.
- **News blackout + spread_gate_proxy**: both firing in live rows. Karri's recommendation to KEEP spread_gate + per-strategy cap is correct and these are orthogonal to the two gates under review.

So even the worst-case loosened-mean_revert trade is bounded in *size* and *daily aggregate loss*. The residual risk is **per-trade adverse excursion on a wide-stop post-impulse reversal** (a single trade can still lose its full clamped stop, and the loss cap only stops *additional* trades after the day is already red). That's the gap the caps do NOT close — which is exactly why mean_revert should stay.

---

## Single biggest risk (call-out)

**mean_revert_block's reported edge is a cross-strategy aggregation artifact, and its WR confidence interval includes break-even.** Loosening it to harvest `xau-session-breakout`'s blocked R would also re-admit genuine post-impulse counter-trend entries on the mean-reversion strat — the 04-21 blowup pattern — for an average edge that is not statistically real. The caps bound size and daily loss but NOT single-trade reversal excursion. **Keep mean_revert as-is; only risk_level_high warrants the A/B, and that one's shadow evidence is already nearly decisive.**
