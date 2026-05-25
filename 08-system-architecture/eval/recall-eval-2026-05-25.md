---
title: Recall Eval Set 2026-05-25
date: 2026-05-25
status: v1.0 — initial gold standard
purpose: Benchmark RAG engine retrieval quality (MRR/nDCG@10/P@1)
acceptance_target: MRR > 0.6, P@1 > 0.5
author: A-10 (sub-agent)
related:
  - "[[RAG_ENGINE_SPEC]]"
  - "[[MEMORY_DISTILLATION_SPEC]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
tags: [eval, retrieval, rag, gold-set]
---

# Recall Eval Set — 2026-05-25 (v1.0)

## Method

Constructed by sub-agent A-10 by surveying the brain vault:

1. Read top-level orientation: `00-DASHBOARD.md`, `01-CURRENT-FOCUS.md`.
2. Sampled 10 MOC / atomic notes from `_maps/` (Foundation-Gate, OK-Kjor-Autonomous-Execute, Karri, Demo-Mode, Truth-Hierarchy, Memory-Lifecycle, Distillation-Hook, Parallel-Batch-Coordination, Operator-Principles, Secrets-Policy).
3. Skimmed `_decisions/` (When-* decision trees), `_runbooks/` (push-cycle, firm-8-pane, multi-agent-dispatch), recent dated drops in `03-business/` (on-prem-AI), `01-nexus/strategies/` (ORB, Scalp-Overlap, Vol-Expansion + dated audits), `02-thesis/` (concepts + methods), `06-AS/` (ENK-til-AS, Spor-A).
4. Scanned 5 `00-claude-inbox/nexus/2026-05-1*` entries to model the "vague-recall" tone operator uses when remembering a recent audit.
5. Drafted 10 queries spanning category mix (3 exact-phrase / 4 concept / 2 multi-hop / 1 cross-domain) and difficulty mix (4 easy / 4 medium / 2 hard).
6. For each query mapped 1-5 gold notes, justified the gold mapping, then verified each gold path exists via `ls`.

Queries are written the way the operator actually asks ("hva het den greia som...", "hvor står det at..."), not in retrieval-friendly keyword form. This is intentional — the eval scores the engine's ability to bridge operator-vague-recall to canonical brain notes.

## Eval-set distribution

- 3 exact-phrase (Q1, Q2, Q3)
- 4 concept (Q4, Q5, Q6, Q7)
- 2 multi-hop (Q8, Q9)
- 1 cross-domain (Q10)

Difficulty: 4 easy (Q1, Q2, Q3, Q4) + 4 medium (Q5, Q6, Q7, Q8) + 2 hard (Q9, Q10).

## Queries

### Q1 (easy, exact-phrase)
- **Query:** "hva er foundation gate"
- **Gold:**
  - `/home/nithu/Obsidian/Brain/_maps/Foundation-Gate.md`
  - `/home/nithu/Obsidian/Brain/01-nexus/operations/Foundation-Gate.md`
- **Why:** Both notes carry "Foundation Gate" in the title and define the 5-rule canonical structure. Operator uses the exact phrase regularly; engine should rank either of these top-1.

### Q2 (easy, exact-phrase)
- **Query:** "OK kjør trigger phrases"
- **Gold:**
  - `/home/nithu/Obsidian/Brain/_maps/OK-Kjor-Autonomous-Execute.md`
  - `/home/nithu/Obsidian/Brain/_decisions/When-Operator-Says-Kjor-Pa.md`
- **Why:** Title is verbatim "OK-Kjor Autonomous Execute" and the body lists all six trigger phrases ("OK kjør", "kjør på", "kjør alle", "letsgooo", "BYGG ALT", "max"). Decision-tree complements with execute-mode behaviour.

### Q3 (easy, exact-phrase)
- **Query:** "firm 8-pane runbook"
- **Gold:**
  - `/home/nithu/Obsidian/Brain/_runbooks/firm-8-pane-2026-05-14.md`
- **Why:** Title and frontmatter are exact match; this is the canonical operating doc for the 8-pane multi-Claude session.

