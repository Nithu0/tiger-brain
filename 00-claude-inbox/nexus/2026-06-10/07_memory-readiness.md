# Memory subsystem readiness — recall activation map

Date: 2026-06-10
Context: operator "minnehåndtering"-tema + Karri dispatch #3 (`MEMORY_RECALL_ENABLED=false` — firm_memory written but never read).
Scope: READ/ANALYSIS only. No code changed, no flags flipped.

## TL;DR (answers to the three asks)

- **Recall wired-and-ready?** GAP. Code is fully wired and would not crash if flipped, but two things blunt it: (1) the only *trade-decision* consumer (`prismSynthesis`) is **bypassed in ORB_ONLY_MODE**, which is the current production mode — so flipping the flag today changes briefings only, not trades; (2) data-quality gap — `regime` is NULL on ~99% of rows and `thesis` rows have no direction, so recall runs on a thin, lower-fidelity slice.
- **firm_memory row count / growth:** **1819 rows**, actively growing — **+345 last 7d, +45 last 24h**. Oldest 2026-04-15, newest today. NOT stale. Write path is healthy.
- **The one thing to do before flipping recall:** Backfill/populate `regime` (and `direction` on the trade-bearing types) on firm_memory writes so the similarity key actually discriminates. Without it, recall returns the session-only 0.7-similarity path and never the intended 0.9 regime-matched path. This is a Claude-infra fix (write-path enrichment + optional backfill), NOT Karri-gated — it doesn't alter trade decisions, only the quality of what recall *would* surface.

---

## 1. firm_memory — write-only confirmed, recall path audited

**Flag state:** `docs/ref/feature-flags.md` line 121 confirms `MEMORY_RECALL_ENABLED` default `(default-on)`, **current production `false`**. The code only disables on the literal string `"false"` (`firm-memory.ts:126` and `:249`) — so "default-on" is real; production is explicitly opted-out. Karri dispatch #3 is accurate.

**Recall code path (`apps/worker/src/firm/firm-memory.ts`):**
- `recallSimilarSetups()` (structured, Postgres) — line 115. Queries `firm_memory WHERE symbol='XAUUSD' AND direction=$1 AND memory_type IN ('trade','postmortem','thesis')`, optional session/regime filters, falls back to a broader direction-only query if the narrow one is empty. Builds win-rate + best-department + warnings. **Fully wired, would work if flipped.**
- `recallSemanticContext()` (Qdrant) — line 244. Delegates to `searchMemory()` in `services/memory.service.ts`.

**Consumers of recall:**
- `managers.ts:174,191` — `prismSynthesis()`. This is the **trade-decision** path (enriches evidenceFor/evidenceAgainst from historical win-rate). **BUT** `orchestrator.ts:668-670`: in `ORB_ONLY_MODE` the synthesis call is short-circuited to a stub (`prismSynthesis` is never called). ORB_ONLY_MODE is the current production mode. **⇒ Flipping recall today does not touch live trades.**
- `briefing.ts:65` — morning-briefing enrichment (`patternSummary` string). This is observability, runs regardless of ORB-only. **This is the only thing a flip would light up today.**

**Would it work if flipped?**
- Structured recall: YES, no crash. Returns real rows. But fidelity is capped (see data-quality below).
- Semantic recall: CONDITIONAL. `recallSemanticContext` works only if Qdrant is configured AND the collection dimension matches. `memory.service.ts` hard-codes `VECTOR_SIZE=1536` (OpenAI text-embedding-3-small). If `QDRANT_URL` is unset, semantic returns `[]` silently (self-disables). If the collection exists at a different dim, it self-disables with a loud one-shot log. Embeddings come from OpenAI directly (`OPENAI_API_KEY`); fallback is a hash pseudo-vector (useless for similarity). **No similarity index gap in Postgres — recall is a plain SQL filter, not a vector search; the structured path has no embedding dependency at all.** Only the semantic side does.

