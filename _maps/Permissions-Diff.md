---
type: decision
status: proposed
created: 2026-05-11
---
# Permissions-Diff

Proposed `.claude/settings.json` diff to right-size Claude's harness permissions. Source: `docs/architecture/permissions-diff.md` in Nexus repo.

## Buckets
- **Allow** — bash commands and MCP tools used so frequently that permission-prompts cost more friction than the marginal safety. e.g. `git status`, `git diff`, `pnpm typecheck`, `mcp__nexus-pg__*`, `curl /health`.
- **Deny** — irreversible or secret-bearing operations. e.g. `git push --force`, `rm -rf`, `cat .env*`, `git config --global`.
- **Ask** — destructive-but-legitimate ops where operator confirmation is appropriate per-call. e.g. `git push origin main` (harness-blocked anyway), `mcp__nexus-pg-rw__query` with DELETE/UPDATE.

## Goal
Reduce permission-prompt fatigue while preserving the gates from [[Operator-Principles]] and [[Secrets-Policy]].

## Status
PROPOSED. Operator reviews and applies via the `update-config` skill before any merge.

## Related skill
The `fewer-permission-prompts` skill scans transcripts for common read-only calls and proposes additions to the allow-list.

Linked to: [[Decisions-MOC]], [[Secrets-Policy]], [[Operator-Principles]], [[Tools-MOC]]
