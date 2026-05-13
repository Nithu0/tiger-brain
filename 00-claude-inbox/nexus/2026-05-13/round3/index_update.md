---
title: INDEX.md round-3 fill — audit
date: 2026-05-13
round: 3
tags: [audit, library, index, moc]
---

# INDEX.md round-3 fill — audit

## What ran

Filled the four placeholder sections (`Concepts`, `Strategies`, `Lessons`, `Sources`) in `~/Obsidian/Brain/_library/trading/INDEX.md` with one-line bullets per file, plus added a `## Topic pivot` section grouping entries by tag for fast cross-cutting lookup.

## Total entries indexed: 9

**Concepts (3):**
- `foundation_gate_tier3.md` (P0)
- `karri_mental_model.md` (P0)
- `trend_pause_detection.md` (P0)

**Strategies (5):**
- `orb_xau.md` (P0)
- `mean_reversion_xau.md` (P0)
- `scalp_overlap.md` (P0)
- `session_breakout.md` (P0)
- `volatility_expansion.md` (P0)

**Lessons (0):** folder empty. Noted explicitly in INDEX with pointer to raw drafts in `00-claude-inbox/nexus/2026-05-13/`.

**Sources (1):**
- `karri_quotes_corpus.md` (raw status, P0-priority)

## Orphans

None. Every `.md` file present in `concepts/`, `strategies/`, `sources/` is now indexed. `lessons/` is empty so no orphan possible there.

## Topic-pivot clusters

Largest cluster is **Reviewer-binding / workflow** (4 entries cross-listed: `karri_mental_model`, `karri_quotes_corpus`, `trend_pause_detection`, `mean_reversion_xau` for the all-caps code-header guard). **ORB/breakout** and **Mean reversion** clusters each carry 2 strategy files plus cross-refs.

## SKILL.md changes

Updated `~/.claude/skills/trading-knowledge/SKILL.md` v0.1.0 → v0.2.0:

1. `description` frontmatter — added `scalp-overlap`, `session-breakout`, `volatility-expansion`, `TIER 3` as explicit triggers.
2. `## When this skill activates` — expanded trigger list with strategy-specific Karri vocabulary (`TIER 1 fix`, `observe-only`, `structural vs statistical`, `impuls / pause / fortsettelse`, `smart-money pullback`, `no-chase`, `katastrofedag`, `post-impulse blind`, `compression / expansion`, `pullback continuation`, `RSI extreme`, `ATR ratio`, `SL cooldown`, `regime direction`, `session block`).
3. Routing step 1 — pointed Claude to the new `## Topic pivot` section for cross-cutting questions.
4. Routing step 2 — added `tag:strategy mean-reversion` and `tag:strategy session-breakout` example queries.

## Follow-ups (not actioned)

- `lessons/` folder is empty. Round-3 produced strategy/concept distillations but no postmortem-format lessons. When the trend-pause-blindhet postmortem or 11.5 13:14 scalp-overlap forensics get distilled into a tag:lesson note, add it here.
- `karri_quotes_corpus.md` is marked `status: raw`. Once Karri actually fills in any of the 16 enumerated `(Karri fyller inn her)` placeholders in proposal docs, promote affected entries to `status: distilled` and back-link from `karri_mental_model.md`.
