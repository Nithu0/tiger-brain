# Nexus recon — 2026-06-13 (ai-1 / READ-VERIFY only)

Build live = `12a4c25` (== `origin/main` HEAD). Pull via HTTPS/443 API (token from railway).
Today = **Saturday** → market closed; matters for the 0-trade reading.

---

## TL;DR (4 asks the prompt set)

1. **ai-1 handoff (PR #99 / `b1cbdbc`, doc `docs/ops/handoff-ai1-2026-06-11.md`):** two items needing my access.
   - (#1) Validate `BC_RANGE_SEARCH_TIGHTEST` (PR #98, default OFF) on **6mo real M1, FULL pipeline** (confirmation + direction-filter + SL/TP/BE/trail) before enabling. Karri's backtest was underpowered (9–15 trades, +0.78R vs −0.20R — suggestive not proof). Range-detection unlock 43%→74% is solid; question is only whether extra ranges are profitable or noise. **STILL OPEN** — flag absent on Worker.
   - (#2) Verify the recon delta is not an **untracked open OANDA position**. Check OANDA `/openTrades` directly. 0 `status='open'` rows in DB, so delta is either (a) unregistered realized loss/fees or (b) an orphan open OANDA position (the scary case → unmanaged). **STILL OPEN** — needs OANDA token (I have it; not run this session — read-only recon only).

2. **Why DEGRADED:** ONLY `reconciliation.ok=false`. `balanceDelta = −$544.67` (broker $89,288.68 vs expected $89,833.35). `driftCountUnresolved=0`, `lastError=null`, worker cycling (cycle #415). NOT a crash. **Note: delta WORSENED from −$445 (06-11) to −$544.67 (06-13)** — ~$100 more drift in 2 days. db/broker/blackboard/worker all `ok=true`.

3. **Firm trading?** YES — back to trading. 7d = **4 trades** (3 long / 1 short). 0 trades/24h is **Saturday market-closed**, not gating. The 0-trades/3-days regime was the NOISY_CHAOTIC over-classification — now fixed (see #4).

4. **Learning loop:** derive HEALTHY — `latestSuccess 2026-06-13` (04:45Z), 5 consecutive successes since the 06-08 `MODULE_NOT_FOUND` crash (fixed by `676c222` firehose script-path fix, this branch). Lessons = **4 proposed / 0 approved** (+3 archived). All proposed conf **0.12–0.14** — far below 0.5 inject floor and auto-promote gate. Low because barely any trade data (~n=2 buckets), not broken formula.

---

## DEGRADED detail

```
status: degraded
db ok (40ms) | broker ok demo bal=89288.68 | blackboard ok | worker ok cycle#415 lastErr=null
reconciliation ok=FALSE  balanceDelta=-544.67  expected=89833.35  driftUnresolved=0
  lastSyncCycleIso = 2026-06-12T03:26Z   lastBackfillRowIso = 2026-04-28 (stale, expected)
```

`/operator/status-report`: foundation **RED** for `continuous-table-dead: gate_decisions 0 writes/24h`
+ `memory-yellow: reddit_posts 4d`. Warning: "No gate_decisions in last 24h — either no blade
cycles ran, or new-gates code not deployed." → **This is weekend/market-closed**: blade decisions
last seen 2026-06-12 17:59Z (Friday NY close, ~24h ago); market.raw still flowing (29 min old, slowed).
recommendedAction = OBSERVE. Foundation-RED here is expected weekend behavior, not a fault — but it
DOES block any new-gate/new-strategy activation until Monday (operator-prinsipp 4).

**The only real money-near open item = the −$544.67 recon delta (handoff #2).** Growing → worth ai-1's
OANDA `/openTrades` check to rule out an orphan position.

---

## What landed in the 3-day gap (money-near flagged)

| PR | SHA | What | Activation state |
|---|---|---|---|
| #101 | `f687c70` | regime-gate: add `xau-mean-reversion` to MEAN_REVERSION_STRATEGIES (ai-1 finding) | merged, behavioral fix |
| #102 | `76fa80c` | **price-relative ATR thresholds** (hard gates) — gold $4214 vs $2000-cal → 32% cycles false NOISY_CHAOTIC → 0 trades/3d | code default OFF, **but `ATR_PCT_THRESHOLDS_ENABLED=true` IS SET ON WORKER → LIVE** |
| #103 | `cb044d0` | scale soft ATR scoring bands w/ price (entry-thesis + challenge-agents) + absolute-$ audit doc | same flag → LIVE |
| #98 | `60308a5` | BC range-window search (`BC_RANGE_SEARCH_TIGHTEST`) | **OFF** (absent on Worker) — handoff #1 to validate |
| #97 | `ce7870f` | watch: clean derive-status digest + stale-derive WARN | obs-only |
| #91 | `bc433d7`/`b0cbee8` | learning unblock: confidence `max(wr,1-wr)*min(1,n/8)` + auto-promote MIN_OBS 20→8 | LIVE in build |
| #92 | `f4bfadf` | risk-gate narrowed to high+extreme | LIVE |

### ATR fix (#102/#103) — answer to "did it reduce NOISY_CHAOTIC?"
- `ATR_PCT_THRESHOLDS_ENABLED=true` is **confirmed set on Worker** → the price-relative classifier is active.
- Current `/operator/regime`: **RANGING**, ADX 18.8, ATR 0.273, vol=low, tradeability=poor, source=twelvedata, fallback=OFF. **No NOISY_CHAOTIC.**
- Firm went from 0-trades/3d → 4 trades/7d → consistent with the over-gating being cleared.
- Caveat: today is low-vol Saturday RANGING, so this isn't a stress test of the chaotic path. Worth re-confirming the chaotic-classification rate on a high-vol weekday now that the flag is live (the #102 commit measured 32% false-chaotic pre-fix).

### #91 confidence-rewrite — confirmed LIVE
Old formula `min(0.95, n/50)` plateaued at ~0.11–0.16 at ~2 trades/day → nothing ever cleared threshold (structurally muted). New = signal-strength `max(wr,1-wr)*min(1,n/8)`; "an 86%-WR n=7 cluster now lands ~0.75 → injectable." Build `12a4c25` contains `bc433d7` → live.
- Current proposed lessons 0.12–0.14 → these are ~50%-WR, n≈2 buckets (low signal AND low n). **None near 0.5 inject / auto-promote (consistency≥0.8, MIN_OBS 8).** Need a higher-WR cluster with more trades — gated by trade volume, which is gated by market being open + the ATR fix letting trades through. So the chain is now unblocked; just needs data to accumulate.

---

## Open for ai-1 (my queue)
1. **BC #98 6mo validation** (needs M1 backtest infra) — gate before operator sets `BC_RANGE_SEARCH_TIGHTEST=true`.
2. **OANDA `/openTrades` orphan check** (needs OANDA token) — rule out unmanaged position behind the −$544.67 (and growing) delta; verify oanda-sync import is actually running (lastSyncCycle 2026-06-12).
3. (watch) Re-confirm NOISY_CHAOTIC rate on a high-vol weekday now ATR-pct flag is live.

Invariants respected: tighten-only SL, default-OFF for trade-altering, REPORT-only on health. No flips made.
