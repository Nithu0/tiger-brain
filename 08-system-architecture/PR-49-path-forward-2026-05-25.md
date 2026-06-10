---
title: PR #49 path-forward — sister-pkg dependency chain
date: 2026-05-25
status: recommendation
purpose: Resolve PR #49 (integration-tests) which depends on 4 unmerged sister @cc/* packages
related: [[pr-ci-status-2026-05-25]], [[COMMIT_PLAN_2026-05-25]]
tags: [pr, blocker, integration-tests, sprint-1]
---

# PR #49 path-forward

## Problem
`packages/integration-tests/package.json` declares devDeps on 4 @cc/* packages that exist only on unmerged PR branches:
- @cc/skill-registry (PR #61)
- @cc/youtube-ingest (PR #62)
- @cc/github-discovery (PR #59)
- @cc/rag-engine (code-1's branch)

`npm install --package-lock-only` fails with E404 because npm can't resolve workspace packages that don't exist on the branch yet.

## Recommended path
**Option A: Merge sister PRs in order, then PR #49 auto-resolves.**

Merge order:
1. PR #57 (_template) — foundation
2. PR #58 (lockfile chore) — workspace registration
3. PR #61 (skill-registry) — sister dep #1
4. PR #62 (youtube-ingest) — sister dep #2
5. PR #59 (github-discovery) — sister dep #3
6. PR #60 (rag-engine eval-runner) OR wait for code-1's full rag-engine PR — sister dep #4
7. PR #63 (agent-poller) — independent
8. PR #64 (firm-task scripts) — independent
9. **PR #49 (integration-tests)** — now mergeable; just needs lockfile regen after sisters land

After step 6: `gh pr checkout 49 && npm install --package-lock-only && git add package-lock.json && git commit -m "fix(integration-tests): sync lockfile post sister merges" && git push`

## Alternative: drop deps
If sisters won't merge soon, edit `packages/integration-tests/package.json` to drop the 4 deps + `.todo` the relevant tests. Lower priority.

## Operator action
Just merge in the order above. ~10 min total.
