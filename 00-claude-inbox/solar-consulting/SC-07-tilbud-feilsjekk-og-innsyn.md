# SC-07: tilbudet stoppes på avvisningsgrunner, og tap blir treningsdata

Pane tools-1, 2026-10-16. Gren `sc-07-tilbud`, commit `678302e`, worktree `~/code/Veldora-sc07`. Ikke pushet.

## Hva som er levert
1. **Blokkerende sjekkliste** (`lib/tilbud/checklist.ts`). Tre nye fail-tilfeller, ingen av dem kan kvitteres ut:
   - Et delvis oppfylt skal-krav som er absolutt eller uklassifisert. En ukjent klasse leses som absolutt.
   - `must-documented`: vi sier ja eller delvis, men det finnes verken dokumentasjonstekst eller en koblet seksjon med kildehenvisning. Det samme gjelder når en seksjon lister kravet som et gap.
   - `sitat-kontrollert:<hash>`: et uverifisert eller ikke-sjekket sitat bak et agentuttrukket skal-krav. Et menneske bekrefter, og bekreftelsen er bundet til nettopp det kravsettet.
2. **Avkutting** (`lib/tilbud/avkutting.ts`, `tenderText.ts`, tre jobs). Kuttene lagres i `opportunities.avkutting`, og sjekklisten blokkerer med `avkutting-kontrollert:<hash>`. Fire stille kutt gjenstår, se issue 056.
3. **Kravmatrise** i tilbuds-docx (`lib/tilbud/kravmatrise.ts`, `docx.ts`).
4. **Innsynssløyfe** (`lib/klage/laeringsdata*.ts`, collection `evaluation-lessons`). En rad per kriterium inneholder vår score mot vinnerens, vekt, begrunnelse og kilde, og et `split` som er train før 2026-10-14 og test fra den datoen. Red team og `GET /api/anbud/opportunity/:id/laerdom` leser bare train-rader.

## Målt
- vitest 2718/2718 (262 filer), tsc 0 feil, `check-migration-snapshot.sh` OK.
- `royktest.sh smoke-tilbud.ts` mot en engangs-PG 18 (postgres:18-alpine) med hele migreringskjeden: GRØNN.
- Akseptansen «testtilbud med bevisst avvisningsgrunn stoppes» er dekket av en test i `checklist-blokk.test.ts`.
- Akseptansen «en innsynsrunde ligger som treningsdata»: KOFA 2026/0352 er skrevet med `ingest-laeringsdata.ts --write` mot engangsbasen og ga 4 rader, alle `train`/`lost`, 3 av dem under vinneren.

## Gjenstår og forbehold
- **To migreringer** (avkutting og laerdom_evaluering). Begge er additive, med down, og ingen er kjørt mot prod. De står i køen etter SC-03 → SC-01 → SC-02 og regenereres trolig ved rebase.
- **Treningsdataene finnes ikke i prod ennå.** Det krever migrering pluss `ingest-laeringsdata.ts --write` mot prod, og det er operatør-gatet.
- **KOFA-runden er en ekstern runde** (`perspective: external`). Repoet har ingen innsyn fra våre egne tilbud.
- **Dashboardet viser ikke `/laerdom` ennå.** Endepunktet finnes bare i crm.
- **Kravmatrise-docx er ikke åpnet i Word.** XML-innholdet er sjekket i testen.
- **Punkt 5 (prismodell.json)** er BLOCKED på ni spørsmål til operatøren, sendt via orchestrator-1.
