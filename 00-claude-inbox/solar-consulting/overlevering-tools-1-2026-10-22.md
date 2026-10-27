# Overlevering tools-1, 2026-10-22

Alt er committet. Ingen ucommittet arbeid i noen av mine worktrees. Ingen åpne PR-er fra meg.

## Gjort (18.–20.10, merget til main)

- **#262** konkurransegrunnlag `realistic` (overtatt fra trading-1), deretter backfill av 48 muligheter (2,11 USD).
- **#269** `/marked/ordninger` (DPS-panel). Leser `dps.qualifiable` og `dps.gaps` fra paal-1.
- **#273** «Mulige partnere» i Konkurranse og kjøper. Leser `partner.candidates` fra data-1. Verifisert mot prod (133 signaler).
- **#275** HIDDEN_TOPICS: 7 skjulte emner i crm og dashbord.
- **#276 / #277** kjøperresearch: fiks i `criteriaWeighting` og evalkjøring 3 **bestått** (10/10). Flagget er på med dagstak 3 USD.
- **#280 / #283 / #288** teknologiregisteret: ordliste med 68 termer uten integratorer, `buyer.technology` per kjøper, CLI `npm run teknologiregister`, og seksjonen «Teknologi hos kjøperen». I prod: 410 kjøpere. D- og skifte-sitat beholdes, med 0 brudd.
- **#227** Horizon (Tintun): main merget inn to ganger, våre sider portet, fire Horizon-feil rettet, og lookalike-migreringen regenerert etter #290. Merget som b3e1233, deployet, og migreringen er kjørt i prod.

## Åpent

1. **Merkeark for teknologiregisteret, runde 2:** `00-claude-inbox/solar-consulting/teknologi/merkeark-runde2-2026-10-19.md` (100 treff, frø 20261019-2). Operatøren eller en utpekt person merker det. Bestått (presisjon på navn ≥ 0,90) gir en liten PR som setter `TECH_VERIFIED = true` i `crm/src/lib/teknologi/register.ts` og kjører `npm run teknologiregister -- --apply`. Da forsvinner merket «ikke kontrollert» i panelet. Ikke bestått: operatøren avgjør (forhåndsregistreringen ligger i `crm/eval/teknologi/FORHANDSREGISTRERING.md`).
2. **#189 prismodell** (draft): venter på operatørens svar på prismodell-spørsmålene.
3. **959 og 1016** mangler anbudsdokumenter. Operatøren laster opp med `npm run dokumenter:last-opp` (#259).

## Måletall å følge

- Kjøperresearch døgn 1 (19.10): 1,21 av 3 USD, 17 kjøringer ok, 51 profiler, 0 feil. Måles med `scratchpad/kjoperresearch-dogn1.sql` via `scripts/baseline/run-triage-baseline.sh`. Cron-en går 04:25Z–20:25Z.

## Hvor ting ligger

- Worktrees (alle rene, kan ryddes av operatøren): `~/code/Veldora-{b23b,dps,partner,hidden,eval2,tek,tek2,tek3,horizon}-t1`, og `~/code/Veldora-e2e`.
- Evalfiler: `crm/eval/kjoperresearch/`, `crm/eval/teknologi/`.
- Lærdommer i minnet (command-center): Actions-minutter (kjed test med `&&` før push), WSL-klokka, firm-bus er append-only, bakgrunn og STATUS-takt, regel 21.10.
