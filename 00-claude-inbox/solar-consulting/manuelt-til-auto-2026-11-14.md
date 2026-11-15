# Manuelt til auto: 48 saker som venter på et menneske

learning-1 · 14.11.2026 · bare lest fra GitHub, Brreg og GitHub-API (org-medlemmer). Klassifiseringen bygger på saksteksten og de tre siste kommentarene per sak.
Klasser: **a** = en agent eller plattformen gjør steget nå, **b** = ett trykk eller ett valg (teller som automatisert, orchestrator-1 14.11), **c** = må være manuell (BankID, signatur, betaling, juridisk vurdering, personlig arbeid).

## Kort

- **48 saker venter på et menneske** (ikke 50: to er lukket siden gaplisten ble laget).
  - **a: 6**: #62, #65, #71, #190, #208, #251
  - **b: 22**
  - **c: 19**
  - **UNKNOWN: 1**: #198 er en logg uten et steg som venter
- **Med ett-trykks-køen** (tools-1) teller a + b = **28 av 48 (58 %)** som automatisert. Til 80 % mangler 10 saker. De må flyttes fra c til b, og bare noen av c-sakene kan det.
- **Gjort i dag:**
  - **drift#257 Registervakt** (merget). Daglig Brreg-sjekk som lukker #208 og varsler #196. Nye vakter er én linje i JSON.
  - **#62 og #65 lukket.** De ventet bare på «lest».
  - **#31:** GitHub-2FA lest fra API-et. Alper har tre spørsmål færre.
- **Største gjenværende a krever en beslutning: e-postvakt.** #71 og #190, og svar fra KS (#13), Altinn (#251), Sikt (#14) og Digdir (#16), venter alle på en e-post. Uten lov til å lese en avgrenset del av innboksen forblir de manuelle. Se «Beslutning».
- **Deling:** admin-1 tar firma-økonomi og offentlige tilganger, 12 saker merket «(admin-1)» under. #208 ble merget før delingen kom, og admin-1 har fått beskjed.

## Hva som flytter mest mot 80 %

| Tiltak | Saker | Klasse nå → etter | Hvem | Status |
|---|---|---|---|---|
| Ett-trykks-kø i plattformen | alle 22 b | b teller først når køen finnes | tools-1 | pågår |
| E-postvakt: les bare e-post fra kjente avsendere, last opp vedlegg til Drive, lukk eller kommenter | #71, #190, #13, #14, #16, #251 | a (eller venter på svar) | learning-1, etter beslutning | **trenger ja** |
| Registervakt (Brreg) | #208, senere #236 steg 6 og #19 signatar | a | learning-1 → admin-1 | merget |
| Innsynsbrev som Gmail-utkast | #125 (8 brev) | c → b (ett trykk per brev) | admin-1 eller learning-1 | når juristen har godkjent malen (#210 punkt 1) |
| Juristens c-saker som ferdige utkast med ja/nei-spørsmål | #19, #21, #26, #105 | c → b | jurist-panen | forslag |
| Fylle ut Soalr-svar på forhånd (Nova, PPT) | #27 | b, raskere | learning-1 | kan tas |

## Oppdatering 14.11 kl. 16.30

