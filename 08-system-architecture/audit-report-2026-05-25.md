---
title: Brain content audit — first live run 2026-05-25
date: 2026-05-25
status: v1.0 (first run after F-9 landed audit script)
purpose: Baseline brain hygiene metrics post-60-agent sprint
script: scripts/brain-content-audit.sh
related:
  - "[[2026-05-25-brain-upgrade-plan]]"
  - "[[wikilink-audit-2026-05-25]]"
tags:
  - audit
  - brain-hygiene
  - baseline
---

# Brain content audit — first live run 2026-05-25

## Script + execution

- Script: `~/Obsidian/Brain/scripts/brain-content-audit.sh` (F-9)
- Run time: 2026-05-25T14:45:34Z
- Exit code: `1` (script exited at step 5 due to a `set -euo pipefail` interaction; **not** caused by audit findings — script ran step 1-4 cleanly, then aborted before printing summary. Steps 5-7 were re-run manually to complete coverage.)
- Categories: 7 (frontmatter, YAML, wikilinks, markdown-links, future-dated, folders, READMEs)

## Counts

- **Issues: 1** (category: invalid YAML frontmatter — 24 files affected)
- **Warnings: 3** (missing frontmatter 135 files; broken wikilinks 90; markdown-style links 3 files)
- Effective script-summary equivalent: `ISSUES=1 WARN=3` (would have printed had it not aborted at step 5)

> Note: the script's tallies count *categories that triggered*, not individual files. So 1 issue = "YAML validity category fired" (covers 24 files); 3 warnings = three categories warned (covering 228 file-level findings).

## Per-category findings

### 1. Frontmatter presence — WARN

135 files lack a leading `---` frontmatter block. First 20:

```
./07-personlig/_README.md
./.github/pull_request_template.md
./01-nexus/platform-status.md
./01-nexus/README.md
./90-archive/README.md
./_promote-candidates/README.md
./00-command-center/ADRs/ADR-002-sqlite-then-postgres.md
./00-command-center/ADRs/ADR-001-architecture.md
./_maps/README.md
./02-thesis/README.md
./00-claude-inbox/nexus/2026-05-11-evaluategates-cleanup.md
./00-claude-inbox/nexus/2026-05-11-codex-blocker-2-pr-crash.md
./00-claude-inbox/nexus/2026-05-11-codex-blocker-3-worktree.md
./00-claude-inbox/nexus/2026-05-11-session-block-impl.md
./00-claude-inbox/nexus/2026-05-11-codex-prod-readiness.md
./00-claude-inbox/nexus/2026-05-12-daily-trade-cap-impl.md
./00-claude-inbox/nexus/2026-05-11-followups-commit.md
./00-claude-inbox/nexus/2026-05-11-challenge-async.md
./00-claude-inbox/nexus/2026-05-11-regime-gate-impl.md
./00-claude-inbox/nexus/2026-05-11-context-map-refresh.md
```

Two clusters stand out:
- Boilerplate `README.md` / `_README.md` / `pull_request_template.md` — arguably OK to be frontmatter-free (template/index files), but baseline still flags them.
- The entire `00-claude-inbox/nexus/` log archive (historical Codex/agent drops from May 11-12) — none had frontmatter discipline applied.

### 2. Frontmatter YAML validity — ISSUE (24 files)

