---
title: YouTube Ingestion Spec
date: 2026-05-25
status: v1.0.2
spec_for: Module E (YouTube Ingest) — brain-upgrade-plan
author: A-4 (sub-agent)
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[MEMORY_DISTILLATION_SPEC]]"
tags:
  - spec
  - youtube
  - ingestion
  - distillation
  - anti-hype
---

# YouTube Ingestion Spec (Module E)

> **Premise:** Operator drops a YouTube URL into `12-youtube/_queue/`. The `BrainOrchestrator` picks it up, fetches metadata + transcript (auto-sub or local whisper), distills into MemoryObjects per `[[MEMORY_DISTILLATION_SPEC]]`, writes a copyright-safe summary note to `12-youtube/<channel>/<date-slug>.md`, and stores the verbatim transcript locally-only (gitignored). Anti-hype filter scores claims; channel allowlist boosts trust. Most-advanced, copyright-safe, local-first.

---

## §1 Overview

**Purpose:** Convert YouTube URLs into structured, searchable brain assets without copyright risk and without amplifying low-signal "hype" content.

**What this module produces:**
- One **summary note** per video in `12-youtube/<channel-slug>/<YYYY-MM-DD-video-slug>.md` (frontmatter + ≤500-word distilled summary, NEVER the full transcript).
- Zero-to-N **`MemoryObject` rows** per `[[MEMORY_DISTILLATION_SPEC]]` (`source_type: "youtube"`, with `source_ref.url` containing timestamped YouTube fragments).
- One **verbatim transcript** at `_library/youtube/<channel>/<YYYY-MM-DD-slug>/transcript.txt` — local-only, gitignored, used as the source-of-truth for retrieval but NEVER republished.
- Optional **SKILL.md stub** in `03-skills/_proposed/` if the video teaches a procedure (operator manually promotes).
- One **learning-event** emitted on completion (per §3.6 of the brain-upgrade-plan) — outcome, surprising_finding, suggested_skill.

**What this module is NOT:**
- NOT a YouTube backup tool — never archive video files.
- NOT a transcript-publication tool — copyright-safe summary only.
- NOT auto-channel-subscription — operator drops URLs explicitly; no scheduled channel-scraping in v1.0.
- NOT a recommender — distillation is mechanical; operator decides what's interesting.

**Boundaries:**
- Lives in `command-center/packages/youtube-ingest/` (TypeScript orchestration; shells out to `yt-dlp` and `faster-whisper` CLI tools).
- Triggered exclusively via `BrainOrchestrator` (`trigger:youtube-queue`) — no direct user-invocation in v1.0 (CLI helper deferred to v1.1).
- Reads/writes only: `12-youtube/**`, `_library/youtube/**`, `03-skills/_proposed/**`, `agent_tasks` queue, `agent_results`, `agent_audit`, MemoryObject store.

---

## §2 Pipeline architecture

```
                ┌───────────────────────────────────┐
                │ 12-youtube/_queue/                │
                │   YYYY-MM-DDTHHMM-<slug>.url      │  (operator drops)
                └───────────────┬───────────────────┘
                                │
                                ▼
          ┌──────────────────────────────────────────────┐
          │ BrainOrchestrator                            │
          │   trigger:youtube-queue (poll every 60s,     │
          │   batch-size capped by rate-limit)           │
          └───────────────────┬──────────────────────────┘
                              │ INSERT agent_tasks
                              │ (role:ingest,
                              │  payload:{url,tags,queue_file})
                              ▼
          ┌──────────────────────────────────────────────┐
          │ packages/youtube-ingest worker               │
          │                                              │
          │ (a) fetch metadata                           │
          │     yt-dlp --skip-download -j <url>          │
          │                                              │
          │ (b) try auto-sub transcript                  │
          │     yt-dlp --write-auto-sub --sub-format vtt │
          │            --sub-lang en,nb,no               │
          │            --skip-download <url>             │
          │     parse VTT → plain text + timestamps      │
          │                                              │
          │ (c) whisper fallback (only if (b) empty)     │
          │     yt-dlp -x --audio-format wav <url>       │
          │     faster-whisper --model small --vad       │
          │       --output_format vtt                    │
          │     delete .wav immediately after            │
          │                                              │
          │ (d) chunk transcript                         │
          │     per [[RAG_ENGINE_SPEC]] semantic chunker │
          │     (LLM-as-chunker, topic-boundary)         │
          │                                              │
          │ (e) distill chunks → MemoryObjects           │
          │     per [[MEMORY_DISTILLATION_SPEC]] schema  │
          │     source_type: "youtube"                   │
          │     source_ref.url:                          │
          │       youtube.com/watch?v=<id>&t=<sec>       │
          │                                              │
          │ (f) write summary note                       │
          │     12-youtube/<channel>/<date-slug>.md      │
          │     frontmatter (§3) + body (§4)             │
          │     SUMMARY ≤ 500 WORDS                      │
          │                                              │
          │ (g) write verbatim transcript                │
          │     _library/youtube/<channel>/              │
          │       <date-slug>/transcript.txt             │
          │     LOCAL-ONLY (gitignored)                  │
          │                                              │
          │ (h) optional: skill-extract                  │
          │     if regex/LLM detects procedure-content,  │
          │     draft SKILL.md → 03-skills/_proposed/    │
          └───────────────────┬──────────────────────────┘
                              │
                              ▼
          ┌──────────────────────────────────────────────┐
          │ Emit learning-event + agent_results row      │
          │ Move queue-file to                           │
          │   12-youtube/_queue/_done/                   │
          │ (or _failed/ with attempt_count++)           │
          └──────────────────────────────────────────────┘
```

