---
title: LANE 7 — Per-strategy edge analysis (strategy scorecard)
date: 2026-06-04
lane: 7
project: nexus
tags: [nexus, strategy, edge, karri, scorecard, sweep]
data_source: data/pull/ (export.csv, strategies.json, strategy_states.json, threads_closed.json, readiness.json) pulled 2026-06-04 16:17Z
---

# LANE 7 — Per-strategy edge analysis

**TL;DR:** The headline -$11.3k loss is almost entirely the **legacy auto-managed path ("XAUUSD Auto")**, which is **already OFF** (`LEGACY_XAUUSD_EXECUTION_ENABLED=false`). The new firm strategies are all enabled but barely trading — they're heavily gate-blocked, so we have **near-zero live edge data** on them. Nothing is currently bleeding-while-live in a way that warrants a pause; the real finding is the **opposite problem: the firm strategies aren't getting enough executions to judge.** Only vol-expansion has a (tiny, 3-trade) positive sample.

---

## Data caveats (read first)

1. **Two account epochs.** The `export.csv` ledger (194 trades, Apr 16 → Jun 4) runs on a ~$10k demo account that blew down to ~$2.9k on 21-apr. Current broker balance is **$89,795** (readiness.json) — the demo account was recapitalized/reset since. So the -$11.3k is **historical legacy damage**, not current live exposure.
2. **`strategies.json` aggregation collapses everything into 3 buckets** (auto-managed, xau-mean-reversion, xau-volatility-expansion). The finer truth is in `export.csv`'s `bot` column (4 labels) + `threads_closed` `strategyId` (per-firm-strategy).
3. **Data freshness flag: last signal ~1522 min old (~25h)** at pull time (weekend/session gap). Strategies aren't producing fresh signals right now — expected, not a fault.
4. **Firm strategies barely execute.** Of last 50 closed threads: session-breakout proposed 31×, **executed 1×** (29 stuck PROPOSAL_PENDING). vol-expansion 3 threads, 1 executed. The gate stack is doing most of the filtering.

---

## (a) + (b) Per-strategy metrics + statistical read

Computed from `export.csv` (193 PnL-bearing closed trades). t-stat = mean-PnL / standard-error; |t|>2 ≈ significant once n>30.

| Strategy (bot label) | Trades | Total PnL | WinRate | PF | Expectancy/trade | t-stat | Verdict |
|---|---|---|---|---|---|---|---|
| **XAUUSD Auto** (legacy auto-managed) | 183 | **-$11,323.88** | 37.2% | 0.64 | -$61.88 | -1.77 | Net-negative, big sample. BUT already OFF. |
| **External (OANDA)** (manual/external fills) | 4 | -$1,208.48 | 25.0% | 0.01 | -$302.12 | -3.26 | Not a Nexus strategy — out of scope. |
| **XAUUSD Mean Reversion** | 4 | -$124.86 | 25.0% | 0.84 | -$31.22 | -0.12 | Too small to judge (noise). |
| **XAUUSD Volatility Expansion** | 3 | **+$2,414.78** | 100.0% | ∞ | +$804.93 | +4.69 | Positive but n=3 — promising, not proven. |

### XAUUSD Auto time-segmented (the important breakdown)

| Segment | Trades | Total PnL | WinRate | PF | Exp/trade | t-stat |
|---|---|---|---|---|---|---|
| Before 21-apr | 61 | +$44.12 | 39.3% | 1.11 | +$0.72 | +0.38 |
| **21-apr blowup day** | 10 | **-$7,119.43** | 10.0% | 0.22 | -$711.94 | -2.29 |
| 22-apr onward | 112 | -$4,248.57 | 38.4% | 0.81 | -$37.93 | -0.82 |

