---
tags: [meta, audit, wikilinks]
type: report
created: 2026-05-13
status: complete
---

# Wikilink Validation — 2026-05-13

Read-only audit of `[[target]]` references across the full vault. 
Code-fences and YAML frontmatter stripped. Basename-lowercase match.

## Summary

- **Markdown files scanned:** 326
- **Total wikilink references:** 1476
- **Unique targets:** 163
- **Broken targets:** 8
- **Healthy:** 155 (95.1% of unique targets)
- **Healthy references:** 1468/1476 (99.5% of all references)

## Top 20 most-referenced targets (incoming-link hubs)

| Rank | Target | Refs | Status |
|---:|---|---:|---|
| 1 | `operator-principles` | 117 | OK |
| 2 | `foundation-gate` | 69 | OK |
| 3 | `nexus-moc` | 53 | OK |
| 4 | `truth-hierarchy` | 46 | OK |
| 5 | `karri` | 44 | OK |
| 6 | `decisions-moc` | 33 | OK |
| 7 | `ok-kjor-gate` | 33 | OK |
| 8 | `tools-moc` | 33 | OK |
| 9 | `strategy-proposal-workflow` | 29 | OK |
| 10 | `thesis-moc` | 24 | OK |
| 11 | `memory-moc` | 22 | OK |
| 12 | `advisor-instructions` | 21 | OK |
| 13 | `workflows-moc` | 21 | OK |
| 14 | `when-strategy-change-tempting` | 19 | OK |
| 15 | `module-postmortem` | 17 | OK |
| 16 | `phase-status-pointer` | 17 | OK |
| 17 | `strategy-orb` | 16 | OK |
| 18 | `career-moc` | 15 | OK |
| 19 | `distillation-hook` | 15 | OK |
| 20 | `module-blackboard` | 15 | OK |

## Targets that look broken

| Target | Refs | Referencing files | Suggested fix |
|---|---:|---|---|
| `question-2` | 1 | `02-thesis/open-questions/Open-Questions.md` | _(no close match)_ |
| `question-3` | 1 | `02-thesis/open-questions/Open-Questions.md` | _(no close match)_ |
| `question-4` | 1 | `02-thesis/open-questions/Open-Questions.md` | _(no close match)_ |
| `question-5` | 1 | `02-thesis/open-questions/Open-Questions.md` | _(no close match)_ |
| `question-6` | 1 | `02-thesis/open-questions/Open-Questions.md` | _(no close match)_ |
| `stub:mp-discussion-flag` | 1 | `02-thesis/concepts/Materials-Project-Features.md` | _(no close match)_ |
| `stub:submission-dates` | 1 | `02-thesis/logistics/Submission-Timeline.md` | _(no close match)_ |
| `stub:vft-extension` | 1 | `02-thesis/concepts/Ionic-Conductivity.md` | _(no close match)_ |

## Categorized broken

### External-repo refs

These targets describe notes that live in a separate repo (e.g. `ai-assistent/`, `battery-electrolyte-predictor/`, `Master-oppgave/`). Wikilinks cannot cross vault boundaries — convert to relative markdown links or prose.

_None detected._

### Memory refs

Targets that live under `~/.claude/projects/.../memory/` (e.g. `reference_autopush`, `feedback_*`, `project_*`). Not vault notes — should be inline prose with the file path.

_None detected._

### Documentation examples that escaped code-fence stripping

Placeholder targets like `[[example]]`, `[[target]]`, `[[your-note]]`. Usually inside indented or malformed fences. Re-fence the snippet.

_None detected._

### Genuine orphan stubs (intentional to-write markers)

Everything else: probably real stubs awaiting a note. Convert into a note or rewrite as prose.

- `[[question-2]]` (1 refs)
- `[[question-3]]` (1 refs)
- `[[question-4]]` (1 refs)
- `[[question-5]]` (1 refs)
- `[[question-6]]` (1 refs)
- `[[stub:mp-discussion-flag]]` (1 refs)
- `[[stub:submission-dates]]` (1 refs)
- `[[stub:vft-extension]]` (1 refs)

## Healthy clusters by top-level folder

Healthy references resolving to notes inside each top-level folder — high density indicates a MOC neighborhood.

| Folder | Resolved incoming refs |
|---|---:|
| `01-nexus/` | 645 |
| `_maps/` | 586 |
| `02-thesis/` | 193 |
| `_decisions/` | 88 |
| `_runbooks/` | 61 |
| `05-learning/` | 37 |
| `(root)/` | 36 |
| `03-business/` | 35 |

## Top 10 orphan notes (not linked from anywhere, excl. 90-archive)

| Note | Path |
|---|---|
| `READY-TO-SHARE` | `READY-TO-SHARE.md` |
| `OPERATOR-MODS-RECOMMENDATION-2026-05-13` | `_promote-candidates/OPERATOR-MODS-RECOMMENDATION-2026-05-13.md` |
| `firm-launcher` | `_runbooks/firm-launcher.md` |
| `Graph-View-Curation` | `_maps/Graph-View-Curation.md` |
| `pull_request_template` | `.github/pull_request_template.md` |
| `2026-05-13_research-os-audit` | `00-claude-inbox/nexus/2026-05-13_research-os-audit.md` |
| `2026-05-13_firm-launch-failure-diagnosis` | `00-claude-inbox/nexus/2026-05-13_firm-launch-failure-diagnosis.md` |
| `plugin-audit-2026-05-13` | `security/plugin-audit-2026-05-13.md` |
| `CURRENT-HANDOFF` | `handoffs/CURRENT-HANDOFF.md` |
| `00_SYNTHESIS` | `00-claude-inbox/nexus/2026-05-13/00_SYNTHESIS.md` |

## Suggested follow-up commands

Operator can grep for any broken target and Edit the referencing files manually. Examples:

```bash
# Find every occurrence of a broken target to decide rewrite vs create-stub:
rg -n --no-heading -F '[[TARGET]]' /home/nithu/Obsidian/Brain

# Rewrite an external-repo wikilink to a markdown link (manual review first):
#   [[katastrofedag-analyse-2026-05-12]]  ->  [katastrofedag-analyse-2026-05-12](../ai-assistent/...)

# Convert a memory-ref wikilink to prose:
#   [[reference_autopush]]  ->  see `~/.claude/projects/-home-nithu-code/memory/reference_autopush.md`
```

See also: [[Graph-View-Curation]] for MOC hygiene patterns.
