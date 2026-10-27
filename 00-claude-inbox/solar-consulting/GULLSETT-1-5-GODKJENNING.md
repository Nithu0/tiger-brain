# Gullsett 1.5: godkjenning av Sauda-kravene

**Til:** operatøren eller en eier. **Tid:** ca. 20 minutter (84 rader, ~15 sekunder per rad).
**Laget:** 2026-10-18 av learning-1, fra data-1s `gullsett-krav/sauda-kravspek.json` (versjon med data-1s rettinger 18:33Z). **Status:** ingen rad er godkjent ennå. **Klar til utfylling.**

## Hva dette er, og hvorfor det haster

Dette blir fasiten for agenten som leser konkurransegrunnlag og finner kravene (bølge 1.2). Uten en godkjent
fasit kan vi ikke måle om agenten finner skal-kravene, og da går den ikke i prod. Dokumentet er vår egen
kravspesifikasjon for solcelleanlegg på kommunale boliger i Sauda (Solarconsulting, versjon 2, 27.02.2025),
8 sider. Ingen kundedata utover det.

## Hva du sjekker per rad

Sitatene er kontrollert maskinelt: alle 84 finnes ordrett på riktig side i teksten slik systemet leser PDF-en.
Du vurderer **merkelappene**:

1. **Er det et krav?** Teksten pålegger tilbyderen noe. Hvis ikke, sett **nei**.
2. **Plikt:** `skal` (må oppfylles), `bør` (vurderes), `kan` (valgfritt). Et punkt i en liste under en «skal»-setning er `skal`, selv om punktet selv ikke sier det.
3. **Kategori:** `qualification` (hvem som kan levere), `technical`, `functional` (hva som leveres), `security`, `commercial` (pris, frister, betaling), `legal`, `other`.
4. **Rolle:** `kravspesifikasjon` (krav til leveransen), `kontraktsvilkår`, `tilbudsinnhold` (hva tilbudet skal inneholde), `frist`, `opsjon`, `kvalifikasjonskrav`, `avvisningsgrunn`, `tildelingskriterium`.

Kryss av **ja** hvis alt stemmer. Skriv **rett:** og det som er feil hvis én merkelapp er feil (f.eks. «rett: bør» eller «rett: rolle kontraktsvilkår»). Kryss av **nei** hvis det ikke er et krav. Er du i tvil om en juridisk rad, skriv «jurist».

**Om tre av sitatene (sauda-015, -016, -019):** PDF-en bruker en sammenskrevet «ff». Systemets tekstuttrekk har fått en retting (data-1, PR under arbeid) som gjør den om til vanlig «ff», og sitatene følger den. Ser du «effektivitet», er det riktig.

## Fordeling


- Plikt: skal 82, kan 2
- Kategori: technical 37, commercial 18, functional 14, security 9, legal 4, qualification 2
- Rolle: kravspesifikasjon 63, kontraktsvilkår 9, tilbudsinnhold 7, frist 2, opsjon 2, kvalifikasjonskrav 1

## Se ekstra nøye på disse to

Merkelappen er en tolkning, ikke noe teksten sier rett ut:

- **sauda-030** (skal · technical · kravspesifikasjon): Rettet 2026-10-18 (data-1): bør → skal, fordi teksten sier «skal holdes så kort som mulig». Ikke målbart (innsatskrav).
- **sauda-080** (skal · commercial · tilbudsinnhold): Betinget: gjelder bare dersom underentreprenør brukes.

Rader data-1 har rettet etter første utkast (6), med merknad i lista under: sauda-015, sauda-016, sauda-019, sauda-030, sauda-061, sauda-080.

## Radene (sortert etter side og seksjon)


### Side 3: Omfanget av leveransen

