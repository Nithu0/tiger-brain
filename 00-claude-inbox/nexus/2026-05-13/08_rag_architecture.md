# RAG architecture for Claude Code + Obsidian (single operator)

**Context**: Linux WSL2, Obsidian vault at `~/Obsidian/Brain/`, `obsidian-mcp` installed, Claude Code runs locally. Goal: sharpen Claude into a trading domain specialist using books, YT transcripts, and curated notes.

**TL;DR**: Don't build a vector store. Build a curated index folder + skill files + a tagging discipline. That gets 80% of the value at 5% of the maintenance cost. Revisit vector search only if grep-style retrieval visibly fails for 3+ real queries.

---

## 1. What "RAG on Obsidian" actually means here

Claude Code already does file-system RAG: it greps, globs, reads, and follows links on demand. The mental model "RAG = vector DB" is misleading in this context. What matters is **retrieval quality**, which has three failure modes:

- **Discovery**: Claude doesn't know a relevant note exists.
- **Cost**: Reading 30 notes to find the one paragraph that matters burns context.
- **Recall under fuzziness**: User asks "trend-pause behavior" but the note is titled "regime stickiness" — keyword grep misses it.

A vector DB only helps with the third. The first two are solved by **indexes and conventions**, not embeddings. Honest framing: for a single operator with a few hundred to a few thousand notes, semantic search is a luxury, not a requirement. The bottleneck is curation, not retrieval algorithms.

---

## 2. Option matrix

### a. Pure Obsidian + obsidian-mcp (status quo)
**Pros**: zero setup, already works, Claude can list/search/read/tag/patch. Human and AI share one source of truth.
**Cons**: keyword search misses synonyms; large notes burn context; Claude must do multiple roundtrips to find the right note.
**Verdict**: foundation. Don't replace — augment.

### b. Local vector store (chromadb / sqlite-vss / lancedb / qdrant)
**Pros**: semantic recall, chunk-level retrieval, scales to thousands of docs.
**Cons**: embedding pipeline to maintain, sync drift when notes change, MCP wrapper to write/debug, embedding model choice + cost, returns chunks without filenames so Claude still has to read the source. Adds a second system to keep healthy when the existing system isn't actually broken.
**Verdict**: skip until grep-failure is a documented, repeated problem.

### c. Hybrid (Obsidian for human, vector store for Claude)
**Pros**: theoretically best of both.
**Cons**: doubles maintenance, introduces sync failure mode (vault edited → stale embeddings → Claude returns confidently wrong chunks). Worst-case outcome of all options.
**Verdict**: no. The drift cost is real and silent.

### d. Curated index pattern (CLAUDE.md / MEMORY.md style)
**Pros**: deterministic, cheap, version-controlled, human-readable. Already proven on this project — `docs/ref/` table + `CLAUDE.md` pointer block work. Trivially debugged: if Claude missed it, the index was wrong, fix the index.
**Cons**: requires writing/maintaining the index. Doesn't help with fuzzy queries on raw note bodies.
**Verdict**: highest leverage. Expand from `docs/ref/` to `_library/trading/INDEX.md`.

### e. Skill-files (`~/.claude/skills/<topic>/SKILL.md`)
**Pros**: only loads when relevant (trigger-based, not always-on), good for domain procedures ("when user asks about ORB tuning, do X then Y"). Already supported.
**Cons**: skills are procedures, not knowledge dumps. Wrong tool for "I read a book, store the lessons".
**Verdict**: use for repeatable workflows ("review-a-strategy-proposal"), not for raw knowledge.

---

## 3. Beyond RAG — sharpening techniques that fit this setup

- **Per-strategy session-start briefings**: when working on S1/S2/S3/S4, the CLAUDE.md (or a strategy-scoped skill) points to `docs/strategy/<name>/BRIEFING.md` — current params, last 3 lessons, known failure modes. Cheap and effective.
- **Just-in-time skill files**: e.g. `skills/review-strategy-proposal/SKILL.md` encoding the review checklist. Triggers only on intent, doesn't bloat context.
- **Pinned grep targets**: convention encoded in CLAUDE.md — "before answering questions about price-action concepts, grep `_library/trading/` first". This is the cheapest semantic shortcut available.
- **Memory-as-curriculum**: after reading a book/transcript, write a **distilled lesson** (200-500 words) to `_library/trading/lessons/<topic>.md` with tags. The raw source stays archived; the distillation is what Claude retrieves. This is the single highest-leverage move — it forces YOU to internalize and Claude to read 500 words instead of 50,000.
- **Tag taxonomy**: `#concept/`, `#strategy/`, `#instrument/xauusd`, `#regime/`, `#source/book`, `#source/yt`. Used by `obsidian_search_notes` for filtered retrieval.

---

## 4. Recommended approach for THIS operator

**Build a `_library/trading/` knowledge base with curated lessons + a hand-maintained INDEX.md. Skip vector stores entirely for now.**

Justification: (1) Single operator means no team-scale ambiguity — you can curate at human speed. (2) Obsidian-MCP + grep already handles retrieval; the gap is *quality of source material*, not *retrieval algorithm*. (3) Distilling sources into 200-500 word lessons does double duty — it teaches you, and gives Claude pre-chewed content with zero pipeline. (4) Diminishing returns on embeddings kick in hard below ~5k documents; you're nowhere near that. Revisit only if a real query fails because of synonym/recall, not because the lesson wasn't written yet.

**What NOT to over-engineer**:
- No chromadb/lancedb. No embedding pipeline.
- No automated YT transcript ingestion that dumps raw transcripts into the vault — that's noise, not knowledge.
- No "AI auto-summarizer" that writes lessons without you reading. Defeats the curriculum point.
- No second tagging system parallel to existing brain folders.

---

## 5. Three concrete next steps

1. **Create `~/Obsidian/Brain/_library/trading/` with subfolders** `concepts/`, `strategies/`, `lessons/`, `sources/`, plus a top-level `INDEX.md` listing every lesson with one-line summary + tags. Add a pointer in `~/code/ai-assistent/CLAUDE.md` under "Where to find details": `_library/trading/INDEX.md — distilled trading lessons (read first for domain questions)`.

2. **Write the first 5 lessons by hand** (e.g. one per book chapter or YT video you've consumed). Format: 200-500 words, frontmatter tags `#source/<type>`, `#concept/<area>`, link to the raw source note in `sources/`. This proves the workflow and reveals tag taxonomy gaps before you scale.

3. **Add a skill `~/.claude/skills/trading-knowledge/SKILL.md`** that triggers on trading-domain questions, instructing Claude to: (a) read `_library/trading/INDEX.md` first, (b) grep `_library/trading/lessons/` for relevant tags, (c) only then fall back to wider vault search. This wires the curated path into Claude's retrieval without touching MCP config.

After 30 days / ~30 lessons, re-evaluate. If grep-with-tags is failing on real queries, *then* consider a vector layer over `_library/trading/` only (not the whole vault). Keep the failure budget honest — don't pre-build for problems you don't have yet.
