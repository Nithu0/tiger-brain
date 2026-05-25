---
name: github-discover
description: Run github-discovery on a query (or drain the queue) — searches gh, scores repos, distills top-N into brain notes
tier: brain
project_scope: workspace
when_to_use: operator drops a query in `13-github-repos/_queue/`, OR runs manually with a search string; keywords "find repos", "discover library", "gh search", "scout github"
inputs:
  - name: query
    type: string
    required: false
    default: drain-queue
  - name: limit
    type: number
    required: false
    default: 5
  - name: min_stars
    type: number
    required: false
    default: 100
outputs:
  - notes_written: array
  - scored_count: number
  - blocked_by_license: array
  - rate_limit_remaining: number
tools_required: [Bash, Write, Read]
cost_estimate: medium
cache_strategy: persistent
auto_invocable: false
created: 2026-05-25
created_by: operator
confidence: 0.7
validation_passes: 0
related: ["[[SKILL_REGISTRY_SPEC]]", "[[GITHUB_DISCOVERY_SPEC]]", "[[2026-05-25-brain-upgrade-plan]]"]
tags: [skill, brain, github, discovery, research]
---

## Purpose

Discover GitHub repositories relevant to an operator query via `gh search repos`, score the hits by relevance + activity + license + risk, fetch top-N READMEs and manifest files, and distill each into a brain note at `13-github-repos/<owner-name>.md`. The skill never clones or executes repo code — only metadata + README + manifest extraction. License-gating blocks GPL-incompatible repos when dependency policy demands it.

## When to use

- Operator drops a query file into `13-github-repos/_queue/<query-slug>.txt`
- Manual invocation when scouting libraries before adopting a dependency
- Periodic ecosystem-watch (weekly run with curated queries)
- **Anti-patterns:** never clone+run a repo (security); never auto-add a repo as dependency without operator approval; never exceed daily rate-limit cap (50 search-calls / 20 extract-calls)

## Inputs

| Arg | Type | Required | Default | Notes |
|---|---|---|---|---|
| `query` | string | no | drain-queue | gh-search syntax, e.g. `agent orchestration TypeScript stars:>100` |
| `limit` | number | no | 5 | Max repos to extract (cap at 10) |
| `min_stars` | number | no | 100 | Filter floor for stars |

## Steps

1. Resolve input: if `query` given, use it; else iterate files in `13-github-repos/_queue/`
2. Check rate-limit budget in `firm_state` KV: `github_discovery_calls_today`; abort if exceeded
3. Run `gh search repos "<query>" --json fullName,description,stars,updatedAt,license,url --limit 30`
4. Score each hit: relevance (LLM 0-1) + activity (months-since-update) + license (allow/warn/block) + risk (postinstall scripts, install_script presence in `package.json`)
5. Take top-N by composite score (default 5)
6. For each, fetch README via `gh api repos/<owner>/<name>/readme --jq .content | base64 -d`
7. Fetch manifest (`package.json`, `Cargo.toml`, `pyproject.toml`) via `gh api`
8. Call memory-engine distill on README + manifest combined
9. Write distilled note to `13-github-repos/<owner-name>.md` with frontmatter (`url`, `stars`, `license`, `last_commit`, `score`, `confidence`)
10. Increment rate-limit counter in `firm_state`; remove queue file on success

## Tools / commands

```bash
# Manual search
gh search repos "agent orchestration TypeScript stars:>100" \
  --json fullName,description,stars,updatedAt,license,url --limit 30

# Fetch README
gh api repos/anthropics/claude-code/readme --jq .content | base64 -d

# Fetch manifest
gh api repos/anthropics/claude-code/contents/package.json --jq .content | base64 -d

# Drain queue
for f in /home/nithu/Obsidian/Brain/13-github-repos/_queue/*.txt; do
  /home/nithu/code/command-center/_bin/github-discover.sh --query "$(cat "$f")"
done
```

## Pitfalls

- GPL-block — if license is `GPL-3.0` and our policy is MIT/Apache, write distilled note but flag `dependency_eligible: false`
- Rate-limit exhaustion — gh API has 5000/hour authenticated; track in `firm_state` to stay well under
- Abandoned-with-stars (red flag) — high stars + last commit > 18 months = warn in distilled note
- README in non-English — distill-LLM may degrade; flag with low confidence
- Repo with `install_script` or `postinstall` in `package.json` — flag in note as "security-risk: requires-review"
- Owner-name collision (e.g. `react` exists under many owners) — disambiguate via owner prefix in filename

## Validation checks

1. Distilled note exists at `13-github-repos/<owner-name>.md` for each top-N hit
2. Each note has frontmatter with `url`, `stars`, `license`, `score`
3. `rate_limit_remaining` returned and decrement persisted in `firm_state`
4. License-blocked repos appear in `blocked_by_license` output AND have a note with `dependency_eligible: false`
5. No repo was cloned or executed (audit: `git worktree list` shows no new entries from this skill)

## Example usage

```
/skill github-discover query="agent orchestration TypeScript stars:>100" limit=5
```

Drain queue:

```
/skill github-discover
```

Tighter discovery:

```
/skill github-discover query="rust embedded async" limit=3 min_stars=500
```

## Related

- [[SKILL_REGISTRY_SPEC]]
- [[GITHUB_DISCOVERY_SPEC]]
- [[2026-05-25-brain-upgrade-plan]]
- [[youtube-ingest]]
- [[OBSIDIAN_BRAIN_STRUCTURE]]
