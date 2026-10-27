# Databehandleravtale: standardmal for Solarconsulting AS

**Status: UTKAST. Ikke juridisk gjennomgått. Må leses av jurist før bruk.**

Utarbeidet 2026-10-18. Versjon 0.1. Eier: [SIGNATURBERETTIGET ETTER EIERSKIFTET].

## Hva som må fylles ut / avklares

1. **Org.nr. for Solarconsulting AS.** UNKNOWN. Plassholder `[ORG.NR]` står overalt.
2. **Hvem som er signaturberettiget etter eierskiftet i uke 43 2026.** UNKNOWN. Sjekk Brønnøysundregistrene etter at endringen er registrert. Avtaler som signeres før registreringen er på plass, må signeres av den som faktisk har signaturrett den dagen.
3. **Faktisk hosting-region i Azure.** UNKNOWN. Malen forutsetter EU/EØS-region (for eksempel Norway East eller Sweden Central). Sjekk hvilke ressursgrupper som faktisk står hvor før vi skriver det inn i Bilag 1 og 3.
4. **Avtalepart hos Anthropic og hvilken plan vi er på.** UNKNOWN. Anthropics vilkår sier at kunder i EØS kontraherer med Anthropic Ireland, Limited [5]. Vi må bekrefte at kontoen vår er en kommersiell konto (API/Console, Team eller Enterprise) og ikke en forbrukerkonto, og at DPA-en er akseptert for vår organisasjon.
5. **Hvor Anthropic behandler dataene.** UNKNOWN. Anthropics DPA sier ikke noe om lagringssted, bare at overføringer reguleres av SCC [6]. Ikke lov kunden EU-lagring for Claude-kall.
6. **Anthropics status under EU–US Data Privacy Framework.** UNKNOWN. Vi fant ikke Anthropic i noe søk 2026-10-18, og DPA-en nevner ikke DPF [6]. Vi støtter oss derfor på SCC.
7. **Microsofts status under DPF og gjeldende DPA-versjon.** UNKNOWN. Ikke verifisert i dag. Last ned gjeldende Microsoft DPA og sjekk dataprivacyframework.gov før første tilbud.
8. **Forsikring.** UNKNOWN. Har vi ansvarsforsikring (profesjonsansvar/cyber)? Det påvirker hvilket ansvarstak vi tør å akseptere i punkt 13.
9. **Varslingskontakt.** Hvem er avvikskontakt med telefonnummer som faktisk blir besvart, også i ferier? `[AVVIKSKONTAKT]`.
10. **Railway og Vercel.** Brukes i dag til egne prosjekter (ASSUMPTION). Anbefaling: ingen kundedata der. Sjekk at det stemmer i praksis før vi skriver det i Bilag 3.

## Når malen brukes, og når den ikke brukes

- Malen brukes når Solarconsulting AS behandler personopplysninger **på vegne av** en kunde. Kunden er da behandlingsansvarlig og vi er databehandler. GDPR art. 28 nr. 3 krever en skriftlig avtale (elektronisk holder) med bestemte minimumselementer [1] (art. 28 nr. 9). FACT.
- GDPR gjelder som norsk lov gjennom personopplysningsloven [3]. FACT.
- **Kundens mal går foran vår.** Mange offentlige oppdragsgivere har sin egen databehandleravtale. Det gjelder særlig når oppdraget går på Statens standardavtaler (SSA), der oppdragsgiver ofte legger ved en egen databehandleravtale. ASSUMPTION: at DFØ/anskaffelser.no har en egen mal knyttet til SSA kunne vi ikke bekrefte med direkte kilde 2026-10-18 (UNKNOWN: navn, versjon, URL). Vi fant kommunale eksempler på anskaffelser.no, blant annet fra Ålesund og Hamar [12]. Hvis kunden har en mal, signerer vi den etter en gjennomgang, og vår mal brukes ikke. Vår mal er reserveløsningen når kunden ikke har noe.
- Det er ikke alltid nødvendig med databehandleravtale. Veiledende bilag til SSA-S 2026 nevner at oppdrag der kontaktopplysninger bare brukes for å levere tjenesten, ikke nødvendigvis krever det [11]. FACT (fra kilden). Om vi faktisk er databehandler, må vurderes per oppdrag. Hvis vi bestemmer formål og midler selv, er vi behandlingsansvarlig for den delen [1] (art. 28 nr. 10).
- Ved bruk sammen med SSA bør avtalen regulere rangordningen mellom dokumentene [10]. Det gjør punkt 13.2 under.
- Datatilsynet sier at jo mer omfattende, inngripende eller risikofylt behandlingen er, desto mer konkret må avtalen være [4]. FACT. For AI-oppdrag med sensitive data holder ikke denne minimumsmalen alene. Da må Bilag 1 og 2 skrives konkret for oppdraget.

