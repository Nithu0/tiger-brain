# Før vi selger: status 15.11.2026

paal-1, på oppdrag fra orchestrator-1 16:24Z. Bare lesing. Kilder: drift på main (998312c), GitHub-API-et, den offentlige nettsiden og issuene. Merking: FACT er sjekket nå, UNKNOWN er ikke sjekket.

## Kort

Vi kan ikke selge Solar Secure ennå. Ingen partneravtale er signert, og det står heller ingen steder på nettsiden at vi har partnere. Konsulenttimer og nettsider kan selges, men fire ting bør ordnes før første kontrakt: 2FA, forsikringen, personvernerklæringen og én setning om Anthropic i kvalitetssystemet.

## 1. 2FA (A2)

- FACT: GitHub-org-en står på **team**, men kravet om 2FA er **av**. 1 av 4 medlemmer har ikke 2FA. Ingen eksterne samarbeidspartnere mangler 2FA.
- UNKNOWN: Google Workspace. Agentene kan ikke lese adminkonsollen. trading-1 meldte 14.11 at den eneste brukeren er superadmin uten 2FA.
- Plan: Alper slår det på innen 30.11. Fristen blir en oppgave 23.11 (drift#303).
- Rekkefølge: først skrur alle på 2FA selv, deretter settes kravet. Settes kravet først, blir medlemmer uten 2FA fjernet fra org-en.

## 2. Forsikring

- FACT: ansvarsforsikringen er ikke tegnet. `anbud/espd.md` sier «Nei».
- **Motstrid:** plan-2027 (vedtatt 15.11) sier «Tegn ansvarsforsikring hos Storebrand» 15.11. #1 ble 14.11 flyttet til «senere», med første kontrakt som utløser. #1 viser dessuten til Gjensidige og If, ikke Storebrand. Eier: Nithu. Den ene av dem må rettes.
- Storebrand er også partner i Solar Secure (tipshonorar, #278 og #287). Om forsikringsdistribusjonsloven gjelder, er ikke avklart. Juristen svarer innen 30.11.
- Det haster ikke for DPS-opptak. Ifølge #1 og #126 krever SSA-B forsikringen ved første kontrakt. Ledetiden er 1–2 uker.

## 3. Personvernerklæringen

- FACT: https://solarconsulting.no/personvern er publisert, men med `noindex`. På siden står fortsatt «lagringstid fylles inn av juridisk ansvarlig» og «Overføringsgrunnlag og databehandleravtaler fylles inn av juridisk ansvarlig».
- FACT: det finnes ikke noe kontaktskjema på nettsiden, bare mailto. Skjemaet er sperret til #22 og #20 er ferdige. Det er riktig.
- Siden sier at kundesystemet «driftes hos Railway i EU (Amsterdam)». Railways DPA sier at hovedbehandlingen skjer i USA, og vår DPA-status er UNKNOWN (#49). Vercel-planen er UNKNOWN. På Hobby kan vi ikke inngå DPA (#20).
- Juristen har fristen 15.12 (#22). Før vi samler inn leads må erklæringen være ferdig, og samtykket til videresending (#286 og #302) må være på plass.

## 4. Påstander om partnere mot det som er signert

Ingen partneravtale er signert (FACT). Nettsiden har ingen partnerseksjon, ingen logoer og ingen partnernavn. Det som går lenger enn det som er bekreftet, er dette, det alvorligste først:

1. `anbud/kvalitetssystem.md:103` sier at vi har «kommersiell API-avtale» med Anthropic. **Rettet i drift#318 (16:36Z):** nå står det standardvilkår, ingen egen avtale, og BEKREFTES før bruk i tilbud. Påstanden står med merket `[BEKREFTES … #20]`. Om kontoen tilhører selskapet, er ikke sjekket. Fjernes merket før det er sjekket, havner påstanden i et tilbud.
2. En kommentar i #284 sier om Telenor Cyberdefence og Netsecurity: «samtale pågår». Profilen (drift#304) er **rettet i drift#321** til «Mulig, møter planlagt». Kommentaren i #284 står fortsatt. I #283 står det bare «Book møter», og det er ingen spor av noe møte. Den kommentaren er grunnlaget for pakkebeskrivelsen, og den skal bli kundevendt.
3. Samtykketeksten i drift#302 har avkrysningsfelt for Storebrand, Telenor og Loyalty. Den er riktig merket som UTKAST, men sier ikke at et felt bare kan publiseres når avtalen med den partneren er signert. Jeg foreslo en linje om det til trading-1. **Rettet i drift#310 (16:31Z).** plattform#61-spesifikasjonen sperrer også partnere uten `avtaleSignert`, og skjemaet står av i prod.
4. /solenergi siterer «Norway Solar AS har benyttet Solarconsulting som samarbeidspartner». Jeg fant ikke noe skriftlig samtykke i drift. UNKNOWN. Eier: Tintun (nettsiden, #282).
5. Loyalty er bare en ASSUMPTION, også når det gjelder rollen (#284: «bekreft at det er Loyalty som leverer internett»).

Dette er OK: ESPD sier ingen underleverandører og ikke sertifisert. Microsoft Partner er søkt, og godkjenningen venter (#71). Microsoft for Startups er søkt (#196). Telenor AI Factory, Anthropic og OpenAI er bare kartlegging (#281).

## Gjør dette før første salg

| Hva | Eier | Frist |
|---|---|---|
| Alle skrur på 2FA, deretter settes kravet i GitHub og GWS | Alper | 30.11 |
| Bestem forsikringen: Storebrand nå (planen) eller ved første kontrakt (#1) | Nithu | 20.11 |
| Lagringstid og DPA-avsnitt på /personvern, og avklar Vercel-planen | jurist og Nithu | 15.12 |
| Behold `[BEKREFTES]` på Anthropic-setningen til #20 er sjekket | admin-1 | før neste tilbud |
| Endre «samtale pågår» i #284 til det som faktisk er gjort | Alper | 20.12 |
| Skriftlig samtykke til Norway Solar-sitatet, ellers fjern det | Tintun | 20.12 |

## Ikke sjekket

Google Workspace-2FA. Om noen har snakket med Storebrand, Loyalty eller Telenor utenom issuene. Upublisert innhold i nettside-repoet (Terra, ikke åpnet).
