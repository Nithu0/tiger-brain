---
title: Integration Notes v1.1 — cross-spec verification
date: 2026-05-25
status: v1.0 — initial cross-check
purpose: Verify internal consistency across 7 specs before code-1 implementation
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[MEMORY_DISTILLATION_SPEC]]"
  - "[[RAG_ENGINE_SPEC]]"
  - "[[AGENT_ORCHESTRATION_SPEC]]"
  - "[[OBSIDIAN_BRAIN_STRUCTURE]]"
  - "[[YOUTUBE_INGESTION_SPEC]]"
  - "[[GITHUB_DISCOVERY_SPEC]]"
  - "[[SKILL_REGISTRY_SPEC]]"
tags: [meta, verification, integration, v1.1]
---

# Integration Notes v1.1 — Cross-spec verification

> Meta-audit pass over the 7 v1.0 specs landed 2026-05-25 by A-1..A-6 + A-7. Goal: catch internal contradictions, schema drift, dangling wikilinks, scope-creep, and post-B-1/B-3 inconsistencies before code-1 starts implementation. Audit run by code-2 in single pass — each section A..I = one matrix dimension; severities `CRITICAL` (blocks implementation), `MEDIUM` (must fix before merge to main), `NIT` (cosmetic / future-proofing).

**Headline counts:**
- **CRITICAL: 7**
- **MEDIUM: 12**
- **NIT: 9**

The single largest issue (and only blocker for code-1 starting C1-1 / C1-2 today) is **finding B.1**: B-1 folder-rename (`06-youtube` → `12-youtube`, `07-github-repos` → `13-github-repos`) was executed on disk but NOT propagated into any of the 7 specs. ~50 hard-coded path strings still reference the old folder names. The specs will instruct workers to write to non-existent paths.

---

## A. Schema alignment

### A.1 MemoryObject schema — MEMORY_DISTILLATION_SPEC vs RAG_ENGINE_SPEC consumption

**A.1.1 — `source_type` enum mismatch — `agentic_recall` undefined.** **CRITICAL.**
- `MEMORY_DISTILLATION_SPEC` §2 defines `SourceType` union: `"conversation" | "code_change" | "youtube" | "github_repo" | "document" | "manual_note" | "terminal_log"` (7 values).
- `RAG_ENGINE_SPEC` §1.2 + §4.6 + §15.1 writes `MemoryObject` rows of `source_type: "agentic_recall"` for Tier 3 reasoning traces.
- `RAG_ENGINE_SPEC` §3.1.4 uses `agentic_recall` in the chunking strategy table.
- Result: every agentic-RAG call will fail MEMORY_DISTILLATION_SPEC's §7.7 type validator (`SourceType` enum check) at insert-time. Hard error, no agentic queries land.
- **Fix:** Add `"agentic_recall"` to `SourceType` union in MEMORY_DISTILLATION_SPEC.md §2 line 46-53. Re-bump to v1.0.2.

**A.1.2 — `source_type: "sensitive"` undefined.** **CRITICAL.**
- `RAG_ENGINE_SPEC` §3.1.4 chunking-strategy table has a row for `source_type: sensitive` → strategy (b) sentence local-only.
- `RAG_ENGINE_SPEC` §5.4, §6.3, §12 enforce local-only routing based on `source_type === "sensitive"`.
- MEMORY_DISTILLATION_SPEC §2 `SourceType` union does NOT include `"sensitive"`.
- Result: any chunk marked sensitive bypasses the routing check (`opts.sensitive` is the alternative path in §5.3, but the source_type-keyed paths fail silently).
- **Fix:** EITHER add `"sensitive"` to `SourceType` OR change RAG_ENGINE_SPEC to use a separate `sensitivity_flag: boolean` field on `MemoryObject` (cleaner — `sensitive` is orthogonal to `source_type`). Recommend the latter; document the new field in MEMORY_DISTILLATION_SPEC §2 as an operator-extension.

**A.1.3 — `source_ref.id` referenced but not defined.** **MEDIUM.**
- `RAG_ENGINE_SPEC` §3.2.2 `HybridHit.source_ref` and §8.1 `buildPrompt` reference `h.source_ref.id` as the citation token.
- `MEMORY_DISTILLATION_SPEC` §2 `SourceRef` interface has `conversation_id`, `ply_*`, `file_path`, `commit_sha`, `url`, `verbatim_row_id` — NO `id` field. The closest is `verbatim_row_id` (integer) or the parent `MemoryObject.id` (UUIDv7).
- Result: TypeScript code that types `SourceRef` and accesses `.id` will not compile.
- **Fix:** RAG_ENGINE_SPEC §3.2.2 + §8.1 change `h.source_ref.id` → `h.source_ref.verbatim_row_id` OR add a derived `id: string` getter on the `HybridHit` type (UUIDv7 of the parent MemoryObject). Document in RAG §3.2.2.

