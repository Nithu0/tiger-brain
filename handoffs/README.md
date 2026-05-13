---
type: readme
tags: [handoff, meta]
created: 2026-05-11
---

# handoffs/ — session continuity

This folder holds session-handoff documents. Each one is a self-contained
snapshot that lets the next Claude session (or the operator, or a teammate)
pick up cold without context loss.

## Convention

- One file per session: `<YYYY-MM-DD>-<slug>.md`
  - `<slug>` is 2-5 kebab-case words (project + topic).
  - Example: `2026-05-11-nexus-phase-3-gate.md`
- `CURRENT-HANDOFF.md` always points to the most-recent active handoff.
  Update it at the end of every session.
- Use the template in `prompts/CLAUDE-HANDOFF-PROMPT.md` to write the doc.

## Lifecycle

- Active → linked from `CURRENT-HANDOFF.md`.
- Superseded → leave the file in place; `CURRENT-HANDOFF.md` advances.
- Stale (>30 days, project done) → move to `90-archive/handoffs/`.

## Rule

Do not delete handoffs. They are the audit trail of who-did-what-when.

---

Sist oppdatert: 2026-05-11
