# SessionStart hook: firm-launched session awareness

**Date**: 2026-05-13
**Author**: ai-N (parallel-build agent)
**Scope**: `~/.claude/settings.json` — add a second SessionStart hook entry
**Status**: Proposed (operator approves settings.json edits)

---

## Goal

When a Claude session is launched from a firm tab (via `firm-tab-init.sh`,
which exports `FIRM_ROLE` / `FIRM_PROJECT` / `FIRM_TAB_OPENED_AT`), the
in-tab Claude should automatically see:

1. A `### firm-launched session` header with its role/project/opened-at.
2. The last 30 lines of `~/Obsidian/Brain/00-firm-bus/feed.md`.
3. The contents of `~/Obsidian/Brain/00-firm-bus/inbox/$FIRM_ROLE.md`
   if the file exists and is non-empty.

Non-firm sessions (no `FIRM_ROLE` exported) must be completely unaffected —
the hook exits 0 with zero output.

---

## Why a separate hook (not modifying the existing one)

`~/.claude/settings.json` already has one `SessionStart` hook entry that
runs `/home/nithu/code/ai-assistent/scripts/hooks/session-start.sh`. That
script is Nexus-repo-specific (cd's to `ai-assistent`, prints phase-status,
operator decisions, etc.) — it runs in EVERY session regardless of FIRM_ROLE.

The firm-launched-session block is orthogonal:
- It runs in tabs for all three projects (nexus, workspace, master-oppgave),
  not just nexus.
- It needs `FIRM_ROLE` from the parent shell — that env var is already
  exported by `firm-tab-init.sh` before `exec claude` runs.

Keeping it as a second array entry under the same `matcher: ""` block is
the cleanest non-destructive merge.

---

## The script

Path: `/home/nithu/code/_bin/firm-session-context.sh` (already written + chmod +x +
`bash -n` clean). Verified behavior:

- With `FIRM_ROLE=ai-2 FIRM_PROJECT=nexus FIRM_TAB_OPENED_AT=...` set:
  prints the role header, tails feed.md (30 lines), prints inbox if non-empty.
- With `FIRM_ROLE` unset: exits 0 with no output.

Script contents (for reference — file is canonical):

```bash
#!/usr/bin/env bash
# firm-session-context.sh — SessionStart hook for firm-launched Claude tabs.
#
# Emits a short context block telling the in-tab Claude its role, the recent
# firm-bus feed, and any pending inbox items. Skips silently when FIRM_ROLE
# is unset so non-firm sessions are untouched.
#
# Wired into ~/.claude/settings.json under hooks.SessionStart. Output is
# captured by Claude Code and surfaced as additional SessionStart context.
#
# SAFETY:
#   - Read-only. Never edits feed.md, inbox, or any settings.
#   - Hard caps total output to MAX_CHARS to protect context budget.
#   - Never reads .env / secrets.

set -u
# no `set -e`: a missing optional file must not abort the dump.

# Silent skip for non-firm sessions.
if [ -z "${FIRM_ROLE:-}" ]; then
  exit 0
fi

BUS_DIR="$HOME/Obsidian/Brain/00-firm-bus"
FEED_FILE="$BUS_DIR/feed.md"
INBOX_FILE="$BUS_DIR/inbox/${FIRM_ROLE}.md"
MAX_CHARS=4000

main_dump() {
  echo "### firm-launched session"
  echo "Role: ${FIRM_ROLE} | Project: ${FIRM_PROJECT:-unknown} | Opened: ${FIRM_TAB_OPENED_AT:-unknown}"
  echo

  echo "### recent firm-bus feed (last 30 lines)"
  if [ -r "$FEED_FILE" ]; then
    tail -n 30 "$FEED_FILE"
  else
    echo "(no feed.md at $FEED_FILE)"
  fi
  echo

  if [ -r "$INBOX_FILE" ] && [ -s "$INBOX_FILE" ]; then
    echo "### your inbox"
    cat "$INBOX_FILE"
    echo
  fi
}

RAW=$(main_dump 2>/dev/null)
if [ "${#RAW}" -gt "$MAX_CHARS" ]; then
  printf '%s' "$RAW" | head -c "$MAX_CHARS"
  printf '\n... (output truncated at %d chars)\n' "$MAX_CHARS"
else
  printf '%s\n' "$RAW"
fi

exit 0
```

