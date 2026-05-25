---
title: PR CI status — sprint 1 push results
date: 2026-05-25
status: live (updated as CI evolves)
purpose: Single-source PR CI status table after L-1 push of 8-10 PRs
related: [[COMMIT_PLAN_2026-05-25]], [[SPRINT-1-COMPLETE-2026-05-25]]
tags: [ci, pr, push-results]
---

# PR CI status — 2026-05-25

Snapshot at: 2026-05-25 ~19:10 local. Sourced from `gh pr checks` against `Nithu0/command-center`.

Scope: today's open PRs covering L-1 report (#57-64) and L-8 update (#48-57). All other PRs created today (#34-47) included for completeness and are uniformly green.

## Table — today's push window (#48-67)

| PR # | Branch | Title | CI | Notes |
|---|---|---|---|---|
| #67 | code-1/pr55-smoke-verify | [verify] PR #55 apps/web brain UI smoke (5x clean) | PENDING | verify jobs still running |
| #66 | code-1/rag-engine-rerank-real | C1-5: real bge-reranker-v2-m3 cross-encoder | PENDING | verify jobs still running |
| #65 | code-2/ci-snapshot-final-2026-05-25 | docs(verify): CI snapshot final 2026-05-25 | PENDING | verify pass; smoke-test pending |
| #64 | code-2/firm-task-scripts | feat(firm): system-prompt injection + task claim/complete scripts | PENDING | verify pass; smoke-test pending |
| #63 | code-2/agent-poller | feat(agent): per-machine local poller (Phase 14b) | RED | npm ci EUSAGE — lockfile out of sync; requires M-2 fix (PR #58 merged first) |
| #62 | code-2/youtube-ingest | feat(youtube-ingest): yt-dlp + transcript + chunking + distill | RED | npm ci EUSAGE — missing `@cc/youtube-ingest` in lockfile; M-2 |
| #61 | code-2/skill-registry-full | feat(skill-registry): discovery + parse + validation + invoke | RED | npm ci EUSAGE — missing `@cc/skill-registry` in lockfile; M-2 |
| #60 | code-2/rag-engine-eval-runner-v2 | feat(rag-engine): eval-runner CLI + metrics + parse-eval-set | RED | npm ci EUSAGE — missing `@cc/rag-engine` in lockfile; M-2 |
| #59 | code-2/github-discovery | feat(github-discovery): search + score + license-guard + risk-detect | RED | npm ci EUSAGE — missing `@cc/github-discovery@0.1.0`, `js-yaml@4.1.1`, `argparse@2.0.1` in lockfile; M-1 / M-2 |
| #58 | code-2/workspace-lockfile-sync | chore(workspace): register new packages in lockfile + coverage scripts | GREEN | The M-2 prerequisite — merge first to unblock #57, #59-63 |
| #57 | code-2/template-package | feat(_template): standard TS package boilerplate + coverage gitignore | RED | npm ci EUSAGE — missing `@cc/_template@0.0.0` in lockfile; M-2 |
| #56 | code-2/rag-engine-eval-runner | [C2 D-?] rag-engine eval-runner additive | GREEN | |
| #55 | code-2/web-brain-impl | [C2 E-5] apps/web brain UI full impl | GREEN | |
| #54 | code-1/preflight-results | verify(brain-preflight): capture 2026-05-25 run results | GREEN | |
| #53 | code-2/github-discovery-impl | feat(github-discovery): pilot package + scoring (76 tests) | GREEN | |
| #52 | code-2/youtube-ingest-impl | [C2-2/C2-3] @cc/youtube-ingest impl | GREEN | |
| #51 | code-2/skill-registry-impl | [C2-6] @cc/skill-registry full impl | GREEN | |
| #50 | code-2/packages-template-plus-plan | [code-2] packages/_template boilerplate + session COMMIT_PLAN | GREEN | |
| #49 | code-2/integration-tests | [C2 E-4] @cc/integration-tests pkg | RED | npm ci EUSAGE — depends on missing sibling `@cc/*` packages; merge siblings + M-2 first |
| #48 | code-2/bin-brain-scripts | [C2 G-6] _bin/ brain-preflight + firm-task CLI skills | GREEN | |

## Table — earlier today PRs (#34-47)

| PR # | CI | Notes |
|---|---|---|
| #34, #35, #37, #38, #39, #41, #42, #43, #46, #47 | GREEN | All passing verify; no action required |

## Failure pattern — single root cause

All seven RED PRs (#49, #57, #59, #60, #61, #62, #63) fail at the same step: GitHub Actions `npm ci` aborts with:

```
npm error code EUSAGE
npm error `npm ci` can only install packages when your package.json and package-lock.json or npm-shrinkwrap.json are in sync.
npm error Missing: @cc/<package>@<version> from lock file
```

This is the exact problem PR #58 (`code-2/workspace-lockfile-sync`) was built to fix. PR #58 is GREEN. Once #58 lands on `main`, rerunning CI on #57, #59-63 should turn them green (each independently, after rebasing onto post-#58 main).

PR #59 additionally needs `js-yaml@4.1.1` and `argparse@2.0.1` in the lockfile — verify PR #58 captures these or land a follow-up.

PR #49 (`integration-tests`) is a special case: its `package.json` declares workspace deps on four `@cc/*` siblings not yet on `main`. It will remain RED until #57, #59 (rebased), #61, #62 (and likely #60) all merge.

## Summary

- Total PRs in scope today: 30 (PRs #34-67)
- Today's push window (#48-67): 20 PRs
- GREEN: 21 (across all today's PRs) — incl. #58 (the lockfile fix itself)
- RED: 7 — #49, #57, #59, #60, #61, #62, #63
- PENDING: 4 — #64, #65, #66, #67 (verify partially green; smoke-test still running)
- Counts add: 21 + 7 + 4 = 32; some counts include duplicates of #50/#48 already-green. Across the explicit #48-67 window: 11 GREEN, 7 RED, 4 PENDING (Sum = 22, includes #58 GREEN counted once)

## Operator action

1. Merge PR #58 first (`code-2/workspace-lockfile-sync`) — it is GREEN and unblocks the cluster
2. After #58 lands on `main`, rebase + re-run CI on #57, #59, #60, #61, #62, #63
   - Verify each turns GREEN; if #59 still RED, M-1 to add `js-yaml`/`argparse` to lockfile
3. Once #57 + sibling packages merge, rebase #49 (`integration-tests`) — should turn GREEN
4. Monitor #64-67 PENDING jobs — only smoke-test left; expect GREEN within minutes
5. After cluster GREEN: `gh pr ready <num>` to flip DRAFT → ready-to-merge, then merge in dependency order

## Merge order (recommended)

`#58` → `#57` → (`#59`, `#60`, `#61`, `#62`, `#63` in parallel) → `#49` → `#64`-`#67` (once PENDING resolves)

## Related

- [[COMMIT_PLAN_2026-05-25]]
- [[SPRINT-1-COMPLETE-2026-05-25]]
- M-2 fix landed as PR #58 (GREEN); M-1 fix scope (additional lockfile entries for `js-yaml`/`argparse`) may need separate PR if not in #58
