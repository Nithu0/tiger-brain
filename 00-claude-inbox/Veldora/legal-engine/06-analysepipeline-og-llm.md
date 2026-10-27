# Analysepipeline og LLM-lag — `projects/anbud/crm`

Les-only kartlegging. Repo-sti: `/home/nithu/code/Veldora-frist/projects/anbud/crm`. Alle linjetall verifisert med `cat -n`/`grep -n` 2026-10-15.

## 1. Jobbinventar — `src/jobs/tasks/**`

48 jobber registrert i `src/jobs/registry.ts:55-113` (array `tasks`). 45 produksjonsfiler i `src/jobs/tasks/*.ts` (ekskl. 14 `*.test.ts`). `importChatTask`+`interpretMessagesTask` deler fil `messages.ts`; `notifyEmailTask`+`emailDigestTask` deler `notify-email.ts`; `ingestDoffinTask`/`ingestTedTask` deler inputSchema fra `ingest-doffin.ts`.

13 av 45 kaller en modell (`completeJson`): `assess-requirements, challenge, contract-review, draft-bid, draft-reply, extract-requirements, ingest-answer, messages (interpret), news-digest, parse-cv, qualify-requirements, red-team, tender-brief`. Resten er deterministisk (regelbasert/henting).

| Task (slug) | Fil | Leser (collections) | Skriver (collections) | Modell | Idempotens (bevis) |
|---|---|---|---|---|---|
| ingest-doffin | ingest-doffin.ts | Doffin API | tenders | N | upsert, `ingest-doffin.ts:1-3` «upsert tenders» |
| ingest-ted | ingest-ted.ts | TED API | tenders | N | samme upsert-sti (`ingestPages`) |
| ingest-kofa | ingest-kofa.ts:31,53,70,135 | KOFA web + `kofa-ingest-state` global | legal-documents, news-items | N | global cursor-state |
| ingest-lovdata | ingest-lovdata.ts:62 | Lovdata-tar | legal-chunks, legal-documents | N | FINNES IKKE eksplisitt idempotens-kommentar (målt: grep) |
| classify | classify.ts:103-117 | opportunities, tenders | opportunities, tenders | N | kommentar `classify.ts:116` «idempotent, re-queuing harmless» |
| enrich-buyer | enrich-buyer.ts | buyers | buyers | N | per-item, `rethrow: true` (Payload-retry) |
| extract-requirements | extract-requirements.ts:52,69,175,189-201 | documents, opportunities, requirements | requirements, opportunities | **J** (`extract.requirements`) | dual-pass diff mot `existing`, queue assess-requirements |
| awards-backfill | awards-backfill.ts:75 | awards, suppliers, tenders | awards, suppliers, tenders | N | kommentar `:4` «tender × supplier, idempotent» |
| score | score.ts:136,287,306 | awards, documents, opportunities, predictions, requirements | opportunities, predictions | N | leser `decision-profile` global |
| challenge | challenge.ts:99-130 | opportunities, requirements | opportunities | **J** (`generate.challenge`) | `rethrow: true`, per-item |
| scan-news | scan-news.ts:73,206 | buyers, news-items, opportunities, suppliers, tenders | news-items | N | queuer watch-match |
| news-digest | news-digest.ts:21,48,74-77 | news-items | news-digests | **J** (`generate.news`) | — |
| stats | stats.ts:19 | — | market-snapshots | N | — |
| deadline-sweep | deadline-sweep.ts:93 | briefs, opportunities | briefs, opportunities | N | sweep over alle åpne |
| morning-briefing | morning-briefing.ts:263 | agent-runs, fakturaer, market-snapshots, opportunities, predictions, signals, ukesrapporter, workspace-items | signals | N | daglig rapport, lesetung |
| postmortem | postmortem.ts:121 | awards, opportunities, predictions, signals, tenders | — (signals via emitSignal) | N | sweep RESULT-notices |
| calibration-backtest | calibration-backtest.ts:19,39 | predictions | global `calibration-backtest` | N | overskriver samme global |
| watch-match | watch-match.ts:189 | buyers, news-items, opportunities, signals, tenders, watch-items | watch-items, signals | N | per tender/news |
| sync-workspace | sync-workspace.ts:331,342 | activities, buyers, customers, opportunities, prospekter, tenders, workspace-items | workspace-items | N | kommentar `:47` «upsert makes it idempotent», cursor i `workspace-sync` global |
| interpret-messages | messages.ts:101,119-206 | workspace-items | workspace-items | **J** (`extract.message`) | queuer draft-reply |
| import-chat | messages.ts:216 | chat-imports, payload-jobs | workspace-items | N | — |
| parse-cv | parse-cv.ts:68,102 | cvs, people | people, cvs | **J** (`extract.cv`) | — |
| assess-requirements | assess-requirements.ts:83,103,112,125,129,142,160,194,227,252 | interview-questions, opportunities, requirements | requirements, interview-questions | **J** (`judge.assess`) | queuer score + tender-brief |
| qualify-requirements | qualify-requirements.ts:70,90,191,259,277 | interview-questions, opportunities, qualification-assessments, requirements, tenders | qualification-assessments, requirements | **J** | — |
| ingest-answer | ingest-answer.ts:59,65,83,111,123,140,147,165,172,179,194 | capability-facts, interview-questions, people, references | capability-facts, people, references | **J** (`extract.answer`) | kommentar `:110` «idempotent by normalised statement» |
| refresh-assessments | refresh-assessments.ts:21,61 | interview-questions, opportunities | — | N | queuer assess-requirements |
| requalify | requalify.ts:28,36,93 | opportunities | — | N | leser `decision-profile`/`supplier-profile` global |
| learn-preferences | learn-preferences.ts:108,122 | — | global `decision-profile` | N | debounced hver 10. beslutning |
| tender-brief | tender-brief.ts (se §2) | tenders, documents, requirements, briefs, opportunities | briefs, opportunities | **J** (`generate.brief`) | upsert på `opportunity`, LLM cachet på `textHash` |
| draft-bid | draft-bid.ts:101,112,128,142-259 | requirements, documents, bid-drafts, opportunities | bid-drafts, bid-sections | **J** (`extract.criteria`, `generate.draft`) | queuer contract-review |
| contract-review | contract-review.ts:41,55,84,96-150 | bid-drafts, documents, opportunities | legal-flags, reservations, bid-drafts | **J** (`extract.contract`) | — |
| red-team | red-team.ts:34,49-84 | bid-drafts, bid-sections, opportunities, requirements | bid-sections | **J** (`generate.redteam`) | — |
| ingest-lovdata/-kofa | se over | | | | |
| notify-email / email-digest | notify-email.ts:166,194 | email-sends, push-subscriptions, signals, users | email-sends | N | rate-budsjett (`:129,130`) |
| score-prospekter | score-prospekter.ts:14 | — (prospekter via lib) | prospekter (3 scorefelt) | N | kommentar `:3-4` «deterministic … never touches status/log/contact» |
| draft-reply | draft-reply.ts:114,122,132,144,180,194 | capability-facts, workspace-items | workspace-items | **J** (`draft.reply`) | — |
| slett-utloept-tekst | slett-utloept-tekst.ts:78 | workspace-items | workspace-items (sletter tekst) | N | — |
| verdi-backfill | verdi-backfill.ts:62 | tenders | tenders | N | manuell, idempotent (registry.ts:94-96) |
| verdi-tekstpromotering | verdi-tekstpromotering.ts:116 | briefs, documents, opportunities, tenders | tenders.estimatedValue | N | manuell, idempotent (`:2`) |
| scope-backfill | scope-backfill.ts:47 | opportunities | opportunities | N | manuell, idempotent (registry.ts:100-103) |
| analyser-energidata | analyser-energidata.ts:79 | energidata, oppdrag | energidata | N | queued on upload + hourly sweep |
| rapportutkast | rapportutkast.ts:180 | customers, energidata, oppdrag | oppdrag (rapport) | N | queued by endpoint |
| referanseforesporsel | referanseforesporsel.ts:86 | oppdrag, references | references | N | 1 uke etter levering |
| brief-coverage | brief-coverage.ts:74,102 | briefs, opportunities, payload-jobs | — (queuer tender-brief) | N | kommentar `:14` stoler på tender-brief sin idempotens |
| fakturakladd | fakturakladd.ts:149 | fakturaer, oppdrag, salgstilbud | fakturaer | N | — |
| avstemming | avstemming.ts:140 | fakturaer, oppdrag | — (rapport) | N | månedlig |
| weekly-report | weekly-report.ts:67 | approvals, ukesrapporter | ukesrapporter | N | mandager |
| heartbeat | heartbeat.ts:16,24 | — | global `worker-heartbeat` | N | bevisst ingen agent-runs-rad (`:4`) |

