---
tags: [nexus, ops, demo-mode]
type: atomic
created: 2026-05-08
---

# Demo-Mode

Currently `DEMO_AUTO_DEGRADE_ENABLED=false` since 2026-04-23. Source: `_repo-docs/ops/phase-status.md` + `apps/worker/src/firm/demo-mode.ts`.

## What demo-mode is

Nexus runs against OANDA practice account. Demo-mode classifies the account state into one of four levels based on realized PnL:

- **NORMAL** — within tolerance
- **DEGRADED** — losses crossed soft threshold
- **SHADOW** — losses crossed harder threshold; would normally bump thresholds
- **LEARNING_ONLY_DEMO** — account in learning state; previously blocked execution

## Auto-degrade — disabled

Pre-2026-04-23 behaviour: when realized loss crossed -$1,500, demo-mode auto-stepped into `LEARNING_ONLY_DEMO` and blocked execution for 24h. This actually triggered: -$1,613 realized → 24h trading freeze on a demo account where the safety is unnecessary.

Operator's call (2026-04-23): set `DEMO_AUTO_DEGRADE_ENABLED=false`. Demo-mode now **reports** the level (NORMAL / DEGRADED / SHADOW / LEARNING) in logs and morning briefing, but does **not** block execution and does **not** bump thresholds.

This is [[Operator-Principles]] prinsipp 1 in action: no auto-disable based on anomaly detection. Health-check reports; operator decides handling.

## Rollback (operator-side)

Set `DEMO_AUTO_DEGRADE_ENABLED=true` on Railway Worker. 30 seconds, no code change.

## Why it matters

Demo is where calibration happens. Blocking trading because losses crossed an arbitrary line on a demo account loses calibration data, which is the entire purpose of running demo. The reporting layer is enough — operator sees the severity in [[Module-Notifications]] morning briefing.

## Related

- [[Operator-Principles]] — prinsipp 1 source
- [[Module-Notifications]] — surfaces demo-mode level in morning briefing
- [[Foundation-Gate]] — separate gate, unaffected by this change
- [[Module-Orchestrator]] — reads demo-mode but no longer auto-blocks
- [[OK-Kjor-Gate]] — the operator override pattern this incident codified
