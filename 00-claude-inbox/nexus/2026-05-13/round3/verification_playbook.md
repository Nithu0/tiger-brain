# Verification Playbook — Round 3 Flip (B1 + A2 + later C1)

**RUN T+1h AT: ~11:00 CEST (assumes flip lands ~10:00 CEST, 13.5.2026)**
Adjust forward 1h-real-time after operator confirms actual flip-timestamp in firm-bus feed.

Flags in scope:
- `ENTRY_STACK_COOLDOWN_ENABLED=true` (B1, Karri-approved) — flips gate 4 from soft-log to hard-reject.
- `REGIME_DIRECTION_GATE_ENABLED=true` (C1, conditional on Karri) — separate flip, run same playbook + observe `regime_direction_gate` rows.
- A2 observability (commit `deb7075`) — `regimeDirectionReason` now writes to `blackboard.state` on every cycle. No flag — passive after push.

Tables in play: `gate_decisions`, `simulated_orders`, `blackboard`.

---

## T+1h sanity check (≈11:00 CEST)

Goal: gate is firing, A2 telemetry is writing, nothing exploded.

### Q1 — Cooldown gate is alive

```sql
-- run via nexus-pg MCP
SELECT recorded_at, would_reject, hard_rejected, reason, context
FROM gate_decisions
WHERE gate_name = 'entry_stack_cooldown'
  AND recorded_at > now() - interval '1 hour'
ORDER BY recorded_at DESC
LIMIT 50;
```
Expect: ≥1 row (worker is cycling). Most `would_reject=false` (no stacking attempt). On any `would_reject=true`, `hard_rejected=true` proves the env-flag took effect. If ALL `hard_rejected=false` despite `would_reject=true` → flag did not land. Check Railway.

### Q2 — A2 `regimeDirectionReason` is on the blackboard

```sql
-- run via nexus-pg MCP
SELECT timestamp,
       state->>'regimeDirection'        AS direction,
       state->>'regimeDirectionReason'  AS reason
FROM blackboard
WHERE topic = 'portfolio.regime'
  AND timestamp > now() - interval '1 hour'
  AND state ? 'regimeDirectionReason'
ORDER BY timestamp DESC
LIMIT 20;
```
Expect: every cycle has non-null `reason`. If `reason` column is empty → deploy did not land commit `deb7075`. Topic name may differ — fall back to `WHERE state ? 'regimeDirectionReason'` only and inspect.

### Q3 — No silent error spike

```sql
-- run via nexus-pg MCP
SELECT count(*) FILTER (WHERE status='open')   AS opened_last_hour,
       count(*) FILTER (WHERE status<>'open')  AS closed_last_hour
FROM simulated_orders
WHERE opened_at > now() - interval '1 hour';
```
Expect: opened in low single digits (cooldown WILL suppress some). Zero opens AND zero closes for a market-hours hour → gate too strict OR upstream blocker, investigate immediately.

### Discord briefing line
In the morning briefing (firm-strategy block) look for:
- `Gate hits last 1h: entry_stack_cooldown=N hard, M soft`
- `Regime direction reason dist: ok_up=…, ok_down=…, not_trending=…`

If briefing line is missing, A2 wiring did not reach the briefing renderer — file as observability followup, not a B1 rollback.

---

## T+24h trend check (≈11:00 CEST 14.5)

### Q4 — Gate-firing aggregate

```sql
-- run via nexus-pg MCP
SELECT date_trunc('hour', recorded_at) AS hr,
       gate_name,
       count(*)                              AS evals,
       count(*) FILTER (WHERE would_reject)  AS soft_hits,
       count(*) FILTER (WHERE hard_rejected) AS hard_rejects
FROM gate_decisions
WHERE recorded_at > now() - interval '24 hours'
GROUP BY 1,2
ORDER BY 1 DESC, 2;
```
Expect: `entry_stack_cooldown` hard_rejects total = 2–4 (B1 plan estimate). 0 hard_rejects for 24h on a normal trading day = either Karri's stacking pattern absent (good) or gate not firing (check Q1 still works).

