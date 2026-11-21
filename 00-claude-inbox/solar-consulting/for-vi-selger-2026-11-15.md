# Før vi selger: status 15.11.2026

paal-1, på oppdrag fra orchestrator-1 16:24Z. Bare lesing. Kilder: drift på main (998312c), GitHub-API-et, den offentlige nettsiden og issuene. Merking: FACT er sjekket nå, UNKNOWN er ikke sjekket.

## Kort

Vi kan ikke selge Solar Secure ennå. Ingen partneravtale er signert, og det står heller ingen steder på nettsiden at vi har partnere. Konsulenttimer og nettsider kan selges, men fire ting bør ordnes før første kontrakt: 2FA, forsikringsbeviset (If fra 25.11), personvernerklæringen og én setning om Anthropic i kvalitetssystemet.

## 1. 2FA (A2)

- FACT: GitHub-org-en står på **team**, men kravet om 2FA er **av**. 1 av 4 medlemmer har ikke 2FA. Ingen eksterne samarbeidspartnere mangler 2FA.
- UNKNOWN: Google Workspace. Agentene kan ikke lese adminkonsollen. trading-1 meldte 14.11 at den eneste brukeren er superadmin uten 2FA.
- FACT (21.11): meldinger i #agenter fra fire personer (sikker=true) blir nå jobber hos en agent på PC-en (cc#218). Motoren er låst til lesing i ~/code og Brain og skriving i én fil, men tofaktor i Slack er ikke påkrevd ennå (Nithu: «tofaktor etterpå»). Bør på plass snarest.
- FACT (drift#351, 20.11): det nye Slack-workspacet (18.11) har ikke tofaktor. Kontoene ble opprettet med samme startpassord, og bare én har byttet. Alle adressene er aliaser til kontakt@. Slack må med i 2FA-runden.
- Plan: Alper slår det på innen 30.11. Fristen blir en oppgave 23.11 (drift#303).
- Rekkefølge: først skrur alle på 2FA selv, deretter settes kravet. Settes kravet først, blir medlemmer uten 2FA fjernet fra org-en.

## 2. Forsikring

- FACT (oppdatert 16.11, drift#342): Nithu valgte If 16.11, gyldig fra 25.11.2026. Motstriden mellom plan-2027 (Storebrand nå) og #1 (ved første kontrakt) er dermed løst. ESPD sier «Nei» før 25.11 og «Ja, hos If» fra 25.11.
- Gjenstår: forsikringsbeviset (sum og vilkår) er ikke lagret. Fristen 25.11 kommer som påminnelse i #1. Prisen er UNKNOWN.
- Storebrand er fortsatt partner i Solar Secure (tipshonorar, #278 og #287). Om forsikringsdistribusjonsloven gjelder, er ikke avklart. Juristen svarer innen 30.11.

## 3. Personvernerklæringen

- FACT: https://solarconsulting.no/personvern er publisert, men med `noindex`. På siden står fortsatt «lagringstid fylles inn av juridisk ansvarlig» og «Overføringsgrunnlag og databehandleravtaler fylles inn av juridisk ansvarlig».
- **Rettet 20.11:** det står ikke at det ikke finnes noe kontaktskjema. Det stemmer ikke. Siden 15.11 sjekket jeg med curl, og skjemaet tegnes i nettleseren. FACT 20.11 (Chromium, 390 px): /kontakt og forsiden har et skjema med navn, e-post, telefon, virksomhet, tema og melding. Det leverer til kontakt@ (drift#355). Personvernerklæringen har fortsatt tre felt der det står «fylles inn av juridisk ansvarlig», og #22 er åpen. Skjemaet samler altså inn persondata før erklæringen er ferdig.
- Siden sier at kundesystemet «driftes hos Railway i EU (Amsterdam)». Railways DPA sier at hovedbehandlingen skjer i USA, og vår DPA-status er UNKNOWN (#49). Vercel-teamet står på Pro (FACT, skjermbilde fra Tintun 14.11, Nithu0/Solar-Consulting#374). Om DPA-en med Vercel er inngått, er ikke sjekket (#20).
- Juristen har fristen 15.12 (#22). Før vi samler inn leads må erklæringen være ferdig, og samtykket til videresending (#286 og #302) må være på plass.

## 4. Påstander om partnere mot det som er signert

Ingen partneravtale er signert (FACT). Nettsiden har ingen partnerseksjon, ingen logoer og ingen partnernavn. Det som går lenger enn det som er bekreftet, er dette, det alvorligste først:

1. `anbud/kvalitetssystem.md:103` sier at vi har «kommersiell API-avtale» med Anthropic. **Rettet i drift#318 (16:36Z):** nå står det standardvilkår, ingen egen avtale, og BEKREFTES før bruk i tilbud. Påstanden står med merket `[BEKREFTES … #20]`. Om kontoen tilhører selskapet, er ikke sjekket. Fjernes merket før det er sjekket, havner påstanden i et tilbud.
2. En kommentar i #284 sier om Telenor Cyberdefence og Netsecurity: «samtale pågår». Profilen (drift#304) er **rettet i drift#321** til «Mulig, møter planlagt». Kommentaren i #284 står fortsatt. I #283 står det bare «Book møter», og det er ingen spor av noe møte. Den kommentaren er grunnlaget for pakkebeskrivelsen, og den skal bli kundevendt.
3. Samtykketeksten i drift#302 har avkrysningsfelt for Storebrand, Telenor og Loyalty. Den er riktig merket som UTKAST, men sier ikke at et felt bare kan publiseres når avtalen med den partneren er signert. Jeg foreslo en linje om det til trading-1. **Rettet i drift#310 (16:31Z).** plattform#61-spesifikasjonen sperrer også partnere uten `avtaleSignert`, og skjemaet står av i prod.
4. /solenergi siterer «Norway Solar AS har benyttet Solarconsulting som samarbeidspartner». Navnet står også på forsiden og /om-oss etter redesignet 19.11 (Solar-Consulting#378). Det finnes ikke noe skriftlig samtykke i drift. drift#41 har bare samtykke fra Sauda (18.10). UNKNOWN, sjekket 20.11. Eier: Tintun (nettsiden, #282).
5. Loyalty er bare en ASSUMPTION, også når det gjelder rollen (#284: «bekreft at det er Loyalty som leverer internett»).

Dette er OK: ESPD sier ingen underleverandører og ikke sertifisert. Microsoft AI Cloud Partner Program: verifisert medlem 19.11, uten designasjon og uten logo (drift#354). Skriv «medlem av Microsoft AI Cloud Partner Program», ikke «Microsoft Partner». Microsoft for Startups er søkt (#196). Telenor AI Factory, Anthropic og OpenAI er bare kartlegging (#281).

## Gjør dette før første salg

| Hva | Eier | Frist |
|---|---|---|
| Alle skrur på 2FA, deretter settes kravet i GitHub og GWS | Alper | 30.11 |
| Lagre forsikringsbeviset fra If i Drive (avgjort 16.11, drift#342) | Nithu | 25.11 |
| Lagringstid og DPA-avsnitt på /personvern, og DPA med Vercel (Pro) og Railway | jurist og Nithu | 15.12 |
| Behold `[BEKREFTES]` på Anthropic-setningen til #20 er sjekket | admin-1 | før neste tilbud |
| Endre «samtale pågår» i #284 til det som faktisk er gjort | Alper | 20.12 |
| Skriftlig samtykke til Norway Solar-sitatet, ellers fjern det | Tintun | 20.12 |
| Eget samtykke fra Tin Tun og Alper til portrettene på /konsulenttjenester (publisert 21.11 på ja fra Baber; WEB-13 i team.ts, åvl. § 104). Bildet tas bort hvis noen sier nei (tools-1) | Tintun, Alper | snarest |
| Kvalifikasjonsmatrisen: referanser står GREEN (3.10), men ESPD sier «IT: ingen kundereferanser». Velg IT RED, YELLOW eller del etter fagområde (forslag i grenen learning-1/referanser-etter-fag) | Nithu | før neste IT-bud |

## Ikke sjekket

Google Workspace-2FA. Om noen har snakket med Storebrand, Loyalty eller Telenor utenom issuene. Upublisert innhold i nettside-repoet (Terra, ikke åpnet).
