# Foundation-Monitor Verify — Post `FOUNDATION_MONITOR_ENABLED=true`

**Date**: 2026-05-11
**Trigger**: Operator flipped `FOUNDATION_MONITOR_ENABLED=true` on Railway.
**Verdict**: **PASS — monitor firing as designed, steady-state.**

---

## 1. Build commit live

- `/health` → `b6b4934c` (`test(orchestrator): smoke + step-flow coverage (11 tests)`)
- Foundation-monitor commit `8bc0394` is an ancestor of `b6b4934` → monitor code IS in the deployed build.
- `git merge-base --is-ancestor 8bc0394 b6b4934` returned 0 (confirmed).

## 2. `firm_state` row present

```
key:        foundation_monitor:last_state
updated_at: 2026-05-11T13:48:28.950Z  (9.2 min ago)
```

Contents:

| Rule | Name | State | Detail |
|---|---|---|---|
| 1 | Ingen KRITISKE åpne problemer | UNKNOWN | manual operator doc (docs/ops/phase-status.md) — not DB-checkable |
| 2 | Position-management synkronisert | GREEN | `POSITION_MANAGEMENT_ENABLED=true` |
| 3 | Deploy sunn (siste 3 builds) | UNKNOWN | Railway Deployments tab — not DB-checkable |
| 4 | Hard-gate datagrunnlag | GREEN | `entry_stack_cooldown`: 20d, 1955 evals |
| 5 | Forfalne claude-followups | GREEN | 0 overdue claude/both entries |

**Overall**: GREEN (3 GREEN, 2 UNKNOWN; UNKNOWN does not poison per `worst()` in monitor source).

## 3. Independent cross-check vs. live DB

### Rule 4 — gate_decisions

```sql
SELECT gate_name, COUNT(*) AS evals,
       EXTRACT(DAY FROM MAX(recorded_at) - MIN(recorded_at))::int AS days_observed
FROM gate_decisions GROUP BY gate_name ORDER BY MAX(recorded_at) DESC;
```

| gate_name | evals | days | last_eval |
|---|---|---|---|
| entry_stack_cooldown | 1955 | 20 | 2026-05-11T13:33:04Z |
| risk_level | 1977 | 20 | 2026-05-11T13:33:04Z |
| scalp_overlap_asia | 1977 | 20 | 2026-05-11T13:33:04Z |
| ranging_conviction | 1977 | 20 | 2026-05-11T13:33:04Z |

Monitor picks the **first** mature row (≥7d AND ≥50 evals) as the GREEN witness — `entry_stack_cooldown` matches the persisted detail string exactly. Independent verification PASS.

### Rule 5 — claude/both overdue followups

Source: `apps/worker/src/firm/followups.ts` (in-code list, not a DB table). Today = 2026-05-11. Filtering owner∈{claude, both} AND due≤today:

- `per-strategy-sql-export-csv` (claude, 2026-06-01) → not due
- `ohlcv-diagnose-railway-logs` (operator, 2026-04-22) → wrong owner
- `backfill-original-risk-points-on-oanda-reconcile` (claude, 2026-05-18) → not due

→ 0 overdue claude/both. Monitor row's GREEN matches. PASS.

## 4. Discord alerts fired?

**No.** Expected per design:

- First-run baseline path in `diffSnapshots()`: emits an alert only if any rule is `YELLOW` or `RED`. All 3 checkable rules are GREEN (rules 1+3 are UNKNOWN-placeholders, which are filtered out). → 0 changes → no embed POST.
- `foundation_monitor:last_alert` row does NOT exist in `firm_state` (the monitor only writes `:last_state`, no separate alert ledger — the source code's `persistState()` only touches the single `STATE_KEY`).
- Blackboard scan for `foundation_monitor` / `foundation_gate` topics last 30 min: 0 rows. (Monitor doesn't post to blackboard either — log + Discord only.)

## 5. Cooldown behavior

Row age = 9.2 min. `COOLDOWN_MS = 15 * 60 * 1000`. → Next run scheduled at ~`2026-05-11T14:03:29Z` (15 min after last persistence). Worker reads `firm_state.updated_at`, so process restarts won't double-trigger.

## 6. Operator-visible behavior going forward

- Every ~15 min the orchestrator's Step 0a2c re-evaluates the 5 rules and refreshes `firm_state.foundation_monitor:last_state`.
- A Discord embed to `DISCORD_ALERTS_WEBHOOK_URL` (or `DISCORD_WEBHOOK_URL` fallback) fires ONLY when a rule flips between checkable states (GREEN/YELLOW/RED). UNKNOWN ↔ anything is suppressed.
- If a flip happens (e.g. someone disables `POSITION_MANAGEMENT_ENABLED` → rule 2 goes RED), the embed will list ALL 5 rules with current state, color-coded by the worst change.
- Per operator-prinsipp #1: monitor is REPORT-only. It will never auto-flip flags, never auto-trim data, never auto-close positions.

## Verdict

**PERFECT — monitor firing as designed, steady-state.**

- Build deployed: YES (`b6b4934c` ≻ `8bc0394`).
- Monitor ran post-flip: YES (row exists, 9.2 min old).
- Persisted state matches independent DB probes: YES (rule 4 exact match, rule 5 logic match).
- Discord alert fired: NO (correct — no state change to alert about).
- Cooldown active: YES (next check ~14:03 UTC).

No further action needed. Operator can expect Discord pings only when something materially changes.
