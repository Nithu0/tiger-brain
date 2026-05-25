---
title: Runbook — Sample Task Walkthrough
type: runbook
created: 2026-05-25
audience: operator + new collaborators (Karri's first task)
purpose: Step-by-step walkthrough of claim → work → complete → PR cycle using T-2026-05-25-001
related:
  - "[[Runbook-Brain-Upgrade-Workflow]]"
  - "[[AGENT_ORCHESTRATION_SPEC]]"
  - "[[Tasks-MOC]]"
tags: [runbook, task, walkthrough, lifecycle]
---

# Runbook — Sample Task Walkthrough

> Example: claim T-2026-05-25-001 (RAG semantic-chunker), work it, complete it.
> Do NOT actually claim T-001 if you're reading this for orientation — it is a real
> task assigned to `code-1`. Copy the commands mentally; substitute your own task-id.

## Prerequisites

- You're in a firm pane (`echo $FIRM_ROLE` returns one of `code-1/code-2/ai-1/ai-2/thesis-1/as-1/soking-1/personal-1`)
- `~/code/command-center/_bin/` is on your `PATH`, OR you invoke the scripts via their full path
- `gh` CLI installed + authenticated (`gh auth status`) for the draft PR step
- Git repo with at least one commit on the default branch (so a feature branch can fork off it)
- `ANTHROPIC_API_KEY` set in shell or `.env` (needed for T-001 specifically — see `expected_output`)

## Step 1: See what's available

```bash
cd ~/code/command-center
~/code/command-center/_bin/firm-task-claim.sh
```

Expected output (abbreviated, ANSI colours stripped):

```
Available tasks in _open/
─────────────────────────────────────────────────────────────
  T-2026-05-25-001  Build packages/rag-engine/src/chunking/semantic.ts ...
  T-2026-05-25-002  Implement skill-registry discovery (full)
  T-2026-05-25-003  Build youtube-ingest yt-dlp wrapper

Claim: firm-task-claim.sh <task-id>
```

The listing pulls `task_id` + `objective` from each file's frontmatter via the
`fm_get` awk helper in `firm-task-claim.sh:49`. If `objective` is missing it
falls back to `title`.

## Step 2: Claim the task

```bash
~/code/command-center/_bin/firm-task-claim.sh T-2026-05-25-001
```

What happens (cross-reference `firm-task-claim.sh:134-235`):

- File moves from `~/Obsidian/Brain/10-tasks/_open/` to `_in-progress/` via atomic-ish `mv`
- Frontmatter rewritten in-place: `status: in-progress`, `claimed_at: <ISO-UTC>`, `claimed_by: $FIRM_ROLE`
- Branch from frontmatter `branch: code-1/rag-semantic-chunker` either:
  - checked out if it already exists (warn if dirty working tree)
  - created with `git checkout -b` if missing
  - skipped with a `WARN` if cwd isn't a git repo or `git` isn't installed
- Stdout block prints `task_id`, `objective`, `branch`, `files_allowed`, `expected_output`,
  `sla_seconds`, `status` transition, `claimed_at`, `claimed_by`, `branch_status`, and
  the new `location:` path

If you see `Destination already exists`, the task is already claimed by someone
else — peek at `_in-progress/T-2026-05-25-001-*.md` to find `claimed_by`.

## Step 3: Do the work

1. Open the in-progress task file and re-read the body for **Acceptance criteria** + **Test plan**
2. Implement only files in the `files_allowed:` glob. For T-001 that's exactly:
   - `packages/rag-engine/src/chunking/semantic.ts`
   - `packages/rag-engine/tests/semantic-chunker.test.ts`
3. Run tests as you go from the repo root:
   ```bash
   npm -w @cc/rag-engine test -- chunking/semantic
   npm -w @cc/rag-engine run typecheck
   ```
4. Verify each line in `expected_output:` is satisfied (1 compiled file, 5 passing tests,
   smoke test produces 50-200 chunks)
5. **NEVER touch files outside `files_allowed:`**. The script does not enforce this — it
   is operator discipline. If a refactor genuinely needs adjacent files, stop and ping
   operator on `00-firm-bus/inbox/operator.md` for a scope expansion

## Step 4: Complete + open draft PR

```bash
~/code/command-center/_bin/firm-task-complete.sh T-2026-05-25-001
```

What happens (cross-reference `firm-task-complete.sh:141-218`):

- `git status --porcelain` checked. If dirty → `git add -A` + `git commit -m`. Auto-message
  is `"<task-id>: <objective>"`. Override with `--message "feat: ..."` if you want a custom one
- Upstream check: `git rev-parse --abbrev-ref --symbolic-full-name "@{u}"`
  - **If branch has upstream**: `gh pr create --draft --title "<task>: <objective>" --body "<task-link>"`
  - **If no upstream**: script prints `branch '<name>' has no upstream — operator OK kjør needed to push first` and skips PR step cleanly (per CLAUDE.md no-auto-push rule)
- Task file moves `_in-progress/` → `_done/`
- Frontmatter rewritten: `status: done`, `completed_at: <ISO-UTC>`, `completed_by: $FIRM_ROLE`
- One line appended to `~/Obsidian/Brain/00-firm-bus/feed.md`:
  `- <ISO> <role>: task T-2026-05-25-001 done (PR-ready, awaiting push-gate)`

## Step 5: Operator OK kjør → push + non-draft

Per `~/.claude/CLAUDE.md` push-gate ("OK kjør-gate before every push. No exceptions."):

1. Operator reviews the local commit + diff (and the draft PR if one was opened)
2. Operator says `OK kjør` (or `kjør på` / `letsgooo` / `BYGG ALT`)
3. You run:
   ```bash
   git push -u origin code-1/rag-semantic-chunker
   gh pr ready <pr-number>          # flip draft → ready-for-review
   ```
4. Operator (or reviewer per `CODEOWNERS`) approves + merges; CI runs

If no draft PR was opened in Step 4 (no upstream branch yet), the sequence is:

```bash
git push -u origin code-1/rag-semantic-chunker
gh pr create --title "T-2026-05-25-001: ..." --body "..."   # non-draft directly, post-OK
```

## Failure scenarios

### A. "Task already claimed"

- `firm-task-claim.sh` errors with `Destination already exists: ...`
- `cat ~/Obsidian/Brain/10-tasks/_in-progress/T-2026-05-25-001-*.md | head -20` to find `claimed_by`
- Either: ping that role via their `00-firm-bus/inbox/<role>.md`, OR wait for the `sla_seconds:`
  to expire and then run `firm-task-release.sh <task-id>` (returns to `_open/`)
- Per `feedback_read_own_inbox_first.md`: check your own inbox first — operator may already
  have re-routed the task

### B. "Branch exists, dirty"

- `firm-task-claim.sh` warns: `exists but checkout failed (working tree dirty?)`
- The task file is still moved + frontmatter still updated (claim succeeded — branch step is best-effort)
- Manually: `git stash` or commit your WIP, then `git checkout code-1/rag-semantic-chunker`

### C. "gh CLI not installed"

- `firm-task-complete.sh` warns: `gh CLI not installed — skipping PR step`
- The commit still lands locally and the task still moves to `_done/`
- After installing gh (`sudo apt install gh && gh auth login`), run manually:
  ```bash
  gh pr create --draft --title "T-2026-05-25-001: ..." --body "..."
  ```

### D. "Tests fail at completion"

- Per `~/.claude/CLAUDE.md` "Verify before declaring done": DO NOT run `firm-task-complete.sh`
  while tests are red. The script does not run the tests — it trusts you
- Fix the failing test, commit the fix, re-run the test command from Step 3, then run complete
- If a test can't be made green and the task needs to escalate: move the file to `_blocked/`
  manually and post on `00-firm-bus/inbox/operator.md` with `blocked_reason:`

### E. "FIRM_ROLE not set"

- Both scripts warn and use `unknown` as the role
- You're probably not in a firm-launched pane. Either:
  - Re-launch via `firm` (alias for `firm-wt-split.sh`), OR
  - Manually export: `export FIRM_ROLE=code-1` before claiming (be honest about which role
    you're acting as — frontmatter is the audit trail)

### F. "claimed_by mismatch on completion"

- `firm-task-complete.sh` warns: `claimed_by='code-1' but current role='code-2' — proceeding anyway`
- The script does NOT block — but the audit trail will show the inconsistency
- If you're completing on behalf of another role, post a note in `feed.md` explaining why

## What this teaches

- **Task lifecycle is auditable**: every state change writes to `feed.md` + frontmatter (`status`,
  `claimed_at`/`claimed_by`, `completed_at`/`completed_by`). Forensics is grep-able
- **`files_allowed` is enforced by you, not the script** — discipline matters. Scope creep is
  the #1 way tasks become un-reviewable
- **Draft PR is the default**, push-to-remote is gated. Per CLAUDE.md, no auto-push exists in
  the toolchain. The scripts deliberately never call `git push`
- **Inbox + feed are the coordination substrate**. Read your inbox first per
  [[feedback_read_own_inbox_first]] before claiming anything that might already be re-routed
- **The scripts are dumb on purpose**: pure bash + awk, no yq, no node, no external state.
  If they break, you can read all ~230 lines of each in a few minutes

## Related

- [[AGENT_ORCHESTRATION_SPEC]] §10 (the canonical spec for these scripts)
- [[Runbook-Brain-Upgrade-Workflow]] §E (broader daily-ops — claim+complete is one of 7 daily flows)
- [[Tasks-MOC]] (index of all open/in-progress/done tasks)
- [[T-2026-05-25-001-rag-semantic-chunker]] (the actual task body referenced throughout)
- [[Runbook-Multi-Agent-Dispatch]] (when a task wants 5/10/15-agent fan-out instead of solo work)
- `~/code/command-center/_bin/firm-task-claim.sh` (claim script — 235 lines)
- `~/code/command-center/_bin/firm-task-complete.sh` (complete script — 232 lines)

---

Sist oppdatert: 2026-05-25 — v1.0, første utgivelse sammen med brain-upgrade fase 2 + 8-pane firm-launcher.
