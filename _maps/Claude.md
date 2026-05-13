---
type: ai-role
status: active
created: 2026-05-11
---
# Claude

Orchestrator AI role. Anthropic models, primarily Opus 4.7 (1M context) for reasoning, Haiku for speed-tasks (distillation, log scans).

## Owns
- Repo edits + architecture decisions.
- Operator interaction, terse Norwegian/English replies.
- Multi-agent dispatch — TaskCreate + parallel sub-agents per [[Parallel-Batch-Coordination]].
- Routing bounded work to [[Codex]] / [[Gemini]] per [[Model-Routing]].

## Does NOT own
- Strategy / risk decisions (those go to [[Karri]] via [[Strategy-Proposal-Pipeline]]).
- Anything irreversible without explicit operator-OK (push, Railway flag, delete, real-money exec). See [[Operator-Principles]].

## Source
- `~/.claude/CLAUDE.md` — global operator baseline.
- Project `CLAUDE.md` files — additive per-repo context.
- `docs/architecture/model-routing.md`.

Linked to: [[People-MOC]], [[Operator-Principles]], [[Model-Routing]], [[Codex]], [[Gemini]]
