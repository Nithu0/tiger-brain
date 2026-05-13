# deb7075 deploy status — VERDICT: LIVE

**Timestamp**: 2026-05-13T08:10Z (10:10 CET)
**Push**: 2026-05-13T07:35Z (Wed 09:35 CET) — deb7075 + 46a2534 + 5c07156 + f0a25c0
**Verdict**: **LIVE on Worker** — verification queries at T+1h are valid.

## Evidence

### 1. `/health` endpoint
```
build.commit: "5c07156d"   (= HEAD on main, past deb7075)
worker.lastHeartbeatSec: 40
worker.lastCycleNo: 12
worker.lastCycleDurationMs: 4788
db.ok: true (43ms)
broker.ok: true (demo, balance 89245.47)
```
Note: `build.deployedAt: null` — minor field not populated, ignore.

### 2. A2 (regimeDirectionReason) — **CONFIRMED LIVE**
Fresh `xauusd.portfolio.context` rows (last 4h) all carry the new field:
```
reason="not_trending" — count=15
```
**Earliest occurrence**: `2026-05-13T07:54:01Z` — i.e. new field started flowing ~19 min after push. That timestamp is the de-facto deploy time.

### 3. A1 (regime_direction_gate persistence) — **CODE LIVE, DORMANT BY FLAG**
`gate_decisions` table:
- Latest row across all gates: `2026-05-12T17:35:53Z` (~14h stale)
- Zero `gate_name='regime_direction_gate'` rows exist yet

This is **expected**: the gate persists only when invoked, and `REGIME_DIRECTION_GATE_ENABLED=false` (per phase-status). The stale gate_decisions across all names also suggests the broader gate-recording path is dormant outside London/NY hours OR gated on something else — worth a separate look, but not a deb7075 regression.

### 4. A3 / A4 — not directly verifiable yet
- A3 (`atr_at_entry` on session-breakout): no new SB trades today; will show on next fill.
- A4 (daily_trade_cap allow-list widening): dormant (`DAILY_TRADE_CAP_ENABLED=false`).

## Anomalies noted

1. **`gate_decisions` flat since 12.5 17:35Z** — even pre-deploy gates (entry_stack_cooldown, risk_level, ranging_conviction) stopped writing ~14h ago. May correlate with off-session hours, or a separate regression. **Flag for round-4 forensics** — not a deb7075 issue (the table was already stale before push).
2. `blackboard.lastDecisionSec: 51830` (~14.4h) in `/health` aligns with the gate_decisions gap — same upstream cause.
3. All 15 fresh `regimeDirectionReason` values = `"not_trending"` — no distribution yet to assess A2's 9-bucket discriminator. Need trending sessions to see other reasons (candles_empty, fetch_error, flat_close_move, etc).

## ETA / next
- T+1h verification (~09:10Z / 11:10 CET): re-run A2 reason-histogram. If London opens with trend, expect non-`not_trending` reasons to appear.
- Investigate gate_decisions/lastDecisionSec gap separately — pre-existing, not caused by deb7075.