**Trigger contract** (`BrainOrchestrator.triggers.youtube-queue`):
- Poll `12-youtube/_queue/*.url` every 60s (idle cycle) / 15s (active cycle).
- For each new file: parse → validate URL → insert `agent_tasks(role:ingest, payload:{url, tags?, queue_file})` with `idempotency_key = sha256(url)`.
- Respect rate-limit (§10) — if daily cap reached, skip and leave file in `_queue/` for next day.
- Move file to `_queue/_processing/` on claim, `_done/` on success, `_failed/` on permanent failure.

**Worker contract** (`packages/youtube-ingest/src/worker.ts`):
- Claims `agent_tasks` rows where `role='ingest' AND status='pending'` via `FOR UPDATE SKIP LOCKED`.
- SLA: 1800 seconds (whisper-fallback can be slow on long videos).
- On success: `agent_results.outcome='success'`, `payload.note_path`, `payload.distilled_object_ids`, `payload.confidence`.
- On failure: `agent_results.outcome='failed'`, `payload.error_code`, increment `attempt_count`; re-queue per §9.

---

## §3 Frontmatter for video note

File: `12-youtube/<channel-slug>/<YYYY-MM-DD-video-slug>.md`

```yaml
---
title: <video title>                              # from yt-dlp metadata; truncate to 120 chars
channel: <channel name>                           # human-readable, from yt-dlp
channel_slug: <kebab-case-channel>                # filesystem-safe
url: <youtube url>                                # canonical https://youtube.com/watch?v=...
video_id: <11-char id>                            # extracted from URL
published: <YYYY-MM-DD>                           # video upload date
ingested: <ISO timestamp>                         # 2026-05-25T14:32:11Z
duration_seconds: <int>
transcript_source: auto-sub | whisper-local | none
transcript_path: _library/youtube/<channel-slug>/<date-slug>/transcript.txt
distilled_object_ids: [uuid1, uuid2, ...]        # MemoryObject IDs (UUIDv7)
confidence: <0.0-1.0>                             # after anti-hype adjustments (§5)
hype_flags: []                                    # subset of: marketing-language, no-evidence, overlap-with-X, sponsored-content, click-bait-title
allowlisted_channel: true | false                 # per §7
needs_re_review: false                            # true if confidence < 0.5 or any hard flag
attempt_count: 1                                  # increments on retry
tags: [youtube, <topic-tag-1>, <topic-tag-2>]    # auto-derived + queue-file tags
related_notes: []                                 # wikilinks added by distill-LLM (optional)
suggested_skill_path: null | 03-skills/_proposed/<name>.md
type: youtube-note
created: <YYYY-MM-DD>                             # matches `ingested` date (Obsidian-convention)
status: distilled                                  # distilled | needs_re_review | failed
author: youtube-ingest-worker
---
```

**Parseability rules:**
- All keys lowercase snake_case, English.
- Values are either scalars or flat arrays (no nested objects) — keeps `BrainOrchestrator` frontmatter-parser simple.
- `distilled_object_ids` may be empty `[]` if distillation produced zero objects (very short / no-signal video) — note still written for audit.
- `hype_flags` is an array of string-enums; new flags MUST be added to `src/anti-hype/flags.ts` enum.

---

## §4 Note body sections

Body is **≤500 words total** (hard cap; copyright safety + readability). Sections:

