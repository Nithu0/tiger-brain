---
type: incident-pointer
status: resolved
target: docs/ops/gate-silence-2026-05-08.md
---
# Gate Silence Incident — 2026-05-08

`gate_decisions` table stopped writing for 14 days (2026-04-24 → 2026-05-11). Foundation Rule 4 RED during this period.

## Root cause
`STRATEGY_BLADE_NEW_GATES` env-var was undocumented in `.env.example` (one of 156 missing vars at the time). Operator never saw it; flag sat at default false.

## Resolution
- 2026-05-08: Diagnosed + correction filed
- 2026-05-11: Operator flipped `STRATEGY_BLADE_NEW_GATES=true` on Railway → gate_decisions resumed writing same day (~12 rows/24h, 4 rows/hour)
- 2026-05-11: 156 missing env-vars synced to `.env.example` (commit 937bd30) — stops next gate-silence-style incident

## Why this matters
Single most-impactful operability lesson: `.env.example` is not just documentation, it's operator visibility. Drift kills features silently.

## Reference
Full diagnostic: `~/code/ai-assistent/docs/ops/gate-silence-2026-05-08.md`

Linked to: [[Foundation-Gate]], [[Operator-Principles]], [[Nexus-MOC]]
