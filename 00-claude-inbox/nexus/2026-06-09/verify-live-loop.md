# Nexus live-loop verify — Tuesday 2026-06-09 (market open)

READ/VERIFY ONLY. Data pulled over 443 at ~11:20 CET. Live commit `362eafac`. Source: `data/pull/` + Railway `Worker` env (flag states only, no secrets).

## TL;DR

- **Worker healthy, cycling.** db ok, broker demo ok (bal €89,915), reconciliation 0 drift. Cycle #45, heartbeat 4s, 55 cyc/hr, lastError null.
- **Gates biting today:** only `risk_level` (RISK_LEVEL_HARD_GATE) is hard-rejecting — 3/6 cycles in 24h (3/7 over 3d). `mean_revert` 1 hard-reject. Everything else evaluated-and-passed (LIVE but not biting today).
- **Circuit-breaker: NO clamps today.** Today's 2 trades were ~150% and ~58% notional — under the 300% cap. And they're `oanda_import` (external FVG), not firm-sized, so the breaker path doesn't even touch them.
- **Lesson loop stops at auto-promote, and it's DATA-THIN, not broken.** Derive succeeded 06-09 04:22. Lessons 4,5 have `sample_size=1` → fail the `>=20` SQL prefilter. They will NOT auto-promote and will NOT inject. Separately, injection is also **not wired into agent prompts at all** (second, structural stop).
- **No anomaly.** PnL today -€142.93 (28.6% of daily limit), within normal variance. No new error classes.

## 1. Health / cycling

`/health` 09:21Z: status ok. db latency 3ms; broker demo, configured, bal 89915.81; blackboard `lastMarketRawSec=6`, `lastDecisionSec=4035` (~67min — expected: firm is in WAIT_FOR_MORE_DATA, thesis quality 31/100, entry score 28<37, so no fresh decision emitted; not a fault). worker heartbeat 4s, cycle #45, 55 cyc/hr, lastError null. Reconciliation: 0 unresolved drift, balanceDelta 38.37.

Memory tables all green (gate_decisions +55/24h, market/analysis_snapshots ~700/24h). Only yellow = `reddit_posts` stale 12d (known, non-blocking).

Session: LONDON_ACTIVE. Regime: RANGING. foundationStatus = **RED** — driven by `risk_level` gate-saturation (3/6 hard-rejects), exactly the gate flagged below.

## 2. Per-gate LIVE/inert (3d funnel + 24h report)

Env (Worker service) — all gate flags `true`: RISK_LEVEL_HARD_GATE, MEAN_REVERT_GATE, REGIME_DIRECTION_GATE, DAILY_TRADE_CAP, SL_COOLDOWN, NEW_GATES_SOFT_LOG, VOL_EXP_MEAN_REVERT_BLOCK, STRATEGY_BLADE_NEW_GATES, POSITION_SIZE_CIRCUIT_BREAKER.

> Caveat: the `config` block in `/firm/risk-snapshot` reports `slCooldownEnabled:false`, `dailyTradeCapEnabled:false`, and the `/operator/status-report` runtimeManifest shows several gate flags `<unset>`. Those reflect the **API service** env, not Worker. The Worker env (above) and the actual funnel behaviour are the source of truth for what bites the trade loop.

| Gate | Evaluated (3d) | Hard-rejected | Status |
|---|---|---|---|
| `risk_level` (RISK_LEVEL_HARD_GATE) | 7 | **3** (risk_level_high ×2, elevated ×1) | **LIVE — biting.** Only gate hard-rejecting. 3/6 in 24h (>50%) → status-report warns "consider loosening", foundation RED. |
| `mean_revert` | 8 | **1** (mean_revert_block) | **LIVE — biting lightly.** 4 hard-rejects over 7d. |
| `regime_direction_gate` | 7 | 0 | LIVE, evaluating, not biting today (0 rejects 3d & 7d). |
| `daily_trade_cap` | 7 | 0 | LIVE, evaluating, not biting (volume too low to hit cap=6). |
| `sl_cooldown` | 7 | 0 | LIVE, evaluating; 1 hard-reject over 7d window, 0 today. |
| `session_block` | 7 | 0 | LIVE, pass-through. |
| `entry_stack_cooldown` | 7 | 0 | LIVE, pass-through. |
| `scalp_overlap_asia` | 7 | 0 | LIVE, pass-through. |
| `ranging_conviction` | 7 | 0 | LIVE, pass-through. |

All nine gates are producing rows (evaluated>0) → none inert. "Pass-through" gates are confirmed-LIVE but conditions to bite haven't occurred today. The only gate actually rejecting entries is `risk_level`, with `mean_revert` a distant second.

gateImpact (7d): `risk_level` would-have-blocked 1 trade, a winner, netPnlIfActivated -2112.54 — i.e. activating it cost one winning trade this window. Worth noting for Karri but it's the gate doing its hard-reject job.

## 3. Circuit-breaker (POSITION_SIZE_CIRCUIT_BREAKER_ENABLED=true)

Cap = maxNotionalPct 300% (default), maxUnits default; clamp = `min(maxUnits, 300%·equity/price)`.

**No CLAMPED events on today's trades.** Today's 2 closed trades (both `oanda_import:xau-fvg`, external FVG executions):
- 03:38Z short 31u @ 4334.9 → notional ~$134k = ~150% of €90k equity. Under cap.
- 02:35Z long 12u @ 4335.0 → notional ~$52k = ~58%. Under cap.

