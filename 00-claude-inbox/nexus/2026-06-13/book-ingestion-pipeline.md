# Book → Brain → Trade-Decision pipeline — analysis + spec

Date: 2026-06-13
Author: Claude (Opus 4.8, 1M)
Scope: How a trading book becomes (a) a distilled concept note in the Brain and (b) injectable knowledge a Nexus firm-agent retrieves per trade decision.
Status of this doc: ANALYSIS + SPEC. No behavioural code shipped (pure-additive scaffold proposal only; nothing wired into the trade loop without Karri-gate).

---

## TL;DR

- **Does the existing ingestion path work for books? PARTIAL — gap is one bridge.** The Nexus `agent_knowledge` path (ingest → Postgres → FTS → inject into risk-advisor/trade-critic) is REAL and end-to-end for YouTube. The schema already accepts book content (`source_type` allows `'doc'`/`'paper'`/`'manual'`). And the command-center `@cc/book-ingest` package already solves the hard part for books — epub/pdf/txt extraction + copyright-safe distillation. **But the two are disconnected: book-ingest writes only to the Obsidian vault; nothing writes book content into Postgres `agent_knowledge`.** That missing vault-note→Postgres bridge is the entire gap.
- **The smallest concrete next step:** distill ONE book's risk rules into a small operator-curated `.md`, then load those rows into `agent_knowledge` with `source_type='doc'`, `domain='xauusd'`, `status='active'`. The retrieval + injection that already exists picks them up the moment `AGENT_KNOWLEDGE_ENABLED` + `KNOWLEDGE_INJECTION_ENABLED` are flipped. That flip is the only money-near gate and it goes to Karri.

---

## 1. The existing `agent_knowledge` path (verified, end-to-end)

Repo: `/home/nithu/code/ai-assistent`. All flags default OFF.

**Ingest** — `scripts/firehose/ingest-youtube.mjs`
- Gated on `AGENT_KNOWLEDGE_ENABLED` (or `FIREHOSE_FORCE=true`).
- Fetches a YouTube transcript via `yt-dlp` (VTT subtitles) → `cleanVtt()` → `chunkText()` greedy-packs to `KNOWLEDGE_CHUNK_MAXCHARS` (default 1500 chars) on sentence boundaries.
- Writes one row per chunk. **The `source_type` is a hardcoded SQL literal `'youtube'`** in the INSERT (`ingest-youtube.mjs:~116-119`) — so even the `--transcript-file=<path>` escape hatch (which DOES exist, lines 158-160) stores book text mislabeled as `youtube`. This is the one concrete code-level snag for reuse.

**Store** — `packages/shared/src/db/schema.ts:~1360-1397`, table `agent_knowledge`
- Columns include `source_type, source_url, source_title, source_author, domain, topic_tags TEXT[], chunk_index, chunk_total, content, embedding JSONB, status, added_by, operator_rating (1-5), operator_note`.
- CHECK constraint **already allows books**: `source_type IN ('youtube','doc','paper','manual','transcript','podcast')`. So no migration is needed to store book content — use `'doc'` or `'paper'`.
- `status IN ('pending','active','archived')`; only `active` is retrievable.
- Indexes: partial `(domain,status,added_at) WHERE status='active'`; `source_url`; GIN on `topic_tags`; **`idx_knowledge_fts` = GIN on `to_tsvector('english', content)`**.

**Index/retrieve** — `apps/worker/src/firm/agent-knowledge/client.ts:~147-192` `searchByText()`
- Postgres FTS: `ts_rank_cd(to_tsvector('english',content), plainto_tsquery('english',$2))`, filtered `status='active' AND domain=$1`, ordered by `operator_rating DESC, rank DESC, reference_count DESC`. Bumps `reference_count`/`last_referenced_at` on hit.
- **The `embedding JSONB` column is a dead end.** `scripts/firehose/embed-pending.mjs` generates + stores vectors (gated `KNOWLEDGE_EMBED_ENABLED`), but NOTHING reads them for retrieval. There is no pgvector extension. Retrieval is pure FTS. Semantic search over books — the thing embeddings would buy — is not implemented. (Not a blocker for books; keyword FTS works. Just note it.)

