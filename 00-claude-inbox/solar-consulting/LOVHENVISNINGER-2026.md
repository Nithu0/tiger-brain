# Utdaterte lovhenvisninger etter 1.7.2026: kartlegging

data-1, 2026-10-18. Oppdrag fra orchestrator-1. **Bare lesing, ingenting er endret.** Grep mot `origin/main` (7447955).
Kilder: Lovdata-korpuset i prod, read-only (`crm/scripts/baseline/foa-opphevet-2026.sql` → `crm/eval/foa-opphevet-2026-2026-10-18.txt`).
I tillegg Lovtidend avd. I fra Lovdatas åpne API (`api.lovdata.no/v1/publicData`, NLOD 2.0, hentet 2026-10-18):
`lti/2026/sf-20260414-0617.xml`, `sf-20260430-0713.xml`, `nl-20260306-008.xml`, `lti/2016/sf-20160812-0974.xml` (FOA slik den ble vedtatt),
`lti/2023/sf-20230829-1368.xml`, `lti/2018/sf-20180404-0533.xml` og `lti/2020/sf-20200212-0128.xml`.

## Kort

- FOR-2026-04-14-617 (i kraft 1.7.2026) opphever i FOA **§§ 7-2, 7-9, 8-12a, 8-13, 19-3 og 19-5**. Opphevelsen av «§ 19-15» i -617 ble
  rettet til **§ 19-5** ved FOR-2026-04-30-713. I forsyningsforskriften oppheves §§ 7-8 og 7-10, og nye §§ 7-9 til 7-17 i forskriften
  selv erstatter dem. Der flyttes reglene **ikke** til loven.
- Lov 6. mars 2026 nr. 8 innfører anskaffelsesloven §§ 5b–5p (i kraft 1.7.2026).
- **Det meste i koden er allerede riktig.** Feilsjekkens regelkart (`lib/feilsjekk/rules.ts`) skiller mellom «før» og «fra» 1.7.2026
  (LOA § 5b / FOA § 7-9), og `lib/legal/kofa/findings.ts` har riktig liste over opphevede paragrafer (med § 19-5).
- **Funn 1, de egentlige restene:** to `primarySource`-felt viser fortsatt til FOA § 7-9 uten «opphevet». Én juridisk tekst har «19-15»
  i stedet for 19-5. Dokumentasjonen sier at skatteattestplikten er `UNKNOWN`, men den står nå i LOA § 5l.
- **Funn 2, eldre og viktigere: underleverandør-regelen siterer feil paragraf.** Kode, dashboard og kommentarregler bruker
  «FOA § 19-3» som hjemmel for bruk av underleverandører. § 19-3 var «Begrensning av antallet ledd i leverandørkjeden» (bare bygg,
  anlegg og renhold), og den er nå opphevet (flyttet til LOA § 5k). Bruk av underleverandører står i **FOA § 19-2**, som fortsatt
  gjelder, og utskifting i **§ 24-4**. «§ 24-2» er avvisning, ikke utskifting.

## Hva paragrafene var, og hvor de står nå (`FACT` der ikke annet står)

| Opphevet | Tittel (FOA 2016 / endringsforskrift) | Står nå i | Kilde |
|---|---|---|---|
| FOA § 7-2 | Skatteattest | **LOA § 5l** Dokumentasjon av skatte- og avgiftsmessige forhold | sf-20160812-0974, korpus LOV5 |
| FOA § 7-9 | Klima- og miljøhensyn (2017, endret 2024) | **LOA § 5b** Klima- og miljøhensyn (+ § 5c standardiserte minimumskrav) | `legal/repealed/foa-7-9.ts`, korpus |
| FOA § 8-12a og § 19-5 | Krav til kontraktsvilkår om betaling av lønn mv. via bank (FOR-2023-08-29-1368) | **LOA § 5g** | sf-20230829-1368, korpus LOV5 |
| FOA § 8-13 og § 19-3 | Begrensning av antallet ledd i leverandørkjeden | **LOA § 5k** | sf-20160812-0974, 2018-533, 2020-128 |
| Forskrift om lønns- og arbeidsvilkår i offentlige kontrakter | | **LOA § 5e** (+ § 5f bygg/anlegg/renhold) | LEVERANSEKLAR-SJEKKLISTE [1], korpus LOV5. `ASSUMPTION`: opphevelsen selv er ikke sjekket i Lovtidend |
| Forsyningsforskriften § 7-8 og § 7-10 | | Nye forsyningsforskriften §§ 7-9 til 7-17 (i forskriften) | sf-20260414-0617 del II |

Gjelder fortsatt (korpus `GJELDER`): FOA § 16-10 Støtte fra andre virksomheter, **§ 19-2 Bruk av underleverandører**,
§ 24-2 Avvisning på grunn av forhold ved leverandøren, **§ 24-4 Utskiftning av underleverandører**, § 17-1 ESPD.
«Kritiske oppgaver utført av leverandøren selv» står i **FOA § 19-2 (2)**.

## A. Utdatert, bør rettes (forslag)

