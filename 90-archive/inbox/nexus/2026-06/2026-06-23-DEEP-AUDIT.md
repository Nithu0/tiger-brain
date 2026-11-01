# Nexus — DYP KRITISK REVISJON (2026-06-23)

> 11-agent evidens-revisjon (9 fullført + 2 rate-limited→re-kjøres: data-pipeline, Thesis-1). ALT DB-verifisert mot prod, ikke antatt. Mandat: verifiser, ikke anta.


## HOVEDDOM (mest farlig først)

**Trade-kvalitet: KARAKTER F.** Den såkalte '+$2k firma-positive' (som ai-1 OG ai-2 har båret i flere økter) er et **data-korrupsjonsartefakt**: 18 trades (20%) har korrupte sub-0.5pt stops → bokfører +$9,238 med 14W/2L og ~$0 tap + umulig result_r (opptil 297R). På GYLDIGE stops er firmaet **dypt negativt** (PF 0.33-0.49). Ærlig firm_strategy-sti: 36% WR, PF 0.98, -$263 over 86 trades — FØR umodellerte kostnader. Ingen demonstrert edge.

**Lærings-loopen jeg 'landa' er HUL.** hypotheses=0, change_verifications=0, trade_lineage=0, meta_label_models=0 (alle DB-verifisert tomme). #157 engine_scores-stamp: 0/7015 stamplet siste 7d (inert i prod). getActiveProfile() autotune-readback fortsatt hardkodet stub. strategy_versions=9 alle v1 (seedet én gang, aldri v2). Writers mangler/ukalt/gated. Loopen er wiret på papir, død i data.

**Ingen kostnadsmodellering.** spread_at_entry NULL på 100% av 224 ordrer; commission/swap nowhere. Hver PnL er brutto, optimistisk biased.

**De 18 korrupte radene har excluded_from_learning=0** → de forgifter hver downstream-metrikk + enhver framtidig modell. Mest farlig: kunne falskt rettferdiggjøre en live-kapital-flip.


---

## repo + architecture + integrations
**Stack is large and live (62 API routes, ~100 worker modules, real data flowing), but the much-hyped "learning loop" infra is hollow — hypotheses/lineage/meta-label/change-verification tables are all empty with no live writers — and the honest live P&L is negative.**

Verdict: Big, genuinely-live system (data + scoring + demo execution all real and fresh), but the celebrated learning loop is hollow (4 key tables empty, writers missing or uncalled), costs are unmodeled, attribution is starved, and the honest live edge is slightly negative — far from live-capital ready.

