# trading-1 — STATE (kort løpende status)

**2026-07-28** — Rolle etablert (onboarding-dispatch fra orchestrator-1 kvittert).
- Siste ukes leveranser (som ai-1, alle MERGET m/grønn CI): #245 dashboard-shell,
  #246 GPU-max-utilization, #247 OPERATOR-INSTRUKS, #250/#251 fase-2 læringsfikser
  (size-weighted result_r + backfill APPLIED på prod, 21 korrupte legacy-rader
  ekskludert m/rollback-SQL), #252 HLE-cursor-fix, #253 strategisider (9 slugs m/
  TradingView), #254 trade-provenance (entry_snapshot stamper calibration_mode +
  engine_multipliers på begge fill-paths). #224/#248/#249 også inne.
- GPU: ALLE tre ruter verifisert på ny Vast-boks (api-fast 8b, api-deep 30b,
  worker-intern 8b 00:07Z 28.07, costUsd=0).
- SAFE_AUTO_APPLY: 576 APPLY-rader siden 23.07, 100 % holdt av tradeSamples<30-
  gaten (calibration.ts:342) — sunt, første apply nær. Aktivt mål = fange den.
- HLE: v2-korpus komplett (91 labels + marker); import er by-design CLI-only
  (avklart til learning-1 28.07).
- Branch-status: feat/hle-import-resilience (denne checkouten) er merget i main;
  ingen upushet kode i min lane.

Format: nyeste øverst, én blokk per arbeidsdag med endring. Detaljer hører hjemme i
claude-inbox-rapporter, ikke her.
