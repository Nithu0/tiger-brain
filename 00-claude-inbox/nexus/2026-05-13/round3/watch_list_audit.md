# watch_list_audit — round 3

**Output:** `/home/nithu/code/ai-assistent/docs/ops/2026-05-13_watch-list_7d.md`
**Word count:** ~1450 (over 1000 target — operator may trim once Karri responds and Day 5–7 shape becomes deterministic).
**Status:** written locally, NOT committed.

## Structure

- Top: 6-point kill-switch criteria + 30s rollback command. Memorise-first principle.
- Day 1 (14.5) — first-24h post-B1 sanity: hard-reject ≥2, A1 wire-up writes, A2 reason histogram non-empty, health green.
- Day 2 (15.5) — first aggregation window: per-gate distribution, per-strategy PnL vs 14d baseline, counter-factual list of blocked trades.
- Day 3 (16.5, weekend) — A5 backfill verification + per-regime PnL view (the Karri-requested cut).
- Day 4 (17.5) — Karri response checkpoint; draft response if feedback received.
- Day 5 (18.5) — first implementation Monday if Karri approved anything; foundation-gate must stay green.
- Day 6 (19.5) — push window; new-gate smoke tests.
- Day 7 (20.5) — round-4 sweep prompt embedded as copy-paste; 7d B1 verdict.

## Sources used

- `B1_entry_stack_cooldown_flip.md` (verification SQL pattern + rollback command + expected impact 2–4 blocks/day)
- `A1_persist_regime_direction.md` (gate_decisions persist verification query)
- `A2_null_reason_tagging.md` (regimeDirectionReason blackboard query)
- `A4_daily_trade_cap_filter.md` (allow-list rationale, dormant note)
- `A5_backfill_portfolio_regime.md` (137 NULL → 96 after backfill, per-regime distribution)
- `00_ROUND2_SYNTHESIS.md` (kill-switch criteria grounded in 11.5 cluster + Karri's principles)

## Cross-reference notes

- `verification_playbook.md` (sibling round-3 agent) referenced as authoritative for SQL — my queries should be a strict subset of theirs. If they drift, playbook wins. Did NOT have access to that file while writing (parallel agent), so my queries are derived from B1/A1/A2/A5 first-principles.
- Kill-switch criterion #5 ("same-direction PnL collapse") is my proposed framing; operator may want to tighten the 2σ threshold once Karri weighs in.

## Bias I avoided

- Did NOT propose any new gate flips or behaviour changes — watch-list is observe-only per operator-prinsipp 1.
- Did NOT pre-decide Karri's C1 outcome — Day 4 prompt is neutral.
- Did NOT recommend B2 (RISK_LEVEL_HARD_GATE_ENABLED) flip; surfaced as round-4 question only.

## Open items

- Operator should commit + push the watch-list once "OK kjør" given.
- Worth duplicating Day-1 + Day-7 sections into `docs/ops/phase-status.md` as the active observation window once B1 is committed?
- Round-4 dispatch prompt (Day 7) is template-shaped; operator can refine before triggering.

---

*Generated 2026-05-13 by round-3 watch-list agent. No git changes made.*
