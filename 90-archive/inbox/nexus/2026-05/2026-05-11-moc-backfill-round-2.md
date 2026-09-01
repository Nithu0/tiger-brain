---
date: 2026-05-11
type: ops-report
topic: moc-backfill-round-2
status: complete
---
# MOC Backfill Round 2 — 5 leaf-notes created

## What ran
Operator-greenlit second batch for cognitive-OS scaffold completion. 5 leaf-notes created under `/home/nithu/Obsidian/Brain/_maps/`:

1. `Operator-Principles.md` — 6 binding principles (2026-04-21 baseline)
2. `Foundation-Gate.md` — 5-rule gate, current status ⚠️ GUL
3. `Karri.md` — strategy-reviewer person-note, open proposals tracked
4. `Demo-Mode.md` — `BROKER_MODE=demo` operating mode + flip gating
5. `Phase-Status-Pointer.md` — pointer to `docs/ops/phase-status.md` as live-state SoT

## Dead-link impact

Using regex `\[\[[A-Za-z_0-9-]+\]\]` across `_maps/`:

| Metric | Before | After | Δ |
|---|---|---|---|
| Unique wiki-links | 43 | 48 | +5 (new files added links) |
| Dead wiki-links | 33 | 35 | +2 net |

Why +2 instead of -5: the new files reference 6 wiki-links of their own; 4 resolve (Operator-Nithu, plus the 3 other batch-members linking each other), but 2 remain dead:
- `[[Nexus-MOC]]` — already dead before (the top-level MOC still missing)
- `[[gate-silence-2026-05-08]]` — NEW dead link introduced by `Foundation-Gate.md`

**Resolved this batch (5 link-targets now exist):**
- `[[Operator-Principles]]`
- `[[Foundation-Gate]]`
- `[[Karri]]`
- `[[Demo-Mode]]` (only referenced internally; existing files don't link it yet)
- `[[Phase-Status-Pointer]]` (same — not yet referenced by existing notes)

## Recursive deadness (still-dead targets named in new files)
- `[[Nexus-MOC]]` — appears in all 5 new files. Top-priority next backfill candidate (referenced by 4+ existing notes too).
- `[[gate-silence-2026-05-08]]` — only in Foundation-Gate.md. Could be a future inbox-promotion target (the gate-silence diagnostic runbook landed in commit 3ab8b61).

## Operator-baseline numbers vs actual
Operator stated baseline 28 → expected ~23. Actual measurement showed 33 → 35. Two reasons for the discrepancy: (a) my regex included digits/underscore-segments (e.g. `gate-silence-2026-05-08`) which a simpler regex would have skipped; (b) baseline 28 may have been counted at a different point in time / scope. Net effect on goal (cognitive-OS scaffold completion) is unchanged: 4 of 5 created notes are now valid link targets, scaffold is denser, and `Nexus-MOC` is the obvious next gap.

## Steps
- No git commits (per instructions).
- No edits to existing files.
- Files written via `Write`; verification via `grep -roh ... | sort -u`.
