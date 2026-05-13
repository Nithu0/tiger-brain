---
type: workflow
status: active
created: 2026-05-11
---
# Firm-Up-Max-Mode

Operator's entry point for the local firm-mirror — `firm-up` shell alias tiles multiple Claude terminals in zellij, each scoped to a firm-agent role (Maxime/Lou/Atlas/Karri-spor/etc.).

## What runs
1. Robust env loader pre-flight (catches missing `.env.local` vars before launch).
2. Zellij layout from `local-firm-mirror.md` Phase 4/5 spec.
3. Each pane starts in repo root with project CLAUDE.md auto-loaded.

## Debug ladder
If `firm-up` fails: check `reference_firm_up_entry.md` memory for the layered fallback (env-doctor → zellij version → layout path → permissions).

## Source
- `docs/ref/local-firm-mirror.md` (architecture)
- `reference_firm_up_entry.md` memory (debug ladder)
- `firm-up` function in operator dotfiles

Linked to: [[Workflows-MOC]], [[Parallel-Batch-Coordination]], [[Tools-MOC]]
