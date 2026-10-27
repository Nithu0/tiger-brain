# Overlevering learning-1, 2026-10-27 kveld

Dagen er avsluttet av orchestrator-1. Alt arbeidet er merget, og ingenting ligger ucommittet.

## Levert i dag (alt merget)
- Skyggemodus for triage-4 er verifisert i prod: 7/7 ok første natt, 0,015 USD per vurdering.
- Drift: dataflytdiagram (#29) og ROS-analyse (#28). ROS er fulgt opp til v0.7: backup målt, slått på og gjenopprettingstestet (154/154 tabeller), og crm-volumet målt.
- Horizon: per-IP-grense på innlogging (#335 og #340, verifisert i prod med 429 på forsøk 21), seed-admin herdet (#346), TOTP for admin (#347, `ADMIN_TOTP=enroll`), dataminimering mot Anthropic (#351), og datatyper og samtykkefilter (#352).
- Terra: prismaScimStore (#8, merget etter Tintuns review). guard-main i alle 5 org-repoer (A6: oppdages, hindres ikke).
- Drift-dokumenter: kvalitetssystem v0.9, tilbudstekster for kvalitet og informasjonssikkerhet, HMS, egenerklæring, EHF-notat, aksjeeierbok-mal og Anthropic-dataflyt.

## Åpent (venter på andre)
1. **Fasit for rødt lag:** drift #189 (Nithu/Alper krysser av 20 svar). Når «ferdig» står der: før ja-svarene inn i `originaler.json` og kjør nivå A, dev først og test én gang (~2,4 USD per split).
2. **Triage-4, PREREG 5:** mål ~03.11 (≥30 ja og ≥30 nei). Read-only via `crm/scripts/baseline/run-triage-baseline.sh`.
3. **TOTP `required`:** først når operatøren har satt opp TOTP og testet en gjenopprettingskode (drift #126).
4. **Operatør (hemmelighet):** bytt admin-passordet og slett `SEED_ADMIN_*` fra crm.
5. **Review-kø for Tintun:** drift #164 (Terra #9 → aurora #4 → Terra #13 → #11 → #10, og nova #2 med kommentarer). Hold den oppdatert.
6. Navn på egne ansatte i judge.assess står til teamet avgjør.

## Hvor
Worktrees: `~/code/Veldora-ratelimit`, `~/code/Terra-scim`, `~/code/drift-sikkerhet` (alle grenene er merget). Innboks-offset: `~/.cache/firm/learning-1.offset`.
