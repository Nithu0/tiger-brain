# Overlevering learning-1, 2026-10-22

Ingen ucommittet arbeid. Begge worktreene er rene. Ingen WIP-commit var nødvendig.

## Gjort
- **#200 triage-vurderer i skyggemodus** (worktree `~/code/Veldora-triagevurd`, gren `learning-1/triage-vurderer`, commit 1ca393d, pushet én gang, draft).
  - `TRIAGE_ASSESS_ENABLED=shadow` skrur den på. Utvalget er treff på scope eller CPV 72/48/79 (målt ~12,4 per døgn).
  - Kostnadstaket er `LLM_DAILY_CAP_USD_JUDGE_TRIAGE`. Migrasjonen er 20261020_205706. PREREG 5 er preregistrert.
  - Lokalt var tsc 0, og de målrettede testene var grønne. Bakgrunnssjekken etter forrige STATUS var tsc 0 og 4/4.
- **Eval-historikk 1.3:** testsettet ble kjørt én gang (PREREG 4). triage-4 fikk balanced 0,762 mot søkeordsporets 0,537. Det viser bare retning, fordi bare 4 rader er uenige. Søkeordsporets 81 % på dev er in-sample (#298).

## Åpent
1. **#200:** orchestrator-1 merker den klar og merger. Etter deploy settes `TRIAGE_ASSESS_ENABLED=shadow` og `LLM_DAILY_CAP_USD_JUDGE_TRIAGE=1` på worker. Så sjekker jeg agent-runs og kostnad per døgn, og melder tempoet mot 30 ja etter 7 døgn. PREREG 5 måles når det finnes ≥30 ja og ≥30 nei.
2. **#254 rødt lag** (draft, `~/code/Veldora-redteam`, gren `learning-1/redteam-agent`, flagget av): eval nivå A venter på at operatøren godkjenner GODKJENNING.md. Det koster ~2,4 USD per split. Dev kjøres først, så test én gang.
3. **1.5 gullsett:** `GULLSETT-1-5-GODKJENNING.md` (84 Sauda-rader) venter på operatøren. Haker overføres så til sauda-kravspek.json sammen med data-1.
4. **Prisagent v2** eies av data-1. Ikke rør lib/pris.

## Hvor ting ligger
- Eldre overlevering: `LEARNING-1-OVERLEVERING-2026-10-18.md` (samme mappe).
- Innboks-offset: `~/.cache/firm/learning-1.offset`.
