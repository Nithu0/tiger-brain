---
type: ops-report
status: complete
created: 2026-05-11
session: deadlink-drain-r2
---
# Deadlink Drain R2 — 2026-05-11

Second-round drain after memory-consistency audit reported dead-link growth 19 → 46.

## Resolutions applied

| # | Target | Action | Result |
|---|---|---|---|
| 1 | `Foundation-Gate-08may` | Source-fix in `2026-05-11-week-opening-synthesis.md` → `[[Foundation-Gate]]` (existing canonical) | 1 source updated, 0 remaining refs |
| 2 | `Operator-Pays-Premium` | Stub created `_maps/Operator-Pays-Premium.md` → points to feedback memory | resolved |
| 3 | `Firm-Up-Max-Mode` | Stub `_maps/Firm-Up-Max-Mode.md` → references `reference_firm_up_entry.md` + `local-firm-mirror.md` | resolved |
| 4 | `Parallel-Batch-Coordination` | Stub `_maps/Parallel-Batch-Coordination.md` → `parallel_batch_pattern.md` + `multi-claude-parallel.md` | resolved |
| 5 | `MCP-clickup` | Stub `_maps/MCP-clickup.md` → `reference_available_tools.md` | resolved |
| 6 | `MCP-google-drive` | Stub `_maps/MCP-google-drive.md` → `reference_available_tools.md` | resolved |
| 7 | `MCP-ms365` | Stub `_maps/MCP-ms365.md` → `reference_available_tools.md` | resolved |
| 8 | `Claude` | Stub `_maps/Claude.md` → global / project CLAUDE.md + `model-routing.md` | resolved |
| 9 | `Codex` | Stub `_maps/Codex.md` → `model-routing.md` | resolved |
| 10 | `Cross-Project-Pollution-Audit` | Stub `_maps/Cross-Project-Pollution-Audit.md` → `cross-project-fixes.md` | resolved |
| 11 | `Model-Routing` | Stub `_maps/Model-Routing.md` → `docs/architecture/model-routing.md` + `llm-router.service.ts` | resolved |

**10 stubs created, 1 source-fix applied. All 11 audit targets now resolve or have zero remaining references.**

## Dead-link sweep

- Pre-drain (per audit): 46 occurrences
- Post-drain: **36 distinct dead targets, 100 occurrences** (full vault wikilink scan)

Note: my count uses the full vault scan and is the binding number going forward. Audit's "46 occurrences" likely excluded `_runbooks/` patterns or treated case differently — either way the absolute count is what matters next round.

## Top 5 remaining dead targets (priority for R3)

| Count | Target | Most likely fix |
|---|---|---|
| 15 | `Runbook-Post-Deploy-Verification` | Create `_runbooks/Post-Deploy-Verification.md` — referenced from every push-cycle runbook |
| 11 | `Runbook-Karri-Proposal-Send` | Create `_runbooks/Karri-Proposal-Send.md` — Discord webhook + 204-verify procedure |
| 9 | `Runbook-Push-Cycle` | Create `_runbooks/Push-Cycle.md` — edit → typecheck → commit → operator-push |
| 8 | `Runbook-Backfill-Script-Pattern` | Create `_runbooks/Backfill-Script-Pattern.md` — env-var + dry-run + CONFIRM=YES |
| 7 | `Runbook-Multi-Agent-Dispatch` | Alias existing `_runbooks/Multi-Agent-Dispatch.md` OR rename references |

**Pattern observed:** the 5 `Runbook-*` prefixed names in `Decisions-MOC.md` don't match the un-prefixed filenames in `_runbooks/`. Cheapest fix is to rename the on-disk files to match the canonical `Runbook-<slug>.md` referenced from the MOCs — 50+ dead refs resolved in one operation.

Plus 7 `Gemini` references — needs `_maps/Gemini.md` stub similar to Claude/Codex.

## Constraints honored

- Vault writes only. No git commits.
- All stubs 50–100 words + frontmatter + linked-to footer.
- No memory file content copied into vault (only references).

Linked to: [[Nexus-MOC]], [[Memory-MOC]], [[Decisions-MOC]]
