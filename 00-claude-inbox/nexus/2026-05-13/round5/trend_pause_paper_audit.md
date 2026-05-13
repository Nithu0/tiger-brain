---
date: 2026-05-13
round: 5
author: claude (data-paper composer)
task: compose Karri-facing evidence brief on trend-pause-bevissthet (NOT a proposal)
constraint: binding memory project_trend_pause_concept.md — "Don't propose own implementation — Karri reviewing"
output: docs/strategy/proposals/2026-05-13_trend_pause_data_paper.md
---

# Round 5 — trend-pause data paper audit

## What was produced

`docs/strategy/proposals/2026-05-13_trend_pause_data_paper.md`, ~5 min read,
8-section evidence brief framed for Karri's next review session.

Frontmatter explicitly marks it `Status: data-paper-not-proposal`,
`Type: evidence-brief` — distinct from the other ~25 files in the same
directory which are all `Status: proposed/approved/implemented`. Lives in
`proposals/` per operator instruction so it co-locates with the proxy proposals
Karri may want to read together.

## Source materials consumed

1. `~/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/05_cross_strategy_regime.md` — round-1 cross-strategy audit (90d, 152 trades). NB: lives at top level, NOT under `round2/` as the task description stated.
2. `~/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/round2/18_trend_pause_karri_state.md` — round-2 state organizer
3. `~/Obsidian/Brain/_library/trading/concepts/trend_pause_detection.md` — library concept entry
4. `~/Obsidian/Brain/_library/trading/sources/karri_quotes_corpus.md` — Karri quote harvest
5. `~/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/round3/A2_null_reason_tagging.md` — A2 instrumentation status (9 null-reason tags now wired)

## Structure used

1. Karri's hypothesis (verbatim 12.5 quote)
2. Quantitative evidence — counter-trend -$5 954, TRENDING 15.4% WR, TRENDING+with-trend 0/5
3. Case study — 2026-05-11 textbook day (9 trades, 6 shorts into +$76 rally, all 4 strategies)
4. What's NOW measurable — A2 deployed today, table of 9 null-reasons + implication of each
5. Data gaps Karri's decision needs — 7d histogram, M15 EMA spread, candle-overlay, backfill, counter-factual replay
6. Concrete things Claude can prepare — 6 read-only / observability-only deliverables, none requiring detector design
7. Karri's 6 open questions (unchanged from 12.5, no Claude-pre-answers)
8. Explicit "next step is yours" footer

## Constraint compliance check

- No detector design proposed: confirmed. Section 7 explicitly leaves the 6 design questions open. Sections 4 (null-reason table) and 6 (prep tasks) are framed as data substrate, not design decisions.
- No timeframe choice committed: confirmed. Section 5 lists M15 EMA20-50 as a *gap to fill*, not a recommended axis.
- No activation policy committed: confirmed. Section 7 question 5 left as "hard gate, soft filter, or regime-state input".
- No extension of hypothesis: confirmed. The 0/5 with-trend TRENDING finding is presented as "new evidence that doesn't fit your original formulation directly" — flagged for Karri, not patched by Claude.

## Voice / tone choices

- Mixed NO/EN per Karri-corpus harvest (memory `reference_strategy_reviewer.md`: "address Karri casually, mixed NO/EN")
- Direct address ("din hypotese", "dine åpne spørsmål", "neste steg er ditt")
- Concrete numbers in every claim (no hand-waving)
- Section 8 names what to send him as handoff package (3 docs, ~3500 words)
- No emojis (per global instructions)

## What I did NOT do

- Did not file this in the proposals registry table at the bottom of `proposals/README.md` — it's not a proposal, doesn't fit the table semantics. If operator wants it listed elsewhere (e.g. `docs/strategy/data-papers/` registry), say so.
- Did not auto-send to Karri's Discord. The auto-send rule is for proposals; this is explicitly not one. Operator decides hand-off.
- Did not modify the binding memory `project_trend_pause_concept.md`. Untouched.
- Did not run the A2 SQL histogram query — A2 was implemented locally NOT committed per its own audit; histogram only meaningful after deploy + 24h accumulation.
- Did not produce any new code or commits. Pure documentation.

## Open items for operator if Karri triggers any §6 prep task

If Karri picks any of the 6 prep tasks:
- #1 daily histogram report — requires A2 commit + deploy first (currently uncommitted per A2 audit)
- #2 annotated trade-log — needs `cycle_states` regime backfill (#4) to be useful for pre-2026-05-10
- #3 candle-overlay plotter — need to pick the plotting tool (matplotlib local? dashboard widget?)
- #4 processed_signals mining — straight SQL, ~30 min
- #5 proxy-impact replay — non-trivial; need to checkout gate logic against historical blackboard rows
- #6 `regime_direction_gate` observability fix — pure code change, no proposal needed, ~1h

None blocked on Karri review — all can ship the moment operator says "kjør".

## File path

`/home/nithu/code/ai-assistent/docs/strategy/proposals/2026-05-13_trend_pause_data_paper.md`
