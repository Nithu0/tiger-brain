---
type: prompt
tags: [prompt, nexus]
created: 2026-05-11
---

# Nexus worker prompt — restrict Claude to Nexus paths only

## Purpose

When working on Nexus (XAUUSD trading firm) content or notes inside the Brain
vault, lock Claude into the Nexus subtree. This prevents cross-project
pollution into thesis/business/career/learning folders, and protects the
shared rule/decision/map files from accidental edits.

Use this at the **start of any Nexus-focused session** — paste it as your
first message to Claude in the vault directory, before any real work begins.

## The prompt (copy-paste below into Claude Code from the vault root)

```text
You are working on Nexus (XAUUSD trading firm) inside the Obsidian Brain
vault. Treat the following as binding scope rules for this entire session.

READ permissions:
  - You MAY read the ENTIRE vault for context. Read-only access anywhere
    is fine, including other projects, _decisions/, _maps/, claude-context/.

WRITE / EDIT permissions:
  - You MAY write or edit ONLY these paths:
      * `01-nexus/**`
      * `00-claude-inbox/nexus/**`
      * `_promote-candidates/`  (only if the operator has explicitly
        approved promoting a specific note in THIS session)

WRITE PROHIBITIONS (do NOT touch, do NOT create files under):
  - `_decisions/`
  - `_maps/`
  - `claude-context/`
  - `.github/`
  - `scripts/`
  - root-level rule files (`BRAIN-RULES.md`, `CONTRIBUTING.md`, `README.md`,
    `00-DASHBOARD.md`, `01-CURRENT-FOCUS.md`)
  - any other project's folder: `02-thesis/`, `03-business/`, `04-career/`,
    `05-learning/`, `90-archive/`

SOURCE-OF-TRUTH for Nexus state:
  - Before writing anything Nexus-related, read
    `/home/nithu/code/ai-assistent/docs/ops/phase-status.md` first. That
    file is the authoritative current state of Nexus. The vault notes
    are derived/reflective views, not the source.

RULES that override everything else:
  - Foundation gate, OK-kjør gate, no auto-disable of strategies, no real
    trading actions — see [[BRAIN-RULES]] and [[claude-context/RULES]].
  - If you need to touch a protected path to complete a task, STOP and
    ask the operator. Do NOT work around it by renaming, copying, or
    placing equivalent content elsewhere.

BEFORE any commit:
  - Run `python scripts/brain_audit.py` and confirm it passes.
  - Run `python scripts/path_guard.py --base origin/main --head HEAD`
    and confirm no protected paths were touched.
  - If either fails, stop and report. Do not push.

END-OF-SESSION:
  - Write a handoff summary using
    `prompts/CLAUDE-HANDOFF-PROMPT.md` as the template.
  - Save it to `handoffs/<YYYY-MM-DD>-<slug>.md` and update
    `handoffs/CURRENT-HANDOFF.md` to point to it.

Confirm you understand by replying with: "Nexus scope locked.
Source-of-truth: phase-status.md. Will run brain_audit + path_guard
before any commit."
```

## When to use this prompt

- Start of any Nexus-focused vault session.
- Paste it **before** your first real message to Claude.
- If the session drifts off-Nexus, re-paste it to re-anchor.
- Do NOT use this for thesis, business, career, or learning work — those
  get their own scope prompts (TBD).

---

Sist oppdatert: 2026-05-11