- **E-postvakten er bygd og i drift** (drift#259, merget etter code-review med to blokkerende funn, rettet).
  - Den har fem vakter: #251, #13, #71, #190 og #14.
  - Den leser bare avsender, emne og DMARC-resultat. Den sender, sletter og merker ingenting.
  - Kommentaren i saken har bare domene og dato.
  - Den kjøres hvert 30. minutt fra drift-vakt.
- **Funnene er kommentert:**
  - **#105:** fristen er passert, og juristen er spurt.
  - **#1 og #210:** de sier ulikt om forsikringen, og #26 avgjør det.
  - **#14:** e-posten er sendt, og saken står nå som `venter:ekstern`. Svaret kommer trolig til Nithus personlige adresse, som vakten ikke ser.
  - **#8:** alt lukket av admin-1.
- **admin-1** har bygd scopevakten for #251 (drift#260).

## Ti c-saker som kan bli b (ett trykk)

Hvis alle ti flyttes, blir a + b **38 av 48 (79 %)**. Resten (#47, #48, #50, #126, #206, #18, #236, #13 og #198) er betaling, hemmeligheter eller bankinnlogging og blir værende manuelle.

| # | Nå | Hva agenten forbereder | Trykket som gjenstår |
|---|---|---|---|
| #19 | Jurist leser hele DPA-en (1 t) | Høyst 8 ja/nei-beslutninger med anbefalt svar og henvisning til punkt i avtalen | Jurist krysser av |
| #21 | Jurist vurderer SCC mot TIA | Kort TIA-utkast med anbefaling | Jurist: ja eller nei |
| #26 | Jurist vurderer SSA-krav | Foreslått forsikringsbeløp og vurdering av ansvarsbegrensningen. Avgjør også motstriden i #1 | Jurist godkjenner |
| #105 | Fire åpne spørsmål | Foreslått svar på hvert spørsmål med kilde i AUP-teksten | Jurist krysser av |
| #20 | Nithu leser Anthropic Console | Avtalepart og ZDR-vilkår fra Anthropics offentlige vilkår | Nithu bekrefter én verdi i Console |
| #42 | Alper skriver CV | CV fylt ut fra offentlig profil og git-historikk, med samtykke | Alper godkjenner |
| #41 | Alper finner referanser | Tre kandidater med ferdig tekst | Alper velger |
| #7 | Fire felt og tre signaturer | Feltene fylt ut, dokumentet klart for e-signering | Én BankID-signatur hver |
| #6 | Last ned årsregnskapet fra DNB | Tallene for 2023–2025 ligger åpent i Brregs regnskapsregister (FACT: API-et svarer 200 for 931949837, 14.11). Trengs PDF-kopi, bestilles den fra Brreg | Ingen, eller én bestilling. Kan bli **a** (admin-1 sin sak) |
| #72 | Tre innstillinger i admin-konsollen | Direkte lenke til hver innstilling. Etterpå sjekker vi med `sc tilgang` (2FA) | Nithu: tre brytere i én økt |

De fire første er juristens. De passer for jurist-panen og ikke for meg, fordi forslagene må være juridisk forsvarlige.

## Resultat av c→b (14.11 kl. 16.45)

Det er postet ferdige forslag i alle ti sakene, og #6 er lukket av admin-1.

- **`bare-godkjenning`**: #19, #21, #26 og #105, de fire juristsakene. De har nå `jurist` + `klar-for-nithu`, og Nithu svarer `avgjør N: ok`, `endre` eller `til jurist`.
- **Ett trykk, men ikke bare godkjenning** (derfor uten etiketten):
  - #20: én verdi leses av i Console etter innlogging.
  - #72: tre brytere med direkte lenker.
- **Fortsatt ikke ett trykk** (ærlig merket):
  - #42: Alper må svare på 5 spørsmål. Repoet har for lite om ham.
  - #41: verdi, kontaktperson og periode må fylles inn.
  - #7: tre BankID-signaturer, og tjenesten for e-signering er ikke valgt.

**Andel a + b av 48:**
| Måling | Antall | Andel |
|---|---|---|
| Streng: a, b og de fire med `bare-godkjenning`. #8 og #16 er lukket | 34 av 48 | **71 %** |
| Med #20 og #72 | 36 av 48 | **75 %** |
| Mål | | 80 % |

Det som står igjen, er manuelt med vilje:
- betaling og abonnement: #47
- Azure-tilganger og hemmeligheter: #48, #50, #126 og #206
- nøkkel: #18
- bankinnlogging: #236
- innlogging i Fiks: #13
- personlig input: #41, #42 og #7

Til 80 % mangler 2–3 saker. Mest realistisk er å velge en tjeneste for BankID-signering, så #7 blir ett trykk hver, og at Alper svarer på #42 én gang.

## Beslutning (til orchestrator-1 og Nithu), avgjort 14.11: ja, bare lesing

**E-postvakt: skal broen få lese e-post fra en fast liste med avsendere?** Det gjelder bare bestemte domener (microsoft.com, creditsafe, altinn.no, ksdigital.no, sikt.no, digdir.no). Den sender aldri, og den sletter aldri.

- **Ja:** 6 saker går fra å vente på at et menneske leser innboksen til at agenten melder fra og lukker. Det er den største enkeltgevinsten som er igjen.
- **Nei:** sakene står som de står, og den som leser e-posten, skriver svaret i saken.
- Gaplisten sier: «E-post og deling er forbudt for agentene.» Lesing av utvalgte avsendere er derfor en ny tillatelse, og den gis ikke av en agent.

## Saker å sjekke før noen handler (funn fra gjennomgangen)

- **#105:** fristen 12.11 er passert uten svar fra juristen.
- **#1:** #210 og #1 sier ulikt om når forsikringen trengs (før DPS-fristen 22.11 eller ved første kontrakt).
- **#14:** trolig utdatert. #236 sier at svaret til Sikt ble sendt 14.11.
- **#8:** sjekken i DNB Regnskap er kanskje unødvendig, fordi Fiken sender EHF fra 1.1.2027 (#236).

## Alle saker

| # | Tittel | Hvem venter | Steget som venter | Klasse | Grunn |
|---|---|---|---|---|---|
| #251 | Systembruker Altinn tt02 | Nithu (venter på Altinn) | Svar fra Altinn, sjekke at tre scopes står på klienten, så «ja» | a (admin-1) | Scopene kan sjekkes med tokenkall i test-Maskinporten |
| #236 | Bytte til Fiken, årsoppgjør 2026 | Nithu | Steg 11: sjekke hvor ajour 2026 er i DNB Regnskap | c (admin-1) | Krever innlogging i DNB Regnskap (bank) |
| #210 | Klar for jurist (samleliste) | Jurist | Gå gjennom punkt 1–6 i rekkefølge (#125, #105, #26, #20/#21, #19, DPIA) | b | Samleliste; utkastene er klare, delsakene klassifiseres hver for seg |
| #208 | Næringskode til IT | Ingen (Brreg/SSB) | Vente på ny næringskode i Brreg; sjekk igjen 20.11 | a, vakt merget (#257) (admin-1) | Åpent Brreg-API kan leses og sjekkes jevnlig |
| #206 | Horizon-flytting | Nithu | Railway-app på org, ANTHROPIC_API_KEY-secret, «go» med tidspunkt | c | Eier må lage nøkkel og installere appen |
| #198 | Tintun-sync (logg) | Tintun | Står ikke i saken; det er en logg uten ventende steg | UNKNOWN | Ingen konkret handling ventes |
| #196 | Azure-kreditter | Nithu | Avgjøre søknad til Microsoft for Startups (venter på #71, #208) | b | Ett valg; selve søknaden krever personlig Microsoft-innlogging |
| #192 | DPS NTNU solceller | Nithu | «avgjør 192: ikke aktuell» eller «undersøk partner» | b | Ett valg, anbefaling er klar |
| #190 | Kredittvurdering Creditsafe | Nithu (venter på Creditsafe) | Rapporten kommer; laste den opp i bevisarkivet og lukke | a | Agent kan laste opp til Drive og lukke |
| #170 | Færder markedsdialog PPT | Nithu | Registrere på Hyyr, melde interesse, avgjøre hvem som deltar | b | Melde interesse er ett trykk; deltakerne er et valg |
| #126 | Beslutninger for eierne (samlet) | Nithu | HASTER: AUTH_SECRET i cockpit, gws-scope, logge inn i Horizon én gang | c | Hemmelighet, OAuth-samtykke og innlogging må gjøres av eier |
| #125 | Innsyn timepriser (8 brev) | Jurist, så Nithu | Jurist ser over malen, så sender Nithu 8 e-poster | b | Godkjenne ferdig utkast og trykke send |
| #105 | Anthropic AUP 12.11 | Jurist | Svare på fire åpne spørsmål, blant annet om høyrisiko-KI | c | Juridisk vurdering, ikke godkjenning av ferdig tekst |
| #99 | FORREGION Østfold | Nithu | «avgjør 99»: ansette noen og velge FoU-partner, eller ikke aktuell | b | Ett valg mellom ferdige alternativer |
| #98 | IN oppstartstilskudd 1 | Nithu | «avgjør 98»: Nova ja, og hvem tar kundesamtalene | b | Ett valg; samtalene og innsendingen etterpå er c |
| #72 | Google Workspace | Nithu | Admin-konsoll: reauth-unntak, godta DPA, 2-trinns (steg 3, 6, 7) | c | Flere innstillinger og avtalegodkjenning i admin-konsollen |
| #71 | Microsoft Partner adressebevis | Nithu (venter på Microsoft) | Følge med på godkjenning etter opplasting 14.11, så lukke | a | Statusen kan leses fra e-posten fra Microsoft |
| #66 | Investorliste | Nithu | «avgjør 66»: trenger vi egenkapital nå? | b | Ett valg, lista er klar |
| #65 | Kommunale næringsfond | Nithu | «ferdig 65»: liste lest; avgjørelsen ligger i #99 | a, lukket 14.11 | Ren kvittering, agent kan lukke med henvisning |
| #64 | SkatteFUNN | Nithu | «avgjør 64»: lønn og revisor, søk januar eller ikke aktuell | b | Ett valg, notatet er klart |
| #63 | Innovasjon Norge notat | Nithu | «avgjør 63»: søk OS1 for Nova eller ikke nå | b | Ett valg, overlapper #98 |
| #62 | Oversikt finansieringskilder | Nithu | «ferdig 62»: tabellen lest; valgene tas i #63–66 | a, lukket 14.11 | Ren kvittering, agent kan lukke med henvisning |
| #52 | Flytte Nithu0/Solar-Consulting | Nithu | Overføre repoet til org (etter #206) | b | Én bekreftelse i Danger Zone; resten gjør agentene |
| #50 | Key Vault | Tintun | Rulle ut infra, gi roller, legge inn hemmeligheter (etter #47) | c | Hemmeligheter og Azure-tilgang; venter på #47 |
| #49 | DPA og regioner | Nithu | Sette Vercel-region til arn1 på 2 prosjekter, godkjenne tabellen | b | Agent kan forberede API-kallet; prod-endring trenger trykk |
| #48 | Entra-testtenant | Tintun | Lage tenant, brukere og app (venter på #47) | c | Innlogging i Entra; venter på abonnement |
| #47 | Azure-abonnement | Nithu | Opprette pay-as-you-go med kort, budsjett, RG, gi Tintun tilgang | c | Betaling og kontoinnlogging |
| #46 | Prisliste og tilbudsmaler | Nithu (og eierne) | «avgjør 46»: prismodell og timepriser, eller vent på #125 | b | Ett valg, malene er klare |
| #45 | Miljødokumentasjon | Alper | Bekrefte at én side om arbeidsform stemmer | b | Godkjenne ferdig utkast |
| #42 | CV-er | Alper | Skrive egen CV i malen med samtykke | c | Å skrive CV er personlig arbeid |
| #41 | Referanseprosjekter | Alper | Liste 1–3 IT-prosjekter som kan bli referanser | c | Krever personlig kunnskap og kontakt med kunder |
| #37 | ESPD | Alper | Lese del III (utelukkelsesgrunner), svare «ferdig 37» | b | Én bekreftelse; utkastet er klart |
| #31 | Kvalitetssystem | Alper | Svare ja/nei på 2FA, passordhåndterer og kryptert disk | b | Tre ja/nei; GitHub-2FA kan leses fra API-et |
| #27 | Bruksvilkår Soalr | Nithu, så jurist | Svare: hva er Soalr, første produkt, første kunder | b | Korte svar; agent kan forhåndsutfylle (Nova, PPT) |
| #26 | SSA-avtaler | Jurist | Forsikringskrav og om ansvarsbegrensningen er akseptabel | c | Juridisk risikovurdering, ca. 30 min |
| #22 | Personvernerklæring | Nithu | «avgjør 22: 12 mnd, B, personvern@…» (tre valg) | b | Agentens forslag ligger klart; ett svar |
| #21 | Overføring til USA | Jurist | Holder SCC alene, eller trengs TIA? | c | Juridisk vurdering |
| #20 | Underdatabehandlere | Nithu + jurist | Nithu leser avtalepart og ZDR i Anthropic Console; jurist velger frister | c | Console-innlogging; jurist-delen alene ville vært b |
| #19 | Databehandleravtale | Jurist | Lese hele utkastet og kommentere (ca. 1 t) | c | Grundig juridisk gjennomlesning |
| #18 | Doffin API-nøkkel | Nithu | Registrere i DFØ-portalen, legge nøkkelen i Railway | c (admin-1) | Nøkkelen må lages og limes inn av et menneske |
| #16 | Virksomhetssertifikat | Nithu | Sende ferdig e-post til servicedesk@digdir.no | b (admin-1) | Teksten er klar, bare send |
| #15 | FINT/Novari | Tintun | Skrive beslutning og status i fint.md (agent tilbyr utkast) | b (admin-1) | Agent skriver utkast, Tintun godkjenner |
| #14 | Feide hos Sikt | Nithu | Sende ferdig e-post til kontakt@sikt.no | b (admin-1) | Teksten er klar, bare send (trolig gjort, se 4) |
| #13 | KS Fiks-testtilgang | Nithu (venter på KS) | KS svarer (ref. 169279), så bytte aktør eller sette opp integrasjon | c (admin-1) | Neste steg er innlogging i Fiks forvaltning |
| #8 | EHF-fakturering | Nithu | Sjekke EHF i DNB Regnskap, lage og validere testfaktura | c (admin-1) | Krever innlogging i DNB Regnskap |
| #7 | HMS-egenerklæring | Nithu + alle tre | Fylle fire felt, alle tre signerer verneombudsavtalen | c (admin-1) | Signatur fra alle tre |
| #6 | Regnskap og øk. dok. | Nithu | Laste ned årsregnskap 2025 som PDF fra DNB Regnskap | c (admin-1) | Krever innlogging i DNB Regnskap |
| #1 | Ansvarsforsikring | Nithu | Sende tilbudsforespørsel til 2–3 selskaper, eller «vent» | b (admin-1) | Teksten er klar, bare send eller velg |

## Oppdatering 15.11: det som ble gjort for hånd i dag, og de 5 som gir mest

Kilde: feed.md 15.11 og sakene den viser til. Målt med regelen om `bare-godkjenning`: bare et godkjenningstrykk er igjen for mennesket.

**Gjort for hånd i dag (agenter og mennesker)**
| Hva | Hvem | Saker |
|---|---|---|
| DPS-er undersøkt én og én: Brreg, Flytoget og Tromsø (krav, frister, plattform) | trading-1, admin-1 | #136, #149, #297, #300, #301 |
| Mercell: tilgang ordnet og frist lagt inn | Nithu (innlogging), admin-1 | #136, #295 |
| Drive-strukturen bygd (71 mapper), filer lastet opp og sortert | tools-1 | — |
| QA av hver PR: eksterne lenker, åpne saker, persondata | paal-1 | #295, #296, #301 |
| Registervakten kjørt for hånd, fordi GitHubs tidsplan var 7 timer forsinket | admin-1 | #208 |
| Vipps-søknad, Railway-invitasjon, GitHub Team | Nithu | c (betaling og innlogging) |

**De 5 som gir mest**
| # | Automatisering | Fjerner | Trykket som gjenstår | Avhenger av | Omfang |
|---|---|---|---|---|---|
| 1 | **DPS-vakt:** finner nye kunngjøringer som passer oss (CPV og stikkord), lager en sak med krav og frist, og fyller ut svarutkast fra svarbiblioteket (`anbud/dps/`) | Manuell undersøkelse av hver DPS (3 i dag) | Nithu: «søk» (innsendingen i Mercell eller TendSign er c) | Doffin-nøkkel (#18, c), eller lesing fra offentlige sider | 1 dag |
| 2 | **QA-sjekk i drift-CI:** eksterne lenker (200), `#N`-referanser finnes, mønstre for persondata (fnr, telefon, privat e-post), og regnskapstall i issues og filer | paal-1 sin faste manuelle sjekk på hver PR | Ingen. PR-en er grønn eller rød | Actions-minutter (lite) | 0,5 dag |
| 3 | **Drive-sortering:** broen foreslår mappe i 00–09-strukturen for nye filer (etter navn og type) og flytter når noen trykker. Aldri sletting | Manuell sortering og opplasting | «Flytt» i plattformen | Mappe-ID-lista til tools-1 | 1 dag |
| 4 | **Vakter som ikke er avhengige av GitHubs tidsplan:** registervakten og fristvakten kjøres også fra drift-vakt-timeren på PC-en én gang i døgnet, med samme merke mot dobbel skriving | Manuelle kjøringer når tidsplanen er forsinket | Ingen | — | 1–2 t |
| 5 | **Mercell- og innkjøpsoppfølging:** frister for fornyelse og opptak, og «ny melding i Mercell» via e-postvakten (avsender mercell.com) | At noen må huske å sjekke Mercell | Nithu åpner meldingen | E-postvakten (#259) | 1 t |

Dagsrapporten er utelatt med vilje. Den er alt fordelt i oppdraget for neste uke (16.11).

Anbefalt rekkefølge: 4 og 5 først (små, og bruker det som alt finnes), så 2, så 1 og 3. learning-1 kan ta 4, 5 og 2 med det samme hvis orchestrator-1 sier ja.
