# Blowup 2026-04-21/22: REAL sizing decision vs backfill-import artifact

**Date:** 2026-06-04
**Auditor:** code-1 (read/analysis only — no commits, no DB writes)
**Question (the #1):** Was the Apr 21-22 blowup (size 1.0 → ~95-106 units, ~−$13k/48h) a REAL sizing-engine decision, or a backfill-import artifact (unit error)?
**Verifying:** ai-2's report `2026-06-03_ai-2_intent-vs-execution-audit.md`

---

## VERDICT: REAL

The 95-106 unit positions were genuinely sized by the firm's risk formula and genuinely
filled by OANDA at those quantities. This is **not** a backfill import/unit artifact. I
**agree with ai-2's root-cause** (`7479b20` stacked RANGING SL=$4 × 5% risk × real OANDA
balance ~$8.5k → ~106 units) and with their "no max-units cap was added" finding.

I add one correction/refinement ai-2 did not surface: **the recorded SL/TP on those rows
is NOT $4/$6 — it's ~$12/$24 (TRENDING-style).** The $4 lived ONLY in the size
denominator, not in the actual stop placement. That makes the bug worse than "tight stop,
big size, stop got hit": the position was sized as if the stop were $4 away but the stop
sat ~$12 away, so each adverse move bled 3× the nominal risk budget.

---

## Evidence chain

### 1. The cited rows are all `oanda_backfill_*`, and `size` = OANDA `initialUnits` by construction

The size-70-106 trades on Apr 21-22 (ids 378, 382, 386, 396, 402, 408, 414, 420, 426,
432, 438, 444, 452, 458, 464, 502, 542, 548) are **all** `oanda_backfill_*` rows.

The backfill importer (`apps/worker/src/firm/oanda-sync.ts`) maps OANDA's own fields
verbatim:
- `getClosedTrades` (`oanda.service.ts:839`): `units: Math.abs(parseFloat(t.initialUnits))`
  — pulled straight from OANDA `/v3/accounts/.../trades?state=CLOSED`.
- `backfillClosedTrades` INSERT (`oanda-sync.ts:744-760`): `size = t.units`,
  `entry_price = t.openPrice`, `close_price = t.closePrice`, `pnl = t.realizedPL`.

=> `size` IS OANDA's executed `initialUnits`. There is **no oz↔lot conversion layer, no
scaling multiplier** anywhere between OANDA's number and the DB row. The cross-check the
task asked for ("is size == OANDA initialUnits for the matching oanda_trade_id?") is
answered structurally: **yes, by construction.** `realizedPL` is likewise OANDA's own
(includes financing/commission), not a Nexus recompute. An import/unit error is ruled out:
the loss and the unit count are both OANDA-reported truth.

Net realized on the 18 size>=60 backfill rows in the Apr 21-22 window: **−$10,841**
(consistent with operator's ~−$13k once smaller trades + the open/unrealized leg are
included).

### 2. The size matches the RANGING risk formula precisely

Code at `7479b20` (`managers.ts:953`): `demoSize = (virtualBalance * finalRiskPct/100) / slPoints`
with RANGING → `slPoints=4`, `finalRiskPct=5.0`, `virtualBalance = oandaAccount.balance (~8500)`.

`8500 * 0.05 / 4 = 106.25` → floored ~106. The actual sizes (106 early, drifting to 94 as
balance eroded from losses) track this formula exactly. ai-2's arithmetic is confirmed by
the data.

### 3. KEY REFINEMENT — recorded SL/TP are TRENDING ($12/$24), not RANGING ($4/$6)

Per-row geometry from `export.json` (slPts = |entry−sl|, tpPts = |tp−entry|):

| id | size | slPts | tpPts | 8500·5%/slPts | 8500·5%/4 (RANGING) |
|---|---|---|---|---|---|
| 378 | 106 | 12.37 | 23.63 | 34 | 106 |
| 382 | 106 | 11.51 | 24.49 | 37 | 106 |
| 408 | 103 | 12.62 | 23.38 | 34 | 106 |
| 420 | 101 | 12.70 | 23.30 | 34 | 106 |
| 432 | 70 | 17.44 | 18.56 | 24 | 106 |

