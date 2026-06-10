# Nexus anomaly sweep — 2026-06-10 (READ/VERIFY ONLY)

**Pulled:** 2026-06-10T12:39Z over /443. Build live=`f4bfadff`. Mode=demo.
**Verdict:** healthy infra=YES, but **system is GATED INTO PARALYSIS — 0 trades for 3rd day (06-10)**. Foundation=RED.

---

## TL;DR

| Question | Answer |
|---|---|
| Worker healthy / cycling / no new errors? | YES. hb=39s, cyc/h=54, lastError=null, db ok, broker connected (demo). |
| Reconciliation clean? | YES. driftCountUnresolved=0, balanceDelta=$38.38 (small, expected). |
| Trading, or over-gated? | **OVER-GATED.** 0 trades today, 3 trades in trailing 3d. risk_level hard-rejects 21/22 cycles, mean_revert 47/70. |
| PnL step-change / blowup / clamp? | No blowup. No clamps, no killSwitches. dailyLoss today=$0. Last close was -172.88 (06-09 14:16, a mean-rev trade). Expectancy flat at -50.97 (n=202, unchanged — because nothing new is trading). |
| nexus-watch overnight? | YES, ran as scheduled (cron `*/30 6-21 UTC Mon-Fri` + 04:35 daily heartbeat). 19 digests 06-10. **No ALARM fired.** All digests HEALTHY. |

---

## 1. Health / infra — GREEN
- worker.ok=true, lastHeartbeatSec=39, cyclesPerHour=54, lastCycleDurationMs=14399, **lastError=null**.
- db.ok=true (6ms). broker.ok=true demo (75ms), balance €89,742.94, openTrades=0, unrealizedPL=0.
- blackboard: lastMarketRawSec=41 (fresh), lastDecisionSec=502.
- reconciliation: **clean** — 0 unresolved drift, balanceDelta $38.38, expectedBalance 89704.56.
- Memory tables all green except **reddit_posts yellow** (last write 06-09 12:23, ~1d stale — minor, recurring).
- Runtime manifest: 0 anomalies, all flags match expected.

## 2. Over-gating — THE HEADLINE
**The system is NOT trading because the gates reject nearly everything — but the root cause is NOT the ADX/regime gates biting. It's the opposite: the regime gates are BLIND.**

Decision funnel (3d): totalCycles=78, **signalsProposed=0**, decisionsEmitted=0, tradesOpened=3 (all from before window edges).
- `risk_level`: **24/29 hard-rejected** (`risk_level_high`). Top blocker.
- `mean_revert`: **48/78 hard-rejected** (`mean_revert_block`). Second.
- `regime_direction_gate`, `daily_trade_cap`, `scalp_overlap_asia`, `ranging_conviction`, `session_block`, `sl_cooldown`: **0 rejects each** — these are NOT the problem.

Status-report warnings (24h):
- mean_revert hard-rejected 47/70 (>50%) → "consider loosening".
- risk_level hard-rejected 21/22 (>50%) → "consider loosening".
- recommendedAction.mode = **DIAGNOSE**. foundationStatus = **RED** (2 gate-saturation reds + reddit yellow).

regime = **NOISY_CHAOTIC**, noTradeBias = **9/10**, enabledManagers = [momentum_breakout] only. Latest thesis: SHORT q64. Latest decision: REJECTED "Mini-Blade REJECT: risk_level_high".

## 3. ROOT CAUSE (carried from 06-10 10:24Z autonomous-watch note + confirmed here)
**ADX and ATR are `null` in strategy-states and market data** (`market.atr=null, market.adx=null`; every strategy's indicators show `adx:null atrRatio:null`). The ADX publish-shape fix (Fix A+B, the #1 P0) has NOT landed. So:
- The regime classifier defaults to NOISY_CHAOTIC / risk=high because it can't read trend strength.
- That high-risk default is exactly what makes `risk_level` hard-reject 21/22 cycles.
- So the "over-gating" is a **downstream symptom of blind ADX**, not a too-tight threshold per se.

Karri landed #92 (RISK_LEVEL_HARD_GATE narrowed full-set → high+extreme) on 06-10 to mitigate the over-block, plus b0cbee8 (fail-conservative breaker, learning unblock, ORB_ONLY safeguard). But **none of these is the ADX publish-shape fix** — ai-1 is working Karri's risk/learning items, not the ADX P0. Until ADX populates, regime gates stay blind and the firm stays at ~0 trades.

## 4. PnL / risk — no blowup
- expectancy -50.97, winRate 37.6%, PF 0.70, sharpe -0.11 (n=202). **Unchanged** vs 06-08/06-09 watch digests — frozen because no new fills.
- rDistribution: 20 recent trades, avgR -0.392, winRate 15%, worst bucket -1.5R..-1R (10 trades). Poor but not deteriorating.
- dailyLoss today=$0 / limit $500 (0%). **No clamp, no killSwitch.** dayChange=0.
- Note: 06-09 18:00 digest briefly showed `broker.ok=False` + dailyLoss -315.81 (63% of limit). By 06-10 broker recovered and the day reset — transient, resolved, not flagged.
- gateImpact (7d): risk_level would-have-blocked 1 winner, netPnlIfActivated -2112.54 → i.e. activating it historically AVOIDS loss. The gate isn't obviously wrong on PnL; the problem is total paralysis.

## 5. nexus-watch overnight — RAN, NO ALARM
- cron: `*/30 6-21 * * 1-5 UTC` + `35 4 * * *` daily heartbeat. By design, no dense overnight coverage outside that window — the single 04:35Z run + business-hours cadence is expected, not a gap.
- 06-10: 19 digests, 02:35Z → 12:30Z, all **HEALTHY**. 06-09: 22 digests through 18:00Z.
- **No ALARM/ALERT/CRITICAL string in any 06-09 or 06-10 digest.** Cloud-side anomaly alerts (fab56f3) had no hard-loss/streak/activation page either.
- derive-status: latestSuccess 2026-06-10, failedToday=False. Lessons: 4 proposed / 0 approved / 3 archived. (Note: `/firehose/derive-status` returned null fields on the canonical path this pull — overview path works; minor endpoint inconsistency, not an outage.)

---

## TOP ANOMALY
**Blind ADX/ATR (null) → regime stuck NOISY_CHAOTIC/high → risk_level hard-rejects ~95% of cycles → 0 trades for the 3rd straight day. Foundation RED.** The fix that matters (ADX publish-shape Fix A+B) is still unlanded; Karri's #92 narrowing helps the over-block math but does not restore ADX, so the firm remains gated into paralysis.

REPORT ONLY — no auto-disable, no gate changes (operator-prinsipp 1). Next unblock = land ADX publish-shape P0, then re-measure funnel.
