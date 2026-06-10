---
title: "Watch me Manage a -10.000$ trading Session"
channel: Fabervaale ENG
url: https://www.youtube.com/watch?v=jasv3L-d8ZE
video_id: jasv3L-d8ZE
published: unknown
ingested: 2026-06-01
duration_seconds: 721
transcript_source: auto-sub (en)
transcript_path: _library/youtube/fabervaale-eng/jasv3L-d8ZE.transcript.txt
confidence: 0.75
hype_flags: [NQ-not-XAU, discretionary, dollar-figures-for-engagement]
tags: [youtube, trading, drawdown, compression, regime, stop-loss-streak, distilled, fabervaale]
---

# Watch me Manage a -10.000$ trading Session

## Core idea
A consolidation/compression session is the *single worst environment* for a trend-following / breakout model — "every movement got absorbed in the first two hours... you can take 10 stop loss." The session is salvaged not by a better entry but by (a) accepting drawdown, (b) NOT over-exposing, and (c) waiting for the one range-breaking expansion move that pays for the whole streak.

## Concrete techniques
- Recognize compression early (price absorbed at highs/lows, shrinking ranges) and downshift: "this is not the day to trade trend following."
- During the streak: reduce size, move stops to breakeven on the recovering position, do not revenge-add.
- The edge in chop = endurance: survive the stop-loss streak with controlled loss, then capture the expansion candle that creates a new range.
- He explicitly notes cutting profit too early then re-engaging tired/late is its own failure mode — discipline cuts both directions.

## Mapping to Nexus
- This is the clearest external statement of the operator's *exact* hard-loss pathway: breakout/trend strategies bleeding via repeated SL hits inside compression. Compare the 11.5 13:14 scalp-overlap forensics (3 SHORTs / -$1058, rules green but trend-blind) in `_library/trading/strategies/scalp_overlap.md`.
- Supports a **compression/absorption detector** as a gate input (ATR-ratio collapse, range-shrink) to stand down trend/breakout strategies — proxy for the trend-pause concept Karri owns.
- Reinforces session-breakout SL flaw analysis: in chop, the opposite range edge (the stop) gets tagged repeatedly.

## Contradiction / support
- SUPPORTS the trend-pause / regime-direction-gate direction.
- Does NOT prescribe an automated rule (it's discretionary endurance). For Nexus the actionable translation is detect-and-stand-down + daily-loss cap, REPORT not auto-disable.

## Suggested library candidates
- `_library/trading/lessons/` — "compression session = breakout death-by-1000-stops; detect + stand down, don't out-trade it" (HIGH relevance to operator's SL problem)

## Related
- [[scalp_overlap]]
- [[session_breakout]]
- [[trend_pause_detection]]
