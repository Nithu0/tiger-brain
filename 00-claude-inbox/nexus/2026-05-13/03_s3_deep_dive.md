---
date: 2026-05-13
session: deep-dive S3 (Pullback-Continuation)
author: Claude
status: analysis-only (no code changes)
---

# S3 Pullback-Continuation — deep dive

## TL;DR (3 bullets)

- **Live "weakness" is misleading: S3 has produced ZERO live trades since flip-on 11.5 22:21 UTC.** Backtest baseline (6mo, sweet-spot config) was 28 trades / 57% WR / PF 6.38 / MaxDD $80 — none of that is realized yet. Operator perception of "weakened S3" cannot come from S3 itself; it's likely portfolio-aggregate read.
- **Funnel-reject mix (last 14d, 844 cycles):** session_not_allowed 40% + session_blocked 30% + vol_expansion_below_min 23% + pullback_too_deep 7%. **The strategy is alive but every cycle dies at filter 1–3.** No cycle ever reached impulse/RSI/signal-candle gates.
- **Karri's trend-pause hypothesis is not directly testable on S3 yet** (no entries). But the `pullback_too_deep` rejects (depths 6.5–7.8 ATR vs max 2.0) are the structural fingerprint of a trend-reversal day, *not* a healthy pullback — which is exactly what trend-pause detection would also flag. S3 is implicitly avoiding trend-break days. Good behavior, but it explains why volume is zero.

## S3 mechanics

- **File:** `apps/worker/src/firm/pullback-continuation/pullback-continuation-manager.ts` (+ `config.ts`, `index.ts`, tests). Wired in `orchestrator.ts:417` (Step 1h) and `strategy-execution.ts:141`.
- **Archetype:** "second-leg" continuation entry after impulse + structured pullback. Buy weakness in strength.
- **Pipeline (11 filters):** H1 trend regime → ADX ≥ 20 → vol expansion ≥ 1.05x → impulse ≥ 0.6 ATR → pullback 0.1–2.0 ATR → no trend-break → RSI 30–70 → session in {LONDON_ACTIVE, NY_CONTINUATION} → no-chase (≤ 3.0 ATR from EMA20) → strong signal candle (close in top/bottom 45%) → cooldowns/caps (60 min, 3/day, 2 losses/dir, 45-min gap).
- **Entry/exit:** break of signal-candle high/low; SL = swing-low − 0×ATR buffer; TP = 3R; BE at 0.5R; trail 1.0 ATR after 1R; time-stop 12h.
- **Sizing:** 0.5% risk (0.35% if ATR > 1.8x avg).
- **Gate dependencies:** standalone; no Trinn-A/FASE-5 gate dependency in current orchestrator branch. Decisions made entirely inside the manager.

## Baseline vs recent

| Metric | Spec (Karri 12.5) | Backtest 6mo (sweet-spot, commit 9561993) | Live since 11.5 22:21 UTC |
|---|---|---|---|
| WR | 45–65% | 57.1% | n/a (0 trades) |
| Avg R | 1.5–3R | PF 6.38 ⇒ implied high | n/a |
| Trades / period | — | 28 / 6mo (~1/wk) | 0 / 38h |
| MaxDD | — | $80 | n/a |
| Net $ | — | +$1048 | $0 |

Backtest claimed S3 is "sterkest av de 3 strategiene på risk-justering." Live data has not had a chance to confirm or deny — sample size is zero.

## Funnel breakdown (last 14d, 844 evaluations)

| Reject bucket | Count | Share |
|---|---|---|
| session_not_allowed (ASIA_*, LONDON_OR, LOW_PRIORITY) | 340 | 40% |
| session_blocked (OVERLAP_ACTIVE, NY_OR) | 252 | 30% |
| vol_expansion_below_min (0.7–0.85 < 1.05) | 193 | 23% |
| pullback_too_deep (6.5–7.8 ATR > 2.0) | 59 | 7% |
| impulse / RSI / signal-candle / no-chase / cooldown | 0 | 0% |

**Key observation:** the strategy has not even reached the alpha-discriminating filters (impulse / RSI / signal-candle). Sessions + vol-exp + structure shred the candidate set before judgment kicks in. The `pullback_too_deep` cluster (6.5–7.8 ATR) is highly unusual — pullbacks of that magnitude are not pullbacks; they're trend reversals. It maps to the 11.5–12.5 mean-revert / sell-off price action.

## Loss-pattern hypothesis (testable later)

Because there are no S3 losses to dissect, the hypothesis must be on **why edge is hidden, not lost**:

1. **Sessions filter is most restrictive constraint** — 70% of cycles die before any market math. LONDON_ACTIVE + NY_CONTINUATION are narrow windows; expanding to LONDON_OR / OVERLAP_ACTIVE might increase volume but breaks Karri spec.
2. **Vol-expansion threshold 1.05 + recent low-ATR regime** — 23% of cycles fail this. If ATR-regime stays compressed through next week, S3 stays silent.
3. **Trend-pause angle (Karri 12.5):** the 6.5–7.8 ATR pullbacks are the *structural opposite* of what S3 wants. S3 demands "impulse → controlled pullback → continuation." Recent tape has been "impulse → reversal." S3 correctly abstains — its silence is a feature, not a bug. This is indirect evidence supporting Karri: a market mode that breaks continuation-strategies is one S3 self-detects via the pullback-depth filter.

## Analysis-only next-steps

- **Wait for sample.** Hold position-management & filters unchanged for 14 days post-flip-on (target: 26.5). Re-evaluate WR/PF then.
- **Instrument:** add a daily aggregate of the funnel table above to morning briefing (no code change needed yet; query is the one in this doc).
- **Cross-strategy correlation:** if S2 (Breakout-Continuation) takes losses on days where S3 was completely silent, that pattern is direct evidence for Karri's trend-pause hypothesis. Worth tracking.
- **Do NOT** loosen sessions, ATR mult, or pullback-max to "get more trades." All three gates are doing their job — the absence of S3 trades on 11.5–12.5 katastrofedager is the strongest argument for keeping S3 strict.
- **Reviewer ask (Karri):** confirm whether S3 should remain silent during ≥4-ATR pullback regimes or whether to add a trend-pause-aware short-side variant.
