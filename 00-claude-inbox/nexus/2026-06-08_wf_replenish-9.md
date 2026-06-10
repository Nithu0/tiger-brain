---
lane: replenish-9
task: S7 BUILD @cc/book-ingest
date: 2026-06-08
branch: feat/wf-knowledge-ingest-books
status: built, committed, NOT pushed
gate: BOOK_INGEST_ENABLED (default OFF)
---

# WF replenish-9 — @cc/book-ingest greenfield package

## Verdict

BUILT + committed on `feat/wf-knowledge-ingest-books` (commit `d1e16ca`). Behaviour-neutral on deploy (default-OFF flag). Not pushed (operator OK-kjør gate). All tests green, full workspace typecheck clean.

## What landed

Greenfield `@cc/book-ingest` package in the command-center repo (`packages/book-ingest/`), mirroring the `@cc/youtube-ingest` seam pattern:

- `drainBookQueue()` drains `14-books/_queue/*.book` → epub-first text extract → word-bounded chunk → deterministic copyright-safe distill → flat-frontmatter note in `14-books/<author>/` + verbatim text under `_library/books/**` (gitignored).
- All external effects (extraction, fs) behind injectable seams; vitest runs fully offline.
- `BOOK_INGEST_ENABLED=1` gate — `drainBookQueue()` is a no-op (`processed:0`) unless set. Gate is enforced inside the function via env only (no opts override), so a stray caller cannot turn it on.

Files: `types.ts`, `slug.ts`, `queue.ts`, `chunk.ts`, `distill.ts`, `note.ts`, `extract.ts`, `index.ts` + 6 test files (35 tests).

## Seam-fidelity notes (vs youtube-ingest)

- Queue payload is a local file path (`.epub`/`.txt`), not a URL — so the seam is a `TextExtractor(sourcePath)` rather than a URL `fetcher`.
- epub extraction uses `unzip -Z1`/`-p` shell-outs (no heavy epub/zip npm dep), then HTML-strips entries in order; pulls best-effort title/author from `content.opf` `dc:title`/`dc:creator`. Falls back to queue-file overrides → epub metadata → filename.
- Books are long → added a chunker (`chunk.ts`, default 800 words/chunk, MAX_CHUNKS cap) the way youtube did not need.
- Ported the copyright guard verbatim: distiller output must never reuse >10 consecutive source words; asserted in `processItem` and in a distill test.
- Failure resilience matches youtube: extract failure → `extract_source: none` + `needs_re_review`; malformed queue → `_failed/`; success → `_done/` with an audit line.

## "Reuse S3 distiller / S4 memory sink" — deviation, flag for review

The task framed it as "reuse S3 distiller -> reuse S4 memory sink". The actual youtube-ingest seam does NOT call memory-engine's `distillReal` (S3) or `storage` sink (S4) — it ships its own deterministic offline distiller and writes notes straight to the brain filesystem. I mirrored that exact pattern for fidelity, so book-ingest is self-contained (no memory-engine dependency). An LLM/memory-engine-backed distiller can later replace `distillBook()` behind the same signature without touching the worker — same upgrade path youtube documents. If the intent was a hard memory-engine wiring, that is a follow-up (would couple the package to memory-engine + sqlite, currently it has only a `uuid` dep).

## Daemon wiring (additive, behaviour-neutral)

`brain-orchestrator` queue-watcher (`queue-watcher.ts`):
- Added `drainBook?` seam + `resolveDrainBook()` (dynamic `import("@cc/book-ingest")`).
- Routing: a `rel` dir containing "book" → book drainer. `14-books/_queue` is NOT added to `DEFAULT_QUEUE_DIRS`, so the default watcher behaviour is unchanged. G6 gate stays default-OFF. Added 1 routing test.

## Data-side scaffold (Obsidian Brain, auto-syncs)

- Created `14-books/{_queue/_done,_queue/_failed,_samples}/`, `_library/books/`, `14-books/README.md`, `14-books/_samples/example.book`.
- `.gitignore`: added `_library/books/` + `14-books/_queue/_inbox/` (copyright-sensitive verbatim never committed).

## Verification

- `packages/book-ingest`: tsc clean, build clean, 35/35 vitest green.
- `brain-orchestrator`: tsc clean, gates 13/13 + full suite 73/73 green.
- Full workspace `npm run typecheck`: EXIT 0 (book-ingest inserted into build + typecheck chains).

## Branch incident (resolved)

A concurrent worker switched the shared working copy onto `feat/wf-replenish-8-yt-to-memory` between my `checkout -b` and my commit, so my first commit (`791adb3`) landed on that lane's branch. Fixed: cherry-picked to `feat/wf-knowledge-ingest-books` (`d1e16ca`) and restored `feat/wf-replenish-8-yt-to-memory` to its tip (`1dbc8dd`) via `git branch -f` — no working-tree touch, no commits lost from either lane. Note for orchestrator: parallel lanes sharing one checkout race on branch state; worktrees would avoid this.

## Constraints honoured

No Railway flips, no push, no trades, no strategy/risk/gate-logic changes, no ADX/regime/indicator edits. Husky not bypassed (no husky in command-center). Only my files staged; other workers' unstaged changes left untouched.
