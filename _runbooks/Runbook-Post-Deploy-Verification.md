---
type: runbook
trigger: a push has landed on main and Railway has deployed (or is deploying)
autonomy_level: fix-locally
---
# Runbook: Post-Deploy-Verification

What to query after every push lands, so "tsc clean + commits landed" turns into "user symptom gone". Binding per [[Operator-Principles]] safety rule 4.

## Within 5 minutes of push
1. **Deploy completed**: visit Railway dashboard OR `curl https://api-production-b660.up.railway.app/health` and confirm the response includes the new commit SHA in `version`.
2. **No regression in core health JSON**: `db: ok`, `broker: ok`, `blackboard: ok`, `worker: running`, `reconciliation: <expected-state>`.
3. **No new error spike**: Railway worker log over the last 5 min — grep for `ERROR|FATAL|UNHANDLED`. Baseline = matching the previous 5-min window.

## Within 15 minutes — change-specific verification
This is the part operators forget. Match the verification to the change shape:

### If change touched DB schema / metadata stamping
- `SELECT count(*) FROM <table> WHERE <new_column> IS NOT NULL AND created_at > now() - interval '15 minutes';`
- Expect > 0 if the system has been active. If 0 → fix didn't deploy or path isn't being hit.

### If change touched gate logic
- `SELECT max(created_at), count(*) FROM gate_decisions WHERE created_at > now() - interval '15 minutes';`
- Pair with `/firm-agents/status` to confirm gates ran since deploy.

### If change touched a firm-agent
- `curl /firm-agents/status` — find the agent, check `last_run_at` advanced past the deploy time.
- Worker log: grep `[firm.<agent>]` for fresh activity.

### If change touched env-var / `.env.example` sync
- Operator confirms the Railway flag is now set (env-var fixes are pointless until flag is flipped).
- Then re-verify the downstream effect (often, this falls back to one of the categories above).

### If change touched docs / Obsidian / CLAUDE.md
- No DB verification needed. Verify the links resolve (`ls -la` the target paths). Verify the MOC graph still navigable.

## Within 30-60 minutes — money-impact follow-up
Per `feedback_periodic_verification.md`: for any live-loop change (gates, strategies, position-management, sizing), schedule a re-check 30-60 min later against fresh trade data. Do not assume green just because the 15-min check was green.

## What to report back to operator
Format:
```
Push: <SHA> shipped at <hh:mm>
Deploy: ok / failed / pending
Health: <db/broker/blackboard/worker> all ok
Change-specific: <one sentence — what query, what result, vs expected>
Next check: <hh:mm> for <reason>
```

Keep terse. No multi-section reports unless operator asks.

## What never auto-fires
- Declaring a fix "done" without the change-specific verification step.
- Rolling back deploys without operator-OK ([[Decision-No-Auto-Activation]] applies).
- Auto-disabling a feature because the post-deploy check found a regression ([[Operator-Principles]] rule 1 — REPORT, don't act).

## Examples from past sessions
- **2026-05-11 round-5 post-push verification**: see `00-claude-inbox/nexus/2026-05-11-round-5-post-push-verification.md` for the canonical shape.
- **Metadata-stamping fix verification**: query at +15 min showed `strategy_id NOT NULL` count = 3 fresh trades. Green.

## Linked
[[Operator-Principles]] · [[Runbook-Push-Cycle]] · [[OK-Kjor-Gate]] · [[MCP-nexus-pg]] · [[Live-Endpoints]] · [[Phase-Status-Pointer]]

Memory refs: `feedback_periodic_verification.md`, `feedback-verification-gate.md`.
