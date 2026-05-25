---
title: Pre-distill manifest — 2026-05-25
date: 2026-05-25
status: v1.0 (initial backlog)
purpose: Order of bulk-distillation when memory-engine is ready (depends on code-1 C1-2/3)
related: ["[[MEMORY_DISTILLATION_SPEC]]", "[[RAG_ENGINE_SPEC]]", "[[2026-05-25-brain-upgrade-plan]]"]
tags: [manifest, distillation, backlog]
---

# Pre-distill manifest — bulk-load order

When `@cc/memory-engine` (code-1's C1-2 / C1-3 lanes) lands and `/skill brain-distill-daily` becomes invocable, this manifest gives the operator and the BrainOrchestrator an ordered backlog for the **one-shot historical bulk-load** of the existing brain into the verbatim + distilled SQLite store defined in `[[MEMORY_DISTILLATION_SPEC]]` §5-6.

Order is by **retrieval-value** (= probability the operator asks recall queries that should hit these), not by file age or folder size. Each tier is independently invocable; later tiers do not depend on earlier ones, only on memory-engine itself.

All file counts below were enumerated against the live vault on 2026-05-25 — see §"Counts verified" at bottom.

---

## Tier S — distill immediately (operator-critical recall)

These 5 files dominate "what did we decide / what's the current state" queries. Hand-curated; do not bulk-expand. Each must produce ≥1 MemoryObject; large ones split at H2 per spec §8.1.c.

| File | Why high-value | Project |
|---|---|---|
| `[[2026-05-25-brain-upgrade-plan]]` (`08-system-architecture/`) | Just-built workspace AI-OS — governs every module under construction | command-center |
| `[[2026-05-24-onprem-ai-strategi]]` (`03-business/`) | On-prem AI strategy v1.0, 909 lines, 10-agent synthesis | business |
| `[[01-CURRENT-FOCUS]]` (`Brain/`) | Operator's live TODO + priorities | meta |
| `[[Foundation-Gate]]` (`01-nexus/operations/`) | Nexus go/no-go binding rule | nexus |
| `[[Phase-Status-Pointer]]` (`_decisions/`) → mirrored from `ai-assistent/docs/ops/Phase-status.md` | Live Nexus phase state | nexus |

**Estimate:** 5 source files → ~30 MemoryObjects (large docs split per spec §8.1.c — `2026-05-25-brain-upgrade-plan.md` alone ~50KB and will produce ~15 chunks).

---

## Tier A — distill in batch 2 (decisions + runbooks)

Both folders are dense, immutable / operationally-canonical. High recall-query value: "hva besluttet vi om X" and "hvordan gjør jeg Y".

| Folder | Real count (verified) | Why distill |
|---|---|---|
| `_decisions/` | **15 files** | Immutable operator-binding decisions. Every recall query about "skal vi …" should hit these first. |
| `_runbooks/` | **18 files** | "How do I X?" procedural recall (1 more than the spec's `17 procedures` note — `Runbook-Brain-Upgrade-Workflow.md` was added 2026-05-25). |

**Files in `_decisions/` (15):** `2026-05-14-16-pane-codex-parallell.md`, `2026-05-14-control-plane-proposal.md`, `2026-05-14-job-scrape-feasibility.md`, `2026-05-14-nav-feed-verification.md`, `Operator-Principles.md`, `When-Agent-Stalls.md`, `When-Brain-Structure-Drifts.md`, `When-Day-Hits-Overtrading-Pattern.md`, `When-Doc-Drifts-From-Code.md`, `When-Foundation-Rule-Goes-Yellow.md`, `When-Gate-Goes-Silent.md`, `When-Operator-Says-Kjor-Pa.md`, `When-Quota-Blocks-Pipeline.md`, `When-Strategy-Change-Tempting.md`, `When-Trade-Bleeds-Multi-Day.md`.

**Files in `_runbooks/` (18):** `Runbook-Backfill-Script-Pattern.md`, `Runbook-Brain-Post-Push-Cleanup.md`, `Runbook-Brain-Upgrade-Workflow.md`, `Runbook-Brain-Weekly-Maintenance.md`, `Runbook-Branch-Protection.md`, `Runbook-Karri-Proposal-Send.md`, `Runbook-Multi-Agent-Dispatch.md`, `Runbook-Obsidian-Git-Sync.md`, `Runbook-Obsidian-Workspace-Drift.md`, `Runbook-Post-Deploy-Verification.md`, `Runbook-Push-Cycle.md`, `Runbook-Quota-Upgrade.md`, `dashboard-runbook.md`, `firm-8-pane-2026-05-14.md`, `firm-launcher.md`, `git-worktree-workflow.md`, `job-scraper-runbook.md`, `operator-action-handoff.md`.

**Estimate:** 33 source files (15+18) → **~200 MemoryObjects** (avg 6 chunks per file; runbooks tend to be larger than decisions).

---

## Tier B — distill in batch 3 (per-project MOCs)

MOCs index everything else, so they appear as direct hits OR as bridge-hits in the agentic retrieval loop (`[[RAG_ENGINE_SPEC]]` §4.6).

**Real count: 21 MOC files total** — split between `_maps/` (12 cross-cutting) and project-roots (9 per-project).

`_maps/` (12 files):
- `[[Decisions-MOC]]`
- `[[Github-Repos-MOC]]`
- `[[Memory-MOC]]`
- `[[People-MOC]]`
- `[[RAG-MOC]]`
- `[[Retrospectives-MOC]]`
- `[[Skills-MOC]]`
- `[[System-Architecture-MOC]]`
- `[[Tasks-MOC]]`
- `[[Tools-MOC]]`
- `[[Workflows-MOC]]`
- `[[Youtube-MOC]]`

Project-root MOCs (9 files):
- `[[Nexus-MOC]]` (`01-nexus/`)
- `[[Thesis-MOC]]` (`02-thesis/`)
- `[[Business-MOC]]` (`03-business/`)
- `[[Career-MOC]]` (`04-career/`)
- `[[Active-Job-Search-MOC]]` (`04-career/`)
- `[[Learning-MOC]]` (`05-learning/`)
- `[[AS-MOC]]` (`06-AS/`)
- `[[Personlig-MOC]]` (`07-personlig/`)
- (1 stub slot reserved for any MOC added between manifest-write and execution — re-enumerate at distill-time.)

**Note:** the original spec mentioned "8 new MOCs from B-6 + D-4" — those work-streams have not yet emitted MOC files as of 2026-05-25. Re-enumerate `find Brain -maxdepth 4 -name "*-MOC.md"` before invoking tier B to pick up any new ones.

**Estimate:** 21 MOC files → **~80 MemoryObjects** (MOCs are mostly link-tables; few chunks each).

---

## Tier C — distill in batch 4 (recent dated content)

Recent dated content gets distilled with shorter `expires_at` (per spec §2 `MemoryObject.expires_at`) where appropriate — runtime-state especially.

| Source | Real count | Notes |
|---|---|---|
| `00-claude-inbox/` (recursive) | **223 .md files total** | Bulk verification/audit drops. Filter to **last 30 days** for initial pass (~150 estimated). |
| `01-nexus/runtime-state/` | **11 files** | Set short `expires_at` (e.g. "active branch" stale by next merge). |
| `handoffs/` | **5 files** | Session/day-end handoffs. All in. |

**Filter rule for inbox:** apply `created_at >= now() - 30d` at walk-time to skip stale audits. If operator wants full inbox-history later, run with `--since 2025-01-01`.

**Estimate:** ~166 source files → **~250 MemoryObjects** (inbox docs are short; runtime-state often single-chunk).

---

## Tier D — distill on-demand (low-priority)

Everything else under the include-set from spec §8.1: project folders (`01-nexus/**`, `02-thesis/**`, …, `07-personlig/**`), `08-system-architecture/specs/`, older inbox drops (>30d), older handoffs, `12-youtube/` summaries (not transcripts), `13-github-repos/` notes.

**Approximate scope:** ~350 remaining .md files (total relevant corpus = **570 .md files** counted at write-time, minus Tier S/A/B/C ≈ 225).

Run this tier only when operator triggers `/skill brain-distill-daily mode=manifest tier=D` — never auto.

---

## Excluded from distillation (binding)

Per spec §8.1 EXCLUDE rules, plus operator hygiene:

- `~/Obsidian/Brain/.git/` — git internals
- `~/Obsidian/Brain/.obsidian/` — Obsidian config
- `~/Obsidian/Brain/_library/youtube/*/transcript.txt` — already verbatim by design; would double-store
- `~/Obsidian/Brain/_library/raw/**` — same reason
- `~/Obsidian/Brain/_library/memory-backups/**` — DB-backup target (writing here would create recursion)
- `~/Obsidian/Brain/90-archive/**` — cold storage, unless operator restores
- `~/Obsidian/Brain/00-firm-bus/feed.md` — low-signal high-churn
- `~/Obsidian/Brain/00-firm-bus/PRESENCE.md` — ephemeral
- Any file with frontmatter `distill: false`
- Any file with frontmatter `sensitive: true` (route through sensitive-only flow per `[[MEMORY_DISTILLATION_SPEC]]` SourceType union)

---

## Total estimated MemoryObjects

| Tier | Source files | Est. MemoryObjects |
|---|---|---|
| S | 5 | ~30 |
| A | 33 (15 + 18) | ~200 |
| B | 21 | ~80 |
| C | ~166 | ~250 |
| **Bulk-load (S+A+B+C)** | **~225** | **~560** |
| D (on-demand) | ~350 | ~1 400 |

Verbatim layer: every included source-file inserts at least one `verbatim_exchanges` row regardless of distill outcome.

---

## Throughput estimate (assumptions explicit)

**Per-distill latency:** Haiku 4.5 at ~3-5s per call with prompt caching (system prompt cached after first call per spec §3.1). Concurrency: 4-8 parallel calls before hitting per-minute rate-limit.

**Single-stream:** ~560 / (1 call per ~4s) = ~37 min wall-clock.
**4 parallel:** ~10 min wall-clock.
**8 parallel (hit rate-limit; backoff kicks in):** ~7-8 min wall-clock.

The operator-spec line "~10 distillations/sec" is **optimistic** — that would require sub-100ms Haiku turnaround which Anthropic does not deliver today (typical Haiku 4.5 generation is 50-150 tokens/s, prompt+output ≈ 800 tokens per distill). Revised honest estimate: **~10-15 minutes for full S+A+B+C bulk load** at 4-8 parallel.

**Storage:** ~30 MB SQLite at 560 MemoryObjects + verbatim bodies + bge-m3 embeddings (1024-dim × 4 bytes × 560 = 2.3 MB just for vectors). Tier D adds ~80 MB if executed.

**Cost:** ~560 × ~800 tokens × ($0.80 / 1M input + $4 / 1M output) ≈ **~$2-3 USD** for full bulk-load. Cheap.

---

## Operator approval needed before

Per `~/.claude/CLAUDE.md` "Operator-gated actions" + spec §8.1 step 4:

- **Tier A bulk** — touches `_decisions/` which is immutable. Distill creates separate `memory_objects` rows; original .md files are never touched, but explicit OK kjør is still required because decisions are operator-binding.
- **Tier C bulk** — touches `00-claude-inbox/` (223 files) + `handoffs/` which may contain draft context, partial findings, or unredacted operator notes. Dry-run first; operator reviews count + project-breakdown.
- **Tier D bulk** — touches everything else; lowest-priority but largest scope. Requires explicit "OK kjør tier D" plus a `--max-files N` cap on first invocation.
- **Any file with frontmatter `sensitive: true`** — never bulk-distilled; route through sensitive-only flow.

Tier S and Tier B may proceed without per-tier approval since both lists are short and contents are already operator-curated.

---

## How to invoke

Once memory-engine + skill-registry are wired (waiting on `code-1` C1-2 / C1-3 / C1-4 + `[[SKILL_REGISTRY_SPEC]]`):

```bash
/skill brain-distill-daily mode=manifest tier=S         # ~30s, no approval needed
/skill brain-distill-daily mode=manifest tier=A         # ~3 min, OK kjør required
/skill brain-distill-daily mode=manifest tier=B         # ~1 min, no approval needed
/skill brain-distill-daily mode=manifest tier=C --since 2026-04-25   # ~5 min, OK kjør required
/skill brain-distill-daily mode=manifest tier=D --max-files 50       # on-demand, OK kjør required
```

**Pre-flight (every invocation):** dry-run mode prints counts per folder (verbatim rows to insert, distill-jobs to enqueue, projected Haiku token spend). Operator OK kjør gates the `--execute` flag, per spec §8.1 step 4.

**Reports:** Each tier emits `08-system-architecture/distill-report-<tier>-<date>.md` with MemoryObject count, sample IDs, fingerprint-dedup hit-rate, surviving-vocabulary stats per spec §7.3, and any failures.

---

## Related

- Spec: `[[MEMORY_DISTILLATION_SPEC]]` v1.0.2 (verified at `08-system-architecture/specs/`)
- RAG: `[[RAG_ENGINE_SPEC]]` v1.0.1 (verified at `08-system-architecture/specs/`)
- Plan: `[[2026-05-25-brain-upgrade-plan]]` (verified at `08-system-architecture/`)
- Skill: `[[brain-distill-daily]]` (stub — not yet authored; depends on `[[SKILL_REGISTRY_SPEC]]`)
- Eval: `[[recall-eval-2026-05-25]]` (stub — referenced by spec §9.1, lives in `08-system-architecture/eval/`)

---

## Counts verified (audit trail)

Run on 2026-05-25 against live vault at `/home/nithu/Obsidian/Brain/`:

```
_decisions/  → 15 .md files
_runbooks/   → 18 .md files (spec said 17 + 1 new from D-5; matches)
_maps/       → 12 *-MOC.md files
project-root MOCs (01-nexus..07-personlig) → 9 *-MOC.md files
Total MOCs across brain → 21
00-claude-inbox/ (recursive) → 223 .md files
handoffs/    → 5 .md files
01-nexus/runtime-state/ → 11 .md files
Total relevant .md (excl .git/.obsidian/_library-youtube/90-archive) → 570
```

Re-run this enumeration immediately before invoking each tier — counts drift as the brain grows.

---

*Sist oppdatert: 2026-05-25. v1.0 initial backlog. Waiting on code-1 C1-2 / C1-3 / C1-4 + `[[SKILL_REGISTRY_SPEC]]` before this manifest becomes executable.*
