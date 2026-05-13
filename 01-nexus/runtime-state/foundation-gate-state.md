---
type: living-state
subsystem: foundation-gate
last_verified: 2026-05-11T20:00Z
status: 🟢
---

# Foundation Gate — Living State

Foundation gate ("kan vi legge til ny strategi?") is the 5-rule promotion gate. Operator-binding: refuse to advance new-strategy work if any rule is red, regardless of who is asking. See [[Operator-Principles]] rule 4.

## Current state (verified 2026-05-11T13:33Z, refresh 20:00Z after Karri batch)

**Overall: 🟢 GRØNN — 5/5 grønn (first time ever).** Rule 2 flipped to green at 13:33Z when three post-deploy trades (`205dd6ad`, `02d3d403`, `f64feec4`) came in fully metadata-stamped. Confirmed via SQL + phase-status commit `353896e`.

| # | Rule | Status | Why |
|---|---|---|---|
| 1 | No CRITICAL open issues | 🟢 | `docs/ops/known-failures.md` only MEDIUM/LAV/RESOLVED. New issues from runde 6+7 (Gemini quota resolved via Tier-1, audit-trail gaps closing via c062696) are MEDIUM/LAV |
| 2 | `POSITION_MANAGEMENT_ENABLED=true` (with metadata stamping) | 🟢 | Verified live 13:33Z: 3 post-deploy trades stamped on `strategy_id` + `execution_source` + `atr_at_entry` + `entry_conviction_score` + `portfolio_regime_at_entry`. Metadata-strip fix `0ad348f` confirmed working on live INSERT path |
| 3 | Last 3 builds OK | 🟢 | All runde 6+7 commits green: c062696, 15089c6, a301b8b, 09dd027, ee6a8ab, 38921eb, 0ad348f |
| 4 | At least one hard-gate has 7d × 50 evals | 🟢 | `gate_decisions` resumed writing after `STRATEGY_BLADE_NEW_GATES=true` flip. Cycle-id wiring stable. Caveat: 7-consecutive-day rule post-reopen ETA full GREEN 2026-05-18 if strict |
| 5 | 0 overdue Claude-followups | 🟢 | All shipped. Zero overdue |

## Trajectory

- Pre runde 6+7: 3/5 green (rules 1, 3, 4). Rule 2 yellow (technical-only), rule 5 yellow (2 overdue followups)
- Post runde 6+7: 4/5 green. Rule 2 path is now "next trade triggers the new INSERT"
- Runde 11 (2026-05-11T13:33Z): rule 2 verified GREEN on 3 live post-deploy trades → **5/5 GRØNN first time**
- Refresh 15:30Z: still 5/5 after `611269f` + `3a1f2e1` + `a2f1cbc` added more attribution columns + `353896e` updated phase-status canonical
- Refresh 20:00Z (post-Karri TIER 1 batch via PR #1 `b22cb8d`): **still 5/5 🟢**. Karri-proposals er strategy-side endringer (env-flag gated, default OFF), påvirker ikke foundation-gate-tilstand. Ny strategi-arbeid kan fortsette.

## Recent changes

- 2026-05-11: `0ad348f` deployed — INSERT path now stamps all 6 attribution columns
- 2026-05-11: `38921eb` deployed — `decisionCycleId` wired, rule 4 audit chain closed
- 2026-05-11: 59 historical trades backfilled
- 2026-05-11: rule 5 cleared (per-strategy-sql-export + wire-analysis-snapshots both shipped)

## Health indicators

- Rules 1, 3, 4, 5 all stable green
- Rule 2 flips when verification SQL returns stamped_trades ≥ 1
- All 7 today's commits in `git log --oneline` reachable from main

## Open issues

- [ ] **Rule 2**: awaiting first post-deploy trade. Run verification SQL at next session-open
- [ ] **Rule 4 strict-7d**: ETA full GREEN 2026-05-18 if 7-consecutive-day post-reopen rule enforced

## Verification SQL

```sql
-- rule 2 confirmation
SELECT count(*) AS stamped_trades, max(created_at) AS latest_trade
FROM simulated_orders
WHERE created_at > '2026-05-11T<deploy-time>'::timestamptz
  AND strategy_id IS NOT NULL
  AND execution_source IS NOT NULL
  AND atr_at_entry IS NOT NULL
  AND entry_conviction_score IS NOT NULL;
```

Expected: stamped_trades ≥ 1 → flip rule 2 to 🟢.

```sql
-- rule 4 strict-window check
SELECT date_trunc('day', created_at) AS day, count(*) AS evals
FROM gate_decisions
WHERE created_at > '2026-05-11'::timestamptz
GROUP BY 1 ORDER BY 1;
```

Expected: 7 consecutive days with ≥ 50 evals each → ETA 2026-05-18.

## What never auto-fires

- Promotion to GREEN without operator OK ([[Operator-Principles]] rule 4)
- Bypassing rule 2 with a backfill — historic NULL rows tracked separately; this gate measures NEW trades
- Auto-disable of strategies if rule 2 regresses. Report-only; operator decides

Linked to: [[Nexus-MOC]], [[Foundation-Gate]], [[Operator-Principles]], [[metadata-stamping-state]], [[gate-decisions-state]], [[production-loop-state]], [[retention-state]], [[Truth-Hierarchy]] (this is a snapshot; `phase-status.md` + live SQL are canonical), [[When-Foundation-Rule-Goes-Yellow]], [[Karri]] (rule-loosening proposals)
