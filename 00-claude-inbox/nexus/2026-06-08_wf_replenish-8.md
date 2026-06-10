# WF replenish-8 — S4 BUILD: youtube-ingest → memory-engine bridge

Date: 2026-06-08
Lane: replenish-8 (knowledge-ingest)
Verdict: BUILT (commit on branch, default-OFF, behaviour-neutral)
Repo: command-center (NOT ai-assistent — the packages live here)
Branch: feat/wf-replenish-8-yt-to-memory
Commit: 1dbc8dd

## The gap (confirmed)

`@cc/youtube-ingest` `drainYoutubeQueue()` already did the hard part: fetch
transcript via yt-dlp seam, distill a copyright-safe note, write the note under
`12-youtube/<channel>/`, write the verbatim transcript under `_library/youtube/**`,
and move the queue file to `_done`. But it stopped there — nothing pushed the
transcript into `@cc/memory-engine`. So YT knowledge:
- never landed in `verbatim_exchanges` / distilled layer,
- never reached the RAG corpus (`@cc/rag-engine`),
- never reached agent prompts.

It was a write-to-Obsidian dead end. `distilled_object_ids` in the note
frontmatter was even being populated with a throwaway `uuidv7()` that pointed
at NO real MemoryObject — a dangling reference that made it *look* wired.

Meanwhile the sink side was fully ready: `source_type: "youtube"` is already in
the memory-engine `SourceType` enum, `insertVerbatim` accepts it, and
`distillAndInsert(memoryDb, verbatim_row_id, opts)` is the canonical single
sink that every distillation trigger funnels into (verbatim → distillReal →
embed). Nothing called it from the YT path.

## What I built

New module `packages/youtube-ingest/src/memory-bridge.ts`:
- `YOUTUBE_INGEST_TO_MEMORY_ENV` + `memoryBridgeEnabled(env)` — gate, default OFF
  (unset / "0" → false; only "1" → true).
- `MemorySink` injectable seam interface + `MemorySinkInput` / `MemorySinkResult`.
  youtube-ingest takes NO hard dependency on memory-engine — the daemon / app
  wires the sink (same pattern as the queue-watcher's dynamic-import seam). Keeps
  the package dependency-free and offline-testable with a fake.

Wired into `drainYoutubeQueue` / `processItem` (`src/index.ts`) + new opts on
`DrainOptions` (`src/types.ts`): `memorySink?`, `ingestToMemory?`, `memoryProject?`.

Behaviour: after writing the verbatim transcript file, IF
(`YOUTUBE_INGEST_TO_MEMORY=1` OR `ingestToMemory:true`) AND a sink is wired AND
the transcript is non-empty AND not dryRun → call the sink, and thread the
returned real `distilledObjectId` into the note's `distilled_object_ids`
(replacing the throwaway uuid → closes the loop visibly).

Reference daemon wiring (in the bridge docstring):
```
const sink: MemorySink = async (input) => {
  const v = insertVerbatim(memoryDb, { ...input, source_type: "youtube" });
  const r = await distillAndInsert(memoryDb, v.id, { distiller, embedder });
  return { verbatimRowId: v.id, distilledObjectId: r.object.id, ... };
};
```

## Safety / constraints honoured

- Default OFF: flag unset or no sink → drain behaves EXACTLY as before. Verified
  by test (sink wired but gate off → 0 sink calls, placeholder id, note written).
- Behaviour-neutral on deploy (no flag flip; I did not touch Railway).
- Sink failure is non-fatal: note still written with a placeholder id, ingest
  never blocks on the substrate (verified by throwing-sink test).
- Learning-infra (capture/observability), NOT a trade-decision change — does not
  touch sizing / gates / risk / strategy. No Karri gate needed for the build
  itself. Flipping the flag later is also capture-side, not trade-altering.
- Focused diff: committed ONLY the 4 youtube-ingest files. Left code-1's
  in-progress `packages/book-ingest/` and the `package-lock.json` churn UNSTAGED
  and untouched in the worktree. No ADX/regime/indicator code touched (ai-1's lane).

## Verification

- `tsc --noEmit -p packages/youtube-ingest` → clean.
- `tsc --noEmit -p packages/brain-orchestrator` → clean (new exports don't break daemon).
- `tsc --noEmit -p packages/memory-engine` → clean (untouched).
- `vitest run` (youtube-ingest) → 61 passed (was 54; +7 in memory-bridge.test.ts):
  gate off/on, env-flag path, empty transcript, dryRun, graceful sink-failure.

## Operator / follow-up

1. To actually feed the firm, the daemon must wire a real `MemorySink` (see
   docstring) AND flip `YOUTUBE_INGEST_TO_MEMORY=1`. The sink needs a real
   `Distiller` (production wraps Claude Haiku 4.5 per memory-engine §10.1) +
   `bgeM3Embedder` (needs the Ollama bge-m3 backend that the C1-9 / real-embedding
   workstream is standing up). Until that distiller+embedder wiring lands in the
   app layer, the flag has no sink to call.
2. `package-lock.json` shows uncommitted churn in the command-center worktree
   (from code-1's book-ingest npm install) — left for that lane to own.
3. PR / merge gated on operator "OK kjør".

## New tasks surfaced

- App-layer: construct + inject the real `MemorySink` (distiller=Haiku,
  embedder=bge-m3) and gate `YOUTUBE_INGEST_TO_MEMORY` in the daemon.
- Same bridge gap exists for `book-ingest` (currently a types-only shell) and
  likely `github-discovery` → memory. The `MemorySink` seam pattern is reusable.