### Q5 — `regimeDirectionReason` distribution (Karri-feedable for C1)

```sql
-- run via nexus-pg MCP
SELECT state->>'regimeDirectionReason' AS reason,
       count(*)                        AS n
FROM blackboard
WHERE timestamp > now() - interval '24 hours'
  AND state ? 'regimeDirectionReason'
GROUP BY 1
ORDER BY n DESC;
```
Expect: `ok_up`/`ok_down`/`not_trending` dominate. If any of `candles_too_short_*`, `fetch_error`, `non_finite_close`, `flat_*` >5% → data-quality bug, send to Karri before he decides C1.

### Q6 — Did blocks clip bleed?

```sql
-- run via nexus-pg MCP
SELECT date_trunc('day', opened_at) AS d,
       count(*)                        AS trades,
       round(sum(pnl)::numeric, 2)     AS net_pnl
FROM simulated_orders
WHERE opened_at > now() - interval '3 days'
GROUP BY 1 ORDER BY 1 DESC;
```
Compare today vs prior loss-cluster days (e.g. 11.5). Fewer trades + flatter PnL on a similar-regime day = working as intended.

---

## T+7d outcome check (≈20.5)

### Q7 — Trade volume + PnL delta (this week vs prior week)

```sql
-- run via nexus-pg MCP
WITH buckets AS (
  SELECT CASE WHEN opened_at > now() - interval '7 days' THEN 'this' ELSE 'prior' END AS w,
         pnl, status
  FROM simulated_orders
  WHERE opened_at > now() - interval '14 days'
)
SELECT w,
       count(*)                          AS trades,
       count(*) FILTER (WHERE status<>'open') AS closed,
       round(sum(pnl)::numeric, 2)       AS net_pnl,
       round(avg(pnl)::numeric, 2)       AS avg_pnl
FROM buckets GROUP BY 1;
```

### Q8 — Hard-reject totals over 7d

```sql
-- run via nexus-pg MCP
SELECT gate_name,
       count(*) FILTER (WHERE would_reject)  AS soft,
       count(*) FILTER (WHERE hard_rejected) AS hard
FROM gate_decisions
WHERE recorded_at > now() - interval '7 days'
GROUP BY 1 ORDER BY hard DESC;
```

### Q9 — Cluster-catch witness

```sql
-- run via nexus-pg MCP
SELECT recorded_at, reason, context
FROM gate_decisions
WHERE gate_name='entry_stack_cooldown'
  AND hard_rejected=true
  AND recorded_at > now() - interval '7 days'
ORDER BY recorded_at;
```
Any row here = 11.5-style cluster attempted + blocked = win. Zero rows over 7d = wait another week before declaring B1 validated.

---

## Rollback triggers

Operator should revert `ENTRY_STACK_COOLDOWN_ENABLED=false` if:

1. **False-positive flood** — `hard_rejects / (soft_hits + non_stack opens) > 20%` over a 4h window. Means cooldown threshold too long; tune `ENTRY_STACK_COOLDOWN_MINUTES` down before re-enabling.
2. **Zero opens for 6h during active session** (LONDON/NY) AND `hard_rejects > 0` — gate is starving the firm.
3. **A2 telemetry missing for >2h** — observability gap, not a B1 problem per se, but rollback C1 if it depends on this signal.
4. **PnL net worse vs prior 7d while regime comparable** (Q7 + manual regime check) — fix did not deliver, revisit Karri.

For C1 specifically: revert if `regime_direction_gate` blocks >30% of trades that would have been winners on prior week's replay (requires Karri's separate analysis — do not auto-decide).

---

Filed by Claude. Source proposals: `B1_entry_stack_cooldown_flip.md`, `A2_null_reason_tagging.md`, `C1_proposal_audit.md`.
