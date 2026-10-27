# Veldora strategiråd — nedbrytning (WBS)

Kilde: 12 kartleggings-/research-/designagenter + syntese på max effort, 2026-10-13. 14 agenter, 1,37 M subagent-tokens.
**NB:** denne agenten leste repoet, ikke prod. Der tallene spriker, gjelder learning-1 sin prod-måling (105 beslutninger, 4/30 tapte ja, verdi 50,9 %, 758 køkvalifiserte av 907) — ikke tallene referert fra issues 050/051 under.

## Tilstandsbilde

Veldora-rad, gren strategy/ai-plattform-rad, 0 upushede, HEAD 6cc89c2 (#156). PR-fronten er FORBI #156 — #89-#106 beskriver ikke naatilstanden, og issues 023-030 samt 033-046 er LEVERT (FACT).
Anbud har to deploy-maal: crm+worker paa Railway (Docker, migrate-or-die) og dashboard+website paa Vercel via deploy.yml (IMPL).
CRM: 58 collections, 11 globals, 131 haandskrevne endepunkter i 29 moduler, 52 jobbtasks, 34 cron (Europe/Oslo, egen croner i worker.ts), 52 migreringer (FACT).
Dashboard: 46 page.tsx, 24 nav-lenker i 5 grupper + Innstillinger = 25 nav-maal, MORE_LINKS = 25. VERIFISERT av meg i src/lib/nav.ts — korrigerer funnet som paastod 27 href og tom MORE_LINKS (FACT).
Rangeringen er 100 % deterministisk: scoreFit, matchScopeCategory, computePriority (prio-2), winProbability (wp-2). Null LLM-kall; scope.ts sier «No LLM calls — BINDENDE per oppdrag 2026-10-12». Det harde kravet er ikke brutt noe sted i dag (IMPL).
97 menneskelige beslutninger i prod (30 ja / 62 nei), 725 opportunities, 1653 kunngjoeringer per 12 dager. Alle tall er REFERERT fra issues 050/051 — ingen kjoering er lagret i repoet, saa de er ikke reproduserbare (FACT).
CPV diskriminerer maalt ikke (CPV 72: 26 ja/43 nei; 48: 21/37; 79: 6/15), men cpvMax gir opptil 50 av 100 fit-poeng. Scope-filteret kutter 69 % av nei og taper 8 av 30 ja (27 %) — issue 050s akseptkriterium er brutt (FACT).
0 registrerte utfall. VERIFISERT: ingen outcomes-collection finnes; utfall er klemt inn i opportunities.status sammen med pipeline-steg, og predictions.outcome kjenner bare won|lost. Ingen taps-aarsak-enum (FACT).
Feedback er 100 % eksplisitt — 0 treff paa viewed/opened/impression/dwell. pref-1 er lag-aggregert («aggregated, never per person»), gatet paa n>=30, flytter maks ±10 prio-poeng (IMPL).
LLM: én klient, 25 oppgavetyper, ~26 kallsteder. VERIFISERT: TASK_MODEL_DEFAULTS = {} (alt paa samme modell) og 0 treff paa cache_control (ingen prompt-caching, ingen batch). Kostnad logges per kall med prisversjon — ingen har summert den (FACT).
Datapolicy-gaten kalles foer hvert kall, men er fail-open: VERIFISERT at loadDataPolicy returnerer PERMISSIVE_POLICY baade ved !payload og i catch, og defaultModelApiAllowed er true. 2 av 8 datatyper er ikke mappet til noen oppgave (FACT).
Dokumenter: documentsUrl lagres, men VERIFISERT 0 jobber roerer det — ingenting lastes ned. documents fylles kun ved manuell opplasting. Ingen OCR, ingen xlsx-parser. Dette hullet blokkerer hele LLM-kjeden nedstroems (FACT).
428 av 546 ubesluttede manglet estimatedValue 11.10. Tildelt beloep finnes bare fra Doffin. Fornyelsesradaren baeres av tre konstanter merket «ASSUMPTION — tune» (48 + 24 + 6 mnd) (FACT).
TED v3 er reell, keyless, Zod-validert, 30 verifiserte eForms-felt, i timescron — 9959 norske kunngjoeringer YTD. Doffin-API-et krever derimot abonnementsnoekkel (401 uten), og 41 % av kunngjoeringene ligger under EOeS-terskel og finnes KUN der (FACT).
CI: anbud.yml har 3 jobber (crm, migrasjonssnapshot, dashboard), ingen Postgres, ingen nettleser. VERIFISERT 0 treff paa «smoke» i workflows — de 29 ferdige smoke-skriptene kjoeres aldri. Groenn CI betyr tsc + unit + build (FACT).
VERIFISERT: auto-merge har REQUIRED=(schemas website) som hardkodet bash-array, utvidet for anbud-paths. Fail-open mot ukjente sjekker — migrasjonssnapshot sto roed og ble merget i ~en maaned (fikset i #155) (FACT).
deploy.yml slutter paa `vercel deploy --prod`: ingen readyState-sjekk, ingen post-deploy GET, ingen rollback. Workeren mangler healthcheck, og migrate-or-die ligger bare i next-grenen av Dockerfile (FACT).
Triage-kortet har ALLEREDE Suggestion + TriageBrief + TriageFremgang (brief.recommendation, lean, advisory, faktaverifisering per felt) + gates + fit-aarsaker. VERIFISERT i TriageCard.tsx:171-192 — dette korrigerer funnet som paastod at grunnlaget ligger i en annen rute. Problemet er 9 likestilte seksjoner, ikke manglende forslag (IMPL).
Beslutning: 4 utfall, 1-tasts hurtigtast, append-only tender-decisions, menneske-only (stampDecision kaster 403). Men MIN_JUSTIFICATION = 10 tegn fritekst er obligatorisk foer lagring, saa veien er 4 handlinger + tekst (IMPL).
Godkjenningskoe: én approvals-collection, 6 koetyper, 6 lanes, agent foreslaar med frosset proposal / menneske avgjoer, `deliver` bevisst utelatt. Men modell-output fra ~20 oppgaver (brief, roedt lag, kravuttrekk, CV, juridisk svar) skrives rett til DB uten godkjenn-steg (IMPL).
Jus: DOC_REF-whitelist (kun lov/forskrift/kofa), utgaaende lenker laast til lovdata.no og KOFA. Myhre = 59 regler med ASSUMPTION|FACT|REJECTED, redistribution RED (ingen artikkeltekst lagres), crawler utenfor git, siste fetch 2026-10-09. Statusen finnes i datamodellen men ikke i UI — proveniens har bare 2 nivaaer (ai/you) (IMPL).
17 ADR-er, 12 ACCEPTED. Kritiske: ADR-0017 (/mote hovedflate, operator direction 2026-10-11, bygget), ADR-0014 (wp fra dag én), ADR-0011 (bid_no_bid alltid null, KODEHAANDHEVET), ADR-0012 (ingen branch protection). 3 proposals staar PROPOSED i 5-8 dager uten ADR (FACT).
Markedet: varsling er commodity (Varsly 99 kr/mnd mot Mercell ~1242, gratis aapent datagrunnlag), og AI er paritetsfeature hos fire aktoerer. Hullet ingen dekker: kvalifikasjon mot egen kapasitet + utfallshistorikk som treningssignal (FACT).
Operatoersmerten: 16 paner = firm-wt-split (8) + codex-wt-split (8). VERIFISERT at Omnigent firm-harnessen FINNES i command-center/omnigent/firm — orchestrator-1 + 7 lanes + 10 spesialister + codex, watch/takeover i UI, push policy-gatet. Én styrt flate er konfigurert, ikke groent felt (IMPL).

## Må gjøres først

### [S] auto-merge want_checks avledes fra workflow-jobbene, ikke fra en hardkodet bash-array

**Eier:** infra-1

REQUIRED=(schemas website) er en hardkodet liste i .github/workflows/auto-merge.yml:62, utvidet til crm/dashboard/migrasjonssnapshot bare naar PR-ens filer matcher en regex (:124-127). Boten er fail-open mot sjekker den ikke kjenner navnet paa — migrasjonssnapshot sto roed og ble merget i ~en maaned (fikset i #155, 03e45c1). Saa lenge porten er en array noen maa huske aa oppdatere, betyr «merget» ikke «verifisert», og hver ny port vi bygger under arver samme hull.

### [M] Smoke-CI-jobb med kastbar Postgres: de 29 eksisterende smoke-skriptene inn i want_checks

**Eier:** infra-1

Ingen CI-jobb roerer noensinne en database (anbud.yml:3 «Unit tests only - no database»), og 0 treff paa «smoke» i .github/workflows. 29 ferdige smoke-*.ts finnes, er fail-closed mot remote DB og exiter non-zero. Dette er feilklassen som traff prod to ganger paa en maaned (#135 verdi-backfill og #154/#155 scope-backfill: enum manglet i basen, CI groenn, prod feil). Uten denne porten er alt vi bygger i boelge 2 og 3 ubeskyttet mot samme feil.

### [M] Datapolicy fail-closed for personal/internal + map kundedokument og energidata inn i TASK_DATA_TYPES

**Eier:** tools-1

Verifisert i src/lib/datapolicy.ts: loadDataPolicy returnerer PERMISSIVE_POLICY baade naar payload er null (:95) og i catch (:106), og defaultModelApiAllowed er true (:40). DB nede eller gammelt skjema = alt sendes til modell-API med én console.warn. I tillegg er 2 av 8 datatyper (kundedokument, energidata) ikke knyttet til noen LLM-oppgave, saa en admin som blokkerer dem oppnaar ingenting. Dette er en aapen sikkerhetsgate, og det er salgskravet mot offentlige kunder.

### [S] Nullmaaling lagret i repoet: dokumentdekning + triage-eksport som fixtures

**Eier:** data-1

Alle tall vi styrer etter er referert, ikke reproduserbare: 97 beslutninger, 725 opportunities, 8-av-30 tapte ja, 428/546 uten estimatedValue. Issue 050 og 051 sier selv at «kjoeringen/spoerringen er ikke lagret». crm/scripts/eval-scope-categories.ts krever en JSON-eksport som ikke finnes i repoet, og crm/scripts/dokumentdekning.ts har ingen lagret kjoering. Uten fixtures kan ingen regelendring verifiseres, og V-12/V-18/V-19 er umulige aa gate.

### [S] Post-deploy helse-port i deploy.yml

**Eier:** infra-1

Siste steg i deploy.yml (:95-110) er selve `npx vercel deploy --prod`. Ingen sjekk av readyState, ingen GET mot prod-URL, ingen rollback. En groenn deploy-jobb beviser at vercel-CLI returnerte 0 — ikke at siden lever. Produksjonen brukes LIVE til aa vurdere anbud i dag, saa en stille doed deploy er den dyreste feilen i riggen.

### [S] Worker-healthcheck + migrate-or-die ogsaa i worker-grenen av Dockerfile

**Eier:** infra-1

Dockerfile:42-45: naar ANBUD_ROLE=worker exec'es workeren FOER migrate-or-die, og .railway/railway.ts gir workeren ingen healthcheck. Skjema-drift feller derfor bare crm-tjenesten. Workeren kan kjoere 52 tasks og 34 cron mot feil skjema uten at plattformen oppdager det — og den eier all innhenting og scoring.

## Parkeres — med begrunnelse

- Azure-migrering av plattformen. Operatoersvaret «Bygge paa Azure» (2026-10-12) har INGEN ADR, bryter ADR-0014 (Railway/Postgres som system-of-record) og ADR-0006/0008 (Vercel), og Norway East har null SKU for baade Document Intelligence og Speech. Proposalen advarer ordrett mot at «noen starter en migrering». Park til ADR-0020 avgrenser Azure til kundeproduktene.

- Tale og voice. 0 treff paa whisper/tts/speech/elevenlabs/deepgram/twilio i hele repoet — alle «tale»-treff er norske ord (samtale, rammeavtale, omtale). Dette er groent felt, ikke en utvidelse, og ingenting i funnene etterspoer det.

- LLM som rangeringsmotor eller reranker i boelge 1-2. Dagens arkitektur er bevisst deterministisk, scope.ts sier eksplisitt «No LLM calls — BINDENDE per oppdrag 2026-10-12», og det absolutte kravet er ikke brutt noe sted i dag. Bevar grensen; V-35 ligger i boelge 3 og bare bak eksplisitt operatoersvar.

- Learning-to-rank (LambdaMART/XGBoost) og contextual bandits. 92 brukbare labels i én gruppe, ingen graderte relevansnivaaer, 0 registrerte utfall. Burges anbefaler «a few thousand queries»; TS-regret krever T i tusener. En tree-ranker paa 92 rader laerer stoey. Forsvarlig tidligst ved ~500-1000 merkede beslutninger eller 150+ utfall.

- pgvector og embeddings (issue 019). Recall er ikke BEVIST aa vaere problemet — 725 saker er et bittelite korpus, og Postgres fulltekst + sporene kan ha recall naer 1. Maal recall-av-ja foerst; kjoep vektorer bare under ~0,95. Embedding er dessuten ikke kostnadsdriveren (100k biter koster 1-9 USD én gang, eller null paa lokal bge-m3).

- Nye dashboards, sider og faner. 46 ruter, 25 nav-maal, 2 badge-signaler. Neste side gjoer problemet maalbart verre. Alt nytt arbeid gaar INN i eksisterende flater.

- De fem foreslaatte agentrollene (Scout/Qualification/Evidence/Bid Advisor/Compliance). Alle fem finnes funksjonelt alt — Scout = ingest + score + triage, Qualification = qualify/assess-requirements + engine, Evidence = Evidence-collection + evidencePolicy + Brreg, Bid Advisor = brief + challenge + red-team + draft-bid, Compliance = feilsjekk/rules + legal/ask + citationJudge. Aa bygge dem paa nytt duplikerer ~26 kallsteder. Det som mangler er navngivning, ikke funksjonalitet.

- Full redesign, Tailwind eller komponentbibliotek. tokens.css (230 l) + 40 CSS-moduler er konsistente, og pakken har i dag 0 UI-avhengigheter. Byttet koster hele frontenden uten aa roere det operatoeren klager paa (antall flater og faner).

- Playwright/e2e som FOERSTE kvalitetstiltak. Dyrest og tregest, og dekker ikke de tre faktiske prod-feilene (backfill-enum i #135/#154, scope-matching i #156). Hoerer hjemme etter smoke-porten, mot mobil-layout-klassen i #152/#153.

- Egen KOFA-indeks som produktfunksjon. FOA har alt bygget den (sitemap-kofa.xml + sitemap-dommer.xml, oppdatert 2026-10-13) fra samme offentlige raakilde, med 25 aars forsprang. Dette er et differensieringsspoersmaal, ikke et datainntaksspoersmaal.

- Keyed Doffin v2 som hovedinnsats i boelge 1. Det forbedrer metadata vi stort sett har, og koden sier selv at det er UKJENT om keyed API godtar type-filteret. Dokumenthullet (0 jobber laster ned noe) er stoerre. V-27 ligger derfor i boelge 2, etter V-14.

- Per-bruker preferanselaering. learn-preferences er eksplisitt «aggregated, never per person». Per-bruker er inngangsdoera til filterbobla, har en personvern-/arbeidsrettsflanke (individuell beslutningsprofilering av egne ansatte), og n=97 er for lite selv for lag-profilen.

- Tre-scopes-beslutningen kjoert parallelt med arkitektur-ADR-ene. Fristen er 19.10 med 4 av 5 forutsetninger uloeste. Begge krever samme beslutningstaker. Kjoer eval-tallene (billigst, blokkerer en reell frist) foerst, arkitektur-ADR-ene foer ELLER eksplisitt etter — aldri samtidig.

- Branch protection via GitHub Pro / offentliggjoering av repoet. Hygiene, ikke svaret paa at merget ikke betyr verifisert: en manglende sjekk er fortsatt manglende. V-01 loeser den faktiske feilmodusen.

## Strategiske spenninger

### Hva ER hovedflaten. ADR-0017 er operator direction fra 2026-10-11, ACCEPTED, og /mote er bygget med tre ruter — men UX- og frontend-domenene anbefaler begge ÉN arbeidskoe som hovedflate. To flater kan ikke begge eie «hva skal jeg gjoere naa».

- **A:** UX + frontend-IA: bygg én arbeidsflate (Koe) som samler Triage, Til godkjenning, Innboks og Pipeline, og kutt nav fra 25 til 7. Begrunnelse: 46 ruter bak 25 nav-maal, 20 av 25 usynlige paa mobil, bare 2 med badge.
- **B:** Beslutnings-domenet: ADR-0017 er 2 dager gammel, merket operator direction, og operatoeren valgte konsolidering til /mote med synlig Trening/Live-toggle som virkemiddel mot nettopp denne flatebelastningen. En ny hovedflate er en omkamp paa en 48 timer gammel beslutning.
- **Avgjøres av:** operatoren

### Skal vinnsannsynlighet brukes i utvalget. To ACCEPTED ADR-er peker mot hverandre, og ML-domenet sier tallet ikke er etterrettelig i det hele tatt.

- **A:** ADR-0014 pkt 2: fitScore og winProbability beregnes fra dag én som ekte tall, lagret med modellversjon og per-faktor breakdown.
- **B:** ADR-0017 pkt 2: Live-filteret i fase 1 er DETERMINISTISK paa harde gates + weMeet, eksplisitt IKKE paa vinnsannsynlighet. Og recsys: wp-2 har haandsatte vekter og 0 observerte utfall — en tallfestet sannsynlighet uten kalibreringsdata er verre enn ingen, fordi den ser etterproevbar ut.
- **Avgjøres av:** operatoren

### Datapolicy fail-open mot fail-closed. Sikkerhets- og salgsargumentet trekker motsatt vei av en bevisst operatoerbeslutning fra fem dager siden.

- **A:** LLM-/agent-domenet: gjoer gaten fail-closed for personal og internal. Uleselig global, DB nede eller payload=null gir i dag PERMISSIVE og én console.warn — alt sendes til modell-API. Dette er salgskravet mot offentlige kunder.
- **B:** PERMISSIVE_POLICY er dokumentert som operatoervalg 2026-10-08 («alt tillatt, ingenting auto-slettet»). Fail-closed kan stoppe 52 tasks og 34 cron ved DB-troebbel — i en produksjon som brukes LIVE til aa vurdere anbud i dag.
- **Avgjøres av:** operatoren

### Juster vektene naa, eller frys dem til evalueringen finnes. To ML-leveranser anbefaler motsatt foerste trekk paa samme datasett.

- **A:** triage-rank: senk CPV-taket i scoreFit fra 50 til ~20 poeng naa og flytt vekten til tekst/scope-bevis — CPV er maalt som ikke-diskriminerende (72: 26 ja/43 nei, 48: 21/37, 79: 6/15).
- **B:** recsys: FRYS vektene. Med 30 ja og 62 nei er Hanley-McNeil-SE ca. 0,057, saa 95 %-KI paa AUC er ca. ±0,11 — enhver forbedring under ~0,10 er ikke maalbar. Dagens eval er dessuten in-sample paa samme data profilen er bygget fra; litteraturen maaler 21,7-73,4 % inflasjon fra den lekkasjen.
- **Avgjøres av:** raadet

### Begrunnelsesgaten: rask feedback mot treningsgrunnlag. UX vil fjerne friksjonen, laeringslaget lever av den.

- **A:** UX: fjern MIN_JUSTIFICATION fra innsendingen. Maks 1 obligatorisk interaksjon per sak; begrunnelse blir en valgfri linje etter valget. I dag er veien 4 handlinger pluss fritekst paa minst 10 tegn.
- **B:** Backend/laering: MIN_JUSTIFICATION tvinger tekst paa alt annet enn UNDECIDED, og aarsakskoder pluss begrunnelse er hele treningsgrunnlaget til pref-1 paa et korpus av 97 beslutninger. Billigere feedback gir mer data men tynnere data.
- **Avgjøres av:** raadet

### Én blokkerende smoke-port mot bevisst fail-open leveringsvei. CI-domenet vil ha en hard port; ADR-0012 valgte det motsatte.

- **A:** CI/test: bygg én blokkerende smoke-jobb med Postgres og legg de 29 eksisterende skriptene i want_checks. Ingen CI-jobb roerer i dag en database, en nettleser eller prod-URL-en — «groenn» betyr tsc + unit + build.
- **B:** ADR-0012: ingen branch protection, direkte push til main tillatt, strict bevisst droppet. Porten er en hardkodet bash-array som er fail-open mot sjekker den ikke kjenner — migrasjonssnapshot sto roed og ble merget i ~en maaned. En ny port arver det hullet med mindre arrayen avledes.
- **Avgjøres av:** raadet

### Azure. Ett operatoersvar uten ADR staar mot tre ACCEPTED ADR-er og en regional SKU-mangel.

- **A:** FACT operatoersvar 2026-10-12: «Bygge paa Azure». Proposalen ANTAR at det gjelder kundeproduktene og skriver ordrett: «Skriv det inn i ADR-en, ellers starter noen en migrering.»
- **B:** Plattformen kjoerer Railway + Vercel per ADR-0014/0006/0008. Og Norway East har NULL SKU for baade Document Intelligence og Speech — OCR og tale paa Azure betyr West Europe, altsaa et datalokalitetsvedtak for anbudsdokumenter og lydopptak, ikke et prisvedtak.
- **Avgjøres av:** operatoren

### Hva kommersialiseres. Markedsanalysen peker paa kvalifikasjonslaget, men selskapets egen rolle er en strukturell ulempe der.

- **A:** Marked: ikke bygg varsling (priskomprimert mot 99 kr/mnd, gratis aapent datagrunnlag, AI er paritetsfeature hos fire aktoerer). Bygg kvalifikasjons- og utfallslaget — det eneste stedet ingen av de 10 aktoerene har noe etterproevbart.
- **B:** ADR-0015: Solarconsulting AS er selv budgiver. FOA og Hyyr har separate leverandoerprodukter og byr ikke selv. Habiliteten maa loeses FOER salg til andre leverandoerer, og distribusjon (Finndoff eier Byggmesterforbundet/NESO, Mercell har 16 000 leverandoerkunder) er en stoerre blokker enn produktet.
- **Avgjøres av:** operatoren

### Hard-filtre: triage-tid mot tapte ja. Begge sider er maalt, og de peker i motsatt retning.

- **A:** Hard-filtre og scope-kategorier kutter 69 % av nei-ene og er det som gjoer en koe paa 725 haandterbar. Deterministiske porter er dessuten det harde kravet for kritiske avgjoerelser.
- **B:** Samme filter taper 8 av 30 ja (27 %), og issue 050s eget akseptkriterium «naer null tapte ja» er dermed brutt med faktor 8. Og sortQueue rangerer binaere flagg (NO_FIT, duplikat, stoey) FOER score i et 200-raders vindu — formelt ikke filtrert, reelt usynlig. Et hardt filter skjulte alt et godkjent lisens-anbud 2026-10-12.
- **Avgjøres av:** operatoren

### Nav-kuttet: «én datafil» mot delte dyplenker. Frontend sier det er lavrisiko, dyplenke-virkeligheten sier noe annet.

- **A:** Frontend-IA: nav er allerede ren data (NAV_GROUPS/TAB_LINKS/MORE_LINKS) med testbare activeHref/tabState. En konsolidering fra 25 til 7 maal er en endring i ÉN fil.
- **B:** 21 filer leser ?fane, ICON_PATHS er koblet paa href-streng og gir <path d={undefined}> uten typefeil, og URL-ene er delt i Obsidian og Telegram. Det finnes ingen bruksstatistikk i repoet, saa vi vet at rutene eksisterer — ikke at de brukes. Nav-kuttet er det som kan oedelegge en arbeidsdag.
- **Avgjøres av:** operatoren

## Oppgaver

### Bølge 1 (13 oppgaver)

| id | tittel | lane | eier | str | avhenger av | leveranse |
|---|---|---|---|---|---|---|
| V-01 | want_checks avledet fra workflow-jobbene | plattform | infra-1 | S | — | auto-merge.yml leser jobbnavn fra .github/workflows/*.yml i stedet for REQUIRED=(schemas website). En PR som legger til en ny CI-jobb uten aa roere auto-merge kan ikke merges foer den jobben er groenn. Verifiseres med en test-PR som legger til en jobb som feiler med vilje: boten skal nekte aa merge. |
| V-02 | Smoke-CI-jobb med Postgres: 29 eksisterende skript inn i porten | plattform | infra-1 | M | V-01 | Ny jobb `smoke` i anbud.yml med services: postgres:17, som kjoerer payload migrate + de 29 smoke-*.ts mot en kastbar base, og staar i want_checks. Verifiseres ved aa reintrodusere #154-feilen (scope-backfill uten enum-verdi) paa en gren: jobben skal bli roed. |
| V-03 | Post-deploy helse-port i deploy.yml | plattform | infra-1 | S | — | deploy.yml avsluttes med GET mot /api/health og én prod-URL per matrise-prosjekt; ikke-2xx feller jobben og varsler. Verifiseres med en bevisst brukket build paa en gren. |
| V-04 | Worker-healthcheck og migrate-or-die i worker-grenen | plattform | infra-1 | S | — | Dockerfile kjoerer migrate-or-die ogsaa naar ANBUD_ROLE=worker, og .railway/railway.ts gir workeren en healthcheck. Verifiseres ved aa starte workeren mot en base med ventende migrering: den skal exite non-zero, ikke kjoere cron. |
| V-05 | Nullmaaling lagret som fixtures i repoet | data | data-1 | S | — | Anonymisert triage-eksport (97 beslutninger) og én dokumentdekning-kjoering (--json) sjekket inn som fixtures, med dato og hvordan de ble produsert. eval-scope-categories.ts kjoerer groent mot fixturen uten prod-innlogging. |
| V-06 | Datapolicy fail-closed for personal og internal | agent | tools-1 | M | — | loadDataPolicy skiller «ingen regler» fra «kunne ikke lese»: uleselig global blokkerer dataClass personal/internal og varsler, i stedet for aa tillate alt. kundedokument og energidata mappet inn i TASK_DATA_TYPES. Verifiseres med test som river DB-tilgangen og sjekker at kallet blokkeres med errorCode datapolicy. |
| V-07 | Triage-kortet komprimert: beslutning og forslag over folden | ux | tools-1 | M | — | TriageCard har beslutningsknappene, forslagslinja (Suggestion) og tre stikkord over folden; gates, sammendrag, TriageBrief, TriageFremgang, fit-aarsaker og beskrivelse kollapset bak «Hvorfor» og «Grunnlag». Verifiseres paa 390px: beslutning + forslag synlig uten scroll. |
| V-08 | Begrunnelsen flyttet fra innsendingsgate til valgfri etterspoersel | ux | tools-1 | S | V-07 | MIN_JUSTIFICATION kreves ikke lenger for aa lagre; etter valget vises én linje med aarsak-chips som kan hoppes over. Tvungen begrunnelse beholdes for STRONG_BID og NO_BID over en beloepsgrense. Verifiseres: beslutning lagret med 2 handlinger og uten fritekst. |
| V-09 | Triage-badgen blir direktelenke til neste uavklarte sak | ux | tools-1 | S | — | Badgen i layout lenker til /tenders/triage?id=<neste uavklarte> med beslutningsskjemaet aapent, i stedet for til koeens start. Verifiseres: fra badge-klikk til lagret beslutning i 2 handlinger. |
| V-10 | Prompt-caching av systemprompt og dokumentkontekst | agent | tools-1 | S | — | anthropicRequest() setter cache_control paa systemprompt og dokumentblokk. Verifiseres i llm-usage: cache-read-tokens over 0 og synkende costUsd for extract.requirements over samme dokument. |
| V-11 | TASK_MODEL_DEFAULTS satt for de billige oppgavene | agent | tools-1 | M | V-10 | extract.threshold, extract.message, generate.feilsjekk, generate.news og extract.answer rutes til haiku; eval kjoert foer og etter paa samme input med lagret resultat. Verifiseres: maalt kostnadsfall i llm-usage per oppgave uten kvalitetsfall i evalen. |
| V-12 | Eval-harness for rangering med tidsbasert splitt og konfidensintervall | rangering | learning-1 | M | V-05, V-01 | Nytt eval-skript som trener paa uke 1..k og tester paa k+1, rapporterer AUC med Hanley-McNeil-KI og precision@10 med Wilson-KI, kjoert i CI mot fixturen. Verifiseres: en bevisst daarlig vektendring gir roed port. |
| V-13 | Omnigent firm-harness som default inngang: 16 paner til én styrt flate | drift | infra-1 | M | — | Én kommando aapner orchestrator-1-flaten der operatoeren snakker til harnessen og kan se/ta over hver lane; firm-wt-split og codex-wt-split blir fallback, ikke default. Isolasjon og push-gate uendret. Verifiseres: en arbeidsdag gjennomfoert uten aa aapne 16 paner. |

### Bølge 2 (20 oppgaver)

| id | tittel | lane | eier | str | avhenger av | leveranse |
|---|---|---|---|---|---|---|
| V-14 | Jobb som henter konkurransedokumenter fra documentsUrl | data | data-1 | L | V-05 | hent-konkurransedokumenter laster ned vedlegg til documents (purpose=tender) i crm-prosessen som eier upload-volumet, med MIME-/stoerrelsesgrense, rate-limit og retry; extractOnUpload gjoer resten. Verifiseres: dokumentdekning stiger maalbart fra nullmaalingen i V-05. |
| V-15 | xlsx-parser i tekstuttrekket | data | data-1 | S | V-14 | extractText haandterer xlsx (prisskjema, kravmatriser) i tillegg til pdf/docx/txt. Verifiseres: et reelt prisskjema gir uttrukket tekst i stedet for text=null. |
| V-16 | Append-only outcomes-collection med utfall gjennom godkjenningskoeen | data | data-1 | L | V-02 | Ny outcomes-collection (opportunity, stage, aarsak-enum, verifisertAv/At, kildedok) der postmortem og awards-backfill FORESLAAR rader via ny approvals-koetype «utfall» i stedet for aa skrive status direkte. Verifiseres: et utfall foreslaatt av agent, avgjort av menneske, synlig i «Til godkjenning». |
| V-17 | predictions.outcome utvidet til samme enum, med backfill | data | data-1 | M | V-16 | predictions.outcome dekker levert/kvalifisert/vunnet/tapt/avlyst, backfillet fra opportunities.status og awards. Verifiseres: calibration-backtest kjoerer paa flere enn won|lost, og vinnrate regnes ikke lenger fra den overlastede status-enumen. |
| V-18 | CPV-taket senket fra 50 til 20 poeng, verifisert mot fixture | rangering | learning-1 | M | V-12 | FIT_POINTS.cpvMax ned, vekten flyttet til tekst-/scope-bevis, med foer/etter-tall fra V-12-harnesset i PR-beskrivelsen. Verifiseres: tapte ja faller mot 0-2 av 30 mens nei-kuttet holder over 60 %. |
| V-19 | Hard-filter-lag som versjonert konfig som alltid logger bortfiltrering | rangering | learning-1 | M | V-12 | Terskelverdi, frist, geografi og kvalifikasjons-blokkere som eksplisitt versjonert konfig; hver bortfiltrert sak logges med hvilken regel som traff, og filteret kan skrus av i UI. Verifiseres: koeen viser «N skjult av regel X» med lenke til aa se dem. |
| V-20 | Delt Tabs-komponent ekstrahert | ux | tools-1 | S | — | Én Tabs-komponent erstatter den dupliserte fane-navigasjonen i opportunities/[id]/page.tsx:157 og kompetanse/page.tsx:134, med aria-current og ?fane-kontrakten bevart. Verifiseres: begge sider bruker komponenten, dype lenker virker uendret. |
| V-21 | opportunities/[id] fra 7 til 3 faner | ux | tools-1 | L | V-20 | Sak, Grunnlag (Krav + Kvalifikasjon + Brief) og Tilbud; Klage og Arbeid blir seksjoner. page.tsx (629 l) splittet saa TilbudTab (1178 l) ikke er i samme endringsflate som kravuttrekk. Verifiseres: gamle ?fane-verdier redirecter, og to lanes kan jobbe i mappa uten kollisjon. |
| V-22 | Sidemenyen fra 25 nav-maal til 7, med redirects | ux | tools-1 | L | V-20, V-21 | NAV_GROUPS redusert til Koe, Anbud, Marked, Kunnskap, Salg/OEkonomi, Rapport, Innstillinger; de 18 oevrige blir faner/filtre inne i de 7, med redirect fra hver gammel href. Agenter, AI-bruk og Kalibrering ut av arbeidsmenyen og inn under Innstillinger. Verifiseres: ingen 404 fra de gamle URL-ene, og mobil «Mer» har under 10 punkter. |
| V-23 | Kildehierarki i proveniens-UI: seks rangnivaaer | jus | paal-1 | M | — | Source-unionen i provenance.tsx utvidet fra ai|you til LOV, DOM, KOFA, KOMM, PRESSE, VAAR, med fast rekkefoelge, prefiks-tekst (ikke farge alene, WCAG 1.4.1) og svakere kant paa de tre nederste. KOMM/PRESSE/VAAR kan aldri staa alene bak et forslag — mangler primaerkilde vises forslaget som «Undersoek». Verifiseres: en Myhre-basert paastand uten primaerkilde gir ikke «Tilby». |
| V-24 | Myhre-kommentarer rendret med status og «ikke bindende» | jus | paal-1 | S | V-23 | ASSUMPTION/FACT/REJECTED fra types-kommentar.ts synlig i UI; ASSUMPTION faar teksten «vaar lesning, ikke etterproevd», og KOFA under opphevet 1999/2006-regelverk faar «opphevet regelverk» i samme linje. Maks ett 25-ords sitat per paastand (RED redistribution). Verifiseres: ingen kommentar vises uten statusmerking. |
| V-25 | Godkjenningskoeen utvidet til modell-output med penge- eller leveransepaavirkning | agent | tools-1 | M | V-16 | Modell-output som i dag skrives rett til DB og blir «sannhet» i UI (tilbudsutkast, kontraktsgjennomgang, kravuttrekk der det styrer pris) gaar gjennom approvals med proposal frosset og humanVersion separat. Verifiseres: et tilbudsutkast kan ikke bli gjeldende uten en menneskelig avgjoerelse i loggen. |
| V-26 | Kvote for saker utenfor profilen, og MMR i koevisningen | rangering | learning-1 | M | V-19 | 18 profil-slots + 2 eksplisitt merkede «utenfor profil» per koevindu, med MMR over scope-kategori/kjoeper/verdiband saa topp-2 ikke er to nesten identiske saker. Gjenbruker reserveStatuteSlots-mekanikken fra legal/retrieve.ts. Verifiseres: koeen inneholder maalbart flere distinkte kategorier, og de 2 kvote-slottene er merket i UI. |
| V-27 | Doffin keyed API-loep for kunngjoeringer under EOeS-terskel | data | data-1 | M | V-02 | eForms-parser mot Doffin Public API bak abonnementsnoekkel, saa de 41 % under terskel kommer inn maskinelt i stedet for aa mangle. Verifiseres: antall kunngjoeringer under terskel i basen stiger fra dagens keyless-dekning, med XSD-validert mapping. |
| V-28 | Node-versjonsparitet maskinelt sjekket | plattform | infra-1 | S | V-01 | En CI-sjekk sammenligner node-versjon i validate.yml, anbud.yml, Vercel-konfig og Railway-image og feiler ved avvik. Verifiseres: en bevisst versjonsbump i én fil gjoer porten roed. |
| V-29 | Kostnad per arbeidsflyt synlig paa /ai | drift | tools-1 | S | V-10, V-11 | SUM(costUsd) GROUP BY task og per arbeidsflyt (full anbudsgjennomgang, kravuttrekk, tilbudsutkast) paa /ai, med maanedlig trend. Verifiseres: dagens anslag 0,6-1,5 USD per gjennomgang erstattet med et maalt tall. |
| V-30 | ADR-0018, 0019 og 0020 skrevet og avgjort | produkt | orchestrator-1 | M | — | Tre ADR-er: agent-/arbeidsflate (sier eksplisitt om den superseder ADR-0017 pkt 1 eller legger seg som modus i /mote), rangeringsmotor (sier om den superseder ADR-0014 pkt 2 og/eller ADR-0017 pkt 2, og bekrefter at ADR-0011s bid_no_bid=null staar), og kjoereplattform (avgrenser Azure til kundeproduktene, bekrefter Railway+Vercel). Verifiseres: hver ADR har Status og lenker til issuene som utfoerer den. |
| V-31 | Myhre-crawler inn i versjonskontroll med plan | data | data-1 | S | — | crawl_myhre.py flyttet fra ~/.local/share inn i repoet med cron/CI, saa nye artikler kommer inn uten manuell kjoering. Siste fetch er 2026-10-09. Verifiseres: en planlagt kjoering henter og logger nye artikler uten manuelle steg. |
| V-32 | Ukentlig kalibreringsrapport i stedet for auto-justering | rangering | learning-1 | M | V-12 | Rapport til operatoeren: «motoren er X % enig med dere, disse 5 trekkene drar mest, disse 3 ja-ene rangerte vi lavt», med KI paa hvert tall. Ingen automatisk vektjustering. Verifiseres: rapporten leveres uten at noen terskel endres av seg selv. |
| V-33 | Mobil «Mer»-ark gruppert | ux | tools-1 | S | — | MORE_LINKS rendres i NAV_GROUPS-gruppene i stedet for som én flat liste paa 25 punkter. Verifiseres paa 390px: arket har overskrifter og under 10 punkter per gruppe. |

### Bølge 3 (10 oppgaver)

| id | tittel | lane | eier | str | avhenger av | leveranse |
|---|---|---|---|---|---|---|
| V-34 | OCR-fallback for skannede PDF-er | data | data-1 | M | V-14 | Skannet PDF uten tekstlag gaar til OCR i stedet for text=null + warn, med retry-koe for uprosesserte dokumenter. Verifiseres: en kjent skannet konkurransegrunnlag gir uttrukket tekst. |
| V-35 | LLM som re-ranker paa topp-50 med sitatplikt, A/B foer paaslag | rangering | learning-1 | L | V-12, V-18 | Listwise re-ranking av topp-50 der hver flytting krever en begrunnelseslinje med sitat mot anskaffelsesteksten; ingen nye poengtall uten begrunnelse. A/B mot prio-2 i V-12-harnesset foer den slaas paa. Verifiseres: harnesset viser maalt forbedring, ellers forblir den av. |
| V-36 | Kvalifikasjonslaget som eksternt visbart produkt | jus | paal-1 | L | V-16, V-23, V-37 | «Kan DU vinne dette, og hva mangler du» — ESPD-krav mot faktisk omsetning, soliditet og referanser, med kilde paa hvert krav, bygget paa prd/kvalifikasjonslaget og eksisterende engine. Verifiseres: en ekstern bruker faar svar med kildehenvisning per krav. |
| V-37 | Kredittkilde integrert bak ett grensesnitt | data | data-1 | M | — | Reell soliditet og omsetning fra valgt kommersiell kilde, bak samme grensesnitt som Brreg-bevisene, med degrade-sti naar kilden mangler. Verifiseres: et kvalifikasjonskrav om omsetning avgjoeres mot ekte tall, ikke antakelse. |
| V-38 | Verktoey-konkurrentkart i market/competitors/ | produkt | admin-1 | M | — | Mercell, Tendium, Finndoff, Varsly, Anbudsradar, FOA, Hyyr og Tenderlake som JSON i samme format som de 34 eksisterende radgiver-profilene, med pris, AI-funksjoner og distribusjonskanal. Verifiseres: hver rad har kilde-URL per paastand. |
| V-39 | wp-2 refittet mot registrerte utfall | rangering | learning-1 | L | V-17, V-32 | Vektene i winProbability estimert med penalisert logistisk regresjon mot ekte utfall i stedet for haandsatte tall, med ny modellversjon og uendret forklaringsflate. Verifiseres: kalibreringsplott og Brier-score lagret, og tallet rapporteres bare naar KI er smalere enn en definert grense. |
| V-40 | Dokumenthenting fra portaler med innlogging | data | data-1 | L | V-14 | Mercell og tilsvarende portaler dekket der vilkaar og legitimasjon tillater det, med tydelig logg over hva som ikke kunne hentes. Verifiseres: dokumentdekning stiger videre fra V-14-nivaaet, med kildefordeling. |
| V-41 | Varsling naar en agentjobb feiler, report-only | drift | infra-1 | S | V-04 | Feilede tasks og missed cron-vinduer rapporteres til Discord/morgenbriefing med hva som feilet og naar; ingenting slaas av automatisk. Verifiseres: en bevisst feilet task gir ett varsel og ingen automatisk deaktivering. |
| V-42 | Issue 032: referansekrav-terskeltrapp | jus | paal-1 | M | V-23, V-24 | relevant/sammenlignbar/tilsvarende som regelgruppe i kvalifikasjon og triage — det eneste reelle hullet i Myhre-rekken 032-046 (033-046 er alle levert). Verifiseres: et referansekrav klassifiseres i trappa med kildehenvisning, og regelen er dekket av test. |
| V-43 | Catch-up for cron-vinduer maskinen var nede | drift | infra-1 | M | V-41 | Croner som mistet vinduet kjoeres igjen ved oppstart innenfor en definert horisont, med logg over hva som ble hentet inn. Verifiseres: en simulert nedetid paa 12 timer gir etterfylling, ikke et hull i innhentingen. |

## Operatør-gater

- **[na]** Prod-innlogging (DATABASE_URL eller IMPORT_EMAIL/IMPORT_PASSWORD + prod-URL) saa `npm run export:triage -- --remote` og `npm run dokumentdekning -- --json` kan kjoeres og lagres som fixtures. Per minnet feedback_prod_db_access_safety: kjoeres som skriptfil, aldri inline env-var. — blokkerer V-05, og dermed V-12, V-18, V-19 og hele eval-sporet
- **[na]** Beslutning: skal utfall (levert/kvalifisert/vunnet/tapt + aarsak) registreres obligatorisk? Ingen teknisk loesning erstatter dette svaret. — blokkerer V-16, V-17, V-39 og all kalibrering
- **[na]** ADR-0017-omkamp: er /mote fortsatt hovedflaten, eller overtar triage-/arbeidskoeen? ADR-en er operator direction fra 2026-10-11 og flaten er bygget. — blokkerer V-07, V-22, V-30
- **[denne uken]** Tre-scopes-valget (strategy/proposals/2026-10-12-tre-scopes.md, frist 19.10): velg de tre, fordel eierskap, avklar hva «regnskapssystem (faa fra Malik)» betyr. — blokkerer V-30, V-38 og all scope-avhengig rangering
- **[denne uken]** Azure-avgrensning som ADR: gjelder «Bygge paa Azure» kundeproduktene eller ogsaa plattformen? Uten ADR starter noen en migrering (proposalens egen advarsel). — blokkerer V-30; park-statusen for Azure-sporet
- **[denne uken]** Datapolicy: forlater vi PERMISSIVE, hvilke datatyper blokkeres, og skal gaten stoppe eller bare varsle naar den ikke kan lese policyen? — blokkerer V-06
- **[denne uken]** Skal MIN_JUSTIFICATION-gaten slakkes? Det endrer hva som logges som treningsgrunnlag til pref-1 (LEARNING_MIN_N=30 paa et korpus av 97). — blokkerer V-08
- **[denne uken]** Hvilke gamle href skal redirectes og hvilke kan doe? URL-ene er delt i Obsidian/Telegram. — blokkerer V-22
- **[denne uken]** Skal Omnigent-harnessen bli default inngang i stedet for 16 paner, og hva maa du kunne se samtidig? — blokkerer V-13
- **[denne uken]** Anskaffelsesjurist til aa kvalitetssikre kildehierarkiet (lov > dom > KOFA > kommentar > presse > vaar hypotese) og Myhre-sitatgrensen (RED redistribution). — blokkerer V-23, V-24, V-42
- **[senere]** DOFFIN_API_KEY: registrering paa dof-notices-prod-api.developer.azure-api.net (+ e-post til DFOe for Notices-delen). Uten den er 41 % av kunngjoeringene — alt under EOeS-terskel — utilgjengelig maskinelt. — blokkerer V-27
- **[senere]** Kredittkilde: velg og godkjenn kostnad (Proff 349 kr/rapport, eller abonnement hos Enin/Creditsafe/D&B). eBevis er stengt for oss ved design — tilgangen forutsetter rolle som oppdragsgiver. — blokkerer V-37, V-36
- **[senere]** Habilitetsavklaring fra anskaffelsesjurist FOER anbudsplattformen selges til andre leverandoerer, siden Solarconsulting AS selv byr (ADR-0015). — blokkerer V-36, V-38
- **[senere]** Nedlasting av konkurransedokumenter fra portaler med innlogging (Mercell m.fl.) krever operatoerens legitimasjon + vilkaarsvurdering. Den keyless delen (aapne documentsUrl) trenger ingen gate. — blokkerer V-40 (ikke V-14)
- **[senere]** Myhre: svar fra forfatteren paa intern AI-prosessering (ai_processing_rights = UNKNOWN), og beslutning om crawleren skal inn i versjonskontroll (ligger i ~/.local/share utenfor git). — blokkerer V-31
- **[senere]** Enhver ny migrering og enhver backfill mot prod-base: OK kjoer-gaten per ~/.claude/CLAUDE.md pkt 1 og 3. — blokkerer V-16, V-17, V-19, V-27

## Måleparametere

- Median tid fra sak vist til beslutning lagret. Baseline finnes IKKE i dag (ingen «vist»-timestamp) — foerste leveranse er aa kunne maale det. Maal: under 90 sekunder.
- Obligatoriske interaksjoner per beslutning. I dag 4 handlinger + fritekst paa minst 10 tegn. Maal: 1-2 for aapenbare saker, full begrunnelse bare der den koster penger.
- Tapte ja i scope-/hard-filteret maalt mot lagret fixture. I dag 8 av 30 (27 %). Maal: under 2 av 30 mens kuttet av nei holder seg over 60 %. Maa rapporteres med Wilson-KI — med n=97 er enhver forbedring under ~0,10 AUC ikke maalbar.
- Andel anbud i triage-koeen med minst ett dokument med uttrukket tekst. Nullmaaling mangler (skriptet finnes, ingen lagret kjoering). Dette er takhoeyden for hele LLM-kjeden nedstroems.
- Registrerte utfall per maaned. I dag 0. Alt annet laerings- og kalibreringsarbeid er blindt til dette tallet er positivt — det er den eneste maaleparameteren som endrer hva som er mulig om seks maaneder.
- USD per arbeidsflyt, fra SUM(costUsd) GROUP BY task i llm-usage. Logges alt per kall med prisversjon, men ingen har summert det — dagens anslag (0,6-1,5 USD per full anbudsgjennomgang) er ANTAKELSE. Maal: maalt tall med maanedlig trend, og synkende per arbeidsflyt.
- Andel merge-til-main der alle relevante CI-porter faktisk var groenne. I dag ikke avledbart (hardkodet want_checks-array; migrasjonssnapshot sto roed og ble merget i ~en maaned). Maal: 100 %, maalt ved aa sammenligne kjoerte sjekker mot jobbene i workflow-filene.
- Antall samtidige agent-flater operatoeren maa holde oversikt over. I dag 16 (firm-wt-split 8 + codex-wt-split 8). Maal: én styrt flate med isolasjonen intakt — maalt som «paner aapnet per arbeidsdag».

## Åpne spørsmål til operatøren (grill-me-grunnlag)

- HOVEDFLATE: Er /mote fortsatt hovedflaten (ADR-0017, din egen beslutning 2026-10-11, bygget med 3 ruter) — eller skal triage-/arbeidskoeen overta? Hvis begge lever: hvem av dem eier spoersmaalet «hva skal jeg gjoere naa»? Jeg trenger ett svar, ikke to flater som begge paastaar aa vaere inngangen.
- UTFALL: Skal utfall (levert / kvalifisert / vunnet / tapt + aarsak) registreres obligatorisk? Hvem fyller det, naar i loepet, og hva skjer hvis det ikke blir fylt? Dette er den ENESTE gaten som avgjoer om kalibrering og ML er mulig om 6 mnd — all annen laering er blind uten den.
- UTFALLS-ENUM: Hvilke utfallsverdier og taps-aarsakskoder er kanoniske? Valget laaser migrering, rapportering og vinnrate-definisjonen. Er «declined» (vaart eget nei) et tap eller ikke?
- DATAPOLICY: Forlater vi PERMISSIVE? Konkret hvilke av de 8 datatypene (intern, anbudsdokument, kunde-epost, whatsapp, kundedokument, energidata, cv, intern-chat) skal blokkeres mot modell-API — og naar gaten ikke kan lese policyen: stoppe agenten eller slippe gjennom med varsel? Du valgte permissiv 2026-10-08; jeg foreslaar aa snu det, men det er din risiko.
- MODELLKVALITET: Hvor mye kvalitetstap aksepterer du per oppgavetype for aa kutte kostnad? Hvilke oppgaver skal ALDRI ned-rutes til billigmodell (jeg foreslaar: juridisk svar, kravuttrekk, tilbudsutkast)?
- BEGRUNNELSE: Skal fritekst-begrunnelsen fortsatt vaere obligatorisk foer lagring? For alle 4 utfall, eller bare over en beloepsgrense / bare for STRONG_BID og NO_BID? Aa slakke den gir raskere triage men tynnere treningsgrunnlag — og vi har bare 97 beslutninger.
- NAV-BRUK: Hvilke av de 25 nav-maalene bruker du faktisk i en vanlig uke? Det finnes ingen bruksstatistikk i repoet, saa jeg kan bare se at rutene eksisterer — ikke at de brukes. Uten svar blir et nav-kutt gjetning.
- DYPLENKER: Hvilke gamle URL-er har du delt eksternt (Obsidian, Telegram, e-post) som MAA redirecte naar nav konsolideres? Hvilke kan doe stille?
- AZURE: Gjelder «Bygge paa Azure» kundeproduktene eller ogsaa den interne plattformen? Og hvis OCR/tale skal paa Azure: er West Europe akseptabelt for anbudsdokumenter og lydopptak, naar Norway East ikke har SKU for Document Intelligence eller Speech i det hele tatt?
- KOMMERSIALISERING: Skal anbudsplattformen selges til andre leverandoerer? Plattformstrategien har staatt PROPOSED i 8 dager. Hvis ja: hvordan loeser vi at vi selv byr (ADR-0015) — en habilitetsulempe ingen av de 10 kartlagte konkurrentene har?
- TRE SCOPES (frist 19.10): Hvem eier hvilket scope, og skal valget tas FOER eller ETTER arkitektur-ADR-ene? Fire av fem forutsetninger er uloeste, og jeg mener de to beslutningene ikke kan kjoeres parallelt uten aa overbelaste deg.
- MALIK: Hva betyr «regnskapssystem (faa fra Malik)» konkret? Det staar som operatoer-eid punkt i proposalen og blokkerer scope-valget.
- MULTI-TENANT: Delt basisprofil + per-tenant residual, eller fullt isolerte profiler per kunde? Dette maa avgjoeres FOER kunde nr. 2, ikke etter — det bestemmer datamodellen for pref-1.
- HARD-FILTRE: Faar et hard-filter skjule saker som standard, eller skal det alltid vaere av-skrubart med logget bortfiltrering? Avveiningen er triage-tid mot tapte ja — og dagens skjulte variant (binaere flagg sortert foer score i et 200-raders vindu) taper alt 8 av 30 ja.
- 16 PANER: Skal Omnigent-harnessen bli default inngang (den er konfigurert: orchestrator-1 + 7 lanes + 10 spesialister, watch/takeover, push policy-gatet), eller vil du beholde separate paner for isolasjon? Hva er minimum du MAA kunne se samtidig, og hva holder det aa kunne hente opp?
- DETERMINISME: Er «LLM er ikke eneste rangeringsmotor» et forbud mot LLM i rangeringen for alltid, eller et krav om at deterministiske regler alltid skal kunne overproeve den? Svaret avgjoer om V-35 (re-ranker med sitatplikt) i det hele tatt skal staa i planen.

## Completeness-kritikk

**1. DEKNING PER PROBLEMSTILLING (dårligst først)**

- **E produktøkonomi — dårligst dekket.** Pris-agenten leverte enhetspriser og sier selv: «ingen volumantakelser», «kodebasen ble ikke lest», «alle tall over er enhetspriser, ikke et budsjett». Mangler nøyaktig: pris mot kunde, dekningsgrad per kunde, CAC/churn, antall kunder for break-even, og hva en tenant koster å kjøre. Nedbrytningen har ÉN økonomi-oppgave (V-29, intern LLM-kostnad). Null P&L. E er ubesvart.
- **D agentbasert produktarkitektur — nest dårligst.** Parkert med «de fem rollene finnes alt, det som mangler er navngivning, ikke funksjonalitet» — og så ingen oppgave som gir navngivningen eller orkestratoren. V-06/V-25 er sikkerhetshygiene, ikke arkitektur. Ingen agent fikk D som mandat. Ingen leste `automation/lib/llm.mjs` (den ustyrte stabelen) eller ARCHITECTURE.md-kroppen der foreslåtte agentroller kan ligge.
- **C market intelligence — halvt dekket.** Tre agenter dekket KILDER (TED/Doffin/Brreg/KOFA) og KONKURRENTER. Ingen dekket produktet: de fire signalene (kategoriaktivitet, lav konkurranse, SMB-stengende krav, fornyelser) er klassifisert MULIG/UMULIG, men ingen oppgave bygger ett av dem. KOSTRA/kommunebudsjetter ikke sjekket. Ingen kundevalidering — «hullet» er utledet fra featurelister, agenten sier det selv.
- **A UX — godt dekket, men blind.** To agenter, 0 skjermbilder, 0 kjørt app. Ingen åpnet `/mote` (ADR-0017s hovedflate, tre ruter) — de anbefaler å erstatte en flate ingen har lest.
- **B anbefalingsmotor — godt dekket, uenig med seg selv.** Se spenningen juster-nå vs frys. `similar.ts`, `relevance.ts`, `gates.ts`, `baseRates.ts`, `priority.ts`-kroppen aldri lest.

**2. UDOKUMENTERTE PÅSTANDER SOM BEHANDLES SOM FAKTA**

- 97 beslutninger / 30 ja / 62 nei, 725 opportunities, 1653 per 12 dager, 428 av 546 uten verdi, CPV 72:26/43 — ALLE referert fra issue-markdown. Issue 050/051 sier selv «kjøringen/spørringen er ikke lagret». V-05 flagger det, og **V-18 bruker likevel «0-2 av 30» som akseptkriterium**. Stryk akseptkriteriet eller gjør V-05 blokkerende for V-18 formelt.
- «8 av 30 ja tapt (27 %)» er samme ureproduserbare kjøring, og er det eneste beviset bak V-19 og hele hard-filter-spenningen.
- Mercell 14 900 kr: agenten sier prisarket ble lest «via søkesammendrag, ikke ved å åpne PDF-en». Brukes som fakta i «Varsly 99 mot Mercell ~1242» i strategiske spenninger. Verifiser eller stryk.
- Railway-vs-Azure-raden i pris-funnene motsier seg selv i samme setning («~2.3x dyrere … altså Railway er BILLIGERE»). Ubrukelig. Stryk.
- Konkurrentenes AI-funksjoner: leverandørenes egne sider, ingen testet. «AI er paritetsfeature» er en antakelse, ikke et målt faktum.
- Omnigent-påstanden i V-13 og tilstandsbildet har INGEN kilde i funnene — den kom fra orkestratorens minne, ikke fra en agent. Jeg verifiserte `omnigent/firm/config.yaml`: orchestrator-1 som brain + 7 lanes + 10 spesialister + codex stemmer, og `codex-wt-split.sh` finnes. Behold, men merk som verifisert av kritiker, ikke av funn.
- To agenter er uenige om samme fil (24 vs 27 nav-href, 46 vs 47 page.tsx, tom vs full MORE_LINKS). Én ble sjekket. Det betyr at den tapende agentens ØVRIGE greps-tall også er upålitelige — ingen har sjekket resten av dem.

**3. MODALITETER OG KILDER SOM IKKE BLE KJØRT**

Ingen kjørte appen. Ingen skjermbilder, ingen nettleser — playwright-MCP er konfigurert (feilet i dag), ingen forsøkte. Ingen prod-spørring. Ingen operatør-observasjon på en flate med N=1 bruker. Ingen konkurrent-prøveabonnement. Ingen leste Brain-vaulten for tidligere Veldora-beslutninger eller handoffs.
Aldri åpnet: `/mote`-rutene (3 filer), ARCHITECTURE.md-kroppen (1350 l, bare overskrifter), OPPGAVER.md §4/§7 (WEB-26..38 + ANB-01..06, mulig åpent arbeid), de to øvrige PROPOSED-proposalene, de 3 PRD-ene, `test/`-mappen, `agents.yml` (594 l), `guard-main.yml` (194 l), `automation/lib/llm.mjs`, 28 `actions-*.ts`, `hooks/`, `eval/`, `config/verticals.ts`.

**4. DUPLIKATER MOT ALT LEVERT**

- V-07 er omskrevet riktig etter korreksjonen (TriageCard har alt Suggestion + TriageBrief), men V-07/V-08/V-09 måles alle på «2 handlinger» — samme gevinst talt tre ganger. Slå sammen måltallet.
- V-12 overlapper agreement.ts (AUC finnes); bare splitt + KI er nytt. Riktig rammet, men størrelse M er for høyt.
- V-30 ADR-0019 risikerer å re-spesifisere ADR-0011/0014/0017 i stedet for å velge mellom dem.
- Ingen oppgave duplikerer issues 023-030 eller 033-046 — bra, det var den største fellen og den er unngått.

**5. OPERATØRENS FEM EKSPLISITTE PUNKTER**

- **heygen-nedlastingene: FALT HELT UT.** Null treff i 12 funn, null oppgave, null åpent spørsmål, ikke engang parkert. Verifisert: 0 forekomster av «heygen» i Veldora-rad; skillene ligger i `~/.claude/skills/heygen-*`. Ingen spurte hva nedlastingene er, hvor de ligger, eller hva de skal brukes til. Dette er den klareste mangelen i hele runden.
- **omnigent: behandlet** (V-13 + tilstandsbilde), men uten funn-kilde. Ingen agent hadde det som mandat.
- **16 paner til én flate: behandlet, men uspesifisert.** V-13 er «wiring og vane», og leveransen er «en arbeidsdag uten 16 paner». Ingen definerer hva flaten VISER. Akseptkriteriet er en vane, ikke et produkt.
- **taleassistent: PARKERT på sirkelargument** — «ingenting i funnene etterspør det». Operatøren etterspurte det. Og svaret finnes faktisk i pris-funnene (Voice Live Lite mot Pro, STT $1/lydtime, og Norway East har 0 SKU for Speech) — begravet i en parkeringskule. Må opp som eget valg: bygg, avvis, eller utsett med begrunnelse.
- **nyttig for andre / produkt: halvt behandlet.** V-36 + V-38 + ett åpent spørsmål. Mangler: pris mot kunde, multi-tenant-arkitektur (bare et spørsmål, ingen oppgave), og distribusjonskanal — som markedsanalysen selv kaller større blokker enn produktet.

**6. TRE SPØRSMÅL RUNDE 2 (uavhengige forslag) MÅ SVARE PÅ**

1. Hva er produktet, hvem betaler, og hva koster én tenant å kjøre? Et forslag uten én P&L-linje adresserer ikke E.
2. Hva gjør orkestratoren som de fem eksisterende rollene ikke gjør? Si det konkret, eller avvis D som problemstilling.
3. Hva er hovedflaten — etter å ha lest `/mote`? Forslag som ikke har åpnet flaten operatøren valgte 2026-10-11 er ikke forslag.

**TRE SPØRSMÅL RUNDE 3 (red-team) MÅ SVARE PÅ**

1. Hvilke oppgaver har et akseptkriterium som hviler på et ureproduserbart tall? Stryk dem eller gjør V-05 hard forutsetning. Start med V-18 og V-19.
2. Hvor mange av 43 oppgaver leverer noe en bruker merker? Bølge 1 er 6 CI/infra-porter + 3 UI-småting. Angrip at hele første bølge er intern hygiene mens A-E står ubesvart.
3. Hva er fallback hvis utfall aldri blir fylt manuelt? V-16/V-17/V-39 og hele B hviler på det. Finn en kilde som ikke krever menneskelig disiplin, eller erklær B dødt i 6 måneder.
