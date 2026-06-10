# WF lane: cloud-alert-enablement — RUNBOOK (operator-flip)

Date: 2026-06-08
Author: wf worker agent (read-only; no flips performed)
Source commit: `fab56f3` feat(notifications): cloud-side anomaly alerts
Scope: produce the exact ordered Railway-flip sequence + recommended thresholds + post-flip verification for the 4 default-OFF cloud alerts. **Nothing was flipped. No code changed.**

---

## TL;DR

Four REPORT-only alert families are merged and wired into the always-on Worker cycle, all default OFF, behaviour-neutral (operator-prinsipp 1 — they re-read the same signals the live gates read, never change cap/pause/gate logic or any trade). The delivery plumbing they need is ALREADY live on Worker:

- `DISCORD_ALERTS_WEBHOOK_URL` = SET
- `DISCORD_NOTIFICATIONS_ENABLED=true`, `DISCORD_SEND_ALERTS=true`
- `DAILY_LOSS_CAP_ENABLED=true`, `LOSS_STREAK_PAUSE_ENABLED=true` (so the loss-cap/streak probes have real underlying signals — not inert)

So flipping the four enable flags is sufficient; no webhook setup needed. Recommended order: hard-loss first (smallest blast radius, single code path), then loss-cap/streak, then activation-health, then flow-watcher.

---

## The 4 alert families + exact flag names / defaults / thresholds

### 1. Hard-loss alert — `detector.ts`
Fires an extra A_ALERT when a single trade closes with `pnl <= -HARD_LOSS_ALERT_USD`, alongside (not instead of) the routine TRADE_CLOSED line. Debounced per orderId.

| Env var | Default | Notes |
|---|---|---|
| `HARD_LOSS_ALERT_ENABLED` | `false` | master gate |
| `HARD_LOSS_ALERT_USD` | `400` | positive USD magnitude; clamped to `[1, 100000]`; garbage/out-of-range silently falls back to 400 |

Delivery path: goes through the FULL notification stack (`delivery.ts`). Therefore it ALSO obeys `DISCORD_NOTIFICATIONS_ENABLED` + `DISCORD_SEND_ALERTS` and routes to `DISCORD_ALERTS_WEBHOOK_URL ?? DISCORD_WEBHOOK_URL`. All three preconditions are already true on Worker.

