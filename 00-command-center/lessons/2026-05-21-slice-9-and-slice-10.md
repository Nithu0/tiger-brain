---
tags: [command-center, lessons, retro, slice-9, slice-10]
type: lesson
created: 2026-05-21
---

# 2026-05-21 — Slice 9 (developer flow) + Slice 10 start (mobile-first + Brain Layer)

Same-day continuation after Slice 8. Built across a two-pane firm session —
code-1 and code-2 working in parallel on a disjoint file set. Relates to
[[../project-card]] and `docs/ROADMAP.md` Slices 9-10.

## Worked

- **Slice 9 — developer flow — done.**
  - Commit-message suggestions for staged diffs, surfaced per project
    (`/api/github/:id/suggest-commit`).
  - Issue drafts — paste an error or describe a change, AI drafts a GitHub
    issue (title + body) for review before it is opened (`/draft-issue`).
  - Per-project activity feed — recent commits, PRs and CI events rolled up
    into one chronological view (`/api/projects/:id/activity`).
- **Slice 10 — mobile-first + Brain Layer — started.**
  - Mobile bottom-tab navigation (`MobileTabBar`) — on phones the three rails
    (projects / project / AI) become bottom tabs, one pane at a time, instead
    of a cramped single-column scroll.
  - Read-only Brain Layer — `@cc/brain` package reads per-project Obsidian
    notes from `~/Obsidian/Brain/`; `/api/brain/:id` route serves them;
    `BrainPanel` component renders them in the dashboard. Read-only by design,
    consistent with the firm-bus boundary — the dashboard never writes to the
    brain vault.
- **Two-pane parallel build worked cleanly.** code-1 and code-2 each owned a
  disjoint file set (one on the API/package side, one on the web components),
  and the docs pass owned only `docs/ROADMAP.md`, `README.md`, and this Brain
  folder. No merge collisions despite simultaneous edits.

## Friction

- The Brain Layer crosses a sensitive boundary: command-center now reads the
  Obsidian vault directly. Kept it strictly read-only and scoped per project
  to avoid the dashboard becoming a vault editor — same discipline as the
  read-only firm-bus reader. Worth an ADR if write access is ever proposed.
- Docs again lagged the code mid-session — README still showed v0.2.0 /
  Slice 8 while Slices 9-10 were landing. Confirms the standing lesson: docs
  need an explicit refresh pass per session, owned by one agent.

## Next

- Finish Slice 10 — verify mobile bottom-tab navigation on a real phone form
  factor; confirm `BrainPanel` renders lessons + project cards correctly.
- Slice 8 infra remains operator-gated — install Litestream binary, wire S3
  credentials, stand up the read replica on Karri's machine.
- Consider an ADR for the Brain Layer read boundary before any write feature.
