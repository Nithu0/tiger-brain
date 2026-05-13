---
type: mcp
status: active
scope: scoped-write
---
# MCP-obsidian

Obsidian Local REST API MCP for this vault. Tool names: `mcp__obsidian__*`.

## Purpose
Lets Claude read any note in `/home/nithu/Obsidian/Brain/` and write to scoped locations — without operator having to copy-paste between terminal and Obsidian.

## Write scope
- ✅ `00-claude-inbox/` — Claude's scratchpad for observations during a session.
- ✅ `_promote-candidates/<YYYY-MM-DD>-<slug>.md` — staged for operator review before promotion.
- ✅ `_maps/` — MOC + leaf notes when backfilling dead links (per audit rounds).
- ⚠️ Other folders: read freely, write only when operator explicitly says "skriv det i `<folder>`".

## When to reach for it
- Resolving dead wiki-links (e.g. `\[\[X\]\]` style) found by vault audits.
- Capturing a durable observation that should outlive the session (drop in inbox, operator promotes).
- Reading project memory MOCs at session-start to load context.

## Activation
Powered by the Obsidian Local REST API community plugin (must be enabled in Obsidian + listening on the configured port). If MCP calls fail: check whether Obsidian app is running and the plugin is active — operator may have quit the app.

## Workflow integration
Sits between [[Distillation-Hook]] (writes raw notes) and [[Promote-Inbox-To-Repo]] (curates raw → durable). See [[Obsidian-Bridge]] for the full architecture.

Linked to: [[Tools-MOC]], [[Obsidian-Bridge]], [[Memory-MOC]], [[Distillation-Hook]]
