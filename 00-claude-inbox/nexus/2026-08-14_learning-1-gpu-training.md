# learning-1 — GPU-trening + live prediksjon levert (2026-08-14, MERGET 17.08)

**Status 17.08: PR #281 MERGET til main (grønn CI) etter operatør «OK kjør».** Review-runde (10 funn) fikset før commit — viktigst: scale_pos_weight fjernet (dekalibrerte sannsynlighetene), path-traversal-validering i modulene, `mlmgpu_`-rader ekskludert fra strategy-lab/health-flatene så GPU-lanen ikke maskerer en død in-cycle-scorer, `meta_label_gpu_models` registrert i schema.ts, env-vars registrert i alle tre registre. E2E re-kjørt etter fiks: brierSkill −0.17 (bedre kalibrert, fortsatt ærlig no-signal ved n=129).

Opprinnelig leveranse-notat (14.08):

Svar på infra-1s dispatch 10.08 (operatør-ordre): meta-label-trening flyttet til boksen (CUDA-xgboost), kadens økbar via env, live prediksjon servert via modul. Alt REPORT-ONLY og flag-gated OFF.

## Levert

**På boksen (deployet + E2E-verifisert i dag):**
- `/opt/analytics/modules/meta_label_train.py` — tar {rows, feature_keys}, purged time-ordered CV (k=5, embargo 2 %), CUDA-xgboost m/ cpu-fallback, artefakt til `/opt/data/artifacts/meta_label/<versjon>/` (model.ubj + meta.json) + atomisk `latest.json`-peker. Guards speiler TS-treneren (min 30 rader, degenerate-labels).
- `/opt/analytics/modules/meta_label_predict.py` — laster siste (eller pinnet) artefakt, batch-prediksjon, p_win [0,1].
- Kanonisk kildekode i repo: `scripts/gpu/modules/` (worktree-branch, ucommittet til push-OK).

**I worker (branch fra origin/main i worktree, tsc rent, 2078/2078 tester grønne):**
- `gpu-train.ts` — datasett via SAMME `labeledFeatureProjectionSql()` som TS-treneren (inkl. quarantine-filter, null skew), POST til boksen, modell-rad i NY tabell `meta_label_gpu_models` (egen tabell fordi scorer.ts strukturvaliderer logistisk shape på siste `meta_label_models`-rad — en xgboost-rad der ville stille drept dagens shadow-scorer). Fingerprint-skip når datasettet er uendret.
- `gpu-score.ts` — batch-rescoring av siste døgns shadow-kandidater (features ligger allerede i `meta_label_scores`) → GPU-p_win-rader side-om-side med logistiske (samme trade_id, `mlmgpu_`-prefiks) = direkte A/B logistisk-vs-xgboost. ALDRI i trading-syklusen (#264 står).
- `gpu-schedule.ts` + wiring i index.ts (times-tick, firm_state last-run, failed-markers).

## E2E på ekte data (i dag, via HTTP-tjenesten på boksen)
- 129 labels (48W/81L) → trening 200 runder CUDA → `mlmgpu_20260814160902`, 5 folds.
- **Ærlig resultat: brierSkill −0.36 = ingen prediktiv edge ved n=129.** Samstemmer med TS-trenerens «no-signal» på alle 15 modeller. Ikke en bug — datamengde/feature-dekning. Importances: nesten alt i atr_norm_stop + conviction_total; adx/rsi/macro_delta er 0 i mesteparten av historikken (snapshot-skriving kom sent → featurene fylles først fremover).
- Predict live: laster artefakt, svarer per trade-id.

## Flagg (operatør flipper — Railway worker)
```
GPU_ANALYTICS_BASE_URL=http://81.166.173.12:11691
GPU_ANALYTICS_TOKEN=<samme bearer som 11602>
META_LABEL_GPU_TRAIN_ENABLED=true          # trening hver 6. time (META_LABEL_GPU_TRAIN_INTERVAL_HOURS)
META_LABEL_GPU_SHADOW_ENABLED=true         # batch-scoring hver time (META_LABEL_GPU_SCORE_INTERVAL_MINUTES)
```
Rollback 30 sek: unset flaggene (dobbelt-gated på base-URL også).

## VERIFY-BY 01.08-verifiseringen (levert i samme økt, read-only)
- META_LABEL-wiring: VERIFISERT live (labeler 156 labels, nattlig trener, 468 scores/24t). MEN trener-hull 23.07→13.08 (flagg/deploy-vindu — verd å sjekke Railway-historikk).
- SAFE_AUTO_APPLY: **0 applied-rader siden 26.06.** Sample-gaten (tradeSamples<30) holder alt, og vinduet FALLER (29→19, matcher doctor-funnet). Re-armen 23.07 har aldri fått virke. Beslutning om gate-terskel er operatør/Karri-domene — jeg bare rapporterer.
- Oneshot-SQL-korreksjon: `normalize-thesis-quality-score.sql` er IKKE trener-blokkerende (thesis_quality_score er ikke en trener-feature; gjelder scorer-fallback via convictionTotal + firm_memory-overflow). Fortsatt verdt å kjøre, men haster mindre enn antatt.

— learning-1
