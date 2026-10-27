# Veldora strategiråd — runde 1, syntese

Kilde: 7 panerapporter (~117 kB) lest av to uavhengige synteseagenter 2026-10-13.
Alt under er komprimert FRA panenes egne rapporter. Stryk-lista nederst er påstander som IKKE skal brukes videre.

## Det alle landet på uavhengig (sterkeste signaler)

- Dokument-pipen er det ene manglende leddet alt annet henger på. data-1, tools-1 og paal-1 fant uavhengig at `tenders.documentsUrl` lagres men ALDRI hentes, at det ikke finnes én `payload.create` mot `documents` i `src/`, og at hele sitat-med-sidehenvisning-løftet derfor hviler på manuell opplasting. Tre domener, samme fil:linje-belegg, ingen motstemme.
- Ingenting nytt skal bygges før det som finnes er skrudd på. Alle sju leverer samme mønster: `TASK_MODEL_DEFAULTS` tom, `embeddings.ts` returnerer null, `expiry.ts` uwiret, 29 røyktester utenfor CI, 59 `agent_verdict`-etiketter som ingenting leser, `retentionDays` virksom på 4 av 58 collections, `omnigent/firm` aldri startet. Dette er det sterkeste signalet i hele runden.
- Azure-migrering har ingen dokumentert kunde bak seg. infra-1 priser gulvet til 160-200 USD/mnd mot ~40-60 i dag og finner null Azure-fotavtrykk (`which az` tomt); paal-1 viser at Azure-premisset er eksplisitt ASSUMPTION-merket i `tre-scopes.md:78-81` og trolig gjelder kundeproduktene; tools-1 fant Azure ikke brukt som kjøremiljø noe sted. Krever kundekrav, ellers er det teknologiskift uten kjøper.
- Deterministisk først, LLM bare til uttrekk, klassifisering og forklaring — aldri som rangeringsnøkkel eller juridisk konklusjon. learning-1 (AUC 0,55-0,58 på dagens score, `scope_score` 0,678 uten LLM), admin-1 (regex-regler som tviler mot `ukjent`), tools-1 (`verify.ts` → `citationFlags.ts` → Jev → modell bare i båndet) og trading-1 lander på samme skille, og `prd/kvalifikasjonslag.md` har alt vedtatt det.
- Mennesket i løkken skal ikke svekkes. `bid_no_bid` er alltid null og ingen kodelinje setter det, `decisionGuard.ts:5-21` nullstiller beslutningsfelt ved enhver agentskriving, og innleveringssjekklisten BLOKKERER et menneske med HTTP 409 i stedet for å handle for det. admin-1 og trading-1 peker på samme apparat og sier: kopier det, ikke bygg nytt.
- Datapolicy-gaten er riktig bygget og feil konfigurert. infra-1, admin-1 og tools-1 fant uavhengig at gaten kalles før hvert kall (`llm.ts:128-136`) men at defaulten er fail-open (`datapolicy.ts:41`, `DataPolicy.ts:26-27`), at det ikke finnes PII-maskering noe sted (`grep redact|maskPII|anonymize` → 0), og at CV-tekst, kunde-epost og WhatsApp går ut urørt. Tre domener, samme konklusjon: liten kodeendring, operatørens policy.
- Kortet lyver i dag. `winProbability`/`fitScore` har AUC 0,575/0,577 (learning-1, prod), «lav konkurranse» finnes bare etter tildeling fordi `bidderCount` kommer fra `receivedTenders` (data-1), fornyelsesdato hviler på en 48-måneders fallback (data-1), og vinnsjansen vises uten forbehold på en hardkodet fire-tilbyder-antakelse (paal-1). Fire roller: FACT/ANTAKELSE-merking hører i komponenten, ikke i fotnoten.
- Multi-tenancy finnes ikke, og er en absolutt forutsetning for ekstern kunde. `Users` har ingen org-nøkkel, `access/index.ts:9-31` har null referanse til tenant, `Customers.ts:16` er `read: isLoggedIn` — alle innloggede ser alt på tvers av 58 collections. infra-1, admin-1 og paal-1 er enige om at dette er sant; de er bare uenige om prislappen.

## Dagens tilstand per domene

### infra-1 (Azure/FinOps/sikkerhet)

Stacken er allerede EU-pinnet: Vercel arn1/Stockholm, Railway europe-west4-drams3a, IaC i TypeScript. Null Azure-fotavtrykk (`which az` tomt, ingen subscription/Entra-tenant), og Azure-gulvet er 3-4x dagens. Prod er ustabil i redeploy-vinduer, har ingen APM/tracing/ekstern uptime-tjeneste, og eneste probe er en WSL-boks utenfor repoet.

- 33 env-navn fordelt på 3 separate secret-flater (Railway/GitHub/Vercel), ingen sentral store (ARCHITECTURE.md:255-290)
- 1 replika crm + 1 worker; >1 worker dobbeltkøer alle schedules (.railway/railway.ts:34)
- ~35 cron-schedules in-process i ÉN worker-replika (jobs/registry.ts:132-184)
- CRM /api/health → HTTP 000 fem ganger 12.10 (16:57, 17:10, 18:50, 19:07, 21:38), 2 ALERT (vakt.log)
- Azure-gulv $160-200/mnd (headless) vs ~$40-60 i dag; pane-måling sier ~$87 — 2x internt avvik, uverifisert
- Dokumenter på lokalt Railway-volum 2x50 GB, ikke objektlagring (Documents.ts:20,86,93-95)
- railway logs -s worker --since 1h → 0 linjer (pane-måling): vaktens 5xx-sjekk pekte på worker og var derfor blind

### tools-1 (AI-agentsystemer)

Veldora har ferdig modellruting, prisliste og kostnadslogg — men rutingtabellen er tom, så alt kjører på samme mellomdyre modell uten prompt-caching. CRM-en har null tool-loops; «agent» = cron-jobb + logg. Tre halvferdige styringsflater står ubrukt, og firmaets egen kostledger er aldri opprettet.

- 26 oppgavetyper definert, men TASK_MODEL_DEFAULTS er TOM (models.ts:90) ⇒ alt på claude-sonnet-5 (router.ts:8)
- models.ts:118 sier eksplisitt «no cache or batch discount (we use neither)»
- 8 firm-executors active running siden 07.10, NRestarts=0 — verdict-watch har behandlet 0 verdicts (tom journal, tom verdicts/done/)
- omnigent/firm: 21 agent-configs, 220 K, UTRACKET i git, 0 prosesser kjører den
- command-center api/web bygd men AV (ingen 3100/3200, curl → 000)
- 5 av 5 MCP-servere feilet tilkobling i sesjonen; github-MCP borte fra konfig (grep githubcopilot → 0)
- ~/.firm/costs.csv aldri opprettet mens 8 executors har kjørt i 6 døgn (cost-log.sh:26)

### data-1 (procurement-data)

Innhentingen av kunngjøringer er solid (allowlist, dedup på contentHash, idempotente awards), men konkurransegrunnlaget lastes aldri ned — documentsUrl lagres og brukes aldri. TED-queryen er låst til norske oppdragsgivere, så den gir duplikater av Doffin, ikke EU-marked. Markedsintelligensen regnes live og persisteres ikke.

- Keyless Doffin har hardt tak på 1000 treff (doffinWebclient.ts:19, håndhevet ingest-doffin.ts:65)
- TED-query = organisation-country-buyer=NOR (ted.ts:286-288) — ingen EU-/nordisk konkurrentintelligens
- Parser: PDF+DOCX+TXT. XLSX nei, HTML nei, OCR nei (extractText.ts:49,58-59)
- MarketSnapshots persisterer 5 skalarer (MarketSnapshots.ts:12-16) av et rikt SegmentRow; CPV-grain = 2-sifret divisjon
- radar/expiry.ts predictRetenders() ferdig skrevet, IKKE wiret til jobb/endpoint; contractEnd skrives aldri ⇒ fallback 48 mnd ANTAKELSE
- Myhre-korpus: 187 rader, 821 claims, alle fra robertmyhre.no, 134/187 (72 %) uten §-referanse, 0 rader 2020-2024, 11/32 FOA-kapitler udekket, claim-basis «forfatterens vurdering» i 316/821

### learning-1 (ML/anbefalingsmotor)

