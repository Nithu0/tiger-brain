---
type: decision-tree
trigger: operator types "OK kjør", "kjør på", "kjør alle", "letsgooo", "BYGG ALT", "max"
autonomy_level: fix-locally
---
# When Operator Says Kjør På

## Trigger
Operator's autonomous-execute phrases (binding in global CLAUDE.md):
- "OK kjør"
- "kjør på"
- "kjør alle"
- "letsgooo"
- "BYGG ALT"
- "max"

These switch Claude from propose-mode to execute-mode. Distinct from the pre-push "OK kjør"-gate (which is also operator-OK, just at a different step).

## What's in scope
1. **The highest-value bounded item** from the most-recently-presented options list. Not a fresh idea Claude hadn't mentioned.
2. **End-to-end shipping**: TaskCreate first (if non-trivial), then parallel sub-agents per [[Parallel-Batch-Coordination]], then verification, then [[Runbook-Push-Cycle]].
3. **Reading-only operations** (audits, sweeps, MCP queries): no further gate, run immediately.
4. **Repo edits + commits**: fine, autonomous. Push still goes through the [[OK-Kjor-Gate]] (operator types the literal push command, since harness blocks direct push).
5. **Vault writes** (Obsidian inbox / `_promote-candidates`): autonomous.
6. **Multi-agent dispatch**: default to 5-10 parallel sub-agents on non-trivial work ([[Runbook-Multi-Agent-Dispatch]]).

## What's NOT in scope (still gated)
- **Railway env-var flips**: operator-only, no MCP. Claude reports recommended flags + the operator flips.
- **Discord webhook posts to external humans** (especially [[Karri]]): goes through [[Runbook-Karri-Proposal-Send]]; auto-send only during work hours 09-17 CET per `feedback_auto_send_karri.md`, otherwise hold for next morning.
- **Money-impact strategy changes**: still go through [[When-Strategy-Change-Tempting]] + proposal. "kjør på" doesn't override [[Operator-Principles]] rule 1.
- **Irreversible SQL / data deletion**: still requires explicit acknowledgement of the destructive action ("OK kjør delete X").
- **Cross-project actions**: don't pick up Master-oppgave work just because operator said "kjør alle" in Nexus context. Check `pwd` first.
- **Actions outside the most-recent options list**: no "while I'm in here, I'll also …".

## Frustration counter-trigger
If operator says "skjerp deg", "kronglete", "skjønner ikke", "irriterende" — Claude pauses execute-mode, rechecks approach, simplifies. Per `user_personality.md`.

## Verification posture
"tsc clean + commits landed" is NOT done. "User's symptom gone" is. After every push, run [[Runbook-Post-Deploy-Verification]] and report verified state, not assumed state.

## Examples from past sessions
- **2026-05-03 Batman + Prediction batches**: operator typed "BYGG ALT" → 12 commits, 4 dashboard pages, 10 firm-agents activated. All within scope (already-discussed options list).
- **Periodic verification cadence** (feedback_periodic_verification.md): after a live-loop fix, "kjør" includes scheduling 30-60 min checks against real data until positively confirmed.

## Linked
[[Operator-Principles]] · [[OK-Kjor-Autonomous-Execute]] · [[OK-Kjor-Gate]] · [[Decision-No-Auto-Activation]] · [[Parallel-Batch-Coordination]] · [[Runbook-Push-Cycle]] · [[Runbook-Multi-Agent-Dispatch]] · [[Runbook-Karri-Proposal-Send]] · [[When-Strategy-Change-Tempting]] · [[Foundation-Gate]] (max-mode does NOT bypass foundation-first — rule 4 of [[Operator-Principles]] still gates new-strategy work)
