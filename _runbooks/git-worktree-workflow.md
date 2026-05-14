---
tags: [runbook, git, worktree, firm-launcher, codex, claude-code, parallell]
date: 2026-05-14
owner: operatør
related:
  - "[[2026-05-14-16-pane-codex-parallell]]"
  - "[[reference_firm_launcher]]"
  - "[[firm-launcher]]"
---

# Git worktree workflow — firm-launcher (16-pane Claude + Codex)

Daglig bruks-runbook for git worktrees som lar Claude- og Codex-paner jobbe parallelt i samme repo uten å trampe på hverandre.

## Hva worktrees er

En git worktree er en **ekstra arbeidskopi** av samme repo, koblet til en annen branch. Alle worktrees deler `.git/`-objektdatabasen — billig på disk (én kopi av hver fil per worktree, men én delt objektstore). Lar deg ha `main` checked-out i `<repo>/` og samtidig `codex/dashboard-mvp` checked-out i `<repo>/.worktrees/codex/dashboard-mvp/` uten å bytte branch.

**Hvorfor**: 16 agenter (8 Claude + 8 Codex) i parallell vil før eller siden krasje på samme fil hvis de jobber på samme branch. Worktree-konvensjon gjør isolasjonen fysisk, ikke disiplin-basert.

## Konvensjon (følg den)

- **Path**: `<repo>/.worktrees/<model>/<slug>/`
- **Branch**: `<model>/<slug>`
- **Model**: `claude` eller `codex` (kun de to)
- **Slug**: kort task-id, `a-z0-9-`, eks. `fix-orb-gate`, `dashboard-mvp`, `latest`

Eksempel:

```
~/code/ai-assistent/.worktrees/claude/fix-orb-gate/   # branch claude/fix-orb-gate
~/code/ai-assistent/.worktrees/codex/dashboard-mvp/   # branch codex/dashboard-mvp
```

## Daglig bruk

### Start ny Claude-worktree

```bash
~/code/_bin/firm-worktree-spawn.sh claude ~/code/ai-assistent fix-orb-gate
cd ~/code/ai-assistent/.worktrees/claude/fix-orb-gate
claude --dangerously-skip-permissions
```

Scriptet:
- Validerer model + slug
- Lager branch `claude/fix-orb-gate` fra current HEAD (typisk main) hvis ikke finnes
- Lager worktree under `.worktrees/claude/fix-orb-gate/`
- Idempotent — trygt å kjøre flere ganger

### Start ny Codex-worktree

```bash
~/code/_bin/firm-worktree-spawn.sh codex ~/code/ai-assistent dashboard-mvp
cd ~/code/ai-assistent/.worktrees/codex/dashboard-mvp
codex
```

### Start hele firm-launcher i codex-modus

```bash
# Alle 8 paner peker til .worktrees/codex/latest/ i hver respektive repo
~/code/_bin/firm-wt-split.sh --codex
```

Forutsetning: worktrees må eksistere. Hvis ikke advarer scriptet og avbryter. Lag dem først:

```bash
for repo in ai-assistent Master-oppgave AS "Søking fulltid" Personlig; do
  ~/code/_bin/firm-worktree-spawn.sh codex "/home/nithu/code/$repo" latest
done
# pluss workspace selv:
~/code/_bin/firm-worktree-spawn.sh codex /home/nithu/code latest   # (krever at /home/nithu/code er git-repo)
```

For en annen slug enn `latest`:

```bash
~/code/_bin/firm-wt-split.sh --codex --slug exp-2026-05-14
```

### Liste alle worktrees

```bash
~/code/_bin/firm-worktree-list.sh
```

Viser tabell: repo, model, slug, branch, last-commit-age. Tar med worktrees fra ai-assistent, Master-oppgave, battery-electrolyte-predictor, research-os, Brain.

## Synking

### Hente endringer fra main inn i din worktree (rebase)

```bash
cd ~/code/ai-assistent/.worktrees/claude/fix-orb-gate
git fetch origin main
git rebase origin/main
# løs konflikter hvis noen, deretter:
git rebase --continue
```

### Pushe worktree-branch til remote (når klar for PR)

