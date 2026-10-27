# trading-1 — GOALS

> PARKERT 2026-10-13 for Veldora-strategirådet (runde 1). Gjenopptas etter rådet.

## Hva jeg hadde i gang
- Branch `feat/hle-import-resilience` i `ai-assistent` (3 commits: 2856344, 22ddbb1, 95990c3) —
  HLE historical_events-backfill tålte ikke droppet DB-socket; retry-loop + test registrert.
  Status: lokalt grønt, IKKE pushet. Venter på operatør "OK kjør".

## MÅ gjøres før noe annet (begrunnelse)
1. **Ingenting er farlig å etterlate.** Branchen er isolert, main urørt, ingen prod-endring,
   ingen Railway-flip, ingen DB-skriv utført. Ingen halvferdig migrering i flukt.
2. Eneste levende avhengighet: operatøren må på et tidspunkt pushe/merge
   `feat/hle-import-resilience`, ellers fortsetter backfill-jobben å dø på transiente
   DB-drop i prod. Lav hast (jobben er manuelt trigget, ikke i cron).

## Trygt å parkere
- Alt annet nexus-arbeid: winrate-artefakt-oppfølging, portfolio_regime-backfill (A5),
  Karri-proposals 15.07. Ingen av dem har tidsvindu denne uken.

## Uryddig men ufarlig
- ~20 untracked filer i worktree (PDF-er, skjermbilder, proposal-drafts, oneshot-SQL).
  Ingen secrets. Ingen av dem skal committes som del av HLE-branchen.

## BØLGE 0 (2026-10-13)
- Levert: crm-build + royktest-port i CI. Gren `trading-1/crm-ci-royktest` (1c00bde) i worktree `/home/nithu/code/Veldora-ci`. IKKE pushet.
- Står igjen: isolasjon per røyktest, 3 data-avhengige skip, fixture-eval for scoring-regresjon, post-deploy-port (parkert av orchestrator).
