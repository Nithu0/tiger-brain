# Chain-trail TP2 < TP1 (H14-config) — invertert kjede klipper vinnere og inflaterer win rate

- **Dato:** 2026-07-15
- **Reviewer:** Karri
- **Status:** proposed
- **Kategori:** teknisk sett bug-fix (gjenoppretter intendert trapp-semantikk), men endrer live-exits på Karri-godkjent H14-config → Karri-gated uansett
- **Foreslått av:** ai-1 (Claude), rot-årsaket 15.07 med kode + prod-DB

## Hva data viser

- 13 trades har `CHAIN_TP2_LOCKIN` i `management_events` siden 22.06 (12 MR long + 1 SB short). Alle lukket `OANDA_SL_TP` 1–5 min etter lockin, med close 0,03–3,4 pkt over tp2Price og 8,7–15,7 pkt UNDER tp1-nivået som ble "låst inn".
- Siste 2 uker: 23 trades totalt, WR 52,2 %, sum −$746. **Uten de 10 lockin-tradene: WR 15,4 %, sum −$1 715.** Lockin-tradene alene: 10/10 "vinnere", +$969 (snitt +$107).
- MR før/etter: juni WR 41,7 % med snittvinner $396; juli WR 83,3 % med snittvinner $97 og snitt-taper −$349 (krever ~78 % WR for breakeven).
- Alle strategier, snittvinner før/etter første lockin 22.06: $385 → $123.
- Konsekvens: **alt som konsumerer win rate (kalibrering, lesson-derive, morgenbriefing, dashboards) leser et tall som er ~37 pp inflatert.**

## Root cause

- `apps/worker/src/firm/position-management/lifecycle.ts:272-333` (`evaluateChainTrail`): TP-nivåer = entry + sign·mult·ATR; TP2-grenen setter `newStop = tp1Price`.
- `apps/worker/src/firm/position-management/rules.ts:181-188`: MR-profil fra H14 er **tp1=1.5, tp2=0.1, tp3=5.0 ATR** — TP2 ligger UNDER TP1. Samme inversjon i TF (2.0/0.5) og BC (1.0/0.1). Ingen validering av tp1<tp2<tp3 finnes.
- Live-mekanikk på long: pris når entry+0,1·ATR → TP2 fyrer først → SL settes til entry+1,5·ATR = over markedspris → OANDA lukker umiddelbart på marked. `CHAIN_TP1_BE` har aldri fyrt for MR — uoppnåelig med configen.
- H14-sveipet (27 600 combos, commit `8a08cef` 16.05) fant tp2<tp1 som "sweet-spot" for 3 av 4 strategier. Mest sannsynlige simulator-hull: exit kreditert på SL-*nivået* (+1,5 ATR fantom) i stedet for marked (+0,1 ATR reelt) når SL settes forbi pris — forklarer både "perfekt stabilitet" i sveipet og +1319p/6mo-estimatet. Live-tallene motbeviser backtest-claimet uavhengig av dette.

## Forslag

1. **Invariant-guard i `evaluateChainTrail`:** aldri sett `newStop` forbi gjeldende markedspris (long: newStop < price, short: newStop > price). Gjenoppretter trapp-semantikken uansett config.
2. **Config-validering i `resolveChainTrailRules`:** avvis/logg ikke-monotone profiler (krav tp1<tp2<tp3) med fallback til default-profil + Discord-varsel.
3. **Karri-eid oppfølging:** re-kjør H14-sveipet med monotonisitets-constraint og korrigert fill-modell (exit på marked når SL settes forbi pris) for MR/TF/BC før nye chain-verdier settes.

1+2 er kodeendringer bak eksisterende flagg-struktur, revertbare med git-revert; ingen nye env-vars.

## Alternativer jeg vurderte og forkastet

- **Bare flippe chain-trail av (env):** fjerner også TP1-BE/TP3-logikken som er korrekt for SB/default-profilene; mister management-data.
- **Stille fikse verdiene (sette tp2=2.5):** det er en ny strategi-parameter ingen har validert → verre enn guard + resveip.
- **Ikke gjøre noe før mer data:** hver uke til produserer ~5-7 forurensede labels som HLE/kalibrering konsumerer.

## Strategisk vurdering for deg

- **Best case:** guard + validering deployes, MR-exits går tilbake til intendert trapp; ny data blir ren; H14-resveip gir ærlige chain-verdier.
- **Worst case:** MR mister de små +0,1-ATR-scalpene (+$969 siste 2 uker) og viser sin underliggende svakhet (15 % WR eks-klipp) tydeligere — men det tallet er sant, og du vil se det, ikke skjule det.
- **Sample-caveat:** 13 lockin-trades er lite; retningen (close ved tp2, aldri ved tp1) er deterministisk mekanikk, ikke statistikk — konfidensen ligger i koden, ikke n.

## Spørsmål jeg vil ha din vurdering på

1. Godkjenner du guard (1) + validering (2) som bug-fix nå, med resveip (3) som separat løp?
2. Var tp2<tp1 et bevisst valg i H14 ("scalp-modus") — eller bekrefter du artefakt-tolkningen?
3. TF (2.0/0.5) og BC (1.0/0.1) bærer samme inversjon — skal de guardes samtidig (anbefalt) eller vente?

## Rollback

- Kodeendring: `git revert` av fix-commiten; ingen env-endringer kreves.
- Hvis guard gir uventet oppførsel: chain-trail kan flagges av per strategi via eksisterende MGMT-flagg (30-sekunders Railway-revert).

## Vedlegg

- Full analyse med tall: interaktiv rapport (lenke sendt operatør 15.07) + agent-rot-årsak i sesjonslogg ai-1 15.07.
- Relatert: `docs/strategy/proposals/2026-05-16_mr_reaktivering_h14.md` (configen som innførte verdiene).
