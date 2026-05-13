---
tags: [rules, meta, governance]
type: meta
created: 2026-05-11
---

# BRAIN-RULES

Operating rules for this vault. Applies to operator, teammate, and Claude. Binding unless operator overrides.

## Source of truth (per project)

- **Nexus** -> code in `ai-assistent/` + `docs/ops/phase-status.md`. Vault holds context and decisions, not state.
- **Thesis** -> `Master-oppgave/` repo (LaTeX/Overleaf) + `battery-electrolyte-predictor/` for code/results.
- **Business / Career / Learning** -> vault is primary; promote anything load-bearing into a repo when one exists.

## Where to write

- **Default**: drop new notes in [[00-claude-inbox/README|00-claude-inbox]] under the right project folder. Don't pre-optimize.
- After it earns its keep -> move to project folder (`01-nexus/`, `02-thesis/`, etc.) or to `_promote-candidates/` for repo migration.
- MOCs in `_maps/` are curated — only add a link when the atomic note is stable.

## Where NOT to write without "OK kjør"

These are operator-owned and must not be edited without an explicit go-ahead:

- `claude-context/` (Claude's entry-point material)
- `_decisions/` (immutable decision log — append-only, dated)
- `00-DASHBOARD.md`, `01-CURRENT-FOCUS.md`, `BRAIN-RULES.md`
- `SYSTEM-AUDIT.md` (if/when present)
- `.github/`, `scripts/`

## Link convention

- **Wikilinks only**: `` `[[Note-Name]]` `` or `` `[[Note-Name|Alias]]` ``. No markdown links inside the vault.
- **Frontmatter required** on every note: `tags`, `type` (`moc` | `atomic` | `meta`), `created: YYYY-MM-DD`.
- One H1 per note matching the filename concept.

## Inbox naming

Format: `<project>/<YYYY-MM-DD>-<slug>.md`

Example: `00-claude-inbox/nexus/2026-05-11-foundation-gate-thoughts.md`

## Promote workflow

`00-claude-inbox/` -> review -> `_promote-candidates/` (stage with intended destination) -> land in the relevant repo's `docs/` (or stable vault folder if no repo).

## Archive workflow

After ~30 days untouched in inbox: move to `90-archive/inbox/<YYYY-MM>/`. Nothing is deleted — archive is cold storage.

## Secrets

**NEVER** write env values, tokens, passwords, API keys, or `.env*` contents into the vault. Variable **names** and **comments** are fine. If in doubt, leave it out.

## Daily notes

- Location: vault root, filename `YYYY-MM-DD.md`.
- Empty placeholder is fine. No required template.
- Not a status file — status lives in [[01-CURRENT-FOCUS]].

## If unsure

Ask the operator. Don't restructure folders, rename top-level files, or change conventions without explicit go-ahead.

---

Sist oppdatert: 2026-05-11