ARCHITECTURE MAP (verified):
- Monorepo, npm workspaces (apps/*, packages/*). Frontend: Next.js dashboard, ~40 page.tsx routes (apps/dashboard/src/app). Backend: API (Fastify-style) with 62 non-test route files (apps/api/src/routes). Worker: single Node process (apps/worker/src/index.ts), BullMQ + Redis, Pool→Postgres.
- Schedulers are all IN-PROCESS setInterval (apps/worker/src/index.ts:146-347): supervisor 10min, bot-manager 15min, firehose-digest hourly (gated FIREHOSE_DIGEST_ENABLED OFF), lesson-derivation hourly@04:00 (gated AGENT_LESSONS_ENABLED+LESSON_DERIVATION_ENABLED OFF). FirmOrchestrator self-schedules ~90s adaptive cycle (index.ts:350-351) and is the SOLE execution authority (trading-manager.agent RETIRED, index.ts:12,134). No external cron, no GPU; only Docker on Railway (apps/{api,worker,dashboard}/Dockerfile, node:20-alpine), one GitHub Actions test.yml.
- DB is the real backbone (50+ tables). Live + fresh (verified now): blackboard 233,722 rows (last 40s ago), ohlcv_candles 192,177 (last 28min), engine_scores 34,574 (35min), signal_scorecards 1,868 (35min). So the analysis/scoring loop genuinely runs.

INTEGRATIONS (code-verified, by env-var reference, not values):
- LIVE/WIRED: OANDA (oanda.service.ts — candles + order placement /v3/accounts/{}/orders:319; BROKER_MODE default 'demo', live NEVER auto-enabled:30). TwelveData = primary market data (MARKET_DATA_API_KEY, market-data.service.ts:203,292 api.twelvedata.com price/time_series/rsi). Polygon = fallback (POLYGON_FALLBACK_ENABLED). Discord (boot/shutdown + alerts webhooks, index.ts:400-454). LLM router: Anthropic (claude-sonnet-4) + OpenAI + OpenRouter, availability-gated on API-key presence (llm-router.service.ts). Finnhub calendar + Forex Factory (event-policy/state-machine + finnhub-calendar.service). FRED (11 refs in firm/), Reddit + sentiment snapshots (32,181 reddit rows).
- DORMANT / HALF-WIRED: TradingView = config enum only (providers.ts), NOT a live webhook receiver. Qdrant (11 refs but vector store usage unclear). Notion (2 refs), Telegram (1 ref), Tavily (5 refs) — peripheral. Commission/financing/swap NOT modeled anywhere (only acknowledged in an oanda-sync comment:1141).

LOOP-INFRA REALITY CHECK (the audit's central question — verified empty TODAY):
- hypotheses = 0 rows; only writer is scripts/firehose/derive-lessons.mjs, a cron subprocess gated OFF. No worker-loop writer.
- trade_lineage = 0 rows; only schema defs + READ routes (explorer.ts, warroom.ts) + a one-shot dedupe SQL. NO live writer.
- change_verifications = 0 rows; writer file exists (firm/change-verification/change-verification.ts) but grep finds NO caller/importer — dead code.
- meta_label_models = 0 rows; scorer.ts:112 comment admits "the offline trainer that writes meta_label_models" — that trainer does NOT exist in the repo. Scorer is null-safe so it silently no-ops.
- strategy_versions = 9, backtests = 6 (token-level, not a real cadence). So of the "landed loop infra," only stamping exists; the productive writers are absent or gated.

TRADE LEDGER / P&L (simulated_orders, 224 rows, verified):
- Cumulative PnL = -$11,913.88. Breakdown by execution_source: legacy NULL era (Apr15-21) = -$10,797 over 79 trades (the catastrophe, pre-firm). firm_blade (6 trades, Apr22-23) = +$2,290. firm_strategy (CURRENT path, Apr26→Jun22, 86 trades over ~8wk) = -$263, 31/86 wins = 36% WR. So the live system is roughly breakeven-to-slightly-negative with LOW frequency (~10 trades/wk, last trade 10h ago).

**Kritiske funn:**
- FAKE-CAPABILITY RISK: The 'learning loop' is advertised as landed but produces nothing. hypotheses=0, trade_lineage=0, change_verifications=0, meta_label_models=0 (all verified empty via live DB). meta_label_models has NO trainer in the repo (scorer.ts:112 references a non-existent offline trainer); change-verification.ts has NO caller. Any dashboard/decision relying on these is reading empty tables — silent, not erroring.
- NO SPREAD/COMMISSION ON LIVE TRADES: simulated_orders.spread_at_entry is NULL for ALL 224 rows; oanda-sync.ts:142 marks it 'reserved; v2'. A realistic slippage+spread model EXISTS (paper-execution.service.ts:59-105, session-based + ATR-adjusted, always-unfavorable) but the live OANDA-synced path doesn't populate it. Commission/financing/swap are modeled NOWHERE — so reported PnL omits carry costs entirely. This biases any forward analysis optimistic.
- TRADE ATTRIBUTION STARVED: simulated_orders.strategy is NULL for ~99% of rows; trade_labels has only 89 rows and is 3+ days stale (last 2026-06-20). Per-strategy performance, one-strategy-dominance checks, and the meta-label feature pipeline are all data-starved — you cannot honestly attribute the -$263 to any strategy.
- HONEST LIVE EDGE IS NEGATIVE: current firm_strategy path = 36% win rate, -$263 over 86 trades / 8 weeks. Not catastrophic, but no demonstrated positive expectancy after the (unmodeled) spread/commission drag. Do not treat any green dashboard number as proof of edge.
- REPO HYGIENE / SUPPLY-CHAIN NOISE: 30+ stale worktrees under .claude/worktrees/ each carrying full Dockerfiles + docs copies (agent-*, wf_*). Pollutes greps, risks accidental builds from stale code, and bloats the tree. backtest_xauusd_m1=175,000 rows feeding 6 backtests with no lineage to live strategy_versions — backtest→live provenance is unverifiable.

**Anbefalinger:**
- Stop claiming the learning loop 'landed.' Either wire the writers (hypotheses producer in runCycle, trade_lineage writer at trade open, call change-verification.ts, build the meta_label_models trainer) OR mark these explicitly DORMANT in docs/ref + dashboards so empty tables don't read as 'no findings.' Add a boot-time assertion that warns when a 'landed' loop table has 0 rows after N cycles.
- Populate spread_at_entry on the live path (capture OANDA bid/ask at fill) and add an explicit commission/financing line to PnL accounting. Until then, stamp every PnL surface with a 'gross of costs' disclaimer. Reconcile paper-execution.service.ts's spread model against actual OANDA fills to validate it.
- Fix trade attribution: backfill/forward-fill simulated_orders.strategy from the firm decision cycle, and make trade_labels generation run on the orchestrator cadence (it is 3 days stale). Without this, no per-strategy or dominance analysis is trustworthy.
- Treat current live edge as UNPROVEN-NEGATIVE. Do not advance toward live capital. Keep demo, raise trade count for statistical power, and require a positive expectancy net of modeled spread+commission before any flip — gate via Karri per protocol.
- Clean up .claude/worktrees/ (30+ stale trees) and add to .gitignore/CI ignore; ensure Railway builds only from apps/* root, not worktree copies. Establish backtest→strategy_versions lineage so the 6 backtests/175k candles can be traced to what actually trades.
- Add a single 'loop health' DB view (table, row count, max-timestamp, has-live-writer bool) and surface it on the status page so starved/stale tables are impossible to miss in future audits.

---

## trade-quality audit (graded A-F)
**The firm's headline +$2,027 is a data-corruption artifact. The real strategy engine is deeply negative: 26% win rate, profit factor 0.33, -$8,833 on trades with valid stops.**

Verdict: Grade F. The firm's trades show no real edge — the only 'profit' is a corrupt-stop data artifact; the actual strategy engine loses money at PF 0.33 with costs not even modeled.

## Cohort
Firm-originated (UUID id, per `packages/shared/src/firm-attribution.ts:49`): **92 closed trades**, 2026-04-23 → 2026-06-23. Imported/reconciled: 132 (excluded, correctly).

## Headline metrics (firm cohort, all 92)
- Win rate **38%** (35W / 52L / 5 flat); avg_win $459, avg_loss -$270; gross +$16,080 / -$14,053 → **profit factor 1.14**, total **+$2,026.78**.
- `avg_r = 13.65` — physically impossible, an immediate red flag.

## CRITICAL: the profit is a corrupt-stop artifact
20% of trades (18/92) have a stop-loss <0.5 points from entry (min 0.000, ten at exactly 0.200). On XAUUSD @ $4,500 a 0.2-pt stop = 0.004% — inside the spread, cannot exist as a real order. The code itself documents this: `postmortem-r-multiple.ts:14-21` — "some OANDA-reconcile rows had stop_loss overwritten with an entry ± 0.20 placeholder."

Splitting by stop validity:
- **18 broken-SL rows: +$9,238** (14W / 2L — absurd win-skew, confirms post-hoc stop overwrite).
- **74 valid-SL rows: -$7,212** (21W / 50L, profit factor 0.49).

Strip the corrupt rows and the firm is **deeply negative**. The +$2,027 exists only because the corruption clustered on winners.

## CRITICAL: the actual strategy engine loses money
By `execution_source`, valid-stop trades only:
- `firm_strategy` (the real engine, n=69): **18W (26% win rate), -$8,832.75, profit factor 0.33**.
- `firm_blade` (n=5): +$1,621 — but n=5 is noise, not edge.
The entire firm "profit" rides on (a) corrupt stops and (b) 5 blade trades.

## result_r poisoned in DB despite the code fix
`computeRealizedR` (postmortem-r-multiple.ts:38) correctly returns NULL when `original_risk_points < MIN_PLAUSIBLE_RISK_POINTS=1.0`. But all 18 broken rows STILL carry non-null result_r (297.4, 260.3, 146.0, 122.3, 118.8, 107.6…) — the guard landed 21.5 but postmortem was never re-run to overwrite the poisoned historical rows. Distribution: only 10/92 result_r values are < 5; the rest are NULL or astronomical. R-multiple stats are unusable.

## Costs / slippage / fees: NOT modeled
- `spread_at_entry` NULL for **92/92** trades.
- `fill_latency_ms` / `signal_price` present on only 10/92 (recent instrumentation).
- No commission/financing column exists. PnL is broker gross — no cost drag applied. Any forward edge estimate is optimistic by the full spread+commission.

## Metadata completeness (firm cohort)
- `regime_at_entry` NULL 67/92 (73%); `atr_at_entry` NULL 60/92 (65%); `original_risk_points` NULL 11/92.
- `session_at_entry`, `entry_price`, `stop_loss`, `take_profit` fully populated (good).
- `excluded_from_learning = 0 for ALL 92` — none of the corrupt rows are quarantined, so they leak into meta-labels / hypotheses / strategy-versions.

## Per-strategy grades
- xau-volatility-expansion (n=45, +$2,100, 19W): **F** — "profit" is 10+ broken-0.20-stop rows; on real stops it is negative. Dominates the book and the fake edge.
- xau-session-breakout (n=24, -$910, 6W): **D/F** — 25% win rate, 5 zero-distance stops.
- xau-orb (n=5, -$1,300, 0W): **F** — 0 wins, -$260 avg.
- xau-scalp-overlap (n=7, -$213): **F** small-sample loser.
- xau-mean-reversion (n=2): **F** insufficient + losing.
- xau-fvg (n=3, +$437): **inconclusive** (n too small; 1 broken row).
- firm_blade path (n=6, +$2,290): **inconclusive** — carries the headline but n=6 is noise.

## Clustering
PnL concentrated in a handful of days: 2026-04-23 (+$2,415, 3 trades), 06-02 (+$2,113, 1 trade), 05-03 (+$2,096, 6 trades). Three days account for ~$6.6k; remove them and the book collapses. No edge persistence.

## News-window / lookahead
Could not verify news-window avoidance — no economic-calendar join available in this cohort and 73% of regime metadata is NULL. Stated as unverified, not clean.

**Kritiske funn:**
- FAKE PROFITABILITY: headline +$2,026.78 is an artifact. 18 trades (20%) carry corrupt sub-0.5pt stops (min 0.000) producing +$9,238 with a 14W/2L skew. On valid stops the firm is -$7,212 (PF 0.49). Evidence: DB split by abs(entry-stop); postmortem-r-multiple.ts:14-21 documents the entry±0.20 placeholder.
- REAL ENGINE IS NEGATIVE: firm_strategy on valid stops = 69 trades, 26% win rate, -$8,832.75, profit factor 0.33. The only positive path is firm_blade (n=5, +$1,621) which is statistically meaningless. There is no demonstrated edge.
- POISONED LEARNING INPUT: all 18 corrupt rows have excluded_from_learning=0 and still carry astronomical result_r (up to 297.4) in the DB despite the computeRealizedR fix (postmortem-r-multiple.ts:38). The guard was never backfilled, so meta-labels/hypotheses/strategy-versions train on fabricated R-multiples and a fake +$9k of PnL.
- NO COST MODELING: spread_at_entry NULL for 92/92; no commission/financing field; fill latency on only 10/92. All PnL is broker gross with zero slippage/cost drag — every edge estimate is upward-biased by full spread+commission.
- UNRELIABLE RISK BASIS: we do not actually know the risk taken on 18 real OANDA trades because their stop_loss was overwritten to a placeholder. R-multiple distribution, expectancy, and PF cannot be trusted for the cohort.
- OVERFIT/NON-PERSISTENT: ~$6.6k of total PnL comes from 3 calendar days; one strategy (xau-volatility-expansion) dominates and its profit is the corrupt-stop rows. Remove a handful of days/rows and the book is clearly losing.
- METADATA STARVATION: regime_at_entry NULL 73%, atr_at_entry NULL 65% — regime/news/volatility context for most trades is unknown, so news-window and regime-conditioned audits cannot be completed (stated unverified).

**Anbefalinger:**
- IMMEDIATE: re-run postmortem over all 92 firm rows so the computeRealizedR guard nulls the 18 astronomical result_r values currently in the DB. Verify afterward that no result_r > ~10 survives.
- QUARANTINE: set excluded_from_learning=TRUE on every row with abs(entry_price-stop_loss) < 1.0 (the 18 corrupt-stop rows) before any meta-label/hypothesis/strategy-version run consumes them. They are training on fabricated edge.
- Recompute ALL firm performance with corrupt rows removed and publish the honest number: firm_strategy valid-stop = -$8,833, PF 0.33, 26% win rate. Stop reporting +$2,027 as the firm's edge — it is false.
- Root-cause the stop overwrite: find the reconcile/oanda-sync path that writes entry±0.20 into stop_loss and either (a) preserve the original order stop, or (b) write NULL and flag the row, never a placeholder. Until fixed, every new reconciled trade re-poisons the book.
- Add cost modeling NOW: capture spread_at_entry on every fill (0/92 today), add a commission/financing field, and apply spread+commission to PnL before any edge/expectancy claim. Current gross PnL overstates net.
- Backfill regime_at_entry and atr_at_entry (73%/65% NULL) so regime-conditioned and news-window audits become possible; add an economic-calendar timestamp join to flag high-impact-news trades — currently unverifiable.
- Treat firm_blade's +$1,621 (n=5) as noise, not validation. Do not size up any strategy on <30 valid-stop trades. xau-orb (0/5 wins), session-breakout (25%), scalp-overlap, mean-reversion should be halted or shadow-only pending real-stop evidence.
- Route all of the above PnL/stop/cost corrections to Karri before any sizing or gate change — these are money-impact findings, and the headline-profitability claim must be retracted in phase-status.md.

---

## learning loop: producing or starved?
**Infra now EXISTS but is WIRED-BUT-STARVED: the second-half loop tables are empty or default-OFF, the keystone autotune readback is still a hardcoded stub, and ~2 trades/day with 80-100% NULL metadata means even the live half learns nothing but UNKNOWN/UNKNOWN noise.**

Verdict: Not learning. The infra was built and partly landed, but it is wired-but-starved: hypotheses/change_verifications empty, strategy_versions seeded-once, the #157 stamp and the autotune readback both inert in prod, and ~2 trades/day with 80-100% NULL metadata mean the live half only produces UNKNOWN/UNKNOWN noise.

## Verdict per loop link (live DB + code evidence, build on feat/dashboard-structure-vpa-tile, DB queried 2026-06-23)

The prior audit (2026-06-15) said the foundation was on a branch awaiting push. It HAS landed — tables now exist. But existence != production. Here is each link with row evidence:

| # | Link | Verdict | Evidence |
|---|---|---|---|
| 1 | data→signal | WIRED | engine_scores fresh (max 2026-06-23 10:54), candles flowing |
| 2 | signal→trade | WIRED-but-THIN | simulated_orders: only ~2-4 trades/day, 54 in 30d |
| 3 | trade→log | WIRED-but-BROKEN-METADATA | last 30d (n=54): strategy=100% NULL, strategy_version=94.4% NULL, result_r=77.8% NULL, regime=79.6% NULL, atr=77.8% NULL. strategy_id IS populated (0% NULL) so attribution exists via the OLD column; the NEW `strategy` col the loop reads is 100% empty. Of 54, only ~12 are real `firm_strategy`; ~42 are `oanda_import/backfill:blade_match_220-828ms` heuristic timestamp guesses, not genuine signal→trade records |
| 4 | result→eval | WIRED | postmortems 179 total, fresh (2026-06-23 01:34), 1-4/day; engine_scores 34,574 |
| 5 | eval→hypothesis (derive) | PRODUCING-GARBAGE | agent_lessons 15 total, 0 approved, latest 2026-06-18. Content is noise: every recent lesson is "UNKNOWN regime in UNKNOWN session..." because regime/session are ~80% NULL — derive clusters everything into UNKNOWN buckets over n=1-5. Not hypotheses, WR-buckets |
| 6 | hypothesis→backtest | DEAD/STARVED | **hypotheses table: 0 rows.** The structured-hypothesis writer is not wired. derive still writes free-text agent_lessons, not hypotheses |
| 7 | backtest | DEAD/STALE | backtests: 6 rows, frozen at 2026-06-14 (9 days stale). Manual HTTP only, no production growth |
| 8 | backtest→version | SEEDED-NOT-VERSIONING | strategy_versions: 9 rows, ALL created in the same 16ms window (2026-06-19 23:09:20), all version=1, all retired_at=NULL. One-time seed. No param change has ever produced a v2 |
| 9 | version→compare | DEAD | nothing to compare; every strategy frozen at v1; stamp flag OFF so trades aren't even joined to versions |
| 10 | eval→daily report | PARTIAL | agent_artifacts journal/brief produced (not re-verified this pass; prior audit confirmed) |
| 11 | report→agent tasks | PRODUCING-but-DISCONNECTED | agent_tasks: 519 rows, fresh (2026-06-23 03:16). Generator works; prior audit confirmed ai-1/ai-2 work from markdown, not the queue |
| 12 | task→implement | PARTIAL/manual | only real path ends in open PR; no auto-merge by design |
| 13 | implement→verify | DEAD/STARVED | **change_verifications table: 0 rows.** change-verification.ts has ZERO callers outside its own dir + tests. Built, unwired |
| 14 | calibration→thresholds (hidden) | NO-OP STILL UNFIXED | calibration_log very active: 2513 total, 1079 in 7d, 154 applied=true in 7d (124 SAFE_AUTO_APPLY/1-param + 30 APPLY/5-param). BUT `getActiveProfile()` (calibration.ts:362-366) is STILL `return getBaselineProfile()` with comment "When SAFE_AUTO_APPLY is active, this would query...". Session-threshold autotune writes 154 rows/week and reads back none. (Engine-multiplier path via setEnginePerformanceMultipliers is separate and may be live; session-threshold readback is dead) |

## #157 engine_scores trade_id stamp fix: DID NOT TAKE
engine_scores last 7d: 7015 rows, 0 stamped (0.0%). All-time: 690/34,574 stamped (2%). The stamp fix produces nothing in production — engine scores cannot be joined to trade outcomes.

## Wiring status of the new modules (code)
- strategy-versions/stamp.ts: gated by `STRATEGY_VERSION_STAMP_ENABLED` (default OFF) → explains 94.4% NULL strategy_version. Called from strategy-execution.ts:44 but no-ops.
- change-verification.ts: built, ZERO live callers.
- hypotheses writer: not wired → 0 rows.
- derive-lessons: runs as spawned subprocess from index.ts (firehose-gated), but produces UNKNOWN-bucket noise.

**Kritiske funn:**
- #157 engine_scores trade_id stamp produces NOTHING in prod: 0/7015 stamped last 7d, 690/34574 all-time (2%). The eval layer cannot join scores to outcomes. The fix is reported-landed but is inert in production.
- Keystone autotune no-op UNFIXED: getActiveProfile() at apps/worker/src/firm/calibration.ts:362-366 still hardcodes baseline. 154 applied=true calibration rows/week (124 SAFE_AUTO_APPLY) are written and never read back for session thresholds. The one real statistical feedback motor adjusts and forgets.
- hypotheses=0 and change_verifications=0: the two tables that would close the loop's second half exist but are empty. change-verification.ts has zero live callers; the hypotheses writer is unwired. derive still emits free-text agent_lessons, not structured testable hypotheses.
- strategy_versions is a one-time seed, not versioning: all 9 rows minted in the same 16ms at version=1, retired_at=NULL. No param change has ever produced a v2. The stamp flag (STRATEGY_VERSION_STAMP_ENABLED) is OFF so 94.4% of trades carry no version. 'Did v2 beat v1?' remains unanswerable.
- Metadata starvation makes even the live half meaningless: 100% NULL `strategy`, 80% NULL regime/session/atr/result_r on last-30d trades. derive consequently clusters everything into 'UNKNOWN regime in UNKNOWN session' buckets over n=1-5 — statistical noise, 0 approved lessons.
- Trade volume too low to ever cluster: ~2-4 trades/day, 54 in 30 days. Even with perfect metadata, per-strategy/per-regime samples are single digits. No statistically valid feedback is possible at this throughput regardless of infra.
- ~42 of 54 recent trades are blade_match heuristic reconstructions (oanda_import/backfill:blade_match_220-828ms), not genuine logged signal→trade records — attribution-by-timestamp-guessing pollutes the learning corpus.
- backtests frozen at 2026-06-14 (6 rows, 9 days stale): no hypothesis is ever backtested before shipping; the proposed→approved gate has no fuel.

**Anbefalinger:**
- Stop building loop infra; turn ON and feed what exists. Flip STRATEGY_VERSION_STAMP_ENABLED so trades join to versions, and fix the #157 stamp so engine_scores.trade_id actually populates (verify with a 24h re-query: stamped pct should jump from 0%).
- Fix the metadata-at-write-time bug FIRST (it gates everything): write strategy/regime_at_entry/session/atr/result_r on ALL execution paths, not just firm_strategy. Target <5% NULL over 48h. Without this, every downstream lesson is UNKNOWN/UNKNOWN noise. This is the single highest-leverage fix.
- Implement getActiveProfile() to read the latest applied calibration_log row (default-OFF read path, Karri-gate activation). Until then the 154 applied rows/week are pure write-amplification with zero effect — either wire the readback or stop the autotune writes to avoid a false sense of learning.
- Wire change-verification.ts into the orchestrator (it has zero callers) and wire the hypotheses writer into derive so derive emits structured hypotheses (problem/proposed-change/expected-effect/test/success-criterion/rollback) instead of WR-buckets. Acceptance: next 04:00 run produces >=1 hypotheses row and a landed change produces >=1 change_verifications row.
- Confront the throughput floor explicitly: at 2-4 trades/day no per-strategy learning is statistically possible. Either (a) accept the loop will be data-starved for months and plan accordingly, or (b) raise signal frequency / widen the eligible-trade universe (Karri-gated). Do not pretend the infra learns while it is starved.
- Quarantine blade_match heuristic reconstructions from the learning corpus (use excluded_from_learning) — they are timestamp guesses, not logged trades, and currently dominate the sample.
- Re-run backtests per-strategy on a schedule and enforce the proposed→approved gate so no hypothesis ships without a passing backtest; the table being 9 days stale means the gate is decorative.
- Correct the project record: the 2026-06-15 verdict's '5/13 wired' is now '~6/13 wired, but second half is wired-but-starved/empty, not just dead'. The honest status is: infra built, production inert. Do not report the loop as 'learning'.

---

## leakage / lookahead / timezone / slippage / labels
**No fake profitability in the backtest engine (every run is honestly negative), but the ACTIVE shadow-signal resolver produces win-inflated R via a path-blind single-spot fill, the backtest default candle source is 10.5 days stale, and the forward-test resolver mixes timeframes — exit-side costs are unmodeled everywhere.**

Verdict: Backtest + triple-barrier labels are honest (all backtests negative, labels 14% win) — but the actively-written shadow_signals P&L is win-inflated by a path-blind spot resolver, the backtest's default 1min source is 10.5 days stale with no coverage guard, and all simulated exits are frictionless; trust labels/backtests, distrust shadow_signals profitability.

## Verdict on reported profitability
Mixed, but the *honest* sources are trustworthy and the *broken* source is NOT presented as live P&L.

**Backtests (trustworthy, honest).** All 6 `backtests` rows show NEGATIVE totalR (-1.92, -0.01, -0.84, -0.96, -1.35; win rates 33-50%). The ORB runner is not faking wins — it shows the strategy loses. `apps/api/src/backtest/runner.ts`.

**Triple-barrier labels (trustworthy).** `apps/worker/src/firm/meta-label/triple-barrier.ts:107-134` filters `c.timeMs >= entryTsMs` (no lookahead/lookback), conservative SL-first tiebreak (:123-126), degenerate zero-risk → NULL not fake-0R (:99-101,:125,:134), and the '15min' timeframe bug is fixed with an explicit comment (:200-203 — '15m' would match 0 rows and mark everything `expired`). Firm-only filter via `isFirmOriginatedSql` (:226) is WORKING: DB shows 132 imported OANDA rows excluded, 92 firm UUIDs kept. Labels are honestly bearish: DB `trade_labels` = 68 sl_hit / 11 tp_hit / 10 expired (14% win), r0=10, rnull=5. No leakage of outcome-derived fields into labeling.

**Timezone (trustworthy).** `london-time.ts` + `session-window.ts:54-201` use `Intl.DateTimeFormat('Europe/London')` for DST-correct session boundaries; backtest runner uses the same London-local logic (`runner.ts:120-148`). Resample buckets are UTC-epoch-aligned (:184-204) which is consistent. No UTC-vs-trading-day mismatch found.

## What is BROKEN
**1. Active shadow resolver is path-blind and win-inflating.** `shadow-log.ts:128-209` `trackPendingOutcomes()` compares ONE current spot price to SL/TP. DB proof: of 178 `tp_hit` rows only **32 have outcome_price within $0.50 of the actual TP**; of 143 `sl_hit` only **24 near SL**. outcome_price ranges $4029-$4752 — i.e. resolved at scan-time spot, not at a barrier, yet `pnl_simulated_r` is booked as the FULL reward (avg +1.747R for tp_hit). Net the table looks profitable (178 win / 143 loss @ +1.75R) — this is exactly the win-only bias the code's own comments warn about (:124-127, :422-431). The correct path-aware resolver exists (`resolveOutcomeFromCandles` :442-482) but the legacy spot resolver is still the one writing `shadow_signals`.

**2. Backtest default candle source is 10.5 days STALE.** `runner.ts:49` `CANDLE_TIMEFRAME` defaults to `1min`; DB max 1min candle = 2026-06-12, now = 2026-06-23 (staleness 10d 14h). 1min stopped updating while 15min is current to 11:00 today. The runner only throws on ZERO candles (:427); a window like "last 30 days" silently truncates at June 12 with no warning. The one '5m'/recent backtest (date_to 2026-06-12) sits exactly on that cliff.

**3. Forward-test resolver mixes timeframes.** `shadow-log.ts:525-531` queries `ohlcv_candles WHERE symbol='XAUUSD' AND candle_time >= $1` with **NO timeframe filter** — walks 1min AND 15min bars together. For the overlap period two bars share a timestamp with different high/low, corrupting first-touch ordering. (`SHADOW_FORWARD_TEST_ENABLED` is ON in prod despite default-OFF: 40,775 rows.)

**4. Exit-side transaction costs unmodeled everywhere.** Backtest applies `spreadUsd` (default 0.3) only on ENTRY (`runner.ts:302-303`); SL/TP/EOS exits fill at the exact level (:319-354) with no spread, no stop slippage, no gap-through. Shadow + forward-test resolvers apply zero spread/slippage on either side. Live trades are exempt (OANDA fill is truth, `strategy-execution.ts:1132-1180`) — so only the SIMULATED paths are optimistic.

**5. No high-impact-news gate in backtest.** The runner trades every qualifying session breakout regardless of NFP/CPI/FOMC; no `economic_events` join. Live path has news gates; the backtest does not, so backtest fills include news-spike bars the live system would skip — a sim/live divergence (here it makes the backtest look WORSE, not better, so not a fake-profit risk, but it invalidates sim≈live).

## Data hygiene (clean)
178,059 candles, **0 duplicate (symbol,timeframe,candle_time) groups**, 15min current to now. No stale-price or dup-candle problem on the live (15min) series.

**Kritiske funn:**
- WIN-INFLATED SHADOW METRICS (HIGH): active trackPendingOutcomes (shadow-log.ts:128-209) resolves via single current spot, not price path. DB: only 32/178 tp_hit and 24/143 sl_hit fills land near the real barrier; pnl_simulated_r books the full +1.747R reward. shadow_signals net-positive R is a measurement artifact, not edge. Any dashboard/agent that reads shadow_signals P&L is being lied to.
- STALE BACKTEST CANDLE SOURCE (HIGH): runner default BACKTEST_CANDLE_TIMEFRAME=1min (runner.ts:49) but DB 1min ends 2026-06-12 (10.5 days stale); 15min is current. Runner only errors on zero candles (runner.ts:427), so recent-window backtests silently truncate/return partial data with no warning -> conclusions drawn on missing days.
- FORWARD-TEST RESOLVER MIXES TIMEFRAMES (MEDIUM): shadow-log.ts:525-531 reads ohlcv_candles without a timeframe filter, walking 1min+15min bars together; duplicate-timestamp bars with different high/low corrupt first-touch SL/TP ordering. 40,775 forward-test rows affected for the 1min/15min overlap period.
- FRICTIONLESS SIMULATED EXITS (MEDIUM): backtest spread applied only on entry (runner.ts:302-303); SL/TP/EOS exits and both shadow resolvers fill at exact levels with no spread/slippage/gap modeling. Optimistic on the exit leg and on stop fills; biases simulated R upward (~0.3-0.6 USD per round trip unaccounted).
- BACKTEST IGNORES HIGH-IMPACT NEWS (LOW-MEDIUM): runner has no economic_events gate, so it fills session-breakout trades on NFP/CPI/FOMC bars the live system skips. Breaks sim=live equivalence even though live is more conservative.

**Anbefalinger:**
- Retire trackPendingOutcomes (single-spot) as the shadow_signals resolver; route shadow_signals through the path-aware resolveOutcomeFromCandles (already written, shadow-log.ts:442-482). Until then, do NOT treat shadow_signals tp_hit/pnl_simulated_r as edge — flag the table as measurement-biased on every dashboard.
- Change backtest default to a non-stale source: set BACKTEST_CANDLE_TIMEFRAME=15min OR fix the 1min ingestion that stopped on 2026-06-12. Add a guard in runner.ts that throws/warns when max(candle_time) in the requested window is older than dateTo by >1 trading day (coverage check, not just count>0).
- Add `AND timeframe = $2` to the forward-test candle query (shadow-log.ts:525-531) and re-resolve the 40,775 forward-test rows; otherwise overlap-period first-touch ordering is unreliable.
- Model exit-side costs symmetrically: apply spreadUsd on exit fills and add a configurable stop-slippage (e.g. 0.2-0.5 USD worse than slPrice) in runner.ts:319-354; apply spread to both shadow resolvers. Gold practice spread is often 0.2-0.4 USD but widens to 0.5-1.0+ on news/illiquid hours — make it regime/session-aware, not a flat 0.3.
- Add an economic_events join to the backtest runner to skip (or flag) trades opened within N minutes of high-impact news, matching the live news gate, so backtest results are comparable to live behaviour.
- Investigate 1min ingestion halt (stopped 2026-06-12) as a standalone data-pipeline incident; the 15min series is healthy so this is an isolated feed, but it silently degrades every 1min-default backtest.

---

## backtest engine correctness + validation framework
**The ORB backtest engine is honest (every result is negative-R, no fake profitability) but methodologically thin: single-period, no walk-forward/OOS, no cost realism beyond a fixed $0.30 entry spread, a re-implementation that does not share live code, and zero reproducibility tracking. The "loop infra" the brief claimed (jarvis/decision, hypothesis-gate backtest path) does not exist; the loop arms that do exist are starved (0 rows).**

Verdict: No — a backtest result here cannot currently be trusted to predict live: single-period (no walk-forward/OOS), optimistic costs, a re-implementation not shared with live, ORB-only, no reproducibility, on tiny samples. It is honest (no fake profits) but methodologically not a validation framework yet.

## What actually exists vs. what the brief claimed

The brief asserted `/jarvis/decision`, a "hypothesis-gate backtest path", and a suite of loop endpoints "landed". **Verified false / starved:**
- No `/jarvis/*` route, no jarvis file anywhere (`grep -rln jarvis apps` → only `simulated_orders`-style false hits). No hypothesis-gate backtest path. The only backtest entrypoint is `POST /backtest` → `apps/api/src/backtest/runner.ts`.
- DB row counts (live prod): `hypotheses=0`, `trade_lineage=0`, `change_verifications=0`, `meta_label_scores=0`, `meta_label_models=0`. So the meta-label model that the (good) purged-CV code would validate **has never been trained** — purged-CV is dead code in practice. `change-verification` module is fully built + default-OFF and has produced nothing.
- What DOES produce rows: `backtests=6`, `engine_scores=34579` (stamping works), `strategy_versions=9`, `trade_labels=89`.

## The backtest engine itself (runner.ts)

**It is ORB-only.** `runner.ts:1-33` self-documents it as a "faithful TypeScript port" of `scripts/backtest-orb.mjs`, base-ORB path only; scalp_A/scalp_C and HTF/vol-expansion filters intentionally NOT ported. `meta.strategy` is hardcoded `"orb"` (line 494). The firm runs S1-S4 live; the backtester covers one. No per-strategy coverage.

**No code sharing with LIVE (the #135 finding is CURRENT).** runner.ts:30-33 explicitly: *"this runner validates a faithful re-implementation of the ORB rules, not the live orb-manager.ts code path. A Phase-1 refactor to share a pure core is ... intentionally NOT done here."* Fidelity to live is therefore unbounded/unmeasured — any divergence between this re-impl and `orb-manager.ts` is invisible.

**No walk-forward / out-of-sample / cross-validation.** `runBacktest` (runner.ts:419-500) loads one [date_from, date_to] window, simulates, reports on the same window. `config` (rangeMin/Max, tpR, breakoutHrs) is operator-supplied per run (backtest.ts:296-319) — nothing stops tuning params on the exact window you then report. No train/test split, no anchored/rolling WFO. Purged-K-fold (`packages/shared/src/meta-label/purged-cv.ts`) is correctly implemented (López de Prado ch.7: real purge + embargo + a `findLeakage` checker) but applies ONLY to the meta-label model eval, which has no model and no scores — it never runs on the backtest path.

**Cost modeling is optimistic.** Fixed `spreadUsd=0.3` applied to ENTRY only (runner.ts:302-303). Exit at SL/TP fills at the EXACT level (runner.ts:319-345) — no exit spread, **no slippage at all**, no gap-through (if a bar gaps past SL, you still get filled at slPrice, not the worse open). XAUUSD spread is $0.2-0.5 in-session but blows to $1-3 around news/rollover; modeling it as a flat $0.30 understates costs materially on a 2R strategy. One genuinely-conservative choice: same-bar SL-before-TP ordering (longs check `wc.l<=slPrice` at line 319 before TP at 326), so ambiguous bars resolve as losses — good.

**No high-impact-news exclusion.** `grep news|calendar|blackout|event runner.ts` → nothing. The live firm has an event-risk BLACKOUT gate; the backtest ignores it, so backtested trades include ones the live system would never take (and vice-versa) — another live-fidelity gap.

**Reproducibility: none.** `grep git_sha|engine_version|reproduc backtest*` → nothing. `assumptions` stored is a static string blob (backtest.ts:313-318). No git_sha stamped on a backtest, so a result can't be invalidated when the engine code changes, and two runs of "the same" backtest across code versions are indistinguishable.

## Data quality (live DB, the source the engine reads)

Runner default source is `ohlcv_candles` (runner.ts:47). Checked it:
- `XAUUSD/1min`: 174,087 candles, **0 duplicate timestamps**, range 2025-12-14 → 2026-06-12. Good hygiene on dupes/timezone (London-local via Intl, weekend filter present).
- BUT density is uneven: only ~6,880 M1/week from late-April-2026 onward (≈complete for a 5-day FX week), far sparser before. 174k over ~6 months ≈ 970/day vs ~1,440 expected → **pre-April backtests run on gapped M1**. `resample()` (runner.ts:184-204) silently emits partial buckets and there is **no gap detection / missing-bar warning** — a session with holes can still "form a range" and trade on bad data with zero flag.
- Separate stale table `backtest_xauusd_m1` (175k rows, ends 2026-05-13) exists but the runner doesn't use it by default — a trap if `BACKTEST_CANDLE_TABLE` is ever pointed at it.

## Results sanity (the good news)

All 6 backtests are honest and **all negative**: 17 trades over 4.5mo = -1.35R @47% WR; others -0.01R to -1.92R, 33-50% WR. Sample sizes are 6-17 trades — statistically meaningless. No sign of fake profitability, lookahead, or one-strategy-dominance inflation (there's only one strategy). The `trustWarnings` block (backtest.ts:278-284) is candid ("PAPER trading", "<20 trades = very low significance"). Sample-size warning exists but is generic, not enforced per backtest result.

## Validation route

`apps/api/src/routes/validation.ts` is NOT a validation framework — it's a live-trade aggregator over `simulated_orders`/`firm_memory`/`blackboard`. Uses string-interpolated `${days}` in SQL (bounded numeric via Math.min, so not injectable, but sloppy). No backtest-vs-live reconciliation, no engine-fidelity check.

## Tests

No `backtest.test.ts` and no test under `apps/api/src/backtest/`. The engine has zero unit coverage — the only guard is the (untested) port from `backtest-orb.mjs`.

**Kritiske funn:**
- NO walk-forward / out-of-sample split. runner.ts:419-500 tunes-and-reports on the same single [date_from,date_to] window; operator-supplied config params (backtest.ts:296-319) can be fit to the exact reported period. Any positive result would be unfalsifiable overfit. Evidence: no train/test code path anywhere in runner.ts.
- Backtest is a re-implementation, NOT shared with live (the #135 finding is STILL current, self-admitted at runner.ts:30-33). Divergence from live orb-manager.ts is unmeasured, so backtest fidelity to live execution is unbounded. A backtest result cannot be trusted to predict live behaviour.
- Cost model is optimistic and unrealistic: fixed $0.30 spread on ENTRY only, exact fills at SL/TP, ZERO slippage, ZERO gap-through (runner.ts:302-345). Real XAUUSD spread spikes to $1-3 at news/rollover. On a 2R strategy this systematically understates losses.
- Meta-label validation (purged-CV) is correct code but DEAD: meta_label_models=0, meta_label_scores=0 in prod. The trustworthy CV/embargo machinery has never validated anything because no model has been trained and shadow scoring is OFF.
- No reproducibility / git_sha stamping on backtests (grep confirms absent). Results cannot be invalidated when engine code changes; runs across code versions are indistinguishable. assumptions is a static string, not a code fingerprint.
- Silent data-gap risk: pre-April-2026 M1 in ohlcv_candles is sparse (~970/day vs ~1440 expected) and resample() emits partial buckets with NO missing-bar detection (runner.ts:184-204). Backtests over that range can form ranges and trade on holey data with no warning.
- ORB-only coverage (meta.strategy hardcoded 'orb', runner.ts:494) while the firm runs S1-S4 live. 3 of 4 strategies have no backtest at all. No per-strategy validation.
- No high-impact-news / event-blackout exclusion in the backtester (grep: none) though live has an event-risk gate — backtest trades a different universe than live, breaking comparability.
- Sample sizes are non-significant: largest backtest = 17 trades (DB-verified). No backtest can support any conclusion; the engine even labels <20 trades 'very low significance' but doesn't block reporting on it.
- Zero test coverage on the backtest engine (no backtest.test.ts). The only correctness guarantee is an untested manual port of scripts/backtest-orb.mjs.

**Anbefalinger:**
- Do NOT trust any backtest result here to predict live, today. Verdict the operator needs: the engine is a sanity/regression tool for ORB rules, not a validation framework. Treat current outputs as 'directionally negative, statistically meaningless'.
- Extract a pure shared core from live orb-manager.ts and have BOTH live and backtest call it (the deferred Phase-1 refactor at runner.ts:32). Until then, add an explicit live-vs-backtest reconciliation test on a fixed candle fixture so divergence is at least measured.
- Add walk-forward: split into IS-tune / OOS-report folds (anchored or rolling). Forbid reporting metrics on the same window params were chosen on. Persist which window was IS vs OOS on the backtests row.
- Make cost modeling realistic and configurable: variable/session-aware spread, per-side spread on exit too, a slippage parameter, and gap-through fills (fill at bar open when it gaps past SL/TP). Add a news-window widened-spread mode.
- Stamp git_sha (and engine semver) on every backtest row; surface a 'stale — engine changed since this run' flag in the UI when sha != current HEAD.
- Add gap detection to loadM1/resample: count expected vs present M1 per session, refuse or loudly warn when a session/window has >X% missing bars instead of silently trading partial buckets.
- Port the other strategies (S2-S4) or clearly scope the tool as ORB-only in the UI so nobody reads firm-wide conclusions from a one-strategy backtest.
- Add the event-risk/news blackout filter to the backtester to match live's universe; otherwise comparability is broken.
- Wire the meta-label loop end-to-end (train a model -> populate meta_label_models -> enable shadow scoring) so the genuinely-good purged-CV/embargo code actually validates something; right now it's 0 rows and inert.
- Add unit tests for the engine: same-bar SL/TP precedence, EOS close, range-too-wide/narrow skips, resample bucket boundaries, DST/London-time edges. Currently zero coverage on money-adjacent logic.
- Enforce a minimum-sample gate on reported summaries (e.g. mark results with <30 trades as 'insufficient' and suppress win-rate/PF headline numbers) rather than just a soft trustWarning.

---

## strategy inventory
**9 strategies declared, 5 ever traded, 2 never fired, and the ONLY "profitable" one is a result_r/cold-start artifact — net attributed PnL is -$3,374.**

Verdict: Strategy book is net −$3.4k; its only 'winner' is a result_r/cold-start artifact, two strategies never fired, FVG contradicts its backtest, and direction filters are micro-sample overfits — do not trust any current expectancy number until result_r and spread are fixed.

## Strategy inventory (code + LIVE simulated_orders, 226 closed rows, 19 trading days last 30d)

`getStrategyConfigs()` declares 9 strategies (strategy-execution.ts:211-277). All default OFF; each gated by `<NAME>_ENABLED`. Trades land in `simulated_orders` (no `managed_trades`/`positions` table exists). Live status inferred from last-trade recency (cannot read .env).

| strategyId | file (config) | idea | entry | exit / SL-TP | live n / win% / total PnL / avg_r | last trade | status | overfit risk |
|---|---|---|---|---|---|---|---|---|
| xau-volatility-expansion | vol-expansion/config.ts | trade ATR expansion (recent5h ATR ≥1.3× prior15h) | ratio breakout, SHORT-only default (config:72-73) | SL 0.7×ATR / TP 2.0×ATR (1:2.86) | **45 / 42% / +$2100 / 27.9** | 2026-06-16 | active-ish | **SEVERE — see crit#1** |
| xau-fvg | fvg/config.ts | H1 fair-value-gap retest | confirmation re-entry, SHORT-only, gap≤0.8ATR (config:76-80) | SL behind gap+buffer / TP 2.5R | **27 / 33% / −$2367 / 0.19** | 2026-06-21 | ACTIVE (most recent) | HIGH — backtest "+0.3R both halves" vs live −$2367 |
| xau-session-breakout | session-breakout/config.ts | break prior-session range (London/NY/Asia) | range break | SL opposite range / TP 1.5R | 24 / 25% / −$910 / −0.01 | 2026-06-17 | active | MED |
| xau-mean-reversion | mean-reversion/config.ts | counter-trend post-impulse (≥1.5ATR move, ADX<25, RSI 40/60) | reversion w/ RSI confirm, LONG-only default (config:81-82) | SL 0.75×ATR / TP 3.0R / 6h time-stop | 22 / 50% / +$875 / −0.35 | 2026-06-22 | ACTIVE (winner) | HIGH — long-only fit on n=12 |
| xau-scalp-overlap | scalp-overlap/config.ts | RSI-extreme scalp in 12-16 UTC overlap | RSI 25/75 | SL 1.0×ATR / TP 1.75×ATR | 7 / 43% / −$213 / −0.02 | 2026-05-10 | DEAD (6wk) | MED |
| xau-orb | orb/config.ts | opening-range breakout (London/NY) | range break + retest + momentum | SL opposite/midpoint / range-based | 5 / 0% / −$1300 / −0.30 | 2026-05-10 | DEAD (6wk), 0% WR | MED |
| xau-trend-following | trend-following/config.ts | EMA20/50 + ADX≥22 + vol-exp pullback | pullback 0.2-0.8ATR | SL 0.75×ATR / TP 4R / trail / 8h stop | 5 / 20% / −$807 / null | 2026-06-02 | near-dead | HIGH — many "sweet-spot" knobs |
| xau-breakout-continuation | breakout-continuation/config.ts | compression→trigger→expansion | compression breakout | spec-based | **0 trades EVER** | — | **DEAD/never fired** | unknown (untested live) |
| xau-pullback-continuation | pullback-continuation/config.ts | impulse→pause→continuation | pullback in trend | spec-based | **0 trades EVER** | — | **DEAD/never fired** | unknown (untested live) |

Plus 86 `NULL`-strategy rows (−$8540, pre-attribution Apr-May) and 3 `oanda_backfill` rows — orphaned, should be excluded_from_learning.

Net PnL across all *attributed* strategies = **−$3,374**. Remove the corrupted vol-exp profit and the book is deeply negative.

**Direction filters are micro-sample overfits** (all dated 2026-05-29): vol-exp SHORT-only from n=43, MR LONG-only from n=12 (SHORT n=1!), FVG SHORT-only from n=40. These hard-code a single 6-week regime into the strategy.

**Spread/slippage:** `spread_at_entry` is NULL on ALL 226 rows; `fill_latency_ms` populated on ~10. A spread-gate proxy exists (strategy-execution.ts:706) and OANDA fills carry implicit spread, but per-trade transaction cost is NOT captured for analysis. avg_r therefore ignores spread.

**News:** only 4 trades within 30min of a high-impact event (economic_events coverage is likely sparse, so this is a floor not a clean bill).

**Kritiske funn:**
- FAKE PROFITABILITY (vol-expansion). The only positive strategy (+$2100) is an artifact. 38/45 of its trades have regime_at_entry=NULL and carry +$1972 with an impossible avg_r of 33.87; the 7 trades with real regime labels are net-negative on R (avg_r −0.33). Top rows show original_risk_points=0.20 (a 20-cent stop on $3000+ gold = cold-start/stale default), producing result_r of 297, 260, 146. result_r = pnl/(risk_points×size) is corrupted whenever risk_points is the stale 0.20 default. So both the headline profit AND the avg_r=27.9 are bunk. Evidence: simulated_orders rows opened 2026-04-28..05-05, close_reason OANDA_SL_TP, result_r 60-297.
- TWO STRATEGIES NEVER TRADED. xau-breakout-continuation and xau-pullback-continuation have 0 rows ever (verified both naming columns). They are fully built + env-gated dead code; their filters (esp. Karri's ADX=25 which 'produced 0 trades over 6mo', pullback config:33) are so tight they never fire. Untested live, yet counted in the strategy roster.
- OVERFIT DIRECTION FILTERS on n=12-43. vol-exp SHORT-only (n=43), MR LONG-only (n=12, SHORT n=1), FVG SHORT-only — all hard-coded 2026-05-29 from <6 weeks of one regime. Live data already breaks them: FVG shorts (the 'edge' direction) lose −$692 live; FVG longs −$1675. These are curve-fits that will invert when gold's regime flips.
- FVG live contradicts its own backtest. Config claims validated '+0.25..0.35R, positive in BOTH halves, MFE 1.1R→1.9R' (fvg/config.ts:11-15). Live: 27 trades, 33% WR, −$2367, avg_r 0.19. It is the most recently active strategy (last trade 06-21) and the single biggest live loser. Backtest did not survive forward test.
- NO PER-TRADE TRANSACTION-COST CAPTURE. spread_at_entry NULL on 226/226 rows; fill_latency_ms on ~10. All result_r/avg_r/expectancy figures exclude spread. On XAUUSD with frequent wide spreads this materially overstates edge, especially for scalp-overlap and FVG.
- ONE-STRATEGY-DOMINANCE + DEAD BOOK. 5 of 9 strategies are dead or near-dead (orb/scalp last traded 06-May with orb at 0% WR over 5 trades; trend-following 1 trade since 06-02). Recent activity is concentrated in fvg (losing) + mean-reversion (the only genuine winner, but on n=22 with avg_r −0.35, meaning a few big TP3R wins mask many small losses — fragile).

**Anbefalinger:**
- Fix result_r at the source: recompute using actual stop distance, reject/flag any row where original_risk_points is the 0.20 cold-start default. Re-run all per-strategy expectancy after the fix — the current vol-exp 'profit' and avg_r=27.9 must not be trusted or shown on any dashboard until then.
- Backfill spread_at_entry (and slippage = fill price − signal_price, already have signal_price + fill_latency_ms on new rows) for every trade, then recompute expectancy net of costs. Without this, no strategy's edge claim is verifiable.
- Quarantine the 89 orphan rows (86 NULL-strategy + 3 oanda_backfill) with excluded_from_learning=true so they stop polluting aggregate PnL and any learning pipeline.
- Either delete or honestly label breakout-continuation + pullback-continuation as 'never fired / untested' — don't count them in the strategy roster. If kept, loosen the gates and run them in shadow first to confirm they CAN fire before claiming they exist.
- Treat all SHORT/LONG-only direction defaults as expired overfits: re-derive on the full 6-month sample with walk-forward OOS, or revert to symmetric and let a gate decide per-regime. Flag to Karri — these are trade-altering (gate logic) and need review.
- Demote FVG to shadow-only until it reproduces its backtested +0.3R on forward data; it is currently the top live loser while claiming validated edge. File the discrepancy as a strategy postmortem.
- Build one canonical per-strategy scorecard (n, win%, expectancy_net_of_cost, avg_R_capped, max_dd, regime breakdown) computed ONLY from rows with valid risk_points + non-null spread, and make it the single source of truth instead of raw AVG(result_r).

---

## data pipeline + macro/news coverage
****

Verdict: 



---

## manuscript methodology → Nexus Research Methodology
**The battery-ML thesis is methodologically rigorous (group-leakage holdout, honest limitations, no-silent-correction); Nexus has bought the schema for a research loop but the keystone tables produce ZERO rows — hypotheses=0, change_verifications=0, strategy_versions=100% seed, derive 5 days stale, trade metadata 50-88% NULL. The loop is wired on paper, starved in production.**

Verdict: Nexus has the thesis's vocabulary (versions, hypotheses, backtest, verification) but none of its discipline in production — the rigor tables are empty, the dataset is 50-88% NULL, and there is no out-of-sample test; the loop is real in schema, dead in data.

## Manuscript found and read
Thesis: `/home/nithu/code/Master-oppgave/` — ML prediction of solid-state Li electrolyte ionic conductivity. Code: `ml_training.py` + `chapters/Methodology.tex` (360 lines). 4,407 measurements / 342 compounds / 146 features (145 Magpie + Temp), 5 algorithms (RF/XGB/GB/LGBM/MLP), target log10(sigma).

## What the thesis does RIGHT (the rigor bar)
1. **Pipeline-at-a-glance + reproducible order** (Methodology.tex:2-17): every step states what/order/why; figure summarises raw 6,555 → modelling 4,407.
2. **Explicit inclusion criteria** (:47-60): kept only rows with the quantities the model needs; missing-but-not-discard rule (keep row, leave blank).
3. **No silent correction** (:123-125): conductivity outliers (≤0, >1e3, family-MAD, intra-paper jumps) **flagged, not corrected**.
4. **Iterative collect-test-correct** (:175-199): pilot ~50 pubs → run model → expose unit/parse/label bugs → fix at source → re-run → grow to 187. This is a closed learning loop on the DATASET.
5. **Two verification passes** (:189-194): digitised values cross-checked vs source paper; compositions reconciled to canonical formula.
6. **HONEST about what the split measures** (:258-272): random 80/20 measures **interpolation** (temperature points of a compound leak across split because Temp is a feature), explicitly NOT generalisation.
7. **Group-leakage holdout** (:274-293): composition-level holdout removes the held-out compound AND near-neighbour chemistries (same anion sublattice + small stoichiometric distance) — "grouped evaluation whose group is the chemistry itself". This is the gold-standard leakage control.
8. **Reproducibility** (:351-359, ml_training.py:42-44,98): seed=42 everywhere, fixed lib versions in requirements.txt, script+dataset shipped as supplementary, thesis cites code by commit hash (README).
9. **Model comparison on held-out test by R²/RMSE/MAE on same input matrix** (ml_training.py:111-139), uniform zero-fill so all 5 models see identical features (Methodology.tex:246).

## Nexus reality (DB verified live, build today)
- **hypotheses: 0 rows. change_verifications: 0 rows.** Schema landed; NO worker code writes to `hypotheses` (grep: zero non-test refs). change-verification code exists but gated `CHANGE_VERIFICATION_ENABLED=false` (change-verification.ts:55).
- **strategy_versions: 9 rows, ALL version=1, ALL notes='source=reconcile-seed', ALL performance_json empty**, one batch 2026-06-19. No strategy ever produced a v2. Version frozen — exactly as 2026-06-15 audit predicted.
- **Trade metadata still broken**: simulated_orders result_r 63% NULL, regime 88% NULL, atr 86% NULL; even last 7 days 50-57% NULL → Task-2 acceptance (<5%) NOT met.
- **Attribution still broken**: 79 of 224 trades (35%) have NULL strategy_id + NULL execution_source; unattributed bucket = **-$8,540** (the single biggest loss source, unascribable).
- **No fake profitability** (honest): 7 of 9 strategies losing; total deeply negative. The 2 "positive" strats (vol-expansion +$2100 @ 42% WR n=45, mean-reversion +$875 @ 50% WR n=22) are positive only via avg-win>avg-loss on tiny n — not statistically established.
- **"Hypotheses" are loss-clusters, not hypotheses**: agent_lessons (15 rows, last 2026-06-18, 5 days stale) carry sample_size 1-4 with confidence up to 0.875-0.95 — a sample of 1 yielding 0.875 confidence is overfitting. No proposed-change/expected-effect/test-method/success-criterion/rollback fields. Double-gated OFF (index.ts:241-242).
- **Backtest = re-implementation, ORB-only**: runner.ts header line 7 "intentionally NOT ported for v1" → does NOT share live strategy code, so results can't predict live (8 live strategies, backtest covers 1). Spread modelled ($0.30) but NO commission/swap/financing. No news/high-impact event filter in backtest. Entry close-based (no lookahead); intrabar SL-before-TP is conservative (good).
- **Crons fragile/skippable**: derive ran 06-08,09,13,14,15,17 then stopped — multi-day gaps, in-process setInterval, matches prior-audit blindspot finding.

## Translation: the Nexus Research Methodology (doc)
Map each thesis practice to a trading analogue Nexus is MISSING:
| Thesis rigor | Nexus equivalent | Status |
|---|---|---|
| Curated dataset, row-per-measurement, provenance (DOI) | Curated trade table, row-per-trade, full provenance (strategy_version, regime, atr, session) | BROKEN (50-88% NULL) |
| Outliers flagged not corrected | Anomalous fills/slippage flagged not dropped | absent |
| Iterative collect-test-correct on dataset | Continuous metadata-quality repair loop | absent (NULLs persist) |
| Inclusion criteria | Trade-eligibility for evaluation (only fully-attributed trades) | absent (35% unattributed counted) |
| Group-leakage holdout (chemistry=group) | Walk-forward / out-of-sample by TIME (regime=group); never test on data overlapping train period | absent (no walk-forward, no OOS) |
| Honest "this measures interpolation not generalisation" | Explicit "this backtest re-implements, doesn't predict live" caveat surfaced to operator | partially (code comment only) |
| Seed + versions + commit-hash citation | strategy_versions stamping every trade + params_json hash | seed-only, never v2 |
| 5-model comparison on identical held-out matrix | Strategy comparison on identical evaluation window per (strategy,version) | absent (scorecards spread, no per-version) |
| Limitations chapter | Explicit per-strategy limitation register | absent

**Kritiske funn:**
- KEYSTONE DEAD: hypotheses=0 + change_verifications=0 rows (DB-verified). The hypotheses table has ZERO non-test code writers in apps/worker/src (grep). The schema landed but nothing fills it — the research loop's second half cannot produce a single artifact. This is the thesis's 'collect-test-correct loop' with the test+correct stages physically disconnected.
- strategy_versions is 100% seed: all 9 rows version=1, notes='source=reconcile-seed', performance_json empty, created in one 2026-06-19 batch. No strategy has ever produced a v2 (DB-verified). Nexus cannot answer 'did v2 beat v1?' — the thesis's model-comparison discipline has no object to compare. Version column frozen exactly as the 2026-06-15 audit predicted; 8 days later, unchanged.
- Trade dataset is not research-grade: result_r 63% NULL, regime 88% NULL, atr 86% NULL; even last-7-days 50-57% NULL (Task-2 acceptance of <5% FAILED). 35% of trades (79/224) are fully unattributable (NULL strategy_id+source) and that bucket is the single largest loss at -$8,540. The thesis would have discarded or fixed these rows at source; Nexus evaluates on them. Garbage-in for every downstream metric.
- No out-of-sample / walk-forward validation exists anywhere (grep: no walk-forward framework). The thesis's central rigor move — a strict grouped holdout (composition+near-neighbours removed) to separate interpolation from generalisation — has NO trading analogue. Strategy 'evidence' is in-sample on the same live trades used to derive lessons. This is the leakage the thesis explicitly designs against.
- Backtest cannot predict live: runner.ts:7 states strategy logic is 'intentionally NOT ported' — it re-implements ORB only, covers 1 of 8 live strategies, models spread but no commission/swap, and has no high-impact-news filter. A hypothesis 'tested' here tells you nothing about the live strategy it claims to validate. The thesis ran the SAME pipeline on the data; Nexus runs a different pipeline.
- derive/lessons stale 5 days (last 2026-06-18) with multi-day gaps, fragile in-process setInterval crons (prior-audit blindspot), and lessons carry confidence up to 0.95 on sample_size=1 — statistically meaningless, the opposite of the thesis's n=4,407 discipline. 'Hypotheses' have no proposed-change/expected-effect/success-criterion/rollback.

**Anbefalinger:**
- WRITE the hypotheses producer (P0). Point derive-lessons output at the `hypotheses` table with the thesis's full-field schema: problem, supporting SQL, proposed change, expected effect, test method, success criterion, rollback. Acceptance: next derive run produces >=1 fully-populated hypothesis row. Without this the loop's second half is unreachable code.
- Fix the dataset at source before any modelling, thesis-style (P0). Backfill result_r/regime_at_entry/atr_at_entry/session at WRITE time in BOTH execution paths (firm_strategy AND the unattributed/blade path). Repair the 79 NULL-source rows (operator-gated SQL via nexus-pg-rw). Acceptance: <5% NULL over 48h AND unattributed share <15%. This is the thesis's collect-test-correct loop applied to live trades.
- Add a walk-forward / out-of-sample protocol as the canonical strategy validator (P0). Group=TIME (and/or regime): train/derive on period A, validate on disjoint later period B; never evaluate a change on trades that overlap its derivation window. This is the direct analogue of the thesis composition-holdout and is the single biggest scientific-rigor gap.
- Make strategy_versions LIVE, not seed (P1). Every params change appends a new version row + stamps subsequent trades; populate performance_json per (strategy,version) from a single canonical scorecard. Acceptance: a real param change creates v2 and old trades retain v1. Enables the thesis's model-comparison discipline.
- Share ONE strategy core between live and backtest, dispatch per strategy_name, add commission/swap + a news-window filter (P1). Acceptance: backtesting a strategy over period X reproduces its live signals within tolerance. Until then, label backtest output 'illustrative, does NOT predict live' in the operator-facing UI (the thesis-style honest-limitation move).
- Turn on the verification arm and prove loop closure (P1, change-verification gated CHANGE_VERIFICATION_ENABLED). Every landed change gets parent_task_id + a before/after metric check N cycles later writing a 'helped/did-not-help' row to change_verifications. Acceptance: one landed change auto-produces one verdict row. This closes the loop the thesis closes by re-running the model after each correction.
- Replace single-sample lessons with a minimum-n + confidence-floor rule (P2): no lesson promoted on sample_size<10 (thesis used n=4,407; confidence 0.95 on n=1 is noise). Harden crons (out-of-process scheduler + catch-up + alert on skip) so derive/scoring don't silently stall for days.
- Write the methodology doc into the repo as docs/research/nexus-research-methodology.md mirroring the thesis chapter order (curation -> inclusion -> no-silent-correction -> iterative repair -> modelling subset -> feature documentation -> walk-forward -> model comparison -> limitations register -> verification), and a per-strategy limitations register stating exactly what each strategy's evidence does and does NOT establish (thesis :258-272 honesty standard). No-fake-certainty as a binding rule.

---

## Thesis-1 research (cited best practices)
****

Verdict: 



---

## GPU/worker/queue architecture plan
**GPU need NOW is ~zero (0 trained models, the one ML model is a CPU linear classifier); the real architecture gap is that loop-closure jobs are starved, not under-resourced. Design queues for CPU-medium work and rent GPU on-demand via the Vast path that already exists.**

Verdict: GPU-now is unnecessary (0 models, CPU-only linear classifier, no GPU libs); the genuine Task-9 gap is a durable medium-CPU queue tier plus loop-closure job producers — design for cloud-on-demand GPU (reuse existing Vast path), and do not buy.

## What actually exists (verified against code + live prod DB, 2026-06-23)

**Scheduling today is three disconnected layers, none of which is a real job queue for heavy work:**

1. **In-process `setInterval` timers** in `apps/worker/src/index.ts` — supervisor (10min, L146), bot-manager (15min, L160), firehose digest (hourly self-gating to Sun 23:00 UTC, L177), lesson-derivation (hourly self-gating to 04:00 UTC, L240). Plus `FirmOrchestrator.start()` (L350) self-scheduling at adaptive cadence (90s default, `getSessionCadence`, orchestrator.ts:251). These are wall-clock timers inside the long-lived worker — NOT durable jobs. If the worker restarts mid-interval, the tick is simply skipped.
2. **BullMQ/Redis queues** — only THREE exist: `QUEUE_NAMES = {LLM: "llm-jobs", BOT_CYCLE: "bot-cycle-jobs", AGENT: "agent-jobs"}` (packages/shared/src/index.ts:80). The `jobs` table mirrors lifecycle (index.ts:20-42 `attachLifecycle`). **`bot-cycle-jobs` is dead** — last queued 2026-04-22 (firm orchestrator superseded it; 13,500 completed then nothing). `agent-jobs` is live (1,886 completed, 12 stuck `queued` since 2026-06-11 — a leak). There is NO backtest queue, NO training queue, NO research/embedding queue.
3. **Host crontab** (`NEXUS-WATCH-BLOCK`, UTC) — only read-only watch pings: `*/30 6-21 * * 1-5` + `35 4 * * *` calling `nexus-watch.sh`. No compute scheduling.
4. **Out-of-band GPU dispatch already built** in `command-center/_bin/`: `firm-job-submit.sh` (writes a `## JOB` block to code-2's Obsidian inbox), `firm-job-run.sh` (picks up), `firm-job-gpu.sh` → `vast-job.sh` (full Vast.ai lifecycle: search→create→ssh→run→fetch→**auto-destroy via trap**, default RTX_4090 @ max $0.50/hr, ephemeral CUDA image). It is **PII-fail-closed**: `--data-class pii` is hard-refused (`firm-job-gpu.sh`), `--pii yes` forces local (`firm-job-submit.sh`). This is a sound, cheap, cloud-now GPU path that ALREADY EXISTS and needs no rebuild.

**The decisive fact for the GPU question — there is nothing for a GPU to do:**
- `meta_label_models`: **0 rows, 0 models ever trained** (`SELECT count(*)` = 0). The scorer (`meta-label/scorer.ts:140`) loads a model with a `weights` array — i.e. a **linear/logistic classifier, JSON-stored, trains in milliseconds on CPU**. No torch/xgboost/sklearn/CUDA dependency anywhere in the worker.
- `backtests`: only **6 rows total**, ALL `trust_level=simulation`, `data_source=twelvedata`, 1 failed. Backtesting is manual-HTTP, low-volume, CPU-bound, and not execution-grade.
- No LLM inference runs locally that would need GPU — `llm-jobs` calls hosted APIs.

**Realtime CPU load (the genuine always-on work):**
- `engine_scores`: 34,589 rows, ~500–2,600/day (530 today, 2,625 on 06-22). This is the orchestrator's per-cycle strategy scoring — the real CPU heartbeat. Weekend gaps (06-20/21) are gold-market-closed, expected.
- `ohlcv_candles`: 15min fresh to **2026-06-23 11:15** (3,973 rows, live). **1min is STALE since 2026-06-12** (174k rows, backfill only — 11 days stale). Spread/bid-ask captured nowhere (prior audit Stage 1).
- `signal_scorecards`: 1,872 rows (live evaluation substrate). `postmortems`: 179.

**Loop-closure infra: landed but STARVED (the 2026-06-15 audit's branch is now in prod, producing ~nothing):**
- `strategy_versions`: 9 rows (exists now — was DEAD in prior audit). Progress.
- `hypotheses`: **0 rows.** `change_verifications`: **0 rows.** `trade_lineage`: **0 rows.** The keystone tables exist but no job writes to them. The second half of the learning loop is wired but idle.
- `agent_lessons`: 15. `firm_state`: 100 (idempotency keys).

**Net:** the bottleneck is missing job-producers and a missing durable medium-work queue — NOT missing GPU horsepower.

**Kritiske funn:**
- GPU-NOW IS A NON-PROBLEM — buying or even renting a GPU today would idle. Evidence: meta_label_models=0 (no model exists), the model class is a CPU linear classifier (weights array, scorer.ts:140), backtests=6/all-simulation, no GPU lib in the tree. Operator's cloud-now lean is correct; do NOT provision GPU until a trained model needs >minutes on clean data. Spending now = pure burn.
- NO DURABLE QUEUE FOR MEDIUM/HEAVY WORK. Only 3 BullMQ queues exist (llm/bot-cycle/agent); bot-cycle is dead since 2026-04-22. Backtests, training, embeddings, postmortems, research all run as either in-process setInterval ticks (lost on restart) or manual HTTP/Obsidian-inbox dispatch. There is no realtime/backtest/training/research/postmortem/alert queue split. This — not GPU — is the actual Task-9 gap.
- JOB STARVATION, NOT JOB RESOURCING, IS WHY THE LOOP DOESN'T CLOSE. hypotheses=0, change_verifications=0, trade_lineage=0 in prod despite the tables existing. The infra landed (strategy_versions went 0→9) but no producer enqueues hypothesis/backtest/verification jobs. A GPU server would change none of this.
- DATA NOT CLEAN ENOUGH TO TRAIN ANYTHING — training on it now would bake in garbage. 1min candles stale 11 days (since 06-12); no spread/bid-ask captured anywhere; prior audit: result_r ~64% NULL, regime ~90% NULL, ~41% of trades un-attributable to a strategy. Any model trained today inherits lookahead/leakage/label-noise risk. Clean-data gate must precede any training queue.
- IN-PROCESS setInterval SCHEDULING IS FRAGILE AND UNOBSERVABLE. firehose/lesson/supervisor ticks live inside the worker process (index.ts:146-347); a Railway redeploy mid-window silently skips the tick (the code even comments on this for lesson-derivation). 12 agent-jobs stuck in 'queued' since 2026-06-11 with no reaper. No queue-length / worker-health / job-age monitoring table exists.
- BACKTESTS ARE SIMULATION-GRADE AND DON'T SHARE LIVE CODE (prior audit Stage 6, still true: 6 rows, all twelvedata/simulation). Even with a backtest queue, results won't predict live fills until backtest reuses the live execution path and models OANDA spread/slippage/fees. A param-search GPU job on this engine would produce confidently-wrong numbers.

**Anbefalinger:**
- DECISION: cloud-on-demand, do NOT buy. Use the EXISTING Vast path (firm-job-gpu.sh -> vast-job.sh, auto-destroy, PII-fail-closed). It already does search->run->fetch->destroy at <=$0.50/hr. No new GPU infra until a real training job exists. Reconfirm to operator: GPU spend today idles.
- BUILD THE MEDIUM (CPU) TIER FIRST — this is the real Task-9 win. Add durable BullMQ queues to QUEUE_NAMES: 'backtest', 'postmortem', 'features', 'research/embeddings'. Move the four in-process setInterval ticks (supervisor/bot-manager/firehose/lesson-derivation) onto BullMQ repeatable jobs so they survive restarts and are observable in the jobs table. Keep the firm orchestrator's 90s realtime loop in-process (it's latency-sensitive and correctly adaptive).
- DEFINE WORKER TYPES on this split: A=realtime/CPU (orchestrator cycle, candle poll, indicators, dashboard, alerts) -> stays in the existing Railway worker, never blocked by batch. B=medium/CPU (strategy scoring batches, simulation backtests, postmortems, feature/label builds, embeddings, LLM summarization) -> a SEPARATE 'batch-worker' Railway service consuming backtest/postmortem/features/research queues, so a long backtest never stalls the 90s trade loop. C=heavy/GPU -> dispatched out-of-band to Vast ONLY when a job genuinely needs it (model training on clean data, large param search, LLM fine-tune/sim batches). C does not exist yet and should stay dormant.
- ADD A 'jobs2' / job-monitoring spine before adding compute: columns for queue, type, status, enqueued_at, started_at, finished_at, attempts, worker_id, payload_hash, result_ref. Add a reaper (BullMQ stalled-job recovery) to clear the 12 stuck agent-jobs and any future zombies. Surface queue depth, oldest-queued-age, failed-count, and data/model freshness (max(candle_time), max(meta_label_models.trained_at)) on the dashboard. Monitoring is cheap and missing.
- GATE ANY TRAINING/BACKTEST QUEUE BEHIND A DATA-CLEAN CHECK. Before queue C or even simulation backtests are trusted: restore live 1min candles (stale since 06-12), capture spread/bid-ask, fix trade->strategy attribution (~41% un-attributed), and backfill result_r/regime. Wire the backtest job to REUSE the live execution path (shared code) and model OANDA spread+slippage+fees. Otherwise trained models and param-search are fake-profitable.
- UNBLOCK THE LOOP BY ADDING PRODUCERS, NOT HORSEPOWER. The highest-leverage Task-9 deliverable is a 'postmortem -> hypothesis' enqueuer and a 'hypothesis -> backtest -> change_verification' chain that writes the currently-empty tables (hypotheses=0, change_verifications=0, trade_lineage=0). These are all CPU jobs. Land them on the new batch-worker; revisit GPU only after the loop produces rows and a model that's slow on CPU emerges.
- WHEN GPU IS EVENTUALLY NEEDED, formalize a 'training' / 'param-search' queue whose CONSUMER is a thin dispatcher that calls vast-job.sh with a job-kit and writes results back to meta_label_models/backtests. Keep PII fail-closed (real client/AS/audio/memory data never leaves for Vast — already enforced). This keeps GPU strictly on-demand and revertable, matching operator rollback-safety rules.

---

## analytical layer + no-trade + agent-debate + Jarvis/frontend plan
**Agent-debate / Skeptic layer is dead code (0 rows ever); regime engine + no-trade explainer + postmortems are real and alive, but strategy/engine scoring is partly placeholder; "Jarvis" endpoints do not exist.**

Verdict: Intelligence layer is half-real: regime engine, no-trade explainer, and postmortems are genuinely alive and decent — but the headline 'agent debate / mandatory Skeptic' is dead code (0 prod rows ever), strategy/engine scoring leans on a hardcoded regime_fit and zero-spread economics, and 'Jarvis' doesn't exist.

VERIFIED AGAINST LIVE PROD DB (2026-06-23) + code. The prompt's framing ("Jarvis cockpit + /jarvis/* endpoints + stream all landed") is FALSE — there is no `jarvis` anywhere in apps/ (grep: 0 hits). The closest is `apps/api/src/routes/cockpit.ts` and the dashboard `why-no-trades-today` route. Do not build the spec on a Jarvis foundation that does not exist.

1) AGENT DEBATE / MANDATORY SKEPTIC — EXISTS IN CODE, DEAD IN PROD (the real gap the prompt flagged).
   - `apps/worker/src/firm/challenge-agents.ts` implements 3 challengers: No-Trade/Bastion (l.16), Bear-Case/Lattice (l.82), Timing-Skeptic/Drift (l.169). `runAllChallenges` (l.239) is called from `managers.ts:377` inside `bladeApproval`, and blocking logic exists (`managers.ts:389-414` strongChallenges strength>=4 → BLOCKED_PENDING_RESPONSE at l.598-600).
   - LIVE DB: `SELECT count(*) FROM blackboard WHERE topic LIKE '%challenge%'` = **0. Zero. Ever.** (blackboard.manager.synthesis=7119, manager.decisions=5838 same period). bladeApproval demonstrably runs (1,399 PROPOSAL rows in 7d: 686 neutral/425 short/288 long) yet not one challenge message persisted. `board.publish` always INSERTs (blackboard.ts:89), so the only explanation is `CHALLENGE_AGENTS_ENABLED=false` (kill-switch at challenge-agents.ts:247) is set in prod. The "mandatory challenge round" comment (l.5) is aspirational — there is NO real debate before trades. It is single-path.
   - Even if enabled, it is not a debate: challengers publish objections one-shot; there is no rebuttal/resolution loop (managers.ts:385 literally says `resolved: false, // Not yet implemented`). Strong challenges request resolution but nothing resolves them.