## 2. Brief-kjeden (`tender-brief.ts` + `lib/brief.ts`)

Trigger: queued av `assess-requirements` (relevant/i-spill) eller `brief-coverage`/`force` (tender-brief.ts:85-87,100-103). Leser `tenders` (root + linked via `relatedTender`), `documents`, `requirements`, forrige `briefs`-rad parallelt (`:106-113`). `textHash(root, docs, BRIEF_VERSION)` (`:118`) avgjør cache: samme hash + eksisterende `llm`-felt ⇒ gjenbruk, ingen nytt kall (`:124-126`). Ellers ett LLM-kall `completeJson(briefLlmSchema, {task:'generate.brief', system: BRIEF_SYSTEM, maxTokens:4000})` (`:128-132`), verifisert i `verifyLlmBrief` (brief.ts:243-262) mot `prepareSources`/`verifyQuote` (verify.ts). Tomt/avslått LLM-svar når forrige brief hadde reelt innhold ⇒ kaster og behold forrige (`:139-141`, `llmGaveNothing`/`prevHadLlmSubstance`, brief.ts:40-48). `deadlineCandidates` (`:55-78`) samler: root+linked tenders' `deadline`, `findDocumentDeadlines` på hvert dokument, og KI sin `tilbudsfrist` KUN hvis verifisert mot et dokument — deretter `compareDeadlines(...)` (deadlines.ts, ikke lest her) gir `consistent/mismatch/insufficient`. Signaler: `deadline.mismatch` (ALERT), `tender.change.diff` (SYNTHESIS, ved `reason==='change'`), `brief.ready` (INTERPRETATION) (`:199-231`). Lagres i `briefs` (create/update, `:192-194`), og `opportunities.prising` kun hvis endret (`samePrising`, `:197`).

