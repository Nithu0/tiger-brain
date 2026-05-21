---
tags: [command-center, lessons, retro, slice-8]
type: lesson
created: 2026-05-21
---

# 2026-05-21 — Slice 8 pt2 (multi-operator) + git/push

Companion to [[2026-05-21-slice-8-and-hardening]]. That note covers Slice 8
pt1 (`packages/sync`, Litestream config, multi-operator audit). This one
captures pt2 and the version-control catch-up. Relates to [[../project-card]]
and `docs/ROADMAP.md` Slice 8.

## Worked

- **Slice 8 pt2 — multi-operator identity — complete** at commit `c7a4190`:
  - Operator registry: `nithu` (primary) + `karri` (collaborator).
  - Migration 002 — who-did-what columns `proposed_by` / `decided_by` /
    `decided_at`, plus `audit_log.machine`.
  - `X-Operator-Id` request header carries operator identity to the API.
  - Server-side per-operator approval-rights enforcement — 403 if the
    operator is not entitled; `BLOCKED` commands stay un-approvable for
    everyone.
  - Who-did-what UI — operator selector + attribution surfaced on rows.
- **Verified before declaring done:** typecheck + build + 192 tests +
  smoke 9/9, all green.
- **Repo finally under version control.** `git init` on 2026-05-21,
  initial commit `1e15eed`, pushed to a new private GitHub repo
  **github.com/Nithu0/command-center**
  (`1e15eed` → `f0d128a` → `3c56874` → `8586b07` → `c7a4190`).

## Friction / lesson

- **The repo had no git history for 5 days.** Built 2026-05-16, version
  control only added 2026-05-21 — Slices 1-7 plus Slice 8 pt1 all shipped
  with no commit history, no diff trail, no remote backup. A disk loss or
  a bad edit in that window would have been unrecoverable. Lesson:
  `git init` + a private remote belong in the *first hour* of a new
  project, not as a later hardening pass. Bootstrap a repo before writing
  the second file.

## Open — operator-gated

Slice 8 code is done; the remaining work is deliberately operator-gated and
**not** complete:

- Install the Litestream binary.
- Provide S3 credentials.
- Stand up the read replica on Karri's second machine.

Once those are done the live cross-machine sync can be exercised end to end.
