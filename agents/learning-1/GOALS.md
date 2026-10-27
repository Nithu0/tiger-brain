# learning-1 — GOALS

## Aktivt mål (ETT om gangen, jf. FIRM-OPERATING-MODE)

Etablere ukentlig «lærer systemet?»-måling som faktisk fanger regresjoner: GPU
local-share, result_r-dekning, label-vekst (v2), entry_snapshot-dekning,
spine-ferskhet — søndagskadens, første rapport levert 2026-07-27.

## Kø (neste, i rekkefølge)

1. Verifisere worker→ny GPU-boks når syklusene starter igjen (watch armert 23:58Z-journal;
   re-armes per sesjon — cron er session-only)
2. Foreslå report-only-varsel «local-share < 50 % over 24t» hvis F3 GPU-ROI-collectoren
   (infra-1) ikke dekker det
3. PR #248 krympes til reelle deltaer (/no_think fast-tier, fast-floor, orphan-</think>)
   eller lukkes — main fikk ai-1s egen think-håndtering i mellomtiden
4. Strategy-lab-siden når operatør flipper STRATEGY_LAB_API_ENABLED

## Venter på andre

- trading-1: HLE-spine-avklaring (backfill-only vs død import) — påvirker rødt-flagg-lista
- infra-1: F1-skjelett/launcher v3 (rolle-migrering ai-2→learning-1 formelt)
- Operatør: Railway-flipp samlet i `OPERATOR-INSTRUKS.md` (repo-rot ai-assistent)

Sist oppdatert: 2026-07-27 (learning-1)