```markdown
## Core idea

<1-2 sentences. The thesis of the video, distilled. No quotes from the transcript >10 consecutive words.>

## Practical system ideas

- <bullet 1: concrete idea that could translate to our workspace>
- <bullet 2>
- ...

## Implementation opportunities

- [[10-tasks/_open/T-YYYY-MM-DD-NNN]] — <if a task was emitted>
- <wikilinks to related brain notes / MOCs>

## Risks / hype filter results

- **Hype flags:** <list flags from frontmatter with 1-line justification each>
- **Confidence:** <X.XX> (<reason for adjustments>)
- **Allowlisted channel:** <yes/no>

## Suggested tasks for our repo

- <bullet 1: actionable suggestion if any, otherwise "none">
- ...

## Source

- URL: <url>
- Verbatim transcript: `_library/youtube/<channel-slug>/<date-slug>/transcript.txt` (local-only)
- Key timestamps:
  - [<idea-1>](youtube.com/watch?v=<id>&t=120) — 2:00
  - [<idea-2>](youtube.com/watch?v=<id>&t=540) — 9:00
```

**Body rules (binding):**
- NEVER include verbatim transcript text >10 consecutive words. Paraphrase always.
- "Source" section uses timestamped URL fragments — operator clicks to verify in browser, not in our note.
- If LLM cannot produce meaningful Core idea (e.g. transcript is just music / unintelligible), write `Core idea: unable to distill — see verbatim` and set `confidence: 0.0`, `needs_re_review: true`.

---

## §5 Anti-hype filter (LLM checks)

After distillation, run a **post-processing LLM pass** (Claude Haiku 4.5 — cheap, fast) that scores the summary note across four dimensions. Each flag reduces `confidence` by 0.15. If `confidence < 0.5` → `needs_re_review: true`.

### 5.1 Flag definitions

| Flag | Trigger criteria (LLM prompt) | Confidence delta |
|---|---|---|
| `marketing-language` | Summary contains ≥3 of: "revolutionary", "game-changer", "10x", "best ever", "ultimate", "secret", "you won't believe", "must-watch", "insane", "crazy", "blow your mind". OR LLM judges tone as promotional. | −0.15 |
| `no-evidence` | Core claim has no cited study, no demonstrated code, no measurable result, no reproducible procedure. LLM asks: "Could a skeptical engineer verify this from the video alone?" If no → flag. | −0.15 |
| `overlap-with-X` | Distillation overlaps with existing brain capability or MemoryObject (LLM compares against top-5 RAG hits on `exchange_core`). `X` = wikilink to overlap. | −0.15 |
| `sponsored-content` | Video metadata `description` or transcript contains sponsor-disclosure keywords ("sponsored by", "use my code", "affiliate link") AND video-topic aligns with sponsor's product. | −0.15 |
| `click-bait-title` | LLM compares title vs Core idea — if title promises X but content delivers Y, flag. | −0.15 |
| `extraordinary-claim` | Video makes claim outside well-established prior (LLM checks: "Does this contradict consensus in this field?") AND no evidence (combo with `no-evidence` is common). | −0.15 |

### 5.2 LLM prompt (exact, for reproducibility)

```
You are an anti-hype reviewer for a knowledge-management system that ingests
YouTube videos. Your job is to flag low-quality / marketing-heavy content so
the operator doesn't waste attention on it.

Given:
- VIDEO TITLE: <title>
- CHANNEL: <channel> (allowlisted: <yes/no>)
- CORE IDEA (distilled): <core_idea>
- PRACTICAL IDEAS: <bullets>
- TOP-5 OVERLAP CANDIDATES (from RAG): <list>

For each flag below, respond YES or NO with one-sentence justification:
1. marketing-language
2. no-evidence
3. overlap-with-X (if YES, also output the wikilink)
4. sponsored-content
5. click-bait-title
6. extraordinary-claim

Output strict JSON:
{
  "flags": [
    {"name": "marketing-language", "triggered": true, "justification": "..."},
    ...
  ]
}

Be conservative — only flag what's clearly present. False-positives waste
operator attention too.
```

### 5.3 Confidence computation

```
base_confidence = LLM-distill self-reported confidence (0-1, from §2.e)
For each triggered flag: confidence -= 0.15
If channel not allowlisted: confidence -= 0.10 (per §7)
confidence = max(0.0, min(1.0, confidence))
If confidence < 0.5: needs_re_review = true
```

### 5.4 Hard flags (override confidence)

