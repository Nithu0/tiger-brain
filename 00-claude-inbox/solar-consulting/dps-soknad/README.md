# DPS-søknadspakker — Solarconsulting AS (admin-1, 2026-10-19)

Status: `UTKAST`. Operatøren sender selv. Ingenting her er sendt.
Kildedata (prod read-only 2026-10-19 05:52Z): [`kildedata-2026-10-19.txt`](kildedata-2026-10-19.txt), skript `crm/scripts/baseline/dps-soknad-krav.sql`.

| Ordning | Oppdragsgiver | Frist | Pakke |
|---|---|---|---|
| Sammensatte team knyttet til systemutvikling ([2022-962877](https://doffin.no/notices/2022-962877)) | Registerenheten i Brønnøysund | **22.11.2026** | [brreg-sammensatte-team.md](brreg-sammensatte-team.md) |
| IT-konsulenter – Analytics, maskinlæring og dataforvaltning ([2022-343586](https://doffin.no/notices/2022-343586)) | Sjøfartsdirektoratet | 31.12.2026 | [sjofart-analytics-ml.md](sjofart-analytics-ml.md) |
| IT-konsulenter – Utviklere og techlead ([2022-318980](https://doffin.no/notices/2022-318980)) | Sjøfartsdirektoratet | 31.12.2026 | [sjofart-utviklere-techlead.md](sjofart-utviklere-techlead.md) |

Felles: [firmabeskrivelse-utkast.md](firmabeskrivelse-utkast.md) · [espd-utkast.md](espd-utkast.md) · [epost-dfo-utkast.md](epost-dfo-utkast.md)

## Det viktigste først
1. **Kvalifikasjonskravene i kunngjøringene er bare to:** lovlig registrert foretak og ordnede skatteforhold (`FACT`, sitert i hver pakke). Begge er lette å oppfylle. Brreg henter dem selv via eBevis, Sjøfartsdirektoratet vil ha dem vedlagt.
2. **Kompetansekravene står i et kvalifikasjonsgrunnlag vi ikke har.** Brreg viser til Mercell (permalink i kunngjøringen), og Sjøfartsdirektoratet skriver «Mer informasjon om ønsket erfaring og kompetanse finnes i kvalifikasjonsgrunnlaget». Et menneske må hente det fra Mercell/KGV med egen innlogging (ingen skraping, ARCHITECTURE §10). **Pakkene er ufullstendige til det er lest.**
3. **Eierskiftet (ventet uke 43):** søknaden må signeres av den som har signaturrett *når den sendes*. Firmaattesten viser roller etter Foretaksregisteret. For Brreg (frist 22.11) bør den sendes etter at eierskiftet er registrert.
4. **Faktum i prod er feil:** capability_facts id 28 sier «Hele systemet stresstestes før levering». Ifølge Tintun er det ende-til-ende-test (Playwright), ikke lasttest. Det må rettes i CRM-admin **før** noe gjenbrukes i en søknad.
5. **Ingen IT-kundereferanser i selskapet** (fakta id 26). En DPS-kvalifisering krever det ikke ifølge kunngjøringen, men konkurransene under ordningen vil vekte erfaring. Personlige referanser i CV-ene (Tintun: Nevion) er det vi har, men de er **ikke frigitt** (Nevion må spørres).

## Hvem skaffer hva
| Hva | Hvem | Når |
|---|---|---|
| Kvalifikasjonsgrunnlag fra Mercell (Brreg) og fra Sjøfartsdirektoratet | operatør (innlogging) | nå |
| Registrering av eierskifte i Foretaksregisteret, ny signaturrett | operatør / tidligere eier | uke 43 |
| Skatteattest fra Altinn (Sjøfartsdirektoratet: vedlegg; maks 6 mnd gammel) | operatør | etter eierskiftet |
| Firmaattest (Sjøfartsdirektoratet: vedlegg) | operatør | etter eierskiftet |
| Ansvarsforsikring | operatør | etter eierskiftet |
| CV-er i standardformat (3 stk.), med samtykke | Nithusan, Tintun, Alper | før innsending |
| Alpers intervju (kompetanse og referanser) | Alper | mangler |
| Frigivelse av Nevion-referanser | Tintun | spør Nevion |
| Retting av faktum id 28 | operatør (CRM-admin) | nå |

---

# Runde 2 — Vinmonopolet, Digdir, Entur, Mattilsynet, Flytoget (trading-1, 2026-10-20)

Status: `UTKAST`. Ingenting er sendt. Kildedata (prod read-only, målt 2026-10-20 20:46Z): [`kildedata-2026-10-20.txt`](kildedata-2026-10-20.txt). SQL-en står nederst i fila.
Kompetansebank og bevis-id er de samme som i runde 1 (`kildedata-2026-10-19.txt`). Jeg har ikke lest dem på nytt.

## Søk i denne rekkefølgen
| # | Ordning | Frist / varighet | Krav i kunngjøringen | Match | Pakke |
|---|---|---|---|---|---|
| 1 | Mattilsynet, systemutvikling ([2025-103853](https://doffin.no/notices/2025-103853)) | 12.04.2029 | **3 konkrete:** kredittverdighet, presentasjon på maks 2 A4-sider, egenerklæring om russisk involvering | god (frontend, backend, fullstack). Risiko: «100% engasjement» | [mattilsynet-systemutvikling.md](mattilsynet-systemutvikling.md) |
| 2 | Vinmonopolet 20-019, systemutvikling ([2024-105583](https://doffin.no/notices/2024-105583)) | 08.05.2028 | ESPD-skjema uten terskler | god | [vinmonopolet-systemutvikling.md](vinmonopolet-systemutvikling.md) |
| 3 | Vinmonopolet 20-018, analytics/ML ([2024-105499](https://doffin.no/notices/2024-105499)) | 08.05.2028 | samme | middels | [vinmonopolet-analytics-ml.md](vinmonopolet-analytics-ml.md) |
| 4 | Digdir, utvikling og teknisk støtte ([2025-112751](https://doffin.no/notices/2025-112751)) | 05.10.2029, 200 MNOK | ingen | `UNKNOWN` | [digdir-utvikling-teknisk-stotte.md](digdir-utvikling-teknisk-stotte.md) |
| 5 | Entur, individuelle ressurser ([2021-386923](https://doffin.no/notices/2021-386923)) | 01.02.2027 | ingen (TendSign) | middels, kort varighet | [entur-it-utvikling.md](entur-it-utvikling.md) |
| – | Flytoget ([2023-664176](https://doffin.no/notices/2023-664176)) | 30.12.2026 | ingen | lav (mobil/web, «Østlandet 2») | [flytoget-it-utvikling.md](flytoget-it-utvikling.md) |
| – | Mattilsynet 2021 ([2021-361268](https://doffin.no/notices/2021-361268)) | 31.12.2026 | ingen | erstattes av nr. 1 | [mattilsynet-ikt-utvikling-2021.md](mattilsynet-ikt-utvikling-2021.md) |
| – | Entur, team/gruppe ([2021-320600](https://doffin.no/notices/2021-320600)) | 29.03.2027 | ingen | nei («et større antall ressurser») | [entur-it-utvikling.md](entur-it-utvikling.md) |

## Det viktigste
1. **«34 krav» (Vinmonopolet) og «50 krav» (Digdir) er ikke krav.** Det er Mercells ESPD-skjema: avvisningsgrunner og overskrifter som «Leverandørens ("totale") årsomsetning … er som følger:», uten terskler (`FACT`, eForm i kildedata).
   Telleren i paal-1s notat og i `dps-assess` (DPS-VURDERINGER-2026-10-19) teller derfor skjemafelt. Det er ikke et mål på hvor vanskelig det er å kvalifisere seg. **Dette bør meldes til den som eier `lib/dps/assess.ts`.**
2. **Mattilsynet 2025-103853 er den eneste med egne minstekrav i kunngjøringen**, og alle tre er lette. Den bør søkes først, gjerne samtidig med Brreg.
3. **Referanser er den ukjente som avgjør Vinmonopolet og Digdir.** ESPD-feltet «viktige tjenester av den etterspurte type» er med, men om det er et minstekrav, står bare i grunnlaget. Vi har ingen IT-kundereferanser (fakta id 26).
4. **Tre av ordningene går ut innen ca. 3,5 måneder** (Flytoget, Mattilsynet 2021, Entur individuelle). En kvalifisering der gir lite (ANTAKELSE: fristen = varighet).
5. **Portaler:** alle unntatt Entur er i Mercell (samme konto som Brreg). Entur bruker TendSign, som krever en egen konto.

## Hvem skaffer hva (i tillegg til runde 1)
| Hva | Hvem |
|---|---|
| Mercell-grunnlag for Mattilsynet 2025, Vinmonopolet 20-018/019 og Digdir (hvilken ordning er åpen?) | operatør |
| Kredittvurdering (Mattilsynet punkt 4.3) | operatør |
| Presentasjon på maks 2 A4-sider (Mattilsynet punkt 4.4) | Nithusan, med en CV-ressurs |
| Egenerklæring om russisk involvering (Mattilsynet punkt 4.6) | signaturberettiget etter eierskiftet |
| Kan noen ta oppdrag på 100 %? | Tintun, Alper |
| TendSign-konto (Entur), bare hvis vi går videre med nr. 5 | operatør |
