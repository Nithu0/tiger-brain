# event.policy staleness — root cause + freshness probe (2026-06-04)

Branch: `node-migration-nexus`. REPORT-only, no commit/push/Railway. operator-prinsipp 1 honoured (probe reports; never auto-disables a gate).

## Verdict: producer is DEAD, not read-stale

The `xauusd.event.policy` topic is ~40 days stale because **its producer is dormant**, not because anyone reads stale state into a live gate.

### Producer
`apps/worker/src/firm/managers.ts:434` — `board.publish({ topic: "xauusd.event.policy", ... })`.
This publish lives **inside `bladeApproval()`** (managers.ts:344–739).

`bladeApproval` is only invoked from `orchestrator.ts:663`, and only when ALL of:
1. `!orbOnlyMode` (orchestrator.ts:642/651) — **but production runs `ORB_ONLY_MODE=true`** (confirmed `docs/ref/feature-flags.md:74` + `docs/ops/phase-status.md:78`). Under ORB_ONLY_MODE the orchestrator bypasses the entire Prism+Blade path → `bladeApproval` is **never called** → the publish never runs.
2. `synthesisId && thesis && isTradeAllowed(window) && portfolioGate`
3. `thesis.thesisQualityScore >= boostedThresholds.marketThesis` (mature-thesis only).

So even with ORB_ONLY_MODE off, the topic would only refresh on cycles that reach a mature thesis. With ORB_ONLY_MODE **on** (current prod), it never refreshes at all. That is the 40-day staleness. **Root cause: dead producer, gated out by ORB_ONLY_MODE.**

### Is the news-blackout GATE running on ancient state? NO.
The actual gate (`apps/worker/src/firm/strategy-blade.ts:291–315`, `event_policy` check) calls `computeEventPolicy(input.db)` **fresh** every evaluation — it does **not** read the `xauusd.event.policy` blackboard topic. So gating is computed live; it never consumed the stale topic. (Note: under ORB_ONLY_MODE the blade gate also doesn't run, but that's a separate matter — ORB has its own path.)

### Who DOES read the stale topic (observability only):
- `managers.ts:899` — `board.latest("xauusd.event.policy", 600)` for the `entry_snapshot` JSONB at trade-open. 600 s maxAge → a 40-day-old row is filtered out, so `eventMsg` is just `null` and that snapshot field is empty (not "wrong", just missing).
- `apps/api/src/routes/operator-readiness.ts:354` + `:389` — readiness page freshness widget + `eventState`/`eventName`/`eventCountdown`. The page already shows it as stale, but **nothing pushed an alert** — that was the gap.

Net: no live trade-decision ran on ancient state. The harm was silent observability rot + a dead alert path. Probe closes that.

## What I added (REPORT-only, default OFF)

New module `apps/worker/src/firm/notifications/topic-freshness.ts`:
- `DEFAULT_FRESHNESS_TARGETS` — 6 critical topics + per-topic max-age thresholds (event.policy = 1h default).
- `resolveFreshnessTargets(env)` — per-topic override via `TOPIC_FRESHNESS_MAX_AGE_<TOPIC_UPPER_SNAKE>` seconds (e.g. `TOPIC_FRESHNESS_MAX_AGE_XAUUSD_EVENT_POLICY=7200`).
- `findStaleTopics(...)` — pure; never-seen = stale + sorts worst-first.
- `buildTopicStalenessEvent(...)` — Priority-A `alerts` event; cooldown 6h, key = sorted stale-topic set (new topic going stale re-fires immediately).
- `probeTopicFreshness(db, env)` — env-gate → one grouped SQL `MAX(timestamp)` query → detect → event. Returns null when flag OFF or board fresh. DB read wrapped; never throws into the cycle.

Wiring:
- `notifications/types.ts` — new `TopicStalenessEvent` added to the union.
- `notifications/detector.ts` — calls `probeTopicFreshness(input.db)` at end of `detectNotifications`, try/wrapped. Pushes event onto the existing detector→dispatcher→delivery (Discord alerts webhook) path.
- `notifications/formatter.ts` — `formatTopicStaleness` red embed, explicitly states "REPORT only — no gate or flag was changed."

### Gate / rollback
- `TOPIC_FRESHNESS_ALERT_ENABLED` (default OFF). Unset/`false` → probe returns null, zero behaviour change. Set `true` to start alerting.
- Routing also respects existing `DISCORD_SEND_ALERTS` + `DISCORD_ALERTS_WEBHOOK_URL`.
- This is learning/observability infra (no trade-decision impact) → per prinsipp 6 (2026-06-03) it can run freely; no Karri gate. Operator just needs to flip the flag.

## Verify
- `cd apps/worker && npx tsc --noEmit` → exit 0.
- `npm test` → **1167/1167 pass** (was ~1153; +14 new in `topic-freshness.test.ts`).
- New tests cover: fires when age>threshold (incl. 40-day event.policy case), silent when fresh, never-seen=stale+sorts-first, oldest-first ordering, env-gate OFF→null, flag-ON+fresh→null, per-topic override + invalid-fallback, formatter renders embed.

## Follow-up for operator (NOT auto-done)
1. Flip `TOPIC_FRESHNESS_ALERT_ENABLED=true` in Railway Worker to activate the alert. With ORB_ONLY_MODE on, it WILL fire for `xauusd.event.policy` — that is correct/intended (it's genuinely dormant).
2. Decide the event.policy producer's fate: either (a) accept dormancy under ORB_ONLY_MODE and bump `TOPIC_FRESHNESS_MAX_AGE_XAUUSD_EVENT_POLICY` very high / drop it from targets, or (b) move the `event.policy` publish OUT of `bladeApproval` so it publishes per-cycle independent of ORB_ONLY_MODE (small refactor — would be a behaviour-touching change near the trading path, so file as proposal if chosen). Recommend (b) long-term since it restores the readiness-page event state, but it's operator's call.
