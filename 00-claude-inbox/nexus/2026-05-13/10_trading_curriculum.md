---
title: "10-source trading curriculum for Nexus knowledge base"
date: 2026-05-13
purpose: "Build Claude into a domain specialist on ORB / mean-reversion / regime-gated XAUUSD systems"
context_filter: "XAUUSD only, M5–H1 entries, London + NY sessions, systematic ensemble"
live_question: "Trend-PAUSE vs trend-FLIP detection (Karri's open research item)"
---

# 10-source curriculum — Nexus ingestion plan

Strict filter applied: every entry must link to ORB, mean-reversion (S4), trend/regime gating, or XAUUSD-specific dynamics. No generic TA, no psychology fluff, no retail-bro content.

## Summary table

| # | Title | Author / Channel | Format | Bucket | Prio |
|---|---|---|---|---|---|
| 1 | The Logical Trader (ACD Method) | Mark Fisher | Book | ORB | P0 |
| 2 | Day Trading with Short Term Price Patterns & Opening Range Breakout | Toby Crabel | Book | ORB | P0 |
| 3 | Street Smarts | Linda Raschke & Laurence Connors | Book | ORB / MR | P0 |
| 4 | Algorithmic Trading: Winning Strategies and Their Rationale | Ernest Chan | Book | Mean-reversion | P0 |
| 5 | Building Winning Algorithmic Trading Systems (+ Quantified Strategies blog) | Kevin Davey / Oddmund Groette | Book + blog | Mean-reversion / robustness | P1 |
| 6 | Systematic Trading | Robert Carver | Book | Regime / sizing | P0 |
| 7 | Long-Term Secrets to Short-Term Trading (2nd ed.) | Larry Williams | Book | Regime / commodity microstructure | P1 |
| 8 | Commodity Trading Advisors / "Gold as a safe haven" papers (SSRN) | Baur & Lucey 2010, Baur & McDermott 2010 | Papers | Gold-specific | P1 |
| 9 | The New Case for Gold | James Rickards | Book | Gold macro context | P2 |
| 10 | Robot Wealth YouTube + Quantified Strategies YouTube | Kris Longmore / Oddmund Groette | YouTube | Systematic / quant | P1 |

---

## Detailed notes

### 1. The Logical Trader — Mark Fisher (P0, ORB)
- **Why it matches**: ACD is the canonical opening-range breakout framework. Nexus has multiple ORB variants — Fisher is the source they all descend from. Operator's S1/S2 logic should be cross-referenced against ACD's A-up/A-down and pivot range.
- **Extract**: chapters on ACD setup definitions (A, B, C, D values), pivot range computation (3-day rolling), failed-breakout playbook (this is the trend-PAUSE seed material). **Skip** the floor-trader anecdotes and the option-overlay section — not relevant.
- **Quality**: dense, sometimes repetitive; Fisher writes like a pit trader because he is one. Extract definitions cleanly, ignore narrative.

### 2. Day Trading with Short Term Price Patterns and Opening Range Breakout — Toby Crabel (P0, ORB)
- **Why it matches**: the empirical foundation for ORB. Crabel catalogues NR4/NR7, opening-range expansion, inside-day setups — all directly applicable to XAUUSD's London opening behaviour. S4 mean-reversion can use Crabel's "stretch" concept inverted.
- **Extract**: pattern catalogue (NRn, IDnr4, "stretch" calculation, opening-range expansion thresholds), the section on "follow-through day" filters. **Skip** Crabel's personal-diary entries; the book is half pattern reference, half journal, and the journal half doesn't generalise.
- **Quality**: short on prose, dense on patterns. Book is out of print and expensive — get PDF, transcribe pattern definitions only.