2) MARKET REGIME ENGINE — REAL AND ALIVE. portfolio-brain publishes `xauusd.portfolio.context` (7,131 rows/7d, live). Real distribution: TRENDING-DOWN 956, MIXED_NO_EDGE 853, RANGING 803, LOW_VOLATILITY 730, TRENDING-UP 156, HIGH_VOLATILITY 11. BUG: `regimes.ts` MarketRegime union (l.35-42) does NOT include `LOW_VOLATILITY` but the DB emits 730 of them → type/runtime drift; any consumer using the enum will treat these as unhandled.

3) STRATEGY / ENGINE SCORING — PARTLY PLACEHOLDER. `engine_scores` is alive (34,594 rows, live to now) across 6 engines (technical/momentum/macro/structure/intermarket + sentiment). BUT: (a) `regime_fit` is a hardcoded constant **1.00 for ALL 34k rows** — regime-fit scoring is not actually computed; (b) the `regime` column stores RISK regime (normal/high/elevated), not MARKET regime, so per-market-regime strategy scoring isn't captured here; (c) `sentiment` engine is STALE — last row 2026-04-24 (~2 months dead); (d) loop-closure stamp landed but only **115 / 6,301** scores carry a trade_id — 98% are unlinked to outcomes.

4) NO-TRADE INTELLIGENCE — LOGGED + EXPLAINED, partially valued. `gate_decisions` alive (34,594 all-time, live). `why-no-trades-today/route.ts` builds a real NL narrative from /decision-funnel + gate rollups. Counterfactual valuation exists as postmortem classification `NO_TRADE_SHOULD_HAVE_WON` but only **1 row** — effectively unused; no systematic "value of trades we correctly skipped" ledger.