---

# DATABEHANDLERAVTALE

etter personvernforordningen (GDPR) artikkel 28

**mellom**

**[KUNDE]**, org.nr. [KUNDE ORG.NR], [adresse]
(heretter «Behandlingsansvarlig»)

**og**

**Solarconsulting AS**, org.nr. [ORG.NR], [adresse]
(heretter «Databehandler»)

Knyttet til hovedavtale: [HOVEDAVTALE, f.eks. «SSA-K / oppdragsavtale av [DATO], ref. [SAKSNR]»] (heretter «Hovedavtalen»).

## 1. Formål og omfang

1.1 Avtalen regulerer Databehandlers behandling av personopplysninger på vegne av Behandlingsansvarlig i forbindelse med leveransene etter Hovedavtalen.

1.2 Hva som behandles, hvorfor, om hvem og hvor lenge, står i **Bilag 1**. Databehandler skal ikke behandle personopplysninger utover det som står der.

1.3 Begreper i avtalen har samme betydning som i personvernforordningen (GDPR), slik den gjelder i Norge gjennom personopplysningsloven.

## 2. Instruks

2.1 Databehandler skal bare behandle personopplysningene etter dokumenterte instrukser fra Behandlingsansvarlig. Avtalen, Bilag 1 og skriftlige instrukser gitt senere (e-post holder) utgjør instruksen. Dette gjelder også overføring til land utenfor EU/EØS.

2.2 Hvis norsk rett eller EU-retten pålegger Databehandler å behandle opplysningene på annen måte, skal Databehandler si fra til Behandlingsansvarlig før behandlingen starter, med mindre loven forbyr slik varsling.

2.3 Databehandler skal straks si fra hvis Databehandler mener at en instruks er i strid med personvernregelverket.

2.4 Databehandler skal ikke bruke personopplysningene til egne formål. Det gjelder også trening, finjustering eller forbedring av egne eller tredjeparters KI-modeller, med mindre Behandlingsansvarlig skriftlig har gitt instruks om det.

## 3. Taushetsplikt

3.1 Alle som behandler personopplysningene på vegne av Databehandler, skal ha skrevet under på en taushetserklæring eller være underlagt lovbestemt taushetsplikt.

3.2 Taushetsplikten gjelder også etter at avtalen eller arbeidsforholdet er avsluttet.

3.3 Bare personer som trenger tilgang for å utføre oppdraget, skal få tilgang.

## 4. Sikkerhet

4.1 Databehandler skal gjennomføre de tekniske og organisatoriske tiltakene som kreves etter GDPR artikkel 32, ut fra risikoen ved behandlingen. Minimumstiltakene står i **Bilag 2**.

4.2 Databehandler skal vurdere tiltakene på nytt ved vesentlige endringer i behandlingen, og ellers minst en gang i året.

4.3 Databehandler kan endre tiltakene, men bare slik at sikkerhetsnivået ikke blir lavere.

## 5. Underdatabehandlere

5.1 Behandlingsansvarlig gir med denne avtalen generell skriftlig tillatelse til at Databehandler bruker underdatabehandlerne i **Bilag 3**.

