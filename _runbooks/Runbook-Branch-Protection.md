---
tags: [runbook, github, security]
type: runbook
created: 2026-05-13
---

# Runbook: Branch Protection (tiger-brain)

## 1. Use case

Solo operator + 1 trusted collaborator with bypass (Karri) + optional future restricted collaborators. Goal: trusted Karri can push direct; everyone else PR-only with CODEOWNERS review. The ruleset must protect `main` from accidents (force-push, delete, broken CI) while keeping Karri's hotfix-velocity intact. Reuse this recipe for any future repo with the same collaboration model.

## 2. Ruleset name + scope

- **Name**: `main-protection`
- **Enforcement**: Active
- **Target branches**: `main`
- **Bypass list**: Add Karri's GH handle (operator: `@Karri-handle`)

## 3. Rules table — exact checkboxes

| Box | Setting | Why |
|---|---|---|
| ✅ | Restrict deletions | Prevents accidental `main` delete |
| ✅ | Require a pull request before merging | Forces review flow |
| ⤷ | Required approvals: **1** | Minimum gate |
| ⤷ | Dismiss stale approvals on new push | Approvals reset if rebased |
| ⤷ | Require review from Code Owners | CODEOWNERS file gets enforced |
| ✅ | Require status checks to pass | Forces CI green |
| ⤷ | Add: `audit` (brain-checks), `path-guard`, `gitleaks` | The 3 workflows we have |
| ⤷ | Require branches to be up to date before merging | No stale merge bases |
| ✅ | Block force pushes | No history rewrites |
| ✅ | Require linear history | No merge commits — cleaner |

**Skip** (with reasoning):
- Restrict creations — collaborators need to create branches
- Restrict updates — collaborators need to push their branches
- Require deployments — N/A
- Require signed commits — defer, adds friction
- Require code scanning — we already have secrets-scan via gitleaks
- Require code quality — defer
- Copilot review — operator decides per PR, usually not needed

## 4. Collaborator role matrix

| Role | GitHub permission | Notes |
|---|---|---|
| Owner (operator) | Admin | You |
| Trusted reviewer (Karri) | Maintain or Write + on bypass list | Can push direct |
| Default teammate | Write | Must PR through normal flow |
| Restricted collaborator | Triage or Read | Read-only or comment-only — pick when you have someone you don't fully trust |

## 5. One-time setup commands (gh CLI)

```bash
# Install gh first if missing:
bash scripts/install-gh-cli.sh
gh auth login

# Add Karri as collaborator (Write):
gh api -X PUT "repos/Nithu0/tiger-brain/collaborators/<karri-handle>" -f permission=push

# The ruleset itself: easier via UI than gh api (the JSON is verbose).
# See: https://github.com/Nithu0/tiger-brain/settings/branches
```

## 6. Bypass-list semantics

Bypass means Karri can ignore PR-required + status-check-required. But Karri SHOULD still follow the PR flow for risky changes. Bypass is for "I need to land a hotfix right now" — not "I push to main daily." If Karri starts pushing direct frequently, downgrade them off the bypass list and require PR like everyone else.

## 7. Adding future restricted collaborator

- Settings → Access → Add people → give them `Read` or `Triage`
- Ruleset rules already block them from main without PR
- CODEOWNERS forces operator review on every PR they open
- No additional ruleset changes needed — the existing ruleset covers this case

## 8. Verify protection works

```bash
bash scripts/smoke-test-pr.sh
```

The smoke test should: create a throwaway branch, attempt direct push to main (must fail), open a PR (must require approval + status checks), confirm CODEOWNERS review trigger.

## 9. Related

- [[OPERATOR-NEXT-STEPS]]
- [[TEAMMATE-ONBOARDING]]
- [[Runbook-Brain-Post-Push-Cleanup]]

---

Sist oppdatert: 2026-05-13
