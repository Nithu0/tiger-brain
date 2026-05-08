---
tags: [meta, moc-index]
type: meta
created: 2026-05-08
---

# _maps — folder convention

This folder holds **Maps of Content** (MOCs). A MOC is a hub note that indexes related thoughts so the graph forms clusters instead of flat hairballs.

## How MOCs work

- A MOC is a **table of contents**, not a treatise. Short descriptions, lots of links.
- Every MOC has frontmatter `tags: [moc, ...]` so they're queryable.
- Atomic notes link **back** to their MOC; MOCs link **out** to atomic notes. The bidirectional density is what makes Graph View readable.

## Link convention

- Always use `[[wiki-links]]` to other vault notes — never relative paths or markdown links to vault files.
- Stub-links (notes that don't exist yet) are intentional. They appear as orange unlinked nodes in Graph View — visible to-do markers.

## Current MOCs

[[Tools-MOC]] · [[Memory-MOC]] · [[People-MOC]] · [[Decisions-MOC]] · [[Workflows-MOC]]

Domain MOCs (operator-curated): [[Nexus-MOC]] · [[Thesis-MOC]] · [[Business-MOC]] · [[Career-MOC]] · [[Learning-MOC]].
