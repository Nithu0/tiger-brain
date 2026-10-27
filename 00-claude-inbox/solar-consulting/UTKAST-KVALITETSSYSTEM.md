> **UTKAST — må gjennomgås av eierne; marker hva som faktisk praktiseres i dag.**
> Skrevet 2026-10-18 på grunnlag av eierintervjuet samme dag og LEVERANSEKLAR-SJEKKLISTE.md, del D.
> Tekst i [hakeparentes] er plassholdere. Punkter merket «etableres før første leveranse» er ikke praksis i dag og må enten innføres eller strykes før dokumentet legges ved et tilbud.
> Kommentaren til eierne står nederst og skal ikke være med i tilbudet.

---

# Beskrivelse av kvalitetssikringssystem

**Solarconsulting AS** · org.nr. [ORG.NR.] · versjon [1.0], [DATO] · godkjent av [NAVN, ROLLE]

## Innledning

Solarconsulting AS er et lite konsulentselskap innen IT og kunstig intelligens (KI). Vi har tre konsulenter: én som arbeider med løsningsdesign for KI og agentbaserte løsninger, salg og drift av selskapet, og to utviklere med flere års erfaring. Vi selger konsulenttjenester på timebasis og tar oppdrag opp til om lag 4 MNOK.

Dette dokumentet beskriver hvordan vi styrer kvaliteten i oppdragene våre. Selskapet er ikke ISO-sertifisert. Beskrivelsen dokumenterer rutinene vi følger, og den gjelder for alle oppdrag. Der en rutine ennå ikke er tatt i bruk i et kundeoppdrag, står det.

## 1. Ansvar og roller

- **Kvalitetsansvarlig:** [NAVN]. Eier dette dokumentet, fører avviksloggen og leder den årlige gjennomgangen.
- **Prosjektleder per oppdrag:** utpekes av teamet ved oppstart av hvert oppdrag. Prosjektlederen er kundens faste kontaktperson og har ansvar for fremdrift, statusrapportering, risiko og at leveransen blir godkjent.
- **Løsningsdesign:** ansvar for at løsningen, særlig KI-delene, svarer på kundens behov og krav.
- **Utviklere:** ansvar for kode, tester og teknisk dokumentasjon. Teamet eier koden og arkitekturen og kan forklare hver funksjon i det som leveres.

Rollene fordeles per oppdrag ut fra kompetanse og kapasitet, og fordelingen skrives inn i oppdragsplanen. Hver konsulent har normalt 20–40 timer i uken tilgjengelig.

## 2. Oppdragsprosess

**Oppstart**
- Avklaringsmøte med kunden: mål, omfang, krav, rammer og kontaktpersoner.
- Kravene skrives ned og nummereres. For hvert krav avtales et akseptkriterium, altså hva som må være oppfylt for at kunden skal godkjenne.
- Risikovurdering: hva kan gå galt (faglig, teknisk, fremdrift, personvern), hvor sannsynlig det er, og hva vi gjør med det.
- Oppdragsplan med milepæler, rollefordeling og rapporteringsform, godkjent av kunden.

**Gjennomføring**
- Arbeidet gjøres i korte iterasjoner på [1–2] uker. Hver iterasjon avsluttes med en demonstrasjon av det som er laget, slik at kunden kan rette kursen tidlig.
- Kunden får skriftlig statusrapport [hver/annenhver uke]: hva som er gjort, hva som kommer, avvik, risiko og timeforbruk mot ramme.
- Endringer i omfang avtales skriftlig før de gjennomføres.

**Leveranse**
- Før leveranse tester vi hele løsningen samlet, også under belastning (se punkt 3).
- Kunden gjennomfører akseptansetest mot de avtalte akseptkriteriene. Feil som blir funnet, registreres og rettes før endelig godkjenning.

**Avslutning**
- Overlevering av kode, dokumentasjon, tilganger og driftsinformasjon (se punkt 5).
- Sluttmøte med kunden og en kort evaluering: hva fungerte, hva skal vi gjøre annerledes. Lærdommen føres inn i forbedringsloggen (punkt 6 og 9).

## 3. Utvikling og test

- **Versjonskontroll:** all kode og konfigurasjon ligger i Git. Ingen endringer gjøres direkte i produksjon.
- **Kodegjennomgang:** målsettingen er at alle endringer gjennomgås av en annen enn den som skrev dem før de tas inn i hovedgrenen. Med to utviklere i teamet er dette praktisk gjennomførbart. [Bekreftes av utviklerne: gjøres i dag / etableres før første leveranse.]
- **Automatiske tester:** funksjonalitet dekkes av automatiske tester som kjøres ved hver endring.
- **Kontinuerlig integrasjon (CI):** bygg og tester kjøres automatisk. En endring som feiler, tas ikke inn. [Etableres for hvert kundeoppdrag ved oppstart.]
- **Ende-til-ende-test før leveranse:** hele løsningen testes gjennom brukergrensesnittet med automatiserte ende-til-ende-tester (Playwright) i tillegg til enhetstester, ikke bare enkeltdeler. Lasttest (f.eks. k6) etableres for oppdrag der kunden stiller krav til ytelse.
- **Testdata:** vi tester med syntetiske eller anonymiserte data. Ekte personopplysninger brukes ikke i test uten skriftlig avtale med kunden.
- **Sporbarhet:** hvert krav fra oppstarten kobles til minst én test. Testrapporten viser hvilke krav som er dekket og bestått. [Etableres før første leveranse.]

