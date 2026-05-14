---
tags: [reference, AS, regnskap, automation]
status: aktiv
opprettet: 2026-05-14
sist-oppdatert: 2026-05-14
---

# Plan.xlsx ↔ regnskap-status.md — integrasjon

Dokumenterer hvordan `/home/nithu/code/AS/Plan.xlsx` er strukturert og hvordan `scripts/excel-aggregate.py` mapper innholdet til `docs/regnskap-status.md`.

## TL;DR

- Plan.xlsx (ark `AS`) er **primær kilde** for månedlig utgiftsoversikt.
- `scripts/excel-aggregate.py` leser arket og genererer en markdown-tabell mellom `<!-- STRUCTURED-AGGREGATE:BEGIN -->` og `<!-- STRUCTURED-AGGREGATE:END -->` i `docs/regnskap-status.md`.
- Workflow: rediger Plan.xlsx → kjør scriptet → markdown oppdateres idempotent.

## Plan.xlsx struktur (per 2026-05-14)

Filen inneholder flere ark; relevante for AS-regnskap:

| Ark | Innhold | Brukes av scriptet? |
|---|---|---|
| `AS` | Månedlige utgifter per kategori (Oktober 2025 → August 2026) | **Ja** (default) |
| `2026` | Privat budsjett 2026 (Januar-Juni) | Nei |
| `2025`, `2024`, `2023`, `2022` | Historisk privat budsjett | Nei |
| `Overview` | Aggregert visning | Nei |
| `AI agents`, `investering`, `Bilflipp`, `Education`, `Kosthold`, `mamma og pappa` | Andre formål | Nei |

### Layout for ark `AS`

**Pivotert / wide format**: hver måned okkuperer ~4 kolonner, ikke rader.

**Rad 1** (header):

- Kolonne 0: tittel `Forbuk fra AS`
- Kolonne 3: `Privat ` (privat-spor, ignoreres av scriptet)
- Kolonne 6-9: `Bra mnd`, `Privat`, `AS`, `160 timer` (planleggings-metadata, ignoreres)
- Kolonne 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52: månedsanker-celler med tekst `Oktober`, `November`, `Desember`, `Januar`, `Februar`, `Mars`, `April`, `Mai`, `Juni`, `Juli`, `August`
- Hver måned følges av to underkolonner (anchor+1 og anchor+2):
  - `Hvor mye` (planlagt beløp)
  - `Betalt` (faktisk beløp)

**Rad 2-12** (kategorier i kolonne 0):

1. Bil
2. Bom
3. Diesel
4. Forsikring
5. Klarna
6. Mobil
7. Leie
8. Tjenester (Chat, fiken…)
9. Lønn
10. Regnskapsfører
11. Investering

**Rad 13**: `Totalt` — summer per måned (Excel-formel).

**Rad 15+**: planlegg-noter (`110 timer arbeid (70% stilling) *50%`, `37000`, `Bil pris`, etc.) — ikke brukt av scriptet.

**Rad 23-26**: Kina-relaterte poster (Reise, Bo, Bruk) — ikke relevant for regnskap.

### Visualisering

```
        col 0      col 1       col 2     col 3      col 4     col 5     ... col 12      col 13     col 14    ...
row 1 | Forbuk    |           |         | Privat   |         |         | Oktober  | Hvor mye | Betalt   | ...
row 2 | Bil       | 7000      | (note)  | Klarna   | 1000    |         | Bil      | 7500     | 7500     | ...
row 3 | Bom       |           |         |          |         |         |          |          |          | ...
...
row 13| Totalt    |           |         |          |         |         |          | <sum>    | <sum>    | ...
```

## Mapping: xlsx → markdown

Scriptet (`scripts/excel-aggregate.py`) gjør:

1. **Åpner read-only** med `openpyxl.load_workbook(..., read_only=True, data_only=True)`. Verdiene som returneres er beregnede tall (formler eksekveres ikke; siste lagrede verdi brukes).
2. **Finner månedsankere** i rad 1: matcher mot `MONTH_TOKENS` (Januar … Desember + forkortelser).
3. **Identifiserer kategori-rader**: rad 2 til (rad-med-`Totalt` − 1) der kolonne 0 er ikke-tom tekst.
4. **Per måned**:
   - Hvis `Totalt`-rad finnes og har verdi i `Hvor mye` / `Betalt`-kolonnene: bruk den verdien
   - Ellers: aggregér kategori-radene
