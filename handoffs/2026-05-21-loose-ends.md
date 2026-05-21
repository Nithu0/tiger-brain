---
type: handoff
tags: [handoff, loose-ends, open-items, infra, git, risk]
created: 2026-05-21
last_updated: 2026-05-21
project: workspace
owner: "Claude (Opus 4.7 1M)"
session: loose-ends tracking — 2026-05-21
status: OPEN — items below are unresolved and need operator attention
next: operator decision on workspace _bin version control; peer panes commit/push their dirty work
related:
  - "[[2026-05-21-command-center-version-control]]"
---

# 2026-05-21 — loose ends / things at risk of being forgotten

Operator explicitly said it feels like things keep getting forgotten. This
note exists so they do not. Every item below is **OPEN** as of 2026-05-21.

---

## 1. `/home/nithu/code` workspace is NOT a git repo

The workspace root has no version control. That means these files are tracked
**nowhere**:

- `_bin/` firm-launcher scripts — `firm-tab-init.sh`, `firm-wt-split.sh`,
  `firm-wt-tabs.sh`, `firm-statusline.sh`, `firm-zellij.sh`, etc.
- The workspace `CLAUDE.md`.

**Consequence:** the firm-launcher statusline bugfix made this session
(`firm-tab-init.sh`) currently exists only on local disk. One bad `rm` or disk
loss and it is gone.

**Needs an operator decision.** Options, with the trade-off flagged honestly:

- **Dedicated `_bin` (or `_workspace-meta`) repo** — clean, but one more repo
  to track.
- **Fold `_bin` + workspace `CLAUDE.md` into command-center** — fewer repos,
  but couples workspace tooling to the control-plane project.
- **`git init` at `/home/nithu/code` itself** — would nest a git repo *over*
  the 8 existing project sub-repos. This is messy: sub-repos become embedded
  repos / accidental submodules, `git status` at root is noisy, and there is
  real risk of accidentally committing project trees. **Not recommended
  blindly** — flagged here as the trade-off, operator decides.

Status: **OPEN — awaiting operator decision.**

---

## 2. Peer repos have uncommitted / unpushed work

Dirty trees and unpushed commits in repos owned by other firm panes:

| Repo | State | Owning pane |
|---|---|---|
| Master-oppgave | 18 dirty files | thesis-1 |
| research-os | 3 dirty files | (research) |
| Søking fulltid | 6 dirty files | soking-1 |
| ai-assistent | 5 commits unpushed | ai-1 |

These belong to other firm panes, not this session. **Flagged to them via the
firm-bus inbox**, but they remain uncommitted/unpushed at the time of writing.

Status: **OPEN — handed off to peer panes; not yet confirmed resolved.**

---

## 3. brain_audit `__pycache__` loop

Running `brain_audit.py` creates `scripts/__pycache__/`. The audit's own
`big_generated_folders` check then flags that `__pycache__` as an error — so
the audit can never stay green: running it breaks it.

Status: **fix in progress 2026-05-21.**

---

Sist oppdatert: 2026-05-21.
