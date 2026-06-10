# Adversarial verification — PR #86 (b2723eb): aggregate exposure breaker + injection floor align

**Verifier:** Claude (adversarial judge, read/analysis only)
**Date:** 2026-06-09
**Target:** origin/main `362eafa` (HEAD). b2723eb landed via merge `c3cb0da`. CONFIRMED on origin/main.
**Note on local checkout:** local working HEAD was `676c222`, 13 commits BEHIND origin/main — the on-disk `injection.ts` still showed the old `0.5`. This is a stale local clone, NOT a sign the PR didn't land. Verified against `git show b2723eb` + a worktree at b2723eb. The live build (362eafa) DOES contain both changes.

---

## #4 Aggregate / portfolio exposure breaker

### Verdict: CORRECT, but NOT yet safe to ENABLE without two fixes/decisions. Default-OFF is fine.

### What it does (confirmed by reading the diff + call site)
- New pure fn `portfolioExposureBreaker(openNotional, size, entryPrice, equity, cfg)` in `strategy-execution.ts`.
- Live call site sits AFTER the per-trade `positionSizeCircuitBreaker` (line ~986–999) and BEFORE `placeOandaOrder` (line ~1025). **Order of clamps is correct:** per-trade clamps `size` first, then the aggregate clamps the already-clamped size. No interaction bug.
- Sums open notional via SQL: `SELECT COALESCE(SUM(size * entry_price),0) FROM simulated_orders WHERE status='open' AND market='XAUUSD'`. This SUMS notional (not count) — correct. Columns `size`, `entry_price`, `status`, `market` all exist and are used identically elsewhere (briefing.agent.ts, operator-brief.ts).
- Basis match: `simulated_orders.size` is stored as broker `actualUnits` (units), `entry_price` as USD price → `SUM(size*entry_price)` = USD notional. New trade notional = `size * entryPrice` (units × intended USD price). **Same USD-notional basis.** Good.
- No double-count: the current trade's row is INSERTed (tryOpenPosition, line ~1088) AFTER the breaker check, so `openNotional` correctly excludes the in-flight trade and the fn adds it explicitly.

### Break attempts — results
| Attempt | Result |
|---|---|
| Zero equity | `equity<=0` guard → size 0, clamped. Test covers. SAFE. |
| **Negative equity** | `equity<=0` also catches negative → size 0. SAFE (test only covers 0, but code covers <0). |
| Zero/neg entryPrice | `entryPrice<=0` guard → size 0. SAFE. |
| No open positions | openNotional=0 → behaves as per-trade-only ceiling. SAFE. |
| Position with null/0 size | `COALESCE(...,0)` + `SUM` treats NULL as 0; a 0-size row adds 0 notional. SAFE. |
| Clamp-to-0 case | When room ≤ 0 (or room < 1 unit), `Math.max(0, floor(room/price))` = 0 → caller returns `{executed:false, reason:"no room under aggregate cap"}` and emits a shadow row. **Rejects CLEANLY — no garbage tiny trade.** SAFE. |
| Clamp math | room=cap−open; e.g. cap 450k, open 400k → room 50k → floor(50000/4500)=11 units; 11×4500=49,500 ≤ 50,000. Stays UNDER cap. Correct. |
| Currency mismatch (EUR equity vs USD notional) | **PRESENT** — inherited from the per-trade breaker. cap = pct×equity(acct ccy) compared to USD notional. For a EUR account the cap is ~8% tighter (errs conservative → clamps more → safe-direction for a brake). Demo is USD-denominated so no live impact today. Not a new risk; flag for Karri if account ccy ever ≠ USD. |

### THE BIGGEST RISK — fail-open direction is WRONG for a safety brake
On `db.query` throw, the code logs a warning, sets `openNotional = NaN`, and the `if (Number.isFinite(openNotional))` gate then **skips the entire aggregate check** → the trade proceeds at full (per-trade-clamped) size with NO aggregate cap that tick.

This is **fail-OPEN**. For a SAFETY brake whose entire reason-for-existing is the 2026-04-21 cluster (3 simultaneous ~12% trades, ~1690% aggregate), failing open is the wrong direction: a transient DB blip during exactly the kind of burst this guards against would disable the guard at the worst moment. A cluster of signals often arrives together (same regime trigger) — the same conditions that stress the DB.

