---
type: hook
status: active
trigger: SessionStart, SessionStart:resume, SessionStart:compact
---
# Session Start Hook

SessionStart hook (configured in `~/.claude/settings.json`) that runs `scripts/hooks/session-start.sh`. Purpose: load 6000-char snapshot of current repo state at session start so Claude has up-to-date context without burning tokens reading docs/ops files manually.

## What it loads
- Current branch + working tree
- Recent commits (3 most recent)
- Top 30 lines of `docs/ops/phase-status.md`
- Open operator decisions
- Run mode (from .env.example, not secrets)
- Recent promoted memory
- Stale TIER docs
- Required env-var names (NO values)

## Token budget
6000-char cap to stay within context budget.

Linked to: [[Memory-MOC]], [[Distillation-Hook]], [[Truth-Hierarchy]]
