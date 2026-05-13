---
type: snapshot
subsystem: nexus-firm-full-state
generated_at: 2026-05-11T18:30Z
generated_by: claude-opus-4.7 (round-16 — Karri katastrofedag-analyse + TIER 1 implementations close)
build_commit: post-rebase-main (round-16 push completed)
overwrite_each_time: true
---

# Nexus — END-OF-DAY SNAPSHOT (2026-05-11, round 16 — Karri katastrofedag-close)

Single-page truth-snapshot. Future Claude: read top-to-bottom in 30s, then jump to linked living-state docs for depth. **Overwritten each time** — git history is the only audit-trail.

Canonical living-state index: [[firm-agents-state]] · [[foundation-gate-state]] · [[gate-decisions-state]] · [[discord-delivery-state]] · [[gemini-pipeline-state]] · [[codex-pipeline-state]] · [[production-loop-state]] · [[retention-state]] · [[metadata-stamping-state]] · [[local-mirror-safety-state]]

---

## 1. Production health

### Build + worker

| Field | Value |
|---|---|
| HEAD (main) | post-round-16 (rebase + push completed cleanly, ~85 commits today) |
| build.commit (last verified live) | Railway deploy of rounds 13-16 pending operator |
| db | ok (Postgres via `nexus-pg` MCP) |
| broker | last verified `ok demo` (balance ~$91,187 baseline) |
| blackboard | last `market.raw` continuous |
| worker | heartbeat OK, **lastError null**, cycle progression 10s cadence |
| reconciliation | drift=0 |

### Foundation gate — **5/5 GREEN** (verified earlier, no regressions today)

Per `firm_state.foundation_monitor:last_state`:

| # | Rule | State | Detail |
|---|---|---|---|
| 1 | Ingen KRITISKE åpne problemer | 🟢 | manual operator doc OK |
| 2 | Position-management synkronisert | 🟢 | `POSITION_MANAGEMENT_ENABLED=true` |
| 3 | Deploy sunn (siste 3 builds) | 🟢 | Railway tab — manual check |
| 4 | Hard-gate datagrunnlag | 🟢 | `entry_stack_cooldown` |
| 5 | Forfalne claude-followups | 🟢 | 0 overdue |

### Active env-flags (operator-confirmed) — UNCHANGED from round 14

| Flag | Value | Confirmed |
|---|---|---|
| `POSITION_MANAGEMENT_ENABLED` | true | 22.4 |
| `DEMO_AUTO_DEGRADE_ENABLED` | false | 23.4 |
| `ORB_ENABLED` | **true** (flip to `false` queued for morning) | live |
| `SCALP_OVERLAP_ENABLED` | **true** (flip to `false` queued for morning) | live |
| `LEGACY_XAUUSD_EXECUTION_ENABLED` | false | live |
| `STRATEGY_BLADE_NEW_GATES` | true | 11.5 morning |
| `RETENTION_ENABLED` | true | 11.5 |
| `DISCORD_LEGACY_ENABLED` | true | 11.5 |
| `FOUNDATION_MONITOR_ENABLED` | true | 11.5 |
| `REGIME_DIRECTION_GATE_ENABLED` | **false (env-gated, default OFF)** | impl round 14-16 |
| `SESSION_BLOCK_GATE_ENABLED` | **false (env-gated, default OFF)** | impl round 14-16 |
| `SL_COOLDOWN_ENABLED` | **false (env-gated, default OFF)** | impl round 14-16 |
| `DAILY_TRADE_CAP_ENABLED` | **false (env-gated, default OFF)** | impl round 16 |
| `AGENT_BUS_ENABLED` (prod) | false | dormant by design |
| `AGENT_DISCORD_DELIVERY_ENABLED` | true | 03.5 |
| `RAW_DATA_PERSIST_ENABLED` | true | live |
| `DAILY_MORNING_BRIEFING_ENABLED` | true | live |

---

## 2. Karri's pushed work today — 4 new PRs (post round-15)

### PR #2 — Daily trade-cap proposal
- 152-trade historikk-analyse
- Proposed `daily_trade_cap` (per-strategy + global) — caps trades/day after N consecutive losses
- Filed: `docs/strategy/proposals/2026-05-11_daily_trade_cap.md`

### PR #3 — Katastrofedag-analyse 21.4, 22.4, 6.5 (HOVED-INSIGHT)
**3 worst days account for -$11,053 of -$9,572 total net** (resten av dagene = positiv eller flat).

| Date | Net | Strategy mix | Regime | Mode |
|---|---|---|---|---|
| **21.4** | **-$7,119** | legacy LONG bias | clear DOWN-trend | knife-catching |
| **22.4** | **-$3,722** | legacy LONG bias | chop | over-trading direction-blind |
| **6.5** | -$211 | TIER 3 (modern) | UP-trend | flip-flop mid-day |

