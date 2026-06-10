---
title: "Exposing my Risk Management Protocol"
channel: Fabervaale ENG
url: https://www.youtube.com/watch?v=LQvv5xgy_ik
video_id: LQvv5xgy_ik
published: unknown
ingested: 2026-06-01
duration_seconds: 2040
transcript_source: auto-sub (en)
transcript_path: _library/youtube/fabervaale-eng/LQvv5xgy_ik.transcript.txt
confidence: 0.7
hype_flags: [prop-firm-context, NQ-not-XAU, self-promo, survivorship-bias-on-comp-results]
tags: [youtube, trading, risk-management, position-sizing, regime, distilled, fabervaale]
---

# Exposing my Risk Management Protocol

## Core idea
Risk geometry must be chosen for the *goal of the account*, not copied across contexts. He separates four regimes: hedge-fund (optimize risk-adjusted return / survivability, diversify by strategy), prop-firm eval (low-variance, high-win-rate, modest R:R ~1:1 to maximize pass probability), competition (controlled-variance, late-stage aggression for terminal rank), and personal (moderate fixed % per trade, 0.5-1.25%, multi-broker for tail risk).

## Concrete techniques
- Fixed, identical risk per trade. Never increase size to "recover" a losing streak — explicitly called the fastest path to ruin.
- For consistency-rule / drawdown-capped accounts, prefer high-win-rate + low R:R over "sniper" high-R:R-low-win-rate — the latter has fatter loss-streak tails that blow the account before the big winner lands.
- Pre-test regime fit per strategy before deploying risk: he runs trend-following / mean-reverting / volatility-breakout on parallel accounts and only scales the one matching the current regime.
- Automated hard caps: max risk per day, max risk per week, enforced at platform/execution level, not willpower.

## Mapping to Nexus
- Identical-% sizing + no martingale → already aligned with Nexus fixed-risk model; reinforces the existing `sl_cooldown` and `daily_trade_cap` rationale (see `docs/ref/position-metadata.md`).
- "Pick the strategy that fits the regime, discard the rest this period" → directly supports the regime-direction-gate / trend-pause hypothesis (`_library/trading/concepts/trend_pause_detection.md`, Karri-owned).
- Max-risk-per-day automated breaker → maps to a possible firm-level daily-loss kill (REPORT-only per operator-prinsipp 1; no auto-disable).

## Contradiction / support
- SUPPORTS current behavior (fixed sizing, daily caps, regime-awareness).
- Context caveat: most of his framing is prop-firm/competition (synthetic rules), NQ futures, discretionary scalping — not directly XAUUSD nor automated. Treat the *principles* as transferable, the *parameters* as not.

## Suggested library candidates
- `_library/trading/lessons/` — "fixed-fractional, no recovery-sizing; loss-streak tail kills before the big winner"
- `_library/trading/concepts/` — "risk geometry is goal-conditional (hedge / prop / comp / personal)"

## Related
- [[trend_pause_detection]]
- [[karri_mental_model]]
