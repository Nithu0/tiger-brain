# Brain — Obsidian vault

Knowledge graph + thinking layer. Companion to GitHub repos (which remain source of truth for code/docs).

## Layout

| Folder | Purpose | Claude write? |
|---|---|---|
| `00-claude-inbox/` | Daily captures by Claude, per project | YES |
| `01-nexus/` | Operator-curated Nexus notes (mirrors repo via `_repo-docs`) | NO (read-only) |
| `02-thesis/` | Operator-curated thesis notes (mirrors repo via `_chapters` + `_docs`) | NO (read-only) |
| `03-business/` | Personal business notes | NO |
| `04-career/` | Personal career notes | NO |
| `05-learning/` | Personal learning notes | NO |
| `90-archive/` | Read-only history (auto-archived inbox after 30d) | NO |
| `_maps/` | Operator-curated Maps of Content (MOCs) | NO |
| `_promote-candidates/` | Items proposed for promotion to repo docs | YES |

## Claude write boundaries

ONLY two write paths:
- `00-claude-inbox/<project>/<YYYY-MM-DD>-<slug>.md`
- `_promote-candidates/<YYYY-MM-DD>-<slug>.md`

Everything else: read-only by convention. Enforced via CLAUDE.md hard rule + operator audit.

## Promote workflow

`00-claude-inbox/` → operator review → `_promote-candidates/` → operator promotes polished version to `docs/memory/promoted/<slug>.md` in the relevant repo.

## Git

This vault is a private local git repo (30s rollback). Not pushed to any remote. See `.gitignore` for excluded Obsidian state.

## Symlinks (read-only mirrors)

- `01-nexus/_repo-docs` → `/home/nithu/code/ai-assistent/docs`
- `02-thesis/_chapters` → `/home/nithu/code/Master-oppgave/chapters`
- `02-thesis/_docs` → `/home/nithu/code/Master-oppgave/docs`

## Spec

See `/home/nithu/code/ai-assistent/docs/architecture/obsidian-bridge.md` for full design + rationale.