### 3. Street Smarts — Linda Raschke & Laurence Connors (P0, ORB + MR hybrid)
- **Why it matches**: bridges ORB and mean-reversion. "Turtle Soup" is a failed-breakout fade (directly relevant to telling trend-PAUSE from trend-FLIP). "80-20" and "Holy Grail" are regime-gated continuation plays. Maps onto Nexus's S1–S4 stack precisely.
- **Extract**: Turtle Soup + Turtle Soup Plus One (the fade-of-failed-breakout logic — feed this into Karri's pause-vs-flip question), Holy Grail (ADX-gated pullback entry → relevant to regime gate design), Anti pattern. **Skip** the section on options-based hedges.
- **Quality**: every setup has explicit rules. Highest signal-per-page of the three ORB books. Start here if time-constrained.

### 4. Algorithmic Trading: Winning Strategies and Their Rationale — Ernest Chan (P0, mean-reversion)
- **Why it matches**: S4 just went live 2026-05-13. Chan's book is the cleanest treatment of stat-arb / mean-reversion that survives out-of-sample. Cointegration, half-life of reversion, Bollinger-mean-reversion all sit here.
- **Extract**: chapter 2 (mean-reversion of stationary series — half-life calculation via Ornstein-Uhlenbeck), chapter 3 (Bollinger-band MR with z-score sizing), chapter 7 (regime switching with HMMs — directly applicable to trend/range gate). **Skip** the inter-day-pairs equities sections; XAUUSD is single-instrument.
- **Quality**: terse, mathematical, with Matlab code (translate mentally). High signal density.

### 5. Building Winning Algorithmic Trading Systems — Kevin Davey + Quantified Strategies blog (Oddmund Groette) (P1, MR + robustness)
- **Why it matches**: Davey is one of very few authors who treats walk-forward, Monte Carlo, and parameter robustness rigorously — Nexus has 478 tests but no formal walk-forward pipeline. Quantified Strategies blog has dozens of XAUUSD/gold-specific backtests with code.
- **Extract from Davey**: walk-forward optimisation chapter, Monte Carlo for equity-curve confidence intervals, "10 questions to kill a strategy" checklist. **Extract from QS blog**: any post tagged "gold" or "XAUUSD" + their mean-reversion-on-daily-close studies. **Skip** Davey's autobiography sections.
- **Quality**: Davey writes plainly. QS blog is signal-rich but cherry-picked — treat as hypothesis source, not validation.

### 6. Systematic Trading — Robert Carver (P0, regime / sizing)
- **Why it matches**: gold-standard reference for systematic position-sizing, instrument-diversification, and forecast combination. Nexus already runs a multi-strategy ensemble — Carver's forecast-combination math is what makes ensembles not blow up. Volatility-targeting is directly applicable to XAUUSD sizing.
- **Extract**: chapters on forecast scaling/capping (essential for combining S1–S4 outputs), volatility targeting via rolling stdev, the "speed limit" concept (max Sharpe per cost), and his treatment of regime via trend-filter speeds (16/64, 32/128, etc — feed into trend-PAUSE detection). **Skip** the portfolio-of-instruments chapters (we're single-instrument).
- **Quality**: best-in-class clarity. Carver is rigorous and operationally honest about what does/doesn't work. P0 because it shapes the ensemble math.

### 7. Long-Term Secrets to Short-Term Trading (2nd ed.) — Larry Williams (P1, regime + commodity microstructure)
- **Why it matches**: Williams is a commodity guy first (gold, grains, currencies). His TDW/TDM seasonal patterns and "specialist trap" sections are genuinely useful for XAUUSD intraday microstructure. The 2nd edition adds walk-forward content the 1st lacked.
- **Extract**: chapters on day-of-week / day-of-month bias (does XAUUSD reliably mean-revert Tuesday into Thursday? — test on Nexus data), the volatility-breakout sizing logic (Williams' "volatility breakout" predates ORB literature and complements Fisher's ACD), open-vs-close gap behaviour. **Skip** the "trading gurus I knew" stories.
- **Quality**: more anecdotal than Carver/Chan but commodity-native — that's the value vs equity-centric authors.

### 8. SSRN gold papers (Baur & Lucey 2010 "Is Gold a Hedge or a Safe Haven?", Baur & McDermott 2010 "Is gold a safe haven? International evidence") (P1, gold-specific)
- **Why it matches**: regime detection on XAUUSD requires understanding gold's bimodal personality — risk-off hedge vs commodity. These papers quantify the regime split using equity-correlation analysis. Feeds the macro-context layer of regime gating.
- **Extract**: methodology for splitting gold-return regimes by VIX/equity-stress thresholds, asymmetric-correlation findings (gold correlates negatively to equities in crash regimes only), the dollar-correlation conditional results. **Skip** the literature-review sections.
- **Quality**: peer-reviewed, replicable. Short (20–30 pages each). High signal per minute. Free on SSRN.

### 9. The New Case for Gold — James Rickards (P2, gold macro context)
- **Why it matches**: not a trading book, but Nexus trades a politically/monetarily charged instrument. Understanding why gold moves on Fed/CB-buying/dollar headlines helps Claude parse macro-event impact (Nexus already has macro-event Discord wiring).
- **Extract**: chapters on central bank gold flows (PBoC/Russia accumulation cycles), the dollar-vs-gold inverse-correlation breakdowns. **Skip** the Rickards-prediction sections (he's directionally biased; treat as context not signal).
- **Quality**: P2 because it's narrative not quantitative. Read after the quant stack is in place.

### 10. Robot Wealth YouTube (Kris Longmore) + Quantified Strategies YouTube (Oddmund Groette) (P1, systematic / quant)
- **Why it matches**: both channels are explicitly systematic and code-forward. Robot Wealth has multi-part series on volatility regimes, trend-following design, and edge decay — directly relevant to Nexus's foundation-gate logic. QS YouTube companions the blog with backtests visualised.
- **Extract from Robot Wealth**: "Trend following" series (regime gates, vol-scaling), "Crypto/FX mean reversion" videos (logic transfers to XAUUSD), edge-decay episodes. **Extract from QS**: any video tagged "gold", "mean reversion daily", "opening range". **Skip** their general-market-commentary livestreams — those are noise.
- **Quality**: Longmore is ex-quant fund; signal density high. Groette is prolific but repetitive — pick the systematic-design videos, not the "10 strategies" listicles.

---

## Honest tradeoffs

- **Crabel is hardest to source** but the patterns are timeless. If unavailable, Raschke covers ~60% of the Crabel material with clearer rules.
- **Chan ch 7 (HMM regime switching)** is mathematically heavy. If Claude needs faster wins on trend-PAUSE detection, start with Carver's filter-speed combination first, then promote to HMM.
- **Larry Williams** is the weakest link academically but commodity-native — keep him for the day-of-week/seasonality angle, drop if time-bound.
- **Gold papers (Baur & Lucey)** are the only academically peer-reviewed sources in this list. Worth disproportionate weight.

## What's NOT here (and why)
- Murphy/Pring/Edwards-Magee — generic TA, already encoded in Claude's weights.
- Mark Douglas / Van Tharp — psychology; no Nexus gap to fill (Nexus is autonomous, no human-in-loop emotion).
- "Quantitative Trading" (Chan vol. 1) — superseded by his 2nd book listed above.
- Tradeciety / generic FX YouTube — retail-targeted, low signal density.
- Jack Schwager (Market Wizards) — interview format, narrative not systematic.

## Ingestion priority order (suggested reading sequence)

1. **Week 1 (P0)**: Raschke (Street Smarts) → fastest setups-to-code conversion.
2. **Week 2 (P0)**: Carver (Systematic Trading) → re-architect ensemble math.
3. **Week 3 (P0)**: Fisher (ACD) + Crabel (patterns) in parallel — feeds ORB variants.
4. **Week 4 (P0)**: Chan (Algorithmic Trading) ch 2, 3, 7 — S4 validation + regime HMM.
5. **Month 2 (P1)**: Davey + QS blog (robustness), Williams (commodity microstructure), Baur & Lucey papers, YouTube channels transcribed.
6. **Month 3 (P2)**: Rickards (macro context, low priority).

---

Word count: ~1,420. Within budget.
