# LANE 10 — Ops-docs reconcile vs code + 443 live data (2026-06-04)

READ-ONLY audit. Code = truth, docs lie until proven. New input this sweep: the
**443 HTTPS data channel** (`pull-nexus-data.sh` → `data/pull/*.json`, pulled
2026-06-04 ~16:15Z) which surfaces live prod state previously blocked on the
PG-tunnel. That channel changed several conclusions.

Scope: `docs/ops/known-failures.md`, `docs/ops/learning-ledger.md`,
`docs/ops/phase-status.md`, `docs/ref/feature-flags.md`.

---

## TOP DISCREPANCIES (claim → reality → action)

### D1 — `risk_events` is NOT frozen at 2026-04-10. NEWS_BLACKOUT path is NOT dead code. **[highest]**

- **Claim (3 docs agree):**
  - known-failures.md §"risk_events frozen since 2026-04-10": "13 rows total, none since 2026-04-10", NEWS_BLACKOUT path "structurally unreachable" / "dead code" under `STRATEGY_BLADE_ENABLED=false`.
  - learning-ledger.md REOPENED: "risk_events silent … table still frozen at 2026-04-10 (confirmed 2026-05-25, last=2026-04-10T06:09Z, 13 rows)".
  - phase-status.md (multiple dates): same.
- **Reality (443 `risk_snapshot.json` → `risk_events` table via `cockpit.ts:42`):** a **NEWS_BLACKOUT row dated `2026-06-02T14:02:40Z`** exists: `"News BLACKOUT — entries blocked"`, severity warn. That description string is emitted *only* by `strategy-blade.ts:307` (`event_policy` check reason), which flows into `logRiskEvent(..., "NEWS_BLACKOUT", ...)` at `strategy-execution.ts:742`. That writer fires **only** when `blade && !blade.approved` with a failed `event_policy` check — i.e. it requires `STRATEGY_BLADE_ENABLED=true`. So:
  1. The table is NOT frozen at 2026-04-10 (newest row is 2026-06-02).
  2. The "dead code / structurally unreachable" claim is FALSE — the firm-blade NEWS_BLACKOUT path is reachable and fired. Implication: `STRATEGY_BLADE_ENABLED=true` was live in prod around 2026-06-02 (contradicts the "prod default off since ≥2026-05-08" assertion in known-failures.md §67).
- **Caveat (stay skeptical):** the snapshot is `LIMIT`-bounded (cockpit returns recent N). I see 14 rows, can't confirm the *total* count. But the 2026-06-02 row alone falsifies "frozen since 2026-04-10".
- **Action:**
  - **[Claude/infra]** Rewrite known-failures.md §risk_events, learning-ledger REOPENED line, and phase-status risk_events notes. risk_events should move OUT of REOPENED — the firm NEWS_BLACKOUT path is verified firing on live data (2026-06-02). Reclassify to VERIFIED (writes resumed) with the open sub-question being only "is STRATEGY_BLADE_ENABLED intended-on?".
  - **[operator]** Confirm whether `STRATEGY_BLADE_ENABLED=true` on the prod worker is intentional (the doc model assumed it was off). This flag-state assumption underpins several other "dead path" claims.

### D2 — learning-ledger REOPENED #1 (`agent_lessons` cron exit-1) is stale vs code

- **Claim:** learning-ledger REOPENED: "subprocess exits with code 1 every day … BLOCKED ON RAILWAY LOG-PULL"; root cause "schema mismatch in fetchClusters … OR DB-connection".
- **Reality:** the exit-1 path is already GUARDED in code (`derive-lessons.mjs` `RecoverableFetchError` L74-80, caught → exit 0). This was reconciled in known-failures.md + phase-status.md on 2026-06-01, but the **learning-ledger REOPENED entry was never updated to match** — it still reads as the pre-fix 2026-05-25 diagnosis. Internal doc drift (ledger lags the other two docs by one reconcile).
- **Action [Claude/infra]:** update the learning-ledger REOPENED `agent_lessons` line to point at the 2026-06-01 GUARDED reconcile; downgrade from "crashing daily" to "guarded; loop dormant end-to-end (injection off + no approval pipeline) by design". Still not closeable end-to-end, but the "crashing" framing is wrong.

### D3 — feature-flags.md `LESSON_INJECTION_ENABLED` vs known-failures.md `KNOWLEDGE_INJECTION_ENABLED` — two different gates conflated