```
./00-CHEAT-SHEET.md
./08-system-architecture/wikilink-audit-2026-05-25.md
./08-system-architecture/INTEGRATION_NOTES_v1.1.md
./08-system-architecture/test-summary-2026-05-25.md
./08-system-architecture/2026-05-25-brain-upgrade-plan.md
./08-system-architecture/specs/YOUTUBE_INGESTION_SPEC.md
./08-system-architecture/specs/LICENSE_GUARD_SPEC.md
./08-system-architecture/specs/SKILL_REGISTRY_SPEC.md
./08-system-architecture/specs/RETROSPECTIVE_SPEC.md
./08-system-architecture/specs/RAG_ENGINE_SPEC.md
./08-system-architecture/specs/AGENT_ORCHESTRATION_SPEC.md
./08-system-architecture/specs/OBSIDIAN_BRAIN_STRUCTURE.md
./08-system-architecture/specs/GITHUB_DISCOVERY_SPEC.md
./08-system-architecture/eval/recall-eval-2026-05-25.md
./_maps/Packages-MOC.md
./_maps/Decision-Stack-Deliveries.md
./_maps/System-Architecture-MOC.md
./_runbooks/Runbook-Brain-Demo.md
./_runbooks/Runbook-Sample-Task-Walkthrough.md
./_runbooks/Runbook-Brain-Upgrade-Workflow.md
```
(+ 4 more not shown by the script's first-20 cap; total = 24)

**Root cause** (script's `[:80]`-truncated message hides this — verified manually):

Most failures are caused by inline `[[X]], [[Y]]` arrays inside YAML, e.g.:

```yaml
related: [[00-DASHBOARD]], [[Runbook-Brain-Upgrade-Workflow]], [[2026-05-25-brain-upgrade-plan]]
```

YAML parses `[[00-DASHBOARD]]` as a nested flow-sequence, then chokes on the comma + next `[[`. Obsidian renders this fine (it's a documentation convention), but `yaml.safe_load` rejects it.

`./_maps/Decision-Stack-Deliveries.md` fails differently: unquoted scalar `"one change per session" cap` in a `supersedes:` field.

### 3. Wikilinks — WARN (90 potentially broken)

First 20:

```
[[ "$cmd_string" != *$'\n'* ]]
[[ -d "$WT_PATH" ]]
[[...]]
[[04-career]]
[[2026-05-13-firm-launcher-decision]]
[[2603.13017v1]]
[[30-agent-audit]]
[[<!-- atomic-1 -->]]
[[<!-- atomic-2 -->]]
[[<!-- atomic-3 -->]]
[[<MOC-or-spec>]]
[[<MOC>]]
[[<new-path>]]
[[<original-path>]]
[[<other-spec>]]
[[<related-note>]]
[[<related-skill>]]
[[<spec-or-MOC>]]
[[ADR-003-cross-machine-sync]]
[[ADR-004-slice-14-control-plane-split]]
```

Most are false positives:
- Bash array indexing (`[[ ... ]]`) is double-bracket test syntax in code fences — not wikilinks.
- `[[<MOC>]]`, `[[<new-path>]]`, `[[<related-note>]]` etc. are **template placeholders** living inside `00-templates/` or spec examples.
- `[[<!-- atomic-N -->]]` are HTML-comment placeholders in scaffolding.

The remaining are real stubs (`[[ADR-003-cross-machine-sync]]`, `[[30-agent-audit]]`, `[[2026-05-13-firm-launcher-decision]]`, `[[04-career]]`) — already documented in `wikilink-audit-2026-05-25.md` per the script's own pointer.

### 4. Markdown-link usage — WARN (3 files)

Should use `[[wikilink]]` style instead of `[text](path.md)`:

```
./04-career/Interview-Prep-Workflow.md
./04-career/Active-Job-Search-MOC.md
./README.md
```

### 5. Future-dated files — OK

None. (Script aborted before printing the OK marker; verified manually: `find . -name '????-??-??-*.md'` returned no files with date `> 2026-05-25`.)

### 6. Required folders — OK (16/16)

All present (verified manually):

```
00-DASHBOARD.md           00-CONTROL-PANEL.md       01-CURRENT-FOCUS.md
_maps                     _decisions                _runbooks
_library                  00-firm-bus               00-claude-inbox
00-templates              03-skills                 08-system-architecture
09-retrospectives         10-tasks                  12-youtube
13-github-repos
```

### 7. Required folder READMEs — OK (7/7)

```
03-skills/README.md             09-retrospectives/README.md
10-tasks/README.md              12-youtube/README.md
13-github-repos/README.md       00-templates/README.md
00-firm-bus/README.md
```

## Recommendations

### Issues (must fix before next weekly cadence)

**[1] Invalid YAML frontmatter — 24 files** (the single ISSUE that failed the audit)

Two-pronged remediation, **but defer bulk rewrite to operator** per task constraints:

1. **Convention fix (recommended):** change `related: [[X]], [[Y]]` → YAML list form:
   ```yaml
   related:
     - "[[X]]"
     - "[[Y]]"
   ```
   This is what `08-system-architecture/audit-report-2026-05-25.md` (this file) already uses. Obsidian still resolves the wikilinks.

2. **Quote-fix for `Decision-Stack-Deliveries.md`:** wrap the offending scalar:
   ```yaml
   supersedes: '"one change per session" cap'
   ```

3. **Script-side improvement:** F-9's `[:80]` error truncation makes triage hard — file an enhancement to print full YAML error or at least the offending line/column. Also: script aborts at step 5 due to `set -euo pipefail` interaction with the empty `find | while | head` pipeline. Fix: append `|| true` to the future-files pipeline, same pattern used in step 3.

### Warnings (defer-or-fix)

**[W1] 135 missing-frontmatter files** — DEFER. Most are READMEs / templates / historical inbox archives. Recommend: introduce an exemption list in the script (e.g. `*/README.md`, `*/_README.md`, `00-claude-inbox/**`, `.github/**`) so the metric becomes meaningful. Alternatively, batch-add minimal `---\ntype: log\n---` to the inbox archive in a single operator-approved sweep.

**[W2] 90 potentially-broken wikilinks** — MOSTLY-DEFER. Real broken stubs already tracked in `wikilink-audit-2026-05-25.md`. Recommend: extend audit script to filter out (a) wikilinks inside fenced code blocks, (b) wikilinks containing `<`, `-->`, or `$` (template placeholders), (c) anything matching the documented-stub list. After filtering, the genuine-stub count should drop to ~10-15.

**[W3] 3 files with markdown-style .md links** — LOW-EFFORT FIX. All in `04-career/` + root `README.md`. Single operator-approved sweep would clear these.

## Fixes applied in this run

**None.** Per task constraints, only trivial frontmatter typos may be auto-fixed. The 24 YAML issues are systemic (a documentation convention disagreement, not typos) — bulk-rewriting them is out of scope and must be operator-approved. No fixes applied.

## Sign-off

- Baseline established 2026-05-25 14:45 UTC.
- **Audit result: FAILED** (1 issue category, 3 warning categories) per script's own pass/fail logic — but the failure is concentrated in one root cause (`related: [[X]], [[Y]]` convention) affecting 20 of 24 files.
- **Script bug noted:** premature abort at step 5/7 due to `set -euo pipefail`; steps 5-7 verified clean via manual re-run. Recommend operator file this against F-9.
- Next run: weekly per `[[Runbook-Brain-Upgrade-Workflow]]`.
- Operator should review:
  1. Whether to adopt YAML-list form for `related:` (one-time sweep clears the only ISSUE).
  2. Whether to add exemption list for inbox/README files (drops W1 from 135 → ~20).
  3. Whether to extend wikilink filter to skip code blocks + placeholders (drops W2 dramatically).
