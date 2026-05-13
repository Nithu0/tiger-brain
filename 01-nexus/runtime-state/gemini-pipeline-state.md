---
type: living-state
subsystem: gemini-research-drainer
last_verified: 2026-05-11T15:30Z
status: 🟢
tier: tier-1-paid
tier_verified: 2026-05-11
---

# Gemini Pipeline — Living State

Living state doc. Source: `agent_tasks` + `agent_results` joined on `role='research'`.

## Current state (verified 2026-05-11)

- **Model**: `gemini-2.5-flash` (mapped from `task.model='gemini-flash'`)
- **API path**: SDK via `@google/generative-ai`, in-process on Railway worker
- **Auth**: `GEMINI_API_KEY` (or `GOOGLE_API_KEY` alias) — present + valid
- **Tier**: **Tier-1 paid** — upgraded 2026-05-11 today
- **Soft rate-limit gate**: in code, default OFF, threshold=3 (per commit `a301b8b`)
- **Drainer**: enabled via `FIRM_RESEARCH_DRAINER_ENABLED=true`, cooldown 120s, MAX_ATTEMPTS=3, 180s LLM timeout
- **Workers**: `worker-research-drainer-12` active

## New failure-rate expectation (post Tier-1 upgrade)

| Window | Pre-upgrade (free tier) | Post-upgrade (Tier-1 expected) |
|---|---|---|
| 7-day failure rate | ~53% (quota_429 dominant) | <2% (only transient 503 + timeouts) |
| 24h failure rate | 30-70% | 0% |
| Cost per 1k research tasks | $0 (free-tier) | ~$1-3 (Tier-1 paid) |
| Soft rate-limit gate trigger | n/a | activates at 3 consecutive 429s (default OFF) |

**Verification target**: 48-72h post-upgrade, fail rate should stabilize <2%. If 429s appear, the new soft rate-limit gate (a301b8b) is the diagnostic, not auto-disable.

## Recent changes

- 2026-05-11: operator upgraded GCP project to Tier-1 paid
- 2026-05-11: `a301b8b` — added soft rate-limit gate (threshold=3 consecutive 429s, default OFF); report-only when enabled, per [[Operator-Principles]] rule 1

## Health indicators

- Zero `quota_429` errors in last 24h (post upgrade)
- SDK mode active on all worker-drainer results (no CLI-mode regressions)
- `GEMINI_API_KEY` valid (no 401/PERMISSION_DENIED)
- Task runtimes 75-145s (normal SDK band)

## Open issues

- [ ] T+48h verification: confirm <2% fail rate sustained
- [ ] Tier-1 ceiling watch: flash limit ~1000 RPM / ~10K RPD — alert if daily volume approaches
- [ ] Audit non-worker claimers — `cipher-9131-movefh22` appeared once 2026-05-07; verify not a local-mirror loop touching prod queue
- [ ] In-memory `taskAttempts` counter doesn't survive worker restart (unchanged)
- [ ] Error truncation at 300 chars in `failTask` cuts Gemini docs URL (cosmetic, unchanged)

## Verification SQL

```sql
SELECT date_trunc('day', r.created_at) AS day,
       SUM(CASE WHEN r.status='success' THEN 1 ELSE 0 END) AS ok,
       SUM(CASE WHEN r.summary LIKE '%429%' THEN 1 ELSE 0 END) AS q429,
       SUM(CASE WHEN r.summary LIKE '%503%' THEN 1 ELSE 0 END) AS q503,
       SUM(CASE WHEN r.summary LIKE '%exit 124%' THEN 1 ELSE 0 END) AS timeouts,
       COUNT(*) AS total
FROM agent_results r JOIN agent_tasks t ON r.task_id=t.id
WHERE t.role='research' AND r.created_at > NOW() - INTERVAL '7 days'
GROUP BY 1 ORDER BY day DESC;
```

Expected: q429=0, q503≈0, timeouts≈0, ok≈total.

## Cross-refs

- Code: `apps/worker/src/firm/agent-bus/research-drainer.ts`
- Code: `apps/worker/src/firm/agent-bus/firm-agents/llm.ts:240-287` (callGemini SDK path)
- Env-vars: `docs/ref/env-vars.md` lines 78-90
- Architecture: `docs/ref/agent-bus.md`

Linked to: [[Nexus-MOC]], [[Module-Agent-Bus]], [[codex-pipeline-state]], [[Operator-Principles]], [[Truth-Hierarchy]] (provider dashboard above this doc), [[When-Quota-Blocks-Pipeline]], [[Runbook-Quota-Upgrade|Quota-Upgrade]], [[Foundation-Gate]] (research-drainer feeds postmortem write rate → rule 5)
