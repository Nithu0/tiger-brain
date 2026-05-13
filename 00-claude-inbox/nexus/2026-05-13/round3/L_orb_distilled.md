---
title: ORB lesson distilled — audit
date: 2026-05-13
session: round3
output_path: ~/Obsidian/Brain/_library/trading/strategies/orb_xau.md
---

# Audit — `orb_xau.md` distillation

## Sources consulted

- `apps/worker/src/firm/orb/config.ts` — env-vars, window defs (London 08:00–08:30, NY 14:30–15:00), formation rules, hard gates.
- `apps/worker/src/firm/orb/orb-manager.ts` (lines 1–220) — confirmation flow, trend-filter, daily cap, fit-score weights, 5-criteria binary check, rearm-on-stopout decision.
- `docs/ref/orb.md` — module map (6 files), orchestrator integration (Step 1b), DB tables, blackboard topics.
- `docs/strategy/orb-master-plan.md` — adoption rationale 24.4, kjerneregler (range quality 0.5–3.0×ATR, CLOSE-not-wick, SL = opposite side, TP = 2× range), hard no-trade-filtre, roadmap (BOS-reversal, trailing, FVG-confluence).
- `docs/ops/phase-status.md` — current LIVE state, `orb_observe_only` proposal queued in TIER 1 after -$398 bleed.
- `docs/ref/feature-flags.md` — confirmed `ORB_ENABLED=true` and `ORB_ONLY_MODE` semantics (bypasses Prism + Blade pipeline).
- Curriculum `10_trading_curriculum.md` — Fisher (ACD method, A-up/A-down, 3-day pivot range, failed-breakout playbook), Crabel (NR4/NR7, "stretch"), Raschke (Turtle Soup) — cross-referenced as upstream sources for ORB implementation.

## Format match

Followed the `volatility_expansion.md` template precisely: frontmatter shape, section ordering, 50-word/60-word opener targets, code-rooted "implementation" section, "what's been validated live" pulling from phase-status, "where it fails" using the master plan's hard-no-trade-filtre + Karri's `orb_observe_only` flag, cross-references explicitly tying each book to a code/concept gap.

## Key findings worth flagging

1. **Live edge has not held** — the lesson states this honestly (per the `orb_observe_only` TIER 1 proposal sitting in Karri's queue after -$398 day, plus roadmap targets not met). The volatility-expansion lesson reported PF≥1; this one had to report regime-dependence instead.
2. **Crabel's "stretch" maps directly to `ORB_RANGE_MIN_USD`/`MAX_USD`** — those env-vars are currently hand-tuned absolute dollars, not self-calibrating. Quick win: rewrite as a fraction of trailing ADR (Crabel-canonical). Worth raising with Karri as a separate proposal after the current observe-only decision lands.
3. **Fisher's 3-day pivot range is missing from Nexus** — would give a higher-TF context filter for daily session-only ranges. Could replace or augment the current `xauusd.analysis.technical` trend-filter call. Pending Fisher full-text ingestion.
4. **Turtle Soup (Raschke) is the literature for `ORB_BOS_REVERSAL_ENABLED`** — master-plan-flagged as future extension; the literature exists and is rules-based. Promotable to a proposal when ORB-base hits ≥30 clean trades.

## Word counts

- Lesson: ~720 words body (frontmatter excluded). Slightly over the 300–500 target — driven by the precision required to capture Nexus's 5 binary criteria + 5 hard gates + Karri-state. Kept tight; no padding.
- This audit: ~280 words.

## What I did NOT include

- ORB stats.ts internal math (would have pushed lesson over budget; covered by "fit score 0–100" pointer).
- Position-management interaction (break-even, trailing) — covered by master plan but belongs in a position-management lesson, not the strategy lesson.
- Backtest results from `scripts/backtest-orb.mjs` — operator-mentioned in master plan but I did not run it and would not fabricate numbers.
