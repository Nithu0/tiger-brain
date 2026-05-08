---
tags: [moc, workflows, ops]
type: moc
created: 2026-05-08
---

# Workflows-MOC

Operator's recurring workflows. Each entry: when triggered, what happens, where to look.

## [[Firm-Up-Max-Mode]]
- **Trigger:** operator types `firm-up` (alias) in terminal.
- **What:** Launches the zellij firm-mirror — multiple Claude terminals tiled, each scoped to a firm-agent role. Robust env loader pre-flight runs first; debug ladder at `reference_firm_up_entry.md`.
- **Where to look:** `docs/ref/local-firm-mirror.md` (Phase 4 / 5 design); `firm-up` shell function in operator's dotfiles.

## [[Parallel-Batch-Coordination]]
- **Trigger:** any non-trivial multi-file task. Default per `feedback_default_parallel_subagents.md`.
- **What:** Operator runs 2–4 parallel Claude terminals against the same repo, coordinated via a shared spec at `docs/ops/parallel-*-batch.md` with disjoint file ownership per terminal. Cross-terminal context forwarded by pasting transcripts.
- **Where to look:** `parallel_batch_pattern.md` memory; recent example in `session_2026-05-03_summary.md`.

## [[OK-Kjor-Autonomous-Execute]]
- **Trigger:** operator says "OK kjør", "kjør alle", "kjør på", "letsgooo", "BYGG ALT", "max".
- **What:** Claude switches from propose-mode to execute-mode. Picks the highest-value bounded item from any pending options list, ships it, reports terse summary. Still subject to [[Operator-Principles]] — does NOT bypass irreversible-action gates.
- **Where to look:** [[People-MOC]] → Operator-Nithu; `user-orchestration-style.md` memory.

## [[Strategy-Proposal-Pipeline]]
- **Trigger:** any money-impact change (thresholds, sizing, gate logic, new strategies, position-management defaults).
- **What:** Claude writes `docs/strategy/proposals/YYYY-MM-DD_<slug>.md` using template at `proposals/README.md`. Status flows: proposed → approved → implemented (with commit SHA) → archived. Operator forwards to [[Karri]] via Discord webhook with structured embed (Hva data viser, Root cause, Forslag, etc). Claude does NOT implement until operator confirms approval.
- **Counter-signal:** "bare fix det" / "kjør på" inline → implement directly, file retroactive proposal as `Status: implemented (approved-verbally)`.
- **Where to look:** [[Decisions-MOC]] → Decision-Strategy-Review-Pipeline.

## [[Distillation-Stop-Hook]]
- **Trigger:** Claude session ends (Stop hook).
- **What:** `scripts/hooks/distill.sh` runs Haiku over the transcript with `distill-prompt.md`, appends durable lessons to `docs/memory/daily/YYYY-MM-DD.md`, and queues promotion candidates in `docs/memory/PROMOTE_QUEUE.md`. Idempotent via SHA-12 marker. Budget-capped at $0.10/run. Never auto-commits, never auto-promotes.
- **Status:** DRY-RUN — `.dryrun` extension blocks accidental activation.
- **Where to look:** `docs/architecture/distillation-hook.md`.

## [[Promote-Inbox-To-Repo]]
- **Trigger:** operator reviews `00-claude-inbox/` in Obsidian and finds something durable.
- **What:** Move note to `_promote-candidates/<YYYY-MM-DD>-<slug>.md` → operator (or Claude with explicit "OK kjør") commits polished version to `docs/memory/promoted/<slug>.md` in the relevant repo. Inbox auto-archives after 30 days into `90-archive/inbox/<YYYY-MM>/`.
- **Where to look:** `docs/architecture/obsidian-bridge.md` → Promote workflow.

## Related

[[Tools-MOC]] · [[People-MOC]] · [[Decisions-MOC]] · [[Memory-MOC]]