**Data-quality gap (the real limiter):**
firm_memory breakdown by type:
| type | rows | last_7d | with_pnl |
|---|---|---|---|
| postmortem | 1087 | 175 | 258 |
| regime | 584 | 115 | 0 |
| thesis | 101 | 34 | 0 |
| execution | 47 | 21 | 0 |

Recallable types (`trade`/`postmortem`/`thesis`) field-completeness:
| type | total | has_direction | has_regime | has_session |
|---|---|---|---|---|
| postmortem | 1087 | 258 | **12** | 258 |
| thesis | 101 | **0** | 0 | 0 |

Implications:
- Only **258 postmortems** carry `direction` (the ones from real closed trades via `postmortem-hook.ts`); the other ~829 are direction-NULL cycle/regime postmortems that `recallSimilarSetups` can't match (it filters `direction = $1`).
- `regime` is populated on **12 of 1087** postmortems and **0** thesis rows. Since the high-similarity (0.9) recall path requires both session AND regime, recall will almost always fall to the **0.7 (session-only)** or **0.5 (broad)** path. It works, but never at the fidelity the schema implies.
- `thesis` rows are entirely unreachable (no direction).

So: recall is "wired and won't break", but a flip today would surface a thinner, lower-confidence signal than the design intends — and only into briefings, not trades.

---

## 2. agent_knowledge (YouTube/GitHub ingestion) — empty, ingestion path wired but gated

- **Rows: 0.** Still completely empty. `AGENT_KNOWLEDGE_ENABLED` default false (`flag-echo.ts:50`, `client.ts:22`).
- **Ingestion path:** `scripts/firehose/ingest-youtube.mjs` exists and is real (fetches transcript, distills, chunks, inserts at status=`pending`). It self-gates on `AGENT_KNOWLEDGE_ENABLED==='true'` (or `FIREHOSE_FORCE`). No GitHub ingester in this repo (`scripts/` has only `ingest-youtube.mjs`; GitHub-discovery lives in the command-center brain product, separate).
- **Storage/retrieval:** `agent-knowledge/client.ts` — `ingestChunks` (idempotent replace-on-URL, transactional), `searchByText` (Postgres FTS `ts_rank_cd`, status=`active` only), rating/status CRUD. All gated on the master flag (return empty/no-op when off).
- **Injection into prompts:** `agent-knowledge/injection.ts::buildKnowledgeContext` is double-gated (`AGENT_KNOWLEDGE_ENABLED` AND `KNOWLEDGE_INJECTION_ENABLED`). It IS wired into two firm-agents: `risk-advisor.ts:115` and `trade-critic.ts:70`. So the pipeline is end-to-end (ingest → FTS → prompt-inject) but dormant on the master flag, and there's no content to retrieve anyway.
- **Note:** content default status is `pending`; even with the flag on, retrieval only sees `active` chunks — operator must explicitly activate sources. So this is genuinely operator-gated content curation, not just a flag flip.

**Verdict:** Ingestion path is built and wired; subsystem is empty because nobody has ingested + activated content. Knowledge-injection touches agent *reasoning* prompts (risk-advisor/trade-critic) → if those agents are live, this IS trade-adjacent → Karri-gated for activation, same as recall-into-decisions.

---

## 3. Lesson/memory lifecycle (RAW → DISTILLED → PROMOTED → ARCHIVED)

Two distinct systems share the "memory" word — keep them separate:

