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
- 2026-05-13T17:08:51Z code-1 online in workspace
- 2026-05-13T17:08:51Z code-2 online in workspace
- 2026-05-13T17:08:52Z ai-1 online in nexus
- 2026-05-13T17:08:52Z ai-2 online in nexus
- 2026-05-13T17:08:52Z ai-3 online in nexus
- 2026-05-13T17:08:52Z ai-4 online in nexus
- 2026-05-13T17:08:52Z thesis-1 online in master-oppgave
- 2026-05-13T17:08:52Z thesis-2 online in master-oppgave
- 2026-05-13T17:15:13Z ai-3 stand-down: peer pane already landed thesis-score JOIN fix (41dd662) and is mid-work on AUDIT_ALLOWLIST trim + firm-memory.ts. ai-3 will not touch overlapping files; awaiting operator re-assignment.
- 2026-05-13T17:18:17Z code-1 stand-down: peer ai-pane already landed thesis-score fix (41dd662) and is mid-work on AUDIT_ALLOWLIST trim + manager-state publishers (3 files dirty) + peak_price_true backfill (oneshot scripts staged). code-1 in workspace context — should not be doing nexus code edits. Operator notified. Awaiting reassignment.
- 2026-05-13T17:18:37Z ai-2 stand-down: dispatched same followups (thesis-score JOIN, AUDIT_ALLOWLIST trim, /health cyclesPerHour) but discovered peer pane (likely ai-1) already mid-work on overlapping files + had committed 41dd662 + 1f3ae1f. My /health.ts cyclesPerHour edit (~30 LoC, agent-verified tsc-clean) was lost in their rebase. ai-2 will not touch tree further; awaiting operator coordination.
- 2026-05-13T17:26:58Z thesis-2 done: references loop closed — 131/144 fetched (case-insensitive), 13 paywalled remain (manual_fetch.md), b106715 OCR'd, check_ocr_needed.py heuristic fixed (was sampling only front-matter). Pushed 4168d15.
- 2026-05-14T13:55:23Z as-1 online in AS
- 2026-05-14T13:55:23Z soking-1 online in soking-fulltid
