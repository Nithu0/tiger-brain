---
tags: [command-center, adr, meta]
type: meta
created: 2026-05-16
---

# ADRs — command-center

Architecture Decision Records. Each ADR captures a binding choice with context, decision, and consequences. Immutable once accepted — supersede with a new ADR rather than editing.

## Convention

- Filename: `ADR-NNN-short-slug.md`
- Status: `proposed | accepted | superseded`
- Mirror the canonical ADR in `/home/nithu/code/command-center/docs/`. Source of truth is the repo; this folder is a brain-side copy for cross-referencing from notes, retros, and decisions.

## Index

- [[ADR-001-architecture]] — standalone repo, loose interfaces (file + HTTP only)
- [[ADR-002-sqlite-then-postgres]] — SQLite for Slice 1, Postgres in Slice 3
