# Nexus worker self-reporting audit — 2026-06-07

READ-ONLY investigation. Goal: confirm the always-on Railway worker reports + pings Discord 24/7 without a PC-bound Claude, and map the gaps.

## TL;DR

- The worker **does** self-report autonomously via two independent Discord paths. The modern `firm/notifications/` webhook stack is fully wired and gated only by `DISCORD_NOTIFICATIONS_ENABLED` + a webhook URL — NOT by the legacy quad-gate.
- Coverage is good on **routine** events (briefing, session, decisions, trades, trade-closed+postmortem, foundation RED) but **thin on anomalies**: hard-loss, daily-loss-cap hit, loss-streak pause, breaker/clamp, "strategy bleeding", and "activation not biting" (ADX null / gate never fires) are **not** alerted.
- Live state shows the cost of the gaps: a **-$787 hard loss (06-03)** and a string of -$300..-$630 losses in the last 7d produced **no dedicated alert**; foundation is **RED** since 06-06; `last_briefing_date_iso` = **2026-06-05** (no morning briefing fired 06-06/06-07 — worker likely down during those London windows; that downtime itself was not alerted beyond a boot/shutdown ping if a webhook is configured).

---

## 1. What fires, when, and what it sends

All firm self-reporting runs inside `FirmOrchestrator.runCycle()` (`apps/worker/src/firm/orchestrator.ts`), self-scheduled on adaptive session cadence (~90s primary window, slower off-hours; `index.ts:307-308`). `index.ts` itself only schedules supervisor (10min) + bot-manager (15min) + firehose weekly digest + lesson-derivation — none of those ping Discord.

### Path A — modern webhook notifications (primary, well-wired)
`runNotificationCycle()` called every cycle at `orchestrator.ts:735`.
- Pipeline: `notifications/detector.ts` (state diff → typed events) → `formatter.ts` → `delivery.ts` (fire-and-forget POST, 2s timeout, in-memory cooldown+dedup).
- Gate: `DISCORD_NOTIFICATIONS_ENABLED` (default true) + a webhook (`DISCORD_WEBHOOK_URL` default, or category-specific `DISCORD_{ALERTS,BRIEFING,DECISIONS,EXECUTIONS}_WEBHOOK_URL`). Per-category mute via `DISCORD_SEND_*`. See `notifications/config.ts:48-70`.
- **This path does NOT touch `DISCORD_LEGACY_ENABLED` / bot-token.** It is the reliable cloud-side path.

Events emitted (`detector.ts`), with cadence:
| Event | Trigger | Cadence/cooldown |
|---|---|---|
| DAILY_MORNING_BRIEFING | first LONDON_PREPARE/ACTIVE cycle of UTC day | 1×/day (`detector.ts:912`, gated `DAILY_MORNING_BRIEFING_ENABLED`) |
| OPERATOR_PULSE | foundation RED↔YELLOW↔GREEN transition | on change; RED routes to `alerts` (A_ALERT) (`detector.ts:864`) |
| SESSION_STARTED | into LONDON/OVERLAP/NY | per session, B_BRIEFING |
| THESIS_CROSSED | thesis crosses 42/45/60 | per level, B_BRIEFING |
| REGIME_CHANGED | regime label change | on change |
| DECISION | decision TYPE change (APPROVED/REJECTED/WAIT/BLOCKED) | C_DECISION, 30s cd |
| TRADE_OPENED | new fill | D_EXECUTION |
| TRADE_CLOSED + TRADE_ANALYSIS_SUMMARY | closed_at > watermark (DB-sourced, catches SL/TP + OANDA-sync) | per close; summary needs a postmortem row |
| EXECUTION_STATE_CHANGED | riskLevel=extreme or news blackout toggles execution allowed | A_ALERT |
| PORTFOLIO_PULSE | every ~15min in active sessions | B_BRIEFING |
| ANALYST_ATTENTION | thesis 50-59 idle | 30min |
| TEAM_CHANGELOG_POSTED | new team_changelog row | per entry |
| topic-freshness | stale critical topic | **gated `TOPIC_FRESHNESS_ALERT_ENABLED`, default OFF** |

