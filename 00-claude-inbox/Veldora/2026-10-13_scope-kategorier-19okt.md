# Tallgrunnlag for 19.10-beslutningen: ja-er per kandidatkategori

`FACT` Målt mot produksjon read-only 2026-10-13, kode `6cc89c2`. Lukker `TODO` i
[`strategy/proposals/2026-10-12-tre-scopes.md`](../../../../strategy/proposals/2026-10-12-tre-scopes.md) § 3.
Rådata: [`scope-kategorier-19okt-2026-10-13.txt`](scope-kategorier-19okt-2026-10-13.txt).
Reproduser: `cd projects/anbud/crm && ./scripts/baseline/run-triage-baseline.sh --sql scope-kategorier-19okt.sql`

> **LES § «Etterprøvd 13.10» NEDERST FØRST.** admin-1 fant tre feil i nøkkelordene mine, og
> etterprøvingen flyttet tall: dialog/RFI-aksen er **13 ja, ikke 8**, og bare **17 av 30 ja** er
> reelle konkurranser. Tabellen rett under er den opprinnelige målingen og beholdes for sporet.

**Grunnlaget er 105 beslutninger** (ja 30 · nei 69 · undersøk 6), ikke 97. Ja = STRONG_BID + BID.

## Svaret, kort

**De tre foreslåtte scopene dekker 3 av 30 ja. Kategorien med flest ja — 8 — er den som står
som «ut of scope».** Og 16 av 30 ja treffer ingen av de sju kategoriene i det hele tatt.

| # | Kategori | Status i forslaget | ja | nei | undersøk |
|---|---|---|---|---|---|
| 7 | **dialog-rfi** | «out of scope», omstridt (§ 4) | **8** | 19 | 1 |
| 4 | saksbehandling | utsatt | 2 | 3 | 0 |
| 1 | **kvalitetssystem** | **foreslått (kjernen)** | **1** | 3 | 1 |
| 2 | **rapportering renhold/lekeplass** | **foreslått** | **1** | 2 | 1 |
| 3 | **medarbeiderundersøkelse** | **foreslått** | **1** | 0 | 0 |
| 5 | oversettelse | utsatt | 1 | 0 | 0 |
| 6 | regnskapssystem | ut | 1 | 3 | 0 |

Kategoriene overlapper (én sak kan treffe flere), derfor også:

| Spørsmål | ja | nei | undersøk | Tag |
|---|---|---|---|---|
| Treffer minst én av de **tre foreslåtte** | **3** | 5 | 1 | `MOTE_TOP3_COVER` |
| Treffer **ingen** av de tre foreslåtte | **27** | 64 | 5 | `MOTE_NONE_TOP3` |
| Treffer **ingen** av alle sju | **16** | 45 | 4 | `MOTE_NONE_ALL7` |

## Hvor tallgrunnlaget er for tynt til å bære en beslutning

**Det er det, for valget mellom de tre foreslåtte.** Hver av dem har nøyaktig **ett** ja. Med n = 1
kan man ikke rangere dem mot hverandre — forskjellen mellom 1 og 1 er ikke en forskjell. Svaret
på «hvilken av de tre har mest markedsstøtte i triagen» er **vi vet ikke**, og det blir ikke
bedre før det kommer flere beslutninger.

Det tallgrunnlaget *kan* bære, er en sammenligning mot kategorien som ble lagt til side:
8 mot 1 er en forskjell som holder selv på 105 beslutninger.

Sakene bak hvert ja-treff, slik at hver celle kan etterprøves (`JA_TITTEL`):

- **kvalitetssystem (1):** «Kvalitetssystem».
- **rapportering renhold/lekeplass (1):** «BME X 2026-07 RFI – Markedskartlegging av fagsystem
  for lekeplasskontroller». **Dette er samme sak som et av dialog-RFI-treffene.** Scope 2s eneste
  markedsbevis er altså en markedsdialog — nøyaktig den sakstypen forslaget vil holde utenfor.
- **medarbeiderundersøkelse (1):** «Medarbeiderundersøkelse og pulsmålinger».
- **saksbehandling (2):** «26182 Saksbehandlingsløsning» og «Anskaffelse av tilgang til
  KI-tjenester for Energidepartementet» — den siste er sannsynligvis et nøkkelordstreff i
  beskrivelsen, ikke en saksbehandlingsanskaffelse. Regn kategorien som 1–2, ikke 2.
