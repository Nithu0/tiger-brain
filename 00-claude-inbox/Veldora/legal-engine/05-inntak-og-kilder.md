# Inntak av eksterne data — anbud/crm

`FACT` Lest read-only mot `admin-1/legal-engine-map` = `origin/main` (`fae0ddd`), repo
`/home/nithu/code/Veldora-frist/projects/anbud/crm`. Ingen filer endret.

## 1. Kildeadaptere (`src/lib/sources/**`)

| Kilde | Fil:linje | Endepunkt (sitert) | Auth (nøkkelnavn) | Format | Felt → `tenders` | Paginering/rate | Feilhåndtering |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Doffin, keyed** | `doffin.ts:27` `DOFFIN_SEARCH_URL = 'https://api.doffin.no/public/v2/search'`; kalt `doffin.ts:228` | header `Ocp-Apim-Subscription-Key` ← `DOFFIN_API_KEY` (`ingest-doffin.ts:45`) — **ALDRI TESTET MOT LIVE** (`doffin.ts:5-8` FACT-kommentar: "untested, no key") | JSON | `mapDoffinHit` (`doffin.ts:154`): title/description/buyer/cpv/estimatedValue/lots/deadline → `MappedTender`; `documentsUrl` alltid `null` (`doffin.ts:199`) | `PAGE_SIZE=100` (`config/ingest.ts:4`), stopper på kjent side (`tenders/ingest.ts:62`); `MAX_PAGES_INCREMENTAL=5`/`BACKFILL=50` | `zod` `safeParse` per hit, ugyldige telles (`invalid`), kaster ikke (`doffin.ts:213-220`) |
| **Doffin, keyless (webclient)** | `doffinWebclient.ts:16-17` `.../webclient/api/v2/search-api/search` + `.../notices-api/notices` | ingen (brukes når `DOFFIN_API_KEY` er tom, `ingest-doffin.ts:54`) | JSON | Samme mapper + `fetchDoffinNotice`/`applyDoffinNotice` for CPV, lots, vinnere, `documentsUrl` fra `competitionDocsUrl` (`doffinWebclient.ts:422`) | Maks **1000 treff** (`DOFFIN_WEBCLIENT_MAX_HITS`, `doffinWebclient.ts:19`, FACT: senere sider ikke servert); detaljhenting 150 ms pause, budsjett 300/1000 (`config/ingest.ts:21-23`) | `try/catch` per varsel i `doffinEnrich.ts:104-111`, logger `warn`, fortsetter med usupplert data |
| **TED** | `ted.ts:3,24` `TED_SEARCH_URL = 'https://api.ted.europa.eu/v3/notices/search'`, POST | ingen (keyless, `ted.ts:2`) | JSON | `mapTedNotice` (`ted.ts:210`): CPV, buyer, lots, vinnere, `documentsUrl` fra `document-url-lot` (`ted.ts:263`) | `PAGE_SIZE=100`; vindu `TED_SINCE_DAYS=3` / backfill 365 dager (`config/ingest.ts:7-8`) | `zod` `safeParse` per varsel, ugyldige telles (`ted.ts:277-279`) |
| **Brreg** (ikke tender-kilde) | `brreg.ts:12,95` `data.brreg.no/enhetsregisteret` + `/regnskapsregisteret` | ingen | JSON | Beriker `buyers` (org.nr → navn/type), ikke `tenders` | — | — |
| **News (RSS)** (ikke tender-kilde) | `news.ts:88` `fetchFeed` mot `config/news.ts` sine feed-URLer | ingen | XML/RSS | `news-items`-samling, ikke `tenders` | per feed | `safeFetch` retry/backoff |
| **Google Workspace** (ikke tender-kilde) | `google.ts:13-17` oauth2/gmail/calendar/drive/tasks | `GOOGLE_WORKSPACE_CREDENTIALS_B64` (OAuth refresh token) | JSON | sync-workspace, ikke `tenders` | — | — |
| **WhatsApp** (ikke tender-kilde) | `whatsapp.ts:14` Meta-webhook-signatur | app secret (signatur), ikke URL-basert | JSON/webhook | meldinger, ikke `tenders` | — | — |

Alle eksterne kall går gjennom `src/lib/http.ts:4-19` sin **allowlist** (`STATIC_ALLOWED_HOSTS`: kun `api.doffin.no`, `betaapi.doffin.no`, `api.ted.europa.eu`, `data.brreg.no`, Google-hostene, `api.lovdata.no`, KOFA-sekretariatet, `api.fiken.no`) — ukjent host kastes (`http.ts:100`). Delt retry/backoff (429/5xx, maks 3 forsøk, 20 s timeout, 10 MB cap) i `safeFetch`/`fetchJson` (`http.ts:128-157`).