5) POSTMORTEM ENGINE — GOOD QUALITY. `postmortems` (179 rows, live). full_reasoning 100% populated (LLM-generated, specific — not boilerplate). Classifications sane and P&L-consistent: CORRECT_THESIS 45 (+339 avg), WRONG_THESIS 48 (-531 avg), RIGHT_THESIS_BAD_EXECUTION 36 (-247), RIGHT_THESIS_BAD_INVALIDATION 39 (-10). DEAD COLUMN: `cleanliness` 100% NULL across all 179.

6) TRADE THESIS BUILDER — no dedicated module, but `ThesisQuality` + prismSynthesis fills the role (synthesis 7,119 rows). Adequate; not a gap.

7) TRADE-ECONOMICS DATA QUALITY (cross-domain, but it poisons the analytical layer): `simulated_orders` ALL 224 closed trades have **spread_at_entry = NULL** → every postmortem/score reasons over zero-spread economics (unrealistic). `strategy` column NULL on 223/224 (dead); attribution survives only via `strategy_id` (86 NULL there too, -$8,540 of the loss is unattributed). Net demo P&L over the run: **-$12,363, 36% win rate**. By strategy_id only xau-volatility-expansion (+2,100) and xau-mean-reversion (+875) are net positive; xau-orb -1,300, xau-fvg -2,367.

