---
task_id: T-2026-05-25-003
title: Build yt-dlp wrapper in @cc/youtube-ingest (metadata + auto-sub transcript)
from: operator
to: code-2
owner: unclaimed
project: command-center
branch: code-2/youtube-ytdlp-wrapper
files_allowed:
  - packages/youtube-ingest/src/fetch.ts
  - packages/youtube-ingest/src/types.ts
  - packages/youtube-ingest/src/errors.ts
  - packages/youtube-ingest/tests/fetch.test.ts
  - packages/youtube-ingest/tests/fixtures/**
objective: Implement steps (a) fetch metadata and (b) auto-sub transcript from YOUTUBE_INGESTION_SPEC §2. Wrap yt-dlp as a typed Node API; return structured VideoMetadata + Transcript objects. No whisper fallback in this task (separate task T-2026-05-25-XXX).
expected_output:
  - fetch.ts compiles + exports fetchMetadata(url) and fetchAutoSubTranscript(url, langs)
  - both functions return typed promises; errors propagate as YtDlpError subclasses
  - 6 unit tests pass (valid url, restricted-video, no-sub-available, multi-lang preference, VTT parse, error mapping)
  - integration test (skipped in CI; runnable locally with INTEGRATION=1) hits one allowlisted channel video end-to-end
tests:
  - npm -w @cc/youtube-ingest test -- fetch
  - npm -w @cc/youtube-ingest run typecheck
  - INTEGRATION=1 npm -w @cc/youtube-ingest test -- fetch.integration
rollback: revert PR; no production side-effects (read-only against YouTube)
status: open
sla_seconds: 14400
priority: medium
spec_blocker: YOUTUBE_INGESTION_SPEC §2
related:
  - "[[YOUTUBE_INGESTION_SPEC]]"
  - "[[RAG_ENGINE_SPEC]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
tags: [task, youtube, ingestion, yt-dlp, code-2]
created_at: "2026-05-25T14:50:00Z"
claimed_at: null
claimed_by: null
finished_at: null
---

## Purpose

The first two stages of the YouTube ingestion pipeline (`[[YOUTUBE_INGESTION_SPEC]]` §2 steps a + b) wrap yt-dlp behind a typed Node API. Step (a) pulls structured video metadata (title, channel, duration, upload_date, lang) via `yt-dlp --skip-download -j`. Step (b) attempts to fetch auto-generated subtitles in priority `en, nb, no` and parses VTT to plain text + timestamp pairs. Whisper fallback (step c) is explicitly out of scope for this task — it depends on disk-space management and audio extraction that warrant their own scope. Downstream stages (chunk, distill, write-note) cannot start until (a)+(b) ship; this task is the discovery + transcript foundation.

## Acceptance criteria

- `fetch.ts` exports `fetchMetadata(url: string, opts?: FetchOpts): Promise<VideoMetadata>` and `fetchAutoSubTranscript(url: string, langs?: string[]): Promise<Transcript | null>`.
- `VideoMetadata` type includes: `video_id`, `title`, `channel`, `channel_id`, `duration_seconds`, `upload_date`, `lang`, `view_count`, `description`, `original_url`.
- `Transcript` type: `{lang: string, segments: Array<{start: number, end: number, text: string}>, plain_text: string}`. Returns `null` (not throws) when no auto-sub available.
- `langs` param defaults to `["en", "nb", "no"]` per spec §2(b); honours order — first available language wins.
- VTT parser handles standard VTT cue blocks + auto-generated overlapping cues (deduplicate consecutive identical text per spec §2(b) note).
- Errors are typed via `YtDlpError` and subclasses: `YtDlpNotInstalled`, `YtDlpVideoUnavailable`, `YtDlpAgeRestricted`, `YtDlpRateLimited`, `YtDlpUnknownError`. Error mapping derives from yt-dlp stderr regex.
- Subprocess invocation uses `execa` (already a workspace dep), with `timeout: 60_000` and `maxBuffer: 50 * 1024 * 1024`. Never invokes yt-dlp via shell-interpolation.
- All 6 unit tests pass against recorded fixtures (no live YouTube hits in CI).
- `npm -w @cc/youtube-ingest run typecheck` passes.

## Implementation notes

- **yt-dlp binary:** assume installed and on `$PATH`. On `ENOENT`, throw `YtDlpNotInstalled` with install instructions for both Linux (`pip install -U yt-dlp` or `apt`) and macOS (`brew install yt-dlp`).
- **Metadata call:** `yt-dlp --skip-download --no-warnings -j <url>`. Parse stdout as a single JSON object. Map fields to `VideoMetadata` — `id` → `video_id`, `uploader` → `channel`, `uploader_id` → `channel_id`, `duration` → `duration_seconds`, `upload_date` (YYYYMMDD) → ISO date, `language` → `lang` (fall back to `null` if absent).
- **Auto-sub call:** `yt-dlp --write-auto-sub --sub-format vtt --sub-langs <langs-csv> --skip-download --no-warnings -o '<tmpdir>/%(id)s' <url>`. After exit, scan `<tmpdir>` for `<id>.<lang>.vtt`; pick the first matching the priority order.
- **Tmpdir:** use `fs.mkdtemp(os.tmpdir() + '/cc-ytdlp-')` and clean up in `finally` block even on throw.
- **VTT parsing:** roll a tiny parser (no NPM dep) — split on blank lines, parse timestamp lines via regex `/(\d+:\d{2}:\d{2}\.\d{3})\s+-->\s+(\d+:\d{2}:\d{2}\.\d{3})/`, accumulate text. Strip HTML-like tags `<c>`, `</c>`, `<00:00:00.000>` markers from auto-subs.
- **Deduplication:** consecutive cues with identical text (common in auto-generated subs) are merged into one cue spanning the full range — keeps `plain_text` clean.
- **No retries in this layer.** Rate-limit handling and exponential backoff live in the worker (`packages/youtube-ingest/src/worker.ts`, future task). `fetch.ts` is pure: call → result or typed error.
- **Logging:** `pino` child logger named `youtube-ingest:fetch`. Log video_id + duration on success, error_code + stderr-tail on failure.
- **Channel allowlist:** NOT enforced here. Allowlist enforcement (spec §7) belongs in the worker before this is called.

## Test plan

1. **fetchMetadata happy path:** mock execa to return a recorded JSON for a Veritasium video; assert all `VideoMetadata` fields populated correctly, `duration_seconds` is integer, `upload_date` is ISO.
2. **fetchMetadata video-unavailable:** mock execa to exit non-zero with stderr `ERROR: Video unavailable`; assert throws `YtDlpVideoUnavailable` with original URL in message.
3. **fetchAutoSubTranscript happy path:** seed tmpdir with a fixture `<id>.en.vtt` containing 5 cues; mock execa exit-0; assert returns `Transcript` with 5 segments and concatenated `plain_text`.
4. **fetchAutoSubTranscript no-sub-available:** mock execa exit-0 with empty tmpdir; assert returns `null` (not throws).
5. **fetchAutoSubTranscript multi-lang preference:** seed tmpdir with both `<id>.no.vtt` and `<id>.en.vtt`; call with `langs=["en","nb","no"]`; assert returned transcript has `lang === "en"`.
6. **VTT parser dedup:** parse a fixture VTT with 3 consecutive identical-text cues; assert merged into 1 segment spanning the full time range.
7. **(integration, skipped in CI)** fetch metadata + transcript for one allowlisted Veritasium video; assert non-null transcript and sensible `duration_seconds`.

## Files to create

- `packages/youtube-ingest/src/fetch.ts` — the wrapper.
- `packages/youtube-ingest/src/types.ts` — `VideoMetadata`, `Transcript`, `FetchOpts`.
- `packages/youtube-ingest/src/errors.ts` — `YtDlpError` + subclasses.
- `packages/youtube-ingest/tests/fetch.test.ts` — 6 unit tests + 1 integration test (skipped without `INTEGRATION=1`).
- `packages/youtube-ingest/tests/fixtures/metadata-veritasium.json`, `transcript-en.vtt`, `transcript-multi-lang/` — recorded fixtures.

Do not implement worker.ts, queue management, channel allowlist, distillation, or note-writing. Those are downstream tasks.

## Notes

<!-- operator/peer can add inline notes here as the task progresses -->