## 4. Kontroll av KI-generert kode og innhold

Vi bruker KI-verktøy i utviklingen. Det gjør oss raskere, men ansvaret for resultatet ligger alltid hos oss. Disse reglene gjelder:

- **Mennesket eier koden.** KI-generert kode behandles som kode fra en ny kollega: den leses, forstås og gjennomgås før den tas inn, og den må bestå de samme testene og den samme kodegjennomgangen som annen kode. Teamet skal kunne forklare hver funksjon i det som leveres, og kunden kan be oss om det.
- **Fakta krever kilde.** Faktapåstander i rapporter, utredninger og dokumentasjon som KI har bidratt til, kontrolleres mot en navngitt kilde før de leveres. Det gjelder særlig tall, lovhenvisninger og tekniske krav. Påstander uten kilde merkes eller strykes.
- **Ingen kundedata til KI-modeller uten avtale.** Kundens data, personopplysninger og konfidensielle dokumenter sendes ikke til eksterne KI-tjenester uten at kunden har godkjent det skriftlig og det foreligger databehandleravtale. Vi bruker KI-modeller fra Anthropic gjennom en bedriftsavtale. [Bekreft vilkårene i avtalen: at innsendte data ikke brukes til trening, og hvor de lagres.]
- **Logging av modellbruk.** I løsninger vi bygger med KI, logges hvilken modell og versjon som ble brukt, og når. Dermed kan resultater etterprøves og endringer i modellen oppdages. [Omfang avtales per oppdrag; etableres før første leveranse.]
- **KI i løsningen testes som resten av løsningen.** Når kundens løsning selv bruker KI, lager vi et fast sett med testtilfeller med forventet svar. Settet kjøres ved hver endring, slik at vi oppdager om kvaliteten faller.

## 5. Dokumentasjon og overlevering

Ved overlevering får kunden:
- kildekoden og tilgang til repositoriet, med historikk
- en beskrivelse av arkitekturen og de viktigste designvalgene
- en installasjons- og driftsveiledning, inkludert konfigurasjon og avhengigheter
- testrapporten, med kobling mellom krav og tester
- en oversikt over KI-modeller og eksterne tjenester løsningen bruker, med vilkår
- en liste over kjente begrensninger og åpne feil

Planlagt driftsmiljø er Microsoft Azure i EU/EØS. Tilganger, nøkler og passord overleveres på en sikker måte og ikke i dokumentasjonen. Rett etter overleveringen har vi en avtalt periode med støtte på [ANTALL] uker.

## 6. Avvik og forbedring

- **Avvikslogg:** feil i leveranser, brudd på rutiner, sikkerhetshendelser og klager fra kunder registreres i en avvikslogg med dato, beskrivelse, alvorlighet og ansvarlig. [Etableres før første leveranse.]
- **Årsaksanalyse:** for alvorlige avvik finner vi årsaken, ikke bare symptomet. Vi spør hvorfor det skjedde og hvorfor det ikke ble oppdaget tidligere.
- **Korrigerende tiltak:** hvert avvik får et tiltak, en ansvarlig og en frist. Kvalitetsansvarlig følger opp at tiltaket blir gjennomført og virker.
- **Kundevarsling:** avvik som påvirker kunden, varsles prosjektlederen hos kunden uten ugrunnet opphold, og senest [ANTALL] virkedager etter at vi oppdaget dem. Brudd på personopplysningssikkerheten varsles etter databehandleravtalen.

## 7. Kompetansestyring og bemanning

- **Kompetansebank:** selskapet fører en oversikt over hver konsulents kompetanse, erfaring, referanseoppdrag og sertifiseringer. Oversikten brukes til å bemanne oppdrag og til å svare på tilbudsforespørsler.
- **CV-er** oppdateres etter hvert avsluttet oppdrag og minst én gang i året.
- **Rollefordeling:** bemanningen avgjøres per oppdrag ut fra hva oppdraget krever. Vi tilbyr ikke oppdrag vi mangler kompetanse eller kapasitet til.
- **Faglig oppdatering:** hver konsulent setter av tid til faglig utvikling, særlig innen KI, som endrer seg raskt. [Omfang: TIMER per år.]
- **Underleverandører:** selskapet bruker i dag ingen underleverandører. Tas en underleverandør inn, gjelder de samme kravene til kvalitet, sikkerhet og personvern, og kunden får vite om det på forhånd.

## 8. Informasjonssikkerhet og personvern

