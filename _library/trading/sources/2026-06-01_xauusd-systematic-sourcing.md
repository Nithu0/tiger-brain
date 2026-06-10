---
title: XAUUSD systematic/algorithmic learning sources — sourcing note (PROPOSE)
type: sourcing-note
status: proposed
created: 2026-06-01
author: claude (research sweep)
project: nexus
related:
  - "[[karri_quotes_corpus]]"
  - "[[12-youtube/_queue/HOW-TO-DROP-URL]]"
tags: [trading, sourcing, systematic, xauusd, regime, books, youtube, papers, propose]
note: >
  PROPOSE-style. Does not overwrite curated files. Operator/Karri to vet before
  promoting any channel into 12-youtube/_channels.yaml or buying books.
---

# XAUUSD systematic sourcing — 2026-06-01

Scope: sources that fit **systematic / algorithmic gold + forex intraday** trading and
Nexus's real open problems — trend-pause vs trend-flip, regime detection, structurally-correct
stop placement (not opposite-range-edge), position sizing, and not over-trading in
compression/consolidation.

Explicitly **rejected the previous lead**: the prior YouTube channel was NQ-futures
discretionary orderflow, prop-firm-framed — wrong instrument, discretionary, hype-adjacent.
This note hunts for the opposite: rules-based, backtested, quant-leaning, evidence-first.

Honest meta-finding up front: **genuinely good systematic-gold YouTube is thin.** The signal
lives in (1) a couple of quant-interview/backtest channels that are instrument-agnostic but
methodologically right, and (2) **books + papers**, which are where the real Nexus-relevant
depth is. Don't expect a single channel that does "systematic XAUUSD session strategies"
well — it mostly doesn't exist without hype attached.

---

## 1. YouTube / video — ranked, honest

### #1 (best) — Better System Trader (Andrew Swanscott)
- URL: https://www.youtube.com/@BetterSystemTraderPodcast
- Channel ID: `UCXtFh3dcGQ1wfORL1tZxKrQ` · also https://www.youtube.com/channel/UCXtFh3dcGQ1wfORL1tZxKrQ
- Why it fits Nexus: interview-based, **systematic/algorithmic only** — building, validating,
  adjusting strategies; market **regimes & reducing drawdowns**; trend following, breakout,
  mean reversion, day trading; entries/exits/trade-management; risk & money management.
  Guests are the actual canon Nexus should learn from: Perry Kaufman, Kevin Davey,
  Nick Radge, Linda Raschke, Adam Grimes, Jerry Parker, Larry Connors, Jack Schwager.
  Directly addresses the regime / over-fit / trade-management problems Nexus has.
- Signal-to-noise: **HIGH.** Not instrument-specific (no dedicated XAUUSD), and interview
  format means depth varies by guest, but essentially zero prop-firm hype. Best single
  YouTube fit by a wide margin.

### #2 — Quantified Strategies (Oddmund Groette / Sammy)
- URL: https://www.youtube.com/channel/UCBP0QGCn6bKRHJRsEmh7Q5A
- Site: https://www.quantifiedstrategies.com/
- Why it fits Nexus: every strategy is **backtested with stated rules + stats** — strong on
  **mean-reversion** (RSI(2), rubber-band/ATR snap-back) which maps to Nexus S4, plus
  channel/breakout patterns. Also has explicit material on **HMM market-regime detection**
  (trend vs range → switch model). Methodology-first, anti-narrative.
- Signal-to-noise: **MEDIUM-HIGH.** Caveats: mostly equities/ETF (SPY/QQQ) not gold/FX so
  edges won't transfer 1:1; clickbait-y win-rate titles ("77% WinRate!"); some backtests are
  short-sample / in-sample-flattering. Mine for *method and study design*, not for ready edges.

### #3 (honorable mention, not a channel) — Top Traders Unplugged
- URL: https://www.toptradersunplugged.com/podcast/ (audio; YouTube clips exist)
- Why: deep systematic **trend-following / managed-futures** interviews (incl. Robert Carver).
  Strongest on the *trend-pause vs trend-flip* + *don't-widen-stops* mindset at a portfolio
  level. Audio-first, long-form — lower video utility, high conceptual value.
- Signal-to-noise: HIGH conceptually, but it's a podcast not a tight video channel.

