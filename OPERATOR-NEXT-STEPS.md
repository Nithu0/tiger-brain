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

## STEP 1: Create the GitHub repo (one of these, your choice)

```bash
# OPTION A — gh CLI:
bash scripts/install-gh-cli.sh             # ~30s, asks for sudo
gh auth login                              # opens browser
gh repo create tiger-brain --private --description "Personal second-brain (Obsidian + GitHub)"

# OPTION B — UI (fastest if you don't want to install gh):
# Open https://github.com/new
# Name: tiger-brain
# Visibility: Private
# Do NOT initialize with README/gitignore (repo already has them)
```

---

## STEP 2: Push + branch protection

```bash
bash scripts/push-and-protect.sh --mode easy     # or --mode full if gh installed
```

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
- [ ] Repo opprettet privat (STEP 1)
- [ ] `main` pushet + branch protection aktiv (STEP 2)
- [ ] API-nøkkel rotert i Obsidian (STEP 3)
- [ ] Teammate invitert med `push`-rolle (STEP 4)
- [ ] CODEOWNERS `@TEAMMATE` byttet til ekte handle (STEP 5)
- [ ] Path-guard smoke test feilet som forventet (STEP 6)
- [ ] `TEAMMATE-ONBOARDING.md` sendt til teammate

---

## Vedlikehold (recurring)

| Hvor ofte | Hva | Kommando |
|---|---|---|
| Ukentlig | Oppdater `01-CURRENT-FOCUS.md` | manuell |
| Ukentlig | Oppdater `claude-context/CURRENT.md` | manuell |
| Månedlig | Arkivér gammel inbox | `python3 scripts/archive_old_inbox.py --apply` |
| Kvartalsvis | Refresh system-audit | `python3 scripts/brain_audit.py > SYSTEM-AUDIT.md` + manuell oppdatering |
| Etter big restructure | Re-kjør hele audit | `python3 scripts/brain_audit.py` |

---

## Rollback per step

| Step | Rollback |
|---|---|
| 1 (repo create) | `gh repo delete Nithu0/tiger-brain --yes` (irreversibelt; sletter alt) |
| 2 (push) | `git push origin --delete main` (men da blir repo tomt) |
| 2 (protection) | `gh api -X DELETE "repos/Nithu0/tiger-brain/branches/main/protection"` |
| 3 (rotér nøkkel) | Re-generer på nytt i Obsidian |
| 4 (collaborator) | `gh api -X DELETE "repos/Nithu0/tiger-brain/collaborators/<TEAMMATE>"` |
| 5 (CODEOWNERS) | `git checkout HEAD~1 -- .github/CODEOWNERS` |
| 6 (smoke test) | Branch slettes som del av test-flow |

---

## DONE 2026-05-13

- **API-key leak purge**: `git filter-repo --invert-paths --path .obsidian/plugins/obsidian-local-rest-api/` kjørt; `git log --all -- .obsidian/plugins/obsidian-local-rest-api/data.json` returnerer tomt. (Var step 3 i forrige versjon, Option A.)
- **CODEOWNERS owner-handle**: `@OWNER` → `@Nithu0` byttet i `.github/CODEOWNERS`. `@TEAMMATE` venter fortsatt på teammates handle (se STEP 5).

---

Sist oppdatert: 2026-05-13
