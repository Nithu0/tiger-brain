---
title: Library bootstrap audit (round 2, 13.5)
tags: [audit, library, bootstrap]
type: audit
date: 2026-05-13
---

# Library bootstrap audit — round 2, 2026-05-13

Task: bootstrap the trading-knowledge library scaffolding — INDEX MOC, Claude skill router, CLAUDE.md pointer. Sibling agents fill the section contents same session.

## Files created

| Path | Size |
|---|---|
| `~/Obsidian/Brain/_library/trading/INDEX.md` | 3788 bytes |
| `~/.claude/skills/trading-knowledge/SKILL.md` | 5381 bytes |

The `~/.claude/skills/` parent directory did not exist before this task — created it as part of the SKILL.md write. Folder structure now:

```
~/.claude/skills/
└── trading-knowledge/
    └── SKILL.md
```

No `references/`, `examples/`, `scripts/` subdirs created yet — SKILL.md body is lean (~700 words) and self-contained for v0.1. Add subdirs later when content depth justifies progressive disclosure.

## CLAUDE.md change (diff snippet)

Single-row addition to the "Where to find details" table, appended after the firm-bus row to keep Obsidian-anchored entries co-located:

```diff
 | firm-bus convention (inter-terminal coordination) | `~/Obsidian/Brain/00-firm-bus/README.md` |
+| **Trading knowledge library (Obsidian)** | `~/Obsidian/Brain/_library/trading/INDEX.md` |
```

No other edits to CLAUDE.md.

## Gotchas hit

1. **No prior `~/.claude/skills/` directory.** First user-level skill on this machine. Convention had to be inferred from the marketplace plugin examples at `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/plugin-dev/skills/skill-development/SKILL.md`. Confirmed YAML frontmatter expects only `name` + `description` as required (with optional `version`); `tools` key mentioned in the task brief is NOT part of the documented plugin-skill schema, so it was omitted to avoid breaking the loader. The system-reminder skill list (e.g. `update-config`, `simplify`, `loop`) shows skills are referenced by name only, consistent with this.

2. **Skill description style is third-person + trigger-phrase heavy.** Followed plugin-dev convention strictly: `"This skill should be used when the user asks about..."` instead of second-person. All operator-supplied trigger phrases (strategy, trade, gate, regime, ORB, trend, mean reversion, Karri, XAUUSD) included verbatim plus a few obvious extensions (S1–S4, foundation gate, daily trade cap, trend pause).

3. **Skill body written in imperative form** per the plugin-dev style guide — "Read the INDEX first" not "You should read the INDEX". Matches the rest of the skill ecosystem.

4. **Frontmatter on INDEX.md** uses Obsidian-style YAML (title / tags / type) since it's an Obsidian note, distinct from the skill's frontmatter schema. Tags `[library, MOC]` per task spec.

5. **Cross-reference to prior RAG analysis** baked into both INDEX.md and SKILL.md — pointing at `00-claude-inbox/nexus/2026-05-13/08_rag_architecture.md` so the 30-lesson re-eval trigger lands somewhere actionable.

6. **No `tools:` key in skill frontmatter.** Task brief mentioned the YAML may include `name`, `description`, `tools` — but the documented plugin-skill schema only requires `name` + `description`. Adding `tools` without confirmed loader support risks the skill being rejected; omitted. If a future Claude session confirms `tools` is supported at user-level skill scope, add `tools: [Read, Grep, mcp__obsidian__obsidian_search_notes]` then.

## Verification

- INDEX.md readable, frontmatter valid, four sections (Concepts / Strategies / Lessons / Sources) with empty-section markers ready for sibling-agent fills.
- SKILL.md frontmatter validates against plugin-dev convention.
- CLAUDE.md table row inserted exactly once, no collateral edits (verified by single-line `old_string` match).

## Not done

- Section contents (sibling agents owning those today per task framing).
- Skill testing — cannot trigger the skill in this same session; first real test happens on the next session that asks a trading-domain question.
- No commit of CLAUDE.md change. Operator decides when to stage / commit / push.
