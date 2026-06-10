---
title: WF lane knowledge-ingest — books + YouTube-channel ingestion design
date: 2026-06-08
lane: knowledge-ingest
author: claude (nexus firm worker)
type: design + activation-plan
status: design-complete (no build landed; design + 1 doc-fix queued-file recommendation)
related:
  - "[[YOUTUBE_INGESTION_SPEC]]"
  - "[[GITHUB_DISCOVERY_SPEC]]"
  - "[[MEMORY_DISTILLATION_SPEC]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
---

# Knowledge-ingest lane — design + activation plan

DESIGN-ONLY lane. No code landed (the constraint is BUILD => new branch + default-OFF flag;
this lane is a design + activation plan, plus a queue-file drop). Findings below are from
read-only inspection of `command-center/packages/{youtube-ingest,github-discovery,memory-engine,
brain-orchestrator,rag-engine}` + the brain folders.

## 1. What EXISTS (verified, not claimed)

### youtube-ingest — REAL and solid
`command-center/packages/youtube-ingest` is a complete, tested package. `npx vitest run` =
**54/54 green** (7 files). Pipeline (`src/index.ts` `drainYoutubeQueue`):
1. list `*.url` in `12-youtube/_queue`
2. parse (`queue.ts`) — first non-comment line = URL; `# tags:` / `# note:` supported
3. metadata via `yt-dlp --skip-download -j` (`ytdlp.ts`, injectable seam)
4. denylist check (`channels.ts` + `_channels.yaml`)
5. transcript via `yt-dlp --write-auto-sub` → VTT → plaintext (en,nb,no)
6. **distill** (`distill.ts`) — copyright-safe, ≤500 words, >10-consecutive-word verbatim guard
7. anti-hype + confidence scoring (`anti-hype.ts`)
8. write note `12-youtube/<channel-slug>/<date-slug>.md` + verbatim → `_library/youtube/**` (gitignored)
9. move queue file → `_done/` (or `_failed/` w/ audit reason)

All external effects behind seams → suite runs offline. Production deps present:
`yt-dlp` IS installed (`~/.local/bin/yt-dlp`). **`ffmpeg` is NOT installed**, **`ollama` NOT on PATH**.

### github-discovery — REAL
`packages/github-discovery` — `drainGithubQueue`, license/risk/score gating, `_topics.yaml` allowlist
(currently empty). Same seam pattern. Not the focus of this lane but shares the queue-watcher.

### Wiring — gated, default OFF
`brain-orchestrator/src/triggers/queue-watcher.ts` (gate **G6**, env `BRAIN_ENABLE_QUEUE_WATCHER`):
watches `12-youtube/_queue` + `13-github-repos/_queue`. When G6 open AND `drainInline:true`,
it dynamically imports the ingest packages and drains in-process. **Default OFF** (daemon registers
G4+G6, both off; `daemon.test.ts` asserts this). So today nothing auto-picks-up — manual only.

### Distillation → RAG path
`memory-engine/src/distill-pipeline.ts` `distillAndInsert(verbatim_row_id)` is the single sink:
loads verbatim row → fingerprint-dedup → `distillReal` (two-tier) → persist MemoryObject + bge-m3
embedding (best-effort; NO_EMBED mode degrades to FTS-only). eval-harness MRR=0.9556 per workspace CLAUDE.md.

## 2. The GAPS (what blocks end-to-end channel + books ingestion)

**G1 — channel-URL not supported (the big one).**
`queue.ts` `YT_URL_RE` only matches `/watch?v=<11>` or `youtu.be/<11>`. A **channel** URL
(`youtube.com/channel/UC...`) is `malformed_url` → `_failed`. SPEC §38 is explicit:
*"NOT auto-channel-subscription — operator drops URLs explicitly; no scheduled channel-scraping in v1.0."*
So channel ingestion is **by-design absent**, not a bug. All 3 queued files are channel URLs
(fabervaale, Better System Trader, Quantified Strategies) and would all fail the current drain.

**G2 — youtube-ingest note → memory-engine distill is NOT wired.**
`drainYoutubeQueue` writes a markdown note to `12-youtube/<channel>/`. But `distillAndInsert`
keys off a **`verbatim_row_id` in the memory DB**, not a folder scan. There is no extractor that
ingests `12-youtube/**` notes (or `_library/youtube/**` transcripts) into the memory-engine
verbatim table. So distilled YT notes sit in Obsidian but do NOT reach the RAG corpus / agent
prompts automatically. (`rag-engine` has no `12-youtube` scan; only a `stubs.ts` gold reference.)

