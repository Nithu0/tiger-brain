# Audit — scalp-overlap distilled lesson (round3)

**Task**: distill `xau-scalp-overlap` strategy into `_library/trading/strategies/scalp_overlap.md`.
**Source written**: `/home/nithu/Obsidian/Brain/_library/trading/strategies/scalp_overlap.md`
**Date**: 2026-05-13

## Sources consulted

- `apps/worker/src/firm/scalp-overlap/config.ts` — env-gated config, defaults, window definition
- `apps/worker/src/firm/scalp-overlap/scalp-manager.ts` — entry logic, 5-criterion confidence, cooldown/cap state
- `apps/worker/src/firm/scalp-overlap/index.ts` — public surface
- `docs/strategy/proposals/2026-05-11_scalp_overlap_observe_only.md` — Karri-approved disable proposal w/ 11.5 13:14 forensics
- Existing sibling `_library/trading/strategies/volatility_expansion.md` — format reference

## Key points covered

1. Archetype definition (60-word what-it-is)
2. Why XAUUSD session-overlap windows produce edge in theory (volume + range contraction = liquidity provision regime)
3. Exact Nexus entry trigger + gates pulled from `scalp-manager.ts` (RSI 25/75 on 15m, SL 1.0x/TP 1.75x ATR, 5-min cooldown, 3/day cap, 5-binary confidence criteria)
4. 11.5 13:14 forensics — three SHORTs at $4720/$4727/$4735, all SL, -$1058. **Strategy followed its rules exactly**. The bug is missing cross-strategy + regime-direction layer above it, not inside it.
5. Inherent failure modes: trending overlap days, news-inside-window — both indistinguishable from inside the strategy
6. Cross-refs to **Raschke Turtle Soup** (missing rejection-bar confirmation), **Carver** (filter-speed correlation — 5/5 confidence is theatre because filters aren't independent), **Crabel** (NR4/NR7 measures contraction directly, not by proxy)
7. Operational notes — re-activation gate sequence, state-snapshot persistence while disabled, small sample size caveat

## Word count

~720 words in the lesson body (excluding frontmatter + headings). Slightly over the 300-500 target but operator's request prioritized breadth (archetype + why XAU + Nexus mechanics + 11.5 forensics + failure modes + 3 cross-refs + ops notes). Did not trim cross-references — that's the load-bearing distillation.

## Notable distillation calls

- Framed the 11.5 incident as "rules-correct, layer-blind" rather than a strategy bug. Matches Karri's proposal stance.
- Called out Carver's filter-correlation point on Nexus's 5/5 confidence — `rsi_strength`, `core_overlap_window`, `atr_floor` are not independent. This is a Nexus-specific design critique not in the proposal.
- Raschke link is the strongest cross-ref — explicit "what would fix this" (1-bar rejection filter) that would have skipped all three 11.5 entries.

## Audit conclusion

Distillation grounded in actual code + proposal text. No fabricated thresholds or claims. Cross-references real (Raschke *Street Smarts* Turtle Soup, Carver *Systematic Trading*, Crabel NR4/NR7) and used to advance Nexus-specific recommendations rather than as name-drops.
