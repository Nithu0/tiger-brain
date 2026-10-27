# infra-1 — samlet rapport 17.–18.10.2026

Alt er målt read-only i prod, med SQL fra skriptfil, der ikke annet står.

## PR-er og status
| PR | Hva | Status |
| --- | --- | --- |
| #196 | Periodisk releaseStaleJobs (30 min, hvert 10. min) | merget og deployet 18.10 09:30Z. Ingen stillstand over 20 min i steg 2, heller ikke over deployene |
| #205 | Agent-bølge 0.3/0.4: caching, kostnads- og kredittvakt (cap 20 USD/døgn) | merget |
| #206 | Rapport for backfill steg 1 (eval + SQL) | merget |
| #213 | smoke-konfig sjekker egenskaper, ikke svarform, + regel i anbud/CLAUDE.md §3 | merget |
| #219 | runAgentLoop `outputSchema` → output_config.format, zod-validert `result.output` | merget. Ønsket kom fra tools-1 (#218), og #211 og #200 har også nytte av det |
| #226 | smoke-tilbud: onboarding-steget med falsk modell (deterministisk) | merget |
| #244 | eForms-kode fra norske kodelistenavn (DFØ eforms-sdk-nor f728043) + CLI `eforms:kode-fyll` | merget |
| #245 | Utvelgelseskriterier i 2024-skjemaet: «Navn» + «Beskrivelse: ____», dedup av like rader, CLI `eforms:kriterier-reparse` | merget |
| #260 | TED-kriterier fra søkefelt + `reparse --source ted` | merget 19:41Z, worker deployet før TED-vinduene |

## Backfill steg 2 (scope all, 2021–2024): FERDIG
- 09:46Z–20:36Z, 258 av 258 vinduer ferdig, 0 feilet, 0 stillstand over 20 min.
- Doffin: 210 uker, 69 023 hentet av 69 023 oppgitt = 100 %.
- TED: 48 måneder, 37 331 av 47 624 = 78 % (2021 76,8 · 2022 76,6 · 2023 78,5 · 2024 81,5). 0 vinduer med feil eller avkorting. Steg 1 hadde 92,9 % (bare resultater). HYPOTHESIS: samme gap mellom TEDs `totalNoticeCount` og det søket leverer. Hvorfor gapet er større for `all`, er UNKNOWN. TODO: sammenlign ett vindu mot ted.europa.eu før TED-dekningen brukes i telling.
- History-tenders 33 729 → 107 925 (Doffin 67 929, TED 39 996). Rå-versjoner: Doffin 67 934 + 215 (raa-arkiv-hent), TED 39 996.
- Kontroller: 0 kontaktfelt, 0 e-post i raw_notices, 0 awards fra history-backfill-tenders.
- Disk: postgres-volume 1 724 → 2 061 / 50 000 MB.
- Jobbkøen ble ikke blokkert. Andre jobber ventet høyst ett vindu (~2–4 min).
- 383 «pending» vinduer i ingest_windows er planlagte vinduer UTENFOR 2021–2024. Det er ikke et avvik.

## Relink: FERDIG
- Snapshot 20:37:44Z: 110 059 rader, 15 043 med related. Fil `~/relink-snapshots/relink-snapshot-2026-10-18.txt` (md5 5d95d650…, utenfor alle repoer).
- Jobb 20536 (20:42–20:53Z): 14 272 koblinger endret.
  - 4 325 rotbytter (eldre history-kunngjøring ble rot).
  - 5 622 peker nå på en annen rot.
  - Antall med related er uendret, 15 043.
  - 16 konflikter (mulighet på en rad som ikke er rot) er ikke flyttet.
- Awards etter relink: 387 totalt, 0 med rot som ikke lenger er rot, 0 nøkler ≠ rot, 0 kollisjoner. Nattens awards-backfill dupliserer ikke av dette. Sendt til paal-1.
- Tilbakerulling (operatørgatet): `scripts/relink-restore.ts <snapshot>`.

## Kvalifikasjonskriterier (eForms)
- Årsak 1 (#244): `eformsCodeFor` kjente bare engelske kodelistenavn. Historiske Doffin-notiser bruker norske navn.
- Årsak 2 (#245): 2024-skjemaet har Type (gruppe), Navn og «Beskrivelse: ____». Parseren leste bare Type, så ulike kriterier ble like rader. Det var IKKE duplikater, så dedup på (kind, name, description) ville slettet ekte kriterier.
- Reparse i prod fra raw_notices (tørrkjøring, så `--apply` i trinn, idempotent):
  - Doffin 2024 (8 553): rader 299 935 → 261 177, med beskrivelse 113 255 → 258 483, med kode 0 → 102 383, unike 141 614 → 261 177 (alle rader unike).
  - Doffin 2023 (4 009): rader 43 271 → 35 632. Bare kopier er fjernet, unike er uendret 35 632. Kode 0 er forventet, fordi navnene er engelske gruppenavn uten kode.
  - Live 2026: 2 % gjentak, og parsingen er uendret (snapshot-test).
- TED (#260): kriterier finnes bare i eForms-notiser (2024). TED 2024 konkurranse: 5 766 av 5 769 med kriterier, 214 909 rader. Navn og tekst pares bare når listene er like lange.
- Ikke dekket: Doffin 2021–2022 (før eForms), TED 2021–2023 (feltene finnes ikke), live TED-rader fra før #260 (ingen rå-versjon med feltene).

## Røyktest og CI
- Rødt på main 17.10 var flaky modellsvar (fra #166). Rettet i #213, #214 og #226.
- `payload migrate` gjorde en stille no-op i CI (#247, #260). Vernet til data-1 (#249) fanget det. Det er CI-miljøet, ikke kode.
- GitHub Actions stoppet av fakturering 17.10 22:07Z, ordnet 18.10.

## Åpent eller å vurdere
- TED-dekning 78 %: TODO, sammenlign ett vindu mot ted.europa.eu.
- Live TED-tenders (før SC-01, ~743) har ingen kriterier. Det krever ny henting hvis det trengs.
- Egne avvik: (1) Jeg merget main inn i #196 og #219 uten konflikt (~50 Actions-min) før regelen kom. (2) To pusher på #260, fordi testen mot engangs-PG18 ble kjørt etter første push.
- Ingen åpne oppgaver hos infra-1.
