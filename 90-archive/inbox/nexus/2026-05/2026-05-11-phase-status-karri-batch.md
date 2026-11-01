---
type: claude-inbox
date: 2026-05-11
topic: phase-status refresh + Karri TIER 1 batch
status: filed
---

# 2026-05-11 — Phase-status refresh + Karri TIER 1 batch

End-of-day pointer for next session.

## What landed today (round 14 close)

**Karri ferdig review-runde (kveld 11.5).** 5 nye TIER 1 proposals merged via PR #1 (`b22cb8d`), branch `proposals/2026-05-11-tap-analysis`, base commit `02e8ac8`. Alle 5 default-OFF bak per-proposal env-flag.

| Proposal | Tier | Impact | Env-flag |
|---|---|---|---|
| `regime_direction_gate` | TIER 1 | +$2–3k/30d | `REGIME_DIRECTION_GATE_ENABLED` |
| `session_block_gate` | TIER 1 | **−$3683 / 19 trades — sterkest** | `SESSION_BLOCK_ENABLED` |
| `sl_cooldown` | TIER 1 | $1023 spart | `SL_COOLDOWN_ENABLED` |
| `scalp_overlap_observe_only` | TIER 1 emergency | Stopper $1058-bløding | `SCALP_OVERLAP_OBSERVE_ONLY` |
| `orb_observe_only` | TIER 1 emergency | Stopper ORB-bløding | `ORB_OBSERVE_ONLY` |

Kilde-doc: `docs/ops/strategy-analysis-day-2026-05-11.md` (995 linjer, full data + per-strategi tap-attribution).

## Files touched in this refresh

- `docs/ops/phase-status.md` — header timestamp, new "11.5 runde 9" subsection, Karri-kø-rad i åpne problemer
- `Brain/01-nexus/runtime-state/SNAPSHOT.md` — round-14 header, today's totals augmented with round-14 batch, Karri queue 5→10
- `Brain/01-nexus/runtime-state/foundation-gate-state.md` — timestamp + Karri-batch trajectory entry; gate still 5/5 🟢
- `Brain/01-nexus/strategies/karri-tier1-batch-2026-05-11.md` — **NEW** — canonical batch overview doc

## Foundation gate

**Still 5/5 🟢.** Karri proposals are strategy/risk-side endringer (env-flag gated, default OFF) — påvirker ikke foundation-gate-tilstand. New-strategy work can continue.

## Karri queue total (after this update)

**10 open proposals:**
- 5 new TIER 1 (this batch — awaiting OK kjør for env-flag flips)
- 4 actionable carry-over (conviction_quartile_position_sizing, funnel_drain, postmortem_size_down_feedback, vol_expansion_throttle_review)
- 1 architecture (processed_signals_persistence)

3 closed/revised earlier today (deprecate_strategy_id_desk, risk_pct_clamp, vol_expansion_throttle stale-data).

## Next-session pickup pointers

1. Implement 4 of the new TIER 1 in parallel (env-gated default-off commits) — see karri-tier1-batch-2026-05-11.md aktiverings-rekkefølge
2. Verify Discord audit-trail NULL-rate after 24h (still #1 watch-item from round-13)
3. Carry-over operator decisions: Retention FK 13,500-row handling, AGENT_BUS_ENABLED prod flip, 8 OANDA dupe rows SQL OK kjør, 138-row metadata backfill

## Commit reference

`docs/ops/phase-status.md` updates folded into commit **`a53598b`** (`feat(postmortem): Phase 1 streak-table for size-down feedback`) — a parallel agent's commit picked up the staged phase-status changes during a rebase/reset cycle, so the phase-status edits landed as part of that commit rather than a standalone ops-commit. Effect is identical: phase-status reflects Karri runde 9 + Karri-kø: 10. SNAPSHOT.md + foundation-gate-state.md + new batch-overview doc are in the Brain vault (separate git repo). No push per instruction.