**Inject** — `apps/worker/src/firm/agent-knowledge/injection.ts:~42` `buildKnowledgeContext()`
- Requires BOTH `AGENT_KNOWLEDGE_ENABLED` AND `KNOWLEDGE_INJECTION_ENABLED` (`injection.ts:~29-34`).
- `formatKnowledgeBlock()` renders `## Reference knowledge (operator-curated)` with title/author/rating/tags/url + ~400-char preview + score.
- Wired into two live firm-agents:
  - `risk-advisor.ts:~113-126` — query `"${regime} regime ${session} session risk advisory"`, `maxChunks:3`.
  - `trade-critic.ts:~69-76` — query `"trade postmortem patterns regime mismatch failure modes"`, `maxChunks:3`.
- Retrieval per agent is a FIXED keyword query (not vector, not dynamic-per-trade). So for a book to reach a decision, its chunks must contain words that match those fixed queries (e.g. "risk", "regime", "session", "failure"). This matters for the next-step design — distilled book notes should be phrased with the vocabulary the agents query on.

**Flags** (`apps/worker/src/firm/lib/flag-echo.ts:~50-51`): `AGENT_KNOWLEDGE_ENABLED=false`, `KNOWLEDGE_INJECTION_ENABLED=false`, `KNOWLEDGE_EMBED_ENABLED=false`.

### Book vs YouTube gap (narrow)
What's YouTube-specific and useless for a book: the `yt-dlp` transcript fetch + `cleanVtt()`, and the hardcoded `source_type='youtube'`. Everything else (chunking, store, FTS, inject) is source-agnostic. Concrete gaps to ingest a book into Nexus today:
1. No PDF/epub→text extraction in the `ai-assistent` repo. **(Already solved in command-center — see §2.)**
2. `source_type` is a hardcoded literal in the YT INSERT — a book needs a generic INSERT that sets `'doc'`.
3. Embedding column is unused — so no semantic retrieval. FTS-only.

---

## 2. The Brain side: book-ingest + the trading library + RAG

**`@cc/book-ingest`** — `/home/nithu/code/command-center/packages/book-ingest/` (built + tested; lands DARK, gated `BOOK_INGEST_ENABLED=1` AND the G6 queue-watcher gate, both default-OFF).
- `extract.ts` — epub (unzip + strip xhtml, no heavy deps), `.txt` direct, with a pdf seam. Pulls title/author from epub OPF metadata.
- `chunk.ts` — word-based chunking (`DEFAULT_CHUNK_WORDS`, `MAX_CHUNKS`).
- `distill.ts` — **copyright-safe**: `distillBook()` produces a summary capped at `SUMMARY_MAX_WORDS`, and `longestVerbatimRun()` enforces that the summary never reuses long word-runs from the source (anti-plagiarism guard). This is the asset that makes books safe to store.
- `note.ts` — renders a vault note (frontmatter + body) under `14-books/<author>/`.
- **What it does NOT do:** it never writes to Postgres and never calls the memory-engine `distillAndInsert`/`insertVerbatim`. Unlike `@cc/youtube-ingest` and `@cc/github-discovery` (which DO feed the memory-engine), book-ingest only writes a markdown note to the vault + verbatim text to gitignored `_library/books/`. So a distilled book is currently invisible to BOTH the command-center RAG engine AND Nexus Postgres.

