# Rettskildemotoren som finnes — kartlegging admin-1

Repo `/home/nithu/code/Veldora-frist`, gren `admin-1/legal-engine-map` (`fae0ddd`). LES-ONLY, ingen DB-tilgang — tilstand skilt fra kode der det ikke er målt.

## Moduler (`projects/anbud/crm/src/lib/legal/`)

| Fil | Gjør | Status |
|---|---|---|
| `db.ts` (13) | Henter ut pg-pool fra Payload for rå SQL (tsvector/ts_rank) | KODE |
| `embeddings.ts` (30) | `EmbeddingProvider`-interface; `embeddingProvider()` returnerer **alltid `null`** — ingen leverandør konfigurert. `probeVector()` sjekker om pgvector-extension finnes, lager den aldri | KODE, ingen i drift |
| `lovdata.ts` (50) | Henter datasett-liste + tar.bz2 (≤40MB) fra `api.lovdata.no`, NLOD 2.0, ingen nøkkel | KODE, I DRIFT (cron) |
| `tar.ts` | Streamer tar-entries fra bunzip-strøm uten å holde 223MB i minnet | KODE |
| `parse.ts` (410) | Lovdata XML → `legal-documents` + `legal-chunks` (ett ledd per rad), pure | KODE |
| `sync.ts` (57) | Diff lagret vs. ny parse på `chunkId`/`contentHash`; vakt: 0 ledd eller <halvparten av lagret ⇒ skriver ingenting | KODE |
| `refs.ts` (54) | Finn §/vedlegg/KOFA-referanser i fritekst (brukes av retrieval + validator) | KODE |
| `query.ts` (109) | Parser søkefeltet: paragraf-oppslag vs. fulltekst, `dok=`-filter | KODE |
| `search.ts` (367) | `searchLegal` — paragrafoppslag ELLER `ts_rank`/`ts_headline`, innholdsliste, `citedBy()` (KOFA som siterer en paragraf) | KODE, I DRIFT via `/api/anbud/legal/search` |
| `retrieve.ts` (216) | Henting til assistenten: kanaler `paragraph`/`fulltext-and`/`fulltext-or`/`fulltext-synonym`/`vector`, slått sammen med RRF (`fuseRanked`); `vector`-kanal kobles kun inn når `embeddingProvider()` ikke er null OG kolonnen `embedding` finnes på `legal_chunks` | KODE, vector-grenen aldri aktiv i dag |
| `ask.ts` (275) | LLM-svar kun fra hentede chunks, via `lib/llm.ts`-seam | KODE |
| `answer.ts` (194) | Deterministisk validator: hver setning må sitere ordrett tekst fra EN hentet chunk, ellers `usikkert` | KODE |
| `evalMetrics.ts` (30) | Recall/precision/MRR/hitRate for gullsett | KODE, brukt av `scripts/eval-legal.ts` |
| `terskel.ts` (157) | Terskelverdi → del II/III. Leser `terskelverdier.json` — **tom med vilje** (se under) | KODE, TOMT datagrunnlag |
| `helligdager.ts` (151) | Norske helligdager + fristforskyvning. Hjemmel `ANTAKELSE`, regel for forskyvning `UKJENT` (kode viser begge datoer) | KODE, hjemmel ikke verifisert |
| `kommentarVurdering*.ts` | Fletter jurist-dom (egen Payload-collection `kommentar-vurderinger`) over JSON-frøet `kommentar-regler.json`; degraderer aldri til krasj | KODE |
| `log.ts` (42) | Én `legal-questions`-rad per besvart spørsmål, feil i logging skjuler aldri svaret | KODE |
| `kofa/*.ts` (robots/polite/page/decision/citations/build/plan/run) | Hele KOFA-scraperen: robots.txt-sjekk, 3s/request, WP REST-liste, PDF→tekst (`unpdf`), chunking til `avsnitt-n`/`innledning`/`konklusjon`, sitat-oppløsning mot lov/forskrift | KODE, se §3 for drift |

## Datamodell (Postgres via migrasjon `20261005_223213_legal_corpus_kofa.ts`, verifisert mot `collections/LegalDocuments.ts` + `LegalChunks.ts`)

| Tabell | Nøkkelfelt | Versjon/dato-felt |
|---|---|---|
| `legal_documents` | `ref_id` (unik), `kind` (lov/forskrift/kofa), `dok_id`, `content_hash`, `chunk_count` | `in_force_from`, `last_change_in_force` (= versjon), `dataset_last_modified`, `retrieved_at` — **alle tekstfelt med «fra»-semantikk, ingen `gyldig_til`** |
| `legal_chunks` | `chunk_id` (unik), `document_id`→documents, `ref_id` (paragraf), `paragraph_key`, `text` (ordrett), `content_hash` | `version` (= documentets `last_change_in_force`), `in_force_from`, `retrieved_at` — samme «ingen til-dato» |
| `kofa_ingest_state` | singleton-global, ikke en rettskilde-tabell | `high_water`, `backfill_cursor/offset/total`, `retry[]` — inkrementell scraper-state |
| `search_vector` | generert SQL-kolonne på `legal_chunks` (ikke Payload-felt): `tsvector`, `'norwegian'`, vektet A=paragraf+tittel, B=tekst, STORED, GIN-indeks | — |

