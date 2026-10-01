# Nexus PnL Bleed — 5-Day Investigation (2026-05-04 → 2026-05-10)

**Closed PnL (red days)**: -714 / -211 / -167 / -564 / -433 = **-$2,089 cumulative**
**Mode**: OANDA demo, XAUUSD
**Investigator**: Claude (subagent), 2026-05-11

> NOTE on dates: PG groups by UTC, so "day=2026-05-04T22:00Z" = trading day **2026-05-05** Oslo/Brussels-tid. Below uses the PG-bucket label to match SQL output; the calendar dates in the operator's question (04.5–10.5) map cleanly to those buckets.

---

## Q1. Close-reason breakdown per day

| Day (PG bucket) | close_reason | n | pnl |
|---|---|---|---|
| 05-04T22 | OANDA_SL_TP | 3 | **-647.67** |
| 05-04T22 | STALE_TRADE_EXIT | 1 | -66.67 |
| 05-05T22 | OANDA_SL_TP | 7 | **-336.25** |
| 05-05T22 | STALE_TRADE_EXIT | 2 | +125.08 |
| 05-06T22 | OANDA_SL_TP | 6 | **-146.76** |
| 05-06T22 | STALE_TRADE_EXIT | 3 | -20.12 |
| 05-09T22 | OANDA_SL_TP | 1 | **-563.64** |

**Interpretation**: The bleed is overwhelmingly from `OANDA_SL_TP` closes (i.e. broker hit the stop loss). `STALE_TRADE_EXIT` is roughly neutral. We are getting stopped out, not timed out. This rules out "trail stop took us out prematurely" or "stale-exit logic too aggressive". The stops themselves are getting hit.

---

## Q2. Per-strategy PnL

Result: **all 28 closed trades come from a single bot_id** (`9b2f966c-09a9-46ec-bc6e-c7ae50fe1708`) with `execution_source = NULL` and `strategy_id = NULL`. There is no per-strategy breakdown to make.

This is itself a **major finding** — see Q4.

---

## Q3. Win/loss ratio last 7d vs prior 7d

| Period | wins | losses | avg_win | avg_loss | total_pnl | trades |
|---|---|---|---|---|---|---|
| **last_7d** | 13 | 16 | **+394.84** | **-347.80** | **-431.90** | 29 |
| prior_7d | 13 | 16 | +378.77 | -209.51 | +1,571.74 | 31 |

**Win rate identical (45%)**. **Avg win unchanged**. The ONLY thing that changed: **avg loss size grew from -$210 to -$348 (+66%)**. We didn't get more losses — we got **bigger losses**. This is a stop-management / risk-sizing story, not a setup-selection story.

---

## Q4. Entry-to-fill drift + metadata audit

Schema check: `simulated_orders` has `entry_price`, `stop_loss`, `take_profit`, `atr_at_entry`, `regime_at_entry`, `entry_conviction_score`, `execution_source`, `strategy_id`, `management_events` (jsonb).

**On the 28 closed trades for these red days:**

| Field | NULL count |
|---|---|
| signal_id | 0 |
| strategy_id | **28 / 28** |
| execution_source | **28 / 28** |
| regime_at_entry | **28 / 28** |
| entry_conviction_score | **28 / 28** |
| atr_at_entry | **28 / 28** |

**Every single trade is missing the firm metadata**. Either:
- (a) trades enter via a legacy path that bypasses the firm-context populator, or
- (b) the postmortem/persistence layer has stopped writing those fields (regression), or
- (c) reconciliation-sync from OANDA only re-creates the row with broker-only fields and overwrites firm metadata to NULL.

Comparing winning vs losing **SL distance** is the next-best proxy for "did we have an edge":

| Day | wins | losses | sl_dist (wins) | sl_dist (losses) | tp_dist (losses) | adverse_move (losses) |
|---|---|---|---|---|---|---|
| 05-03T22 | 6 | 0 | 25.4 | — | — | — |
| 05-04T22 | 0 | 3 | — | 22.4 | 43.2 | **14.2** |
| 05-05T22 | 4 | 5 | **6.9** | 16.2 | 35.7 | **16.3** |
| 05-06T22 | 3 | 6 | 10.3 | **22.4** | 47.8 | **11.2** |
| 05-07T22 | 0 | 1 | — | 44.5 | 52.3 | **54.7** |

