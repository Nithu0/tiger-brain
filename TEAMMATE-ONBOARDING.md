---
title: TEAMMATE-ONBOARDING
type: meta
tags: [meta, onboarding, teammate]
created: 2026-05-11
---

# TEAMMATE-ONBOARDING

Welcome! Dette er Nithus delte brain — en Obsidian-vault som dobler som git-repo. Du er invitert inn for å samarbeide, primært på Nexus (XAUUSD-trading firm). Denne fila er din day-1 guide.

## Lesetilgang

Du kan lese **alt** i vaulten. Bla deg gjerne gjennom for kontekst — spesielt:

- [[00-DASHBOARD]] — current state across all projects
- [[01-CURRENT-FOCUS]] — what operator is working on this week
- [[BRAIN-RULES]] — the rule of the road
- `01-nexus/` — der du kommer til å bo

## Hva du kan redigere (uten å spørre først)

- `01-nexus/**` — Nexus runbooks, notes, drafts, journal entries
- `00-claude-inbox/nexus/**` — Claude-genererte drafts til nexus-arbeid
- `_promote-candidates/**` — notes som er kandidater til promotion (legg til, ikke slett andres)

## Hva du IKKE skal redigere uten operator-OK

| Path | Hvorfor |
|---|---|
| `_decisions/` | ADRs — kun operator ratifiserer |
| `_maps/` | MOCs — strukturell, må holdes konsistent |
| `_runbooks/` | Cross-project runbooks — operator-eid |
| `claude-context/` | Claude session context — operator-eid |
| `.github/` | CI / CODEOWNERS / templates |
| `scripts/` | Tooling — sjekkes av CI |
| `90-archive/` | Frosset historikk |
| Root-filer (`README.md`, `00-DASHBOARD.md`, `01-CURRENT-FOCUS.md`, `BRAIN-RULES.md`, `SYSTEM-AUDIT.md`) | Operator-eide rule-filer |

Hvis du _må_ endre en av disse, åpne PR med `OPERATOR-APPROVED: <reason>` i beskrivelsen — operator legger den til etter approval.

## Day-1 commands

```bash
git clone git@github.com:Nithu0/tiger-brain.git ~/Obsidian/Brain
cd ~/Obsidian/Brain
bash firm-launcher/install.sh    # installs firm + hooks + clones ai-assistent
source ~/.bashrc
firm                              # launches 8-tab Claude session
```

If you only want the brain (no firm launcher), use `bash scripts/setup-from-scratch.sh --mode easy` instead.

Setup-skriptet kloner (hvis ikke allerede klonet), installerer pre-push hook, og kjører `brain_audit.py` for å verifisere lokal state. Hvis auditen faller — ping operator før du begynner å redigere.

## What's automated for you

| Automation | What it does | Where it runs |
|---|---|---|
| firm command | one-command 8-tab Claude session across operator's projects | Lokalt (installeres av firm-launcher) |
| Firm-tab brain check | Kjører `brain_audit.py` ved oppstart av firm-tabs | Lokalt (Claude Code session start) |
| Pre-push hook | Kjører `sanity.sh` før push — fanger feil før de når CI | Lokalt (installeres av setup-skriptet) |
| CI on PRs | `brain-checks` + `path-guard` på alle PR-er | GitHub Actions |
| Monthly archive | Flytter aldrende notes til `90-archive/` | Scheduled workflow |

## Hvis du vil ha samme oppsett som operator

```bash
bash scripts/setup-from-scratch.sh --repo git@github.com:Nithu0/tiger-brain.git --mode easy
```

Note: `--mode advanced` adds optional extras like Claude Code install pointer. Du trenger ikke kjøre advanced for å bidra — easy mode dekker hooks + audit + clone.

## Branch + PR flow

Kort versjon (full versjon i [[CONTRIBUTING]]):

