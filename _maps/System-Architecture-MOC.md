---
title: System-Architecture-MOC
type: moc
created: 2026-05-25
updated: 2026-05-25
purpose: Index of brain-upgrade plan, specs, eval-set, integration notes, implementation packages, pane scripts, and architecture-adjacent content across the vault
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[INTEGRATION_NOTES_v1.1]]"
tags: [moc, system-architecture, brain-upgrade, conductor, hermes, distillation]
---

# System-Architecture-MOC

Curated index of `08-system-architecture/` — the workspace-wide brain-upgrade plan, its v1.0/v1.0.1/v1.0.2 specs (one per module), the v1.0 recall-eval gold set, the cross-spec integration notes, plus the implementation packages and pane scripts that ship alongside. Live truth for module implementation always lives in the spec; this MOC only points.

## Primary plan

- [[2026-05-25-brain-upgrade-plan]] — audit + target + parallel-todo for lifting Nexus/Conductor/Hermes patterns into a workspace-wide brain-OS (v1.0 draft, awaits OK kjør per module).

## Specs (current versions, 2026-05-25)

One spec per module in the upgrade plan. All under `08-system-architecture/specs/`. Version reflects state after fase 1 (A-agenter), fase 2 (B-agenter v1.0.1 bumps), and fase 3 (C-1 → MEMORY v1.0.2).

| Spec | Version | One-line purpose | Link |
|---|---|---|---|
| Agent Orchestration | v1.0.1 | BrainOrchestrator + worktree per agent (Module A + I) | [[AGENT_ORCHESTRATION_SPEC]] |
| Memory Distillation | v1.0.2 | Two-stage distillation + MemoryObject schema (Module B + K input) | [[MEMORY_DISTILLATION_SPEC]] |
| Obsidian Brain Structure | v1.0 draft | Folder taxonomy + frontmatter conventions (Module C) | [[OBSIDIAN_BRAIN_STRUCTURE]] |
| Skill Registry | v1.0.1 | Hermes-style auto-skill registry + invocation contract (Module D) | [[SKILL_REGISTRY_SPEC]] |
| YouTube Ingestion | v1.0 draft | Metadata + transcript + distill pipeline (Module E) | [[YOUTUBE_INGESTION_SPEC]] |
| GitHub Discovery | v1.0 draft | gh-search → score → distill repo notes (Module F) | [[GITHUB_DISCOVERY_SPEC]] |
| RAG Engine | v1.0.1 | Advanced + agentic retrieval over MemoryObjects (Module K) | [[RAG_ENGINE_SPEC]] |

## Eval

| Artifact | Purpose | Link |
|---|---|---|
| Recall gold-set v1.0 | 10 queries (exact-phrase / concept / multi-hop / cross-domain) with MRR > 0.6 / P@1 > 0.5 acceptance target for the RAG engine | [[recall-eval-2026-05-25]] |

## Integration notes

- [[INTEGRATION_NOTES_v1.1]] — cross-spec verification audit by code-2 (B-2 output, fase 2). Headline: 7 CRITICAL, 12 MEDIUM, 9 NIT findings; folder-rename propagation (`06-youtube` → `12-youtube`, `07-github-repos` → `13-github-repos`) was the largest blocker. CRITICAL items dispatched to fase 3 (C-agenter); MEDIUM items target spec-review window before code merges; NIT items deferred lazily.

## Implementation packages (command-center)

Workspace-wide brain-OS packages live in `/home/nithu/code/command-center/packages/`. Each package is independently versioned and tested.

