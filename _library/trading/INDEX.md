---
title: Trading Knowledge Library — MOC
tags: [library, MOC]
type: index
---

# Trading Knowledge Library — Index (MOC)

Map-of-Content for the operator's curated trading-knowledge base. Built so future Claude sessions can answer XAUUSD-specific questions (and adjacent strategy / regime / gate questions) by pulling from a small, hand-distilled corpus instead of guessing or re-googling.

**Scope:** strategies actually used in Nexus (ORB, mean-reversion, breakout, trend follow), regime taxonomy, gate logic, position-management rules, and reusable lessons distilled from live trading + Karri reviews. Out of scope: pure-theory finance, retail-influencer content, anything not directly cross-referenceable to Nexus modules or proposals.

**Cadence:** sibling agents fill the sections below (round 2 bootstrap + round 3 fill, 2026-05-13). After ~30 lessons accumulate, re-evaluate whether to migrate to a proper vector store (Chroma / pgvector). Until then the grep + tag-filter path is fast enough.

---

## Concepts

Foundational definitions, taxonomies, and reusable mental models. Location: `~/Obsidian/Brain/_library/trading/concepts/`. Tag filter: `tag:concept`.

- [[foundation_gate_tier3]] (P0, `concept` `foundation-gate` `tier3` `operator-binding` `architecture`) — the 5-rule foundation-gate + TIER 3 4-strategy parallel-deploy binding. Refuse strategy work if any rule red.
- [[karri_mental_model]] (P0, `reviewer` `karri`) — Karri's vocabulary, demands, rejection patterns, approval archetypes, open research questions. Read before any strategy/risk reasoning.
- [[trend_pause_detection]] (P0, `concept` `trend-pause` `karri-owned`) — canonical open hypothesis: trend-pause vs flip discrimination. Karri-owned; do NOT propose detector designs.

## Strategies

Specific entry/exit setups, with parameter ranges, regime fit, and historical performance notes. Location: `~/Obsidian/Brain/_library/trading/strategies/`. Tag filter: `tag:strategy`.

- [[orb_xau]] (P0, `strategy` `orb` `breakout` `fisher` `crabel`) — Opening Range Breakout (XAUUSD lens). London + NY 30-min ranges, 5m close confirmation, range-derived risk. Live but under Karri scrutiny (orb_observe_only pending).
- [[mean_reversion_xau]] (P0, `strategy` `mean-reversion` `s4` `chan` `connors` `rsi`) — S4 8-gate pipeline. ADX<25, RSI 40/60, 1.5×ATR impulse fade. Approved-verbally 13.5, LIVE. News-block unresolved.
- [[scalp_overlap]] (P0, `strategy` `scalp-overlap` `mean-reversion` `session-overlap` `raschke`) — RSI-extreme fade inside London-NY overlap (12-16 UTC). Disabled observe-only post 11.5 13:14 forensics (3 SHORTs / -$1058 — strategy rules green but trend-blind).
- [[session_breakout]] (P0, `strategy` `session-breakout` `breakout` `fisher` `sl-flaw`) — London/NY range-break with load-bearing SL flaw: stop = opposite range edge = structural retracement zone. 43% OANDA_SL_TP hits over 30d. C2 proposal pending Karri.
- [[volatility_expansion]] (P0, `strategy` `volatility-expansion` `karri-approved`) — ATR-ratio breakout (recent 5 vs prior 15), 1.30× threshold, R:R 1:2.86. Only firm strategy with PF≥1 over 27d live. Approaching 30+ closed for autotune.

## Lessons

Distilled "what we learned the hard way" — postmortems, near-miss saves, tuning iterations, Karri-feedback synthesis. Location: `~/Obsidian/Brain/_library/trading/lessons/`. Tag filter: `tag:lesson`.

- _(folder empty as of 2026-05-13 round 3 — postmortem distillations queued; see `00-claude-inbox/nexus/2026-05-13/` working drafts for raw material)_

## Sources

Where the knowledge came from — videos, papers, books, threads, Karri DMs. Each entry is a citation stub + 3-bullet summary so Claude can drill down without re-watching/re-reading. Location: `~/Obsidian/Brain/_library/trading/sources/`. Tag filter: `tag:source`.

- [[karri_quotes_corpus]] (P0-status raw, `reviewer` `karri` `quotes`) — primary-source Karri quote harvest (08.5–13.5). Topic-pivoted: #trend-pause #regime #gate #sl #sizing #evidence-bar #strategy-spec #mean-reversion #vocabulary #workflow #sweet-spot-override. Use as raw evidence; interpretation lives in `karri_mental_model`.

