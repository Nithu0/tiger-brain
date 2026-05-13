---
tags: [meta, operator, runbook]
type: meta
created: 2026-05-13
---

# OPERATOR-NEXT-STEPS

Copy-pasteable runbook for å fullføre brain-hardening: GitHub repo, push, branch protection, teammate-invite.

Placeholders som MÅ byttes ut før kjøring:
- `<YOU>` — operatørens GitHub-handle (ukjent per 2026-05-13)
- `<TEAMMATE>` — teammates GitHub-handle
- `<repo>` — repo-navn (forslag: `nithu-brain`)

---

## 1. TL;DR

- Rotér Local REST API-nøkkelen FØR push (lekket i commit `f824aa8`).
- Bytt CODEOWNERS-placeholders, så `gh repo create --private`, så push.
- Sett branch protection via `gh api` (eller UI), inviter teammate med `push`-rolle.
- Smoke-test path-guard på en throwaway-branch.

---

## 2. Prereq sanity

```bash
cd ~/Obsidian/Brain
gh auth status                           # must be logged in
python3 scripts/brain_audit.py           # must pass
git status --short | wc -l               # what's uncommitted
git log --oneline -5                     # confirm hardening commits present
```

Hvis `gh auth status` feiler: `gh auth login` først.

---

## 3. KRITISK: API-key leak i git-historikken

`.obsidian/plugins/obsidian-local-rest-api/data.json` ble committet i `f824aa8`. Nøkkelen ligger fortsatt i historikken selv om `.gitignore` nå dekker den.

### Option A (anbefalt): rotér + purge historikk

```bash
# 1. Rotér nøkkelen i Obsidian:
#    Settings → Community plugins → Local REST API → "Re-generate API key"

# 2. Installer git-filter-repo:
pip install git-filter-repo

# 3. Purge fil fra HELE historikken (rewriter repoet — irreversibelt):
git filter-repo --invert-paths --path .obsidian/plugins/obsidian-local-rest-api/

# 4. Verifiser at filen er borte:
git log --all -- .obsidian/plugins/obsidian-local-rest-api/data.json
# (should print nothing)
```

OBS: `git filter-repo` skriver om SHA-er. Kjør FØR du legger til remote og pusher første gang. Hvis du allerede har pushet: må force-pushe og varsle alle som har klonet.

### Option B (raskere, mindre rent)

Aksepter at hvem som helst som kloner repoet ser den gamle nøkkelen. Rotér i Obsidian (samme steg 1 over). Den lekkede nøkkelen funker kun mot operatørens localhost REST API — ubrukelig uten LAN-tilgang til maskinen din. Lav reell risiko hvis repoet forblir privat.

Merk: `.gitignore` hindrer fremtidige commits uansett valg.

---

## 4. Bytt CODEOWNERS-placeholders

```bash
cd ~/Obsidian/Brain

# Bytt <YOU> til faktisk handle (uten @-tegn i variabelnavnet, men med @ i fila):
sed -i 's/@OWNER/@<YOU>/g' .github/CODEOWNERS
sed -i 's/@TEAMMATE/@<TEAMMATE>/g' .github/CODEOWNERS

# Sanity-sjekk:
grep -E '@OWNER|@TEAMMATE' .github/CODEOWNERS && echo "STILL HAS PLACEHOLDERS" || echo "all placeholders replaced"
```

Commit:
```bash
git add .github/CODEOWNERS
git commit -m "chore: fill CODEOWNERS handles"
```

---

## 5. Commit & first push

```bash
# Lag privat repo:
gh repo create <repo> --private --description "Personal second-brain (Obsidian + GitHub)"

# Legg til remote:
git remote add origin git@github.com:<YOU>/<repo>.git

# (Hvis du jobbet på feat/brain-hardening: merge til main først)
# git checkout main && git merge feat/brain-hardening

# Push main:
git push -u origin main
```

Verifiser:
```bash
gh repo view <YOU>/<repo> --web   # åpner i nettleser
```

---

## 6. Branch protection (via gh API)

Krever at minst én commit er pushet til `main` først.

```bash
gh api -X PUT "repos/<YOU>/<repo>/branches/main/protection" \
  -F required_pull_request_reviews.required_approving_review_count=1 \
  -F required_pull_request_reviews.require_code_owner_reviews=true \
  -F required_status_checks.strict=true \
  -F 'required_status_checks.contexts[]=brain-checks / audit' \
  -F 'required_status_checks.contexts[]=path-guard / path-guard' \
  -F enforce_admins=false \
  -F restrictions= \
  -F allow_force_pushes=false \
  -F allow_deletions=false
```