**Trading library** — `/home/nithu/Obsidian/Brain/_library/trading/`
- `INDEX.md` + `concepts/` (11 notes), `strategies/` (5 — Karri's mapped strategies), `sources/`, `lessons/` (empty).
- Routed by the global skill `~/.claude/skills/trading-knowledge/SKILL.md` — a Claude-Code-session routing skill (reads INDEX → tag-filter → read 1-2 notes). It points only at the vault. No connection to RAG, Postgres, or firm-agents.

**Book queue** — `/home/nithu/Obsidian/Brain/14-books/_queue/` currently holds TWO un-ingested books:
- `Advanced+Futures+Trading+Strategies...epub` (25 MB)
- `Successful Algorithmic Trading.pdf` (2.3 MB)
- `14-books/_done`, `_failed`, and `_library/books/` are all empty — the pipeline has never run on anything.

**RAG engine** — `/home/nithu/code/command-center/packages/rag-engine/`
- Real code (hybrid BM25+vector, CombMNZ fusion, bge-m3 Ollama dim-1024), backed by `@cc/memory-engine` over **local SQLite** (sqlite-vec) at `~/.claude/projects/.../state/memory.db`. NOT Postgres, NOT the vault directly — it indexes distilled MemoryObjects in SQLite.
- `hybrid()` has **zero production consumers** outside its own eval harness (MRR=0.9556). Built-but-dormant as a query service. The brain-orchestrator daemon does distillation/triggers but does not call `hybrid()`.

### The decisive structural fact: TWO DISCONNECTED WORLDS
- **Nexus firm-agents** (repo `ai-assistent`, on Railway) get decision-time knowledge ONLY from **Postgres** `agent_knowledge` (FTS) + `agent_lessons` (SQL filters).
- **Brain-RAG** (command-center, SQLite) serves Claude-Code sessions / the orchestrator daemon locally. Never reaches Railway.
- Grep of the entire `ai-assistent` repo for `rag-engine` / `@cc/` / `bge-m3` / `ollama` → zero runtime references. No `package.json` depends on `@cc/*`.

**Implication:** "book concept reaches a live trade decision" = book content must land in **Postgres `agent_knowledge`** inside the `ai-assistent` repo. The command-center RAG engine cannot deliver that. So the design has two parallel sinks, and only the Postgres one touches live trading.

---

## 3. Design: book → Brain → decision (reuse, don't rebuild)

Two sinks, fed from ONE distilled artifact:

```
        operator drops PDF/epub into ~/Obsidian/Brain/14-books/_queue/
                              │
                              ▼
            @cc/book-ingest  (extract → chunk → distillBook, copyright-safe)
                              │
                produces ONE distilled artifact:
        ~/Obsidian/Brain/14-books/<author>/<book>.md   (concept note: rules, not prose)
                              │
              ┌───────────────┴────────────────┐
              ▼                                 ▼
   SINK A: Brain (Claude sessions)     SINK B: Nexus live firm-agents
   - the .md note is already here      - NEW bridge: vault-note → Postgres
   - trading-knowledge skill finds it    agent_knowledge rows (source_type='doc',
     via Obsidian MCP                      domain='xauusd', status='active')
   - (optional) route through            - existing FTS retrieval + injection.ts
     memory-engine distillAndInsert        picks them up at decision time
     so the SQLite RAG can retrieve it    - gated AGENT_KNOWLEDGE_ENABLED +
                                            KNOWLEDGE_INJECTION_ENABLED
```

### The only NEW piece: the vault-note→Postgres bridge (Sink B)
A small generic ingest script in `ai-assistent` (mirror of `ingest-youtube.mjs` minus yt-dlp), e.g. `scripts/firehose/ingest-knowledge-note.mjs`:
- Input: a distilled `.md` (or `--text-file` + `--source-type=doc --title --author --domain --tags`).
- Reuse `chunkText()` (extract to a shared `lib/chunk.mjs` or copy — it's ~15 lines).
- INSERT with parameterised `source_type` (default `'doc'`) instead of the hardcoded `'youtube'` literal. `status` starts `'pending'`; operator/curation flips to `'active'`.
- Idempotent replace-on-reingest via `source_url` (use a stable synthetic id like `book:successful-algorithmic-trading`).

This is **pure-additive** (new script, no change to the trade loop, no schema change — `'doc'` already allowed). It can be scaffolded now without a Karri gate, because it writes `status='pending'` rows that are invisible to retrieval until (a) flipped to `active` AND (b) the two injection flags are on. The behaviour-change gate is the flag flip, not the script.

### Copyright/secret caveat (binding)
- Store DISTILLED CONCEPTS ONLY — rules, heuristics, parameter intuitions, failure modes — never long verbatim passages. `@cc/book-ingest`'s `longestVerbatimRun()` guard already enforces this; the bridge should re-assert a max-verbatim-run check before INSERT.
- Verbatim/full text stays in gitignored `_library/books/**`, never in Postgres, never committed, never sent to Discord/Karri.
- The distilled note is the only thing that crosses into `agent_knowledge`.

---

## 4. Concrete next step (smallest thing that reaches a decision)

Goal: get ONE book's risk rules into one risk-advisor decision. Pick *Trading in the Zone* (operator's stated example) OR, since it's already queued, *Successful Algorithmic Trading.pdf*.

**Step 0 (operator):** confirm the book and that we may distill it. Buying/owning is operator's call.

**Step 1 (Claude, no gate — pure-additive):**
- Distill the book's risk/discipline rules into a small operator-curated note `~/Obsidian/Brain/_library/trading/concepts/<book>_risk_rules.md` — 8-15 atomic rules, each phrased with the vocabulary the agents query on (`risk`, `regime`, `session`, `failure`, `postmortem`, `sizing`). Concepts only, no verbatim. (Can leverage `@cc/book-ingest` extraction on the queued PDF to get source text to distill from.)
- Scaffold `scripts/firehose/ingest-knowledge-note.mjs` (generic, parameterised `source_type`) — lands dark; default does nothing unless `AGENT_KNOWLEDGE_ENABLED`.

**Step 2 (operator-gated — DB write):** load the distilled rules into `agent_knowledge` as `source_type='doc'`, `domain='xauusd'`, `status='active'`, `operator_rating=4-5`, `added_by='book:<slug>'`. This is an INSERT into production Postgres — operator/`nexus-pg-rw`-approved write. (Until §1's flags are on, these rows are inert even when `active`.)

**Step 3 (Karri-gated — behaviour change):** flip `AGENT_KNOWLEDGE_ENABLED=true` + `KNOWLEDGE_INJECTION_ENABLED=true` on Railway. THIS is the money-near switch (it changes what risk-advisor sees at trade time → alters trade decisions). Per operator-prinsipp + the learning-infra/strategy boundary, lesson/knowledge injection that alters trade decisions goes through Karri before activation. File a `docs/strategy/proposals/` doc.

**Verify:** after flip, confirm a risk-advisor cycle on Railway logs shows the `## Reference knowledge` block containing the book's rules, and `reference_count` on those rows increments. Don't declare done until a real cycle injected them.

### Claude-infra vs gated split
| Action | Owner |
|---|---|
| Distill book → concept note in Brain | Claude (free) |
| Scaffold generic `ingest-knowledge-note.mjs` (dark) | Claude (free) |
| Extract queued PDF/epub via `@cc/book-ingest` | Claude (free, local) |
| Optional: route book note through memory-engine for SQLite RAG | Claude (free, local) |
| INSERT distilled rows into prod Postgres `agent_knowledge` | Operator (DB write, `nexus-pg-rw`) |
| Flip `AGENT_KNOWLEDGE_ENABLED` + `KNOWLEDGE_INJECTION_ENABLED` | Karri (strategy proposal) → Operator (Railway flip) |

---

## Open questions for operator
1. Which book first — *Trading in the Zone* (psychology/discipline rules; maps cleanly to risk-advisor) or the already-queued *Successful Algorithmic Trading* (more systematic/backtest, maps to trade-critic)?
2. Want the optional memory-engine route (so the local Brain RAG can also retrieve book notes), or is the Postgres path enough for now?
3. Should I scaffold the generic `ingest-knowledge-note.mjs` now (pure-additive, dark), or hold until you pick the book?
