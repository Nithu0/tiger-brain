---
type: living-state
subsystem: gate-decisions
last_verified: 2026-05-11T15:30Z
status: 🟢
---

# Gate Decisions — Living State

The `gate_decisions` table records every entry-gate evaluation. Foundation Rule 4 (data maturity) reads this table — silence = RED.

## Current state (verified 2026-05-11)

- **Flag**: `STRATEGY_BLADE_NEW_GATES=true` on Railway (flipped 2026-05-11)
- **Cycle-id wiring**: commit `38921eb` — every new INSERT now includes `decision_cycle_id`, closing audit chain
- **Rows in last 24h**: ~12 (4/hour cadence) — was 0 for 14 days before flip
- **Foundation Rule 4**: 🟢 stable green
- **Schema**: gate_id, strategy_id, decision (pass/veto), reason, regime_at_eval, **decision_cycle_id (new)**, created_at

## Recent changes

- 2026-05-11: `38921eb` — `decisionCycleId` wired into gates INSERT path. All post-deploy rows should have non-null `decision_cycle_id`
- 2026-05-11: `STRATEGY_BLADE_NEW_GATES` flipped on (closes 14-day silence period 2026-04-24 → 2026-05-08)

## Health indicators

- ≥1 row/hour during market open (London + NY sessions)
- Both `pass` and `veto` decisions appear in 24h window (mix expected)
- Post-deploy rows have non-null `decision_cycle_id`
- Foundation Rule 4 holds 🟢 — 7-day consecutive coverage path active

## Open issues

- [ ] 7-consecutive-day post-reopen rule: full GREEN ETA 2026-05-18 if strict
- [ ] Verify cycle_id coverage: every new row should join to a `decision_cycles` row

## Incident history

- **2026-04-24 → 2026-05-08**: gate_decisions silent (14 days). Root cause: `STRATEGY_BLADE_NEW_GATES` undocumented in `.env.example`. Diagnosed 2026-05-08, fix in commit 937bd30. Flag flipped 2026-05-11.

## Verification SQL

```sql
SELECT max(created_at), count(*)
FROM gate_decisions
WHERE created_at > now() - interval '1 hour';
```

Expected: ≥ 1 row/hour during market open.

```sql
-- decision_cycle_id coverage (post 38921eb)
SELECT COUNT(*) AS total,
       COUNT(*) FILTER (WHERE decision_cycle_id IS NOT NULL) AS with_cycle_id
FROM gate_decisions
WHERE created_at > '2026-05-11T<deploy-time>'::timestamptz;
```

Expected: with_cycle_id = total.

```sql
-- pass vs veto distribution
SELECT decision, count(*)
FROM gate_decisions
WHERE created_at > now() - interval '24 hours'
GROUP BY decision;
```

## What never auto-fires

- Disabling a gate to "unblock" trades when veto rate is high. Vetoes are guardrails ([[Operator-Principles]] rule 1).
- Removing gate entries to clean up DB. Append-only.

## Sibling silences to watch

- `signals` table: if silent → strategy isn't producing signals
- `firm_messages` topic depth growing without consumption → drainer stall
- `gate_decisions` silent again → [[When-Gate-Goes-Silent]]

Linked to: [[Nexus-MOC]], [[Foundation-Gate]], [[foundation-gate-state]], [[production-loop-state]], [[gate-silence-2026-05-08]], [[When-Gate-Goes-Silent]], [[Operator-Principles]] (rule 1: silence ≠ reason to lower defences), [[Truth-Hierarchy]] (`gate_decisions` SQL above this snapshot), [[Module-Exposure-And-Shield]] (producer)