---

## Topic pivot

Cross-cutting index by domain — grep this section first when the question doesn't fit cleanly into Concepts/Strategies/Lessons/Sources.

### ORB / breakout
- [[orb_xau]] — Opening Range Breakout, 5m-close confirmation, range-derived SL
- [[session_breakout]] — Range-edge breakout (London/NY) with structural SL flaw

### Mean reversion / counter-trend
- [[mean_reversion_xau]] — S4 portfolio-diversifier (counter-trend after impulse)
- [[scalp_overlap]] — RSI-extreme fade inside session-overlap window
- [[karri_quotes_corpus]] (#mean-reversion) — Karri's mean-rev framing + 12.5 vol-exp-blind-to-post-impulse coinage

### Volatility / breakout-continuation
- [[volatility_expansion]] — ATR-ratio expansion trigger, body-direction entry
- [[orb_xau]] (cross-ref Crabel) — NR4/NR7 contraction lineage

### Regime / detection
- [[trend_pause_detection]] — canonical Karri-owned hypothesis (do NOT auto-implement)
- [[karri_mental_model]] — regime_direction_gate proxy + open detector questions
- [[karri_quotes_corpus]] (#regime, #trend-pause) — H4-EMA-slope method-choice + 12.5 katastrofedag hypothesis

### Foundation / architecture / gates
- [[foundation_gate_tier3]] — 5-rule pre-flight + TIER 3 4-strategy parallel model
- [[karri_mental_model]] — gate stack order (sl_cooldown → regime_direction → session_block → daily_trade_cap → mini-Blade)
- [[karri_quotes_corpus]] (#gate, #evidence-bar) — cap=6 152-trade evidence, session-block impact framing

### Reviewer-binding / workflow
- [[karri_mental_model]] — vocabulary + demands + rejection patterns + approval archetypes
- [[karri_quotes_corpus]] — raw quote harvest, topic-pivoted
- [[trend_pause_detection]] — Karri-owned constraint binding
- [[mean_reversion_xau]] — code-header all-caps "KREVER KARRI-REVIEW FØR LIVE" guard

### Risk sizing / SL / cooldown
- [[karri_quotes_corpus]] (#sl, #sizing) — sl_cooldown per-strategi-vs-global, conviction-quartile 3-phase, postmortem size-down feedback
- [[session_breakout]] — full-range-SL is 5–7× wider than Fisher's textbook per-trade risk

### Strategy-spec vocabulary (Karri lexicon)
- [[karri_mental_model]] — TIER 1 fix, observe-only, structural-vs-statistical, sweet-spot tuning
- [[karri_quotes_corpus]] (#vocabulary, #strategy-spec) — S1/S2/S3 phase models, "Buy weakness in strength", "compression → trigger → expansion"

---

## How to use this index (instructions for future Claude)

1. **Grep this INDEX.md first** to scope the question. Search by keyword in the section headers above, or by topic-pivot tag (`### Mean reversion`, `### Regime / detection`, etc.). If the answer fits a section header, drill into that folder.
2. **Topic pivot for cross-cutting questions** — when the question spans multiple sections (e.g. "how do gates interact with mean-reversion?"), the `## Topic pivot` section groups entries by tag for faster lookup than full-folder scan.
3. **Tag-filter via Obsidian MCP** — call `mcp__obsidian__obsidian_search_notes` with the relevant tag (`concept`, `strategy`, `lesson`, `source`) plus a keyword. Returns a ranked list; don't read everything.
4. **Read 1–2 most-relevant entries** before answering. Don't fan out into 10 files — the library is curated so the top hit is usually authoritative.
5. **If nothing relevant found**, say so explicitly to the operator and propose adding a new entry — don't fabricate. Cite Nexus code (`apps/worker/src/firm/*`) or proposal docs (`docs/strategy/proposals/`) as the fallback ground truth.
6. **Cross-reference Nexus state** — concepts/strategies here describe ideas; live behaviour is in `docs/ops/phase-status.md` + `docs/ref/feature-flags.md`. Always reconcile before quoting.
7. **At ~30 lessons accumulated**, raise with operator whether to spin up a vector store (see `~/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/08_rag_architecture.md` for the prior analysis).

---

_Last updated 2026-05-13 (round 3 fill — 9 entries indexed across concepts/strategies/sources; lessons folder still empty; topic-pivot added)._