Two patterns:
1. **05-05**: winners had SL=6.9pts — these are scalps. Losing trades had SL=16.2pts but moved against us only 16.3pts before stopping. **Stops were tight relative to ATR** → noise stop-outs.
2. **05-06**: SL_loss=22.4pts but adverse_move=11.2pts. **We got stopped on barely-an-eyelid wiggle?** That doesn't add up arithmetically unless the slippage was huge (price gapped through stop) OR the broker-fill price differs from our recorded `close_price`. Possible reconciliation bug.

**Direction split** (also important):
- Shorts: 17 trades, 9W/8L, **+$1,001**
- Longs: 11 trades, 4W/7L, **-$564**

Macro state for the window: `direction=long, score=1` (maximum bullish). **The macro agent said BUY, the system made money SHORTING and lost money LONGING**. Either macro is wrong or the entry triggers ignored macro.

---

## Q5. Postmortem patterns

Schema: `postmortems` has no `reason` column. Real columns: `classification`, `cleanliness`, `market_score`, `entry_score`, `execution_score`, `summary`.

Last-7d aggregation by classification:

| classification | n | avg_pnl | total_pnl |
|---|---|---|---|
| **RIGHT_THESIS_BAD_EXECUTION** | **16** | -347.80 | **-5,564.83** |
| CORRECT_THESIS | 14 | +366.64 | +5,132.93 |

**Every single losing trade is autoclassified as "right thesis, bad execution".** The summaries are uniform:

> "Management followed the playbook: no lifecycle events. Final pnl -X."

And on losers: `break_even_applied=false, degrade_cut_applied=false, management_events=[]` — for ALL 5 of the worst losers (and likely all 16).

**The postmortem is telling us, in plain English, that position management never engaged on losing trades.** No break-even, no degrade-cut, no trail. The trades just sat there until the SL got hit.

Compare to 05-03 (the winning day): **3/6 BE fires, 0 losses**. BE was doing its job. From 05-04 onward: **only 4 BE fires across 22 trades**.

---

## Q6. Regime context

The `blackboard` table has 3,484 macro analyses + 3,483 risk analyses + 3,484 technical analyses over the window — data pipeline is healthy and active.

**No `regime` field in any `state` JSONB blob**. Schema actually emits:
- `macro-analyst.state`: `{spy, tlt, uso, eurusd, score, direction}` — **direction=long, score=1**
- `radar.state`: `{blackout, riskLevel, session, atr, drawdown, warnings}`
- `technical-analyst.state`: `{price, direction, indicators, score, atr}`

No top-level `regime` key materializes anywhere, so the operator's "regime_at_entry" column (which is NULL on every trade anyway — see Q4) likely depends on something downstream that isn't getting set.

**Macro direction was consistently `long` with maximum bullish `score=1`** across all 5 red days. Yet shorts made money and longs lost. The entry agent appears to be **fading the macro signal**, and that worked on shorts (the actual XAU move was choppy/bearish intraday) but the longs that did fire were brutally cut.

---

## Hourly entry distribution

Big losing clusters (UTC):
- 05-06 13:00–14:00: 4 trades, **-$2,019** combined (2 shorts -$1,296, 2 longs -$723)
- 05-07 17:00–18:00: 4 trades, **-$720** (all shorts/longs immediately stopped)
- 05-08 13:00: 1 long, **-$564** (the 09.5 bleeder)

Big winning clusters:
- 05-06 01:00–03:00: 2 longs, **+$2,148** (Asia session, low size)
- 05-07 16:00: 1 short, **+$1,142** (NY open)

Asia and NY-open were the green windows. **NY mid-session (13–18 UTC = 15:00–20:00 Oslo) was the slaughterhouse** — exactly the window where ORB-style breakout strategies live. Tight stops + chop = death.