Verifiser:
```bash
gh api "repos/<YOU>/<repo>/branches/main/protection" | jq .
```

UI-fallback hvis API tryner: GitHub → Settings → Branches → Add rule → branch pattern `main` → huk av tilsvarende bokser.

OBS: status-check-navnene (`brain-checks / audit`, `path-guard / path-guard`) må matche eksakt det workflow-filene rapporterer. Hvis de ikke har kjørt enda, må du først pushe en PR som trigger dem — ellers godtar ikke GitHub konteksten.

---

## 7. Inviter teammate

```bash
gh api -X PUT "repos/<YOU>/<repo>/collaborators/<TEAMMATE>" -f permission=push
# permission=push = "Write" role (kan pushe branches + lage PR, kan ikke endre settings)
```

Verifiser:
```bash
gh api "repos/<YOU>/<repo>/collaborators" | jq '.[].login'
```

Teammate får invitasjon på e-post. Send dem også link til `TEAMMATE-ONBOARDING.md` i repoet.

---

## 8. Smoke test path-guard

Bekreft at path-guard faktisk blokkerer endringer på beskyttede paths.

```bash
git checkout -b test/path-guard
echo "test" >> _decisions/When-Trade-Bleeds-Multi-Day.md
git commit -am "test: should be blocked by path-guard"
git push -u origin test/path-guard
gh pr create --title "test path-guard" --body "no override — should fail"

# Vent på CI:
gh pr checks
# path-guard skal feile

# Cleanup:
gh pr close --delete-branch
git checkout main
git branch -D test/path-guard
```

Hvis path-guard IKKE feilet: workflow-fila er feil konfigurert. Sjekk `.github/workflows/path-guard.yml`.

---

## 9. Teammate-flow

Når teammate aksepterer invitasjon:
1. Pek dem til `TEAMMATE-ONBOARDING.md` i repoet (åpnes direkte på GitHub).
2. De kjører `scripts/setup-from-scratch.sh` for å sette opp lokal kopi + Obsidian-pekere.
3. Første test-PR fra dem skal trigge CODEOWNERS-review-request på deg.

---

## 10. Vedlikehold (recurring)

| Hvor ofte | Hva | Kommando |
|---|---|---|
| Ukentlig | Oppdater `01-CURRENT-FOCUS.md` | manuell |
| Ukentlig | Oppdater `claude-context/CURRENT.md` | manuell |
| Månedlig | Arkivér gammel inbox | `python3 scripts/archive_old_inbox.py --apply` |
| Kvartalsvis | Refresh system-audit | `python3 scripts/brain_audit.py > SYSTEM-AUDIT.md` + manuell oppdatering |
| Etter big restructure | Re-kjør hele audit | `python3 scripts/brain_audit.py` |

Sett gjerne cron-reminder for månedlig inbox-arkivering.

---

## 11. Rollback per step

| Step | Rollback |
|---|---|
| 3A (filter-repo) | Ingen rollback hvis pushet. Lokalt: `git reflog` + reset til pre-filter SHA |
| 3B (rotér nøkkel) | Re-generer på nytt i Obsidian |
| 4 (CODEOWNERS) | `git checkout HEAD~1 -- .github/CODEOWNERS` |
| 5 (repo create) | `gh repo delete <YOU>/<repo> --yes` (irreversibelt; sletter alt) |
| 5 (push) | `git push origin --delete main` (men da blir repo tomt) |
| 6 (protection) | `gh api -X DELETE "repos/<YOU>/<repo>/branches/main/protection"` |
| 7 (collaborator) | `gh api -X DELETE "repos/<YOU>/<repo>/collaborators/<TEAMMATE>"` |
| 8 (smoke test) | Branch slettes som del av test-flow |

---

## Sjekkliste før du sier deg ferdig

- [ ] `gh auth status` OK
- [ ] `brain_audit.py` passerer
- [ ] API-nøkkel rotert i Obsidian (Option A eller B valgt)
- [ ] CODEOWNERS har ekte handles, ingen `@OWNER`/`@TEAMMATE` igjen
- [ ] Repo opprettet privat
- [ ] `main` pushet
- [ ] Branch protection aktiv (verifisert med `gh api`)
- [ ] Teammate invitert med `push`-rolle
- [ ] Path-guard smoke test feilet som forventet
- [ ] `TEAMMATE-ONBOARDING.md` sendt til teammate

---

Sist oppdatert: 2026-05-13
