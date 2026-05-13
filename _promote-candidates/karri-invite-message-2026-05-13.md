---
tags: [meta, karri, message]
type: draft
created: 2026-05-13
updated: 2026-05-13
status: ready-to-send
---

## 1. Message (copy-paste literally)

````text
Hei Karri,

Har laga en delt brain-repo med hele firm-oppsettet pakka inn — du får samme launcher + brain-hooks som meg på én kommando.

Du er nå collaborator på `Nithu0/tiger-brain`. Det inneholder:
- Hele Obsidian-vaulten (MOCs, decisions, runbooks, claude-context for Claude)
- 00-firm-bus/ — multi-tab coordination (din inbox: 00-firm-bus/inbox/<din-rolle>.md)
- firm-launcher/ — installer for firm-kommandoen
- _library/trading/karri_quotes_corpus.md + karri_mental_model.md (din pensum)

3-minutters setup:

Når installer'n spør om FIRM_ROSTER, velg `2` (nexus-only — 8 nexus-paner). Den setter også git config så dine commits viser deg som author, ikke meg.

```bash
git clone git@github.com:Nithu0/tiger-brain.git ~/Obsidian/Brain
cd ~/Obsidian/Brain
bash firm-launcher/install.sh
# answer the prompts (name, email, roster=2 for nexus-only)
source ~/.bashrc
firm
```

Etter setup:
- `firm` åpner 8 Claude-paner (2 workspace, 4 nexus, 2 thesis)
- Pre-push hook + brain-sanity kjører automatisk
- Du står på bypass-listen for branch protection — kan pushe direkte til main, men PR gir bedre review

Først å lese:
1. `KARRI-DAY-1.md` (vault root) — kort cheat sheet
2. `BRAIN-RULES.md` — hva som er fritt vs no-touch
3. `_runbooks/Runbook-Karri-Proposal-Send.md` — proposal-flowen din

Si fra hvis noe ikke fungerer eller dokumentasjonen er rar.

— Nithu
````

## 2. Pre-send checklist

- [ ] Karri har SSH-key på maskinen sin som funker mot Nithu0 GitHub-konto
- [ ] Tigger-brain pushed to origin (already done)
- [ ] Send meldingen

## 3. If Karri reports issues

- "firm: command not found" → he didn't reload shell. Tell him `source ~/.bashrc`
- "wt.exe not found" → he's on Linux/macOS without WT. Use `firmz` (zellij fallback)
- "pre-push hook fails" → run `bash scripts/sanity.sh` to see why
- "Path-guard blocks my PR → siden du er på Nithu0-kontoen kan du i prinsippet pushe direkte til main, men bedre å lage PR + svar `OPERATOR-APPROVED: <reason>` hvis du må røre protected paths."

Sist oppdatert: 2026-05-13
