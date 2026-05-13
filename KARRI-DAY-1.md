---
tags: [meta, onboarding, karri]
type: meta
created: 2026-05-13
---

# Karri — Day 1 (3 min)

Hei Karri. Paste this block, du er i gang.

```bash
git clone git@github.com:Nithu0/tiger-brain.git ~/Obsidian/Brain
cd ~/Obsidian/Brain
bash firm-launcher/install.sh
source ~/.bashrc
which firm   # should print a path
```

## First run

```bash
firm   # 8-pane WT split: 2 workspace, 4 nexus, 2 thesis
```

Hver pane booter Claude med rolle-context. Banner: `Nexus shell ready | commands: firm-status | firm-talk | wake ...`.

## Automated for you (ikke tenk på det)

- Brain pull + sanity check on every firm tab boot
- Pre-push hook blocks bad pushes
- CI on every PR

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

---

Velkommen til hjernen. Si fra hvis noe ikke gir mening — det betyr at jeg skrev dårlig dokumentasjon. 🐯