## 3. LLM-laget (`src/lib/llm.ts`, `src/lib/llm/*`, `src/config/models.ts`)

**Ingen SDK** — rå `fetch` mot Anthropic Messages API (`llm.ts:19,172-201`) eller en OpenAI-kompatibel endpoint (`llm.ts:204-234`, `LLM_BASE_URL`, lokale modeller). Modell-id-strenger fra kode: `claude-sonnet-5` (DEFAULT_MODEL, router.ts:17), `claude-haiku-4-5`, `claude-sonnet-5-5`, `claude-opus-5-5` (models.ts:184-188), `jev-1.13.0`/`jev-latest` (TypeSafe, models.ts:165,188).

**Ruting** (`router.ts:47-50`): `LLM_MODEL_<TASK>` env ?? `TASK_MODEL_DEFAULTS[task]` ?? `LLM_MODEL` env ?? `claude-sonnet-5`. `TASK_MODEL_DEFAULTS` (models.ts:114-143) ruter 10 "mekaniske" oppgaver inkl. **`generate.brief`** til Haiku ($1/$5 vs Sonnet $2/$10 per MTok) — 80 % av 7-dagers kostnad ($17.58 av $21.99, målt 2026-10-13, kommentar `:130-141`). Hard clamp: en `legalConclusion`-oppgave (kun `generate.answer`, models.ts:41) kan aldri rutes under `LEGAL_MIN_TIER=2` (Sonnet) — `router.ts:40-45`.

**Caching**: ingen generisk response-cache i LLM-laget selv. Eneste cache er domenespesifikk: `tender-brief` per `textHash` (over). `completeJson` (llm.ts:487-507) har én reparasjonsrunde ved valideringsfeil: sender svaret + feilmelding tilbake, ber om gyldig JSON på nytt (`:492-503`); feiler reparasjonen ⇒ `LlmError` kastet (`:505`). Truncation: input kappes til `INPUT_CHAR_BUDGET=60000` tegn med markør `[… avkortet: N tegn utelatt]` (`:21,160-164`), skalert per-attempt timeout 25ms/outputtoken (60s–300s, `:22-33`).

