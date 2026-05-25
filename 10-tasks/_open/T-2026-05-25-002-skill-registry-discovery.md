---
task_id: T-2026-05-25-002
title: Extend skill-registry full discovery (scan + parse + conflict-resolve three tiers)
from: operator
to: code-2
owner: unclaimed
project: command-center
branch: code-2/skill-registry-full-discovery
files_allowed:
  - packages/skill-registry/src/scan.ts
  - packages/skill-registry/src/parse.ts
  - packages/skill-registry/src/validate.ts
  - packages/skill-registry/src/store.ts
  - packages/skill-registry/src/conflict.ts
  - packages/skill-registry/src/watcher.ts
  - packages/skill-registry/src/index.ts
  - packages/skill-registry/tests/**
  - packages/skill-registry/fixtures/**
objective: Implement the discovery half of @cc/skill-registry per SKILL_REGISTRY_SPEC §5. Sub-agent B-4 scaffolded the package directory; this task fills scan/parse/validate/store/conflict/watcher so the registry can index all three tiers and serve the in-process query API.
expected_output:
  - registry scans all three tiers on cold start and produces a populated SQLite index in <2s for 50 skills
  - chokidar watcher picks up add/modify/delete events and reflects them in the index within 500ms
  - conflict detector logs collisions (same name across tiers) to agent_audit and exposes them via getConflicts()
  - all 6 fixture sets (valid-workspace, valid-project, valid-brain, invalid-tier-mismatch, conflict-same-name, malformed-frontmatter) drive deterministic test outcomes
  - validate() rejects skills missing required frontmatter fields per §3
tests:
  - npm -w @cc/skill-registry test
  - npm -w @cc/skill-registry run typecheck
  - npm -w @cc/skill-registry run lint
rollback: revert PR; if SQLite cache file leaked, delete ~/.cache/cc-skill-registry/index.db
status: open
sla_seconds: 28800
priority: medium
spec_blocker: SKILL_REGISTRY_SPEC §5
related:
  - "[[SKILL_REGISTRY_SPEC]]"
  - "[[AGENT_ORCHESTRATION_SPEC]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
tags: [task, skills, registry, discovery, code-2]
created_at: "2026-05-25T14:50:00Z"
claimed_at: null
claimed_by: null
finished_at: null
---

## Purpose

The skill-registry package was scaffolded by sub-agent B-4 (directory layout, package.json, tsconfig, empty stubs). This task fills in the discovery logic so `BrainOrchestrator` can call `registry.list()` and `registry.get(name)` at startup. Without discovery, every other consumer of skills — manual `/skill <name>` invocation, auto-invocation for Tier 3 skills, REST API at `/api/brain/skills/*`, the `brain skills list` CLI — has nothing to look up. This is the unblocker for §6 (invocation) and §7 (auto-skill-creation).

## Acceptance criteria

- `scan()` walks the three default tier paths (`~/.claude/skills/*/SKILL.md`, `/home/nithu/code/*/.claude/skills/*/SKILL.md`, `~/Obsidian/Brain/03-skills/*.md` excluding `_proposed/_archived/_system/`) and returns a flat array of `RawSkillFile` records.
- `parse(rawFile)` extracts YAML frontmatter via `gray-matter` plus section headers via `remark` and produces a `ParsedSkill` (frontmatter blob + section map).
- `validate(parsed)` checks all required fields per `SKILL_REGISTRY_SPEC §3`; returns `{ok: true, skill}` or `{ok: false, errors: string[]}`. Errors are descriptive and include the offending field path.
- `store` writes the index to `~/.cache/cc-skill-registry/index.db` (better-sqlite3) with schema `(name TEXT PRIMARY KEY, tier TEXT, path TEXT, frontmatter_json TEXT, last_modified INTEGER, validation_passes INTEGER)`. Index supports `getByName`, `listByTier`, `listAll`, `search(query)`.
- `conflict.resolveTierPriority(name, candidates)` returns the winner per tier priority (workspace > project > brain per spec §2) and logs all losers as conflicts.
- `watcher.start()` uses chokidar to watch all three tier paths; on add/change/unlink it re-parses the affected file and updates the index within 500ms (measured in test).
- Public `index.ts` exposes: `createRegistry(opts)`, `Registry.list()`, `Registry.get(name)`, `Registry.search(q)`, `Registry.conflicts()`, `Registry.reindex()`, `Registry.close()`.
- Unit-test coverage ≥ 80% on `scan.ts`, `parse.ts`, `validate.ts`, `conflict.ts`.

## Implementation notes

- **No external network calls.** Discovery is purely filesystem + SQLite. (Invocation in §6 is a separate task and may call LLMs.)
- **Glob library:** use `fast-glob` (already a transitive dep of the monorepo). Honour `.gitignore` semantics for the brain-tier path; do not descend into `_archived/`.
- **Frontmatter parser:** `gray-matter` with YAML-only mode (reject TOML/JSON variants to keep parser surface small).
- **Section headers:** `remark` + `mdast-util-toc` to extract `##` and `###` headings as the section map. Body content is not stored verbatim in the index — only the section header list (avoids index bloat for large brain-tier skills).
- **Tier priority:** workspace (1) > project (2) > brain (3). Lower number wins on collision. Log loser into `conflicts` table — schema `(name TEXT, winning_tier TEXT, losing_tier TEXT, losing_path TEXT, detected_at INTEGER)`.
- **Watcher debounce:** 250ms debounce per path to coalesce rapid sequential writes (editor save patterns). Use chokidar's `awaitWriteFinish: {stabilityThreshold: 250}` option.
- **Validation:** required fields per spec §3 include `name`, `tier`, `description`, `version`, `auto_invocable`. Cross-check `tier` field matches the discovered tier from path; mismatch is a hard validation error.
- **Idempotent reindex:** `reindex()` truncates and rebuilds; callers expect it as a recovery hatch. Use a single transaction.
- **Cache invalidation:** compare `mtimeMs` to stored `last_modified`; only re-parse files whose mtime changed since last scan. Cold-start scan reads every file regardless.

## Test plan

1. **scan.test.ts:** seed three fixture directories with 6 SKILL.md files (2 per tier); `scan()` returns 6 records with correct tier attribution and absolute paths.
2. **parse.test.ts:** parse a valid Tier-3 skill with 4 sections (`## Purpose`, `## When to use`, `## Steps`, `## Pitfalls`); section map contains all 4 keys.
3. **validate.test.ts:** valid skill returns `{ok: true}`; skill with missing `version` returns `{ok: false, errors: ["frontmatter.version: required"]}`; tier-mismatch (path is brain-tier but frontmatter says workspace) returns `{ok: false, errors: ["frontmatter.tier: mismatch (path=brain, declared=workspace)"]}`.
4. **conflict.test.ts:** seed two skills both named `format-code` (one workspace, one brain); `conflict.resolveTierPriority` returns the workspace one; conflicts table contains exactly 1 row with `losing_tier=brain`.
5. **invocation.test.ts (smoke, discovery-only path):** `createRegistry({paths: fixtures}).list()` returns 6 skills in <100ms after warm-cache; <2s on cold cache.
6. **watcher.test.ts:** start watcher on a temp dir; add a SKILL.md file; assert it appears in `registry.list()` within 500ms; modify, assert re-parsed; delete, assert removed.

## Files to create

- `packages/skill-registry/src/scan.ts`, `parse.ts`, `validate.ts`, `store.ts`, `conflict.ts`, `watcher.ts`, `index.ts` — fill the B-4 stubs.
- `packages/skill-registry/tests/scan.test.ts`, `parse.test.ts`, `validate.test.ts`, `conflict.test.ts`, `invocation.test.ts`, `watcher.test.ts`.
- `packages/skill-registry/fixtures/` — 6 fixture sets per `SKILL_REGISTRY_SPEC §5` code skeleton.

Do not implement `invocation/`, `auto-create/`, `cli/`, or `api/` directories — those belong to follow-up tasks.

## Notes

<!-- operator/peer can add inline notes here as the task progresses -->