- Når vi behandler personopplysninger for kunden, inngår vi databehandleravtale før behandlingen starter. [Henvis til vedlegg: databehandleravtale.]
- Tilgang til kundens systemer og data gis bare de som trenger den i oppdraget, og fjernes når oppdraget er avsluttet.
- Vi bruker tofaktorautentisering, kryptert lagring og passordhåndterer. [Bekreftes; detaljer i vedlegg: sikkerhetstiltak.]
- Kundedata lagres i EU/EØS. Planlagt plattform er Microsoft Azure (EU-region).
- Etter avsluttet oppdrag slettes eller tilbakeleveres kundens data, etter avtalen.

## 9. Årlig gjennomgang og forbedring

Én gang i året, og i tillegg etter alvorlige avvik, går kvalitetsansvarlig og eierne gjennom systemet. Vi ser på:
- avvik, kundeevalueringer og lærdom fra avsluttede oppdrag
- om rutinene i dette dokumentet faktisk følges
- endringer i regelverk, kundekrav og KI-verktøyene vi bruker
- behov for kompetanse og sertifisering

Gjennomgangen ender i et kort referat med tiltak og ansvarlige, og dokumentet oppdateres med nytt versjonsnummer. Første gjennomgang er planlagt [DATO].

---
*Slutt på tilbudstekst.*

---

## Kommentar til eierne (ikke med i tilbudet)

**Juridisk grunnlag.** FACT: Anskaffelsesforskriften §16-7 (3) (lovdata.no/dokument/SF/forskrift/2016-08-12-974, hentet 2026-10-18) sier at oppdragsgiver skal godta annen dokumentasjon for tilsvarende kvalitetstiltak når leverandøren ikke kan skaffe sertifikat innen fristen av grunner som ikke skyldes leverandøren selv. ASSUMPTION: ordlyden gir oss et argument når et ISO-sertifikat kreves eksplisitt, men det er ingen garanti. Der kriteriet bare er «tilbyder har et kvalitetssikringssystem» (slc-sche-qu-cert-indep), er dette dokumentet i seg selv svaret. Les kravteksten i hver konkurranse. Ikke siter paragrafen i tilbudet med mindre konkurransen krever sertifikat.

**Hva som stemmer i dag**
- FACT (intervju): tre personer, rollene som beskrevet, roller fordeles per oppdrag, timebasis, maks ca. 4 MNOK, 20–40 t/uke hver.
- FACT: KI-assistert utvikling. Teamet eier koden og arkitekturen og kan forklare hver funksjon. Hele systemet testes ende-til-ende (Playwright) før leveranse. RETTET 2026-10-18 etter Tintuns svar: det er funksjonell test, ikke lasttest.
- FACT: planlagt drift på Azure (EU) og KI-modeller via Anthropics bedriftsavtale. «Planlagt» står med vilje i teksten.
- FACT: ingen underleverandører og ingen ISO-sertifisering. Begge deler står ærlig i teksten.
- FACT: kompetansebanken finnes i CRM-et, men er så å si tom (0 leveransefakta per 2026-10-17). Avsnittet i punkt 7 beskriver verktøyet, ikke innholdet.

**Må på plass før dokumentet brukes (eller strykes)**
- UNKNOWN: navn på kvalitetsansvarlig, org.nr., versjon og dato.
- ASSUMPTION: avvikslogg, sporbarhet krav→test, logging av modellbruk og CI per kundeoppdrag er ikke praksis i kundeoppdrag i dag, fordi det ikke finnes IT-kundeleveranser ennå. De er merket «etableres før første leveranse». Avviksloggen kan være et enkelt regneark eller en tabell i CRM-et. Det tar under én time og gjør teksten sann.
- UNKNOWN: iterasjonslengde, rapporteringshyppighet, støtteperiode, varslingsfrist, timer til faglig oppdatering. Velg tall dere faktisk kan holde.
- UNKNOWN: vedleggene «databehandleravtale» og «sikkerhetstiltak» finnes ikke ennå. Lag dem, eller stryk henvisningene.
- UNKNOWN: vilkårene i Anthropic-avtalen (trening på data, lagringssted). Les dem før punkt 4 sendes ut.
- FACT: ansvarsforsikring kommer etter eierskiftet. Den hører ikke hjemme i dette dokumentet, men kreves ofte i samme konkurranse.

**Tintun og Alper må bekrefte i sine intervjuer (§ 4 Metode)**
- Gjennomgås hver endring av den andre i dag (pull requests), eller er det en målsetting?
- Skriver de automatiske tester i dag, og med hvilket verktøy? Kjører det CI?
- ~~Hva betyr «stresstest hele systemet» konkret?~~ Besvart av Tintun 2026-10-18: ende-til-ende-tester med Playwright + enhetstester. Ingen lasttest i dag.
- Bruker de syntetiske testdata, og finnes det en vane med sporbarhet fra krav til test?
- Hvilke KI-verktøy bruker de, og hvordan kontrollerer de det som genereres?
- Tofaktor, passordhåndterer, kryptert disk: ja eller nei per person.

**Referanser.** FACT: solcelleoppdragene (Sauda kommune, kravspesifikasjon 2025, og fem andre kunder) er selskapets referanser fra før eierskiftet og gjelder ikke IT. De er bevisst utelatt her, fordi dette dokumentet handler om rutiner og ikke om erfaring. De passer i referansedelen av tilbudet, merket som energirådgivning.
