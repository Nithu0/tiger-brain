---
type: workflow
status: live
created: 2026-05-11
---
# Promote-Inbox-To-Repo

Workflow for curating raw vault inbox notes into durable repo memory.

## Flow
1. Operator (or Claude during distillation review) browses `00-claude-inbox/` in Obsidian.
2. Items deemed durable get moved to `_promote-candidates/<YYYY-MM-DD>-<slug>.md`.
3. Operator (or Claude with explicit "OK kjør") commits polished version to `docs/memory/promoted/<slug>.md` in the relevant repo.
4. Inbox notes auto-archive after 30 days into `90-archive/inbox/<YYYY-MM>/`.

## Why a pipeline, not direct writes
Inbox is RAW (per [[Memory-Lifecycle]]); only operator-blessed content reaches DURABLE repo memory. Prevents low-signal noise from polluting code-adjacent docs.

## Adjacent
Sits downstream of [[Distillation-Hook]] which writes the raw notes. See [[Obsidian-Bridge]] for full architecture.

Linked to: [[Workflows-MOC]], [[Memory-MOC]], [[Memory-Lifecycle]], [[Distillation-Hook]], [[Obsidian-Bridge]], [[Truth-Hierarchy]]