1. `git checkout -b feat/<slug>`
2. Gjør endringer i tillatte mapper.
3. `python scripts/brain_audit.py && python scripts/path_guard.py --base main --head HEAD`
4. Commit med type-prefix (`note:`, `fix:`, `chore:`, `runbook:`).
5. Push branch, open PR mot `main`, fyll templaten.
6. Vent på CODEOWNERS-approval. **Ikke merge selv.**

## Your first PR — end-to-end walkthrough

1. Create a branch:
   ```bash
   git checkout -b feat/<your-slug>
   ```
2. Make your change (only in allowed paths — see "What you can edit" above)
3. Run local checks:
   ```bash
   bash scripts/sanity.sh
   # or individually:
   python3 scripts/brain_audit.py
   python3 scripts/path_guard.py --base origin/main --head HEAD
   ```
4. Commit (use type-prefix: `note:`, `fix:`, `chore:`, `runbook:`, `decision:`):
   ```bash
   git add <files>
   git commit -m "note: <short summary>"
   ```
5. Push your branch and open a PR:
   ```bash
   git push -u origin feat/<your-slug>
   gh pr create --title "note: <summary>" --body "$(cat <<'EOF'
   ## Summary
   <what + why>

   ## Touched folders
   - <path1>
   - <path2>

   ## Checklist
   - [x] Edited only allowed folders
   - [x] Ran scripts/sanity.sh locally — green
   - [x] No secrets in diff
   - [x] Used [[wikilinks]]
   - [x] Frontmatter present
   EOF
   )"
   ```
6. Wait for CI: both `brain-checks` and `path-guard` must pass.
7. Wait for CODEOWNERS approval (operator).
8. Once approved + merged: delete your branch:
   ```bash
   git checkout main && git pull && git branch -d feat/<your-slug>
   ```

## If CI fails

- `brain-checks` failure → run `python3 scripts/brain_audit.py` locally and fix what it reports.
- `path-guard` failure → you edited a protected folder. Either:
  - (a) move your change to an allowed folder, OR
  - (b) ask operator to approve. If they say yes, add `OPERATOR-APPROVED: <reason>` to your PR body and the workflow will re-evaluate.
- YAML/Python syntax → `bash scripts/sanity.sh` will catch these locally before push.

## Common pitfalls

- **Ikke restructure mapper.** Hvis du tror noe er feilplassert, åpne issue i stedet.
- **Ikke rename MOCs** (`_maps/*.md`). De er hardlinket fra mange notes.
- **Ikke auto-disable gates eller hooks.** Hvis noe ser broken ut, rapporter til operator — operator decides handling. (Dette er en hard regel hos Nithu: health-checks REPORT, operator DECIDES.)
- **Ikke commit `.env` eller secrets.** Se [[CONTRIBUTING]] for hva du gjør hvis det skjer.
- **Ikke push direkte til `main`.** Alt går gjennom PR.
- **DON'T disable the pre-push hook unless you really know why** (`git push --no-verify` is the bypass). Hooken fanger feil før de når CI — det er din venn, ikke en hindring.

## Hvem pinger du?

Operator (Nithu) — Discord eller email. For akutte issues (secrets-lekkasje, ødelagt main): Discord først.

## Glossary

- **Nexus** — operator's XAUUSD trading firm; primary domain you'll work in.
- **MOC** — Map of Content; index-note som peker til relaterte notes (`_maps/`).
- **Foundation Gate** — ops-readiness check som må passere før Nexus kan ta risk; lever i Nexus-runbooks.
- **Karri** — reviewer-rolle for strategi/risk-changes på Nexus.
- **OK kjør** — operator's autonomous-execute trigger; når du ser dette i en Claude-tråd betyr det "execute now, no further confirmation needed".
- **ADR** — Architecture Decision Record; lever i `_decisions/`.
- **Promote-candidate** — note som er kandidat til å flyttes fra inbox/scratch til kuratert område.

Velkommen ombord. Spør hvis noe er uklart — bedre å spørre én gang for mye enn å redigere feil mappe.

---

Sist oppdatert: 2026-05-13 (firm-launcher install path)
