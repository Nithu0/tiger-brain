---
name: brain-recall
description: Query brain memory via hybrid RAG (BM25+HNSW+rerank) and return top-K MemoryObjects with source-ref backlinks
tier: brain
project_scope: workspace
when_to_use: operator types "/brain recall ..." OR vague-memory query OR "find that thing about X"
inputs:
  - name: query
    type: string
    required: true
  - name: tier
    type: number
    required: false
    default: 2
  - name: k
    type: number
    required: false
    default: 10
  - name: project
    type: string
    required: false
outputs:
  - hits: array-of-RetrievalResult
  - mrr_estimate: number
harness_tools: [Bash]
system_tools: [curl, jq]
auto_invocable: false
created: 2026-05-25
created_by: operator
confidence: 0.7
validation_passes: 0
version: 0.1.0
related: ["[[SKILL_REGISTRY_SPEC]]", "[[RAG_ENGINE_SPEC]]", "[[Runbook-Brain-Upgrade-Workflow]]"]
tags: [skill, brain, recall, rag]
---

## Purpose

Operator's primary recall surface against the workspace brain. Wraps the command-center `/api/brain/recall` hybrid-RAG endpoint (BM25 + HNSW + cross-encoder rerank, per RAG_ENGINE_SPEC) and surfaces top-K MemoryObjects with verbatim source-ref backlinks. The skill is the standard answer to "I remember we decided X — find me where", "what did Karri say about Y last week", "show me the audit row that triggered Z". Without this surface operator falls back to `rg` across the brain — much slower, no semantic recall, no ranking, and no closed-loop confidence updates.

## When to use

- Operator types `/brain recall <query>` in any firm-launcher pane
- A vague-memory question surfaces mid-session ("the thing about ORB gating", "Karri's note on regime detection")
- Sub-agent needs to ground a claim in prior MemoryObjects before asserting it
- Pre-flight before claiming a task to check if prior knowledge already exists
- **Anti-patterns:** do not use as primary search for active code (use `Grep`/`rg`); do not use for files the operator just edited (cache lag); never call inside a tight loop (rate-limited at T3); never pass secrets in the `query` field (logged in audit)

## Inputs

| Arg | Type | Required | Default | Notes |
|---|---|---|---|---|
| `query` | string | yes | — | Natural-language recall query; max 512 chars |
| `tier` | number | no | 2 | Retrieval tier 1-3 (1=fast BM25 only, 2=hybrid+rerank, 3=agentic multi-hop) |
| `k` | number | no | 10 | Top-K results to return; capped at 50 |
| `project` | string | no | — | Optional scope filter: `nexus`, `thesis`, `as`, `personlig`, `command-center`, etc. |

## Steps

1. Parse `query`, `tier`, `k`, `project` from skill args; reject empty `query` early
2. Build POST body: `{ "query": "<text>", "tier": <n>, "k": <n>, "project": "<optional>" }` — omit `project` key when not provided
3. POST to `http://127.0.0.1:3100/api/brain/recall` with `content-type: application/json`
4. Parse JSON response — expected shape: `{ hits: [{ verbatim_row_id, exchange_core, source_ref, score, project, tier_used }], mrr_estimate: <float> }`
5. For each hit, render one block: `[ref:<verbatim_row_id>]` link + `exchange_core` (1-3 sentences) + `source_ref` path/URL + score badge
6. Print `mrr_estimate` footer so operator can gauge result quality at a glance
7. If response status `503`, surface "rag-engine not implemented (code-1 C1-4 pending)" and fall back to a `rg -n "$query" ~/Obsidian/Brain/` hint
8. If response status `400`, echo the validation error verbatim (most common: empty query or `tier` out of range)

## Tools / commands

```bash
# Manual invocation (operator copy-pasteable)
QUERY="ORB gating decision Karri"
curl -sS -X POST http://127.0.0.1:3100/api/brain/recall \
  -H 'content-type: application/json' \
  -d "$(jq -n --arg q "$QUERY" '{query:$q, tier:2, k:10}')" \
  | jq -r '.hits[] | "[ref:\(.verbatim_row_id)] \(.exchange_core)\n  -> \(.source_ref) (score=\(.score))"'

# With project scope
curl -sS -X POST http://127.0.0.1:3100/api/brain/recall \
  -H 'content-type: application/json' \
  -d '{"query":"regime detection","tier":2,"k":5,"project":"nexus"}' \
  | jq '.'

# Health-check the endpoint before relying on it
curl -sS -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3100/api/brain/recall
```

## Pitfalls

- 503 response — rag-engine not yet implemented (code-1 module C1-4 pending per brain-upgrade-plan); fall back to `rg` until shipped
- 400 response — usually empty `query`, `tier` outside 1-3, or `k` > 50; echo the validator message verbatim
- Rate-limit on T3 — agentic multi-hop is expensive; orchestrator caps T3 at 10/hour per pane; downgrade to tier=2 if hit
- Cache lag — MemoryObjects from the last hour may not yet be indexed (HNSW rebuild every 15 min); warn operator if query relates to very recent work
- Secret leakage — `query` is logged in `agent_audit`; never embed API keys or `.env` values in the query string

## Validation checks

1. POST returns HTTP 200 with `hits` array (may be empty for no-match — still valid)
2. Each hit has all four fields: `verbatim_row_id`, `exchange_core`, `source_ref`, `score`
3. `mrr_estimate` is a float in `[0.0, 1.0]`
4. `len(hits) <= k` (server enforces cap)
5. Random-sample one hit weekly: click `source_ref`, confirm `exchange_core` faithfully summarizes the source

## Example usage

```
/brain recall query="ORB gating Karri decision" tier=2 k=5
```

Sample output:

```
[ref:mo_2026-05-19_847] Karri vetoed auto-enable of ORB gate after 3 consecutive losing days; operator agreed, set manual-only.
  -> 01-nexus/_decisions/2026-05-19-orb-gate-manual-only.md (score=0.91)

[ref:mo_2026-05-12_412] ORB gate logic moved from foundation-tier to TIER 3 stack after backtest showed 12bps slippage.
  -> 01-nexus/postmortems/2026-05-12-orb-tier-move.md (score=0.84)

...
mrr_estimate: 0.78
```

Scoped to a single project:

```
/brain recall query="electrolyte conductivity model" project=thesis k=3
```

## Related

- [[SKILL_REGISTRY_SPEC]]
- [[RAG_ENGINE_SPEC]]
- [[Runbook-Brain-Upgrade-Workflow]]
- [[MEMORY_DISTILLATION_SPEC]]
- [[brain-distill-daily]]
