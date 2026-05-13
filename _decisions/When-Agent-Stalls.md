---
type: decision-tree
trigger: firm-agent (Atlas, Prism, Shield, Forge, etc.) is enabled but produces no output or last_run_at is stale
autonomy_level: fix-locally
---
# When Agent Stalls

## Trigger
A firm-agent shows `enabled=true` in the registry but `/firm-agents/status` reports `last_run_at` older than its expected cadence (e.g. Atlas review-worker hourly, but `last_run_at` is 6 hours stale). Canonical incident: review-worker stall on atlas-2474 batch.

Sibling: a draining worker that should be consuming from a topic but the topic depth keeps growing.

## Diagnose order
1. **Confirm the stall is real**: `curl /firm-agents/status` (authenticated). Compare `last_run_at` to expected interval. Double-check against `last_error` field — many "stalls" are silently caught errors looping.
2. **Worker logs**: Railway worker → grep for the agent's namespace (`[firm.atlas]`, `[firm.prism]`, etc.). Look for the **last successful** line then the **first error or silence**. The boundary tells you what broke.
3. **Topic depth (for drainers)**: `SELECT topic, count(*) FROM firm_messages WHERE consumed_at IS NULL GROUP BY topic;` — growing depth + stale `last_run_at` = drainer isn't pulling.
4. **DB transaction state**: agent stuck in a long-running transaction? `SELECT pid, state, query FROM pg_stat_activity WHERE state != 'idle';` via [[MCP-nexus-pg]].
5. **Memory/CPU**: Railway worker resource panel. OOM kills look like stalls from the outside.
6. **Run a manual cycle**: many firm-agents expose `/firm-agents/:name/run-once` for ops. Triggering it manually surfaces the error if logs were too noisy.

## Action by classification
- **Caught-but-unlogged error** → fix locally: improve error logging + add the error surface to `/firm-agents/status`. Commit, push, verify.
- **DB deadlock / long transaction** → fix locally: add timeout + retry-with-backoff. Commit. Consider whether the migration that introduced the lock needs a rethink.
- **OOM** → operator-decision: bump Railway plan vs. trim memory footprint. Report both options.
- **Drainer wired to wrong topic** → fix locally: rewire + add an assertion that fails fast at startup if the topic doesn't exist.
- **Strategy-touch** (agent's decision logic is questioned, not its plumbing) → [[When-Strategy-Change-Tempting]] applies. Karri-spor.
- **Irreversible** (proposed deletion of agent state) → "OK kjør"-gate.

## What never auto-fires
- Disabling the agent to silence the alarm. That just hides the stall, see [[Decision-No-Auto-Activation]].
- Force-clearing the agent's queue without operator-OK (data loss).

## Examples from past sessions
- **Atlas review-worker stall (atlas-2474)**: review-worker processed batch 2474 but never advanced cursor. Root cause: silent exception in a downstream `firm_memory` write. Fix: added try/catch with explicit error surface + commit log. Pattern: "if the worker stalls but doesn't crash, look for caught-but-unlogged errors in the **downstream** writes, not the agent's own loop."
- **firm-agents 6/10 active**: 4 agents are intentionally dormant pending operator-activation, not stalled. Read [[firm-agents-state]] before flagging a "stall".

## Linked
[[Operator-Principles]] · [[Module-Postmortem]] · [[firm-agents-state]] · [[Decision-No-Auto-Activation]] · [[When-Gate-Goes-Silent]] · [[Runbook-Post-Deploy-Verification]] · [[Truth-Hierarchy]] · [[Foundation-Gate]] (rule 5: postmortem write rate)
