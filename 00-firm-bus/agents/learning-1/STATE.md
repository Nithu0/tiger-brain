# learning-1 — STATE

_Peker: autoritativ prosjektstatus = `<repo>/project_state.md` (PATH-MAP.md) — NB: den er ~6 uker stale per 28.07; `CURRENT-STATE.md` (maskin-generert) er ferskest._

Oppdatert: 2026-08-17. **PR #281 merget:** GPU-meta-label-trening (CUDA-xgboost på boksen) + batch-shadow-scoring, flag-gated OFF — flip-liste i `00-claude-inbox/nexus/2026-08-14_learning-1-gpu-training.md`. Loop-midten IKKE lenger tom: 156 labels, 15 modeller (alle no-signal), 14,5k scores. SAFE_AUTO_APPLY: 0 applied siden 26.06 (sample-gate). Onboarding-analyse: `2026-07-28_learning-1-onboarding.md`

## Statuskart (kort)

- **Checkout:** ai-assistent står på merget branch `feat/hle-import-resilience`, **114 commits bak origin/main**. Nyeste læringsfikser (HLE label v2, P2.8, #254 provenance) kun på main. Arbeid gjøres i worktree mot main.
- **Læringsloop:** capture LIVE, labeler SHADOW-LIVE (93 labels), men loopens midte er TOM: hypotheses=0, meta_label_models=0, meta_label_scores=0, change_verifications=0. Flaskehals = derive→hypoteser, ikke gaten.
- **Kalibrering:** SAFE_AUTO_APPLY re-armet 23.07 per operatør; META_LABEL-wiring UVERIFISERT (VERIFY-BY 01.08). feature-flags.md sier fortsatt OFF → doc-drift.
- **HLE:** P2.0–P2.8 merget, flag-OFF by design; ~82 settled labels → MinTRL INSUFFICIENT (ærlig data-sult).
- **GPU-måling:** llm-metering finnes (api+worker+3 lokale agenter), men chief/pengeagenter/embeddings/feil-fallbacks er umetret; lokal kost=0; ingen lese-flate. F3-målepunktliste levert i onboarding-notatet §3.
- **Venter på operatør:** 2 oneshot-SQL (185R-outlier-flagg; thesis-score-normalisering — MÅ før neste meta-label-trening), branch/worktree-GC.
