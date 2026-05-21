---
tags: [command-center, lessons, retro, slice-8]
type: lesson
created: 2026-05-21
---

# 2026-05-21 — Slice 8 start + test/push/git hardening

Multi-pane firm session. Several agents worked in parallel: Slice 8 sync,
push-notification routes, smoke-test script, test coverage, and a docs refresh
(this note). Relates to [[../project-card]] and `docs/ROADMAP.md` Slice 8.

## Worked

- **Slice 8 first cut landed.** New `packages/sync` — a Litestream-backed
  replication helper for `data/command-center.db`. Litestream config written
  for DB → S3-compatible store. Multi-operator audit added (who-did-what
  attribution on approve/reject rows).
- **Push notifications wired.** Web push routes for approval-required and
  execution-failed events; `scripts/gen-vapid.ts` generates the VAPID keypair
  so the operator can provision keys without committing secrets.
- **Smoke test.** `scripts/smoke-test.sh` boots API + web and hits the core
  endpoints — a fast pre-push sanity gate beyond `tsc` + unit tests.
- **Test coverage** expanded across the workspaces; `npm test` (vitest) and
  `npm run typecheck` are the standing checks.
- **Git init** on the repo so the project is now version-controlled (the
  repo had no history for its first 5 days — see companion note).
- Parallel-agent split worked cleanly: each agent owned a disjoint file set
  (docs agent owned only `docs/ROADMAP.md`, `README.md`, and this Brain folder),
  so no merge collisions despite simultaneous edits.

## Friction

- Obsidian REST API was unreachable mid-session — `obsidian_write_note` failed
  with `fetch failed`. Fell back to direct filesystem writes under
  `~/Obsidian/Brain/00-command-center/`. Worth confirming the Local REST API
  plugin is running before relying on the MCP path.
- Docs drift: README and CLAUDE.md still described Slice-1-only scope while
  Slices 2-7 were already built. Cross-agent edits mean docs need an explicit
  refresh pass per session, not just per slice.
- Litestream is not self-installable here — binary install + S3 credentials
  are deliberately operator-gated, so Slice 8 stays IN PROGRESS until the
  operator does that step.

## Next

- Slice 8 pt2 (multi-operator identity) and the GitHub push followed later
  the same day — see [[2026-05-21-slice-8-pt2-multi-operator]].
- Operator: install the Litestream binary and provide S3 credentials, then
  flip Slice 8 infra to DONE in `docs/ROADMAP.md`.
- Stand up the read replica on the second machine (Karri's) once sync is live.
- Integrate cross-machine sync with the existing Obsidian-Git sync so DB and
  brain stay coherent across machines.
