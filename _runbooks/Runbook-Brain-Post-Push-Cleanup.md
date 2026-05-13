---
tags: [runbook, brain, post-push]
type: runbook
created: 2026-05-13
---

# Runbook — Brain Post-Push Cleanup

## When to run

Anytime after first push to `github.com/Nithu0/tiger-brain` and branch protection is on. Recommended within 24h of first push so the repo is hardened before any teammate touches it.

## Step 1: Enable branch protection (UI, ~60 seconds)

- Open https://github.com/Nithu0/tiger-brain/settings/branches
- "Add branch ruleset" → name `main-protection` → target `main`
- Enable:
  - Require PR (1 approval, dismiss stale approvals on new push)
  - Require linear history
  - Require status checks: `brain-checks`, `path-guard`, `secrets-scan`
  - Block force pushes
  - Block deletions
  - Require conversation resolution
- Save

## Step 2: Rotate the Obsidian REST API key

The key was exposed in the pre-push history snapshot — rotate before doing anything else.

- Open Obsidian → Settings → Community plugins → Local REST API → "Re-generate API key"
- Verify locally:

```bash
cat .obsidian/plugins/obsidian-local-rest-api/data.json | head -3
```

- Confirm the file is gitignored:

```bash
git check-ignore -v .obsidian/plugins/obsidian-local-rest-api/data.json
```

## Step 3: Install pre-push hook locally

```bash
cd ~/Obsidian/Brain
bash scripts/install-hooks.sh
```

Every push will now run `sanity.sh` before the network call, catching path/secret regressions before CI does.

## Step 4: Smoke test the gates (run ONCE)

```bash
bash scripts/smoke-test-pr.sh
```

Expected: 4 tests, all pass — `allowed-PASS`, `blocked-no-override`, `override-PASS`, `secret-detected`. If any fail, the CI gates are not actually blocking; stop and investigate before relying on protection.

## Step 5: Delete merged feat branch

After PR is opened and merged, OR if `main` and `feat/brain-hardening` point to the same SHA:

```bash
# On GitHub — delete remote feat branch:
gh api -X DELETE "repos/Nithu0/tiger-brain/git/refs/heads/feat/brain-hardening"
# Or via UI: Branches → delete

# Locally:
git checkout main
git branch -d feat/brain-hardening
git fetch -p
```

## Step 6: Invite teammate (when you have their handle)

```bash
gh api -X PUT "repos/Nithu0/tiger-brain/collaborators/<handle>" -f permission=push
# Or via UI: https://github.com/Nithu0/tiger-brain/settings/access
```

## Step 7: Update CODEOWNERS with teammate handle

```bash
sed -i 's/@TEAMMATE/@<handle>/g' .github/CODEOWNERS
git checkout -b chore/codeowners-teammate
git commit -am "chore(codeowners): add teammate"
git push -u origin chore/codeowners-teammate
gh pr create --fill
# merge after one approval (yourself counts if branch protection allows)
```

## Verification (after all done)

```bash
gh repo view Nithu0/tiger-brain --json defaultBranch,visibility,viewerPermission
gh api "repos/Nithu0/tiger-brain/branches/main/protection" --jq '.'
```

Spot-check: `defaultBranch` is `main`, protection block includes `required_status_checks`, `required_pull_request_reviews`, and `allow_force_pushes.enabled = false`.

## Related

- [[Runbook-Push-Cycle]]
- [[Runbook-Obsidian-Workspace-Drift]]
- [[OPERATOR-NEXT-STEPS]]
- [[SECURITY-INCIDENT-API-KEY]]

Sist oppdatert: 2026-05-13
