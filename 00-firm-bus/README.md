# 00-firm-bus — inter-terminal coordination

When `firm` launches 8 Windows Terminal tabs, each tab runs Claude in a project directory. This folder is their shared scratchpad, and it doubles as a **cross-machine presence layer** between operator and Karri (both have the brain repo cloned and synced via the Obsidian Git plugin every 2-5 min).

## Layout

| Tab | Project | Working dir |
|---|---|---|
| code-1, code-2 | workspace | `/home/nithu/code` (cross-project meta-work) |
| ai-1, ai-2, ai-3, ai-4 | nexus | `/home/nithu/code/ai-assistent` (XAUUSD trading firm) |
| thesis-1, thesis-2 | master-oppgave | `/home/nithu/code/Master-oppgave` (battery ML) |

Each tab exports `FIRM_ROLE` (e.g. `ai-2`), `FIRM_PROJECT` (e.g. `nexus`), and `FIRM_USER_TAG` (sanitized git user name) so Claude inside the tab can identify both itself AND which human operator's machine it's running on.

## Files

- `feed.md` — **append-only activity log**. Anyone writes, everyone reads. One line per event. Format `- <ISO-time> [<git-user>] <role> <verb>: <summary>`. Never edit old entries — append corrections.
- `inbox/<role>.md` — **per-role message destination**. Drop a markdown block in another tab's inbox to hand off work. Read by `firm-session-context.sh` on session start (shown with pending-message count).
- `PRESENCE.md` — **"who's online" snapshot**. Each firm-tab boot appends a row. Read the LAST row per `(user, role)` pair for current state; rows older than 2h are stale.
- `roster.md` — **configured roles**: who's typically running what. Updated manually when intent changes.

## Sync model

The brain repo is synced across operator's + Karri's machines by the **Obsidian Git plugin** with a 2-5 min auto-pull/auto-push interval. That means:

- Operator's firm tab writes to `feed.md` → Karri sees it within ~5 min.
- Karri's firm tab writes to `feed.md` → operator sees it within ~5 min.
- The `[<git-user>]` tag lets each side filter out its own entries to see "what the OTHER side did".

Latency is not zero — this is async coordination, not chat. For sub-minute sync use a real channel (Discord).

## Convention (read this first when a session starts)

1. **On session start** — your launcher already appended `<ISO-time> [<git-user>] <role> online in <project>` to `feed.md` and a row to `PRESENCE.md`.
2. **Before starting non-trivial work** — `tail -50 feed.md` to see what peer sessions touched, check `PRESENCE.md` for who's currently online, and read your own `inbox/<role>.md`. The `firm-session-context.sh` hook already surfaces the last 20 peer lines + your inbox at session start.
3. **When handing off** — write to peer's inbox:
   ```md
   ## YYYY-MM-DD HH:MMZ — from <your-role> [<your-git-user>]
   <what you did | what you need from them | which files | which commits>
   ```
4. **When done with a chunk** — append `<ISO-time> [<git-user>] <role> done: <one-line summary>` to `feed.md`.
5. **For cross-project knowledge** — drop a note in `~/Obsidian/Brain/00-claude-inbox/<project>/`. Don't write project-specific stuff into firm-bus; firm-bus is for coordination, not knowledge.

## Anti-patterns

- Don't dump full reports into `feed.md`. One-liners only. Long-form goes in `~/Obsidian/Brain/00-claude-inbox/`.
- Don't write to another tab's inbox if you're not handing off concrete work. No "FYI" spam.
- Don't claim a project file is "yours" — git is the source of truth, always check `git status` + `git log` before edits.
- Don't edit old `feed.md` or `PRESENCE.md` rows. Append-only. Corrections get a new row with a `note` verb.

## Updating

Each session is allowed to extend this README via direct edit. Don't delete sections; append a `## Update YYYY-MM-DD` block if a convention changes.

## Update 2026-05-13

- Added `[<git-user>]` tag to feed.md entries so operator and Karri can tell each other apart.
- Added `PRESENCE.md` as a live "who's here" snapshot.
- `firm-session-context.sh` now filters out own entries when showing recent feed activity, and surfaces inbox message count.
