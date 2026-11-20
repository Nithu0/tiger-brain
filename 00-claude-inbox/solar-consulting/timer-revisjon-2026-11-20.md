# Timer-revisjon: hvem kjører kode andre kan endre, med Nithus legitimasjon

infra-1, 20.11.2026, bestilt av orchestrator-1 (fra paal-1). Bare lesing, ingenting endret.

## Grunnlaget

- **gh-legitimasjonen:** `gh` er logget inn som **Nithu0**, med scopene `repo, workflow, read:org, project, gist`. Det gir skrivetilgang til alle repoer Nithu0 når, i begge org-ene, inkludert workflow-filer. `git` bruker samme token gjennom `gh auth git-credential` (global credential.helper). Alt som kjører som brukeren `nithu`, kan derfor lese og bruke tokenet. Det gjelder også `~/.config/gh/hosts.yml`, Railway- og Vercel-innloggingen og `~/.config/firm/*.env`.
- **Hvem som kan endre koden:**
  - Nithu0/command-center og Nithu0/aslisten-crm har bare Nithu0 (admin). I praksis er det likevel alle agent-panene, siden de pusher og merger som Nithu0.
  - Nithu0/Solar-Consulting har tintun2602 og AlperOnics med write.
  - Solar-Consulting/drift har tintun2602, AlperOnics, **veldora-anbud** (bot) og Nithu0, alle som admin.
- **Slik kommer ny kode i drift:** bare aslisten-backupen henter origin/main selv. Den gjør `git fetch` og `checkout --detach origin/main` før hver kjøring. Resten kjører fra delte hovedcheckouter (`~/code/command-center` og `~/code/drift` på main) og får ny kode når et pane kjører `git pull` og bygger. Hvem som puller `~/code/drift`, og hvor ofte, er UNKNOWN.

## Tabell

Risiko: **H** = kode som andre enn Nithu kan endre kjører med full gh/Railway-tilgang, eller kan gjøre det med én push. **M** = kode som agentene endrer, med skrivetilgang. **L** = installert kopi eller ingen legitimasjon.

