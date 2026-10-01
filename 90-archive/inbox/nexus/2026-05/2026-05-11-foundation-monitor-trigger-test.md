---
date: 2026-05-11
project: nexus
topic: foundation-monitor verification
commit: 8bc0394
status: verified-likely-firing
---

# Foundation-Monitor trigger verification (commit 8bc0394)

## Source-of-truth code

`apps/worker/src/firm/foundation-monitor.ts` (488 lines) + wired in `apps/worker/src/firm/orchestrator.ts:269-274` as Step 0a2c.

## Alert-trigger conditions (verbatim from code)

### Env gate (`isFoundationMonitorEnabled`)
- `FOUNDATION_MONITOR_ENABLED === "true"` strict-equal. Anything else = no-op.

### Cooldown (`isWithinCooldown`)
- Reads `firm_state.updated_at` for key `foundation_monitor:last_state`.
- If `Date.now() - updated_at < 15 * 60 * 1000` (15 min) → SKIP, return `skipped: "cooldown"`.
- If row missing → run anyway (treat as first-run).
- Cooldown is the SAME timer as `persistState` — every run advances it (including no-change runs).

### Diff logic (`diffSnapshots`)
- **First-run** (no prior): alert ONLY if any rule is YELLOW or RED. All-GREEN baseline → silent.
- **Subsequent runs**: alert on rules where `prev.state !== cur.state`.
- **UNKNOWN sentinel** — both directions ignored:
  - `prev.state === "UNKNOWN"` → skip (don't promote out of unknown)
  - `cur.state === "UNKNOWN"` → skip (don't demote to unknown)
  - Protects Rule 1 (phase-status.md, manual) + Rule 3 (Railway deployments) from flapping.

### Webhook URL precedence
```ts
const webhookUrl =
  process.env.DISCORD_ALERTS_WEBHOOK_URL ??
  process.env.DISCORD_WEBHOOK_URL ?? null;
```
Falls back to generic webhook if alerts-specific not set. Both null → `webhookConfigured=false`, no POST, but state still persists.

### Delivery
- Only if `changes.length > 0 AND webhookUrl !== null`.
- `postFoundationDiscordEmbed` → best-effort, never throws, 5s timeout.
- Returns `delivered: false` on any HTTP failure (logged via `logWarn`, no retry).
- Color: red if any change went red, else yellow, else green.

## Live state probes

### `firm_state` row
```
key:        foundation_monitor:last_state
updated_at: 2026-05-11T17:42:54.683Z (7 min ago at query time)
```

**Key finding:** the persisted state has been refreshed at 17:42Z — NOT stuck at the 13:48Z baseline mentioned in the assignment. The monitor IS running on Railway and re-persisting on each cycle past the 15-min cooldown. The 15-min cadence is being honored.

### Current snapshot in persisted state
- Rule 1: UNKNOWN (manual doc, expected)
- Rule 2: GREEN (POSITION_MANAGEMENT_ENABLED=true)
- Rule 3: UNKNOWN (Railway deploys, expected)
- Rule 4: GREEN (entry_stack_cooldown 20d, 1957 evals — well above 7d/50 threshold)
- Rule 5: GREEN (0 overdue claude/both followups)

Overall: GREEN (UNKNOWN doesn't poison `worst()`).

### Webhook configuration (Railway)
- Cannot read `.env.local`/Railway env directly (deny rule).
- Local `env-doctor.sh` reports `MISSING: DISCORD_ALERTS_WEBHOOK_URL` — expected; operator only sets it on Railway.
- Per `docs/ops/phase-status.md` line 73: `DISCORD_LEGACY_ENABLED=true` flipped this round, alongside `FOUNDATION_MONITOR_ENABLED=true` (line 74). Implies operator is in the Discord-delivery phase. Webhook configured: **assumed yes on Railway** (not directly verifiable from this sandbox).
- Verification path: operator can confirm via Railway dashboard, or via `curl https://<api>/health` (which would expose `webhook=set` in foundation-monitor log lines).

### Blackboard / agent_audit search
- `blackboard` topic/message_type/agent LIKE `%foundation%`: **0 rows**.
- `agent_audit` event/actor LIKE `%foundation%` OR `%gate%` last 24h: **0 rows**.
- `agent_artifacts` kind/path LIKE `%foundation%`: **0 rows**.

**Important interpretation:** the monitor does NOT publish to blackboard / agent_audit / agent_artifacts. It only writes to `firm_state` (state persistence) and POSTs Discord (alert delivery). Absence of rows is **not evidence of failure** — it's the designed behavior. The only DB-side evidence the monitor ran is the `firm_state.updated_at` advancing, which it is.

## Historical state-change events
**Count: 0** since baseline was first written. All rules have stayed GREEN/UNKNOWN since the initial all-green baseline. No flips → no Discord deliveries expected since deploy.

## Cooldown logic — verbatim summary
- 15-min window enforced via `firm_state.updated_at`, not in-process memory → survives worker restarts.
- Every run persists, so a no-change run still advances the cooldown clock.
- Cannot be bypassed without DELETE on the firm_state row OR rewriting `updated_at` backwards.

## Verdict

**Monitor likely-firing-correctly.** Evidence:
1. Code path is straightforward, well-tested (`foundation-monitor.test.ts` covers env gate, all rule paths, diffSnapshots edge cases, cooldown, persistState).
2. `firm_state.updated_at` is advancing (17:42Z, 7 min before query) — proves the orchestrator IS invoking `runFoundationMonitor` and the cooldown is being respected.
3. Compute path is observable: latest persisted snapshot reflects current env + DB state correctly (Rule 2=GREEN per `POSITION_MANAGEMENT_ENABLED=true`, Rule 4=GREEN per gate_decisions).
4. No state changes have occurred since baseline → no Discord posts expected → absence of Discord delivery is consistent with all-green state, not silent failure.

**What we CANNOT confirm from here:**
- Whether `DISCORD_ALERTS_WEBHOOK_URL` is actually set on Railway (only operator can verify).
- Whether a real POST to Discord would succeed (would require a real state change; no historical posts to inspect).

## Recommendation

**Wait for a real state-change.** Reasons:
1. The 5 rules cover env vars + slow-moving DB metrics — natural transitions will happen within days (e.g., Rule 5 yellow on first overdue followup; Rule 4 yellow if a new gate is added).
2. Manufacturing a fake state-change is risky on prod even read-only — would require either editing Railway env (POSITION_MANAGEMENT_ENABLED=false) or DELETE/UPDATE on `firm_state`. Both touch prod write paths.
3. Cheap pre-test that doesn't touch prod: operator can run the test suite (`npm test --filter foundation-monitor`) to validate diff + cooldown logic, and visually inspect the embed shape.
4. If operator wants a positive-confirmation TODAY: temporary, safe option is to set `DISCORD_ALERTS_WEBHOOK_URL` to a throwaway test-channel webhook for one cycle, then DELETE `firm_state.foundation_monitor:last_state` row (forces first-run baseline) — but this is invasive and the next non-GREEN rule would surface anyway. **Recommend skip.**

## Files referenced
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/foundation-monitor.ts`
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/foundation-monitor.test.ts`
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/orchestrator.ts` (line 269)
- `/home/nithu/code/ai-assistent/docs/ops/phase-status.md` (line 74)
- `/home/nithu/code/ai-assistent/.env.example` (line 65)
