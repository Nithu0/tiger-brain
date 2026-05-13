# Audit drop — conviction_score concept doc

**When:** 2026-05-13
**Task:** Round 4 / Karri open Q#2 — distill conviction-score concept doc into `_library/trading/concepts/conviction_score.md`.

## What landed

`~/Obsidian/Brain/_library/trading/concepts/conviction_score.md` (~530 words). Frontmatter per spec (relevance 4, P1, tags include `karri-owned`, status `distilled`).

## Sources I read

- `apps/worker/src/firm/conviction/index.ts` — public surface
- `apps/worker/src/firm/conviction/scoring.ts` — `computeTieredConviction()` pure function, three-tier composition, gate logic
- `apps/worker/src/firm/conviction/adapters.ts` — `buildStandardEngineSet()` from blackboard, regime-fit heuristics, confidence normalization (legacy vs cold_start modes)
- `apps/worker/src/firm/conviction/config.ts` — `BASE_WEIGHTS`, `REGIME_WEIGHTS` (BASE/TRENDING/RANGING/HIGH_VOLATILITY), `TIER_WEIGHTS` (0.45/0.35/0.20), `CONVICTION_GATES` (env-overridable 0.18/0.12/0.20), `PERF_MULT_BOUNDS`
- `apps/worker/src/firm/strategy-execution.ts:568-791` — where `entry_conviction_score` + `conviction_total` get stamped on trades INSERT
- `apps/worker/src/firm/postmortem.ts:250` — read-back path for closed-trade analytics
- `apps/dashboard/src/app/analytics/conviction/page.tsx` — Phase 1 dashboard (Q1-Q4 buckets, per-strategy breakdown, 7/30/90/365d windows)
- `apps/api/src/routes/analytics.ts:299-410` — `/analytics/conviction-quartiles` endpoint (the buckets + unscored count)
- `docs/strategy/proposals/2026-05-11_conviction_quartile_position_sizing.md` — the open proposal (status: pending, Karri review)
- `docs/ops/phase-status.md` — confirms metadata-strip fix `0ad348f` (2026-05-11) restored stamping; 138 historic rows need backfill; conviction-as-hard-control gated on ≥100 logged trades

## Key findings worth surfacing

1. **Two distinct scores both persisted.** `entry_conviction_score` (Blade's 0..1 from `proposal.confidence`) and `conviction_total` (tiered output, -1..+1). Easy to confuse. The dashboard buckets the former.
2. **Score is currently a passenger.** Sizing is conviction-blind. The whole infrastructure exists to answer Karri's Q#2; no behaviour change has happened yet.
3. **Calibration window is wide-open.** Only 2 days of clean post-fix data (since 2026-05-11). 30-day target = mid-June at earliest. Karri's bar likely pushes that to 60+ days.
4. **Anti-pattern risk is real:** the soft conviction gates (`CONVICTION_MIN_DIRECTION` etc.) use the same blackboard messages as existing entry gates. Double-counting risk if anyone proposes "add conviction gate" without auditing the dependency graph. Flagged in the concept doc.
5. **No cross-reference to Carver existed in the codebase** — added in the concept doc because the forecast-combination framing is the closest external analogue and gives Claude a reading anchor.

## Status

Concept doc landed. No code change. No proposal filed (this was a documentation task).