Rangeringsløypa er deterministisk hele veien, og ingenting filtreres bort i dag — alt rangeres. Men de tre score-kolonnene køen sorteres på er ikke skillbare fra myntkast, og AUC beregnes allerede i prod uten at noen handler på den. Et komplett, append-only feature-store-snapshot og 59 kalibreringsetiketter ligger uleste i basen.

- 105 beslutninger (NO_BID 69, STRONG_BID 24, BID 6, INVESTIGATE 6) — ikke 97
- AUC: fitScore 0,577 · priorityScore 0,549 · winProbability 0,575 · scope_score 0,678 (95 %-CI ±0,11) — beregnes alt i lib/learning/agreement.ts, eksponert på GET /triage/stats
- Scope-kategori som KONTRAFAKTISK filter: kutter 69,6 % av nei, taper 13,3 % av ja (4/30) → presisjon 28,6 %→51,0 %, lift 1,78x, ~2,8 t spart per 105 saker. 809/907 (89,2 %) av køen er utenfor-scope
- tender_decisions.snapshot: 19 felt × 105 rader, append-only, serverstemplet (create/update: nobody)
- agent_verdict: for-høy 24 · for-lav 10 · riktig 25 · vet-ikke 45 = 59 etiketter, leses IKKE av buildProfile (profile.ts:156-203)
- 0 treff repo-bredt på exploration|epsilon|diversity|bandit|thompson — motoren kan bare bli smalere
- Fire grader kollapses til binært (sideOf, decisionReasons.ts:70-71): STRONG_BID og INVESTIGATE veier identisk
- Terskelen 30 finnes i fire uavhengige kopier (triage.ts:33, adjust.ts:13, priority.ts:58, dashboard triage.ts:18); profileN faller tilbake til decidedCount (endpoints/triage.ts:305)
- Verdi-propagering: tenders.estimated_value_amount 947/1748 (54,2 %) → opportunities.estimated_value 70/907 (7,7 %)
- pgvector finnes IKKE i prod (pg_extension → kun plpgsql); search_vector er tsvector. bid_drafts = 1; awards = 552 med bidder_count

### trading-1 (staff engineer / kodebase, CI, migrering)

Frontend er allerede en ren HTTP-klient gjennom én søm (cms.ts), så en omskriving er backend-trygg. Det som ikke er trygt er å deploye: to ukoordinerte deploy-baner, CI bygger aldri crm, 29 ferdige røyktester kjører ikke i CI, og merge-porten er en hardkodet strengliste som alt har sluppet gjennom en rød port.

- crm: 754 TS-filer, 95 129 linjer, 58 collections + 11 globals, 131 egendefinerte endepunkter, 51 migreringer på 17 dager
- dashboard: 222 filer, 37 171 linjer, 46 ruter, 108 server actions
- Tester: 294 filer / 32 282 linjer — men 0 på .tsx, 0 på 108 server actions, 0 på 51 migreringer, 0 e2e/DOM, 18 access-tester for 58 collections
- 29 smoke-*.ts mot ekte Postgres finnes (18/18 og 19/19 logget); 0 av dem kjører i CI (grep smoke i workflows → 0)
- anbud.yml: crm = tsc + test, INGEN npm run build (:18-24) — mens payload.config.ts ble rørt av 35 commits på 14 dager
- 23 håndskrevne types-*.ts speiler collections; dashboard importerer aldri payload-types.ts
- 9 endepunkter returnerer rå Payload-dokumenter uten DTO; 131 endepunkter, ingen /v1
- Churn 14 dager: ARCHITECTURE.md 61 berøringer, payload-types.ts 48, migrations/index.ts 48; 20 worktrees, ~28 grener
- PR #154: migrasjonssnapshot-porten svarte rødt, boten merget likevel

### paal-1 (produktstrategi/forretningsmodell)

Verdiløftet «slipp å lete» er ikke implementert — det er sortert kunngjøringstekst over en tom dokumentbase. Markedet er overfylt i den billige enden, og den eneste nedskrevne kommersielle veien (salg til offentlige oppdragsgivere) kolliderer med ADR-0015 som gjør Solarconsulting AS til budgiver. Strategien peker på sol; måledata sier sol finnes ikke.

