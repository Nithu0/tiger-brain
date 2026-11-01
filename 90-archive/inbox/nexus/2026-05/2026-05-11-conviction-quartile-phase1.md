---
date: 2026-05-11
project: nexus
type: implementation
phase: 1/3
proposal: docs/strategy/proposals/2026-05-11_conviction_quartile_position_sizing.md
reviewer: Karri
status: shipped (local, NO push)
commit: f8df52a
---

# Conviction-Quartile Histogram — Phase 1 shipped

## What landed

Phase 1 of Karri's conviction-quartile sizing proposal. **Observation-only** — no sizing change. Sets up the instrument that lets Karri see the actual distribution of `entry_conviction_score` post the 0ad348f fix.

## Files touched (5)

- `apps/api/src/routes/analytics.ts` — new `GET /analytics/conviction-quartiles?days=N`
- `apps/dashboard/src/app/analytics/conviction/page.tsx` — new page (407 lines)
- `apps/dashboard/src/components/Sidebar.tsx` — nav entry under Strategy
- `apps/dashboard/src/components/CommandPalette.tsx` — Ctrl+K entry
- `apps/dashboard/src/lib/api.ts` — `convictionQuartiles(days?)` client method

## Endpoint contract

```
GET /analytics/conviction-quartiles?days=30

{
  windowDays: 30,
  totalScored: 12,
  unscored: 138,           // pre-fix backlog + ORB rows
  strategies: ["scalp_overlap", "session_breakout", "vol_expansion"],
  overall: [{quartile:"Q1", trades:3, winRate:33.3, totalPnl:-45.20}, ...],
  buckets: [{strategyId, quartile, trades, wins, winRate, totalPnl, avgScore}, ...],
  cuts: { Q1:{min:0,max:0.25}, Q2:..., Q3:..., Q4:{min:0.75,max:1.0} },
  readyForCalibration: false   // needs 30+ days AND 30+ scored trades
}
```

NULL `entry_conviction_score` rows are excluded from buckets but counted as `unscored` so the operator sees how much of the closed-trade population is uninstrumented (ORB still doesn't stamp; firm_strategy pre-0ad348f doesn't either).

## What user sees at `/analytics/conviction`

Page layout (under sidebar Strategy → "Conviction Distribution"):

1. **Headline cards (4):** Scored Trades · Unscored · Strategies · Calibration Ready (yes/no)
2. **Sample-size caveat banner** if `readyForCalibration=false` — cites operator-prinsipp #6 (30+ days minimum)
3. **Cross-strategy bar chart** — Q1/Q2/Q3/Q4 trade counts, red→amber→blue→green palette
4. **Per-quartile detail cards** (4 small cards under bar chart): trades / win-rate / total-PnL each
5. **Per-strategy x quartile table** — rows = strategies, columns = Q1/Q2/Q3/Q4, each cell shows trades + win% + PnL
6. **Source footnote** with the API endpoint + commit context

Time-range selector: 7d / 30d / 90d / 1y (defaults 30d).

Right now (2026-05-11) it shows empty / nearly-empty state because score-stamping just started — that's expected and is the whole point of Phase 1.

## Verify

```
cd apps/api && npx tsc --noEmit          → clean
cd apps/dashboard && npx tsc --noEmit    → clean
cd apps/worker && npm test               → 488/488 pass
                                            (registry has grown from 478)
```

Pre-commit hook auto-ran tsc on both touched workspaces — also clean.

## Commit

```
f8df52a feat(dashboard): Phase 1 conviction-quartile histogram (Karri proposal)
```

NO push (operator-gated).

## Wrinkle worth noting

Parallel agent in another terminal was committing `feat(gates): session_block_gate` simultaneously. My initial `git add` got bundled into their commit (e09566b) under the wrong title. I soft-reset and re-committed my 5 files cleanly as `f8df52a`. The other agent's working tree changes (gates + .env.example + session_block_gate.md) are intact as unstaged changes — they'll re-commit on their next push.

## Next steps (Phase 2/3 — gated on data)

- **Phase 2** (after 30+ days of scored data): Karri reviews `/analytics/conviction` → decides per-strategy quartile cuts (e.g. xau-orb: Q1≤0.45, Q4>0.75).
- **Phase 3** (after Karri approves Phase 2): implement `effective_risk_pct = base * conviction_multiplier[quartile]` behind `CONVICTION_SIZING_ENABLED=false` flag.

Neither happens without explicit Karri-approval + operator "OK kjør".