FRONTEND = ai-2's lane. Below is a spec to hand them, not for me to build.

**Kritiske funn:**
- DEAD AGENT-DEBATE: 0 challenge messages ever in prod blackboard despite the code calling runAllChallenges every cycle. CHALLENGE_AGENTS_ENABLED=false means there is NO Skeptic/Bear/No-Trade challenge before trades — the firm is single-path. Evidence: blackboard topic '%challenge%' count=0 all-time vs 7,119 synthesis rows; challenge-agents.ts:247 kill-switch; managers.ts:377 caller.
- FAKE SCORING SIGNAL: engine_scores.regime_fit is a hardcoded 1.00 across all 34,594 rows — the 'regime-fit' input to any strategy-scoring is a placeholder, not a measurement. Any dashboard or calibration that trusts regime_fit is reading a constant.
- NO SPREAD/SLIPPAGE CAPTURED: spread_at_entry is NULL on 100% of 224 closed orders. Postmortems, engine P&L attribution, and any backtest reason over frictionless economics — systematically optimistic. (simulated_orders, verified.)
- DEBATE HAS NO RESOLUTION LOOP even when enabled: challenges are one-shot objections; managers.ts:385 marks resolved:false 'Not yet implemented'. Strong objections trigger a REQUEST that nothing answers — so 'mandatory challenge' would deadlock or be ignored, not debated.
- STALE/UNLINKED SCORING: sentiment engine dead since 2026-04-24; only 115/6,301 engine_scores carry a trade_id, so 98% of scores never get tied to an outcome — the scoring loop is effectively open. Counterfactual no-trade valuation (NO_TRADE_SHOULD_HAVE_WON) has just 1 row.
- REGIME ENUM DRIFT: portfolio-brain emits LOW_VOLATILITY (730 rows/7d) but regimes.ts MarketRegime union omits it — parseMarketRegime would coerce it to 'unknown', silently dropping a whole regime class from gates/UI.

