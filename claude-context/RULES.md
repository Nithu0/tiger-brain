---
tags: [meta, claude-context]
type: meta
created: 2026-05-11
---

# RULES — binding rules for Claude in this vault

Read this together with [[START-HERE]]. These rules are binding; violations require operator override ("OK kjør" + named file).

## Write zone

Claude may freely write to:

- `00-claude-inbox/<project>/` — raw thinking by project
- Own session notes (dated, in inbox)
- `_promote-candidates/` — only if the operator has explicitly asked for promotion polish

Everywhere else is read-only by default.

## No-touch zone (read only unless "OK kjør" + named file)

- `_decisions/` — append-only decision-trees; new row only, never edit past rows
- `_maps/` — MOCs; structural, operator-owned
- `.github/`, `scripts/` — automation
- `claude-context/` itself — meta layer, operator-owned
- `BRAIN-RULES.md`, `00-DASHBOARD.md`, `01-CURRENT-FOCUS.md`, `SYSTEM-AUDIT.md` — top-level operator surfaces

## Secrets

Never paste env values, tokens, API keys, passwords, broker credentials, or wallet keys into any note. Variable names and "PRESENT/MISSING" status are OK. See `~/.claude/CLAUDE.md` "Secret handling" for the full rule.

## Wikilinks

Use `` `[[name]]` ``, not file paths. Broken stub-links are intentional — they mark notes the operator plans to write later. Do not "fix" them by creating empty stubs unless asked.

## Frontmatter

Every note Claude writes must include at minimum:

```yaml
---
tags: [...]
type: <note|moc|decision|handoff|meta|...>
created: YYYY-MM-DD
---
```

Add `updated:` when editing an existing note. Add `status: archived` when archiving.

## Foreign-project pollution

Do not write Nexus content into Thesis notes or vice versa. If a note touches both, file it in the more specific project's inbox and cross-link with `` `[[...]]` ``. When in doubt, check `pwd` and the active project in [[CURRENT]].

## Promotion gate

Inbox notes do not get promoted to repo docs (`/home/nithu/code/<repo>/docs/`) without explicit "OK kjør" + filename from operator. Polishing into `_promote-candidates/` also requires explicit ask.

## Big-picture changes need approval

Folder renames, MOC restructures, archive moves, mass tag changes, or any operation that touches >5 files structurally — stop and ask. These break the operator's mental model and link graph.

Sist oppdatert: 2026-05-11
