---
name: youtube-ingest
description: Run the youtube-ingest pipeline on a URL (or drain the queue) — fetches metadata, transcript, distills into a brain note
tier: brain
project_scope: workspace
when_to_use: operator drops a URL in `12-youtube/_queue/`, OR runs manually with a single URL; keywords "ingest video", "youtube transcript", "distill talk", "process queue"
inputs:
  - name: url
    type: url
    required: false
    default: drain-queue
  - name: force_whisper
    type: bool
    required: false
    default: false
  - name: channel_override
    type: string
    required: false
outputs:
  - note_path: string
  - transcript_path: string
  - distill_confidence: number
  - skill_stub_created: bool
tools_required: [Bash, Write, Read]
cost_estimate: medium
cache_strategy: persistent
auto_invocable: false
created: 2026-05-25
created_by: operator
confidence: 0.7
validation_passes: 0
related: ["[[SKILL_REGISTRY_SPEC]]", "[[YOUTUBE_INGESTION_SPEC]]", "[[2026-05-25-brain-upgrade-plan]]"]
tags: [skill, brain, youtube, ingestion, distillation]
---

## Purpose

Pull a YouTube video's metadata + transcript (auto-captions first, whisper fallback), semantically chunk it, distill into a brain note at `12-youtube/<channel>/<date-slug>.md` and store verbatim transcript under `_library/youtube/<channel>/<date-slug>/transcript.txt`. The distilled note holds the 4-field MemoryObject summary plus operator-curated insights — verbatim is the source of truth, distilled is the index. Designed to handle both manual URLs and queue-drain mode.

## When to use

- Operator drops URL into `12-youtube/_queue/<anything>.txt`
- Manual invocation on a specific video the operator wants captured
- Re-ingestion when distill-LLM upgraded or transcript regenerated
- **Anti-patterns:** never re-publish full transcript outside `_library/` (copyright); never ingest geo-blocked videos without proxy; never auto-ingest from algorithm-recommended feeds (operator-curated queue only)

## Inputs

| Arg | Type | Required | Default | Notes |
|---|---|---|---|---|
| `url` | url | no | drain-queue | YouTube URL; if omitted, drains `12-youtube/_queue/` |
| `force_whisper` | bool | no | false | Skip auto-caption fetch, go straight to whisper |
| `channel_override` | string | no | from-metadata | Override channel folder name |

## Steps

1. Resolve input: if `url` given, treat as single; else read all files in `12-youtube/_queue/`
2. Run `yt-dlp --dump-json --no-warnings <url>` to get metadata (title, channel, upload_date, duration)
3. Attempt to fetch auto-captions: `yt-dlp --write-auto-sub --sub-lang en,no --skip-download <url>`
4. If no captions OR `force_whisper=true`: download audio (`yt-dlp -x --audio-format mp3`) and run whisper locally
5. Semantic chunk transcript via LLM-as-chunker (Haiku) — topic boundaries, not char count
6. Call memory-engine distill on full transcript: returns 4-field MemoryObject
7. Write verbatim to `_library/youtube/<channel>/<date-slug>/transcript.txt`
8. Write distilled note to `12-youtube/<channel>/<date-slug>.md` with frontmatter (`url`, `channel`, `published`, `duration`, `confidence`, `tags`)
9. Run skill-extract LLM pass — if video teaches a procedure, draft a SKILL.md stub in `03-skills/_proposed/`
10. Remove the queue file on success; on failure, leave queue file and write error to `00-firm-bus/feed.md`

## Tools / commands

```bash
# Single URL
yt-dlp --dump-json --no-warnings "https://youtube.com/watch?v=ID" > /tmp/meta.json
yt-dlp --write-auto-sub --sub-lang en,no --skip-download -o '/tmp/yt/%(id)s' "$URL"

# Whisper fallback
yt-dlp -x --audio-format mp3 -o '/tmp/yt/%(id)s.%(ext)s' "$URL"
whisper /tmp/yt/${ID}.mp3 --model medium --language en --output_dir /tmp/yt/

# Drain queue
for f in /home/nithu/Obsidian/Brain/12-youtube/_queue/*.txt; do
  /home/nithu/code/command-center/_bin/youtube-ingest.sh --url "$(cat "$f")"
done
```

## Pitfalls

- Copyright — verbatim transcript MUST stay local under `_library/`, never re-publish
- Geo-blocking — yt-dlp will fail silently; log to feed.md
- OOM on long videos (>3h) — chunk transcript before LLM distill, limit whisper RAM
- Channel name with slashes/unicode — sanitize for folder name
- Duplicate ingestion — check `12-youtube/<channel>/<date-slug>.md` exists before writing
- Auto-caption quality varies; if confidence < 0.5, retry with whisper

## Validation checks

1. Distilled note exists at `12-youtube/<channel>/<date-slug>.md` with valid frontmatter
2. Verbatim transcript exists at `_library/youtube/<channel>/<date-slug>/transcript.txt` and is non-empty
3. Distilled note contains at least one wikilink back to a MOC or related skill
4. `confidence` field present and in `[0, 1]`
5. Queue file removed (on success) or error logged (on failure)

## Example usage

```
/skill youtube-ingest url=https://youtube.com/watch?v=dQw4w9WgXcQ
```

Drain queue:

```
/skill youtube-ingest
```

Force whisper for low-quality auto-caption:

```
/skill youtube-ingest url=https://youtube.com/watch?v=ID force_whisper=true
```

## Related

- [[SKILL_REGISTRY_SPEC]]
- [[YOUTUBE_INGESTION_SPEC]]
- [[2026-05-25-brain-upgrade-plan]]
- [[brain-distill-daily]]
- [[OBSIDIAN_BRAIN_STRUCTURE]]
