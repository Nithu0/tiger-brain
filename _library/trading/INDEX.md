---
title: Trading Knowledge Library — MOC
tags: [library, MOC]
type: index
---

# Trading Knowledge Library — Index (MOC)

Map-of-Content for the operator's curated trading-knowledge base. Built so future Claude sessions can answer XAUUSD-specific questions (and adjacent strategy / regime / gate questions) by pulling from a small, hand-distilled corpus instead of guessing or re-googling.

**Scope:** strategies actually used in Nexus (ORB, mean-reversion, breakout, trend follow), regime taxonomy, gate logic, position-management rules, and reusable lessons distilled from live trading + Karri reviews. Out of scope: pure-theory finance, retail-influencer content, anything not directly cross-referenceable to Nexus modules or proposals.

**Cadence:** sibling agents fill the sections below today (round 2, 2026-05-13). After ~30 lessons accumulate, re-evaluate whether to migrate to a proper vector store (Chroma / pgvector). Until then the grep + tag-filter path is fast enough.

---

## Concepts

Foundational definitions, taxonomies, and reusable mental models. Location: `~/Obsidian/Brain/_library/trading/concepts/`. Tag filter: `tag:concept`.

- _(sibling agents populating today — entries will appear with tags `concept` + topical e.g. `regime`, `gate`, `risk`, `microstructure`)_

## Strategies

Specific entry/exit setups, with parameter ranges, regime fit, and historical performance notes. Location: `~/Obsidian/Brain/_library/trading/strategies/`. Tag filter: `tag:strategy`.

- _(sibling agents populating today — entries should include S1/S2/S3/S4 deep-dives + reference setups like classical ORB, BB mean-reversion)_

## Lessons

Distilled "what we learned the hard way" — postmortems, near-miss saves, tuning iterations, Karri-feedback synthesis. Location: `~/Obsidian/Brain/_library/trading/lessons/`. Tag filter: `tag:lesson`.

- _(sibling agents populating today — keep each lesson under ~400 words, include date, trigger, takeaway, related Nexus commit/PR if any)_

## Sources

Where the knowledge came from — videos, papers, books, threads, Karri DMs. Each entry is a citation stub + 3-bullet summary so Claude can drill down without re-watching/re-reading. Location: `~/Obsidian/Brain/_library/trading/sources/`. Tag filter: `tag:source`.

- _(sibling agents populating today — YouTube transcripts already in `~/Obsidian/Brain/_library/youtube/`; raw paste-ins in `_library/raw/`)_

---

## How to use this index (instructions for future Claude)

1. **Grep this INDEX.md first** to scope the question. Search by keyword or topical heading (e.g. `regime`, `gate`, `ORB`, `mean reversion`). If the answer fits a section header, drill into that folder.
2. **Tag-filter via Obsidian MCP** — call `mcp__obsidian__obsidian_search_notes` with the relevant tag (`concept`, `strategy`, `lesson`, `source`) plus a keyword. Returns a ranked list; don't read everything.
3. **Read 1–2 most-relevant entries** before answering. Don't fan out into 10 files — the library is curated so the top hit is usually authoritative.
4. **If nothing relevant found**, say so explicitly to the operator and propose adding a new entry — don't fabricate. Cite Nexus code (`apps/worker/src/firm/*`) or proposal docs (`docs/strategy/proposals/`) as the fallback ground truth.
5. **Cross-reference Nexus state** — concepts/strategies here describe ideas; live behaviour is in `docs/ops/phase-status.md` + `docs/ref/feature-flags.md`. Always reconcile before quoting.
6. **At ~30 lessons accumulated**, raise with operator whether to spin up a vector store (see `~/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/08_rag_architecture.md` for the prior analysis).

---

_Last updated 2026-05-13 (round 2 bootstrap — sections seeded, content to follow same session)._
