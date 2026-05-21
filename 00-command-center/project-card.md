---
tags: [project, command-center, ops]
type: project-card
created: 2026-05-16
updated: 2026-05-21
---

# command-center — project card

## Purpose

Workspace-wide control plane. One dashboard + command queue across all 8 projects under `/home/nithu/code` + the Obsidian Brain.

## Status

Slices 1-10 all code-complete as of 2026-05-21. Only operator-gated Slice 8 infra remains.

- **Slice 1** ✅ Foundation + read-only dashboard + command queue + risk classification + audit log
- **Slice 2** ✅ AI Router — intent → command, Claude Opus + prompt caching
- **Slice 3** ✅ Execution worker — firm-bus handoff + sandboxed direct exec
- **Slice 4** ✅ Real-time WebSocket fan-out (commands, git, presence)
- **Slice 5** ✅ PWA + mobile push (web push, install banner, service worker)
- **Slice 6** ✅ Agent system — Atlas / Cipher / Shield / Prism / Forge / Blade
- **Slice 7** ✅ GitHub integration — PRs / branches / CI
- **Slice 8** ✅ Cross-machine sync (code) — **pt1** `packages/sync` (Litestream config generation, multi-operator audit migration); **pt2** multi-operator identity — operator registry (`nithu` primary + `karri` collaborator), migration 002 (`proposed_by`/`decided_by`/`decided_at` + `audit_log.machine`), `X-Operator-Id` request header, server-side per-operator approval-rights enforcement (403 if not entitled; BLOCKED un-approvable for all), who-did-what UI (operator selector + attribution). Verified: typecheck + build + 192 tests + smoke 9/9 green.
  - **Operator-gated, still open:** install the Litestream binary, wire S3 credentials, stand up the read replica on Karri's second machine.
- **Slice 9** ✅ Developer flow — commit-message suggestions for staged diffs (`/api/github/:id/suggest-commit`), AI-drafted GitHub issues (`/draft-issue`), per-project activity feed rolling up commits/PRs/CI (`/api/projects/:id/activity`). Landed 2026-05-21.
- **Slice 10** ✅ Mobile-first + Brain Layer — mobile bottom-tab navigation (`MobileTabBar` — one rail-pane at a time on phones) + read-only Brain Layer (`@cc/brain` package, `/api/brain/:id` route, `BrainPanel` component) surfacing per-project Obsidian notes in the dashboard. Read-only by design — never writes to the brain vault. Landed `5565745` — 268/268 tests, smoke 9/9.

## Version control

Repo went under git on 2026-05-21 (initial commit `1e15eed`) — it had no version control for the first 5 days. Pushed to a new private GitHub repo **github.com/Nithu0/command-center**. Through `94d928d`: Slices 8 pt2 → 10, `_bin/` firm-launcher tooling moved in, docs synced.

## Stack

- Monorepo (npm workspaces) — `apps/{api,web}`, `packages/{shared,bus,git,router,executor,agents,github,sync,brain}`
- `apps/api` — Fastify 5 + WebSocket
- `apps/web` — Next.js 15 + Tailwind 3 + SWR
- `data/command-center.db` — better-sqlite3 (WAL, embedded, gitignored)
- Node >= 20

## Ports

- **3100** — API (Fastify, `127.0.0.1` default)
- **3200** — Web (Next.js dashboard, `127.0.0.1` default)

LAN exposure requires explicit `API_HOST=0.0.0.0` + auth. firm-bus is read-only.

## Owner / reviewer

- **Owner:** operator
- **Reviewer:** none yet (workspace-agnostic project; Karri reviews trading-specific only)

## Key files

| What | Where |
|---|---|
| Repo root | `/home/nithu/code/command-center/` |
| Project CLAUDE.md | `/home/nithu/code/command-center/CLAUDE.md` |
| Architecture ADR | `docs/ADR-001-architecture.md` |
| DB choice ADR | `docs/ADR-002-sqlite-then-postgres.md` |
| Slice plan | `docs/ROADMAP.md` |
| Security model | `docs/SECURITY.md` |
| Project registry | `packages/shared/src/projects.ts` |
| Risk classifier | `apps/api/src/routes/commands.ts:classifyRisk()` |
| Sync helper | `packages/sync/` |
| Brain Layer reader | `packages/brain/` |

## Run + checks

```bash
npm install && npm run dev          # API :3100 + Web :3200
npm test                            # vitest suites
npm run typecheck                   # tsc --noEmit
bash scripts/smoke-test.sh           # boot + endpoint smoke test
npx tsx scripts/gen-vapid.ts         # generate VAPID keypair for push
```

`ANTHROPIC_API_KEY` needed for the live router + desk dispatch.

## Next milestones

- **Slice 8 infra (operator-gated)** — install Litestream binary, wire S3 credentials, stand up read replica on Karri's second machine
- **Verify on phone** — Slice 10 mobile-first nav is built; confirm the bottom-tab UX on a real phone form factor
- **Slice 11+** — not yet scoped; the ROADMAP's original plan ended at Slice 8, Slices 9-10 were added on top