### Path B — legacy bot-token (`services/discord.service.ts`)
- Gate: `DISCORD_LEGACY_ENABLED` (default true via `envEnabledUnlessFalsy`) **AND** `DISCORD_BOT_TOKEN` **AND** `DISCORD_CHANNEL_ID`. If any missing → silent early-return (`skipped:"legacy_gate"`).
- Only live caller in the firm loop: **session-window-change embed** at `orchestrator.ts:277` (`sendDiscordEmbed`). Builders for trade-open/close/risk/briefing exist but are largely superseded by Path A.
- `firm-agents/discord-bridge.ts` also routes through this gate (firm-agent pings) — needs `AGENT_DISCORD_DELIVERY_ENABLED` + `DISCORD_LEGACY_ENABLED` (the documented dual-gate, MEMORY `project_discord_delivery_dual_gate`).

### Path C — standalone monitors (own webhook, own gate)
- **foundation-monitor** (`foundation-monitor.ts`): every cycle if `FOUNDATION_MONITOR_ENABLED==="true"` (strict). POSTs to `DISCORD_ALERTS_WEBHOOK_URL ?? DISCORD_WEBHOOK_URL` when a foundation rule flips, 15min cooldown. **LIVE** — `firm_state.foundation_monitor:last_state` updated today.
- **flow-watcher** (`flow-watcher/index.ts`): every cycle if `FLOW_WATCHER_ENABLED==="true"` (strict). 7 anomaly signals S1-S7: worker-stall, restart, stacking, silent-blocker, blackboard-staleness, DB↔OANDA drift, attribution-NULL. Alerts on severity change. **OFF** — no `flow_watcher` firm_state key exists.
- boot/shutdown ping: `index.ts:357-411`, fire-and-forget to alerts/default webhook.

---

## 2. Anomaly coverage — what alerts vs what is silent

ALERTED today:
- Foundation RED transition (OPERATOR_PULSE A_ALERT + foundation-monitor). Live: pulse=RED since 06-06.
- Execution blocked by risk=extreme / news blackout (EXECUTION_STATE_CHANGED).
- Each trade open/close (incl. SL/TP losses show up as a red TRADE_CLOSED embed).
- Worker boot/shutdown (if webhook set).

**NOT alerted (gaps):**
- **Hard single-trade loss** — no threshold alert. A -$787 close (06-03) only appeared as a routine TRADE_CLOSED line, not flagged as severe.
- **Daily-loss-cap hit** — `checkDailyLossCap` (`daily-loss-cap/index.ts`) is consumed only as an entry gate in `strategy-execution.ts:664`; when it caps it blocks trading **silently** (no publish, no Discord).
- **Loss-streak pause** — `loss-streak-pauser` blocks entries; **no Discord wiring** at all.
- **Breaker/clamp** — sizing clamps / blade rejections are gate-level, not surfaced as alerts (DECISION fires only on TYPE change, so a persistently-clamped strategy is quiet).
- **"Activation not biting"** — e.g. ADX still null, a newly-activated gate never firing, a strategy bleeding over N trades: **no monitor**. flow-watcher S4 (silent-blocker) + S7 (attribution-null) would partially cover this but flow-watcher is **OFF**.
- **Worker downtime during a session** — only catchable via flow-watcher S1/S2 (OFF) or absence-of-heartbeat (no external dead-man). The missing 06-06/06-07 morning briefings are evidence this gap bit.

---

## 3. Is delivery actually wired end-to-end?

Yes for Path A, conditionally for B:
- **Path A (notifications)**: reaches a channel as long as `DISCORD_NOTIFICATIONS_ENABLED!=false` and at least `DISCORD_WEBHOOK_URL` is set. Independent of the legacy quad-gate. Dispatcher logs a one-time `dispatcher alive: ... defaultWebhook=set|MISSING` line — grep Worker logs to confirm the URL is present. This is the path to trust for 24/7 cloud alerts.
- **Path B (legacy + firm-agents)**: needs BOTH `DISCORD_LEGACY_ENABLED=true` AND `DISCORD_BOT_TOKEN` AND `DISCORD_CHANNEL_ID`; firm-agent pings additionally need `AGENT_DISCORD_DELIVERY_ENABLED=true`. Missing any → silent `legacy_gate` skip. The operator's three ON flags satisfy the gate booleans but **token+channel must also be present** or B drops silently. (A still works regardless.)
- **Path C (monitors)**: foundation-monitor LIVE and confirmed writing state today; flow-watcher OFF.

