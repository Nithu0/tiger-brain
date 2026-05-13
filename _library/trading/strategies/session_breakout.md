---
title: Session-breakout — Nexus xau-session-breakout lens (+ SL-flaw)
source: Nexus codebase + round 2 forensics + Fisher (ACD)
author: distilled-by-claude
source_type: distilled
relevance_to_nexus: 5
claude_priority: P0
tags: [library, strategy, session-breakout, breakout, fisher, sl-flaw]
status: distilled
---

# Session-breakout (XAUUSD, Nexus lens)

## What the archetype is (50 words)

Mark the high/low of a quiet session (Asia or pre-NY London). When the next session opens with order-flow imbalance and price breaks the prior range, ride the breakout in that direction. Bet that range = balance-area, and a clean break = imbalance about to extend.

## Why XAUUSD respects session edges (60 words)

Gold rolls between three regional liquidity pools (Asia → London bullion fix → NY Comex). Each handover concentrates institutional flow at fresh time-of-day extrema. Stops cluster just beyond prior-session high/low because retail and desk traders place them at the same obvious level. A genuine breakout sweeps that cluster; a fake one snaps right back. The level itself is *structural*, not arbitrary.

## Nexus implementation (precise, from `session-break-manager.ts`)

- **Window 1 (London Open)**: 08:00–12:00 London. Source range = prior 16h (Asia/late-US tape), 1h candles.
- **Window 2 (NY Open)**: 14:30–19:30 London. Source range = today's London session (08:00–14:30), 15m candles.
- **Trigger**: current price closes outside `[range.low, range.high]` → direction = side of break.
- **Range filter**: width in `[$3, $80]`; sweet criterion `$8–$25`. Cap one trade per window, max 2/day.
- **TP**: `entry ± 1.5 × risk`.
- **SL** (the load-bearing flaw): **opposite range edge** (`range.low` for longs, `range.high` for shorts). Same logic for with-trend and counter-trend. ATR is fetched but only for observability — *not* used in SL math.

## The structural flaw

Range edges are exactly where retracement is *normal* price action. A breakout-and-retest is the textbook continuation pattern — but Nexus sticks the stop at the retest level itself. Result: a single normal pullback into the broken edge takes us out at full range-width risk ($30–$85 typical), and TP-distance (1.5×risk) is then so far away that even a winning thesis often can't reach it before management exits.

The risk-distance equals one full session range, which in current XAUUSD vol regime is ~1× NY-session ATR. So **one ATR of mean reversion = SL hit**. Vinnere og tapere har overlappende SL-distanser ($30–$72) — SL-distance is not the discriminator; the discriminator is that the SL *sits in the structural retracement zone by design*.

## Live evidence (30d to 13.5)

14 trades, **6 OANDA_SL_TP hits (43%)**, –$1111 from SL alone, 4 winners, **–$631 net**. Worst loss (08.5 NY long, 57h hold): weekend gap → reversed back into prior London-range low → SL exactly at structural pivot the next session naturally tested. This is the archetype of the flaw.

`atr_at_entry` is NULL on every session-breakout row — observability gap (fixed via A3 patch round-3) blocked ATR-vs-WR postmortem until now.

## Cross-references

- **Fisher — *The Logical Trader* (ACD methodology)**: the closest published cousin. Fisher's "A" and "B" levels are computed off the opening-range and prior day's pivot, but his SL is *never* the opposite range edge — it's a noise-multiple of the opening-range width *beyond* entry. Nexus's SL = full-range-width is roughly 5–7× wider than Fisher's per-trade risk on the same setup.
- **Crabel — *Day Trading with Short Term Price Patterns and Opening Range Breakout***: range-expansion lineage. Crabel's stops are tied to opening-range fractions (1/3, 1/2 ORR), not full prior-day range. Same critique: full-range SL is unjustified by the literature it descends from.
- **Williams — narrow-range / breakout family**: confirms range-edge as a *target* zone, not a stop zone.

## Pending C2 proposal (Karri reviewing)

`docs/strategy/proposals/2026-05-13_session_breakout_sl_method.md` offers three forks:

- **Option A — Cap at 1.0×H1 ATR(14).** Keep range-edge when it's tighter than ATR, else use ATR-stop. Minimal intervention, reversible. Risk: caps winners that needed runway.
- **Option B (recommended in forensics) — Swap to swing-based SL.** Last M15 swing high/low ± 0.25×M15 ATR. Couples SL to microstructure the breakout actually defends. Structurally correct but needs new swing-detection code.
- **Option C — Disable** pending 6-month re-validation on current high-vol regime (NY-ATR ~$22 live vs ~$14 backtest window). Stops bleed immediately, loses optionality.

Sequencing is binding: A3 observability fix lands first → 14d of `atr_at_entry`-populated data → backtest all three options against the live distribution → Karri picks → env-flag flip (`SESSION_BREAKOUT_SL_MODE`). No autonomous disable per operator-prinsipp 1.

## Operational notes

- Strategy ID: `xau-session-breakout`. Files: `apps/worker/src/firm/session-breakout/`.
- Default OFF in code; live since 28.4 via `SESSION_BREAKOUT_ENABLED=true`.
- Backtest sweet-spot (90d, 26.4): WR 45.9%, +$440. Walk-forward W3 (nov–jan): **–$236** — overfit-flag was raised at deploy and has now materialized in live.
- Currently the largest legacy bleeder on the 30d window. Disable is not authorized; reviewing.
