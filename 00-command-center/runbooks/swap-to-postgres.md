---
tags: [command-center, runbook, db]
type: runbook
created: 2026-05-16
---

# Swap to Postgres

Triggered in Slice 3+ when the execution worker introduces multiple writers, or when any condition from [[../ADRs/ADR-002-sqlite-then-postgres]] § "Trigger to revisit" becomes true.

## Pre-flight

- Docker Desktop WSL integration enabled, OR native Postgres installed.
- `pg_isready` returns ready on the chosen host/port.
- `DATABASE_URL` added to `.env.example` + `.env`.

## Steps (estimated ~80 lines diff, contained to `apps/api/src/`)

1. Add `pg` dependency: `npm install pg --workspace apps/api`.
2. In `apps/api/src/db.ts`, replace better-sqlite3 connection with a `pg.Pool`.
3. Rewrite the four prepared statements (commands insert, commands select, audit insert, audit select). Schema is portable — no SQLite-only types in current DDL.
4. Switch better-sqlite3 synchronous calls to async — currently only `commands.ts` + `db.ts` touch the DB. Await everywhere.
5. Replace SQLite autoincrement with Postgres `BIGSERIAL` in `audit_log`.
6. Migration: dump SQLite to SQL with `sqlite3 data/command-center.db .dump`, hand-edit incompatible statements (rare given simple schema), psql-load into Postgres.

## Verify

- All endpoints from [[run-locally]] still return same shape.
- `audit_log` row count matches pre-migration.
- `npm run dev` clean — no leftover better-sqlite3 imports.

## Rollback

Keep `data/command-center.db` for 7 days. If anything misbehaves, revert the `db.ts` swap and the route async changes — schema in SQLite is intact.
