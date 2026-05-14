---
tags: [decision, control-plane, infra, dashboard, firm-bus, proposal]
date: 2026-05-14
status: proposal
owner: operator
reviewers: [operator, karri]
related:
  - "[[00-firm-bus/README]]"
  - "[[reference_firm_launcher]]"
  - "[[reference_shared_instance]]"
---

# Control-plane / dashboard for 6-prosjekt-multi-AI

## TL;DR

Bygg dashboardet i **tre lag**, ikke ett. MVP = **Obsidian Dataview** med
master-note `00-CONTROL-PANEL.md` (timer, ikke dager). V2 = **Python TUI** i
en dedikert 9. WT-pane når MVP-en føles trang. V3 = **Tauri** først hvis vi
faktisk trenger native GUI/klikkbar pane-fokus-bytte og cross-machine push.

Hovedanbefaling: start på D (Dataview). All data ligger allerede i vault,
Obsidian Sync er løsningen for cross-machine, og det er null nye prosesser
å babysitte. Skaler oppover bare hvis MVP slår i taket.

## Problem

Operatør driver i dag 8 paner Claude i ett Windows Terminal-vindu (snart 16
med Codex), fordelt på 6 prosjekter. Koordinering skjer via append-only
`feed.md` + `inbox/<role>.md` + sporadiske handoffs. Det fungerer, men:

- Ingen oversikt-på-ett-blikk: "hvilke paner er live? hvem har uleste meldinger?
  hvem er blokkert?"
- Ingen cross-prosjekt-status: "hvor er siste commit i hvert repo? åpne TODOs?"
- Ingen sentral trigger: "send melding til alle paner", "rydd inbox",
  "ny handoff" krever manuell `echo >> ...` i hver pane.
- Discord-alerts (Nexus) krever kontekst-bytte.
- Når operatør og Karri jobber parallelt på samme delte instans, vet ingen
  hvem som rørte hva sist uten å gå i `feed.md` for hånd.

Visjonen: "hele `code/` skal bli én personlig AI som tracker og navigerer".
Dashboardet er kontroll-planet for den AI-en.

## Scope

Hva MVP-en skal svare på, i prioritert rekkefølge:

1. **Pane-status**: hvilke roller er online nå, hvor lenge åpen, siste verb fra
   feed (online/done/blocked/handoff).
2. **Inbox-status**: per `inbox/<role>.md` — uleste meldinger
   (filsize > 0 eller siste mtime > siste read-marker).
3. **Live feed**: siste N linjer fra `feed.md`, auto-refresh.
4. **Prosjekt-status**: siste commit + branch + dirty-flag per repo
   (`ai-assistent`, `Master-oppgave`, `battery-electrolyte-predictor`,
   `research-os`, brain-repo, workspace selv).
5. **Cross-prosjekt-søk**: "hvem rørte fil X sist?" — git-log scan + feed-grep.
6. **Discord-snippet**: siste alerts (Nexus webhooks) inn i samme view.
7. **Pane-fokus-bytte**: klikk → `wt.exe focus-tab` (kun haves når vi er ute
   av Obsidian — V2+).
8. **Trigger-knapper**: broadcast melding til alle inbox-er, rydd, ny handoff
   (V2+).

Ikke i scope MVP: ekte real-time push, multi-bruker locking, mobile view,
permission-modell utenom delt-instans.

## Tech-valg

### A. Tauri (Rust + web-frontend)

- **Pros**: single binary, native følelse, kan kalle `wt.exe` via PowerShell,
  fungerer ute av Obsidian, kan kjøre system-tray.
- **Cons**: Rust-onboarding ikke null (operatør har ikke ride-or-die Rust),
  packaging/auto-update er sin egen kanin-tunnel, cross-machine
  state-sync må bygges selv (Obsidian Sync gir det gratis).
- **Når**: V3, etter at vi vet hva vi faktisk vil ha i UI-et.

### B. Next.js / SvelteKit + Node

- **Pros**: kjent stack, `localhost:3000` i nettleser, lett å hacke,
  rikt komponent-økosystem.
- **Cons**: enda en Node-prosess å babysitte, browser-tab er ennå en
  kontekst-bytte, statisk å integrere med wt.exe / Obsidian, cross-machine
  state-sync må bygges selv.
- **Når**: hopper over. Web-app gir ikke nok over D+C kombinert.

### C. TUI (Python `textual` eller `rich`)

- **Pros**: bor i en 9. WT-pane → samme paradigme som resten av firm,
  null kontekst-bytte, kan kalle ut til `git`/`wt.exe`/`curl` trivielt,
  delt instans kan kjøre samme script på begge maskiner.