| Package | Status | Owner / agent | Notes |
|---|---|---|---|
| `packages/skill-registry/` | Scaffolded (discovery only) | B-4 | Schema-validation + manifest scan; full invocation runtime pending C-lane / code-1 |
| `packages/_template/` | Boilerplate | B-8 | Template for new packages: `package.json`, `tsconfig.json`, `vitest.config.ts`, `src/`, `tests/`, `README.md` |
| `packages/brain-orchestrator/` | Planned | code-1 lane | Conductor pattern, owns triggers + worktree spawn (AGENT_ORCHESTRATION_SPEC) |
| `packages/memory-engine/` | Planned | code-1 lane | MemoryObject store + FTS5 + sqlite-vec (MEMORY_DISTILLATION_SPEC) |
| `packages/rag-engine/` | Planned | code-1 lane | Hybrid + agentic retrieval over MemoryObjects (RAG_ENGINE_SPEC) |
| `packages/youtube-ingest/` | Planned | code-1 lane | Metadata + transcript + distill pipeline (YOUTUBE_INGESTION_SPEC) |
| `packages/github-discovery/` | Planned | code-1 lane | gh-search + score + distill repo notes (GITHUB_DISCOVERY_SPEC) |

Existing siblings (not part of the brain-upgrade plan but already in the monorepo): `agents/`, `auth/`, `brain/`, `bus/`, `engines/`, `executor/`, `git/`, `github/`, `router/`, `shared/`, `sync/`.

## Pane scripts (`command-center/_bin/`)

Firm-launcher and task-coordination scripts that wire the 8-pane workflow to `agent_tasks` + Obsidian inboxes.

| Script | Purpose | Origin |
|---|---|---|
| `firm-tab-init.sh` | Per-pane init: exports `FIRM_ROLE` / `FIRM_PROJECT`, touches inbox, execs Claude | Pre-existing |
| `firm-wt-split.sh` | 8 panes in ONE Windows Terminal tab (default `firm` alias) | Pre-existing |
| `firm-wt-tabs.sh` | 8 separate WT tabs (fallback `firmt`) | Pre-existing |
| `firm-zellij.sh` | Zellij fallback (`firmz`) | Pre-existing |
| `firm-worktree-spawn.sh` | Spawn isolated git worktree for an agent task | Pre-existing |
| `firm-worktree-cleanup.sh` / `firm-worktree-list.sh` | Worktree GC + inventory | Pre-existing |
| `firm-heartbeat.sh` / `firm-inbox-watch.sh` / `firm-session-context.sh` / `firm-statusline.sh` / `firm-git-snapshot.sh` | Pane-side observability + firm-bus | Pre-existing |
| `firm-task-claim.sh` | Atomically claim a task from `10-tasks/_open/`, move to `_claimed/`, write claim metadata | B-5 (fase 2) |
| `firm-task-complete.sh` | Mark task complete, move to `_done/`, push branch + open draft PR via `gh` | B-5 (fase 2) |

System prompt for firm-launched panes: `_bin/firm-system-prompt.md`.

## Related architecture content elsewhere in brain

Architecture-adjacent material that predates the brain-upgrade plan but feeds into it:

- [[2026-05-24-onprem-ai-strategi]] — on-prem AI strategy notes (foundational input to the upgrade plan).
- [[ADR-001-architecture]] — command-center architecture decision (Next.js + Fastify + SQLite control plane).
- [[ADR-002-sqlite-then-postgres]] — datastore migration path for command-center.
- [[ADR-003-cross-machine-sync]] — cross-machine state sync strategy (relevant to BrainOrchestrator multi-host).
- [[ADR-004-slice-14-control-plane-split]] — control-plane split for Slice 14 (Railway boundary).
- [[Nexus-MOC]] — Nexus (`ai-assistent`) already implements Conductor + Hermes patterns; the upgrade plan lifts these into a generic workspace orchestrator.
- [[Truth-Hierarchy]] — where live state lives vs. where decisions/notes live; binding for any module that writes state.
- [[Memory-MOC]] — current memory lifecycle (pre-distillation); will be superseded by MEMORY_DISTILLATION_SPEC once Module B lands.
- [[command-center]] — Slices 1–13 code-complete; Slice 14a (Railway) in progress; host for `@cc/brain-orchestrator`, `@cc/memory-engine`, `@cc/rag-engine`, `@cc/skill-registry`, `@cc/youtube-ingest`, `@cc/github-discovery`.

## Status timeline

