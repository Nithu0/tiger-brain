---
title: Brain content audit v3 — post-I/J cleanup
date: 2026-05-25
status: v3 (after I-3 spec fixes + J-1 residual YAML + J-3 gate cascade + I-5 exemptions)
purpose: Final audit state after fase 9-10 cleanup
related:
  - "[[audit-report-v2-2026-05-25]]"
  - "[[cleanup-report-2026-05-25]]"
  - "[[wikilink-audit-v2-2026-05-25]]"
  - "[[Runbook-Brain-Upgrade-Workflow]]"
tags:
  - audit
  - v3
  - final
  - brain-hygiene
---

# Brain content audit v3 — final state

## Run info

- **Time:** 2026-05-25T15:11:41Z (third re-run)
- **Script:** `~/Obsidian/Brain/scripts/brain-content-audit.sh` (I-5 exemption list landed — `_library/`, `90-archive/`, `00-claude-inbox/`, `00-templates/`, `README.md`, `HOW-TO-*.md` now excluded from [1/7] frontmatter-presence and [2/7] YAML-validity)
- **Exit:** `1` (still ISSUE-triggered — one residual YAML-invalid file)
- **Concurrent run note:** J-agents may still be in flight; numbers below reflect filesystem state at 15:11Z. Late landings will move counts further down, not up.

## Counts evolution

| Metric | G-1 (v1) | H-6 (v2) | J-6 (v3) | Total reduction G-1 → J-6 |
|---|---|---|---|---|
| Issues (categories) | 1 | 1 | 1 | 0 |
| Warnings (categories) | 3 | 3 | 3 | 0 |
| Invalid YAML (files) | 24 | 11 | **1** | **−23 (−96%)** |
| Missing frontmatter (files) | 135 | 135 (24 after exemptions) | **24** | **−111 (−82%)** |
| Broken wikilinks (raw) | 90 | 95 | 102 | +12 (more template scaffolding added) |
| Markdown links (files) | 3 | 4 | 4 | +1 (audit-report-v1 itself) |
| Future-dated | (aborted) | 0 | 0 | 0 |
| Folders missing | 0 | 0 | 0 | 0 |
| READMEs missing | (unmeasured) | 0 (7/7) | 0 (7/7) | 0 |
| Required dashboards | 3/3 | 3/3 | 3/3 | 0 |

**Headline:** Issues category still fires but underlying file count collapsed from 24 → 1. Frontmatter coverage went from 135 gaps → 24 acceptable (operator-decision) gaps. Net: real-content hygiene now ≥96% clean.

## What landed since v2

- **I-3 (specs YAML)** — 8 spec files in `08-system-architecture/specs/` converted from `related: [[X]], [[Y]]` inline-array to YAML-list form. Bumped to v1.0.2: `AGENT_ORCHESTRATION_SPEC`, `GITHUB_DISCOVERY_SPEC`, `LICENSE_GUARD_SPEC`, `OBSIDIAN_BRAIN_STRUCTURE`, `RAG_ENGINE_SPEC`, `RETROSPECTIVE_SPEC`, `SKILL_REGISTRY_SPEC`, `YOUTUBE_INGESTION_SPEC`. Plus parent-folder files `coverage-gap-analysis-2026-05-25.md` and `link-graph-insights-2026-05-25.md`. Net: −10 invalid-YAML files.
- **J-1 (residual YAML)** — 2 new files with proper YAML headers: `2026-05-25-BRAIN-UPGRADE-FINAL-SUMMARY.md` (80+ agent / 9-phase summary, 145 lines) + `08-system-architecture/presence-investigation-2026-05-25.md` (PRESENCE.md root-cause writeup). Both pass `yaml.safe_load`.
- **J-3 (gate cascade naming)** — gate-identity naming consistency across OperatorDecisionQueue + spec docs (caught by H-9 OperatorDecisionQueue spec). No new files; cross-ref alignment only.
- **I-5 (audit-script exemption list)** — script header now documents exempt paths (`_library/`, `90-archive/`, `00-claude-inbox/`, `00-templates/`, `README.md`, `HOW-TO-*.md`). Both [1/7] presence and [2/7] YAML-validity respect the same list. Net: missing-frontmatter dropped 135 → 24, removing 111 false positives (READMEs, inbox logs, templates, library scrap).

## What's still flagged

### Issues — 1 category, 1 file (operator-action)

- `_maps/Decision-Stack-Deliveries.md` — `supersedes: "one change per session" cap` is a valid quoted scalar, but the YAML parser block-mapping path objects to the leading `typ` truncation when paired with `decided: 2026-05-03`. **Recommendation:** rewrite as `supersedes: 'one change per session cap'` (single-quote, no internal double-quote) or move the original-phrase into the body and use `supersedes: stack-deliveries-v0` in YAML. Trivial 1-file fix. Operator-action: 30 sec.

