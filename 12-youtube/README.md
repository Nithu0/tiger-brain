---
title: YouTube Notes
folder: 12-youtube
created: 2026-05-25
purpose: Distilled YouTube video notes as 4-paper-field MemoryObjects; never full transcripts
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[YOUTUBE_INGESTION_SPEC]]"
tags: [youtube, notes, distilled, memory-object]
---

## Purpose

This folder holds distilled notes from YouTube videos in the 4-paper-field MemoryObject format (claim, evidence, context, applicability). NEVER stores full transcripts — copyright-sensitive verbatim content goes to `_library/youtube/<channel>/` which is gitignored and local-only. Distilled notes are safe to commit and link from MOCs. The `_queue/` subfolder is the operator drop-zone for new URLs; BrainOrchestrator's youtube-queue trigger picks them up, fetches metadata, generates a draft, and routes it through the distillation pipeline.

## Subfolders

| Subfolder | Purpose |
|---|---|
| `_queue/` | Operator-dropped YouTube URLs awaiting orchestrator pickup |

## Naming convention

`<channel-slug>/<YYYY-MM-DD-video-slug>.md` — e.g. `two-minute-papers/2026-05-20-diffusion-explained.md`. Channel slug is lowercase-kebab; date is video publish date; video slug is short kebab.

## Frontmatter convention

Required fields per spec (see [[YOUTUBE_INGESTION_SPEC]]):

- `title` — video title
- `channel` — channel name
- `url` — full YouTube URL
- `published` — YYYY-MM-DD
- `duration` — minutes
- `distilled` — YYYY-MM-DD (when note was created)
- `claim` — single-sentence main thesis (4-paper-field)
- `evidence` — bullet list of supporting points
- `context` — when/why this applies
- `applicability` — projects/domains it touches
- `tags` — topical tags

## Workflow

1. Operator drops URL into `_queue/<short-id>.url` (single line)
2. BrainOrchestrator youtube-queue trigger picks up
3. Distiller fetches metadata + transcript (transcript → `_library/youtube/`, gitignored)
4. Generates draft 4-paper-field MemoryObject in `<channel-slug>/<date-slug>.md`
5. Operator reviews + accepts (or rejects → archived)

## Anti-patterns

- Full transcripts in this folder (copyright; goes to `_library/`)
- Bare links without distillation (no value)
- Notes without `claim` field (defeats MemoryObject contract)
- Personal video annotations (use a project folder instead)

## Related

- [[2026-05-25-brain-upgrade-plan]]
- [[YOUTUBE_INGESTION_SPEC]]
- [[MEMORY_OBJECT_SPEC]]
- [[OBSIDIAN_BRAIN_STRUCTURE]]
