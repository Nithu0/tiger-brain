---
date: 2026-05-13
agent: claude-round3-C1
task: write proposal for null-direction-block-eligible
---

# C1 — Proposal audit

## Output

- **Proposal path:** `/home/nithu/code/ai-assistent/docs/strategy/proposals/2026-05-13_null_direction_block_eligible.md`
- **Word count:** ~1180 words
- **Reviewer:** Karri
- **Status:** proposed
- **Builds on:** `2026-05-11_regime_direction_gate.md` (Karri pending)

## The 3 options' essence

**Option A — Hard block.** When `regime=TRENDING` and `regimeDirection=null`, gate hard-rejects mean-reversion signals (`xau-scalp-overlap`, `xau-volatility-expansion`). Breakout strategies unaffected. Cleanest semantics, but blocks 97.7% of TRENDING-cycle mean-rev signals until classifier null-rate drops. Risk: nukes legitimate counter-trend wins if classifier stays null-dominant.

**Option B — Cheap M15 fallback.** Upstream fix: when H4 returns null, fall back to sign of M15 EMA20-EMA50 slope already on blackboard. Closes coverage gap without extra API calls. Risk: M15-slope is noisier than H4 — needs threshold (~$1.50 min slope) to avoid chop-flips during pullbacks. Doesn't change gate logic; shifts fix into classifier.

**Option C — Soft reject + size-degrade.** Don't block on null — shrink size ×0.5 and emit `would_reject` row. Lowest blast-radius if classifier is later trustworthy on nulls (e.g. `null_flat` = real chop). Ships less protection: 11.5 cluster would still fire all 9 trades at half size (~$945 loss vs $1893).

## Sequencing recommendation embedded in proposal

A2 instrumentation (round 3, observability-only, no proposal needed) → 7d data on null-reason histogram → Karri picks A/B/C based on which reason dominates. Activating `REGIME_DIRECTION_GATE_ENABLED=true` *before* null-policy is decided = gate stays silently dormant.

## Rollback design

Named flag `REGIME_DIRECTION_NULL_BLOCK_MODE=off|soft|hard` (default `off`). Option B orthogonal as `REGIME_DIRECTION_M15_FALLBACK_ENABLED`. Combinable for belt+braces.

## My bias (Karri can override)

**B+A composite.** Fix the data-availability hole first (B), then block residual nulls in TRENDING (A). C alone is too passive given 11.5 evidence.
