---
tags: [meta, karri, message]
type: draft
created: 2026-05-13
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

```bash
git clone git@github.com:Nithu0/tiger-brain.git ~/Obsidian/Brain
cd ~/Obsidian/Brain
bash firm-launcher/install.sh
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

- [ ] Karri er lagt til som Write collaborator på `Nithu0/tiger-brain` (https://github.com/Nithu0/tiger-brain/settings/access)
- [ ] Karri sitt GH-handle er lagt til på bypass list på `main-protection` ruleset
- [ ] CODEOWNERS oppdatert: `sed -i 's/@TEAMMATE/@<karri-handle>/g' .github/CODEOWNERS` + commit + push
- [ ] Karri har SSH-key uploaded til GitHub
- [ ] Send meldingen via Discord/Slack/email

## 3. If Karri reports issues

- "firm: command not found" → he didn't reload shell. Tell him `source ~/.bashrc`
- "wt.exe not found" → he's on Linux/macOS without WT. Use `firmz` (zellij fallback)
- "pre-push hook fails" → run `bash scripts/sanity.sh` to see why
- "Path-guard blocks my PR" → he edited a protected path. Either move edits to allowed zone, or operator adds `OPERATOR-APPROVED: <reason>` to PR body

Sist oppdatert: 2026-05-13