5.2 Før Databehandler tar i bruk en ny underdatabehandler eller bytter ut en eksisterende, skal Behandlingsansvarlig varsles skriftlig minst 30 dager i forveien. Behandlingsansvarlig kan protestere innen fristen. Ved protest skal partene forsøke å finne en løsning. Finner de ingen, kan Behandlingsansvarlig si opp den delen av Hovedavtalen som berøres, uten kostnad.

5.3 Databehandler skal pålegge underdatabehandlere de samme personvernforpliktelsene som følger av denne avtalen, gjennom en skriftlig avtale. Det skal gi tilstrekkelige garantier for at tekniske og organisatoriske tiltak gjennomføres.

5.4 Databehandler har fullt ansvar overfor Behandlingsansvarlig for at underdatabehandlere oppfyller sine forpliktelser.

## 6. Overføring til land utenfor EU/EØS

6.1 Personopplysninger skal ikke overføres til eller gjøres tilgjengelige fra land utenfor EU/EØS uten at det står i Bilag 1 eller Bilag 3, eller Behandlingsansvarlig skriftlig har godkjent det.

6.2 Slik overføring krever et gyldig grunnlag etter GDPR kapittel V, for eksempel en beslutning om tilstrekkelig beskyttelsesnivå (art. 45) eller EU-kommisjonens standard personvernbestemmelser (art. 46 nr. 2 bokstav c). Grunnlaget for hver underdatabehandler står i Bilag 3.

6.3 Databehandler skal på forespørsel bistå Behandlingsansvarlig med informasjon som trengs for en vurdering av overføringen (transfer impact assessment).

## 7. Bistand med de registrertes rettigheter

7.1 Databehandler skal, så langt det er mulig og ut fra hva slags behandling det er, hjelpe Behandlingsansvarlig med å svare på henvendelser fra registrerte som vil bruke rettighetene sine etter GDPR kapittel III (innsyn, retting, sletting, begrensning, dataportabilitet, protest).

7.2 Får Databehandler en slik henvendelse direkte, skal den sendes videre til Behandlingsansvarlig innen tre virkedager. Databehandler skal ikke svare den registrerte selv uten instruks.

## 8. Bistand med sikkerhet, avvik, DPIA og forhåndsdrøftelser

8.1 Databehandler skal hjelpe Behandlingsansvarlig med å oppfylle pliktene i GDPR artikkel 32 til 36, ut fra hva slags behandling det er og hvilken informasjon Databehandler har. Det omfatter sikkerhet ved behandlingen, melding om avvik til Datatilsynet og varsling av de registrerte, vurdering av personvernkonsekvenser (DPIA) og forhåndsdrøftelser med Datatilsynet.

8.2 For oppdrag som bruker KI-modeller, skal Databehandler på forespørsel gi en beskrivelse av hvilke modeller og tjenester som brukes, hvilke data som sendes til dem, og hvor lenge leverandøren lagrer dem. Beskrivelsen kan brukes i DPIA-en.

8.3 Bistand utover det som er rimelig i oppdragets omfang, kan faktureres etter timeprisene i Hovedavtalen. Bistand med avvik som skyldes Databehandler, faktureres ikke.

## 9. Varsling av avvik

9.1 Databehandler skal varsle Behandlingsansvarlig uten ugrunnet opphold etter å ha blitt kjent med et brudd på personopplysningssikkerheten. **Målet er varsling innen 24 timer.** Varslet sendes til kontaktpersonen i punkt 15.

9.2 Varslet skal så langt mulig beskrive hva som har skjedd, hvilke kategorier og omtrent hvor mange registrerte og opplysninger som er berørt, sannsynlige konsekvenser, og hvilke tiltak som er satt i verk eller foreslås. Informasjon som ikke er klar ennå, kan ettersendes.

9.3 Det er Behandlingsansvarlig som melder avviket til Datatilsynet og eventuelt varsler de registrerte. Databehandler skal ikke gjøre det uten skriftlig avtale med Behandlingsansvarlig.

9.4 Databehandler skal dokumentere alle avvik, også de som ikke ser ut til å ha konsekvenser.

## 10. Revisjon og innsyn

