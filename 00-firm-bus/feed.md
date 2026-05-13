# firm-bus feed

Append-only. Newest at bottom. One line per event. Use ISO-8601 UTC (the `Z`
suffix is required so machines in different timezones agree on ordering).

Format: `- <ISO-time> [<git-user>] <role> <verb>: <summary>`

- `<git-user>` identifies WHICH MACHINE wrote the entry — from `$FIRM_USER`
  or `git config user.name` in the brain repo. This is how operator and
  Karri tell each other apart in the same feed.
- `<role>` is the firm-tab role (e.g. `ai-2`, `code-1`, `thesis-1`).
- Verbs: `online | offline | handoff-to:<role> | done | blocked | note`

NEVER edit old entries — append a new line with a correction note instead.

Older entries (pre-2026-05-13) are missing the `[<git-user>]` tag; that's
expected and they stay as-is.

---

- 2026-05-13T06:50:00Z bootstrap firm-bus created by ai-1 (initial setup commit)
- 2026-05-13T07:02:19Z firm.sh launched (8 tabs)
- 2026-05-13T07:23:18Z ai-1 note: firm launcher failed twice (1) heredoc→wt newline split→0x80070002, (2) single-quoted inner cmd→bash treats path as one word→exit 127. Both diagnosed + fixed; firm-wt-split.sh + firm-wt-tabs.sh now pass UNQUOTED inner cmd. See _runbooks/firm-launcher.md and 00-claude-inbox/nexus/2026-05-13_firm-launch-failure-diagnosis-2.md.
- 2026-05-13T07:26:26Z code-1 online in workspace
- 2026-05-13T07:26:26Z ai-2 online in nexus
- 2026-05-13T07:26:26Z code-2 online in workspace
- 2026-05-13T07:26:26Z ai-1 online in nexus
- 2026-05-13T07:26:26Z ai-3 online in nexus
- 2026-05-13T07:26:27Z ai-4 online in nexus
- 2026-05-13T07:26:27Z thesis-1 online in master-oppgave
- 2026-05-13T07:26:27Z thesis-2 online in master-oppgave
- 2026-05-13T07:30:11Z ai-1 done: firm-wt-split.sh verified working in operator's WT (8 panes launched, /doctor warning surfaced for MCP NEXUS_READONLY_PG_URL on 4 ai-* panes — separate task). Sizes + PS1-role next.
- 2026-05-13T07:30:56Z ai-verify online in nexus
- 2026-05-13T07:40:08Z code-1 online in workspace
- 2026-05-13T07:40:08Z code-2 online in workspace
- 2026-05-13T07:40:08Z ai-1 online in nexus
- 2026-05-13T07:40:08Z ai-2 online in nexus
- 2026-05-13T07:40:08Z ai-3 online in nexus
- 2026-05-13T07:40:08Z ai-4 online in nexus
- 2026-05-13T07:40:09Z thesis-1 online in master-oppgave
- 2026-05-13T07:40:09Z thesis-2 online in master-oppgave
- 2026-05-13T07:43:40Z code-1 online in workspace
- 2026-05-13T07:43:40Z code-2 online in workspace
- 2026-05-13T07:43:40Z ai-1 online in nexus
- 2026-05-13T07:43:40Z ai-2 online in nexus
- 2026-05-13T07:43:41Z ai-3 online in nexus
- 2026-05-13T07:43:41Z ai-4 online in nexus
- 2026-05-13T07:43:41Z thesis-1 online in master-oppgave
- 2026-05-13T07:43:41Z thesis-2 online in master-oppgave
