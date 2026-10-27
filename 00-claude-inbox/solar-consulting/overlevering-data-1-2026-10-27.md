# Overlevering data-1, 2026-10-27

**Gjort:** hendelseskjede-målingen (25.10) er levert som PR #328 (bare SQL). Dekningen av v4-signalene er målt i prod read-only. PREREG v4 og kode er commitet på `sc-04-prisagent-v4` i Veldora-sc04-krav (ikke pushet ennå).
**Åpent:** kodegjennomgang av v4, push av PREREG-PR, fersk eksport, så én `--v4`-kjøring.
**Neste:** `scripts/eval-pris-spenn.ts <eksport> --v4 --tell`, så `--v4`. Resultatet føres i eval/prisagent/PREREG.md under «Kjøring v4».
**NB:** /tmp ble tømt ved omstarten, så eksporten fra natt 3 er borte. v4-sett er derfor hentet fra prod (`scripts/baseline/prisagent-v4-sett.sql`).
