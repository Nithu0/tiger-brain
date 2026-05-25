---
title: How to drop a YouTube URL
type: howto
created: 2026-05-25
related:
  - "[[YOUTUBE_INGESTION_SPEC]]"
  - "[[youtube-ingest]]"
  - "[[Runbook-Brain-Upgrade-Workflow]]"
tags: [howto, youtube, queue]
---

# How to drop a YouTube URL for ingestion

1. Copy the YouTube URL
2. Create a new file in THIS folder:
   - Filename: `YYYY-MM-DDTHHMM-<short-slug>.url`
   - Content: just the URL on one line
   - Optional second line: `# tags: <comma-separated>`

## Example file content
```
https://www.youtube.com/watch?v=dQw4w9WgXcQ
# tags: ai, agent-orchestration, research
```

## What happens next
- BrainOrchestrator's `youtube-queue` trigger picks up new files in this folder (when brain-G6 activated; manual `/skill youtube-ingest url=<url>` until then)
- Result: distilled note in `12-youtube/<channel-slug>/<YYYY-MM-DD-video-slug>.md`
- Verbatim transcript: stored in `~/Obsidian/Brain/_library/youtube/<channel>/<slug>/transcript.txt` (gitignored, local-only)
- Original file in `_queue/` moves to `_queue/_processed/` after ingestion

## Channel allowlist
- Trusted channels are listed in `~/Obsidian/Brain/12-youtube/_channels.yaml` (TBD; for now, all channels work but unlisted ones get `confidence: -0.1`)
- Add a channel to the allowlist by editing `_channels.yaml`

## Anti-hype filter
Each video distilled gets `hype_flags`:
- `marketing-language` — too much sales-speak
- `no-evidence` — claims without sources
- `overlap-with-X` — duplicates existing capability we have

Videos with `confidence < 0.5` get marked `needs_re_review: true`.

## Related
- Skill: `[[youtube-ingest]]`
- Spec: `[[YOUTUBE_INGESTION_SPEC]]`
- Folder: `[[12-youtube/README]]`