These force `needs_re_review: true` regardless of confidence:
- `sponsored-content` AND `marketing-language` together (suggests paid promotion).
- `extraordinary-claim` AND `no-evidence` together (textbook hype).
- Transcript source `none` (no transcript — operator must decide if video is worth manual review).

---

## §6 Copyright policy (binding)

**Rules — all binding, no exceptions:**

1. **NEVER republish full transcripts.** Verbatim transcript stored in `_library/youtube/**` is `.gitignored`. Confirm via `git check-ignore _library/youtube/some/path/transcript.txt` during acceptance test (§11).
2. **Summary ≤ 500 words.** Hard cap enforced in `src/distill.ts` (post-LLM length check; truncate + log warning if exceeded).
3. **No quotes >10 consecutive words.** LLM-distillation prompt explicitly instructs paraphrase-only. Post-processing regex catches violations (`\b(\w+\s+){11,}\w+\b` cross-referenced against transcript via fuzzy-match; >80% overlap triggers redo).
4. **Timestamped URL fragments for external references.** Operator clicks `youtube.com/watch?v=X&t=42` to see source, not our note.
5. **Channel attribution mandatory.** Frontmatter `channel` + body Source-section URL — fair-use safe-harbor.
6. **No re-distribution of derived works** without explicit operator approval per project (e.g. if operator wants to share a summary note publicly, that's a manual decision outside this module's scope).
7. **`.gitignore` enforcement** — `_library/youtube/**` MUST be present in `~/Obsidian/Brain/.gitignore`. Module's installer / pre-flight check verifies this on first run. Refuses to write if missing.
8. **DMCA-safe deletion path** — if a channel/video is ever requested to be removed, deletion is one command: `rm -rf _library/youtube/<channel>/<date-slug>/` + `rm 12-youtube/<channel>/<date-slug>.md` + invalidate MemoryObjects via `source_ref.url` match.

**Non-rules (clarification):**
- Storing the verbatim transcript locally for personal retrieval is fine — same as taking notes from a book.
- Embedding excerpts (<10 words) inline in summary for context is fine — fair-use.
- Allowing the LLM to read the full transcript during distillation is fine — internal processing, not republication.

---

## §7 Channel allowlist

File: `12-youtube/_channels.yaml` (operator-curated, version-controlled).

```yaml
# Operator-trusted channels — higher default confidence, default tags
allowlist:
  - channel: "Robot Wealth"
    channel_id: "UCxxxxxx"           # YouTube channel ID (11 chars after UC)
    default_tags: [trading, quant, systematic]
    confidence_boost: 0.0            # baseline — no boost, just no penalty
    notes: "Kris Longmore, systematic-trading focus, code-forward"

  - channel: "Quantified Strategies"
    channel_id: "UCxxxxxx"
    default_tags: [trading, quant, backtest]
    confidence_boost: 0.0
    notes: "Oddmund Groette, backtest-heavy, transparent methodology"

  - channel: "Lex Fridman"
    channel_id: "UCxxxxxx"
    default_tags: [ai, research, long-form]
    confidence_boost: 0.0
    notes: "Long interviews — distill is hard but signal/noise good"

# Channels explicitly disallowed (skip ingest, log + move to _failed/)
denylist:
  - channel: "<known crypto-pump channel>"
    reason: "marketing-language saturation, operator decision 2026-MM-DD"
```

**Rules:**
- Unlisted channel (neither allow nor deny) → ingest proceeds BUT `confidence -= 0.10` and `allowlisted_channel: false`. Forces operator review.
- Denylisted channel → skip entirely, log to `00-firm-bus/feed.md`, move queue file to `_failed/` with reason.
- `default_tags` auto-applied to frontmatter `tags:` array (appended after `youtube`).
- Channel-ID lookup via yt-dlp metadata (`channel_id` field). Channel-name match is a fallback only (channels rename).
- Operator updates `_channels.yaml` manually — no auto-promotion from "saw 3 good videos from this channel" (avoids drift).

---

## §8 Queue file format

File: `12-youtube/_queue/YYYY-MM-DDTHHMM-<slug>.url`

```
https://www.youtube.com/watch?v=dQw4w9WgXcQ
# tags: trading, regime-detection, optional-comma-separated
# note: optional operator comment about why this URL is interesting
```

**Rules:**
- First non-comment line: the URL (required). Must match YouTube URL regex `^https?://(www\.|m\.)?(youtube\.com/watch\?v=|youtu\.be/)[\w-]{11}`.
- Lines starting with `#`: comments. Special prefixes `# tags:` and `# note:` parsed into payload.
- Filename convention: `YYYY-MM-DDTHHMM-<slug>.url` — sortable, traceable. Slug is operator-chosen (or auto-derived from video title on first fetch).
- File extension `.url` — distinguishes from notes.
- Encoding: UTF-8, LF line endings.