## 2. Dokumentpipen — hvor stopper den

`FACT` `documentsUrl` på en `tender` er bare **tekst** (`collections/Tenders.ts:105`), satt av Doffin/TED-mapperne. **Ingen kode i repoet henter filen bak den URL-en.** `documents`-samlingen (`collections/Documents.ts:87`) er et Payload `upload`-felt som kun fylles av et **menneskelig/API-opplastet** multipart-POST — `extractOnUpload`-hooken (`collections/Documents.ts:28`) trigges av `operation === 'create'` på selve opplastingen, ikke av en URL.

`FACT` `importFolder.ts`/`importRemote.ts`/`importRun.ts` er **ikke** konkurransedokument-pipen — de er "Capability import" (CV-er, referanser, kunder for firmaets eget kompetansearkiv, `importRun.ts:1-9`). Feil spor i oppdragsbeskrivelsen; verifisert ved lesing, ingen `documentsUrl`/`tenders`-referanse i disse filene.

`extractText.ts:42-62` kan parse pdf (unpdf)/docx (mammoth)/txt; xlsx er **TOMT** (`"xlsx støttes ikke ennå"`, linje 59). Men funksjonen kalles kun fra `extractDocumentText` (opplastet fil på disk, `extractText.ts:66`) og fra `importRun.ts` (CV-filer) — aldri fra en nettverkshentet `documentsUrl`.

**Grensen konkret:** en kunngjøring kommer inn med `documentsUrl` pekende på en portal (Mercell, TendSign osv.). Ingen jobb, hook eller skript laster ned noe derfra — filen må legges inn av et menneske via admin-UI/API. Dette stemmer med kjent måling i brief: `documents` har 0 rader i prod, 0 av 1184 `documentsUrl` er en fil.

## 3. Planlegging — cron (`src/jobs/registry.ts` + `src/worker.ts`)

`I DRIFT` (forutsatt at `npm run worker` kjører): `worker.ts:8,173` bruker `croner`, tidssone Europe/Oslo, kjører `payload.jobs.queue` per schedule + `jobs.run` hvert 10. sekund (`worker.ts:3`).

| Jobb | Cron | Linje |
| --- | --- | --- |
| `ingest-doffin` | `*/30 6-22 * * *` + `0 0-5,23 * * *` | `registry.ts:133-134` |
| `ingest-ted` | `5 * * * *` (hver time) | `registry.ts:135` |
| `ingest-lovdata` | `30 4 * * *` | `registry.ts:153` |
| `ingest-kofa` | `0 5 * * *` | `registry.ts:157` |
| `scan-news` | `15 */2 * * *` | `registry.ts:136` |
| `deadline-sweep` | `30 7 * * *` | `registry.ts:167` |

GitHub Actions (`.github/workflows/daily.yml`) er **ikke** inntaket — det er en separat ukedags-sweep (06:30 UTC) for fristvarsling via `scripts/deadlines.mjs`, uavhengig av worker-cronen. `anbud.yml` er CI-port (tsc/test/build), ingen inntakslogikk.

## 4. Portaler — Mercell/TendSign/EU-Supply/Ivalua/hyyr

`FINNES IKKE i kode` (målt: `grep -rln "Mercell\|TendSign\|EU-Supply\|Ivalua\|hyyr" --include=*.ts .` → 0 treff utenfor `eval/` og testtekst/fixtures). Alt som finnes er:

- `eval/DOKUMENTKILDER.md` — en **målt** fordeling av 1184 `documentsUrl`-lenker per plattform (Mercell 36,8 %, TendSign 18,2 %, hyyr 12,6 %, Artifik 11,6 %, Ivalua 10,7 %, EU-Supply 9,3 %), **ingen adapterkode**.
- `tilbud/checklist.ts:90` nevner Mercell/TendSign/EU-Supply bare som fritekst i en sjekkliste for mennesker ("innleveringskanal … er bekreftet").
- DOKUMENTKILDER.md linje 57-64 sier "hyyr er alt bygget" / "er den eneste som svarer uten innlogging" — men dette er **ikke verifiserbart i kildekoden**: ingen `hyyr`-adapter finnes i `src/`. Påstanden i dokumentet refererer til en måling gjort av en annen pane (trading-1), ikke til kode i dette repoet.

