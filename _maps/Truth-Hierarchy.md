---
type: principle
canonical: true
---
# Truth Hierarchy

When sources disagree, this ranks which to trust. Per `docs/ops/truth-hierarchy.md` (binding).

## Rank
1. **Codebase + live system** — `git log`, `git blame`, code at HEAD, /health JSON, Postgres queries
2. **Current docs in `docs/ref/` and `docs/ops/`** — should match #1, but verify before asserting
3. **CLAUDE.md files** — project + global; ground rules
4. **Memory files** — point-in-time observations; can be stale
5. **Recent session summaries** — historical record

## Why
Memory captures snapshots; the world moves. When a memory says "X exists at line 42" and the file now has different content, trust the file.

## When to update memory
When you detect divergence: update the memory entry OR delete it. Do NOT act on stale memory.

Linked to: [[Memory-MOC]], [[Operator-Principles]], [[Distillation-Hook]], [[Phase-Status-Pointer]], [[Foundation-Gate]], [[Reconciliation]], [[When-Doc-Drifts-From-Code]], [[Karri]] (canonical reviewer; strategy proposals go through repo not vault)
