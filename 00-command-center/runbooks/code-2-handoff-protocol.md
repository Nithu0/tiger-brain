---
tags: [command-center, runbook, firm-bus, handoff]
type: runbook
created: 2026-05-16
---

# code-2 handoff protocol

Convention for handing tasks between an active command-center work session and the `code-2` pane (per [[../../_runbooks/firm-8-pane-2026-05-14]]).

## Why

`code-2` is the workspace-wide pane — it owns command-center work by default. When another pane (`code-1`, `ai-1`, etc.) needs command-center to do something, it goes through the firm-bus inbox, not direct edits.

## Outgoing — handing TO code-2

Write to `~/Obsidian/Brain/00-firm-bus/inbox/code-2.md`:

```markdown
## 2026-05-16 14:30 from <role>

<one-line ask>

<optional 2-3 lines of context>

Repro / next step: <command or file>
```

Append, don't overwrite. The receiving pane scans for new sections on its next loop.

## Incoming — code-2 picks up

1. On session start (or every loop): `cat ~/Obsidian/Brain/00-firm-bus/inbox/code-2.md`.
2. Process top-to-bottom; mark done by moving the section to `.archive/` or deleting after handling.
3. Log one-liner to `~/Obsidian/Brain/00-firm-bus/feed.md` on chunk complete:

```
2026-05-16T14:55:00 code-2 done: <one-line>
```

## Long reports

Never dump multi-page output to `feed.md`. Put it in `~/Obsidian/Brain/00-claude-inbox/command-center/<date>-<slug>.md` and reference the path in `feed.md`.

## When NOT to use this

- Trivial single-pane work — just do it.
- Anything trading-specific — goes to `ai-1`/`ai-2` inbox, not `code-2`.
- Brain-vault edits outside operator-owned paths — handle directly per [[../../BRAIN-RULES]].
