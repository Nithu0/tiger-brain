---
title: Brain preflight — first validation 2026-05-25
date: 2026-05-25
status: v1.0 (partial run — skipped tests×5 section)
script: command-center/_bin/brain-preflight.sh
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
external_refs:
  - "command-center/COMMIT_PLAN_2026-05-25.md"
tags: [preflight, validation, command-center]
---

# Brain preflight — partial validation

Fast manual run on `2026-05-25` by `code-1` agent. Tests×5 deliberately
skipped (operator runs the full `_bin/brain-preflight.sh` before push).

## Script structure

- File: `~/code/command-center/_bin/brain-preflight.sh` (4078 bytes, executable)
- `bash -n`: **PASS** (clean syntax)
- Sections found: **8** (matches expected)
  1. `[1/8] Git state` — git status + warn-checks for staged .env / secret patterns
  2. `[2/8] Workspace install` — `npm install --silent`
  3. `[3/8] Typecheck` — `npm run typecheck` (root)
  4. `[4/8] Tests x 5` — `npm test` ×5 to catch flaky tests
  5. `[5/8] Per-package tests` — iterates `skill-registry youtube-ingest github-discovery rag-engine _template` (note: integration-tests NOT in script's loop)
  6. `[6/8] Bash script syntax` — `bash -n` over `_bin/*.sh`
  7. `[7/8] Brain folder consistency` — greps for stale `06-youtube` / `07-github-repos`
  8. `[8/8] Brain sanity` — runs `$BRAIN/scripts/sanity.sh` if present

## Manual run results (fast sections only, tests×5 SKIPPED)

### Git state
- Branch: `code-1/ci-survey-final-2026-05-25` (up to date with origin)
- Untracked: **16** (incl. `COMMIT_PLAN_2026-05-25.md`, `_bin/brain-preflight.sh`,
  `_bin/firm-system-prompt.md`, `_bin/firm-task-claim.sh`, `_bin/firm-task-complete.sh`,
  `apps/agent/`, `apps/web/__tests__/`, `apps/web/app/brain/`, `apps/web/components/brain/`,
  `coverage/`, `packages/_template/`, `packages/github-discovery/`,
  `packages/integration-tests/`, `packages/rag-engine/`, `packages/skill-registry/`,
  `packages/youtube-ingest/`)
- Modified: **5** (`_bin/firm-tab-init.sh`, `apps/api/package.json`,
  `apps/api/src/routes/brain.test.ts`, `apps/api/src/routes/brain.ts`, `package-lock.json`)
- Staged: **0**

### Typecheck (root)
- Command: `npm run typecheck`
- Result: **PASS**
- Output: clean; ran `tsc --noEmit` for `shared, bus, engines, git, router, executor,
  agents, github, sync, brain, auth, apps/api` in sequence. No diagnostics printed.

### Per-package typecheck

| Package | Result |
|---|---|
| `@cc/skill-registry` | PASS |
| `@cc/_template` | PASS |
| `@cc/youtube-ingest` | PASS |
| `@cc/github-discovery` | PASS |
| `@cc/rag-engine` | PASS |
| `@cc/integration-tests` | PASS |

All six new packages produced only the standard `> @cc/<pkg>@<ver> typecheck\n> tsc --noEmit`
header lines — no errors emitted.

### Bash syntax (`_bin/*.sh`)
- Total scripts: **15**
- Pass: **15**
- Fail: **0**
- Files checked: `brain-preflight.sh, firm-git-snapshot.sh, firm-heartbeat.sh,
  firm-inbox-watch.sh, firm-session-context.sh, firm-statusline.sh, firm-tab-init.sh,
  firm-task-claim.sh, firm-task-complete.sh, firm-worktree-cleanup.sh,
  firm-worktree-list.sh, firm-worktree-spawn.sh, firm-wt-split.sh, firm-wt-tabs.sh,
  firm-zellij.sh`

### Brain folder consistency
- Stale `06-youtube` refs: **0** (target: 0) ✓
- Stale `07-github-repos` refs: **0** (target: 0) ✓
- The only match for either pattern is `_bin/brain-preflight.sh` itself,
  which contains the literal strings as part of its `warn_check` greps —
  this is the script defining the check, not a stale consumer.

## What's NOT yet verified (deferred to full preflight)

- **Tests × 5** (catch flaky) — operator runs `_bin/brain-preflight.sh` before push.
- **Brain sanity.sh** — covered by separate G-1 audit.
- **`npm install` clean** — assumed (workspace stable; root typecheck succeeded
  against installed deps, implying lockfile is coherent).
- **Per-package `npm test`** — script also runs `test` per new package; only
  `typecheck` was exercised here.
- **`@cc/integration-tests`** — not iterated by the script's package loop
  (only `skill-registry youtube-ingest github-discovery rag-engine _template`).
  Typechecked manually here and passes; consider adding `integration-tests`
  to the loop in `_bin/brain-preflight.sh` line 77 if its tests should also
  run during preflight.

## Sign-off

All manual fast checks PASS:

- bash -n on preflight: ✓
- Section count: 8 ✓
- Git readable: ✓
- Root typecheck: ✓
- 6/6 per-package typechecks: ✓
- 15/15 bash syntax: ✓
- Stale brain folder refs: 0 ✓

**Push-readiness:** Fast-check clean. Pending operator-run of the full
`_bin/brain-preflight.sh` (tests×5 + npm install + brain sanity.sh) and explicit
"OK kjør" per CLAUDE.md push-gate.

### Minor follow-ups (defer, do not fix here)

1. `_bin/brain-preflight.sh` line 77 omits `integration-tests` from the
   per-package loop — add it if integration-tests should run during preflight.
2. Untracked `coverage/` directory present — consider `.gitignore` entry
   if not already covered.
