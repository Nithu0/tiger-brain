---
tags: [meta, onboarding, karri]
type: meta
created: 2026-05-13
---

# Karri — Day 1 (3 min)

Hei Karri. Paste this block, du er i gang.

```bash
# 1. Clone the brain (assumes you have SSH access)
git clone git@github.com:Nithu0/tiger-brain.git ~/Obsidian/Brain
cd ~/Obsidian/Brain

# 2. Run installer — it'll ask for your name, email, and roster preference
bash firm-launcher/install.sh
# (when prompted for roster, pick "2" for nexus-only — 8 nexus panes)

# 3. Reload shell
source ~/.bashrc

# 4. Launch
firm   # opens 8 Claude-paner in WT split, all Nexus
```

## Hva install.sh spør om

- **Name**: Ditt navn (settes som git author på commits — viktig siden du er logget inn som Nithu0)
- **Email**: Din mail (samme grunn)
- **Roster**: Velg `2) nexus` for 8 nexus-paner. Hopp ikke over.

Hver pane booter Claude med rolle-context. Banner: `Nexus shell ready | commands: firm-status | firm-talk | wake ...`.

## Automated for you (ikke tenk på det)

- Brain pull + sanity check on every firm tab boot
- Pre-push hook blocks bad pushes
- CI on every PR

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
3. `claude-context/START-HERE.md` — for Claude i alle taber
4. `01-nexus/Nexus-MOC.md` — Nexus map
5. `_runbooks/Runbook-Karri-Proposal-Send.md` — din proposal flow

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

Detaljer: [[SHARED-INSTANCE-MODEL]] + [[Runbook-Obsidian-Git-Sync]]. Med 8 nexus-paner + auto-sync får jeg det same operasjonsbildet som operator — full Nexus-kontekst, brain-en min er fersk hele tiden.

---

Velkommen til hjernen. Si fra hvis noe ikke gir mening — det betyr at jeg skrev dårlig dokumentasjon. 🐯
