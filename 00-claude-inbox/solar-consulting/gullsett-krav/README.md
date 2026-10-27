# Gullsett for kravuttrekk og kvalifikasjon (AG-01 bølge 1.5): utkast

data-1, 2026-10-17. Laget sammen med learning-1 (eval-standard: `projects/anbud/docs/agenter.md` §4.2).
Status: `EXPERIMENTAL`. **Ingen rad er godkjent.** Alle rader har `status: "forslag"` til operatøren
(eller juristen for juridiske rader) har satt `godkjent`/`avvist` og `reviewedBy`.

Formål: måle agent 1.2 (kravuttrekk og kvalifikasjon) før den går i prod. Krav til agenten: recall
for skal-krav ≥ 0,9, presisjon for kategori og rolle, andel verifiserte sitater. Tallene fastsettes
endelig i en forhåndsregistrering før første eval-kjøring, på samme måte som SC-04.

## Hvorfor fila ligger i Brain og ikke i repoet ennå

`data/sources/doffin.json` har `storage_rights: UNKNOWN`. Kunngjøringstekst og konkurransegrunnlag
legges ikke i git før det er avklart. Sauda-kravspeken er skrevet av Solarconsulting selv
(forsiden: «Solarconsulting.no», versjon 2, 27.02.2025), så den kan ligge i repoet. Når fasiten er
godkjent, flyttes skjemaet og Sauda-fila til `crm/eval/krav-gold/`, og resten refereres med
dokument-id og sha256.

## Skjema (én rad per krav)

| Felt | Verdi | Merknad |
|---|---|---|
| `id` | `sauda-001`, `opp670-q01` … | stabil |
| `docId` | `sauda-kravspek-v2`, `doffin-<external_id>`, senere `doc-<documents.id>` | |
| `page` | PDF-sidenummer, 1-basert (ikke trykt sidetall) | `null` for kunngjøringsfelt |
| `section` | overskrift i dokumentet | |
| `quote` | ordrett, whitespace normalisert | sjekkes maskinelt mot `pdftotext -layout` |
| `quoteVerified` | `true` når sitatet finnes i teksten | |
| `obligation` | `must` · `should` · `nice-to-have` | samme enum som `lib/requirements.ts:9` |
| `category` | `qualification` · `technical` · `functional` · `security` · `commercial` · `legal` · `other` | samme enum som `lib/requirements.ts:8` |
| `role` | `kvalifikasjonskrav` · `avvisningsgrunn` · `tildelingskriterium` · `kravspesifikasjon` · `kontraktsvilkår` · `tilbudsinnhold` · `frist` · `opsjon` | nytt felt: skillet orchestrator-1 ba om (kvalifikasjon/tildeling/annet) |
| `espdCode` | eForms-kode når oppdragsgiver har oppgitt den | fasit for klassifisering |
| `labelSource` | `data-1 forslag` · `oppdragsgiver (eForms)` · `menneske` | |
| `status` | `forslag` → `godkjent` / `avvist` / `rettet` | bare et menneske flytter den |
| `proposedBy`, `reviewedBy`, `note` | | |

Maskinlesbart skjema: [`schema.json`](schema.json).

## Innhold nå

| Fil | Kilde | Rader | Status |
|---|---|---|---|
| [`sauda-kravspek.json`](sauda-kravspek.json) | `~/code/Veldora/Generell_kravspesifikasjon_-_Solcelleanlegg_kommunale_boliger_Sauda_kommune.pdf`, 8 sider, sha256 `bb20054a…f237f` | **84** (63 kravspesifikasjon, 9 kontraktsvilkår, 7 tilbudsinnhold, 2 frist, 2 opsjon, 1 kvalifikasjonskrav) | forhåndsutfylt av data-1. 84/84 sitater er verifisert maskinelt mot teksten |
| [`eforms-4-kunngjoringer.json`](eforms-4-kunngjoringer.json) | `tenders.qualification_criteria`/`award_criteria` for muligheter 670, 464, 1016, 814 (Doffin, offentlige kunngjøringer) | **116** (100 avvisningsgrunner, 7 kvalifikasjonskrav, 9 tildelingskriterier) | mekanisk uttrekk. Kategorien er oppdragsgiverens egen |

**Hva Sauda tester, og hva den ikke tester:** en ren kravspesifikasjon med mange tekniske skal-krav.
Den har nesten ingen kvalifikasjonskrav (1: DSB-registrering) og ingen tildelingskriterier, så den
måler recall og klassifisering av tekniske krav, ikke kvalifikasjon.

**Funn ved uttrekket:** `pdftotext` mister ligaturen «ff» («e ektivitet», «anska elsen»).
Sitatverifiseringen må sammenligne mot samme uttrekk som agenten ser. Ellers feiler ordrette sitater
på korrekte krav. `ASSUMPTION`: `lib/documents/extractText` har samme egenskap. Det er ikke sjekket.

**De 100 avvisningsgrunnene er standardtekst** (ESPD-oppsettet, rundt 25 per kunngjøring). Det har lite verdi som
fasit for uttrekk, men det er riktig å ha dem med, for agenten skal ikke telle dem som egne krav. De 7
kvalifikasjonskravene og 9 tildelingskriteriene er de verdifulle radene.

## Gratis fasit vi ikke brukte før

