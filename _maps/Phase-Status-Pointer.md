---
type: pointer
target: docs/ops/phase-status.md
---
# Phase Status (live state pointer)

`docs/ops/phase-status.md` is the single source of truth for Nexus's current operational state. Read FIRST at every session checkpoint.

## What it contains
- "Sist oppdatert" timestamp + change summary
- Live MCP roster
- Foundation-gate state (5 rules)
- Operator decisions log
- Active environment flags
- Open issues + temporary exceptions

## When to update
After every commit that changes live/observasjons-tilstand. Operator-prinsipp: "Hvis uenighet mellom denne fila og koden — koden vinner, oppdater fila."

## Last refresh (mirror)
- 2026-05-11 — uke-åpning state, metadata-strip fix, env-sync, foundation gate revisited

Linked to: [[Nexus-MOC]], [[Foundation-Gate]], [[Operator-Principles]]
