---
tags: [meta, architecture, brain]
type: meta
created: 2026-05-13
---

# WHAT IS THE BRAIN?

## TL;DR

- Obsidian-vaulten ER hjernen — graph, MOCs, beslutninger, runbooks.
- Men hjernen lever ikke alene: den henter strøm fra Claude-memory, deler historikk via git, og peker mot kildekoden i andre repoer.
- Når du deler vaulten, deler du en SKIVE av økosystemet — ikke hele systemet.

## The 4 layers

| Layer | Lives at | Purpose | Shared with teammate? |
|---|---|---|---|
| **Obsidian vault (the brain)** | `~/Obsidian/Brain/` → `github.com/Nithu0/tiger-brain` | Graph + MOCs + decisions + runbooks + claude-context | Yes |
| **Claude memory** | `~/.claude/projects/.../memory/` | Persistent Claude recall between sessions | No — operator-only |
| **Code repos (source of truth)** | `~/code/ai-assistent`, `~/code/Master-oppgave`, etc. | Where actual work runs | Yes, separately |
| **Operator's muscle memory** | Your head + aliases + scripts | The glue | N/A |

## What flows where

- Code repos → `phase-status.md` → brain notes (1-way; code wins on conflict).
- Brain → Claude memory (1-way; memory is Claude's recall, vault is operator-readable).
- Operator → inbox → promote-candidates → brain (curation pipeline).
- Claude inbox writes → operator review → promoted notes.
- `_decisions/` → behavioral guardrails for both Claude and operator.

## Source-of-truth precedence (if conflict)

1. Code in the code-repo (authoritative).
2. `docs/ops/phase-status.md` in the relevant code-repo.
3. The brain notes.
4. Claude memory.
5. Operator's verbal recall.

## Why this matters for teammate

- They see ONE layer (the vault). They don't see Claude memory or operator's aliases.
- When they ask "what's the current state?", point to `phase-status.md` + `claude-context/CURRENT.md`.
- When they want to change behavior, the answer is rarely "edit the brain" — it's usually "edit the code, then update the brain".

## Why this matters for Claude

- Multiple companion brains coexist. Each Claude session loads:
  - Global `~/.claude/CLAUDE.md` (operator baseline)
  - Workspace `~/code/CLAUDE.md` (project map)
  - Project `<repo>/CLAUDE.md` (per-project rules)
  - Project memory `~/.claude/projects/.../memory/MEMORY.md` (persistent recall)
  - And NOW: this Obsidian vault (when working from it)
- Order: code instructions > vault notes > memory recall. Code wins.

## Ecosystem diagram

```
                  ┌────────────────────────────┐
                  │   operator (Nithu, in head)│
                  └────────────┬───────────────┘
                               │ curates
                               ▼
   ┌──────────────────────────────────────────────┐
   │   Obsidian Brain  (~/Obsidian/Brain)         │
   │   github.com/Nithu0/tiger-brain  ← SHARED    │
   │                                              │
   │   - graph (MOCs, decisions, runbooks)        │
   │   - claude-context (reading guide)           │
   │   - 00-claude-inbox (Claude write zone)      │
   │   - 01-nexus, 02-thesis, ...                 │
   └────┬───────────────────────────────┬─────────┘
        │ informs                       │ informs
        ▼                               ▼
   ┌──────────────────┐         ┌──────────────────────┐
   │  Claude memory   │         │  Code repos          │
   │  ~/.claude/      │         │  ai-assistent (LIVE) │
   │  (operator-only) │         │  Master-oppgave      │
   └──────────────────┘         │  battery-electro…    │
                                │  research-os         │
                                └──────────────────────┘
```

## What the brain is NOT

- NOT the code (code is in code repos).
- NOT the live trading firm (Nexus is in `~/code/ai-assistent`).
- NOT the operator's secrets vault (those stay in `.env` files outside git).
- NOT a CMS — it's a thinking layer.

## When the brain disagrees with the code

Code wins. Update the brain. See `BRAIN-RULES.md`.

## Related

- [[SYSTEM-MAP|claude-context/SYSTEM-MAP]] — mechanical map of vault layout
- [[BRAIN-RULES]] — binding rules
- [[Truth-Hierarchy]] — source-of-truth precedence (in `_maps/`)
- [[SYSTEM-AUDIT]] — current health snapshot

---

Sist oppdatert: 2026-05-13
