---
title: "anthropics/claude-code"
repo: https://github.com/anthropics/claude-code
owner: anthropics
name: claude-code
stars: 12500
forks: 1234
last_commit: 2026-05-24T18:00:00Z
primary_language: TypeScript
license: MIT
license_compatible: true
discovered: 2026-05-25T13:00:00Z
query_source: "claude code Anthropic"
relevance_score: 0.95
activity_score: 0.92
risk_score: 0.05
integration_difficulty: low
has_install_script: false
has_postinstall_hook: false
security_red_flags: []
tags: [github, sample, claude, anthropic, agent]
---

# anthropics/claude-code

> **NOTE:** This is a SAMPLE for spec-demo purposes. Real discovery from real query goes through `/skill github-discover`.

## Repo summary
Official Anthropic CLI for the Claude API + agent SDK. Open source MIT. Active maintenance. Reference implementation for AI-coding CLIs.

## Useful patterns to copy conceptually
- Tool-use loop pattern
- Plan mode + edit-confirmation gates
- Slash-command framework
- MCP server integration

## Dependencies + integration cost
- Node 18+
- Anthropic SDK
- Light deps; easy to study, harder to fork (large + actively maintained)

## Install risk assessment
- License: MIT ✓
- No postinstall hooks ✓
- No suspicious scripts in package.json ✓
- Risk score: 0.05 (very low)

## Suggested tasks for our repo
- Operator may already use this — verify in `~/.claude/`
- Conceptual patterns for our `@cc/agents` package

## Related
- [[GITHUB_DISCOVERY_SPEC]]
- [[Packages-MOC]]
