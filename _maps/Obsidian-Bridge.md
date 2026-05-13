---
type: integration
status: live
---
# Obsidian Bridge

Connection between Claude Code and the Obsidian vault at `~/Obsidian/Brain/`. Architecture: Obsidian Local REST API plugin (HTTPS 127.0.0.1:27124, self-signed cert) + MCP server (`obsidian-mcp-server` npm pkg, registered via `claude mcp add obsidian -s user`).

## Claude write boundaries
Claude writes ONLY to:
- `00-claude-inbox/<project>/<YYYY-MM-DD>-<slug>.md`
- `_promote-candidates/<YYYY-MM-DD>-<slug>.md`

Everything else is read-only by convention.

## Status (2026-05-11)
- Plugin installed + enabled
- MCP registered
- 97 .md files in vault
- 656 wiki-link occurrences
- 33 dead links being backfilled (this note is part of that backfill)

Linked to: [[Memory-MOC]], [[Tools-MOC]], [[Truth-Hierarchy]]
