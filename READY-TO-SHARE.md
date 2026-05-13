---
tags: [meta, share, checklist, ops]
type: status
created: 2026-05-13
status: blocked-on-operator
---

# READY-TO-SHARE

Single-page state-of-share-readiness. Tick boxes left-to-right, top-to-bottom. Operator: when section 3 is fully ticked, vault is shareable.

## 1. TL;DR

- Hardening done (23+ files, 5 commits, CI + path-guard, sanity 8/8, audit 0 errors).
- Blocked on operator for: (a) `gh` CLI install + `gh auth login`, (b) secret-in-history decision (purge vs. rotate-and-accept), (c) CODEOWNERS placeholder replacement.
- Repo is local-only on `feat/brain-hardening`. Nothing pushed. Teammate not yet invited.

Time-to-share estimate after operator starts: **15-30 min** (Option B/rotate-only) or **30-60 min** (Option A/purge history). Most of that is waiting for installs.

## 2. Done by Claude (autonomous)

- [x] Vault structure audited (`SYSTEM-AUDIT.md`)
- [x] 23+ hardening files added
- [x] 5 commits on `feat/brain-hardening` branch
- [x] CI workflows: `brain-checks` + `path-guard`
- [x] Scripts: `brain_audit`, `path_guard`, `archive_old_inbox`, `sanity`, `setup-from-scratch`, `install-gh-cli`, `install-hooks`
- [x] `claude-context/` (START-HERE, RULES, SYSTEM-MAP, CURRENT)
- [x] `prompts/` (BRAIN-AUDIT, NEXUS-WORKER, HANDOFF)
- [x] `handoffs/` (README + CURRENT-HANDOFF)
- [x] Cleanup: `Untitled.canvas`, `Untitled.base`, `2026-05-11.md`, duplicate `Brain/Brain/`
- [x] `.gitignore` extended; `obsidian-local-rest-api/` untracked
- [x] Security incident documented (`SECURITY-INCIDENT-API-KEY.md`)
- [x] Inbox triage report (`_promote-candidates/INBOX-TRIAGE-2026-05-13.md`)
- [x] Operator-mods recommendation (`_promote-candidates/OPERATOR-MODS-RECOMMENDATION-2026-05-13.md`)
- [x] Wikilink validation report (`_maps/wikilink-validation-2026-05-13.md`)
- [x] Memory updated (3 new entries)
- [x] Sanity 8/8 green; Audit 0 errors

> Verified: 2026-05-13 — sanity 8/8, audit 0 errors, 0 warnings (update if wikilink-fix run lands non-zero).

## 3. Blocked on operator (in order)

- [ ] **Install gh CLI** — `bash scripts/install-gh-cli.sh` (currently missing on this host)
- [ ] **`gh auth login`** — authenticate with the GitHub account that will own the repo
- [ ] **Decide secret-in-history strategy** — Option A (purge with `git filter-repo`) or Option B (accept history + rotate key). See `SECURITY-INCIDENT-API-KEY.md`. Default recommendation: **A** (purge — repo is fresh, low cost).
- [ ] **Rotate Obsidian Local REST API key** — open Obsidian → Settings → Community plugins → Local REST API → "Re-generate API key". Do this regardless of A/B.
- [ ] **If Option A**:
  ```bash
  pip install git-filter-repo
  git filter-repo --invert-paths --path .obsidian/plugins/obsidian-local-rest-api/
  ```
- [ ] **Replace CODEOWNERS placeholders**:
  ```bash
  sed -i 's/@OWNER/@<your-handle>/g; s/@TEAMMATE/@<teammate-handle>/g' .github/CODEOWNERS
  ```
- [ ] **Decide operator-mods** — commit per `_promote-candidates/OPERATOR-MODS-RECOMMENDATION-2026-05-13.md`, or discard with `git checkout -- <files>`.
- [ ] **Add workspace-state to `.gitignore`** — append `.obsidian/graph.json` if you don't want UI state tracked.
- [ ] **Create private repo**:
  ```bash
  gh repo create <name> --private --description "Personal second-brain"
  ```
- [ ] **Add remote + push**:
  ```bash
  git remote add origin git@github.com:<YOU>/<repo>.git
  git push -u origin main
  git push -u origin feat/brain-hardening
  ```
- [ ] **Branch protection** — see `OPERATOR-NEXT-STEPS.md` step 6 (gh api command) or set via GitHub UI: require PR, require CODEOWNERS review, require `brain-checks` + `path-guard` to pass.
- [ ] **Invite teammate**:
  ```bash
  gh api -X PUT "repos/<YOU>/<repo>/collaborators/<TEAMMATE>" -f permission=push
  ```
- [ ] **Smoke test path-guard** — open a test PR touching a protected path without `OPERATOR-APPROVED:` in the body; CI must fail. Close PR after.

## 4. Optional but recommended

- [ ] Install pre-push hook: `bash scripts/install-hooks.sh`
- [ ] Archive old inbox monthly: `python3 scripts/archive_old_inbox.py --apply --yes`
- [ ] Add `detect-secrets` or `trufflehog` to CI (next sprint)
- [ ] Schedule weekly refresh of `claude-context/CURRENT.md` from `docs/ops/phase-status.md`

## 5. Verification commands

Operator runs these to confirm green before push:

```bash
cd ~/Obsidian/Brain
git checkout feat/brain-hardening
bash scripts/sanity.sh                            # expect 8/8
python3 scripts/brain_audit.py                    # expect 0 errors
git log --oneline main..feat/brain-hardening      # confirm 5 commits
git status --short | wc -l                        # operator's mods + inbox count
git ls-files | grep -i 'obsidian-local-rest-api' || echo "OK — not tracked"
```

Expected output sketch:
- `sanity.sh` → `8/8 checks passed`
- `brain_audit.py` → `errors: 0, warnings: 0` (or 1-3 if wikilink-fix run is still pending; harmless)
- `git log` → exactly 5 SHAs
- `git ls-files | grep` → `OK — not tracked` (if it prints filenames, `.gitignore` did not catch them — STOP and re-check before push)

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

- **Undo all hardening**: `git checkout main && git branch -D feat/brain-hardening` (loses 5 commits — confirm not needed; consider tagging first: `git tag brain-hardening-snapshot feat/brain-hardening`).
- **Undo a single commit**: `git revert <sha>` — keeps history, recommended over reset.
- **Restore deleted artifacts**: `git checkout f824aa8 -- Untitled.canvas Untitled.base 2026-05-11.md` (they come back; delete again if not wanted).
- **Restore `obsidian-local-rest-api/` tracked files**: still on disk — `git add -f .obsidian/plugins/obsidian-local-rest-api/`. **NOT recommended** (contains secrets).
- **Post-push regret**: if a bad commit lands on remote `main`, do NOT force-push without explicit "OK kjør" — open a revert PR instead.

## 8. Sign-off

When every box in section 3 is ticked:

1. **OK kjør → push** (`git push -u origin main && git push -u origin feat/brain-hardening`)
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

Sist oppdatert: 2026-05-13 by Claude (Opus 4.7 1M)
