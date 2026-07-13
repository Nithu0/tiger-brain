---
tags: [meta, checklist, sharing]
type: meta
created: 2026-05-11
---

# Final Sharing Checklist

Pragmatisk sjekkliste før Brain-vaulten deles med teammate via privat GitHub repo. Les hele før du gjør noe.

## 1. Status snapshot

**Ferdig**: CI-filer (`.github/workflows/{brain-checks,path-guard}.yml`), scripts (`brain_audit.py`, `path_guard.py`, `setup-from-scratch.sh`), `claude-context/` (START-HERE, RULES, SYSTEM-MAP, CURRENT), prompts (audit, nexus-worker, handoff), handoffs scaffold, root-filer (DASHBOARD, CURRENT-FOCUS, BRAIN-RULES, SYSTEM-AUDIT, CONTRIBUTING, TEAMMATE-ONBOARDING).

**Ikke ferdig**: GitHub remote finnes ikke, branch protection ikke konfigurert, teammate ikke invitert, `@OWNER`/`@TEAMMATE` placeholders ikke erstattet, ~30 uncommitted modified files ligger på `main`.

## 2. What's READY to share now

- Vault-struktur dokumentert i `SYSTEM-AUDIT.md`
- Claude reading guide i `claude-context/`
- GitHub workflows + scripts i `.github/` og `scripts/`
- PR template + CODEOWNERS scaffold
- Onboarding-doc `TEAMMATE-ONBOARDING.md`
- Regelverk `BRAIN-RULES.md` + `CONTRIBUTING.md`

## 3. What you must still do manually in GitHub UI

Rekkefølgen betyr noe — ikke pushe før CODEOWNERS er fikset.

1. Lag privat GitHub repo (foreslått navn: `brain` eller `nithu-brain`).
2. `git remote add origin git@github.com:<YOU>/<REPO>.git`
3. `git push -u origin main` — **vent med dette til steg 4 og 5 er gjort**.
4. Erstatt `@OWNER` i `.github/CODEOWNERS` med din egen GitHub-handle. Erstatt `@TEAMMATE` med teammatens handle når du har den.
5. Commit endringene:
   ```bash
   git add .github/CODEOWNERS && git commit -m "chore(codeowners): set real handles"
   ```
6. Push til remote: `git push -u origin main`
7. GitHub UI → Settings → Branches → Add branch protection rule for `main`:
   - [x] Require a pull request before merging
   - [x] Require approvals (minimum 1)
   - [x] Require review from Code Owners
   - [x] Require status checks to pass before merging — velg `brain-checks` og `path-guard`
   - [x] Require branches to be up to date before merging
   - [ ] Allow force pushes — la stå AV
   - [ ] Allow deletions — la stå AV
   - [x] Do not allow bypassing the above settings (også for admins — anbefalt)
8. Settings → Collaborators and teams → inviter teammate med `Write`-tilgang. CODEOWNERS gater fortsatt beskyttede paths.
9. Optional: Settings → Secrets and variables → Actions — ingen secrets trengs for disse workflowsene. La stå tom.
10. Verifiser: åpne en test-PR fra en branch som kun rører `01-nexus/` → skal passere path-guard. Åpne en som rører `_decisions/` uten override-marker → skal feile. Begge skal kjøre på PR.

## 4. Recommended collaborator permission

- **GitHub repo role**: `Write`.
  - Tillater PR-opprettelse og push til ikke-main branches.
  - Blokkeres fra direkte push til `main` av branch protection.
  - CODEOWNERS gater fortsatt beskyttede paths.
- **Ikke** `Admin` — ville la teammate disable branch protection.
- **Ikke** `Triage` — for smal, kan ikke pushe branches.

## 5. Direct collaborator vs fork vs separate repo

- **Anbefalt: direct collaborator** på samme private repo. Teammate jobber primært på Nexus, men har nytte av å se resten av brainet. Ingen fork-friksjon, én sannhetskilde, lettere CODEOWNERS-håndhevelse.
- **Fork**: bare hvis teammate er ekstern eller ikke fullt betrodd. Introduserer sync-overhead.
- **Separat repo for Nexus**: ikke anbefalt nå — splitter MOCs og bryter wikilinks. Vurder kun hvis teammate vokser ut over Nexus med selvstendig eierskap.
- **Hybrid (git submodule)**: ikke anbefalt for Obsidian-vault — submodules bryter wikilink-resolving i Obsidian.

