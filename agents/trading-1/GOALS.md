# trading-1 — GOALS

## Aktivt mål (ETT om gangen, jf. FIRM-OPERATING-MODE)

**2026-08-22 natt — LEVERT:** per-trade tekstsammendrag (PR #323, 577e14b): `summary_text` +
`GET /trade-forensics/summaries` keyset-cursor; data-1 har kontrakten (inbox 22.08).
Prod: kolonne på plass, 296/296 klassifisert, backfill ≤100/pass starter neste
forensics-pass (bakgrunnsvakt armert). #284 (size-fallback, bundet) og #266
(macro-thresholds, flagg OFF) reviewet + merget. Neste aktive mål velges ved
neste sesjonsstart — kandidater: forensics-anbefaling #5–11 er operatør/Karri-
beslutninger; mitt eget: verifisere at peak_price_true-sweep + forensics-
backfill faktisk fyller (mandag), og `hasOpenedTradeInWindowToday`-labelbuggen
(trade-beslutning → egen PR kun på operatør-OK).

**Kø-korreksjon 21.08:** «første applied=true»-målet er UTDATERT — CALIBRATION_MODE=
RECOMMEND_ONLY er bevisst operatørbeslutning siden 27.06 (thesis-2 evidensgrunnlag;
APPLY-wiren var ødelagt). calibration_log: 0 applied siden 26.06, APPLY-mode-rader
sluttet 18.08 11:18, kun RECOMMEND_ONLY nå. P1-bugfiksene (engineBlindOpen rot-
årsak i strategy-execution.ts:1161 + P&L-objektiv 04d10b8) er landet.

## Levert (forensics-ordren 14.08 → ferdig 21.08)

PR #318 pitstop-crew, #319 live-chart + agent-feed, #320 GPU-paneler, #321 llm-retry,
#322 forensics report-only-fikser #1–4 (+ 4 backfill-SQL-er kjørt mot prod m/ backup)
— alle på main. Railway Dashboard: GPU_LLM_TOKEN (ref) + GPU_ANALYTICS_URL satt av
trading-1 (operatør-autorisert CLI-bruk 21.08); GPU-paneler live i prod.
Rapport: `00-claude-inbox/nexus/2026-08-14_trade-forensics-fullanalyse.md`.

## Parkert (krever operatørflipp av CALIBRATION_MODE — ikke mitt kall)

Fange og verifisere første `applied=true` i calibration_log med full proveniens —
overgangen fra «læringen påvirket null trades» til levende autotune. Status 28.07:
576 APPLY-rader siden 23.07, alle holdt av tradeSamples<30-gaten (max 29 → nær);
provenance-stamping (PR #254) ligger klar i begge fill-paths.

## Kø (neste, i rekkefølge)

1. LESSON_INJECTION_ENABLED-oversight når operatør re-adder flagget (R er nå ren)
2. Beslutning: skal HLE-import skeduleres løpende, eller forbli manuell backfill?
   (i dag by design CLI-only — svar levert learning-1 28.07)
3. Provenance-hullene fra docs/ref/trade-provenance.md (exit-side conviction,
   session-threshold-halvdelen av SAFE_AUTO_APPLY, historiske rader)
4. Dashboard-eyeball av TradingView-embed + gull-rad-highlight på strategisidene (post-#253)

## Venter på andre

- Operatør: Vast-kreditt ~$6.8 ved $0.364/t (≈18 t runway 21.08 17:30) — påfyll
- data-1/learning-1: RAG-ingest av docs/ref/trade-forensics.md (inbox-ping 21.08)

- Operatør: re-add LESSON_INJECTION_ENABLED (egen annonsert handling)
- infra-1: F3 GPU-ROI-collector (overlapper min llm_results-watch — koordiner)
- Karri: eventuelle egne endringer (collision-watch armert)

Sist oppdatert: 2026-08-22 (trading-1)
