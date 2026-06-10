# Nexus live trade forensics — 2026-06-04 (LANE 3 deep sweep)

Data pulled over 443 (`pull-nexus-data.sh`) at ~16:15–16:20Z. Sources: performance, export, strategies, threads_closed, risk_snapshot, readiness, weaknesses, strategy_states, health, status_report (24h/72h), decision_funnel (3d/7d), positions, broker_account/trades, diagnostic_broker.

---

## TL;DR

- The **open 79-unit short (tradeId 1459) WON: +$2112.54** — closed 2026-06-03 22:17Z at 4426.74 (entry 4458.06). It is the single largest winning trade in all-time history. Account is now flat (0 open trades, broker NAV = balance = 89,795.94 EUR, unrealizedPL 0).
- **June MTD is net positive (+$765.59, 13 trades, 46% WR, PF 1.28)** — but only because the one firm_strategy short carried it. Strip that one trade and June is deep red.
- **The real story: execution-source split.** Last 20 trades: `firm_strategy` path = 2 trades / 2 wins / **+$2171.66**. `oanda_import:*:blade_match` side-channel = 18 trades / 6 wins / **−$2456.48**. The firm decision path is profitable; everything bleeding comes through the import/blade-match path.
- All-time still bleeds: 194 trades, WR 37.6%, **PF 0.69, expectancy −$52.8/trade**, Sharpe −0.11.

---

## (a) What happened since 2026-06-03

| Trade | When (open→close) | Strat / exec source | Size | Dir | PnL |
|---|---|---|---|---|---|
| `0bd8373b…` (=OANDA 1459) | 06-03 14:55 → 22:17 | xau-volatility-expansion / **firm_strategy** | 79 | short | **+2112.54** |
| oanda_import_1447 | 06-03 00:45 → 01:01 | xau-fvg / import-blade-match | 114 | long | −787.10 |
| oanda_import_1453 | 06-03 09:06 → 10:08 | xau-trend-following / import | 40 | short | −310.09 |
| oanda_import_1468 | 06-04 01:28 → 05:29 | xau-fvg / import | **0*** | short | −33.42 |
| oanda_import_1472 | 06-04 02:57 → 06:50 | xau-fvg / import | **0*** | short | +78.79 |
| oanda_import_1484 | 06-04 08:42 → 10:22 | xau-fvg / import | **0*** | short | −100.72 |

\* size persisted as 0 — see (d).

- **1459 outcome:** clean win. Price fell ~31 pts on a 79-unit short. Persisted faithfully (export size 79.0 == OANDA −79 units).
- **Current exposure/risk:** ZERO open positions. Daily realized −$55.35 (11% of $500 limit, status ok). No active kill-switches. 30d max DD = $5,840.67 (6.19%), peak 94,370 → trough 88,530. Regime HIGH_VOLATILITY, `runningBots: 0`.
- **Since the Jun-3 short, only 3 small import trades on Jun-4 (net −$55.35).** No new `firm_strategy` decision in ~25h (Blade-decisions topic 91k s stale, last decision = the Jun-3 short).

## (b) Expectancy / WR / PF trend — still bleeding?

- **All-time:** 194 trades, WR 37.6%, PF **0.69**, expectancy **−$52.8**, avgWin +318 / avgLoss −277, worst streak 17.
- **May-1 → now:** 87 trades, net **−$2376**, WR 37.9%, PF **0.85**.
- **June MTD:** 13 trades, net **+$765.59**, WR 46%, PF **1.28** — entirely propped by the +2112 short. Without it: ~−$1347 over 12 trades.
- **Internal ledger balance** has clawed from −$2299 (06-03 10:08) to −$242 (06-04 10:22), almost all from the one short. (Note: internal ledger ≠ broker EUR balance; broker is the source of truth at 89,795 EUR.)
- **Verdict: still structurally bleeding.** PF<1 all-time and over the trailing month. The recent "recovery" is one lucky/good directional short, not a trend break.

## (c) Loss-tail — new hard losses

New since 06-03:
- **−$787.10** — oanda_import_1447, 114-unit long, FVG, 06-03 00:45 (Asian/pre-London). Largest new loss; the only ≥$700 loss outside the Apr-21/22 blowout cluster.
- −$310.09 — oanda_import_1453, 40-unit short, trend-following, 06-03 London.
- Jun-4 import trades small (−33, +79, −101).

All-time worst losses remain the **Apr 21–22 backfill blowout** (106/103/101-unit longs, −$1714 / −$1532 / −$1192 …). No new entries into that tail tier, but the −787 FVG long is the worst single trade in 6 weeks.

Session attribution (performance.json, derived from timestamps — reliable):
- **London-NY Overlap: 76 trades, 30.3% WR, −$5159** ← worst.
- **London: 71 trades, 38% WR, −$5269** ← worst by $.
- Asian: 29 trades, 48% WR, −$95 (~flat).
- New York: 18 trades, 50% WR, +$281 (only green session).
- Money is lost in the **London + London-NY overlap** windows; Asian/NY are roughly neutral-to-green.

## (d) Sizing fidelity — persisted size vs OANDA units

- **When size is persisted, fidelity is exact:** 1459 → export 79.0 == OANDA −79 units. No drift on the firm_strategy trade.
- **But size=0 persistence gap persists and is NOT fixed.** 21 of 194 rows have `size=0.00000`, including **all 3 most-recent Jun-4 import trades (1468/1472/1484)** and 4 of the last 20 positions. PnL is still recorded (so the trade happened), but unit count is lost.
- Pattern: size=0 hits both `oanda_import_*` (5) and UUID-native (16) rows — so it is not purely the import path, but the **freshest cluster is all import-path**. This breaks any per-$ risk attribution / R-multiple math on those trades and corrupts size-based analytics.
- Health reconciliation: `driftCountUnresolved: 0`, balanceDelta $38.38 (expected 89,757 vs actual 89,795) — small, acceptable. So broker↔ledger $ reconciliation is fine; the gap is **size-field persistence**, not balance.

