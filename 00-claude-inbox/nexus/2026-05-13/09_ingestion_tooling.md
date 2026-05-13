---
title: Ingestion tooling — books + YouTube → Obsidian markdown
date: 2026-05-13
author: Claude
status: spec
---

# Ingestion tooling pick

Single-operator WSL2. Goal: turn external knowledge (trading books, YT videos) into clean markdown under `~/Obsidian/Brain/_library/` so Claude can read it later.

## 1. PDF → markdown — **pick: `marker`**

Comparison:
- `pandoc` — fast but garbles multi-column, kills tables, no OCR. Useless for charts-heavy trading PDFs.
- `pymupdf4llm` — decent, fast, but tables come out flat and footnotes get jumbled.
- `pdfplumber` — library, not a tool. Build-your-own. Skip.
- `mistral OCR API` — best quality on tough scans but $$ + cloud. Overkill until we hit a scanned book.
- **`marker`** — LLM-assisted layout reconstruction, handles tables/charts/footnotes/equations. GPU optional. This is what you want.

Coin-toss: marker vs mistral OCR for scanned/photographed PDFs. Default marker; flip to mistral if a specific book's output is unreadable.

Install + usage:
```bash
pipx install marker-pdf       # isolates the heavy ML deps
marker_single /tmp/foo.pdf /tmp/out/ --output_format markdown
```

## 2. YouTube → transcript — **pick: `yt-dlp --write-auto-subs` first, `faster-whisper` fallback**

- `yt-dlp --write-auto-subs` — free, ~5 seconds per video, transcript quality is "fine" for English trading content where the YT auto-caption already exists. Punctuation weak.
- `faster-whisper` (or `whisper.cpp`) — local, runs on CPU acceptably, much better punctuation + speaker breaks. ~real-time on a 1h video without GPU.

Default: yt-dlp subs. Switch to faster-whisper when (a) no auto-subs exist, (b) heavy accent / poor audio, (c) it's a flagship lecture worth the extra minutes.

```bash
# fast path
yt-dlp --write-auto-subs --sub-lang en --skip-download \
  --convert-subs srt -o "%(id)s.%(ext)s" "$URL"

# fallback (audio-only, then whisper)
yt-dlp -x --audio-format mp3 -o "%(id)s.%(ext)s" "$URL"
pipx install faster-whisper
faster-whisper-cli "$ID.mp3" --model medium.en --output_format txt
```

## 3. EPUB → markdown — `pandoc`

```bash
pandoc -f epub -t gfm book.epub -o book.md --extract-media=./media
```

That's it. EPUB is structured; pandoc nails it.

## 4. Chunking — **one file per chapter**, with concept tags

Default: one markdown file per chapter. Justification: chapters are the author's natural semantic unit (~10-30 pages, fits Claude's context with room for the question), and table-of-contents alignment makes citation trivial. Per-concept splitting sounds nice but is fragile — you re-do it every book. Per-chapter is mechanical and reversible.

Concept tags go in frontmatter (`key_topics: [orb, regime-filter, risk-sizing]`) — that's how Claude finds chapter 7 of book X when researching ORB tuning.

## 5. Frontmatter template

```yaml
---
title: "Trading in the Zone"
author: "Mark Douglas"
source_type: book                    # book | youtube | article | podcast
source_url: ""                       # blank for offline PDFs
source_path: "/tmp/trading-in-the-zone.pdf"
chapter: 7
chapter_title: "The Five Fundamental Truths"
ingested_date: 2026-05-13
ingested_by: claude
key_topics: [psychology, edge, risk-acceptance]
relevance_to_nexus: 4                # 1-5; 5 = directly informs current modules
claude_priority: P1                  # P0 = read on next strategy session, P1 = read on demand, P2 = archive
word_count: 4320
---
```

## 6. Workflow sketch — `nexus-ingest`

`nexus-ingest book /tmp/foo.pdf`:
1. Slugify filename → `book_slug` (`trading-in-the-zone`).
2. Run `marker_single` → single big markdown.
3. Split on `^# ` headers (marker emits chapter headings as H1). Fallback: split on TOC if H1s missing.
4. For each chunk: inject frontmatter (title/author from PDF metadata via `pdfinfo`, chapter from heading, defaults for everything else — operator edits relevance/priority post-hoc).
5. Write to `~/Obsidian/Brain/_library/trading/<book-slug>/NN_<chapter-slug>.md`.
6. Emit `00_INDEX.md` in that folder: TOC linking each chapter, top-level frontmatter (title/author/source_path/ingested_date), and a `summary:` field operator fills in after first read.

`nexus-ingest yt <url>`:
1. yt-dlp pulls title + auto-subs (fallback faster-whisper if subs missing/short).
2. Convert SRT/VTT → flat markdown (strip timestamps, paragraph-break on long pauses).
3. Single file (no chapter split) at `~/Obsidian/Brain/_library/youtube/<channel-slug>/<video-id>_<title-slug>.md`.
4. Frontmatter: `source_type: youtube`, `source_url`, video duration, `key_topics: []` (manual).
5. Append entry to `_library/youtube/00_INDEX.md`.

## 7. **First step**

Install marker, ingest **one** trading book end-to-end **manually** before writing the wrapper script:

```bash
pipx install marker-pdf
mkdir -p ~/Obsidian/Brain/_library/trading/_smoke-test
marker_single /tmp/<pickabook>.pdf ~/Obsidian/Brain/_library/trading/_smoke-test/ --output_format markdown
```

Read the output. Eyeball tables + footnotes. If quality is good → write the `nexus-ingest` script. If marker chokes on a specific book → try `pymupdf4llm` on that one as fallback, or escalate to mistral OCR.

Don't automate before you've seen what marker produces on YOUR books. That's a half-day saved.