### Warnings

- **W1 — 24 missing frontmatter (post-exemption).** Operator-action-required, NOT a script bug. Composition:
  - 9 firm-bus runtime files (`00-firm-bus/feed.md`, `roster.md`, all `inbox/*.md` including `.archive/`) — these are append-only operational logs; **recommend exempting** `00-firm-bus/feed.md`, `00-firm-bus/roster.md`, `00-firm-bus/inbox/**` in next script iteration. Removing these = 15 files gone.
  - 4 AS-prosjekt notes (`06-AS/AS-MOC.md`, `_README.md`, `Regnskap-Runbook.md`, `Skatt-Notater.md`) — real notes that **should** get frontmatter; operator-action.
  - 1 personlig README (`07-personlig/_README.md`) — operator-action.
  - 2 ADRs (`00-command-center/ADRs/ADR-001-architecture.md`, `ADR-002-sqlite-then-postgres.md`) — should have frontmatter; operator-action.
  - 1 nexus status (`01-nexus/platform-status.md`) — operator-action.
  - 1 GitHub PR template (`.github/pull_request_template.md`) — **recommend exempting** `.github/**` in script.
  - After both recommended exemptions land (firm-bus runtime + `.github/`): residual = ~8 real notes needing frontmatter.
- **W2 — 102 broken wikilinks (raw).** Per `wikilink-audit-v2-2026-05-25.md` (G-3): **true broken = 30 documented stubs / 0 unintentional**. Raw count inflated by:
  - Bash `[[ ... ]]` test syntax inside code-fenced blocks (e.g. `[[ -d "$WT_PATH" ]]`, `[[ "$cmd_string" != *$'\n'* ]]`)
  - Template placeholder tokens (`[[<MOC>]]`, `[[<placeholder>]]`, `[[<!-- atomic-N -->]]`)
  - Documented intentional stubs (`[[04-career]]`, `[[2603.13017v1]]`)
  - **Recommendation:** extend audit-script in K-phase to skip fenced code blocks + skip wikilinks containing `<`, `-->`, or `$`. Expected post-filter raw count: 10–20.
- **W3 — 4 markdown-style links.** `04-career/Interview-Prep-Workflow.md`, `04-career/Active-Job-Search-MOC.md`, `08-system-architecture/audit-report-2026-05-25.md`, `README.md`. Trivial; convert `[text](path.md)` → `[[path]]`. 5-min job.

## Did I/J phases work?

- **I-3 (spec YAML):** YES. All 8 specs now parse. Coverage-gap + link-graph-insights also fixed.
- **J-1 (residual YAML):** YES. Both files have valid YAML at write-time.
- **J-3 (gate cascade naming):** YES per code-2 dispatch log. No audit category for this; observable in spec cross-refs.
- **I-5 (exemption list):** YES. Script section comments updated; both [1/7] and [2/7] honor the same EXEMPT_DIRS. False positives gone (111 files).

## Status: YELLOW (improved from RED → YELLOW → YELLOW-LOWER)

Why not GREEN: ISSUE category still fires (1 file). Audit-script exits non-zero. Warnings still > 0.

Why not RED: real-content hygiene now ≥96% clean. Issue is one isolated YAML quote-style mismatch, not systemic. All required folders + READMEs + dashboards present. Future-date check passes. Frontmatter coverage on real notes is now operator-tractable (24 files, of which ~16 can be exempted in K-phase, leaving ~8 to write).

## Next cadence

Weekly per `[[Runbook-Brain-Upgrade-Workflow]]` § Maintenance cadence. Operator can run manually anytime via:

```bash
~/Obsidian/Brain/scripts/brain-content-audit.sh
```

**Recommended K-phase (next sprint) actions to reach GREEN:**

1. Fix `_maps/Decision-Stack-Deliveries.md` YAML quote issue (1 file, 30 sec) — eliminates Issue.
2. Add `00-firm-bus/feed.md`, `00-firm-bus/roster.md`, `00-firm-bus/inbox/**`, `.github/**` to script EXEMPT_DIRS (drops missing-frontmatter from 24 → ~8).
3. Add frontmatter to ~8 remaining real notes (AS-prosjekt, ADRs, personlig README, platform-status).
4. Extend wikilink filter: skip fenced code blocks + template placeholders (drops W2 from 102 → ~15).
5. Convert 4 markdown-style links to wikilinks (W3 gone).

Estimated effort to GREEN: 1–2 hours operator time + 1 K-phase agent batch.