- **Claim:** known-failures.md §57 describes the agent_lessons loop injection point as `isKnowledgeInjectionEnabled()` requiring `AGENT_KNOWLEDGE_ENABLED` + `KNOWLEDGE_INJECTION_ENABLED`.
- **Reality:** there are **two distinct injection subsystems**:
  - `agent-lessons/injection.ts` → `isInjectionEnabled()` → `AGENT_LESSONS_ENABLED` + **`LESSON_INJECTION_ENABLED`** (this is the agent_lessons loop's actual gate; matches feature-flags.md).
  - `agent-knowledge/injection.ts` → `isKnowledgeInjectionEnabled()` → `AGENT_KNOWLEDGE_ENABLED` + `KNOWLEDGE_INJECTION_ENABLED` (RAG knowledge, a different feature).
  - Both are wired into risk-advisor.ts + trade-critic.ts (verified). known-failures.md §57 cites the *knowledge* gate when describing the *lessons* loop — wrong gate name for that point.
- **Action [Claude/infra]:** fix known-failures.md §57 to cite `LESSON_INJECTION_ENABLED` (+`AGENT_LESSONS_ENABLED`) for the lessons loop. Both gates are real and correctly documented in feature-flags.md; no flag is missing — this is a citation error, not a missing-flag bug.

### D4 — ORB production status contradicts itself across docs

- **Claim A:** feature-flags.md row — `ORB_ENABLED` default `false`, **current production `false`**.
- **Claim B:** phase-status.md "Hva kjører i produksjon akkurat nå" — **ORB LIVE, `ORB_ENABLED=true`**.
- **Reality (443):** `strategy_states.json` lists running strategies trend-following / breakout-continuation / pullback-continuation / mean-reversion / volatility-expansion / session-breakout — **no classic ORB**; `runningBots:0`. `strategies.json` (closed-trade attribution) shows only xau-volatility-expansion, auto-managed, xau-mean-reversion with trades. No ORB attribution. Suggests ORB is **not** the live driver right now (TIER-3 strategies are). One of the two docs is stale; the prod-table "ORB LIVE" looks like the stale one.
- **Action [operator/Claude]:** confirm `ORB_ENABLED` actual Railway value, then make the two docs agree. Low money-impact but it's a foundational "what's running" claim that's internally contradictory.

### D5 — hard-loss bundle (2026-06-03) — claims are accurate but watch the overstatement on `cc02426`

- **Claim:** phase-status.md 2026-06-03 block: `cc02426` regime-direction, `7110e5c` session-breakout SL-mode, `685164a` operator-control, all default-OFF, "ingen live-atferdsendring".
- **Reality:** all three commits exist with matching messages (verified `git log`). Env var names verified in code: `SESSION_BREAKOUT_SL_MODE` (config.ts:55), `MANUAL_POSITION_CONTROL_ENABLED` + `MANUAL_SL_WIDEN_ALLOWED` (operator-control), regime-direction-gate.ts present. **The doc is honest** — it explicitly flags `cc02426` as "diagnostiserbar, garanterer ikke at gaten biter" and session-breakout swing_based as "UBEKREFTET". No "fixed" overstatement found here; the block correctly says diagnosable-not-fixed.
- **Action:** none on accuracy. Keep the honest framing. (This block is the *good* example — contrast with D1 where the opposite framing leaked.)

### D6 — `DISCORD_LEGACY_ENABLED` doc default vs the foot-gun

- **Claim:** feature-flags.md — default `true`, current production `false`.
- **Reality:** code default IS `true` (discord.service.ts:20, discord-bridge.ts:65: `?? "true"`). phase-status (11.5 runde 6+7 #8) says it was flipped to `true` on Railway. So "current production false" in feature-flags.md is likely stale vs the 11.5 flip. Minor, but it's the exact flag whose silent-drop foot-gun is documented — worth keeping correct.
- **Action [Claude/infra]:** reconcile feature-flags.md "current production" column for `DISCORD_LEGACY_ENABLED` against the 11.5 flip (phase-status says it's now `true`).

---

## VERIFY-BY / REOPENED items now CLOSEABLE via the 443 channel

The 443 channel was NOT available when these were marked BLOCKED-on-PG-tunnel.
It does NOT execute client JS and does NOT expose raw SQL, so some items remain
partial.

| Ledger item | Prior block | 443 verdict |
|---|---|---|
| **REOPENED: risk_events silent** | PG-tunnel / Karri proposal | **CLOSE → VERIFIED.** Live `risk_events` has a 2026-06-02 NEWS_BLACKOUT row from the firm-blade path. Writes resumed; path not dead. (See D1.) |
| **VERIFY-BY 2026-05-26: dashboard charts render** | needs browser eyes | **PARTIAL.** 443 confirms the *data layer* feeding charts is live + fresh: `readiness.json`, `risk_snapshot.json`, `strategy_states.json`, `performance.json` (equityCurve present), `threads_closed.json` all return populated, sub-minute-fresh payloads. Still cannot confirm canvas/SVG actually paints (443 ≠ browser). Net: data-layer half = GREEN via 443; client-render half still needs operator browser-eyes. Item stays OPEN but note the data side is now independently re-confirmed. |
| **BLOCKED: agent_lessons Railway env-flags** | operator | Still BLOCKED — 443 doesn't expose `firm_state` markers or the agent_lessons table. No change. |
| strategy_id non-NULL on new trades (was VERIFIED 25.5) | — | 443 `threads_closed.json`: 34/50 threads carry non-null `strategyId` (xau-volatility-expansion, xau-session-breakout, …). Corroborates the 25.5 VERIFIED. The 16 nulls are pre-fix / ANALYSIS_OPEN threads. No regression. |

Note: 443 `export.json` (CSV) exposes a `bot` column, **not** `strategy_id`, so it
can't be used to re-measure the strategy_id null_pct directly — use
`threads_closed.json` (`strategyId`) or `strategies.json` (per-strategy
attribution) instead.

---

## Live-state facts worth recording (from 443, 2026-06-04 16:15Z)

- Broker: demo, EUR, balance ~89.8k, 1 open trade (XAU_USD short, +$1.6k unrealized). connected=true.
- `dailyLoss.limit = $500` in live snapshot — but the old 2026-04-10 DAILY_LOSS_LIMIT risk_events say `limit $200`. The limit was raised at some point; no doc captures the $200→$500 change. (Minor — flag/threshold drift not in feature-flags.md.)
- `freshness`: market.raw warn (151s), Shield/Portfolio-Brain ok (~149s), **Blade decisions BAD (91314s ≈ 25h stale, last 2026-06-03 14:55Z)**, **Event policy BAD (40+ days stale, last 2026-04-24)**, Prism/Forge/Market-Pulse/Market-Pulse idle. The "Blade decisions 25h stale" + "event.policy 40d stale" is consistent with a quiet market window but worth an eyeball — event-policy topic going 40 days silent while a NEWS_BLACKOUT risk_event fired 2026-06-02 is its own small inconsistency (blackout decision logged to risk_events but not to xauusd.event.policy topic).
- performance.json: 194 trades, 37.6% WR, PF 0.69, expectancy −$52.8. (Demo, calibration epoch.)
- strategies.json: xau-volatility-expansion 3 trades +$2414 / 100% WR (tiny n), auto-managed 183 trades −$11,323 / 37.2%, xau-mean-reversion 4 trades −$124 / 25%.

---

## NEW TASKS

1. **[infra/Claude]** Rewrite the `risk_events` failure entry across known-failures.md + learning-ledger REOPENED + phase-status: writes resumed, NEWS_BLACKOUT firm-blade path verified firing 2026-06-02, move out of REOPENED. (D1)
2. **[operator]** Confirm `STRATEGY_BLADE_ENABLED` actual prod value — the docs' "off since ≥2026-05-08" assumption is contradicted by the 2026-06-02 blade-path NEWS_BLACKOUT write. Several "dead path" claims hang on this flag's true state. (D1)
3. **[infra/Claude]** Update learning-ledger REOPENED `agent_lessons` line to the 2026-06-01 GUARDED reconcile (stop calling it "crashing daily"). (D2)
4. **[infra/Claude]** Fix known-failures.md §57 gate citation: lessons loop uses `LESSON_INJECTION_ENABLED`+`AGENT_LESSONS_ENABLED`, not `KNOWLEDGE_INJECTION_ENABLED`. (D3)
5. **[operator/Claude]** Resolve ORB prod-status contradiction (feature-flags `ORB_ENABLED=false` vs phase-status "ORB LIVE"); 443 suggests TIER-3 strategies are the live drivers, not ORB. (D4)
6. **[infra/Claude]** Reconcile feature-flags.md "current production" column for `DISCORD_LEGACY_ENABLED` (code default true; flipped true on Railway 11.5; doc still says false). (D6)
7. **[infra/Claude]** Record the DAILY_LOSS_LIMIT threshold change ($200→$500) somewhere in feature-flags.md / phase-status (currently undocumented; only visible in live snapshot). 
8. **[operator]** Eyeball the 40-day-stale `xauusd.event.policy` topic vs the live NEWS_BLACKOUT risk_event — blackout fired but event.policy topic hasn't published since 2026-04-24. Possible event-policy publish path gap (separate from the risk_events write). Not money-impact, observability gap.
9. **[Karri]** Only if activating the lessons loop end-to-end (injection + auto-approve) — unchanged, still gated. No new Karri ask from this sweep; D1's risk_events finding is observability, not a strategy change.
10. **[operator]** Dashboard charts VERIFY-BY: data layer re-confirmed live via 443; only browser-render half remains. One real-browser open of `/` + `/charts` closes the 2026-05-26 overdue item.

---

_Method: read 4 docs; verified commits cc02426/7110e5c/685164a + 4c51309/b8195b9
via git log; grepped env-var names in apps/worker + apps/dashboard; traced
NEWS_BLACKOUT writer chain (strategy-blade.ts:307 → strategy-execution.ts:742);
cross-checked against live 443 pulls in data/pull/ (broker_account, risk_snapshot,
readiness, strategy_states, threads_closed, strategies, performance, export).
No writes, no pushes, no flag flips._
