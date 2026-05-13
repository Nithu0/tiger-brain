---
type: decision-tree
trigger: documentation states X, code does Y, and the two disagree on observable behaviour
autonomy_level: fix-locally
---
# When Doc Drifts From Code

## Trigger
While answering an operator question or running an audit, Claude finds a doc (`docs/ref/*.md`, `docs/ops/*.md`, an Obsidian MOC, `.env.example`, `CLAUDE.md`) that claims behaviour X, but reading the code or running the system shows behaviour Y.

This is one of the most common operability incidents — gate-silence-2026-05-08 was fundamentally a `.env.example` drift.

## Truth hierarchy (binding)
Per [[Truth-Hierarchy]], when sources disagree:
1. Codebase + git history (highest)
2. `phase-status.md`
3. `operator-decisions.md` (append-only)
4. Promoted memory (`reference_*.md`)
5. Daily memory (RAW)
6. Raw scratchpads / inbox notes
7. Archived (lowest)

**Code wins.** Always. Doc gets updated to match — never the other way around without a code change AND operator-OK.

## Diagnose order
1. **Confirm the drift is real, not a misread**: read both sides cold. Quote them side-by-side in your head.
2. **Identify the right truth layer**: a `.env.example` claim is layer 1-adjacent (it should mirror code). A `docs/ref/` claim is layer 1-adjacent. An old `00-claude-inbox/` note is layer 6 — it can lag without anything being broken.
3. **Check git log** on the doc file: was it written before a refactor? Recent commits to the code side often explain the drift.
4. **Establish scope**: does the drift change operator behaviour? A wrong `.env.example` means operator doesn't flip a flag = silent feature. A wrong inbox-note from 2 weeks ago changes nothing live.

## Action by classification
- **Doc lags code, no money-impact**: fix locally + commit. Pure cleanup. No proposal, no operator wait beyond [[OK-Kjor-Gate]].
- **`.env.example` missing a flag**: fix locally + commit. High-priority because it gates operator visibility. See [[When-Gate-Goes-Silent]] for why.
- **`phase-status.md` is wrong about live state**: refresh from `/health` + `/operator/readiness` + last commits. Don't fabricate.
- **CLAUDE.md drift** (pointers to docs that have moved / been renamed): fix the pointers, commit. Do NOT rewrite content — that's a separate exercise.
- **Code seems wrong, doc seems right** (operator might prefer the documented behaviour): flag as a bug, file proposal if it's money-impact, otherwise fix code to match doc + commit.
- **Strategy-touch implied** (the doc says we use stop X, code uses stop Y, and we're debating which is right) → [[When-Strategy-Change-Tempting]]. Karri.

## What to preserve when updating docs
- Decision history. If the doc was right at a point in time, note the date the behaviour changed.
- Operator-facing language. Don't replace operator's voice with Claude's.
- Cross-links. Update the wiki-link graph in Obsidian; don't leave dangling.
- Append-only files (`operator-decisions.md`): never edit past entries. Add a new dated entry.

## Examples from past sessions
- **`.env.example` 156 missing vars (2026-05-11)**: a sweep against actual code-referenced env vars found 156 not in `.env.example`. Synced in commit 937bd30. Same sweep would have prevented [[gate-silence-2026-05-08]].
- **Phase-status refresh ops/08.5**: phase-status drifted from live state during a multi-week sprint; refresh shipped in 3ab8b61.

## Linked
[[Operator-Principles]] · [[Truth-Hierarchy]] · [[Phase-Status-Pointer]] · [[Foundation-Gate]] (doc-drift on `phase-status.md` directly impacts gate accuracy) · [[gate-silence-2026-05-08]] · [[When-Gate-Goes-Silent]] · [[When-Strategy-Change-Tempting]]
