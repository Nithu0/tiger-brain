---
tags: [decision, infra, firm-launcher, codex, claude-code, conductor, worktrees, parallell]
date: 2026-05-14
status: proposal
owner: operatør
reviewers: [karri]
supersedes: []
related:
  - "[[reference_firm_launcher]]"
  - "[[2026-05-13-firm-launcher-decision]]"
  - "[[reference_brain_structure]]"
---

# 16-pane Claude + Codex parallell — beslutnings-forslag

## TL;DR

- **Hovedanbefaling**: Dobble til 16 paner i **to separate Windows Terminal-vinduer** (`firm-claude`, `firm-codex`) — ikke 16 paner i ett vindu. Kjør hver agent i **egen git worktree** per prosjekt (`<repo>/.worktrees/claude/<slug>` og `<repo>/.worktrees/codex/<slug>`). Konflikt-forebygging via **path-lock-filer i `00-firm-bus/locks/`** og **rolle-eier per fil-domene**, ikke distribuert låsing.
- **Conductor (MIDI/gamepad)**: Teknisk mulig via usbipd-win, men **anbefales IKKE som MVP**. Krever WSL2-kernel-modul-tweaking, udev-rules i WSL, og betaler ikke for kompleksiteten når `wt.exe -w 0 focus-tab -t N` allerede løser pane-bytting. Spar Conductor til når det er en reell smerte (når 16 paner faktisk roterer raskere enn taster klarer).
- **MVP-rekkefølge**: (1) speil firm-launcher til `firm-wt-codex.sh` med codex-paner, (2) introduser worktree-konvensjon med ett pilotprosjekt (nexus), (3) utvid `00-firm-bus` med `codex-*` roller + locks-katalog. Estimat: 1 arbeidsdag for MVP, 2-3 dager for fullskala 16-pane med worktree-disiplin.
- **Største risiko**: Mental-load. 8 paner med Claude alene er allerede grenseland. 16 samtidige sesjoner uten en koordinerings-agent (konduktør) er sannsynligvis for mye. Vurder et "dispatcher-pane" (én Claude som styrer de andre 15).

## Kontekst

Operatør har akkurat (2026-05-13) fått 8-pane multi-Claude firm-launcher i drift — split-view i ett Windows Terminal-vindu, hver pane et eget rolle/prosjekt med inbox i `~/Obsidian/Brain/00-firm-bus/inbox/`. Det funker. Neste fase:

