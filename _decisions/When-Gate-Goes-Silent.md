---
type: decision-tree
trigger: a table/event-stream that should be writing has produced 0 rows for ≥ 1 hour during market open
autonomy_level: fix-locally
---
# When Gate Goes Silent

## Trigger
A table that the morning briefing or health-check expects to grow is flat. Canonical incident: `gate_decisions` 0 rows for 14 days (2026-04-24 → 2026-05-08), [[gate-silence-2026-05-08]].

Sibling patterns: `signals` flat, `firm_messages` flat for a specific topic, `analysis_snapshots` flat. Same five-layer playbook applies.

## Diagnose order (the "silent-blocker" five-layer grep)
1. **DB layer**: `SELECT max(created_at), count(*) FROM <table> WHERE created_at > now() - interval '24 hours';` via [[MCP-nexus-pg]]. Confirm the silence is real, not a clock or timezone artefact.
2. **Worker logs**: Railway worker → grep for the module name + `error|skip|veto|blocked`. Most silent failures already log a skip reason; you just have to look.
3. **Env-var layer**: does the feature have a kill-switch? Check `docs/ref/env-vars.md` AND `.env.example`. If the flag isn't in `.env.example` → it's invisible to the operator and probably stuck at default false. **This was the gate-silence root cause.**
4. **Code path**: read the module's `index.ts` and orchestrator wiring (`apps/worker/src/firm/orchestrator.ts:runCycle()`). Is the call actually wired into the cycle? Lots of silent failures = a function exists but nothing calls it.
5. **Schema**: does the table have a NOT NULL column that recent code stopped populating? `psql \d+ <table>` + the most recent INSERT site in code.

Reference playbook: `docs/ref/silent-blocker-debug.md`.

## Action by classification
- **Env-var drift** (flag exists in code but missing from `.env.example`) → fix locally: sync `.env.example`, commit, push. Operator flips the flag on Railway after deploy. NO proposal needed — it's a doc/visibility fix, not a behaviour change.
- **Wiring bug** (function never called) → fix locally + commit. Add a test that exercises the cycle path so it can't silently regress.
- **Schema mismatch** (recent migration broke an INSERT) → fix locally + commit. If migration needs reversal → "OK kjør"-gate, irreversible class.
- **Strategy-touch** (someone proposes "let's disable the silent gate to unblock") → NO. File via [[When-Strategy-Change-Tempting]]. Silence is not a reason to remove a guardrail.
- **Operator decision required** (gate is intentionally off pending business call) → flag and stop.

## What never auto-fires
- Removing a gate to "unblock" trades when it's silent. Silence means broken plumbing, not a reason to lower defences ([[Operator-Principles]] rule 1).

## Examples from past sessions
- **Gate-silence 2026-05-08**: `gate_decisions` 0 rows for 14 days. Root cause: `STRATEGY_BLADE_NEW_GATES` undocumented in `.env.example` (1 of 156 missing vars). Fix: synced `.env.example` (commit 937bd30), operator flipped flag → resumed ~12 rows/24h same day. Single most-impactful operability lesson in the project.
- See [[gate-silence-2026-05-08]] for the incident pointer and `docs/ops/gate-silence-2026-05-08.md` for the full diagnostic.

## Linked
[[Operator-Principles]] · [[Foundation-Gate]] · [[Truth-Hierarchy]] · [[gate-silence-2026-05-08]] · [[Runbook-Post-Deploy-Verification]] · [[When-Agent-Stalls]] · [[MCP-nexus-pg]]