### 2 + 3. Loss-cap / streak + activation-health — `loss-and-activation-monitor.ts` (orchestrator Step 0a2e)
One module, two independent enable flags. Posts directly via `postWebhookFireAndForget` to `DISCORD_ALERTS_WEBHOOK_URL ?? DISCORD_WEBHOOK_URL` — **bypasses** the `DISCORD_SEND_ALERTS` / `DISCORD_NOTIFICATIONS_ENABLED` toggles (different path than #1). Per-signal debounce persisted in `firm_state` inside an advisory-locked txn.

**2a/2b — daily-loss-cap halt + loss-streak pause:**

| Env var | Default | Notes |
|---|---|---|
| `LOSS_CAP_ALERT_ENABLED` | `false` | enables BOTH the daily-loss-cap probe and the loss-streak probe |

- Daily-loss-cap probe re-reads `checkDailyLossCap` → only meaningful if `DAILY_LOSS_CAP_ENABLED=true` (it IS, on Worker).
- Loss-streak probe reads recent closed trades per strategy. Only fires for strategies listed in `LOSS_STREAK_PAUSE_STRATEGIES` AND when `LOSS_STREAK_PAUSE_ENABLED=true` (both set on Worker). Uses `LOSS_STREAK_PAUSE_TRIGGER` (default 3, range 2..10) as the streak count.
- **CAVEAT (flag to operator/Karri, not a blocker):** the probe's recency guard is HARDCODED to `< 2h` since last close (line 167), but Worker has `LOSS_STREAK_PAUSE_HOURS=4`. The actual pauser presumably uses the 4h env; the alert mirror uses 2h. Net effect: the alert can under-fire (miss a streak the live pauser still considers active between 2–4h after the last close). Read-only mismatch, no trade impact. Worth a follow-up to read `LOSS_STREAK_PAUSE_HOURS` in the probe so the alert window matches the pause window.

**3 — activation-health:**

| Env var | Default | Range | Notes |
|---|---|---|---|
| `ACTIVATION_HEALTH_ALERT_ENABLED` | `false` | — | enables ADX-null + gate-100%-reject probes |
| `ACTIVATION_HEALTH_ADX_CYCLES` | `10` | 1..1000 | consecutive ADX-null technical-fact rows before alert (weekday-only; stays quiet if < N rows of history) |
| `ACTIVATION_HEALTH_GATE_CYCLES` | `20` | 1..1000 | window size (most-recent `gate_decisions` rows) for the 100%-reject check |
| `ACTIVATION_HEALTH_GATE_MIN_EVALS` | `10` | 1..100000 | min gate evals in window before its reject-rate counts (avoids false alarms on a 1–2-eval gate) |
| `LOSS_ACTIVATION_MONITOR_COOLDOWN_MIN` | `30` | 1..1440 | per-signal debounce minutes (covers all of 2a/2b/3) |

`gate_decisions` is actively written by strategy-blade + new-gates (verified), and `xauusd.market.raw` carries the ADX in `state.indicators` — so both probes have real data.

> **COORDINATION NOTE:** the ADX-null probe directly touches the ADX-activation question that `ai-1` owns (ADX/regime P0 fix). If `ai-1`'s fix is mid-flight, the ADX-null alert may fire legitimately (ADX genuinely null) — that is the probe doing its job, not a false positive. Recommend enabling `ACTIVATION_HEALTH_ALERT_ENABLED` AFTER `ai-1`'s fix lands, or accept that early fires are signal, not noise.

### 4. Flow watcher — `flow-watcher/index.ts` (orchestrator Step 0a2d)
7 known-failure signals (S1 worker-stall, S2 restart, S3 stacking, S4 silent-blocker, S5 bb-staleness, S6 drift, S7 attribution-NULL). Posts changes-only (state-diff) with a 15-min cooldown, direct to `DISCORD_ALERTS_WEBHOOK_URL ?? DISCORD_WEBHOOK_URL`.

| Env var | Default | Notes |
|---|---|---|
| `FLOW_WATCHER_ENABLED` | `false` | single master gate; thresholds are code constants (not env-tunable): S1 5min, S2 3min gap/30min window, S3 20min, S4 5min, S5 10min, S7 24h |

No threshold env vars exist for flow-watcher — only the on/off flag.

---

## Exact ordered Railway-flip sequence (Worker)

Operator runs these. Each is one `railway variables` call against the Worker service. I do NOT run them.

**Phase 1 — hard-loss (smallest blast radius):**
```
railway variables --service Worker --set HARD_LOSS_ALERT_ENABLED=true
# optional: tune threshold (default 400 is a sane start for demo sizing)
# railway variables --service Worker --set HARD_LOSS_ALERT_USD=400
```

**Phase 2 — loss-cap + loss-streak (underlying gates already live):**
```
railway variables --service Worker --set LOSS_CAP_ALERT_ENABLED=true
```

**Phase 3 — activation-health (AFTER ai-1's ADX fix, or accept early fires as signal):**
```
railway variables --service Worker --set ACTIVATION_HEALTH_ALERT_ENABLED=true
# defaults are fine; only override if too chatty:
# railway variables --service Worker --set ACTIVATION_HEALTH_ADX_CYCLES=10
# railway variables --service Worker --set ACTIVATION_HEALTH_GATE_CYCLES=20
# railway variables --service Worker --set ACTIVATION_HEALTH_GATE_MIN_EVALS=10
# railway variables --service Worker --set LOSS_ACTIVATION_MONITOR_COOLDOWN_MIN=30
```

**Phase 4 — flow-watcher (broadest; 7 signals, can be chatty on a noisy day):**
```
railway variables --service Worker --set FLOW_WATCHER_ENABLED=true
```

Each `--set` triggers a Worker redeploy. Recommend one phase per session/day so you can attribute any alert-channel volume to the family you just turned on. Rollback for any phase = same command with `=false` (30-second revert, no code).

---

## Recommended threshold values

- `HARD_LOSS_ALERT_USD=400` — keep default to start. Re-tune once you see real close magnitudes; if 400 never fires across a week, drop toward the 90th-percentile single-trade loss.
- Activation-health: keep all defaults (10 / 20 / 10 / 30). They are deliberately conservative (history-gated, min-evals-gated, weekday-only) and unlikely to false-fire.
- Flow-watcher: no tuning available (code constants); accept defaults.

---

## Post-flip verification plan (what each alert should produce)

General check after each phase: tail Worker logs for the per-module summary line.
- Hard-loss: routed through delivery — look for the A_ALERT delivery log + the embed in the alerts channel.
- Loss/activation monitor log line: `[loss-activation-monitor] active=<n> fired=<n> delivered=<bool> webhook=set`
- Flow-watcher log line: `[flow-watcher] overall=<sev> changes=<n> delivered=<bool> webhook=set`

Per family:

1. **Hard-loss** — on the next trade that closes `pnl <= -400`, expect a 🔴 A_ALERT embed in the alerts channel labelled hard-loss, with orderId/pnl/R/closeReason/threshold, ALONGSIDE the normal TRADE_CLOSED line. To force-verify without waiting: temporarily set `HARD_LOSS_ALERT_USD=1` for one session so any losing close trips it, confirm the embed, then restore 400. `webhook=set` must appear; if `MISSING`, the webhook env is unset (it is currently set, so this should pass).

2. **Loss-cap halt** — when daily PnL breaches the cap and `checkDailyLossCap` returns `capped`, expect a 🔴 embed "Daily-loss-cap halt" with the cap reason/PnL. Verify by cross-checking against the cap actually halting entries that day (the alert mirrors the same check, so the two must agree).

3. **Loss-streak pause** — after a listed strategy logs ≥`LOSS_STREAK_PAUSE_TRIGGER` consecutive losses with the last close within 2h, expect a 🔴 "Loss-streak pause" embed naming the strategy + streak count. NOTE the 2h-vs-4h window caveat above when reconciling against the live pauser.

4. **Activation-health / ADX-null** — weekday only; after `ACTIVATION_HEALTH_ADX_CYCLES` consecutive technical-fact publishes with null/absent ADX, expect a 🟡 embed "ADX null (activation not biting)". This is the cross-check on ai-1's ADX work.

5. **Activation-health / gate-100%-reject** — when any gate hard-rejects 100% of ≥`MIN_EVALS` over the last `GATE_CYCLES` evals, expect a 🟡 embed naming the gate + reject ratio.

6. **Flow-watcher** — on first non-GREEN cycle (or any signal state-change), expect a flow-watcher embed listing all 7 signals with the changed one(s) highlighted, 15-min cooldown between posts. Easiest live confirm: a Worker redeploy itself trips S2 (restart-deteksjon) within the 30-min window — so right after you flip FLOW_WATCHER_ENABLED=true and it redeploys, you should see an S2 WARNING embed.

Debounce/cooldown sanity: loss/activation cooldown is per-signal 30min default; flow-watcher is 15min global. Don't expect repeat spam inside those windows.

---

## Constraints honoured
- No Railway flips performed (operator-gated).
- No code changed; read-only diagnosis only. Did not touch ADX/regime/indicator code (ai-1 owns).
- All four families confirmed default-OFF + behaviour-neutral.

## Follow-up tasks surfaced (not actioned)
- Loss-streak alert recency window hardcoded 2h vs Worker `LOSS_STREAK_PAUSE_HOURS=4` → make the probe read the env so alert window matches the live pause window. Small fix, behind existing flag, behaviour-neutral.
