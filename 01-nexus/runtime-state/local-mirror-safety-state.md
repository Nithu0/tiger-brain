---
type: living-state
subsystem: local-mirror-safety
last_verified: 2026-05-11T15:30Z
status: 🟢
---

# Local Mirror Safety — Living State

Documents the prod-DB guard preventing local-mirror processes (ralph loops, codex-runner) from accidentally writing to the Railway production Postgres.

## Current state (verified 2026-05-11)

- **Guard**: live in `scripts/agent-codex-runner.mjs` + ralph loop scripts (commit `15089c6`)
- **Block trigger**: `DATABASE_URL` matches `rlwy.net` OR `railway.app` host
- **Override flag**: `RALPH_ALLOW_PROD_DB=true` — explicit operator opt-in only
- **Behavior on block**: process exits with non-zero status before any DB connection attempt; emits clear error message naming the offending URL host

## How the guard works

```
on startup:
  if DATABASE_URL host contains 'rlwy.net' OR 'railway.app':
    if RALPH_ALLOW_PROD_DB != 'true':
      log: 'refusing to run against prod DB host=<host>; set RALPH_ALLOW_PROD_DB=true to override'
      exit non-zero
```

The guard is defense-in-depth on top of `AGENT_BUS_ENABLED=false` on Railway worker — those Railway processes never spawn ralph/codex; this guard catches the inverse case (operator's local machine accidentally pointing at prod).

## Recent changes

- 2026-05-11: `15089c6` — prod-DB-guard added to codex-runner + ralph; refuses rlwy.net/railway.app URLs unless `RALPH_ALLOW_PROD_DB=true`

## Health indicators

- Local ralph loops start successfully against local Postgres (no rlwy.net match → no block)
- Operator's WSL machine: `echo $DATABASE_URL` → localhost or docker URL, never Railway host
- If guard ever fires, operator sees clear "refusing to run against prod DB" error before any writes

## Open issues

- [ ] Smoke-test the guard locally: temporarily set `DATABASE_URL` to a Railway host (read-only credential) + verify both ralph and codex-runner exit cleanly
- [ ] Document the override in `docs/ops/codex-activation-runbook.md` — when prod activation lands (months away), the override flag is the explicit production-gate

## What the guard does NOT cover

- Direct `psql` / `nexus-pg-rw` connections from operator's machine — those go through MCP and are operator-authorized
- Web dashboard / API calls against production — those use API_KEY auth, not DB URL
- Any process that doesn't import the guard helper — only ralph + codex-runner currently use it

## Verification

```bash
# expect block + non-zero exit:
DATABASE_URL='postgresql://x@host.rlwy.net/db' node scripts/agent-codex-runner.mjs
# expected stderr: 'refusing to run against prod DB host=...rlwy.net...'

# expect run (with explicit override):
DATABASE_URL='postgresql://x@host.rlwy.net/db' \
  RALPH_ALLOW_PROD_DB=true \
  node scripts/agent-codex-runner.mjs
```

## Operator principles respected

- **Operator-gated irreversible action**: writing to prod from a local-mirror loop is the kind of action [[Operator-Principles]] requires explicit approval for. Guard forces that approval to be in-band (env var) rather than implicit (just happen to have the URL set).
- **Defense-in-depth**: layered on top of `AGENT_BUS_ENABLED=false` on Railway side.

Linked to: [[Nexus-MOC]], [[codex-pipeline-state]], [[Operator-Principles]], [[Module-Agent-Bus]], [[Truth-Hierarchy]] (`DATABASE_URL` host string is canonical truth; doc claims rank below), [[Runbook-Backfill-Script-Pattern]] (same `CONFIRM=YES` pattern), [[OK-Kjor-Gate]] (override flag is operator-only)