**Strukturert utdata**: Zod-skjema pr. kall (`briefLlmSchema` m.fl.), `extractJson` finner første gyldige JSON-blokk i fri tekst (`:434-471`), deretter `schema.safeParse` (`:473-484`).

## 4. Kostnadssporing (`llm-usage`)

Collection `LlmUsage` (src/collections/LlmUsage.ts:9-28): felt `task, provider(anthropic/openai-compatible/typesafe), model, inputTokens, outputTokens, latencyMs, attempts, ok, errorCode, costUsd, priceVersion`. `access: create: nobody` — kun skrevet via sink (`usage.ts:29-42`, registrert i `payload.config` onInit). `costUsd` regnes i `recordUsage` (`usage.ts:35`) via `estimateCostUsd`→`priceFor` (cost.ts:5-24, lengste prefiks-match). Satser fra kode (`models.ts:184-188`, kilde «ANTHROPIC_PRICING», hentet 2026-10-06): Haiku 4.5 $1/$5 per MTok, Sonnet 5/5.5 $2/$10, Opus 5.5 $4/$20, TypeSafe Jev $0.042/$0.

**Tak/budsjett i kode: FINNES IKKE** (målt: `grep -rniE "budsjett|budget|dollar.?cap|spending.?limit|maxSpend" src/` — alle treff er tegn/token/rate-budsjetter, ikke dollar-tak). Ingen enforcement stopper videre LLM-kall ved en kostnadsgrense; `llm-usage` er ren måling.

## 5. Sitater og verifikasjon (kvalitetslaget)

**Enforced** (filtrerer faktisk bort): `verify.ts` — deterministisk, normaliserer tekst og gjør fuzzy substring-match (Sellers edit-distance), `VERIFY_THRESHOLD=0.85` (`:12`), korte sitater (<4 token) må matche eksakt (`:14`). Brukes av `verifyLlmBrief` (brief.ts) og `citations.ts` (`verifyQuote`). I `buildBrief` droppes et `omfang`-punkt uten verifisert sitat helt (brief.ts:648, kommentar «aldri vist»).

**Målt, men ikke blokkerende**: `citationFlags.ts` — rene kodesjekk (endret modalverb, tall i påstand uten dekning i sitat) ⇒ `avvist` uten modell (`:1-3`). `citationJudge.ts` — "cheapest first": kodeflagg → TypeSafe Jev Noul (>0.9 støttet, <0.1 avvist) → eskalering til Claude i båndet mellom, ellers `usikkert`; uten Jev ⇒ `ikke-vurdert` (`:1-7`). `needsHuman` (citationFlags.ts:9) returnerer true for `avvist`/`usikkert` — **sender til menneske, godkjenner aldri selv**. `consensus.ts` sammenligner to uavhengige ekstraksjonspass og **løser aldri** en konflikt — setter bare `needsReview` (`:1-4`). `coverage.ts` teller kun menneskets `weMeet`, ikke en sitatsjekk (`:1-4`).

## 6. Promptene (`src/prompts/**`)

