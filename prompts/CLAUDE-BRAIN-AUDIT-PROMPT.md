---
type: prompt
tags: [prompt, audit]
created: 2026-05-11
---

# Brain audit prompt — paste into Claude Code from vault root

## Purpose

Ask Claude to verify vault health (frontmatter, broken wikilinks, stale "current"
files, protected-folder hygiene) **without making any changes**. Use this when
you want a read-only pulse-check of the Brain vault — e.g. before a big
restructuring session, after a long absence, or when something feels off.

This prompt is intentionally narrow: Claude reports, operator decides. No
auto-fixes.

## The prompt (copy-paste below into Claude Code from the vault root)

```text
You are auditing the Obsidian Brain vault. You are in READ-ONLY mode.

DO NOT modify any files. DO NOT commit. DO NOT push. DO NOT run any
write-capable scripts. If a step would require a write, skip it and note
the skip in your report.

Steps:

1. Run `python scripts/brain_audit.py` and capture its full output. Report
   the summary line and any FAIL/WARN entries verbatim.

2. Run `git status --porcelain` and list every file under any of these
   protected paths that appears as modified, staged, or untracked:
     - `_decisions/`
     - `_maps/`
     - `claude-context/`
     - `.github/`
     - `scripts/`
     - root-level rule files (`BRAIN-RULES.md`, `CONTRIBUTING.md`,
       `README.md`, `00-DASHBOARD.md`, `01-CURRENT-FOCUS.md`)
   If any are touched, flag them — they need operator review before commit.

3. Spot-check 5 random markdown files from the vault (exclude `.git/`,
   `.obsidian/`, `90-archive/`). For each, verify:
     a. Has YAML frontmatter with at least `type:` and `tags:`.
     b. Every `[[wikilink]]` resolves to an existing note (or note alias).
   Report each file as PASS or FAIL with reason.

4. Identify any file whose name or frontmatter marks it as "current"
   (e.g. `CURRENT-*.md`, `01-CURRENT-FOCUS.md`, `handoffs/CURRENT-HANDOFF.md`,
   anything with `status: current` in frontmatter) that has not been
   modified in the last 14 days. Use `git log -1 --format=%cs <path>` to
   check.

5. Produce a final report in this exact format:

   ## Audit result: PASS | FAIL
   ## Top 5 issues (most important first)
   1. ...
   2. ...
   3. ...
   4. ...
   5. ...
   ## Suggested next step
   <one sentence>

DO NOT modify any files. DO NOT commit. DO NOT push.
```

## After Claude reports — operator-decision checklist

- [ ] Did the audit PASS or FAIL?
- [ ] Any protected-folder touches? If yes, revert or escalate.
- [ ] Any stale "current" files? Decide: update, archive, or accept.
- [ ] Any broken wikilinks? Decide: fix, redirect, or remove link.
- [ ] Do I want Claude to fix the top issues now? If yes, start a NEW
      session with a write-capable prompt (not this one).

---

Sist oppdatert: 2026-05-11