Verification levers in logs: `[firm.notifications] dispatcher alive ...`, per-event `event type=... delivered=... webhook=...`, `[firm.foundation-monitor]`, boot ping `Worker boot at ...`.

---

## 4. Minimal gap-fill plan (infra-only, no strategy change)

All REPORT-only, per operator-prinsipp 1 (no auto-disable). Each behind an env flag, default OFF, revertable in 30s. None alter trade decisions → Claude-ownable (learning-infra/observability side of the boundary), no Karri gate.

**P0 — turn on what already exists (zero code):**
1. Set `FLOW_WATCHER_ENABLED=true` on the Railway worker. Instantly lights S1-S7 (worker-stall, restart, stacking, silent-blocker, staleness, DB↔OANDA drift, attribution-null) → the single biggest coverage win, already built + tested. Routes to `DISCORD_ALERTS_WEBHOOK_URL`.
2. Confirm `DISCORD_ALERTS_WEBHOOK_URL` (or at least `DISCORD_WEBHOOK_URL`) is set so A_ALERT events land on a channel the operator watches. (Operator action — Claude cannot flip Railway env.)

**P1 — small new emitters (focused diffs, ~1 file each, behind a flag):**
3. **Hard-loss alert**: in the existing TRADE_CLOSED detector branch (`detector.ts:601`), when `pnl <= -HARD_LOSS_USD` (or `rMultiple <= -1.5`), raise the event priority to `A_ALERT` (alerts category) instead of D_EXECUTION. New env `HARD_LOSS_ALERT_USD` (default off / large). ~10 lines, no new module.
4. **Daily-loss-cap + loss-streak alert**: when `checkDailyLossCap` returns `capped` or the pauser engages, publish a blackboard event the detector already could surface, OR fire `postWebhookFireAndForget` directly to the alerts webhook (mirroring foundation-monitor). Behind `LOSS_CAP_ALERT_ENABLED`. Currently these safety stops are completely silent — operator should know the moment trading auto-halts.
5. **Activation health probe** ("is it biting"): a tiny cycle-gated check (reuse flow-watcher's compare-and-cooldown pattern) that alerts when an enabled strategy has had N consecutive cycles with a null required indicator (ADX null) or a gate that has rejected 100% over a window. Behind `ACTIVATION_HEALTH_ALERT_ENABLED`. This is the "are the new activations working" signal the operator explicitly wants.

**P2 — dead-man (cloud-independent of the worker process):**
6. External heartbeat watchdog: an n8n cloud workflow (WF, the n8n MCP is available) polls `firm_state.worker:heartbeat.updated_at` (or `/health`) every 5min and pings Discord if it goes stale > X min. This is the only way to catch a fully-dead worker — flow-watcher S1/S2 can't fire if the worker isn't cycling. Pure cloud, no PC.

Recommended order: P0 #1 (free, huge), then P2 #6 (catches total death), then P1 #3-#5.

---

## Citations
- Schedule/cron: `apps/worker/src/index.ts:146-219` (supervisor/manager/firehose), `:307-308` (firm start), `:357-411` (boot/shutdown ping).
- Cycle reporting calls: `apps/worker/src/firm/orchestrator.ts:277` (legacy session embed), `:343-361` (foundation-monitor + flow-watcher gates), `:630` (briefing), `:735` (notifications), `:745` (CIO).
- Detector events: `apps/worker/src/firm/notifications/detector.ts` (full file; key branches cited inline above).
- Gating: `notifications/config.ts:48-70`, `notifications/delivery.ts:58-114`, `services/discord.service.ts:21-23,55-91`.
- Silent safety stops: `daily-loss-cap/index.ts` (no publish), consumed `strategy-execution.ts:664`; `loss-streak-pauser/index.ts` (no Discord).
- Monitor flags: `foundation-monitor.ts:96-97` (LIVE), `flow-watcher/index.ts:61-62` (OFF), `notifications/topic-freshness.ts:211-212` (OFF).
- Live DB: heartbeat fresh (cycleNo:4 today); `last_briefing_date_iso`=2026-06-05; `last_pulse_state`=RED (06-06); worst 7d loss -$787 (06-03), no hard-loss alert; `foundation_monitor:last_state` present, no `flow_watcher` key.