- **sauda-001** · skal · commercial · frist  
  «Anleggene skal være ferdigstilt innen 01.06.2025.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-002** · skal · functional · kravspesifikasjon  
  «Tilbyder skal levere komplette, ferdig tilkoblede og idriftsatt anlegg, inkludert prosjektering, materiell, installasjon, nettilknytning, overvåkning, prøvedrift, FDV-dokumentasjon og samsvarserklæring.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-003** · skal · technical · kravspesifikasjon  
  «Leveransen skal omfatte alt nødvendig utstyr, som solcellemoduler, montasjesystem, vekselrettere, kabler, brytere, overspenningsvern og målere.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-004** · skal · legal · kontraktsvilkår  
  «Entreprenør er ansvarlig for eventuelle skader på eiendommene under leveransen»  
  [ ] ja  [ ] nei  rett: ______

### Side 4: Omfanget av leveransen

- **sauda-005** · skal · legal · kravspesifikasjon  
  «forskrifter og HMS-krav for arbeid i høyden skal følges.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-006** · skal · commercial · tilbudsinnhold  
  «Entreprenør skal inkludere alle kostnader til transport, rigging og spesialisert utstyr, samt stillas og taksikring.»  
  [ ] ja  [ ] nei  rett: ______

### Side 4: Generelle krav til solcelleanlegget

- **sauda-007** · skal · technical · tilbudsinnhold  
  «skal entreprenør også legge frem forventet årlig og månedlig energiproduksjon ved bruk av et anerkjent simuleringsprogram»  
  [ ] ja  [ ] nei  rett: ______

### Side 4: Solcellemoduler

- **sauda-008** · skal · technical · kravspesifikasjon  
  «Skal minimum ha sertiﬁsering SA8000:2014 eller OHSAS 18001»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-009** · skal · technical · kravspesifikasjon  
  «Skal ha EPD ihht. ISO 14025:2006 og EN 15804:2012+A2:2019/AC:2021.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-010** · skal · technical · kravspesifikasjon  
  «Skal ha LCA som viser produktets miljøpåvirkning og livssyklus.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-011** · skal · technical · kravspesifikasjon  
  «TUV NORD sertiﬁsert IEC 61215-1:2021»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-012** · skal · security · kravspesifikasjon  
  «Class one ﬁre prevention certiﬁcation»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-013** · skal · technical · kravspesifikasjon  
  «Helsorte, N-Type, glass glass, bifacial.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-014** · skal · commercial · kravspesifikasjon  
  «Minimum 25 års kvalitets garanti.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-015** · skal · technical · kravspesifikasjon  
  «Minst 0,4% degradering og linjæreffekt minimum 85% etter 25 år i forhold til STC eller bedre.»  
  *Merknad: Rettet 2026-10-18 (data-1, gjennomgang med learning-1): sitatet er utvidet til hele setningen, og kravet står i andre halvdel. Sitatet følger uttrekkeren etter ligaturfiksen (PR om fixLigatures, 2026-10-18), som gjør «Ư» om til «ff». Mellomrommet i «linjæreffekt» mangler i PDF-en selv.*  
  [ ] ja  [ ] nei  rett: ______
- **sauda-016** · skal · technical · kravspesifikasjon  
  «20% effektivitet eller høyere.»  
  *Merknad: Rettet 2026-10-18 (data-1): sitatet manglet ligaturen («e ektivitet», pdftotext). Sitatet følger uttrekkeren etter ligaturfiksen (PR om fixLigatures, 2026-10-18), som gjør «Ư» om til «ff». Mellomrommet i «linjæreffekt» mangler i PDF-en selv.*  
  [ ] ja  [ ] nei  rett: ______

### Side 4: Vekselrettere

- **sauda-017** · skal · technical · kravspesifikasjon  
  «Skal tilfredsstille krav for montering mot 230V IT anlegg.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-018** · skal · technical · kravspesifikasjon  
  «Skal minimum følge disse standardene IEC 62109-1 og IEC 62109-2»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-019** · skal · technical · kravspesifikasjon  
  «Minimum 97% effektivitet.»  
  *Merknad: Rettet 2026-10-18 (data-1): sitatet manglet ligaturen («e ektivitet», pdftotext). Sitatet følger uttrekkeren etter ligaturfiksen (PR om fixLigatures, 2026-10-18), som gjør «Ư» om til «ff». Mellomrommet i «linjæreffekt» mangler i PDF-en selv.*  
  [ ] ja  [ ] nei  rett: ______