| Fil | Linjer | Brukt av | Avgjørende instruks (fil:linje) |
|---|---|---|---|
| shared.ts | 17 | alle (HARD_RULES/wrapDocument) | `shared.ts:5`: «Du gir råd; mennesker tar bid/no-bid-beslutningen.» `shared.ts:3`: finn aldri på fakta, UNKNOWN/null ellers |
| brief.ts | 33 | tender-brief.ts | `brief.ts:13`: sitater kontrolleres maskinelt; ikke-funnet ⇒ «ikke verifisert». `:26`: «Ikke vurder om vi bør by» |
| legal.ts | 32 | lib/legal/ask.ts | `legal.ts:8`: hver setning MÅ ha kilde+ordrett sitat (≥3 ord); `:11`: «Du gir ikke juridisk rådgivning og konkluderer ikke» |
| feilsjekk.ts | 30 | lib/feilsjekk/explain.ts | `feilsjekk.ts:9`: «Du gir ikke juridisk rådgivning og konkluderer ikke. Anskaffelsesjuristen vurderer.» |
| klage.ts | 24 | lib/klage/evaluation.ts | `klage.ts:7`: ukjent verdi ⇒ null, aldri gjett; `:8`: hver verdi må ha ≥5-ords sitat |
| kompetanse.ts | 51 | ingest-answer, parse-cv, assess-requirements | `kompetanse.ts:35`: «Ingen dokumentasjon ⇒ UNKNOWN. Aldri gjett.» |
| requirements.ts | 53 | extract-requirements.ts | `requirements.ts:4-7`: sitat kontrolleres maskinelt mot kilde; dual-pass kontrollør (`:39`) ser ikke pass 1 |
| tilbud.ts | 60 | draft-bid, contract-review, red-team | `tilbud.ts:4` (AI_ROLE): «Du tar aldri en endelig beslutning om bud, forbehold eller juridiske spørsmål.» `:46`: forbehold kan gi avvisning — foreslå kun ved høy risiko |
| challenge.ts | 41 | challenge.ts | `challenge.ts:14`: «Ikke dikt opp konkurrenter, referanser eller tall.» |
| news.ts | 32 | scan-news, news-digest | `news.ts:12`: kun det som står i teksten, ingen tall/navn/datoer som ikke står der |

## 7. Sømmer for en juridisk kunnskapsmotor (observasjon, ingen design)

- `src/lib/legal/` er ALLEREDE en fullverdig retrieval-motor (ask.ts, retrieve.ts, search.ts, embeddings.ts, db.ts, query.ts, kofa/, lovdata.ts) — ikke et tomt felt. `legal/ask.ts:9` henter `RetrievedChunk` fra `retrieve.ts`, bygger prompt i `prompts/legal.ts`, sjekker svaret med `judgeCitations` (citationJudge.ts) før noe vises.
- `feilsjekk/explain.ts` → `prompts/feilsjekk.ts:feilsjekkMessage` (`:17-29`) sender allerede `law: {label, excerpt}[]` pr. funn inn i prompten — lovtekst slås opp FØR modellkallet, modellen vurderer bare støtte/tvil.
- `tilbud.ts` CONTRACT_SYSTEM (`:35-48`) ber modellen flagge avvik fra standardavtaler (SSA-x/NS 84xx) og endringsklausuler, men henter **ingen** lovtekst — ren LLM-dom uten korpusoppslag. Seam: `contract-review.ts:84` (`completeJson(contractSchema, {system: CONTRACT_SYSTEM, ...})`) kunne mates med relevante KOFA/lov-sitater samme vei som feilsjekk gjør.
- `klage.ts`/`lib/klage/evaluation.ts` (tildelingsbrev) kobler ikke mot `legal/` i det hele tatt — rent faktautrekk, ingen juridisk vurdering av selve avslaget.
- `tender-brief.ts` bruker `verify.ts`, ikke `legal/retrieve.ts` — ingen lovkobling i brief-kjeden i dag.

## Tre viktigste funn

1. **13 av 45 jobber kaller en modell**; `generate.brief` er 80 % av målt ukeskost ($17.58 av $21.99) og ble derfor rutet til Haiku 2026-10-13 (models.ts:114-143) — en kostnadsdrevet modellendring på nøyaktig den jobben som produserer brukerens beslutningsgrunnlag.
2. **Ingen dollar-budsjett/tak finnes i kode.** `llm-usage` måler kostnad per kall, men ingenting stopper videre kjøring ved en grense — kun token/tegn/rate-budsjetter eksisterer.
3. **Kvalitetslaget er lagdelt, ikke ensartet håndhevet**: `verify.ts` (sitat-fuzzy-match, 0.85-grense) filtrerer faktisk innhold bort (f.eks. `omfang` uten verifisert sitat droppes, brief.ts:648); `citationJudge`/`consensus` derimot **måler og flagger** (`needsHuman`, `needsReview`) men avgjør aldri selv — alt usikkert går til et menneske, aldri til auto-godkjenning. Legal-retrieval-motoren (`lib/legal/`) finnes allerede og brukes av `legal/ask.ts` og `feilsjekk/explain.ts`, men IKKE av `contract-review`/`klage`.
