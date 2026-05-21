---
tags: [project, command-center, ops]
type: project-card
created: 2026-05-16
---

# command-center — project card

## Purpose

Workspace-wide control plane. One dashboard + command queue across all 8 projects under `/home/nithu/code` + the Obsidian Brain.

## Status

Slice 1 complete (2026-05-16). Read-only dashboard + command queue + risk classification + audit log. No execution wired. Next: Slice 2 AI Router.

## Stack

- Monorepo (npm workspaces) — `apps/{api,web}`, `packages/{shared,bus,git}`
- `apps/api` — Fastify 5 + WebSocket
- `apps/web` — Next.js 15 + Tailwind 3 + SWR
- `data/command-center.db` — better-sqlite3 (WAL, embedded, gitignored)
- Node >= 20

## Ports

- **3100** — API (Fastify, `127.0.0.1` default)
- **3200** — Web (Next.js dashboard)

LAN exposure requires explicit `API_HOST=0.0.0.0` + auth (Slice 5+).

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

## Next milestones

- **Slice 2** — AI Router (intent → command, Claude Opus + prompt caching)
- **Slice 3** — Execution worker + Postgres migration + daily audit dump to brain
- **Slice 4** — Real-time WebSocket fan-out (commands, git, presence)
- **Slice 5** — PWA + mobile push
- **Slice 6** — Agent system (Atlas / Cipher / Shield / Prism / Forge / Blade)