**Read:**
- The legacy path's damage is **62% concentrated in one catastrophic day (21-apr, -$7.1k).** That's the katastrofedag pattern Karri has flagged — a regime/trend-pause blindness event, not slow edge decay.
- **Even excluding the blowup, post-22-apr legacy is -$4.2k over 112 trades** (PF 0.81, exp -$38/trade). That's a persistent negative drift, BUT t=-0.82 means it is **NOT statistically distinguishable from zero** — i.e. consistent with a zero-edge strategy losing the spread/commission, not a proven money-loser beyond noise. The blowup day IS significant (t=-2.29).
- Conclusion: legacy auto-managed has **no demonstrated positive edge** and one proven catastrophic tail. Correctly retired.

### Statistical bottom line
- **Net-negative beyond noise:** only the 21-apr legacy blowup day (t=-2.29) and the External/OANDA bucket (t=-3.26, but n=4 and not a real strategy).
- **Too-small-sample to judge:** mean-reversion (n=4), vol-expansion (n=3), and effectively ALL six firm strategies (1–4 live executions each).
- **No firm strategy currently has a statistically defensible edge — positive or negative.** We are data-starved on the live firm path.

---

## (c) Strategy name → code module → flag → live state

| Data label / slug | Code module (`apps/worker/src/firm/`) | Env flag | Doc default | LIVE state (strategy_states.json / phase-status) |
|---|---|---|---|---|
| `auto-managed` / "XAUUSD Auto" | legacy execution path (not a firm/ module; pre-firm) | `LEGACY_XAUUSD_EXECUTION_ENABLED` | — | **OFF** (phase-status: "Legacy-path for XAUUSD = AV") |
| `trend-following` | `trend-following/trend-following-manager.ts` | `TREND_FOLLOWING_ENABLED` | false | **enabled=true** (live); shouldTrade=false (no_trend) |
| `breakout-continuation` | `breakout-continuation/breakout-continuation-manager.ts` | `BREAKOUT_CONTINUATION_ENABLED` | false | **enabled=true** (live); shouldTrade=false (no_valid_range) |
| `pullback-continuation` | `pullback-continuation/pullback-continuation-manager.ts` | `PULLBACK_CONTINUATION_ENABLED` | false | **enabled=true** (live); shouldTrade=false (no_trend) |
| `mean-reversion` / "XAUUSD Mean Reversion" | `mean-reversion/mean-reversion-manager.ts` | `MEAN_REVERSION_ENABLED` | false | **enabled=true** (live); shouldTrade=false (adx_too_high 25>25) |
| `volatility-expansion` / "XAUUSD Volatility Expansion" | `vol-expansion/vol-exp-manager.ts` | `VOL_EXPANSION_ENABLED` | false | **enabled=true** (live); shouldTrade=false (direction_blocked: long disabled) |
| `session-breakout` / `xau-session-breakout` | `session-breakout/session-break-manager.ts` | `SESSION_BREAKOUT_ENABLED` | false | **enabled=true** (live); shouldTrade=false (price inside range) |
| `orb` | `orb/` | `ORB_ENABLED` | — | **LIVE** (phase-status) |

> Note: doc defaults say `false` for the 6 firm flags, but live Railway state has them all `enabled=true`. Defaults are the code-safe baseline; operator flipped them live.

---

## (d) LIVE-enabled but bleeding → pause candidates

**Honest answer: none that are statistically bleeding right now.**

- The big bleeder (legacy auto-managed, -$11.3k) is **already OFF.** No action needed beyond confirming it stays off.
- The six firm strategies are enabled but execute so rarely (1–4 fills each, 29/31 session-breakout proposals never executed) that there's **no bleed to point at and no edge to defend.** Pausing them would just freeze data collection while they're not losing money anyway.
- vol-expansion is the only one with a positive (if tiny) sample — keep it on.

The actionable risk concern is **not** "pause a bleeder" — it's "the firm strategies are gate-starved and we can't learn from them." That's a different conversation for Karri (gate-loosening / observe-only attribution), not a pause.

---

## (e) Zero / near-zero trade (dead or dormant)