Size tracks `balance·5%/4` (RANGING denom) — NOT `balance·5%/slPts` (the recorded stop).
So the engine sized with `slPoints=4` while the stop that was actually placed/recorded was
~$12 (TRENDING). Likely cause: size was computed in the RANGING branch (denominator 4),
but the SL price written to the row came from a different value of `slPoints` at
order-placement / reconciliation time (ATR path `max(12, atr·1.5)`, or OANDA read-back of a
position-manager-set stop). Net effect: **nominal risk budget $425 (5% of $8.5k); real risk
per trade ≈ 106 × $12 ≈ $1,270 — ~3× over budget.** Several rows lost $1,100-1,700, matching
106 units × ~$12-16 adverse move.

### 4. Remediation commits — verified, and confirm NO cap was added

- `8816365` (Apr 21 09:26) — `managers.ts:801` scalp risk **5.0 → 2.5**. One-line knob.
- `50d102a` (Apr 21 01:18) — cap RANGING/VOLATILE to **max 2 simultaneous** trades
  (`maxOpenPositions: isScalp ? 2 : 3`). Trade-COUNT cap, not a per-trade size cap.
- `2b1986b` (Apr 21 09:52) — **env-gate** every override: `REGIME_SLTP_ENABLED`,
  `SCALP_RISK_PCT`, `SCALP_SL/TP`, `VOLATILE_SL/TP`, `USE_OANDA_BALANCE` — all default OFF;
  rollback without code. `dailyLossLimitUSD: isScalp ? 1000 : 500`.

ai-2's claim that **no max-units / max-notional cap was added is CORRECT.** I grepped the
firm path, `oanda.service.ts`, and `paper-execution.service.ts` for
`maxUnits|maxNotional|UNITS_CAP|MAX_POSITION_SIZE|units >` — nothing. The only sizing
guards remain (a) the risk-% knob, (b) the simultaneous-trade count, (c) the daily-loss
limit. The amplification vector `balance · risk% / stopLossPoints` is **structurally
intact** — current firm path `strategy-execution.ts:900-901` has the identical shape with
no upper clamp. A future tight-SL strategy + high balance can re-create a large position
with zero "bug."

---

## Where I agree / disagree with ai-2

- **AGREE:** root cause = formula amplification from `7479b20`, not a comms/transform bug.
  Broker faithfully executed ~106 units; loss is real.
- **AGREE:** remediation lowered risk% + env-gated + count-capped; **no notional/units cap**.
- **AGREE:** amplification vector still live; recommend a hard max-units circuit breaker in
  `placeOandaOrder` + a regression test pinning size under a sane cap for $4-SL × high
  balance (Karri-owned — risk change).
- **REFINE:** ai-2 wrote "RANGING SL tightened to $4 → stop got hit." The persisted rows
  show ~$12 stops with $4-denominator sizing. The $4 was a *phantom denominator*, not the
  real stop. The mechanism is "sized for a $4 stop, ran a $12 stop" — a sizing/SL
  inconsistency, strictly worse than a uniformly-tight-stop story. Worth flagging to Karri
  because a max-units cap alone wouldn't have caught the SL/size denominator mismatch.

---

## Can the artifact-vs-real question be settled from available data? YES — already settled.

`size` on the backfill rows is definitionally OANDA `initialUnits` (oanda-sync.ts:744-760 +
oanda.service.ts:839), and `pnl` is OANDA `realizedPL`. Both are broker truth, not Nexus
recomputes. No further data needed to rule out an import artifact.

**The one thing data alone can't show** (code already answers it): which *value of
slPoints* was used for the size denominator vs. the recorded SL. To confirm the
"$4-denominator / $12-recorded-stop" mismatch on a live row rather than inferring it from
geometry, pull the structured entry log line `managers.ts:956-957`
(`OANDA sizing: balance=… finalRiskPct=… slPoints=… → units=…`) from Railway Worker logs
for Apr 21, or the `simulated_orders` / blackboard `xauusd.execution.reports` `slPoints`
field for those cycleIds. That would pin the denominator used at sizing time.

---

### Evidence index
- Backfill size mapping: `apps/worker/src/firm/oanda-sync.ts:650-654, 744-760`
- OANDA initialUnits source: `apps/worker/src/services/oanda.service.ts:839` (`units: Math.abs(parseFloat(t.initialUnits))`)
- Root-cause sizing formula: `7479b20` `managers.ts:953` (`demoSize = balance·risk%/slPoints`), RANGING branch `managers.ts:774,796,804`
- Current firm sizing (vector intact, no cap): `strategy-execution.ts:900-901`
- Remediation: `8816365`, `50d102a`, `2b1986b`
- Data: `data/pull/export.json` (CSV) rows oanda_backfill_378..548