`FACT` (`crm/eval/eforms-kriterier-dekning-2026-10-17.txt`, prod read-only): **269 av 5 305 Doffin-kunngjøringer
har strukturerte kvalifikasjonskriterier**, med til sammen 937 utvelgelseskriterier, der oppdragsgiver selv har
satt ESPD-koden (31 ulike koder). **3 634 har strukturerte tildelingskriterier.** TED-kunngjøringene har 0.
Det er et merket datasett for klassifisering av kvalifikasjonskrav (`lib/qualification/classify.ts` +
`llmClassifier.ts`) uten menneskelig arbeid. Forbehold: `slc-stand-other` (238) er en sekkepost, og
oppdragsgiveres koding er ikke kvalitetssikret. Bør brukes i bølge 1.2-evalen for kategori, men ikke for uttrekk.

## Det som mangler: 10 konkurransegrunnlag operatøren må laste ned

Alle 50 muligheter teamet har sagt ja eller undersøk til, har **0 dokumenter** i CRM-et
(`crm/eval/gullsett-kandidater-2026-10-17.txt`). Dokumentene ligger bak innlogging i portaler, og ARCHITECTURE §10
sier at de hentes av et menneske eller med operatørens egen sesjon (hyyr: samme, `learning-1/hyyr-droppet`).
Forslaget velger åpne konkurranser vi har sagt ja til, spredt på portal og oppdragstype. Hver nedlasting
er altså også et grunnlag for et faktisk tilbud (bølge 1.1):

| # | Mulighet | Tittel | Oppdragsgiver | Portal | Frist | Hvorfor |
|---|---|---|---|---|---|---|
| 1 | 116 | Ny skybasert EPJ-løsning for Innherred Interkommunale Legevakt IKS | Innherred anskaffelser | hyyr | **20.10** | STRONG_BID, lang beskrivelse |
| 2 | 252 | Medarbeiderundersøkelse og pulsmålinger | Horten kommune | hyyr | 21.10 | STRONG_BID, undersøkelser-scope |
| 3 | 460 | Kommunalt innfordringssystem | Bjørnafjorden kommune | TendSign | 26.10 | STRONG_BID, fagsystem |
| 4 | 377 | 26182 Saksbehandlingsløsning | Innkjøpskontoret AS | Artifik | 27.10 | STRONG_BID |
| 5 | 212 | Skybasert sak- og arkivsystem til Arbeidstilsynet (2. utlysning) | Arbeidstilsynet | EU-Supply | 29.10 | BID, stat |
| 6 | 1016 | Kjøp av tjeneste – SMS Gateway | Trondheim Renholdsverk AS | Mercell | 29.10 | har også eForms-fasit, så uttrekket kan kryssjekkes |
| 7 | 440 | Accounting, wages and HR services for Luftambulansetjenesten HF | Sykehusinnkjøp HF | Ivalua | 02.11 | BID, engelsk grunnlag |
| 8 | 1085 | Nytt biblioteksystem til vidaregåande skolebibliotek | Møre og Romsdal fylkeskommune | hyyr | 10.11 | BID, nynorsk, har tildelingskriterier i eForms |
| 9 | 959 | Fagsystem for PPT- og logopedtjenesten i Nord-Østerdal | Abakus AS | hyyr | 13.11 | BID, har tildelingskriterier i eForms |
| 10 | 821 | Møtegjennomføringsverktøy | Halden kommune | Mercell | 13.11 | STRONG_BID |

Reserve: 670 (Billedarkiv, Artifik, har eForms-kvalifikasjon), 837 (Valgdirektoratet, TendSign, konsulent).

**KOFA-PDF-ene (39 i dokumentarkivet) er avgjørelser, ikke konkurransegrunnlag.** De siterer krav og
tildelingskriterier fra saken, så de egner seg som negativ kontroll («var dette kravet ulovlig eller uklart?»), ikke
som fasit for uttrekk. Forslag: 3 KOFA-saker om avvisning tas med i bølge 1.2-evalen som kontroll, ikke som gullrader.

## Hvordan fasiten godkjennes

1. Operatøren laster ned grunnlagene for 1–10 og laster dem opp på muligheten i CRM-et (dokumentfanen).
   Det starter `extract-requirements` som i dag, og den eksisterende kjeden gir et første forslag gratis.
2. data-1 forhåndsutfyller fasitrader per dokument som for Sauda: ordrett sitat, side, rolle og kategori, maskinelt sitatsjekket.
3. Operatøren går gjennom radene i ett regneark eller én visning: `godkjent` / `avvist` / `rettet` + `reviewedBy`.
   Anslått tid: 10–15 minutter per dokument for et utvalg. Ikke alle rader trenger godkjenning hvis vi
   forhåndsregistrerer at et tilfeldig utvalg på 30 % godkjennes og avviksraten rapporteres.
4. Når fasiten er godkjent, fryses den med manifest og hash (som `eval/testsett/`), og den brukes aldri til å tune.

## Åpne spørsmål til operatøren

- Kan vi lagre kunngjøringstekst og konkurransegrunnlag i git (`doffin.json` `storage_rights: UNKNOWN`)? Ellers
  ligger fasiten i Brain, og repoet har bare id og hash.
- Hvem laster ned de 10 grunnlagene, og innen når? Nr. 1 og 2 har frist 20. og 21.10.
