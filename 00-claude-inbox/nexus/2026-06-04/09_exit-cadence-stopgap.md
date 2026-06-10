# Exit-cadence / stop-gapping audit — verify ai-2's "10-min gapping" claim

Date: 2026-06-04
Scope: READ/ANALYSIS ONLY. Verify whether the −$1500 losses on ~100-unit positions are caused by SL/TP being checked only ~every 10 min (gapping through stops between cycles).
Sources: `apps/worker/src/firm/orchestrator.ts`, `session-window.ts`, `services/oanda.service.ts`, `services/paper-execution.service.ts`, `jobs/bot-cycle.ts`; `data/pull/export.json` (194 trades), `weaknesses.json`.

## TL;DR

The "10-min gapping" story is **largely wrong for the trades that actually hurt.** The big losses (−$1000 to −$1715) are **real OANDA broker fills** (`oanda_*` ids) whose stops are **broker-side OANDA stop-loss orders** that execute on tick at the broker, *independent of worker cadence*. Gapping/slippage beyond the intended stop is only **~5.7% of total loss dollars**. The losses are dominated by **intended stop-distance × large position size**, not by exit cadence.

- **Stops are broker-side**, not loop-side, on the firm path (and on every `oanda_*` trade in the data).
- **$ attributable to gapping: ~$1,870 out of ~$33,483 total loser pnl (~5.7%).** And that $1,870 is a slight *overstate* (see size caveat). The intended-stop portion of those same losers is ~$30,979.
- **Recommended fix: notional/size cap (+ broker-side guaranteed stops as cheap insurance). NOT tighter monitor cadence** — cadence is not enforcing these exits.

## 1. Cadence — what the code actually does

`orchestrator.scheduleNext()` reschedules each cycle using `getSessionCadence(window.state).fullCycleIntervalMs` (default 60s). `session-window.ts:205-230` cadence table:

| Session state | fullCycleIntervalMs |
|---|---|
| active / high-vol | 30,000 (30s) |
| normal | 60,000 (60s) |
| quieter | 120,000–180,000 (2–3 min) |
| pre/post / slow | 300,000 (5 min) |
| **DEAD (closed market)** | **600,000 (10 min)** |

So "~every 10 minutes" is the **worst-case, dead-market** cadence only. During live trading sessions the loop runs every **30–120s**, not 10 min. ai-2's self-report quotes the dead-market number as if it were the steady-state.

**But cadence is moot for the exit:** see §2.

## 2. Broker-side vs loop-side stops — the decisive finding

`orchestrator.ts:912-914` (`monitorPositions`):
> "OANDA is the source of truth for price and position state. **Nexus NEVER closes a trade on its own — OANDA handles SL/TP.**"

`monitorPositions()` only calls `manageFirmPositions()`, whose comment (line 940-941) is explicit: "Does NOT close positions — only adjusts SL/TP levels" (break-even, trailing).

Orders are placed in `oanda.service.ts:323-331` with **`stopLossOnFill` and `takeProfitOnFill` attached to the MARKET order**. These become server-side resting orders at OANDA that fill on tick — the worker loop is not in the exit path at all. `modifyOandaStopLoss()` (line 490) only *moves* the resting order.

→ **On the firm path, stops are broker-side. The worker cadence (30s or 10 min) does not gate when a stop fires.** OANDA fires it on the next qualifying tick.

### The one loop-side path (and why it's not the culprit here)

There IS a cadence-bound paper-close: `paper-execution.service.ts:checkAndClosePositions()` evaluates `if (currentPrice <= sl) closeReason = "SL_HIT"` using the *polled* price, then applies a slippage model. This is called from the **legacy `jobs/bot-cycle.ts:118`**, not from the firm orchestrator. This path *would* gap (it fills at the polled price, which can already be past SL, and cannot see intra-cycle ticks). It only governs `uuid`-id paper trades — and those are NOT where the big losses live (see §3).

## 3. Data: gap vs intended stop (export.json, 194 trades, 190 closed w/ sl+close)

For each loser, compare `close_price` vs `sl` (worse-than-stop = gapped through):

| | losers | gapped through stop | ~at stop | better than stop (exited early) | no SL |
|---|---|---|---|---|---|
| All | 116 | 85 | 6 | 23 | 2 |

**Dollar decomposition (all gapped losers):**
- Sum of ALL loser pnl: **−$33,483**
- Intended-stop portion (entry→sl distance × size): **−$30,979**
- Beyond-stop / gap portion (sl→close distance × size): **−$1,870**
- **Gap = 5.7% of (intended + gap).**

