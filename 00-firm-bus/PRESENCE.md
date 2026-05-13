---
tags: [meta, firm-bus, presence]
type: meta
auto-updated: true
---

# firm-bus presence

Live "who's here" snapshot. Updated automatically by `firm-tab-init.sh` each
time a firm tab boots. Append-only — every tab launch adds one row.

To find the current state for a given role, read the LAST row that matches
that `(user, role)` pair. Rows older than 2h should be considered stale
(treat the role as offline). A sweeper may annotate stale rows with a
`stale` marker in the Status column.

Synced across machines via the Obsidian Git plugin (auto-pull every 2-5 min).

| Time | User | Role | Project | Status |
|---|---|---|---|---|
