# GOALS.md — data-1

## Aktivt mål (2026-10-14)

**Levert:** distill-hullet målt + spor B kjørt etter operatør-påfylling.
**456 av 457 rader for 13.10 er destillert** (10:13-10:55Z, ~12 rader/min, USD ~1,5),
verifisert med `rag-recall` — gårsdagen er søkbar igjen. Rapport med resultat-seksjon:
`00-claude-inbox/command-center/2026-10-14_distill-gap.md`.

**Venter på beslutning (meldt orchestrator-1 10:58Z):** to små fikser i min lane,
ingen startet —
(1) `distill.ts:148` degraderer ukjent `room_assignments[].type` til `concept`,
(2) `haiku-distiller.ts` leser `stop_reason` og prøver én gang med dobbelt tak ved
`max_tokens`. De to kjente giftradene (verbatim 14960 fra 12.10, 15061 fra 13.10) er
en gratis regresjonssuite.

**Fortsatt åpent:** de 49 radene over 8 delvise juni/juli-dager (spor C, ≈ USD 0,17)
retryes aldri av design og trenger et valg. 14.10 tas av nattens ordinære kjøring.

**Ikke min lane:** hook-taket (`firm-hook-session-start.sh`) + morgenbrief-timeren
ligger i `_bin/`; begge sviktet i natt og er grunnen til at feilen gikk uoppdaget.

## Pushet 2026-10-14 (operatørens «push alt ut», uten force)

- `feat/data-1-f4b-reviewed` = `512ec2e` (stakken STATE dokumenterer)
- `feat/data-1-f4b-reconcile` = `ec10e37` (lå bare i `~/.cache/cc-wt-f4b`)

Begge 3 commits over base `fc303ea`, 34 bak `origin/main`, divergerer fra hverandre
(9 filer, 91+/156−). `feat/data-1-f4b` (`92ff3d1`) urørt — **force-push ikke gjort,
krever operatøren.** Ingen PR: må reconciles mot dagens main først.

Urørt og usikret: `feat/data-1-trade-forensics-ingest` (`bf1301e`, `~/.cache/cc-wt-tfingest`).

Handoff: `Brain/handoffs/2026-10-14-data-1.md`

## Parkert fra før — oppdatert status

- `feat/data-1-f4b` / fasett-filtrert hybrid-recall: **ikke lenger upushet** — begge
  stakkene er sikret på origin (se over). Gjenstår: velg én, rebase på dagens main, PR.
  Detaljer i `agents/data-1/STATE.md`.
- `tools-1/doctor-guard-aware` (`fee21a7`): **landet på origin/main** (via tools-1 sin
  PR #89 13.10). Ikke parkert arbeid lenger, og det var tools-1 sin lane.
- Etter merge av en f4b-stakk gjenstår fortsatt: `_bin/facets-backfill.ts` mot live-DB
  (derive-v2) + populer `customer_aliases` (operatør). **NB:** f4b-stakkene rører
  `_bin/{facets-backfill.ts,rag-recall.*,session-capture.mjs}` — omstridt territorium,
  må samkjøres med tools-1/infra-1 ved merge.

### Updated
2026-10-14 — data-1 (overlevert + pushet)
