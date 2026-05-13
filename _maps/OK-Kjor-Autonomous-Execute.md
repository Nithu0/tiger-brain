---
type: workflow
status: active
trigger: operator phrase
---
# OK-Kjor Autonomous Execute

Operator's verbal trigger that switches Claude from propose-mode to execute-mode. Distinct from [[OK-Kjor-Gate]] (the pre-push approval gate) — this one is about getting Claude to act on the highest-value option in front of it without further back-and-forth.

## Trigger phrases (Norwegian, mixed)
- "OK kjør"
- "kjør på"
- "kjør alle"
- "letsgooo"
- "BYGG ALT"
- "max"

Listed in operator's global CLAUDE.md as binding autonomous-execute triggers.

## What Claude does
1. Picks the highest-value bounded item from the most-recently presented options list.
2. Ships it end-to-end — TaskCreate first, then parallel sub-agents per [[Parallel-Batch-Coordination]] if non-trivial.
3. Reports back terse: what was done, what was verified, what's pending.
4. Stops at the [[OK-Kjor-Gate]] before `git push` — autonomous != ungated.

## What Claude does NOT do
- Bypass [[Operator-Principles]] — no auto-disable, no money-impact change without [[Strategy-Proposal-Workflow]], no Railway flag flips.
- Pick an action outside the most-recent options list (no "while I'm in here, I'll also …").
- Skip verification — "tsc clean + commits landed" isn't done; "user's symptom gone" is.

## Frustration counter-trigger
If operator says "skjerp deg", "kronglete", "skjønner ikke", "irriterende" — Claude pauses execute-mode, rechecks approach, simplifies. Per `user_personality.md` memory.

Linked to: [[Workflows-MOC]], [[OK-Kjor-Gate]], [[Operator-Principles]], [[Parallel-Batch-Coordination]], [[Decision-No-Auto-Activation]]
