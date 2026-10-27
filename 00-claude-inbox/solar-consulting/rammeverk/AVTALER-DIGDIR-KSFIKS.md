# Avtaler og tilganger: Digdir (Maskinporten / ID-porten) og KS Fiks

admin-1 · 2026-10-20 · alle kilder hentet 2026-10-20 · Solarconsulting AS, org.nr. 931949837
**Ingen søknad er sendt. Operatøren søker selv.** Merking: FACT / ASSUMPTION / UNKNOWN.

## Bunnlinjen
- **Testmiljøet kan vi få alene, uten kunde.** Det gjelder både Digdir og KS Fiks: Maskinporten-klient, `ks:fiks`-scope i test, en testorganisasjon i Fiks og SvarUt-test (FACT).
- **Produksjon mot kommuner krever kommunen.** Kommunen signerer KS-avtalen og oppretter integrasjonen med vårt org.nr. «Det finnes ikke noe API for å opprette Fiks-integrasjoner» (FACT).
- **ID-porten-innlogging på vår egen plattform er sannsynligvis ikke tillatt for en privat virksomhet** (UNKNOWN, sannsynligvis nei). For offentlige kunder er det kunden som søker og eier klienten.
- **Virksomhetssertifikat trengs ikke.** Egne JWK-nøkler godtas av både Maskinporten og Fiks (FACT).
- ⚠ **Eierskiftet først:** signering og delegering i Altinn følger rollene i Enhetsregisteret (daglig leder, styreleder = hovedadministrator). Til de nye rollene er registrert hos Brreg, kan de nye eierne verken signere eller delegere (ASSUMPTION, utledet). **Start steg 1 etter at eierskiftet er registrert.**
- **Ledetid er ikke dokumentert noe sted** (UNKNOWN). Spør i e-postene under. Søk tidlig, fordi skjemaene behandles manuelt.

## Sjekkliste: gjør dette nå (test, uten kunde)

