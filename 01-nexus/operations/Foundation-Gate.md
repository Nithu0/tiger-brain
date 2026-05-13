---
tags: [nexus, ops, foundation-gate]
type: atomic
created: 2026-05-08
---

# Foundation-Gate

Five rules that must ALL be green before a new strategy can be added or before any aggressive tuning of an existing strategy. Source: `_repo-docs/ops/new-strategy-gate.md`. **Binding for any Claude session, any device.**

## The five rules

| # | Rule | Green when | Red when |
|---|---|---|---|
| 1 | No CRITICAL open issues | `phase-status.md` "Åpne problemer" has no rows with `hastegrad=KRITISK` | At least one CRITICAL row |
| 2 | Position-management synchronized | `POSITION_MANAGEMENT_ENABLED=true` on Railway Worker (OANDA two-way sync landed) | Flag = false |
| 3 | Deploys healthy | Last 3 Worker builds = successful on Railway | At least one failed build last 48h |
| 4 | At least one hard-gate has mature data | One gate in `gate_decisions` has ≥7 days, ≥50 evaluations | <7 days or <50 rows |
| 5 | No overdue claude-followups | `firm/followups.ts` has 0 entries with `dueDateIso ≤ today` AND `owner ∈ {claude, both}` | At least one overdue |

One rule red → STOP. No exceptions.

## Current status (per `_repo-docs/ops/phase-status.md`)

🟡 **GUL** as of 2026-05-03:
- Rule 1: 🟢
- Rule 2: 🟢 (since 2026-04-22 evening, verified on ticket 548)
- Rule 3: 🟢 (Dockerfile builder since 2026-04-20)
- Rule 4: 🔴 (gates have only been running since 2026-04-20 ~15:00 UTC — needs 3-4 more days of data)
- Rule 5: 🟡 (one followup was overdue 2026-04-23, was covered by ticket 548 verification)

Foundation goes 🟢 when rule 4 has 7 days of data (~2026-04-27). Always read [[Phase-Status-Pointer]] for live truth — do not trust this snapshot.

## Behaviour when red

Claude must REFUSE to proceed with new-strategy work. Operator can override **explicitly in-session** but must add the override as an entry under "Midlertidige unntak" in `phase-status.md` for audit trail.

## SQL for rule 4

```sql
SELECT gate_name, COUNT(*) AS evals,
       COUNT(*) FILTER (WHERE would_reject) AS would,
       MIN(recorded_at)::text AS first_seen,
       MAX(recorded_at)::text AS last_seen,
       EXTRACT(DAY FROM MAX(recorded_at) - MIN(recorded_at)) AS days_observed
FROM gate_decisions
GROUP BY gate_name
ORDER BY days_observed DESC, evals DESC;
```

Green when `days_observed >= 7 AND evals >= 50` for at least one gate.

## Related

- [[Operator-Principles]] — prinsipp 4 (foundation-først) makes this binding
- [[Strategy-Promotion-Workflow]] — gates the promotion path
- [[Strategy-Proposal-Workflow]] — proposals can be drafted while red, but not implemented
- [[OK-Kjor-Gate]] — both must be green for activation
- [[Phase-Status-Pointer]] — live truth
- [[Module-Exposure-And-Shield]] — produces `gate_decisions` rows that feed rule 4
- [[Truth-Hierarchy]] — this doc is a snapshot; live state in `phase-status.md` + `gate_decisions` rules
- [[When-Foundation-Rule-Goes-Yellow]] — decision-tree when any rule flips
- [[Karri]] — threshold loosening on any rule routes through [[Strategy-Proposal-Workflow]]
- [[foundation-gate-state]] — living-state mirror
