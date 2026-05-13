---
tags: [meta, welcome, teammate]
type: meta
created: 2026-05-13
updated: 2026-05-13
---

# Hei, og velkommen til Nithus brain

This is operator's second brain — a shared vault for Nexus (XAUUSD trading firm) and ops context. Glad you're here.

## First 60 seconds

```bash
git clone git@github.com:Nithu0/tiger-brain.git ~/Obsidian/Brain
cd ~/Obsidian/Brain
bash firm-launcher/install.sh    # installs firm + hooks + clones ai-assistent
source ~/.bashrc
firm                              # launches 8-tab Claude session
```

Karri: see [[KARRI-DAY-1]] for the 3-minute version.

Pre-push hook installs automatically. Brain checks run in firm tabs. No manual ritual — see `_runbooks/Runbook-Brain-Weekly-Maintenance.md` for details.

## Where to start reading

- `TEAMMATE-ONBOARDING.md` — your day-1 guide
- `BRAIN-RULES.md` — what you can touch, what's off-limits
- `claude-context/START-HERE.md` — if you're using Claude here
- `01-nexus/Nexus-MOC.md` — main project (XAUUSD trading firm)

## Three things to remember

- Aldri push direkte til `main` — alltid PR
- Hold deg i `01-nexus/**` og `00-claude-inbox/nexus/**` (CODEOWNERS sjekker resten)
- `bash scripts/sanity.sh` før hver push (lokal CI-ekvivalent)

## Stuck?

Open an issue with the `operator-decision` template; ping operator on the usual channel.

Glad to have you here. 🐯
