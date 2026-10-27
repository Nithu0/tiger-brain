# Til operatøren — ting bare du kan gjøre

> **Teamets oppgaver (Tintun, Alper, deg) ligger nå i repoet: `TEAM-OPPGAVER.md` (PR #304, merget 21.10).** Denne fila har bare det som er ditt personlig.

Én fil, oppdatert av orchestrator-1. Kryss av eller skriv svar rett i fila, så plukker jeg det opp.
Sist oppdatert: 2026-10-19 ~18:55 (Oslo).

## Hva skjedde i natt (18.–19.10), kort

- **Data:** hullet 2025–sept. 2026 er fylt (Doffin og TED 100 %), og TED 2021–24 er rettet fra 78 % til 100 %. 164 855 historiske kunngjøringer, 0 dubletter, 0 kontakter. Disk 3,9 av 50 GB.
- **Tildelinger:** natt 1 ga 387 → 5 829 (+5 461, 0 dubletter). Taket er hevet til 8 000 per natt, og natt 2 kjører 02:00.
- **Leverandører:** vinnere med org.nr. 51 % → 83 %. 7 678 leverandører. 530 åpne muligheter har nå «sittende leverandør».
- **PÅ i prod (nye i natt):** kjøperresearch (tak 3 USD/døgn, morgenen kostet 0,24), partnerspor (133 muligheter med mulige partnere), gjenkjøpssignal (første kjøring 03:15), teknologiregister (430 kjøpere, merket «ikke kontrollert»), Slack (testmelding OK) og Google-token.
- **Morgen 19.10:** systemskifte-radar BESTÅTT (54 % mot grunnrate 45 %) og slått PÅ (30 systemskifter hos ~23 kjøpere, første kjøring 03:15). Visningen venter på at du skriver «OK kjør» i paal-1. Doffin Public API trinn 1 er merget (av til nøkkel). Teknologiregisteret er rettet (integratorer ute, sitater beholdt), 410 kjøpere.
- **Ettermiddag 19.10:** Tintuns #220 (logo) og #227 (Horizon, med alle våre paneler portet og to Horizon-feil rettet) er MERGET og deployet. Kunnskapsgraf-view (#290) i prod. Triage-4 ikke bestått, så 1.3 er endelig stoppet. Prisagent-diagnose: 60 % av «endelige» priser er hele millioner (trolig anslag/tak), og v3 kommer etter natt 2.
- **Bygget, AV:** DPS-motoren (venter på at du sjekker 10 vurderinger), prisagenten (to forsøk, ikke bestått: for få tildelinger med både estimat og pris, ny kjøring etter natt 2).
- **Lagt bort:** triage-vurderer (slår ikke nøkkelord), overvåker C (for lite beslutningslogg).
- **Panes:** learning-1 og trading-1 har hengt i flere timer. Arbeidet deres er flyttet. Se gjerne om panene må startes på nytt.
- **Merkeark til deg:** teknologiregisteret, `~/Obsidian/Brain/00-claude-inbox/solar-consulting/teknologi/merkeark-runde2-2026-10-19.md` (100 treff, ~15 min, uten integratorer).

## Rammeverk/base (ADR-0022): resultat av fellesteknologi-kartleggingen (PR #297)

- **Kunngjøringene alene kan ikke avgjøre hva som er kjerne.** 923 sakssystem-kunngjøringer siden 2022: ingen teknologi er nevnt i over 15 %. Bare 24 av 1 333 kandidater har krav fra et konkurransegrunnlag. Resten er omtale.
- **Sterkeste ekte signal: integrasjon mot kundens arkiv** (arkivkjerne 70, Noark 49, Acos/WebSak 34, Public 360 18). Det støtter «integrer, ikke egen Noark». KS Fiks og ID-porten nevnes knapt i kunngjøringene (4 og 5).
- **For et grunnlag teamet kan bestemme ut fra:** last ned kravspesifikasjonene for 50–100 sakssystem-anbud. Ferdig liste med lenker: `~/Obsidian/Brain/00-claude-inbox/solar-consulting/rammeverk/nedlastingsliste.md` (100 stk, 53 med høy sannsynlighet for at dokumentet fortsatt ligger ute, start øverst) og legg dem i `~/Solar-Consulting-dokumenter/`. Kravagenten leser dem, og med ~80 blir usikkerheten rundt ±11 prosentpoeng. Inntil da anbefaler jeg å bare bygge arkivintegrasjon + innlogging/roller + saker i base.
- **Avtaler med Digdir og KS Fiks: sjekkliste klar** i `~/Obsidian/Brain/00-claude-inbox/solar-consulting/rammeverk/AVTALER-DIGDIR-KSFIKS.md` (13 punkter). Test kan vi få selv nå (Digdir-vilkår, Maskinporten-testklient, e-post til fiks@ksdigital.no for KS Fiks-test). Prod mot kommuner krever kommunen (SSA-L, kommunen oppretter integrasjonen). ID-porten til egen innlogging er trolig ikke tillatt for private, så spør Digdir. **Start etter at eierskiftet er registrert hos Brreg** (signering følger rollene i Enhetsregisteret).

## Raskt når du er tilbake

- [x] (begge er oppe igjen 20.10) **Start learning-1- og trading-1-panene på nytt.** De svarte ikke på vekking (monitoren deres er død). learning-1 har et viktig funn: nøkkelordfilteret er in-sample og fanger 0–3 av 8 ja utenfor utvalget, så triage-vurdereren bør testes rettferdig (~0,2 USD).

- [x] (GJORT 20.10, #299 og #300) **Skriv «OK kjør» i paal-1-panen igjen**, for IT-filter-rettelsen (commit b88a88e, og eval-commit 6abd68c for natt 1–2). 18 av 1010 IT-rader faller ut, alle sjekket for hånd, og ingen var ekte IT (Statsbygg-bygg, prosjektledelse). Udir IT-konsulentavtale og Asker EPJ kommer inn i topp 20.

- [x] (GJORT) **Skriv «OK kjør» i paal-1-panen.** Den holder push av systemskifte-visningen (commit 569753a) til du skriver det selv. Fullmakt via meg godtar den ikke, med vilje.

## VIKTIGST: varslene når ingen i dag

- [x] **(GJORT 18.10, testmelding OK)** **Slack: morgenbrifen og driftsvarslene har aldri nådd noen.** Alle kjøringer melder «Slack ikke konfigurert, kun logget». Sett `SLACK_BOT_TOKEN` og `SLACK_CHANNEL_ANBUD` på Railway-tjenesten **worker** (Slack-appen trenger `chat:write` og må være invitert i kanalen). Si fra når det er gjort, så tester jeg.
- [x] **(GJORT 18.10, sjekkes 19.10 ~16:00)** **Google-tokenet dør etter ~16 t** (`invalid_rapt`). Det gjør at sync-workspace feiler (480 ganger på 7 dager) og at e-postsammendraget ikke sendes. Årsaken er re-autentiseringspolicyen i Google Workspace. Gå til Google Admin → Sikkerhet → Tilgangs- og datakontroll → Google Cloud session control og sett «Krev aldri re-autentisering» for kontoen. Kjør så `gws auth login`, si fra, så eksporterer jeg tokenet til worker på nytt.

## Strategi (19.10): les og ta stilling (~10 min)

- [ ] Les `~/Obsidian/Brain/00-claude-inbox/solar-consulting/strategi-2026-10-19/STRATEGISK-VURDERING.md` (topp 5, rangert; raske forbedringer er alt i gang).
- [ ] **Søk opptak i dynamiske innkjøpsordninger** når forsikringen er på plass (uke 43): Brønnøysundregistrene «Sammensatte team» (frist **22.11**), Sjøfartsdirektoratet «Analytics/ML» + «Utviklere/techlead» (31.12). DPS-motoren viser snart hva vi mangler per ordning.
- [ ] **Det som låser opp flest DPS-er** (målt på 50 åpne ordninger i feltet vårt: 0 kan søkes i dag, 34 mangler noe). Billigst først: (1) **org.nr. i leverandørprofilen** (25 ordninger, settes etter eierskiftet), (2) **skatteattest** (29), (3) **kort firmabeskrivelse og leveranseomtale** (31), (4) kredittvurdering (23), (5) miljø- og kvalitetsdokumentasjon (22). Legg dem inn i kompetansebanken eller leverandørprofilen, så vurderer motoren alt på nytt.
- [ ] **Sjekk 10 DPS-vurderinger** (~15 min) før DPS-motoren slås på: https://github.com/Nithu0/Solar-Consulting/blob/main/projects/anbud/crm/eval/DPS-VURDERINGER-2026-10-19.md (etter merge av #271)
- [ ] **DPS-søknadspakker er klare** i `~/Obsidian/Brain/00-claude-inbox/solar-consulting/dps-soknad/` (Brønnøysundregistrene «Sammensatte team», frist 22.11, og Sjøfartsdirektoratet). Kunngjøringene krever bare to ting: registrert foretak og skatteattest. Org.nr. 931949837 er verifisert. **Men kompetanse- og teamkravene står i kvalifikasjonsgrunnlaget, som ligger i Mercell og hos Sjøfartsdirektoratet.** Last det ned og legg det i `~/Solar-Consulting-dokumenter/dps-<navn>/`, så fyller vi ut resten.
- [ ] **(Lav prioritet, ikke nødvendig nå)** **Doffin Public API-nøkkel:** innhentingen virker i dag uten. Nøkkelen er bare en forsikring hvis Doffin endrer sitt udokumenterte API. lag en nøkkel på DFØs utviklerportal (gratis, ingen godkjenning) og sett `DOFFIN_API_KEY` på Railway worker. Send helst DFØ-e-posten om vilkår først. Plan: `2026-10-19_infra-1-doffin-public-api-plan.md`.
- [ ] **(Ikke nødvendig nå, bruken er intern)** **E-post til DFØ om Doffin-API-et**: blir aktuelt først hvis vi skal selge innsikt (for eksempel systemskifte-radaren) til kunder. ligger ferdig i `dps-soknad/`. Riktig mottaker må finnes (Notices-kontakten er neppe rett).
- [x] (GJORT, «OK kjør») kunnskapsgraf-migrering (§4.1).
- [ ] Se gjennom dashbordet i nettleseren etter Horizon (Tintun bør også se det).
- [ ] Godkjenn eller avslå:, retningen «systemskifte-radar» (§2.3).
- [ ] (Ikke nødvendig nå) E-post til DFØ: bare hvis vi skal selge data-innsikt videre.

## Les og godkjenn (sortert etter hvor mye det låser opp)

- [ ] **Red team, godkjenning** (låser opp bølge 2.2, red team som scorer tilbudsutkast). NB: når du godkjenner, godkjenner du også at eval A kjøres for ~2,5 USD (Opus, nytt anslag fra riggen, tak 5 USD)
  https://github.com/Nithu0/Solar-Consulting/blob/main/projects/anbud/crm/eval/redteam/nivaa-a/GODKJENNING.md
- [ ] **Konkurranseagenten, stikkprøve 5 av 43** (~5 min): åpne 5 av linjene merket `TIL_MENNESKE` og se at verdien står i kilden
  https://github.com/Nithu0/Solar-Consulting/blob/main/projects/anbud/crm/eval/konkurranse-kilde-v1-2026-10-18.txt
- [ ] **Fasit for kravuttrekk (gullsett 1.5)** (KLAR, ~20 min, 84 Sauda-krav, alle sitater sjekket 84/84, du vurderer bare merkelappene; 2 er markert «se ekstra nøye»: sauda-030 og sauda-080). Låser opp en ekte måling av kravagenten på dokumenter
  `~/Obsidian/Brain/00-claude-inbox/solar-consulting/GULLSETT-1-5-GODKJENNING.md`
- [ ] **Overvåkeren, merkeark** (~20 min, 30 rader, ja/nei + kort grunn)
  `~/Obsidian/Brain/00-claude-inbox/solar-consulting/OVERVAKER-A-MERKEARK.md`
- [ ] **Underleverandør-paragraf** (FOA § 19-3 → § 19-2/§ 24-4, vises til brukere). Står på hold til du eller en jurist sier ok
  https://github.com/Nithu0/Solar-Consulting/pull/231
- [ ] **Databehandleravtale-utkast** (to konflikter mot Anthropics DPA: 48 t mot 24 t avviksvarsel, 15 mot 30 dager underleverandørvarsel)
  `~/Obsidian/Brain/00-claude-inbox/solar-consulting/UTKAST-DATABEHANDLERAVTALE.md`
- [ ] **Kvalitetssystem-utkast** (kodegjennomgang og testing må bekreftes av Tintun og Alper)
  `~/Obsidian/Brain/00-claude-inbox/solar-consulting/UTKAST-KVALITETSSYSTEM.md`
- [ ] **Brief med Haiku 5.5 kontra 4.5** (bytte modell for briefen hvis Haiku 5.5-teksten er god nok)
  `~/Obsidian/Brain/00-claude-inbox/solar-consulting/HAIKU-55-brief-side-om-side.md`
- [ ] **Tilbudsskriver, blind A/B** (10 seksjoner, gammel mot ny; nøkkelen ligger ved siden av)
  `~/Solar-Consulting-kompetanse/tilbudsskriver-ab/side-om-side.md`

- [ ] **Kompetansebanken: rett «stresstestes» i dine fakta** (CRM-admin, dine intervjufakta). Det betyr ende-til-ende-testing med Playwright, ikke lasttest.
- [ ] **Tintuns intervju-utkast venter på at Tintun godkjenner**: `~/Solar-Consulting-kompetanse/intervju/tintun-2026-10-18.yaml`. Avklar også om konkurranseklausulen hans (kringkasting og media) omfatter medieovervåking, og om Nevion kan oppgis som referanse.

## Prøv plattformen (10 min)

- [ ] Åpne https://anbud-veldora.vercel.app/opportunities/1016 (SMS Gateway). Se at krav (12 fra kravagenten), brief og konkurransegrunnlag vises. Trykk «Lag utkast»: tilbudsskriveren er nå på. Skriv her hva som mangler eller ser rart ut.

## Last ned konkurransegrunnlag (fra hyyr), 10 konkurranser

Legg filene i `~/Solar-Consulting-dokumenter/<mulighet-id>/` (lag mappen, ZIP går fint). Last dem så opp selv, med din egen innlogging, fra `~/code/Veldora/projects/anbud/crm` (etter at PR #259 er merget):

```
export IMPORT_EMAIL=<din e-post>; read -rs IMPORT_PASSWORD; export IMPORT_PASSWORD
npm run dokumenter:last-opp -- --dir ~/Solar-Consulting-dokumenter --remote https://crm-production-ef9b.up.railway.app
# ser lista riktig ut: samme kommando med --apply
```

Kravagenten starter av seg selv for hver mulighet som får filer. .doc og .xls må lagres som .docx og .xlsx først.

| Mulighet | Konkurranse | Oppdragsgiver | Frist | Kunngjøring |
|---|---|---|---|---|
| 1016 | SMS Gateway | Trondheim Renholdsverk | 29.10 | https://doffin.no/notices/2026-116062 |
| 377 | Saksbehandlingsløsning (26182) | Innkjøpskontoret AS | 27.10 | https://doffin.no/notices/2026-114750 |
| 959 | Fagsystem PPT og logoped, Nord-Østerdal | Abakus AS | 13.11 | https://doffin.no/notices/2026-115977 |
| 821 | Møtegjennomføringsverktøy | Halden kommune | 13.11 | https://doffin.no/notices/2026-115817 |
| 1085 | Biblioteksystem vgs-bibliotek | Møre og Romsdal fk. | 10.11 | https://doffin.no/notices/2026-116150 |
| 699 | Konsulenttjenester Hypergene | Arbeidstilsynet | 09.11 | https://ted.europa.eu/en/notice/-/detail/694924-2026 |
| 19 | Digitalt omsorgsverktøy skolemiljø | Trondheim kommune | 03.11 | https://ted.europa.eu/en/notice/-/detail/667527-2026 |
| 937 | Varslingssystem (felleskontrakt) | DSS | 13.11 | https://ted.europa.eu/en/notice/-/detail/710095-2026 |
| 1051 | Digital partner | 22. juli-senteret | 13.11 | https://ted.europa.eu/en/notice/-/detail/716139-2026 |
| 830 | Tilgang til KI-tjenester | Energidepartementet | – | https://doffin.no/notices/2026-115810 |

Valgt fordi de er åpne, i vårt felt (fagsystem, KI, konsulent), og flere er små nok til å være realistiske som første kontrakt.
SMS Gateway og Hypergene-konsulent er de mest realistiske å vinne.

## Avgjørelser du har tatt (logg)

- 2026-10-18: Tilbudsskriver og konkurranseagent PÅ i prod.
- 2026-10-18: Ingen timepris. Målet er én vunnet kontrakt i år, realistisk størrelse, i et felt der det kommer flere (referanseliste).
- 2026-10-18: AI SKAL foreslå tilbudspris og vinnsjanse (ny prisagent, bølge 2.5, learning-1).
- 2026-10-18: Kunngjøringer og sammendrag holder for nå. 10 grunnlag lastes ned for innsikt.
- 2026-10-18: #227 Horizon går fritt. Den som merges sist, fikser konflikten.

## Senere

- Omnigent-cockpit: én fane der oppgavene dine, filer å lese og alle agentene vises. Denne fila er en midlertidig erstatning.

## Kommer snart

- Brreg-kontrollkøen (`/api/anbud/suppliers/brreg-queue`) fylles med anslagsvis ~450 leverandører som må kontrolleres for hånd de neste ~5 nettene (navn som ikke ga et sikkert treff i Brreg). Noen i teamet bør ta den.