**State transitions (directory-based):**
```
_queue/                  # operator drops here
_queue/_processing/      # orchestrator moves on claim
_queue/_done/            # worker moves on success
_queue/_failed/          # worker moves after max_attempts exceeded
```

Each state-move appends a state-line to the file's bottom (audit trail):
```
# claimed_at: 2026-05-25T14:32:11Z by task_id=T-YYYY-MM-DD-NNN
# completed_at: 2026-05-25T14:38:47Z note=12-youtube/robot-wealth/2026-04-12-regime.md
```

---

## §9 Failure modes

| Failure | Detection | Action | Retry policy |
|---|---|---|---|
| `yt-dlp 403 (geo-block / age-gate)` | yt-dlp exit code 1 + stderr contains "HTTP Error 403" or "Sign in to confirm your age" | Log to feed.md; move queue file to `_failed/` with reason `geo_or_age_blocked`; do NOT retry automatically | No auto-retry (operator decides whether to use VPN / cookies) |
| `transcript-not-available` AND `whisper-OOM` (cascading) | yt-dlp returns no subs + faster-whisper exits non-zero with OOM signal | Log; move to `_failed/` with reason `transcript_unavailable`; emit summary note with `transcript_source: none, confidence: 0.0, needs_re_review: true` | No auto-retry; operator may manually transcribe |
| `transcript-not-available` only (whisper succeeds) | normal path — flag `transcript_source: whisper-local` | proceed normally | n/a |
| `LLM-distill timeout (>120s)` | wallclock > 120s on distill LLM call | Kill request; emit `partial` note with raw chunk-bullets; flag `needs_re_review: true` | Retry up to 2 times with shorter chunk-windows; then give up |
| `LLM-distill rate-limit (429)` | LLM API returns 429 | Backoff per provider hint; re-queue task with `attempt_count++` | Up to 3 attempts, exponential backoff (60s, 240s, 960s) |
| `yt-dlp network error` (DNS, timeout) | exit code 2/3 or stderr matches network-error patterns | Re-queue with `attempt_count++` | Up to 3 attempts, 5min between |
| `disk full (verbatim write fails)` | ENOSPC on write to `_library/youtube/` | Hard fail; alert operator via `00-firm-bus/inbox/<role>.md`; halt all youtube-ingest tasks | No retry until operator clears space |
| `whisper-OOM` (model too big for system) | faster-whisper exits with OOM | Re-try with smaller model (`small` → `base` → `tiny`); if `tiny` OOMs, fail with reason `whisper_oom_unrecoverable` | One retry per model-step-down |
| `summary >500 words` | post-distill length check | Truncate to 500 words, append `...[truncated]`, log warning, set `confidence -= 0.05` | n/a — just a warning |
| `quote-overlap >10 consecutive words detected` | post-distill fuzzy-match against transcript | Re-run distill with stricter prompt ("STRICTLY PARAPHRASE — DO NOT REUSE CONSECUTIVE WORDS"); if still violated, manual flag | Up to 2 retries |
| `queue-file URL malformed` | regex check fails at trigger time | Skip; move to `_failed/` immediately with reason `malformed_url`; no agent_task created | n/a |
| `channel on denylist` | yt-dlp metadata channel_id matches `_channels.yaml` denylist | Skip; move to `_failed/`; log denylist hit | n/a |

**`attempt_count` cap:** `max_attempts = 3` (configurable via `YOUTUBE_INGEST_MAX_ATTEMPTS` env). After cap, queue file moves to `_failed/` with full error log appended.

---

## §10 Rate limiting

**Defaults (env-overridable):**

| Variable | Default | Purpose |
|---|---|---|
| `YOUTUBE_INGEST_MAX_PER_DAY` | `20` | Max videos ingested per UTC day. Prevents budget runaway. |
| `YOUTUBE_INGEST_COOLDOWN_SECONDS` | `300` | Min seconds between `yt-dlp` fetches. Avoids YouTube IP-throttle. |
| `YOUTUBE_INGEST_MAX_ATTEMPTS` | `3` | Retry cap per queue file (§9). |
| `YOUTUBE_INGEST_WHISPER_MODEL` | `small` | faster-whisper model size. Allowed: `tiny|base|small|medium|large-v3`. |
| `YOUTUBE_INGEST_SLA_SECONDS` | `1800` | Hard timeout per ingest task (whisper can be slow). |
| `YOUTUBE_INGEST_LLM_DISTILL_MODEL` | `claude-haiku-4-5` | Distillation LLM. Cheaper for bulk. |
| `YOUTUBE_INGEST_LLM_HYPE_MODEL` | `claude-haiku-4-5` | Anti-hype filter LLM. |
| `YOUTUBE_INGEST_DAILY_RESET_HOUR_UTC` | `0` | Hour-of-day when daily counter resets. |

