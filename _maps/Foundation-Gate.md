---
type: gate
status: ⚠️ GUL → 🟢 (target 2026-05-13)
last_verified: 2026-05-11
---
# Foundation Gate

5 rules that must all be 🟢 before adding new strategies. Per `docs/ops/new-strategy-gate.md`.

| # | Rule | Current | Why |
|---|---|---|---|
| 1 | No CRITICAL open problems | 🟢 | known-failures.md has 0 KRITISK |
| 2 | POSITION_MANAGEMENT_ENABLED=true | 🟡 | Functionally restored 2026-05-11 after metadata-strip fix (commit 0ad348f) |
| 3 | Last 3 builds OK | 🟢 | Railway clean since 20.4 |
| 4 | gate_decisions writing (≥7d × ≥50 evals/strategy) | 🟢 | 1951+ evals across 4 gates; last 2026-05-11 |
| 5 | 0 overdue Claude-owned followups | 🟡 | 2 overdue (was 7 before commit 1bb20f8); 1 may be superseded by nexus-pg MCP |

## Why this exists
Operator-prinsipp 4. Claude must refuse new-strategy work if any rule red — regardless of who's asking.

## Path to 🟢
- Rule 2: monitor next 7 days of trades — confirm new metadata fields populate
- Rule 5: resolve `wire-analysis-snapshots` + `per-strategy-sql-export-endpoint`

Linked to: [[Nexus-MOC]], [[Operator-Principles]], [[gate-silence-2026-05-08]], [[Truth-Hierarchy]], [[Karri]] (rule-2 / rule-5 mitigations route via [[Strategy-Proposal-Workflow]]), [[foundation-gate-state]], [[When-Foundation-Rule-Goes-Yellow]], [[Strategy-Promotion-Workflow]]
