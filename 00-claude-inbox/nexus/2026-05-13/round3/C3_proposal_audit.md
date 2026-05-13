---
date: 2026-05-13
author: claude (round-3 agent C3)
task: write `cross_strategy_direction_flip` proposal
output: `docs/strategy/proposals/2026-05-13_cross_strategy_direction_flip.md`
status: drafted, NOT committed
reviewer: Karri
---

# C3 proposal audit

## What I wrote

New proposal: a `cross_strategy_direction_flip_gate` that blocks (or shadow-logs) a new strategy proposal when ANY firm strategy opened an opposite-direction trade within the last X minutes. Env-gated `off|shadow|hard`, default `off`. Karri owns X (30/60/90/180), regime-conditional toggle, threshold, same-strategy exemption.

## Evidence used

- Round-2 agent 14: 11.5 13:14–14:12 cluster — 3 scalp SHORTs then vol-exp LONG 39 min later, -$1 585 from the flip-pair specifically. Cited as Exhibit A.
- Round-2 agent 18: Karri's trend-pause-bevissthet hypothesis — framed cross-strategy flip as surface symptom of the same pause-blindness rotproblem.
- Round-1 agent 5: TRENDING-regime stats (15.4% win, -$3 573 net), 11.5 textbook day (9 trades pregime=TRENDING, no coordination).

## Boundaries respected

- Did NOT pre-answer Karri's open questions (window, regime-cond, threshold) — explicitly left for him with candidates.
- Did NOT commit. File written to proposals/ only.
- Followed mal exactly: TL;DR, Current behaviour, Proposed change, Risk profile, Supporting evidence, Rollback path, Review notes.
- Status: `proposed`. Reviewer: Karri.
- Persistence pattern mirrors `daily_trade_cap` (writes gate_decisions row), NOT `regime_direction_gate` (which has known observability hole per agent 11).
- Relationship section ties to existing proposals (regime_direction_gate, daily_trade_cap) so Karri sees it isn't redundant.

## Rollout shape proposed

14-day shadow-mode → counter-factual replay over 152 trades since 26.4 → regime-stratified hit-rate → Karri decides hard threshold + final X. Pure observability path matches his standard.

## Open items

Auto-send to Karri's Discord webhook applies (filed during work hours, 2026-05-13 daytime CET). Proposal table in `proposals/README.md` not yet updated — operator decision whether to include in this drop.
