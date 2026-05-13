---
type: mode
status: active
flag: BROKER_MODE=demo
---
# Demo Mode

Nexus runs in demo (paper) mode against OANDA's practice API. Switch is `BROKER_MODE=demo` (never auto-switches). Live-capital flip is gated on:
- 30+ days of clean firm-loop data
- Foundation-gate all 🟢
- Operator explicit decision

## Demo characteristics
- Real OANDA prices + fills against demo account
- Real broker latency + slippage profile
- `DEMO_AUTO_DEGRADE_ENABLED=false` (per 2026-04-23 decision) — health-check reports degradation but never auto-kills strategies

## Why
Per operator-prinsipp 1 (no auto-disable). Health-check REPORTS via Discord. Operator decides.

## Demo balance
~$92,646 (per /health 2026-05-11). Expected $92,632. Drift $13.62 explained by OANDA daily-financing + rounding (per recon audit).

Linked to: [[Nexus-MOC]], [[Operator-Principles]], [[Foundation-Gate]]
