# Overlevering: trading-1, 2026-10-22 (pause)

## Gjort siden forrige overlevering (18.10)
- **Teknologikart (strategi):** `strategi-2026-10-19/trading-1.md`. En ordliste uten LLM ga treff i 1 274 av 110 059 kunngjøringer, med 98 % presisjon på navn. eForm-teksten gir ca. 5x så mange treff. Registeret som kom ut av dette, er bygget og merget av tools-1 (#280, #283 og #288).
- **HIDDEN_TOPICS (skyggesignaler ut av innboksen):** jeg fant hullet, men pushet ikke, fordi operatøren stoppet push-kallet. tools-1 leverte fiksen i #275.
- **DPS-søknadspakker 2 (20.10):** sju pakker og en oppsummering for runde 2 i `dps-soknad/README.md`. Kildedata ligger i `dps-soknad/kildedata-2026-10-20.txt` (prod read-only, SQL med). Søk Mattilsynet 2025-103853 først.
  Funn: «34/50 krav» hos Vinmonopolet og Digdir er Mercells ESPD-skjema, ikke reelle krav. Sendt til paal-1 via orchestrator-1.

## Åpent (venter på andre)
- **DPS:** operatøren må logge inn i Mercell og hente kvalifikasjonsgrunnlagene. Om referanser er minstekrav hos Vinmonopolet og Digdir, avgjør om vi kan søke der. Digdir har tre overlappende ordninger, og hvilken som tar opp nye leverandører, er ukjent.
- **Fra 18.10, uendret:** merkeark A, stikkprøve 5/43 for B23, godkjenning av red team nivå A og skyggemodus B rundt 2026-11-01. Detaljer i `TRADING-1-OVERLEVERING-2026-10-18.md`.

## Hvor ting ligger
- `~/code/Veldora-skjul` (gren `skjul-skygge`): lokal WIP-commit 7e409f4. Den er **overflødig** (#275 er på main) og skal **ikke pushes**. Kan slettes (sletting er operatørgatet).
- `~/code/Veldora-tek` (gren `tek-register`): ren, uten commits. Overflødig av samme grunn.
- Scratchpad (forsvinner med sesjonen): SQL og råutdata er kopiert inn i `dps-soknad/kildedata-2026-10-20.txt`, så ingenting går tapt.

## Neste steg
Ingen aktiv oppgave. Når pausen er over: start innboks-monitoren fra lagret offset (`~/.cache/firm/trading-1.offset`) og vent på oppgave.
