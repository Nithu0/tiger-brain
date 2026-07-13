---
title: Youtube-MOC
type: moc
created: 2026-05-25
purpose: Index of the 12-youtube/ folder + URL-drop ingestion pipeline (metadata + transcript + anti-hype + distill)
related: [[2026-05-25-brain-upgrade-plan]]
tags: [moc, youtube, ingestion, distillation, brain-upgrade]
---

# Youtube-MOC

Curated index of `12-youtube/` and its ingestion pipeline per [[YOUTUBE_INGESTION_SPEC]] (Module E in [[2026-05-25-brain-upgrade-plan]]). **Operator flow**: drop a URL file in the queue → BrainOrchestrator picks up → metadata + transcript fetched (`yt-dlp` wrapper, T-2026-05-25-003) → anti-hype LLM filter scores → distillation runs → brain note lands at `12-youtube/<channel>/<slug>.md` with verbatim transcript mirrored to a local-only `_library/youtube/...` path. This MOC points only — binding truth lives in the spec.

## Spec

- [[YOUTUBE_INGESTION_SPEC]] **v1.0.1** (post-fase-3 folder-rename sweep, was `06-youtube/`) — pipeline architecture, frontmatter contract, anti-hype filter rules, copyright policy, channel allowlist semantics, queue file format.

## Folder

- [[12-youtube/README]] — folder-level conventions, `_queue/` lifecycle, library path layout, lookup conventions for the orchestrator.

## Skill

- [[youtube-ingest]] — brain-tier skill that wraps the pipeline. Runs on a single URL (operator-invoked) **or** drains all pending items in `12-youtube/_queue/` (orchestrator-invoked). Trigger keywords: "ingest video", "youtube transcript", "distill talk".

## Queue mechanism

**Slik koden faktisk virker per 2026-07-13** (`packages/youtube-ingest/src/queue.ts` + `index.ts` — spec-teksten under §8 er justert av virkeligheten):

1. Drop **én fil per video** i `12-youtube/_queue/`: filnavn `YYYY-MM-DDTHHMM-<slug>.url`, første linje = enkeltvideo-URL (`watch?v=` eller `youtu.be/`), valgfritt `# tags:` / `# note:`. **KUN `*.url`-filer konsumeres** — `.txt`-lister, kanal- og playlist-URLer blir liggende for alltid (legg dem i `_queue/_manual/`; ekspander med `yt-dlp --flat-playlist --print url`).
2. BrainOrchestrators G6 queue-watcher (PÅ i drift) fanger nye filer → enqueuer ingest-task → `brain-worker` kjører `drainYoutubeQueue`.
3. Hver URL fetches (metadata + transcript via `yt-dlp` — må finnes i daemonens PATH; fikset 13.07), filtreres, distilleres, skrives som brain-note. Ferdige køfiler → `_queue/_done/`, feilede → `_queue/_failed/` med `# failed_at:`-linje (IKKE `_processed/`/`_rejected/` som spec-en opprinnelig sa).

## Verbatim storage

Per [[YOUTUBE_INGESTION_SPEC]] §6 (copyright policy, binding):

- Transcripts land at `_library/youtube/<channel>/<slug>/transcript.txt` — **local-only**, **gitignored**, never pushed.
- The brain note at `12-youtube/<channel>/<slug>.md` contains the distilled summary + frontmatter + back-refs only — no transcript body.
- Verbatim transcript is mirrored into the MemoryObject verbatim layer per [[MEMORY_DISTILLATION_SPEC]] §5 (per-ingest trigger).

## Anti-hype filter

Per [[YOUTUBE_INGESTION_SPEC]] §5 — LLM scoring step gates note creation.

- Flag definitions (§5.1) — `marketing-only`, `unsubstantiated-claims`, `no-implementation-detail`, etc.
- LLM prompt (§5.2) — exact reproducible prompt.
- Confidence computation (§5.3).
- Hard flags (§5.4) — overrides confidence; e.g. `paid-promotion` blocks unconditionally.

Failed scores route the URL to `_queue/_failed/` with the reason appended to the queue file.

## Channel allowlist

Per [[YOUTUBE_INGESTION_SPEC]] §7 — channel-level trust:

- **Stub** — `12-youtube/_channels.yaml` (not yet created; landed in T-2026-05-25 successor task). Will define `allowlist:` (auto-pass anti-hype), `denylist:` (auto-reject), `review:` (default — full anti-hype pipeline).
- Until the file lands, all channels route through the full anti-hype pipeline.

## Frontmatter

Note frontmatter contract — [[YOUTUBE_INGESTION_SPEC]] §3. Sections of the body — [[YOUTUBE_INGESTION_SPEC]] §4 (Core idea / Practical system ideas / Implementation opportunities / Risks & hype-filter results / Suggested tasks / Source). Template at [[00-templates/youtube-note]].

## Transcripts (orphan-fix 2026-07-13)

Rå transcripts ligger i `12-youtube/transcripts/` (26 notater fra manuell `yt-transcribe.sh`-kjøring juni) — egen klynge utenfor pipeline-strukturen over. Distillerte notater fra pipelinen lander per kanal-mappe (`12-youtube/<channel>/`).

## Related

- [[System-Wiring-MOC]] — hvor denne pipelinen sitter i hele systemet.
- [[2026-05-25-brain-upgrade-plan]] §2.E — Module E (YouTube) within the upgrade graph.
- [[00-templates/youtube-note]] — frontmatter + section template.
- [[AGENT_ORCHESTRATION_SPEC]] §8.1 — poll cadence that drains the queue.
- [[Github-Repos-MOC]] — sibling discovery pipeline; shares the queue-drain pattern, anti-hype-style scoring philosophy, and per-ingest distillation trigger.
- [[Memory-MOC]] — ingest events emit one verbatim row + one distilled MemoryObject per video.
- [[RAG-MOC]] — the distilled notes become retrieval substrate for T2 hybrid queries.
- [[Skills-MOC]] — the `youtube-ingest` brain-tier skill is the operator-facing wrapper around this pipeline.
- [[System-Architecture-MOC]] — parent context.
- [[T-2026-05-25-003-youtube-ytdlp-wrapper]] — pilot task implementing the `yt-dlp` fetcher.
- [[Tasks-MOC]] — distilled notes' "Suggested tasks" section (per YOUTUBE §4) can auto-propose tasks into `10-tasks/_open/`.

## Open questions

- **Stub** — `_channels.yaml` schema needs operator-facing documentation once it lands (allowlist / denylist / review tiers + trust expiry).
- **Stub** — failure-mode handling for region-blocked videos (per [[YOUTUBE_INGESTION_SPEC]] §9).
- **Stub** — rate-limit budget for `yt-dlp` (per §10) — current limit is yt-dlp default; needs operator sign-off when batch sizes grow.

---

*Spec is binding truth. This MOC is a navigation aid; folder conventions live in the README, pipeline details in the spec.*
