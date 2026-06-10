# WF lane: overblock-vs-dormant (READ-ONLY diagnosis) — 2026-06-08

**Verdict: KNOWN DORMANT-STRATEGY STATE. Gates are NOT over-blocking.** The 0-wouldFire / 0-trades-since-06-05 is caused upstream of the gate layer — strategies are not *proposing* signals because live market conditions don't satisfy any strategy's entry criteria. The ADX-cascade (ai-1's lane) contributes to the mean-reversion strategy's self-reject but is not the primary cause.

All data pulled over 443 (`bash pull-nexus-data.sh`), fresh at 2026-06-08 ~10:55 UTC. Build `5fd39f9b`. System health: all green (db 3ms, broker demo connected bal 90058.74, worker heartbeat 41s, 55 cycles/h, lastError null).

---

## 1. The funnel proves it's not the gates

`/decision-funnel?days=7` (and 3d, and 24h/72h status-report all agree):

| stage | 7d | 3d | 24h |
|---|---|---|---|
| totalCycles | 46 | 22 | — |
| **signalsProposed** | **3** | **1** | — |
| decisionsEmitted | 0 | 0 | — |
| tradesOpened | 15* | 2* | 0 |

\* tradesOpened in funnel reflects historical/position-mgmt activity, not new strategy entries in-window; `closedLast24h=0`, `openPositions=0`.

The collapse happens between cycles (46) and signalsProposed (3). Gates only get evaluated when a signal is proposed, so they barely run.

### Per-gate reject % (7-day window)

| gate | evaluated | hardRejected | wouldReject | reject % |
|---|---|---|---|---|
| session_block | 19 | 0 | 0 | 0% |
| entry_stack_cooldown | 19 | 0 | 0 | 0% |
| risk_level | 19 | 0 | 1 | 0% hard / 5% would |
| sl_cooldown | 22 | 1 | 1 | 4.5% |
| regime_direction_gate | 21 | 0 | 0 | 0% |
| daily_trade_cap | 21 | 0 | 0 | 0% |
| **mean_revert** | 46 | 3 | 3 | **6.5%** |
| scalp_overlap_asia | 19 | 0 | 0 | 0% |
| ranging_conviction | 19 | 0 | 0 | 0% |

24h window: every gate evaluated exactly 1×, **0 rejections across all gates.**
72h window: identical shape, only `mean_revert` rejects (1 hard) + 1 `sl_cooldown`.

**Top reject reasons (7d):** `mean_revert_block` ×3, `sl_cooldown_active` ×1. That's the entire gate-rejection volume over a week. An over-blocking system would show double/triple-digit hardRejected counts. We have 4 total. Gates are wide open.

---

## 2. Where signals actually die: the strategy-evaluation layer (pre-gate)

`/firm/strategy-states` — all 6 strategies enabled, all `shouldTrade:false`, each with a market-condition self-reject (NOT a gate):

| strategy | enabled | rejectReason |
|---|---|---|
| trend-following | true | `session_not_allowed: WEEKEND` (STALE — lastEval 06-06 17:16, age 41.6h) |
| breakout-continuation | true | `no_valid_range` |
| pullback-continuation | true | `pullback_too_deep: 16.49 ATR > 2` |
| mean-reversion | true | `adx_too_high: 43.8 > 25 (strong trend, not mean-revert phase)` |
| volatility-expansion | true | `ATR ratio 1.03 < threshold 1.3` |
| session-breakout | true | `Range too wide ($84.97)` |

These are the strategies refusing to fire on their own logic — XAUUSD at ~4299 is in a strong directional/high-volatility regime (`regime.risk=high`, `portfolio=HIGH_VOLATILITY`). In that regime: mean-reversion correctly stands down (ADX high), pullback sees too-deep retraces, vol-expansion sees ATR not expanding, breakout sees no clean range. This is exactly the designed dormant behaviour — strategies are mutually exclusive across regimes and none matches current conditions.

`/operator/status` confirms: `execution.canExecute:true`, `blockers:["Waiting for better data/conditions"]`. The system itself reports it is waiting, not blocked. `blackboard.lastDecisionSec=3945` (~66 min).

---

## 3. Shadow-cycle math checks out

Prompt cited ~1840 shadow cycles. `analysis_snapshots` writes 388/24h (and market/sentiment snapshots match at 388). 388 × ~4.75 days (06-05 → 06-08 midday) ≈ 1843. So the ~1840 figure is the analysis/shadow-evaluation count, NOT gate evaluations. Strategies ARE being evaluated ~16×/h continuously — they're just all self-rejecting on conditions. Data pipeline is alive and writing (all memory tables green except `reddit_posts` yellow, last write 05-27).

---

## 4. ADX-cascade note (ai-1's lane — read-only flag, no edit)

Cross-cutting data-quality issue visible but NOT touched: in `strategy-states.indicators`, **every** strategy reports `adx:null` and `atr14:null` while the human-readable `rejectReason` quotes concrete values (`adx_too_high: 43.8`, `ATR ratio 1.03`). So the indicator *values* exist in the eval path but are not surfacing into the `indicators` payload — null-rendering cascade. Also `market.atr=null, market.adx=null` at top level.

Impact on THIS lane's verdict: the ADX cascade does not *cause* the dormancy. Even with ADX/ATR fully wired, the regime is genuinely high-vol-trending (ADX 43.8 is a real strong-trend reading), which legitimately stands down 4 of 6 strategies. The cascade is a transparency/observability bug, not a trade-suppression bug. Mean-reversion's self-reject is correct given a true ADX of 43.8. Leave the fix to ai-1.

---

## 5. Foundation gate (separate, not the cause)

`recommendedAction.mode=OBSERVE`, reason `Foundation YELLOW: reddit_posts last write 11 days ago`. This blocks *activation of new gates/strategies* — it does NOT block existing strategies from trading. Not the dormancy cause, but worth a backfill: reddit_posts ingestion has been dead since 2026-05-27.

---

## Bottom line

- **OVER-BLOCKING: ruled out.** 4 total gate rejections over 7 days; 0 over 24h. Per-gate reject ≤6.5% (mean_revert), most 0%.
- **DORMANT-STRATEGY STATE: confirmed.** All 6 strategies self-reject at the eval layer on real market conditions; current XAUUSD regime (high-vol trending, ADX ~43.8, price ~4299) matches none of the entry profiles. System self-reports "waiting for better data/conditions."
- **ADX-CASCADE: present but secondary** (transparency bug; indicators render null). Does not cause dormancy. Belongs to ai-1.

## Non-build follow-ups surfaced (no code changed this lane)
1. reddit_posts ingestion dead since 05-27 → backfill (foundation YELLOW). Ops, not strategy.
2. trend-following strategy-state is STALE (last eval 06-06, "WEEKEND" reason persisting into Monday London-active) — possible refresh bug in trend-following eval scheduling. Diagnosis only; flag to whoever owns trend-following eval cadence.
3. (ai-1) ADX/ATR null-rendering cascade in strategy-states indicators payload + top-level market.adx/atr.