- **oversettelse (1):** «Framework Agreement for Norwegian-Northern Sami Translation Services».
- **regnskapssystem (1):** «Kommunalt innfordringssystem».
- **dialog-rfi (8):** markedsdialog om kommunale gebyrer · RFI lekeplasskontroller ·
  markedsdialog innkjøpsløsning · markedsdialog inkassosystem (Bodø) · markedsdialog KGV/KAV ·
  markedsdialog timeregistrering/internfakturering · RFI national service for targeted health
  advice · veiledende kunngjøring konsulentavtaler digitalisering.

## Kriterium 3: «små kontrakter finnes, slik at første referanse kan komme under terskelverdi»

**Kriteriet kan ikke bekreftes, og det kan ikke avkreftes.** Grunnen er en datamangel:

`FACT` `awards` har 552 rader, men **bare 54 har et beløp** (`AWARD_TOTAL`). Premisset «du har
`awards` = 552 rader med verdi» holder ikke — 90 % av tildelingene mangler beløp.

Tildelinger i kategoriene, etter beløp (`AWARD_BAND`):

| Kategori | Tildelinger | Med beløp | Minste | Største |
|---|---|---|---|---|
| kvalitetssystem | 8 | 2 | 5,1 MNOK | 15 MNOK |
| rapportering renhold/lekeplass | 3 | 2 | 2,5 MNOK | 15 MNOK |
| saksbehandling | 2 | 2 | 8 MNOK | 8 MNOK |
| regnskapssystem | 5 | 1 | 116 MNOK | 116 MNOK |
| oversettelse | 7 | 0 | — | — |
| dialog-rfi | 3 | 0 | — | — |
| **medarbeiderundersøkelse** | **0** | 0 | — | — |

**Ingen tildeling med kjent beløp i noen av kategoriene ligger under 2,2 MNOK.** Alle sju med
beløp er 2,5 MNOK eller mer. Og EØS-flagget fra kunngjøringen (`AWARD_EEA`, `FACT` fra kilden)
peker samme vei: kvalitetssystem 7 over / 1 under, rapportering 3 over, saksbehandling 2 over,
regnskap 5 over, oversettelse 4 over + 3 ukjent, dialog-rfi 2 over + 1 ukjent.

Tolkningen må være forsiktig: når 90 % av beløpene mangler, er «vi ser ingen små kontrakter»
like forenlig med at små kontrakter ikke blir registrert med beløp som med at de ikke finnes.
Men `ASSUMPTION`-en i forslagets § 3 («`ASSUMPTION` ja» for kvalitetssystem og renhold/lekeplass)
har ingen støtte i dataene, og **medarbeiderundersøkelse har null tildelinger i det hele tatt** —
det samme punktet forslaget selv merket `UNKNOWN` i § 4.

Båndgrensene (100k / 1,4M / 2,2M) er **min** inndeling: forslaget sier «under terskelverdi» uten
tall, og repoet definerer ingen terskelkonstant. Operatøren må bekrefte hvilket nivå som gjelder.

## De to taksonomiene

Beslutningen handler om møte-kategoriene, men koden kjenner bare sporene. Derfor begge:

**A. De 9 sporene** (`opportunities.scope_category`, beregnet av produksjonen med full
beskrivelse — `FACT`, `SPOR`): fagsystem 13 ja/11 nei · utvikling-ki 8/7 · undersokelser 2/1 ·
dokument-ai 1/1 · oversettelse 1/0 · rapportering 1/0 · solenergi 0/1 · utenfor-scope 4/48.

**B. De 7 møte-kategoriene** er tabellen øverst. Nøkkelordene er **mine**, skrevet for denne
tellingen (`ASSUMPTION`) — de står i `scripts/baseline/scope-kategorier-19okt.sql` og bør leses
før tallene brukes. `eval-scope-categories.ts` kan ikke svare på B; den kjenner bare sporene.

Kryssmapping for ja-ene (`KRYSS`) viser hvorfor én taksonomi ikke kan erstatte den andre:
`fagsystem` inneholder både dialog-rfi (4), kvalitetssystem (1), regnskapssystem (1) og
saksbehandling (1); `utvikling-ki` inneholder dialog-rfi (3) og saksbehandling (1).
Sporet «fagsystem» er altså en sekk, ikke en kategori.

## Hva dette betyr for 19.10

Ikke en anbefaling — jeg teller, operatøren velger. Men tre ting følger direkte av tallene:

