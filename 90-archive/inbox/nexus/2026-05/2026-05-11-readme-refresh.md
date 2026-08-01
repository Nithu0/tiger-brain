---
date: 2026-05-11
type: docs
project: nexus
tags: [readme, onboarding, docs]
---

# README + onboarding refresh — 2026-05-11

## Task

Build/refresh `README.md` + onboarding docs for the Nexus repo so an
operator (or teammate, or clone-target) can pick up the project in
~15 minutes.

## State before

- `README.md` at repo root: **missing entirely.**
- `docs/CONTEXT-MAP.md`: present, refreshed earlier today — solid 5-min
  orientation for fresh-Claude sessions.
- `docs/onboarding/`: directory did not exist.

## What was written

### `/README.md` (132 lines, new)

Sections:
- One-paragraph "what it is" + headline numbers (16 modules, 10
  firm-agents, 4 active strategies, 467/467 tests, demo against OANDA
  practice).
- Quick-start path via `scripts/setup/bootstrap-cognitive-os.sh`.
- Run commands (`npm run dev:worker|api|dashboard`).
- Architecture pointer + decision-path diagram.
- Testing (467/467 in `apps/worker`).
- Pre-commit (tsc) + pre-push (worker tests) husky hooks.
- CI (`.github/workflows/test.yml` — typecheck → test on push/PR to main).
- Folder tour (apps, packages, docs subdirs).
- Operator-principles (6 binding rules, summarised with foundation gate
  state 4/5 green per today).
- Strategy/risk change protocol (Karri review queue under
  `docs/strategy/proposals/`).
- "Where to learn more" with links to CLAUDE.md, CONTEXT-MAP, onboarding
  index, cognitive-OS clone guide, phase-status.

### `/docs/onboarding/index.md` (100 lines, new)

Day-1 reading order for new contributors:
- Hour 1 — orientation (README → CLAUDE.md → CONTEXT-MAP → phase-status →
  firm-modules).
- Hour 2 — pick a track (A: trading-loop code, B: ops/observability, C:
  data/analytics, D: agent-bus).
- Repeatable session checklist (5 steps every Claude session in this repo).
- "What NOT to do" (no push from Claude, no auto-disable, no foundation
  bypass, no .env reads, no --no-verify).
- Common references table.

## Verification

- README head matches new content; 132 lines (>>50 threshold means it's
  the full version, not a stub).
- All 10 spot-checked linked docs resolve to real files (firm-modules,
  execution-paths, agent-bus, phase-status, CONTEXT-MAP, onboarding/index,
  cognitive-os-clone-guide, new-strategy-gate, critical-rules,
  blackboard-topics).
- `apps/worker && npm test` confirmed 467/467 before writing the count.

## Commit

`af20215` — `docs(readme): operator + contributor onboarding refresh (2026-05-11 state)`
- 2 files changed, 232 insertions(+), 0 deletions
- README.md (new, 132 lines)
- docs/onboarding/index.md (new, 100 lines)
- Pre-commit tsc: skipped (no TS touched), as predicted.
- Not pushed (per Principle 5; waiting for "OK kjør").

## Followups

- None. Pre-commit husky tsc will skip (no TS touched). Pre-push runs
  worker tests; already verified green so the push won't be blocked when
  operator OKs it.
- No push without "OK kjør" — per Principle 5.
