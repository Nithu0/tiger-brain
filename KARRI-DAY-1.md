---
tags: [meta, onboarding, karri]
type: meta
created: 2026-05-13
updated: 2026-05-21
---

# Karri — Day 1 (3 min)

Hei Karri. Paste this block, du er i gang. Målet: du ender opp med **samme firm-oppsett som operator kjører nå** — 8 parallelle Claude Code-paner som koordinerer via firm-bus i denne vaulten.

```bash
# 1. Clone the brain (assumes you have SSH access to tiger-brain)
git clone git@github.com:Nithu0/tiger-brain.git ~/Obsidian/Brain
cd ~/Obsidian/Brain

# 2. Run the firm-launcher installer — den spør om navn, email, og roster
bash firm-launcher/install.sh

# 3. Reload shell
source ~/.bashrc

# 4. Launch the firm
firm   # opens 8 Claude-paner i WT split-view
```

## Hva install.sh gjør

`firm-launcher/install.sh` er den portable installeren som ligger version-controlled her i brain-en. Den:

- Installerer firm-launcher-scriptene + `~/.bashrc`-aliasene (`firm`, `firmt`, `firmz`, `nx`).
- Setter opp statusline-en så hver pane viser rolle + prosjekt.
- Spør om **navn** og **email** — settes som git author på commits (viktig siden du er logget inn som `Nithu0`).
- Spør om **roster** — velg det operator anbefaler for din maskin.

Du trenger **ikke** command-center-repoet for å kjøre firm-launcheren. Launcheren er selvstendig.

## Hva firm-en er

"Firm-en" er 8 parallelle Claude Code-paner, én per rolle, spredt over operatorens prosjekter. Hver pane får en `FIRM_ROLE` og booter Claude med rolle-context. De koordinerer gjennom firm-bus-en i denne vaulten — slik jobber flere agenter i parallell uten å kollidere.

**8-pane-modellen:**

| Pane | Prosjekt | Working dir |
|---|---|---|
| `code-1`, `code-2` | workspace | `~/code` (cross-project meta-work) |
| `ai-1`, `ai-2` | nexus | `~/code/ai-assistent` (XAUUSD trading firm) |
| `thesis-1` | master-oppgave | `~/code/Master-oppgave` |
| `as-1` | AS | `~/code/AS` |
| `soking-1` | søking fulltid | `~/code/Søking fulltid` |
| `personal-1` | personlig | `~/code/Personlig` |

**Launch-varianter:**

- `firm` — 8 paner i ÉN Windows Terminal-tab via split-pane (split-view, **default**).
- `firmt` — 8 separate tabs i ett WT-vindu (fallback hvis split-view føles trangt).
- `firmz` — zellij-fallback hvis WT misoppfører seg.
- `nx` — alias for `firm`.

(`firm!` funker ikke — bash reserverer `!` for history-expansion. Bruk `firm`.)

## Firm-bus — koordineringsprotokollen

Alt ligger i `~/Obsidian/Brain/00-firm-bus/`. Brain-en synces mellom din og operatorens maskin via Obsidian Git (2-5 min), så firm-bus dobler som cross-machine presence-lag.

- `feed.md` — **append-only aktivitetslogg**. Alle skriver, alle leser. Én linje per event. **Read-only observasjon** — aldri rediger gamle linjer, append korreksjoner.
- `inbox/<role>.md` — **per-pane append-only dispatch-kanal**. Slik handes arbeid av mellom paner.
- `PRESENCE.md` — "hvem er online"-snapshot. Les siste rad per `(user, role)`.

**Disiplinen (dette er hele poenget):**

1. **Les din egen `inbox/<role>.md` FØRST** når en pane starter — peers koordinerer scope gjennom den.
2. **Hold deg i din lane.** Ikke rør filer en annen pane jobber med. Sjekk `git status` + `git log` før edits.
3. **Hand off via inbox** — skriv en markdown-blokk i peer-ens `inbox/<role>.md` når du gir fra deg konkret arbeid.
4. **One-liner til `feed.md`** når en chunk er ferdig. Lange rapporter → `~/Obsidian/Brain/00-claude-inbox/<project>/`, aldri `feed.md`.

## command-center — control plane

