# learning-1 onboarding — full analyse (2026-07-28)

Rolle: learning-1 (tidl. ai-2). Domene: læringsloop, backtest, kalibrering, GPU-nyttelast + måling av om systemet faktisk lærer. Kartlagt med 3 parallelle Explore-agenter (læringsloop-kode, GPU/LLM-målepunkter, repo-state). Ingen endringer gjort, ingen push.

## 1. Repo-state (viktigst først)

- **Checkouten er 114 commits bak `origin/main`.** Står på `feat/hle-import-resilience` (PR #225, MERGET, 0 ahead). Mye av den ferskeste læringsloop-koden (HLE label v2, P2.8 dataset-builder, `fix/learning-signal-fixes`, trade-provenance #254) finnes KUN på main, ikke på disk her. All videre lesing/bygging må skje mot main (worktree — shared-checkout-kollisjonsfaren gjelder).
- `project_state.md` er ~6 uker stale (Book→AI-æraen); `CURRENT-STATE.md` (maskin-generert 28.07) er eneste ferske. `apps/worker/CURRENT-STATE.md` peker på en død branch.
- **Reelt umerget arbeid:** `feat/hle-rmultiple-guard` (1 commit, 185R-guard, kun på origin — aldri merget) + `node-migration-nexus` (25 commits, jun-05, aldri pushet — trenger operatør-beslutning). Resten av ~40 gamle branches er stale/superseded; ~100 worktree-agent-branches + 3 døde /tmp-worktrees er ren GC.
- **2 oneshot-SQL venter bevisst:** `2026-06-30_flag-185r-label-outlier.sql` (ROLLBACK-guardet, operatør-gated) og `2026-07-15_normalize-thesis-quality-score.sql` (skal kjøres FØR neste meta-label-trening — write-steg kommentert ut med vilje).
- Untracked proposals: chain-tp2 (fix landet via #242, dokumentet er stale duplikat), hle-labeler-trailed-stop (relatert labeler-v2 merget i #250), calibration-apply-guard (fortsatt kun proposed), edge-findings (do-NOT-ship-liste fortsatt gjeldende). `2026-06-08_operator-action-brief.md` er delvis SUPERSEDED (anbefaler SAFE_AUTO_APPLY-flip som senere docs fraråder).

## 2. Læringsloop — tilstandskart

Full loop: capture → label → train → eval → hypotese → backtest → versjon → verifisering → apply.

| Stadium | Tilstand |
|---|---|
| Capture (postmortem/result_r, learningFilterSql, forward-test 45k rader) | LIVE |
| Meta-label labeler (trade_labels 93: 11W/82L) | SHADOW-LIVE (prod-flagg PÅ) |
| Meta-label train/eval/shadow-score | DORMANT — `meta_label_models`=0, `meta_label_scores`=0 (data er klar: 93>30) |
| Lessons (agent_lessons 15 rader, auto-promote PÅ) | LIVE men tynn; injection Karri/operatør-gated |
| Hypoteser (`hypotheses`) | **0 rader** — derive-lessons er eneste writer, terskler aldri nådd |
| Hypothesis-gate → backtest → versjon (PR #135) | BYGD men DORMANT + data-sultet (0 hypoteser å konsumere) |
| Backtest-engine | ORB-only, base path only, i TO divergerende kopier (api/runner.ts vs hypothesis-gate/orb-backtest-core.ts) uten ekvivalens-test. 8 av 9 strategier kan ikke backtestes av gaten |
| strategy_versions | reconcile LIVE (9 rader) men `STRATEGY_VERSION_STAMP_ENABLED=false` → `simulated_orders.strategy_version` alltid NULL → "slo v2 v1?" er strukturelt ubesvarbar |
| change_verifications | 0 rader — writer finnes, aldri fyrt |
| Kalibrering | RECOMMEND_ONLY-logging LIVE (calibration_log 2786). **SAFE_AUTO_APPLY re-armet 23.07 per operator (CURRENT-STATE.md) — feature-flags.md sier fortsatt OFF. Doc-drift, prod-env er autoritet.** `getActiveProfile()` er fortsatt stub → kun engine-multipliers beveger seg, ikke terskler |
| HLE P2.0–P2.8 | Alt merget til main, alt flag-OFF/CLI-drevet by design. ~82 settled labels → MinTRL sier INSUFFICIENT (ærlig data-sult, ikke bug) |

**Kjernediagnose: loopens midte er TOM, ikke AV.** Flaskehalsen er stadium 2 (derive→hypotheses gir 0 rader), ikke gaten. Å flippe `HYPOTHESIS_GATE_ENABLED` i dag skanner 0 rader.

**Topp-5 hull:**
1. Loop-midten tom (hypotheses/meta_label_models/meta_label_scores/change_verifications = 0).
2. `engine_scores.trade_id` 98 % NULL → kalibreringens attribusjon (som nå kjører under SAFE_AUTO_APPLY!) hviler på en tynn skive. regime_fit hardkodet 1.0.
3. Kalibrerings-doc-drift ×2 (jun-vinduet urekonsiliert + 23.07-re-arm udokumentert i feature-flags.md). phase-status.md er 2 mnd stale.
4. Backtest-fidelity er en fork uten ekvivalens-test; dekker kun ORB.
5. Versjon→ytelse-lenken kuttet ved stampen (billig, null trade-impact flagg AV); trade_lineage = 0-rads død bro med 2 live lesere.

## 3. GPU/LLM-målepunkter (grunnlag for infra-1s F3-collector)

**Det som finnes:** `packages/shared/src/llm-metering.ts` (på main) — `recordLlmUsage` skriver `usage-meter`-rader til `llm_results.meta` (provider/model/task/latencyMs/costUsd). Initieres i både api og worker. api `routeChat` (8 ruter) + worker `routeLlm` + firm-agents via `meterAgentCall` er dekket.

**Hullene (prioritert for F3):**
1. **Dashboard `/api/chief` = null instrumentering** — høyest-volum GPU-sti (qwen3:8b per turn, 30b-thinking på deep, betalt opus-4-8-fallback). Token-usage kastes i parsing. Trenger meter-endpoint eller egen pg-klient.
2. **Pengeagentene (risk-advisor, trade-critic, strategy-tuner, research-drainer) er umetret** — betalt-spend-nevneren i ROI blir feil-lav. `LLMCallResult` har allerede costUsd/tokens; ingen kaller meterAgentCall.
3. **Kun suksesser metres** — GPU-feil → betalt fallback metres som Anthropic uten attempt/failure/fallback-attribusjon. ROI trenger GPU-forsøkstall + fallback-kost.
4. **Alle 4 embedding-steder (bge-m3) umetret**; .mjs-firehose kan ikke importere TS-meteret.
5. `source:"api.routeChat"` mangler task-felt → 8 ruter uskillelige.
6. **Ingen lese-flate** — ingenting konsumerer usage-meter i dag; ingen index på `llm_results(created_at)`/meta.
7. **Lokal kost hardkodet 0** — ROI trenger Vast $/t amortisert mot volum; ingen plass i schema/env for GPU-rate, ingen GPU-side-metrikk (util, tok/s, uptime).
8. Dobbel-skriving på BullMQ-stien (filtrer på `meta->>'kind'`).

**Steady GPU-last fra firm-agents er bare ~2–8 kall/dag** (daily-journal 1/d, operator-brief 1/d, fill-quality ≤6/d). Reelt GPU-volum er interaktivt (chief) + embeddings — begge umetret. Env-drift: OPERATOR-INSTRUKS.md peker fortsatt på gammel boks 194.14.47.19:22631; ny boks er 81.166.173.12:11602.

## 4. Forslag: "lærer systemet?"-måling (ukentlig feed-rapport)

Deterministisk SQL-basert rapport (ingen LLM-dømming), kandidat-metrikker:
- **result_r-kvalitet:** ikke-NULL-andel på firm-attribuerte closed trades (var 66 % NULL); korrupt-stop-quarantine-telling.
- **Label-dekning:** trade_labels nye/uke + W/L-fordeling; HLE settled labels + MinTRL-avstand (n mot krevd N).
- **Loop-puls:** hypotheses/meta_label_models/meta_label_scores/change_verifications radtelling (0→>0 er selve begivenheten).
- **Kalibrerings-provenance:** andel nye fills med `entry_snapshot.calibration_mode` stemplet (#254) + engine_scores.trade_id join-rate.
- **GPU:** usage-meter-rader per provider/task/uke + fallback-rate (når F3 tetter hullene).

## 5. Anbefalt rekkefølge (learning-1-lanen)

1. **VERIFY-BY 01.08:** verifiser META_LABEL-wiring + SAFE_AUTO_APPLY-effekt i prod (CURRENT-STATE sier "uverifisert"). Read-only DB-sjekk.
2. Kjør/eskaler de 2 ventende oneshot-SQL-ene (operatør-gated; thesis-score-normalisering MÅ før neste trening).
3. Første ukentlige "lærer systemet?"-rapport (SQL over nexus-pg, resultat til feed + Obsidian).
4. Doc-reconcile: feature-flags.md vs prod-env (23.07-flippene), phase-status.md stale-varsel til trading-1/orchestrator-1.
5. Gi infra-1 F3-målepunktlisten (seksjon 3) — den er klar nå.
6. Branch-GC-forslag til operatør (merged/stale branches + døde worktrees) — destruktivt = operatør-gated.

— learning-1, 2026-07-28
