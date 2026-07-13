# Audit §9 — Railway / Deployment / Drift: does the infra support a 24/7 learning loop?

Date: 2026-06-15. Scope: deployment, scheduled jobs, persistence, recovery, monitoring.
Method: read-only — code/config + live `/health`. Evidence-based, brutal.

## TL;DR verdict

Railway is **mostly sufficient for running the loop, but has two structural gaps that directly threaten learning continuity**:
1. **NO evidence of any database backup** of the irreplaceable trading data. This is the single biggest risk.
2. **Every scheduler is an in-process wall-clock timer with no catch-up.** A restart in the wrong hour silently skips that day's derive-lessons run (the 17-day silent crash, `676c222`, is the proof this class of failure is real and went unnoticed for 17 days).

Monitoring is good *for derive-lessons specifically* (purpose-built after the crash) but **only derive-lessons** — the other ~6 scheduled jobs have no equivalent run-status surface.

---

## 1. SCHEDULERS — every cron/interval job

All schedulers live in `apps/worker/src/index.ts` (in-process `setInterval`/`setTimeout`) plus the self-scheduling firm orchestrator. **There is no real scheduler (no Railway cron service, no BullMQ repeatable jobs, no system cron). All timers anchor to worker boot time and die on restart with no catch-up.**

| Job | Mechanism | Cadence | Trigger logic | Restart-safe? |
|---|---|---|---|---|
| **Firm trading cycle** | `FirmOrchestrator.scheduleNext()` `setTimeout` (self-rescheduling) | **Adaptive 30s–3600s** by session window (`getSessionCadence`, `session-window.ts`): 30s opening-range, 60s London/overlap active, 120–180s prepare/NY-cont, 300–600s Asia/low-prio observe, **3600s weekend** | Runs continuously; reschedules itself each cycle | Resumes on restart (cycleCount resets to 1 — see live `lastCycleNo:1`) |
| **Supervisor agent** | `setInterval` | 10 min | enqueue BullMQ agent job | Dies + reanchors on restart; no catch-up (low impact, frequent) |
| **Bot-manager agent** | `setInterval` | 15 min | enqueue BullMQ agent job | Same |
| **Firehose weekly digest** | `setInterval` 1h tick | Hourly tick, acts only when `UTCDay===0 && UTCHour===23` | `FIREHOSE_DIGEST_ENABLED`; idempotent per ISO-week via `firm_state` | **Fragile** — see below |
| **Derive-lessons (04:00 UTC)** | `setInterval` 1h tick | Hourly tick, acts only when `UTCHour===4` | `AGENT_LESSONS_ENABLED` + `LESSON_DERIVATION_ENABLED`; idempotent per UTC-date via `firm_state`; spawns subprocess | **Fragile** — see below |
| **Qdrant TTL cleanup** | inside firm cycle (Step 0a2) | once per UTC day | `firm_state` "already ran today" marker (survives restart) | OK (marker-gated, retried next cycle) |
| **Blackboard 14-day TTL cleanup** | inside firm cycle (Step 0a3) | every 100 cycles | cycleCount % 100 | OK-ish (cycleCount resets on restart → effectively "every 100 cycles since boot") |
| **OANDA position sync** | inside firm cycle (Step 0a) | every cycle | always | OK |
| **Postmortem hook** | inside firm cycle (Step 0c) | every cycle | env-gated | OK |
| **Raw-data persistence** | inside firm cycle (Step 1a) | every cycle | `RAW_DATA_PERSIST_ENABLED` (default true) | OK |
| **Loss/activation monitor** | inside firm cycle (Step 0a2e) | every cycle | `LOSS_CAP_ALERT_ENABLED` + `ACTIVATION_HEALTH_ALERT_ENABLED` | OK |
| **Daily morning briefing** | inside firm cycle (`detector.ts`) | once/day, fires when session ∈ {LONDON_PREPARE, LONDON_ACTIVE} | `DAILY_MORNING_BRIEFING_ENABLED`; "last emitted UTC date" persisted | OK (session-window + date-marker driven, not wall-clock-tick) |

### The restart-skip problem (the core learning-continuity risk)

`setInterval(fn, 3600_000)` **anchors to boot time**, and the callback only acts when `getUTCHours()` equals a target (4 for derive, 23 for digest). There is **no catch-up**: if a tick never lands inside the target hour, the job is skipped for the whole day/week.