- **Cons**: tekst-only, må bygge keyboard-shortcuts selv, ingen embed av
  Discord-embeds eller Obsidian-renderte notes.
- **Når**: V2, når Dataview-MVP-en føles trang for "trigger knapper".

### D. Obsidian Dataview + embedded views

- **Pros**: **all data ligger allerede her**. Null nye prosesser. Cross-machine
  via Obsidian Git plugin gratis. Operatør lever i vaulten uansett. Karri
  ser samme view. Setup-tid: timer.
- **Cons**: Dataview leser frontmatter/inline-fields best — `feed.md` er fri
  tekst, må enten parses med DataviewJS eller suppleres av små state-filer.
  Ingen "klikk → bytte WT-pane". Refresh-rate begrenset til Dataview-default
  (sekunder, godt nok). Begrenset av hva Obsidian gir.
- **Når**: **MVP, nå.**

## Anbefaling: MVP = D (Dataview)

**Hvorfor**:

1. Data finnes allerede (`feed.md`, `inbox/*.md`, `roster.md`, `PRESENCE.md`).
2. Cross-machine "gratis" via Obsidian Git plugin — løser delt-instans-problemet
   uten at vi skriver én linje sync-kode.
3. Tids-til-første-bruk: timer.
4. Nedside ved feil valg: kastet en master-note. Null infra-rydding.
5. Funn fra MVP-bruken styrer V2-design.

Ulempen ("kan ikke klikke for å bytte pane") er V2-funksjonalitet uansett.

## Arkitektur-skisse

### Data-kilder (MVP)

Eksisterende:

- `00-firm-bus/feed.md` — append-only log.
- `00-firm-bus/inbox/<role>.md` — per-pane innboks.
- `00-firm-bus/roster.md` — pane → prosjekt-mapping.
- `00-firm-bus/PRESENCE.md` — operatør+Karri presence (allerede der).

Nye (introduseres av MVP):

- `00-firm-bus/pane-status.json` — heartbeat-fil. Hver pane oppdaterer ved
  init og en gang i minuttet via cron/hook. Skjema (skisse):

  ```jsonc
  {
    "code-1": {
      "machine": "operator-laptop",
      "opened_at": "2026-05-14T09:12:33Z",
      "last_heartbeat": "2026-05-14T15:55:01Z",
      "last_verb": "done",
      "last_summary": "ryddet workspace CLAUDE.md",
      "cwd": "/home/nithu/code"
    },
    "ai-2": { ... }
  }
  ```

- `00-firm-bus/git-snapshot.json` — refresht hvert N-te minutt av en
  workspace-cron eller hook. Per repo: branch, last commit SHA + message
  + author + age, dirty-count.

  ```jsonc
  {
    "ai-assistent": {
      "branch": "main",
      "last_commit": "abc123",
      "last_msg": "fix: foundation gate hysteresis",
      "age_minutes": 42,
      "dirty_files": 3
    },
    ...
  }
  ```

### Master-note: `~/Obsidian/Brain/00-CONTROL-PANEL.md`

Layout (skisse, pseudo-Dataview):

```markdown
# Control panel

## Live paner (siste 5 min)

```dataviewjs
// les pane-status.json
// list paner hvor last_heartbeat > now - 5min
// vis: role | machine | opened-for | last_verb | last_summary
```

## Inbox-status

```dataviewjs
// for hver fil i 00-firm-bus/inbox/
// vis: role | size | mtime | "uleste" hvis mtime > read-marker
```

## Siste 20 feed-events

```dataviewjs
// tail -n 20 av feed.md
// parse "- <ISO> [<git-user>] <role> <verb>: <summary>"
// vis som tabell
```

## Git-status per repo

```dataviewjs
// les git-snapshot.json
// vis: repo | branch | last_msg | age | dirty
```

## Discord-snippet (Nexus)

```dataviewjs
// les en Discord-spool-fil (V1.5) eller link ut
```

## Quick actions

- [[broadcast-template]] — copy/paste melding til alle inbox-er
- [[handoff-template]]
- `_runbooks/rydd-inbox.md`
```

### Heartbeat-mekanikk (MVP)

- `_bin/firm-tab-init.sh` skriver til `pane-status.json` ved init
  (atomisk write: tmpfil + `mv`).
- Cron i hver pane (`*/1 * * * *`) eller en bash-while-true bakgrunnsjobb
  starta av init-scriptet, oppdaterer `last_heartbeat`.
- En workspace-side-cron oppdaterer `git-snapshot.json` hvert 2. minutt.
- Skriving til `pane-status.json` må være atomisk for å unngå race
  conditions ved 16 paner — bruk `flock(1)` eller per-pane shard-fil
  (`pane-status/<role>.json`) som Dataview aggregerer.

