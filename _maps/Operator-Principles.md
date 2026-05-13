---
type: principle
canonical: true
last_revised: 2026-04-21
---
# Operator Principles (binding)

The 6 principles operator established 2026-04-21 for Nexus. All Claude sessions on all devices must respect these unless explicitly overridden in-session AND documented in phase-status.md "Midlertidige unntak".

1. **No auto-disable** of strategies, gates, or flags based on anomaly detection. Health-check REPORTS via Discord/morning briefing. Operator decides handling.
2. **Data must never stop.** Even during memory-cleanup: fact-agents, analysis-agents, persistence tables keep writing. Cleanup is on which types are kept, not whether anything writes.
3. **Small cleanup adjustments can be automatic** — dedupe, TTL, retention, low-value memory entry curation. NO behavior changes in the trading loop without operator-OK.
4. **Foundation-first**: before new strategy added, all 5 rules in `docs/ops/new-strategy-gate.md` must be green. Claude must refuse strategy work if any are red.
5. **"OK kjør"-gate** before every push. No exceptions.
6. **Self-fix/autotune is long-term.** Not earlier than 30+ days of data + explicit operator approval. Until then: report, don't act.

Linked to: [[Nexus-MOC]], [[Foundation-Gate]], [[Operator-Nithu]], [[Karri]]