```bash
cd ~/code/ai-assistent/.worktrees/claude/fix-orb-gate
git push -u origin claude/fix-orb-gate
gh pr create --base main --head claude/fix-orb-gate
```

**NB**: PR-godkjenning trenger fortsatt "OK kjør"-gate per global memory. Push aldri uten operatør-ok.

## Konflikt-håndtering

### Forebygging: rolle-eier-kart

Per [[2026-05-14-16-pane-codex-parallell]] Lag 1: skriv ned i prosjektets `CLAUDE.md` hvilken rolle som eier hvilke fil-domener.

Eksempel for nexus:

```
ai-1 (claude) + cx-ai-1 (codex): strategy/* + tests/strategy/*
ai-2 (claude) + cx-ai-2 (codex): infra/*    + scripts/*
```

Cross-model samme rolle (claude ai-1 + codex cx-ai-1): koordinerer via inbox-er i `~/Obsidian/Brain/00-firm-bus/inbox/`.

### Når konflikt skjer

1. PR som lander først vinner.
2. Den andre rebase'r mot oppdatert main.
3. Hvis konflikten er kompleks: meld i `00-firm-bus/feed.md` og koordiner med peer-pane via inbox.

## Cleanup-rutine

### Tørrkjøring — vis kandidater

```bash
~/code/_bin/firm-worktree-cleanup.sh
~/code/_bin/firm-worktree-cleanup.sh --older-than-days 7
```

Default: viser alle firm-worktrees med alder + om de er clean/dirty. Sletter ingenting.

### Faktisk sletting

```bash
~/code/_bin/firm-worktree-cleanup.sh --force
~/code/_bin/firm-worktree-cleanup.sh --force --older-than-days 14
```

- Sletter worktree + lokal branch.
- Hopper over worktrees med uncommitted endringer (sikkerhetsnett).
- For å overstyre dirty-skipping: `--force-dirty` (bruk forsiktig).

### Anbefalt rytme

- **Daglig**: tørrkjør `firm-worktree-cleanup.sh --older-than-days 3` for å se hva som henger igjen.
- **Ukentlig**: `--force --older-than-days 14` for å rydde gamle merged branches.
- **Etter PR-merge**: manuell `git -C <repo> worktree remove .worktrees/<model>/<slug>` + `git branch -d <model>/<slug>`.

## Eksempler — full lifecycle

### Eksempel 1: Claude pilot-task

```bash
# 1. Spawn worktree
~/code/_bin/firm-worktree-spawn.sh claude ~/code/ai-assistent fix-foundation-gate

# 2. Jobb (i pane eller annen terminal)
cd ~/code/ai-assistent/.worktrees/claude/fix-foundation-gate
claude --dangerously-skip-permissions
# ... edit, test, commit ...

# 3. Push + PR (etter "OK kjør")
git push -u origin claude/fix-foundation-gate
gh pr create --base main --head claude/fix-foundation-gate

# 4. Etter merge, rydd opp
~/code/_bin/firm-worktree-cleanup.sh --force --older-than-days 0
```

### Eksempel 2: Codex parallell A/B

```bash
# Claude jobber på refactor
~/code/_bin/firm-worktree-spawn.sh claude ~/code/ai-assistent refactor-regime

# Codex jobber på samme problem, annen tilnærming
~/code/_bin/firm-worktree-spawn.sh codex ~/code/ai-assistent refactor-regime-alt

# Begge åpne separate paner / sesjoner, sammenlign resultater når begge er ferdige.
# Velg vinner, slett taperen.
```

## Felle-fri sjekkliste

- [ ] Verifiser at du står i riktig worktree før edit: `pwd` og `git branch --show-current`.
- [ ] Aldri push direkte til main fra worktree — alltid via PR.
- [ ] Sjekk `firm-worktree-list.sh` før du starter ny pane så du ikke duplikerer.
- [ ] Rydd merged worktrees ukentlig.
- [ ] Hvis `git worktree remove` feiler: sjekk om noen kjører i den (lsof), eller bruk `--force`.

## Relatert

- Decision: [[2026-05-14-16-pane-codex-parallell]] — arkitektur + alternativ-vurdering
- Reference: [[reference_firm_launcher]] — 8-pane setup som dette utvider
- Runbook: [[firm-launcher]] — daglig firm-launcher-bruk
