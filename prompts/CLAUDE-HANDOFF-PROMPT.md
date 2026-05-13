---
type: prompt
tags: [prompt, handoff]
created: 2026-05-11
---

# Handoff prompt — write a clean session summary

## Purpose

At the end of a working session, produce a handoff doc that the next-Claude
(or the operator, or a teammate) can pick up cold without context loss. A
good handoff is the difference between "5 minutes to resume" and "30 minutes
of re-reading scrollback".

Use this prompt **at the end of every non-trivial session** — Nexus, thesis,
or any project. Pair it with the Nexus worker prompt when relevant.

## The prompt (copy-paste below into Claude Code)

```text
Produce a handoff document for this session. Output it as a single
markdown file with the following sections, in this order, using these
exact headings. Be terse and concrete. No filler.

---
type: handoff
tags: [handoff, <project-tag>]
created: <YYYY-MM-DD>
owner: <claude session id or operator or teammate name>
status: <in-progress | done | blocked | needs-decision>
---

# Handoff — <one-line title>

## Owner
Who was working this session. If Claude: include session id or short
descriptor. If operator/teammate: name.

## Status
One of: in-progress | done | blocked | needs-decision. One sentence
explaining why.

## Next action
ONE sentence. Actionable. Starts with a verb. The thing the next
person should do first.

## What was done
Bullets. For each, include the absolute file path and line refs where
possible (e.g. `/home/nithu/Obsidian/Brain/01-nexus/foo.md:42-58`).

## What was NOT done and why
Bullets. Be honest about what got skipped, deferred, or hit a wall.
Include the "why" — time, scope, blocker, operator decision pending.

## Open questions
Numbered list. For each, suggest a resolution path (who decides, what
info is needed, what the default is if nobody answers).

## Files to read first to continue
3-5 absolute paths, ordered by importance. Include line ranges if a
file is long. The next person should be productive after reading these.

## State pointers
- Live source-of-truth: <e.g. /home/nithu/code/ai-assistent/docs/ops/phase-status.md>
- Latest commit SHA on working branch: <sha>
- Branch name: <branch>
- Any external state: <links, ticket ids, etc.>

End of handoff.
```

## Save it to

- Path: `handoffs/<YYYY-MM-DD>-<slug>.md`
  - `<slug>` = 2-5 kebab-case words describing the session
  - Examples: `2026-05-11-nexus-phase-3-gate.md`,
    `2026-05-11-thesis-electrolyte-features.md`
- Then update `handoffs/CURRENT-HANDOFF.md` to point to the new file
  (replace its body with a single wikilink + the one-sentence "Next action"
  from above, so the dashboard surfaces it).

## Then commit on a branch

- Do NOT push directly to `main`.
- Create a branch like `handoff/<YYYY-MM-DD>-<slug>` if not already on
  a feature branch.
- Run `python scripts/brain_audit.py` and `python scripts/path_guard.py`
  before committing.
- Operator does the merge to `main` after review (OK-kjør gate).

---

Sist oppdatert: 2026-05-11
