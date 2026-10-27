# Overlevering learning-1, 2026-10-27

Det fantes ikke ucommittet arbeid, så ingen WIP-commit var nødvendig.

## Gjort siden 22.10
- **#254 rødt lag** er merget (flagget REDTEAM_AGENT_ENABLED er av). Main ble merget inn og pushet én gang. CI var grønn 7/7.
- **#200 triage-vurderer** er merget 25.10 18:12Z. Migreringen er laget på nytt som `20261025_123751_triage_assessment`, slik at den sorterer etter main sin 20261024. Up, down og up er testet på en fersk base, og CI var 8/8.
- **Skyggemodus PÅ** 26.10 ~21:25Z. Jeg satte `TRIAGE_ASSESS_ENABLED=shadow` og `LLM_DAILY_CAP_USD_JUDGE_TRIAGE=1` på worker etter operatørens «kjør». Redeployen 5d416408 gikk OK. Worker-loggen har ingen feil, men ved 06:30Z var det heller ingen vurderinger å se ennå.
  - Tilbakerulling: `railway variables -s worker --set TRIAGE_ASSESS_ENABLED=`

## Neste steg
1. **~26.10 22:30 CET + 24 t:** sjekk de første skyggevurderingene read-only via `crm/scripts/baseline/run-triage-baseline.sh --sql <fil>`. Spørringen er mot `agent_runs` der agent er triage-assess: antall ok/skipped/failed og kostnad. Sjekk også `opportunities.triage_assessment IS NOT NULL` for åpne muligheter, og at den er skjult i API-et før beslutning.
2. **Etter 7 døgn:** meld tempoet mot ≥30 ja og ≥30 nei (PREREG 5, `crm/eval/triage-vurderer/PREREG.md`). Måles når tallene er nådd.
3. **Parkert, venter på orchestrator-1:** eval nivå A for rødt lag (originaler.json 0/20 godkjent) og gullsett 1.5 (84 Sauda-rader). Begge krever menneskelig fasit (ADR-0011). Jeg har bedt orchestrator-1 om å avgjøre parkering eller annen vurderer.
4. Prisagent v2 eies av data-1.

## Hvor
- Worktrees: `~/code/Veldora-triagevurd` (learning-1/triage-vurderer, merget) og `~/code/Veldora-redteam` (merget). Begge er rene.
- Innboks-offset: `~/.cache/firm/learning-1.offset`.
- Forrige overlevering: `overlevering-learning-1-2026-10-22.md`.
