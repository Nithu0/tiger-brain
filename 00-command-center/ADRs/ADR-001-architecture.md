# ADR-001: Standalone command-center repo, loose interfaces

**Status:** accepted (2026-05-16)
**Context:** New control-plane project. Operator considered three locations: new repo, extension of `ai-assistent/apps/dashboard`, or hybrid (new UI sharing the ai-assistent API).

## Decision

Build as **standalone repo** at `/home/nithu/code/command-center/`. Talk to other systems only through stable, narrow interfaces:

- **firm-bus** (`~/Obsidian/Brain/00-firm-bus/`) is the source of truth for terminal state. We read its markdown files; we never write to its protocol from this app.
- **git CLI** for per-repo status. No GitPython, no native bindings — `git` is already on every machine.
- **own SQLite** for command queue + audit. Survives ai-assistent / Brain being down.
- **ai-assistent API** is consumed (proxy in Slice 2+) but not depended on at boot time.

## Why standalone

1. **Project isolation rule (operator CLAUDE.md):** "Do NOT pollute one project's context with another's content." Embedding workspace orchestration in ai-assistent breaks this directly — a trading-firm repo would then carry job-search and thesis context.
2. **Blast radius:** command-center will touch many repos. It must NOT inherit ai-assistent's deploy lifecycle, secrets surface, or DB.
3. **Tempo:** Slice 1 should land in hours, not days. A new repo has no compatibility constraints.
4. **Future portability:** if operator wants to share command-center (it's mostly project-agnostic), shipping it as its own thing is straightforward.

## Why not "hybrid" (reuse ai-assistent API)

Tempting — ai-assistent already has Fastify, Postgres, Redis, BullMQ. But:
- The interesting endpoints (firm-bus reader, cross-repo git, command queue) don't belong in a trading-firm API surface.
- Adding workspace-orchestration routes to ai-assistent grows its threat surface (one app now controls all repos).
- Operator's "no production behaviour change without proposal" rule means every change in ai-assistent goes through docs/strategy/proposals/. command-center should not be gated by trading-firm release process.

## Why loose interfaces, not tight integration

The control plane should keep working when:
- ai-assistent is down (we just stop showing trading-specific data).
- Brain sync is paused (we show stale feed-data with a warning).
- A project's git is in a weird state (we degrade per-project, not globally).

So: no shared DB connection, no shared queue, no in-process imports across repos. Only files and HTTP.

## Consequences

- More code (own Fastify, own DB schema).
- Two dashboards exist (ai-assistent's + command-center's). Operator decides which they open first. Acceptable — they're for different jobs.
- Sync between PRESENCE.md and our DB has eventual consistency. That's fine for an observability layer; we never trust our cache over the file system.
