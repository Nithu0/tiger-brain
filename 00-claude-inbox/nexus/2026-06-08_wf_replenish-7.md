# WF lane replenish-7 — Claude-Haiku transcript distiller (knowledge-ingest)

Date: 2026-06-08
Branch: `feat/wf-knowledge-ingest-llm-distill` (commit `cc24d82`)
Status: BUILT, committed on branch, NOT pushed/merged. Flag default-OFF, deploy behaviour-neutral.

## Task
S3 BUILD: swap the deterministic transcript distiller for a Claude-Haiku distiller
behind `YOUTUBE_INGEST_LLM_DISTILL=0`, keeping a >10-word verbatim guard as a hard
post-check.

## Reality vs the task wording
The task referenced `distillTranscript` as if it already existed. It did not.
The actual knowledge-ingest pipeline lives in `scripts/firehose/` (pure Node ESM
`.mjs`, no Anthropic SDK), NOT in `packages/`. The "deterministic distiller" was
just the inline `chunkText()` + `cleanVtt()` flow in `ingest-youtube.mjs`, and there
was no verbatim guard at all. So I introduced the named API the task assumes, with
the deterministic path preserved exactly as the default.

## What landed
- `scripts/firehose/lib/distill.mjs` (new):
  - `distillTranscript(transcript, opts)` — selects deterministic vs LLM path by
    the env flag (`YOUTUBE_INGEST_LLM_DISTILL === "1"`). Default OFF.
  - `chunkText()` — extracted verbatim from `ingest-youtube.mjs`, so the OFF path
    is byte-identical to the historical pipeline.
  - `distillViaLlm()` — raw `fetch` against the Anthropic Messages REST API
    (`https://api.anthropic.com/v1/messages`, `anthropic-version: 2023-06-01`,
    `x-api-key`), model `claude-haiku-4-5`. No SDK dependency — mirrors the
    existing `lib/embeddings.mjs` raw-fetch style.
  - `assertVerbatimGuard()` + `longestVerbatimRun()` — HARD post-check: rejects any
    distilled chunk that copies MORE THAN 10 consecutive words verbatim from the
    source transcript (n-gram match on lowercased, punctuation-stripped tokens).
  - Fallback policy: on guard trip OR any LLM/HTTP/config failure →
    fall back to the deterministic chunker, never throw out of the pipeline
    (operator-prinsipp 2: data never stops). Return tag is
    `deterministic` / `llm` / `deterministic-fallback`.
- `scripts/firehose/ingest-youtube.mjs`: removed the inline `chunkText`, imports
  `distillTranscript`, calls it in `main()` (already async), passes pre-computed
  `chunks` into `ingest()`. Logs the chosen method.
- `scripts/firehose/lib/distill.test.mjs` (new): 16 `node:test` cases — flag
  defaults, model override, chunker behaviour, verbatim-guard primitives
  (11-word copy tripped, 10-word overlap allowed, paraphrase clean), and
  orchestration including fallback-on-guard-trip and fallback-on-LLM-error.

## Flags (all default-OFF / safe)
- `YOUTUBE_INGEST_LLM_DISTILL=1` — enable the LLM distill path
- `YOUTUBE_INGEST_LLM_MODEL=...` — model override (default `claude-haiku-4-5`)
- `ANTHROPIC_API_KEY` — required ONLY when the LLM path is enabled

## Verification
- `node --test scripts/firehose/lib/distill.test.mjs` → 16/16 pass
- `node --test scripts/firehose/lib/*.test.mjs` → 48/48 pass (no regression)
- `node --check scripts/firehose/ingest-youtube.mjs` → OK; module import OK
- pre-commit hook ran, skipped tsc (no staged TS — these are `.mjs` in `scripts/`)
- OFF path proven byte-equivalent to old `chunkText` by test assertion

## Coordination / scope hygiene
- Did NOT touch ADX/regime/indicator code (ai-1 owns that P0).
- Did NOT touch strategy/risk/gates. This is learning-infra (knowledge
  capture/distill), which ships freely per the continuous-learning boundary —
  it does not alter trade decisions, so no Karri gate.
- Staged ONLY my 3 files; other lanes' in-flight changes (`apps/api/*`, `docs/*`,
  another lane's `firm-memory-strategy-states.test.ts`) were left unstaged.
- The firehose `.test.mjs` files are NOT wired into the worker suite or CI; they
  run ad-hoc via `node --test`. Follow-up worth considering: add a `scripts/firehose`
  test entry to CI so this guard is enforced on every push.

## Caveats
- The LLM path is untested against the live Anthropic API in this run (no key
  exercised; all LLM tests use an injected `llmFn`). First real enable should be
  smoke-tested with one transcript + `YOUTUBE_INGEST_LLM_DISTILL=1`.
- `docs/ref/feature-flags.md` was already modified by another lane, so I did not
  add the new flags there to avoid a collision — they're documented in the commit
  body and here. Worth folding into feature-flags.md once that lane lands.