## 6. Day-1 commands for the teammate

```bash
git clone git@github.com:<OWNER>/<REPO>.git Brain
cd Brain
python3 scripts/brain_audit.py
# Hvis grønn: åpne i Obsidian → File → Open folder as vault → velg Brain/
# Les i denne rekkefølgen:
#   1. TEAMMATE-ONBOARDING.md
#   2. BRAIN-RULES.md
#   3. claude-context/START-HERE.md
#   4. 00-DASHBOARD.md
```

## 7. What teammate is allowed to edit (without prior operator OK)

- `01-nexus/**`
- `00-claude-inbox/nexus/**`
- `_promote-candidates/` (push til PR — operator godkjenner promotion til repo docs)
- Egne `handoffs/<date>-<slug>.md` filer

## 8. What teammate should NEVER edit without asking

- `_decisions/`
- `_maps/`
- `_runbooks/`
- `claude-context/`
- `.github/` (workflows, CODEOWNERS, PR-template)
- `scripts/`
- `90-archive/`
- Root-regler: `BRAIN-RULES.md`, `CONTRIBUTING.md`, `SYSTEM-AUDIT.md`, `00-DASHBOARD.md`, `01-CURRENT-FOCUS.md`, `TEAMMATE-ONBOARDING.md`, `FINAL-SHARING-CHECKLIST.md`
- Andre prosjekt-mapper: `02-thesis/`, `03-business/`, `04-career/`, `05-learning/`

## 9. How teammate runs checks before pushing

```bash
python3 scripts/brain_audit.py
python3 scripts/path_guard.py --base origin/main --head HEAD
```

Hvis `path_guard` flagger beskyttede paths og du har operator-OK: legg til `OPERATOR-APPROVED: <reason>` i PR-description, og re-run workflow.

## 10. Safe sharing workflow (recommended)

- **Dag 1**: Operator fullfører manuell GH UI-setup (steg i seksjon 3), committer CODEOWNERS, pusher til main.
- **Dag 1**: Operator inviterer teammate.
- **Dag 1**: Teammate kloner, kjører audit, åpner vault, leser onboarding.
- **Dag 2+**: Teammate jobber på en branch, åpner PR. Begge workflows kjører. CODEOWNERS-review kreves. Operator approver og merger.
- **Periodisk** (operator): pull, kjør `brain_audit.py`, refresh `SYSTEM-AUDIT.md`.

## 11. Files operator should review before committing/pushing

- `.github/CODEOWNERS` — erstatt `@OWNER` og `@TEAMMATE` placeholders
- `TEAMMATE-ONBOARDING.md` — verifiser glossary, kontaktinfo, Discord/email
- `BRAIN-RULES.md` — signoff på regler
- `FINAL-SHARING-CHECKLIST.md` — denne fila, sanity-check
- De ~30 uncommitted modified filene — bestem hva som skal commits
- Bestem: keep / delete på følgende:
  - `Untitled.canvas`
  - `Untitled.base`
  - `2026-05-11.md` (tom fil)
  - `Brain/Brain/scalp-overlap-losses-2026-05-11.md` (duplikat — nested Brain/Brain-path er feil)

## 12. Health score

**Nåværende: 7/10** når manuelle steg over er gjort.

For å pushe til **9/10**:
- Automated inbox archival (cron som flytter eldre `00-claude-inbox/`-filer til `90-archive/`)
- Broken-link cleanup-pass (audit-script kan rapportere, men ikke fikse)
- Færre uncommitted-changes drift (oftere commits, mindre lokal divergens fra main)
- Coverage-rapport på MOCs (hvilke noter mangler backlinks)

10/10 krever sannsynligvis at vault har vært delt et par uker og workflow-en er bevist.

## 13. Sign-off

Når listen er grønn og branch protection er på — **OK kjør**.

---

Sist oppdatert: 2026-05-11
