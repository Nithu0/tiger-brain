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

Slices 1-7 complete. Slice 8 (cross-machine sync) — both parts delivered 2026-05-21; only operator-gated infra steps remain.

- **Slice 1** ✅ Foundation + read-only dashboard + command queue + risk classification + audit log
- **Slice 2** ✅ AI Router — intent → command, Claude Opus + prompt caching
- **Slice 3** ✅ Execution worker — firm-bus handoff + sandboxed direct exec
- **Slice 4** ✅ Real-time WebSocket fan-out (commands, git, presence)
- **Slice 5** ✅ PWA + mobile push (web push, install banner, service worker)
- **Slice 6** ✅ Agent system — Atlas / Cipher / Shield / Prism / Forge / Blade
- **Slice 7** ✅ GitHub integration — PRs / branches / CI
- **Slice 8** ✅ Cross-machine sync (code) — **pt1** `packages/sync` (Litestream config generation, multi-operator audit migration); **pt2** multi-operator identity — operator registry (`nithu` primary + `karri` collaborator), migration 002 (`proposed_by`/`decided_by`/`decided_at` + `audit_log.machine`), `X-Operator-Id` request header, server-side per-operator approval-rights enforcement (403 if not entitled; BLOCKED un-approvable for all), who-did-what UI (operator selector + attribution). Verified: typecheck + build + 192 tests + smoke 9/9 green.
  - **Operator-gated, still open:** install the Litestream binary, wire S3 credentials, stand up the read replica on Karri's second machine.

## Version control

Repo went under git on 2026-05-21 (initial commit `1e15eed`) — it had no version control for the first 5 days. Pushed to a new private GitHub repo **github.com/Nithu0/command-center** (`1e15eed` → `f0d128a` → `3c56874` → `8586b07` → `c7a4190`).

## Stack

- Monorepo (npm workspaces) — `apps/{api,web}`, `packages/{shared,bus,git,router,executor,agents,github,sync}`
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
- Shared-instance integration with existing Obsidian-Git sync
