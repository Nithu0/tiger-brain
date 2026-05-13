---
type: living-state
subsystem: production-trading-loop
last_verified: 2026-05-11T15:30Z
status: 🟡
---

# Production Trading Loop — Living State

Tracks the firm-strategy decision/execution loop on Railway worker. Ground truth: `runCycle()` in `apps/worker/src/firm/orchestrator.ts` + `/health` endpoint.

## Current state (verified 2026-05-11)

- **Decision path**: firm Blade / Forge / Shield, LIVE
- **ORB strategy**: LIVE (`ORB_ENABLED=true`)
- **Legacy XAUUSD path**: OFF (`LEGACY_XAUUSD_EXECUTION_ENABLED=false`)
- **Position-management master**: LIVE (`POSITION_MANAGEMENT_ENABLED=true`)
- **Cold-start delta**: active (`FIRM_COLD_START_MODE=true`)
- **Retention TTL pass**: LIVE (`RETENTION_ENABLED=true`) — see [[retention-state]]
- **New gates flag**: LIVE (`STRATEGY_BLADE_NEW_GATES=true`) — see [[gate-decisions-state]]
- **Cycle progression**: continuous; orchestrator cycle_no incrementing, heartbeat OK, lastError=null

## Cycle progression snapshot

- Cycles firing per minute: ~6 (10s cadence)
- Most recent `gate_decisions` write: post-`38921eb` deploy, all rows include `decision_cycle_id`
- Most recent metadata-stamped trade: **awaiting first post-`0ad348f` trade** (likely next session-open)
- PnL trend: not yet measurable post-deploy — pre-deploy bleed window 2026-05-04 → 2026-05-10 closed by f551c17

## Latest deploys (today's runde)

| Commit | What | Risk |
|---|---|---|
| `c062696` | Discord audit-trail wiring (risk-advisor + agent-trigger) | Low; observability |
| `15089c6` | Local-mirror prod-DB safety guard | Low; defense-in-depth |
| `a301b8b` | Gemini soft rate-limit gate (default OFF) | Low; report-only |
| `09dd027` | Retention jobs-done bug fix | Low; pure bug-fix |
| `ee6a8ab` | Retention TTL pass (master) | Low; flag-gated |
| `38921eb` | Gates INSERT wires `decisionCycleId` | Medium; closes audit chain |
| `0ad348f` | Metadata-strip fix on firm-strategy INSERT | Medium; restores attribution. **Awaiting trade-confirm.** |

## Loop ordering (canonical — runCycle())

1. Market data ingest (Twelve Data + OANDA price stream)
2. Step 0a2b: retention self-check (when `RETENTION_ENABLED=true`)
3. Module-Fact-And-Analysis (Prism)
4. Strategy proposers (ORB, scalp-overlap, session-breakout, vol-expansion)
5. `strategy-blade` evaluates gates → writes `gate_decisions` (now with `decision_cycle_id`)
6. `strategy-execution` writes `simulated_orders` (with metadata after `0ad348f`)
7. Position-management tick (break-even, trailing, partials, stale)
8. CIO step
9. Agent-trigger publish (gated)
10. Firm-agents (operator-brief, risk-advisor, etc. — gated)
11. Reconciliation

Don't ask Claude to reorder; ask the code at `apps/worker/src/firm/orchestrator.ts:runCycle()`.

## Health indicators
## Trade Frequency Baseline (XAUUSD Auto-bot)

**Last updated:** 2026-05-11  
**Analysis period:** 30 days (2026-04-11 → 2026-05-11)

| Metric | Value |
|--------|-------|
| Median daily trades | 7.5 |
| P25 / P75 | 3 / 9.75 |
| Min / Max daily | 1 / 24 |
| Trading days active | 18 / 31 |
| Zero-trade days | 13 |
| Today's count | 7 (normal) |

**Peak session:** 13:00–17:00 UTC (London open)  
**Operator question reconciliation:** Baseline is 7–8 trades/day, not 2–5. Days with 2–5 are below-normal. Today tracking on-expectation. See [[2026-05-11-trade-frequency-baseline|detailed analysis]].


- `/health` returns db / broker / blackboard / worker / reconciliation all OK
- `gate_decisions` writing ≥4/hour during market hours
- Worker heartbeat: `lastError=null`, cycle_no monotonically incrementing
- Next metadata-stamped trade SQL returns ≥1 row → flip [[foundation-gate-state]] rule 2

## Open issues

- [ ] **Foundation rule 2 yellow** — awaiting first post-deploy trade for column-level confirm
- [ ] First post-deploy trade SQL probe (run at next session-open)
- [ ] Verify retention pass fires at next UTC-day boundary, reaps ~19k stranded jobs

## Verification commands

```bash
curl -H "Authorization: Bearer $API_KEY" \
  https://api-production-b660.up.railway.app/health
curl -H "Authorization: Bearer $API_KEY" \
  https://api-production-b660.up.railway.app/operator/readiness
curl -H "Authorization: Bearer $API_KEY" \
  https://api-production-b660.up.railway.app/firm-agents/status
```

```sql
-- last metadata-stamped trade
SELECT count(*) AS stamped_trades,
       max(created_at) AS latest_trade
FROM simulated_orders
WHERE created_at > '2026-05-11T00:00:00Z'::timestamptz
  AND strategy_id IS NOT NULL
  AND execution_source IS NOT NULL
  AND atr_at_entry IS NOT NULL
  AND entry_conviction_score IS NOT NULL;

-- last gate_decisions
SELECT max(created_at), count(*)
FROM gate_decisions
WHERE created_at > now() - interval '1 hour';
```

## What never auto-fires

- Disabling a strategy on a single bad cycle ([[Operator-Principles]] rule 1)
- Switching to legacy path on firm errors — surface via Discord, operator decides
- Skipping retention if a deploy mid-cycle interrupts it — runs again next UTC-day

Linked to: [[Nexus-MOC]], [[Module-Orchestrator]] (`runCycle()`), [[Module-Blackboard]], [[Module-Position-Management]], [[foundation-gate-state]], [[metadata-stamping-state]], [[gate-decisions-state]], [[retention-state]], [[firm-agents-state]], [[discord-delivery-state]]