Largest notional today: the 31u short (~$134k, ~150%). Nowhere near the 300% ceiling.

Two important caveats:
1. The big positions (158u/$717k on 06-01, 114u/$512k on 06-03) predate breaker activation (06-08) AND are `oanda_backfill`/`oanda_import` — external, not firm-sized.
2. The breaker only sits in the **firm strategy-execution sizing path** (`strategy-execution.ts:986`). Today's trades came via OANDA import (Karri's FVG, executed broker-side), so the breaker would not engage even if they were huge. There were **zero firm-side strategy executions today** to exercise the breaker on. So "no clamp" = "no firm-sized trade happened," not "breaker proven on a big trade."

## 4. Lesson loop end-to-end — WHERE IT STOPS

Derive: **succeeded** 06-09 04:22Z (latestSuccessDate 2026-06-09). Preceding 06-03→06-08 all failed (`MODULE_NOT_FOUND: /app/apps/worker/scripts/firehose/derive-lessons.mjs` — cwd/path bug; the 362eafac deploy fixed it, first green run is today). Auto-promote is chained at the end of derive (`derive-lessons.mjs:370`, gated by LESSON_AUTO_PROMOTE_ENABLED=true), so it DID run today.

Two proposed lessons (both same fingerprint: TRENDING/unknown-session/OANDA_SL_TP, 14.3% WR over 7 trades, -2108 PnL):

| id | role | status | outcome_score | confidence | sample_size |
|---|---|---|---|---|---|
| 5 | trade-critic | proposed | -0.714 | 0.140 | **1** |
| 4 | risk-advisor | proposed | -0.714 | 0.140 | **1** |

**Will auto-promote pick them? NO.**
- Auto-promote SQL: `WHERE status='proposed' AND sample_size >= 20` (`LESSON_AUTO_PROMOTE_MIN_OBSERVATIONS` unset → default 20).
- `sample_size=1` → excluded by the prefilter before consistency is even checked.
- **Critical nuance:** `sample_size` is NOT the trade count. The 7 trades feed `confidence = min(0.95, n/50) = 7/50 = 0.14`. The `sample_size` column starts at 1 and only `+1` via ON CONFLICT when the SAME fingerprint re-derives on a later daily run (a cross-day vote counter). So reaching `>=20` requires this exact pattern to re-derive on ~20 separate days.
- Consistency would actually PASS if it got there: outcome_score -0.714 → wr=0.143 → consistency max(.143,.857)=0.857 ≥ 0.8. So the ONLY thing blocking promotion is the N≥20 vote count.

**Will they inject? NO (two independent stops):**
- (a) They're not approved (counts: approved=0), and injection reads `status='approved'` only.
- (b) Even if approved, `buildLessonInjection` (the function that fetches approved lessons via `listApprovedFor`) is **never called anywhere in the worker** — grep across `apps/` non-test = 0 consumers. Injection into agent prompts is unwired. (Also: the injection min-confidence default is **0.5** in `injection.ts:53`, not 0.40 — and `LESSON_INJECTION_MIN_*` env is unset, so 0.5 stands. conf 0.14 would fail that too.)

### Conclusion: where the loop stops today
The loop runs derive → propose → (auto-promote scan) and **stops at auto-promote** because lessons are **DATA-THIN, not broken**. The pipeline is mechanically healthy (derive green today, promote chained & enabled, consistency logic would pass). It stops because:
1. `sample_size` (cross-day vote count) = 1 « 20. Needs ~20 daily re-derivations of the same fingerprint, OR the threshold lowered (Karri-gated — this is a trade-altering switch).
2. Downstream of promotion, prompt-injection is **not wired** (`buildLessonInjection` has no caller) — a structural gap that would block injection even with approved lessons. This is infra Claude can fix, but it changes trade-decisions (lesson→prompt) so per prinsipp 6 the *activation* gates via Karri; wiring it dormant/behind a flag does not.

So: derive works, promote can't fire (thin), inject can't fire (thin + unwired). Net = capture/derive layer is live and correct; the "acts-on-it" half hasn't reached its first eligible lesson.

## 5. Anomalies since activation

None material.
- PnL by day: …06-04 -55, 06-05 +263, (weekend/Mon gap), 06-09 -143. No step-change. Today -142.93 = 28.6% of €500 daily limit, status ok.
- No new error classes. derive-lessons error cleared (was the MODULE_NOT_FOUND chain, now green).
- Direction mix balanced (24h 1L/1S; 7d 6L/9S, no bias warning).
- killSwitches empty. riskEvents are all stale (newest 06-02 NEWS_BLACKOUT warn; criticals are 04-10).
- Reconciliation clean (0 drift).
- Only standing flag: foundation RED from `risk_level` saturation (3/6) — that's the gate working as designed; report-only per operator prinsipp 1, no auto-action.

## Pointers for Karri / operator (report-only, no action taken)
- `risk_level` hard-rejecting >50% of cycles + foundation RED → decide loosen vs keep (it blocked 1 winner this week, netPnl -2112 if-activated). Karri call.
- Lesson auto-promote will never fire on `sample_size` until the same pattern re-derives ~20 days, OR `LESSON_AUTO_PROMOTE_MIN_OBSERVATIONS` is lowered. Trade-altering → Karri.
- Lesson→prompt injection is unwired (`buildLessonInjection` no caller). Infra gap; wiring behind a flag is Claude-ownable, activation Karri-gated.