**A.1.4 — `source_ref.extras` referenced but not defined.** **MEDIUM.**
- `RAG_ENGINE_SPEC` §4.6 stores agentic trace in `source_ref.extras: { trace, truncated, cited, cost }`.
- `MEMORY_DISTILLATION_SPEC` `SourceRef` has no `extras` field.
- **Fix:** EITHER add optional `extras?: Record<string, unknown>` to `SourceRef` in MEMORY_DISTILLATION_SPEC §2 OR move the agentic trace to a dedicated column (preferable for queryability). Document.

**A.1.5 — `chunking_strategy` field on `source_ref`.** **NIT.**
- `RAG_ENGINE_SPEC` §3.1.4 closing line: "Operator can override via `chunking_strategy` field in `MemoryObject.source_ref`."
- Not defined anywhere in MEMORY_DISTILLATION_SPEC.
- **Fix:** Either add to `SourceRef` interface or drop the override mechanism (it's chunker-config, not source-of-truth — belongs on a request-level options object, not the immutable source_ref).

### A.2 `agent_tasks` schema — AGENT_ORCHESTRATION_SPEC vs YOUTUBE/GITHUB publish

**A.2.1 — `role` enum mismatch.** **CRITICAL.**
- `AGENT_ORCHESTRATION_SPEC` §4.1 line 161 DDL comment: `role TEXT NOT NULL, -- 'distill'|'ingest'|'review'|'fix'|'research'` (5 values, comment-only — no DB-level CHECK).
- `SKILL_REGISTRY_SPEC` §6.1 + §6.2 publishes `role: skill-runner` and §7.2 publishes `role: skill-extractor`. Neither in the enum.
- Result: documentation lie (DDL comment claims 5 values, code uses 7+). Operator-grepping the comment will be misled. No code-level enforcement saves us because the CHECK is absent — but the README/spec is wrong.
- **Fix:** AGENT_ORCHESTRATION_SPEC.md §4.1 expand role-comment to `'distill'|'ingest'|'review'|'fix'|'research'|'skill-runner'|'skill-extractor'`. Consider promoting to a `CHECK` constraint so DB enforces it. Document the contract.

**A.2.2 — Payload shape contract missing.** **MEDIUM.**
- YOUTUBE_INGESTION_SPEC §2 publishes `payload:{url, tags?, queue_file}` for `role: ingest`.
- GITHUB_DISCOVERY_SPEC §2 publishes `payload: {query, limit, topic}` for `role: research`.
- SKILL_REGISTRY_SPEC §6.1 publishes `payload: { skill, args, invoker }` for `role: skill-runner`.
- AGENT_ORCHESTRATION_SPEC §4.1 types `payload` as `JSONB` — fine — but does not document the per-role shape contract.
- **Fix:** Add `## 4.4 Per-role payload contract` to AGENT_ORCHESTRATION_SPEC enumerating each role's payload TypeScript type. Cite back to sibling specs.

**A.2.3 — `skill_invocation` field referenced.** **NIT.**
- SKILL_REGISTRY_SPEC §1 line 23: "`BrainOrchestrator` can publish `agent_tasks(skill_invocation: <name>)`".
- Inconsistent with §6.1 which uses `role: skill-runner, payload: { skill: <name> }`.
- **Fix:** SKILL_REGISTRY_SPEC §1 rewrite to use the §6.1 shape (`role: skill-runner`). The phrase `skill_invocation: <name>` is misleading shorthand.

**A.2.4 — `model` field unused by ingest specs.** **NIT.**
- AGENT_ORCHESTRATION_SPEC §4.1 has `model TEXT` column (`'claude-sonnet'|'gemini-flash'|null=any`).
- YOUTUBE_INGESTION_SPEC and GITHUB_DISCOVERY_SPEC never set it; SKILL_REGISTRY_SPEC ignores it.
- **Fix:** Either remove `model` from AGENT spec (it's orchestrator-internal) or document expected publisher behavior (default `null`).

### A.3 SKILL.md frontmatter — SKILL_REGISTRY_SPEC vs actual `03-skills/*.md` files

The 5 hand-authored SKILL files (`brain-distill-daily.md`, `youtube-ingest.md`, `github-discover.md`, `multi-agent-dispatch.md`, `worktree-spawn-cleanup.md`) all deviate from the SPEC §3 schema. Every single one will fail `validate.ts` at index-build time as currently specified.

**A.3.1 — `inputs` / `outputs` shape: array-of-objects vs object-of-types.** **CRITICAL.**
- SPEC §3 schema:
  ```yaml
  inputs:
    date: { type: string, format: YYYY-MM-DD, required: true }
    dry_run: { type: boolean, default: false }
  outputs:
    count_new_objects: number
    count_promoted_to_brain: number
  ```
- Actual files (all 5):
  ```yaml
  inputs:
    - name: date
      type: string
      required: false
      default: yesterday
    - name: dry_run
      type: bool
      required: false
      default: false
  outputs:
    - count_new_objects: number
    - count_promoted_to_brain: number
  ```
- These are not equivalent. The actual files use an array-of-objects pattern (cleaner for readability + arg-ordering); the spec uses an object-keyed dict (cleaner for direct lookup). Pick ONE.
- **Fix:** Update SPEC §3 + §4 to match the actual array-of-objects pattern in the 5 SKILL files (it's friendlier and the files already exist). Re-bump SPEC to v1.0.1.

**A.3.2 — `tier: brain` + `project_scope: workspace`.** **MEDIUM.**
- SPEC §3: "`project_scope` required iff tier=project; glob relative to /home/nithu/code". Means absent when tier ∈ {workspace, brain}.
- Actual files: all 5 have `tier: brain` AND `project_scope: workspace`. The string `"workspace"` is not a glob.
- **Fix:** Either drop `project_scope` from the 5 files OR loosen SPEC to allow `project_scope: workspace` as a sentinel value (meaning "applies workspace-wide"). Recommend dropping from the files — clearer.

**A.3.3 — Missing `cache_strategy` enum mismatch.** **NIT.**
- SPEC §3: `cache_strategy: ephemeral | persistent | none`.
- Actual files use these values correctly. PASS.

**A.3.4 — Missing required field `version`.** **NIT.**
- SPEC §8.2 introduces `version: <semver>` field, optional, default `0.1.0`.
- Actual files all omit it — fine, default applies.

**A.3.5 — Body section template mismatch.** **MEDIUM.**
- SPEC §4 requires 8 fixed-order sections: Purpose, When to use, Inputs, Steps, Tools / commands, Pitfalls, Validation checks, Example usage, Related (technically 9).
- Actual files include all 9 sections. PASS.

**A.3.6 — `tools_required` populated with Claude-builtin tools.** **NIT.**
- Actual files: `tools_required: [Bash, Read, Write, Edit]`.
- SPEC §3 example uses package-style names: `["@cc/memory-engine", "brain-write", "sqlite-fts5"]`.
- This is a meaning-mismatch: SPEC treats `tools_required` as "external system tools the skill calls"; files treat it as "Claude tool names the harness needs to grant".
- **Fix:** Disambiguate in SPEC §3 — distinguish `harness_tools` (Claude tools) from `system_tools` (packages, CLIs). Or pick one interpretation. Recommend separating into two fields.

---

## B. Cross-spec wikilinks

Every spec uses Obsidian wikilinks. Resolution scan:

**B.1 — Sibling-spec wikilinks all resolve.** **PASS.**
- `[[MEMORY_DISTILLATION_SPEC]]`, `[[AGENT_ORCHESTRATION_SPEC]]`, `[[RAG_ENGINE_SPEC]]`, `[[OBSIDIAN_BRAIN_STRUCTURE]]`, `[[YOUTUBE_INGESTION_SPEC]]`, `[[GITHUB_DISCOVERY_SPEC]]`, `[[SKILL_REGISTRY_SPEC]]` — all present in `specs/`.
- `[[2026-05-25-brain-upgrade-plan]]` — present.
- `[[2026-05-24-onprem-ai-strategi]]` — verified by MEMORY_DISTILLATION_SPEC §12 to exist at `03-business/`.

**B.2 — MOC wikilinks: STUBS.** **MEDIUM.**
- OBSIDIAN_BRAIN_STRUCTURE §5.2 + §10 reference `[[Skills-MOC]]`, `[[System-Architecture-MOC]]`, `[[Tasks-MOC]]`, `[[Retrospectives-MOC]]`, `[[Youtube-MOC]]`, `[[Github-Repos-MOC]]`, `[[Memory-MOC]]` — none exist in `_maps/` yet.
- OBSIDIAN_BRAIN_STRUCTURE §10.1 explicitly schedules 3 of these as "new MOCs to write" (Skills, System-Architecture, Tasks) and 3 as "optional / when first note lands". So they're EXPECTED stubs — but the dead-link check (§11.2) will flag them as broken unless marked.
- **Fix:** Add the 7 MOC names to a `.stub-allow` file at brain root (per OBSIDIAN_BRAIN_STRUCTURE §5.3 contract), OR write the 3 high-priority MOCs as one-liner placeholders before sanity.sh extension lands. Recommend the latter — `.stub-allow` is a workaround.

**B.3 — `[[BRAIN-RULES]]`, `[[Operator-Principles]]`, `[[00-DASHBOARD]]`.** **PASS.**
- BRAIN-RULES.md present at brain root. `00-DASHBOARD.md` present.
- `[[Operator-Principles]]` — NOT present at brain root. **MEDIUM.** OBSIDIAN_BRAIN_STRUCTURE §12.5 references it. Fix: rename existing file or create stub.

**B.4 — `[[2603.13017v1]]`.** **NIT.**
- Referenced by MEMORY_DISTILLATION_SPEC §12 and RAG_ENGINE_SPEC §16 as the paper.
- No `.md` file in brain — it's the PDF at `/home/nithu/code/2603.13017v1.pdf`. The wikilink doesn't resolve in Obsidian.
- **Fix:** Either create `_library/papers/2603.13017v1.md` as a stub pointing to the PDF, or change wikilink to plain markdown link `[2603.13017v1](file:///home/nithu/code/2603.13017v1.pdf)`. Recommend the brain-stub.

**B.5 — `[[CLAUDE.md]]` wikilink.** **NIT.**
- MEMORY_DISTILLATION_SPEC §10 + §12 reference `[[CLAUDE.md]]`.
- `CLAUDE.md` doesn't live in the brain (lives at `~/.claude/CLAUDE.md` and per-repo). Wikilink unresolved.
- **Fix:** Same as B.4 — stub-allow or convert to inline path.

**B.6 — `[[Runbook-Multi-Agent-Dispatch]]`, `[[git-worktree-workflow]]`.** **MEDIUM.**
- SKILL_REGISTRY_SPEC §14 references these as "codified by …" runbook origins.
- `_runbooks/` contains runbooks but exact filenames need confirmation. Likely close-matches exist (e.g. `Runbook-Multi-Agent-Dispatch.md`) but slug-case matters in Obsidian.
- **Fix:** Verify exact filenames in `_runbooks/` and align wikilinks.

**B.7 — `[[reference_available_tools]]`.** **NIT.**
- SKILL_REGISTRY_SPEC §14 references it. Lives at `~/.claude/projects/-home-nithu-code/memory/reference_available_tools.md` (per CLAUDE.md tool-roster habit), NOT in brain. Unresolved wikilink.
- **Fix:** Either stub-allow or cite as inline path.

---

## C. BrainOrchestrator trigger coverage

AGENT_ORCHESTRATION_SPEC §8.1 lists 5 built-in triggers: `stale-task`, `dead-link`, `youtube-queue`, `github-discovery`, `nightly-distill`.

**C.1 — Trigger names match across specs.** **PASS.**
- YOUTUBE_INGESTION_SPEC §2 uses `trigger:youtube-queue` — matches.
- GITHUB_DISCOVERY_SPEC §2 uses `trigger:github-discovery` — matches.
- MEMORY_DISTILLATION_SPEC §4.c uses `nightly-memory-distill` — **MISMATCH**. AGENT lists `nightly-distill`. **MEDIUM.**
- **Fix:** Pick one canonical name. Recommend `nightly-memory-distill` (more specific). Update AGENT §8.1 table.

**C.2 — Missing trigger: `worktree-gc`.** **MEDIUM.**
- AGENT_ORCHESTRATION_SPEC §9.2 + §12.5 + §15 (`firm-worktree-gc.sh`) all reference a `worktree-gc` trigger that runs every 24h.
- §8.1 built-in trigger table does NOT include it.
- **Fix:** Add `worktree-gc` to §8.1 with cadence `cycleNo % 1440 === 0` and publish-spec.

**C.3 — Missing trigger: `skill-extract-from-success`.** **MEDIUM.**
- brain-upgrade-plan §2.H Module H lists this routine (per-task-done cadence).
- SKILL_REGISTRY_SPEC §7 describes the pipeline.
- AGENT_ORCHESTRATION_SPEC §8.1 does NOT list it.
- **Fix:** Add to §8.1 with cadence `on:agent_audit insert where outcome=success && surprising_finding=true`. Document this as a non-cycle-based "event-driven" trigger type — current `shouldFire(ctx)` is cycle-based; need to extend interface OR add an event-bus.

**C.4 — Missing trigger: `repo-health-audit` (weekly).** **NIT.**
- brain-upgrade-plan §2.H Module H lists it.
- Not in AGENT §8.1.
- **Fix:** Add or note as out-of-scope for v1.0 with reference.

**C.5 — Missing trigger: `weekly-arch-review` (Sunday 22:00).** **NIT.**
- brain-upgrade-plan §2.H lists it.
- OBSIDIAN_BRAIN_STRUCTURE §10.1 / §3.5 expects retrospectives generated by it.
- Not in AGENT §8.1.
- **Fix:** Add or note deferred to v1.1.

**C.6 — Trigger interface limitation: cycle-only `shouldFire`.** **CRITICAL.**
- AGENT_ORCHESTRATION_SPEC §8 `Trigger.shouldFire(ctx: TriggerContext)` — context includes `cycleNo`, no event payload.
- SKILL_REGISTRY_SPEC §7 auto-skill-creation is event-driven (post-task hook).
- Result: no clean way to wire skill-extract trigger into the orchestrator without re-architecting.
- **Fix:** Extend `Trigger` interface with optional `onEvent(ctx, event)` for event-driven triggers. OR add a separate `EventListener` interface for post-task hooks. Document in AGENT §8.

**C.7 — Cadence math: `cycleNo % 120 === 0`.** **NIT.**
- AGENT §8.1 says `stale-task` fires every `cycleNo % 120 === 0 (~daily at idle)`. At idle cadence 5min, 120 cycles = 600 min = 10 hours, not daily.
- For daily on idle, should be `cycleNo % 288 === 0`.
- Math is also fragile if operator toggles active/idle cadence.
- **Fix:** Replace modulo-arithmetic with wall-clock check (e.g. `state_kv.get('stale-task:last_run') < NOW() - 24h`). Document.

---

## D. RAG → distillation contract

RAG_ENGINE_SPEC Tier 2 strategy (c) "structured" uses MemoryObject as chunk. Verify schema-tightness.

**D.1 — `chunk_text_for_embedding` formula.** **PASS.**
- RAG §3.1.3: `${exchange_core}\n${specific_context}`.
- MEMORY_DISTILLATION_SPEC §6.3: same. Match.

**D.2 — Chunk-text-for-display = verbatim source.** **PASS.**
- RAG §3.1.3 + §1.2.
- MEMORY §1 hard invariant 2: "distilled rows are never shown to the operator". Match.

**D.3 — `HybridHit.distilled_text` field naming.** **MEDIUM.**
- RAG §3.2.2 `HybridHit` has `content` (verbatim, for display) and `distilled_text` (for debug).
- `distilled_text` is NOT defined in MemoryObject — it's a computed concatenation per D.1.
- **Fix:** RAG §3.2.2 clarify: "`distilled_text` is the concatenation `${exchange_core}\n${specific_context}` from the matched MemoryObject; not a stored column".

**D.4 — `SemanticChunk` shape vs MemoryObject.** **MEDIUM.**
- RAG §3.1.1 defines `type SemanticChunk = { chunk_id, source_id, topic_label, content, token_count, method }`.
- RAG §3.1.3 says structured chunking emits `SemanticChunk` with `method: "structured-distill"` plus "full MemoryObject JSON attached as `meta`".
- The `meta` field is not declared in the `SemanticChunk` type.
- **Fix:** Add `meta?: MemoryObject` (or `meta?: Record<string, unknown>`) to the SemanticChunk type in RAG §3.1.1.

**D.5 — Embedding text consistency.** **PASS.**
- RAG §5 + MEMORY §6.3 both embed `${exchange_core}\n${specific_context}` with bge-m3 1024-dim. Match.

---

## E. Folder path references (post B-1 rename)

**This is the largest single issue. B-1 was incomplete.**

**E.1 — Folder structure on disk.** **CONFIRMED.**
- `ls /home/nithu/Obsidian/Brain/` shows: `12-youtube/`, `13-github-repos/`. NO `06-youtube/`, NO `07-github-repos/`.
- B-1 rename executed on disk.

**E.2 — Specs still use OLD names.** **CRITICAL.**
- GITHUB_DISCOVERY_SPEC: 13 hits for `07-github-repos/`.
- YOUTUBE_INGESTION_SPEC: 14 hits for `06-youtube/`.
- OBSIDIAN_BRAIN_STRUCTURE: 12 hits for `06-youtube/` / `07-github-repos/` (incl. §3.2, §3.3 headers + §11.4 REQUIRED_DIRS array).
- MEMORY_DISTILLATION_SPEC: 4 hits (`06-youtube/`, `07-github-repos/`) in `inferProjectFromPath()` switch + comments.
- AGENT_ORCHESTRATION_SPEC: 2 hits — `06-youtube/_queue/` AND `07-github/_queue/` (note: AGENT uses `07-github/` which never existed even pre-rename — should have been `07-github-repos/`).
- SKILL_REGISTRY_SPEC: 4 hits in §9 default-skills table.
- RAG_ENGINE_SPEC: 0 direct hits (only references via abstract types). Untouched by B-1.

**Result:** every worker built against the v1.0 specs will write to non-existent `06-youtube/` and `07-github-repos/` paths, OR will look for queue files where none exist. End-to-end the system is broken until paths are aligned.

**Fix:** Single global pass: `06-youtube` → `12-youtube`, `07-github-repos` → `13-github-repos` across ALL spec files. Also fix the orphan `07-github/` in AGENT_ORCHESTRATION_SPEC §8.1 line 397 (typo even relative to old name). Re-bump all touched specs to v1.0.1.

**E.3 — `_library/youtube/` path.** **PASS.**
- YOUTUBE_INGESTION_SPEC stores verbatim at `_library/youtube/<channel>/<date-slug>/transcript.txt`. `_library/youtube/` exists on disk (placeholder per pre-existing convention). No rename needed.

---

## F. Known corrections to propagate

**F.1 — bge-m3 dim = 1024.** **DONE.**
- MEMORY_DISTILLATION_SPEC v1.0.1 changelog (line 698): "embedding dim 768 → 1024 (bge-m3 actual = 1024; A-7 RAG_ENGINE_SPEC catch)".
- Verified: all references in MEMORY_DISTILLATION_SPEC now say 1024 (lines 23, 31, 98, 102, 345, 348, 392, 641).
- RAG_ENGINE_SPEC consistent (lines 61, 76, 188, 357 — all 1024).
- B-3 successful. **No action needed.**

**F.2 — `text-embedding-3-large` dim.** **PASS.**
- MEMORY §2 + §6.3 say 3072.
- RAG §5.2 says 3072. Match.

**F.3 — SQLite vector extension naming: `sqlite-vss` vs `sqlite-vec`.** **MEDIUM.**
- MEMORY_DISTILLATION_SPEC §6 uses `sqlite-vss` throughout (DDL `USING vss0`, library refs, failure-mode §10.4 "sqlite-vss corruption").
- RAG_ENGINE_SPEC §2.3 + §7.1 uses `sqlite-vec` (successor to vss). §2.3 explicitly notes fallback chain `sqlite-vec → sqlite-vss → in-memory`.
- These are TWO DIFFERENT extensions with incompatible virtual-table syntax (`vec0` vs `vss0`).
- **Fix:** Standardize on ONE. Recommend `sqlite-vec` (newer, actively maintained, RAG already specs the fallback). MEMORY_DISTILLATION_SPEC §6.1 DDL needs rewrite from `vss0(embedding(1024))` → `vec0(chunk_id TEXT PRIMARY KEY, embedding FLOAT[1024])`. Update failure-mode §10.4 wording.

**F.4 — `ply_start`/`ply_end` units.** **NIT.**
- MEMORY §2 docs `ply_start`/`ply_end` "paper-tro (inclusive)" — `ply` = a single conversation turn per paper terminology.
- Other specs reference `ply_*` only via MEMORY's interface. Consistent.

---

## G. Scope drift

**G.1 — MEMORY_DISTILLATION_SPEC §1 mentions hybrid retrieval architecture.** **NIT.**
- §1 closing: "Relation to RAG_ENGINE_SPEC: this spec owns storage and write-path. The RAG engine owns the read-path."
- This boundary is correctly stated. But MEMORY §6.1 + §6.2 ship FTS5 virtual tables AND vector tables AND public API functions `queryDistilledFts()`, `queryDistilledVector()` — these are read-path primitives.
- Verdict: acceptable — MEMORY exposes low-level queries; RAG composes them. Document this layering in MEMORY §1 explicitly: "low-level storage queries live in MEMORY; high-level hybrid+rerank+agentic lives in RAG".

**G.2 — RAG_ENGINE_SPEC §3.1.3 (structured chunking).** **PASS.**
- RAG correctly delegates to MEMORY for distillation; never re-implements it.

**G.3 — SKILL_REGISTRY_SPEC §6 invocation triggers.** **MEDIUM.**
- §6 invocation protocol describes BrainOrchestrator triggering skills. But the trigger registration mechanism (skill → trigger binding) is not defined.
- AGENT_ORCHESTRATION_SPEC §8 owns triggers. SKILL owns skills. The bridge is undefined.
- **Fix:** Define in SKILL_REGISTRY_SPEC §6.2 OR add a section in AGENT_ORCHESTRATION_SPEC §8 explaining how `auto_invocable: true` skills become triggers (probably a dynamic trigger registered at registry-scan time).

**G.4 — OBSIDIAN_BRAIN_STRUCTURE §11 sanity.sh extensions.** **NIT.**
- Spec defines 4 new sanity.sh sections. This is implementation-level scope but acceptable for a structure-defining spec (validators ARE the structure contract).

**G.5 — YOUTUBE_INGESTION_SPEC §5 anti-hype filter.** **PASS.**
- Anti-hype LLM prompt is in scope (per brain-upgrade-plan §3.4 explicit directive).

**G.6 — GITHUB_DISCOVERY_SPEC §5 license policy.** **PASS.**
- License taxonomy + override mechanism explicitly in-scope per brain-upgrade-plan §3.5.

---

## H. Acceptance test coverage

**H.1 — Per-module numeric thresholds.** **PASS.**
- MEMORY: MRR ≥ 0.60, surviving-vocab ≥ 25%, top-15 IDF — all numeric (§9).
- AGENT: 5/5 PRs cleanly mergeable, lease-expiry within 60s, 3-attempt cap — all numeric (§13).
- RAG: MRR ≥ 0.6, nDCG@10 ≥ 0.65, P@1 ≥ 0.5, latency p50/p95 per tier (§10.2, §15.3).
- YOUTUBE: 15 ATs with explicit verification commands (§11). 3-of-3 pilot URL pass criterion.
- GITHUB: 3 pilot queries with explicit expected outcomes (§12).
- SKILL: 10 ATs with explicit counts and exit codes (§12).
- OBSIDIAN: §14 5× checklist (qualitative, no numeric — acceptable for structure spec).

**H.2 — Cross-module e2e test missing.** **MEDIUM.**
- No spec defines an end-to-end test: "operator drops YouTube URL → ingest → distill → RAG retrieves the new note within 5s".
- brain-upgrade-plan §9 "Definisjon av ferdig" lists the 7 acceptance criteria but they aren't owned by any module.
- **Fix:** Add e2e suite as `tests/integration/` to `packages/brain-orchestrator/` OR `packages/rag-engine/` and reference from all 7 specs.

**H.3 — Regression-gate threshold.** **NIT.**
- RAG §10.3 specifies "any metric drops > 10% relative to previous baseline → block merge". Good.
- No other spec has equivalent regression gate. Recommend adding to MEMORY (MRR target) and SKILL (validation_pass count).

---

## I. Anti-patterns alignment

Each spec has a "binding anti-patterns" section. Cross-check for contradictions.

**I.1 — "Never delete verbatim source".** **PASS.** Consistent across MEMORY §5.3, RAG §13.4.

**I.2 — "Never show distilled content to operator as final answer".** **PASS.** MEMORY §1 invariant 2, RAG §13.5. Match.

**I.3 — "Local-first for sensitive data".** **PASS.** RAG §13.6, MEMORY §6.3 (re: embeddings). Match.

**I.4 — "Never auto-disable".** **PASS.** All specs respect CLAUDE.md baseline. Match.

**I.5 — "Never bulk-rename existing notes".** **CONTRADICTS B-1.** **MEDIUM.**
- OBSIDIAN_BRAIN_STRUCTURE §12.1: "Never bulk-rename existing notes to fit new conventions."
- §12.1: "Never relocate `06-AS/`, `07-personlig/`" etc.
- But B-1 just bulk-renamed `06-youtube/` → `12-youtube/` and `07-github-repos/` → `13-github-repos/`. These were NEW folders, not pre-existing — so technically not in violation. But the spirit of the anti-pattern conflicts with the B-1 operation.
- **Fix:** Add a clarifying note to OBSIDIAN_BRAIN_STRUCTURE §12.1: "Renaming NEW folders before they ship content (during the initial design phase) is allowed; renaming existing folders with content is not." Document the B-1 rename as the precedent.

**I.6 — "Never embed sensitive data with external provider".** **PASS.** RAG §13.6 enforces. MEMORY §6.3 echoes. Match.

**I.7 — "Never clone-and-run" (GitHub).** **PASS.** GITHUB §6 + §13.5 (RAG anti-pattern about not running external code). Match.

**I.8 — "Never dump full YouTube transcripts".** **PASS.** YOUTUBE §6 + OBSIDIAN §12.4. Match.

**I.9 — "Auto-promotion always operator-gated".** **PASS.**
- SKILL §7.3: "No automatic promotion ever. Operator's flow."
- YOUTUBE §12: SKILL stubs go to `03-skills/_proposed/`, operator promotes.
- GITHUB §11: task proposals require `operator_approval_required: true`.
- All consistent.

**I.10 — Operator commentary in Norwegian Bokmål.** **MEDIUM.**
- brain-upgrade-plan §3.7 instruction: operator commentary + brain notes in Norwegian.
- 5 of 7 specs are in English (per the same instruction — specs are technical, English OK).
- INTEGRATION_NOTES (this file) is in English. Acceptable per the same rule.
- No conflict, just noting the convention is followed.

---

## v1.1 edit-list (concrete, ordered by severity)

### CRITICAL (block code-1 / C1-1 / C1-2 today)

1. **MEMORY_DISTILLATION_SPEC.md §2** — add `"agentic_recall"` and decision on `"sensitive"` to `SourceType` union (or split sensitive into separate flag). Bump v1.0.2. (A.1.1, A.1.2)
2. **MEMORY_DISTILLATION_SPEC.md §2** — add `source_ref.extras?: Record<string, unknown>` for agentic trace storage. (A.1.4)
3. **AGENT_ORCHESTRATION_SPEC.md §4.1 line 161** — expand `role` enum comment to include `skill-runner`, `skill-extractor`. (A.2.1)
4. **AGENT_ORCHESTRATION_SPEC.md §8 `Trigger` interface** — add `onEvent(ctx, event)` for event-driven triggers (skill-extract-from-success can't wire otherwise). (C.6)
5. **SKILL_REGISTRY_SPEC.md §3** — change `inputs/outputs` schema to array-of-objects to match the 5 actual SKILL.md files. Bump v1.0.1. (A.3.1)
6. **All 5 SPECS that reference `06-youtube/` / `07-github-repos/`** — bulk replace with `12-youtube/` / `13-github-repos/`. Targets:
   - GITHUB_DISCOVERY_SPEC.md (13 hits)
   - YOUTUBE_INGESTION_SPEC.md (14 hits)
   - OBSIDIAN_BRAIN_STRUCTURE.md (12 hits incl. §11.4 REQUIRED_DIRS array)
   - MEMORY_DISTILLATION_SPEC.md (4 hits in `inferProjectFromPath()`)
   - SKILL_REGISTRY_SPEC.md (4 hits in §9 default-skills table)
   - AGENT_ORCHESTRATION_SPEC.md §8.1 line 396-397 (2 hits, ALSO fix orphan `07-github/` typo → `13-github-repos/`)
   - All re-bump to v1.0.1. (E.2)
7. **RAG_ENGINE_SPEC.md §3.2.2 + §8.1** — change `h.source_ref.id` references to `h.source_ref.verbatim_row_id` OR add derived `id` getter on `HybridHit`. (A.1.3)

### MEDIUM (must fix before any code merges to main)

8. **AGENT_ORCHESTRATION_SPEC.md §4** — add `## 4.4 Per-role payload contract` section enumerating each role's payload shape with TypeScript types. (A.2.2)
9. **SKILL_REGISTRY_SPEC.md §3** — decide: drop `project_scope` from 5 SKILL files OR allow `project_scope: workspace` sentinel. Document and apply. (A.3.2)
10. **SKILL_REGISTRY_SPEC.md §3** — disambiguate `tools_required` semantics (harness tools vs system tools). Optionally split into two fields. (A.3.6)
11. **AGENT_ORCHESTRATION_SPEC.md §8.1** — add `worktree-gc`, `skill-extract-from-success` (event-driven), `nightly-memory-distill` (rename from `nightly-distill`). (C.1, C.2, C.3)
12. **MEMORY_DISTILLATION_SPEC.md §6** — replace `sqlite-vss` references with `sqlite-vec` to align with RAG §2.3. Rewrite DDL `vss0` → `vec0`. Update §10.4 failure-mode wording. (F.3)
13. **RAG_ENGINE_SPEC.md §3.2.2** — clarify `distilled_text` is computed `${exchange_core}\n${specific_context}`, not stored. (D.3)
14. **RAG_ENGINE_SPEC.md §3.1.1** — add `meta?: MemoryObject` field to `SemanticChunk` type. (D.4)
15. **OBSIDIAN_BRAIN_STRUCTURE.md** — write `_maps/Skills-MOC.md`, `_maps/System-Architecture-MOC.md`, `_maps/Tasks-MOC.md` as 1-line placeholders so dead-link check doesn't fail. (B.2)
16. **OBSIDIAN_BRAIN_STRUCTURE.md** — create `[[Operator-Principles]]` stub or fix reference. (B.3)
17. **OBSIDIAN_BRAIN_STRUCTURE.md §12.1** — clarify "renaming NEW folders before they have content is allowed; renaming pre-existing folders is not". (I.5)
18. **SKILL_REGISTRY_SPEC.md §6.2** — define how `auto_invocable: true` becomes a registered trigger in BrainOrchestrator (bridge to AGENT §8). (G.3)
19. **All specs** — write a cross-module e2e integration test as `packages/brain-orchestrator/tests/integration/` and reference from all 7 specs. (H.2)

### NIT (cosmetic, future-proofing)

20. SKILL_REGISTRY_SPEC.md §1 line 23 — rewrite shorthand `skill_invocation:` to match §6.1 payload shape. (A.2.3)
21. AGENT_ORCHESTRATION_SPEC.md §4.1 — remove or justify the `model` column. (A.2.4)
22. RAG_ENGINE_SPEC.md §3.1.4 — clarify or remove `chunking_strategy` override on `source_ref`. (A.1.5)
23. Brain root — add `.stub-allow` file listing `[[CLAUDE.md]]`, `[[2603.13017v1]]`, `[[reference_available_tools]]` etc. OR create stub `.md` files. (B.4, B.5, B.7)
24. SKILL_REGISTRY_SPEC.md §14 — verify exact filenames for `[[Runbook-Multi-Agent-Dispatch]]` and `[[git-worktree-workflow]]` in `_runbooks/`. (B.6)
25. AGENT_ORCHESTRATION_SPEC.md §8.1 — replace cycle-modulo cadence (`cycleNo % 120`) with wall-clock check via state_kv. (C.7)
26. AGENT_ORCHESTRATION_SPEC.md §8.1 — add `repo-health-audit` and `weekly-arch-review` (or note deferred to v1.1). (C.4, C.5)
27. MEMORY_DISTILLATION_SPEC.md §1 — explicitly document MEMORY-low-level vs RAG-high-level retrieval layering. (G.1)
28. SKILL_REGISTRY_SPEC.md §3 — document `version: <semver>` as a required-on-new-skills field (currently optional). Helps future caller-migration. (A.3.4)

---

## Footer

- All 9 check-matrix sections (A..I) present.
- Each finding tagged with severity (CRITICAL/MEDIUM/NIT) + actionable fix.
- Wikilink resolution status documented in B; stubs explicit.
- Frontmatter validates as YAML.
- v1.1 edit-list points to specific `file:section:line` for every edit.

**Recommended next action:** code-2 (this pane) dispatches a single 6-fix CRITICAL pass to inbox/code-1.md or executes inline. CRITICAL items 1-7 must land before C1-1 / C1-2 begins. MEDIUM items 8-19 can land during the spec-review window before code merges. NIT items 20-28 can land lazily.

*Sist oppdatert: 2026-05-25 av code-2. v1.0 — initial cross-spec verification. Awaiting operator review + OK kjør for v1.1 edit-application.*
