# Verify: cloud-side anomaly alerts (fab56f3 + 4e25db6)

READ/VERIFY-ONLY. 2026-06-08. Verifies the just-landed `feat(notifications): cloud-side anomaly alerts`
commit on `main` (fab56f3, test-reg 4e25db6). This is the implementation of P1 #3/#4/#5 from the
2026-06-07 self-reporting audit (`2026-06-07_verify_self-reporting.md`).

## Verdict (one line)

Sound, correctly wired, REPORT-only, all default-OFF. Bypasses the dual-gate foot-gun by design.
Operator WILL receive these IF `DISCORD_ALERTS_WEBHOOK_URL` (or `DISCORD_WEBHOOK_URL`) is set on
Railway AND the respective flags are flipped. Test 25/25 green. One scope gap (derive/lessons/autotune
health is NOT this monitor's job — different audit).

## 1. What it alerts on

Three emitters, all new in fab56f3:

**(1) Hard-loss alert** — `detector.ts`. When a trade closes `pnl <= -HARD_LOSS_ALERT_USD`
(default 400, clamped [1,100000]), emits a distinct `HARD_LOSS_ALERT` event, priority `A_ALERT`,
category `alerts`, debounced per orderId (`cooldownKey: hard_loss:<id>`). Fires *alongside* the
routine TRADE_CLOSED line. Formatter renders a red embed. Flags: `HARD_LOSS_ALERT_ENABLED` (OFF),
`HARD_LOSS_ALERT_USD` (400).

**(2) loss-and-activation-monitor.ts** (new 464-line module, wired orchestrator Step 0a2e). Two flag groups:

- `LOSS_CAP_ALERT_ENABLED` (OFF) → 2a daily-loss-cap halt + 2b loss-streak pause:
  - 2a `probeDailyLossCap`: re-calls the SAME `checkDailyLossCap()` the live entry gate calls; if
    `capped`, RED signal. Read-only — does not consume/alter the gate decision.
  - 2b `probeLossStreaks`: only for strategies in `LOSS_STREAK_PAUSE_STRATEGIES` when
    `LOSS_STREAK_PAUSE_ENABLED`. Reads recent closed trades from `simulated_orders`, counts
    consecutive losses ≥ `LOSS_STREAK_PAUSE_TRIGGER` (default 3) with last close ≤2h ago (mirrors
    the pauser's own recency guard). Does NOT call the live pauser (would mutate in-memory state).
- `ACTIVATION_HEALTH_ALERT_ENABLED` (OFF) → 3 activation-not-biting:
  - `probeAdxNull`: reads last N (`ACTIVATION_HEALTH_ADX_CYCLES`=10) `xauusd.market.raw` rows that
    carry `state.indicators`; if ADX null/absent across all → YELLOW. Weekday-only (skips Sat/Sun UTC).
    Stays quiet if < N rows of history.
  - `probeGateFullReject`: groups the last `ACTIVATION_HEALTH_GATE_CYCLES` (20) `gate_decisions` rows
    by `gate_name`; any gate with ≥ `ACTIVATION_HEALTH_GATE_MIN_EVALS` (10) evals and 100% `hard_rejected`
    → YELLOW (gate may be mis-activated).

Per-signal debounce `LOSS_ACTIVATION_MONITOR_COOLDOWN_MIN` (default 30 min), persisted in `firm_state`
key `loss_activation_monitor:last_state`, compare-and-update inside one `pg_advisory_xact_lock` txn so
two workers during a deploy crossover can't double-fire. Discord POST is fire-and-forget AFTER commit.

## 2. Default state + REPORT-only

- All flags default OFF. `isLossActivationMonitorEnabled()` returns false unless a sub-flag is set, so
  orchestrator Step 0a2e is a no-op until flipped — wiring is behaviour-neutral.
- REPORT-only confirmed: each probe re-reads the same signals the live gates read and returns a `Signal`.
  No probe flips a flag, closes a position, or mutates gate/cap/pause state. Embeds explicitly say
  "REPORT-only — no auto-action taken (operator-prinsipp 1)." Compliant with operator-prinsipp 1.

## 3. Will the operator actually RECEIVE them? (Discord gate)

YES, and the dual-gate foot-gun is avoided. Two distinct delivery paths, NEITHER goes through the
`DISCORD_LEGACY_ENABLED` / `AGENT_DISCORD_DELIVERY_ENABLED` quad-gate (that gate only applies to the
firm-agents discord-bridge / legacy discord.service path):

- **Hard-loss alert** → notifications dispatcher → `deliverNotification` (`delivery.ts`). Gated only by
  `DISCORD_NOTIFICATIONS_ENABLED` (default true) + `DISCORD_SEND_ALERTS` (default true), routes to
  `DISCORD_ALERTS_WEBHOOK_URL ?? DISCORD_WEBHOOK_URL`.
- **loss-and-activation-monitor** → posts DIRECTLY via `postWebhookFireAndForget` to
  `DISCORD_ALERTS_WEBHOOK_URL ?? DISCORD_WEBHOOK_URL` (same pattern as foundation-monitor / flow-watcher).

So the only delivery precondition is: a webhook URL is set on Railway. The monitor logs
`webhook=set|MISSING` every pass for observability, and returns `webhookConfigured` in its report.

**Operator action required (Claude cannot flip Railway env):**
1. Confirm `DISCORD_ALERTS_WEBHOOK_URL` (or at least `DISCORD_WEBHOOK_URL`) is set on the worker.
2. Flip whichever of `HARD_LOSS_ALERT_ENABLED`, `LOSS_CAP_ALERT_ENABLED`, `ACTIVATION_HEALTH_ALERT_ENABLED`
   you want live. These are pure observability (no trade-decision change) → Claude-side of the
   boundary, no Karri gate needed.

## 4. activation-health — does it catch derive-crash / lessons-inert / autotune-blocked-by-ORB_ONLY?

NO — and that is by design, not a bug. This monitor's "activation-health" is scoped (per the audit's
P1 #5) to *indicator/gate* not-biting: ADX-null streak + gate-100%-reject. The three learning-pipeline
failure modes you named live in a SEPARATE audit (`2026-06-07/06_health-anomaly-watch.md`):
- derivation crashing → addressed separately (firehose `:failed` marker, commit b59f39a).
- lessons inert (0 approved, injection reads only `status='approved'`) → `LESSON_AUTO_PROMOTE_ENABLED`
  pipeline, not this monitor.
- autotune (`calibration_log` empty since 04-25, all RECOMMEND_ONLY) → SAFE_AUTO_APPLY question, Karri gate.

GAP (genuine but out-of-scope for fab56f3): there is no cloud-side Discord alert that fires when the
learning pipeline is structurally inert (0 approved lessons / 0 calibration applies / derive crashing).
That is a candidate for a follow-up "learning-pipeline-health" emitter behind its own OFF flag — pure
observability, Claude-ownable. Flag it; do not bolt it onto loss-and-activation-monitor (different concern).

Minor scope notes (not bugs):
- `probeGateFullReject` covers *over*-blocking (100% reject). A gate that's mis-activated and rejecting
  *nothing* (under-active) is not covered — but that wasn't in the audit scope either.
- `probeAdxNull` only sees the 15m technical-facts rows (`state ? 'indicators'`); H1 ADX
  (`xauusd.market.h1-indicators`, the topic strategies actually read for trend) is a separate topic and
  is NOT probed. If an H1-ADX-gated activation goes null, this won't catch it. Low priority, worth noting.

## 5. Test

`node --test ... loss-and-activation-monitor.test.ts` → **25/25 pass** (780ms). Covers config
defaults/clamps, selectDueSignals cooldown logic, embed RED/AMBER, and all four probes incl. fail-safe
(DB error → [], weekday-only ADX, recency guard, partial-reject quiet). Registered in `apps/worker/package.json`.

## Schema sanity (verified against live code)

- `gate_decisions` columns `gate_name`, `hard_rejected`, `recorded_at` — all real (strategy-blade.ts
  INSERTs, foundation-monitor ORDER BY recorded_at).
- `xauusd.market.raw` with `state.indicators.adx` — real (fact-agents.ts runTechnicalFacts publishes
  exactly this shape; price-only rows lack `indicators`, so `WHERE state ? 'indicators'` correctly
  filters to technical-fact rows).
- `simulated_orders` (pnl, closed_at, strategy_id/strategy, status='closed') — query shape consistent
  with rest of codebase.

## Citations
- `apps/worker/src/firm/notifications/loss-and-activation-monitor.ts` (full module)
- `apps/worker/src/firm/notifications/detector.ts` (hard-loss branch, readHardLossConfig)
- `apps/worker/src/firm/notifications/delivery.ts` + `config.ts` (alerts gate, no dual-gate)
- `apps/worker/src/firm/orchestrator.ts` Step 0a2e (wiring)
- `apps/worker/src/firm/fact-agents.ts:73-108` (market.raw indicators shape)
- `apps/worker/src/firm/daily-loss-cap/index.ts` (capped/capUsd/dailyPnl shape)
- audit: `2026-06-07_verify_self-reporting.md` (P1 #3/#4/#5), `2026-06-07/06_health-anomaly-watch.md` (learning gaps)