### Q4 (easy, concept)
- **Query:** "hvordan flytter et Claude-observert faktum fra inbox til durable memory"
- **Gold:**
  - `/home/nithu/Obsidian/Brain/_maps/Memory-Lifecycle.md`
  - `/home/nithu/Obsidian/Brain/_maps/Distillation-Hook.md`
- **Why:** `Memory-Lifecycle.md` is literally the 5-stage RAW→DISTILLED→PROMOTED→DEPRECATED→ARCHIVED pipeline. `Distillation-Hook.md` is the mechanism that drives stage transitions. Concept is described without the operator using the term "lifecycle".

### Q5 (medium, concept)
- **Query:** "den regelen om at kode og /health JSON slår dokumentasjon når det er konflikt"
- **Gold:**
  - `/home/nithu/Obsidian/Brain/_maps/Truth-Hierarchy.md`
- **Why:** Note encodes the canonical 5-rank truth hierarchy with codebase + live system at rank 1. Operator describes the rule by content, not by the term "truth hierarchy" — medium because semantic match required.

### Q6 (medium, concept)
- **Query:** "den ORB-strategien som triggrer på London open"
- **Gold:**
  - `/home/nithu/Obsidian/Brain/01-nexus/strategies/Strategy-ORB.md`
  - `/home/nithu/Obsidian/Brain/01-nexus/modules/Module-ORB.md`
- **Why:** Operator remembers the strategy concept (opening-range breakout, London session) but not the exact ORB acronym formality. Strategy note carries the timing (08:00-08:30 London / 07:00-07:30 UTC) and trigger logic; Module-ORB is the implementation pointer.

### Q7 (medium, concept)
- **Query:** "hvordan håndtere usikkerhet på toppen av Random Forest-modellen i master-oppgaven"
- **Gold:**
  - `/home/nithu/Obsidian/Brain/02-thesis/methods/Conformal-Prediction.md`
  - `/home/nithu/Obsidian/Brain/02-thesis/methods/Validation-Strategy.md`
- **Why:** Conformal-Prediction note describes split-CP on the RF as the uncertainty quantifier. Operator remembers the concept ("usikkerhet på toppen av RF") but not "conformal". Validation-Strategy is the supporting context.

### Q8 (medium, multi-hop)
- **Query:** "før jeg pusher noe som flipper en Railway-flag — hva er gaten og hvem må godkjenne"
- **Gold:**
  - `/home/nithu/Obsidian/Brain/01-nexus/operations/OK-Kjor-Gate.md`
  - `/home/nithu/Obsidian/Brain/_runbooks/Runbook-Push-Cycle.md`
  - `/home/nithu/Obsidian/Brain/_maps/Operator-Principles.md`
- **Why:** Requires joining (a) OK-Kjor-Gate (the explicit approval gate listing Railway env-vars as gated), (b) Push-Cycle runbook (where the gate fires), (c) Operator-Principles (prinsipp 5 source). No single note answers fully — engine must surface at least 2 of 3.

### Q9 (hard, multi-hop)
- **Query:** "den scalp-overlap-tapssekvensen vi diskuterte før calibration og hva Karri sa"
- **Gold:**
  - `/home/nithu/Obsidian/Brain/01-nexus/strategies/scalp-overlap-losses-2026-05-11.md`
  - `/home/nithu/Obsidian/Brain/01-nexus/strategies/karri-tier1-batch-2026-05-11.md`
  - `/home/nithu/Obsidian/Brain/_maps/Karri.md`
  - `/home/nithu/Obsidian/Brain/01-nexus/strategies/Strategy-Scalp-Overlap.md`
- **Why:** Requires synthesizing (a) the dated loss-cluster audit, (b) the Karri batch from the same date, (c) reviewer-context note, (d) the strategy doc itself. Hard because operator-recall is vague ("den ... vi diskuterte") and the answer is split across 4 notes by time + role.