10.1 Databehandler skal gi Behandlingsansvarlig all informasjon som trengs for å vise at pliktene i denne avtalen og GDPR artikkel 28 er oppfylt.

10.2 Databehandler skal legge til rette for og bidra til revisjoner, også inspeksjoner, som utføres av Behandlingsansvarlig eller en uavhengig revisor Behandlingsansvarlig har gitt fullmakt. Revisor skal ha taushetsplikt.

10.3 Revisjon varsles minst 30 dager i forveien, med mindre det skyldes et avvik eller krav fra en tilsynsmyndighet. Behandlingsansvarlig dekker egne kostnader. Databehandlers tidsbruk utover én arbeidsdag per år kan faktureres, med mindre revisjonen avdekker vesentlige brudd på avtalen.

10.4 For underdatabehandlere kan Databehandler oppfylle innsynsplikten ved å legge fram underdatabehandlerens tredjepartsrapporter (for eksempel SOC 2 eller ISO 27001) eller tilsvarende dokumentasjon.

## 11. Varighet

11.1 Avtalen gjelder fra signering og så lenge Databehandler behandler personopplysninger for Behandlingsansvarlig, også etter at Hovedavtalen er avsluttet.

11.2 Avtalen kan ikke sies opp alene mens Hovedavtalen gjelder.

## 12. Sletting og tilbakelevering ved opphør

12.1 Når leveransene er ferdige, skal Databehandler etter Behandlingsansvarligs valg slette eller levere tilbake alle personopplysninger og slette eksisterende kopier. Valget meldes skriftlig. Er det ikke meldt innen 30 dager etter opphør, slettes opplysningene.

12.2 Sletting og tilbakelevering skal være gjennomført innen 30 dager etter at valget er meldt, eller etter at fristen i 12.1 er gått ut. Dette gjelder også hos underdatabehandlere, innenfor de slettefristene som følger av deres vilkår (se Bilag 3).

12.3 Sikkerhetskopier som ikke kan slettes enkeltvis, slettes når de roterer ut, senest innen [35] dager. Til da skal de ikke brukes til noe annet.

12.4 Databehandler skal på forespørsel bekrefte skriftlig at slettingen er gjennomført.

12.5 Plikten gjelder ikke hvis lov krever at opplysningene lagres. Da skal Databehandler opplyse om hvilket krav det er.

## 13. Ansvar og forholdet til Hovedavtalen

13.1 Ansvar for brudd på denne avtalen reguleres av Hovedavtalens bestemmelser om mislighold, erstatning og ansvarsbegrensning. Det gjelder ikke der GDPR artikkel 82 eller annen ufravikelig lov sier noe annet.

13.2 Ved motstrid går denne avtalen foran Hovedavtalen i spørsmål om behandling av personopplysninger. Er Behandlingsansvarligs egen databehandleravtale eller personvernvilkår avtalt, går de foran denne avtalen.

13.3 Endringer i avtalen og bilagene skal være skriftlige og signert av begge parter. Bilag 3 kan likevel endres etter prosessen i punkt 5.2.

## 14. Lovvalg og verneting

14.1 Avtalen reguleres av norsk rett.

14.2 Tvister skal først forsøkes løst gjennom forhandlinger. Lykkes ikke det, avgjøres tvisten av de ordinære domstolene, med [Behandlingsansvarligs hjemting / Oslo tingrett] som avtalt verneting. Har Hovedavtalen en annen tvisteløsningsordning, gjelder den.

## 15. Kontaktpersoner

| | Behandlingsansvarlig | Databehandler |
|---|---|---|
| Avtaleansvarlig | [NAVN, e-post, tlf.] | [NAVN], [e-post], [tlf.] |
| Personvern/avvik | [NAVN / personvernombud] | [AVVIKSKONTAKT], [e-post], [tlf.] |

## 16. Signatur

Avtalen er signert elektronisk eller i to eksemplarer, ett til hver part.

| For [KUNDE] | For Solarconsulting AS |
|---|---|
| Sted/dato: [DATO] | Sted/dato: [DATO] |
| Navn: | Navn: [SIGNATURBERETTIGET] |
| Stilling: | Stilling: |

