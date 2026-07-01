---
title: Strategy / regime fit analysis — XAUUSD firm
date: 2026-05-11
window: last 30 days (live + signals); last 7 days for bleed focus
author: Claude (analysis-only, no strategy changes)
reviewer: Karri
status: observation
---

# Strategy / regime fit — last 30 days

## TL;DR

The 5-day PnL bleed is **not** a regime-fit problem on the 4 named firm-strategies (orb / scalp-overlap / session-breakout / volatility-expansion). Those strategies have produced almost **no closed live trades** in 30 days (8 trades total across them, all under bot wrappers). The bleed comes from **`XAUUSD Auto`** — the auto-managed bot — which closed 19 trades for **-$3,523** over the last 5 trading days (and **132 of its 135 closed trades have NULL `portfolio_regime_at_entry`**, meaning regime context wasn't even captured at entry-time → can't gate on something you don't read).

Headline: **regime taxonomy exists, but the live-trading bot is not consuming it.** That is the regime-fit angle on the bleed.

---

## 1. Strategy-fire counts last 30 days

Two streams populate `signals`:

### A. Named firm-strategies (firm-strategy:* source)

| Strategy | 30d signals | Days seen |
|---|---|---|
| `xau-volatility-expansion` | 37 | 8 |
| `xau-session-breakout` | 13 | 7 |
| `xau-orb` | 6 | 3 |
| `xau-scalp-overlap` | 5 | 2 |

These are sparse. Compare with the bot-wrapped engines:

### B. Bot-attributed signals (engines-v3 source, mapped via `bot_id`)

| Bot | 30d signals |
|---|---|
| XAUUSD Mean Reversion | 3,201 |
| XAUUSD Volatility Expansion | 2,764 |
| XAUUSD Session Breakout | 2,652 |
| XAUUSD Htf Trend | 1,666 |
| XAUUSD Scalp Overlap | 1,441 |
| XAUUSD Auto | 106 |

**Read:** the engines fire thousands of signals/strategy/30d, but they're flowing through the legacy engine path (`xauusd-engines-v3`), not the new firm-strategy path. Conversion to actual orders is the funnel that collapses — only **a handful become closed trades** in `simulated_orders`.

---

## 2. Per-strategy closed-trade PnL (30d)

| Bot (= strategy) | Trades | PnL | Avg | Win-rate |
|---|---|---|---|---|
| XAUUSD Volatility Expansion | 3 | **+$2,415** | +$805 | 100 % |
| XAUUSD Mean Reversion | 4 | -$125 | -$31 | 25 % |
| XAUUSD Auto | 135 | **-$8,905** | -$66 | 39.3 % |
| (oanda_backfill, no bot) | 3 | -$752 | -$251 | 33 % |

**Important nuance:** of XAUUSD Auto's -$8,905, **-$10,797 is `OANDA_BACKFILL`** (79 historical sync rows, not live executions). Live `OANDA_SL_TP` closes on Auto are -$269 over 40 trades. Live + stale-exit + recent reconciles = -$3,523 over the last 5 closed days. **The "5-day bleed" is the auto-managed bot, not the named strategies.**

Zero closed-trade activity in 30d for: `xau-orb`, `xau-scalp-overlap`, `xau-session-breakout`, `xau-htf-trend`, `xau-news-narrative`, `xau-macro-core`. They're all firing signals; nothing is reaching the order-book.

---

## 3. Regime breakdown (last 14 days, blackboard `xauusd.portfolio.context` → `state.regime`)

| Regime | 14d snapshots | Share |
|---|---|---|
| TRENDING | 2,253 | 33 % |
| RANGING | 2,029 | 29 % |
| NOISY_CHAOTIC | 829 | 12 % |
| MIXED_NO_EDGE | 715 | 10 % |
| HIGH_VOLATILITY | 705 | 10 % |
| LOW_VOLATILITY | 97 | 1 % |

Regime distribution is healthy and varied. The classifier is producing data — that's not the issue.

Day-by-day during the bleed window (4–10 May):

| Day | Dominant regime(s) | Daily PnL |
|---|---|---|
| 2026-05-10 | TRENDING (296) | -$433 |
| 2026-05-09 | LOW_VOLATILITY + TRENDING | -$564 |
| 2026-05-07 | RANGING (651) | -$352 + stale exits |
| 2026-05-06 | RANGING (395), TRENDING (122), HIGH_VOL (98) | -$167 |
| 2026-05-05 | TRENDING (601) | -$211 |
| 2026-05-04 | MIXED_NO_EDGE (302), HIGH_VOL (259), RANGING (148) | -$714 |
| 2026-05-03 | TRENDING (296), MIXED_NO_EDGE (104) | +$2,093 |

The bleed days span all regimes. There is no single "wrong-regime" day driving the loss.

---

## 4. Strategy × regime cross-tab (live trades, ex-backfill)

Only 11 live closed trades carry a non-NULL `portfolio_regime_at_entry` across the named strategies in 30d. That's the entire sample. With those caveats:

### XAUUSD Volatility Expansion (expected: HIGH_VOLATILITY / expanding ATR)

| Regime | Trades | PnL | Win | Verdict |
|---|---|---|---|---|
| RANGING | 2 | +$1,291 | 100 % | **out-of-regime, won anyway (sample N=2)** |
| MIXED_NO_EDGE | 1 | +$1,123 | 100 % | **out-of-regime, won (N=1)** |

Fired 3 trades total; **zero in HIGH_VOLATILITY**. The strategy is profitable but it's not firing in its intended regime — it's catching RANGING and MIXED_NO_EDGE entries. Sample too small to call this "wrong"; just note that the regime-classifier and the strategy's internal entry-trigger aren't co-firing.

### XAUUSD Mean Reversion (expected: RANGING)

| Regime | Trades | PnL | Win | Verdict |
|---|---|---|---|---|
| TRENDING | 2 | -$125 | 50 % | **out-of-regime, lost** |
| HIGH_VOLATILITY | 1 | $0 | 0 % | out-of-regime |

**100 % of Mean Reversion's regime-tagged fires are in TRENDING or HIGH_VOL.** It is the textbook out-of-regime fire pattern, but the absolute PnL impact is tiny (-$125) so it's not driving the bleed. Still — the `ranging_conviction` gate from `docs/ref/regimes.md` either isn't wired to this bot, or isn't gating hard enough.

### XAUUSD Auto (no declared regime preference — runs all 5 engines internally)

| Regime | Trades | PnL | Win | Verdict |
|---|---|---|---|---|
| TRENDING | 2 | -$433 | 50 % | live, lost |
| RANGING | 1 | -$564 | 0 % | live, lost |
| **null** | 53 | +$2,889 | 45 % | **regime NOT captured at entry** |

The auto-bot's recent live SL/TP losses are tagged in 2 different regimes; not enough to call a pattern. The dominant story is **132 of 135 closed trades have `portfolio_regime_at_entry = NULL`** → portfolio-brain's regime label is not making it into the order metadata for the auto-bot.

### XAUUSD Session Breakout / ORB / Scalp Overlap

**Zero closed live trades in 30 days.** They fire signals (2,652 / 1,441 / 1,441) but nothing converts. Either:
- Order-router downstream gate is rejecting them, or
- They're going through a path that doesn't land in `simulated_orders` (firm-strategy → consensus → never executed)

Cannot assess regime-fit on closed-trade evidence — sample is empty.

---

## 5. Top hypothesis for the 5-day bleed (regime-fit angle)

**The bleed is NOT a strategy-in-wrong-regime story.** It's a **"the live bot is not regime-aware"** story:

1. The named strategies (orb / scalp-overlap / session-breakout / vol-exp) **produce almost no live closed trades** — so their regime-fit is unmeasurable.
2. The only bot generating volume is `XAUUSD Auto`, which **doesn't record `portfolio_regime_at_entry` for 132 of 135 trades**. Whatever regime gates exist in `regimes.md` / `portfolio-brain.ts` are not being applied to its entries.
3. Backfill noise (`OANDA_BACKFILL`, -$10,797 over 79 rows) inflates the headline loss number. Real live SL/TP loss is small but persistent: -$269 over 40 trades, win-rate 47.5 % in that subset.

The actionable signal: **regime metadata pipeline is broken for the live-trading bot.** Anything tuned on `portfolio_regime_at_entry` (stale-exit, sizing, gates) is silently no-op for the bot doing 99 % of the live volume.

---

## 6. Per-strategy verdicts

| Strategy | Expected regime | Actual fires | Verdict |
|---|---|---|---|
| xau-orb | TRENDING session-open | 6 signals, 0 closed trades | **dormant** — cannot evaluate |
| xau-scalp-overlap | RANGING low-vol | 5 signals, 0 closed trades | **dormant** — cannot evaluate |
| xau-session-breakout | BREAKOUT after consolidation | 13 signals, 0 closed trades | **dormant** — cannot evaluate |
| xau-volatility-expansion (firm-strategy) | HIGH_VOLATILITY / expanding ATR | 37 signals, 3 closed via bot wrapper | **off-target but profitable on N=3** (fires in RANGING + MIXED_NO_EDGE, not HIGH_VOL) |
| xau-mean-reversion (bot) | RANGING | 4 closed, all in TRENDING/HIGH_VOL | **out-of-regime** but tiny PnL impact |
| XAUUSD Auto (auto-managed wrapper) | depends on internal engine | 135 closed, 132 NULL regime | **regime metadata not captured** |

---

## 7. Recommendations (observability / wiring, NO strategy changes)

> Strategy / risk changes go through Karri per `docs/strategy/proposals/`. These three are pure wiring / observability — fixing them only improves measurement.

1. **Fix regime stamping on `simulated_orders.portfolio_regime_at_entry` for the `XAUUSD Auto` bot path.** 132 of 135 trades NULL means the join from `portfolio-brain` blackboard topic → order insert is broken for this code path. Until this is fixed, every "regime-aware" gate / stale-exit / sizing rule is no-op for 99 % of live volume. Locate the insert site in `apps/worker/src/` and verify it reads the latest `xauusd.portfolio.context` row.

2. **Diagnose the signal → order funnel collapse for the 4 named firm-strategies.** Signals fire (37 / 13 / 6 / 5), zero land in `simulated_orders`. Pick one strategy (volatility-expansion has the most signals), trace one signal through `firm-consensus-v2` → order-router → execution. Is consensus voting them down? Is risk-gate rejecting? Is the bot-id mapping missing so the order never associates? Once we know the funnel break, we'll know whether regime-fit even applies.

3. **Strip `OANDA_BACKFILL` rows from PnL dashboards (or tag separately).** The -$10,797 backfill PnL is poisoning the "30-day strategy PnL" number on every report. These are historical-sync rows, not live trades. Add a `close_reason != 'OANDA_BACKFILL'` filter to the PnL widgets, or move them to a separate `historical_orders` view. Once filtered, the real recent-bleed signal becomes legible (-$2,089 over 5 days, all on `XAUUSD Auto`).

---

## Caveats

- Sample sizes are tiny for the named strategies (3 / 4 / 0 / 0 / 0 / 0 trades). Anything regime-fit-related is **directional only**, not statistically significant. Karri's review should weigh accordingly.
- This analysis cannot distinguish between "strategy fires correctly in its regime but loses anyway" vs "strategy fires in wrong regime" for orb / scalp-overlap / session-breakout — because they don't produce closed trades to measure.
- `regime_at_entry` (legacy, deprecated per `docs/ref/regimes.md`) was checked as fallback. All NULL where `portfolio_regime_at_entry` is also NULL. No hidden signal there.

---

## Data sources

- `signals` table — 30d, grouped by `source` and `bot_id`
- `simulated_orders` table — 30d, joined to `bots` on `bot_id`, broken down by `portfolio_regime_at_entry`
- `blackboard` table, topic `xauusd.portfolio.context` — `state.regime` field
- `docs/ref/regimes.md` — taxonomy + canonical helpers
