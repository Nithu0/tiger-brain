# HLE-labeler bruker trailet stop i barriere-simuleringen — 29/84 «sl_hit»-labels var lønnsomme trades

- **Dato:** 2026-07-15
- **Reviewer:** Karri
- **Status:** proposed
- **Kategori:** gjenoppretter intendert label-semantikk (bug-fix), men endrer læringskorpuset som edge-verdikter bygger på → Karri-synlighet før re-labeling
- **Foreslått av:** ai-1 (Claude), rot-årsaket 15.07

## Hva data viser

- `label-worker.ts:190-206` simulerer triple-barrier mot **gjeldende `stop_loss`-kolonne**, som er trailet (break-even parkerer den på entry, chain-trail flytter den videre).
- Verifisert mot realiserte utfall: **29 av 84 trades labelet `sl_hit` (label-R ≈ −1,1) lukket i virkeligheten med gevinst** (realisert snitt-R −0,05 på gruppen).
- Konsekvens for eval-run 13.07: label-basert win rate 11,7&nbsp;% / mean R −0,68 vs realisert ~45&nbsp;% / ≈ 0,0 på samme kohort. «Insufficient» står (n_eff=100 er for lite), men «beviselig negativ» er et artefakt.
- Samme felle ble fikset for quarantine-stien i `07a8bdb` (dokumentert i postmortem-r-multiple.ts) men aldri anvendt på labeleren.
- Tilleggsskjevhet: `triple-barrier.ts:366-374` NULL-er label-R ved pnl-motsigelse — treffer 25&nbsp;% av vinnere vs 6,6&nbsp;% av tapere (systematisk vinner-bias i korpuset).

## Root cause

Labeleren skal måle strategiens *entry-beslutning* mot entry-tidspunktets risiko (`original_risk_points` / opprinnelig SL), ikke mot management-lagets senere flyttede stop. Med trailet stop registreres en breakeven-parkert vinner som «sl_hit» når prisen touchér entry igjen.

## Forslag

1. Labeleren bruker entry-tidspunktets risikobasis (original SL / `original_risk_points`) for nedre barriere; management-utfall forblir eget felt (realisert R), ikke label-barrieren.
2. Re-label hele korpuset (label_version bump → v2) + re-kjør eval. Gamle labels beholdes med versjon, ingenting slettes.
3. pnl-motsigelses-stien logger og beholder realisert R i stedet for å NULL-e (fjerner vinner-bias).

## Alternativer jeg vurderte og forkastet

- **La labels stå og bare dokumentere skjevheten:** eval-verdiktene er grunnlaget for live-beslutningen — et kjent-feil korpus som fortsatt konsumeres er verre enn re-labeling med versjonering.
- **Justere eval i stedet for labels:** flikker på symptomet; alle andre konsumenter (profiler, counterfactuals) leser fortsatt feil semantikk.

## Strategisk vurdering for deg

- **Best case:** korpuset måler entry-kvalitet ærlig; eval v2 gir et riktigere (trolig mindre negativt) bilde; MinTRL-kravet består uansett.
- **Worst case:** re-labeling endrer profil-tallene du evt. har sett på — derfor versjonert, aldri overskrevet.
- **Caveat:** 84 sl_hit av 128 labels er liten n; men mekanismen (trailet stop som barriere) er deterministisk feil uavhengig av n.

## Spørsmål jeg vil ha din vurdering på

1. Godkjenner du entry-risiko som barrierebasis (punkt 1) og re-label til v2?
2. Skal realisert R (management-utfall) inn som eget felt i labels-tabellen samtidig, så begge perspektiver finnes?

## Rollback

- Labels er versjonert — v1 beholdes; eval kan pinnes til label_version=1. Kode-revert via git.
