---
title: "The Only Liquidity Guide You'll Ever Need"
channel: Fabervaale ENG
url: https://www.youtube.com/watch?v=FawPrRUGNpk
video_id: FawPrRUGNpk
published: unknown
ingested: 2026-06-01
duration_seconds: 2676
transcript_source: auto-sub (en)
transcript_path: _library/youtube/fabervaale-eng/FawPrRUGNpk.transcript.txt
confidence: 0.65
hype_flags: [product-promo-heatmap, NQ-not-XAU, requires-L2-data-Nexus-lacks, webinar-pitch]
tags: [youtube, trading, liquidity, order-book, stop-placement, microstructure, distilled, fabervaale]
---

# The Only Liquidity Guide You'll Ever Need

## Core idea
Price moves where the path of least resistance is — i.e. where the *least* passive liquidity sits between price and the next level. Aggressive market orders (takers) consume resting passive liquidity (makers); when one side's resting volume is thin, price slides that way. A liquidity heat-map (historical DOM) visualizes where the heavy resting orders are.

## Concrete techniques
- Compute path of least resistance by summing passive limit volume above vs below price over N levels; the lighter side is the easier direction.
- Retail's naive "stops rest above the high / below the low" is "only 60-70% accurate" because it *guesses* liquidity location instead of reading it.
- Watch for "bid reload" in compression (sudden large resting size) — a big participant defending a level; algos front-run it.
- Distinguish absorption (aggressive orders hit a level with no price result) from exhaustion.

## Mapping to Nexus
- **Why the session-breakout SL flaw is a flaw, in microstructure terms**: stops placed at the obvious opposite range edge sit *in* the predictable liquidity pool, exactly where price is drawn / where they get swept (`_library/trading/strategies/session_breakout.md`). Confirms the qualitative argument with an order-book mechanism.
- Mostly NOT actionable for Nexus today: requires L2 / order-book / heat-map data that the OANDA spot-XAU feed does not provide. Flag as a *data-source gap*, not an implementable gate.

## Contradiction / support
- SUPPORTS the SL-flaw critique (stops in obvious liquidity get hunted).
- Largely informational for Nexus — no L2 feed. Useful as concept/explanatory, not as a strategy module.

## Suggested library candidates
- `_library/trading/concepts/` — "path-of-least-resistance / passive-liquidity asymmetry; why obvious-edge stops sit in liquidity pools" (MEDIUM — explanatory, no L2 data in Nexus)

## Related
- [[session_breakout]]
