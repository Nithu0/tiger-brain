# Foundation Monitor — 2026-05-11

State-change alerts for the 5-rule foundation gate. Fires a Discord embed
to `DISCORD_ALERTS_WEBHOOK_URL` when any rule flips. REPORT-only per
operator-prinsipp #1 (no auto-disable, no auto-action).

## What landed

- `apps/worker/src/firm/foundation-monitor.ts` — 393 lines
- `apps/worker/src/firm/foundation-monitor.test.ts` — 22 tests
- `apps/worker/src/firm/orchestrator.ts` — wired as **Step 0a2c** (after
  retention Step 0a2b, before blackboard TTL Step 0a3)
- `apps/worker/package.json` — added test file to npm test runlist

## Implementation path: Option A

Wired into `FirmOrchestrator.runCycle()` as a single best-effort call.
Pattern mirrors `runRetentionAndReport` (Step 0a2b) — env-gated,
non-throwing, runs out-of-band of the trading-decision path.

Why A over B (new firm-agent): the firm-agent bus is for LLM-backed
agents that consume artifacts. This is a deterministic SQL+env check
with no LLM in the loop, so the orchestrator self-check pattern fits
better and avoids paying the firm-agent's cooldown indirection.

## Rules + how they compute

| # | Source | GREEN | YELLOW | RED |
|---|---|---|---|---|
| 1 | `docs/ops/phase-status.md` (manual) | n/a | n/a | UNKNOWN — skipped in diff |
| 2 | `POSITION_MANAGEMENT_ENABLED` env | `true` (default) | unrecognized value | `false` |
| 3 | Railway Deployments tab | n/a | n/a | UNKNOWN — skipped in diff |
| 4 | `gate_decisions` SQL | ≥1 gate w/ ≥7d AND ≥50 evals | ≥1 gate w/ ≥3d AND ≥10 evals | none meet either threshold |
| 5 | `firm/followups.ts` overdue claude/both | 0 overdue | 1–2 overdue | ≥3 overdue |

Rules 1 + 3 are placeholders (state=UNKNOWN) — they need operator
action / Railway dashboard which the monitor can't reach. UNKNOWN ↔
anything transitions are intentionally ignored so they don't flap.

## Persistence

- Last snapshot persisted as JSON in `firm_state` (key=`foundation_monitor:last_state`).
- Cooldown: 15min, enforced via `firm_state.updated_at` so process
  restarts don't trigger an extra eval.
- State persists every run (even no-change) so the cooldown clock advances.

## Discord embed

- Color: red if any change went red, else yellow, else green
- Title: `🟢/🟡/🔴 Foundation Gate — state change`
- One field per rule showing current state + short detail
- Footer reminds: REPORT-only, operator decides

## Operator action when ready

Set on Railway Worker service:

```
FOUNDATION_MONITOR_ENABLED=true
```

Webhook URL is already wired (`DISCORD_ALERTS_WEBHOOK_URL`, with
`DISCORD_WEBHOOK_URL` as fallback). No new secret needed.

## Verify results

- `npx tsc --noEmit`: clean
- `npm test`: 467/467 (baseline was 445; 22 new tests added)

## Operator-prinsipper observed

- #1 (no auto-disable): module REPORTS only, never touches a flag
- #2 (data never stops): no DELETEs, no behaviour changes
- #5 (OK-kjør gate): default OFF, requires explicit operator flip

## Commit

```
feat(monitor): foundation-gate state-change alerts to Discord
```

NO push (per task spec). Operator runs `! git push origin main` when ready.
