# Batch-2 strategy/risk gates — activation status (2026-06-07)

Read/verify only. Live commit `2b2d2cef` (API `api-production-b660`). Data pulled over 443 at 2026-06-07 ~12:33 UTC into `data/pull/`.

## Method / inference rule

The gate-persist helpers in `apps/worker/src/firm/strategy-blade.ts` + `gates/new-gates.ts` only **INSERT a `gate_decisions` row when the gate's env-flag is ON** (each `persistXDecision` call is wrapped in `if (isXEnabled())`; new-gates persist runs only inside the `STRATEGY_BLADE_NEW_GATES` block, which itself runs only when `STRATEGY_BLADE_ENABLED=true`). Therefore:

- **A gate_name producing rows in `/decision-funnel` = that gate's flag is ON in Railway** (high confidence).
- Absent gate_name = flag OFF (or gate never reached — but these gates run every eligible cycle, so absent ≈ off).
- Vol-exp internal filters (no_chase/confluence/mean-revert-block/BE) do NOT write to `gate_decisions`; they only fire when vol-exp emits a signal. Funnel is silent on them → those stay UNKNOWN without Railway env.

Live funnel gate_names (3d + 7d + 72h status-report all agree):
`session_block, entry_stack_cooldown, risk_level, sl_cooldown, regime_direction_gate, daily_trade_cap, mean_revert, scalp_overlap_asia, ranging_conviction`.

`mean_revert` evaluated 49 (7d) / 26 (3d) = every cycle (evaluated upstream in strategy-execution). The blade-gates show evaluated 21 (7d) / 7 (3d) = per proposal-bearing cycle.

---

## CONFIRMED ACTIVE (writing gate_decisions rows on live data)

| Item | Flag | Evidence |
|---|---|---|
| **STRATEGY_BLADE_NEW_GATES** + **STRATEGY_BLADE_ENABLED** | `STRATEGY_BLADE_ENABLED=true`, `STRATEGY_BLADE_NEW_GATES=true` | session_block / entry_stack_cooldown / risk_level / scalp_overlap_asia / ranging_conviction rows present. These only persist when master+new_gates ON. |
| **SL_COOLDOWN** | `SL_COOLDOWN_ENABLED=true` | `sl_cooldown` rows present; 7d had 1 hardReject `sl_cooldown_active`. Actively rejecting. |
| **regime_direction_gate** | `REGIME_DIRECTION_GATE_ENABLED=true` | `regime_direction_gate` rows present (7 in 3d, 23 eval 7d). 0 rejects so far (no counter-trend MR entries hit it). |
| **daily_trade_cap** | `DAILY_TRADE_CAP_ENABLED=true` | `daily_trade_cap` rows present. 0 rejects (volume below cap=6). |
| **mean_revert (VOL_EXP mean-revert *gate*, the cross-strategy one)** | `MEAN_REVERT_GATE_ENABLED=true` | `mean_revert` evaluated every cycle; 7d = 4 hardRejects `mean_revert_block`, 3d = 1. Actively rejecting — top reject reason in funnel. |
| **SESSION_BLOCK** | `SESSION_BLOCK_ENABLED=true` (sub-flag of new_gates) | `session_block` rows present. 0 reject this window (weekend handled upstream at strategy-eval, not at blade). |

Note on the new-gates sub-flags (risk_level / scalp_overlap_asia / ranging_conviction / entry_stack_cooldown / session_block): their ROWS prove `STRATEGY_BLADE_NEW_GATES` is on, but each row's `hard_rejected` also needs its own sub-flag (`RISK_LEVEL_HARD_GATE_ENABLED`, `SCALP_OVERLAP_ASIA_BLOCK`, `RANGING_CONVICTION_GATE_ENABLED`, `ENTRY_STACK_COOLDOWN_ENABLED`, `SESSION_BLOCK_ENABLED`). All show wouldReject=0/hardReject=0 this window, so I cannot prove from data alone whether each sub-flag is hard or soft-log. They are at minimum **soft-logging (active in observe mode)**; hard-enforce state per sub-flag = UNKNOWN (need Railway env). `session_block` is the one most likely hard-on given Karri's 11.5 tap-analyse priority.

---

## CONFIRMED / CLEARLY OFF (no rows, no live evidence)

| Item | Flag | Why off |
|---|---|---|
| **CROSS_STRATEGY_DIRECTION_FLIP** | `crossStrategyFlipMode` (off/shadow/hard) | No `cross_strategy_direction_flip_gate` rows in funnel. Mode=off. Proposal `2026-05-13_cross_strategy_direction_flip.md` Status: **needs-scope-down** (un-actioned). |
| **NULL_DIRECTION_BLOCK** | (eligible-block) | No related rows; proposal `2026-05-13_null_direction_block_eligible.md` Status: **needs-pivot** (never implemented as-spec). OFF. |

---

## FUNNEL_DRAIN_PROPOSALS — assessment: LIKELY STILL OFF

The ~29% proposal-drop fix. `FUNNEL_DRAIN_PROPOSALS=envBool(...,false)` in `strategy-execution.ts:147`. Proposal `2026-05-11_funnel_drain.md` Status: **proposed (implemented behind flag, OFF default)** — explicitly needs operator+Karri OK before flip (raises trade frequency).