- **sauda-020** · skal · technical · kravspesifikasjon  
  «Vekselrettere skal dimensjoneres mellom 95 – 130%.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-021** · skal · technical · kravspesifikasjon  
  «Dersom vekselretter monteres utendørs, skal det etableres beslag og eller kapslinger»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-022** · skal · technical · kravspesifikasjon  
  «Skal være samme vekselretterprodusent på alle anlegg.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-023** · skal · functional · kravspesifikasjon  
  «Entreprenør skal i samarbeid med BH bestemme plassering av vekselretter.»  
  [ ] ja  [ ] nei  rett: ______

### Side 4: Montasjesystem

- **sauda-024** · skal · technical · kravspesifikasjon  
  «Montasjesystemet skal tåle lokale vind og snølaster.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-025** · skal · commercial · kravspesifikasjon  
  «Produkt garanti på minimum 15 år.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-026** · skal · technical · kravspesifikasjon  
  «Skal følge EN 1991-1-3 (Eurokode 1) og EN 1991-1-4 (Eurokode 1).»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-027** · skal · technical · kravspesifikasjon  
  «Skal levere karbonavtrykk sertiﬁkat.»  
  [ ] ja  [ ] nei  rett: ______

### Side 5: DC kabling, kobling og merking

- **sauda-028** · skal · technical · kravspesifikasjon  
  «DC kabel skal være dobbeltisolerte DC kabler.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-029** · skal · technical · kravspesifikasjon  
  «Skal oppfylle krav i NEK.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-030** · skal · technical · kravspesifikasjon  
  «DC kabling skal holdes så kort som mulig.»  
  *Merknad: Rettet 2026-10-18 (data-1): bør → skal, fordi teksten sier «skal holdes så kort som mulig». Ikke målbart (innsatskrav).*  
  [ ] ja  [ ] nei  rett: ______
- **sauda-031** · skal · technical · kravspesifikasjon  
  «DC kabel skal ha TUV og CE merket og ha nødvendige sertiﬁseringer IEC 62930:2017.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-032** · skal · technical · kravspesifikasjon  
  «DC kabler skal være vær og vind bestandig (UV bestandig)»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-033** · skal · technical · kravspesifikasjon  
  «DC kabel skal brukes svart og rød kabel for å skille mellom pluss og minus.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-034** · skal · technical · kravspesifikasjon  
  «DC kabel skal være merket med streng, MPPT og vekselretter nr. ved start og slutt.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-035** · skal · technical · kravspesifikasjon  
  «DC kabler skal beskyttes mot skarpe kanter og mekanisk påkjenning.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-036** · skal · technical · kravspesifikasjon  
  «Det skal brukes originale MC4 plugger (Staubli)»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-037** · skal · technical · kravspesifikasjon  
  «MC4 pluggene skal ha IP 67»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-038** · skal · security · kravspesifikasjon  
  «skal det etableres merke om solcelleanlegg og spenningsfare.»  
  [ ] ja  [ ] nei  rett: ______

### Side 5: Elektrisk installasjon