| Fil:linje | I dag | Forslag |
|---|---|---|
| `projects/anbud/crm/src/config/kommentar-regler.json:101` og `data/legal/kommentar-regler.json:101` | `"FOA § 7-9, KOFA 2025/0801, …"` | `"FOA § 7-9 (opphevet 2026-07-01, nå LOA § 5b), KOFA 2025/0801, …"`, samme form som linje 628/645/662 |
| `…/kommentar-regler.json:118` (begge kopier) | `"FOA § 7-9, KOFA 2025/0666"` | `"FOA § 7-9 (opphevet 2026-07-01, nå LOA § 5b), KOFA 2025/0666"` |
| `legal/procurement/qualification-requirements.md:1788` | «§§ 7-2, 7-9, 8-12a, 8-13, 19-3 og **19-15** er opphevet» | «… 19-3 og **19-5** er opphevet (§ 19-15 i -617 rettet til § 19-5 ved FOR-2026-04-30-713)» |
| `projects/anbud/docs/kvalifikasjonslag.md:564` | «Plasseringen av skatteattestplikten … er `UNKNOWN`» | «`FACT` Skatteattestplikten står i anskaffelsesloven § 5l fra 1.7.2026. Skjemanummer (RF-1316/RF-1507) er fortsatt `UNKNOWN`.» |
| `issues/013-juristgjennomgang-katalog.md:17` | spørsmål: hvor skatteattestplikten ligger | Svar: LOA § 5l (lov 6. mars 2026 nr. 8). Spørsmålet kan lukkes, eller snevres inn til skjemanummer |

## B. Feil paragraf før 2026, og nå også opphevet: underleverandører (forslag, ASSUMPTION til juristen har sett)

| Fil:linje | I dag | Forslag |
|---|---|---|
| `projects/anbud/dashboard/src/lib/underleverandor.ts:5` | «FOA § 16-10, § 19-3, § 24-2, C-812/24» | «FOA § 16-10, § 19-2, § 24-4, C-812/24» |
| `projects/anbud/dashboard/src/lib/underleverandor.ts:23` | «Foretaket utfører deler av kontrakten (FOA § 19-3).» | «… (FOA § 19-2).» |
| `projects/anbud/dashboard/src/app/(app)/opportunities/[id]/UnderleverandorBlock.tsx:114` | «FOA § 16-10, § 19-3 og § 24-2» (vises for brukeren) | «FOA § 16-10, § 19-2 og § 24-4» |
| `projects/anbud/crm/src/lib/qualification/underleverandor.ts:4` | «FOA § 16-10, § 19-3, § 24-2 and C-812/24» | «FOA § 16-10, § 19-2, § 24-4 and C-812/24» |
| `projects/anbud/crm/src/collections/BidDrafts.ts:75` | «set tasks out to (§ 19-3)» | «(§ 19-2)» |
| `…/kommentar-regler.json:220` (begge kopier) | «FOA § 16-10, § 19-3, HR-2022-1964-A» (underleverandører som bærer kvalifikasjonen, utskifting) | «FOA § 16-10, § 19-2, § 24-4, HR-2022-1964-A» |
| `…/kommentar-regler.json:900` (begge kopier) | «FOA § 19-3, § 24-2» (kritiske oppgaver selv, utskifting) | «FOA § 19-2 (2), § 24-4» |
| `projects/anbud/ARCHITECTURE.md:1645` | «verified FOA § 16-10, § 19-3, § 23-5, § 24-2, …» | «… § 16-10, § 19-2, § 23-5, § 24-4, …» |

NB: `24-2` → `24-4` gjelder bare der teksten handler om **utskifting**. Brukes § 24-2 om avvisningsgrunnene som utløser utskifting,
er den riktig. Det må leses i hver sammenheng før endring.

## C. Usikkert, bare en kommentar

| Fil:linje | Merknad |
|---|---|
| `projects/anbud/crm/src/lib/feilsjekk/miljo.ts:97` og `projects/anbud/ARCHITECTURE.md:2913` | «boilerplate lifted from FOA § 19-3». § 19-3 var ledd-begrensning, ikke samfunnshensyn. Hvor standardteksten «kontraktsvilkår for å ivareta samfunnshensyn etter anskaffelsesloven §§ 5b til 5m» kommer fra, er `UNKNOWN`. Forslag: fjern opphavspåstanden og behold regelen (bare en kommentar). |

## D. Riktig som det står, skal ikke endres

- **Regimebevisst kode:** `lib/feilsjekk/rules.ts:601, 801, 843–899` (§ 7-9 før / § 5b fra 1.7.2026), `lib/legal/kofa/findings.ts:41–48`
  (riktig liste, § 19-5), `lib/legal/repealed/*` (gjenopprettet historisk § 7-9), `lib/legal/history.ts:113`, `jobs/tasks/ingest-kofa.ts:94`,
  `lib/feilsjekk/miljo.ts:11`, `ARCHITECTURE.md:1341, 2894`, `src/cli/queue-job-allowed.ts:19`.
- **Allerede oppdatert:** `kommentar-regler.json:628/645/662`, `procurement/qualification/tender-readiness-checklist.md:287`,
  `docs/kvalifikasjonslag.md:106`.
- **Sitert lovtekst med egen død krysshenvisning:** `procurement/qualification/espd.md:146, 435, 776`, `qualification-matrix.yaml:955, 2483,
  2501, 2511` og `qualification-requirements.md:1675–1717, 1898`. Det er FOA § 17-1 (3) som selv viser til opphevet § 7-2. Den er gjengitt
  ordrett og har allerede en TODO til juristen. Forslag: legg til «skatteattestplikten står nå i LOA § 5l» i TODO-en, og endre ikke den siterte teksten.
- **Historiske data:** eval-filer, KOFA-gullsett, typesafe-datasett, fixtures, `issues/done/*` og `research/*`. KOFA-avgjørelser fra før 2026
  viser korrekt til reglene som gjaldt da.

## Omfang av en retting

A og B er 14 tekstlinjer i 9 filer, med to identiske kopier av kommentar-regler.json. Ingen migrering. Den eneste endringen brukeren ser
er UnderleverandorBlock.tsx:114. Tester som sammenligner tekst, må sjekkes (`underleverandor`-testene i dashboard og crm). Det blir én liten PR
når du har sagt hvilke grupper du vil ha med, og B bør gjennom juristen fordi det er en ny lesning av hjemmelen.
