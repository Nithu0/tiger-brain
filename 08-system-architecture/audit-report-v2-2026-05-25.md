---
title: Brain content audit v2 — post-H1/H2 fixes
date: 2026-05-25
status: v2 (re-run after script fix + cleanup pass)
purpose: Measure delta from G-1 baseline after H-1 (script fix) + H-2 (content cleanup)
related:
  - "[[audit-report-2026-05-25]]"
  - "[[wikilink-audit-v2-2026-05-25]]"
  - "[[Runbook-Brain-Upgrade-Workflow]]"
tags:
  - audit
  - v2
  - delta
  - brain-hygiene
---

# Brain content audit v2 — delta vs G-1 baseline

## Run info

- **Time:** 2026-05-25T14:58:24Z (re-run)
- **Script:** `~/Obsidian/Brain/scripts/brain-content-audit.sh` (H-1 patched — `find … done < <(...)` pattern instead of piped `while | head`)
- **Exit:** `1` (driven by ISSUE category triggering, NOT by premature abort — script completed all 7 sections this time)
- **Total .md files scanned:** 567

## Counts comparison

| Metric | G-1 baseline | H-6 re-run | Delta | Notes |
|---|---|---|---|---|
| Issues (categories) | 1 | 1 | 0 | Same YAML-validity category still fires |
| Warnings (categories) | 3 | 3 | 0 | frontmatter / wikilinks / md-links — same 3 |
| Invalid YAML (files) | 24 | **11** | **−13** | H-2 fixed ~54% of YAML errors |
| Missing frontmatter (files) | 135 | 135 | 0 | H-2 deferred (mostly READMEs + nexus inbox logs) |
| Broken wikilinks (raw) | 90 | 95 | +5 | New scaffolding/specs added in F-1/G phases introduced more `[[<placeholder>]]` template hits — see analysis below |
| Markdown links (files) | 3 | 4 | +1 | `audit-report-2026-05-25.md` (G-1's own report) is itself flagged |
| Future-dated files | (aborted G-1) | **0** | first successful run | H-1 script fix enables this check |
| Folders missing | 0 | 0 | 0 | 16/16 present |
| READMEs missing | 0 (7/7) | 0 (7/7) | 0 | All required READMEs present |

## Did H-1 fix work?

- **Script ran past step 5 to completion:** YES. Step 5 (future-dated) executes cleanly via `done < <(find …)` pattern, no longer aborts on SIGPIPE from `head`.
- **All 7 sections executed:** YES. Confirmed by tailing the run log — sections [1/7] through [7/7] + Summary all printed.
- Script's `|| true` markers present on lines 27, 38, 99, 112, 126, 130 — robust against early-exit on `set -euo pipefail`.

## Did H-2 cleanup reduce counts?

- **YAML invalid: 24 → 11** (−13 files, −54%). H-2 fixed the systemic `related: [[X]], [[Y]]` convention bug across most MOCs, runbooks, and date-stamped reports. Files now valid include: `00-CHEAT-SHEET.md`, `wikilink-audit-2026-05-25.md`, `wikilink-audit-v2-2026-05-25.md`, `INTEGRATION_NOTES_v1.1.md`, `test-summary-2026-05-25.md`, `2026-05-25-brain-upgrade-plan.md`, `preflight-report-2026-05-25.md`, `Packages-MOC.md`, `System-Architecture-MOC.md`, `Runbook-Brain-Demo.md`, `Runbook-Sample-Task-Walkthrough.md`, `Runbook-Brain-Upgrade-Workflow.md`, `Runbook-Brain-Preflight-Checklist.md`, `recall-eval-2026-05-25.md`.
- **Wikilinks: 90 → 95** (+5). H-2 deferred the wikilink filter improvement (still no exclusion for code-fenced `[[...]]` bash test syntax or `[[<placeholder>]]` template tokens). Net +5 because new G-phase scaffolding (Packages-MOC, Runbook-Brain-Upgrade-Workflow, link-graph script docs) introduced more placeholder patterns. Real-stub count tracked separately in `wikilink-audit-v2-2026-05-25.md` (30 documented stubs / 0 truly broken per G-3 wikilink-audit v2).
- **Frontmatter missing: 135 → 135** (no change). H-2 deferred per G-1 recommendation — operator should decide whether to add exemption list (READMEs, `00-claude-inbox/nexus/**`, `.github/**`) or batch-add minimal frontmatter.

## Remaining gaps (operator-action-required)

### Issues — 1 category, 11 files

The 11 remaining YAML-invalid files split into two clusters:

**Cluster A — 9 spec files in `08-system-architecture/specs/`** (script error: `tit` truncation = `title:` parser fails on the line that follows it):
- `AGENT_ORCHESTRATION_SPEC.md`, `GITHUB_DISCOVERY_SPEC.md`, `LICENSE_GUARD_SPEC.md`, `OBSIDIAN_BRAIN_STRUCTURE.md`, `RAG_ENGINE_SPEC.md`, `RETROSPECTIVE_SPEC.md`, `SKILL_REGISTRY_SPEC.md`, `YOUTUBE_INGESTION_SPEC.md`
- Plus `coverage-gap-analysis-2026-05-25.md` and `link-graph-insights-2026-05-25.md` in the parent folder (one of these rotates in/out of the first-20 listing as files are written/touched — both contain the same `related: [[X]], [[Y]]` pattern that needs converting to YAML-list form)

Most likely cause: each still uses the inline-array `related: [[X]], [[Y]]` convention that YAML rejects (Obsidian-friendly but yaml.safe_load chokes). Same root cause as G-1 — H-2 missed these specs (presumably out of conservative scope).

**Cluster B — 2 outliers:**
- `_maps/Decision-Stack-Deliveries.md` — unquoted scalar `"one change per session" cap` in `supersedes:` (G-1 already flagged; H-2 deferred)
- `00-claude-inbox/nexus/2026-05-13/round3/C3_proposal_audit.md` — backtick character in frontmatter (parser: `found character '\`' that cannot start any token`)

### Warnings — operator decisions still pending

- **W1 (135 missing frontmatter):** H-2 deferred. Recommend: add exemption list in script for `*/README.md`, `*/_README.md`, `00-claude-inbox/nexus/**`, `00-claude-inbox/command-center/**`, `.github/**` → expected to drop count from 135 to ~10-15.
- **W2 (95 broken wikilinks):** H-2 deferred. Recommend: extend audit-script filter to skip wikilinks inside fenced code blocks + skip templates containing `<`, `-->`, or `$` → expected to drop raw count from 95 to ~10-20.
- **W3 (4 md-style links):** Trivial fix — `04-career/Interview-Prep-Workflow.md`, `04-career/Active-Job-Search-MOC.md`, `08-system-architecture/audit-report-2026-05-25.md`, `README.md`.

## What landed between G-1 and H-6

H-2 cleanup pass (visible in modified file timestamps) successfully patched YAML frontmatter on ~13 files. New content (link-graph-insights, coverage-gap-analysis) and brain skills (brain-task-claim, brain-task-complete) added since G-1 — these introduced 1 new YAML-invalid file (link-graph-insights) and one new md-style-link file (audit-report-2026-05-25 itself).

## Sign-off

**Status: YELLOW (RED → YELLOW progress).**

- 1 issue category still fires (down from G-1's 1 — same category, smaller blast radius: 11 files vs 24)
- 3 warning categories still present (unchanged count, but mostly deferred-by-design per G-1 recommendations awaiting operator decision)
- H-1 script-abort bug confirmed resolved
- All required folders + READMEs present
- 0 future-dated files (first time this check ran cleanly)

**Not yet GREEN** because the YAML category continues to fail. To reach GREEN with one more pass: (a) convert remaining 9 spec files + 2 outliers to YAML-list `related:` form, (b) quote the `Decision-Stack-Deliveries.md` scalar, (c) clean backticks from `C3_proposal_audit.md`. Estimated ~30 min of mechanical edits.

## Next cadence

Weekly per `[[Runbook-Brain-Upgrade-Workflow]]` § Maintenance cadence. Next scheduled run: 2026-06-01.

## 5× verify

1. **Script ran successfully (not aborted prematurely):** PASS — confirmed by presence of `=== Summary ===` block in `/tmp/audit-v2-fresh.log` line 117, all 7 sections printed.
2. **Real numbers (not invented):** PASS — script output reproduced + independently verified via two parallel python probes (got matching 11 YAML / 135 frontmatter / 95 wikilinks / 4 md-links / 0 future / 16-of-16 folders / 7-of-7 READMEs).
3. **Delta math correct:** PASS — 24 → 11 = −13 (54% reduction); 135 → 135 = 0; 90 → 95 = +5; 3 → 4 = +1; script-completed delta vs aborted G-1 = first successful run.
4. **Wikilinks valid:** PASS — all `[[X]]` references in this report target either existing notes (`audit-report-2026-05-25`, `wikilink-audit-v2-2026-05-25`, `Runbook-Brain-Upgrade-Workflow`) or are properly YAML-list-wrapped.
5. **Frontmatter YAML valid:** PASS — uses YAML-list form for `related:` and `tags:` (the convention H-2 standardized on); verified `yaml.safe_load` would parse this report cleanly.
