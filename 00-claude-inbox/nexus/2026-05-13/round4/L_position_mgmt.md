# Audit — position-management concept distillation (round 4 / L)

**Date:** 2026-05-13
**Task:** Write `~/Obsidian/Brain/_library/trading/concepts/position_management.md` (400-600 words)
**Output:** `/home/nithu/Obsidian/Brain/_library/trading/concepts/position_management.md` — 597 words body (excl. frontmatter)

## Sources read

- `apps/worker/src/firm/position-management/manager.ts` — orchestration, OANDA-first atomic wiring, `POSITION_MANAGEMENT_ENABLED` gate, shadow mode
- `apps/worker/src/firm/position-management/lifecycle.ts` — pure decision engine: BE → partials → trailing → stale → degradation
- `apps/worker/src/firm/position-management/rules.ts` — tunables, let-run strategies, regime-aware stale config, calibration overlay
- `docs/ref/position-metadata.md` — runtime metadata columns + Fase 4 regime-aware stale
- `docs/strategy/proposals/2026-05-12_vol_exp_break_even_on_1r.md` — Karri's pending BE-at-1R for vol-exp
- `docs/strategy/proposals/2026-05-13_session_breakout_sl_method.md` — A3 `atr_at_entry` observability fix dependency
- `docs/strategy/proposals/2026-05-12_vol_exp_no_chase_filter.md` — context
- `docs/strategy/proposals/2026-05-12_vol_exp_session_sl_widening.md` — context

## Coverage check vs requirements

| Required topic | Covered? | Section |
|---|---|---|
| Open trade → BE → trailing/partial → stale-exit | yes | "What it does" |
| Break-even rule (per-strategy + Karri's +1R proposal pending) | yes | "Break-even rule" |
| Regime-aware stale-exit | yes | "Regime-aware stale-exit" |
| Trade metadata columns + A3 session-breakout link | yes | "Trade metadata stamped at entry" |
| R-multiple tracking (MFE/MAE/R persisted, postmortem classifier) | yes | "R-multiple tracking" |
| Foundation-gate dependency (POSITION_MANAGEMENT_ENABLED + 3-trade verification) | yes | "Foundation-gate dependency" |
| Anti-patterns (DB-side closes, manual SL/TP edits) | yes | "Anti-patterns" |
| Cross-references (Van Tharp, Connors, Crabel) | yes | "Cross-references" |

## Frontmatter

Exact spec used (status: distilled, claude_priority: P0, relevance_to_nexus: 5).

## Notes

- Verified `originalRiskPoints` frozen-at-entry behaviour from `riskPoints()` in lifecycle.ts:47 — included as anti-pattern because operator's audit history has prior bugs there.
- OANDA-first atomic wiring noted because it's load-bearing for "DB never claims a change that didn't land" — operator-priority correctness invariant.
- Let-run strategies (vol-exp) noted as the reason BE is currently the *only* protection for that strategy class — connects directly to Karri's pending proposal.
- Cross-references kept to the three named in the brief (Tharp / Connors / Crabel) — did not pad with extras.

## Status

distilled. No follow-up required. Doc lands in library; concept-graph references position-management metadata under "Lifecycle" cluster.