**Anbefalinger:**
- Decide the debate question explicitly with Karri (it is trade-altering → gated): either (a) DELETE challenge-agents.ts as dead code and stop claiming 'mandatory challenge', or (b) enable CHALLENGE_AGENTS_ENABLED in SHADOW first (log challenges, don't block) to measure how often a Skeptic would have vetoed — then add a real rebuttal/resolution loop before letting it block. Do NOT keep dead 'mandatory' code that implies a safety property that does not exist.
- Fix engine_scores.regime_fit to actually compute fit (or drop the column). A constant 1.00 is worse than nothing — it gives false confidence. Until fixed, mark it in the UI/spec as 'not measured'.
- Capture spread_at_entry (and ideally realized slippage = fill vs mid) on every order before trusting any P&L-based scoring/postmortem economics. This is observability, not strategy — can be done immediately.
- Backfill/repair strategy_id on the 86 unattributed closed trades and retire the always-NULL `strategy` and `cleanliness` columns; un-attributed -$8,540 makes per-strategy scoring untrustworthy.
- Add LOW_VOLATILITY to regimes.ts MarketRegime union + label/weak-set maps; audit every `regime.includes(...)`/parseMarketRegime consumer for the dropped class.
- Re-point sentiment engine or remove it from the engine roster (dead 2 months); and wire engine_scores trade_id stamping to fire on EVERY closed trade, not 2% of them, before building any engine-attribution UI.
- FRONTEND SPEC for ai-2 (news-channel/control-room, explains intelligence not noise): (1) 'Why no trade right now' live tile sourced from gate_decisions + why-no-trades-today narrative + current regime from portfolio.context. (2) 'The case against this trade' panel — render challenge messages IF/WHEN the debate layer is enabled; until then show 'Skeptic offline' honestly rather than faking it. (3) Postmortem feed (already high-quality) as the 'lessons' channel, grouped by classification with avg-pnl. (4) Strategy scoreboard keyed on strategy_id (not the dead strategy col), explicitly flagging null-spread/unattributed data so it doesn't read as ground truth. (5) Regime ribbon (market + risk, two separate axes per regimes.ts). Hard rule for ai-2: every tile must cite its source table + freshness; never render regime_fit until it is real.


---

## DE 15 SPØRSMÅLENE (DB-verifisert)
All numbers below are live-DB verified (2026-06-23), not taken on faith from the brief.

1) Are current trades good? No. The honest live engine (execution_source=firm_strategy) is 86 trades, 36% win rate, PF 0.98, -$263. Across all closed orders the book is -$11,914. The only "profit" is fake: 18 corrupt-stop rows (abs(entry-stop)<0.5pt) book +$9,238 with 14W/2L and ~$0 losses; on valid stops the book is -$18,797 (PF 0.47). Strip the artifact and there is no good trade quality.

