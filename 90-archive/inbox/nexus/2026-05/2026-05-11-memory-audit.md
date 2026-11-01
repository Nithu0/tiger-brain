---
date: 2026-05-11
type: audit
project: nexus
agent: memory-deep-audit
---

# Memory deep audit — 2026-05-11

**Total memory files:** 27 active. Well-organized, few stale claims. No hard contradictions.

## Recommended actions (operator decides)

### Merges
1. **`user-orchestration-style.md` → `user_personality.md`** — 70% overlap, consolidate into single behavioral profile. Then remove from MEMORY.md index.

### Deduplication
2. **`reference_available_tools.md`** lines 40-46 duplicate the endpoint list now canonical in `reference-railway-api.md`. Replace with one-line cross-reference.

### Updates
3. **`agentic_team_activation_state.md`** — has resolved ambiguity about trade-critic/daily-journal silence. Replace speculation with "✓ Verified live 2026-05-06: silence is normal within cooldown."
4. **`cognitive_os_state.md`** — has stale claim about Obsidian Local REST API "pending operator setup". Now installed + connected. Update.

### Archive candidates
5. **`session_2026-05-03_summary.md`** — pure historical record, all changes shipped, no forward dependency. Move to `memory/archived/`.
6. **`audit_04may_pickup.md`** — superseded by `session_2026-05-07_summary.md` and `docs/ops/audit-2026-05-07-pickup.md`. Archive with forwarding pointer.

### Cross-references (low-priority)
7. **`n8n_integration_pickup.md`** — add pointer to `reference_available_tools.md` for tool context.

## Highest-value memories to lock-in (never delete)

1. `user_personality.md` — operator working style, frustration patterns
2. `feedback-explicit-where-and-what.md` — prevents PowerShell-vs-bash parser errors
3. `reference-railway-api.md` — canonical URLs (prevents fabrication incidents like nexus-production hallucination today)
4. `feedback_default_parallel_subagents.md` — core operating discipline
5. `agentic_team_activation_state.md` — live agent roster + verification method

## Stale/resolved ambiguity to clean up

- Agent silence speculation in `agentic_team_activation_state.md` — resolved 06.5 but text not updated
- Obsidian setup pending-state in `cognitive_os_state.md` — now done

## Bottom line

Memory health is **good**. The 2026-05-07/08 sessions did disciplined memory-update work. Main risk is gradual divergence between `reference_available_tools.md` and the actual MCP/URL state — set a recurring (weekly) verification pass.

---
Linked to: [[Memory-MOC]], [[Nexus-MOC]]
