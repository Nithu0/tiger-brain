# Dokumentdekning i triage-køen — målt 2026-10-11

**Fra:** tools-1 · **Ordre:** code-1-dispatch 2026-10-11T09:47Z (operatør «letsgooo», dagens eneste mål)
**Spørsmål:** finnes anskaffelsesdokumentene, og er de tekstet, slik `crm/src/lib/tenderText.ts` forventer?
**Svar:** nei. `documents`-tabellen i produksjon er tom. Sitater med sidehenvisning er umulige i dag.

---

## 1. Tallene

`FACT` (målt 2026-10-11 ~16:30 CEST, read-only `BEGIN READ ONLY … ROLLBACK` mot produksjons-Postgres
via `railway ssh --service crm`; køfilteret er det samme som triage-siden bruker,
`crm/src/lib/triage.ts:220` `queueWhere`):

| Mål | Tall |
|---|---|
| Muligheter i triage-køen nå (`UNDECIDED`, `spotted\|screening`, frist fram i tid eller ukjent) | **782** |
| …uten noe anbudsdokument | **782 (100 %)** |
| …med dokument, men uten uttrukket tekst | 0 |
| …med tekst, men uten sidetall (`\f`) | 0 |
| Rader i `documents` totalt (hele basen, alle formål) | **0** |
| Muligheter i køen med lenke til konkurransedokumenter (`tenders.documents_url`) | **675 (86 %)** |
| …der lenken peker et annet sted enn kunngjøringen | 675 (alle) |
| Muligheter i køen med `sourceUrl` | 782 (100 %) |
| Frist ukjent | 226 · Frist innen 14 dager | 171 |
| Kilde: Doffin 471 · TED 311 | |
| Muligheter totalt / kunngjøringer totalt | 831 / 1562 |

`FACT`: de tre første `documents_url`-ene i køen peker alle til `tendsign.com/doc.aspx?MeFormsNoticeId=…`
— altså en Mercell/TendSign-portal, ikke en direkte PDF på doffin.no.

## 2. Dagens løp — hvor kjeden stopper

| # | Steg | Kode | Automatisk? |
|---|---|---|---|
| 1 | cron køer `ingest-doffin` | `crm/src/jobs/registry.ts:89` | ja |
| 2 | kunngjøringsdetalj mappes, `documentsUrl` plukkes opp | `crm/src/lib/sources/doffinWebclient.ts:312` (TED: `ted.ts:263`) | ja |
| 3 | lagres som tekstfelt på kunngjøringen | `crm/src/collections/Tenders.ts:96` | ja |
| 4 | **ingen henter den URL-en** | finnes ikke | — |
| 5 | menneske laster opp fil i Payload (`POST /api/documents`) | `crm/src/collections/Documents.ts:87` | **manuelt** |
| 6 | `extractOnUpload`-hook trekker ut tekst i crm-prosessen | `crm/src/collections/Documents.ts:28` | ja |
| 7 | unpdf/mammoth parser, sider skilles med form feed `\f` | `crm/src/lib/documents/extractText.ts:45-48` | ja |
| 8 | `extractedText` + `processedAt` skrives | `crm/src/collections/Documents.ts:32` | ja |
| 9 | `extract-requirements` køes | `crm/src/jobs/tasks/extract-requirements.ts:30` | ja |
| 10 | tekst → LLM-prompt, `\f` → sidetall i sitatet | `tenderText.ts:36-56`, `verify.ts:58-79`, `citations.ts:52` | ja |

Steg 4 er hullet, og steg 5 er manuelt **med vilje**: `ARCHITECTURE.md:1088-1089` sier
«Tender documents uploaded **by a human**». Ingen `payload.create({ collection: 'documents' })`
finnes i `src/` utenfor en smoke-script. Så 0 rader er ikke en feil i driften — det er
arkitekturen som møter en dag der ingen har lastet opp noe.

## 3. De tre viktigste hullene

**H1 — `documents` er tom, så «Dokument s. 12» er uoppnåelig (blokkerer dagens triage-kort).**
Sitatmaskineriet virker, men har ingenting å sitere: `verifySources`/`buildSourceBlocks` filtrerer
bort dokumenter uten tekst (`tenderText.ts:29,50`), og med null dokumenter bygges prompten fra
kunngjøringsteksten alene (`tenderText.ts:38-49`). Det betyr at krav og brief som er hentet ut så
langt er **kunngjørings-baserte**, ikke dokument-baserte — og ingenting i UI-et sier det.
Bare `contract-review` nekter høyt («ingen dokumenter med tekst», `contract-review.ts:68`).
`ASSUMPTION`: hvis triage-kortet lover sidehenvisning, vil det i dag enten stå tomt eller
sitere kunngjøringen — verifiser mot `feat/anbud-triage-veiledning` før demo.

