---
title: GitHub Repository Notes
folder: 13-github-repos
created: 2026-05-25
purpose: Distilled GitHub repo notes (metadata + README + manifests only; never clone+execute)
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[GITHUB_DISCOVERY_SPEC]]"
tags: [github, repos, discovery, distilled]
---

## Purpose

This folder holds distilled notes for GitHub repositories discovered via search queries or operator drops. The discovery pipeline NEVER clones or executes repo code — it ingests metadata, README, and manifest files (`package.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`, etc.) only. A license-guard is enforced: GPL-licensed repos cannot generate implementation-tasks (they may inform MOCs but not seed work). The `_queue/` subfolder accepts operator-dropped search queries; the orchestrator runs them, deduplicates against existing notes, and drafts new entries.

## Subfolders

| Subfolder | Purpose |
|---|---|
| `_queue/` | Operator-dropped search queries (one query per file) |

## Naming convention

`<owner>-<repo-name>.md` — e.g. `anthropic-claude-cookbooks.md`, `karpathy-nanogpt.md`. Lowercase; preserve original casing as a single hyphen-joined slug.

## Frontmatter convention

Required fields per spec (see [[GITHUB_DISCOVERY_SPEC]]):

- `owner` — GitHub owner/org
- `repo` — repo name
- `url` — full GitHub URL
- `license` — SPDX identifier (e.g. `MIT`, `Apache-2.0`, `GPL-3.0`)
- `stars` — at discovery time
- `language` — primary language
- `discovered` — YYYY-MM-DD
- `claim` — one-sentence what-it-is
- `applicability` — projects it might serve
- `implementation_allowed` — bool (false for GPL-derivative work)
- `tags` — topical tags

## Workflow

1. Operator drops query into `_queue/<short-id>.query` (one search string)
2. Orchestrator runs GitHub Search API, filters by stars/recency
3. Deduplicates against existing `<owner>-<repo>.md`
4. Drafts metadata + manifest summary
5. License-guard sets `implementation_allowed: false` if copyleft
6. Operator reviews + promotes to MOC links

## Anti-patterns

- Cloning the repo locally (out of scope; this is metadata-only)
- Executing repo code (security risk; ingestion pipeline never runs untrusted code)
- Implementation tasks seeded from GPL repos (license-guard violation)
- Duplicate entries for the same owner/repo (orchestrator dedupes; manual edits should too)

## Related

- [[2026-05-25-brain-upgrade-plan]]
- [[GITHUB_DISCOVERY_SPEC]]
- [[LICENSE_GUARD_SPEC]]
- [[OBSIDIAN_BRAIN_STRUCTURE]]
