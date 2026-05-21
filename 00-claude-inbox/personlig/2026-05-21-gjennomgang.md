---
type: audit
domain: personlig
created: 2026-05-21
sensitive: true
author: claude-code
---

# Personlig-prosjekt — gjennomgang 2026-05-21

> ⚠ Sensitivitet: helsedata-domene. Ikke pushes til shared repo. Se [[_README]].
> Generert av en Claude Code research-økt etter full gjennomlesning av
> `/home/nithu/code/Personlig/` (CLAUDE.md, alle templates, mål-filer, dashboard,
> dummy-logger, ukentlig-2026-20) + Obsidian `07-personlig/`-mappen.

## TL;DR

Prosjektet er en **velbygget tom skall**. Strukturen, templates og dashboard-scriptet
er gjennomtenkt og fungerer (verifisert mot dummy-data). Men null ekte data er logget,
og alle mål-/referansetall er placeholders. Systemet kan derfor ikke produsere et
eneste reelt beslutningsstøtte-signal ennå. Bootstrap er ferdig; ibruktaking har ikke
begynt. Full beslutnings-sjekkliste ligger i `code/Personlig/BESLUTNINGER-TRENGS.md`.

## Tilstandsvurdering

### Bygget og fungerer
- Mappestruktur komplett, matcher CLAUDE.md.
- Fem templates (daglig, ukentlig, månedlig, matplan, treningsprogram) — lavfriksjon,
  godt designet, realistiske placeholder-eksempler.
- `dashboard/aggregate.py` — solid: robust frontmatter-parsing, tolererer `__`/`4/5`,
  hopper over ugyldige logger uten å krasje. `today`- og `week`-subkommandoer virker.
- Aggregeringen er verifisert: `effektivitet/ukentlige/2026-20.md` ble korrekt generert
  fra 3 dummy-logger (deep work 7.9 t, søvn 7.5, kvalitet 3.7, energi 7.0/6.0).
- `.gitignore` i code-repoet skiller riktig mellom templates (sjekkes inn) og
  sensitive logger (ekskluderes). Bra.
- Obsidian `07-personlig/` har MOC, Goals-2026 og Habits-Tracker — alle med
  sensitivitet-advarsel i frontmatter og topptekst.

### Tomt / ikke bygget
- **0 ekte logger.** Eneste innhold i `logger/` er 3 dummy-filer.
- **Ingen matplan.** `mat/matplaner/` kun `.gitkeep`.
- **Ingen treningsprogram, ingen progresjon-logg.** Begge mapper kun `.gitkeep`.
- **Alle mål-filer er placeholder-skall** — kortsiktig, langsiktig, livsmål, Goals-2026.
- **Måltavle tom** — ingen 1RM, ingen kroppsvekt.
- `aggregate.py` lover en `month`-subkommando + `personlig-month`-wrapper i
  docstringen, men hverken kommandoen, wrapperen eller `effektivitet/manedlige/`
  finnes. Månedlig review er kun en template, ingen kode bak.
- Dashboard fase 2 (visuelt) ikke startet — venter bevisst på data + tech-stack-valg.

### 🔴 Sikkerhetsfunn (binding-brudd)
`~/Obsidian/Brain/` har remote `git@github.com:Nithu0/tiger-brain.git` — det delte
repoet med Karri. `~/Obsidian/Brain/.gitignore` ekskluderer **ikke** `07-personlig/**`.
Ved neste commit/push lekker helsedata (vekt, søvn, mentale tilstander) til et delt
repo. Dette bryter CLAUDE.md sin binding-regel direkte. Må fikses før neste push:
legg `07-personlig/` i Brain-`.gitignore` (eller path-guard CI). Hvis filene allerede
er committet må de fjernes fra historikken — operatør-gated operasjon.

## Friksjons-risikoer (blir dette faktisk fylt ut daglig?)

Dette er prosjektets reelle risiko. Systemet er bra på papiret; spørsmålet er adopsjon.

1. **Mål-vakuum dreper motivasjon.** Å logge tall uten et mål å sammenligne mot føles
   meningsløst etter få dager. KPI-tabellen viser i dag faktiske tall, men `Mål`-
   kolonnen er tom — null diff, null retning. Dette er den største adopsjons-trusselen
   og bør løses før logging i det hele tatt starter.