| Unit | Kodekilde | Hvordan ny kode kommer inn | Legitimasjon | Skrivetilgang | Risiko | Forslag |
|---|---|---|---|---|---|---|
| `github-runner.service` (self-hosted Actions-runner, `nithupc-wsl`, online) | Workflow-filer fra **hvilken som helst gren** i Nithu0/Solar-Consulting med `runs-on: self-hosted` | En push fra en som har write (tintun2602, AlperOnics, agentene). Ingen PR eller merge trengs for `on: push` | Kjører som `nithu` og når dermed gh-tokenet (repo og workflow), Railway, Vercel, `.env`-filer og Brain | Alt Nithu0 kan | **H** | Ingen workflow på main bruker runneren, og siste jobb var 14.10. Forslag: stopp og avregistrer den (operatør-gated). Trengs den, kjør den som egen bruker eller container uten tilgang til `~nithu`, og bare for `workflow_dispatch` fra main. |
| `aslisten-crm-backup.service` (timer 03:30 og 12:30, startes også av aldersvakten) | `~/code/aslisten-crm-drift`, alltid `origin/main` | **Automatisk.** En merge til Nithu0/aslisten-crm main kjører innen 12 t | Railway-CLI (`CRM_BACKUP_AUTH=railway`, Nithus kontoinnlogging). git fetch bruker gh-tokenet (lesing) | Railway-kontoen (alle prosjekter), gh via credential helper | **H** (få kan merge, men det skjer helt uten et menneske) | Lås til en gjennomgått commit eller tag som oppdateres med vilje, for eksempel med `installer.sh`, eller krev signert commit før checkout. Bytt kontoinnloggingen mot et prosjekt-token for aslisten-crm. |
| `drift-vakt.timer` | `~/code/drift` (Solar-Consulting/drift, main, delt checkout) | Ved neste `git pull` i `~/code/drift` | gh som Nithu0 (`gh api`: labels, kommentarer, søk), og `epostvakt.mjs` og `maaltavle.mjs --apply` (gws/gh) | Issues, labels og kommentarer i alle Nithu0-repoer, og Google Workspace via gws | **H** (fire admins, blant dem en bot, kan merge kode som kjører med Nithus token) | Kjør fra en installert kopi av en gjennomgått commit. Gi den et fine-grained token som bare har issues:write på drift, og ikke Nithus fulle token. |
| `scopevakt.timer` | `~/code/drift/tilganger/scopevakt.mjs` | Som drift-vakt | gh som Nithu0 (`execFile('gh')`) | Avhenger av kallene (UNKNOWN, ikke lest i detalj) | **H** (samme kilde) | Som drift-vakt. Ett felles token for begge vaktene, låst til drift. |
| `sc-bro.timer` | `~/code/command-center` main, `packages/platform/dist` | Ved pull **og** bygg av den delte checkouten | gh (les og skriv), Railway, Vercel, gws Drive, og `plattform-bro.env` (BRO_TOKEN) | Kommentarer og fullføringer i drift, **deploy** av plattform og web, flytting i Drive | **M**, men den kraftigste av dem (deploy). Bare agentene kan endre den | Kjør fra en installert og versjonert kopi (mønsteret fra anbud-vakt) bygd fra en merget commit, så pull i den delte checkouten ikke endrer hva som kjører. Lag et eget token for broen. |
| `sc-dagsrapport.timer` | Samme | Samme | gh (skriver kommentar i drift) og gws Docs | Kommentarer i drift og dokumentet «Dagsrapporter» | **M** | Samme som sc-bro. |
| `sc-statusissue.timer` | Samme | Samme | gh (skriver statusissuet) | Issues i drift | **M** | Samme som sc-bro. |
| `slack-vakt.service` | Samme (`dist/cli/slack-vakt.js`) | Samme | `slack-solar.env` (Slack-token). Fant ikke gh | Slack | **M** | Installert kopi. Se feedback_slack_not_authority. |
| `brain-sync.timer` | `~/code/command-center/_bin/brain-sync.sh` | Ved pull | git push via gh credential helper (Nithu0) | Pusher bare `sync/<host>` i tiger-brain, med gitleaks først | **M** | Installert kopi. Et deploy-key med skrivetilgang bare til tiger-brain, ikke gh-tokenet. |
| `firm-remote-verdict-watch.service` | `~/code/command-center/_bin` | Ved pull | Kjører `firm-remote-verify.sh approve` → **push** av jobbens gren med gh/git | Push til alle Nithu0-repoer | **M** (push-porten) | Installert kopi. Porten bør kjøre fra en kopi som ikke endres av det den slipper gjennom. |
| `anbud-modell-vakt.service` | `~/code/command-center/_bin` | Ved pull | Railway (`railway ssh` til prod-Postgres, sesjonen read-only) | Lesing i prod, i praksis full Railway-tilgang | **M** | Installert kopi og prosjekt-token. |
| `morgenbrief.timer` | `~/code/command-center/_bin` | Ved pull | Hermes (Telegram) og lokal node. Fant ikke gh | Telegram til operatøren | **M/L** | Installert kopi når de andre flyttes. |
| `cc-web`, `cc-api`, `brain-orchestrator`, `brain-worker` | command-center-checkouten (bygges ved start) | Ved pull og restart | `command-center/.env` (cc-web og cc-api). brain-worker bruker gh/LLM, ikke lest i detalj | UNKNOWN per tjeneste | **M** | Utenfor timer-spørsmålet. Tas med når de andre flyttes til installerte kopier. |
| `ollama-keepwarm.timer`, `gpu-roi-collect` | command-center | Ved pull | Ingen | Ingen | **L** | Ingen tiltak. |
| `anbud-vakt.service` | Installert kopi `~/.local/state/anbud-vakt/vakt.sh` (versjon ed9ab13) | Bare ved `vakt-install.sh` | Railway (logglesing) | Lesing | **L** | Ingen tiltak. |
| `aslisten-crm-backup-alder.timer` og `-varsel@` | Installert kopi `~/.local/lib/aslisten-crm-backup/` | Bare ved `installer.sh` | Ingen (alder starter backup-enheten) | Ingen | **L** | Ingen tiltak (men den starter rad 2). |
| `firm-varsel@` | Installert kopi `~/.local/lib/firm-varsel/` | Bare ved install | Ingen | Skriver én linje til feed.md | **L** | Ingen tiltak. |
| `hermes-gateway`, `omniroute`, `cc-omnigent*`, `litestream`, `lgtv-*` | Installerte binærer og venv, ikke repo-checkouter | Ved oppgradering | Egne `.env` (Hermes), ikke lest | UNKNOWN | utenfor | Ikke revidert her. |

## Forslag i rekkefølge

1. **Runneren** (høyest risiko, og billigst å fjerne): stopp `github-runner.service` og fjern registreringen. Den brukes ikke, og den gir alle med write i Solar-Consulting en vei inn til hele maskinen. Krever Nithu (operatør-gated).
2. **aslisten-backupen:** slutt å kjøre origin/main automatisk. Lås til en commit som `installer.sh` setter, og bruk et Railway-prosjekt-token.
3. **drift-vakt og scopevakt:** gi dem et eget fine-grained token, bare for Solar-Consulting/drift med issues:write, og kjør dem fra en installert kopi. Fire admins, blant dem en bot, kan i dag merge kode som kjører med Nithus fulle token.
4. **command-center-tjenestene** (sc-bro først, fordi den kan deploye): installert og versjonert kopi med samme mønster som anbud-vakt og firm-varsel, så en pull i den delte checkouten aldri endrer hva som kjører. Eget token for broen.
5. Generelt: ingen tjeneste skal bruke Nithus personlige gh-token. Lag ett token per tjeneste, med minste tilgang. Opprettelsen er Nithus (hemmeligheter).

## Ikke sjekket

- Hvem som puller `~/code/drift`, og hvor ofte.
- Nøyaktig hvilke gh-kall scopevakt og brain-worker gjør.
- Innholdet i `.env`-filene. Bevisst: bare navn og stier står her, ingen verdier.
- Om Solar-Consulting har innstillingen «fork pull request workflows» for private repoer.
