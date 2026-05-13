# C4 addendum audit — postmortem-risk-consumer reframe

**Date:** 2026-05-13 PM
**Proposal:** `docs/strategy/proposals/2026-05-13_postmortem_risk_feedback.md`
**Trigger:** Round-5 forensics (`round5/postmortem_tag_audit.md`) viste at C4's original framing var partisk.

## Hva ble endret

Appended `## Round 5 addendum (2026-05-13 PM)` til bunnen av C4-fila. Original innhold uendret — kode-skisse, env-flags, T/W/M-defaults, A/B/C-vindu, rollback-path står. Tilføyelse, ikke revisjon.

## Hovedendringer i addendum

1. **Framing correction**: "Dormant consumer"-formuleringen var halvveis feil. `classification` leses allerede av tre LLM-advisory agenter (`trade-critic`, `strategy-tuner`, `daily-journal`). Reell gap: programmatisk handling (gates, risk-sizing) leser ZERO postmortem-state. C4 reframet som "promote signal fra advisory-LLM til programmatic gate" istedenfor "bygg første konsument".

2. **Empirical concern**: 90.3% av merkede tapere er RTBE (28/31). 27/27 sammenhengende RTBE-streak 04.5-12.5. 3/6 enum-verdier aldri emittet (`BAD_TIMING`, `BAD_INVALIDATION`, `NO_TRADE`). Klassifikatoren kan over-route — en feedback-loop som tunes mot RTBE vil arve bias-en.

3. **Sequencing change**: Lagt til to precursors før eksisterende 14d-shadow-plan.
   - Phase 0: Karri hand-labels 10 RTBE-PMs (sanity check, classifier-accuracy ≥ 70% gate).
   - Phase 1: Wire `RIGHT_THESIS_BAD_TIMING`-emitter for å splitte monokulturen.
   - Phase 2: Eksisterende 14d shadow.
   - Phase 3: Active.

4. **Status update**: `proposed` → `needs-precursor-sanity-check — see addendum`.

5. **Tre nye open questions for Karri** addet: hand-label sanity check, BAD_TIMING-prioritet, coverage-gap backfill (63 unlabeled tapere 15-29.4).

## Hva ble IKKE endret

T/W/M-defaults, A/B/C window-options, env-stige, rollback-path, kode-skisse. Forslaget står — det er evidens-kravet før Phase 2/3 som strammes.

## Commit-status

Ikke committed per instruks. Endring sitter på arbeidstreet.
