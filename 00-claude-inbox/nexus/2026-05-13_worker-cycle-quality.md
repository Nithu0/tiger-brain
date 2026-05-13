---
date: 2026-05-13
type: investigation
project: nexus
status: open
---

# Worker cycle quality — 13.5 11:23 UTC

## TL;DR

Worker is healthy and cycling normally. `lastDecisionSec=63511` (17.6h) is misleading
— it tracks only manager-DECISION events, not cycle activity. Strategies have been
generating signal *candidates* every cycle, but ~100% are rejected pre-publish by
session/ADX/ATR pre-conditions, so no PROPOSAL → no DECISION → no `gate_decisions`
row → stale `lastDecisionSec`. Last real DECISION was 2026-05-12 17:35 UTC (NY
session, when LONDON_OPENING_RANGE + ASIA_OBSERVE windows lift).

## /health snapshot (11:23 UTC)

- `lastHeartbeatSec=38`, `lastCycleNo=99`, `lastCycleDurationMs=8095` — worker cycling ~8s
- `lastMarketRawSec=45` — market data flowing
- `lastDecisionSec=63511` — 17.6h, **misleading** (see below)
- `balance=89245.4659`, drift=13.63 (reconciled)
- Build `4ac50182`, demo mode

## Data-freshness audit (sec since last write)

| table | sec_since |
|---|---|
| firm_state | 6 |
| market_snapshots | 7 |
| analysis_snapshots | 7 |
| blackboard | 7 |
| agent_events | 209 |
| signals | 64077 (17.8h) |
| gate_decisions | 64077 (17.8h) |
| pending_signals | (empty) |

Market + analysis + blackboard all writing every cycle. Only the
manager-decision layer is silent.

## gate_decisions distribution (24h)

| hour UTC | cycles | rows |
|---|---|---|
| 2026-05-12 14:00 | 4 | 24 |
| 2026-05-12 15:00 | 2 | 12 |
| 2026-05-12 16:00 | 1 | 6 |
| 2026-05-12 17:00 | 1 | 6 |
| 2026-05-12 18:00 → 2026-05-13 11:00 | **0** | **0** |

Every cycle that does reach manager evaluates the same 6 gates:
`daily_trade_cap, entry_stack_cooldown, ranging_conviction, risk_level,
scalp_overlap_asia, session_block`.

## Why no manager-decisions for 17.6h

Blackboard activity is healthy (489 msgs in current hour, 1170 at 09:00 UTC peak),
but the dominant signal flow is **rejection**:

| topic | 24h count |
|---|---|
| xauusd.signal.rejected | 3213 |
| xauusd.market.raw | 1420 |
| xauusd.{strategy}.state | 710 × 6 strategies |
| xauusd.manager.decisions | **11** (last 5 at 17:00 UTC yesterday) |

Rejection log fires every cycle. Top reject reasons (last 12h):

- `xau-breakout-continuation: no_clean_breakout` — 192
- `xau-volatility-expansion: ATR ratio 0.65–0.81 < threshold 1.3` — 314 combined
- `xau-{strategy}: session_not_allowed: ASIA_OBSERVE / LONDON_OPENING_RANGE / ASIA_PREPARE_FOR_LONDON` — 600+ combined
- `xau-trend-following: adx_too_low: 14.9–15.4 < 22` — 100+
- `xau-pullback-continuation: adx_too_low: 14.9–15.4 < 20` — 100+

All reject at `stage=blackboard-publish` — i.e. before the candidate ever reaches
the manager → before gates evaluate → no `gate_decisions` row.

## What this means for /health

`lastDecisionSec` measures time since the most recent **manager DECISION**, not
worker cycle activity. When the market is in a low-ADX, low-ATR phase during
Asia/London-open windows, the strategies legitimately self-veto and the field
balloons. This is **not** a worker stall — it's expected behavior given current
strategy guard thresholds.

## Anomalies / open questions

1. `pending_signals` table is empty for the full 24h window — confirm if this is
   intended (looks like a legacy table, may be dormant).
2. ADX is hovering 14.9–15.4 with strategy thresholds 20/22 — current market is
   genuinely in a low-trend regime. Karri's trend-pause-bevissthet hypothesis
   matches the picture: strategies *correctly* not firing.
3. Cycle count = `lastCycleNo=99` seems low for a worker that has been up; likely
   resets on each deploy. Worth confirming next deploy doesn't drop the counter
   silently.
4. NY-session edge: only 1 manager-decision pulse around 17:00 UTC daily. If
   today follows pattern, expect gates to fire again ~17:00 UTC.

## Recommendation

- Do NOT treat large `lastDecisionSec` as a worker-health alarm during quiet
  market windows. Add a separate "cycles in last hour" metric in /health
  (derive from market_snapshots count) to distinguish "worker stalled" from
  "market is quiet".
- Re-check at 17:30 UTC today; if gates still silent by 18:00 UTC, escalate.