| # | Søk her | Trenger | Hvem | Tar |
|---|---|---|---|---|
| 1 | Digdir informasjonsskjema → Samarbeidsportalen: [samarbeid.digdir.no/maskinporten/konsument/119](https://samarbeid.digdir.no/maskinporten/konsument/119) | org.nr. Signer **«Bruksvilkår for private virksomheter»** (v1.3) | signaturberettiget (ASSUMPTION: daglig leder/styreleder) | UNKNOWN (manuell) |
| 2 | Samme portal: [leverandor/121](https://samarbeid.digdir.no/maskinporten/leverandor/121) | Signer **«Bruksvilkår for leverandører»** (vi skal levere til flere offentlige kunder) | signaturberettiget | UNKNOWN |
| 3 | Altinn (som hovedadministrator) | Deleger rettighetene «Selvbetjening av klienter i ID-porten/Maskinporten» og «Selvbetjening for leverandører» til den som skal lage klienter | hovedadministrator i Altinn | minutter, etter at rollene er registrert |
| 4 | test.maskinporten.no (selvbetjening, Ansattporten-innlogging) | Opprett Maskinporten-**testklient** med egen JWK-nøkkel | utvikler med delegert rett | selvbetjent |
| 5 | E-post **fiks@ksdigital.no** | Org.nr. + «test». Be om `ks:fiks` i Maskinportens **test**, en **testorganisasjon** i forvaltning.fiks.test.ks.no, **SvarUt-test** og Slack #fiks-support | oss | UNKNOWN |
| 6 | forvaltning.fiks.test.ks.no | Opprett integrasjon med eget org.nr., gi tilganger, ta i bruk Fiks Protokoll (test) | oss | selvbetjent etter #5 |
| 7 | Testdata | TestID / Tenor (syntetiske personer), MinID-test (OTC 12345), redirect til localhost er tillatt | oss | straks |

**E-post til KS (#5), spør samtidig om:** ledetid, motpart for Arkiv/Plan-protokoll i test, om `ks:fiks` i **produksjon** kan tildeles før vi har en kunde, om KS har en egen leverandøravtale (vi fant ingen), og om Matrikkel er en egen protokoll.

## Når vi har en offentlig kunde (produksjon)

| # | Hva | Hvem søker | Kilde |
|---|---|---|---|
| 8 | Kommunen har eller signerer **KS-Fiks SSA-L-hovedavtalen** med tjenestevedlegg (Protokoll, SvarUt) og sender den til fiksavtaler@ks.no | **kommunen** | developers.fiks.ks.no |
| 9 | Vi ber om `ks:fiks` i **produksjon** (e-post fiks@ksdigital.no, «produksjon») og lager en prod-klient i Maskinporten med **egen prod-nøkkel**. Testnøkler virker ikke | **vi** | developers.fiks.ks.no/felles/integrasjoner |
| 10 | Kommunen oppretter integrasjonen i Fiks forvaltning med vårt org.nr., gir tilganger og overleverer IntegrasjonId og passord sikkert | **kommunen** | samme |
| 11 | Maskinporten-API-er på vegne av kunden: kunden delegerer scopet til oss i Altinn, og vi kaller med `consumer_org` = kundens org.nr. | **begge** | [konsument-delegert/120](https://samarbeid.digdir.no/maskinporten/konsument-delegert-til-leverandor/120) |
| 12 | ID-porten for kundens løsning: **kunden** signerer, gjør ROS og eier klienten (`client_orgno`), og vi står som `supplier_orgno`. Leverandøreide klienter (onbehalfof) gis restriktivt | **kunden** | [ta-i-bruk/94](https://samarbeid.digdir.no/id-porten/ta-i-bruk-id-porten/94) |
| 13 | **Databehandleravtale** kunde ↔ oss (GDPR art. 28). Digdir- og Fiks-vilkårene dekker ikke den | **begge** | vilkår §2.3. Utkast: UTKAST-DATABEHANDLERAVTALE.md |

## Krav samlet
- **Org.nr.:** norsk org.nr. kreves (FACT). Vi har 931949837, verifisert hos Brreg.
- **Nøkler:** egne JWK-nøkler (maks 1 år i ID-porten) eller virksomhetssertifikat. «Fiks bryr seg ikke om hvilken» (FACT). Vi trenger derfor **ikke** kjøpe sertifikat fra Buypass/Commfides.
- **Signatur:** person med fullmakt til å inngå bindende avtaler (FACT). Hovedadministrator i Altinn delegerer (FACT).
- **Databehandleravtale:** med hver offentlig kunde der vi behandler personopplysninger (FACT, vilkår §2.3).

## Kostnad
- Maskinporten som konsument: **gratis** (FACT).
- ID-porten: gratis under 200 000 innlogginger per år, deretter 0,36 kr eks. mva per innlogging (2024/25-sats, FACT). Kunden betaler for egen klient.
- KS Fiks for leverandør: **UNKNOWN**. Kommunene betaler etter selvkost (FACT).

## Endret 2025–2026, verdt å vite
- **Systembruker** (Maskinporten/Altinn) er den nye mekanismen for sluttbrukersystemer (2025).
- **Altinn II-roller fases ut 31.12.2026** og erstattes av tilgangspakker. Delegeringene i steg 3 kan måtte gjøres på nytt.
- Samarbeidsportalen har innlogging via **Ansattporten**.

## Kilder (hentet 2026-10-20)
- Digdir: [konsument/119](https://samarbeid.digdir.no/maskinporten/konsument/119) · [leverandor/121](https://samarbeid.digdir.no/maskinporten/leverandor/121) · [bruksvilkår private/73](https://samarbeid.digdir.no/maskinporten/bruksvilkar-private-virksomheter/73) · [selvbetjening](https://docs.digdir.no/docs/Maskinporten/maskinporten_sjolvbetjening_web) · [konsumentguide](https://docs.digdir.no/docs/Maskinporten/maskinporten_guide_apikonsument) · [Q&A sertifikat 26.01.2026](https://samarbeid.digdir.no/altinn/sporsmal-og-svar/3028) · [ID-porten ta i bruk/94](https://samarbeid.digdir.no/id-porten/ta-i-bruk-id-porten/94) · [ID-porten leverandør](https://docs.digdir.no/docs/idporten/oidc/oidc_api_admin_leverand%C3%B8r.html) · [kostnadsmodell/66](https://samarbeid.digdir.no/id-porten/kostnadsmodell-id-porten/66) · [testbrukere](https://docs.digdir.no/docs/idporten/idporten/idporten_testbrukere) · [systembruker](https://docs.digdir.no/docs/Maskinporten/maskinporten_func_systembruker)
- KS Fiks: [integrasjoner](https://developers.fiks.ks.no/felles/integrasjoner/) · [testmiljø](https://developers.fiks.ks.no/felles/testmiljo/) · [Fiks Protokoll huskeliste](https://developers.fiks.ks.no/tjenester/fiksprotokoll/veiledninger/1-huskeliste/) · [SvarUt testmiljø](https://developers.fiks.ks.no/tjenester/svarut/testmiljo/) · [support](https://developers.fiks.ks.no/felles/support/) · [KS Digital avtaler og priser](https://ksdigital.no/avtaler-og-priser/)

## Åpent (UNKNOWN), spør i e-post
- **Digdir (servicedesk@digdir.no):** behandlingstid, om private kan bruke ID-porten til egen innlogging, prismodell for Maskinporten som API-tilbyder, og om bruksvilkår v1.3 er erstattet.
- **KS (fiks@ksdigital.no):** se under #5.