---

# Bilag 1: Beskrivelse av behandlingen

Fylles ut per oppdrag. Kursivert tekst i høyre kolonne er eksempler fra et typisk KI-/dataoppdrag. Slett eksemplene og skriv det som faktisk gjelder.

| Felt | Utfylling |
|---|---|
| Oppdrag | [Kort navn, ref. Hovedavtalen]. *Eksempel: Utvikling og drift av en KI-assistent som klassifiserer og oppsummerer innkommende henvendelser til [KUNDE].* |
| Formål med behandlingen | *Eksempel: Sortere og oppsummere henvendelser slik at saksbehandlere svarer raskere. Teste løsningen på et utvalg historiske henvendelser før produksjonssetting.* |
| Behandlingsaktiviteter | *Eksempel: Mottak og lagring av henvendelser, oppsplitting av tekst, sending av tekst til språkmodell via API for klassifisering/oppsummering, lagring av resultat, logging, feilsøking, sletting.* |
| Kategorier registrerte | *Eksempel: Innbyggere/brukere som sender henvendelser; kundens ansatte (saksbehandlere, brukere av løsningen); kontaktpersoner hos tredjeparter som nevnes i henvendelser.* |
| Kategorier personopplysninger | *Eksempel: Navn, e-post, telefon, fritekst i henvendelsen, saksnummer, brukerlogg (bruker-ID, tidspunkt, IP-adresse).* |
| Særlige kategorier (art. 9) eller straffedommer (art. 10) | [Ja/Nei. Hvis ja, hvilke]. *Eksempel: Ikke tilsiktet, men fritekst kan inneholde helseopplysninger. Tiltak: se Bilag 2 punkt 10.* |
| Fødselsnummer | [Ja/Nei]. *Eksempel: Nei. Fødselsnummer filtreres bort før tekst sendes til språkmodell.* |
| Omfang | *Eksempel: Ca. [antall] henvendelser per måned, ca. [antall] registrerte.* |
| Varighet | *Eksempel: Fra [DATO] til Hovedavtalen opphører. Testdata slettes senest 30 dager etter testslutt. Lagringstid i løsningen: [X] måneder, styrt av Behandlingsansvarlig.* |
| Lokasjon for lagring | *Eksempel: Microsoft Azure, region [Norway East / Sweden Central / UNKNOWN]. Ingen lagring på lokale maskiner utover midlertidig feilsøking på krypterte arbeidsmaskiner.* |
| Lokasjon for behandling hos underdatabehandlere | *Eksempel: Anthropic (Claude API). Behandlingssted ikke garantert i EU/EØS. Overføringsgrunnlag: SCC, se Bilag 3.* |
| Tilgang fra utenfor EU/EØS | *Eksempel: Ingen tilgang fra Databehandlers ansatte utenfor EU/EØS uten skriftlig godkjenning.* |
| Særskilte instrukser | *Eksempel: Produksjonsdata skal ikke brukes i utviklingsmiljø. Bruk syntetiske eller pseudonymiserte data i test.* |

---

# Bilag 2: Sikkerhetstiltak

Minimumstiltak for Solarconsulting AS (tre personer). Tiltakene er bygget rundt de fire kategoriene i NSMs grunnprinsipper for IKT-sikkerhet v2.1: identifisere og kartlegge, beskytte og opprettholde, oppdage, håndtere og gjenopprette [9]. Solarconsulting AS har **ingen sertifiseringer** (ikke ISO 27001, ikke SOC 2). FACT (oppgitt av operatør). Underdatabehandlernes sertifiseringer er deres, ikke våre.

Kommentar til internt bruk: kryss bare av det som faktisk er på plass. Tiltak som ikke er innført, skal fjernes eller merkes «planlagt [DATO]». Å love tiltak vi ikke har, er verre enn å love få. Status per tiltak er UNKNOWN til noen har sjekket.

**Identifisere og kartlegge**