**Crucial split by trade origin:**

| origin | losers | gapped | gap $ |
|---|---|---|---|
| `oanda_*` (REAL broker fills) | 69 | 58 | ~$1,575 |
| `uuid` (paper-sim) | 47 | 27 | ~$295 |

**Every big loss (pnl < −$900) is an `oanda_*` id, bot "XAUUSD Auto"** — i.e. real OANDA broker fills with broker-side stops. Examples:

```
oanda_backfill_382 long e=4784.66 sl=4773.15 close=4765.82 pnl=-1714.81 size=106  gap=$7.32/u
oanda_backfill_378 long e=4782.54 sl=4770.17 close=4765.70 pnl=-1532.53 size=106  gap=$4.47/u
oanda_backfill_420 long e=4773.74 sl=4761.04 close=4759.99 pnl=-1191.70 size=101  gap=$1.05/u
oanda_backfill_438 long e=4763.33 sl=4751.27 close=4751.16 pnl=-1025.50 size=98   gap=$0.11/u
```

Note backfill_438: the close ($4751.16) is **$0.11 past** a $12-wide stop — that is a clean broker stop fill with trivial slippage, yet it's a −$1025 loss. The loss is the **$12 stop distance × 98 units**, not the gap. backfill_382's larger $7.32 gap is the genuinely gappy one, but even there the gap ($776) is ~45% of a loss whose stop-distance portion is ~$1,220 on 106 units.

The −$1500-class losses are explained by **stop_distance ($11–17) × size (~100 units)**. With 100 units, every $1 of stop distance is ~$100, so a normal 12–15 point gold stop is already a $1200–1500 hit by design.

### Size caveat
The `size` column in export.json is scaled relative to recorded pnl: `(close−entry)*size` overshoots recorded pnl by ~15% (e.g. backfill_382 implies −$1996 vs recorded −$1715). So the absolute $1,870 gap figure is a modest **overstate**; the real gapping dollars are lower. The **5.7% ratio is robust** because the scale cancels in numerator and denominator.

## 4. Cross-check against weaknesses.json self-report

The same self-report that says "Position SL/TP checks run every ~10 minutes... fast moves can gap through" *also* says, three entries down:
- "Execution mode: **demo — trades are simulated**"
- "**No slippage model in paper execution — fills assume exact price**"

These contradict each other and contradict the data:
1. If fills assume exact price (no slippage), there is *no* paper gapping mechanism at all — so the 10-min claim can't bite the paper trades it's describing.
2. The trades that actually lost big are **real OANDA fills with broker-side stops**, not the demo paper path the weakness entry is talking about.

The weakness entry is a plausible-sounding generic risk that **does not match how the firm path executes or where the losses came from.** It conflates the dead-market 10-min cadence with the steady-state, and assumes loop-enforced exits that don't exist on the broker path.

## 5. Conclusion + recommended fix

**Is exit-cadence a real problem?** Marginally, and only on the legacy paper path (`uuid` trades, ~$295 of gapping). On the firm/broker path it is **not** a problem — stops are server-side and fire on tick.

**What actually causes the −$1500 losses:** intended stop distance (12–17 gold points) multiplied by oversized positions (~100 units). This is a **position-sizing / notional** issue, not an exit-timing issue.

**Recommended fix, in priority order:**
1. **Notional / unit cap (primary).** Cap units so a normal-distance stop costs a bounded $ (e.g. risk-per-trade in $, then size = riskUSD / stopDistance). This directly shrinks the −$1500 tail and also makes any residual gap cost proportionally less. This is the highest-leverage change. NOTE: sizing is a **strategy/risk change → goes through Karri** per project protocol.
2. **Broker-side guaranteed stops (cheap insurance, secondary).** OANDA supports `guaranteedStopLossOnFill` — already broker-side, so this only adds *gap protection*, converting the ~5.7%/~$1.5k tail to ~0 at a small premium. Low effort, low risk. Still a risk-change → Karri.
3. **Tighter monitor cadence — NOT recommended as the fix.** It would only affect the legacy paper path's $295 of gapping and does nothing for the broker-side losses. If anything, raising the dead-market 600s cadence is cosmetic.

**Push-back delivered:** the data contradicts the "10-min gapping → −$1500 losses" story. The fix is sizing/notional (Karri) plus optional guaranteed-stops, not cadence.
