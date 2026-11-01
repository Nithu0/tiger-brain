---
type: session-note
date: 2026-05-11
session: brain-restructure
agent: claude (opus-4-7 1M ctx, sub-agent)
---

# Brain Restructure — Autonomous-Decision Layer

Goal: make the Obsidian vault capable enough that Claude can act on "kjør" alone, with minimal further questions.

## What landed

### `_decisions/` (7 new decision-tree notes)
Each note: trigger → diagnose order → action-by-classification → linked context. Frontmatter `type: decision-tree` + `autonomy_level`.

1. `When-Trade-Bleeds-Multi-Day.md` (autonomy: report)
2. `When-Gate-Goes-Silent.md` (autonomy: fix-locally)
3. `When-Agent-Stalls.md` (autonomy: fix-locally)
4. `When-Doc-Drifts-From-Code.md` (autonomy: fix-locally)
5. `When-Foundation-Rule-Goes-Yellow.md` (autonomy: report)
6. `When-Operator-Says-Kjor-Pa.md` (autonomy: fix-locally)
7. `When-Strategy-Change-Tempting.md` (autonomy: send-to-karri)

### `_runbooks/` (5 new step-by-step procedures)

1. `Push-Cycle.md` — pre-commit checklist + commit conventions + push gate + post-push verify
2. `Karri-Proposal-Send.md` — preconditions + send sequence + HTTP 204 verify + audit-trail commit
3. `Backfill-Script-Pattern.md` — canonical script envelope (explicit env var + dry-run + CONFIRM=YES + transactional batches)
4. `Multi-Agent-Dispatch.md` — 5 / 10 / 15 agent sizing + TaskCreate-first + spec doc + per-agent contract
5. `Post-Deploy-Verification.md` — 5/15/30-60 min cadence + change-shape-specific queries

### `01-nexus/runtime-state/` (5 living-state docs total)
Earlier agents (this morning) had already created `discord-delivery-state.md`, `gemini-pipeline-state.md`, and a bonus `codex-pipeline-state.md`. Both had `last_verified: 2026-05-11` already, so no refresh needed. This session added:

- `gate-decisions-state.md` — STRATEGY_BLADE_NEW_GATES=true verified, ~12 rows/24h
- `metadata-stamping-state.md` — 6 required NOT-NULL columns post-f551c17 + backfill done
- `firm-agents-state.md` — 6 active / 4 silent baseline + activation flags + verification queries

(Plus discord/gemini/codex already in place = 6 total runtime-state files; task asked for 5.)

### MOCs updated
- `_maps/Decisions-MOC.md` — new sections "Decision-trees" (7 wiki-links) and "Runbooks" (5 wiki-links)
- `_maps/Memory-MOC.md` — new section about `_decisions/` + `_runbooks/` layer
- `01-nexus/Nexus-MOC.md` — new "Brain (decision trees + runbooks)" block near the top with all decision-tree, runbook, and runtime-state links

### New memory file
- `~/.claude/projects/-home-nithu-code-ai-assistent/memory/feedback_keep_opus.md` — operator wants Opus default, do NOT propose Haiku/Sonnet downgrade for cost
- Added entry to `MEMORY.md`

## Wiki-link edge estimate

Decision-trees: ~9 outbound links per note × 7 notes ≈ 63
Runbooks: ~7 outbound links per note × 5 notes ≈ 35
Runtime-state (3 new): ~8 outbound links × 3 ≈ 24
MOC updates: ~15 new inbound link references
**Total new wiki-link edges across vault: ~135**

## How this changes "kjør" behaviour

Before: each recurring situation forced Claude to ask 3-5 clarifying questions before acting.
After: decision-trees encode the diagnose-order + action-by-classification + autonomy-level. Claude reads the matching tree, executes the action class, reports back terse.

Critical autonomy boundary preserved per [[Operator-Principles]]: no auto-disable of strategies/gates/flags, no money-impact change without Karri proposal, no Railway flag flips, "OK kjør"-gate before push remains.

## Linked
[[Decisions-MOC]] · [[Memory-MOC]] · [[Nexus-MOC]] · [[Operator-Principles]] · [[OK-Kjor-Autonomous-Execute]]
