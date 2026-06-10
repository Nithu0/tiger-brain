# WF lane replenish-6 — youtube channel-expand queue expander

Date: 2026-06-08
Branch: `feat/wf-knowledge-ingest-channel-expand` (commit `4ffbe52`)
Status: BUILD complete, committed, NOT pushed (push gated on operator "OK kjør")

## Task
S1 BUILD: expand channel/playlist URLs in the youtube ingest queue to per-video
.url files via `yt-dlp --flat-playlist`, behind `YOUTUBE_INGEST_CHANNEL_EXPAND=0`
+ `YOUTUBE_INGEST_CHANNEL_MAX=10`. Unblocks the 3 queued channel files
(fabervaale-eng, better-system-trader, quantified-strategies).

## Spec-vs-repo correction (important)
The lane prompt asked for "youtube-ingest src/channel.ts" — that TS-package shape
exists in **command-center**, not in this repo (ai-assistent). Here the youtube
ingest path is a firehose **.mjs** script: `scripts/firehose/ingest-youtube.mjs`
+ the brain `youtube-queue` trigger. `packages/` only contains `shared`. I
honored the INTENT but matched THIS repo's conventions: a `.mjs` CLI +
`.test.mjs` using `node:test`, same as the other firehose scripts.

## What I built
- `scripts/firehose/expand-channel-queue.mjs` — standalone CLI.
  - Scans `~/Obsidian/Brain/12-youtube/_queue/*.url`.
  - Classifies each URL: single-video (`watch?v=` / `youtu.be/` / `shorts/`,
    incl. video-in-playlist) → left alone; channel/playlist
    (`channel/`,`@handle`,`c/`,`user/`,`playlist?`) → expanded.
  - Enumerates videos with `yt-dlp --flat-playlist --no-warnings -I 1:MAX
    --print "%(id)s\t%(title)s"` — metadata only, NO download, NO transcript.
  - Writes one per-video `.url` per discovered video
    (`<source-slug>--v-<videoId>.url`), carrying the source `# tags:` line
    forward verbatim + a `# expanded-from:` lineage note with the title.
  - Moves the source channel file to `_queue/_expanded/` (reversible, not
    deleted).
  - Idempotent: existing per-video files are not re-written.
  - Flags: `YOUTUBE_INGEST_CHANNEL_EXPAND=1` (default OFF → CLI no-op exit 0),
    `YOUTUBE_INGEST_CHANNEL_MAX` (default 10). CLI args `--queue-dir`, `--max`,
    `--dry-run`.
- `scripts/firehose/expand-channel-queue.test.mjs` — 21 hermetic tests
  (in-memory fs mock + injected yt-dlp, no network/binary). Covers
  classification, file parsing, flat-playlist parsing, file synthesis, cap,
  idempotency, yt-dlp-throw resilience, empty-enumeration handling, dry-run,
  unreadable-dir.

## Constraint compliance
- Behaviour-neutral on deploy: standalone CLI, not wired into any always-on
  loop; default-OFF; nothing imports it.
- No Railway flips, no push, no trades, no strategy/risk/gate/ADX/regime/
  indicator code touched.
- No shared package touched, no TS in scope → husky pre-commit skipped tsc
  (correctly). Pre-push (worker+api tests) untouched.

## Verification (real data, read-only)
- 21/21 unit tests green (`node --test scripts/firehose/expand-channel-queue.test.mjs`).
- Flag-OFF CLI: no-op, exit 0.
- Live `yt-dlp` against fabervaale channel (UCQTN8r4TYJUk2OXrkHyfVSQ), cap 2,
  in a temp dir: generated 2 valid per-video files, archived source to
  `_expanded/`. Sample output:
  ```
  https://www.youtube.com/watch?v=FawPrRUGNpk
  # tags: fabervaale-eng, operator-requested
  # expanded-from: 2026-06-01T1300-fabervaale-eng-channel title="The Only Liquidity Guide You'll Ever Need"
  ```
  These match exactly what the single-video ingest path expects.

## How to use (when operator activates)
```
YOUTUBE_INGEST_CHANNEL_EXPAND=1 \
  node scripts/firehose/expand-channel-queue.mjs --max=10
```
Then the existing single-video path / brain youtube-queue trigger ingests the
emitted per-video files as normal. Run with `--dry-run` first to preview counts.

## Notes / follow-ups
- This does NOT auto-run anywhere yet. To make channel files self-expand, a
  future change would call `expandQueue()` from the brain queue-watcher before
  the single-video pass — that's a separate (command-center / brain) wiring task
  and would need its own flag flip.
- yt-dlp 2026.03.17 confirmed installed at `~/.local/bin/yt-dlp`.
- Branch is off LOCAL main (4 commits ahead of origin: reddit-oauth etc.).
  Behaviour-neutral, so no conflict risk, but note it when opening a PR.
