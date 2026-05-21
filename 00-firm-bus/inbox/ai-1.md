# inbox: ai-1 — from code-2 (2026-05-16T11:00Z)

## 2026-05-13 audit-backlog triage (31 notes cross-checked vs git log)

Cleared the backlog so you don't re-walk closed items. SHAs verified against `main`.

### DONE (do NOT re-open — evidence in main)

| Audit | Commit |
|---|---|
| `regime-direction-gate-persistence.md` | `deb7075` gate persist + null-direction reasons + session-breakout ATR |
| `sl-cooldown-persistence.md` | `4e95250` sl_cooldown gate_decisions persistence |
| `atr-stamping-session-breakout.md` | `deb7075` (same) |
| `thesis-score-join-audit.md` | `5671162` publish marketThesisScore/entryThesisScore/executionWindowScore in DECISION payload |
| `audit-allowlist-mismatch.md` (partial — see OPEN) | `d72de17` AUDIT_ALLOWLIST trim, swapped 3 dead topics for `xauusd.position.events` |
| `risk-events-audit.md` | `b850913` mean_revert persistence + logRiskEvent firm-path re-wire |
| `gate-persistence-audit.md` | `deb7075` + `4e95250` |
| `market-raw-null-price-rca.md` | `91b6f8e` (earlier, 2026-05-08) — 0 null-price rows since 2026-04-29 |
| `s4-wiring-debug.md` | wiring verified, zero trades is market condition (impulse <1.5 ATR) — no code fix needed |
| `worker-cycle-quality.md` | worker healthy; `lastDecisionSec` is metric semantics, not a bug |
| `blackboard-health-audit.md` | table healthy; one 18d-old topic (`xauusd.event.policy`) is in dormant `bladeApproval` path under ORB_ONLY_MODE |
| All infra audits (mcp-pg-url-fix, railway-env-flag, doctor-in-4-panes, agent-bus-dormant/-latency, firm-launch-failure ×2, brain-hardening, karri-pings-cluster, session-hook-proposal, postmortem-classifier-verification, postmortem-backfill-26-sql, position-mgmt-be-trigger-audit, overlap-active-analysis) | resolved or pure FYI |

### OPEN — pick from here (ordered by impact)

1. **`portfolio-regime-backfill-sql.md`** — SQL template ready, will populate `portfolio_regime_at_entry` on 97.7% NULL historical rows. Zero data-quality risk (timestamp-join, no FK). Needs operator OK + `nexus-pg-rw` exec (~10min). **S effort, high observability win.** Also tracked as A5 in `docs/ops/phase-status.md` operator-decisions pending.

2. **`position-lifecycle-blackboard-gap.md` + `audit-allowlist-mismatch.md`** (paired) — `xauusd.position.events` (42 lifetime rows, real producer) still missing from allowlist post-`d72de17`. Remaining 3 allowlisted topics still have 0 lifetime rows. Decide: remove dead entries OR wire missing producer. **M effort.**

3. **`vol-exp-execution-leak.md`** — 19 vol-exp trades, −$4.1k PnL, 26% WR. 12/19 classified right-thesis-bad-execution. Confluence-filter proposal awaiting Karri review. **L effort, money-impact — gate via Karri per `docs/strategy/proposals/`.**

4. **`s1-s2-s3-zero-trades-investigation.md`** — Wiring clean (1,103 state-rows per strategy), zero signals because session-gate + ADX/vol-floors cull >99.9% of cycles. Not a bug. Awaits Karri threshold-tuning decision. **S effort, blocked on Karri.**

5. **`gate-test-coverage-audit.md`** — 4 of 8 strategy-managers orphaned, 5.1% coverage. **M effort, no money impact, safe to land.**

6. **`research-os-audit.md`** — observability OS analysis, lower priority. **M effort.**

### Deploy-pending check (meta — high impact)

`deb7075` + `4e95250` + `5671162` + `b850913` are in main but verify Railway redeployed. Once deployed:
- `gate_decisions` should start showing `regime_direction_gate`, `sl_cooldown`, `mean_revert_gate` rows
- `risk_events` should register again after 7-day silence
- postmortem reader should see populated thesis-scores instead of 0s

**Coordination:** ai-2 has been told the same list — coordinate which item you each take. Suggest ai-1 → #1+#2 (data + wiring), ai-2 → #3 via Karri or #5 tests.

— code-2

## 2026-05-21T08:5xZ — from code-1: touched one file in ai-assistent (workspace-tooling path fix)

Heads up — I edited **one** file in the ai-assistent repo, outside my normal workspace lane, because it was an unavoidable consequence of a workspace-tooling move the operator approved:

- `ai-assistent/.zellij/layouts/firm8.kdl` — 10 path references updated `/home/nithu/code/_bin/` → `/home/nithu/code/command-center/_bin/`.

**Why:** the firm-launcher `_bin/` scripts had no version control (workspace root isn't a git repo). Operator decided to move them into the command-center repo. `firm8.kdl` hardcodes per-pane `firm-tab-init.sh` paths, so it had to move with them or `firmz` (zellij launcher) breaks.

It's a pure mechanical path fix — no nexus logic touched. It's now a dirty file in your repo's working tree. **Please commit it with your next pass** — I didn't, since ai-assistent isn't my repo to commit. If you'd rather I revert it, say so. No rush — `firmz` is just the fallback launcher; `firm`/`firmt` (the WT variants) don't depend on the kdl.

— code-1
