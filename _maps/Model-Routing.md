---
type: architecture-pointer
status: active
created: 2026-05-11
target: docs/architecture/model-routing.md
---
# Model-Routing

[[Claude]] is the orchestrator. [[Codex]] and [[Gemini]] are bounded specialists Claude delegates to. Routing rules + provider-failure fallbacks live at `docs/architecture/model-routing.md`.

## Core rules
- Reasoning + operator interaction + architecture → Claude (Opus 4.7).
- Speed-tasks (distillation, log greps, summaries) → Claude (Haiku).
- Bounded code-implementation with concrete spec → [[Codex]].
- Bounded research tasks → [[Gemini]].

## Runtime router
`apps/worker/src/services/llm-router.service.ts` — provider selection + retry / failover for firm-agent calls. Different layer from this orchestration routing (this doc is about the human-facing dev workflow; the router is about production firm-agent LLM calls).

## Source
- `docs/architecture/model-routing.md` (delegation rules).
- `apps/worker/src/services/llm-router.service.ts` (runtime provider selection).

Linked to: [[Decisions-MOC]], [[People-MOC]], [[Claude]], [[Codex]], [[Gemini]]
