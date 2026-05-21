---
tags: [command-center, lessons, retro, slice-1]
type: retro
created: 2026-05-16
---

# Slice 1 — bootstrap retro

Shipped 2026-05-16. Foundation + read-only dashboard + command queue scaffolding (no execution wired).

## Worked

- **Standalone repo** ([[../ADRs/ADR-001-architecture]]) — zero coupling to ai-assistent meant no compatibility gymnastics. Slice 1 landed in hours, not days.
- **SQLite-pragmatic** ([[../ADRs/ADR-002-sqlite-then-postgres]]) — flipping off Postgres when WSL/Docker wasn't ready unblocked progress. Migration path documented, no abstraction layer built.
- **Parallel agents** — multiple subagents on the api / web / packages split in parallel finished the scaffolding cleanly. Per operator's parallel-by-default rule.

## Friction

- **Docker WSL gap** — Docker Desktop integration not enabled meant the original Postgres plan was a non-starter. Discovered at build time, not plan time. Lesson: pre-flight infra availability before locking stack choice.
- **Two-dashboard awkwardness** — ai-assistent already has a dashboard. Operator now opens one or the other depending on job. Acceptable per ADR-001 but worth a UX pass post-Slice 5.

## Next

- **Slice 2** — AI Router (intent → command, Claude Opus + prompt caching). Project registry + recent commands cached.
- **Slice 3** — execution worker + Postgres swap + first audit dump to [[../audit/README|audit]].
- **Slice 4–7** — real-time, PWA, agents, GitHub. Per `docs/ROADMAP.md`.
