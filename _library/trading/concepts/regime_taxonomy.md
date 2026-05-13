---
title: Regime taxonomy (XAUUSD) — 5 market regimes + direction sub-axis
source: Nexus codebase + docs/ref/regimes + A2 null-reason tags + Carver/Chan
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 5
claude_priority: P0
tags: [library, concept, regime, market-regime, risk-regime, direction, taxonomy]
status: distilled
---

# Regime taxonomy (XAUUSD)

Two orthogonal axes drive every gate, sizing decision, and strategy-fitness check in Nexus: **market regime** (what is price doing?) and **risk regime** (how dangerous is sizing right now?). Conflating them is the #1 source of gate-wiring bugs (`docs/ref/critical-rules.md`). A third sub-axis — **direction** — only refines the TRENDING market regime.

## Axis 1 — Market regime

Published by `firm/portfolio-brain.ts` on `xauusd.portfolio.context`. Stored as `simulated_orders.portfolio_regime_at_entry`. Canonical helpers in `firm/regimes.ts`.

Five operational values plus two infrastructure values (`unknown`, the legacy `BREAKOUT`/`LOW_VOLATILITY`/`EVENT_DRIVEN` labels still appear in `portfolio-brain.ts` but the canonical `MarketRegime` type in `firm/regimes.ts` standardises on the five below + `BREAKOUT`):

| Regime | Detection (`classifyRegime`) | Plain meaning |
|---|---|---|
| **TRENDING** | `ADX > 30`, fakeout-risk ≤ 0.5 | Directional move; ADX confidence scales linearly to 85 |
| **RANGING** | `ADX < 22` and not low-vol | Mean-reverting chop with clear edges |
| **HIGH_VOLATILITY** | `ATR > 7` AND `ADX > 25` | Wide bars with directional bias — vol-expansion home turf |
| **NOISY_CHAOTIC** | `ATR > 12` (extreme volatility) | Whipsaw, fakeout-risk 0.8, tradeability "poor" |
| **MIXED_NO_EDGE** | Default fall-through | None of the above triggers fired; +3 no-trade-bias |

Detection is a **composite** — ADX gates trend/range, ATR gates volatility, event-blackout overrides everything. No HMM, no learning; deterministic thresholds tuned by hand.

## Axis 2 — Risk regime

Published by `firm/analysis-agents.ts` on `xauusd.analysis.risk`. Stored as `simulated_orders.risk_level_at_entry`. Enum: `normal | elevated | high | extreme | unknown`. Drives Forge sizing multiplier, Shield extreme-veto, and event-policy sensitivity (pre-/post-NFP/FOMC/CPI).

**Why this is separate**: `TRENDING + extreme` is NFP-release mid-trend (Blade refuses); `RANGING + normal` is Asia-session-routine (scalping runs). One regime variable cannot carry both.

## Sub-axis — Direction (only meaningful when TRENDING)

Added 2026-05-11 per Karri's regime-direction-gate proposal. Published as a **separate field** on `xauusd.portfolio.context.state.regimeDirection` (UP / DOWN / null) — deliberately NOT folded into MarketRegime so existing consumers checking `regime === "TRENDING"` keep working.

Classifier (`firm/regime-direction.ts`) offers two methods via `REGIME_DIRECTION_METHOD`:
- `close_move` (default): H4 close vs close 4 bars ago (~16h). Cheap, no smoothing.
- `ema_slope`: sign of EMA(20) slope over last 6 H4 bars. Slower, less noisy.

**A2 null-reason tagging (round 3, 13.5)**: round-3 forensics found 97.7% of TRENDING blackboard messages had `regimeDirection=null` indistinguishably. The classifier now returns `{ direction, reason }` with 9 tagged null-paths (`not_trending`, `candles_empty`, `fetch_error`, `candles_not_array`, `candles_too_short_close_move`, `candles_too_short_ema_slope`, `non_finite_close`, `flat_close_move`, `flat_ema_slope`) plus `ok_up` / `ok_down`. Observability-only — no logic change. Lets us query WHY direction came back null.

## Strategy → regime fitness matrix

From `MANAGER_REGISTRY` in `portfolio-brain.ts` + S4 mean-reversion overlay:

| Strategy | Preferred | Blocked | Rationale |
|---|---|---|---|
| ORB (`xau-session-breakout`) | TRENDING, HIGH_VOLATILITY | RANGING, LOW_VOLATILITY | Breakouts need directional follow-through; range-edge fades are a separate edge |
| scalp-overlap (`xau-scalp-overlap`) | TRENDING, RANGING | NOISY_CHAOTIC, EVENT_DRIVEN | Mean-rev fits chop; chaos kills it (whipsaw across both sides of fair value) |
| session-breakout (`xau-session-breakout`) | RANGING (compressed) → break | LOW_VOLATILITY | Pre-break compression IS range; expansion is the trade |
| vol-expansion (`xau-volatility-expansion`) | TRENDING, HIGH_VOLATILITY | RANGING, LOW_VOLATILITY | ATR-spike follower; no expansion in compressed regimes |
| S4 mean-reversion (`xau-mean-reversion`) | NOISY_CHAOTIC, RANGING | TRENDING, HIGH_VOLATILITY | Counter-trend faders; trends are the textbook losing setup |
| HTF-trend / macro / news | TRENDING, EVENT_DRIVEN | RANGING, NOISY_CHAOTIC | Directional conviction in noise = drawdown |

## Dangerous combinations (the 11.5 13:14 disaster)

**TRENDING + mean-reversion strategy** is the cross-strategy round-1 finding: counter-trend trades in TRENDING regime cost -$5 954 over 90 days at 35% win-rate (`05_cross_strategy_regime.md`). 5.11 13:14 instance: all 4 active strategies (S1-S4) fired counter-trend during a directional day. Karri's hypothesis (`_library/trading/concepts/trend_pause_detection.md`): the bot reads brief consolidations inside an H1+ trend as mean-reversion opportunities, fires the fade, gets stopped when trend resumes.

## Karri's regime-aware gate concept

NOT "block all mean-rev in TRENDING" — too coarse, kills with-trend scalps. The intent (per `regime-direction-gate.ts` line 73–112):

- TRENDING + direction known (UP/DOWN) + strategy is mean-rev + counter-trend (SHORT-into-UP or LONG-into-DOWN) → **reject**.
- TRENDING + direction null → **allow** (no edge to act on). The future refinement, per the trend-pause-detection doc, is: allow only IFF an M15 fallback classifier agrees direction is undecidable.
- TRENDING + with-trend mean-rev → allow.
- Non-TRENDING → allow (gate dormant).

Gate is wired but `REGIME_DIRECTION_GATE_ENABLED` unset on Railway as of 2026-05-13. Karri owns activation.

## Cross-references

- Robert Carver, *Systematic Trading* — chapter on regime filters and the danger of overfit regime classifiers in TF-systems.
- Ernie Chan, *Algorithmic Trading*, ch. 7 — HMM-based regime detection as the principled (and more expensive) alternative to the ADX/ATR composite Nexus uses.
- `docs/ref/regimes.md` — internal canonical taxonomy.
- `_library/trading/concepts/trend_pause_detection.md` — pauses WITHIN a TRENDING regime; the open hard problem.
- `apps/worker/src/firm/regimes.ts` — enum + helpers single-source-of-truth.
- `apps/worker/src/firm/regime-direction.ts` — classifier + 9 null-reason tags.
- `apps/worker/src/firm/gates/regime-direction-gate.ts` — gate body, env-gated dormant.