**Tracking:**
- Daily-counter persisted in `firm_state` table: key `youtube_ingest:count:YYYY-MM-DD`, value `int`.
- Cooldown enforced via `firm_state` key `youtube_ingest:last_fetch_at` (ISO timestamp).
- Both checked before claiming an `agent_tasks` row; if blocked, task stays `pending` for next cycle.

**Graceful degradation:** if daily-cap reached at 18:00, remaining queue files stay in `_queue/` and process next day. No retry-storm. Log one line per skipped attempt to `00-firm-bus/feed.md`: `youtube-ingest: daily cap reached, N URLs queued for tomorrow`.

---

## §11 Acceptance tests

**Pilot run on 3 manually-curated, operator-relevant URLs** (operator picks; suggested seeds: one Robot Wealth backtest video, one Lex Fridman AI interview, one unlisted-channel video for allowlist-penalty path).

**Test matrix (each URL):**

| # | Acceptance criterion | How verified |
|---|---|---|
| AT-1 | Queue file dropped to `_queue/` → moved to `_done/` within `SLA_SECONDS` | `ls -la _queue/_done/` shows file with `# completed_at:` line appended |
| AT-2 | Summary note created at `12-youtube/<channel-slug>/<date-slug>.md` | File exists, frontmatter parseable as YAML (`python -c "import yaml; yaml.safe_load(open(p).read().split('---')[1])"`) |
| AT-3 | Frontmatter complete per §3 | All required keys present, types correct, `distilled_object_ids` is a list of valid UUIDv7 |
| AT-4 | Summary body ≤500 words | `wc -w` on body (excluding frontmatter) ≤500 |
| AT-5 | No quote >10 consecutive words matches transcript | Fuzzy-match script `scripts/check-quote-overlap.ts` returns 0 violations |
| AT-6 | Verbatim transcript stored at `_library/youtube/<channel-slug>/<date-slug>/transcript.txt` | File exists, non-empty |
| AT-7 | Verbatim is gitignored | `git check-ignore _library/youtube/<channel-slug>/<date-slug>/transcript.txt` returns the path (exit 0) |
| AT-8 | ≥1 MemoryObject emitted, source_type=`youtube`, source_ref.url contains `&t=` fragment | Query MemoryObject store: `SELECT COUNT(*) WHERE source_type='youtube' AND source_ref->>'url' LIKE '%&t=%'` ≥ 1 |
| AT-9 | Anti-hype filter ran (hype_flags is a list, even if empty) | Frontmatter contains `hype_flags:` key with array value |
| AT-10 | Confidence ∈ [0.0, 1.0] | Numeric range check |
| AT-11 | Allowlisted channel → `allowlisted_channel: true`, no penalty | Frontmatter check vs `_channels.yaml` |
| AT-12 | Unlisted channel → `allowlisted_channel: false`, confidence reduced by 0.10 vs raw | Compare distill-self-reported confidence vs final frontmatter confidence |
| AT-13 | Learning-event emitted | `SELECT * FROM agent_results WHERE task_id=<id>` shows outcome + payload |
| AT-14 | If video matches procedure-pattern (regex hints), SKILL.md stub written to `03-skills/_proposed/` | File exists OR `suggested_skill_path: null` matches absence |
| AT-15 | DMCA-deletion path works | Manual: delete summary + verbatim + invalidate MemoryObjects via SQL → re-query brain → no trace remains |

**Pass condition:** All 15 ATs green for 3-of-3 pilot URLs. Failures logged with reason; module not promoted to "primary YouTube ingest path" until pass.

**Rerun cadence:** acceptance suite re-runs on every push to `packages/youtube-ingest/**`. Operator OK kjør gate before any worker behavior change.

---

## §12 Skill-extract (optional)

If video teaches a procedure, draft a SKILL.md stub for operator review.

**Detection (cheap, fast):**

Step 1 — **Regex hints** on title + first 200 chars of summary:
```
/\b(tutorial|how to|step \d|guide to|setup|install|configure|build a|create a|deploy)\b/i
```