- **Doble bredden**: 8 Claude + 8 Codex = 16 paner. Samme 6 prosjekter (`workspace`, `nexus`, `master-oppgave`, `AS`, `soking-fulltid`, `personlig`).
- **Pane-fordeling (Claude-side, eksisterende)**: 2 code, 2 ai, 1 thesis, 1 as, 1 soking, 1 personal — verifisert i `00-firm-bus/inbox/` (`code-1`, `code-2`, `ai-1`, `ai-2`, `thesis-1`, `as-1`, `soking-1`, `personal-1`).
- **Codex-side**: speile samme fordeling, men jobbe i parallelle worktrees/branches.
- **Hovedutfordring**: Unngå at to agenter skriver oppå hverandre på samme fil eller branch.
- **Bonus**: [Conductor](https://github.com/amiable-dev/conductor) — MIDI/gamepad macro tool — kunne i prinsippet brukes til pane-bytting og makroer.

Strategiske drivere:

- Claude og Codex har forskjellige styrker. Claude er bedre på lang refaktorering og forklaring; Codex (GPT-5/Codex CLI) er ofte raskere på smale kode-tasks. Parallell bruk gir A/B-evaluering.
- Operatør jobber 6 prosjekter konkurrent (workspace, nexus, thesis, AS, søking, personlig). 16 paner = 1.33 paner per modell per prosjekt i snitt — fortsatt sparsom dekning.

## Conductor-research

### Hva Conductor er

Multi-protocol input-automation skrevet i Rust av amiable-dev. Versjon 3.0+ støtter:

- **MIDI-kontrollere**: Native Instruments Maschine Mikro MK3 (full RGB), generic MIDI.
- **Gamepads (HID/SDL)**: Xbox 360/One/Series, PlayStation DualShock 4/DualSense, Switch Pro, joysticks, racing-rattl, flight-sticks, HOTAS.
- **Output-actions**: keystrokes, LED-feedback, profiler. Daemon (`conductor`) + ctl-verktøy (`conductorctl`) + diagnose-tools (`midi_diagnostic`, `pad_mapper`, etc.). Config i TOML, hot-reload med 0-8 ms latency.

**Begrensning som er viktig for vårt formål**: Dokumentasjonen viser **keystroke-output** og **LED-feedback**, men nevner ikke eksplisitt vilkårlig shell-kjøring. Realistisk er Conductor en "MIDI/gamepad → keystroke"-bro, ikke en script-launcher. For å trigge `wt.exe focus-tab -t N` må vi sannsynligvis binde til en globalt registrert Windows-hotkey som AutoHotkey håndterer.

### Linux-installasjons-krav

- udev-rule: `/etc/udev/rules.d/50-conductor.rules`
- Gruppe-medlemskap: `plugdev`, `input`
- Device-paths: `/dev/input/js*`, `/dev/input/event*`, ALSA MIDI-porter (`aconnect -l`)
- Systemd user-service: `~/.config/systemd/user/conductor.service`

### WSL2-feasibility (kritisk)

**Kort svar: mulig, men kronglete.**

- WSL2 har **ikke** native USB/HID-passthrough. Må gå via [usbipd-win](https://github.com/dorssel/usbipd-win): `usbipd bind --busid=X.Y` + `usbipd attach --wsl --busid=X.Y`.
- WSL2-standard-kernelen mangler en del HID-moduler. Microsofts egne ingeniører har kommentert at gamepad-støtte var "ikke vurdert" i system-distroen (se [microsoft/WSL#7747](https://github.com/microsoft/WSL/issues/7747)). Krever ofte custom-kernel eller modprobe av `hid-generic`, `usbhid`, `joydev`.
- ALSA MIDI i WSL2: Eksisterer, men ALSA i WSL2 bruker PulseAudio-bridge mot Windows. MIDI-routing er ikke alltid stabilt.
- **Hver omstart av WSL2** krever ny `usbipd attach`. Kan automatiseres med Task Scheduler i Windows, men én ting til som kan ryke.

### Realistisk use-case for vårt setup

| Use-case | Conductor i WSL? | Bedre alternativ |
|---|---|---|
| Bytte pane i Windows Terminal | Nei — controller-eventet må uansett til Windows for å trigge `wt.exe` | **AutoHotkey** binder gamepad-knapp → `wt -w 0 focus-tab -t N` direkte |
| Trigge bash-script i en bestemt Claude-pane | Mulig, men krever input-injection i en spesifikk pane | Ingen god løsning — Claude-paner er ikke addresserbare som API |
| Skifte mellom 16 paner raskt | Marginalt nyttig | WT chord-bindings + numpad er like raskt |
| RGB-feedback (hvilken Claude er busy) | Stilig, men ingen real-time tilbakemelding fra Claude | Statusline i firm-statusline.sh allerede dekker dette |

### Konklusjon på Conductor

**Drop for nå.** Hvis dette skal inn, bør det være som **AutoHotkey-på-Windows** (ikke Conductor-i-WSL), bundet til numpad eller en billig MIDI-pad direkte på Windows-siden. Det gir 80 % av verdien på 5 % av kompleksiteten.

**Hvis operatør likevel vil teste Conductor**: Kjør det på **Windows direkte** (ikke i WSL). Conductor har Windows-installer ([getconductor.dev/installation/windows.html](https://getconductor.dev/installation/windows.html)). La det sende keystrokes til Windows Terminal, så håndteres pane-bytting via WT's egne keybindings.

## 16-pane design

### Layout

**Anbefaling: To separate Windows Terminal-vinduer side om side på samme skjerm (eller én skjerm per modell hvis ultra-wide / dual monitor).**

```
Skjerm 1 (eller venstre halvdel):        Skjerm 2 (eller høyre halvdel):
+------------------------------+         +------------------------------+
| firm-claude (WT-vindu 1)     |         | firm-codex (WT-vindu 2)      |
| - code-1   - ai-1            |         | - cx-code-1   - cx-ai-1      |
| - code-2   - ai-2            |         | - cx-code-2   - cx-ai-2      |
| - thesis-1 - as-1            |         | - cx-thesis-1 - cx-as-1      |
| - soking-1 - personal-1      |         | - cx-soking-1 - cx-personal-1|
+------------------------------+         +------------------------------+
```

**Hvorfor IKKE 16 paner i ett vindu**:

- Hver pane blir ca. 24×10 tegn på 1080p — ulesbar.
- Visuell ryddighet: én modell per vindu er en mental partisjon.
- WT-vinduer kan flyttes til ulike skjermer / virtuelle desktops.
- Kan lukke ett vindu uten å miste det andre.

### Pane-distribusjon (uendret per side, speilet)

| Rolle (Claude) | Codex-speil | Prosjekt | Worktree-path |
|---|---|---|---|
| `code-1` | `cx-code-1` | workspace (`~/code`) | `~/code/.worktrees/<model>/<slug>` |
| `code-2` | `cx-code-2` | workspace | samme |
| `ai-1` | `cx-ai-1` | nexus (`~/code/ai-assistent`) | `~/code/ai-assistent/.worktrees/<model>/<slug>` |
| `ai-2` | `cx-ai-2` | nexus | samme |
| `thesis-1` | `cx-thesis-1` | master-oppgave + battery-electrolyte-predictor | egen worktree per repo |
| `as-1` | `cx-as-1` | AS-prosjekt | `~/code/<as-repo>/.worktrees/<model>/<slug>` |
| `soking-1` | `cx-soking-1` | søking-fulltid | egen worktree |
| `personal-1` | `cx-personal-1` | personlig | egen worktree |

### Launcher-tilpasninger

Eksisterende `_bin/firm-tab-init.sh` tar `<role> <project>` som argumenter og kjører `claude --dangerously-skip-permissions`. For 16-pane:

- **Ny launcher**: `_bin/firm-codex-init.sh <role> <project>` — speil av firm-tab-init men kjører `codex` (eller hva enn Codex CLI-kommandoen er) i stedet.
- **Felles bus-init**: Begge launchere kaller en delt `_bin/firm-bus-register.sh <role> <model>` som logger til `00-firm-bus/feed.md`.
- **Statusline**: Utvid `firm-statusline.sh` til å vise både `FIRM_ROLE` og `FIRM_MODEL` (claude/codex).
- **Wrapper**: `_bin/firm-16.sh` — starter begge WT-vinduer i sekvens med riktig posisjon (via `wt.exe --pos x,y --size c,r`).

## Git-strategi

**Dette er den viktigste delen.** Uten disiplin her blir 16-pane et merge-helvete.

### Worktree-konvensjon

- **Hovedbranch**: forblir `main` (eller `master` der det gjelder).
- **Worktree-plassering**: `<repo>/.worktrees/<model>/<task-slug>/`
  - Eks: `~/code/ai-assistent/.worktrees/claude/fix-orb-gate/`
  - Eks: `~/code/ai-assistent/.worktrees/codex/refactor-regime-detector/`
- **Branch-navn**: `<model>/<role>/<task-slug>`
  - Eks: `claude/ai-1/fix-orb-gate`
  - Eks: `codex/ai-2/refactor-regime-detector`
- **`.gitignore` per repo**: legg til `.worktrees/` så worktrees ikke vises som untracked i parent-repo.

### Worktree-lifecycle

```
opprett:  git -C <repo> worktree add .worktrees/claude/<slug> -b claude/<role>/<slug>
arbeid:   cd <repo>/.worktrees/claude/<slug>
push:     git push -u origin claude/<role>/<slug>
PR:       gh pr create --base main --head claude/<role>/<slug>
rydde:    git -C <repo> worktree remove .worktrees/claude/<slug>
          git -C <repo> branch -d claude/<role>/<slug>  (etter merge)
```

### Merge-strategi

- **Hver worktree → egen PR mot main**. Aldri direkte push til main fra worktree.
- **Linear merge**: squash-merge for små features, merge-commit for større.
- **Karri reviewer** for nexus-PRs (per global memory).
- **Operatør reviewer** for thesis, AS, personlig.
- **Konflikter løses i PR**, ikke i worktree — det betyr at hvis to PRs rører samme fil, må den som lander først rebase den andre.

### Konflikt-forebygging (operasjonelt)

**Tre lag:**

#### Lag 1: rolle-eier per fil-domene (forebyggende, anbefalt primært)

Skriv ned i hver prosjekt-`CLAUDE.md` hvilken rolle som "eier" hvilke filer:

```
nexus eierkart:
- ai-1 (claude) + cx-ai-1 (codex): strategy/* + tests/strategy/*
- ai-2 (claude) + cx-ai-2 (codex): infra/* + scripts/*
```

To agenter på samme rolle (cross-model) er forventet å koordinere via inbox. To agenter på forskjellige roller skal IKKE krasje fordi de jobber i forskjellige underdomener.

#### Lag 2: path-locks i 00-firm-bus (avvergende, for cross-domene)

Ny katalog: `~/Obsidian/Brain/00-firm-bus/locks/`. Format:

```
locks/
  nexus__strategy__orb_gate.py.lock
    # content:
    # owner: claude/ai-1
    # acquired: 2026-05-14T10:30:00Z
    # task: fix-orb-gate
```

Lock-fil-navn = `<project>__<dot-separert-path>.lock`. Før edit av en fil utenfor egen rolle-domene: `touch` lock-fil og deklarer i `feed.md`. Etter ferdig: slett lock + commit.

**Disiplinen, ikke verktøyet**, gjør dette robust. En hook kan sjekke om lock-fil eksisterer før edit, men ikke i MVP.

#### Lag 3: divergens-detektor (deteksjons-fallback)

Daglig cron / Stop-hook som kjører `git fetch --all` per repo og varsler i `feed.md` hvis to `<model>/*` branches har divergent endring på samme fil.

### Inbox-koordinering — utvidelse av 00-firm-bus

Nye inbox-filer:

```
00-firm-bus/inbox/
  cx-code-1.md       # ny
  cx-code-2.md       # ny
  cx-ai-1.md         # ny
  cx-ai-2.md         # ny
  cx-thesis-1.md     # ny
  cx-as-1.md         # ny
  cx-soking-1.md     # ny
  cx-personal-1.md   # ny
  conductor.md       # NY — for dispatcher-agenten (se under)
```

**Cross-model handoff**: Når claude `ai-1` vil at codex `cx-ai-1` skal ta over (eller motsatt), legges en oppgave i peer-inbox:

```
ai-1.md → cx-ai-1.md
"Task X klargjort i worktree .worktrees/claude/fix-orb-gate.
Branch claude/ai-1/fix-orb-gate. Codex tar over for å skrive tester.
Pull branch og lag .worktrees/codex/test-orb-gate."
```

### Dispatching — hvem fordeler oppgaver?

**Tre modeller, økende kompleksitet:**

1. **Manuell** (MVP): Operatør splitter selv. Kjapt, ingen ekstra infra. Default.
2. **Halv-manuell**: Én "dispatcher"-pane (kan være Claude eller operatør selv i tmux) som tar inn høy-nivå mål og fordeler til inbox-er. Ingen automatikk, men sentralisert oversikt.
3. **Konduktør-agent** (langsiktig): En 17. pane som kjører en koordinerings-Claude. Tar input fra operatør, leser `00-firm-bus/feed.md`, dispatcher til relevante inbox-er, sjekker konfliktsoner. Implementeres som vanlig Claude med spesielt system-prompt + custom slash-commands. **Ikke MVP** — bygg etter at 16-pane har vært i drift i en uke.

## Alternativ-vurdering

| Alternativ | Pro | Con | Verdikt |
|---|---|---|---|
| **A. Beholde 8 Claude, bytte til Codex manuelt** | Null ekstra infra. Operatør har full kontroll. | Mister parallell A/B mellom modellene. Codex-arbeid blir sekvensielt. | **Reell fallback** hvis 16-pane viser seg overveldende. |
| **B. 16 paner i ett WT-vindu** | Ett vindu å fokusere på. | Hver pane blir ulesbart liten på 1080p. Visuell støy. | Avvist. |
| **C. To WT-vinduer (8+8)** ← **anbefalt** | Ren modell-partisjon. Hvert vindu kan på egen skjerm. Bygger på eksisterende launcher. | To launchere å vedlikeholde. | **Velg denne.** |
| **D. tmux + overmind** | Scripted, deklarativ layout. Persisterer over WT-restart. | Krever Linux-side terminal-frontend (no native WT-integration). Operatør har allerede zellij-fallback. | Lavere prioritet. |
| **E. zellij med custom 16-pane layout** | Operatør har allerede `ai-assistent/.zellij/layouts/firm8.kdl`. Lett å utvide til firm16.kdl. | Zellij-pane-borders koster vertikal plass. | **God plan-B** hvis WT-stabilitet er et problem. |
| **F. Tauri-basert custom kontroll-app** | Maks fleksibilitet, kunne integrere Conductor naturlig. | Måneder med bygging for et personlig verktøy. Vedlikeholds-byrde. | Avvist. |
| **G. Conductor + AutoHotkey kombo** | Stilig fysisk kontroll, RGB-feedback. | WSL2-passthrough er ustabilt, og keystrokes via AHK gir 90 % av verdien. | Avvist for MVP. Eventuelt senere som luksus-lag. |

## Anbefaling

### MVP-skritt (kjør i denne rekkefølgen)

**Fase 1: Codex-launcher speiling — 2-3 timer**

1. Kopiér `firm-tab-init.sh` → `firm-codex-init.sh`. Erstatt `claude --dangerously-skip-permissions` med Codex-CLI-kommando.
2. Kopiér `firm-wt-split.sh` → `firm-wt-codex.sh`. Endre pane-titler til `cx-*`. Sett `--pos` så vinduet åpner høyre side av skjermen.
3. Lag `firm-bus-register.sh` (faktoriser ut delt logikk fra `firm-tab-init.sh`).
4. Lag inbox-filer for alle 8 `cx-*` roller (tomme).
5. Test: kjør `firm-wt-codex.sh`, verifiser at alle 8 paner åpner med riktig rolle + Codex starter.

**Fase 2: Worktree-konvensjon på pilotprosjekt (nexus) — 3-4 timer**

1. Legg `.worktrees/` til `.gitignore` i ai-assistent.
2. Dokumentér worktree-lifecycle i `ai-assistent/CLAUDE.md`.
3. Lag helper-script `_bin/firm-worktree-new.sh <model> <role> <slug>` som oppretter worktree + branch.
4. Lag helper-script `_bin/firm-worktree-cleanup.sh` som rydder merge'de branches + worktrees.
5. Kjør et "ekte" parallell-eksperiment: la `ai-1` (claude) jobbe på feature X mens `cx-ai-2` (codex) jobber på feature Y, separate worktrees. Evaluer.

**Fase 3: Path-locks + utvidet inbox-protokoll — 2-3 timer**

1. Opprett `00-firm-bus/locks/` med README som forklarer protokollen.
2. Skriv `_bin/firm-lock.sh acquire|release <project> <path>` helper.
3. Oppdater `ai-assistent/CLAUDE.md` med rolle-eier-kart (hvilken rolle eier hvilke filer).
4. Rull ut til de andre prosjektene én etter én.

**Fase 4 (valgfri, etter 1 ukes drift): Konduktør-agent — 1 dag**

1. Lag `00-firm-bus/inbox/conductor.md`.
2. Skriv system-prompt for dispatcher-Claude.
3. Lag custom slash-commands: `/dispatch <role> <task>`, `/status`, `/lock-check`.

### Tids-estimat samlet

- **MVP (fase 1-3)**: ~1 arbeidsdag (8 timer) for grunn-funksjonalitet.
- **Stabilisering**: 1 ukes daglig bruk for å finne pain-points.
- **Fase 4 (konduktør)**: ekstra 1 dag etter stabilisering.
- **Totalt til "full drift"**: 2-3 arbeidsdager + 1 uke wall-clock.

### Hva venter (ikke gjør nå)

- **Conductor i WSL**: vent til operatør har konkret friksjon ved pane-bytting som AutoHotkey ikke løser.
- **Tauri kontroll-app**: bygg aldri med mindre dette blir et delt verktøy med Karri.
- **Auto-dispatcher**: ikke før manuell dispatching har vært i drift i en uke.

## Risikoer

| Risiko | Sannsynlighet | Impact | Mitigering |
|---|---|---|---|
| **Mental-load: 16 samtidige sesjoner er for mye** | Høy | Høy | Start med 8+4 (claude full + codex bare nexus+code). Evaluer etter 3 dager før full 16. |
| **Git-konflikter når to roller rører samme fil** | Middels | Middels | Lag 1 (rolle-eier-kart) + Lag 2 (locks) + Lag 3 (divergens-detektor). |
| **Kontekst-svinn**: agenter glemmer hva andre paner gjør | Høy | Middels | Inbox-disiplin + `feed.md`-tail + statusline. Aksepter at agenter ikke har full oversikt. |
| **Codex-CLI har annen UX enn Claude** (commit-flow, permissions, etc.) | Middels | Lav | Dokumentér i `reference_codex_setup.md` i memory. Eget oppstarts-script per modell. |
| **WT-vindu-håndtering**: to vinduer er kronglete på laptop-skjerm uten dual monitor** | Middels | Middels | Bruk Windows virtuelle desktops (Win+Ctrl+D), ett vindu per desktop. Eller fallback til zellij-layout med 16 paner. |
| **PR-overload**: 16 agenter genererer 10+ PRs/dag** | Høy | Middels | Karri-reviewer overbelastes. Squash-merge default. Auto-merge for trivielle PRs. |
| **Conductor-eksperimentering tar tid uten payoff** | Lav (hvis vi følger anbefaling) | Lav | Strikt: ikke rør Conductor før MVP-fase 1-3 er stabil. |
| **Strategy/risk-changes glipper gjennom flere PRs samtidig** | Middels | Høy (penger) | Bind global memory-regel: alle nexus strategy/risk-endringer går via `docs/strategy/proposals/`. PR-template med checklist. |

## Neste-skritt

**Når operatør sier "OK kjør 16-pane MVP":**

1. Verifiser at Codex CLI er installert og fungerer i WSL (kjør `codex --version`).
2. Bekreft hvilken kommando Codex starter med (`codex`? `codex chat`? auth-flow?).
3. Kjør Fase 1 (Codex-launcher). Test single-pane først, deretter 8-pane.
4. Velg pilot-task for nexus: én reell oppgave som Claude og Codex kan ta hver sin del av (f.eks. Claude refaktorer en gate, Codex skriver tester).
5. Kjør gjennom worktree-lifecycle manuelt én gang før helper-scripts (lær gotchas).
6. Dokumentér i `~/Obsidian/Brain/00-firm-bus/PRESENCE.md` at firm-launcher nå har 16-mode.

**Operatør må bestemme før vi går videre:**

- [ ] Er Codex CLI auth-flow et engang-oppsett, eller per-pane? (påvirker launcher-design)
- [ ] Er dual-monitor / ultrawide tilgjengelig, eller jobbes det på laptop? (påvirker vinduslayout)
- [ ] Skal Karri ha samme 16-pane oppsett på sin maskin? (påvirker shared-instance behavior)
- [ ] Skal AS-prosjekt og personlig-prosjekt være med fra dag 1, eller bare nexus+thesis+code i pilot? (anbefaling: pilot på nexus+code først, utvid senere)

---

*Forfatter: Claude (Opus 4.7 1M). Forslag — krever operatør-godkjenning før implementering. Karri inviteres til review for nexus-relaterte deler.*
