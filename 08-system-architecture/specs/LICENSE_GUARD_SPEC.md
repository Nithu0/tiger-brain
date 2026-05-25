---
title: License Guard Spec (stub)
date: 2026-05-25
status: stub — TBD (v0.0.1)
spec_for: GitHub Discovery license enforcement (currently inline in GITHUB_DISCOVERY_SPEC §5)
related:
  - "[[GITHUB_DISCOVERY_SPEC]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
tags:
  - spec
  - license
  - stub
---

# License Guard Spec — stub

Detailed license-policy spec deferred. Currently implemented inline in `[[GITHUB_DISCOVERY_SPEC]]` §5 (SPDX-based hardcoded table).

## To detail later
- Full SPDX taxonomy + edge cases (LGPL static vs dynamic linking, MPL file-level)
- License change detection (re-check on repo update)
- Operator override workflow (manually flag GPL as acceptable for specific use)
- LICENSE-file content parsing fallback when SPDX field missing

Stub created 2026-05-25 by D-8 to resolve wikilink in `[[GITHUB_DISCOVERY_SPEC]]`.

## Changelog
- 2026-05-25 v0.0.1 — frontmatter YAML fix (block-list form): converted inline `related: [[X]], [[Y]]` flow-list to block-list with quoted wikilink strings; converted inline `tags: [...]` flow-list to block-list; introduced explicit stub-version marker `v0.0.1` in status (no body change).
