---
date: 2026-05-11
project: nexus
type: applied-fix
status: shipped (defensive); operator-action-pending (Tier-1 upgrade)
commit: a301b8b
---

# Gemini drainer fix — soft rate-limit gate + Tier-1 upgrade guide

## Context (audit 2026-05-11)
- Research drainer failing 48.6 % of attempts.
- 77.8 % of failures = HTTP 429 from Gemini free-tier daily/per-minute caps.
- Volume is tiny (<$1/month at paid pricing). Free tier is the bottleneck, not the cost.

## What landed in this commit (a301b8b)

### Part B — defensive in-code gate (in production once commit deploys)
- New env: `GEMINI_QUOTA_PAUSE_THRESHOLD` (default 3, range 1–100).
- On every observed 429 in the drainer, append a timestamp to a rolling
  1-hour window persisted in `firm_state` (`agent_bus:research_drainer:recent_429s`).
- When window count ≥ threshold, arm a one-tick pause flag
  (`agent_bus:research_drainer:quota_paused_until_next_tick`).
- Next drain tick: skip the claim, publish a blackboard FACT on topic
  `xauusd.research.quota_paused` (department=cipher, urgency=high, expires 6 h),
  consume the flag, return `status: "quota_paused"`. Subsequent ticks resume normally.
- Single-skip rather than long pause = self-healing; rolling window decays as timestamps age out.
- Observation-only — never auto-disables the drainer (per operator-prinsipper #1).

### Part C — operator upgrade guide
- `docs/ops/gemini-tier1-upgrade.md` — full step-by-step:
  1. https://aistudio.google.com/apikey → find project linked to current `GEMINI_API_KEY`.
  2. https://console.cloud.google.com/billing → enable billing on that GCP project.
  3. Tier auto-upgrades — **no API key change, no Railway env change, no restart**.
  4. Verification SQL on `agent_tasks` 24 h after.
  5. Rollback: disable billing → reverts to free tier.
  6. Recommended $25/month budget alert (email-only, no auto-disable).

### Files touched
| File | LoC delta | Purpose |
|---|---|---|
| `apps/worker/src/firm/agent-bus/research-drainer.ts` | +146 / -3 | quota gate logic |
| `apps/worker/src/firm/agent-bus/research-drainer.test.ts` | +45 / 0 | 2 new tests (quota_paused, env default) |
| `apps/worker/src/firm/orchestrator.ts` | +1 / -1 | pass `this.board` to drainer |
| `.env.example` | +2 | document new env-var |
| `docs/ops/gemini-tier1-upgrade.md` | new (162 lines) | upgrade guide |

## Verification
- `cd apps/worker && npx tsc --noEmit` → clean.
- `npm test` (worker) → **445/445 pass** (was 443; +2 new tests).
- Pre-commit hook ran tsc on worker → OK.

## Operator next action
1. **Read** `/home/nithu/code/ai-assistent/docs/ops/gemini-tier1-upgrade.md`.
2. **Upgrade**: 3 clicks in Google Cloud Console (link billing to the existing project that holds `GEMINI_API_KEY`).
3. **Wait 24 h** then run the verification SQL in the guide.
4. **Optionally** set $25/month budget alert (also in the guide).
5. **Push** when ready: `! git push origin main` (commit `a301b8b`).

## Steady-state behaviour after deploy
- If Tier-1 is active: quota gate never fires; `xauusd.research.quota_paused` is silent.
- If still on free tier: gate fires after 3 × 429 in 1 h, skips one drain tick, emits blackboard FACT (visible in dashboard + Discord delivery if `DISCORD_LEGACY_ENABLED=true`).
- Operator sees the event but trading is unaffected (drainer is post-cycle, fully wrapped).

## Audit trail
- Commit `a301b8b` (local, awaiting `! git push`).
- Branch `main`, 4 commits ahead of `origin/main` (3 from prior sessions + this one).
- Other working-tree files modified by prior sessions (agent-trigger, risk-advisor, phase-status) were **not** included in this commit — focused diff per operator scope discipline.
