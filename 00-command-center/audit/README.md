---
tags: [command-center, audit, meta]
type: meta
created: 2026-05-16
---

# Audit — command-center

Daily SQLite `audit_log` dumps land here, one file per day, format `YYYY-MM-DD.md`.

## Why here

- Brain is in git → audit trail survives DB loss.
- Brain syncs across machines via Obsidian Git plugin → audit is replicated.
- Markdown is grep-able, diff-able, scannable.

## Producer

`scripts/audit-dump.ts` in the command-center repo. See [[../runbooks/daily-audit-dump]].

## Schema (Slice 1)

Each row: `ts, actor, action, target, payload (JSON), result`. The dump groups by `action` then chronological within action.

## Not yet populated

Slice 1 doesn't ship the cron. First dump expected once Slice 3 wires execution + scheduled dump. Until then this folder is intentionally empty (`.gitkeep` only).
