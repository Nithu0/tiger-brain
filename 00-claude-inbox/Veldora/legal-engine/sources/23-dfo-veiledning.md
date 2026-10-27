# 23 — DFØ / anskaffelser.no (veiledningslaget)

Researchagent 2026-10-15; **rettskildeklasse-sitatet etterprøvd av admin-1 i egen terminal samme dag**
(curl mot veilederens kapittel 1 — ordlyden stemmer ordrett).

## 1. Maskinlesbar tilgang: finnes ikke utover sitemap og RSS

| Kanal | Status | Merknad |
|---|---|---|
| API for innhold | **FINNES IKKE** | Søk i sitemap (888 URL-er) etter «api» gir bare DFØs interne lønns-API for HR-kunder — irrelevant |
| `anskaffelser.no/sitemap.xml` | 200, 888 URL-er med `lastmod`/`changefreq` | Nærmeste vi kommer maskinlesbart for veiledningstekst |
| `dfo.no/sitemap.xml` | 200 | — |
| `anskaffelser.no/rss.xml`, `dfo.no/rss.xml` | 200 | Nyhetsarkiv |
| robots.txt (begge, etter 301) | Kun `Disallow: /core/`, `/profiles/`, `/README.md` (Drupal-standard) | Innhold under normale node-URL-er er tillatt å hente |

**Konsekvens:** veiledningen må hentes som HTML. Det er en annen pipe enn Lovdata-XML — vår
`legal/parse.ts` tar XML, så dette krever en HTML→tekst-gren.

## 2. Innholdet som er relevant

| Innholdstype | URL | Format | Oppdatering |
|---|---|---|---|
| Veileder til anskaffelsesforskriften (kap. 1-36) | `anskaffelser.no/veileder-til-anskaffelsesforskriften/1-innledning` | HTML, kapitler | Ad hoc; kap. 1 viser til lovendring 1. juli 2026 |
| Veileder til anskaffelsesloven | `anskaffelser.no/veileder-til-anskaffelsesloven/1-innledning` | HTML | Ad hoc |
| Terskelverdier | `anskaffelser.no/anskaffelsesregelverk/terskelverdier-offentlige-anskaffelser` | HTML-tabell + PDF | JSON-LD `dateModified: 2026-06-29`; EØS-beløp revideres hvert 2. år |
| SSA-oversikt + 14 avtalemaler (K, O, T, S, V, D, B, R, L, F, Lille/Store Sky, Innovasjonspartnerskap) | `anskaffelser.no/verktoy/mal/ssa-*` | Word/PDF | Kadens UKJENT |
| «Kunngjøringer av offentlig anskaffelser» (Doffin-metadata) | `data.dfo.no/datasets/0ae16586-ddbd-463a-bac3-ecc57f33e4d3` | CSV, DCAT-AP-NO | FDK-metadata `modified: 2026-03-13` |

## 3. Terskelverdiene løser IKKE hullet vårt

Dette var hovedspørsmålet, og svaret er nei:
- Datoen for ikrafttredelse står **i brødtekst**: «De nåværende EØS-terskelverdiene trådte i kraft
  21. april 2026, og gjelder fram til nye vedtas.» (hentet 2026-10-15).
- Tallene står i en vanlig **HTML-tabell**, ikke JSON/CSV.
- PDF-en ligger på `/sites/default/files/2026-04/oversikt-nye-eos-terskelverdier.pdf` — **URL-en har
  datostempel i stien**, så adressen endres ved neste revisjon. Ingen stabil maskinlesbar adresse.

**Vurdering:** vår tomme `terskelverdier.json` kan altså ikke fylles automatisk fra DFØ uten å skrape
en HTML-tabell og overvåke en PDF-lenke som flytter seg. Det er mulig, men det er ikke den «stabile
kilde»-løsningen jeg håpet å finne — og det styrker dagens valg: juristen fyller tabellen med
`status: FACT`, dato og primærkilde, og den er en datert hurtigbuffer.

## 4. Rettigheter: uavklart for teksten, åpen for det ene datasettet

- **Ingen NLOD- eller CC-merking funnet** for veiledningsteksten (ingen lisenslenke i footer, bare
  «Personvern» og «Tilgjengelighet»). Den avgjørende setningen er **fraværende** — altså
  `licence_status: UNKNOWN`, behandles som opphavsrettslig vernet, ikke som åpne data.
- **Doffin-metadata-datasettet er CC BY 4.0** (lisens-URI fra FDK: `creativecommons.org/licenses/by/4.0/deed.no`).
  Det dekker kunngjøringsmetadata i CSV — **ikke** veiledningsteksten og **ikke** dokumentene bak
  kunngjøringene.

## 5. Rettskildeklassen, med DFØs egne ord (verifisert ordrett)

> «DFØ gjør oppmerksom på at det vil være domstolene som har det avgjørende ordet når det gjelder
> tolkninger av anskaffelsesreglene. Vurderinger som er gitt i veilederen, er derfor av rådgivende
> karakter.»

Hentet fra kapittel 1 i veilederen 2026-10-15, etterprøvd av admin-1. Dette er **kildens egen**
klassifisering, ikke vår tolkning, og den hører direkte inn i rettskildeklasse-enumen:
**veiledning = rådgivende, aldri bindende rett.** Samme avsnitt presiserer at rettsutviklingen er
løpende, og at avgjørelser referert i veilederen ikke nødvendigvis er relevante for all fremtid —
et argument for å datostemple veiledningsutdrag ved inntak.

## 6. data.norge.no: ett relevant datasett, ikke tre

Verifisert mot FDK-søke-API-et (`POST search.api.fellesdatakatalog.digdir.no/search/datasets`, åpent,
200):
- «Doffin» → 2 treff, hvorav **ett relevant**: Kunngjøringer av offentlig anskaffelser (DFØ, CSV, CC BY 4.0)
- «KOFA» → **0 treff**
- «terskelverdier offentlige anskaffelser» → **0 treff**
- «leverandørregister» → **0 treff**

## 7. Skjemafelt

| id | url | access_method | auth | fetchable | storage/ai-rights | licence_status |
|---|---|---|---|---|---|---|
| `dfo-veileder-forskrift` | anskaffelser.no/veileder-til-anskaffelsesforskriften/* | HTML-henting | ingen | GREEN | **UNKNOWN** | UNKNOWN (ingen erklæring funnet) |
| `dfo-terskelverdier` | anskaffelser.no/anskaffelsesregelverk/terskelverdier-… | HTML-tabell + datostemplet PDF | ingen | GREEN (men ustabil PDF-URL) | UNKNOWN | UNKNOWN |
| `doffin-kunngjoringer-csv` | data.dfo.no/datasets/0ae16586-… | CSV via FDK | ingen | GREEN | **OK** | **CC BY 4.0 (verifisert)** — krever navngivelse |

## 8. Slik ville vi koblet den

- Ny vert i allowlisten `crm/src/lib/http.ts` (`anskaffelser.no`, ev. `data.dfo.no`).
- **Ny parser-gren:** veiledningen er HTML, ikke Lovdata-XML, så `legal/parse.ts` dekker den ikke.
- **Eget ID-skjema:** `lov/<dato>-<nr>/§X/ledd-n` passer ikke en veilederside. Veiledning trenger en
  egen `kind` og en egen ID-form, ellers forurenses rettskildekorpuset.
- **Rettighetsgaten bør være eksplisitt:** `licence_status: UNKNOWN` skal logges, ikke behandles som
  avklart. ADR-0010 tillater intern bruk, men «ingen erklæring funnet» er ikke det samme som «fritt».
