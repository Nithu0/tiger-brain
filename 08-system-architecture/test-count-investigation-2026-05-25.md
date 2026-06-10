---
title: Test count drop investigation — 2026-05-25
date: 2026-05-25
status: v1.0
purpose: Diagnose 597→374 test count drop post coverage install
related:
  - "[[test-summary-2026-05-25]]"
  - "[[SPRINT-1-COMPLETE-2026-05-25]]"
tags: [investigation, tests, vitest]
---

# Test count investigation

## Symptom

- Post-fase-12 snapshot (2026-05-25T16:00Z, `critical-path-verify`): **597 tests / 57 files**, all green.
- Post-O-7 snapshot on branch `code-2/skill-registry-full` (2026-05-25T19:33Z, after `@vitest/coverage-v8@2.1.9` install): **374 tests / 39 files**, all green.
- Delta: **-223 tests / -18 files**.
- O-7 flagged this as a regression coincident with coverage install.

## Root cause

**Branch state, not coverage install.** The post-fase-12 measurement (597/57) was captured on a tree that contained seven additional workspace packages whose sources are NOT in the current branch's git tree:

| Package | tests (per `test-summary-2026-05-25.md`) | tracked in `HEAD` of `code-2/skill-registry-full`? |
|---|---:|---|
| @cc/youtube-ingest | 34 | no |
| @cc/github-discovery | 76 | no |
| @cc/rag-engine | 30 | no |
| @cc/skill-registry (D-1 expansion) | +18 over fase-2 baseline | partial (current branch ships skill-registry but per-fase test split shifted) |
| @cc/_template | 1 | no |
| @cc/integration-tests | 0 (scaffold only) | no |
| @cc/memory-engine | 0 | no |
| @cc/brain-orchestrator | 0 | no |

Verification commands (run from `/home/nithu/code/command-center`):

- `git ls-tree -r HEAD packages/ --name-only | awk -F/ '{print $2}' | sort -u` → 12 packages tracked: `agents, auth, brain, bus, engines, executor, git, github, router, shared, skill-registry, sync`.
- `find packages/{youtube-ingest,github-discovery,rag-engine,integration-tests,memory-engine,brain-orchestrator,_template} -name '*.test.ts' 2>/dev/null | wc -l` → **0**. The directories exist on disk but only as leftover `node_modules`/`dist` from earlier branch checkouts; no source files (including `.test.ts`) are present.
- `git ls-tree -r HEAD --name-only | grep -E '\.test\.ts$' | wc -l` → **38** tracked test files (+1 untracked `apps/api/test/routes/health.test.ts` from working tree = 39 reported by vitest).
- `npx vitest run` → `Test Files 39 passed (39) / Tests 374 passed (374) / Duration 3.31s`.
- Branch survey: no single branch in the repo carries all seven additional packages simultaneously. They were each developed on separate `code-1/*` and `code-2/*` lanes (`code-2/youtube-ingest-impl`, `code-2/github-discovery-impl`, `code-2/rag-engine-eval-runner-v2`, `code-2/integration-tests`, `code-1/memory-engine-distill-real`, etc.). The 597-test count must therefore have been produced on a transient integration / dirty working tree that combined these lanes — that state was never committed onto `code-2/skill-registry-full` (this branch) or `main` (33 tracked test files on `origin/main`).

`@vitest/coverage-v8@2.1.9` install was incidental. Confirmed by:

- `vitest.config.ts` unchanged from `HEAD` (only diff in working tree is `package.json` + `package-lock.json` adding the coverage dep).
- `coverage: { enabled: false }` — coverage is opt-in via `--coverage`; the dep being installed does not alter `include`/`exclude` for the default `npm test` run.
- All four H1-H4 hypotheses in the task brief are ruled out: include/exclude unchanged, no project-mode config exists, no thread flags introduced, and the "moved/renamed" framing understates the truth — entire package source trees are absent on this branch.

Cross-confirmation: `SPRINT-1-COMPLETE-2026-05-25.md` already records the same conclusion in its `tests-truth` footnote — "fase 13-15 sub-package consolidation removed 18 test files (57→39 files). O-7 first flagged the drop (597→374 after coverage-install); P-1 investigated, P-3 ran 5× to confirm stability."

## Fix

No code/config fix needed on `vitest.config.ts`. The drop is a real reflection of which packages ship on this branch. Recommended workflow fixes:

1. **Stop comparing test counts across branches.** Anchor sprint deltas to the pre-sprint baseline (341), not the post-fase-12 peak (597) that depended on a never-committed merged state. The brain note `test-summary-2026-05-25.md` § "TRULY FINAL state" already records this as the binding interpretation.
2. **Decide merge order for the seven outstanding package lanes** (`code-2/youtube-ingest-impl`, `code-2/github-discovery-impl`, `code-2/rag-engine-eval-runner-v2`, `code-2/integration-tests`, `code-2/template-package`, `code-1/memory-engine-distill-real`, `code-1/brain-orchestrator-skel`). Merging into `main` (or a release integration branch) will restore the higher test count for the canonical line.
3. **If coverage gate is added to CI** (per G-9 follow-up runbook), measure it on the branch under test, not against the 597-peak snapshot which used a different package set.

Optional config hardening (not required to fix the symptom, defensive only):

- Add `coverage.include: ["packages/**/src/**/*.ts", "apps/**/src/**/*.ts"]` so a future `--coverage` run can't accidentally widen scope and skew counts.
- Add an explicit `passWithNoTests: false` to fail loudly if a package directory exists with no test files (would surface "package dir present but source missing" cases earlier).

## Verify

To confirm the diagnosis on any branch:

```bash
cd /home/nithu/code/command-center
git ls-tree -r HEAD --name-only | grep -cE '\.test\.ts$'   # → 38 on code-2/skill-registry-full
find packages apps -name '*.test.ts' -type f | wc -l        # → 39 (38 tracked + 1 untracked health test)
npx vitest run --reporter=default 2>&1 | tail -5            # → 39 files / 374 tests, ~3.3s
```

To reproduce the 597 figure: requires checking out a merge of `code-2/{youtube-ingest-impl,github-discovery-impl,rag-engine-eval-runner-v2,integration-tests,template-package,skill-registry-full}` plus `code-1/{memory-engine-distill-real,brain-orchestrator-skel}`. No existing branch ships all of these together — the 597 baseline was an in-memory union, never persisted.
