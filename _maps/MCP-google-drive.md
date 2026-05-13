---
type: mcp
status: active
scope: files-read-write
created: 2026-05-11
---
# MCP-google-drive

Google Drive MCP. Tool names: `mcp__claude_ai_Google_Drive__*`.

## What it enables
- Search files across operator's Drive.
- Read file content + metadata.
- Create / copy files; download content.
- Inspect permissions; list recent files.

## When to reach for it
- Operator shares a Drive link and asks Claude to read / summarise it.
- Exporting a Nexus report or audit summary to Drive for sharing.
- Looking up an old doc (PDFs, sheets) that lives in Drive not the vault.

## Boundaries
- Don't write or copy without operator-OK on target folder.
- Treat shared-with-me files as read-only unless operator explicitly authorises edits.

## Source
`reference_available_tools.md` memory.

Linked to: [[Tools-MOC]], [[Decision-Tools-Roster-Habit]]
