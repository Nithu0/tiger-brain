# Audit — foundation_gate_tier3.md distilled

**Date**: 2026-05-13
**Task**: Round-3 distillation, slot L (foundation-gate + TIER 3)
**Output**: `~/Obsidian/Brain/_library/trading/concepts/foundation_gate_tier3.md`
**Word count**: ~560 (target 400–600)

## Sources read
- `docs/ops/new-strategy-gate.md` — 5-rule gate + green/red response templates
- `docs/ops/archive/tier3-deploy-26april.md` — TIER 3 origin (26.4 deploy report, 4 strategies parallel)
- `docs/ref/firm-modules.md` — 16-module map confirmed; `foundation-gate.ts` + `strategy-execution.ts` + `strategy-blade.ts` cited as code anchors
- `ai-assistent/CLAUDE.md` — operator-prinsipper section (6 binding rules, current numbering)

## Coverage check
- [x] Foundation gate: all 5 rules with green/red criteria
- [x] Why foundation gate exists (early-perfection phase, not stacking complexity)
- [x] What's NOT gated (bug-fix, observability, disable)
- [x] TIER 3: 4 strategies (ORB, scalp-overlap, session-breakout, vol-expansion)
- [x] TIER 3 architecture: own swim-lane per strategy, `strategy-execution.ts` routing, `strategy-blade.ts` shared gates
- [x] `ORB_ONLY_MODE=true` semantic clarification (bypass Prism+Blade, NOT "only ORB")
- [x] Operator-prinsipper 1–6 distilled to 5 (no auto-disable, data never stops, foundation-first, OK kjør gate, selvfiks long-term)
- [x] Claude-implications: gate-check first, REPORT not auto-disable, proposal-flow for tuning, exposure-cap owns cross-strategy correlation

## Frontmatter applied
- `relevance_to_nexus: 5`, `claude_priority: P0`, `status: distilled` — matches the operator-binding nature of these rules

## Notes
- Norwegian terms preserved where they carry semantic weight (KRITISK, Midlertidige unntak, RØD template, "OK kjør", Selvfiks)
- Did NOT inline SQL or env-var lists — those belong in source docs, library doc is concept-level
- Operator-prinsipp numbering: source has 6 in CLAUDE.md; the gate-doc itself references principle 5 ("OK kjør") and 6 (autotune). Distilled to 5 logical bindings (combined "data never stops" with cleanup-rule for clarity).