Worked examples for the 04:00 derive job:
- Boot at **04:30** → next hourly ticks land at 05:30, 06:30… `getUTCHours()` is never 4 today → **derive silently skipped, no failure marker written** (the skip isn't an error, the hour just never matched). Retried tomorrow only.
- Boot at **03:59** → next tick ~04:59 (hour 4 ✓) — caught, by luck.
- Worker redeploys (Railway deploys on every push to main) at any time during hour 4 → likely misses the 04:00 window that day.

So: **any Railway redeploy or crash whose recovery boot lands at xx:05–xx:59 of the target hour skips that day's learning derivation.** Given operator pushes to main frequently (auto-deploy), this is not a tail risk — it's a recurring silent gap. The good mitigation: idempotency marker is **written only on success**, so a skipped/failed run is retried the next day rather than permanently suppressed. But "we lose a day's lesson derivation roughly whenever we deploy near 04:00 UTC" remains true and is invisible unless you read `/firehose/derive-status`.

---

## 2. PERSISTENCE — is the data durable + backed up?

- **Postgres**: Railway-managed Postgres (`DATABASE_URL`). Durable storage, single instance. Live `/health` shows `db.ok:true, latencyMs:50`. Connection is a plain `pg.Pool`.
- **Redis**: Railway Redis (`REDIS_URL`) for BullMQ queues — transient job state, not the asset.
- **Qdrant**: vector store for narrative memory (`@qdrant/js-client-rest`) — derived, reconstructible.
- **Migrations**: `DB_MIGRATIONS` array run on every worker boot (idempotent CREATE-IF-NOT-EXISTS pattern). Schema is code-defined; fine.

**BACKUP: NO EVIDENCE OF ANY BACKUP.** Grepped `docs/ref/deploy-and-tests.md`, `env-vars.md` for backup/pg_dump/snapshot/WAL/restore/PITR — zero hits. No backup cron, no `pg_dump` job, no documented Railway PITR/backup plan. Railway's managed Postgres has plan-dependent backups, but **nothing in the repo or docs confirms it's enabled or tested**, and there is no app-level export of trades/postmortems/raw snapshots.

This is the **#1 infra gap**. The trading data (live-collected XAUUSD ticks, executions, postmortems, lessons) is the irreplaceable calibration asset and it lives in a single managed Postgres with no verified, no documented, no tested backup. A Railway DB incident or an accidental `nexus-pg-rw` DELETE (operator has write MCP) is unrecoverable today.

---

## 3. 24/7 — does the worker actually run continuously?

- **Yes, it runs continuously** — single long-lived Node process (`CMD node apps/worker/dist/index.js`), self-rescheduling cycle. Live `/health`: `worker.ok:true, lastHeartbeatSec:584` (~10 min — within the off-hours/observe cadence at 20:36 UTC, so healthy), `cyclesPerHour:6`.
- **But state is in-memory and wiped on every restart.** `cycleCount`, `lessonDeriveInFlight` set, `memoryCleanupInFlight` set, supervisor/manager interval anchors all reset. Live `lastCycleNo:1` is direct evidence of a recent restart (counter reset). Railway auto-deploys on every push → restarts are frequent.
- **What can silently die (the 17-day-crash class):**
  - The 04:00 derive subprocess died `code=1` **every night for 17 days** (2026-05-22 → 06-08, `676c222`) via MODULE_NOT_FOUND because runtime cwd (`/app/apps/worker`) ≠ script copy path (`/app/scripts/firehose`). The learning producer was dead and nobody noticed. Now partly fixed + monitored, but it proves the failure mode is real and slow to detect.
  - Restart-skip of derive/digest (§1) — silent by design (hour-mismatch isn't an error).
  - Defensive hardening exists for the cycle loop itself: `scheduleNext` wraps `runCycle`, cadence lookup, and reschedule in independent try/catch (hot-fix 2026-05-17, after a "cycle 1 finished, cycle 2 never started" stall). Plus `unhandledRejection`/`uncaughtException` handlers (log-only, don't exit). Good — the trading loop is unlikely to silently freeze now.
- **Health status currently "degraded"** (live): all sub-checks report `ok:true`, so degraded is from a threshold elsewhere (likely heartbeat-age vs an expected faster cadence, or balanceDelta 38.37). Worth a follow-up but not an infra blocker.

---

## 4. RECOVERY + MONITORING — are failures detected?

- **Boot/shutdown Discord handshake**: worker posts a boot ping and a SIGTERM shutdown ping (`index.ts`). This catches Railway redeploys/restarts — good, restarts are visible to the operator.
- **derive-lessons monitoring is excellent — but scoped only to derive**: built specifically after the 17-day crash. Failures write a durable `firehose:derive_lessons:<date>:failed` row with a **redacted stderr tail** (`sanitizeStderrTail` strips DSNs/tokens), surfaced read-only via `GET /firehose/derive-status` (success + failure markers, `latestSuccessAt`, `failureCount`). Subprocess is spawned isolated so a derive crash can't take down trading. This is the right pattern.
- **Coverage gap**: that pattern is applied to **derive-lessons only** (and partially the weekly digest, which writes its idempotency key on *attempt*, not success — weaker). The other scheduled jobs — supervisor, bot-manager, Qdrant TTL, blackboard TTL, raw-persist, morning briefing — have **no run-status endpoint**. If supervisor stops enqueueing or raw-persist starts silently failing, nothing surfaces a "last successful run" the way derive-status does. Failures are `logWarn`-only (Railway logs), which is exactly the blind spot that let the 17-day crash hide.
- **No catch-up / no retry-today** on missed wall-clock windows (§1). Recovery = "try again tomorrow."
- **No external uptime/heartbeat monitor** evident (no healthcheck cron pinging `/health`; the `nexus-watch` scaffold is read-only watch, not alerting). Detection relies on the operator reading Discord pings + derive-status.

---

## 5. ENV / SECRETS / COST

- **Env-var sprawl**: `docs/ref/env-vars.md` documents ~92 vars; operator notes ~217 live on the worker. Large gap between documented and live — many are feature-flag toggles (most default OFF). Not a failure risk per se, but a real foot-gun: a mistyped flag silently reads OFF. Mitigation already exists — boot logs an **effective-boolean echo of every master flag** (`masterFlagSummary()` / `resolveMasterFlags()`), so a typo'd `TRUE`/`1`/trailing-space is visible at boot. Good. Cleanup is worthwhile but low-risk.
- **Secret handling**: solid. `firehose-error-capture.ts` redacts connection strings/bearer tokens/rlwy hosts before persisting stderr to `firm_state` (which is readable over the API). No secrets printed. (Did not read any `.env*`.)
- **Cost risks**: `@anthropic-ai/sdk` + `@google/generative-ai` LLM calls in the loop (LLM worker + briefings). Cadence drops to 60s in active windows → bounded call volume; LLM worker has retry+exponential backoff (capped 30s) so a flaky provider won't hammer. No obvious runaway-cost loop spotted. Three always-on Railway services (worker + API + dashboard) + Postgres + Redis + Qdrant = steady baseline cost; nothing pathological.
- **3 services**: worker (the brain), API (Fastify, read-mostly), dashboard (Next.js). All auto-deploy on push to main (Dockerfile-per-app, no railway.json/toml — Railway auto-detects). All intended always-on.

---

## VERDICT

**Railway is adequate to *run* the firm, but NOT yet sufficient for a *disciplined* learning loop without two fixes. No VPS/GPU needed — the gaps are config/code, not compute.**

Concrete gaps, ranked:

1. **[CRITICAL] No verified/tested database backup.** The irreplaceable trading+lessons data sits in one managed Postgres with no documented backup, no PITR confirmation, no app-level export — and an operator-accessible write MCP. Fix: confirm + document Railway PITR/backups, and/or add a daily `pg_dump` of the trade/postmortem/lesson/raw tables to off-Railway storage (e.g. GDrive MCP already available). Test a restore once.

2. **[HIGH] Fragile wall-clock in-process crons with no catch-up.** Frequent auto-deploys mean the 04:00 derive (and 23:00 Sun digest) get silently skipped whenever a restart's hour-tick misses the target window. Fix options: (a) on boot, if the day's success-marker is absent and it's already past the target hour, run the job immediately (catch-up); or (b) move derive/digest to a real scheduler (Railway cron service or BullMQ repeatable job with a date-keyed lock). Either kills the silent-skip class.

3. **[MEDIUM] Monitoring covers only derive-lessons.** Generalize the `firm_state` last-run-marker + `/…-status` pattern to the other scheduled jobs (supervisor, bot-manager, raw-persist, TTL passes, morning briefing) so "job X hasn't succeeded in N days" is queryable, not buried in logs. Add a single external `/health` uptime ping with alerting.

4. **[LOW] Env-var cleanup + investigate current "degraded" health status.** Low risk; flag-echo already mitigates the typo class.

Strengths worth keeping: subprocess isolation for derive, success-only idempotency markers (auto-retry), redacted failure traces over 443, boot/shutdown Discord handshake, defensive cycle-loop try/catch, master-flag boot echo. The team clearly learned from the 17-day crash — but applied the lesson narrowly (derive only) instead of as a general pattern.