## (e) Where money is lost RIGHT NOW — per-strategy & per-execution-source

Last 20 closed positions (richest metadata via `/positions`):

**By strategy (net):**
| Strategy | Trades | Net |
|---|---|---|
| xau-volatility-expansion | 1 | **+2112.54** |
| xau-mean-reversion | 5 | +683.53 |
| xau-session-breakout | 1 | +59.12 |
| xau-trend-following | 4 | **−1195.65** |
| xau-fvg | 9 | **−1944.36** |

**By execution source (the decisive cut):**
| Source | Trades | Wins | Net |
|---|---|---|---|
| **firm_strategy** | 2 | 2 | **+2171.66** |
| **oanda_import:*:blade_match** | 18 | 6 (33%) | **−2456.48** |

- **xau-fvg is the single biggest bleeder (−$1944 over 9 trades)** and FVG is Karri's WIP (per memory `project_fvg_karri_wip.md`). Every FVG trade in the window came via `oanda_import:xau-fvg:blade_match_*`, never `firm_strategy`.
- `regimeAtEntry` / `portfolioRegimeAtEntry` are populated **only** on the 2 firm_strategy trades; all 18 import trades persist `regimeAtEntry: NULL`. The import path is metadata-blind (no regime, sometimes no size, no thesis lineage).

## Decision funnel — structural anomaly

- 3d: 16 cycles, **1 signal proposed, 0 decisions emitted, but 9 trades opened.**
- 7d: 26 cycles, 2 signals, **0 decisions emitted, 15 trades opened.**
- I.e. trades are reaching OANDA and being **reverse-matched** to strategies by the importer (`blade_match_NNNms`), NOT flowing through the firm decision funnel. Gates barely fire because almost nothing reaches them (mean_revert hard-rejected 2–3, sl_cooldown 1; everything else passes). The firm gates are effectively bypassed for 90% of fills.

## Health / freshness flags

- HIGH weaknesses: "Last signal 1522 min old" + "No bots running — platform idle". Reconciles with Blade-decisions 25h stale + `runningBots: 0`.
- Worker heartbeat healthy (164s, cycle #260, 19 cycles/hr) and market data fresh (75–167s) — so the worker runs, but **strategies aren't emitting decisions**; trades arrive via the import/blade-match side-channel.
- Event-policy topic 977h stale (since 04-24) — likely dormant/unwired, low priority.

---

## NEW PROBLEMS (new vs prior sweeps)

1. **[severity HIGH] firm_strategy path is profitable (+2171, 2/2), import/blade-match path is the entire bleed (−2456, 18 trades).** The two paths have opposite expectancy. Most fills bypass the firm decision funnel (0 decisions emitted vs 9–15 trades opened). This is the root P&L driver right now.
2. **[severity HIGH] xau-fvg (Karri WIP) = −$1944 over 9 trades, all via import path.** FVG is live-trading on OANDA and losing, despite being unfinished WIP. Do NOT delete FVG_* (memory), but it is actively bleeding.
3. **[severity MED] size=0 persistence gap unresolved** — all 3 newest Jun-4 import trades + 4 of last 20 positions persist size 0. Corrupts R-multiple / per-$ risk analytics.
4. **[severity MED] import path persists no regimeAtEntry / thesis lineage** — kills regime-based forensic attribution for ~90% of fills.

## NEW TASKS

- **[infra]** Diagnose why `decisionsEmitted=0` while `tradesOpened=9–15`: trades reaching OANDA outside the firm funnel and getting reverse-matched (`oanda_import:*:blade_match`). Identify the side-channel order path (legacy bot? external?) and whether it is intended. This is the #1 forensic question. (read-only diag; no behaviour change)
- **[infra]** Fix the `size=0.00000` persistence gap on the import/sync path (1468/1472/1484 + 16 historical). Backfill size from OANDA units where recoverable. Pure observability/data-fidelity fix — in-scope per learning-infra boundary.
- **[infra]** Persist `regimeAtEntry`/`portfolioRegimeAtEntry` on import-path trades (currently NULL for all 18). Observability only.
- **[Karri]** FVG (xau-fvg) is live and net −$1944 over 9 trades via the import path. Decision needed: is FVG supposed to be executing on OANDA yet? If not, why are FVG-tagged orders hitting the broker? Strategy-owner call — do not disable autonomously (prinsipp 1).
- **[Karri]** xau-trend-following also negative (−$1196/4). Both losing strategies are import-matched, not firm_strategy. Worth a strategy review of whether the import path should be allowed to attribute to live strategies at all.
- **[operator]** "No bots running / platform idle" + 25h with no firm decision while import trades keep filling. Confirm intended state: is the firm decision loop supposed to be the only execution path, or is a legacy/external order source still live? (Gated — needs operator confirmation of intended architecture before any flag change.)

## Honest P&L picture (numbers)

- Broker: 89,795.94 EUR, flat, 0 open, 0 unrealized. Daily −$55.35 (11% of limit).
- All-time: 194 trades, WR 37.6%, PF 0.69, expectancy −$52.8, Sharpe −0.11, 30d maxDD $5,841 (6.19%).
- June MTD: +$765.59 (13 trades) — but +2112 of that is one firm short; underlying remains negative.
- Recent decisive split: firm_strategy +$2172 (2/2) vs import-matched −$2456 (18, 33% WR).