5. **Statusklassifisering**:
   - `tom` — ingen planlagt og ingen betalt
   - `planlagt` — kun planlagt fylt inn, ingen betalt
   - `delvis` — færre `Betalt`-celler enn `Hvor mye`-celler
   - `komplett` — alle fylte planlagt-celler har tilsvarende betalt-celle
6. **Skriver markdown-tabell** mellom `<!-- STRUCTURED-AGGREGATE:BEGIN -->` og `<!-- STRUCTURED-AGGREGATE:END -->`.

### Begrensninger

- **Ikke inntektsdata**: AS-arket sporer kun utgiftssiden. Netto- og MVA-kolonner i markdown-tabellen er tomme. Når Plan.xlsx får inntekt-rader, må scriptet utvides.
- **Formel-resultater**: `data_only=True` returnerer sist beregnede verdi. Hvis Plan.xlsx redigeres uten å åpnes/lagres i Excel/LibreOffice, kan formler ha utdaterte resultater. Mitigering: lagre filen etter redigering.
- **Ikke MVA-tracking**: rullerende 12-mnd omsetning beregnes manuelt i `regnskap-status.md` (egen tabell, utenfor STRUCTURED-AGGREGATE-blokken).
- **Norsk Bokmål kun**: månedsnavn må være norske strenger ("Januar", ikke "January").

## Hvordan oppdatere xlsx → markdown auto-refresher

### Manuell flyt (i dag)

```bash
cd /home/nithu/code/AS
# Aktiver venv (hvis ikke aktivt)
.venv/bin/python scripts/excel-aggregate.py
# git diff docs/regnskap-status.md   # sanity-check
```

### Forslag til automatisering (ikke implementert ennå)

- **Pre-commit hook**: kjør scriptet før commit hvis `Plan.xlsx` er endret. Lokal hook, ikke CI (av personvernhensyn).
- **Cron / systemd-timer**: daglig kjøring kl 23:00. Lavt verdi-tillegg siden Plan.xlsx redigeres sjeldent.
- **Watchdog**: Python `watchdog`-pakke triggerer scriptet ved filendring. Overkill.
- **Anbefaling**: hold som manuell flyt inntil filen redigeres > 2 ganger/uke.

## Endre Plan.xlsx-strukturen — checklist

Hvis ny måned legges til, ny kategori, nye kolonner:

- [ ] Bekreft månedstoken er norsk (eller legg til i `MONTH_NORMALIZE` i scriptet)
- [ ] Sjekk at månedsanker fortsatt er rad 1 i en tekst-celle
- [ ] Sjekk at `Totalt`-rad fortsatt har streng `Totalt` (case-insensitive)
- [ ] Kjør scriptet — verifiser at `Måneder funnet: N` matcher forventet antall

## Sikkerhet

- Scriptet **printer aldri faktiske beløp** til stdout — kun metadata (antall rader, kolonner, måneder, kategorier).
- Plan.xlsx leses **read-only**. Scriptet skriver aldri tilbake til filen.
- Aggregerte månedssummer i `docs/regnskap-status.md` er tillatt (per `CLAUDE.md` — aggregert månedlig sum i docs/ er OK; per-bilag-detalj er ikke).
- Filen `Plan.xlsx` er **ikke** committet til Git (sensitivt). Verifiser i `.gitignore` hvis repo aktiveres.

## Relaterte filer

- `/home/nithu/code/AS/Plan.xlsx` — kilde
- `/home/nithu/code/AS/scripts/excel-aggregate.py` — script
- `/home/nithu/code/AS/scripts/README.md` — script-dokumentasjon
- `/home/nithu/code/AS/docs/regnskap-status.md` — output (med STRUCTURED-AGGREGATE-blokk)
- [[Regnskap-Runbook]] — månedsrutine
- [[Skatt-Notater]] — skatte-regler

## Tags

#reference #AS #regnskap #automation #plan-xlsx