1. **Oversikt.** Vi fører en liste over hvilke systemer, kontoer og lagringssteder som inneholder kundens personopplysninger, per oppdrag.
2. **Risikovurdering.** Før oppstart av hvert oppdrag med personopplysninger gjør vi en kort skriftlig risikovurdering, og den oppdateres ved vesentlige endringer.

**Beskytte og opprettholde**

3. **Flerfaktorautentisering (MFA)** på alle kontoer med tilgang til kundedata eller kildekode: Microsoft/Azure, GitHub, Anthropic Console, e-post og passordhåndterer. Phishing-resistent MFA (passkey/FIDO2) der tjenesten støtter det.
4. **Tilgangsstyring.** Minste tilgang som trengs. Personlige kontoer, ingen delte innlogginger. Tilganger gjennomgås ved oppstart og avslutning av hvert oppdrag, og når noen slutter. Adminrettigheter i Azure brukes bare ved behov.
5. **Kryptering i transitt.** All trafikk med TLS 1.2 eller nyere.
6. **Kryptering i hvile.** Lagring i Azure med kryptering slått på (standard for Azure Storage og databaser). Arbeidsmaskiner har fullt diskkryptert (BitLocker/FileVault/LUKS).
7. **Hemmelighetshåndtering.** API-nøkler og passord ligger i Azure Key Vault eller passordhåndterer. Aldri i kildekode, i chat eller i e-post. Kodelager skannes for hemmeligheter (for eksempel GitHub secret scanning). Nøkler roteres ved mistanke om lekkasje og når noen slutter.
8. **EU/EØS-region.** Kundedata lagres i Azure-region innen EU/EØS. Tjenester som ikke kan begrenses til EU/EØS, står i Bilag 3 med overføringsgrunnlag.
9. **Separasjon.** Hver kunde har egen ressursgruppe eller eget abonnement i Azure. Produksjonsdata brukes ikke i utvikling eller test uten skriftlig instruks.
10. **Dataminimering mot KI-tjenester.** Vi sender bare de dataene som trengs til språkmodellen. Der det er praktisk mulig, fjerner eller pseudonymiserer vi direkte identifikatorer (fødselsnummer, telefon) før kallet. Vi bruker bare kommersielle API-avtaler der leverandøren ikke trener på kundedata. Forbrukerversjoner av KI-verktøy brukes ikke til kundedata.
11. **Oppdatering.** Operativsystem, nettleser og avhengigheter holdes oppdatert. Kritiske sikkerhetsoppdateringer installeres så raskt det lar seg gjøre.
12. **Opplæring.** Alle tre har gått gjennom denne avtalen, avviksrutinen og grunnleggende phishing-bevissthet. Gjentas årlig.

**Oppdage**

13. **Logging.** Pålogging og administrative endringer logges i Azure (aktivitetslogg / Entra ID-pålogginger). Logger beholdes i [90] dager og inneholder ikke mer persondata enn nødvendig.
14. **Varsler.** Varsling ved mistenkelig pålogging og ved endringer i tilganger er slått på der tjenesten tilbyr det.

**Håndtere og gjenopprette**

15. **Sikkerhetskopi.** Kundedata som vi har ansvar for å lagre, tas sikkerhetskopi av med lagring i EU/EØS og oppbevaringstid [35] dager. Gjenoppretting testes minst en gang i året.
16. **Avviksrutine.** (a) Den som oppdager noe, sier fra til [AVVIKSKONTAKT] med en gang. (b) Begrens skaden: sperr kontoer, roter nøkler, steng tilgang. (c) Varsle Behandlingsansvarlig innen 24 timer (avtalens punkt 9). (d) Dokumenter hva som skjedde, hva som ble gjort, og hva vi endrer. Behandlingsansvarlig melder til Datatilsynet. Fristen er 72 timer fra Behandlingsansvarlig ble kjent med bruddet [2].
17. **Sletting.** Rutine for sletting ved oppdragsslutt, med skriftlig bekreftelse (avtalens punkt 12).

---

# Bilag 3: Godkjente underdatabehandlere