**Ingen pgvector-kolonne finnes i migrasjonen.** `embedding`-kolonnen som `retrieve.ts` sjekker for (`information_schema.columns`) er planlagt i issue 019, aldri lagt til.

## §3 Korpuskilde og jobb

| Kilde | Format | Jobb | Frekvens | Automatikk |
|---|---|---|---|---|
| Lovdata `api.lovdata.no/v1/publicData` (NLOD 2.0, ingen nøkkel) — 5 kilder: LOA, FOA, FOFO, offentleglova, klagenemndforskriften (`config/legal.ts`) | `.tar.bz2` → XML per lov | `ingest-lovdata` (`jobs/tasks/ingest-lovdata.ts`) | cron `30 4 * * *` (`jobs/registry.ts:153`) | I DRIFT (kodet + planlagt via worker/croner) |
| Klagenemndssekretariatet (`www.klagenemndssekretariatet.no`), WP REST + sak-side + PDF | HTML-metadata + PDF-tekst via `unpdf` | `ingest-kofa` (`jobs/tasks/ingest-kofa.ts`, kjernelogikk `lib/legal/kofa/run.ts`) | cron `0 5 * * *` | KODE komplett, men issue 018 er `Status: open … venter på operatør og jurist for kriterium 1` (kildevalg/rettighetsgrunnlag ikke formelt besluttet) |

Ingen manuell engangsjobb — begge er nattlige, idempotente (diff på `chunkId`+`contentHash`, samme vakt-logikk).

## §4 Søk

- **Ingen embedding-modell i drift.** `embeddingProvider()` returnerer alltid `null` (`embeddings.ts:17-19`). Vector-kanalen i `retrieve.ts` er kodet men dø — `vectorChannel()` returnerer null før den spør DB når provider er null.
- **Søk i dag = ren Postgres full-text** (`'norwegian'` tsvector-config), `ts_rank`/`websearch_to_tsquery`, pluss paragraf-oppslag (exact `paragraphKey`) og en OR/synonym-kanal via egen tsquery-bygging — RRF (`fuseRanked`) over kanalene.
- Issue `019-embeddings-hybridsok.md` beskriver planen (bge-m3 via OpenAI-kompatibelt endepunkt, egen `embedding`-kolonne, cosinus + RRF) — **ikke bygget**, bare interface-stub.

## §5 Versjonering/datoavhengighet

`FINNES IKKE (målt: felt i migrasjon + Payload-collections)`: hverken `legal_documents` eller `legal_chunks` har et til-dato-felt. `version`/`last_change_in_force`/`in_force_from` er alle «gjaldt fra»-tekstfelt (ikke typet `date`). `sync.ts` **overskriver/fjerner** gamle ledd ved endring (ingen historikk-tabell) — korpuset er et øyeblikksbilde av gjeldende tekst, ikke en tidslinje. Kan ikke svare «hva sa § X på dato Y» hvis loven er endret siden.

## §6 Tilstand (korpus)

- **Kan ikke måles** (ingen DB-tilgang i denne runden). Skilt kode vs. drift:
  - `ensureLegalCorpus()` (test-fixture, `scripts/legal-corpus-fixture.ts`) laster ekte Lovdata-korpus via samme `ingest-lovdata`, pluss **bare 2** KOFA-testfixtures (2025/1898, 2026/0352) — brukt av eval/smoke, ikke bevis på prod-tilstand.
  - Gullsett: `eval/legal-gold.json`, 45 spørsmål (`grep -c "id"`).
  - `terskelverdier.json` = `[]` — **tom med vilje**, dokumentert begrunnelse i `data/legal/README.md` (ingen mal-kopiering av beløp, skal slås opp per konkurranse). Konsekvens: `terskel.ts` kan ikke utlede del II/III fra tabellen i dag.

## Hull

1. **Ingen embedding/vektorsøk i drift** — kun fulltekst; hybrid-planen (019) er ren interface-stub.
2. **Ingen dato-range-versjonering** — korpuset har kun «gjeldende tekst», ingen historikk; en endret paragraf overskrives/fjernes av `sync.ts`.
3. **KOFA-pipeline er kodet og cron-skedulert, men issue 018 står formelt `open`** — operatør/jurist har ikke besluttet kilde/rettighetsgrunnlag; ukjent om nattjobben faktisk har kjørt mot prod-DB (ingen tilgang for å verifisere rad-antall).
4. **Nedstrøms bruk i tilbudsarbeid er ikke ferdig** — issue 017 (`status: open`) sier `/juridisk` og Tilbud-fanen fortsatt har hardkodet lovtekst, ikke korpuset.
5. `terskelverdier.json` tom med vilje ⇒ `terskel.ts` sin del II/III-utledning er ubrukt i praksis til jurist fyller tabellen.