**Bottom line for category 1:** queue **Better System Trader** (#1) and **Quantified
Strategies** (#2). Skip anything that frames itself around prop-firm payouts or "orderflow
secrets". There is no high-quality channel doing *systematic XAUUSD intraday specifically* —
accept that and get the method from these + the books below.

---

## 2. Books — ranked by what each gives Nexus

Buy legitimately — links are publisher/Amazon. No piracy PDFs.

### #1 (highest value to Nexus) — Robert Carver, *Advanced Futures Trading Strategies* (2023)
- What it gives Nexus: the **single most on-point book for the trend-pause / sizing /
  no-widening problem.** 30 fully-tested strategies; continuous (not binary) trend filters
  including **trend-strength** so a pause is sized-down rather than flipped; **volatility
  scaling for position sizing**; risk-managed exits *without* moving stops to the opposite
  range edge. This is the methodological backbone for several of Nexus's open problems.
- Buy: Harriman House (publisher) https://www.harriman-house.com/advancedfuturestradingstrat ·
  Amazon https://www.amazon.com/Advanced-Futures-Trading-Strategies-Robert/dp/0857199684
  (ISBN 9780857199683)

### #2 — Robert Carver, *Systematic Trading* (2015)
- What it gives Nexus: the framework layer — how to combine rules, avoid over-fitting,
  size by volatility target, set forecast strength, and *stick to the system*. Read before
  #1. Pairs with the trend-pause hypothesis (continuous vs binary regime signals).
- Buy: Harriman House · Amazon (ISBN 9780857194459)

### #3 — Ernest Chan, *Algorithmic Trading: Winning Strategies and Their Rationale* (2013)
- What it gives Nexus: rigorous **mean-reversion vs momentum** treatment (S4 relevance),
  stationarity/cointegration tests, **Kalman filter** for dynamically-updated fair price
  (useful for stop/anchor placement that isn't the static range edge), and an explicit
  chapter on **how regime changes break strategies + risk management**. Emphasis on simple
  linear strategies as an antidote to over-fitting.
- Buy: Wiley https://onlinelibrary.wiley.com/doi/book/10.1002/9781118676998 ·
  Amazon https://www.amazon.com/Algorithmic-Trading-Winning-Strategies-Rationale/dp/1118460146
  (ISBN 9781118460146)

### #4 — Mark Fisher, *The Logical Trader* (2002)
- What it gives Nexus: the **ACD method** — pivot/opening-range with A/C points and a
  time-of-day session structure. Direct conceptual parent of Nexus's ORB / session-breakout
  and a cleaner way to think about breakout confirmation vs false-break in a session frame.
- Buy: Wiley · Amazon (ISBN 9780471584032)

### #5 — Larry Connors & Cesar Alvarez, *Short Term Trading Strategies That Work* (2008)
- What it gives Nexus: concrete, backtested **mean-reversion** rules (RSI(2), pullback
  filters, "buy the dip in an uptrend") — direct S4 reference and a sanity check on
  over-trading filters (only act on stretched conditions). Equity-index biased; treat as
  method, not transferable edge.
- Buy: TradingMarkets/Connors Research; widely on Amazon (ISBN 9780981923802)

### #6 — Ernest Chan, *Quantitative Trading* (2008)
- What it gives Nexus: the operational hygiene layer — backtest pitfalls (look-ahead,
  survivorship, data-snooping), Sharpe/drawdown, building/running an automated business.
  Less about edges, more about *not fooling yourself* — relevant given Nexus's short
  calibration samples.
- Buy: Wiley · Amazon (ISBN 9780470284889)

### #7 — Van Tharp, *Trade Your Way to Financial Freedom* (2nd ed.)
- What it gives Nexus: **R-multiples + position sizing** as the lever that dominates expectancy;
  the language ("1R risk", expectancy = avg R × win-rate) Nexus already uses for result_r.
  Light on systematic specifics; valuable for the sizing/expectancy framing.
- Buy: McGraw-Hill · Amazon (ISBN 9780071478717)

### #8 (RARE — flag) — Toby Crabel, *Day Trading with Short-Term Price Patterns & Opening Range Breakout* (1990)
- What it gives Nexus: the **statistical origin of ORB** — NR4/NR7 narrow-range
  compression → expansion, opening-range-breakout stretch logic. Directly addresses
  "don't over-trade in compression; trade the *expansion* out of it" — squarely a Nexus
  problem.
- **Flag: out of print, genuinely rare.** First-edition hardcovers (Traders Press, 1990)
  command premium/collector prices on AbeBooks/ThriftBooks; supply is thin and erratic.
  Don't overpay — the NR4/NR7 + ORB-stretch ideas are well summarized in Crabel-derived
  literature and in Kaufman (below). Acquire the *concepts* first; buy the book only if a
  fair copy appears.
  - Used: https://www.abebooks.com/9780934380171/ · https://www.thriftbooks.com/w/day-trading-with-short-term-price-patterns-and-opening-range-breakout_toby-crabel/261589/

### Additions I'd argue Nexus is missing
- **Perry Kaufman, *Trading Systems and Methods* (Wiley, 6th ed.)** — the encyclopedic
  reference for **regime/volatility-adaptive systems**, trend vs range classification,
  breakout + ORB families, and adaptive parameters. Best single book for the
  regime-detection gap on the practitioner side. (ISBN 9781119605355)
- **Marcos López de Prado, *Advances in Financial Machine Learning* (Wiley, 2018)** — for
  the ML/microstructure gap: **structural-break / CUSUM features** for regime onset,
  meta-labeling + bet-sizing (a principled answer to "should I size this trade and how big"),
  and honest backtesting (purged CV, deflated Sharpe). Heavier/quant; high ceiling.
  (ISBN 9781119482086)

**Single highest-value book: Robert Carver, *Advanced Futures Trading Strategies*** — it is
the closest published treatment of Nexus's exact open problems (continuous trend-strength
instead of flip/pause binary, vol-scaled sizing, exits that don't widen to the range edge).

---

## 3. Papers / freely-available sources — regime / change-point

### #1 — Nystrup et al. (or equivalent) asset-class-independent HMM regime-switching
- arXiv:2107.05535 · https://arxiv.org/pdf/2107.05535
- Relevance: regime-switching model **independent of asset class** for risk-adjusted return
  prediction across commodity / currency / equity / fixed-income via HMM. Closest free,
  rigorous treatment of the trend-vs-range *state* problem that maps onto XAUUSD.
- Honest caveat: HMMs **lag** regime onset — they confirm continuation of an already-changed
  regime more than they predict the switch. Read with that limitation in mind (it's exactly
  the trend-pause-vs-flip ambiguity Nexus faces).

### #2 — "Improving Portfolio Performance Using a Novel Method for Predicting Financial Regimes"
- arXiv:2310.04536 · https://arxiv.org/pdf/2310.04536
- Relevance: explicitly diagnoses and tries to fix the HMM "can't predict the switch, only
  the continuation" weakness. Directly on-point for *anticipating* a trend pause/flip rather
  than reacting late.

### #3 — Rule-based bull/bear regime identification (robust, non-ML)
- "Identifying bull and bear market regimes with a robust rule-based method" — Research in
  International Business and Finance (ScienceDirect; abstract free, PDF may be paywalled):
  https://www.sciencedirect.com/science/article/abs/pii/S0275531921002245
- Relevance: peak/trough rule-based regime labeling (PS / LT / PZ algorithms) — a
  **transparent, non-black-box** alternative for trend-vs-range that's easier to wire into
  Nexus gates than an HMM, and good for *labeling* training data.
- Free practitioner companion (change-point / PELT, Bayesian online CPD): see the
  insightbig.com change-point walkthrough and arXiv:2407.16376 (Bayesian autoregressive
  online change-point with time-varying params) for implementable CUSUM/PELT/BOCPD methods.

**Single highest-value paper: arXiv:2107.05535** (asset-class-independent HMM) — most
directly transferable to XAUUSD regime state; read alongside 2310.04536 for the
"predict-the-switch" limitation.

---

## Overall single highest-value recommendation
**Robert Carver, *Advanced Futures Trading Strategies*** (book) — it targets Nexus's exact
open problems (continuous trend-strength, vol-scaled sizing, no-widening exits) more directly
than any video or paper. If only one source is actioned, action this. Closest free runner-up
for the regime gap: arXiv:2107.05535.

---

## What was queued
- `12-youtube/_queue/2026-06-01T1400-better-system-trader.url` — Better System Trader (#1)
- `12-youtube/_queue/2026-06-01T1401-quantified-strategies.url` — Quantified Strategies (#2)
(Top Traders Unplugged left unqueued — audio podcast, not a clean video-ingest fit.)

## Sources
- Better System Trader: https://www.youtube.com/@BetterSystemTraderPodcast
- Quantified Strategies: https://www.youtube.com/channel/UCBP0QGCn6bKRHJRsEmh7Q5A · https://www.quantifiedstrategies.com/
- Top Traders Unplugged: https://www.toptradersunplugged.com/podcast/
- Carver (Harriman House): https://www.harriman-house.com/advancedfuturestradingstrat
- Chan (Wiley): https://onlinelibrary.wiley.com/doi/book/10.1002/9781118676998
- Crabel (used): https://www.abebooks.com/9780934380171/
- arXiv:2107.05535 · arXiv:2310.04536 · arXiv:2407.16376
- ScienceDirect rule-based regimes: https://www.sciencedirect.com/science/article/abs/pii/S0275531921002245
