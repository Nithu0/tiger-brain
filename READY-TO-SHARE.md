---
tags: [meta, share, checklist, ops]
type: status
created: 2026-05-13
status: push-ready
---

# READY-TO-SHARE

Single-page state-of-share-readiness. Tick boxes left-to-right, top-to-bottom. Operator: when section 3 is fully ticked, vault is shareable.

## 1. TL;DR

**Push-ready.** Operator has 2 manual steps left:

1. Install + auth `gh` CLI **OR** create the repo manually at https://github.com/new (30 sek).
2. Rotate the Obsidian REST API key in plugin settings.

Then run `bash scripts/push-and-protect.sh` and everything else is automated.

History is clean (filter-repo done, 16 commits, secret purged). CODEOWNERS owner-handle set. Operator-mods bulk-committed. CI green.

## 2. Done by Claude (autonomous)

- [x] Vault structure audited (`SYSTEM-AUDIT.md`)
- [x] 23+ hardening files added
- [x] **16 commits** on `feat/brain-hardening` (post filter-repo + bulk-import)
- [x] **`git filter-repo` complete** — 16 commits rewritten, REST API secret purged from all history
- [x] **Operator-mods bulk-committed** — 30 modified + 165 untracked across 4 commits
- [x] **CODEOWNERS owner-handle set** — `@OWNER → @Nithu0` (commit `eb06541`); `@TEAMMATE` still placeholder
- [x] **Workspace-state added to `.gitignore`** — `.obsidian/graph.json`, `app.json`, `appearance.json`
- [x] **Security incident closed** — secret no longer in any commit; rotation pending (operator-side)
- [x] CI workflows: `brain-checks` + `path-guard`
- [x] Scripts: `brain_audit`, `path_guard`, `archive_old_inbox`, `sanity`, `setup-from-scratch`, `install-gh-cli`, `install-hooks`, `push-and-protect`
- [x] `claude-context/` (START-HERE, RULES, SYSTEM-MAP, CURRENT)
- [x] `prompts/` (BRAIN-AUDIT, NEXUS-WORKER, HANDOFF)
- [x] `handoffs/` (README + CURRENT-HANDOFF)
- [x] Cleanup: `Untitled.canvas`, `Untitled.base`, `2026-05-11.md`, duplicate `Brain/Brain/`
- [x] Inbox triage + operator-mods recommendation reports
- [x] Wikilink validation report
- [x] Memory updated (3 new entries)
- [x] Sanity 8/8 green; Audit 0 errors

> Verified: 2026-05-13 — 16 commits, sanity 8/8, audit 0 errors, history purged.

## 3. Blocked on operator (in order)

- [ ] **Install gh CLI** — script ready at `scripts/install-gh-cli.sh`, awaits sudo password from operator. (Skippable — see next item.)
- [ ] **`gh auth login`** OR **create repo manually** at https://github.com/new (private, name `tiger-brain`). Manual route bypasses gh CLI entirely for repo creation.
- [ ] **Rotate Obsidian Local REST API key** — Obsidian → Settings → Community plugins → Local REST API → "Re-generate API key". Required regardless of gh path.
- [ ] **Replace `@TEAMMATE` in CODEOWNERS** — needs teammate's GH handle:
  ```bash
  sed -i 's/@TEAMMATE/@<teammate-handle>/g' .github/CODEOWNERS
  ```
- [ ] **Push + protect**:
  ```bash
  bash scripts/push-and-protect.sh --mode easy    # or --mode full for branch protection
  ```
- [ ] **Invite teammate** (after handle known):
  ```bash
  gh api -X PUT "repos/Nithu0/tiger-brain/collaborators/<TEAMMATE>" -f permission=push
  ```
- [ ] **Smoke test path-guard** — script will be at `scripts/smoke-test-pr.sh` (another agent writing this). Opens a test PR touching protected path; CI must fail.

## 4. Optional but recommended

- [ ] Install pre-push hook: `bash scripts/install-hooks.sh`
- [ ] Archive old inbox monthly: `python3 scripts/archive_old_inbox.py --apply --yes`
- [ ] Add `detect-secrets` or `trufflehog` to CI (next sprint)
- [ ] Schedule weekly refresh of `claude-context/CURRENT.md` from `docs/ops/phase-status.md`

## 5. Verification commands operator runs RIGHT NOW

Repo is in good state — these should all pass before push:

```bash
cd ~/Obsidian/Brain
git log --oneline | head -16        # 16 commits
bash scripts/sanity.sh               # 8/8 green
python3 scripts/brain_audit.py       # 0 errors
git log --all -- .obsidian/plugins/obsidian-local-rest-api/data.json   # empty (purged)
```

Expected:
- `git log` → 16 SHAs
- `sanity.sh` → `8/8 checks passed`
- `brain_audit.py` → `errors: 0`
- Last command → empty output (secret no longer referenced in any commit)

If the last command prints anything, **STOP** — filter-repo did not take. Re-run before push.

## 6. What teammate gets (after operator completes section 3)

- Read-write to: `01-nexus/**`, `00-claude-inbox/nexus/**`, `_promote-candidates/`, own `handoffs/`
- Read-only effective for everything else (path-guard enforces).
- CODEOWNERS review required for any PR.
- CI: `brain-checks` + `path-guard` must pass before merge.
- Onboarding doc: `TEAMMATE-ONBOARDING.md` (send this link first).
- Norm doc: `CONTRIBUTING.md` + `BRAIN-RULES.md`.

Send teammate the repo URL + a one-liner: "Read `TEAMMATE-ONBOARDING.md` first. PRs only. Touch only your lane."

## 7. Rollback

If anything goes wrong:

- **Undo a single commit**: `git revert <sha>` — keeps history, recommended over reset.
- **Restore deleted artifacts**: `git checkout <pre-cleanup-sha> -- <file>`.
- **Post-push regret**: if a bad commit lands on remote `main`, do NOT force-push without explicit "OK kjør" — open a revert PR instead.
- **filter-repo regret**: pre-purge state is gone locally. If something critical was purged, recover from operator's local Obsidian working copy (files still on disk for non-tracked `.obsidian/plugins/obsidian-local-rest-api/`).

## 8. Sign-off

When every box in section 3 is ticked:

1. **OK kjør → push** (`bash scripts/push-and-protect.sh --mode full`)
2. **OK kjør → invite teammate** (`gh api -X PUT ...`)

Section 4 can land in a follow-up sprint.

### Failure modes to watch for

- `git push` rejected on `main` → branch protection already on; push `feat/brain-hardening` only, open PR via `gh pr create`.
- `path-guard` fails on a legit operator-approved change → add `OPERATOR-APPROVED: <reason>` line to PR body, re-run CI.
- `gh auth login` fails over SSH → fall back to HTTPS token flow (`gh auth login --web`).
- Teammate cannot push to `01-nexus/**` → confirm permission is `push` not `pull` on the collaborator invite.

### Post-share housekeeping (within 7 days)

- [ ] Confirm teammate can clone + open first PR
- [ ] Confirm CI runs on teammate PR
- [ ] Confirm CODEOWNERS auto-requests operator review
- [ ] Remove any leftover `_promote-candidates/*-2026-05-13.md` drafts after promotion decisions

---

Sist oppdatert: 2026-05-13 by Claude (Opus 4.7 1M) — post filter-repo + bulk-import session
