---
tags: [decision-tree, meta, brain]
type: decision
created: 2026-05-13
---
# When-Brain-Structure-Drifts

## Trigger
The vault itself has drifted — Claude or operator notices one or more of:
- Broken wikilinks past threshold (audit reports > N dangling targets)
- Orphan files appear (notes with zero inbound links sitting outside `00-claude-inbox/`)
- MOCs go stale (`_maps/*-MOC.md` not updated in > 30 days while underlying area kept moving)
- `_promote-candidates/` backlog builds up (inbox notes flagged for promotion but not acted on)
- `00-claude-inbox/` > 200 files
- `claude-context/CURRENT.md` not updated in > 7 days
- `python3 scripts/brain_audit.py` warnings > 30

This is a **meta-incident**: the structure that lets Claude navigate the vault has degraded. Default posture: **stop adding more notes, repair structure first.**

## Do Y
1. **Stop and read** `BRAIN-RULES.md` + `claude-context/RULES.md`. Refresh on naming conventions, folder roles, frontmatter requirements, link conventions. Do NOT skip — most drift comes from forgetting these.
2. **Run baseline audit**: `python3 scripts/brain_audit.py`. Capture the numbers (broken links, orphans, stale MOCs, inbox count). This is the before-snapshot.
3. **If broken wikilinks**: enumerate with `grep -rn '\[\[' --include='*.md' /home/nithu/Obsidian/Brain/`. For each dangling target, choose ONE of:
   - Fix target (the file was renamed → update the link)
   - Escape with backticks (the link was illustrative, not a real reference)
   - Delete the link (the linked concept no longer applies)
   Do not mass-fix — each broken link is a decision.
4. **If inbox > threshold**: run `python3 scripts/archive_old_inbox.py --apply`. Script moves notes older than the configured window into `90-archive/`. Inspect script's report before re-running.
5. **If MOC stale** (> 30 days no update): refresh per `_maps/_README.md` conventions. Walk the underlying folder, list new notes, drop them into the MOC's "Recent" / "By topic" sections. Do not rewrite the MOC end-to-end — that destroys link continuity.
6. **If `CURRENT.md` stale**: re-read `docs/ops/phase-status.md` (or the project's equivalent live-state doc) and **rewrite `CURRENT.md`** — do not append. `CURRENT.md` is a snapshot, not a log.
7. **If structural drift** (folders renamed, new top-level project added, naming convention changed): update **both** `SYSTEM-AUDIT.md` AND `claude-context/SYSTEM-MAP.md`. These two files are the canonical map; if they disagree, the vault is unnavigable.
8. **Re-run audit**: `python3 scripts/brain_audit.py`. Compare against step-2 baseline. Should be back below threshold. If not, identify which specific category did not improve and loop back to the matching step.

## Anti-patterns (do NOT)
- **Mass-restructure** in one session — small, reversible moves only. Big restructures lose history and break operator's muscle memory.
- **Rename MOCs** — wiki-link graph relies on these names. Rename = orphan every inbound link.
- **Mass-delete inbox** without archiving — `archive_old_inbox.py` exists for a reason. Notes belong in `90-archive/`, not `/dev/null`.
- **Push to main directly** — brain repo follows the same `[[Runbook-Push-Cycle]]` discipline as code repos. Operator gates the push.
- **Add new top-level folders** without updating `SYSTEM-AUDIT.md` + `SYSTEM-MAP.md` + `BRAIN-RULES.md`. New folders without map entries are invisible to future Claude sessions.

## Related
[[When-Doc-Drifts-From-Code]] · [[When-Operator-Says-Kjor-Pa]] · [[Runbook-Push-Cycle]]

Sist oppdatert: 2026-05-13
