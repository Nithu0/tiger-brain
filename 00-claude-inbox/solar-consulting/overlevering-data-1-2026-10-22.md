# Overlevering data-1, 2026-10-22

Repoet er Veldora/anbud (`projects/anbud/crm`), worktree `~/code/Veldora-sc04-krav`.

## Gjort 19.–21.10 (alt merget eller levert)

| Hva | Hvor | Resultat |
| --- | --- | --- |
| Kunnskapsgraf: viewet `graf_kanter` + tre spørringer | #290 | Merget. Norconsult telles én gang. «Hvem bytter» kan ikke besvares uten kontraktsrekker. |
| Kontraktsrekker (D dokumentert, A antatt) | #291, #295 | 67 D-lenker skrevet som 47 `contract.chain`-signaler (FACT). A-regelen er parkert: porten n = 1. Ny registrering først ved ≥ 30 nye D-par med siterende tenders.id > 167 179. |
| Prisdiagnose etter natt 2 | inbox-melding 20.10 | Spennet er ikke skjevt, men løst. Runde millioner (51 %) bommer oppover. |
| Prisagent v3 (runde millioner holdt utenfor) | #292, #305 | Kalibrert (0,540 mot forventet 0,548), men for bredt (bredde 2,29 mot porten 1,0). `PRISAGENT_ENABLED` står av. |
| v1 kjøring 3 | #292 (PREREG) | Treff 0,409 mot 0,519, bredde 2,18. Porten holder ikke. |
| Sakssystem-krav (ADR-0022) | #297 | Ingen KJERNE eller VALGFRI kan dokumenteres fra kunngjøringer. Arkivintegrasjon gir sterkest signal. Bare 24 av 1 333 har krav fra konkurransegrunnlaget. |
| Nedlastingsliste, 100 sakssystem-anbud | `00-claude-inbox/solar-consulting/rammeverk/nedlastingsliste.md` | Til operatøren. Sortert etter sannsynlig tilgjengelighet i portalen. |

## Åpent

1. **Prisagent v4.** PLAN er sendt til orchestrator-1 22.10 og venter på godkjenning. Dekning er målt lokalt: CPV 5 siffer 63 %, estimat 2 %, varighet 2 %, antall tilbydere 62 % (men det lekker og kan ikke brukes). Kjøpersignalene er ikke målt, fordi **Railway-CLI-innloggingen er utløpt (`invalid_grant`)**. Noen med tilgang må kjøre `railway login`.
   - WIP ligger lokalt på grenen `wip/data-1-prisagent-v4` (`06e8688`, ikke pushet): `scripts/baseline/prisagent-v4-dekning.sql` (prod-SQL, ikke kjørt) og `scripts/diag-pris-v4-dekning.ts` (lokal).
   - Ny testdel for v4: tildelinger med id > 32 438, og ikke på kunngjøringer diagnosene har sett. Det må stå i en ny PREREG før kjøring.
2. **Hendelseskjeden 25.10:** mål hvor mange I/B som fikk krav via `queueChainOnDecision` først.
3. **Kontraktsrekker A-regel:** venter på ≥ 30 nye D-par (se over).

## Hvor ting ligger

- Eksportene etter natt 2 og natt 3 ligger bare i en midlertidig scratchpad og forsvinner. Lag dem på nytt med `scripts/baseline/prisagent-diag-export.sql`.
- PREREG: `eval/prisagent/PREREG.md`, `eval/kontraktsrekker/PREREG.md`, `eval/systemskifte/PREREG.md`.
- Sett-nøkler for v3-testdelen: `eval/prisagent/v3-sett.json`.
- Prod-tilgang (read-only) er beskrevet i memory `reference_veldora_prod_db_tilgang.md`: SQL over stdin via `railway ssh -s Postgres`.