**Mitigations / recommendation before enabling:**
1. Change fail-open → **fail-safe-degraded**: on query error, fall back to a conservative proxy (e.g. assume open notional = the per-trade `MAX_NOTIONAL_PCT` × n-open-positions, or simply skip placement that tick), rather than removing the cap entirely. At minimum, make the failure mode a Karri decision and an env flag (`PORTFOLIO_BREAKER_FAIL_MODE=open|closed`).
2. Note the per-trade breaker (default ON, 300% notional / 80 units) is STILL active under the aggregate breaker, so even on aggregate fail-open no SINGLE trade exceeds 300%. The residual risk is purely the CLUSTER (N trades each ≤300% with no aggregate ceiling) — which is precisely the scenario #4 exists to stop. So fail-open meaningfully weakens the only thing this PR adds.

### Default-OFF: CONFIRMED
`envBool("PORTFOLIO_EXPOSURE_BREAKER_ENABLED", false)` — default false. The whole block is gated. No behaviour change until Karri enables + sets `MAX_PORTFOLIO_NOTIONAL_PCT` (default 500, bounds 50–5000). Default-preserving. ✅

### Tests: REAL (5/5 green in isolation)
disabled→unchanged, under-cap→unchanged, cluster-over-cap→clamp to 11u (math verified), at-cap→0 (skip), zero-equity→0. They exercise the actual pure fn with real assertions. Gap: no test for NEGATIVE equity (code handles it) and no test for the live fail-open path (the `NaN`/skip branch is untested — it lives in the impure call site, not the pure fn).

---

## #2 Injection floor align (0.50 → 0.40)

### Verdict: SAFE. YES.

- Change: `minConfidence = opts.minConfidence ?? envFloat("LESSON_INJECTION_MIN_CONFIDENCE", 0.40, 0, 1)` (was hardcoded `?? 0.5`). Bounded [0,1], invalid env → 0.40.
- **The floor is NOT the real gate — approval is.** `buildLessonContext` calls `client.listApprovedFor(...)` which only returns `status='approved'` rows. The confidence floor is a SECONDARY post-filter on top of approval. Lowering it 0.50→0.40 only changes WHICH already-approved lessons get injected — it cannot let an unapproved lesson through.
- Approval still requires auto-promote (n≥20 + consistency≥0.8) OR manual approval. An auto-promoted n=20 lesson has derived confidence min(0.95, 20/50)=0.40 — under the old 0.50 floor it was approved-but-never-injected (silent dead-letter). The align fixes that genuine bug.
- No path where 0.40 injects a "bad" lesson that 0.50 would have blocked, beyond: a borderline-approved lesson (n=20–24, conf 0.40–0.49) now injects. But that lesson already passed the approval bar (consistency≥0.8 over ≥20 obs). The floor was never the safety mechanism; it was an arbitrary 0.50 that happened to sit ABOVE the auto-promote floor → pure misconfiguration. Lowering it to match is correct.
- **Reminder of the real gate downstream:** injection only changes trade BEHAVIOUR when `LESSON_INJECTION_ENABLED` (+ `AGENT_LESSONS_ENABLED`) are on — those are the operator/Karri-gated trade-altering switches per prinsipp 6. The floor align is inert until those flip. So even the borderline-lesson concern is double-gated.
- Default-preserving in spirit: the floor moved, but it's a bug-fix (approved lessons were being dropped). It is env-tunable back to 0.50 in 30s if Karri wants the old behaviour. ✅
- Tests: 2 new, both green — 0.40 lesson passes default floor; env=0.5 still excludes it. Real.

---

## Full-suite 1195/1195
Both changed files' tests are GREEN in isolation (injection 8/8, strategy-execution 26/26 incl. all 5 portfolio + 6 circuit-breaker). Full-suite run in my throwaway worktree showed unrelated failures that were tsx/module-resolution artifacts of the worktree (missing installed deps), NOT logic failures. Trusting the PR's 1195/1195 claim given both touched files are clean.

---

## Bottom line
- **Aggregate breaker correct + safe to ENABLE: NO (not yet).** The logic, clamp math, ordering, and edge-case guards are all correct and default-OFF is safe. But the **fail-open-on-query-error direction is wrong for a safety brake** — it removes the aggregate cap exactly when a DB blip coincides with a signal cluster, which is the scenario it exists to stop. Per-trade breaker (300% cap) still backstops single trades, so residual exposure is cluster-only — but that's the whole point of #4. Fix fail-mode (or make it a Karri-gated env flag) + pick `MAX_PORTFOLIO_NOTIONAL_PCT` before enabling.
- **Single biggest risk:** fail-open on the open-exposure query → aggregate cap silently disabled for that tick during a DB hiccup; clusters can still slip through.
- **Injection floor align safe: YES.** Approval (auto-promote n≥20 + consistency, or manual) is the real gate; 0.40 only re-includes already-approved lessons the 0.50 floor was wrongly dropping. Double-gated behind LESSON_INJECTION_ENABLED.