| Underdatabehandler | Formål | Lokasjon | Overføringsgrunnlag | Status |
|---|---|---|---|---|
| **Microsoft Ireland Operations Ltd.** (ASSUMPTION om juridisk enhet; sjekk avtalen vår) | Hosting, lagring, databaser, nøkkelhvelv og logging i Microsoft Azure | Azure-region [Norway East / Sweden Central] (UNKNOWN: faktisk region). Microsoft oppgir at EU Data Boundary ble fullført i februar 2025 for kunde- og supportdata i EU/EFTA, men med unntak, blant annet for global cybersikkerhet og enkelte ikke-regionale tjenester [7] | Data lagres i EU/EØS. For begrensede overføringer ut: Microsoft DPA [8]. Om DPA-en innlemmer SCC og om Microsoft er DPF-sertifisert, ble ikke verifisert 2026-10-18 (UNKNOWN) | Godkjent |
| **Anthropic Ireland, Limited** (avtalepart for EØS-kunder etter Anthropics kommersielle vilkår [5]; UNKNOWN om dette er satt opp for vår konto) | Tekstbehandling med språkmodellen Claude via API under kommersiell avtale (klassifisering, oppsummering, uttrekk). Anthropic skal ikke trene modeller på kundeinnhold fra tjenestene [5] | UNKNOWN. DPA-en angir ikke behandlingssted [6]. Anthropic bruker egne underdatabehandlere, oppført på trust.anthropic.com/subprocessors (lenket fra DPA-en [6]) | EU-standardkontraktsbestemmelser (SCC) modul 2 og 3, innlemmet i Anthropics DPA [6]; jf. GDPR art. 46 nr. 2 bokstav c [13]. DPF-status: UNKNOWN | Godkjent, forutsatt at punkt 4–6 i avklaringslisten er lukket |
| **Railway** (Railway Corp., ASSUMPTION om navn) | Brukes ikke for kundedata | – | – | **Brukes ikke for kundedata** (anbefaling) |
| **Vercel** (Vercel Inc.) | Brukes ikke for kundedata | – | – | **Brukes ikke for kundedata** (anbefaling) |

Kommentar til internt bruk, ikke del av bilaget:

- Anthropics DPA lover varsling av sikkerhetsbrudd uten ugrunnet opphold og innen 48 timer [6]. FACT. Det er lengre enn vårt mål på 24 timer overfor kunden. I praksis kan vi ikke varsle om noe Anthropic ikke har fortalt oss. Punkt 9.1 sier derfor «uten ugrunnet opphold» som plikt og 24 timer som mål, ikke som absolutt frist. Juristen bør se på om det holder, eller om vi skal skrive «innen 24 timer etter at Databehandler ble kjent med bruddet».
- Anthropic sletter eller returnerer kundedata innen 30 dager etter opphør, med unntak blant annet for lovpålagt lagring og bekjempelse av misbruk [6]. FACT. Det må stemme med punkt 12.2.
- Anthropic gir 15 dagers protestfrist ved nye underdatabehandlere [6]. FACT. Vi gir kunden 30 dager i punkt 5.2. Det betyr at vi kan bli varslet om en endring hos Anthropic som vi ikke rekker å varsle kunden om med 30 dagers frist. Juristen må vurdere om fristen bør ned til 14 dager, eller om vi skal skrive at endringer hos underleverandørens egne underdatabehandlere varsles «så snart vi får beskjed».
- Revisjon hos Anthropic er normalt begrenset til tredjepartsrapporter (SOC 2) og én revisjon i året på kundens bekostning [6]. FACT. Derfor punkt 10.4.
- Railway og Vercel: amerikanske plattformer der vi ikke har kontrollert region eller DPA (UNKNOWN). Det er enklest og tryggest å holde kundedata unna dem. Står det i bilaget, må vi også faktisk holde oss til det.
- Andre verktøy som kan berøre kundedata og som bør vurderes før første oppdrag: GitHub (kildekode og eventuelle testdata), e-post/Microsoft 365, passordhåndterer, eventuelt Claude Code/Claude.ai på egne maskiner. UNKNOWN om noen av disse i praksis får personopplysninger fra kunder. Hvis ja, må de inn i tabellen.

