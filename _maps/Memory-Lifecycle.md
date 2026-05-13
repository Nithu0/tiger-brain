---
type: process
status: active
---
# Memory Lifecycle

How a Claude-observed fact moves from "I noticed this in a session" to "this is durable knowledge the next Claude inherits". Five stages, each with a clear handoff.

## Stages

| Stage | Lives at | Created by | Promoted by |
|---|---|---|---|
| **RAW** | `docs/memory/daily/YYYY-MM-DD.md` + Obsidian `00-claude-inbox/` | [[Distillation-Hook]] (Stop event, automatic) | Operator review |
| **DISTILLED** | `docs/memory/PROMOTE_QUEUE.md` + Obsidian `_promote-candidates/` | Distillation hook queues; operator reviews | Operator + Claude with "OK kjør" |
| **PROMOTED** | `docs/memory/promoted/<slug>.md` (repo) + `~/.claude/projects/<slug>/memory/` | Operator-gated commit | n/a — durable until deprecated |
| **DEPRECATED** | Same file, frontmatter `status: deprecated` + reason | Author of the change that obsoletes it | n/a — kept for history |
| **ARCHIVED** | `90-archive/` in Obsidian or `docs/memory/archive/` in repo | Time (30d inbox auto-archive) or operator | Read-only |

## Invariants

- **Promotion is always operator-gated.** Claude never auto-promotes, even with [[Distillation-Hook]] running. The hook queues; operator decides.
- **Data is never stopped** during cleanup — per [[Operator-Principles]] rule 2. Pruning targets what is kept, not whether anything is written.
- **Deprecated ≠ deleted.** Keep the file with a deprecation note so future Claude sessions can see why X was tried and abandoned.
- **Cross-project firewall holds at every stage.** Thesis observations never enter Nexus memory and vice versa.

## When the hook is dry-run
[[Distillation-Hook]] currently runs in DRY_RUN until operator activates. RAW notes during dry-run are written but not auto-promoted — manual capture into `00-claude-inbox/` still works.

Linked to: [[Memory-MOC]], [[Distillation-Hook]], [[Promote-Inbox-To-Repo]], [[Truth-Hierarchy]]
