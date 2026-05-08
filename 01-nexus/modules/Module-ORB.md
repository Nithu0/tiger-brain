---
tags: [nexus, module, orb]
type: atomic
created: 2026-05-08
---

# Module-ORB

Owner: Prism + Blade. Opening Range Breakout module. Lives in `apps/worker/src/firm/orb/` (six files).

## What it does

Detects the opening range during 08:00-08:30 London (configurable), runs a state machine through breakout / retest / confirm, applies momentum + pre-move filters, and emits an entry signal when CONFIRMED.

This is the implementation layer. The strategy view of when/why to fire is in [[Strategy-ORB]].

## Key files

| File | Purpose |
|---|---|
| `apps/worker/src/firm/orb/config.ts` | 12 env-gated parameters |
| `apps/worker/src/firm/orb/range-detector.ts` | Monitors 5m candles, establishes OR_high/OR_low |
| `apps/worker/src/firm/orb/state-machine.ts` | ARMED → BROKEN → RETESTING → CONFIRMED → EXPIRED / INVALIDATED |
| `apps/worker/src/firm/orb/momentum-filter.ts` | Body/wick ratio scoring on confirmation candle |
| `apps/worker/src/firm/orb/pre-move-filter.ts` | Blocks if Asia session consumed >60% of ADR |
| `apps/worker/src/firm/orb/orb-manager.ts` | Fit-score, trend filter, daily cap, SL/TP calculation |

## Orchestrator integration

Step 1b in `runCycle()`. Range detector runs every cycle; state machine ticks when range is VALID; manager evaluates when CONFIRMED. See [[Module-Orchestrator]].

## DB

`orb_ranges` table stores daily ranges. `simulated_orders` extended with `entry_type`, `range_size_usd`, `result_r`, `orb_range_id`.

## Blackboard topics

`xauusd.orb.range`, `xauusd.orb.state`, `xauusd.orb.signal` — published to [[Module-Blackboard]].

## Activation

`ORB_ENABLED=true` on Railway Worker (currently LIVE). Rollback: set to `false`. Master kill `ORB_ONLY_MODE=true` bypasses Prism synthesis pipeline entirely. See [[Strategy-ORB]] for the strategy roadmap.

## Related

- [[Strategy-ORB]] — when/why
- [[Module-Orchestrator]] — step 1b in cycle
- [[Module-Position-Management]] — manages ORB positions after fill
- [[Module-Blackboard]] — three topics
- [[Module-Exposure-And-Shield]] — news-blackout gate for ORB
- [[Foundation-Gate]] — gate for ORB tuning
