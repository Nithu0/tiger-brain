# Operatør-beslutninger — Veldora strategiråd

Samlet fra runde 1 (7 panerapporter + konfliktkart). Dette er grunnlaget for `/grill-me`-runden.
Hver post: hva som skal avgjøres, hva rådet mener og med hvilket belegg, hva det koster å utsette.

Rekkefølgen er etter hastegrad, ikke etter viktighet.

---

## 1. Tre scopes — HAR FRIST 19.10 (seks dager)

**Avgjøres:** hvilke tre løsningskategorier hver av de tre utviklerne eier fra uke 43.
**Forslaget på bordet:** kvalitetssystem, rapportering av renhold/lekeplasser, medarbeiderundersøkelse — på én felles kjerne. Saksbehandling og oversettelse utsatt, regnskapssystem ut.
**Mangler før du kan svare:** ja-per-kategori av de 105 beslutningene (learning-1 måler nå), om små kontrakter under terskelverdi finnes i disse kategoriene (learning-1, fra 552 tildelinger), KS/10-FAKTOR-forbeholdet (paal-1), og hva «få fra Malik» betyr (bare du).
**Kostnaden ved å utsette:** tre utviklere starter uke 43 uten retning, eller starter på feil ting.

## 2. Sol eller IT som første bud

**Avgjøres:** om første bud skal følge referansene eller markedet.
**Rådet, med belegg:** måledata vinner over vedtaket. 0 sol-relevante av 1653 kunngjøringer på 12 dager (PR #142), alle 30 ja i IT, `solenergi` 0 ja / 1 nei. Men ADR-0015 (ACCEPTED) bærer de fem referansene, og referanser er vinnsjanse.
**Hvorfor det er ditt:** dette er ikke et datavalg. Å bytte til IT betyr å by nesten uten referanser.

## 3. Er Veldora internt verktøy eller produkt

**Avgjøres:** om vi bygger for oss selv eller for kunder.
**Konflikten:** infra-1 og admin-1 planla multi-tenancy, DPA og tenant-isolasjon «før kunde nr. 2». paal-1 viser at den eneste nedskrevne kommersielle veien — salg til offentlige oppdragsgivere — er uforenlig med ADR-0015, der vi selv er budgiver. Habilitetskonflikt, aldri juristvurdert.
**Rådet, med belegg:** paal-1 har best belegg (ACCEPTED ADR + uløst habilitetsspørsmål + konkurrentgulv). Fire domener priset arbeid for en kunde ingen har besluttet skal finnes.
**Prislappen er uenig med seg selv:** infra-1 sier tenant-isolasjon er 3 dager, admin-1 og paal-1 sier 40+ med DPA, auth, fakturering, support og negativ test per collection. Avviket er en størrelsesorden.

## 4. Azure — kundeproduktene eller også anbudsplattformen

**Avgjøres:** ett ord, som forslaget selv ber om å få skrevet inn i en ADR «ellers starter noen en migrering».
**Rådet, med belegg:** Azure-gulv 160–200 USD/mnd mot 40–60 i dag. Null Azure-fotavtrykk (`which az` tomt, ingen subscription, ingen Entra-tenant). Stacken er alt EU-pinnet (Vercel Stockholm, Railway europe-west4). Migrering uten dokumentert kundekrav er teknologiskift uten kjøper.
**Billigste utfall:** svarer du «kundeproduktene», skrives det inn og risikoen forsvinner.

## 5. Hvor går grensen for hva systemet får gjøre selv

**Avgjøres:** om ordren «proaktiv, personalisert AI-plattform med åtte agentroller» skal begrenses.
**Rådet, med belegg:** fire roller konvergerer uavhengig mot et absolutt handlingsforbud — utdata kan aldri endre en frist, en status eller en levering uten menneskelig handling. Belegget er kode som alt gjør dette: `bid_no_bid` er alltid null, `decisionGuard.ts:5-21` nullstiller beslutningsfelt ved agentskriving, innleveringssjekklisten svarer HTTP 409 i stedet for å handle. Ingen har lagt fram belegg for at flere autonome agenter gir bedre dekning; tools-1 viser at 8 executors kjørte i 6 døgn uten at verdict-veien behandlet én sak.
**Anbefaling:** åtte roller bør bli tre tjenester og én inngang.

## 6. «OK kjør»-gaten er ikke reell

**Avgjøres:** om gaten skal håndheves teknisk.
**Belegg:** direkte push til main er tillatt (`guard-main.yml:3-6`), branch protection er Pro-gated på GitHub, auto-merge-boten krever en hardkodet strengliste — og merget over en rød port på PR #154. Boten merger også PR-er som ligger bak main uten ny CI.
**Hvorfor det er ditt:** fire av sju roller behandlet gaten som effektiv kontroll. Den er rådgivende. Enten håndhever vi den, eller vi slutter å kalle den en gate.

## 7. Kostnadstaket — markedet eller måleren

**Avgjøres:** om vi binder arkitekturen til et tak før vi har målt.
**Konflikten:** paal-1 krever under 150 kr per aktiv kunde per måned, avledet av et ARPU-anslag på 10–35k/år. infra-1 vil ikke sette tak før det er målt. Begge argumenterer fra tall de ikke har: ARPU-tallet har ingen kundesamtale bak seg, og dagens forbruk er usporet.
**Det som faktisk mangler:** `~/.firm/costs.csv` er aldri opprettet mens 8 executors har kjørt i 6 døgn. Vi har ingen kostnadshistorikk i det hele tatt.

## 8. pgvector — finnes semantisk søk som mulighet

**Avgjøres:** om Railway kan gi oss pgvector.
**Belegg:** `select extname from pg_extension` i prod gir kun `plpgsql`. `embeddings.ts:17` returnerer null og `retrieve.ts:130-143` er klargjort for pgvector — altså kode som forutsetter en extension som ikke er installert. tools-1 kalte det «en bryter og en backfill»; learning-1 spurte databasen.
**Dette er et spørsmål til Railway, ikke til rådet.**

## 9. Leverandøravhengighet

**Avgjøres:** hva produktet GJØR når modellnøkkelen er død midt i en anbudsfrist.
**Belegg:** Anthropic-kreditten var tom 11.10, og LLM-uttrekk feiler da **stille**. `LLM_PROVIDER=openai-compatible` finnes som konfigurasjon, men er aldri behandlet som beredskap.
**Minimum uansett svar:** stille feil skal bli synlig feil.

## 10. Oppryddingen ingen eier

**Avgjøres:** om vi får slette.
**Belegg:** 42 worktrees, 137 grener, 4,5 G i Veldora alene — og tallet vokste fra 39 til 42 i løpet av åtte minutter mens dette programmet kjørte. Ti ligger under `.claude/worktrees/`, altså agent-opprettede. Ingenting har en livssyklus: agenter oppretter, ingen rydder.
**Hvorfor det er ditt:** sletting av grener og worktrees er operatør-gated, og minst én gren har upushet arbeid (`infra-1/vakt-i-repo`, f47cd4d).

---

## Gater fra tidligere som fortsatt står

Disse er ikke nye, men de blokkerer fortsatt og bør avgjøres i samme runde:
passordrotasjon i node-stacken, `infra-1/leak-scan` i command-center, preview-beskyttelse i Vercel,
prod-legitimasjon til paal-1, oppbevaringstid for intern chat, Slack-speiling (`channels:history`),
og de fire ja-ene utenfor uttalt scope.

## To spørsmål rådet ikke kan svare på i det hele tatt

paal-1 ber om dagsrate og dekningsbidrag. Uten dem er både «under 150 kr per kunde per måned» og
«internt verktøy lønner seg» udokumenterte påstander, og ingen i rådet kan gjette dem.

---

# TILLEGG etter nedbrytningen (2026-10-13, senere samme dag)

Nedbrytningen og bølge 0 har endret fire av postene over og lagt til tre nye. Dette tillegget
gjelder foran teksten over der de spriker.

## NY 0. Hva ER hovedflaten — ADR-0017 mot «én arbeidskø»

**Dette er nå det første spørsmålet, foran alt annet.**
`FACT` ADR-0017 er ACCEPTED, merket *operator direction*, datert 2026-10-11 — to dager gammel — og
`/mote` er bygget med tre ruter. UX-domenet og frontend-domenet anbefaler uavhengig av hverandre
**én arbeidskø** som hovedflate: samle Triage, Til godkjenning, Innboks og Pipeline, og kutt nav
fra 25 mål til 7.

To flater kan ikke begge eie «hva skal jeg gjøre nå». Enten står ADR-0017, eller den erstattes
bevisst. Det som ikke går an er at vi bygger videre på begge.

**Målt navigasjonsstøy, til beslutningen:** 46 ruter bak 25 nav-mål i 6 grupper. 20 av de 25 er
usynlige på mobil (bak «Mer»-arket). Bare 2 av 25 har et tall som sier om noe venter. Sju faner på
opportunity-detaljsiden, fire på kompetanse, og `?fane`-mønsteret er reimplementert i 21 filer.

**Risikoen ved å kutte nav:** 21 filer leser `?fane`, `ICON_PATHS` er koblet på href-streng og gir
`<path d={undefined}>` uten typefeil, og URL-ene er delt i Obsidian og Telegram. Det finnes **ingen
bruksstatistikk i repoet** — vi vet at rutene eksisterer, ikke at de brukes. Nav-kuttet er det
enkelttiltaket som kan ødelegge en arbeidsdag.

## NY 0b. Skal vinnsannsynlighet brukes i utvalget

To ACCEPTED ADR-er peker mot hverandre. ADR-0014 pkt 2 sier `fitScore` og `winProbability`
beregnes fra dag én som ekte tall. ADR-0017 pkt 2 sier Live-filteret i fase 1 er deterministisk på
harde gates og `weMeet`, eksplisitt **ikke** på vinnsannsynlighet.

Målingen avgjør i praksis: `winProbability` har AUC 0,575 med håndsatte vekter og **0 observerte
utfall**. En tallfestet sannsynlighet uten kalibreringsdata er verre enn ingen, fordi den ser
etterprøvbar ut. Anbefaling: vis den ikke som tall før det finnes utfall å kalibrere mot.

## NY 0c. De fem agentrollene finnes allerede

Dette tar en stor del av problemstilling D av bordet, og det er verdt å vite før du ber om en
agentplattform: Scout = ingest + score + triage. Qualification = qualify/assess-requirements.
Evidence = Evidence-collection + evidencePolicy + Brreg. Bid Advisor = brief + challenge +
red-team + draft-bid. Compliance = feilsjekk/rules + legal/ask + citationJudge.

Å bygge dem som navngitte agenter duplikerer ~26 kallsteder. **Det som mangler er navngiving og én
inngang, ikke funksjonalitet.** Anbefaling: åtte roller blir tre tjenester og én inngang.

Og tale finnes ikke i det hele tatt: 0 treff på whisper/tts/speech/elevenlabs/deepgram/twilio i
hele repoet. Alle «tale»-treff er norske ord — samtale, rammeavtale, omtale. Taleassistent er
grønt felt, ikke en utvidelse, og ingenting i funnene etterspør den.

## ENDRET 4. Azure er et datalokalitetsvedtak, ikke et prisvedtak

Prisargumentet står (gulv 160–200 USD/mnd mot dagens drift), men det avgjørende er nytt:
`FACT` **Norway East har null SKU for både Document Intelligence og Speech.** OCR og tale på Azure
betyr West Europe. Det er et vedtak om hvor anbudsdokumenter og lydopptak ligger, ikke om hva de
koster.

Dessuten: operatørsvaret «Bygge på Azure» har ingen ADR og bryter ADR-0014 (Railway/Postgres som
system-of-record) og ADR-0006/0008 (Vercel). Rådet parkerer migreringen inntil en ADR avgrenser
Azure til kundeproduktene.

## ENDRET 7. Kostnadstaket er ikke lenger et åpent spørsmål

Målt, ikke antatt: **0,05 USD per anbud som full-kjede-tak, 0,028 realisert, 0,016 etter
reprising.** Hele systemet 94 USD/mnd. Begge tidligere estimater var feil — det ene 1,6×, det andre
9,7× for høyt — fordi de antok 30–150k input-tokens, mens briefen leser strukturert tekst på 2k.

Ærlig forbehold fra de to som målte: `llm_usage` har ingen anbudsreferanse, så per-anbud-tallet er
utledet fra briefs-tabellen (824 rader, 824 distinkte `opportunity_id`), ikke spurt direkte.

paal-1s krav om under 150 kr per kunde per måned er dermed oppfylt med stor margin, og **hosting er
ikke problemet**. Det fjerner en av de tre spenningene over.

Og 80 % av hele forbruket er `generate.brief` alene. Det er der en optimalisering betyr noe; de
ti andre rutingradene er marginale.

## ENDRET 1. 19.10 — svaret er at forslaget ikke holder

De tre foreslåtte scopene dekker **3 av 30 ja, ett hver** — de kan ikke rangeres mot hverandre.
**16 av 30 ja treffer ingen av de sju kategoriene.** Scope 2s eneste ja er samme sak som et
dialog-RFI-treff. Forslagets eget §7-endringskriterium er utløst.

Kriterium 3 kan ikke avgjøres: `awards` har 552 rader, bare **54 med beløp**, og ingen tildeling med
kjent beløp i noen kategori er under 2,2 MNOK. Med 90 % manglende beløp er «små kontrakter finnes
ikke» like forenlig med en datamangel som med markedet.

27 % av ja-ene er dialoger og RFI-er. Det er en sakstype, ikke et scope — de 8 dekker 8 ulike
fagområder, så det kan ikke bygges mot. Men det sier noe om hva du faktisk sier ja til.

## NY 11. Workeren kan kjøre mot feil skjema uten at noen ser det

Ikke en strategisk beslutning, men den farligste enkeltlinjen vi fant, og den bør du kjenne:
`Dockerfile:42-45` — når `ANBUD_ROLE=worker` startes workeren **før** `migrate-or-die`, og
`.railway/railway.ts` gir workeren ingen healthcheck. Skjemadrift feller bare crm-tjenesten.
Workeren eier all innhenting og scoring, og kan kjøre 52 tasks og 34 cron mot feil skjema
uoppdaget. Det er `S` å rette, og det ligger i «må gjøres først».

## Tillegg til post 4 (Azure): regionvalget er halve prisen

infra-1 avklarte mot primærkilde (Microsofts billing-dokumentasjon): Container Apps' miljøavgift
treffer **bare** Dedicated workload profiles, så en Consumption-only-oppsett slipper den. Og
Postgres B2s koster **29,1 USD/mnd i Sweden Central mot 58,1 i West Europe** — altså 2×.

Det betyr at Azure-regnestykket avhenger mer av regionvalg enn av tjenestevalg, og at de to
regionkravene trekker mot hverandre: Norway East mangler SKU for Document Intelligence og Speech,
Sweden Central er halvparten av prisen til West Europe. Skulle Azure bli aktuelt, er Sweden Central
svaret — ikke Norway East og ikke West Europe. Det er fortsatt et datalokalitetsvedtak.

---

# REVISJON av post 1 (19.10) — enhetsfeilen er målt, og den er 43 %

learning-1 etterprøvde admin-1s tre innvendinger (commit `5f65532`). Alle tre gyldige. Dette
erstatter 19.10-tallene over.

**Målt på `tenders.notice_type`, ikke på nøkkelord:** COMPETITION 60 beslutninger (17 ja) ·
PLANNING 45 beslutninger (13 ja). Altså er **13 av 30 ja — 43 % — førkonkurranse-dialog**, ikke
konkurranser. Det er ingen tildeling å vinne der; et ja er en relasjonshandling.

**Delt i riktige enheter, ja på REELLE konkurranser (17 i alt):**

| Kategori | Ja på konkurranse |
|---|---|
| Kvalitetssystem (scope 1) | 1 |
| Medarbeiderundersøkelse (scope 3) | 1 |
| **Rapportering renhold/lekeplasser (scope 2)** | **0** |
| Saksbehandling (utsatt i forslaget) | 2 |
| Oversettelse (utsatt) | 1 |
| Regnskapssystem (tatt ut) | 1 |
| **Ingen av de fem** | **11 av 17** |

**Scope 2 har null ja på en konkurranse.** Dets eneste bevis — RFI-en om lekeplasskontroll, som
forslagets § 3 kaller «det eneste konkrete markedssignalet vi har for noen av kandidatene» — er en
markedsdialog. Grunnlaget for den ene scopen med et påstått markedssignal er altså av en annen
enhet enn beslutningen krever.

**De tre foreslåtte scopene har til sammen 2 ja på reelle konkurranser.** De to kategoriene som ble
utsatt eller tatt ut har til sammen 3.

**Og en feil som er større enn tellingen:** `buildProfile` ser ingen forskjell på «dette vil vi by
på» og «dette er verdt å svare på i en dialog». Det er ikke en tellefeil, det er en feil i
**målvariabelen**, og den gjelder 43 % av ja-ene. Alle seks `not-a-tender`-radene er PLANNING og
alle er nei, så ingen dialog-ja er utelatt fra læringen — men 13 PLANNING-rader trener profilen som
om de var konkurranser. Må lukkes før noen rangeringsoppgave gates.

**Sidefunn verdt å kjenne:** PLANNING er 11,5 % av korpuset (202 av 1750) men 43 % av
beslutningene. Dialoger triageres omtrent fire ganger så ofte som andelen tilsier. Årsak `UNKNOWN`.

**Rettelser til admin-1s innvendinger, i rettferdighetens navn:** ordgrensefeilen kostet én nei-rad,
ja-tallet sto urørt — men `ERP` som delstreng halverte regnskapskategorien (4 treff til 2). Og
admin-1 hadde rett om `saksbehandling` (5 treff, bare 1 i tittel — prosa) og **feil om
`kvalitetssystem`** (5 treff, 4 i tittel — sterkt belagt).

## Rettelse: årsaken til PR #144s 27 % var feil, og #144 ble urettferdig behandlet

learning-1 retter sin egen forklaring (fixturen lot dem kjøre repoets eget
`eval-scope-categories.ts` på begge former): live tittel+beskrivelse gir **4 av 30 (13,3 %)**,
snapshot-formen slik #144 kjørte gir **5 av 30 (16,7 %)**. Snapshot-mangelen forklarer altså **én**
rad, ikke fire.

Den faktiske årsaken er **kodedrift samme dag**: #144 (`9119c12`) ble fulgt av #147 (`1f4f761`),
som utvidet dekningen med `ux`, `brukeropplevelse*`, `tjenestedesign*`, `artificial intelligence` og
digitaliseringsord — nettopp for å hente tilbake ja-er som falt utenfor. #144 målte altså riktig på
koden som fantes da den ble skrevet.

Tallet 13,3 % står. Årsaksforklaringen «metodefeil i eksporten» strykes. Dette er tredje rettelse i
samme tallkjede i dag, og mønsteret er verdt å merke seg: hver gang var tallet riktig regnet, og
hver gang målte det noe annet enn det ble brukt til.

## NY 12. Hvorfor sier du ja til dialoger? (issue 054, gater all rangering)

learning-1 har skrevet målvariabel-funnet som issue 054, og den er markert HITL fordi kjernen er et
spørsmål bare du kan svare på.

**Målt:** PLANNING er 11,5 % av korpuset (202 av 1750) men 43 % av beslutningene dine (13 av 30 ja).
Du triagerer førkonkurranse-dialoger omtrent fire ganger så ofte som andelen tilsier. Årsaken er
`UNKNOWN` — ingen har målt den, og learning-1 nekter å gjette.

**Tre forklaringer, med helt ulik konsekvens for produktet:**
1. *Dialoger er lettere å vurdere.* Da er overrepresentasjonen en artefakt av friksjon, og produktet
   skal gjøre konkurransene like lette å vurdere.
2. *De dukker opp høyere i køen.* Da er det en rangeringsfeil, og den skal rettes.
3. *Du bygger bevisst relasjoner før konkurransen kommer.* Da er det en strategi, og produktet skal
   støtte den eksplisitt — med egen flate, egne mål og egen målvariabel.

**Hvorfor det gater rangeringsarbeidet:** `buildProfile` lærer i dag på 99 blandede rader. learning-1
foreslår trinn 1 = lær bare på COMPETITION, altså 56 rader i stedet for 99. Det er færre data, men
det er data om én ting. Svaret ditt avgjør om dialogene skal ha sin egen modell, eller bare holdes ute.

Svarer du 3, er det samtidig et produktfunn: ingen av de ti konkurrentene paal-1 kartla gjør noe med
markedsdialog-fasen, og det er den fasen der en leverandør kan påvirke kravspesifikasjonen før den
er skrevet.

---

# REVISJON 2 av post 1 (19.10): KS-undersøkelsen er inne, og den rehabiliterer scope 3 delvis

learning-1, commit `99fc723`, doc `research/2026-10-13-medarbeiderundersokelser-ks-10faktor-og-pivoten.md`.
Hver påstand med URL og hentedato. 28 reelle Doffin-kunngjøringer siste tre år.

**Forbeholdet holder, men konklusjonen holder bare delvis.** 10-FAKTOR er aktiv, KF-driftet, og
**304 av 357 kommuner** har brukt den. KS **utvidet til to** instrumenter i 2026 —
«Arbeidsmiljøundersøkelser i kommunen» (Doffin 2025-109054, Agenda Kaupang, lansert 13.08.26) dekker
risiko og sykefravær der 10-FAKTOR dekker motivasjon. **Kommunesegmentet ble trangere, ikke romsligere.**

**Pivoten, segment for segment:**

| Segment | Kunngjøringer (3 år) | Dom |
|---|---|---|
| **Stat** | 14 | **Eneste segment dataene støtter** |
| Helseforetak | 0 | **AVKREFTET — ut av forslagets § 4** |
| Fylkeskommuner | 6 | Kunngjør **dobbelt så ofte som kommunene** (3) tross 10-FAKTOR |

- **Stat:** incumbenten finnes — MUST (DFØ/STAMI, **gratis**, 115 virksomheter) — men den **lekker**:
  Skatteetaten tildelt 4,7 MNOK (Winningtemp), Statsbygg 1,177 (Rambøll), Bufdir 2,2 (Rambøll),
  Politiet 4,5 utlyst, alt i 2025/26. Påstanden «staten har ingen standard» er altså feil, men
  «staten er bedre marked» holder likevel.
- **Helseforetak:** ForBedring er felles for alle HF, niende år i 2026, med oppfølgingskrav i
  oppdragsdokumentene. Segmentet er **strammere lukket enn kommunene**.
- **Fylkeskommuner:** forslaget avskriver kommunesektoren raskere enn dataene forsvarer.

**Kriterium 3 er OPPFYLT for scope 3, og mitt tidligere «ikke-svar» var en dekningsmangel hos oss.**
learning-1 retter sin egen måling: «medarbeiderundersøkelse: 0 tildelinger» kom fra vår egen
`awards`-tabell, ikke fra markedet. Doffin har flere godt under terskelverdi — Bergen BME **0,3
MNOK**, NHN 0,5, Kulturdirektoratet 0,6, Andøya 0,7. Advarselen de skrev i formiddag («med 90 %
manglende beløp er *ingen små kontrakter* like forenlig med en datamangel som med markedet») var
riktig, og det *var* datamangelen.

**Og det største funnet er om plattformen, ikke om scopet:** 28 relevante konkurranser på tre år, og
`awards` kjenner **ingen av dem**. Vi henter ikke inn dette segmentet i det hele tatt. Det er samme
klasse som `documents` med 0 rader — ikke manglende funksjonalitet, men manglende ledning.

**Konkurrentbildet dataene gir:** Rambøll (2 av 4 tildelinger), Winningtemp AB, Ennova; som
medtilbydere Sopra Steria, Eletive, CatalystOne.

**Kildehull oppgitt ærlig:** ks.no er bak Cloudflare (403 på alt), så KS' egne sider er sitert via
søkeindeks pluss ett Wayback-snapshot. `UNKNOWN`: pris på 10-FAKTOR, anskaffelsesform for
KS/KF-arrangementet, leverandør bak ForBedring, og aktiv årlig base mot «brukt minst én gang».
