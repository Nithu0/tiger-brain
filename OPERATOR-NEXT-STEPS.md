---
tags: [meta, operator, runbook]
type: meta
created: 2026-05-13
---

# OPERATOR-NEXT-STEPS

Tight remaining-only runbook for å fullføre brain-hardening.

Placeholders som fortsatt må byttes ut:
- `<TEAMMATE>` — teammates GitHub-handle (operatørens handle = `Nithu0`, allerede inn i CODEOWNERS)

---

## What's now automated (no manual ritual)

- Brain check runs on every firm tab boot (see `scripts/brain-session-start.sh`)
- Pre-push hook installed locally
- CI runs on every PR (brain-checks, path-guard, gitleaks)
- Monthly inbox archive opens an auto-PR
- Setup-from-scratch installs everything for collaborators in one command

---

## STEP 1: Branch protection (UI)

5 rules to check; Karri on bypass list; rest of collaborators forced through PR + CODEOWNERS.

Full recipe: `_runbooks/Runbook-Branch-Protection.md`.

---

## STEP 2: Pre-push hook — DONE

Operator ran `bash scripts/install-hooks.sh` (confirmed in terminal output 2026-05-13).

---

## STEP 3: Rotate the Obsidian REST API key

```text
Open Obsidian → Settings → Community plugins → Local REST API → "Re-generate API key"
```

(Old key was purged from history but existed on disk for some time.)

---

## STEP 4: Invite teammate (when you have their handle)

```bash
gh api -X PUT "repos/Nithu0/tiger-brain/collaborators/<TEAMMATE>" -f permission=push
# Or via UI: Settings → Collaborators → Add people
```

---

## STEP 5: Update CODEOWNERS with teammate handle

```bash
sed -i 's/@TEAMMATE/@<teammate-handle>/g' .github/CODEOWNERS
git add .github/CODEOWNERS
git commit -m "chore(codeowners): add teammate @<teammate-handle>"
git push
```

---

## STEP 6: Smoke test the gates

```bash
bash scripts/smoke-test-pr.sh                # creates+closes test PRs
```

---

## Sjekkliste før du sier deg ferdig

- [x] API-key purge fra git-historikk (filter-repo kjørt + verifisert)
- [x] CODEOWNERS `@OWNER` → `@Nithu0`
- [x] Pre-push hook installert lokalt (`install-hooks.sh`)
- [ ] Branch protection aktiv i UI (STEP 1, recipe i `_runbooks/Runbook-Branch-Protection.md`)
- [ ] API-nøkkel rotert i Obsidian (STEP 3)
- [ ] Teammate invitert med `push`-rolle (STEP 4)
- [ ] CODEOWNERS `@TEAMMATE` byttet til ekte handle (STEP 5)
- [ ] Path-guard smoke test feilet som forventet (STEP 6)
- [ ] `TEAMMATE-ONBOARDING.md` sendt til teammate

---

## Rollback per step

| Step | Rollback |
|---|---|
| 1 (protection) | `gh api -X DELETE "repos/Nithu0/tiger-brain/branches/main/protection"` |
| 2 (pre-push hook) | `rm .git/hooks/pre-push` |
| 3 (rotér nøkkel) | Re-generer på nytt i Obsidian |
| 4 (collaborator) | `gh api -X DELETE "repos/Nithu0/tiger-brain/collaborators/<TEAMMATE>"` |
| 5 (CODEOWNERS) | `git checkout HEAD~1 -- .github/CODEOWNERS` |
| 6 (smoke test) | Branch slettes som del av test-flow |

---

## DONE 2026-05-13

- **API-key leak purge**: `git filter-repo --invert-paths --path .obsidian/plugins/obsidian-local-rest-api/` kjørt; `git log --all -- .obsidian/plugins/obsidian-local-rest-api/data.json` returnerer tomt.
- **CODEOWNERS owner-handle**: `@OWNER` → `@Nithu0` byttet i `.github/CODEOWNERS`. `@TEAMMATE` venter fortsatt på teammates handle (se STEP 5).
- **Pre-push hook**: `bash scripts/install-hooks.sh` kjørt av operatør.
- **Branch protection recipe**: dokumentert i `_runbooks/Runbook-Branch-Protection.md`.
- **Firm-tab brain check**: automatisert via `scripts/brain-session-start.sh`.
- **Monthly inbox archive**: schedulert via `.github/workflows/monthly-inbox-archive.yml`.
- **Setup-from-scratch**: installerer pre-push hook by default for collaborators.

---

Sist oppdatert: 2026-05-13