**H2 — lenken til dokumentene var usynlig i triagen (fikset, se §4).**
`documentsUrl` lå som siste fallback bak `sourceUrl` (`dashboard/.../triage/page.tsx:83`). Alle 782
har `sourceUrl`, så fallbacken fyrte aldri. 675 muligheter hadde altså en lenke til
konkurransedokumentene som den som triagerer ikke fikk se.

**H3 — selv etter opplasting finnes fire stille sluk.**
- `xlsx` parses aldri (`extractText.ts:59`), men er en godkjent filtype (`Documents.ts:14`) — prisskjema lander alltid uten tekst.
- Skannet PDF gir null tekst, men `processedAt` **settes** (`Documents.ts:32`), så worker-fallbacken (`extract-requirements.ts:55`) prøver aldri igjen. Ingen OCR noe sted.
- Hooken fyrer bare på `operation === 'create'` (`Documents.ts:29`): bytter man fil på en eksisterende rad, blir teksten stående gammel.
- Worker-servicen har ikke opplastingsvolumet (`extract-requirements.ts:71-76`) — feiler uttrekket ved opplasting, kan fallbacken bare be om ny opplasting.
- I tillegg: sidetall krever `\f`, så docx, txt og PDF-er lagret før 2026-10-03 gir `page = null` (`ARCHITECTURE.md:1096-1098`).

## 4. Hva jeg har gjort (branch `fix/anbud-dokumentdekning`, worktree `~/code/Veldora-dok`, commit `abfd123`, IKKE pushet)

1. **Konkurransedokumentene vises som egen lenke på triage-kortet** — `dashboard/.../triage/page.tsx` +
   `TriageCard.tsx`, ~10 linjer, ingen ny hurtigtast. Treffer 675 av 782 i køen.
   `typecheck` + `lint` + `npm test` (420/420) grønt.
   ⚠️ **Kollisjonsvarsel:** `TriageCard.tsx` er der code-1 sine agenter bygger «Om anskaffelsen»
   på `feat/anbud-triage-veiledning`. Ta diffen eller forkast den — den er frittstående.
2. **`crm/scripts/dokumentdekning.ts`** (`npm run dokumentdekning`, read-only) måler de samme tallene
   repeterbart. Importerer `queueWhere` fra `src/lib/triage` i stedet for å kopiere køfilteret.
   `--remote <crm url>` leser over Payload REST; uten flagg kjører den Local API mot `DATABASE_URL`.
   `TODO` (tools-1): den er ikke kjørt mot produksjonsdata ennå — prod-Postgres har ingen
   offentlig TCP-proxy, så tallene i §1 ble hentet med SQL inne i crm-containeren.
   Rørte **ikke** `crm/src/jobs/**` eller `crm/src/endpoints/triage.ts` (code-1s område).

## 5. Beslutningen som ikke er min

`UNKNOWN` → operatør/code-1: skal vi hente konkurransedokumentene automatisk?
Det er ikke en liten, trygg fiks, og det er tre spørsmål i ett:

1. **Juridisk.** Lenkene går til TendSign/Mercell-portaler, ikke til doffin.no. Nedlasting der krever
   ofte registrering per konkurranse. `CLAUDE.md` §7: «technically fetchable ≠ legal to store».
   Doffins gjenbruksvilkår er fortsatt ikke jurist-sjekket (`projects/anbud/README.md`, punkt C6).
2. **Arkitektur.** `ARCHITECTURE.md:1088` sier dokumenter lastes opp av et menneske. En henteprosess
   er en ADR-endring, ikke en patch.
3. **Rekkefølge.** Hvis svaret blir nei: da må triage-kortet si «ingen dokumenter lest» i stedet for
   å antyde at sitatene er dokument-verifiserte. Det er den billigste ærlighets-fiksen, og den ligger
   i `endpoints/triage.ts` — code-1s fil, ikke min.

Hvis svaret blir ja, er den minste ærlige første versjonen: hent bare der `documents_url` peker på
doffin.no selv, lagre med kilde + hentedato, og la portal-lenkene stå som manuell jobb.

---
*Verktøy: `railway ssh --service crm` + `pg` i containeren, read-only transaksjon. Ingen skriv mot produksjon. Ingen hemmeligheter lest eller skrevet.*
