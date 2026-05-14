---
tags: [meta, operator, runbook]
type: meta
created: 2026-05-13
---

# OPERATOR-NEXT-STEPS

Tight remaining-only runbook for operatør. Toppen viser dagens leveranser; historikken under er bevart.

---

## 2026-05-14 — 6-prosjekt + firm-launcher v2

### Hva ble gjort i dag

- **Utvidet fra 3 til 6 prosjekter**: `nexus`, `master-oppgave`, `AS`, `soking-fulltid`, `personlig`, `workspace`.
- **Nye brain-mapper**: `06-AS/`, `07-personlig/` (egne agenter eier sub-filer).
- **Career utvidet**: aktiv jobb-søking flyttet til egen prosjekt-tråd. MOC `04-career/Active-Job-Search-MOC` + `Job-Scrape-Strategy` + `Interview-Prep-Workflow` (career-agent eier).
- **firm-launcher v2**: 8 paner med ny distribusjon — `code-1`, `code-2` (workspace), `ai-1`, `ai-2` (nexus), `thesis-1` (master), `as-1` (AS), `soking-1` (søking), `personal-1` (personlig). Erstatter v1's battery-1/scratch-paner.
- **Runbook for ny layout**: [[_runbooks/firm-8-pane-2026-05-14]].
- **Dashboard + Current-focus oppdatert** til 6-prosjekt-modellen.
- **Vurdering 16-pane / Conductor** logget i `_decisions/2026-05-14-16-pane-codex-parallell.md` (egen agent eier).

### 3 neste-skritt for operatør

1. **Test ny `firm` med dry-run + verifiser**:
   ```bash
   firm --dry-run                           # inspiser wt.exe argv
   firm                                     # launch på ekte
   tail -20 ~/Obsidian/Brain/00-firm-bus/feed.md   # bekreft 8 online-linjer
   ls ~/Obsidian/Brain/00-firm-bus/inbox/   # bekreft 8 inbox-filer
   ```
   Forventet: 8 paner åpner, hver med riktig cwd og rolle-prompt. Hvis en pane lander i feil cwd, sjekk `roster.md` og `firm-wt-split.sh`.

2. **Les gjennom de nye prosjekt-CLAUDE.md-ene** før du dispatcher tunge oppgaver:
   - `~/code/AS/CLAUDE.md`
   - `~/code/personlig/CLAUDE.md`
   - `~/code/soking-fulltid/CLAUDE.md`
   Hver setter sine egne safety- og scope-regler. Klargjør at de ikke kolliderer med globale regler i `~/.claude/CLAUDE.md`.

3. **Vurder Conductor + 16-pane**: les `_decisions/2026-05-14-16-pane-codex-parallell.md` og bestem om vi går videre. Krever "OK kjør" — ikke aktiv enda.

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
- [ ] `firm` dry-run + launch verifisert med ny 6-prosjekt-layout (2026-05-14)

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

Sist oppdatert: 2026-05-14
