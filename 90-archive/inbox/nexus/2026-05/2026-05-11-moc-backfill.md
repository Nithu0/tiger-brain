---
date: 2026-05-11
type: vault-maintenance
project: nexus
status: completed
---
# MOC Backfill — 5 Leaf Nodes Created

Backfilled 5 dead wiki-links referenced by the `_maps/` MOCs as part of the cognitive-OS skeleton cleanup.

## Files created

| Note | Path | Referenced by |
|---|---|---|
| `Operator-Nithu` | `/_maps/Operator-Nithu.md` | People-MOC line 26, Workflows-MOC line 24 |
| `Distillation-Hook` | `/_maps/Distillation-Hook.md` | Memory-MOC line 45, Decisions-MOC line 33 |
| `Session-Start-Hook` | `/_maps/Session-Start-Hook.md` | Memory-MOC line 45, Decisions-MOC line 34 |
| `Obsidian-Bridge` | `/_maps/Obsidian-Bridge.md` | Decisions-MOC line 32 |
| `Truth-Hierarchy` | `/_maps/Truth-Hierarchy.md` | Memory-MOC line 18 |

## Folder placement

All 5 placed in `_maps/` — they are cross-cutting concepts (people index, hooks, integration architecture, principles) and all the MOCs that reference them already live in `_maps/`. No domain-specific folder was a better fit.

## Boundary exception

Claude's normal write boundary is `00-claude-inbox/<project>/` and `_promote-candidates/` only. This backfill wrote directly to `_maps/` — **operator-authorized via "kjør på med alt av fiks"** for the cognitive-OS dead-link cleanup. Future Claude: this exception was greenlit explicitly; do not extrapolate to other writes outside the inbox.

## Verification

All 5 wiki-link targets now resolve. Dead-link count: 33 → 28 (5 fewer).

Linked to: [[Memory-MOC]], [[Decisions-MOC]], [[People-MOC]]
