---
type: hook
status: active
trigger: Stop event
---
# Distillation Hook

Stop-event hook (configured in `~/.claude/settings.json`) that runs `scripts/hooks/distill.sh` after a session ends. Purpose: extract noteworthy observations from the just-ended session into the promote-queue for later memory promotion.

## Status (2026-05-11)
- Registered: yes
- Currently in: DRY_RUN mode (per earlier audit) — verify if activated

## Where output lands
- `docs/memory/PROMOTE_QUEUE.md` — proposed memory entries
- Obsidian `00-claude-inbox/` and `_promote-candidates/`

Linked to: [[Memory-MOC]], [[Session-Start-Hook]], [[Truth-Hierarchy]]
