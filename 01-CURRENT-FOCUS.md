---
tags: [focus, meta, status]
type: meta
created: 2026-05-11
---

# 01-CURRENT-FOCUS

What operator is actually working on **right now**. One file. Keep it honest.

> When this drifts, fix it in this file — don't scatter status across notes.

## Primary focus

**Nexus — calibration phase, foundation gate 5/5 🟢.**

- System is demo-mode. Live-capital flip is operator-gated and depends on the foundation gate staying green.
- Foundation gate is currently **5/5 🟢** per `phase-status.md` (2026-05-11).
- Calibration run + verification must pass before any "OK kjør" on the flip.
- Live truth: `ai-assistent/docs/ops/phase-status.md` (mirror: [[01-nexus/runtime/Phase-Status-Pointer]]).
- Related: [[Nexus-MOC]], [[Decisions-MOC]] for recent gate decisions.

## Secondary

**Master-oppgave — chapters in flight.**

- Active drafting in `Master-oppgave/` (LaTeX/Overleaf), with code/results from `battery-electrolyte-predictor/`.
- Auto-push hook is active for the thesis repo only — see `reference_autopush.md` (in ~/.claude/projects/.../memory/).
- MOC: [[Thesis-MOC]].

## Aktive prosjekt-tråder (6)

Én-linjers status per prosjekt. Detalj i hver MOC.

| Prosjekt | Tråd nå | Eier-pane |
|---|---|---|
| Nexus | Calibration + foundation-gate watch; ingen live-flip uten "OK kjør" | `ai-1`, `ai-2` |
| Master-oppgave | Kapittel-drafting + figur-pipeline fra battery-repo | `thesis-1` |
| Søking fulltid | Aktiv scrape + søknader (career-agent eier flyt) | `soking-1` |
| Business / strategi | Lett vedlikehold, ikke push | *(deles av ops-paner)* |
| AS | Regnskap + inntekt-oppfølging (AS-agent eier) | `as-1` |
| Personlig | Effektivitet/mat/trening (personlig-agent eier) | `personal-1` |

Workspace-meta (cross-cutting fixes, brain hygiene, runbooks) ligger på `code-1` + `code-2`.

## 8-pane multi-Claude operating model

Operatør kjører nå én Windows Terminal-tab med 8 paner, alle på `claude --dangerously-skip-permissions`. Start med `firm` (alias) eller `bash /home/nithu/code/_bin/firm-wt-split.sh`.

### Layout

| Pane | Rolle (`FIRM_ROLE`) | Prosjekt (`FIRM_PROJECT`) | cwd | Farge |
|---|---|---|---|---|
| 1 | `code-1` | workspace | `~/code` | grå |
| 2 | `code-2` | workspace | `~/code` | grå |
| 3 | `ai-1` | nexus | `~/code/ai-assistent` | gul |
| 4 | `ai-2` | nexus | `~/code/ai-assistent` | gul |
| 5 | `thesis-1` | master | `~/code/Master-oppgave` | grønn |
| 6 | `as-1` | AS | `~/code/AS` | blå |
| 7 | `soking-1` | soking-fulltid | `~/code/soking-fulltid` | lilla |
| 8 | `personal-1` | personlig | `~/code/personlig` | rosa |

Fargen settes i `nexus-bashrc.sh` via PS1 (rolle-bracket foran prompten — `[ai-1] ❯`).

### Hva hver pane forventes å gjøre

- **code-1, code-2** — workspace-meta: cross-repo refactor, brain hygiene, runbook-arbeid, dispatcher for parallelle subagents.
- **ai-1, ai-2** — Nexus-arbeid. ai-1: phase-status + calibration; ai-2: review av audit-noter, gate-decisions, strategi-proposals.
- **thesis-1** — master-oppgave kapittel-drafting + figurer fra battery-repo.
- **as-1** — AS regnskap, inntekt, fakturering (egen agent-rolle).
- **soking-1** — jobb-scrape, søknader, intervju-prep (career-agent rolle).
- **personal-1** — effektivitet/mat/trening (personlig-agent rolle).

### Koordinering

- Felles buss: `~/Obsidian/Brain/00-firm-bus/feed.md` (en-linjers `done: ...`-meldinger ved chunk-slutt).
- Per-pane inbox: `~/Obsidian/Brain/00-firm-bus/inbox/<role>.md`. Skriv hit ved handoff til en annen rolle.
- Lange rapporter → `~/Obsidian/Brain/00-claude-inbox/<project>/`, aldri i `feed.md`.
- Day-end handoffs → `~/Obsidian/Brain/handoffs/`.

Full runbook: [[_runbooks/firm-8-pane-2026-05-14]].

## Parked / not now

- Business/Career-notater (utenom de som eies av soking-agent) — light maintenance only, no active push.
- Learning backlog — capture in inbox, don't promote unless directly relevant to primary/secondary.
- Any vault restructuring — needs explicit operator go-ahead (see [[BRAIN-RULES]]).
- 16-pane / Conductor-utvidelse — se `_decisions/2026-05-14-16-pane-codex-parallell.md` for vurdering.

## Active TODOs

1. **Operator**: create github.com/Nithu0/tiger-brain (private) → `bash scripts/push-and-protect.sh` → rotate Obsidian REST API key. After: tell teammate to clone.
2. Foundation-gate calibration: run + verify, log outcome in `_decisions/` once decided.
3. Phase-status pointer accuracy: confirm [[01-nexus/runtime/Phase-Status-Pointer]] reflects the repo's `phase-status.md`.
4. Master-oppgave: continue chapter drafting; promote relevant inbox notes into `Master-oppgave/`.
5. Inbox triage: walk [[00-claude-inbox/README|inbox]] once this week, promote or archive.
6. Decisions log: ensure any gate-state change lands in `_decisions/` with date + rationale.
7. Dry-run `firm` med ny 8-pane-layout og verifiser at alle 6 prosjekt-paner ankommer riktig cwd.

## Working-tree note

- 30 modified files in working tree still pending operator review (unrelated to the `feat/brain-hardening` branch). Decide commit-or-discard before next push.

---

Sist oppdatert: 2026-05-14
