---
type: runbook
trigger: code is staged + ready to commit + ready to deploy
autonomy_level: fix-locally (commit) / operator-only (push)
---
# Runbook: Push-Cycle

The canonical "edit → commit → push → verify" pattern. Push itself is harness-blocked for Claude (`git push origin main` denied); operator types it. Everything around the push is autonomous when operator has said "kjør på".

## Pre-commit checklist
1. **Reproduce the bug or confirm the win** locally if applicable. Don't ship blind.
2. **Typecheck**: `pnpm --filter <workspace> typecheck` (per `feedback-verification-gate.md` memory — `tsc --noEmit` beats full Next build).
3. **Tests**: `pnpm --filter <workspace> test` on touched workspace minimum. Don't break green.
4. **Read the diff**: `git diff --staged`. Catch accidents (secrets, debug logs, unrelated files).
5. **Scope discipline**: focused diffs only. If something tangential needs fixing, flag and hold.

## Commit
- Conventional commit style matching recent commits (`feat(...)`, `fix(...)`, `ops(...)`, `docs(...)`).
- Body explains the WHY, not just the WHAT.
- Co-author footer if applicable.
- NEVER `--no-verify` or `--no-gpg-sign` unless operator explicitly asked.
- NEVER `--amend` after a hook failure — make a NEW commit. The previous commit didn't happen.

## Push (operator-only)
Claude prepares the literal command for operator to paste:
```
git push origin main
```
The harness denies Claude's own `git push` calls per `feedback-push-permissions.md`. Stop here, await operator.

This is the "OK kjør"-gate ([[OK-Kjor-Gate]]). Even on autonomous-execute mode, push is operator-gated.

## Post-push verification
Run [[Runbook-Post-Deploy-Verification]] within 15 minutes of the push:
1. Railway deploy succeeded (`/health` returns 200, version SHA matches)
2. The specific change is visible in DB / endpoint / log
3. No new errors in Railway worker log
4. If money-impact: schedule 30-60 min re-check per `feedback_periodic_verification.md`

## What never auto-fires in this cycle
- `git push --force` to main (warn operator, refuse unless explicit).
- Push from a dirty working tree (`git status` must be clean except staged).
- Skip hooks. If pre-commit fails: fix, restage, NEW commit.
- Commit `.env*` files (deny rule).
- Auto-update git config.

## Examples from past sessions
- Recent commit log shows `ops(...)`, `fix(docs)`, `feat(cognitive-os)`, `feat(scripts)` — matches this pattern.
- Commit 937bd30: `.env.example` 156-var sync. Single focused diff. Pushed same day.
- Commit f551c17: silently-skipping strategies fix. Money-impact, but a bug-fix-not-strategy-change, no proposal needed.

## Linked
[[Operator-Principles]] · [[OK-Kjor-Gate]] · [[When-Operator-Says-Kjor-Pa]] · [[Runbook-Post-Deploy-Verification]]

Memory refs: `feedback-push-permissions.md`, `feedback-verification-gate.md`.
