---
date: 2026-05-11
project: nexus
topic: codex-phase-2a-e2e-verify
status: blocked-by-design
---

# Codex Phase 2a — E2E drain verification

## Test task

| Field | Value |
|---|---|
| `id` | `test-e2e-20260511-161605` |
| `role` | `code` |
| `model` | `codex-2.5` |
| `prompt` | "Read docs/onboarding/index.md and report its first 3 section headings as a JSON array. Do not modify any files." |
| `context_refs` | `["docs/onboarding/index.md"]` |
| `priority` | 50 |
| `created_by` | `claude-e2e-verify` |
| Inserted at | 2026-05-11 14:16:05 UTC |

## Result after 60s+ wait

| Check | Outcome |
|---|---|
| `agent_tasks.status` | `queued` (unchanged at 66s) |
| `claimed_at` / `claimed_by` | `NULL` |
| `finished_at` | `NULL` |
| `agent_artifacts` rows for task | 0 |
| `agent_results` rows for task | 0 |

**Verdict: EXPECTED no-drain.** The drainer is local-only by design.

## Why expected

`scripts/agent-codex-runner.mjs` lines 106–117 enforce a hard guard added 2026-05-11 (post cipher-9131-movefh22 incident):

```
PROD_HOST_PATTERNS = ["rlwy.net", "railway.app", ".rds.amazonaws.com"]
if DATABASE_URL matches a prod pattern AND RALPH_ALLOW_PROD_DB != "true":
    process.exit(4)   // refuse to claim
```

Our prod DB host is `trolley.proxy.rlwy.net` — matches `rlwy.net`. The Railway worker therefore CANNOT run `agent-codex-runner.mjs` without the operator-only override. `AGENT_BUS_ENABLED=true` on Railway only ensures the bus tables are reachable; it does not run the drainer.

The codex-drainer activation is operator-side: locally via `node scripts/agent-codex-runner.mjs --max=1` (one-shot) or under Ralph loop.

## What IS verified

- Bus schema present + writable: insert succeeded into `agent_tasks` with the deployed columns (`prompt`, `context_refs`, `idempotency_key` NOT NULL, `id` text).
- Prod-DB safety guard is doing its job (no rogue local Codex run touched the row).
- `mcp__nexus-pg__query` (RO) and even `mcp__nexus-pg-rw__query` are BOTH effectively read-only — the `@modelcontextprotocol/server-postgres` package wraps every txn in `BEGIN READ ONLY`. The INSERT had to go through `psql "$DATABASE_URL"` using the session-env URL. This means `nexus-pg-rw` as currently configured is misleading — it cannot write. Worth fixing or renaming.

## What is NOT verified yet

- A full claim → codex exec → diff artifact → result envelope → cost capture pass. That requires running the drainer locally with `RALPH_ALLOW_PROD_DB=true` (operator decision) or pointing it at a non-prod DB.

## Open row

The task row remains `queued` in prod. It is harmless (read-only prompt, no impact on trading loop) and provides an audit trail. If operator wants it cleared:

```sql
DELETE FROM agent_tasks WHERE id='test-e2e-20260511-161605';
```

Or run the local drainer with prod override to drain it for real.

## Suggested operator next step

Choose one:
1. **Skip full E2E for now** — infrastructure verified, drainer activation deferred to when there's a real code-task to ship.
2. **Run local drainer one-shot with prod override** — `cd /home/nithu/code/ai-assistent && RALPH_ALLOW_PROD_DB=true AGENT_BUS_ENABLED=true node scripts/agent-codex-runner.mjs --max=1` and watch Claude tail `agent_results` for cost/tokens.
3. **Spin up a local mirror DB** + point drainer at it to verify against without prod risk.

Recommend (1) until there's actual code work queued — running the drainer against prod just to verify $0.001 of tokens is low-signal.
