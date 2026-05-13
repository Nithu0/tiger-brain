---
type: workflow
status: dry-run
created: 2026-05-11
---
# Distillation-Stop-Hook

Stop-hook that runs at Claude session end to auto-curate session memory via Haiku.

## Behavior
- Hook script: `scripts/hooks/distill.sh` (currently `.dryrun` — not active).
- Runs Haiku over the transcript with `distill-prompt.md`.
- Appends durable lessons to `docs/memory/daily/YYYY-MM-DD.md`.
- Queues promotion candidates in `docs/memory/PROMOTE_QUEUE.md`.

## Guard rails
- Idempotent via SHA-12 marker — won't re-run for the same transcript.
- Budget-capped at $0.10/run.
- Never auto-commits, never auto-promotes (per [[Operator-Principles]] rule 3).

## Status
DRY-RUN until activation. `.dryrun` extension blocks accidental enablement.

Source: `docs/architecture/distillation-hook.md`.

Linked to: [[Workflows-MOC]], [[Distillation-Hook]], [[Memory-Lifecycle]], [[Memory-MOC]], [[Promote-Inbox-To-Repo]]
