# 2026-05-11 — scalp_overlap_asia gate strategyId fix

## Change

- **File**: `apps/worker/src/firm/managers.ts:615`
- **Before**: `strategyId: "xau-htf-trend"`
- **After**: `strategyId: "xau-scalp-overlap"`
- **Commit**: `f2688d6` (branch `main`, NOT pushed)
- **tsc**: clean (apps/worker)
- **Tests**: 65/65 pass on new-gates + scalp-overlap + strategy-blade + status-report suites

## Operator-relevant analysis (please read)

The bug-as-described in `docs/ref/known-issues.md:9` was partly stale. I made the fix the task requested, but want to flag what I found so you can decide on follow-up.

### Two `evaluateNewGates` call-sites exist

1. **`managers.ts:615` (firm/bladeApproval)** — the legacy htf-trend firm path. Hardcoded strategyId. This is what the fix changes. **This path is bypassed in production when `ORB_ONLY_MODE=true`** (current TIER 3 state — see `orchestrator.ts:417-426`). So the fix is dormant in current prod.

2. **`strategy-blade.ts:164` (mini-Blade)** — used by the 4 TIER 3 strategies (orb, scalp-overlap, session-breakout, vol-expansion). Already passes `input.strategyId` **dynamically**. Landed 2026-04-27 in `779dd49`. Persistence added 2026-05-06 in `19f1534`. Requires `STRATEGY_BLADE_ENABLED=true` (per `docs/ops/gate-silence-2026-05-08.md` operator-side verification — should be true on Railway).

So for actual scalp-overlap trades in TIER 3, the gate has been firing correctly via path #2 since 04-27. The known-issues entry was written before the mini-Blade landed.

### What my fix accomplishes

- Path #1 (managers.ts) is now consistent with the gate's intent: if `ORB_ONLY_MODE` is ever flipped to `false`, the scalp_overlap_asia gate will at least evaluate as if the firm-path were a scalp-overlap trade.
- **Caveat**: path #1 represents the legacy htf-trend trend-following firm path, not a scalp-overlap path. So the fix makes the gate accurately "fire" but the trade it's evaluating isn't actually a scalp-overlap signal. If ORB_ONLY_MODE ever turns off, every Asian-session trade through bladeApproval will now be soft-flagged (or hard-rejected if `SCALP_OVERLAP_ASIA_BLOCK=true`).
- For current TIER 3 prod (`ORB_ONLY_MODE=true`), this fix is inert — the bladeApproval path doesn't run.

### Better long-term fix (NOT done — operator decision)

The real architectural fix is one of:
- Remove the `evaluateNewGates` call from `managers.ts` entirely (path is bypassed in TIER 3; gate belongs in the strategy-blade.ts mini-Blade where dynamic strategyId works).
- OR pass the strategy context into `bladeApproval` so the strategyId can be set dynamically.
- AND update the stale `known-issues.md:9` entry — the cross-path scalp_overlap_asia firing is already implemented via strategy-blade.ts. Mark resolved.

I did NOT do these because the task spec said "keep the fix MINIMAL: hardcode the correct name. Avoid refactoring." Flagging for your decision.

## Verify in prod

- If `ORB_ONLY_MODE=true` (current): no behavioural change from this commit.
- If `ORB_ONLY_MODE=false`: any Asian-session trade evaluated by bladeApproval will now soft-log a scalp_overlap_asia hit in `gate_decisions`. Hard-reject only if `SCALP_OVERLAP_ASIA_BLOCK=true`.

## Next

- "OK kjør" gate before push (per binding rule 5).
- Decide on the long-term fix per "Better long-term fix" above.
- Update `docs/ref/known-issues.md` line 9 to reflect resolution + accurate architecture.