Behavioural read: funnel shows `signalsProposed:3 (7d) / 1 (3d)` and `tradesOpened:18 (7d) / 5 (3d)`. Very low proposal volume (weekend + thin sessions), so the drain effect isn't observable either way right now. No positive evidence it's on. **Treat as OFF unless Railway env says otherwise (UNKNOWN-leaning-OFF).**

---

## Vol-exp filters (NO_CHASE / confluence / mean-revert-block / BE-1R) — UNKNOWN (need Railway env)

These were meant to stem vol-exp's −$4.1k / 26%WR cluster. All default OFF in `vol-expansion/config.ts`:
- `VOL_EXP_NO_CHASE_ENABLED` (default false)
- `VOL_EXP_MIN_PASSED_CRITERIA` (confluence, default 3)
- `VOL_EXP_MEAN_REVERT_BLOCK_ENABLED` (default false)
- BE-1R: **not a vol-exp flag** — general `BREAK_EVEN_RULES` (position-management/rules.ts, triggerRmult=1.0). Fires for all let-run strategies. Prior 12.5 analysis: vol-exp losers never reached +1R MFE, so BE had no trigger opportunity.
- Direction filter: `VOL_EXP_ALLOW_LONG` default FALSE, `VOL_EXP_ALLOW_SHORT` default TRUE (SHORT-only, data-driven 2026-05-29).

Why UNKNOWN: these filters write NO `gate_decisions` rows — they short-circuit vol-exp signal generation internally. The funnel can't see them. Vol-exp strategy IS evaluating live (`strategy_states.json`: VOL_EXPANSION rejecting on "ATR ratio 0.76 < 1.3"), so `VOL_EXPANSION_ENABLED` is **likely ON**, but the filter sub-flags require Railway env to confirm.

Relevant un-actioned proposal: `2026-05-28_volexp_no_chase_activation.md` Status: **"ready for activation (approved-verbally by Karri 2026-05-28)"** — Karri-approved but I cannot confirm the env flip happened. **Verify `VOL_EXP_NO_CHASE_ENABLED` in Railway.**

---

## TF_ADX 22→20 + H14 optimal-configs — UNKNOWN / still proposed

- **TF_ADX 22→20:** code default is still `TF_ADX_MIN=22` (`trend-following/config.ts:29`). Proposal `2026-05-13_tf_adx_22_to_20.md` Status: **proposed** (not approved). Only active if Railway sets `TF_ADX_MIN=20`. No funnel evidence (TF blocked on weekend session anyway). **UNKNOWN-leaning-OFF.**
- **H14 optimal-configs** (`2026-05-16_{tf,bc,sb}_optimal_config_h14`, `mr_reaktivering_h14`, `volexp_deaktivering_h14`): ALL Status **proposed**. These are env-knob bundles (per-strategy thresholds) + a vol-exp *deactivation* proposal. No approval recorded → assume code-defaults in effect unless Railway overrides. **UNKNOWN, need Railway env to confirm any knob deviates from default.**

---

## Bottom line for operator

**CONFIRMED ACTIVE (6):** STRATEGY_BLADE master + NEW_GATES, SL_COOLDOWN, regime_direction_gate, daily_trade_cap, mean_revert gate, session_block (≥ soft-log). regime_direction + daily_cap are armed but not yet rejecting (low volume); sl_cooldown + mean_revert ARE rejecting on live data.

**CLEARLY OFF (2):** cross_strategy_direction_flip (needs-scope-down), null_direction_block (needs-pivot).

**UNKNOWN — need Railway env read:**
- FUNNEL_DRAIN_PROPOSALS (leaning off; gated on operator+Karri OK)
- Vol-exp filters: NO_CHASE, confluence (MIN_PASSED_CRITERIA), MEAN_REVERT_BLOCK, ALLOW_LONG/SHORT
- TF_ADX_MIN (20 vs default 22)
- All H14 optimal-config knob bundles
- New-gates sub-flag hard/soft state (RISK_LEVEL_HARD, SCALP_OVERLAP_ASIA_BLOCK, RANGING_CONVICTION, ENTRY_STACK_COOLDOWN per-flag)

## Batch-2 items still needing Karri / operator action

1. **`2026-05-28_volexp_no_chase_activation.md`** — Karri-approved-verbally, status "ready for activation". Likely the highest-value un-flipped item (directly targets the −$4.1k vol-exp bleed). **Confirm whether `VOL_EXP_NO_CHASE_ENABLED=true` is set in Railway; if not, flip is pending.**
2. **`2026-05-13_cross_strategy_direction_flip.md`** — Status needs-scope-down. Karri review still open. (11.5 cluster cost −$1,585 from one flip-pair.)
3. **`2026-05-13_null_direction_block_eligible.md`** — Status needs-pivot. Un-resolved.
4. **`2026-05-13_tf_adx_22_to_20.md`** + the five **`2026-05-16_*_h14`** configs — all Status: proposed, no approval recorded. Karri triage outstanding.
5. **`2026-05-11_funnel_drain.md`** — implemented behind flag, awaiting explicit operator+Karri OK to flip (trade-frequency increase).
