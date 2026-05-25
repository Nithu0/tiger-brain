---
title: How to drop a GitHub search query
type: howto
created: 2026-05-25
related:
  - "[[GITHUB_DISCOVERY_SPEC]]"
  - "[[github-discover]]"
  - "[[Runbook-Brain-Upgrade-Workflow]]"
tags: [howto, github, queue]
---

# How to drop a GitHub search query for discovery

1. Decide what you want to find (use [gh search syntax](https://cli.github.com/manual/gh_search_repos))
2. Create a new file in THIS folder:
   - Filename: `YYYY-MM-DDTHHMM-<short-slug>.md`
   - Content: frontmatter + optional notes

## Example file content
```
---
search: "agent orchestration TypeScript stars:>100 pushed:>2025-01-01"
limit: 5
topic: optional-topic-filter
why: "looking for Conductor-style implementations to learn from"
created: 2026-05-25T13:00Z
---
```

## What happens next
- BrainOrchestrator's `github-discovery` trigger picks up new files (when brain-G6 activated; manual `/skill github-discover query=<q>` until then)
- For each repo above relevance threshold (0.7):
  - Distilled note → `13-github-repos/<owner>-<name>.md`
  - If `relevance > 0.7 AND license_compatible AND risk < 0.4`: implementation-task proposed to `10-tasks/_open/` (operator OK kjør required to act)

## License policy (enforced)
- MIT, BSD-2/3, Apache-2.0, ISC, MPL-2.0 → ✓ compatible, can propose implementation
- GPL-2.0, GPL-3.0, AGPL-3.0 → ✗ blocked from implementation-tasks (note still created)
- LGPL → needs manual review
- Unknown → needs manual review

## Security
- NEVER clones repos
- NEVER executes code
- Only fetches: README + manifest (package.json/Cargo.toml/pyproject.toml/requirements.txt) via gh API

## Rate limits
- 50 search calls/day
- 20 extract calls/day
- 60s cooldown between calls

## Related
- Skill: `[[github-discover]]`
- Spec: `[[GITHUB_DISCOVERY_SPEC]]`
- Folder: `[[13-github-repos/README]]`