2) Real edge or bad assumptions? Bad assumptions / no demonstrated edge. The "+$2k profitable" headline is a result_r/cold-start + corrupt-stop artifact. Worse, spread_at_entry is NULL on 100% of 224 orders and commission/financing/swap are modeled NOWHERE, so even the -$263 firm_strategy figure is upward-biased by full spread+commission (~0.3-0.6 USD/round-trip unaccounted). Real edge is negative-to-zero before costs, clearly negative after.

3) Strategies tested properly? No. There is no walk-forward / out-of-sample split anywhere (runner.ts tunes-and-reports on the same single window). Backtest is an ORB-only re-implementation NOT shared with live code (#135 still open), single-period, costs = fixed $0.30 entry spread with exact SL/TP fills and zero slippage/gap. Two strategies (xau-breakout-continuation, xau-pullback-continuation) have 0 rows ever. Direction filters are hardcoded curve-fits on n=12-43 from one 6-week regime. FVG live (-$2,367, 33% WR) directly contradicts its own backtest.

4) Model on valid labels? No model exists. meta_label_models=0, meta_label_scores=0 (DB-verified). scorer.ts references an offline trainer that isn't in the repo. trade_labels=89 rows and stale. Purged-CV code is correct but dead — it has validated nothing. There is literally nothing trained to evaluate.

5) Lookahead bias? Present in the live measurement layer, not the backtest. Backtests are honestly negative. But shadow_signals trackPendingOutcomes resolves via a single current spot (not price path) and books full +1.747R reward; only 32/178 tp_hit and 24/143 sl_hit land near the real barrier — shadow P&L is win-inflated. "Strategy evidence" is also in-sample on the same live trades used to derive lessons (no holdout) = leakage.

6) Data leakage? Yes, two forms. (a) In-sample evaluation: lessons derived from and tested on the same trade set, no grouped holdout. (b) The forward-test resolver (shadow-log.ts:525-531) reads ohlcv_candles with NO timeframe filter, walking 1min+15min bars together; duplicate-timestamp bars corrupt first-touch SL/TP ordering across ~40,775 rows.

7) Slippage/spread handled? No. spread_at_entry NULL on 100% of 224 live orders (DB-verified); oanda-sync marks it "reserved; v2". Commission/financing/swap modeled nowhere. A good slippage model EXISTS in paper-execution.service.ts but the live OANDA-synced path never populates it. Backtest applies spread on entry only; all exits frictionless. Every PnL/edge number is optimistically biased.

8) Timezones correct? Largely yes — session thresholds + DST are documented and handled (docs/ref/session-thresholds.md). The real "time" defect is not TZ but a stale/mixed candle source: backtest default 1min ends 2026-06-12 (10+ days stale), runner only errors on zero candles so recent windows silently truncate. Not a clock bug, a freshness/coverage bug.

9) No-trade logged + learned? Logged yes, learned no. The no-trade explainer + regime engine are genuinely alive. But the agent-debate/Skeptic layer that would challenge decisions is DEAD: 0 challenge messages ever in prod (CHALLENGE_AGENTS_ENABLED=false) vs 7,119 synthesis rows, and even enabled it has no resolution loop (managers.ts:385 resolved:false "Not yet implemented"). Nothing learns from no-trades.

10) Does the platform improve after a trade? No — the loop is wired but starved. hypotheses=0, change_verifications=0, trade_lineage=0, meta_label_models=0 (all DB-verified empty). engine_scores trade_id stamp: 0/6,980 stamped in last 7d — the eval layer cannot join scores to outcomes. The keystone autotune readback getActiveProfile() (calibration.ts:362-366) still hardcodes baseline, so applied calibrations are written and never read back. strategy_versions=9, all version=1 seeded once; no v2 ever. The system adjusts and forgets.

11) Does it know which strategy fits which regime? No. engine_scores.regime_fit is a hardcoded 1.00 across ALL 34,599 rows (DB-verified constant). regime_at_entry is NULL on 88% of trades and strategy NULL on 223/224. Per-strategy-per-regime attribution is impossible on this data; any "regime fit" shown is a placeholder.

