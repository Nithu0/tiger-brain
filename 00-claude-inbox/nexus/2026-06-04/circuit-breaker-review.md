# Circuit-breaker review — PR #61 (hard position-size circuit breaker)

Reviewer: Claude (code-1), read-only audit 2026-06-04
Scope: verify Karri's PR #61 (merge 0f4cb44, commits 2e5cdbf/fff86c4) on origin/main.
Verdict feeds operator's cap-confirmation back to Karri.

## TL;DR

- **Sound + on the live path: YES.**
- **Would have stopped the Apr-21 blowup: YES** (every oversized leg blocked).
- **Coverage: per-trade only.** Aggregate/concurrent exposure is NOT capped — but in the
  actual Apr-21 kill, each concurrent leg was independently >300% notional and >80 units,
  so per-trade blocking catches all of them anyway. Aggregate is a real but secondary gap.
- **Cap recommendation: CONFIRM 300/80.** Tightening to 250 buys almost nothing net
  (~$0.4k) while sacrificing ~$1.2k more in blocked winners. 300/80 is the right call.

## 1. Placement — confirmed on the LIVE firm path

`positionSizeCircuitBreaker()` is a pure exported fn in `strategy-execution.ts`
(line ~118). It is called inside `maybeExecuteProposal()` at line ~938:

- AFTER size calc: `const size = Math.floor(Math.abs(sizeRaw))` (line ~923).
- BEFORE the broker: the only `placeOandaOrder("XAUUSD", ...)` call in the file is at
  line ~974, gated behind `if (!paperOnly)`. The breaker `return`s before reaching it.
- On block: logs `[firm.circuit-breaker]`, shadow-logs `pre-check`, returns
  `{ executed: false }`. Rejects (does not clamp).

Live-path proof (not legacy):
- `orchestrator.ts:571` → `runStrategyExecution(this.board, this.db)` every cycle.
- `runStrategyExecution` (line 289) → `maybeExecuteProposal` (line 349) → breaker.
- This is the firm strategy-execution path. Legacy bot-cycle is intentionally paused
  (bots status-filtered out; comment at line ~303). The breaker sits on the path that
  actually places OANDA orders. Single chokepoint — there is exactly one `placeOandaOrder`
  call site in the file, and the breaker is the last gate before it.

Logic:
```
notionalPct = equity > 0 ? (size*entry/equity)*100 : Infinity
blocked = size > maxUnits || notionalPct > maxNotionalPct
```
- Two independent ceilings, OR-combined (either trips a block). Correct.
- **Fail-safe at 0 equity: YES** — `equity > 0` false → `Infinity` → always blocked.
- Boundary is exclusive (`>` not `>=`): exactly-at-cap passes. Fine, immaterial.
- Reads env each call via `envBool/envInt/envFloat` (all exist, lines 85/93/101) with
  bounds: NOTIONAL_PCT∈[50,2000], UNITS∈[1,10000]. 30s revert via Railway, no code. Good.

One nit (not a defect): `entryPrice` is the *intended* entry (proposal.state.entryPrice),
not the broker fill. Fill slippage is tiny vs a 300% cap, so this does not weaken the guard.

## 2. Cap math vs the real blowup — verified against data/pull/export.json (193 trades)

The 95-106u Apr-21/22 katastrofe trades, checked against the EXACT origin function
(equity ≈ $90k):

| trade | units | notional% | breaker |
|---|---|---|---|
| Apr21 #378 (106u@4783) | 106 | 563% | BLOCKED |
| Apr21 #382 (106u@4785) | 106 | 564% | BLOCKED |
| Apr22 98u@4763 | 98 | 519% | BLOCKED |
| monster 446u@4731 | 446 | 2344% | BLOCKED |
| normal 18u@4500 | 18 | 90% | passes |

All 8 spot-checks (incl. units-cap-only and zero-equity) pass as expected.

- **Would 95-106u trades be blocked by MAX_UNITS=80? YES** — every one of the 18 trades in
  the 90-130u band exceeds 80 units AND ~500% notional. Double-caught.
- **Would the >300% tail be blocked by MAX_NOTIONAL_PCT=300? YES.**
- My independent recompute of the proposal's table (size>80 set): **21 trades, 19% WR,
  −$11.66k** — matches the proposal's "~80% losers, ~−12k" claim. Calibration is honest.

### 300 vs 250 — confirm 300

Net effect at equity≈$90k proxy (blocked-trade PnL is mostly losses avoided; "winnerPnL_lost"
is the cost of false-positives):

| cap | #blocked | PnL of blocked | winner-$ sacrificed |
|---|---|---|---|
| 80u / 300% | 26 | −$11,830 | $5,160 |
| 80u / 250% | 31 | −$12,208 | $6,360 |
| 80u / 200% | 48 | −$11,921 | $9,762 |
| 80u / 150% | 69 | −$11,587 | $14,901 |

Going 300→250 blocks 5 more trades, recovers only ~$0.4k more in avoided losses, but
sacrifices an extra ~$1.2k of winners (incl. a real +$2,113 on 2026-06-03 at 391%). The
marginal 250-300% band is near break-even, so tightening trades real upside for negligible
protection. **300/80 sits right at the elbow — confirm it.** Re-tighten only if Karri sees
fresh oversized losers clustering in the 250-300% band post-deploy.

## 3. Per-trade vs aggregate — PER-TRADE ONLY (flag for Karri, do not implement)

The breaker caps each trade in isolation. It does NOT sum concurrent open positions.

Apr-21 reconstruction from the data:
- 10 trades that day, **peak 3 concurrent** open positions.
- Peak simultaneous notional ≈ **$1.52M = ~1690% of equity** across those 3.
- BUT the largest single leg was already 564% / 106u — each leg independently trips both
  ceilings. So for THIS blowup, per-trade blocking stops every leg before it opens; the
  aggregate stack never forms.

The aggregate gap is real for a *future* failure mode: many trades each just under the cap
(e.g. 4× at 290% notional / 79u) summing to a blowup. The breaker would let all four
through. The proposal itself acknowledges this ("Stacking ... is a separate axis handled by
per-strategy cooldowns/caps — not this breaker").

**Recommendation to Karri (his money-path, not mine to build):** add a portfolio-level
aggregate-notional ceiling (sum of open + pending notional / equity) as a follow-up. Today
it is partially covered by daily_trade_cap + per-strategy cooldowns, but there is no hard
aggregate notional brake. Low urgency given per-trade catches the historical case; worth a
dedicated guard before live-capital flip.

## 4. Tests — real, exercise the rejection

6 unit tests in `strategy-execution.test.ts`, all green (ran node --test against working
tree, 15/15 in file incl. these 6; logic re-verified standalone against the exact origin fn):

1. normal 18u@4500 ≈90% → passes
2. **oversized 106u@4784 ≈563% → blocked** (the literal Apr-20 blowup profile — real)
3. units ceiling: 90u @ tiny price (notional low) → blocked on units only
4. disabled (446u) → never blocks
5. zero equity → blocks (`inf%`)
6. boundary exclusive: exactly 300% → passes

These exercise the actual rejection of a 106-unit / 563%-notional trade, not a smoke test.
1082/1082 worker tests green per PR, tsc clean.

## Bottom line for the operator

Confirm **MAX_NOTIONAL_PCT=300, MAX_UNITS_PER_TRADE=80, ENABLED=true** to Karri. The breaker
is correctly placed on the live broker chokepoint, fails safe, is data-calibrated, tested,
and would have blocked every leg of the Apr-21 −$7,119 day. One follow-up to raise with
Karri (not blocking): aggregate/concurrent-notional cap as a separate guard before live flip.
