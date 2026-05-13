<!--
  PR template for the Brain vault.
  Keep it short. Fill every section. Path-guard CI will fail if you
  touch a protected folder without an `OPERATOR-APPROVED:` line.
-->

## Summary

<!-- What changed and why? 1–3 sentences is enough. -->

## Type

- [ ] Nexus content (note, runbook, decision draft inside `01-nexus/`)
- [ ] Bugfix (broken link, typo, frontmatter fix)
- [ ] New note
- [ ] Restructure (folder/file moves — requires operator approval)
- [ ] Tooling (scripts, `.github/`, CI — requires operator approval)

## Touched folders

<!-- List the top-level folders/files this PR edits, e.g.:
     - 01-nexus/runbooks/
     - 00-claude-inbox/nexus/
-->

## Checklist

- [ ] Only edited Nexus-allowed folders (`01-nexus/**`, `00-claude-inbox/nexus/**`, `_promote-candidates/**`) — OR attached an `OPERATOR-APPROVED:` marker below
- [ ] Ran `python scripts/brain_audit.py` locally and it passed
- [ ] No secrets in the diff (no API keys, tokens, `.env` values, broker creds)
- [ ] Used `[[wikilinks]]` for cross-note references, not absolute paths
- [ ] Frontmatter present on new/edited notes (`tags`, `type`, `created`)
- [ ] Did not modify protected folders (`_decisions/`, `_maps/`, `_runbooks/`, `claude-context/`, `.github/`, `scripts/`, `90-archive/`, root rule files) without an `OPERATOR-APPROVED:` line below

## Operator approval marker

<!--
  If this PR touches any protected path, the operator must add a line
  here in exactly this format (path-guard CI greps for it):

      OPERATOR-APPROVED: <short reason, e.g. "ratified at 2026-05-11 weekly review">

  Without this line, path-guard will block the merge for protected-path edits.
-->
