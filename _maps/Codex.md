---
type: ai-role
status: routing-configured
created: 2026-05-11
---
# Codex

Bounded code-implementation specialist. Dispatched by [[Claude]] for refactors, test writing, pattern-matched bulk edits where the spec is concrete and behaviour-preserving.

## Owns
- Pattern-matched edits across many files (e.g. rename, add typed wrapper everywhere).
- Test scaffolding when the design is settled.
- Mechanical refactors that orchestrator-Claude could do but is cheaper to delegate.

## Does NOT own
- Architecture decisions.
- Strategy / money-impact changes.
- Operator interaction (Claude is the operator's interface).

## Status
Routing rules in `docs/architecture/model-routing.md`. CLI availability operator-confirmed. Delegation is bounded — Claude writes the spec, Codex executes within it.

Linked to: [[People-MOC]], [[Model-Routing]], [[Claude]], [[Gemini]]
