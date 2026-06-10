---
title: "The Simplest Orderflow Trading Model"
channel: Fabervaale ENG
url: https://www.youtube.com/watch?v=cUTsoU-15Tc
video_id: cUTsoU-15Tc
published: unknown
ingested: 2026-06-01
duration_seconds: 1486
transcript_source: auto-sub (en)
transcript_path: _library/youtube/fabervaale-eng/cUTsoU-15Tc.transcript.txt
confidence: 0.8
hype_flags: [product-promo-deepcharts, NQ-equities-not-XAU, neural-net-claim-unverified]
tags: [youtube, trading, ORB, opening-range, breakout, mean-reversion, regime, take-profit, distilled, fabervaale]
---

# The Simplest Orderflow Trading Model (ORB / IVB)

## Core idea
Opening Range Breakout (Crabel lineage): mark the high/low of the first 15/30/60 min of the cash session; first side to break "won the battle" and sets directional bias for the day. He layers two improvements: (1) volume-profile framing of the range to find the real order-block / invalidation level, and (2) a statistical model plotting the highest-probability excursion as TP1 (~65-70% hit) and a lower-probability TP2.

## Concrete techniques
- **Invalidation, not arbitrary stop**: stop is the value-area-low / range edge that, *if accepted (candle close beyond)*, kills the thesis — tightening R:R from ~1:1 to ~1:2 / 1:2.5 vs a naive ORB stop.
- **Regime split on the SAME structure**: while price is *inside* the range → fade the edges (mean-revert on absorption/exhaustion); only *after* a confirmed breakout → trend-follow toward the protection level. Explicit "consolidation vs directional" distribution stat drives which mode is allowed.
- **TP from data, not hope**: statistically-derived protection level = highest-probability day target; keep a runner only beyond it with eyes open about the lower hit-rate.
- Re-entries allowed on retrace-to-broken-level ("reload"), stop below the level.

## Mapping to Nexus
- Direct analogue to Nexus ORB module (`docs/ref/orb.md`, `_library/trading/strategies/orb_xau.md`) — London/NY 30-min ranges, 5m close confirmation.
- **Addresses the session-breakout SL flaw head-on**: his stop = invalidation-on-close *inside* structure, not the opposite range edge. Nexus's flaw is stop = opposite edge = retracement zone (`_library/trading/strategies/session_breakout.md`, 43% SL_TP hits / 30d). A "close-beyond-invalidation" stop rule is a candidate fix.
- **Inside-range = mean-revert, post-break = trend-follow** is the same regime gate Nexus needs for trend-pause; gives a concrete, non-discretionary trigger (range membership + confirmed-close break).
- Data-driven TP1/TP2 ~ Nexus could derive session-level TP distribution from its own raw-data persistence rather than fixed R:R.

## Contradiction / support
- SUPPORTS ORB direction; PARTIALLY CONTRADICTS current session-breakout stop placement (proposes invalidation-close stop instead of opposite-edge).
- Heavy product promo (deepcharts) + equities-microstructure assumptions; the *structural logic* transfers to XAU, the orderflow tooling does not (no equivalent NQ-style footprint feed in Nexus).

## Suggested library candidates
- `_library/trading/lessons/` — "ORB stop should be invalidation-on-close inside structure, not the opposite range edge (session-breakout SL-flaw candidate fix)" (HIGH — feeds a Karri proposal)
- `_library/trading/strategies/` — note on orb_xau: add "inside-range fade vs post-break trend" regime split + data-derived TP1/TP2

## Related
- [[orb_xau]]
- [[session_breakout]]
- [[trend_pause_detection]]