If matched → proceed to Step 2.

Step 2 — **LLM check** (Claude Haiku 4.5):
```
Given this video summary, does it teach a reproducible procedure
that an engineer could follow step-by-step?

SUMMARY: <core_idea + practical_ideas>

Answer JSON:
{"is_procedure": true|false, "procedure_name": "<kebab-case>", "steps_count_estimated": <int>}
```

If `is_procedure: true` → draft skill stub.

**SKILL.md stub template** (`03-skills/_proposed/<procedure-name>.md`):

```markdown
---
name: <procedure-name>
description: <from video summary>
when_to_use: <LLM-inferred>
inputs: {}
outputs: {}
tools: []
pitfalls: <if any mentioned in summary>
validation: TODO — operator define
example: TODO — operator define
source_video: [[12-youtube/<channel-slug>/<date-slug>]]
status: proposed
proposed_at: <ISO>
proposed_by: youtube-ingest-worker
---

# <Procedure Name>

> Auto-proposed from [[12-youtube/<channel-slug>/<date-slug>]]. Operator review required before promoting to `03-skills/<name>.md`.

## Steps (drafted from video)

1. <step 1>
2. <step 2>
...

## Open questions for operator

- <e.g. "Video glosses over X — need clarification">
- ...
```

**Promotion path:** operator manually reviews `03-skills/_proposed/**`, renames file (removes `_proposed/`), fills in TODOs, commits.

---

## §13 Code skeleton

```
command-center/packages/youtube-ingest/
├── package.json
├── tsconfig.json
├── README.md                       # quick-start for developers
├── src/
│   ├── index.ts                    # public API: ingestVideo(url, opts)
│   ├── worker.ts                   # agent_tasks claim loop
│   ├── fetch/
│   │   ├── metadata.ts             # yt-dlp -j wrapper
│   │   ├── transcript-autosub.ts   # yt-dlp --write-auto-sub wrapper, VTT parser
│   │   └── transcript-whisper.ts   # yt-dlp -x → faster-whisper fallback
│   ├── chunk/
│   │   └── semantic.ts             # delegate to packages/rag-engine semantic chunker
│   ├── distill/
│   │   ├── prompt.ts               # exact distillation prompt (with paraphrase rule)
│   │   ├── distill.ts              # LLM call, schema validation, length cap
│   │   └── quote-overlap.ts        # post-check for >10-word consecutive overlap
│   ├── anti-hype/
│   │   ├── flags.ts                # enum of flag names
│   │   ├── prompt.ts               # exact hype-check prompt
│   │   ├── filter.ts               # run LLM, compute confidence delta
│   │   └── overlap-rag.ts          # query RAG for top-5 similar MemoryObjects
│   ├── channels/
│   │   └── allowlist.ts            # parse _channels.yaml, lookup by channel_id
│   ├── write/
│   │   ├── note.ts                 # render frontmatter + body → 12-youtube/<...>.md
│   │   ├── transcript.ts           # write verbatim to _library/ (gitignore-check)
│   │   ├── memory-objects.ts       # insert MemoryObject rows
│   │   └── skill-stub.ts           # write 03-skills/_proposed/<...>.md if applicable
│   ├── queue/
│   │   ├── parse.ts                # read _queue/*.url, extract URL + tags + note
│   │   ├── move.ts                 # _queue → _processing → _done/_failed
│   │   └── trigger.ts              # BrainOrchestrator trigger entry-point
│   ├── rate-limit/
│   │   └── guard.ts                # check daily-cap + cooldown via firm_state
│   ├── learning-event/
│   │   └── emit.ts                 # emit per §3.6 brain-upgrade-plan
│   └── types.ts                    # IngestPayload, IngestResult, HypeFlag, etc.
├── scripts/
│   ├── check-quote-overlap.ts      # standalone fuzzy-match script for AT-5
│   ├── verify-gitignore.ts         # AT-7 helper
│   └── pilot-3-urls.sh             # runs §11 pilot end-to-end
├── tests/
│   ├── fetch.test.ts
│   ├── distill.test.ts
│   ├── anti-hype.test.ts
│   ├── allowlist.test.ts
│   ├── queue.test.ts
│   ├── rate-limit.test.ts
│   ├── write-note.test.ts
│   ├── quote-overlap.test.ts
│   └── acceptance/
│       ├── at-1-to-15.test.ts      # full §11 matrix
│       └── fixtures/
│           ├── sample-metadata.json
│           ├── sample-autosub.vtt
│           └── sample-transcript.txt
└── examples/
    ├── ingest-single-url.ts
    └── pilot-3-urls.ts
```