1. Forslagets eget § 7-kriterium er utløst: «050 viser at en annen kategori har flere ja-er enn
   medarbeiderundersøkelse.» Det har den — dialog-rfi, 8 mot 1.
2. Å holde dialoger og RFI-er utenfor scope fjerner den største enkeltgruppen av ja. Forslagets
   § 4 sa det som en innvending; her er tallet. Issue 053s linje (merk dem, ikke skjul dem) er
   den dataene støtter.
3. 16 av 30 ja ligger utenfor alle sju kategoriene. Uansett hvilke tre som velges, dekker de en
   minoritet av det operatøren faktisk sier ja til. Det er ikke et argument mot å velge tre —
   men valget bør tas på strategi, ikke på at tallene peker dit, for det gjør de ikke.

## Rettelse 2026-10-13 (lagt til av learning-1 etter at tallene ble videreformidlet)

Tabellen øverst lister **dialog-rfi som en kategori på linje med de seks andre. Det er feil, og
det er min feil.** De seks andre er *hva anskaffelsen handler om*; dialog/RFI er *hvilken type
kunngjøring det er*. Det er to akser, ikke sju kategorier på én akse.

Det ser man direkte i de åtte dialog-RFI-ja-ene: de handler om kommunale gebyrer, lekeplass-
kontroll, innkjøpsløsning, inkasso, KGV/KAV, timeregistrering, helseråd og konsulentavtaler —
altså åtte ulike fagområder. «Dialog/RFI» er ikke et produktscope man kan bygge mot; det er
formen anskaffelsen ble kunngjort i.

Hva som derfor **ikke** følger av tallene: at dialog/RFI burde være et fjerde scope, eller at det
«vinner» over de tre foreslåtte. Den sammenligningen er kategorifeil.

Hva som **fortsatt** følger, og som er det substansielle funnet:

1. **8 av 30 ja er markedsdialoger og RFI-er.** Å holde den sakstypen utenfor scope fjerner
   27 % av det operatøren faktisk sier ja til, uansett hvilke fagscopes som velges. Issue 053s
   linje — merk dem, ikke skjul dem — er den dataene støtter.
2. **Scope 2s eneste ja er en RFI.** Det er ikke «én sak tellet to ganger»; det er at det eneste
   markedsbeviset for renhold/lekeplass-rapportering kom inn som en markedsdialog. Utelukker vi
   dialoger, står scope 2 igjen med null bevis.
3. De tre foreslåtte scopene har fortsatt nøyaktig ett ja hver, og 16 av 30 ja treffer ingen av
   de seks fagkategoriene. Det tallet er uendret av rettelsen.

Riktig måling av dialog/RFI-aksen er en krysstabell sakstype × fagkategori, ikke en rad i samme
tabell. `tenders.notice_type` finnes i basen (`crm/src/lib/triage.ts` bruker den som
`noticeKind`-filter), så det er målbart — men det er en ny telling, ikke en omskriving av denne.

---

## Etterprøvd 13.10 — admin-1s tre innvendinger, målt

Kjørt etter at admin-1 leste nøkkelordene mine fra commit `3ddf75f`. Kilde:
[`sakstype-kryss-2026-10-13.txt`](sakstype-kryss-2026-10-13.txt), skript
`scripts/baseline/sakstype-kryss.sql`. Alle tre innvendingene var gyldige. To av dem flyttet tall.

### 1. `~*` uten ordgrenser — reell, men den kostet én rad

`RFID_TREFF`: **én** beslutning i hele settet nevner RFID, og den er et **nei**. Delta med og uten
ordgrense på dialog-mønsteret: `med-ordgrense` 8 ja / 18 nei / 1 undersøk mot `uten-ordgrense`
8 ja / **19** nei / 1. Delstreng-treffet blåste altså opp nei-tallet med én rad og **lot ja-tallet
stå urørt**. 19.10-tallet overlever punkt 1.

`ERP` var verre: 3 rader (1 ja, 2 nei) traff bare uten ordgrense, mot 1 nei med. Kategorien
`regnskapssystem` falt derfor fra 4 treff til 2 da grensene kom tilbake — den var delvis bygget
på delstrenger. Ordgrensene står nå i `sakstype-kryss.sql`; `scope-kategorier-19okt.sql` beholdes
uendret som sporet av den første målingen.

### 2. «Alminnelig anbudsprosa» — bekreftet for ett nøkkelord, avkreftet for ett annet