Brief history of the brain-upgrade rollout (2026-05-25):

- **10:00Z** — fase 1 dispatched (10 A-agenter): spec drafting + folder scaffolding.
- **11:30Z** — fase 1 complete: 7 v1.0 specs landed, folder taxonomy created, 5 hand-authored SKILL.md files, recall-eval v1.0 gold-set.
- **11:45Z** — fase 2 dispatched (10 B-agenter): cross-spec audit, package scaffolds, pane-script additions, folder-rename, version bumps.
- **12:05Z** — fase 2 complete: B-2 cross-spec audit surfaced 7 CRITICAL + 12 MEDIUM + 9 NIT findings (see [[INTEGRATION_NOTES_v1.1]]); packages `skill-registry/` + `_template/` scaffolded; `firm-task-claim.sh` + `firm-task-complete.sh` added.
- **12:10Z** — fase 3 dispatched (10 C-agenter): CRITICAL-fix sweep (MEMORY → v1.0.2, AGENT/SKILL/RAG → v1.0.1, folder-rename propagation).

## Open questions / decisions deferred

- **Module ordering**: which module lands first — A (orchestrator) or B (memory)? Spec drafts assume A → B → K but no commit yet.
- **Worktree default**: lift from opt-in `--codex` mode to default Conductor-style? Requires operator OK kjør per [[2026-05-25-brain-upgrade-plan]] §3.
- **RAG migration trigger**: when does `_library/trading/lessons/` cross 30 entries (per `trading-knowledge` re-eval trigger) and force pgvector/Chroma adoption ahead of Module K?
- **Skill auto-creation gate**: do auto-distilled skills land in `03-skills/_proposed/` only, or can they auto-promote on N successful invocations? Deferred to SKILL_REGISTRY_SPEC §X review.
- **Distillation scope**: structured distillation (paper 2603.13017v1) on Nexus postmortems only, or all workspace audit-log events? Affects Module B implementation cost.
- **command-center hosting**: Railway (in progress Slice 14a) vs. self-host on-prem per [[2026-05-24-onprem-ai-strategi]]? Decision blocks cross-machine state for BrainOrchestrator.
- **NIT findings deferred to v1.2** (from [[INTEGRATION_NOTES_v1.1]] §NIT 20-28): SKILL §1 `skill_invocation` shorthand rewrite; AGENT §4.1 `model` column justification; RAG §3.1.4 `chunking_strategy` override clarification; `.stub-allow` file vs stub-`.md` for unresolved wikilinks (`[[CLAUDE.md]]`, `[[2603.13017v1]]`, `[[reference_available_tools]]`); runbook-filename alignment in SKILL §14; AGENT §8.1 cycle-modulo → wall-clock cadence; AGENT §8.1 `repo-health-audit` + `weekly-arch-review` triggers; MEMORY §1 layering doc; SKILL §3 `version` required-on-new-skills.
- **Cross-module e2e test** (INTEGRATION_NOTES §H.2): "operator drops YouTube URL → ingest → distill → RAG retrieves within 5s" — no spec owns it yet. Candidate home: `packages/brain-orchestrator/tests/integration/`.
- **Event-driven trigger interface** (INTEGRATION_NOTES §C.6): `Trigger.onEvent(ctx, event)` extension landed in AGENT v1.0.1 — but `skill-extract-from-success` wiring still needs C-lane impl.

## Related

[[Decisions-MOC]] · [[Github-Repos-MOC]] · [[Memory-MOC]] · [[RAG-MOC]] · [[Retrospectives-MOC]] · [[Skills-MOC]] · [[Tasks-MOC]] · [[Tools-MOC]] · [[Youtube-MOC]]

---

*Last updated 2026-05-25T12:10Z — post-fase-3 dispatch. Reflects INTEGRATION_NOTES_v1.1 (B-2), packages `skill-registry/` + `_template/` (B-4/B-8), pane scripts `firm-task-{claim,complete}.sh` (B-5), MEMORY v1.0.2 (C-1).*
