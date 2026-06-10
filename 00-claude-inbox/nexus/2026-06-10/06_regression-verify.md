# Nexus regression-verify — main since 2026-06-08

Date: 2026-06-10
Scope: READ/ANALYSIS ONLY. Verify nothing regressed + money-near changes safe in current live state.
origin/main HEAD: `f4bfadf` (Merge PR #92). Live = f4bfadf per prompt — matches.

## TL;DR

- **Tests green: YES** — worker 1196/1196, api 43/43 (clean detached worktree off `origin/main`, fresh installs).
- **Aggregate exposure breaker still default-OFF: YES** — `PORTFOLIO_EXPOSURE_BREAKER_ENABLED` default `false`, intact. Per-trade breaker default-ON, intact.
- **Money-near surprises in recent commits: YES, two** — both authored by Karri, but neither was in the brief:
  1. Learning-pipeline confidence formula rewrite (derive-lessons + auto-promote min-obs 20→8) — makes lessons actually injectable. Trade-altering only if `LESSON_INJECTION_ENABLED`=true (still its own gate).
  2. **GATE-AFTER-FILL RECOVERY** — new *always-on* (ungated) behavior that writes a managed position row when OANDA already filled but the local gate rejected. Reconciliation/anti-orphan, not a new entry path — but landed in #91 with no separate proposal doc.

## 1. What landed since 06-08 (origin/main)

Newest first (4fe89f2 stability fix was the 06-08 baseline):

| SHA | Author | Money-near? | Summary |
|---|---|---|---|
| f4bfadf | Nithu0 | — | Merge #92 |
| 63d5e8a | karri | **YES** | #92 narrow `RISK_LEVEL_HARD_GATE` block set [elevated,high,extreme]→[high,extreme]; env-tunable `RISK_LEVEL_BLOCK_LIST` |
| bc433d7 | Nithu0 | — | Merge #91 |
| b0cbee8 | karri | **YES** | #91 dispatch-2 follow-ups: fail-conservative breaker + learning-unblock + ORB_ONLY safeguard + **gate-after-fill recovery** |
| 4352104 | Nithu0 | no | Merge #89 — 24/7 watch scaffolding (inert) |
| 6773862 | Nithu0 | no | Merge #90 — build fix (pretest builds @ai-agent/shared) |
| 4c1cdbb | Nithu0 | no | pretest builds shared so clean-checkout tests pass |
| d44d3d6 | Nithu0 | no | headless 24/7 watch scaffolding (inert) |
| 362eafa | Nithu0 | — | Merge #87 |
| 6d8813b | karri | **YES** | #87 decouple runCalibration from ORB_ONLY_MODE |
| c3cb0da | Nithu0 | — | Merge #86 |
| b2723eb | karri | **YES** | #86 aggregate exposure breaker (#4) + injection floor 0.50→0.40 (#2) |
| f3068ac / f7b4460 / 9138c24 / 7b92a82 | Nithu0 | no | docs only (Karri dispatches, feature-flag docs, lesson-promo proposal) |

All code-bearing money-near commits are **Karri-authored** (`karri <nithu_00@hotmail.com>`) — consistent with the strategy/risk-reviewer lane. No unrecognized third-party author. The "ADX flag flip" in the brief is **not a code commit on main** — it's a Railway env action (`INDICATOR_OANDA_FALLBACK_ENABLED`) + an in-flight worktree branch `fix/adx-fallback-land` (not yet merged).

## 2. Aggregate breaker (#86/#4) — default-OFF confirmed

`apps/worker/src/firm/strategy-execution.ts`:
- L1040: `if (envBool("PORTFOLIO_EXPOSURE_BREAKER_ENABLED", false))` — **default false**. Not enabled in code.
- `MAX_PORTFOLIO_NOTIONAL_PCT` default 500 (bounds 50..5000) — value still TBD by Karri per comment.
- The fail-OPEN flaw flagged earlier was **FIXED in #91** (b0cbee8): on open-exposure query error the breaker now **fails CONSERVATIVE** (BLOCKS the trade) instead of skipping the cap. So even if operator flips it on, an exposure-query error no longer silently passes the cluster case. Safe.
- `portfolioExposureBreaker()` body intact: fail-safe to size 0 on bad equity/price; clamps to room under cap.

Per-trade breaker:
- L1022: `positionSizeCircuitBreaker(... enabled: envBool("POSITION_SIZE_CIRCUIT_BREAKER_ENABLED", true) ...)` — **default ON**, intact. Function body unchanged (maxUnits ∧ maxNotionalPct, fail-safe 0 on bad equity).

## 3. Injection floor (0.40) + calibration decouple (#87) — intact

`apps/worker/src/firm/agent-lessons/injection.ts` L61: floor = `envFloat("LESSON_INJECTION_MIN_CONFIDENCE", 0.40, 0, 1)`. Aligned with auto-promote so an approved lesson (n≥20 → conf 0.40) is no longer approved-but-never-injected. Behaviour as expected. **Note:** injection itself still gated by `LESSON_INJECTION_ENABLED` (separate flag) — floor change alone does NOT inject anything.

#87 calibration decouple (`orchestrator.ts`): `runCalibration` no longer gated on `!orbOnlyMode` — runs every 20 cycles; engine-weight calibration self-gates on fresh `engine_scores`. No-op on current prod (ORB_ONLY false). #91 added a loud startup WARN if `ORB_ONLY_MODE=true` + `CALIBRATION_MODE=SAFE_AUTO_APPLY` (engine-weight starvation can't die silently). Mode still RECOMMEND_ONLY default; SAFE_AUTO_APPLY still Karri-gated. Intact.

## 4. Test suites (clean checkout)

Detached worktree at `origin/main` (f4bfadf), fresh `npm install` at root + apps/worker + apps/api:
- **Worker: 1196 / 1196 pass, 0 fail** (~56s). Matches Karri's claimed 1196 in #92.
- **API: 43 / 43 pass, 0 fail** (~2.7s).
- Note: firehose `.mjs` script tests run on CI (Linux) only — not spawned in this run (consistent with #91 note). Worker/api suites cover the changed `.ts` paths (new-gates, injection, strategy-execution).

No failures.

## 5. New money-near env flags from parallel work

All understood, all documented in commit messages/code comments (but NOT added to `.env.example` — minor doc gap):

| Flag | Default | Money-near | Status |
|---|---|---|---|
| `PORTFOLIO_EXPOSURE_BREAKER_ENABLED` | false | yes | OFF, fail-conservative on error. Don't enable until Karri sets `MAX_PORTFOLIO_NOTIONAL_PCT`. |
| `MAX_PORTFOLIO_NOTIONAL_PCT` | 500 | yes | value TBD by Karri |
| `LESSON_INJECTION_MIN_CONFIDENCE` | 0.40 | yes (only if injection enabled) | aligned w/ auto-promote |
| `RISK_LEVEL_BLOCK_LIST` | high,extreme | yes | narrowed default; CSV to re-widen |
| `LESSON_AUTO_PROMOTE_MIN_OBSERVATIONS` | 8 (was 20) | yes (learning) | lowered; consistency≥0.8 stays the real gate |

## Flags for operator / Karri

1. **GATE-AFTER-FILL RECOVERY (#91, always-on, ungated)** — `strategy-execution.ts` L1287. When `placeOandaOrder` filled but `tryOpenPosition` returned null (risk/loss/sizing gate, NOT the cap which is backstopped to 99), it now INSERTs a managed `simulated_orders` row (`execution_source='firm_strategy_gate_recovered'`) so position-management adopts it instead of oanda-sync importing an unmanaged orphan that round-trips winners to SL. Rationale is sound (it was described as the dominant MR loss mode) and it does NOT create entries that wouldn't otherwise hit the broker — but it's a new ungated money-near write path that landed without a standalone proposal doc. Worth an explicit operator/Karri ack.

2. **Learning confidence rewrite (#91)** — derive-lessons confidence changed from `min(0.95, n/50)` (pure volume, structurally muted at ~2 trades/day) to `max(wr,1-wr)*min(1,n/8)` (signal strength), + auto-promote min-obs 20→8. This is the switch that finally lets lessons clear the floor and become injectable. Per operator principle 6, lesson-injection-into-prompts is a trade-altering switch that gates via Karri — Karri authored this, so within lane, but confirm `LESSON_INJECTION_ENABLED` state on prod before assuming it's live.

3. `.env.example` was not updated for the 5 new flags above — non-blocking doc gap.
