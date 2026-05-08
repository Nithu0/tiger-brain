---
tags: [moc, people]
type: moc
created: 2026-05-08
---

# People-MOC

Humans and AI roles in operator's network. Each entry: role, communication channel, what they own.

## Humans

### [[Karri]]
- **Role:** Strategy / risk owner on Nexus XAUUSD.
- **Owns:** Review of all money-impact changes (thresholds, sizing, gate logic, new strategies). Filed in `docs/strategy/proposals/` with `Reviewer: Karri` in frontmatter.
- **Channel:** Discord webhook to `#strategy-review`. Send only when operator triggers ("send det til Karri", "shoot melding til Karri") — never auto-send.
- **Style:** Casual NO/EN mix. Embed format with sections: Hva data viser, Root cause, Forslag, Alternativer vurdert, Strategisk vurdering, Spørsmål til reviewer, Rollback.
- See [[Decisions-MOC]] → 2026-05-08 strategy-review decision.

### [[Thesis-Advisor]]
- **Role:** Master's-thesis advisor at NTNU (battery electrolyte ML).
- **Owns:** Thesis scope, methodology approval, chapter sign-off.
- **Channel:** *(operator to fill in — name, email, meeting cadence)*
- Stub for operator to expand.

### [[Operator-Nithu]]
- **Role:** Owns ops + infra across all projects.
- **Style:** Mixed Norwegian / English. Terse. "OK kjør" / "kjør alle" / "letsgooo" / "BYGG ALT" / "max" = autonomous-execute trigger. "skjerp deg" / "kronglete" / "irriterende" = recheck approach + simplify.
- Runs 2–4 parallel Claude terminals as a "firm" — see [[Workflows-MOC]] → parallel-batch.

## AI roles

### [[Claude]]
- **Role:** Orchestrator. Reasoning, repo edits, architecture decisions, operator interaction.
- **Models:** Opus 4.7 (1M context) for reasoning; Haiku for speed-tasks like distillation.
- **Boundaries:** Operator-gated for anything irreversible. See [[Operator-Principles]].

### [[Gemini]]
- **Role:** Research dispatcher / specialist for bounded research tasks.
- **Status:** Routing config'd in `docs/architecture/model-routing.md`; CLI availability operator-confirmed.

### [[Codex]]
- **Role:** Bounded code-implementation specialist (refactors, test writing, pattern-matched bulk edits).
- **Status:** Routing config'd; CLI availability operator-confirmed.

## Related

[[Tools-MOC]] · [[Workflows-MOC]] · [[Decisions-MOC]]
