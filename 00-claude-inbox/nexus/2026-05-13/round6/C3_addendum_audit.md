# C3 Addendum Audit — Cross-Strategy Direction-Flip Scope-Down

**Date**: 2026-05-13 PM
**Action**: Appended round-5 empirical findings to `docs/strategy/proposals/2026-05-13_cross_strategy_direction_flip.md` and flipped status `proposed` → `needs-scope-down — see addendum`.
**Source**: `~/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/round5/c3_evidence_quantified.md`.

## What changed in the proposal

1. **Header status** updated from `proposed` to `needs-scope-down — see addendum`. This is intentionally not a downgrade to `rejected` — the empirical evidence supports a narrower, targeted gate, just not the blanket version originally drafted.
2. **New section "Round 5 addendum (2026-05-13 PM)"** appended just before the Decision footer. Contains:
   - 5-row X-window table (15/30/60/90/120 min) showing 4 of 5 windows are net-profitable for flip-pairs in aggregate (i.e. blanket gate would lose money).
   - Killer caveat: at X=60 (only net-negative window, -$290 combined), the loss is concentrated in scalp-overlap ↔ vol-expansion (9 flips, -$2,536). Other 60-min flips were profitable.
   - Recommended pivot to TARGETED pair-specific gate (scalp-overlap ↔ vol-expansion only, X=60).
   - Open question for Karri on whether the bad pair is structural or noise (n=9 is small, 95% CI almost certainly overlaps zero).
   - Pointer to source forensics file.

## Why this matters

The original proposal's evidence section leaned on the 11.5 cluster (-$1,585 from one flip-pair) as motivation. Round-5 expanded to all 60 days of simulated_orders and found that single anecdote was unrepresentative: across the broader population, cross-strategy flips are usually fine. Shipping a blanket gate would have killed +$3,255 of winning flip-pairs at X=60 just to avoid -$4,374 of losing ones — a 25% wins-killed ratio is fragile, and at X=90/120 the trade-off inverts entirely (gate becomes net-negative).

The targeted pivot preserves Karri's structural intuition (scalp-overlap mean-reversion thesis is genuinely opposite to vol-expansion breakout thesis in the same regime) while limiting the gate's blast radius to one demonstrably problematic pair.

## Not done

- Did not git commit (per instruction).
- Did not send to Karri via Discord webhook — operator-decide whether to push the updated proposal to Karri now or wait for round-6 synthesis.
- Did not update `phase-status.md` or any other ops file. Proposal is the canonical record.

## Files touched

- `/home/nithu/code/ai-assistent/docs/strategy/proposals/2026-05-13_cross_strategy_direction_flip.md` (status + addendum section)
- `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/round6/C3_addendum_audit.md` (this file)
