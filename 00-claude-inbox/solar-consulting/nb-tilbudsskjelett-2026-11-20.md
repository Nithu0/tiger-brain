# Nasjonalbiblioteket 2026/9514: tilbudsskjelett

data-1, 20.11.2026, bestilt av orchestrator-1. Grunnlaget er `nb-kravmatrise-2026-11-20.md` (Doffin 2026-117583, TED 787180-2026 og horizon).

**Konkurransegrunnlaget er ikke lest.** Det ligger i Mercell. Kapitlene under bygger på det kunngjøringen sier, og på slik norske IKT-rammeavtaler pleier å være satt opp (SSA-B eller SSA-T, med kvalitet og pris som tildelingskriterier). Når grunnlaget er lastet ned, følger vi **dets** struktur og svarskjemaer, og dette skjelettet blir bare en sjekkliste. `ASSUMPTION` står der jeg har gjettet strukturen.

**Frister:** spørsmål **03.12 kl. 12**, tilbud **10.12 kl. 12**. Tilbudet signeres elektronisk i Mercell, og **manglende dokumentasjon kan ikke ettersendes**.

## Rollene

| Hvem | Ansvar i tilbudet |
|---|---|
| **Nithu** (daglig leder) | Eier tilbudet. Mercell (laste ned, stille spørsmål, levere), signatur, pris, tilbudsbrev og endelig ja. Har ikke samtykket til at CV-en hans brukes (drift#42). |
| **Tintun** | Faglig ansvarlig for oppdragsforståelse og løsning (kap. 3–4). Kvalitets- og sikkerhetsansvarlig (kap. 6). Godkjenner sin egen CV. |
| **Alper** | Integrasjoner og backend (kap. 4.3). Egen CV og referanseprosjekter fra tidligere arbeidsgiver (drift#41). Eier DPS-søknadene og er vant med svarformen. |
| **Designpartner** | Design, UX og WordPress-tema (kap. 4.2), egne CV-er og egne referanser. Se kortlisten nederst. Avtale om underleverandør eller samarbeid før 10.12. |
| **Juristen** | Leser avtaleutkastet (SSA-vilkår, ansvar, dagbøter) og eventuelle forbehold. Avgjør om forbehold kan tas. |
| **Agentene** | Førsteutkast til kap. 1–8 fra gjenbruksmaterialet, kravmatrise mot grunnlaget og sjekk mot «leveranseklar». Sender aldri noe. |

## Kapitlene

| # | Kapittel | Innhold | Skriver | Gjenbruk (drift) | Status |
|---|---|---|---|---|---|
| 0 | **Tilbudsbrev** | Bindende tilbud, vedståelse (100 dager), aksept av SSA uten forbehold og vedleggsliste | Nithu (agent lager utkast) | `anbud/tilbudsmaler/tilbudsbrev.md` | Malen finnes. Bruk NBs eget skjema hvis det finnes. |
| 1 | **ESPD og kvalifikasjon** | Firmaattest, skatteattest, kredittvurdering A (≤ 6 mnd) og avvisningsgrunner | Nithu og agent | `anbud/espd.md`, `anbud/attester/`, `anbud/dps/kreditt.md`, `anbud/egenerklaring-lonn-arbeidsvilkar.md` | **Kredittvurderingen mangler** (drift#190). Skatteattesten må forklares hvis mva-saken (drift#353) gir restanser. |
| 2 | **Om oss** | Hvem vi er, Solar Digital, team med partner, og hvorfor små og raske | Agent (utkast), Nithu godkjenner | `markedsforing/profil-2027.md` (utkast), firmabeskrivelsen i `dps-soknad/` | Profilen er et utkast og ikke godkjent av Nithu. |
| 3 | **Oppdragsforståelse** | NBs nettsteder (nb.no, bibliotekutvikling.no, tibi.no), WordPress, samarbeid med NBs egne utviklere (Nettbiblioteket), brukerhistorier sammen med kunden og enhetlig brukeropplevelse | Tintun | Kunngjøringen. Bilag 1 og 2 i grunnlaget (`UNKNOWN` til nedlastet). | Skrives når bilag 2 (porteføljen) er lest. |
| 4 | **Løsning og metode** | 4.1 smidig metode og samarbeid · 4.2 design, UX og universell utforming (partner) · 4.3 integrasjoner og videreutvikling · 4.4 forvaltning, drift og sikkerhetsoppdateringer i WordPress · 4.5 overlevering og dokumentasjon | Tintun (4.1, 4.3–4.5), partner (4.2), Alper (4.3) | `anbud/dps/brreg-smidige-metoder-svar.md`, `brreg-arkitektur-svar.md`, `brreg-testing-svar.md`, `sikkerhet/tilgjengelighet.md` (UU, utkast) | **Hull:** ingen av oss har WordPress eller PHP i CV-en. Partneren må dekke WordPress, eller så må vi vise det på annen måte. |
| 5 | **Team, CV-er og nøkkelpersoner** | Roller (utvikler, integrasjon, designer, rådgiver) og tilgjengelighet | Hver person, med agent som redaktør | `anbud/cv/MAL.md`, `anbud/dps/cv/{alper,tintun,nithusan}.md` | Alpers CV er godkjent. Tintuns er et utkast. Nithus kan ikke brukes (samtykke). Partnerens CV-er kommer i tillegg. |
| 6 | **Kvalitet, sikkerhet og personvern** | Kvalitetssystem, informasjonssikkerhet (NSM-prinsippene), personvern og databehandleravtale, og HMS | Tintun | `anbud/kvalitetssystem/tilbudstekst.md` (v0.9, ikke klar), `anbud/informasjonssikkerhet/tilbudstekst.md` (**godkjent 30.10**), `anbud/hms-internkontroll.md`, `sikkerhet/`, `juridisk/databehandleravtale-utkast.md` | Kvalitetsteksten venter på v1.0 (drift#31). DPA-en er et utkast (drift#19). |
| 7 | **Referanser** | 2–3 oppdrag med kontaktperson, gjerne offentlige og gjerne nettsted eller WordPress | Alper og partner | drift#41, Alpers CV | **Hull:** selskapet har ingen egne referanser. Spør NB (spørsmål 5 i kravmatrisen) om nøkkelpersonellets referanser godtas. Partnerens referanser kan bære WordPress og design. |
| 8 | **Miljø og bærekraft** (hvis etterspurt) | Miljøtiltak | Agent | `anbud/miljo/miljo-og-baerekraft.md` | Finnes. |
| 9 | **Pris** | Timepriser per rolle i NBs prisskjema, eventuelle rabatter og reiser (Mo i Rana) | Nithu | `anbud/tilbudsmaler/prisliste.md` | **Timepris er ikke satt** (avgjort 18.10). Avtal partnerens pris før 10.12. |
| 10 | **Forbehold og avtale** | Eventuelle forbehold mot SSA, underleverandørerklæring for partneren | Juristen og Nithu | Avtaleutkastet i grunnlaget | Helst ingen forbehold (de kan gi avvisning). |
| — | **Sluttsjekk** | Alle vedlegg er med (ingen ettersending), signatur, levert før kl. 12 | Agent og Nithu | `anbud/leveranseklar-sjekkliste.md` | Bruk lista dagen før. |

## Rekkefølge og datoer (forslag)

| Dato | Hva |
|---|---|
| Så snart som mulig | Mercell-tilgang (MNO-169100). Last ned grunnlaget og legg det i Drive «04 Anbud / Nasjonalbiblioteket 2026-9514». |
| 24.11 | Agentene sammenholder grunnlaget med denne lista og kravmatrisen. Kap. 1, 2, 6 og 8 kommer som utkast. Velg designpartner. |
| 27.11 | Partneren har bekreftet. Kap. 3–5 og 7 er utkast. Prisen er avklart. |
| **02.12** | Spørsmålene sendes i Mercell (frist 03.12 kl. 12). |
| 07.12 | Alt er inne. Juristen har lest avtalen. Sluttsjekk. |
| **09.12** | Nithu signerer og leverer, én dag før fristen. |

## Mulige designpartnere (kortliste)

Bare offentlige kilder. Ingen er kontaktet. Organisasjonsnumrene er sjekket mot Enhetsregisteret.

Kildene er Doffins åpne API, data.brreg.no og byråenes og kundenes egne nettsider. Alle organisasjonsnumre er aktive, uten konkurs eller avvikling, og adressen stemmer med byråets egen side. Antall ansatte er `antallAnsatte` i Brønnøysund og kan være gammelt.

| # | Byrå | Nettside | Org.nr | Ansatte | Hvorfor de passer | Risiko |
|---|---|---|---|---|---|---|
| 1 | **Gnist Design AS** (Tromsø) | gnistdesign.no | 998675472 | 8 | WordPress-spesialist med egen tjeneste for universell utforming og tilgjengelighetserklæring. Har laget nettstedet til Perspektivet Museum med UX, design og profil (https://gnistdesign.no/referanse/perspektivet-museum/) og vant Holbergprisens nettsted for UiB (Doffin 2022-605466). | Utvikler WordPress selv og kan derfor by alene. Langt fra Oslo, men NB er også i Mo i Rana. |
| 2 | **Riktig Spor Bodø AS** (Bodø) | riktigspor.no | 925372811 | 12 | Design- og kommunikasjonsbyrå som bygger i WordPress. Har laget nettstedet til Helgeland Museum (https://riktigspor.no/arbeid/helgeland-museum/) og en kunnskapsbase for Salten-kommunene. Holder til i Nordland. | Få detaljer i referansene, og universell utforming er ikke dokumentert. Det finnes tre selskaper i konsernet (holding 992248661, Narvik 921828306), så det må avklares hvilket som signerer. |
| 3 | **Frontkom AS** (Fredrikstad) | frontkom.com | 921548826 | 39 | Vant Forbrukertilsynets nettsted (Doffin 2021-303689), som fortsatt går på WordPress med Frontkoms Gutenberg-blokker. Har flere offentlige kunder (https://frontkom.com/cases/distriktssenteret-byggeklosser-som-gir-redaksjonen-kontroll). | Øverst i størrelsesspennet og leverer alt selv, så de er en sannsynlig konkurrent. Nyere oppdrag bruker Sanity/Next.js. |
| 4 | **Copyleft Solutions AS** (Oslo) | copyleft.no | 982116252 | 14 | Vant kunstkultursenteret.no for Nord universitet (Doffin 2022-307374), som går på WordPress. Org.nr står på deres egen side. | Mest et utviklerhus uten dokumentert UX eller universell utforming. De dekker WordPress, men ikke design. |
| 5 | **Dinamo AS** (Oslo) | dinamo.no | 921294751 | 27 | Har hatt designavtaler med Norad, IMDi, Jernbanedirektoratet og Valgdirektoratet, og har laget klimaoslo.no i WordPress (Doffin 2023-642595). | Avtalene ble vunnet av forgjengeren DINAMO AS (976965043), som gikk konkurs 20.09.2023. Det er usikkert om referansene kan brukes. Merkevarebyrå uten dokumentert universell utforming. |

**Anbefaling (data-1):** Gnist Design (1) er den beste matchen. De har både WordPress og universell utforming, er små og har offentlige kulturkunder. Riktig Spor (2) er nummer to og har nærhet til Mo i Rana. Frontkom (3) er mer sannsynlig en konkurrent enn en partner. Copyleft (4) dekker WordPress, men ikke design.

**Konkurrenter og konflikter, viktig:**
- **Dekode Interaktiv AS** (894928662, 29 ansatte) er trolig dagens utvikler for NB. Det tyder tekniske spor på nb.no og bibliotekutvikling.no på: Dekodes `dekode-gtm-plugin` og T2-blokkbiblioteket. Dekode har også vunnet WordPress-avtalene for DSS, Riksantikvaren, LDO og Lotteritilsynet. **Regn dem som hovedkonkurrenten.**
- **NewsLab AS** vant NBs avtale om design og markedsføring i 2024 (Doffin 2024-113566). **Melkeveien designkontor** var med i samme konkurranse og kan by igjen.
- **Superultraplus Designstudio AS** vant NBs avtale om design av utgivelser i 2025 (Doffin 2025-112359).

**Ikke sjekket:**
- om WordPress-nettstedene over faktisk oppfyller WCAG
- om noen av byråene planlegger å by på 2026-117583 selv
- Doffin-tildelingene for Gnists andre offentlige referanser (UNIS, NILU, Framsenteret)

Ingen er kontaktet. Kontakt tas først når Nithu har sagt ja.

## Forbehold

- Kapittelstrukturen er `ASSUMPTION` til konkurransegrunnlaget er lest.
- Gjenbruksfilene er utkast der det står det. Ingenting er godkjent som tilbudstekst uten at eieren har sagt ja.
- Datoene er et forslag fra data-1, ikke en avtalt plan.
