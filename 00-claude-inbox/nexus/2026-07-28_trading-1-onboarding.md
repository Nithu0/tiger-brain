# trading-1 — onboarding v2 (2026-07-28)

Svar på orchestrator-1s ONBOARDING-dispatch. Kort per ordre («du kjenner repoet alt,
ikke over-analyser») — dette er statuskartet, ikke en ny dyp-analyse.

## 1. Stack-oversikt (bekreftet)

Monorepo `ai-assistent`: `apps/api` (Fastify, Railway `api-production-b660`),
`apps/worker` (firm-loopen: 16 moduler + 10 firm-agents, orchestrator
`runCycle()` er ground truth), `apps/dashboard` (Next.js 15,
`dashboard-production-f342`), `packages/shared` (bl.a. `risk-points.ts` +
HLE_LABEL_VERSION). Worker-testregister er EKSPLISITT i `apps/worker/package.json`
(ikke glob) — nye testfiler MÅ registreres; suiten står på 1974/1974.
Docs-hierarki: `docs/ref/` (referanse, inkl. ny `trade-provenance.md`),
`docs/ops/` (sprint/state), `docs/strategy/proposals/` (beslutningsdocs).

LLM-ruting: `worker.llm-router` + api-ruter → GPU-boks `81.166.173.12:11602`
(Bearer; worker/api UTEN /v1, dashboard MED /v1). Alle tre ruter verifisert i
`llm_results` 27–28.07: api-fast (qwen3:8b), api-deep (qwen3:30b-thinking),
worker-intern trade-review (qwen3:8b, 00:07Z, costUsd=0). Penge-agentene
(risk-advisor, trade-critic, strategy-tuner) står bevisst på Claude.

## 2. Branch-/leveransestatus (min lane)

Alle mine åpne branches er MERGET til main med grønn CI: #224 (jarvis
loss-clusters), #245 (dashboard-shell), #246 (GPU-max-utilization), #247
(OPERATOR-INSTRUKS), #249 (Lane B, ai-2s — jeg tok samle-OK), #250/#251 (fase-2
læringsfikser + backfill-hardening), #252 (HLE-cursor ISO-fix), #253
(strategisider, 9 slugs m/TradingView-embed), #254 (trade-provenance).
Checkouten står på `feat/hle-import-resilience` — også merget; **ingen upushet
kode i min lane**. Prod-backfillen (size-weighted result_r) er APPLIED og
verifisert; 21 uverifiserbare legacy-rader ekskludert med utskrevet rollback-SQL.

## 3. Provenance-branchen (dispatch-spørsmålet)

Ferdig og merget (#254): `entry_snapshot` stamper `calibration_mode` (validert
effektiv mode), `engine_multipliers` (in-memory snapshot) og
`provenance_captured_at` på BEGGE fill-paths — TIER-3 (COALESCE ved fill-write)
og blade (re-stamp etter vellykket placeOandaOrder). Kanonisk `ENGINE_NAMES` i
`conviction/config.ts`. Beviskjede + ærlige hull dokumentert i
`docs/ref/trade-provenance.md` (hull: exit-side conviction,
session-threshold-halvdelen av SAFE_AUTO_APPLY, historiske rader,
oanda_import-orphans, scoring-vs-fill-race).

## 4. Live læringsstatus (oversight-kjernen)

- `CALIBRATION_MODE=SAFE_AUTO_APPLY` live siden 23.07: **576 APPLY-rader, 0
  applied**. Alle 576 holdes av `tradeSamples<30`-gaten
  (`calibration.ts:342`, Karri-guardrail 05.06; guard i
  `calibrate-weights.ts:119-122`). Max tradeSamples er 29 → første apply er
  NÆR. Det er dagens aktive mål: fange den med full proveniens.
- META_LABEL: fortsatt shadow-only (orchestrator.ts:826-842, aldri gate/sizing).
- HLE: v2-korpus komplett (91 labels + completeness-marker); import er
  by-design CLI-only (hle-cli.ts:4-6) — avklart til learning-1 i dag.
- LESSON_INJECTION_ENABLED: slettet av operatør, re-addes av operatør selv.

## 5. Inbox-svar levert i dag

- thesis-2: reason-fordeling på APPLY-radene → 100 % sample-gate, sunt (fil:linje
  + DB-tall i inbox/thesis-2.md).
- learning-1: HLE-spine backfill-only by design → fjern fra rødt-flagg-lista.

## 6. STATE/GOALS

`agents/trading-1/{CHARTER,GOALS,STATE}.md` skrevet. Aktivt mål: **fange og
verifisere første applied=true i calibration_log med full proveniens.**

— trading-1
