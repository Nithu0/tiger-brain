---
title: Trend-pause detection (trend-pause-bevissthet)
tags: [library, concept, trend-pause, karri-owned]
type: source
status: distilled
claude_priority: P0
owner: Karri (strategy)
constraint: do not extend without Karri review
last_updated: 2026-05-13
---

# Trend-pause detection

## The concept

A **trend-pause** is the brief consolidation that interrupts an active directional move on a higher timeframe. The market does not reverse — it takes a breath. From the bot's perspective, candle structure during the pause locally resembles range/mean-reversion. A naive mean-reversion strategy reads the pause as a reversal opportunity, fires counter-trend, and gets stopped when the trend resumes.

This is distinct from a **trend-flip**: a genuine reversal that ends the directional regime. Discriminating pause from flip is the core difficulty. A detector that confuses the two will either let losses through (false-pause = real flip, block missed) or block valid reversal entries (false-flip = real pause, signal missed).

## Why it matters in Nexus

Karri's 12.5 katastrofedag-analyse (`docs/ops/katastrofedag-analyse-2026-05-12.md`) found the three worst trading days (21.4, 22.4, 6.5) all shared this pattern. Cross-strategy round-1 audit (`05_cross_strategy_regime.md`) extended the finding: counter-trend trades in TRENDING regime cost -$5 954 across 90 days at 35% win-rate; with-trend trades made +$2 261. The bot systematically fires reversal into directional days.

The signature is sharper still: in 13 TRENDING-tagged trades, even the 5 with-trend trades lost (-$1 997, 0% win). This suggests the problem extends beyond direction to **timing-inside-trend** — entries fire too early in pullback structure, not only on the wrong side. The pause concept may need to cover both.

## Karri's stated hypothesis (verbatim, 12.5)

> "Sterk H1+ trend → kort pause / range-bound → bot leser pause som mean-reversion opportunity → fyrer counter-trend → trend gjenopptas → trade SL'es."

Three days fit the textbook signature:
- **21.4 (-$7 119):** $84 net down-day, bot fired 10 LONG entries into the descent. Classic knife-catching during pullbacks.
- **22.4 (-$3 722):** Mild chop, $48 range, bot LONG'd intraday lows systematically.
- **6.5 (-$211 net but -$2 484 streak):** Clear up-day +$105, bot flipped direction 4 times in 3 hours during mid-day consolidation, taking 5 losses in sequence.

The cross-cutting nature — all 4 active strategies (S1-S4) participating on 5.11 — is what makes this a **regime primitive** problem, not a single-strategy bug.

## Currently implemented as proxy

Two env-gated, default-OFF gates partially address the symptom while awaiting a true detector:

1. **`regime_direction_gate`** (`docs/strategy/proposals/2026-05-11_regime_direction_gate.md`) — classifies H4 direction (UP/DOWN), hard-rejects counter-trend mean-reversion signals in TRENDING regimes. Code is wired in `apps/worker/src/firm/gates/regime-direction-gate.ts`. Status: pending Karri activation. Round-2 forensics (`11_regime_direction_gate_forensics.md`) confirmed gate body never executes today because `REGIME_DIRECTION_GATE_ENABLED` is unset on Railway. Also lacks a `gate_decisions` write path — observability gap separate from activation.

2. **`daily_trade_cap`** (`docs/strategy/proposals/2026-05-12_daily_trade_cap.md`) — hard cap on cross-strategy daily trades, default 6. Catches overtrading days even when bias is mixed; 6 of 7 historical ≥8-trade days were net losers. Complementary, not a pause-detector — addresses volume, not state.

Both proxies were authored by Claude under Karri's hypothesis, neither activated in production as of 2026-05-13.

## Data substrate

Empirically testable from existing tables (152 trades, 2026-04-16 → 2026-05-13):

- `simulated_orders` — per-trade outcomes + portfolio_regime_at_entry (sparse: only 18/156 trades tagged)
- `ohlcv_candles` (XAUUSD, 15min + 1H) — reconstruct impulse-vs-pause structure
- `gate_decisions` — what gates have written; `regime_direction_gate` currently writes 0 rows
- `cycle_states` — `portfolio.context.state.regime` + `regimeDirection` (post-2026-05-11)
- `processed_signals` — counter-factual: which raw signals would a detector have suppressed?

## Open questions (Karri-owned)

These are unresolved and belong in Karri's next review pass. Listed without proposed answers:

1. What candle structure technically counts as a pause? (range-contraction, body-size, Bollinger narrowing, other?)
2. Which timeframe carries the trend and which the pause? (H1 trend / M15 pause is the inferred shape but not Karri-stated)
3. How does the detector discriminate pause from genuine flip?
4. Does the concept need to extend to entry-timing within trend, given the 0/5 with-trend losses in TRENDING regime?
5. Hard gate, soft filter, or regime-state input fed to strategies?
6. Should the two existing proxies activate now, sequentially, or be held until the dedicated detector ships?

## Cross-references

- Memory: `~/.claude/projects/-home-nithu-code-ai-assistent/memory/project_trend_pause_concept.md` (the binding instruction)
- Source: `docs/ops/katastrofedag-analyse-2026-05-12.md` (the three-day textbook cases)
- Quantified evidence: `00-claude-inbox/nexus/2026-05-13/05_cross_strategy_regime.md` (90-day cross-strategy audit)
- Proxy forensics: `00-claude-inbox/nexus/2026-05-13/round2/11_regime_direction_gate_forensics.md`
- Proxy proposals: `docs/strategy/proposals/2026-05-11_regime_direction_gate.md`, `docs/strategy/proposals/2026-05-12_daily_trade_cap.md`
- Regime taxonomy: `docs/ref/regimes.md` (market regime vs risk regime; pause-detection belongs to market regime axis)

## Note for future Claude sessions

This concept is **Karri-owned**. Do not propose detector designs, timeframe choices, or activation rules in this file or related session work. Operator memory `project_trend_pause_concept.md` is binding. Claude's role is: organize state, prepare data substrate, run counter-factuals on existing data when asked, ship observability fixes for the proxies. Detector design waits for Karri.