**Anbefalt valg**: per-pane shard-fil. Null lock-kompleksitet, Obsidian
Git plugin merger fint i de fleste tilfeller, og en aggregator kjører
serverless i Dataview ved render-tid.

## Roadmap

| Versjon | Innhold | Estimat |
|---|---|---|
| **MVP (D)** | `00-CONTROL-PANEL.md` med 4 Dataview-blokker; per-pane shard-status-fil; git-snapshot-cron | **4–8 timer** |
| MVP+ | Discord-spool (siste webhooks dumpes til `00-firm-bus/discord-spool.md`); broadcast/handoff-templates som hurtignote | 1 dag |
| **V2 (C — TUI)** | Python `textual` app i 9. pane: samme data, men med trigger-knapper (broadcast, rydd inbox, ny handoff), keyboard-shortcuts, `wt.exe focus-tab` på pane-row | **3–5 dager** |
| V2.5 | TUI får live tail (inotify på feed.md) og diff-mod på pane-status | 2 dager |
| **V3 (A — Tauri)** | Native app, system-tray, Discord embeds, mobile companion via Tailscale | **2–4 uker** — bygges kun hvis V2 slår i taket |

## Risikoer

1. **Race conditions på `feed.md` ved 16 paner**: append-only med `>>` er
   atomisk for små writes (POSIX < PIPE_BUF = 4 KB), så én linje per write
   er trygt. Risiko øker hvis paner skriver multi-line. Mitigering: enforce
   "ett event = én linje", lint i `firm-tab-init.sh`.
2. **Obsidian Sync vs. on-disk read/write**: operatør bruker Obsidian Git
   plugin (commit + push periodisk), ikke ekte real-time sync. State-filer
   som oppdateres hvert minutt vil produsere mye git-støy. Mitigering: legg
   `pane-status/` og `git-snapshot.json` i `.gitignore` for brain-repo —
   de er lokal-state, ikke shared knowledge. Da må Karri ha egen kopi, og
   "delt instans" på det punktet betyr "delt vault, lokal kontroll-plan".
3. **Cross-machine state**: hvis state ikke skal pushes, mister Karri
   synlighet over operatørs paner. Beslutning: i MVP er kontroll-planet
   per-maskin. `feed.md` er fortsatt shared og forblir sannhetskilde for
   "hva skjedde". Cross-machine pane-status er V3-feature (krever push-bus,
   f.eks. en delt sqlite-fil eller en lett Redis/Cloudflare KV).
4. **Dataview rendering-kost**: med mange queries i én note kan refresh
   bli treigt. Mitigering: cache via `dv.array` + tids-bucketed queries,
   eller splitt panel i flere noter (`CP-paner.md`, `CP-repos.md`).
5. **Heartbeat-drift hvis pane sover**: en pane som er åpen men idle viser
   "stale" status. Avhengig av smak: enten gjør idle-paner grå, eller la
   `last_verb` (ikke `last_heartbeat`) styre visningen.

## Åpne spørsmål

1. **Heartbeat-frekvens**: 1 min (gir fersk view, mer git-støy hvis tracked),
   5 min (rolig, men "live" føles ikke live)? **Forslag**: 1 min, untracked.
2. **Discord-spool**: trekker vi siste alerts fra Discord-API (krever token i
   miljø) eller speiler vi webhooks ved å la Nexus-koden også appende til
   en spool-fil i vault? **Forslag**: spool-fil; null ny secret-håndtering.
3. **Skal Codex-panene (16-pane-utvidelsen) ha samme heartbeat-protokoll**?
   **Forslag**: ja, samme `pane-status/<role>.json`-shard, namespace
   `codex-<n>`.
4. **Aggregator-script**: trenger vi et `_bin/firm-aggregate.sh` som leser
   alle shard-filer og produserer ett `pane-status.json` for Dataview, eller
   parser vi shards direkte i DataviewJS? **Forslag**: parse direkte —
   færre bevegelige deler.
5. **Read-markers for inbox**: hvordan vet vi at en melding er "lest"? En
   ekstra `.read` sidecar-fil med ISO-timestamp, eller en YAML-frontmatter
   `last_read:` i selve inbox-fila? **Forslag**: frontmatter — Dataview-
   native.
6. **TUI vs. native: hvilken trigger får oss til å bygge V2**? Forslag-
   kriterium: hvis vi 5 ganger på en uke ønsket "klikk for å gjøre X" i
   kontroll-panelet, da bygger vi V2.
7. **Karri-review** av dette forslaget før vi setter i gang MVP? Bør være
   ja — kontroll-planet er delt-instans-infrastruktur.

---

*Foreslått 2026-05-14. Avventer operatør "OK kjør" + Karri-blink.*