All measured against live executions (not proposals):
- **trend-following** — 0 attributed closed trades. Dormant (gate: no_trend persistently).
- **breakout-continuation** — 0. Dormant (no_valid_range).
- **pullback-continuation** — 0. Dormant (no_trend).
- **session-breakout** — 31 proposals / **1 execution** over 8 days. Effectively dormant; proposals die at gates/execution.
- **mean-reversion** — 4 lifetime executions. Near-zero.
- **vol-expansion** — 3 lifetime executions. Near-zero (but the only positive one).

This is the headline: **5 of 6 firm strategies are functionally dormant despite being enabled.** Either the gates are too tight for current regime, or these strategies' setups simply don't fire in the recent HIGH_VOLATILITY / range-bound tape (price sat inside session range, ADX hovering at the 25 mean-rev cutoff, long-direction blocked by filter).

---

## Ranked scorecard (best → worst edge confidence)

1. **vol-expansion** — KEEP. Only positive sample (+$2.4k/3, PF ∞). Needs 30+ trades for autotune; currently starved. *Confidence: low (n=3) but only green signal.*
2. **mean-reversion** — NEEDS MORE DATA. -$125/4, PF 0.84, within noise. Approved-verbally LIVE per library. Keep observing.
3. **trend-following / breakout-continuation / pullback-continuation** — NEEDS MORE DATA. Zero executions; can't score. Dormant.
4. **session-breakout** — NEEDS MORE DATA + INVESTIGATE. 31 proposals, 1 fill — why are 97% of proposals not executing? Library flags a load-bearing SL flaw (full-range stop, 43% OANDA_SL_TP hits over 30d). Worth Karri's eye on the proposal→execution gap.
5. **legacy auto-managed** — STAYS RETIRED. -$11.3k, no proven edge, one katastrofedag tail. Already OFF; confirm it never gets re-enabled.

---

## NEW TASKS

- **[Karri]** Decide whether the 5 dormant firm strategies should stay enabled-but-gated, or whether gate thresholds are too tight for the current HIGH_VOLATILITY/range regime. We have ~zero live edge data because they barely fire (e.g. session-breakout: 1 fill / 31 proposals over 8 days). This is a strategy/regime call, not infra. → frame as proposal in `docs/strategy/proposals/`.
- **[Karri]** Session-breakout proposal→execution gap: 30 of 31 proposals over 8 days never executed (PROPOSAL_PENDING/REJECTED). Confirm whether this is intended gate behaviour or a silent block worth investigating. Cross-ref the known full-range-SL flaw (`_library/trading/strategies/session_breakout.md`).
- **[Karri]** vol-expansion is the only positive strategy (n=3) and "direction_blocked: long disabled per filter" in current state — confirm the long-direction filter is intended and not suppressing the one strategy showing edge.
- **[infra/Claude]** Build per-firm-strategy PnL attribution that survives the account-epoch reset. Current `strategies.json` collapses everything into 3 buckets and the export.csv is dominated by a retired legacy path on an old account. We need clean per-slug expectancy/PF from the post-recapitalization epoch only, so the next scorecard isn't drowned by legacy history. (Observability only — no trade-decision change, runs freely per prinsipp-6.)
- **[infra/Claude]** Add a "dormant strategy" surfacing to the morning briefing: any enabled strategy with 0 executions over N days should be reported (NOT auto-disabled, per prinsipp 1). Pure reporting.
- **[operator]** Confirm the demo account epoch boundary (the recap from ~$10k → $89.8k) so we can date-cut the ledger correctly. Without it, every PnL aggregate is contaminated by the retired legacy path's -$11.3k.
- **[operator]** Confirm `LEGACY_XAUUSD_EXECUTION_ENABLED=false` should remain permanent. It's the only proven net-negative path; no reason to ever re-enable.

---

_Generated by Claude analysis lane, 2026-06-04. All live-trading recommendations routed to Karri per strategy/risk protocol. No flags flipped, no proposals auto-sent — operator/Karri gate._