---

## JSON snippet to merge into `~/.claude/settings.json`

### Current state (relevant slice only)

```jsonc
"hooks": {
  "SessionStart": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "[ -x /home/nithu/code/ai-assistent/scripts/hooks/session-start.sh ] && /home/nithu/code/ai-assistent/scripts/hooks/session-start.sh 2>>/tmp/nexus-session-start.log; exit 0",
          "timeout": 5
        }
      ]
    }
  ],
  ...
}
```

### Proposed state — add a second entry to the existing `hooks` array

```jsonc
"hooks": {
  "SessionStart": [
    {
      "matcher": "",
      "hooks": [
        {
          "type": "command",
          "command": "[ -x /home/nithu/code/ai-assistent/scripts/hooks/session-start.sh ] && /home/nithu/code/ai-assistent/scripts/hooks/session-start.sh 2>>/tmp/nexus-session-start.log; exit 0",
          "timeout": 5
        },
        {
          "type": "command",
          "command": "[ -x /home/nithu/code/_bin/firm-session-context.sh ] && /home/nithu/code/_bin/firm-session-context.sh 2>>/tmp/firm-session-context.log; exit 0",
          "timeout": 5
        }
      ]
    }
  ],
  ...
}
```

### The exact diff (one comma + one object)

Add the following object as the **second element** of
`hooks.SessionStart[0].hooks` (insert a comma after the existing entry):

```json
{
  "type": "command",
  "command": "[ -x /home/nithu/code/_bin/firm-session-context.sh ] && /home/nithu/code/_bin/firm-session-context.sh 2>>/tmp/firm-session-context.log; exit 0",
  "timeout": 5
}
```

---

## Why this is safe

- **Idempotent / non-destructive**: doesn't touch the existing
  `session-start.sh` hook; both run in sequence.
- **Silent for non-firm sessions**: `FIRM_ROLE` unset → script exits 0 with
  no stdout → Claude sees no extra SessionStart context.
- **Read-only**: script only `tail`s feed.md and `cat`s inbox; never writes.
- **No secret exposure**: doesn't touch `.env*`, only `~/Obsidian/Brain/00-firm-bus/*`.
- **Bounded output**: `MAX_CHARS=4000` hard cap protects context budget.
- **Errors swallowed**: `2>>/tmp/firm-session-context.log; exit 0` mirrors
  the existing entry's pattern — a broken hook can never block a session.
- **Timeout 5s**: matches existing entry; `tail`/`cat` on small files is
  well under that.

---

## Verification performed

1. `bash -n /home/nithu/code/_bin/firm-session-context.sh` → syntax OK.
2. Smoke run with `FIRM_ROLE=ai-2 FIRM_PROJECT=nexus FIRM_TAB_OPENED_AT=...` →
   produced the expected three-section output (header / feed tail / inbox skipped because empty).
3. Smoke run with no env vars → zero output, exit 0.

---

## Apply procedure (for operator)

1. Open `~/.claude/settings.json`.
2. Inside `hooks.SessionStart[0].hooks`, after the existing object, add a
   comma and the JSON object shown above.
3. Save. New Claude sessions in firm tabs will pick up the hook
   immediately (existing sessions are not affected until restart).
4. To roll back: remove the appended object + trailing comma. 30-second
   revert, no code touched.

---

## Future-proofing notes

- If `firm-tab-init.sh` ever exports additional `FIRM_*` variables (e.g.
  `FIRM_SESSION_ID`, `FIRM_PEER_LIST`), extend `main_dump()` in
  `firm-session-context.sh` — no settings.json change needed.
- If the operator wants the hook to run only in tabs (not in all sessions
  with `FIRM_ROLE` set somehow externally), the script could additionally
  check `[ -n "$FIRM_TAB_OPENED_AT" ]` before printing — currently treated
  as best-effort.