12) Frontend explains decisions? Partly. Regime engine, no-trade explainer, and postmortems are real and surface decent explanations. But "Jarvis" endpoints do not exist, the agent-debate panel is backed by 0 rows, and any tile reading hypotheses/change_verifications/regime_fit/strategy P&L is silently rendering empty or placeholder data — explaining a decision process that didn't actually run.

THIN/UNCERTAIN DOMAINS: "data pipeline + macro/news coverage" and "thesis-1 cited best practices" came back undefined/blank in the brief — I did not independently re-audit news/macro coverage, so treat those two as un-evidenced. Everything I report above I re-verified against the live DB or source.

SINGLE MOST DANGEROUS FINDING: see mostDangerous field.


## TOPP 10 SVAKHETER
Ranked by danger to capital/decisions (all live-verified):
1. FAKE PROFITABILITY — headline +$2k is an artifact. 18 corrupt-stop rows (<0.5pt) = +$9,238 @ 14W/2L, ~$0 losses; valid-stop book = -$18,797 (PF 0.47). These 18 rows have excluded_from_learning=0 and astronomical result_r, so they POISON every downstream metric and any future model.
2. NO COST MODEL — spread_at_entry NULL on 100% of 224 orders; commission/financing/swap modeled nowhere. Every edge estimate is upward-biased; you cannot know true expectancy.
3. LEARNING LOOP HOLLOW — hypotheses=0, change_verifications=0, trade_lineage=0, meta_label_models=0 (DB-verified). Writers missing/uncalled. The advertised self-improvement produces nothing.
4. AUTOTUNE NO-OP — getActiveProfile() hardcodes baseline (calibration.ts:362-366); applied calibrations are written and never read back. The one statistical feedback motor adjusts and forgets.
5. ATTRIBUTION STARVED — strategy NULL on 223/224, execution_source NULL on 79 trades (= the single biggest loss bucket, -$10,797). You cannot attribute losses to a strategy.
6. NEGATIVE/NO EDGE — firm_strategy = 36% WR, PF 0.98, -$263 over 86 trades, BEFORE unmodeled costs. No demonstrated positive expectancy.
7. NO OUT-OF-SAMPLE / WALK-FORWARD — backtests tune-and-report on the same window; any positive result is unfalsifiable overfit. Backtest is an ORB-only re-implementation not shared with live (#135).
8. WIN-INFLATED SHADOW METRICS — shadow_signals resolves via single spot not price path; books full +1.747R; only ~18% of fills land near the real barrier. Dashboards reading shadow P&L are lied to.
9. DEAD AGENT-DEBATE / no challenge layer — 0 challenge rows ever; CHALLENGE_AGENTS_ENABLED=false; no resolution loop. Firm is single-path with no skeptic.
10. PLACEHOLDER SIGNALS — regime_fit hardcoded 1.00 across 34,599 rows; engine_scores 0/6,980 stamped with trade_id in 7d; regime/atr metadata 86-88% NULL. Core scoring inputs are constants/empty.


## TOPP 10 FORBEDRINGER
Ranked by value (close the cheapest gaps that unblock everything else first):
1. QUARANTINE corrupt data — backfill excluded_from_learning=1 on the 18 sub-0.5pt-stop rows and recompute realized R; stop the +$9k artifact from poisoning metrics and any model. (1 SQL migration, highest ROI.)
2. POPULATE spread_at_entry + add commission/financing fields on the live OANDA-synced path; reuse the existing paper-execution slippage model. Every other metric is meaningless until costs are real.
3. WIRE attribution — stamp strategy/execution_source on 100% of new trades; never write a trade with NULL strategy again. Backfill where derivable.
4. FIX the engine_scores trade_id stamp so scores join to outcomes (currently 0/6,980/7d). This is the join that makes the entire eval layer functional.
5. FIX the autotune readback — make getActiveProfile() query applied calibration profiles (keep behind SAFE_AUTO_APPLY/Karri gate). Turn the write-only motor into a loop.
6. PATH-AWARE shadow/forward resolver — replace single-spot fill with first-touch on a single, timeframe-filtered candle stream; add exit-side spread. Removes the win-inflation and the 1min/15min mixing leak.
7. ADD walk-forward / OOS split to the backtest runner + a candle-freshness/coverage guard that errors on stale or partial windows.
8. STAND UP one real producer for the loop's second half — derive structured testable hypotheses (not free-text lessons) and actually call change-verification after a param change. Make strategy_versions mint a v2.
9. TRAIN the first meta-label model ONLY after #1-#3 land (clean, attributed, cost-aware labels) using the existing purged-CV machinery. Gate by Karri.
10. DASHBOARD honesty pass — every tile backed by an empty/placeholder table (hypotheses, change_verifications, regime_fit, shadow P&L) must show "no data / not validated" instead of a green number.


## BYGG FØRST (denne uka)
This week, in order, do NOT touch strategy logic (Karri-gated) — fix the truth layer so every later decision rests on real numbers:

1. (Day 1, SQL only) Quarantine the 18 corrupt-stop rows: set excluded_from_learning=1 and null/recompute their result_r. Add a hard guard in postmortem-r-multiple so any abs(entry-stop) below a sane floor is flagged at write-time. This single fix removes the fake +$9k from every aggregate.
2. (Day 1-2) Make trades cost-aware and attributable: populate spread_at_entry on the live OANDA-sync path (reuse paper-execution.service model), add commission/financing columns, and enforce non-NULL strategy + execution_source on every new write. No new trade should be unattributable.
3. (Day 2-3) Fix the eval join: get the engine_scores trade_id stamp actually writing in prod (currently 0/6,980/7d). Without this nothing downstream can correlate score to outcome.
4. (Day 3-4) Dashboard honesty pass: replace any tile reading empty/placeholder tables (hypotheses, change_verifications, regime_fit=1.00, shadow P&L) with explicit "no data / not validated" states so no green number lies.

Defer to next week / Karri: autotune readback re-wire, walk-forward backtest, first meta-label model, hypothesis producer. They are higher-effort and worthless until the data is clean, cost-aware, and attributed. Rationale: items 1-4 are nearly all observability/data fixes (allowed under operator max-mode), unblock everything else, and stop the system from lying to you — which is the precondition for any trustworthy decision.


## MEST FARLIG
FAKE PROFITABILITY + POISONED LEARNING INPUT (single most dangerous): The headline "profit" is entirely an artifact of 18 corrupt-stop rows (abs(entry-stop)<0.5pt) that book +$9,238 at 14W/2L with ~$0 losses (DB-verified) — strip them and the firm is deeply negative (valid stops -$18,797, PF 0.47; honest firm_strategy path -$263 BEFORE unmodeled spread/commission). It is most dangerous because (a) it could falsely justify a live-capital flip, and (b) those 18 rows carry excluded_from_learning=0 and astronomical result_r values (up to ~297R), so they will train any future meta-label model and seed any hypothesis/strategy-version on fabricated R-multiples. A green dashboard number here is not evidence of edge — it is the artifact. Fix this (quarantine + cost modeling) before trusting ANY profitability figure or training ANYTHING.

---

## THESIS-1 RESEARCH (cited best practices) — landed 2026-06-23

TWO CORRECTIONS to ai-1's audit framing (accuracy):
1. The ORB backtest DOES model a fixed $0.3/side spread (runner.ts:67, applied at fill runner.ts:303) — NOT zero-cost. Real gap = no slippage, no commission/financing, no variable/news spread. (backtest.ts:287 admits "No slippage modeled".)
2. The meta-label module is BUILT + tested (triple-barrier/scorer/features/backfill + 686 lines tests, apps/worker/src/firm/meta-label/), gated OFF (META_LABEL_SHADOW_ENABLED default false). Tables empty because nothing populates them, not because code is missing → turning on labeler+shadow is a flag-flip, not a build.

CITED FINDINGS (full sources in the agent transcript):
- Walk-forward (Pardo 1992): rolling train→OOS, report concatenated OOS only. WARNING: meaningless at ~40 trades/OOS-window — WFO exposes small-sample, doesn't fix it. ~2 trades/day is THE binding constraint.
- Leakage prevention: every feature at t uses only data ≤ t (closed bars); fit scalers on train only; macro = point-in-time first-print (not revised series — highest gold-leakage risk).
- Purged K-fold + embargo (López de Prado AFML ch.7): mandatory IF k-folding the meta-model (labels span entry→barrier). Tie embargo to the 24h vertical-barrier horizon.
- Triple-barrier + meta-labeling (AFML ch.3): primary=direction, secondary=take/skip on triple-barrier outcomes. WARNING: needs hundreds of trades; cannot rescue a negative-expectancy primary (← Nexus's primary IS negative, so meta-label won't save it).
- Regime detection: HMM/Markov-switching as a GATE not a predictor; use FILTERED (online) state not smoothed (smoothed = leakage). A relative/quantile regime label fixes the documented raw-$ threshold-drift bug ($2000→$4200).
- Gold drivers: real yields (strongest, inverse) > DXY (inverse but weakening per Chicago Fed/CME) > inflation-expectations > Fed/FOMC > safe-haven. Feature as point-in-time CHANGES/surprises, daily-bias gate not per-trade (slow signals vs intraday ORB).
- Metrics that matter for Nexus (order): expectancy/R per trade > profit factor > maxDD/MAR > Sortino > tail. Sharpe is most-quoted, least-reliable at this sample size; pair every ratio with N + CI.
- Overfitting: Deflated Sharpe Ratio (Bailey/LdP — deflate by trial count N + skew/kurt/T) + PBO via CSCV (prob of backtest overfit; discard if >0.5). Nexus re-implements ORB repeatedly → real N is high → raw metrics almost certainly inflated. MUST count trials.
- Experiment registry: append-only experiment_runs table (run_id, git_sha, params, train/OOS window, cost assumptions, full metric panel, OOS equity, trial_group) wired INTO runner.ts so N is measured not guessed. None exists today.
- Safe autonomous agents (Knight Capital $440M/45min → SEC 15c3-5): deterministic hard caps (max daily loss/exposure/order-rate/size) that bypass agent reasoning entirely; kill switch at BROKER boundary not just a flag; no auto-disable (report, operator decides — already Nexus prinsipp 1). WARNING: multi-agent feedback loops are the autonomous-firm failure mode — bound each agent's authority.

PRIORITIZED ADOPTION (leverage-per-effort): 1) cost-model completeness in backtest (slippage+commission+variable-spread; many edges die here), 2) experiment_runs registry + trial-counting (unblocks deflated metrics), 3) walk-forward harness (biggest gap — no OOS today), 4) Deflated Sharpe + PBO, 5) turn on meta-label labeler+shadow (flag-flip, accumulates training set), 6) relative/HMM regime label in shadow (fixes threshold-drift), 7) point-in-time gold macro features (later, higher leakage risk). Purged-CV only matters once training on real volume (months out, given trade count).

UNVERIFIED: exact ORB trial count N (no registry); whether kill switch is truly broker-level (flagged, not traced); macro-coefficient magnitudes (directional high-confidence, magnitudes period-dependent).


---

## DATA PIPELINE + MACRO/NEWS (re-run) — landed 2026-06-23
VERDICT: NOT research-grade. Price-only foundation (15m OANDA candles fresh + technicals healthy), but EVERY gold-driver input is DEAD or STALE.
- Economic calendar: **0 future events** (latest 2026-06-05) → all news/event gates blind. Finnhub/ForexFactory sync not running.
- Cross-asset (DXY/yields/silver confirm): FROZEN since 2026-04-25 (58 days) — cross_asset_snapshots + narrative_clusters stopped on identical timestamp → MARKET_PULSE_ENABLED likely false or throwing (swallowed .catch). Kills ALL DXY/yield confirmation.
- FRED macro: real-yield (DGS10-T10YIE) computed in fred.service.ts:155 but NEVER persisted (in-memory only); macro_direction 100% "neutral" (decorative). Gold's #1 driver does not influence anything.
- NO data-validation layer: no stale/gap/bad-tick detection; 0 dup (PK works) but 5 unflagged >30min gaps in 7 days; a frozen feed raises no alarm.
- Only 15min candles persisted live: persistCandles hardcodes tf="15min" (raw-data-persistence.ts:474); multi-TF (1h/4h/daily) defined but never wired; 1min frozen 10 days.
- Reddit broken 14 days (unauth endpoint blocked); sentiment uses CRYPTO Fear&Greed (alternative.me) as gold proxy (wrong instrument).
- HEALTHY: OANDA 15m candles (16min stale), TwelveData indicators (44s), news_headlines (3min).
RECS: (1) fix calendar cron + backfill 30d forward; (2) find why market-pulse froze 2026-04-25 (check MARKET_PULSE_ENABLED, un-swallow the .catch); (3) persist FRED real-yield to a table; (4) data-freshness/gap monitor (REPORT-only); (5) wire multi-TF candle persistence; (6) repair Reddit + swap crypto-F&G for GVZ/VIX.
