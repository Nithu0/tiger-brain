---
tags: [moc, decisions]
type: moc
created: 2026-05-08
---

# Decisions-MOC

Index of binding architectural and operational decisions for the cognitive OS rollout. Source-of-truth lives in the Nexus repo at `docs/ops/operator-decisions.md` (append-only) and `docs/architecture/`. This MOC mirrors the index for graph traversal — never edit decisions here, always at the source.

## Bedrock — operator-prinsipper (2026-04-21)

[[Operator-Principles]] — six binding rules. Apply on all devices, all sessions.
1. No auto-disable of strategies / gates / flags from anomaly detection.
2. Data is never stopped — even mid-cleanup.
3. Small janitorial tweaks may be automatic; behavioural changes need operator-OK.
4. Foundation-first: all 5 rules in `new-strategy-gate.md` green before new strategy work.
5. "OK kjør"-gate before every push.
6. Self-fix / autotune is long-horizon (30+ days data + explicit OK).

Source: `docs/ops/operator-decisions.md` → "2026-04-21: Six binding operator-prinsipper".

## Cognitive-OS rollout (2026-05-08 batch)

- [[Decision-Strategy-Review-Pipeline]] — money-impact changes go through `docs/strategy/proposals/` for Karri review before implementation. Counter-signal: "bare fix det" / "kjør på" implements directly with retroactive proposal.
- [[Decision-Tools-Roster-Habit]] — Claude must consult `reference_available_tools.md` and `docs/ref/claude-code-capabilities.md` before proposing manual workarounds. Update roster same-session when new MCP added.
- [[Decision-No-Auto-Activation]] — never flip Railway flags / send Discord / push without explicit "OK kjør". Status-report-without-acting is the correct shape.
- [[Decision-Stack-Deliveries]] — "one change per session" cap removed 2026-05-03. Stack deliveries when sensible.

## Architecture decisions (design docs)

- [[Obsidian-Bridge]] — vault structure, write boundaries, symlink mirrors, promote workflow. Source: `docs/architecture/obsidian-bridge.md`.
- [[Distillation-Hook]] — Stop-hook auto-curates session memory via Haiku. Idempotent, budget-capped, never auto-promotes. DRY-RUN until activation. Source: `docs/architecture/distillation-hook.md`.
- [[Session-Start-Hook]] — SessionStart hook injects ~1500-token verified state snapshot. Reports only — never acts. Source: `docs/architecture/session-start-hook.md`.
- [[Model-Routing]] — Claude orchestrator + Codex / Gemini specialists. Bounded delegation rules. Source: `docs/architecture/model-routing.md`.
- [[Secrets-Policy]] — allowed / not-allowed list for `.env*`, `~/.ssh/**`, `.git/config`. Source: `docs/architecture/secrets-policy.md`.
- [[Permissions-Diff]] — proposed `.claude/settings.json` diff (allow / deny / ask buckets). Source: `docs/architecture/permissions-diff.md`.
- [[Cross-Project-Pollution-Audit]] — 5 leaks found, thesis → Nexus asymmetry. Source: `docs/architecture/cross-project-fixes.md`.

## Related

[[Tools-MOC]] · [[Memory-MOC]] · [[Workflows-MOC]] · [[People-MOC]]