- **sauda-039** · skal · technical · kravspesifikasjon  
  «Skal oppfylle krav fra gjeldende NEK 400 / NEK 400:2022 / NEK 400-7-712»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-040** · skal · technical · kravspesifikasjon  
  «Krav om spenningskvalitet fra netteier (FAGNE) skal følges.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-041** · skal · legal · kravspesifikasjon  
  «Skal følge FEK (Forskrift om elektroforetak og kvaliﬁkasjonskrav»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-042** · skal · qualification · kvalifikasjonskrav  
  «Utførende for kobling av solcellepanel på tak og som kobler vekselrettere i tavler må være registrert i el-virksomhetsregistrene hos DSB.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-043** · skal · technical · kravspesifikasjon  
  «Ombygging av el-skap samt generell ombygging av el-anlegg skal gjøres ihht NK 350.»  
  [ ] ja  [ ] nei  rett: ______

### Side 5: Driftsovervåkning

- **sauda-044** · skal · functional · kravspesifikasjon  
  «Energiproduksjon skal vises i en og samme plattform for alle anlegg.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-045** · skal · functional · kravspesifikasjon  
  «Plattformen skal ikke være produktspesiﬁkt plattform»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-046** · skal · functional · kravspesifikasjon  
  «Tilbudt overvåkningssystem skal vise produksjon fra hvert enkelt anlegg»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-047** · skal · functional · kravspesifikasjon  
  «skal driftspersonell varsles pr epost eller SMS innen 3 virkedager.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-048** · skal · commercial · kravspesifikasjon  
  «Skal inkludere alle lisenser og kost i fem år.»  
  [ ] ja  [ ] nei  rett: ______

### Side 5: Brannsikkerhet

- **sauda-049** · skal · security · kravspesifikasjon  
  «Skal følge generelle retningslinjer fra NEK 400:2022.»  
  [ ] ja  [ ] nei  rett: ______

### Side 6: Brannsikkerhet

- **sauda-050** · skal · security · kravspesifikasjon  
  «Entreprenør skal utfylle mal fra fornybarnorge om informasjon til brannvesenet»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-051** · skal · security · kravspesifikasjon  
  «Skal følge NEK 400-8-823 (Brannvern i elektriske installasjoner).»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-052** · skal · legal · kravspesifikasjon  
  «Solcelleanlegget skal oppfylle kravene i TEK17»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-053** · skal · security · kravspesifikasjon  
  «Lokalt brannvesen skal inkluderes i prosessen»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-054** · skal · security · kravspesifikasjon  
  «Informasjon til brann og redningsvesen skal være kort og skal være på maks 1-A4 side»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-055** · skal · security · kravspesifikasjon  
  «Kabler, vekselretter skal merkes med skilt som varsler fare om spenning.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-056** · skal · security · kravspesifikasjon  
  «skal DC bryter kobles ut automatisk når brannalarm aktiveres.»  
  [ ] ja  [ ] nei  rett: ______

### Side 6: FDV Dokumentasjon

- **sauda-057** · skal · functional · kravspesifikasjon  
  «FDV dokumentasjon skal ha ryddig mappestruktur pr bygg.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-058** · skal · functional · kravspesifikasjon  
  «Det skal leveres FDV som beskriver solcelleanlegget før overtagelse.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-059** · skal · functional · kravspesifikasjon  
  «All dokumentasjon skal være på norsk utenom datablader og manualer.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-060** · skal · technical · kravspesifikasjon  
  «Det skal også leveres målte verdier og data på strengnivå»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-061** · skal · technical · kravspesifikasjon  
  «Anlegget skal testes med IV tester, solinnstrålings --- W/m2 (minimum 400 W/m2) data skal registreres i det testen ble utført, og dato dette ble gjennomført.»  
  *Merknad: Rettet 2026-10-18 (data-1): sitatet er utvidet fra «(minimum 400 W/m2)» (18 tegn, under koblingsgrensen på 20) til hele setningen slik prod-uttrekket gir den.*  
  [ ] ja  [ ] nei  rett: ______

### Side 6: Garantier

- **sauda-062** · skal · commercial · kontraktsvilkår  
  «Produktgaranti for solcelleanlegget som helhet skal være minimum 5 år.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-063** · skal · commercial · kontraktsvilkår  
  «Produktgaranti solceller skal være minimum 25 år.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-064** · skal · commercial · kontraktsvilkår  
  «Produktgaranti vekselretter skal være minimum 10 år.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-065** · skal · commercial · kontraktsvilkår  
  «Produkter som ikke oppfyller krav, skal erstattes/utbedres kostnadsfritt ved overlevering.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-066** · skal · commercial · kontraktsvilkår  
  «Produktgaranti montasjesystem minimum 15 år.»  
  [ ] ja  [ ] nei  rett: ______

### Side 7: Idriftsettelse

- **sauda-067** · skal · technical · kravspesifikasjon  
  «Oppstart av anlegg, etterkontroll og prøvedrift skal gjennomføres i henhold til NS 6450:2016»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-068** · skal · technical · kravspesifikasjon  
  «Anlegget skal måles med eget apparat for Voc, Isc, polaritetstest, solinnstråling (W/m2).»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-069** · skal · technical · kravspesifikasjon  
  «Inverter skal testes for utkobling ved utfall av spenning fra nettet.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-070** · skal · functional · kravspesifikasjon  
  «Anlegget skal være ferdig koblet mot online plattform for produksjonsovervåkning.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-071** · skal · functional · kravspesifikasjon  
  «Entreprenør skal lage sjekkliste og kommentar rundt testene»  
  [ ] ja  [ ] nei  rett: ______

### Side 7: Overtagelse og første driftsår

- **sauda-072** · skal · functional · kravspesifikasjon  
  «Det skal gjennomføres visuell inspeksjon av anlegget.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-073** · skal · functional · kravspesifikasjon  
  «Entreprenør skal gjennomgå anlegget med BH og lokalt brannvesen før overlevering»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-074** · skal · commercial · kontraktsvilkår  
  «Service, tilsyn og vedlikehold for første driftsår skal være inkludert i leveransen.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-075** · skal · commercial · kontraktsvilkår  
  «skal disse utbedres uten ekstra kostnader innen kort tid.»  
  [ ] ja  [ ] nei  rett: ______

### Side 7: Opsjoner

- **sauda-076** · kan · commercial · opsjon  
  «3 års service avtale, inkludert løpende fjernovervåkning og årlig inspeksjon av anlegget.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-077** · kan · technical · opsjon  
  «Oppgradering av eksisterende EL-tavle»  
  [ ] ja  [ ] nei  rett: ______

### Side 8: Krav tilbud

- **sauda-078** · skal · commercial · tilbudsinnhold  
  «Leverandør skal lage en mappestruktur tilsvarende det som er foreslått under.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-079** · skal · commercial · tilbudsinnhold  
  «Ferdig utfylt prisskjema»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-080** · skal · commercial · tilbudsinnhold  
  «Ferdig utfylt UE registreringsskjema dersom bruk av UE.»  
  *Merknad: Betinget: gjelder bare dersom underentreprenør brukes.*  
  [ ] ja  [ ] nei  rett: ______
- **sauda-081** · skal · commercial · tilbudsinnhold  
  «Ferdigutfylt fremdriftsplan.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-082** · skal · qualification · tilbudsinnhold  
  «Internt kvalitetssikringssystem og standard risikovurdering.»  
  [ ] ja  [ ] nei  rett: ______

### Side 8: Forbehold

- **sauda-083** · skal · commercial · frist  
  «Solcelleanlegget skal være ferdig tilknyttet og funksjonstestet senest innen 01.06.25.»  
  [ ] ja  [ ] nei  rett: ______
- **sauda-084** · skal · functional · kontraktsvilkår  
  «Det må påregnes koordinering mellom solcelleleverandør og takentreprenør»  
  [ ] ja  [ ] nei  rett: ______


## Når du er ferdig

Skriv navnet ditt og datoen her: **Gjennomgått av:** ______ **Dato:** ______

Si fra til orchestrator-1. learning-1 eller data-1 fører avkryssingene inn i `sauda-kravspek.json`
(`status` → `godkjent`/`avvist`/`rettet`, `reviewedBy` = navnet ditt). Deretter flyttes fasiten til
`crm/eval/krav-gold/`, og forhåndsregistreringen for agent 1.2 kan skrives. Ingen rad brukes som fasit
før du har krysset den av.
