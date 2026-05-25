---
title: "ADR-002: SQLite for Slice 1, Postgres later"
type: decision
status: accepted
created: 2026-05-16
tags: [adr, command-center, database]
---

# ADR-002: SQLite for Slice 1, Postgres later

**Status:** accepted (2026-05-16) — supersedes operator's initial "Postgres" choice for Slice 1 only.

## Context

Operator chose Postgres to match `ai-assistent`'s stack. At build time we discovered:
- Docker Desktop WSL integration not enabled.
- No native Postgres server running (psql client present, but `pg_isready` returns "no response").
- Slice 1 should land in hours.

Choosing Postgres for Slice 1 would mean either: install/configure native Postgres (operator-side), enable Docker WSL integration (operator-side), or wait. None of those line up with "OK kjør på max".

## Decision

Use **better-sqlite3** for Slice 1. Embedded, synchronous, fast, zero infrastructure. DB lives at `data/command-center.db` (gitignored).

Migrate to Postgres in Slice 3 or 4 (when execution + concurrent writers actually need it).

## Why this is fine for Slice 1

The Slice 1 workload:
- ~10 writes/min upper bound (command proposals + audit events).
- All reads are single-process (Fastify) on the same machine.
- No replication needed; the DB *is* the cache — source of truth is files (firm-bus, git).
- SQLite WAL mode handles this trivially.

## Migration path (Slice 3+)

The data layer is wrapped in `apps/api/src/db.ts`. To swap:
1. Add a `pg` connection and rewrite the four prepared statements.
2. Schema is portable — `TEXT PRIMARY KEY`, no SQLite-only types.
3. better-sqlite3's synchronous API becomes async — we'll need to await everywhere it's used (currently only `commands.ts` + `db.ts`).
4. Audit_log keeps autoincrement (Postgres BIGSERIAL).

Estimated diff: ~80 lines, contained to `apps/api/src/`.

## Trigger to revisit

When **any** of these become true:
- Multiple worker processes need to write the queue (Slice 3 executor pool).
- Need cross-host availability of audit_log.
- Need JSON-column queries on `payload` field (Postgres `jsonb`).
- Operator wants to push command-center DB to Railway/Fly.

## Non-decision

We are NOT building an abstraction layer to support "any DB". YAGNI. SQLite now, swap to Postgres when the constraint appears.
