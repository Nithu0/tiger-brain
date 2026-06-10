---
title: Book Notes
folder: 14-books
created: 2026-06-08
purpose: Distilled book notes as copyright-safe MemoryObjects; never full text
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
tags: [books, notes, distilled, memory-object]
---

## Purpose

This folder holds distilled notes from books in the same copyright-safe format as `12-youtube/`. It NEVER stores full book text — verbatim content goes to `_library/books/<author>/` which is gitignored and local-only. Distilled notes (no run of >10 consecutive source words) are safe to commit and link from MOCs.

The `_queue/` subfolder is the operator drop-zone. BrainOrchestrator's queue-watcher (gate G6) picks up `*.book` files, and `@cc/book-ingest` (gate `BOOK_INGEST_ENABLED`) extracts text (epub-first), chunks it, distills a copyright-safe note, and files it here.

## Subfolders

| Subfolder | Purpose |
|---|---|
| `_queue/` | Operator-dropped `*.book` pointer files awaiting pickup |
| `_queue/_done/` | Processed queue files (audit trail) |
| `_queue/_failed/` | Failed queue files with a reason audit line |
| `_samples/` | Example queue files |

## Queue file format

A queue file is `_queue/YYYY-MM-DDTHHMM-<slug>.book`:

```
# title: Thinking, Fast and Slow
# author: Daniel Kahneman
# tags: psychology, decision-making
# note: read for the gold-trading bias chapter
/home/nithu/books/kahneman.epub
```

- First non-comment line: path to the source `.epub` or `.txt` (required; absolute or relative to the brain root).
- `# title:` / `# author:` override metadata (epub metadata is used as a fallback, then the filename).
- `# tags:` comma-separated; `# note:` free text.

## Naming convention

`<author-slug>/<YYYY-MM-DD-title-slug>.md` — e.g. `daniel-kahneman/2026-06-08-thinking-fast-and-slow.md`.

## Gates (both default-OFF — behaviour-neutral until flipped)

- `BOOK_INGEST_ENABLED=1` — turns the `@cc/book-ingest` drainer on. Default off → drainer is a no-op.
- `BRAIN_ENABLE_QUEUE_WATCHER=1` — gate G6; lets the daemon auto-pick-up queue items. The `14-books/_queue` dir must also be added to the watcher's `queueDirs` (not in the default set yet).