---

## Kilder (alle hentet 2026-10-18)

1. Lovdata, personopplysningsloven, GDPR artikkel 28 (nr. 2, 3, 4, 9, 10): https://lovdata.no/dokument/NL/lov/2018-06-15-38/gdpr/ARTIKKEL_28
2. Lovdata, GDPR artikkel 33 (nr. 1: behandlingsansvarlig melder til tilsynsmyndigheten uten ugrunnet opphold og senest 72 timer etter å ha fått kjennskap; nr. 2: databehandler underretter behandlingsansvarlig uten ugrunnet opphold): https://lovdata.no/dokument/NL/lov/2018-06-15-38/gdpr/ARTIKKEL_33
3. Lovdata, personopplysningsloven LOV-2018-06-15-38 (forordningen er del av loven og gjelder som norsk lov): https://lovdata.no/dokument/NL/lov/2018-06-15-38
4. Datatilsynet, «Hvordan lage en databehandleravtale?»: https://www.datatilsynet.no/rettigheter-og-plikter/virksomhetenes-plikter/hvordan-lage-en-databehandleravtale/
5. Anthropic, Commercial Terms of Service (avtalepart Anthropic Ireland, Limited for EØS/Sveits/UK; DPA innlemmet; ikke trening på kundeinnhold): https://www.anthropic.com/legal/commercial-terms
6. Anthropic, Data Processing Addendum (ikrafttredelse 24.02.2025; SCC modul 2 og 3; varsling innen 48 t; sletting innen 30 dager; 15 dagers protestfrist for underdatabehandlere; revisjon): https://www.anthropic.com/legal/data-processing-addendum
7. Microsoft, «Microsoft completes landmark EU Data Boundary» (26.02.2025): https://blogs.microsoft.com/on-the-issues/2025/02/26/microsoft-completes-landmark-eu-data-boundary-offering-enhanced-data-residency-and-transparency/ og https://learn.microsoft.com/en-us/privacy/eudb/eu-data-boundary-configure-azure-nonregional-services
8. Microsoft, Products and Services Data Protection Addendum (indeksside; selve vilkårene ligger i .docx, ikke lest): https://www.microsoft.com/licensing/docs/view/Microsoft-Products-and-Services-Data-Protection-Addendum-DPA
9. NSM, Grunnprinsipper for IKT-sikkerhet v2.1: https://nsm.no/getfile.php/1313975-1717589722/NSM/Filer/Dokumenter/Veiledere/NSMs%20Grunnprinsipper%20for%20IKT-sikkerhet%20v2.1.pdf
10. Helsedirektoratet, Normen, «Databehandleravtale ved bruk av skytjenester» (rangordningsklausul ved bruk av SSA; databehandleravtale som vedlegg): https://www.helsedirektoratet.no/normen/bruk-av-skytjenester-til-behandling-av-helse-og-personopplysninger/anskaffelser-ved-bruk-av-skytjenester/databehandleravtale-ved-bruk-av-skytjenester
11. Anskaffelser.no, Veiledende bilag til SSA-S 2026: https://www.anskaffelser.no/sites/default/files/2026-03/ssa-s_bilag_2026-bok_0.docx
12. Eksempler på kunders egne maler på anskaffelser.no: https://www.anskaffelser.no/sites/default/files/2026-03/aalesund-databehandleravtale.pdf og https://www.anskaffelser.no/sites/default/files/2026-05/hamar-ombruksplattform-dba_generell_avtaletekst.docx
13. Lovdata, GDPR artikkel 46 (nr. 2 bokstav c: standard personvernbestemmelser vedtatt av Kommisjonen): https://lovdata.no/dokument/NL/lov/2018-06-15-38/gdpr/ARTIKKEL_46

Merknad om kildene: 10, 11 og 12 er gjengitt fra søkeresultater og er ikke lest i sin helhet. 7 er Microsofts egen framstilling. Anthropic- og Microsoft-vilkår endres jevnlig og må sjekkes på nytt før hvert tilbud.