Operator kjører nå **command-center**, en workspace-wide control plane: en Next.js + Fastify + SQLite-dashboard som observerer OG driver firm-panene. Den lever i et **privat** repo, `github.com/Nithu0/command-center`.

- Slice 11 (Terminal Orchestrator) lar command-center dispatche kommandoer til paner gjennom en approval-gate. Hver pane kjører en `firm-inbox-watch.sh` background-watcher som viser en banner når arbeid blir dispatchet til inbox-en dens.
- **Du har ikke tilgang til command-center-repoet ennå.** Hvis du vil kjøre det selv, må operator gi deg GitHub-tilgang. Firm-launcheren krever det ikke — du kan kjøre hele firm-en uten command-center.

## Automated for you (ikke tenk på det)

- Brain pull + sanity check ved hver firm-pane boot
- Pre-push hook blokkerer dårlige pushes
- CI på hver PR
- `firm-inbox-watch.sh` surfacer dispatch-banner i hver pane

## Set opp Linux Obsidian + auto-sync

Obsidian må kjøre INNI WSL (ikke Windows-versjonen) for å snakke direkte med vault-mappa i Linux-filsystemet.

```bash
# Hvis du ikke alt har gjort dette via bootstrap:
bash ~/Obsidian/Brain/scripts/check-wslg.sh         # verifiserer GUI-støtte
bash ~/Obsidian/Brain/scripts/install-obsidian-linux.sh
```

Når Obsidian er installert:

```bash
bash ~/Obsidian/Brain/scripts/launch-obsidian.sh
```

Første gang:
1. "Open folder as vault" → velg `~/Obsidian/Brain`
2. Trust author + Enable plugins når den spør
3. Settings → Community plugins → Browse → installer "Obsidian Git" by Vinzent03 → Enable
4. Restart Obsidian én gang
5. Plugin config ligger i `.obsidian/plugins/obsidian-git/data.json`: auto-pull/commit 2 min, auto-push 5 min, pull før push.

Når plugin'en kjører ser du grønn status i Obsidian status bar.

## Read first (i rekkefølge)

1. `WELCOME.md` — repo intro
2. `BRAIN-RULES.md` — edit-grenser
3. `TEAMMATE-ONBOARDING.md` — fuller onboarding
4. `00-firm-bus/README.md` — full firm-bus-protokoll
5. `claude-context/START-HERE.md` — for Claude i alle paner
6. `01-nexus/Nexus-MOC.md` — Nexus map
7. `_runbooks/Runbook-Karri-Proposal-Send.md` — din proposal flow

## You can edit freely

- `01-nexus/**`
- `00-claude-inbox/nexus/**`
- `_promote-candidates/**`
- `00-firm-bus/inbox/<your-role>.md`
- Du er på **bypass-list** for branch protection — push direkte til main hvis du må, men PR er greit.

## NEVER edit uten operator OK

- `_decisions/`, `_maps/`, `claude-context/`, `.github/`, `scripts/`, root rule files
- Path-guard CI flagger uansett — bruk `OPERATOR-APPROVED: <reason>` i PR body hvis Nithu har OK'd.

## Stuck?

Ping Nithu, eller åpne issue med `operator-decision` template.

## Det vi prøver å oppnå

Operator + jeg = to fysiske maskiner som føles som én via samme GitHub (skeleton), samme Obsidian-vault (brain, synca via Obsidian Git), og samme Claude-konto (engine). Når operator endrer en note i 01-nexus/, ser jeg det innen 2-5 min. Og omvendt.

Detaljer: [[SHARED-INSTANCE-MODEL]] + [[Runbook-Obsidian-Git-Sync]]. Med firm-en + auto-sync får jeg samme operasjonsbildet som operator — full kontekst på tvers av prosjektene, brain-en min er fersk hele tiden, og firm-bus holder panene koordinert uten kollisjon.

---

Sist oppdatert: 2026-05-21 — firm-launcher flyttet til `command-center/_bin/` (portable installer her i brain-en), command-center control plane lagt til, 8-pane-modell oppdatert (2 code, 2 ai, 1 thesis, 1 as, 1 soking, 1 personal). Previous: 2026-05-13.

Velkommen til hjernen. Si fra hvis noe ikke gir mening — det betyr at jeg skrev dårlig dokumentasjon. 🐯
