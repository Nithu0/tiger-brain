# Full analyse 2026-07-07 — GPU-effekt, læring, kadens, data, løse tråder

Read-only sweep (6 parallelle analytikere, 760k tokens, prod-DB + kode + docs). INGEN endringer gjort. ai-1.

## 1. GPU-sammenligningen — ærlig svar

- GPU serverer KUN Command Room-Chief (siden 25.06, #212–#218) + dark HLE deep-answer. **PR #211 (firm-agents → GPU) er aldri merget** — nå CONFLICTING, 22 commits bak main, CI 11 dager stale. Ingen trading- eller læringsbeslutning har noensinne kjørt på GPU.
- Det som faktisk ble bedre: Chief-latens ~9s→2–4s og null marginalkost på samtaler. Det er hele GPU-effekten.
- Trading etter GPU-datoen: uke 22.06 −$12,50 · uke 29.06 −$1 249,81 · uke 06.07 +$320 → **−$942 på 3 uker**. Ingen målbar trading-forbedring, og en evt. endring kunne uansett ikke vært GPU-kausal.

## 2. Vinner den penger? Netto nei

- 108 rene live-trades (UUID, ikke-kvarantenerte) 23.04→07.07: sum(pnl) = −$3 411,79, MEN sum(realized_partial_pnl) = +$2 650,69 → **ekte netto ≈ −$761**. 35,2 % vinnere.
- Gotcha: raw `pnl`-kolonnen overdriver tap 4,5× (partials bokføres separat, commission=0). Alt som summerer `pnl` alene lyver. Og `excluded_from_learning` er NULL på live-rader — `NOT excluded_from_learning` filtrerer bort ALT; må bruke `IS NOT TRUE`.

## 3. Læringen — 2 ekte bugs + 1 regresjon; resten er sample-matte + bevisste flagg

**BRUKKET:**
- **Postmortems døde siden ~29.06**: 15 closes siden 28.06, alle stemplet `postmortem_run_at`, kun 1 postmortem-rad. Catch-en i `apps/worker/src/firm/postmortem-hook.ts:265-285` logger kun til Railway og stempler run_at uansett → aldri retry. Starver lesson-derivation, kalibrering, analytics — og loss-clusters-endepunktet i PR #224. Root cause: grep Railway-logg for `[firm.postmortem-hook] Postmortem FAILED`. Timing sammenfaller med 04d10b8 (26.06) + DB-ustabilitet 30.06.
- **HLE-import frosset 30.06** (alle `hle:import:*`-cursore ~07:30–09:50 UTC). Fiksen er `feat/hle-import-resilience` (2856344) — pushet, **ingen PR**.
- **Meta-label train-cron stille siden 30.06** (siste modell mlm_20260630053655).
- Trolig felles årsak for alle tre: DB-droppene 30.06 som resilience-branchen adresserer.

**REGRESJON:** fdbdaa4 (15.06) la `entry_hour_utc` i lesson-cluster GROUP BY (`scripts/firehose/derive-lessons.mjs:112,125`). Ved ~1 trade/dag når største bucket n=3 mot MIN_SAMPLE=5 → **0 lessons siden 18.06, strukturelt, ikke transient**. Auto-promote (n≥20) matematisk uoppnåelig. `hypotheses`-tabellen har 0 rader noensinne (insert-feil svelges).

**DARK (bevisst / Karri-gated):** LESSON_INJECTION (og vakuøs — 0 approved lessons finnes), TIER3_ENGINE_ATTRIBUTION (PR #222-skrivingen har 0 rader), HLE_CF/PROFILE/EVAL (tabeller tomme), kalibrering: **auto-apply reverterte til RECOMMEND_ONLY 27.06** — 374 applied-rader 08–26.06, deretter 0. Doc-vs-reality (feature-flags.md:152) — Karri-samtale.

**LIVE og friskt:** derive-lessons daglig cron, meta-label capture (3 456 scores siden 24.06), engine_scores (15 354 siden 25.06), thesis_quality_score 71 % populert.

## 4. Hvor ligger hun i prosessen — MinTRL-svaret

- 115 labels, vekst ~11–12/uke. **MinTRL er UENDELIG ved Sharpe ≤ 0** — venting beviser aldri en edge som ikke finnes. 30d WR 43 %.
- 4 meta-label-modeller ER trent (train-model.ts er ingen scaffold — full logistic+Platt+purged-CV, kjørte daglig). Alle: verdict **no-signal**, negativ Brier skill (−0,073 til −0,176, dvs. dårligere enn base-rate). Ingenting mekanisk blokkerer trening; dataene inneholder ikke lærbart signal ved n≈96.
- Konklusjon: ikke «flere trades», men «flere lønnsomme trades» — og sløyfa som skulle forbedre lønnsomheten er delvis brukket (pkt. 3).

## 5. Kadens — følelsen var reell, men historisk

- Uke 08.06: **0 av 80 forslag fyrt** — risk_level (26 hard-rejects) + mean_revert (51/88) var PÅ i prod mens docs sa av. Ukentlige fired: 1, 3, 0, 4 → 11, 11–12 etter mid-juni-retune + flip-all 24.06. Kadens er alt tredoblet.
- Cycle-motoren frisk: heartbeat cycleNo 3538, 4,3s/cycle, ingen f551c17-klasse skipping.
- Konfigurert tak ~30/uke (cross-cap 6/dag aldri bindende); gapet til 11–12 er risikodesign (loss-streak 4t-pause ~30 blokker, maxOpenPositions=1 → 37 blokker) **pluss en ekte bug-skatt: ~11 tapte trades/6 uker (~25 % lekkasje)** — sizing-motoren produserer størrelser dens egen circuit-breaker avviser (maxUnits=80/300 % notional, `strategy-execution.ts:177`) + 8 OANDA-rejects.
- Raw-$-drift-klassen består i dormante terskler: ORB_RANGE 3–10 USD (død v/ ATR $7,14), DAILY_LOSS_CAP_USD, FVG_MIN_GAP 1,5, REGIME_DIRECTION 1,5 — ingen skalerer med pris/vol/equity.

## 6. Data — ett farlig hull, mye dødvekt, konkrete kutt

- **FARLIG: economic_events stale siden 17.05** → event-BLACKOUT-gaten regner CLEAR gjennom FOMC/CPI/NFP og tillater full size i event-vinduer (`event-calendar-freshness.ts`). Fix = gratis Finnhub-nøkkel eller wire forex-factory-service. Freshness-alerten er også OFF.
- **Reddit-ingest stille død siden 09.06** — narrative-analysten (analysis-agents.ts:344) mistet input uten alarm; begge reddit-tabellene er dessuten write-only.
- Skriv-og-aldri-les / død: backtest_xauusd_m1 (31 MB, 0 kode-refs), macro_series, news_events (0 rader), cross_asset_snapshots (writer OFF siden april — DXY/yields/sølv mangler i 10 uker data), news_headlines (leses kun av OFF-agent).
- DB 1 109 MB, **~480 MB bloat** (sentiment_snapshots: 323 MB disk / 2,5 MB data). Retention sletter rader korrekt men reclaimer ikke disk (VACUUM FULL = operator-gated). Neste ubegrensede voksere: shadow_forward_test + engine_scores (ingen retention).
- **Kutt uten prediksjonstap:** Notion, BetterStack Logtail, Telegram, OpenRouter; Twelve Data tier-nedgradering (unik verdi = 8 indikatorer). NB: data-sources.md-anbefalingen «slett FRED» er STALE — fact-agents bruker den hver cycle.
- Ingen kost-meter (logLlm mangler tokens/kost). Største GPU-flytt etter #211: **sentiment-narrative ~500 Sonnet-kall/dag** (analysis-agents.ts:347, est. $2–4/dag), + postmortem/trade-review/briefing. Embeddings kan ikke flyttes (Qdrant dim 1536 vs bge-m3 1024).
- Manglende data som ville hjulpet: news_events-populering, cross-asset-reaktivering, order-book-dybde fra OANDA v20 (spread_at_entry er nå 30/30 populert — bra).

## 7. Backtest/prediksjon — verktøyet finnes, kjøres ikke

- HLE: import/link/label kjørt én gang; **CF/profiler/eval ALDRI kjørt i prod** (hle_notrade_labels=0, hle_strategy_profiles=0, hle_eval_runs=0). shadow_forward_test-import 16 559 av 74 915 rader (kun 7.–12. juni).
- **185R + 23,8R gift-labels fortsatt label=1** i hle_label_assignments — oneshot-SQL fra 30.06 aldri kjørt, og den treffer bare 185R-raden. De 9 vinner-labelene snitter r=24,3 pga. to artefakter; alt regnet på rå labels er dominert av dem.
- Backtest i dag: ekte M1-replay-harness for **3 av strategiene** (ORB, MR filter 1–4, vol-exp) — som re-implementasjoner. Session-breakout/scalps/FVG/VPA kan ikke replayes. Sist brukt 14.06.
- Prisdata rikelig: 174k M1 (des→12.06, backfill u-kjørt siden) + 175k M1 bid/ask (nov→13.05) + 15min løpende. Knappheten er merkede BESLUTNINGER, ikke pris.
- Akselerator som alt er bygget: counterfactual-labeler over 75k-raders shadow-korpus (S–M å kjøre).

## 8. Løse tråder

- **10 åpne PRs (ikke 2): 7 CONFLICTING** (#28, #50, #52, #60, #78, #85, #211 — eldste 55 dager). Rene: #224 (klar, kun OK kjør-gate), #53, #104.
- **Orphan-fix:** 626ab29 (ADX/ATR-null, STRATEGY_STATES_ADX_FROM_H1) 29 dager på PR-løs branch; testen ligger untracked i main-checkout og står ikke i api/package.json-testlista.
- feat/hle-import-resilience: pushet, ingen PR.
- **phase-status.md 47 dager stale** (CLAUDE.md kaller den single source of truth; rapporterer fortsatt «4 dormante agenter» — alle 10 er live per firm_state i dag). known-failures 32 dager; project_state.md 18 dager.
- **Karri-kø: ~25 uavklarte proposals** (eldste 60 dager), 5 approved-men-aldri-aktivert, **5 proposals kun som untracked filer** (reset-hazard i delt checkout).
- Untracked-rot: manusscript.pdf duplisert i rot + .github/ (hører hjemme i thesis-repo), screenshots, Zone.Identifier-filer, .playwright-mcp/ 6,8 MB — ingen .gitignore-regler.

## Prioritert kart (ingenting utført)

**P0 — stopper blødning i lærings-/sikkerhetsdata:**
1. Postmortem-failure root cause (Railway-grep) + retry-mekanikk
2. economic_events-refresh (gratis Finnhub) — BLACKOUT-gaten er blind nå
3. PR + merge feat/hle-import-resilience → kjør import-catchup (fikser trolig også train-cron/30.06-klyngen)
4. Utvid + kjør 185R-oneshot (begge rader, operator-gated SQL)

**P1 — læring + utførelse:**
5. De-fragmenter lesson-clustering (fjern entry_hour fra GROUP BY el. senk MIN_SAMPLE — proposal til Karri, endrer lesson-innhold)
6. Sizing vs circuit-breaker-mismatch (~25 % lekkasje)
7. Reddit-ingest: restart eller formell avvikling; freshness-alert PÅ
8. PR for ADX/ATR-fixen + test inn i testlista
9. Rebase #211 + fresh CI (så GPU-flytten av agenter blir beslutbar)

**P2 — plattform-soliditet:**
10. PR-kø: rebase-or-close de 7 konfliktende
11. Doc-refresh: phase-status.md, known-failures, data-sources (FRED), commit de 5 untracked proposalene
12. Kost: si opp Notion/Logtail/Telegram/OpenRouter, Twelve Data-nedgradering, kost-meter, sentiment-narrative → GPU
13. VACUUM FULL (~480 MB) + retention på shadow_forward_test/engine_scores

— ai-1, workflow wf_05249d22-0f9 (perf-agenten feilet på API; kjernetall verifisert manuelt)
