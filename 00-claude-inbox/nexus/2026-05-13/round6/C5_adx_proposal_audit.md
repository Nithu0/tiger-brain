# C5 — TF ADX 22 → 20 proposal audit

**Date:** 2026-05-13
**Author:** Claude (cold-start, round 6 dispatch)
**Proposal file:** `/home/nithu/code/ai-assistent/docs/strategy/proposals/2026-05-13_tf_adx_22_to_20.md`
**Status filed:** proposed → Karri review

## What this proposal does

Rolls S1 xau-trend-following ADX-threshold back from 22 (sweet-spot tune-up 12.5) to canonical TIER-3-default 20. Single env-var flip (`TF_ADX_MIN=20`), 30-sec rollback via Railway.

## Why now

Round 5 produced **converging evidence from two independent agents**:

1. `signal_rejection_deep_dive.md` flagged S1 ADX-gate as the single "closest-to-firing strategy" in the firm (28 within 2 of threshold, 63 within 5).
2. `near_miss_analysis.md` independently ranked S1 ADX as the **smallest single margin in the entire portfolio**: 12 cycles at ADX 21.2 (0.8 points / 3.6% from firing) in the last 24h.

Combined with 14 days of zero S1 live trades, this is a strategy that is currently dead code in the prevailing low-vol regime. The 22-threshold was raised via 6mo composite backtest that did not include the current 11–13.5 regime where ATR-ratio sits at 0.72–0.81 (below the 1.05 vol-expansion gate).

## Risk-profile snapshot

- **Best case:** ~37 signals/24h unlocked at ADX-gate. Downstream gates (OVERLAP_ACTIVE, no_chase, vol_expansion_below_min @ 1.05) will eat most. Realistic net: **3–8 new S1 trades/week, primarily in NY_CONTINUATION**. Primary win: break the 14d data drought.
- **Worst case:** Marginal-ADX (20-22 band) entries underperform → marginal bleed. Mitigated via post-flip 14d A/B with metadata tag `adx_band=marginal_20_22`.
- **Edge:** If Karri's trend-pause hypothesis (12.5) holds, marginal-ADX trades are structurally worse. Post-flip data resolves this — without it we have nothing to test against.

## Why this clears Karri's evidence-bar

Not a structural change. ADX 20 has 90d+ historical precedent from the TIER-3-deploy period (canonical default until 12.5 tune-up). This is a retune within already-tested range, single-knob, single-env-var, fully reversible in 30 seconds. The 12.5-tune-up rationale (composite backtest favoring 22) was sound for that regime — current regime data warrants reverting.

## Implementation correctness check

- Verified env-var name: `TF_ADX_MIN` (not `TF_ADX_THRESHOLD` as initial brief said). Confirmed at `apps/worker/src/firm/trend-following/config.ts:43`. Proposal uses correct name.
- Preferred rollout path documented: Railway env override first (no code change), with code-default flip deferred until A/B data confirms.
- Rollback path: single env-var, 30-sec via Railway, no schema/migration impact.

## Open questions for Karri (carried in proposal)

1. Land on 20 or halfway-rollback at 21?
2. Run 14d A/B with `adx_band` metadata for marginal-band post-mortem?
3. Apply same rollback to S3 pullback-continuation (20 → 18)? Held back — S3 has 0 within 2, no near-miss evidence yet.

## Send status

Filed during Nordic work hours (~11:30 CET 2026-05-13). Per `feedback_auto_send_karri.md` — eligible for auto-send to Karri Discord webhook by main thread (no per-message confirmation needed). No "vent"/"hold" override seen.

## Files referenced

- `/home/nithu/code/ai-assistent/apps/worker/src/firm/trend-following/config.ts:43`
- `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/round5/signal_rejection_deep_dive.md`
- `/home/nithu/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/round5/near_miss_analysis.md`
- `/home/nithu/code/ai-assistent/docs/strategy/proposals/README.md`
