# Challenge-agents decouple — STOPPED (strategy-touch)

**Date**: 2026-05-11
**Task**: Per perf audit, decouple `await runAllChallenges()` from orchestrator hot path.
**Decision**: **STOPPED**. This is a strategy/risk change, not a perf fix. Filing as proposal, not implementing.

---

## What I found

The perf audit's assumption ("challenges are informative/logging") is wrong. The current code structure uses challenge results to **block decisions in the same cycle**.

### Call chain

- `apps/worker/src/firm/orchestrator.ts:438` — orchestrator `await`s `bladeApproval(...)`
- `apps/worker/src/firm/managers.ts:376` — inside `bladeApproval`, `await runAllChallenges(board, proposalId, synthesis)`
- `apps/worker/src/firm/managers.ts:380-389` — reads challenges back via `board.readChallenges(proposalId)`, computes `strongChallenges` (strength >= 4), sets `isBlocked`
- `apps/worker/src/firm/managers.ts:597-599` — decision branch:
  ```ts
  } else if (isBlocked) {
    decision = "BLOCKED_PENDING_RESPONSE";
    reason = `Blocked by ${strongChallenges.length} strong challenge(s): ${strongChallenges[0].thesis}`;
  }
  ```

This sits **above** `portfolioBlock`, `marketThesisPassed`, and `entryGatesPassed` in the decision waterfall — challenges have veto power on the trade.

### Flag state

- `CHALLENGE_AGENTS_ENABLED` defaults to **on** in code (`challenge-agents.ts:244` returns only when `=== "false"`).
- Production currently sets it to `false` per ORB_ONLY_MODE (`docs/strategy/orb-master-plan.md:147`) — so the hot-path block is **currently dormant in prod**, but the code path is "default-on" and the flag is operator-controlled.

So the perf-audit symptom (0-120s LLM stalls) only fires when operator flips `CHALLENGE_AGENTS_ENABLED` back on. The bigger issue: when it IS on, the orchestrator hot path is gated by LLM call latency.

---

## Why this is a strategy proposal, not a fix

Option A (fire-and-forget) changes the **decision semantics**:

- Before: challenges complete → strong objections block proposal in same cycle → `BLOCKED_PENDING_RESPONSE`
- After: challenges fire async → proposal decided WITHOUT them → APPROVED can fire and execute before objections arrive

That's not a perf-tune. That removes the challenge-veto. Even with a "lastInFlight tracker", the gap between "fire" and "land in blackboard" means the cycle decides on stale (previous-cycle) or no challenge data.

Option B (defer to next cycle) is the same problem with 1-cycle latency: the proposing cycle becomes vulnerable to entering a trade the challenger would've blocked.

Per CLAUDE.md operator-prinsipp #4 + strategy-change protocol: this needs Karri's review before implementation.

---

## What operator should know

1. **No code change shipped.** No commit, no push.
2. **Production not affected.** ORB_ONLY_MODE keeps `CHALLENGE_AGENTS_ENABLED=false`, so the hot-path block is dormant.
3. **Perf audit recommendation rests on a wrong premise** that challenges are informative-only. They aren't — they're a veto layer.
4. **Real fix paths** (need strategy review):
   - Tighten challenge LLM timeouts (5-10s cap) so the block is bounded.
   - Convert challenges to be advisory (lower their strength cap below blocking threshold) — but that's a strategy decision.
   - Pre-compute challenges in parallel with thesis-synthesis, then `await` on already-running promise at the gate point (overlap, not decouple).
   - Move challenge gating to post-execution review (kill-switch trade vs. block proposal).

Recommend filing a strategy proposal `docs/strategy/proposals/2026-05-11_challenge-async.md` if/when operator wants to revisit. Send to Karri.

---

## Files referenced

- `/home/nithu/code/ai-assistent/apps/worker/src/firm/orchestrator.ts:438`
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/managers.ts:344-413`
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/managers.ts:594-600`
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/challenge-agents.ts:236-251`
- `/home/nithu/code/ai-assistent/docs/ref/feature-flags.md:58`
- `/home/nithu/code/ai-assistent/docs/strategy/orb-master-plan.md:147`
