---
task_id: T-2026-05-25-001
title: Implement RAG semantic-chunker (LLM-as-chunker via Haiku 4.5)
from: operator
to: code-1
owner: unclaimed
project: command-center
branch: code-1/rag-semantic-chunker
files_allowed:
  - packages/rag-engine/src/chunking/semantic.ts
  - packages/rag-engine/tests/semantic-chunker.test.ts
objective: Build packages/rag-engine/src/chunking/semantic.ts that takes a long-form text + returns array of {text, topic_label} chunks. LLM split via Haiku 4.5 at topic boundaries.
expected_output:
  - semantic.ts compiles + exports default chunker function
  - 5 unit tests pass (short text, long text, edge cases, multilingual NO/EN, code-block preservation)
  - smoke test: chunk this brain note (~6000 lines) returns 50-200 chunks with topic_labels
tests:
  - npm -w @cc/rag-engine test -- chunking/semantic
  - npm -w @cc/rag-engine run typecheck
rollback: revert PR
status: open
sla_seconds: 14400
priority: medium
spec_blocker: RAG_ENGINE_SPEC §3
related:
  - "[[RAG_ENGINE_SPEC]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
tags: [task, rag, chunking, code-1]
created_at: "2026-05-25T14:50:00Z"
claimed_at: null
claimed_by: null
finished_at: null
---

## Purpose

Implement strategy (a) — LLM-as-chunker — from `[[RAG_ENGINE_SPEC]]` §3.1.1. This is the primary chunking strategy for YouTube transcripts, GitHub READMEs, long-form documents (>5k tokens), and retrospectives. The chunker uses Claude Haiku 4.5 (cheap-and-fast) to split source text at topic boundaries and emit a JSON array of `{topic_label, chunk_text}` objects. Output conforms to the `SemanticChunk` type defined in spec §3.1.1. This is the entry-point chunker the rest of the Tier 2 pipeline depends on; without it, hybrid retrieval (§3.2) has nothing to embed.

## Acceptance criteria

- `packages/rag-engine/src/chunking/semantic.ts` exports a default async function `semanticChunk(text: string, source_id: string, opts?: {model?: string, cost_cap_usd?: number}): Promise<SemanticChunk[]>`.
- Returned chunks honour the `SemanticChunk` shape exactly: `{chunk_id, source_id, topic_label, content, token_count, method: "llm-chunker"}`.
- Chunks are 200–800 tokens. Post-processing re-splits over-long chunks and merges under-short adjacent ones.
- Topic labels are LLM-generated, ≤ 8 words, ASCII-clean.
- Cost cap of $0.01 USD per source is enforced; abort with a `CostCapExceededError` if exceeded (caller falls through to strategy (b) per §3.1.4).
- 5 unit tests pass (see Test plan below).
- Smoke test: chunking `RAG_ENGINE_SPEC.md` (~700 lines) returns between 20 and 100 chunks, each with a non-empty `topic_label`.
- `npm -w @cc/rag-engine run typecheck` passes with zero errors.

## Implementation notes

- **Model:** `claude-haiku-4-5` (per spec §3.1.1). Use the `@anthropic-ai/sdk` package with `ANTHROPIC_API_KEY` env var. Enable prompt caching on the system prompt — chunking is high-volume.
- **Prompt:** instruct the model to read the source and return only valid JSON: `[{topic_label: "...", chunk_text: "..."}]`. Provide an example in the system prompt. Use `response_format: json` if supported, else parse + retry-once on JSON-parse failure.
- **Token counting:** use `@anthropic-ai/tokenizer` or a tiktoken approximation. Re-split over-long chunks by paragraph; merge under-short adjacent chunks if `topic_label` similarity (lowercase substring overlap) > 0.5.
- **Chunk IDs:** `${source_id}::chunk::${index.toString().padStart(4, "0")}`. Deterministic for the same input.
- **Code-block preservation:** when the source contains fenced code blocks (` ``` `), never split inside one. Pre-process: identify code-block spans; pass them as atomic units to the LLM prompt with explicit "do not split fenced blocks" instruction.
- **Cost cap:** estimate input tokens × Haiku input price + expected output tokens × output price. Abort before the LLM call if estimate exceeds the cap. The Haiku 4.5 price as of 2026-05 is ~$0.0008 per 1K input / $0.004 per 1K output (verify in code-comments, not hard-coded if a price-table util exists).
- **Errors:** export `CostCapExceededError`, `LLMResponseError`, `ChunkSizeError`. Caller in `chunking/index.ts` catches and falls through to strategy (b).

## Test plan

1. **Short text (<200 tokens):** returns exactly 1 chunk; `topic_label` matches first sentence theme.
2. **Long text (~6000 tokens):** returns 8–30 chunks; all within 200–800 token bounds; no overlap, no gaps.
3. **Edge: empty string input:** throws `TypeError` (not silent return of empty array).
4. **Multilingual (Norwegian Bokmål + English mixed):** topic labels correctly produced in dominant language of each chunk; no language-boundary splits inside a single semantic block.
5. **Code-block preservation:** source containing 3 fenced code blocks — each block ends up fully inside exactly one chunk; no chunk splits mid-block. Assert by regex-counting opening vs closing fences per chunk.

## Files to create

- `packages/rag-engine/src/chunking/semantic.ts` — the chunker.
- `packages/rag-engine/tests/semantic-chunker.test.ts` — 5 unit tests + 1 smoke test.

Both files must respect the existing `packages/rag-engine/` tsconfig + vitest config. Do not modify the package `index.ts` exports surface — that is owned by a separate task (T-2026-05-25-XXX, future).

## Notes

<!-- operator/peer can add inline notes here as the task progresses -->
