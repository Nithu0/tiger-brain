---
tags: [inbox, audit, vault-health]
type: inbox
project: nexus
created: 2026-05-11
author: claude
---

# Vault gaps audit — 2026-05-11

Full audit of `/home/nithu/Obsidian/Brain/` second-brain structure. Vault has clean MOC scaffolding and decent edge density in the production-domain clusters (Nexus, Thesis), but the cognitive-OS layer (`_maps/`) leaks heavily into stub-land and the exploratory domains (business, career, learning) are pure scaffolding with no operator content yet.

## Scale

- **Total .md files**: 97 (96 content + 1 root README)
- **Total wiki-link occurrences (edges)**: 656
- **Notes containing at least one outbound link**: 91 / 97 (94 %)
- **Unique wiki-link targets**: 119 (43 of which resolve to nothing — see "Dead links" below)

## Network density (sample of 20 leaf notes)

Average backlinks per leaf note: **~6 files reference it**. Range 2–21.

| Cluster | Mean backlinks | Notes |
|---|---|---|
| Nexus modules / strategies | 9–13 | Densest cluster — Foundation-Gate (21), Operator-Principles (13), Strategy-ORB (12) |
| Thesis concepts / methods | 4–6 | Decent self-contained subgraph |
| Business / career / learning leaves | 3–5 | Sparse — every "Note" is a single-edge stub linking back to its MOC and 2–3 siblings |
| Operations (Demo-Mode, Open-Questions) | 2–3 | Under-linked relative to their importance |

## Orphaned stub notes (count: 21)

Defined: type-frontmatter `stub` AND contains `> Stub — operator to fill` AND ≤ ~40 lines. All sit in `03-business/`, `04-career/`, `05-learning/`. None are linked-orphans (the MOCs reference them), but they are content-orphans — pure scaffolding awaiting operator input.

Five examples:
1. `/home/nithu/Obsidian/Brain/03-business/Customer-Discovery.md` (33 lines, all TODO)
2. `/home/nithu/Obsidian/Brain/04-career/Resume-Updates.md` (32 lines)
3. `/home/nithu/Obsidian/Brain/04-career/Skills-To-Develop.md` (36 lines)
4. `/home/nithu/Obsidian/Brain/05-learning/Notes-On-ML.md` (34 lines)
5. `/home/nithu/Obsidian/Brain/05-learning/Books-And-Papers.md` (36 lines)

Full stub list (file → lines):
- `03-business/Customer-Discovery.md` (33), `Pricing-Strategy.md` (33), `Nexus-Productization.md` (38), `Side-Income-Streams.md` (35), `Tools-And-Stack.md` (35), `Decisions-And-Bets.md` (36)
- `04-career/Current-Role.md` (34), `Skills-To-Develop.md` (36), `Job-Search-Status.md` (33), `Long-Term-Vision.md` (33), `Network.md` (33), `Resume-Updates.md` (32)
- `05-learning/Currently-Reading.md` (32), `Want-To-Learn.md` (33), `Notes-On-ML.md` (34), `Notes-On-Trading-Systems.md` (36), `Notes-On-AI-Agents.md` (36), `Books-And-Papers.md` (36)
- `01-nexus/operations/Karri.md` (has stub marker; check if intentional bridge or unfilled people-card)
- `01-nexus/strategies/Strategy-Promotion-Workflow.md` (check — may be intentionally thin given pointer-to-repo pattern)
- `02-thesis/open-questions/Open-Questions.md` (6 Q-stubs inside)

## Dead wiki-links (count: 33 unique targets, 35 link occurrences)

All concentrated in `_maps/*` MOCs and the root README. These are the documented "stub-links appear orange in Graph View as to-write prompts" pattern — intentional design — but the cognitive-OS layer has shipped MOCs that reference targets the operator never created.

Five examples (target → referenced from):
1. `Distillation-Hook` (2 refs) ← `Memory-MOC`, `Decisions-MOC`
2. `Session-Start-Hook` (2 refs) ← `Memory-MOC`, `Decisions-MOC`
3. `Obsidian-Bridge` ← `Decisions-MOC`
4. `Operator-Principles` (already exists as `01-nexus/operations/Operator-Principles.md`) — referenced as `Operator-Nithu` is dead in `People-MOC`
5. `MCP-nexus-pg` and all six `MCP-*` siblings ← `Tools-MOC` (entire MCP table has zero target notes)