**A. agent_lessons (DB, Nexus' own-trade lessons):**
- **7 rows**, oldest 2026-05-21, newest **today** (+4 last 7d, +2 last 24h). The derive-fix (`b59f39a`, capturing redacted derive-lessons stderr) is producing lessons again — trickle, not flood.
- Derivation: `agent-lessons/derive-lessons` + firehose (`apps/api/src/routes/firehose.ts`, `calibration.ts`). Gated by `LESSON_DERIVATION_ENABLED` / `AGENT_LESSONS_ENABLED`.
- Injection: `agent-lessons` `buildLessonContext` IS wired into `risk-advisor.ts:114` and `trade-critic.ts:69` (gated by `LESSON_INJECTION_ENABLED`). Lesson-injection into agent prompts is the operator-principle-6 / Karri-gated trade-altering switch.
- `department_scores`: 773 rows, but slowing (12 last 7d, 1 last 24h) — tracks per-department accuracy, feeds `bestDepartment` in recall.

**B. Obsidian memory lifecycle (`docs/memory/`):** the RAW→DISTILLED→PROMOTED→DEPRECATED→ARCHIVED folders (`daily/`, `promoted/`, `deprecated/`, `archive/`, `PROMOTE_QUEUE.md`) — this is the docs/knowledge-curation lifecycle, not a runtime loop. Runs on session-hooks + manual curation, independent of the trading worker.

**What runs vs dormant now:**
- RUNNING: firm_memory writes (postmortems every closed trade + cycle), regime/thesis/execution memories, department_scores, agent_lessons derivation (post-fix, trickling), Obsidian distillation hooks.
- DORMANT: all *read-back into decisions* — `MEMORY_RECALL_ENABLED=false`, `LESSON_INJECTION_ENABLED` off, `AGENT_KNOWLEDGE_ENABLED` off, `KNOWLEDGE_INJECTION_ENABLED` off. The capture half runs; the consume-into-trades half is dark.

---

## 4. Readiness verdict + the single pre-flip action

**Readiness state: AMBER — wired, write-side healthy, but two gaps make a naive flip low-value-to-misleading.**

What's genuinely **Karri-gated** (trade-altering, do NOT touch):
- Flipping `MEMORY_RECALL_ENABLED=true` *while ORB_ONLY_MODE is off* (i.e. when prismSynthesis is live) — recall then enters trade evidence. Karri owns this.
- `LESSON_INJECTION_ENABLED`, `KNOWLEDGE_INJECTION_ENABLED` — both inject into risk-advisor/trade-critic prompts. Karri.
- Activating `agent_knowledge` content sources (operator/Karri curation).

What's **Claude-infra (safe, not trade-altering), and the one thing to do first:**
- **Populate `regime` (and ensure `direction`) on firm_memory recallable writes, + optional backfill of the 258 directional postmortems.** Right now regime is NULL on 99% of rows, so the recall similarity key can't discriminate and the 0.9 high-confidence path is never reached. Fixing the write-path enrichment (regime is already in scope at the postmortem-hook call site — it's just not being threaded onto the memory row) makes recall *worth* turning on. This changes no trade behaviour (recall is still flag-off); it only raises the quality of what recall would surface once Karri approves the flip. File it as a focused write-path fix, not a strategy proposal.

Secondary (also Claude-infra, lower priority):
- Verify Qdrant config before anyone leans on `recallSemanticContext`: confirm `QDRANT_URL` set and collection dim == 1536, else semantic recall is silently empty. The structured path doesn't need this; only semantic does.
- Note the ORB_ONLY_MODE interaction in the Karri dispatch reply: "recall is dark for trades today not just because of the flag, but because ORB-only bypasses its only trade consumer. Re-enabling recall-into-trades is coupled to exiting ORB_ONLY_MODE." That coupling is the real decision, and it's Karri's.

---

### One-line answers
- **Recall wired-and-ready: GAP** (wired + won't crash; but trade-consumer bypassed under ORB_ONLY_MODE, and regime-NULL data caps fidelity).
- **firm_memory: 1819 rows, +345/7d, +45/24h — actively growing, write-side healthy.**
- **One thing before flipping recall: backfill/enrich `regime` on firm_memory recallable rows (Claude-infra, not Karri-gated) so the similarity match is real; the flip itself into trades stays Karri-gated and is coupled to leaving ORB_ONLY_MODE.**
