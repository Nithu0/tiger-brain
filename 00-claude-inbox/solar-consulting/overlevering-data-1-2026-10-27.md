# Overlevering data-1, 2026-10-27

**Gjort:** hendelseskjede-målingen (25.10) er levert som PR #328 (bare SQL). Dekningen av v4-signalene er målt i prod read-only. PREREG v4 og kode er commitet på `sc-04-prisagent-v4` i Veldora-sc04-krav (ikke pushet ennå).
**Åpent:** kodegjennomgang av v4, push av PREREG-PR, fersk eksport, så én `--v4`-kjøring.
**Neste:** `scripts/eval-pris-spenn.ts <eksport> --v4 --tell`, så `--v4`. Resultatet føres i eval/prisagent/PREREG.md under «Kjøring v4».
**NB:** /tmp ble tømt ved omstarten, så eksporten fra natt 3 er borte. v4-sett er derfor hentet fra prod (`scripts/baseline/prisagent-v4-sett.sql`).

## Slutt på dagen (19:35Z)

**Levert i command-center:**

| PR | Hva |
|---|---|
| #107 | Kontostatus i cockpiten |
| #108 | GOALS |
| #110 | Morgenbrief med timer, cron-linjen fjernet |
| #111 | Session-hook under 1 s |
| #113 | Distill-retry, flagg PÅ med LOOKBACK 150 |
| #119 | Tokenizer for æøå |
| #121, #124, #135 | Eval-runnere |
| #136 | Recall-flagg, PÅ via `~/.config/firm/rag.env` |
| post-merge-hook | Installert |

**Levert i Veldora:** #328, #332, #334, #337.

**Levert i drift:** #94, #104, #166–#171, #96, #97. **Levert i Terra:** #9 (hold).

**Oppfølging:**

| Når | Hva |
|---|---|
| 28.10 morgen | Sjekk `users_sessions` i Horizon-prod (read-only): utløpte økter skal være 0 etter nattjobben (#334). Lukk drift#97 med lenke. |
| 28.10 og 29.10 | Distill-retry: rader destillert per natt, gjenstående foreldreløse rader (finner-SQL i `nightly-distill.ts`) og målt kostnad (estimat ~$0,30). Kostnaden logges ikke; fakturert beløp leses i Anthropic Console. |
| 29.10 12:00 | `partial-distill-lookback-30.timer` setter LOOKBACK til 30. Sjekk drop-in-fila. Slett timer- og service-fila etterpå. |
| ~03.11 | Recall-måling på nytt med `packages/rag-engine/eval/run-real-questions-eval.ts` mot settet i Brain `08-system-architecture/eval/recall-ekte-sporsmal-2026-10-27.jsonl`, nå med flaggene på. |
| Morgenbrief 28.10 07:30 | Første brief fra timeren alene, uten cron. Sjekk `~/.local/state/morgenbrief.log`. |

**Regler lært i dag (står i minnet):** `~/code/command-center` står alltid på main; grener og tester kjøres i `~/code/.wt/`. Når panen er ledig, meldes bare endringer.