Full dead-target list:
`Claude`, `Codex`, `Gemini`, `Operator-Nithu`, `Thesis-Advisor` (5 people stubs)
`MCP-clickup`, `MCP-google-drive`, `MCP-ms365`, `MCP-n8n`, `MCP-nexus-pg`, `MCP-nexus-pg-rw`, `MCP-obsidian` (7 MCP stubs)
`Decision-No-Auto-Activation`, `Decision-Stack-Deliveries`, `Decision-Strategy-Review-Pipeline`, `Decision-Tools-Roster-Habit` (4 decision stubs)
`Cross-Project-Pollution-Audit`, `Distillation-Hook`, `Distillation-Stop-Hook`, `Firm-Up-Max-Mode`, `Global-CLAUDE-md`, `Memory-Lifecycle`, `Model-Routing`, `OK-Kjor-Autonomous-Execute`, `Obsidian-Bridge`, `Parallel-Batch-Coordination`, `Permissions-Diff`, `Promote-Inbox-To-Repo`, `Secrets-Policy`, `Session-Start-Hook`, `Strategy-Proposal-Pipeline`, `Truth-Hierarchy`, `WF-1-telegram-orchestrator` (17 cognitive-OS stubs)

## MOC coverage gaps

Domain MOCs are **fully covered** against their folder children:
- `Nexus-MOC.md` — covers all 25 notes under `01-nexus/`. No gaps.
- `Thesis-MOC.md` — covers all 23 notes under `02-thesis/`. No gaps.
- `Business-MOC.md` — covers all 6 sub-topics under `03-business/`. No gaps.
- `Career-MOC.md` — covers all 6 sub-topics under `04-career/`. No gaps.
- `Learning-MOC.md` — covers all 6 sub-topics under `05-learning/`. No gaps.

Where the network IS missing edges: `_maps/*.md` MOCs index targets that don't exist as files at all. So "coverage gap" reframes as "MOC references files that were never created" — see Dead Links section.

## Network observations

- **Root `README.md`** → fan-out (5 domain MOCs + 5 meta MOCs) but **zero inbound links**. It's truly the hub but it's a leaf in the back-link sense. Acceptable for a Home note, but worth noting that Graph View renders it as a one-way star.
- **Hub-of-hubs**: `Workflows-MOC` has 6 inbound references; `Tools-MOC` has 5; `Decisions-MOC` has 6. Healthy mesh inside `_maps/`.
- **High-degree concept nodes** in Nexus: `Foundation-Gate` (21 inbound), `Operator-Principles` (13), `Strategy-ORB` (12) — these are correctly serving as decision-anchors.
- **Demo-Mode** has only 2 inbound links despite being on-paper a binding operational state — under-wired given live-state importance.
- `00-claude-inbox/nexus/` and `00-claude-inbox/thesis/` subfolders exist but are empty (this report becomes the first entry under `nexus/`).
- `_promote-candidates/` and `90-archive/` are empty (just README scaffolding) — expected for a vault less than a week old (created 2026-05-08).

## Top 3 wiring improvements

### 1. Backfill the `_maps/*` orange nodes (33 dead targets)

The cognitive-OS MOCs are an empty promise right now: `Tools-MOC` references seven `MCP-*` notes that don't exist, `Decisions-MOC` references four `Decision-*` notes that don't exist, etc. Either:
- **Option A** (low effort): bulk-create one-line stub notes for all 33 dead targets so the graph stops bleeding orange — each stub gets a `> Pointer to <repo-source>.md` line and links back to its MOC.
- **Option B** (right but slow): operator picks the 5–10 most-referenced targets (`Operator-Nithu`, `Distillation-Hook`, `Session-Start-Hook`, `Obsidian-Bridge`, `Truth-Hierarchy`) and writes them properly; deletes the rest from the MOCs as out-of-scope.

Recommendation: B for the top 5, A for the long tail.

### 2. Treat business/career/learning stubs as a 30-min operator-fill session

All 21 stubs follow the same template. Operator could batch-fill the bare minimum (one paragraph + 2–3 real bullets each) in one Pomodoro and convert this cluster from "scaffolding" to "thin but real second brain". Right now Graph View shows three identical fan-out stars with no organic edges between leaves.

### 3. Add inbound-link nudges to high-leverage low-degree notes

Specifically:
- `Demo-Mode` (2 inbound) — every Module-* and Strategy-* note should link to it since the demo flag governs the runtime everywhere.
- `Phase-Status-Pointer` — currently a pure outbound note; the Strategy-* notes should link to it as "live state lives here".
- `Open-Questions` (3 inbound) — should be referenced from each Method / Concept note that prompted a question.

These three changes will lift average backlinks from ~6 → ~8 with maybe 15 edits.

## Audit confidence

- **High** on the MOC coverage check (full folder enumeration + grep diff).
- **High** on dead-link enumeration (filtered for code-snippet noise; all 33 are real `[[wiki-link]]` instances).
- **Medium** on stub identification — used the `> Stub — operator to fill` heuristic + line-count threshold; may slightly over-count if an operator-filled note kept the marker line by accident, may under-count if some thin atomic notes were not flagged with the marker.
- **Sample-based** for backlink-density estimate (20 notes). A full pairwise pass would tighten this.

## Related

- [[Tools-MOC]]
- [[Memory-MOC]]
- [[Decisions-MOC]]
- [[Nexus-MOC]]
- [[Thesis-MOC]]
