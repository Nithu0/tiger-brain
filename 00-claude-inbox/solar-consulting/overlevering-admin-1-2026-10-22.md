# Overlevering admin-1, 2026-10-22

## Gjort (merget)
- #304 TEAM-OPPGAVER.md i rota + `projects/anbud/team/` (DPS-pakker runde 1–2, merkeark, gullsett 1.5, utkast) og `projects/rammeverk/forarbeid/` (nedlastingsliste, Digdir/KS Fiks). Intervjudetaljer som ikke er godkjent, er tatt ut. kildedata-*.txt og eforms-JSON ble liggende i Brain.
- Tidligere: #173, #177, #180, #181, #192, #204, #208, #215. Nithusans intervju er importert til prod.

## Åpent
- **Tintuns intervju:** `~/Solar-Consulting-kompetanse/intervju/tintun-2026-10-18.yaml` (godkjent: nei). Venter på hans [SJEKK]/[FYLL INN] og godkjenning. Import: `bash ~/.cache/firm/import-intervju.sh`, tørrkjøring først, så `--apply`.
- **Alpers svar:** ikke mottatt. Når operatøren limer dem inn: lag YAML etter `crm/kompetanse-mappe.example/intervju-mal.yaml`, Alper godkjenner, så import som over.
- **Lokal gren `tre-scopes-tall` (8605fd5):** upushet. Den har tall til tre-scopes-beslutningen (`crm/eval/tre-scopes-dev-2026-10-17.txt` + SQL). Jeg har spurt orchestrator-1 om den skal inn, og har ikke fått svar.
- **Prod-faktum id 28** («stresstestes») er fortsatt feil. Operatøren må rette det i CRM-admin; det står på OPERATOR-TODO.
- **TODO fra TEAM-OPPGAVER (eier orchestrator-1):** opplastingsvei for kravspesifikasjonene fra nedlastingslista (gamle anbud har ingen mulighet-id), og en dashbordside for Brreg-kontrollkøen.

## Neste steg
Ingen pågående oppgave. Ved oppstart: start innboks-monitoren fra offset `~/.cache/firm/admin-1.offset` og les `inbox/admin-1.md`.

## Hvor ting ligger
- Worktrees: `~/code/Veldora-team` (team-oppgaver, merget, kan ryddes) og `~/code/Veldora-komp` (komp-intervju, merget). Ingen ucommittet arbeid; i `Veldora-komp` ligger bare node_modules-symlinken.
- Notater: `00-claude-inbox/solar-consulting/` (TRE-SCOPES-BESLUTNING, DPS-pakker, utkast; kopiene i repoet er de gjeldende for teamet).