**Hovedfunn:**
1. **TIER 3 fundamentally better than legacy** — 6.5 lost only -$211 vs 21.4 lost -$7,119 on similar dramatic moves
2. **Gap som gjenstår: "trend-pause-bevissthet"** — TIER 3 mangler logikk for å pause/redusere risiko når regime flipper mid-day
3. Legacy LONG bias var den dominante feilen pre-TIER 3; modern firma har eliminert det

### PR #4 — scalp+ORB observe-only APPROVED (Karri-godkjenning)
Karri har eksplisitt approved emergency-stop env-flags for begge:
- `SCALP_OVERLAP_ENABLED=false`
- `ORB_ENABLED=false`

### PR #5 — scalp+ORB observe-only IMPLEMENTED
Env-flag wiring landet, default OFF. Operator-flip på Railway klar.

### Karri queue totalt: **11 proposals**
- 10 fra earlier (5 TIER 1 batch + 4 carry-over + 1 architecture)
- + `daily_trade_cap` (ny i dag, PR #2)

---

## 3. TIER 1 batch + daily_trade_cap — 6 implementations COMPLETE

All env-gated, default OFF, behavior-neutral until operator flips Railway flag.

| Proposal | Status | Impl scope | Env-flag |
|---|---|---|---|
| `regime_direction_gate` | ✓ implemented | Blocks counter-trend mean-reversion in TRENDING_UP/DOWN regimes | `REGIME_DIRECTION_GATE_ENABLED` |
| `session_block_gate` | ✓ implemented | Blocks OVERLAP_ACTIVE + NY_OPENING_RANGE sessions (-$3683 saved historically) | `SESSION_BLOCK_GATE_ENABLED` |
| `sl_cooldown` | ✓ implemented | 60min cooldown per strategy after SL ($1023 saved historically) | `SL_COOLDOWN_ENABLED` |
| `daily_trade_cap` | ✓ implemented (round 16) | Per-strategy + global cap; halt-after-N-losses | `DAILY_TRADE_CAP_ENABLED` |
| `scalp_overlap_observe_only` | ✓ approved + impl-noted | Emergency env-flag stop for scalp-overlap | `SCALP_OVERLAP_ENABLED=false` |
| `orb_observe_only` | ✓ approved + impl-noted | Emergency env-flag stop for ORB | `ORB_ENABLED=false` |

---

## 4. Today's session totals (15 rounds → 16)

| Metric | Value |
|---|---|
| Parallel agents dispatched | **~125** |
| Commits landed | **~85** (rebase + push completed cleanly) |
| Tests passing | **523 / 523** (was 478 round 13 → 523 round 16) |
| Karri proposals filed today | 6 new + ongoing |
| Karri PRs merged today | 5 (PR #1 round 14 + PR #2-5 round 15-16) |
| Implementations complete | **6** (all env-gated, default OFF) |
| Foundation gate | 5/5 GREEN, no regressions |

---

## 5. Today's trade flow (no change since round 13 — no trades after 14:12Z)

| Metric | Value |
|---|---|
| Trades closed | 9 |
| Wins / Losses | 1 / 8 |
| Win-rate | 11.1% |
| Net PnL | **-$2,637.99** |
| Open now | 0 |

### Per-strategy

| Strategy | Orders | W / L | Net PnL |
|---|---|---|---|
| `xau-volatility-expansion` | 4 | 1 / 3 | -$1,178.96 |
| `xau-scalp-overlap` | 3 | 0 / 3 | -$1,058.07 |
| `xau-orb` | 1 | 0 / 1 | -$398.41 |
| `xau-session-breakout` | 1 | 0 / 1 | -$2.55 |

Worst hour: 13:14-13:42Z — 3 consecutive scalp-overlap shorts in trending-up regime.

---

## 6. Tomorrow morning's playbook — CRISP

### Read first
1. **Karri morning-Discord** (queued — should arrive overnight)
2. This file
3. `docs/ops/phase-status.md`
4. Latest Karri proposals (`docs/strategy/proposals/2026-05-11_*`)

### 2 emergency flips FIRST (do these before any other change)
```
SCALP_OVERLAP_ENABLED=false   # halts -$1058/day blødende strategi
ORB_ENABLED=false             # halts ORB tap-strøm
```
Effect: both strategies enter observe-only mode (continue logging, no orders).

### Then progressively flip TIER 1 gates (one at a time, watch metrics 1-2h between)
1. `SESSION_BLOCK_GATE_ENABLED=true` — strongest single-fix, blocks OVERLAP_ACTIVE + NY_OPENING_RANGE sessions ($3683 saved historically)
2. `REGIME_DIRECTION_GATE_ENABLED=true` — blocks counter-trend mean-reversion in trending regimes (+$2-3k/30d expected)
3. `SL_COOLDOWN_ENABLED=true` — 60min cooldown after SL ($1023 saved historically)
4. `DAILY_TRADE_CAP_ENABLED=true` — halt-after-N-losses safety net

### Watch new Phase 1 widgets accumulate data
- Dashboard widgets for: regime_at_entry coverage, session_at_entry coverage, gate-rejection counts, postmortem cycle_id stamping
- Expect 1-3h soak time before patterns visible

---

## 7. Open watch-items (carry from round 13)

- [ ] Discord audit-trail NULL on 18/22 rows — verification SQL queued
- [ ] `regime_at_entry` populated only 1/9 today's trades — needs 24h soak post `a2f1cbc`
- [ ] Retention FK 13,500 referenced rows — operator decision pending
- [ ] ORB_ONLY_MODE bypass — synthesis-observability gap
- [ ] Postmortem backfill scope decision
- [ ] 8 OANDA-trade dupe rows — awaiting "OK kjør"
- [ ] 138 historical metadata-strip backfill — awaiting OK

---

## 8. Karri queue snapshot — 11 proposals open

**Implemented (env-gated, awaiting Railway flip):**
1. `regime_direction_gate` ✓
2. `session_block_gate` ✓ (strongest single-fix)
3. `sl_cooldown` ✓
4. `daily_trade_cap` ✓
5. `scalp_overlap_observe_only` ✓ approved
6. `orb_observe_only` ✓ approved

**Carry-over actionable (earlier proposals):**
7. `conviction_quartile_position_sizing`
8. `funnel_drain`
9. `postmortem_size_down_feedback`
10. `vol_expansion_throttle_review` — HIGH RELEVANCE (vol-exp lost $1,179 today)

**Architecture:**
11. `processed_signals_persistence` — design-level

**Related Brain notes:**
- `Brain/01-nexus/strategies/scalp-overlap-losses-2026-05-11.md` (superseded by observe-only env-flag)
- `Brain/01-nexus/strategies/karri-tier1-batch-2026-05-11.md` (TIER 1 overview)
- `Brain/01-nexus/strategies/katastrofedag-analyse-2026-05-11.md` (new — 3 worst days deep-dive)

---

## 9. Verification SQL queue (run early tomorrow)

```sql
-- 1. Discord audit-trail coverage after 24h with new commits live
SELECT kind, COUNT(*), COUNT(*) FILTER (WHERE discord_delivery_status IS NULL) AS still_null
FROM agent_artifacts WHERE created_at > NOW() - INTERVAL '24 hours' GROUP BY kind;

-- 2. regime_at_entry coverage on new trades
SELECT COUNT(*) AS new, COUNT(regime_at_entry) AS stamped
FROM simulated_orders WHERE opened_at > NOW() - INTERVAL '24 hours';

-- 3. Foundation monitor latest state
SELECT value, updated_at FROM firm_state WHERE key='foundation_monitor:last_state';

-- 4. Today's PnL final (post EOD)
SELECT strategy_id, COUNT(*), SUM(pnl) FROM simulated_orders
WHERE opened_at >= CURRENT_DATE GROUP BY strategy_id;

-- 5. Gate-rejection counts after morning flips (run ~2h after each flip)
SELECT gate_name, decision, COUNT(*) FROM gate_decisions
WHERE created_at > NOW() - INTERVAL '4 hours' GROUP BY gate_name, decision;
```

---

## File locations referenced

- Phase status: `/home/nithu/code/ai-assistent/docs/ops/phase-status.md`
- Karri proposals: `/home/nithu/code/ai-assistent/docs/strategy/proposals/`
- Katastrofedag-analyse: `/home/nithu/code/ai-assistent/docs/strategy/proposals/2026-05-11_katastrofedag_analyse.md`
- Daily trade-cap proposal: `/home/nithu/code/ai-assistent/docs/strategy/proposals/2026-05-11_daily_trade_cap.md`
- TIER 1 batch overview: `Brain/01-nexus/strategies/karri-tier1-batch-2026-05-11.md`
- Codex runbook: `/home/nithu/code/ai-assistent/docs/ops/codex-activation-runbook.md`
- Known issues: `/home/nithu/code/ai-assistent/docs/ops/known-failures.md`

---

*Round 16 end-of-day refresh (18:30 UTC / 20:30 CET). Next refresh: morning session start after operator does emergency flips + progressive TIER 1 activation.*
