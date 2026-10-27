# Lærer systemet? — ukespuls #1 (learning-1)

Dato: 2026-08-19 (uke 12.–19.08 mot 05.–12.08). Kilde: `scripts/ops/learning-pulse.sql` (read-only, deterministisk, ingen LLM-dømming) kjørt mot prod-DB. Metrikksett = onboarding-notatet §4.

## Kortversjon

Loopen er **mekanisk intakt men lærer ikke ennå**, og ett ledd var halvdødt: CPU-treneren har kjørt **5 av 30 dager**. Årsak funnet og fikset (branch `fix/meta-label-trainer-cadence`, 4b8b444, 2401/2401 grønt, venter OK kjør). Ingen læringsjustering har rørt en trade i perioden (calib_applied = 0, lessons_new = 0, GPU-flaggene ikke flippet).

## Tall

| metrikk | denne uka | forrige uke | lesning |
|---|---|---|---|
| closed_trades | 8 | 4 | lavt volum, 8/uke |
| closed_firm_attributed | 8 | 4 | 100 % attribusjon |
| result_r_null_pct | 0 | 0 | holdt (var 66 % i juni) |
| calibration_mode_stamped_pct | 100 | 100 | #254-provenance holder |
| sum_r / wins | −3.01 / 2 | +5.61 / 4 | uke i minus |
| labels_total / new | 160 / 8 | – / 37 | 37 forrige uke var backfill, 8 = reell tilførsel |
| labels_win_pct | 43 | | |
| **trainer_runs_30d** | **5** | | **kadens-bug, fikset** |
| trainer_last_model | mlm_20260818 n=131 brierSkill −0.281 | | no-signal, forverret fra −0.06 (juli) via −0.17 (13.08) |
| gpu_models_total / gpu_shadow_scores | 0 / 0 | | flaggene ikke flippet ennå |
| shadow_scores (CPU) | 2140 | 2020 | scorer går jevnt |
| hypotheses / change_verifications | 0 / 0 | | begivenheten har ikke skjedd |
| agent_lessons total / new | 17 / 0 | – / 0 | siste 23.07 |
| calib_applied / recommendations | 0 / 924 | 0 / 990 | SAFE_AUTO_APPLY: sample-gate holder fortsatt alt |
| shadow_signals / resolved | 51 / 100 % | 5 / 100 % | hopp = #316/#317 path-aware re-resolve |
| engine_scores trade-join | 1 % | 0 % | nesten ingen kobling, som før |
| hle_events / last_import | 255 351 / 13.07 | | manuell kadens by design (trading-1) |

## Funn 1: trener-kadens (fikset)

`trainer-schedule.ts` var "due" bare når den timevise worker-ticken traff 05:30–05:59 UTC. Tick-fasen settes av boot-tidspunkt, så etter en deploy med fase i første halvtime kjørte treneren aldri. Bevis: `firm_state` har `meta_label:train:` 21–23.07, 13.08, 18.08 (5/30), mens eval-refresh (heltime-vindu) har 30/30. Fix: vinduet er nå 05:00–06:59 (to hele timer, så enhver fase treffer), per-dag-idempotens via eksisterende firm_state-nøkkel. Regresjonstest: alle 60 minutt-faser er due minst én gang per døgn. Labeler er timevis, så ":30 etter labeler"-premisset var dødt.

## Funn 2: brierSkill forverres med flere labels

−0.06 (n=128) → −0.17 (n=125) → −0.28 (n=131). Modellen er dårligere enn base-rate og blir det mer. Med 8 nye labels/uke og 43 % WR er det forventet støy, ikke et signal om at noe er galt i trener-koden, men det betyr at det ikke finnes en shadow-modell verdt å flippe. GPU-xgboost-A/B (PR #281, flag-gated) er eneste vei til å teste om det er modellklassen eller datamengden.

## Funn 3: loopen produserer ingen endringer

hypotheses = 0, change_verifications = 0, lessons_new = 0, calib_applied = 0. Dette er konsistent med at sample-gaten holder alt og at trade_forensics→lessons-koblingen (trading-1) ikke er merget. Ikke en feil, men "lærer systemet?" = nei, ikke målbart ennå.

## Neste

- OK kjør → push `fix/meta-label-trainer-cadence` + PR. Verifiser 21.08: `meta_label:train:2026-08-20` og `:2026-08-21` finnes.
- Operatør-flip (Railway worker) for GPU-A/B: GPU_ANALYTICS_BASE_URL, GPU_ANALYTICS_TOKEN, META_LABEL_GPU_TRAIN_ENABLED, META_LABEL_GPU_SHADOW_ENABLED. Report-only.
- Puls #2 neste uke: samme SQL. Tillegg når trading-1s forensics lander: forensics-verdikt per uke.