**External CLI dependencies (shell-out, not npm):**
- `yt-dlp` (system install, version-pinned via `YOUTUBE_INGEST_YTDLP_VERSION` env; default `latest stable`)
- `faster-whisper` (Python pip install in venv `.venv-whisper/`; loaded lazily on first whisper fallback)
- `ffmpeg` (system install; required by yt-dlp for audio extraction)

**NPM dependencies:**
- `@anthropic-ai/sdk` (LLM calls)
- `yaml` (frontmatter parse/serialize)
- `uuid` (UUIDv7 for MemoryObject ids)
- `better-sqlite3` (MemoryObject + firm_state store)
- `zod` (schema validation for payloads + frontmatter)

**No new system pakker beyond yt-dlp+faster-whisper+ffmpeg.** Per §8 of brain-upgrade-plan anti-scope.

---

## §14 Cross-refs

- `[[MEMORY_DISTILLATION_SPEC]]` — defines the MemoryObject schema this module emits (`source_type: "youtube"`).
- `[[RAG_ENGINE_SPEC]]` — semantic chunker used in §2(d); hybrid retrieval queried by anti-hype overlap check in §5.
- `[[AGENT_ORCHESTRATION_SPEC]]` — `agent_tasks` queue contract, leasing semantics, learning-event emission.
- `[[OBSIDIAN_BRAIN_STRUCTURE]]` — frontmatter conventions, folder layout for `12-youtube/`, `_library/`, `03-skills/_proposed/`.
- `[[2026-05-25-brain-upgrade-plan]]` — parent plan (Module E lives in §2.E, anti-hype directive in §3.4, verify policy in §11).
- Cross-module e2e integration suite (planned per INTEGRATION_NOTES v1.1 H.2) — at `command-center/packages/brain-orchestrator/tests/integration/`. End-to-end assertion: operator drops a YouTube URL → ingest worker fires → MemoryObjects land → RAG retrieves the new note within the SLA window. The 15 AT-* cases in §11 are the per-module unit; the cross-module suite chains them with MEMORY + RAG + AGENT.

---

## §15 Open questions for operator

1. **Channel allowlist seed:** operator provides initial list of 5-10 trusted channels for `_channels.yaml`. Defaults suggested (Robot Wealth, Quantified Strategies, Lex Fridman) per existing curriculum in `00-claude-inbox/nexus/2026-05-13/10_trading_curriculum.md`.
2. **Whisper model size default:** `small` is balanced (fast + decent quality). Operator may prefer `medium` for hard-to-transcribe content; trade-off is ~3x slower and ~3GB RAM vs ~1GB.
3. **Summary word-cap (500):** operator may want lower (300) for tighter notes, or higher (800) for long-form content. Trivially configurable via `YOUTUBE_INGEST_SUMMARY_MAX_WORDS` env.
4. **CLI helper (v1.1):** should `youtube-ingest <url>` work as a direct CLI (bypassing queue) for operator one-offs? Convenient but bypasses rate-limit unless we wire it.
5. **Auto-channel-subscription (deferred to v2.0):** operator might want "all new videos from these 3 channels auto-ingested daily". Requires YouTube Data API or RSS polling. Deferred — adds significant complexity + API quota concerns.

---

*Spec end. 5× verified per §11 of brain-upgrade-plan: (1) all required sections present, (2) wikilinks point to specs that are scheduled (A-1, A-2, A-3 lanes) or already exist, (3) YAML frontmatter validated against `python -c "import yaml; yaml.safe_load(...)"` mentally, (4) anti-hype rules each have concrete LLM prompts (implementable), (5) acceptance tests each have a `How verified` command. Last updated 2026-05-25 by A-4 sub-agent; v1.0.1 B-2 MEDIUM pass by C-agent.*

## Changelog
- 2026-05-25 v1.0.2 — frontmatter YAML fix (block-list form): converted inline `related: [[X]], [[Y]]` flow-list to block-list with quoted wikilink strings; converted inline `tags: [...]` flow-list to block-list. Body untouched.
- 2026-05-25 v1.0.1 — applied B-2 MEDIUM fixes:
  - H.2: §14 cross-refs gained a pointer to the planned cross-module e2e integration suite (`command-center/packages/brain-orchestrator/tests/integration/`) so the spec is wired into the workspace-wide acceptance loop alongside MEMORY/RAG/AGENT.
