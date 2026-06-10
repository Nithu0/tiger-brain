---
title: Lønnsskjema → Faktura — månedlig runbook (Verisure/Trondheim-partner)
date: 2026-06-07
tags: [AS, regnskap, verisure, faktura, fiken, runbook]
type: runbook
---

# Lønnsskjema → Faktura — månedlig runbook

Hvordan jeg (Claude) fyller Verisure-lønnsskjemaet og lager månedsfakturaen til Trondheim-partneren.
Ingen PII/kontonummer her — spesifikke ID-er (kundenr, contactId, bankkonto) ligger i
`AS/scripts/fiken-create-draft.py`. Detaljert teknisk versjon: `AS/docs/lonnsskjema-utfylling-runbook.md`.

## Inn hver måned
Operatør legger ny mappe `AS/Lønn <måned>/` med:
- `Salg alt knyttet til Sales ID.xlsx` — alt **mersalg** operatør har solgt OG montert selv.
- `Installasjoner alt knyttet til Installer ID.xlsx` — alle **oppdrag/monteringer** (installasjonsgodtgjørelse).
- `kjorebok <måned>.xlsx` — kjørebok (turer × 350 kr).

## Stegene (i rekkefølge)
1. **Inspisér** malen `AS/Lønn/Lønnsskjema.xlsx` (ark `Base KIT + andre pakker`) — finn input-kolonner vs formler.
2. **Null ut** alle antall i malen, lagre den tom. **Kopier** til `Lønn <måned>/Lønnsskjema Innleid <måned>.xlsx`
   og fyll KOPIEN (aldri malen). openpyxl `data_only=False` så formlene beholdes; Excel re-beregner ved åpning.
3. **Aggreger** eksportene per `Item_desc`, **map** til skjema-rad (fuzzy + faste regler under).
4. **Fyll** input-cellene. **Verifiser** at antallet stemmer mot eksporten (se kontroll under).
5. Bygg **fakturagrunnlaget**: Lønn-total (H16) + Kjøring + egne linjer for "noe annet".
6. Opprett **Fiken-kladd** med `AS/scripts/fiken-create-draft.py --post`. Operatør kontrollerer + sender selv.

## Skjema input-kolonner (resten = satser/formler, IKKE rør)
| Seksjon | Rader | Input | Betydning |
|---|---|---|---|
| Servicer/timer | 20–22 | F | antall (stk servicer / service betalt av kunde / kjøring) |
| Egen-generert | 26–27 | G | EG bolig / EG næring |
| Grunnpakker | 34–99 | H–L (solgt per rabatt) + **M** (installert) | |
| Utvidelser | 105–225, 230–263 | **I** bare solgt, **J** bare installert, **K** solgt+installert av samme | (H er formel) |

Satser: D (salg), E (inst); F/G = D/E × 0,65. Totaler N/O. `Lønn` = **H16**.

## Faste mapping-regler (operatør-bekreftet mai 2026)
- **Salg-fila = alt solgt OG installert av samme SE → K** (gir BEGGE deler: salgsprovisjon + installasjonsgodtgjørelse,
  fullt, ingenting trekkes fra). `J = max(0, installert − solgt)`. **I (bare solgt) = 0.**
- Installasjoner-fila → M (grunnpakker) / J (utvidelser).
- **TM-produkter uten egen rad → basisproduktets rad** (prisforskjell = bare antall). Unntak med egne rader:
  `TM Verisure Smart Alarm 12mnd`→r63, `TM Verisure Smart Alarm.`→r64, `TM - Bedrift Smart Alarm`→r65,
  **`TM Kamera`→Kameradetektor Orion (r158)**.
- **Service etter navn → Servicer-seksjonen (antall i kol F):** `Serviceoppdrag` (@160)→r20 *Stk pris servicer*;
  `Service time` (@250)→r21 *Service betalt av kunden*; `Tilkjøring`→r22 *Kjøring (45min)*.
- **Rabattnivå må treffe eksakt rad** (eksport «kr 3000 rabatt» → raden merket 3000).
- **"Kampanje: ..." regnes som noe annet** → IKKE i skjemaet; egen fakturalinje (se under).
- `tilleggskamera` = samme som vanlig basisprodukt.

## Kontroll (MÅ stemme)
- `Σ(M) + Σ(J+K utvidelser) + F20+F21+F22` = Σ antall i Installasjoner-eksporten.
- `Σ(H) + Σ(I+K utvidelser)` = Σ antall i Salg-eksporten.
- Eksportfilene har **sumrad nederst uten produktnavn** — filtrer bort rader der `Item_desc` er tom (ellers dobbelttelling).

## Faktura (Fiken) — Kukaraja Sikkerhet → "Sikkerhet 24", 25 % MVA
Linjer:
1. **"Lønn Servicer/Installasjoner"** = skjemaets `Lønn`-total (H16), antall 1.
2. **"Kjøring"** = sum av kjørebokas Sum-kolonne (timer × 350), antall 1.
3. **Egne linjer for "noe annet"** (ikke i skjemaet), enhetspris = **base-godtgj × 1,40** (40 % påslag):
   - "[Måned]kampanje: Full Sikkerhet …" (base 1100), "Morgan ekstra betaling" (base 1000),
     "Partner salg ekstra betaling" (base 500), "Ekstra betaling til tekniker" (base 335), m.fl. — operatør oppgir.
   Påslaget gjelder kun disse linjene, ikke hovedlinja.

**Datoregler:** fakturadato = siste dag forrige måned; forfall = 14. i måneden etter — lander den på helg → første
fredag før. (Begge beregnes automatisk i scriptet.)

**Script:** `AS/scripts/fiken-create-draft.py` — `--dry-run` viser payload, `--post` oppretter KLADD, `--lonn <H16>`
setter eksakt Lønn-total. Oppretter kun kladd; operatør kontrollerer i Fiken og sender selv.
Fiken-API-fallgruver (verifisert): bruk `customerId` (ikke `customers`), linje-tekst i `description` (ikke `text`),
beløp i **øre**, `vatType:"HIGH"`, `incomeAccount:"3000"`.

## Generaliserbar metode (samme mønster for lignende oppgaver i andre prosjekter)
1. **Inspisér kilde- og mal-struktur før du rører noe** — skill input-celler fra formler/konstanter.
2. **Bevar formler** (openpyxl `data_only=False`), skriv kun input-celler.
3. **Verifiser totaler mot kilden** — fanget flere reelle feil her; stol aldri på fuzzy-match alene.
4. **Ikke gjett domene-mapping** — overflat tvilstilfeller, la operatør styre, bak bekreftede regler inn i runbook.
5. **Utgående/økonomiske skrivinger** (API): bygg med dry-run default, verifiser felt-navn mot API-et,
   opprett som **kladd/draft**, hent den tilbake for å bekrefte, la operatør gjøre den irreversible sendingen.

Relatert: [[Regnskap-Runbook]], [[Skatt-Notater]], [[Refi-Partnerskap-Forretningsplan]].