Konklusjon: alle fem portaler er **DOKUMENTERT** (målt/beskrevet i `eval/`), **ingen er KODE**.

## 5. TED/EØS

`I DRIFT`: TED v3 Search API (`ted.ts:24`) brukes som egen inntakskilde (pkt. 1) og til **kryss-lenking**, ikke fristkryssjekk: `tenders/related.ts:1-15` lenker en Doffin- og TED-kopi av samme anskaffelse via `procedureId`, ev. buyer+titel+deadline ±1 dag (`related.ts:96`, `pickRelated`). Doffins eget `tedId`-felt (`doffinWebclient.ts:39,322,398`) blir lagret på `raw.detail.tedId` men **TOMT i praksis** — `grep` finner ingen lesing av `tedId` utenom lagringen selv; lenkingen bruker `procedureId`/heuristikk, ikke `tedId`.

## 6. Idempotens og sporbarhet

- **Upsert-nøkkel:** `(source, externalId)`, slått opp i `upsertTender` (`tenders/upsert.ts:93-99`) før skriving.
- **contentHash:** sha256 over `title|description|deadline|status|lots` (`upsert.ts:11-20`); uendret hash ⇒ ingen skriving (med unntak for ny detalj, `hasNewDetail`, `upsert.ts:82-85`).
- **provenance-felt:** satt av hver mapper — `{ source, url, retrievedAt, publishedAt, confidence }` (`doffin.ts:150`, `ted.ts:266`) — altså kilde + tidspunkt per rad, ikke bare per kjøring.
- **agent-runs:** `withAgentRun` (`agentRun.ts:23-79`) skriver **én rad per jobbkjøring** (`agent`, `status`, `startedAt/finishedAt`, `itemsIn/Out`, feilmelding) til samlingen `agent-runs` — dette er importkjørings-loggen (ikke en egen `importRun.ts`-fil, se pkt. 2 for hvorfor den filen er noe annet).
- `payload_jobs`/`deleteJobOnComplete`: `FINNES IKKE i egen config` (målt: `grep -rn deleteJobOnComplete` i repoet → 0 treff) — ingen explisitt override funnet i `payload.config.ts:199-203`; stemmer med brief-konteksten om at det er Payload-bibliotekets standardoppførsel, ikke noe denne kodebasen setter selv.

---

## Sammendrag (maks 10 linjer)

Doffin (keyed + keyless webclient) og TED er de to reelle tender-kildene, begge med egne mappere, zod-validering og sha256-contentHash-upsert på `(source, externalId)`. Brreg/news/Google/WhatsApp er ikke tender-inntak. Dokumentpipen stopper hardt: `documentsUrl` er ren tekst, ingen kode laster ned filen bak den — `documents`-opplasting krever et menneske, `importFolder/importRemote/importRun` er feilaktig antatt i oppdraget (de er CV/referanse-import, urelatert). Planlegging kjører via `croner` i `src/worker.ts` (Doffin hvert 30. min, TED hver time), ikke via GitHub Actions. Mercell/TendSign/EU-Supply/Ivalua/hyyr har **null adapterkode** — kun en målt lenkefordeling i `eval/DOKUMENTKILDER.md`; påstanden "hyyr er alt bygget" er ikke bekreftet i `src/`. TED brukes også til kryss-lenking av dupliserte varsler via `procedureId`/heuristikk; det lagrede `tedId`-feltet er aldri lest. Sporbarhet er solid: provenance per rad + én `agent-runs`-rad per kjøring.

## Tre viktigste funn

1. **Dokumentinntak finnes ikke** — `documentsUrl` lagres som tekst, men ingen jobb/hook henter filen; `documents` fylles kun manuelt. `importFolder/importRemote/importRun` (som oppdraget pekte på) er et annet system (CV-import), ikke konkurransedokumenter.
2. **Portalene er målt, ikke bygget** — Mercell/TendSign/EU-Supply/Ivalua/hyyr har 0 linjer adapterkode; alt som finnes er `eval/DOKUMENTKILDER.md`s lenkefordeling. "hyyr er alt bygget" i det dokumentet kan ikke verifiseres mot `src/`.
3. **Inntaket er solid der det finnes** — Doffin + TED har idempotent upsert (hash + nøkkel), per-rad provenance og én loggrad per kjøring (`agent-runs`), styrt av en egen `croner`-daemon (`worker.ts`), ikke av GitHub Actions.