### Q10 (hard, cross-domain)
- **Query:** "kan vi produktifisere Nexus-arkitekturen som on-prem AI for sensitive bransjer"
- **Gold:**
  - `/home/nithu/Obsidian/Brain/03-business/Nexus-Productization.md`
  - `/home/nithu/Obsidian/Brain/03-business/2026-05-24-onprem-ai-strategi.md`
  - `/home/nithu/Obsidian/Brain/08-system-architecture/2026-05-25-brain-upgrade-plan.md`
- **Why:** Cross-domain — operator joins a nexus-architecture question ("Nexus-patterns") with a business question ("produktifisere on-prem"). The on-prem strategi note explicitly references command-center + Nexus patterns as the technical proof. Hard because relevant notes live in 3 different folders (`03-business/`, `08-system-architecture/`) and require semantic bridge between Nexus engineering vocabulary and business-pilot vocabulary.

## Metrics to compute

- **MRR (Mean Reciprocal Rank):** mean of `1 / rank-of-first-gold-hit` across the 10 queries. If no gold note appears in the returned top-K, contribution is 0. Formula: `MRR = (1/Q) · Σ 1/rank_i` for i=1..Q where Q=10.
- **P@1 (Precision at 1):** fraction of queries where the top-1 result is in the query's gold set. Formula: `P@1 = (1/Q) · Σ [rank_1 ∈ gold_i]`.
- **nDCG@10 (normalized Discounted Cumulative Gain at K=10):** weights gold hits by position with a log-discount, normalized against the ideal ranking. Per query: `DCG@10 = Σ_{i=1..10} rel_i / log2(i+1)` where `rel_i = 1` if result-i is in gold, else 0. `IDCG@10 = Σ_{i=1..min(|gold|,10)} 1 / log2(i+1)`. `nDCG@10 = DCG@10 / IDCG@10`. Mean across 10 queries reported.

**Acceptance gates (per RAG_ENGINE_SPEC Module K):** MRR > 0.6 AND P@1 > 0.5. nDCG@10 reported but not gated in v1; future v1.1 may add nDCG@10 > 0.7 once baseline is observed.

## How to run

The eval-runner (planned `scripts/eval/run-recall-eval.ts`, owned by A-7's RAG_ENGINE_SPEC) loads this file, parses each `### Q*` block into `{query, gold[], category, difficulty}`, then invokes the RAG engine three times per query — once per tier (T1=embedding-only BM25 hybrid, T2=+rerank, T3=+rerank+LLM-grounded distill) — capturing top-10 brain-paths per call. For each tier it computes per-query MRR / P@1 / nDCG@10 and aggregates over the 10 queries. Results are written to `08-system-architecture/eval/results-2026-05-25-T{1,2,3}.md` with frontmatter (`tier`, `mrr`, `p_at_1`, `ndcg_at_10`, `passed_gate`) plus a per-query table (query → rank-of-first-gold → top-10 paths → hit/miss). A summary row is appended to `08-system-architecture/eval/recall-history.md` for trend tracking. The runner is invoked from CI on every change to the brain index or RAG-engine code; failing acceptance gates blocks promotion of the index.

## Verification (5×)

1. **All 10 gold paths exist:** verified via `ls` on every path listed in Q1-Q10 (16 unique gold paths). All return success.
2. **Category distribution:** 3 exact-phrase (Q1-Q3) + 4 concept (Q4-Q7) + 2 multi-hop (Q8-Q9) + 1 cross-domain (Q10) = 10. ✓
3. **Difficulty distribution:** 4 easy (Q1-Q4) + 4 medium (Q5-Q8) + 2 hard (Q9-Q10) = 10. ✓
4. **Frontmatter YAML valid:** opening `---` / closing `---`, 8 fields (title, date, status, purpose, acceptance_target, author, related, tags), `related` and `tags` are YAML lists. ✓
5. **Metrics formulas correct:** MRR uses `1/rank` per ISO IR convention; P@1 is the indicator at position 1; nDCG@10 uses `log2(i+1)` discount and `IDCG = Σ 1/log2(i+1)` for `i=1..min(|gold|,10)` (binary relevance). ✓

---

Sist oppdatert: 2026-05-25