2. **Tre tracking-overflater.** Daglig-logg (code), Habits-Tracker (Obsidian),
   matplan (code) — tre filer å holde i live. Atomic Habits-grid og daglig-logg
   overlapper delvis. Risiko: én glipper, deretter alle. Vurder å starte med KUN
   daglig-loggen i 2-3 uker, legg til habits-grid når den vanen står.
3. **`personlig-today` krever venv + `$EDITOR`.** Hvis venv ikke er satt opp eller
   `$EDITOR` ikke er satt, blir morgenrutinen friksjon. Bør verifiseres at det funker
   i ett klikk før operatøren forventes å bruke det daglig.
4. **Mappestruktur-avvik.** CLAUDE.md sier `logger/YYYY/uke-WW/dag-DD.md`; koden
   skriver flatt `logger/YYYY-MM-DD.md`. Ufarlig for aggregeringen, men forvirrende —
   operatør som følger CLAUDE.md manuelt og operatør som bruker scriptet ender ulikt.
5. **Søndags-review er 15 min + 45 min/mnd.** Realistisk bare hvis ukedataene
   allerede er fylt. Hvis daglig-logging glipper, blir review tom og rutinen dør.
6. **Dummy-logger ligger fortsatt i `logger/`.** Liten ting, men de bør slettes idet
   ekte logging starter, ellers forurenser de aggregeringen.

## Prioritert forslagsliste — neste 4 uker

Mål: gå fra tom skall til et system som gir minst ett reelt signal per akse.

### Uke 1 (2026-05-21 → 05-27) — fjern blockere
- [ ] **Fiks Brain `.gitignore`** — legg inn `07-personlig/`. Sikkerhet, ikke valgfritt.
- [ ] Velg mat-fase: bulk / cut / maintenance. Ett valg som låser opp hele mat-aksen.
- [ ] Fyll inn nåværende 1RM (eller godt estimat) for de store løftene i `måltavle.md`.
- [ ] Sett 2-4 konkrete kortsiktige mål i `mål/kortsiktig.md` — ett per akse, tallfestet.
- [ ] Slett dummy-loggene, start ekte daglig-logging fra dag 1.

### Uke 2 (05-28 → 06-03) — fyll datafiler
- [ ] Lag aktivt treningsprogram fra template → `trening/programmer/<navn>.md`.
- [ ] Lag første ekte matplan → `mat/matplaner/uke-2026-23.md` med kalori-/protein-mål.
- [ ] Fyll deep work-, søvn- og energi-mål inn i `ukentlig-review-template.md`.
- [ ] Kjør første ekte ukentlig review søndag — sjekk at `Mål`/`Diff`-kolonnene nå har tall.

### Uke 3 (06-04 → 06-10) — legg til andre lag
- [ ] Aktiver Habits-Tracker: definer 3-5 vaner (ikke fler), start ukesgrid.
- [ ] Fyll inn `Goals-2026.md` (årets tema + 7 mål) og `mål/langsiktig.md`.
- [ ] Verifiser at logging-vanen faktisk står etter 2 uker — hvis ikke, forenkle.

### Uke 4 (06-11 → 06-17) — konsolider + beslutt
- [ ] Første månedlige review (manuelt fra template — `month`-kode finnes ikke ennå).
- [ ] Beslutt: bygge `aggregate.py month`-subkommando, eller rette docstringen.
- [ ] Med ~4 uker ekte data: ta dashboard fase 2 tech-stack-beslutningen
      (Streamlit vs. Obsidian Dataview — sistnevnte gir lavest friksjon hvis tracking
      uansett delvis bor i vault).
- [ ] Fyll `mål/livsmål.md` (3-7 mål) når hodet er klart for strategisk refleksjon.

### Bevisst utsatt
- Dashboard fase 2 implementasjon — venter på data + tech-stack-valg. Riktig prioritet.
- Korrelasjons-engine (`make analyze`) — meningsløst før det finnes flere ukers data.

## Tre viktigste tingene operatøren bør gjøre først

1. **Fiks Brain `.gitignore`** — `07-personlig/` lekker til shared repo akkurat nå.
2. **Velg mat-fase (bulk/cut/maintenance)** — ett valg som låser opp hele mat-aksen.
3. **Legg inn 1RM + kortsiktige mål** — uten referansetall er all tracking retningsløs,
   og det er det som dreper adopsjon raskest.
