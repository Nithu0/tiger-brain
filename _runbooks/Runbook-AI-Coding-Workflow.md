---
tags: [runbook, ai-coding, ralph, skills, claude-code, tdd]
date: 2026-10-04
owner: operatør
source: "Matt Pocock — Full Walkthrough: Workflow for AI Coding (youtube -QFHIoCo-Ko)"
related:
  - "[[git-worktree-workflow]]"
  - "[[Runbook-Multi-Agent-Dispatch]]"
---

# AI-coding-workflow (Pocock-flyten)

Fra idé til commits uten at agenten gjetter. Skills ligger i `~/.claude/skills/` (egne tilpasninger,
inspirert av github.com/mattpocock/skills, MIT). Ralph-scripts i `command-center/_bin/`.

## Flyten

1. `/grill-me` — agenten intervjuer deg, ett spørsmål om gangen, med anbefalt svar. Til alt er avgjort.
2. `/write-a-prd` — samme økt. Skriver `prd/<slug>.md`: problem, løsning, user stories,
   implementasjonsvalg (modulkart med dype moduler), testvalg, utenfor scope.
3. `/prd-to-issues` — vertikale snitt → `issues/NNN-<slug>.md` med `Type: AFK|HITL`, `Blocked by`.
4. `ralph-once.sh` — én iterasjon mens du ser på. Juster prompt/issues til den gjør riktig ting.
5. `ralph-afk.sh` — løkka går AFK i egen worktree til `NO MORE TASKS` eller taket (10).
6. QA selv: kjør appen, prøv det. Funn → nye issue-filer (AFK der det går), kjør løkka igjen.
7. Review i FERSK kontekst (ny økt / `/code-review`) mot branchen. Push via vanlig OK kjør-gate.
8. Slett `prd/<slug>.md` når alle issues er i `issues/done/`.

`/tdd` brukes inne i hver iterasjon. `/improve-codebase-architecture` ukentlig per aktivt repo
→ RFC som HITL-issue.

## Nøkkelideer (én linje hver)

- **Smart zone ~100k tokens**: over det blir modellen dummere; hold oppgaver små nok til å fullføres der. Se `ctx %` i statuslinja.
- **Clear > compact**: start fersk kontekst per oppgave; compact drar med seg støy.
- **Vertikale snitt**: hvert issue går gjennom alle lag og kan verifiseres alene (tracer bullet først).
- **Dype moduler**: lite grensesnitt, mye oppførsel bak. Lettere å teste, lettere for agenten å navigere.
- **Push standarder til reviewer, pull for implementer**: reviewer får kodestandardene servert; implementer henter selv (skills/docs) ved behov.
- **Feedback-loops er alt**: tester + typecheck er det som lar agenten jobbe AFK.
- **Slett PRD-er etter bruk**: unngår doc rot — gamle planer lyver om koden.
- **AFK vs HITL**: alt som rører penger, prod, migrasjoner, push eller hemmeligheter er HITL.

## Kommandoer

```bash
B=~/code/command-center/_bin

# planlegging (i claude-økt i prosjektet)
/grill-me        # så:
/write-a-prd     # → prd/<slug>.md
/prd-to-issues   # → issues/NNN-*.md

# se på én iterasjon (interaktiv, acceptEdits)
$B/ralph-once.sh --interactive --worktree <slug> ~/code/<repo>
# én headless iterasjon (claude -p)
$B/ralph-once.sh --worktree <slug> ~/code/<repo>
# tørrkjøring: vis workdir, issues, eksakt kommando
$B/ralph-once.sh --dry-run ~/code/<repo>

# AFK-løkke, egen worktree + branch ralph/<slug>, maks 10
$B/ralph-afk.sh --worktree <slug> ~/code/<repo>
$B/ralph-afk.sh --worktree <slug> --max 20 --issues backlog ~/code/<repo>

# etterpå
tail ~/.firm/ralph-logs/<repo>-<ts>/run.log
git -C ~/code/<repo> log --oneline main..ralph/<slug>
cd ~/code/<repo>/.worktrees/ralph/<slug> && claude   # fersk review
~/code/command-center/_bin/firm-worktree-cleanup.sh   # tørrkjøring; --force rydder
```

## Sikkerhet (bindende)

- Scriptene pusher ALDRI. `git push`/`git remote`/`reset --hard`/`rm -rf` er i `--disallowedTools`.
- Default: `--permission-mode acceptEdits -p` + smal `--allowedTools` (git add/commit/log/diff,
  mv/mkdir, test/typecheck-runnere). Annet nektes i stedet for å kjøre.
- `--skip-permissions` (`--dangerously-skip-permissions`) nektes utenfor container
  (`/.dockerenv` / `/run/.containerenv`). Ingen env-overstyring. Docker i WSL er ikke på → i praksis av.
- Løkka stopper på: `NO MORE TASKS`, `--max`, claude-feil, eller to iterasjoner uten ny commit.
- Kjør AFK alltid med `--worktree` (advarsel uten). Issues leses fra hoved-checkout (`<repo>/issues`).
- Pengeprosjekter (nexus): strategi/risk-endringer går fortsatt via `docs/strategy/proposals/`.

## Issue-format (det løkka leser)

```
# 003: <tittel>
Type: AFK
Status: open
Priority: bug | infra | tracer | polish | refactor
PRD: prd/<slug>.md
## What to build / ## Acceptance criteria / ## Blocked by / ## User stories
```

Prioritet i løkka: kritiske bugs > dev-infra > tracer bullets > polish/quick wins > refaktor.
Ferdig = `Status: done` + flyttet til `issues/done/`. Blokkert = `## Blocked`-notat + `Type: HITL`.

## Sandcastle (ikke installert)

`@ai-hero/sandcastle` (github.com/mattpocock/sandcastle, MIT): TS-lib, `sandcastle.run()` kjører
agenter i sandkasse (Docker/Podman/Vercel) med worktree per issue; maler for planner →
implementer → reviewer → merger.

Vurdering: passer ikke nå. Docker WSL-integrasjon er ikke på (ADR-002), og uten container er
"no-sandbox"-provideren bare ralph-afk med flere agenter og full tilgang — det vi nettopp har
forbudt. Ralph-scriptene dekker én-løkke-behovet. Revurder når (a) Docker/Podman er på i WSL og
(b) backloggen har mange uavhengige AFK-issues. Da: prøv `parallel-planner-with-review`-malen
mot et ikke-penge-repo først, maks 3 parallelle (RAM-taket ~8 paner gjelder også her).