- documents = 0 rader i prod; 20 nyeste muligheter har 0 briefer, 0 krav, 0 sitater (prod-måling 11.10)
- Konkurrentpriser 13.10: Varsly Pro 99 kr/mnd · Anbudsregisteret 249/499 (AI-utkast 49 kr) · Finndoff 829 (full 2 977) · Mercell 1 000/1 800/2 580 · Tendium Light ~1 300
- Realistisk SMB-ARPU 10 000-35 000 kr/år ⇒ krav: driftskostnad < 150 kr/kunde/mnd
- Sol: 0 relevante av 1653 kunngjøringer på 12 dager (PR #142); alle 30 ja ligger i IT
- 675 anskaffelser har alt direkte dokumentlenke — startpunkt for dokumentinntak
- Hyyr: ~0 → 15 MNOK ARR på 4 mnd, 9/9 vunnet, ~200 offentlige oppdragsgivere (Shifter 15.07.2026)
- api.doffin.no/public/v2 gir 401 uten nøkkel; TED-API reelt åpent (200, kommersiell gjenbruk tillatt, 2011/833/EU)
- Ingen ICP-katalog (sales/README.md:7 lover den), ingen prisliste i product/prd/sales/strategy
- Tre-scopes-beslutningen har frist 19.10 — seks dager — og lå ikke på rådets bord

### admin-1 (jus og regelverk)

Menneske-i-løkken er håndhevet strukturelt, ikke bare instruert: bid_no_bid er alltid null, decisionGuard nullstiller agentskriving, og kommentar kan ikke nå RAG-pipelinen. Avvikene ligger i persondata: CV-tekst sendes til modell-API uten samtykkesjekk, uten maskering og uten sletterutine. Retention-feltet finnes i UI for datatyper der ingen slettejobb eksisterer.

- Retention håndhevet på 4 av 58 collections (4 av 8 datatyper); udekket: Prospekter, People, Cvs, Customers, Users, EmailSends, HelperConversations, Notes
- 0 treff på redact|maskPII|anonymize — ingen PII-redigering før modellkall; scrubQuestion vasker bare loggkopien
- 0 treff på anthropic-beta|zero-retention|no-train i llm.ts — llm.ts:156 setter kun content-type, x-api-key, anthropic-version
- kommentar-regler.json: 59 rader (jq length), 59/59 status ASSUMPTION, 0/59 verifiedBy ⇒ lowersSeverity er i praksis aldri aktiv. Ordren sa 18, data-1 sa 50
- Kildehierarki: 0 grep-treff på kildetype/autoritet/tier over fem legal-samlinger; eneste diskriminator er LegalDocuments.kind = lov|forskrift|kofa
- avvisningsklasse har avvisningsklasseBy='human' men INGEN avvisningsklasseAt, ingen påkrevd begrunnelse, ingen revisjonslogg
- Terskelverdier finnes kun i prosa med hentedato; Part er inndata, ikke beregnet ⇒ 'ukjent' senker alvorlighet på 4 steder (rules.ts:207,298,422,480-481)
- Frister på helg/helligdag flyttes ikke, og koden erkjenner rettsvirkningen som UKJENT (deadlines.ts:24) — karens er prekluderende
- KOFA-crawler: robots.txt per forespørsel, 3 s hardt gulv, identifiserende UA (polite.ts:13,65-99)

## Gjenbrukbart — bygg ikke dette på nytt

- **llm-usage-apparatet: usage.ts + LlmUsage + cost.ts + /api/anbud/ai-usage + usageSummary (what-if-reprising) + /ai-siden** — Ferdig per-kall kostnadsmåling med priceVersion. Legg på tenantId ⇒ per-kunde marginregnskap gratis. Svarer også på paal-1s 150 kr/kunde/mnd-krav uten å estimere. (infra-1 + tools-1 + paal-1 (tre uavhengige funn))
- **Modellrutingen: config/models.ts (26 oppgavetyper + dataClass + hardkodet prisliste) + llm/router.ts** — Billigste sparepunkt i hele porteføljen. Maskineriet er bygget, bryteren er av — trenger utfylling av TASK_MODEL_DEFAULTS, ikke bygging. (tools-1)
- **Datapolicy-gaten: lib/datapolicy.ts + assertDataPolicy i både complete og streamComplete, med per-task datatyper** — Ett choke point — nøyaktig det en tenant-scoped policy trenger. Riktig bygget, feil konfigurert (default fail-open). (infra-1 + tools-1 + admin-1)
- **tender_decisions.snapshot — 19 felt × 105 rader, append-only, serverstemplet, lekkasjefritt** — Treningssettet/feature-storet finnes allerede. Ingen datainnsamling trengs for runde 1 av personalisering. (learning-1 (prod-spørring))
- **agent_verdict / confidence / duration_ms / primary_reason + answers[] (rank-higher, hide-similar)** — 59 retningsgivende kalibreringsetiketter + 103 konfidens + 103 tidsbruk. Ferdig feedback-kanal; nok til én global kalibrering (Platt/isotonisk). Leses av ingen i dag. (learning-1 + data-1)
- **AUC-målingen som alt kjører i prod: lib/learning/agreement.ts (auc/aucFit/aucPriority) på GET /triage/stats** — Kvalitetsmålingen av rangeringen finnes og eksponeres allerede — ingen trenger å bygge den, bare handle på den. (learning-1)
- **Deterministisk kandidatlag: lib/scoring/scope.ts + config/tracks.ts (matchScopeCategory, CPV 10 p / nøkkelord 4 p / cap 24)** — AUC 0,678 — eneste komponent med målbart signal, gratis, ingen LLM. Behold som recall-lag, aldri som skjuling. (learning-1)
- **RRF-hybridhenting + gullsett-eval: lib/legal/retrieve.ts + eval/legal-gold.json + scripts/eval-legal.ts** — Hybrid henting UTEN vektorer, målt (recall@8 0,930 / MRR 0,630 på 43 spørsmål). Kopier mønsteret til anbudshenting i stedet for å bygge RAG som nytt prosjekt. (learning-1 (+ tools-1: embeddings.ts:17 er en bryter, ikke et prosjekt))
- **De 29 crm/scripts/smoke-*.ts mot ekte Postgres via Payload local API (18/18 og 19/19 logget)** — Ferdig DB-oppførselsdekning. Mangler kun en CI-jobb med Postgres-service — billigste kvalitetsgevinst i hele rådet. (trading-1)
- **dashboard/src/lib/cms.ts — én søm, 82 importører, JWT-videresending, Payload-access arves** — Gjør frontend-omskriving backend-trygg: ny flate kan skrives mot denne uten å røre backend. Dashboard har null DB-tilgang (invariant, ARCHITECTURE.md:49-53). (trading-1)
- **payload-types.ts genereres allerede (payload.config.ts:204)** — Klient-typene finnes, de brukes bare ikke — erstatter 23 håndskrevne speil og gjør feltnavnbytte til rød CI i stedet for stille prod-feil. (trading-1)
- **migrate-or-die.ts + check-migration-snapshot.sh + migrasjonssnapshot-porten i CI** — Fail-closed migrering og skjemadisiplin — forutsetning for rad-nivå multi-tenancy. (infra-1 + trading-1)
- **/api/health med ekte DB-rundtur + heartbeatAgeSec + 503 ved feil** — Grunnlaget for post-deploy-porten som mangler, og for ekstern probe. (infra-1 + trading-1)
- **documents/extractText.ts (PDF/DOCX/TXT, \f-sideskille for sidetall) + Documents.afterChange-hook som køer extract-requirements** — Hele parse→lagre→kø-veien er ferdig. Dokumentpipen trenger bare en HENTER foran seg, ikke ny parser. (data-1 + tools-1)
- **lib/http.ts — allowlist på 10 verter, 10 MiB-tak, re-sjekk per redirect, 3 forsøk, 20 s timeout, felles identifiserende UA** — All nettverkstrafikk gjennom ett revisjonsbart punkt; klar til bruk som nedlaster for konkurransegrunnlag. (data-1 + admin-1)
- **Sitatkjeden: verify.ts (eksakt → Sellers approx 0,85) + citationFlags.ts (kodeavvisning) + citationJudge.ts (Jev, kun tvilsbåndet til Claude)** — Deterministisk-først-mønsteret, ferdig og godt. Verdt å kopiere til flere oppgaver — og det som skiller oss fra et nyhetsvarsel, straks dokumentene finnes. (tools-1)
- **awards-backfill.ts + Awards/Suppliers + radar/competitors.ts (medianBidderCount, expectedBidders)** — 552 awards med bidder_count og beløp — base rates for konkurranse og forventet verdi finnes. Markedsutfall mangler ikke, bare VÅRE egne tilbudsutfall. (data-1 + learning-1)
- **radar/expiry.ts predictRetenders()** — Fornyelsesprediksjon ferdig skrevet, mangler kun wiring til registry.ts (og at contractEnd faktisk skrives fra eForm-detaljen). (data-1)
- **reservations-signaturmønsteret: juristBy/juristAt/juristNote + serverOnly + dedikert review-endepunkt + auto-nullstilling ved omskrevet ordlyd** — Admin-1s svakhet om avvisningsklasse uten spor er allerede løst én gang i samme kodebase. Kopier rått. (admin-1)
- **decisionGuard.ts + bid_no_bid=null + innleveringssjekklistens HTTP 409 + approvals/data-policy-porten + kommentar-exports.test.ts (kildenivå-guard mot URL-lekkasje)** — Ferdig styring for en «proaktiv AI-flate»: varsle/rangere/begrunne/blokkere ja, handle nei. Plus automation/lib/run.mjs tool-use-loop med harde LIMITS (maxTurns 6, maxFetches 12, 300 s) + robots-policy om en ekte agent-loop trengs. Ikke bygg nytt. (admin-1 + trading-1 + tools-1)

## Kritiske svakheter

- **Konkurransegrunnlaget lastes aldri ned — hele verdiløftet står på en tom dokumentbase** [data-1 + tools-1 + paal-1 (tre uavhengige funn, samme konklusjon)] — documentsUrl lagres (ted.ts:263, doffinWebclient.ts:422) men hentes ALDRI; ingen payload.create mot documents i src/. Prod-måling 11.10: documents = 0 rader, 20 nyeste muligheter har 0 briefer/0 krav/0 sitater. 675 anskaffelser har alt direkte dokumentlenke. → Alt nedstrøms (sitatkjede, kravuttrekk, SMB-ekskludering, tilbudsutkast, matching utover tittelsøk) er ornamentikk på to tekstfelt. Produktet er en liste brukeren kunne sett gratis, mens Finndoff henter automatisk fra fire portaler.
- **Køen sorteres på tre tall uten målbar signalverdi — og AUC beregnes allerede i prod uten at noen handler på den** [learning-1 (+ paal-1 og trading-1 underskriver fra forretnings-/kalibreringssiden)] — Prod-målt Mann-Whitney-AUC (n₁=30, n₀=69, CI ±0,11): fitScore 0,577, priorityScore 0,549, winProbability 0,575; deterministisk scope_score 0,678. Tallene finnes alt i lib/learning/agreement.ts, eksponert på GET /triage/stats. winProbability er allerede erkjent ukalibrert og holdt utenfor Live-utvalget (triage.ts:378-382), men ikke ute av rangeringen. TriageCard.tsx:117 viser vinnsjanse uten forbehold, på hardkodet fallback om 4 tilbydere (baseRates.ts:110). → Operatøren prioriteres av myntkast presentert som modell, og sender uker med tilbudsskriving inn på feil sak. Kortet viser hva som er sannsynlig, ikke hva som lønner seg.
- **Ingen deploy-verifisering: to ukoordinerte baner, CI bygger aldri crm, 29 ferdige røyktester kjører ikke** [trading-1 (+ infra-1 måler symptomet i prod: HTTP 000 fem ganger 12.10)] — anbud.yml:18-24 har tsc+test men ingen npm run build for crm; deploy.yml:110 (vercel deploy --prod) er siste steg, ingen helsesjekk etterpå; worker har ingen healthcheck (railway.ts:33); grep smoke i .github/workflows → 0 av 29. payload.config.ts rørt av 35 commits på 14 dager. → Rotårsaken til «grønn CI, virker ikke i prod» består. Frontend kan gå live før migreringen, byggbrudd oppdages først når Railway-deployen feiler — etter merge. Mot en operatør med anbudsfrist 19.10 kan dette koste et reelt anbud.
- **Datapolicy-gaten er default fail-open og maskerer ingenting — med CV-data, kunde-epost og WhatsApp i omløp** [infra-1 + admin-1 (to uavhengige funn; admin-1 verifiserte hvert ledd i CV-kjeden)] — PERMISSIVE_POLICY / defaultModelApiAllowed:true (datapolicy.ts:41, DataPolicy.ts:26-27); llm.ts:88-89 «without one, everything is allowed». To fail-open-veier til: loadDataPolicy fanger feil og returnerer permissiv (datapolicy.ts:94-108, bevisst valg), og llm.ts:130 lar ukjent task passere som 'intern'. Eneste transformasjon før sending er truncate() til 60 000 tegn. 0 treff på redact|maskPII|anonymize, 0 treff på zero-retention/no-train i llm.ts. parse-cv sjekker ikke People.consent; Cvs.extractedText har ingen sletterutine. → Egne ansattes persondata forlater perimeteren uten kontroll, uten sletterutine og uten registrert databehandleravtale. Samlet er dette et avvik, ikke en risiko. Blokkerende for kunde nr. 2, som ikke har signert noe.
- **Null multi-tenancy: ingen tenant-akse i datamodellen, alle innloggede ser alt på tvers av 58 collections** [infra-1 + admin-1] — Users har email/name/role:admin|member|viewer og INGEN customer-/org-nøkkel (Users.ts:34-56). access/index.ts:9-31 har null referanse til tenant/org/customer; Customers.ts:16 er read:isLoggedIn. Admin-1: ved første eksterne kunde blir vi databehandler — DPA mot kunden, underleverandørliste, sletting på instruks, tenant-scoping i hver access-regel. Ingenting av det er bygget. → «Vi kan selge til 10 kunder» er ikke sant med dagens datamodell. Enten budsjetteres 3 dager tenant-arbeid (rad-nivå tenantId + negativ test per collection: bruker i tenant A får 0 rader fra tenant B), eller vi selger ikke. Oppdages dette etter salg er det en kundekrise, ikke en sprint.
- **Merge-porten er en hardkodet strengliste som allerede har sluppet gjennom en rød port** [trading-1] — auto-merge.yml:62,127 — REQUIRED=(schemas website) + want_checks. migrasjonssnapshot ble lagt til i #136 uten å røre auto-merge.yml, svarte rødt på PR #154, boten merget likevel (repoet skriver det selv, :120-123). Branch protection er Pro-gated på privat GitHub Free (:6-11). Direkte push til main er tillatt (guard-main.yml:3-6, ADR-0012-tillegget). Boten merger også når PR ligger bak main, uten ny CI (:160-170). → Hver ny CI-jobb er rådgivende til navnet skrives inn på to steder, og et navnebytte feiler stille. Alle porter i en fase 0-pakke er valgfrie så lenge direkte push til main står åpent — feilklassen gjentar seg.
- **Ingen reproduserbare kvalitetstall — beslutninger tas mot målinger som ikke kan etterprøves** [learning-1 (korrigerer paal-1, PR #144 og issue 050)] — eval-scope-categories.ts leser en JSON-eksport som ikke ligger i repoet; calibration-backtest.ts er typesjekket men aldri kjørt mot prod (fil-header l.9-12: ingen DB-rute). Målbart utfall: PR #144 rapporterer 8 av 30 ja feilfiltrert (27 %), prod-måling i dag gir 4 av 30 (13,3 %) — avviket skyldes at eksportsettet mangler summary på 29/105 rader. Issue 050s akseptkriterium vurderes mot det gale tallet. Samme kilde ga «97 beslutninger»; prod har 105. Og «725 i kø» var antall som trengte scope-backfill, ikke køstørrelse. → Scopefilteret vurderes mot et tall som er dobbelt så ille som virkeligheten, og hvert kvalitetstall i rådet er et engangsutsagn. Frosset, versjonert eval-artefakt blokkerer all annen ML-prioritering.
- **Ingen Postgres-backup utenfor Railways egen, aldri restore-testet — og dokumentene ligger på samme lokale volum** [infra-1 (hovedrapport + pane-tillegg, som gjør funnet hardere enn README-boksen antyder)] — projects/anbud/README.md:190 ukrysset; ADR-0014:77-80 flagget samme. litestream.service kjører men dekker bare lokale SQLite-baser (command-center, brain, memory.db) — anbud-Postgres er ikke i den, og `systemctl --user list-timers --all` har ingen backup-timer for anbud. Documents.ts:20,86,93-95: staticDir=UPLOAD_DIR, disableLocalStorage:false ⇒ lokal disk på Railway-volumet, ikke objektlagring. → Tap av Railway-volumet tar både database og alle opplastede dokumenter. Og «vi har backup» er usant inntil en restore er gjennomført én gang.
- **Grensesnittet er avskrevet for hånd 23 ganger; 131 endepunkter uten versjonering** [trading-1] — Dashboard importerer ALDRI crm/src/payload-types.ts — 23 types-*.ts speiler collections manuelt og sier det selv (types.ts:1-3). 9 endepunkter returnerer rå Payload-dokumenter uten DTO (chat.ts:330,354; henvendelser.ts:112,125; godkjenning.ts:67; leveranse.ts:166; okonomi.ts:119; prospekter.ts:67; kommentar.ts:97). ~60 kallsteder går rett på auto-REST for 20+ slugs med where/depth-dialekten reimplementert i cms.ts:33-48. Ingen /v1. config/tracks.ts ber i headeren om manuell synk på tvers av apper, uten test. → Et feltnavnbytte i backend knekker klienten uten at noen port merker det, og 58 collections kan ikke endres uten å risikere frontend. Typene genereres allerede — dette er en billig fiks som i dag koster stille prod-feil.
- **Rettskildegrunnlaget er ikke juristverifisert, og terskel-/fristberegningen er prekluderende svak** [admin-1 + data-1 (data-1 oppgav 50 rader, ordren 18; admin-1s jq length = 59 er den sterkeste målingen)] — kommentar-regler.json: 59 rader, 59/59 ASSUMPTION, 0/59 verifiedBy. Myhre-korpus: 187 blogginnlegg, 72 % uten §-referanse, hull 2020-2024, redistribution_rights RED, ingen committet crawler-kode (robots/UA/1 req/s er selvrapportert i en README). Ingen maskinlesbar terskelverditabell; Part er inndata, ikke beregnet, og 'ukjent' senker alvorlighet på fire steder (rules.ts:207,298,422,480-481) og gjør karensfristen uberegnelig (klage/deadlines.ts:43). Frister på helg/helligdag flyttes ikke og koden erkjenner rettsvirkningen som UKJENT (deadlines.ts:24). → Direkte rettstapsrisiko på klagefrister (karens og midlertidig forføyning er prekluderende), og «Myhres kommentarer til anskaffelsesretten» er i realiteten et blogg-arkiv presentert som rettskilde. Ingenting i det juridiske domenet kan merkes FACT før juristgjennomgang.

## Hovedanbefaling per domene

- **infra-1 (Azure/FinOps/sikkerhet)**: BLI på Vercel + Railway — ikke migrer til Azure nå; ingen av svakhetene løses av Azure, og vi er allerede EU-pinnet. Bruk pengene på rad-nivå tenantId håndhevet i Payload-access (med negativ test per collection), defaultModelApiAllowed=false med allowlist, og ekte overvåking/backup/objektlagring. · kostnad: 4-6 dager (tenant-akse 3d, policy 0,5d, drift/backup/objektlagring 1-1,5d). Hybrid Azure = 10-15 dager, full Azure = 18-25 dager — trigger (kontraktsfestet norsk datalokasjon eller Entra-SSO), ikke plan. · risiko: Lav. Railway-ustabiliteten består (mitigeres av ekstern probe + plan uten cold start). Alle kronetall er ANTAKELSE til llm-usage-eksport + fakturabilde foreligger: Azure-gulvet oppgis som både ~$87 og $160-200, og LLM/anbud som både $0,08 og $0,50 — ingen av dem bør siteres videre.
- **tools-1 (AI-agentsystemer)**: Ikke bygg nye agenter — skru på det som alt er bygget: fyll TASK_MODEL_DEFAULTS og slå på prompt-caching (dag 0,5), bygg det manglende første leddet (Doffin-vedleggshenting, rent deterministisk), og slå på ÉN styringsflate (omni-firm.sh mot 6767) med omnigent/ committet. De åtte foreslåtte Veldora-rollene bør bli tre tjenester og én inngang, event-drevet på eksisterende payload.jobs-kø. · kostnad: 3 dager (0,5 ruting/caching + 1 dokumenthenter + 1 styringsflate; tale sist og lokalt, 1 dag). Alt målbart i llm-usage før/etter. · risiko: Lav og reversibel — behold de 16 panene som fallback i to uker, riv ingenting. Avvist alternativ: command-center som hovedflate (dispatch ender i fil uten pty-strøm, 3-5 dager for mindre enn omnigent gir i dag). HeyGen: lav kode-risiko, middels governance, ingen plass i Veldora.
- **data-1 (procurement-data)**: Bygg dokument-pipen: documentsUrl → nedlasting via http.ts-allowlist → eksisterende extractText → documents-rader knyttet til tender med kind='konkurransegrunnlag'. Den ene endringen låser opp SMB-ekskludering, kravuttrekk i skala, matching utover tittelsøk og sitérbare briefs samtidig. · kostnad: 4-6 dager (henter + ZIP + kvote/backoff + rate-limit + tester), +2 dager for OCR-fallback (operatør-gate). Alt. A (persister markedstidsserie på CPV-gruppe + wire expiry.ts) 2-3 dager; Alt. B (BidOutcome + lostReason) 2 dager, men vent på kø-SQL. · risiko: Doffin kan levere ZIP bak redirect/sesjon; lagringsvolum vokser (10 MB-tak i http.ts); skannet PDF gir null uten OCR. Juridisk lav for Doffin/TED-dokumenter. Ikke vis «lav konkurranse» eller «fornyes om X mnd» som fakta — førstnevnte finnes kun post-tildeling, sistnevnte hviler på 48-måneders antakelse.
- **learning-1 (ML/anbefalingsmotor)**: «Evidence-ranked shortlist»: harde filtre først (not-a-tender 6, too-large 5, deadline 2 = 13 av 69 nei uten modell), deterministisk scope-evidens som recall-lag operatøren kan slå av, rangering på maks 5 monotone trekk med tids-splitt og rapportert kalibrering (Brier + reliabilitetskurve), og les agent_verdict som kalibreringsmål. Frosset versjonert eval-artefakt først — det blokkerer alt annet. · kostnad: 6-9 dager. Alt. A (håndsatte vekter, ingen læring) 2 dager. Alt. B (LambdaMART/XGBoost nå) AVVIST: 30 positive gir memorering. Modellklasser blir forsvarlige ved ~300 etiketter (logistisk/parvis) og ~1000 (XGBoost); bandits først når leverte tilbud registreres med utfall. · risiko: Lav — ingenting skjules permanent, alt er deterministisk eller en lesbar 5-trekks lineær modell. Presisjon 28,6 %→51 % er alt målt. LLM hører i ekstraksjon/klassifisering/forklaring, aldri som sorteringsnøkkel. Legg inn 10 % utforskningsplasser: i dag finnes 0 utforskning i hele repoet, så motoren kan bare bli smalere.
- **trading-1 (staff engineer)**: Porter først, så inkrementell strangler bak ruteflagg: fase 0 = crm npm run build i CI, ny royktest-jobb med Postgres + de 29 smoke-scriptene (navnet inn i want_checks i SAMME PR), post-deploy helsesjekk mot /api/health, worker-healthcheck, zod-env-skjema, og genererte dashboard-typer. Deretter lesemodell-lag med kildehenvisning per felt, så ny flate bak flagg med triage først. · kostnad: Fase 0: 3 dager (blokkerer resten). Fase 1 lesemodell: 3-4 dager. Fase 2 ny flate bak flagg: 5-8 dager. · risiko: Big-bang AVVIST — med 0 e2e, 0 tester på 108 server actions og ingen post-deploy-port mot frist 19.10 er det det eneste valget som kan koste et reelt anbud. Churn-nåløyene fikses arkitektonisk (splitt ARCHITECTURE.md per lane, ta genererte typer ut av diffen, mappe-skanning for registre), ikke med rebase-regler.
- **paal-1 (produktstrategi/forretningsmodell)**: Veldora forblir internt verktøy; stryk både Vei A og Vei B — kjøpersiden er uforenlig med ADR-0015 (vi er selv budgiver) og alt notert som uløst habilitetsspørsmål. Produktiseres det noen gang, skal det selges til LEVERANDØRSIDEN. De tre neste tingene: dokumentinntak som gir rader (start med de 675 med direkte lenke), break-even-vinnsjanse på kortet (tilbudskostnad / (verdi × dekningsbidrag)), og utfallsløkken lukket inkl. «for dyrt å by». · kostnad: 0 dager kode for hovedanbefalingen — én ADR. Alt. A (SMB-produkt nå) frarådes sterkt: 40+ dager multi-tenant/auth/fakturering/support før første krone. Alt. B (tjeneste, 15 000/mnd + andel ved vunnet kontrakt) ~5 dager, hold åpen hvis tre-scopes glipper 19.10. · risiko: Lav og reversibel. Krav til arkitekturen: < 150 kr driftskostnad per aktiv kunde per måned — taket settes av markedet (konkurransegulv 99 kr/mnd, realistisk ARPU 10-35k/år), ikke av oss. Operatørens SMB-instinkt er riktigere enn dokumentene, men valget står mellom internt og en kjøperside vi ikke kan røre.
- **admin-1 (jus og regelverk)**: Lukk CV-kjeden først (samtykkesjekk i parse-cv fail-closed, retention koblet for cv/kundedokument slik energidata alt er, cv→modelApiAllowed:false, strengeste Anthropic-retensjon nedskrevet i ADR), deretter retention-dekning for hver datatype som har feltet, deretter kildeklasse K1-K7 med avvisningsklasseAt + påkrevd begrunnelse. Avvik slår designmangel. · kostnad: Steg A 2 dager + én operatørhandling · Steg B 2 dager · Steg C 3-4 dager. Tillegg fra pane-versjonen: datert, versjonert terskelverdier.json + utledet Part + helge-/helligdagsregel med juristverifisert hjemmel, 2-3 dager — smalest, men eneste som fjerner direkte rettstapsrisiko. · risiko: Lav teknisk. Alt. «kun juristgjennomgang av de 59 radene» løser ingen av avvikene; alt. «kildeklasse først» frarådes fordi persondata-avviket da står åpent. Bindende grense å vedta: systemets utdata kan aldri endre en frist, en status eller en levering uten en menneskelig handling — varsle/rangere/begrunne/blokkere ja, handle nei.

## Konflikter — hvem har best BELEGG

### Hvor mye ja-tap koster scope-filteret (grunnlaget for 19.10-beslutningen)

- **A:** paal-1 (produkt): 8 av 30 ja feilfiltrert (27 %), filteret må IKKE slås på før tallet er nær null — fra issue 050 / PR #144
- **B:** learning-1 (ML): 4 av 30 (13,3 %) målt mot prod-kolonnen `opportunities.scope_category`; avviket skyldes at eksportsettet mangler `summary` på 29/105 rader
- **Belegg:** b — learning-1 har prod-spørring OG en navngitt mekanisme for hvorfor paal-1s tall er dobbelt for ille; paal-1 siterer et PR-sammendrag.
- **Avgjøres av:** raadet

### Hvem hadde faktisk tilgang til produksjonsdatabasen i dag

- **A:** data-1 + infra-1: `railway` er BLOCKED av firm-exec-guard, derfor er alle kø-/volumtall fra alle roller ANTAKELSE til operatøren kjører SQL manuelt
- **B:** learning-1: kjørte `railway ssh --service Postgres` read-only og leverte 20+ konkrete tall (105 beslutninger, 907 opportunities, 1748 tenders, 552 awards, pg_extension = kun plpgsql)
- **Belegg:** b — learning-1 har output; data-1s blanketterklæring om at ingen kan ha tall er falsifisert samme dag. Men guard-en oppfører seg ulikt per pane, og det er i seg selv et funn.
- **Avgjøres av:** raadet

### Hva multi-tenancy koster

- **A:** infra-1: rad-nivå `tenantId` + access-regler = 3 dager, «enten budsjetterer vi 3 dager tenant-arbeid, eller så selger vi ikke»
- **B:** admin-1: ved første eksterne kunde blir vi databehandler — DPA mot kunden, underleverandørliste, sletting på instruks, tenant-scoping i HVER access-regel, «en større jobb enn den ser ut». paal-1: 40+ dager inkl. auth/fakturering/support
- **Belegg:** b — infra-1 priser bare skjema+access og utelater negativ test × 58 collections, retention-dekning (4 av 58 i dag) og alt juridisk. a undervurderer med minst en størrelsesorden.
- **Avgjøres av:** operatoren

### Finnes kunde nr. 2 i det hele tatt (premisset halve rådet bygger på)

- **A:** infra-1 + admin-1: bygg tenant-isolasjon, stram datapolicy, skaff DPA — «blokkerende for salg, ikke for bygging», «før kunde nr. 2»
- **B:** paal-1: Veldora forblir internt verktøy; stryk både Vei A og Vei B; den eneste nedskrevne kommersielle veien (salg til oppdragsgivere) er uforenlig med ADR-0015 der Solarconsulting selv er budgiver — habilitetskonflikt, ikke juristvurdert
- **Belegg:** b — paal-1 har ADR-0015 (ACCEPTED) + dokumentert uløst habilitetsspørsmål + konkurrentgulv; infra-1 og admin-1 planlegger for en kunde ingen har besluttet skal finnes.
- **Avgjøres av:** operatoren

### Hva dokument-pipen koster (alles førsteprioritet)

- **A:** tools-1: «Dag 1 — automatisk vedleggshenting fra Doffin → `payload.create` mot documents. Rent deterministisk arbeid, ingen modell»
- **B:** data-1: 4-6 dager (henter + ZIP bak redirect/sesjon + kvote/backoff + rate-limit + tester), +2 dager OCR-fallback som egen operatør-gate; skannet PDF gir null i dag, XLSX og HTML ikke støttet
- **Belegg:** b — data-1 navngir de konkrete feilmodusene og har lest parseren (`extractText.ts:45-59`); tools-1 priser bare det glade løpet. Avviket er 1 mot 6-8 dager på det ene steget alle er enige om.
- **Avgjøres av:** raadet

### Er semantisk søk en bryter eller en operatør-gate

- **A:** tools-1: «`embeddings.ts:17` returnerer null og `retrieve.ts:130-143` er klargjort for pgvector. Det er en bryter og en backfill, ikke et prosjekt»
- **B:** learning-1: `select extname from pg_extension` i prod → kun `plpgsql`. pgvector finnes ikke, er en operatør-gate med ukjent svar (tilbyr Railway det?), ikke et sprintmål
- **Belegg:** b — learning-1 har spurt databasen; tools-1 har lest kode som forutsetter en extension som ikke er installert.
- **Avgjøres av:** operatoren

### Port før deploy, eller vakt etter deploy

- **A:** trading-1: «vaktposten dekker 5xx etter at noe er ute. Jeg vil ha porten FØR deploy» — CI bygger aldri crm (`anbud.yml:18-24`), 0 av 29 røyktester kjører, `deploy.yml:110` er siste steg uten verifisering
- **B:** infra-1: ekstern probe + plan uten cold start; vakten målte HTTP 000 fem ganger 12.10 og «Dashboard treg 6,81 s» 13.10, og de to vakt-grenene venter bare på push
- **Belegg:** ingen — de måler to forskjellige feilklasser (byggbrudd før merge mot ustabilitet i drift) og begge har belegg. Konflikten er rekkefølge og 1,5 dag, ikke sannhet.
- **Avgjøres av:** raadet

### LLM-kostmodellen forutsetter en arkitektur som er avslått

- **A:** infra-1: MVP ~150-260 USD/mnd, ~0,50 USD per dypanalysert anbud, screening på Haiku ⇒ 1-2 USD/mnd. «Hosting er ikke problemet — LLM-kost per anbud er hele enhetsøkonomien»
- **B:** tools-1: `TASK_MODEL_DEFAULTS` er TOM (`models.ts:90`) ⇒ alle 26 oppgavetyper kjører på default `claude-sonnet-5` (`router.ts:8`), og `models.ts:118` sier rett ut «no cache or batch discount (we use neither)»
- **Belegg:** b — infra-1 priser en ruting som ikke er skrudd på, og innrømmer selv at infraforbruket er usporet og at både `vercel` og `railway` CLI var blokkert. Hele tabellen er ANTAKELSE på begge sider av likhetstegnet.
- **Avgjøres av:** raadet

### Hvem setter kostnadstaket — markedet eller måleren

- **A:** paal-1: «taket settes av markedet, ikke av oss». Krav: driftskostnad under 150 kr per aktiv kunde per måned, inkludert alle modellkall. Klarer arkitekturen ikke det, er arkitekturen feil
- **B:** infra-1: «Ask til operatør: 7 dagers `llm-usage`-eksport + ett faktura-bilde, så erstatter jeg antakelsene med målte tall i runde 2» — ingen tak før det er målt
- **Belegg:** ingen — paal-1s 150 kr er avledet av et ARPU-anslag (10-35k/år) som ikke har kilde; infra-1 har ingen målt kostnad å stille opp mot. Begge argumenterer fra tall de ikke har.
- **Avgjøres av:** operatoren

### «Proaktiv, personalisert AI-plattform» mot absolutt handlingsforbud

- **A:** Operatørens ordre + problemstilling D: åtte autonome agentroller, proaktiv flate, «ting kjørende live»
- **B:** admin-1: grensen må vedtas — «systemets utdata kan aldri endre en frist, en status eller en levering uten en menneskelig handling». tools-1: åtte roller bør bli tre tjenester og én inngang. learning-1: LLM er feil verktøy for rangering, scoring og vekting. trading-1: `approvals` + data-policy-porten finnes alt, ikke bygg en ny
- **Belegg:** b — fire roller konvergerer uavhengig, med kode som belegg (`bid_no_bid` alltid null, `decisionGuard.ts:5-21`, 409 i `checklist.ts:272-299`, AUC 0,55-0,58). Ingen har lagt fram belegg for at flere autonome agenter gir bedre dekning — tools-1 viser tvert imot at 8 executors kjørte i 6 døgn uten at verdict-veien behandlet én sak.
- **Avgjøres av:** operatoren

### Er «OK kjør»-gaten reell

- **A:** trading-1: direkte push til main er TILLATT (`guard-main.yml:3-6`, ADR-0012-tillegget), branch protection er Pro-gated, auto-merge-boten krever en hardkodet strengliste — `migrasjonssnapshot` svarte rødt på PR #154 og boten merget likevel; boten merger også PR-er som ligger bak main uten ny CI
- **B:** infra-1, tools-1, paal-1 og programplanen: lister upushede grener som venter «OK kjør» og behandler gaten som effektiv kontroll
- **Belegg:** a — trading-1 har fil:linje, et navngitt PR-nummer og repoets egen innrømmelse i `auto-merge.yml:120-123`. De andre antar en port som er rådgivende.
- **Avgjøres av:** operatoren

### Sol eller IT som første bud

- **A:** ADR-0015 (ACCEPTED, referert av paal-1): Solarconsulting AS er budgiver, fem referanser alle innen sol, «første bud bør derfor være innen sol»
- **B:** Måledata (paal-1 + learning-1): 0 sol-relevante av 1653 kunngjøringer på 12 dager (PR #142); alle 30 ja ligger i IT; `solenergi` 0 ja / 1 nei
- **Belegg:** b — en ACCEPTED ADR uten marked slår ikke 1653 målte kunngjøringer. Men ADR-en bærer referansene og dermed vinnsjansen, så dette er ikke et rent datavalg.
- **Avgjøres av:** operatoren

## Blindsoner — det ingen av de sju tok opp

- Ingen priset sin egen plan mot de andres. Summen av «mitt forslag er førsteprioritet» er ~25-40 utviklerdager (porter 3 + lesemodell 3-4 + ny flate 5-8 + dokumentpipe 4-6 + rangering 6-9 + CV/retention/kildeklasse 7-8 + tenant 3-4 + flate-konsolidering 3), i et selskap der paal-1 oppgir at tre utviklere allerede er lovet bort til tre andre produkter. Ingen foreslo en kapasitetsgrense, en rekkefølge på tvers av lanes, eller hva som IKKE gjøres. Programmet står og faller på nettopp det.

- Frist 19.10 — seks dager — på tre-scopes-beslutningen. paal-1 nevner den som selskapets største åpne beslutning og konstaterer at den «ikke ligger på rådets bord». Ingen av de sju la planen sin rundt den; hver eneste anbefaling er 3-9 dager og lander etter fristen. learning-1 leverte ja-per-kategori-tallene som beslutningen trenger, men ingen koblet dem til et forslag operatøren kan vedta innen seks dager.

- Ingen observerte en bruker. Null av sju rapporter inneholder én observasjon av operatøren som faktisk bruker produktet — ingen økt fulgt, ingen oppgave tidtatt (utover `duration_ms` i basen), ingen samtale. Problemstilling A («radikalt bedre brukeropplevelse») er dermed ubelagt på BEGGE sider: vi vet ikke hva som er tungt, bare hva som er stygt i koden. UX-rollen er den eneste som ikke sitter i en pane, og den er ikke blant disse sju.

- De 105 beslutningene er én annotør, to arbeidsøkter, uten kvalitetskontroll. learning-1 melder selv at 72 av 105 ble tatt 11.10 og 24 den 12.10, og at random K-fold lekker øktkontekst. Men ingen — heller ikke learning-1 — spurte om etikettene er GYLDIGE: ingen andre-rater, ingen enighetsmål, ingen definisjon av «riktig» beslutning. Hele læringsplanen, scope-filteret og 19.10-beslutningen hviler på én persons udokumenterte dømmekraft i to kvelder.

- Ingen skrev én inntektslinje. Problemstilling E fikk en kostnadsmodell (infra-1) og en konkurrentprisliste (paal-1), men ingen regnet break-even: hvor mange vunne kontrakter til hvilken margin betaler for 95 000 linjer kode. paal-1 ber operatøren om dagsrate og dekningsbidrag — to tall ingen i rådet kan gjette — og uten dem er både «under 150 kr/kunde/mnd» og «internt verktøy lønner seg» udokumenterte.

- Ingen definerte hva som skjer når bølge 1 regresserer prod. Produksjonen brukes LIVE til å vurdere anbud med frist 19.10 (programplanens eget premiss). trading-1 er nærmest med ruteflagg og rollback, men ingen skrev et abortkriterium, et fryse-vindu, hvem som kan stanse en bølge, eller hva kostnaden er ved å miste ett reelt anbud i et deployvindu. infra-1 målte at prod gikk HTTP 000 fem ganger på én dag; ingen koblet det til risikoen i å bygge oppå den samtidig.

- Én modellleverandør, ingen fallback, og kvoten har alt vært tom. learning-1 melder at Anthropic-kreditten var tom 11.10 og at LLM-uttrekk da «feiler stille». infra-1 nevner `LLM_PROVIDER=openai-compatible` som forhandlingsposisjon, ikke som beredskap. Ingen behandlet leverandøravhengighet som programrisiko, og ingen spesifiserte hva produktet gjør — ikke hva det koster, men hva det GJØR — når nøkkelen er død midt i en anbudsfrist.

- Maskineriet som skal utføre programmet er selv umålt. tools-1 viser at firmaets kostledger aldri er opprettet mens 8 executors kjørte i 6 døgn, at verdict-veien aldri har behandlet én sak, at 5 av 5 MCP-er feilet tilkobling, og at `aslisten-crm-backup.service` står failed uten at noen varsling fanget det. Kombinert med trading-1s funn om åpen main-push og rådgivende CI: bølge 1 skal kjøres av agenter gjennom en port som ikke holder, og ingen av de sju behandlet det som en programrisiko — hver filte det som sin egen lane.

## Operatør-gater reist i runde 1

- **Databehandleravtale + EU/EØS-region med Anthropic, nedskrevet i en ADR (inkl. strengeste zero-retention/no-training på kontonivå)** — blokkerer Første eksterne kunde. Blokkerer salg, ikke bygging. Operatørbeslutningen 08.10 dekker én kunde som er oss selv. (reist av infra-1 + admin-1)
- **Datapolicy-standard: skal defaultModelApiAllowed settes false med eksplisitt allowlist, og fail-closed for 'personal' når policyen ikke kan leses?** — blokkerer Kunde nr. 2. Kodeendringen er liten — policyen er operatørens. Anbefalt ja av både infra-1 og admin-1. (reist av infra-1 + admin-1)
- **Tre-scopes-beslutningen, frist 2026-10-19 (seks dager) — og sol vs. IT (ADR-0015 sier sol først; 0 av 1653 kunngjøringer var sol)** — blokkerer Største åpne beslutning i selskapet; lå ikke på rådets bord. Ja-per-kategori er nå målt: fagsystem 13/11, utvikling-ki 8/7, undersokelser 2/1, solenergi 0/1, utenfor-scope 4/48. (reist av paal-1 (grunnlaget levert av learning-1))
- **Juristgjennomgang: alle 59 kommentarrader (0/59 verifiedBy), hele legal/, procurement/qualification/, regelgrunnlaget for vesentlighet, og hjemmel for fristforlengelse ved helg/helligdag** — blokkerer Ingenting i det juridiske domenet kan merkes FACT. lowersSeverity er i praksis aldri aktiv før dette. Største gaten i admin-1s domene. (reist av admin-1)
- **Vei A/B for kjøpersiden + juristvurdering av habilitet (by selv samtidig som man selger til oppdragsgiver) og av dokumenthenting (Mercell MTS §10)** — blokkerer All kommersialisering mot kjøpersiden. paal-1s innstilling: stryk begge. (reist av paal-1)
- **Dagsrate og dekningsbidrag — to tall** — blokkerer Break-even-vinnsjanse på kortet. Ingen kan gjette dem. (reist av paal-1)
- **Postgres-backup + testet restore for anbud (litestream dekker bare lokale SQLite-baser; ingen backup-timer finnes)** — blokkerer Koster penger. Åpen siden README.md:190 og ADR-0014:77-80. (reist av infra-1)
- **Passordrotasjon: bytt admin-passord i /admin og slett SEED_ADMIN_* fra Railway-env; per-IP rate limit på users/login (i dag kun 10 forsøk / 2 min låsing per konto)** — blokkerer Kunde nr. 1, ikke strategivalget. Admin er eneste rolle som kan opprette brukere og endre datapolicyen. (reist av infra-1)
- **Direkte push til main (tillatt per ADR-0012-tillegget) + GitHub Pro eller offentlig repo for ekte branch protection** — blokkerer Alle porter i fase 0 er valgfrie så lenge dette står åpent. Bare operatøren kan stenge det. (reist av trading-1)
- **Nattlig read-only eksport av tender-decisions til versjonert eval-artefakt (export:triage mot prod på kadens) + DB-rute for calibration-backtest.ts** — blokkerer Alle etterprøvbare kvalitetstall. Uten dette er hvert tall et engangsutsagn — jf. 8/30 vs 4/30 og 97 vs 105. (reist av learning-1)
- **pgvector på Railway-Postgres (prod har kun plpgsql; search_vector er tsvector)** — blokkerer Semantisk henting (issue 019). Ukjent om Railway tilbyr det. IKKE et sprintmål før svaret finnes — og RRF-hybrid uten vektorer måler alt recall@8 0,930. (reist av learning-1 (+ tools-1: embeddings.ts:17 returnerer null))
- **Anthropic-kreditt tom + Google-token invalid_grant (meldt 11.10)** — blokkerer LLM-ekstraksjon og workspace-sync feiler STILLE så lenge de står. Operatørens egen beskjed: nye nøkler fikses senere — da må alt som avhenger av modellkall merkes som ikke-verifisert i mellomtiden. (reist av learning-1)
- **DOFFIN_API_KEY — uten den kjører vi keyless webclient med 1000-treffs-tak (api.doffin.no/public/v2 gir 401)** — blokkerer Full dekning i innhentingen. Er nøkkel søkt/tilgjengelig? (reist av data-1 + paal-1)
- **Myhre: skriftlig tillatelse/lisens før re-crawl (robots Allow:/ men redistribution_rights RED, ingen committet crawler-kode) + oppdatering av lovdata.json-registerraden + registrering av foa.no/anskaffelser.no som kilder før crawl** — blokkerer Ikke dagens bruk (≤25 ord, fulltekst utenfor git, ikke vist til kunde, URL-sperret i skjema). Blir blokkerende ved kundevisning, lagring i repo/DB eller fler-tenant. Registeret er det en revisor leser. (reist av admin-1 + data-1)
- **Lagring + OCR-valg for dokument-pipen: disk/blob-kvote, lokal tesseract vs. betalt API** — blokkerer +2 dager på dokument-pipen; skannede PDF-er gir null uten det. (reist av data-1)
- **Er INVESTIGATE en tredje klasse eller en utsatt ja? Og skal leverte tilbud registreres med utfall?** — blokkerer Førstnevnte endrer hver metrikk i anbefalingen (i dag kollapses STRONG_BID og INVESTIGATE til samme 'approve'). Sistnevnte er eneste vei til læring fra faktiske utfall — bid_drafts = 1 i dag. (reist av learning-1 (+ paal-1: utfallsløkken, inkl. «for dyrt å by»))
- **Mål køen i prod: SQL over tenders/documents/awards/opportunities/tender_decisions (railway er blokkert av firm-exec-guard for headless agenter)** — blokkerer Alle volum-/kø-tall fra roller uten DB-tilgang er ANTAKELSE. De tre siste spørringene avgjør om utfallsmodellen er moden. (reist av data-1 (learning-1 fikk tilgang via railway ssh og leverte sine tall målt))
- **Push av ventende grener: infra-1/vakt-i-repo (f47cd4d, erstatter foreldet 367c83c), tools-1/doctor-guard-aware, tools-1/f2-gates, tools-1/telegram-mcp-pilot, paal-1 feat/jobbko-saksloft + fix/prod-blokkere; commit av utracket omnigent/ (220 K)** — blokkerer «OK kjør»-gaten. omnigent/ er «én flate»-definisjonen og bør i git før noen bygger på den. (reist av infra-1 + tools-1 + paal-1)
- **Personvernerklæringen på nettstedet (noindex; mangler behandlingsansvarlig, behandlingsgrunnlag, lagringstid) — JUS-01** — blokkerer Lansering. Lagringstiden kan ikke skrives før retention-dekningen er bestemt — de to henger sammen. (reist av admin-1)
- **Vercel-team/VERCEL_TOKEN-medlemskap, CRM_URL bakt inn ved bygg, og Node-versjon låst i Vercel-UI** — blokkerer deploy.yml gjør rm -rf .git for å omgå at commit-forfatteren ikke er teammedlem; CI-bygget baker inn localhost:3000, så grønt dashboard-bygg beviser ingenting om prod-rewriten. (reist av trading-1)
- **Eierskap for rapportstier i firm-dispatch: samme jobb ble utført av både interaktiv pane og headless executor mot samme fil, tredje gang på tre dager, og ferdige leveranser ble overskrevet** — blokkerer Rådets egen leveransekvalitet (infra-1 og admin-1 mistet begge en versjon i dag). Forslag: executoren skriver til <rolle>-headless.md, eller dispatchen navngir eier. (reist av infra-1 (pane) + admin-1)
- **Tre åpne drift-/governance-poster: aslisten-crm-backup.service står failed uten at noen varsling fanget det; MCP-sanering krever interaktiv sesjon (5/5 feilet, github-MCP borte fra konfig); HeyGen-opprydding (lisens mangler i 3 av 4, slett duplikater, stram allowed-tools, registrer i CAPABILITY-REGISTRY)** — blokkerer Ikke Veldora-strategien, men ingen andre meldte dem i dag. HeyGen har ingen plass i Veldora — innkjøpere i offentlig sektor leser dokumenter, de kjøper ikke på avatarvideo. (reist av tools-1)

## STRYK — påstander som ikke tåler vekten sin

Disse skal ikke brukes som premiss i runde 2 uten ny måling.

- ~~«8 av 30 ja feilfiltrert (27 %)» — brukes som akseptansekriterium for om scope-filteret kan slås på~~ [paal-1 (via issue 050 / PR #144)] — motsagt av annen rapport med bedre belegg: learning-1 målte 4/30 (13,3 %) direkte i prod og forklarte avviket (`summary` null på 29/105 rader i eksportsettet)
- ~~«97 beslutninger» som datagrunnlag~~ [paal-1 og trading-1] — motsagt av prod-måling: 105 beslutninger (NO_BID 69, STRONG_BID 24, BID 6, INVESTIGATE 6). trading-1 bygger i tillegg et helt motargument på 97-tallet
- ~~«`kommentar-regler.json` er 50 rader»~~ [data-1] — motsagt av `jq length` = 59 (admin-1), som også eksplisitt korrigerer ordrens «18». Alle planer som priser juristgjennomgangen bygger på feil antall
- ~~«Alle tall om kø/volum i dette rådet fra andre roller uten min SQL-kjøring er ANTAKELSE»~~ [data-1] — falsifisert samme dag: learning-1 kjørte read-only prod-spørringer via `railway ssh` og leverte tallene. Blanketterklæringen diskvalifiserer gyldige målinger
- ~~Kostnadsmodellen: «MVP ~150-260 USD/mnd», «~0,50 USD per anbud», «screening på Haiku ⇒ 1-2 USD/mnd»~~ [infra-1] — forutsetter en modellruting som ikke er aktiv (`TASK_MODEL_DEFAULTS` tom, ingen prompt-caching per `models.ts:118`), og dagens side av sammenligningen er usporet (`vercel`/`railway` begge blokkert). Selvmerket ANTAKELSE, men presentert i tabell
- ~~«Hosting er ikke problemet — LLM-kost per anbud er hele enhetsøkonomien»~~ [infra-1] — sirkulær: konklusjonen følger av infra-1s egen umålte kostmodell. Begge ledd (~40-60 USD hosting, ~150-200 USD LLM) er anslag fra samme kilde
- ~~«Tenant-akse: 3 dager»~~ [infra-1] — motsagt av admin-1 (databehandlerplikter, DPA, sletting på instruks, retention på 4 av 58 collections) og paal-1 (40+ dager med auth/fakturering/support). Dekker bare skjema og access-regler, og priser ikke negativ test per collection som infra-1 selv kaller kritisk krav
- ~~«Realistisk SMB-ARPU 10 000-35 000 kr/år» → derav kravet «under 150 kr per kunde per måned»~~ [paal-1] — ingen kilde til ARPU-tallet; det er utledet av konkurrenters listepriser uten én kundesamtale. Kravet er avledet av et avledet tall og brukes som bindende arkitekturkrav mot infra-1
- ~~«Markedet er overfylt i den billige enden» + «Mercells datamoat kopieres ikke på seks måneder»~~ [paal-1] — ett websøk 13.10, med eget forbehold om at Mercell-tallene er fra en kampanjeside og at Hyyr/Bidflow/Tendium-prising ikke er offentlig. Ingen kundeintervju, ingen vunn/tap-data
- ~~«Hyyr: ~0 til 15 MNOK ARR på fire måneder, vant 9 av 9 konkurranser, ~200 oppdragsgivere»~~ [paal-1] — én Shifter-artikkel med selskapsrapporterte tall, brukt som hovedbegrunnelse for at kjøpersidevinduet er lukket
- ~~«Presisjon 51 % mot basisrate 28,6 %, lift 1,78×, ~2,8 timer spart operatørtid per 105 saker»~~ [learning-1] — in-sample: målt på de samme 105 radene filteret er utviklet og valgt på, uten holdout. Tidsgevinsten antar i tillegg at hver av de 48 kuttede nei-ene ville kostet full snittid (207 s)
- ~~«Rangering = regularisert logistisk regresjon på de 105, 5 trekk, tids-splitt»~~ [learning-1] — motsagt av learning-1s egen terskeltabell i samme rapport: regularisert logistisk / parvis rangering blir forsvarlig «~300 etiketter (~85 ja)». Vi har 30 ja. Rapporten anbefaler det den selv sier er for tidlig
- ~~«Praktisk: TED gir ~duplikater av Doffin, ikke EU-marked»~~ [data-1] — ingen målt overlapp mellom kildene. Belegget er kun at TED-queryen filtrerer på `organisation-country-buyer=NOR`; graden av duplisering er ikke tellet
- ~~«Statsregnskapet (åpent API) — beste proxy for kontraktsverdi»~~ [data-1] — ingen URL, ingen verifisering, og data-1 oppgir selv «ingen nettkall gjort» i §7. Presentert i en liste over «gratis + etterprøvbare kilder»
- ~~«Jeg har akkurat sett nexus bruke 93 etiketter til å påstå en edge som ikke fantes» — brukt for å avvise læring fra beslutningsloggen~~ [trading-1] — analogi fra et annet domene (trading), ikke belegg om Veldora. Og kravet trading-1 stiller (Brier + kalibreringskurve) er allerede innfridd av learning-1 med AUC + konfidensintervall