`TREFF_TITTEL` måler presisjon ved å skille treff i tittel fra treff bare i beskrivelsen:

| Kategori | Treff | I tittel | Bare i beskrivelse |
|---|---|---|---|
| kvalitetssystem | 5 | **4** | 1 |
| saksbehandling | 5 | **1** | **4** |
| rapportering renhold/lekeplass | 4 | 2 | 2 |
| regnskapssystem | 2 | 1 | 1 |
| medarbeiderundersøkelse | 1 | 1 | 0 |
| oversettelse | 1 | 1 | 0 |

admin-1 har rett om **saksbehandling**: fire av fem treff kommer fra beskrivelsen, altså prosa.
Og feil om **kvalitetssystem**: fire av fem står i tittelen, som er et sterkt belegg.
`internkontroll` og `befaring` fanges av det samme målet — de to kategoriene de sitter i er
nettopp dem med lavest tittelandel.

### 3. Enhetsfeilen — den alvorligste, og den er større enn vi trodde

Målt på kildens eget felt `tenders.notice_type`, ikke på mine nøkkelord (`SAKSTYPE`, `ENHET`):

| Sakstype | Beslutninger | ja | nei |
|---|---|---|---|
| **COMPETITION** (konkurranse, tildeling å vinne) | 60 | **17** | 39 |
| **PLANNING** (veiledende kunngjøring / markedsdialog) | 45 | **13** | 30 |

**13 av 30 ja (43 %) er førkonkurranse-dialog, ikke konkurranser.** Mitt keyword-tall på 8
*undertelte* aksen — den riktige målingen gjør admin-1s innvending sterkere, ikke svakere.

Konsekvensen for 19.10, med enhetene holdt fra hverandre:

| | ja på konkurranse | ja på dialog |
|---|---|---|
| kvalitetssystem | 1 | 0 |
| medarbeiderundersøkelse | 1 | 0 |
| **rapportering renhold/lekeplass** | **0** | **1** |
| saksbehandling | 2 | 0 |
| oversettelse | 1 | 0 |
| regnskapssystem | 1 | 0 |
| ingen av de fem | 11 | 12 |

**Scope 2 har null ja på en reell konkurranse.** Dets eneste markedsbevis er RFI-en om
lekeplasskontroll, altså en markedsdialog. Og av de 17 konkurranse-ja-ene treffer **11 ingen av
de fem fagkategoriene**.

### 4. isLearnable — admin-1s verste tilfelle inntreffer ikke, men noe annet gjør

`LAERBAR`: alle **6** `not-a-tender`-radene er PLANNING **og alle er nei**. Ingen av de 13
dialog-ja-ene er altså ekskludert fra læringen — admin-1s frykt («den sterkeste kategorien er
samtidig utelatt fra modellen») slår ikke til.

Men det avdekker en inkonsistens som er verdt mer: **samme sakstype behandles på to måter.** Seks
PLANNING-rader fikk `not-a-tender` og er korrekt utelatt; 13 andre PLANNING-rader fikk ja og
**trener profilen som om de var konkurranser**. `buildProfile` ser ingen forskjell på et ja som
betyr «dette vil vi by på» og et ja som betyr «dette er verdt å svare på i en markedsdialog».
Det er ikke en feil i noen telling — det er en feil i målvariabelen, og den gjelder 43 % av ja-ene.

`SAKSTYPE_KO`: PLANNING er 202 av 1750 kunngjøringer (11,5 %) men 45 av 105 beslutninger (43 %).
Dialoger triageres altså ~4× så ofte som andelen i korpuset. Om det skyldes køsortering eller
operatørens valg er `UNKNOWN` — ikke målt.

### 5. Og en bekreftelse på diagnosen av issue 050

`AARSAKSKODE_UFILTRERT` fra multiselect-barnetabellen: scope 42 · core-fit 26 · own-product 15 ·
competence-gap 15 · too-large 8 · qualification 7 · not-a-tender 6 · other 5. Det er issue 050s
tall («scope 41, core-fit 26, own-product 14, competence-gap 13», målt 12.10) — altså **telt uten
filter på utfall**. `AARSAKSKODE_PER_SIDE` viser hvorfor det ikke er nei-årsaker: core-fit er
25 ja + 1 undersøk, own-product 13 ja + 2 undersøk. Diagnosen min 13.10 var riktig, og kilden er nå
navngitt: `tender_decisions_reason_codes`, ikke `primary_reason`.