**G3 — distiller is still the deterministic placeholder.**
`distill.ts` emits a mechanical metadata-based summary ("covers material summarized mechanically
pending LLM distillation"), baseConfidence 0.7. The LLM distiller (Claude Haiku per SPEC §10)
can drop in behind the same signature but is not wired. Low knowledge value until swapped.

**G4 — no books pipeline at all.**
No `14-books` folder, no epub/pdf code in `packages/` (only litestream + a brain.test ref).
Books are greenfield.

**G5 — ffmpeg/whisper fallback absent.** Auto-subs only. Channels w/o captions can't be transcribed.
Not blocking for the 3 queued channels (captions confirmed available).

## 3. The fabervaale channel (task ask)

`https://www.youtube.com/channel/UCQTN8r4TYJUk2OXrkHyfVSQ` is **already queued** —
`12-youtube/_queue/2026-06-01T1300-fabervaale-eng-channel.url` (dropped 2026-06-01, operator-requested).
I did NOT add a duplicate. Note that file's own comment already flags the G1 channel-vs-video gap.
There are also 6 manually-distilled fabervaale notes already in `12-youtube/fabervaale-eng/`
(best-entry-zones-orderflow, liquidity-heatmap-guide, manage-a-drawdown-session, mental-game-of-trading,
orb-ivb-orderflow-model, risk-management-protocol) — so the operator has been hand-distilling pending
automation. NO `_done/` exists yet → the automated drain has never successfully run on this queue.

## 4. ACTIVATION PLAN (concrete, ordered)

Lane owner must keep BUILD on a new branch behind a default-OFF flag. Steps S1–S3 are the unblock;
S4–S6 close the RAG loop; S7 is books.

**S1 (BUILD, branch `feat/wf-knowledge-ingest-channel-expand`) — channel→video expansion.**
Add `src/channel.ts` to youtube-ingest: detect a channel/playlist URL, shell
`yt-dlp --flat-playlist --print "%(url)s" --playlist-end N <channel>/videos` to list the N latest
video URLs, write them as individual `_queue/*.url` files (inheriting the channel file's tags),
then move the channel file to `_done/`. Behind env `YOUTUBE_INGEST_CHANNEL_EXPAND=0` default.
`N` via `YOUTUBE_INGEST_CHANNEL_MAX=10` (cap cost). Behaviour-neutral on deploy (flag off).
Add tests w/ a fake `yt-dlp` lister. Run `npx vitest run` in the package before commit.
This is infra (carries learning, does not alter trade decisions) → not a Karri gate.

**S2 (manual verify, 1 run).** With S1 built + flag on locally, run a one-shot drain against the
fabervaale queue file → confirm it expands to per-video `.url` files and they distill to notes +
`_done/` audit lines appear. yt-dlp present, captions confirmed (en+no), no ffmpeg needed.

**S3 (LLM distiller swap, branch `feat/wf-knowledge-ingest-llm-distill`).** Replace the deterministic
`distillTranscript` body with a Claude-Haiku call (SPEC §10) behind `YOUTUBE_INGEST_LLM_DISTILL=0`.
Keep the >10-word verbatim guard as the hard post-check (it already fails loud on violation).
This raises note quality from placeholder to real knowledge.

**S4 (BUILD) — bridge YT notes → memory-engine verbatim.** Add an extractor that, on drain success,
inserts the verbatim transcript (`_library/youtube/**`) as a memory-engine verbatim row and calls
`distillAndInsert`, so the note reaches the RAG corpus + agent prompts. THIS is the gap that makes
ingestion actually feed the firm. Behind `YOUTUBE_INGEST_TO_MEMORY=0`.

**S5 — re-embedding.** Stand up Ollama bge-m3 (dim 1024) — currently NOT on PATH; this is the
last G4-precondition the workspace is already working on. Until then S4 lands in NO_EMBED/FTS-only.

**S6 — operator G6 flip.** Only after S1–S4 verified manually for ~1 week (per brain-upgrade-plan
G6 precondition), operator sets `BRAIN_ENABLE_QUEUE_WATCHER=1` + `drainInline:true` for true 24/7
auto-pickup. OPERATOR-GATED (env flip) — surface, do not flip.

**S7 — books pipeline (greenfield, branch `feat/wf-knowledge-ingest-books`).**
New `14-books/_queue` + new `@cc/book-ingest` package mirroring youtube-ingest's seam pattern:
queue file points at a local book file path → extract text → chunk → distill (same Haiku path as S3)
→ MemoryObject + embedding via the same `distillAndInsert` sink (reuse S4). Default-OFF flag
`BOOK_INGEST_ENABLED=0`.

## 5. Book-format recommendation (PDF vs epub)

**Prefer epub for text-heavy non-fiction; fall back to PDF only when epub unavailable.**
- **epub** = structured HTML/XHTML + a spine/TOC. Clean reading-order text extraction, chapter
  boundaries are explicit, no layout/column reconstruction. Best distill input. Tool: `epub2txt` or
  the `epub` npm lib → strip tags → chunk per chapter. DRM-free only.
- **PDF** = visual layout, not logical text. Two-column / figure-heavy trading books extract with
  broken reading order, page-header/footer noise, hyphenation breaks. Needs `pdftotext -layout`
  (poppler) + cleanup heuristics, and OCR (`ocrmypdf`/tesseract) for scanned/image PDFs.
- **Rule:** epub → direct text path; PDF (digital) → `pdftotext`; PDF (scanned) → OCR first.
  Chunk to ~800–1200 tokens with ~100 overlap, carry chapter+page metadata into the MemoryObject
  so RAG citations point back to the source. Same copyright posture as YT: verbatim chunks stay
  local-only in `_library/books/**` (gitignored), only distilled MemoryObjects get committed/embedded.

## 6. Queue-file action taken

None added — fabervaale is already queued (no duplicate). The existing file already documents the
channel-expansion caveat. If the lane owner wants, S1's expansion will consume that exact file.

## 7. Karri / operator surface

- **Operator-gated:** S5 Ollama stand-up (paid/infra), S6 `BRAIN_ENABLE_QUEUE_WATCHER=1` flip.
- **Karri:** NONE. This whole lane is learning-INFRA (capture/distill/observability/RAG-feed) —
  per the learning-infra-vs-strategy boundary it carries learning but does NOT alter trade decisions,
  so no strategy proposal needed. (Lesson-injection into agent prompts WOULD need Karri — but that's
  a separate downstream switch, not part of ingestion.)
