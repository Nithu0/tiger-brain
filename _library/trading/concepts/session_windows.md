---
title: Session windows + DST + cold-start behavior (XAUUSD)
source: Nexus codebase + docs/ref/session-thresholds + Raschke/Fisher
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 5
claude_priority: P0
tags: [library, concept, sessions, dst, cold-start, xauusd]
status: distilled
---

# Session windows + DST + cold-start (XAUUSD)

The single highest-leverage filter in any intraday XAUUSD strategy is **what session you are in**. Gold's tape changes personality across the regional liquidity pools (Tokyo bullion desks → London LBMA fix → NY Comex), so the same indicator setup means different things at 02:00, 09:00, and 15:00 London time. This doc is the canonical concept ref — strategy docs cross-link here.

## The three primary sessions (London-local, DST-aware)

Nexus uses **Europe/London local time** as the anchor, not UTC. `apps/worker/src/firm/session-window.ts:getSessionWindow()` wraps `Intl.DateTimeFormat` so session boundaries track the real trading day across GMT↔BST. NEVER hardcode UTC hours (`critical-rules.md` #2).

| State | London-local clock | Character |
|---|---|---|
| `ASIA_OBSERVE` | 00:00–05:00 | Compression. Thin volume, mean-reverting around H1 VWAP. |
| `ASIA_PREPARE_FOR_LONDON` | 05:00–07:30 | Context building. Range setting up for London break. |
| `LONDON_PREPARE` | 07:30–08:00 | No trading. Final briefing. |
| `LONDON_OPENING_RANGE` | 08:00–08:30 | ORB formation. True-range expansion begins. |
| `LONDON_ACTIVE` | 08:30–12:00 | PRIMARY alpha window. Breakouts, directional flow. |
| `OVERLAP_ACTIVE` | 12:00–14:30 + 15:00–16:00 | PRIMARY peak liquidity (London-NY). |
| `NY_OPENING_RANGE` | 14:30–15:00 | NY ORB formation. Often continuation, sometimes reversal. |
| `NY_CONTINUATION` | 16:00–19:00 | Follow-through assessment. Moderate bar. |
| `LOW_PRIORITY_OBSERVE` | 19:00–24:00 | Maintenance. Rare event-only trades. |

## XAUUSD-specific session character

- **Asia = compression / range.** Thin volume keeps price oscillating around H1 VWAP. Edge belongs to mean-reversion archetypes (S4) or to *marking* the range Asia builds so London can break it (session-breakout window 1).
- **London = breakout / true range expansion.** LBMA fix flow + European real-money desks waking together = the day's structural high/low usually prints inside `LONDON_ACTIVE`. ORB and session-breakout are built for this window.
- **NY = continuation OR reversal.** US desks either extend the London leg (continuation) or fade it on profit-taking off psychological levels ($4700, $4650). Direction depends on the macro day, not a fixed rule.

## Overlap windows — where volume + edge concentrate

- **London-NY (12:00–14:30, then 15:00–16:00 London).** Peak liquidity of the day. Two desks at the screen → volume spikes 2–3×. On balanced days this concentrates two-sided liquidity provision (mean-revert edge, scalp-overlap), on directional days it concentrates flow (breakout edge). The window itself is the filter; pick the trigger that matches the regime.
- **Asia-London (07:00–09:00 London).** Smaller, less reliable overlap. Mostly a setup zone — Asia range gets defined, London punches through.

## DST handoff weeks (the dangerous transition)

London and NY enter/exit DST on slightly different dates each spring/autumn. For ~1–2 weeks per year, the London-NY overlap shifts ±1h relative to UTC. **Hard-coded UTC windows silently misfire during these weeks.** Nexus's `getLondonLocalTime()` wrapper insulates session detection, but external signals (news APIs, calendars, third-party indicators) often don't — verify their timestamps explicitly before trusting them around DST handoffs. Treat the first 3 trading days after each handoff as elevated-risk: spreads widen, ATR-baselines recalibrate, fills slip.

## Cold-start deltas (first 30–60 min after open)

ATR baselines are computed over trailing windows that don't reset at session-open, so the first 30–60 min of `LONDON_OPENING_RANGE` and `NY_OPENING_RANGE` show an ATR that is *stale* — it reflects the prior session's volatility regime, not what's printing right now. Nexus handles this two ways:

1. **`FIRM_COLD_START_MODE`** (env flag) subtracts `FIRM_COLD_START_THRESHOLD_DELTA` (default −13, bounded [−20, 0]) from `marketThesis` + `entryThesis` thresholds, **only** on primary windows (`LONDON_*`, `OVERLAP_ACTIVE`, `NY_*`). `executionWindow` and `invalidationQuality` are never loosened. See `cold-start-config.ts`.
2. **Faster cadence inside ORB windows** — `getSessionCadence()` drops `factIntervalMs` to 15s during `LONDON_OPENING_RANGE` / `NY_OPENING_RANGE`, so the range forms with fresh ticks instead of stale 5-min snapshots.

## Strategy → session mapping (canonical)

- **ORB** → `LONDON_OPENING_RANGE` + `NY_OPENING_RANGE` (formation), continues into `LONDON_ACTIVE` / `OVERLAP_ACTIVE`.
- **scalp-overlap** → `OVERLAP_ACTIVE` only (UTC core 13:00–15:00). Currently observe-only pending regime-direction gate.
- **session-breakout** → window 1 = London-open break of Asia range; window 2 = NY-open break of London range.
- **vol-expansion** → any primary window, but NY-session is most productive (ATR-ratio spikes hardest after macro prints).
- **S4 (mean-reversion)** → `NY_CONTINUATION` + `LONDON_ACTIVE` only by code (Asia blocked because chop without volume = false signals). The Asia-chop case is theoretically S4's home but live evidence shows volume too thin to confirm RSI extremes.

## Cross-references

- **Linda Raschke — *Street Smarts* ("Holy Grail")**: timing rules emphasize the first 90 min of session-open as the highest-edge window for momentum continuation. Matches Nexus's `LONDON_ACTIVE` primary classification.
- **Mark Fisher — *The Logical Trader* (ACD method)**: the canonical opening-range framework. Fisher computes A-up/A-down off the session's first N minutes — Nexus's `LONDON_OPENING_RANGE` and `NY_OPENING_RANGE` are direct implementations.
- Sibling concept docs: `foundation_gate_tier3.md` (binding deploy gates), `trend_pause_detection.md` (the missing regime layer across sessions).
- Code: `apps/worker/src/firm/session-window.ts` (state machine), `london-time.ts` (DST wrapper), `cold-start-config.ts` (delta tuning).
- Ops: `docs/ref/session-thresholds.md` (numeric thresholds table), `docs/ref/critical-rules.md` rule #2 (no UTC hardcoding).
