---
type: decision
status: live
created: 2026-05-11
---
# Secrets-Policy

Binding allowed / not-allowed list for secret-bearing files. Source-of-truth: `docs/architecture/secrets-policy.md` in Nexus repo + operator's global CLAUDE.md.

## Allowed
- Read `.env.example` (variable names + comments only — no values)
- List required env vars
- Check existence via `scripts/env-doctor.sh` (PRESENT / MISSING only — no values)

## NEVER allowed
- Print `.env`, `.env.local`, `.env.production`, `.env.staging` values
- Commit secrets to any repo
- Copy secret values into transcripts, memory, or Obsidian
- Send secrets to external tools (web, Discord, email)
- Read `.git/config` (may contain GitHub token)
- Read `~/.ssh/**`

## Enforcement
`.claude/settings.json` deny-rules block direct read of `.env*` paths. Operator pastes any needed value once per session into transcript (operator's responsibility, not Claude's).

## Failure response
If Claude is asked to read a forbidden file: refuse explicitly, name the rule, propose the fix (operator pastes the value).

Linked to: [[Decisions-MOC]], [[Operator-Principles]], [[Permissions-Diff]], [[Global-CLAUDE-md]]
