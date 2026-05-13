---
title: "Obsidian vault inventory — territory map for ingestion planning"
date: 2026-05-13
author: Claude (scout agent)
type: snapshot
tags: [meta, inbox, inventory, rag-prep]
purpose: "Ground-truth the vault state before deciding where ingested knowledge sources land"
---

# TL;DR

Vault is well-organized, MOC-first, frontmatter-disciplined, ~340 md files across 14 top-level folders. **No existing `_library/` or `_sources/` folder exists.** Closest neighbour: `05-learning/` (Currently-Reading, Books-And-Papers, Notes-On-Trading-Systems — all stubs). Trading domain knowledge today lives in `01-nexus/` (modules + strategies, applied not theoretical). Convention: `tags: [domain, type-marker, topic]`, `type: atomic|moc|meta|stub|...`, `created: YYYY-MM-DD`, wikilinks only, one H1 = filename. **Recommended new home: `_library/` at root** (sibling to `_maps/`, `_runbooks/`, `_decisions/`) — underscore prefix signals "operator infra, not domain content"; keeps ingested sources distinct from operator-written notes.

# Vault map (md counts, recursive)

| Folder | MD | Purpose |
|---|---|---|
| `00-DASHBOARD.md` + 7 root files | 8 | Orientation, BRAIN-RULES, SYSTEM-AUDIT, README |
| `00-claude-inbox/` | 113 | Dated Claude write-zone (`<project>/YYYY-MM-DD-<slug>.md`); auto-archives at 30d |
| `00-firm-bus/` | 11 | Inter-terminal coordination (feed.md + inbox/<role>.md) |
| `01-nexus/` | 46 | Nexus domain: modules/, strategies/, operations/, runtime/, runtime-state/, session-summaries/ |
| `02-thesis/` | 30 | concepts/, dataset/, methods/, open-questions/, logistics/ |
| `03-business/`, `04-career/` | 8+8 | MOC + stubs |
| `05-learning/` | 8 | **Closest existing analogue** to a library — but stub-heavy, append-log style |
| `_decisions/` | 10 | Append-only decision trees ("When-X-Happens.md") |
| `_maps/` | 46 | MOCs (one per concept) — Tools, Memory, Decisions, Workflows, People + per-MCP pages |
| `_runbooks/` | 6 | Procedural runbooks |
| `_promote-candidates/`, `handoffs/`, `prompts/`, `claude-context/` | <5 each | Promote queue, handoffs, prompt templates, Claude entry-point |
| `90-archive/inbox/` | 1 | Auto-archive sink |

# Conventions in force

- **Frontmatter (binding)**: `tags`, `type`, `created`. Common `type` values: `atomic, moc, meta, stub, decision, runbook, mcp, person, gate, hook, principle, snapshot, reference, workflow, integration`. Common tag bases: `nexus, thesis, learning, moc, meta`. Optional fields seen: `owner`, `status`, `next`.
- **Wikilinks only** (`[[Note-Name]]` or `[[Note-Name|Alias]]`) — no markdown links to vault files.
- **One H1 per note** matching filename concept.
- **MOC pattern**: every domain has one (`Nexus-MOC`, `Thesis-MOC`, `Learning-MOC`, etc.); atomic notes link back; MOC links out. Densest cluster in graph view = `README.md` at root.
- **Inbox naming**: `<project>/YYYY-MM-DD-<slug>.md` flat OR `<project>/YYYY-MM-DD/<NN_slug>.md` (parallel-batch sessions, like today).

# Existing trading-knowledge surface

- `01-nexus/strategies/`: `Strategy-ORB`, `Strategy-Scalp-Overlap`, `Strategy-Session-Breakout`, `Strategy-Vol-Expansion` — applied/in-production strategy docs (tagged `nexus, strategy, <name>`).
- `01-nexus/modules/Module-ORB.md` — implementation pointer.
- `05-learning/Notes-On-Trading-Systems.md` — stub, no real content yet. Designed as "textbook + paper layer behind design choices" per its own description. **This is where curriculum-derived notes would naturally cross-link.**
- `05-learning/Books-And-Papers.md` — stub, append-log format `YYYY-MM-DD — Title — Author — takeaway — [[topic]]`. Designed as finishing-log.

# Existing ingestion-related notes (siblings filing today)

- `08_rag_architecture.md` — RAG design (recommends curated index + tagging, no vector DB initially)
- `09_ingestion_tooling.md` — picks `marker` for PDF→md, drafts YT pipeline; **assumes target `~/Obsidian/Brain/_library/`**
- `10_trading_curriculum.md` — 10-source reading plan (Fisher, Crabel, Raschke, Chan, Carver, Williams, gold papers, Rickards)

# Recommended location for ingested knowledge

**`_library/`** at vault root. Rationale:

1. **Underscore prefix** matches `_maps/`, `_runbooks/`, `_decisions/`, `_promote-candidates/` — operator-infra convention, sorts above numbered domains.
2. **Keeps operator-written notes separate** from machine-ingested content. `05-learning/` stays for operator's own synthesis + reading-log; `_library/` holds source-of-truth ingested text (which is voluminous + low-edit).
3. **BRAIN-RULES already lists** `_decisions/` as protected ("operator-owned, no edits without OK kjør"). `_library/` can adopt the same rule: Claude reads freely, writes only via the ingestion pipeline; operator-curated summary notes go in `05-learning/` and cross-link to `_library/` sources.
4. Sibling agent 09 (`09_ingestion_tooling.md`) already assumes this path — alignment confirmed.

Suggested structure (architecture agent's call, not mine):
- `_library/books/<author>/<title>/` for chaptered books
- `_library/youtube/<channel>/<YYYY-MM-DD-slug>/` for transcripts
- `_library/papers/<year>-<slug>.md` for single-file papers
- `_library/_Library-MOC.md` as the hub, linked from `Learning-MOC` and `Nexus-MOC`

# Frontmatter + tag convention to adopt for ingested notes

Match existing patterns. Suggested fields:

```yaml
---
tags: [library, <medium>, <topic>]   # e.g. [library, book, orb] or [library, youtube, regime]
type: source                          # NEW type-marker; sits alongside atomic/moc/meta
created: 2026-05-13                   # ingestion date
source_type: book | youtube | paper | blog
source_title: "The Logical Trader"
source_author: "Mark Fisher"
source_url: ""                        # if applicable
ingested_via: marker | yt-dlp+whisper
status: raw | distilled | promoted
---
```

Tag base `library` is new but consistent with existing single-word domain roots (`nexus`, `thesis`, `learning`, `meta`). Topic tags should reuse existing ones (`orb`, `regime`, `mean-reversion`, `gold`, `xauusd`) to merge graph clusters.

# Notes for whoever designs the architecture next

- `BRAIN-RULES.md` will need a paragraph on `_library/` (read-policy, write-policy, who can edit).
- `_maps/_README.md` should get a `_library/` MOC entry.
- `00-DASHBOARD.md` "Quick links" row may want a `[[Library-MOC]]` once non-empty.
- `00-claude-inbox/_README` lifecycle (Inbox → `_promote-candidates/` → repo) does NOT fit ingested sources — they're not repo-bound. New lifecycle needed: `raw markdown → distilled summary → cross-linked from Learning + Nexus`.
- Vault is a git repo (`.git` present, `.github/workflows` exists) — large ingested files will bloat history. Consider `.gitignore` for `_library/raw/` and only commit `_library/distilled/` summaries.