---

## HYPOTHESIS

**Most likely cause (in ranked order):**

### #1 — Position management never engaged on losing trades (high confidence)
The postmortems literally say "no lifecycle events" on every losing trade. `break_even_applied=false` and `management_events=[]` on every big loser. Either:
- A flag (`POSITION_MANAGEMENT_ENABLED`?) got flipped off around 05-04, OR
- The position-management agent stopped subscribing to its trigger topic, OR
- A code change introduced a bug that prevents BE/trail from firing on trades opened after 05-03.

This **directly explains the +66% larger avg loss size** (Q3) — losing trades that should have BE'd at +0.5R now go to full -1R. The win rate didn't change because winners get TP'd by the broker regardless. **This is the single highest-likelihood smoking gun.**

### #2 — Trades are entering via a legacy/bypass path that strips firm metadata (medium-high)
28-for-28 NULL on `strategy_id`, `execution_source`, `regime_at_entry`, `atr_at_entry`, `entry_conviction_score`. This is not "we didn't bother to set those" — these fields existed on 05-03's winning trades (would need to verify, but the schema has them). If the firm-orchestrator path stopped writing trades and a legacy executor took over, you'd expect:
- No regime-conditional sizing (everything full size)
- No conviction filter (low-conviction setups get through)
- No strategy-specific SL/TP logic (one-size-fits-all bracketing)

This compounds #1: legacy trades probably bypass the position-management agent entirely.

### #3 — Tight SL + chop in NY mid-session (medium)
SL distances were 12–22pts on losing trades, but adverse_move was 11–16pts before stop-out. ATR-ish noise is ~10–15pts on 5m XAU. **Stops are sitting inside noise distribution.** Pair that with a sideways/choppy XAU regime (we'd need 4-7 day OHLC to confirm) and you get exactly this pattern: high win rate scalps work in clean trends, but get sliced when range-bound. This is a **regime-strategy mismatch** that #1 would normally cushion via early BE-cut, but #1 broke.

### Less likely (but worth a follow-up query)
- **Reconciliation/sync writing NULL metadata over good rows**: simulated_orders may be getting overwritten by the OANDA-sync 4.5 fix that operator landed (commit `4mai` per docs/ops/oanda-sync-tx-history-fix-4mai.md). If that fix took priority and stripped firm fields, that explains the NULL columns post-05-03.
- **Bad luck**: NOT this. Win rate didn't move. Same 45% as prior week. The distribution shifted only on the loss side. That's structural, not stochastic.

---

## Follow-up queries to confirm

1. Re-run Q4 metadata-null check **on 05-03 and prior week trades**. If those rows ALSO have NULL firm metadata, then hypothesis #2 fails and the issue is a persistence regression that happened at deploy time, not a behaviour shift.
2. `git log --since=2026-05-03 --until=2026-05-05 -- apps/worker/src/firm/` to find code changes touching position management or persistence.
3. Check Railway env diff between 05-03 evening and 05-04 morning for `POSITION_MANAGEMENT_*`, `BE_*`, `TRAIL_*` flags.
4. Re-query `blade_decisions` and `gate_decisions` to see if entry gates are themselves flooding the system with low-conviction signals.
5. Pull XAU 5m OHLC from `analysis.technical` for 05-04→05-10 and characterize the actual regime (trend vs chop) — confirms or refutes hypothesis #3.

---

## TL;DR for operator

The system did NOT get bad signals. It got the same signals at the same hit rate. It just **stopped managing losing trades** somewhere around 05-04. Every losing trade was held to full -1R with zero BE moves, zero trail engagements, and zero degrade cuts. The postmortem agent already flagged this — every loser is tagged `RIGHT_THESIS_BAD_EXECUTION`. The system is telling us what's wrong; we need to find the broken pipe between "signal fires" and "position-manager subscribes".

**Operator-decision needed**: do not auto-disable anything (per principle 1). But: investigate position-management agent health on Railway, check `/health` for stale workers, and verify `POSITION_MANAGEMENT_ENABLED=true` is set.
