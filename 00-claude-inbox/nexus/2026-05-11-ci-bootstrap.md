---
date: 2026-05-11
project: nexus
type: ops
status: shipped
commit: ab380dc
---

# CI bootstrap — husky local gate

Minimal local CI installed. No GitHub Actions yet.

## What landed

- `husky@9.1.7` as root devDependency (workspaces excluded)
- `.husky/pre-commit` — runs `tsc --noEmit` per workspace with staged `.ts/.tsx` changes; idempotent (no TS staged → exit 0)
- `.husky/pre-push` — runs `cd apps/worker && npm test`
- `package.json` → `"prepare": "husky"` (re-installs on every `npm install`)
- `CLAUDE.md` — new "Local CI gate (binding 2026-05-11)" section
- Commit: `ab380dc chore(ci): add husky pre-commit (tsc) + pre-push (worker tests)`

## Verification

- Hook fired on the bootstrap commit itself — output: `[pre-commit] no TS changes — skipping tsc` (correct: no TS files staged in this commit)
- Worker tsc post-commit: clean (silent success)
- Pre-push not dry-run-tested — `git push --dry-run` is harness-blocked. Operator verifies on first real push.

## Operator-visible behavior next time

1. **Next `git commit`** — pre-commit hook runs. If TS files staged, runs `npx tsc --noEmit` in each touched workspace. Red tsc = commit aborted.
2. **Next `git push`** — pre-push runs `apps/worker` test suite (~2.4s, 443/443 last green). Red tests = push aborted.
3. **Bypass** (if needed for emergency): `--no-verify` on commit/push. Don't use without reason.

## Caveats

- `chmod +x` on the user-level hook files is harness-blocked; not needed because husky v9 invokes hooks via `sh -e "$s"` (the inner `_/pre-commit` is already executable from `npx husky init`). Confirmed working by the install-time commit firing the hook.
- Pre-push only tests `apps/worker`. `apps/api` + `apps/dashboard` not covered yet (separate ticket if desired).
- Husky install bumped `package-lock.json`; 17 npm-audit warnings reported but unrelated (existing baseline).

## Not done

- GitHub Actions — explicitly deferred per ticket scope.
- `apps/api` + `apps/dashboard` pre-push coverage.
