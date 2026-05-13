# 00-firm-bus — inter-terminal coordination

When `firm` launches 8 Windows Terminal tabs, each tab runs Claude in a project directory. This folder is their shared scratchpad.

## Layout

| Tab | Project | Working dir |
|---|---|---|
| code-1, code-2 | workspace | `/home/nithu/code` (cross-project meta-work) |
| ai-1, ai-2, ai-3, ai-4 | nexus | `/home/nithu/code/ai-assistent` (XAUUSD trading firm) |
| thesis-1, thesis-2 | master-oppgave | `/home/nithu/code/Master-oppgave` (battery ML) |

Each tab exports `FIRM_ROLE` (e.g. `ai-2`) and `FIRM_PROJECT` (e.g. `nexus`) so Claude inside the tab can identify itself.

## Files

- `feed.md` — append-only event log. Anyone writes, everyone reads. One line per event.
- `roster.md` — who's typically running what; updated manually when intent changes.
- `inbox/<role>.md` — peer mailboxes. Drop a markdown block in another tab's inbox to hand off work.

## Convention (read this first when a session starts)

1. **On session start** — your launcher already appended `<ISO-time> <role> online in <project>` to `feed.md`.
2. **Before starting non-trivial work** — `tail -50 feed.md` to see what peer sessions touched, and read your own `inbox/<role>.md`.
3. **When handing off** — write to peer's inbox:
   ```md
   ## YYYY-MM-DD HH:MMZ — from <your-role>
   <what you did | what you need from them | which files | which commits>
   ```
4. **When done with a chunk** — append `<ISO-time> <role> done: <one-line summary>` to `feed.md`.
5. **For cross-project knowledge** — drop a note in `~/Obsidian/Brain/00-claude-inbox/<project>/`. Don't write project-specific stuff into firm-bus; firm-bus is for coordination, not knowledge.

## Anti-patterns

- Don't dump full reports into `feed.md`. One-liners only. Long-form goes in `~/Obsidian/Brain/00-claude-inbox/`.
- Don't write to another tab's inbox if you're not handing off concrete work. No "FYI" spam.
- Don't claim a project file is "yours" — git is the source of truth, always check `git status` + `git log` before edits.

## Updating

Each session is allowed to extend this README via direct edit. Don't delete sections; append a `## Update YYYY-MM-DD` block if a convention changes.
