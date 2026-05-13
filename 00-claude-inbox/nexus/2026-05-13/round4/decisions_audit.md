# Round 4 — operator-decisions + known-failures audit

**Date:** 2026-05-13
**Scope:** every open item in `docs/ops/operator-decisions.md` + `docs/ops/known-failures.md`, cross-checked against today's commits (`deb7075`, `46a2534`, `5c07156`) + 4 Karri proposals filed today.

## 8 items still open after today: 8

(operator-decisions: 2 actionable + 4 process-bedrock; known-failures: 6 unresolved patterns)

---

## Open decisions (operator-decisions.md)

| # | Item | Status | Priority | Suggested next action |
|---|---|---|---|---|
| D1 | Karri-recommended emergency flip: `SCALP_OVERLAP_ENABLED=false` + `ORB_ENABLED=false` | STILL OPEN | HIGH (money-impact, –$1058/day worst-tap) | Operator-flip on Railway when ready. Code already gated. Re-activation order documented in proposals. Today's C3 (cross-strategy direction flip) is complementary, not a substitute. |
| D2 | 3 Karri proposals from 08.5 (`break_even_trigger_lower`, `risk_pct_clamp`, `deprecate_simulated_orders_strategy_id_desk`) sent 11.5, awaiting Karri review | STILL OPEN | MEDIUM (queued for partner) | Ping Karri if no response by 18.5 (1 wk SLA). Today's 4 new proposals stack on his queue — flag if backlog grows. |
| D3 | `STRATEGY_BLADE_NEW_GATES=true` flipped 11.5 — 7d consecutive evaluation window | ADDRESSED (live, observed) | n/a | Foundation-regel 4 green-date = 18.5. Continue passive observation. |
| D4 | Metadata-strip fix (`0ad348f`) — 138 historic rows still NULL | STILL OPEN (A5 backfill in 5c07156 pending list) | LOW (analytics noise, not bleed) | Run backfill SQL when operator has cycle. Tracked in phase-status hand-off. |
| D5 | 156 env-flags synced 11.5 | ADDRESSED | n/a | Done. |
| D6 | Process-bedrock: strategy/proposals review, MCP-roster, op-prinsipper, no-auto-activate | STILL OPEN (ongoing discipline) | n/a | No action — these are standing rules. |

## Open failures (known-failures.md)

| # | Item | Status | Priority | Suggested next action |
|---|---|---|---|---|
| F1 | `MACRO_ANALYSIS_ENABLED=false` not read (consumer not located) | STILL OPEN | LOW | 30-min code search next cycle; not ORB-critical. |
| F2 | `scalp_overlap_asia` gate wired to wrong path (hardcoded `strategyId="xau-htf-trend"`) | STILL OPEN | MEDIUM (gate dead on real path) | Move evaluation to cross-path hook. NOT covered by today's gate work (Task D mean-revert-gate is different). |
| F3 | `simulated_orders.strategy_id` / `desk` silently NULL (142/145 + 145/145) | STILL OPEN (in Karri queue D2) | MEDIUM | Awaiting Karri review of `2026-05-08_deprecate_*` proposal. |
| F4 | Discord double-gate inert without `DISCORD_LEGACY_ENABLED` | STILL OPEN (documented) | LOW | Operator-flip on Railway when next firm-agent ping needed. |
| F5 | OANDA backfill duplicate row (ticket 548 — UUID + `oanda_backfill_548` both written, PnL double-count) | STILL OPEN | MEDIUM (lesson-loop poison) | Fix oanda-sync to check firm-path UUID by `oanda_trade_id` before treating as orphan. Pre-req for lesson-loop activation. |
| F6 | Firm-path entry/SL/TP drift vs `orderFillTransaction.price` ($1.51 entry drift on ticket 548) | STILL OPEN | MEDIUM (r-multiple/percentile imprecision) | Read `orderFillTransaction.price` post-fill + update DB row. |
| F7 | Strategies skipping ~50% of cycles | ADDRESSED (`f551c17`, 07.5) | n/a | Verify on next 24h tick (1:1 eval:cycle ratio). |
| F8 | Postmortem `RIGHT_THESIS_BAD_EXECUTION` tag with no consumer | ADDRESSED (Karri proposal C4 today) | MEDIUM (in Karri queue) | Await Karri review. |

---

## Today coverage map (for reference)

- `deb7075` → instrumentation (A1 gate-persist, A2 null-direction reasons, A3 ATR breakout, A4 widen daily-cap filter)
- `46a2534` → 4 Karri proposals (C1 null-direction-block, C2 SB-SL-method, C3 cross-strategy-flip, C4 postmortem-risk-feedback)
- `5c07156` → phase-status + 7d watch-list

None of D1, D2, F1, F2, F4, F5, F6 are touched by today's work.

---

## Top-3 by priority

1. **D1 — emergency flip on Scalp+ORB** (HIGH; –$1058 worst-day; operator-timing-gated)
2. **F5 — OANDA backfill duplicate row** (MEDIUM; blocks lesson-loop activation)
3. **F2 — scalp_overlap_asia gate wrong-path** (MEDIUM; gate functionally dead)
