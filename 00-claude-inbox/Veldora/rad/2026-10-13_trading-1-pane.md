# trading-1 — Staff Software Engineer | Veldora strategiråd runde 1

Lest i `/home/nithu/code/Veldora-rad` (main, 6cc89c2), les-only. Egne målinger + to
lese-subagenter. Tidsboksen er overskredet med noen minutter: kontrakt-kartleggingen landet
sent, og jeg tok inn tallene framfor å levere mine egne feilaktige. Hull: ingen av de 131
endepunktene er responstestet mot ekte DB, så formvurderinger er lest kode, ikke trafikk.

## 1. DAGENS TILSTAND (FACT/IMPL, med fil:linje eller kommando)

**Størrelse** (FACT, `find`/`wc -l`/`grep` i `projects/anbud`, 2026-10-13):
- crm: 754 TS-filer, 95 129 linjer. **58 collections + 11 globals** (`payload.config.ts:128-187`),
  **131 egendefinerte endepunkter i 29 filer**, **46 job-tasks / 59 slugs / 32 cron-planer**
  (`jobs/registry.ts:133-184`), 51 migreringer over 17 dager (`20260926_123918_initial` →
  `20261012_210000_scope_backfill_enum`), `push: false` (`payload.config.ts:193`). GraphQL av (:205).
- dashboard: 222 filer, 37 171 linjer, 46 `page.tsx`-ruter, 2 `route.ts`, **108 server actions i
  22 `'use server'`-filer**. Avhengigheter: next, react, react-dom. Det er alt.
- `payload-types.ts` 6 194 linjer, generert. `ARCHITECTURE.md` 4 548 linjer, og den er kontrakten
  som skal endres før koden.

**Tester** (FACT): 294 testfiler, 32 282 testlinjer, alle rene enhetstester i prosess.
`anbud.yml:3`: "Unit tests only - no database". Hullene er systematiske: dashboard `.tsx`
**0** (de 45 `test/*.test.mjs` importerer bare `src/lib/*.ts`), 108 server actions **0**,
2 route handlers **0**, 51 migreringer **0**, 18 access-tester for 58 collections, 14 av 29
endepunktsfiler har testnabo. E2e, nettleser, DOM: **0** — verken playwright, cypress,
testing-library eller jsdom finnes i noen `package.json`. Ingenting treffer en URL.

**Men verifiseringen finnes alt, den er bare ikke koblet på** (FACT): 29 `smoke-*.ts` i
`crm/scripts/` kjører mot lokal Postgres via Payload local API (18/18 og 19/19 logget i
`docs/lanes/plattform.md`). `npm test` er `vitest run` og rører dem ikke (`crm/package.json:17`).
`grep -rniE "smoke" .github/workflows/` gir null. **Null av 29 røyktester kjører i CI.**

**Porter i dag** (FACT, lest i `.github/workflows/`):
- `anbud.yml`: crm = `tsc --noEmit` + `npm test` (23-24), **ingen `npm run build`**;
  dashboard = tsc + lint + test + build (55-58); egen `migrasjonssnapshot`-jobb (44).
- `auto-merge.yml`: en bot, ikke branch protection (privat repo på GitHub Free, rulesets
  Pro-gated, `:6-11`). Obligatoriske checks er en hardkodet strengliste: `REQUIRED=(schemas
  website)` (:62) + `want_checks+=(crm dashboard migrasjonssnapshot)` (:127).
- Direkte push til main er tillatt og går rundt alt (`guard-main.yml:3-6`, ADR-0012-tillegget).
- `deploy.yml`: `npx vercel deploy --prod` (:110) er siste steg i jobben. Ingen røyktest,
  ingen helsesjekk, ingen status-polling etterpå.
- Railway deployer crm og worker selv fra GitHub (`.railway/railway.ts:15-17`). crm har
  `healthcheck /api/health` (180 s) og `migrate-or-die.ts`, som feiler lukket: re-leser
  `payload_migrations` og `exit 1` hvis noe mangler (`src/migrate-or-die.ts:71`, `Dockerfile:46`).
  Worker har **ingen** healthcheck (`railway.ts:33`).

**Parallellarbeid** (FACT, rettet 08:40 — mitt første tall var `head`-avkuttet, samme feil som
orchestrator-1 rettet hos seg): **42 worktrees** (10 agent-opprettede under `.claude/worktrees`),
**130 lokale grener**, 137 totalt. Churn siste 14 dager (103 commits):
`ARCHITECTURE.md` **61**, `payload-types.ts` 48, `migrations/index.ts` 48, `payload.config.ts` 35,
`jobs/registry.ts` 23. Filer rørt av ≥3 av 11 aktive grener: `payload-types.ts` (4),
`migrations/index.ts` (4), `lib/brief.ts` + `brief.test.ts` (4), `triage/TriageCard.tsx` (3),
`jobs/registry.ts` (3), `cli/queue-job.ts` (3). Største: `TilbudTab.tsx` 1 178,
`endpoints/tilbud.ts` 811, `tilbud-forms.tsx` 800, `feilsjekk/rules.ts` 798, `lib/triage.ts` 757.
Triage-klyngen: 4 304 linjer, og `triage/page.tsx` (435) gjør 7 `cmsJson`-kall og eier seks
ansvar: param-parsing (:57), parallellhenting (:63), kø-paginering (:189), dekningslaster (:207),
normalisering (:217) og en lokal `Shell` (:235).

**Frontend-til-backend-sømmen** (FACT, viktigst for §4): dashboardet har **null** DB-tilgang
(`grep -rn "drizzle|from 'pg'|@payloadcms" dashboard/src` er tom; ARCHITECTURE.md:49-53 slår det
fast som invariant). Alt server-side går gjennom én fil, `dashboard/src/lib/cms.ts` (Payload REST,
videresender `payload-token` som `Authorization: JWT`), 82 importører. Klient-side er bare auth,
opplasting og SSE mot `/cms/*`-rewriten (`next.config.ts:30`).

## 2. DE TRE STØRSTE SVAKHETENE (rangert, med bevis)

**1. To uavhengige deploy-baner, ingen rekkefølge, ingen felles verifisering.** (FACT)
Dashboardet deployes av `deploy.yml` til Vercel; crm deployer seg selv fra Railway. Ingenting
koordinerer dem, så en frontend som forventer nytt skjema kan gå live før migreringen, eller etter.
Vercel-banen har null verifisering (`deploy.yml:110` er siste steg), worker har ingen healthcheck,
og CI bygger **aldri** crm (`anbud.yml:18-24`) — et byggbrudd i Payload-configen, som 35 commits
rørte på 14 dager, er usynlig til Railway-deployen feiler, altså etter merge. Dette er rotårsaken
til "grønn CI, virker ikke i prod": ikke uflaks, fravær av port.

**2. Merge-porten er en strengliste noen må huske å redigere.** (FACT)
`migrasjonssnapshot` ble lagt til som CI-jobb i #136 (f42c00f) uten å røre `auto-merge.yml`.
Porten kjørte, svarte rødt på PR #154, og boten merget likevel. Repoet skriver det selv i
`auto-merge.yml:120-123`. #155 (03e45c1) var en én-linjes fiks (:127). Feilklassen står: hver ny
CI-jobb er rådgivende til navnet skrives inn på to steder, og `:58-61` advarer om at et
navnebytte feiler stille. Boten merger også når PR-en ligger bak main, uten ny CI (:160-170),
så semantiske konflikter lander urørt.

**3. Grensesnittet er avskrevet for hånd, 23 ganger.** (FACT)
Dashboardet importerer **aldri** `crm/src/payload-types.ts`. I stedet finnes 23
`types-*.ts` + `types.ts` i `dashboard/src/lib/` som speiler collections manuelt, og de sier det
selv: `types.ts:1-3` "Mirrors the Payload collections in ARCHITECTURE.md §5", `types-tilbud.ts:1-4`
"The stored `jurist*` field names are kept (API unchanged)" — et feltnavn er alt frosset av
duplikatet. Samtidig returnerer 9 endepunkter rå Payload-dokumenter uten DTO
(`chat.ts:330,354`, `henvendelser.ts:112,125`, `godkjenning.ts:67`, `leveranse.ts:166`,
`okonomi.ts:119`, `prospekter.ts:67`, `kommentar.ts:97`), og ~60 dashboard-kallsteder går rett på
auto-REST for 20+ collection-slugs med Payloads `where`/`depth`-dialekt reimplementert i
`cms.ts:33-48`. Null versjonering: 131 endepunkter, ingen `/v1`. Et feltnavnbytte i backend
knekker klienten uten at noen port merker det. Samme mønster i det små: `config/tracks.ts`
(188 linjer, importert av 8 moduler i begge apper) sier i headeren "Keep keys and labels in sync
with dashboard src/lib/triage.ts" — manuell invariant på tvers av apper, uten test.

## 3. HVA VI ALLEREDE HAR SOM KAN GJENBRUKES (alt er IMPL, bygget og i drift i dag)

- **`dashboard/src/lib/cms.ts`** — én søm, 82 importører, JWT-videresending, Payload-access arves; en ny frontend kan skrives mot denne uten å røre backend.
- **De 29 `crm/scripts/smoke-*.ts`** — ferdig DB-oppførselsdekning som bare mangler en CI-jobb med
  Postgres-service. Billigste kvalitetsgevinst i hele rapporten.
- **`migrate-or-die.ts` + `check-migration-snapshot.sh`** — fail-closed migrering og drift-port.
- **`/api/health`** — ekte DB-rundtur, 503 ved feil. Grunnlag for post-deploy-porten som mangler.
- **`payload-types.ts` genereres alt** (`payload.config.ts:204`) — klient-typene finnes, de brukes bare ikke.
- **`/anbud/triage/*`**, navngitt "Kontrakt 1–4" (`types-triage.ts:1`): mal for lesemodellen i §4.
- **`approvals` + `data-policy`-porten** (ARCHITECTURE §5): "Agenter setter aldri status,
  godkjenning eller verdikt. Alt agentene skriver er ASSUMPTION til et menneske bekrefter."
  Presis den styringen en proaktiv AI-flate trenger — ikke bygg en ny. **Forbehold etter infra-1s
  funn, verifisert av meg:** `data-policy` feiler ÅPENT i to veier — uleselig global gir
  `PERMISSIVE_POLICY` + én warning (`datapolicy.ts:90-92,104`, bevisst), og uregistrert kilde gir
  alt tillatt (`llm.ts:86-89`). Vei to var død i drift til kodegjennomgangen 08.10
  (`docs/lanes/plattform.md`). Designet gjenbrukes, implementasjonen må feile lukket først.

## 4. MIN ANBEFALING

**Hovedanbefaling: inkrementell strangler bak ruteflagg, med genererte klient-typer og et
lesemodell-lag mellom den nye flaten og Payload. Men porter først.** (FORESLÅTT)

Begrunnelsen er sømmen i §1: frontend er allerede en ren HTTP-klient, så en omskriving er
backend-trygg. Det som ikke er trygt i dag, er å deploye noe som helst. Rekkefølgen følger av det.

Fase 0, portpakken (3 dager, blokkerer resten):
1. `npm run build` for crm i `anbud.yml` (0,5 d). Fanger byggbrudd før merge.
2. Ny CI-jobb `royktest`: Postgres-service + de 29 smoke-scriptene (1 d). Navnet må inn i
   `want_checks` i samme PR, ellers er porten rådgivende.
3. Post-deploy-port i `deploy.yml`: poll `/api/health` på crm og én GET mot dashboardets
   innlogging etter Vercel-deploy, rød jobb ved feil (0,5 d). Healthcheck på worker (0,25 d).
4. Env-skjema med zod i begge apper, kastet ved oppstart (0,5 d): fjerner
   `ANTHROPIC_API_KEY!` (`llm.ts:156`) og tomstreng-fallbacken i `cms.ts:22`. CRM_URL valideres
   uansett plattform, ikke bare når `VERCEL` er satt (`next.config.ts:9-12`) — i dag baker
   CI-bygget inn `localhost:3000`, så grønt dashboard-bygg beviser ingenting om prod-rewriten.
5. Generer dashboard-typene fra `payload-types.ts` i stedet for 23 håndskrevne speil (0,5 d for
   de tre mest brukte, resten etter behov). Dette er den eneste endringen som gjør et
   feltnavnbytte til en rød CI i stedet for en stille prod-feil.

Fase 1, lesemodell (3-4 dager): ett endepunkt per anbefalingsflate som returnerer presis den
formen flaten trenger, med kildehenvisning per felt (`2026-10-05-anbud-plattformstrategi.md` §1).
Ikke rå collection-dokumenter, og de 9 raw-doc-lekkasjene lukkes samtidig. Dette er laget som gjør
at 58 collections kan endres uten å knekke frontend.

Fase 2, ny flate bak flagg (5-8 dager): ny rutegruppe `(ny)` ved siden av `(app)`, samme `cms.ts`,
flagg per rute. Operatøren bytter rute for rute mens hen vurderer anbud live, og gamle ruter står
urørt som rollback. Triage først, siden den er mest smertefull og mest målt.

Alternativ A: parallell ny flate som eget Vercel-prosjekt mot samme crm. Tryggere isolasjon, men
to frontender og dobbel env-drift. Velg den bare hvis operatøren ikke tåler noen risiko i dagens
flate i det hele tatt. Alternativ B: big-bang. Avvis — med 0 e2e, 0 tester på 108 server actions,
0 på `.tsx` og ingen post-deploy-port, mot en operatør som vurderer anbud med frist 19.10, er det
det eneste valget som kan koste et reelt anbud.

Eierskapsmodell (FORESLÅTT, svar på spørsmål 5): ingen rebase-regel fikser nåløyene, de må gjøres
mindre. (a) `ARCHITECTURE.md` er verste kollisjonsfil, 61 berøringer på 14 dager, og
kontrakt-først-regelen tvinger hver gren gjennom den. Splitt den per lane-seksjon.
(b) `payload-types.ts` genereres — ta den ut av diffen og regenerer i en pre-merge-jobb.
(c) `migrations/index.ts` og `jobs/registry.ts` er registre som kolliderer per linje. Bytt til
mappe-skanning, da legger hver gren en fil uten å røre en felles. (b)+(c) fjerner tre av de fem
verste churn-filene. (d) Én gren eier én lane-fil i `docs/lanes/`; `lib/brief.ts` og
`TriageCard.tsx` får navngitt eier per dag i feed.md.

## 5. HVA JEG VIL UTFORDRE HOS ANDRE ROLLER

- **learning-1:** jeg utfordret at vinnsjanse kan læres av beslutningsloggen nå (#144, "validert
  mot 97 beslutninger"). De målte det selv samme dag og bekrefter: AUC 0,577 / 0,549 / 0,575 ved
  n=30 ja, altså ikke skillbart fra myntkast. Da skal tallet ikke stå på kortet uten "ikke
  kalibrert" ved siden av. Konsekvens for rådet: anbefalingsflaten må designes for å vise
  usikkerhet, ikke for å vise et presist prosenttall vi ikke har.
- **code-1:** at triage-flaten er det presserende problemet. Nåløyene er `TilbudTab.tsx` (1 178)
  og `endpoints/tilbud.ts` (811), ikke `page.tsx` (435). Og ingen frontend-forbedring overlever
  en deploy-bane uten verifisering.
- **infra-1:** vaktposten dekker 5xx etter at noe er ute. Jeg vil ha porten *før* deploy (fase 0
  punkt 3), ellers oppdager vi fortsatt brudd i prod, bare raskere.
- **data-1:** at RAG skal være primærflaten for anbefalinger. BM25 og embedding er svake på
  tallrader; verdi, frist og vinnsjanse hører i SQL med kildepeker.
- **orchestrator-1:** at 20 worktrees er et koordineringsproblem. Det er arkitektur, se §4 (a)-(c).

## 6. ÅPNE OPERATØR-GATER i mitt domene

1. **GitHub Pro eller offentlig repo.** Branch protection er Pro-gated (`auto-merge.yml:6-11`),
   så maskinporten foran main er en bash-løkke. `scripts/github-setup.sh` tar over den dagen.
2. **Direkte push til main.** Tillatt per ADR-0012-tillegget 2026-10-03. Alle porter i fase 0 er
   valgfrie så lenge den står åpen. Bare operatøren kan stenge den.
3. **Vercel-team og VERCEL_TOKEN.** `rm -rf .git` før deploy (`deploy.yml:100`) omgår at
   commit-forfatteren ikke er teammedlem. Fiksen er et medlemskap, ikke kode.
4. **CRM_URL i Vercel** bakes inn ved bygg, krever redeploy (`next.config.ts:7-8`).
5. **Node-versjon i Vercel** matches for hånd (`validate.yml:9`: "forskjellen oppdages først i
   produksjon"). Enten låser operatøren den i Vercel-UI, eller vi godtar driften.

## 7. KILDER

- Målinger: `find`/`wc -l`/`grep`/`ls` i `projects/anbud` 2026-10-13. Kollisjonskart:
  `git diff --name-only origin/main...<gren>` × 11 grener. Churn: `git log --since=14.days
  --name-only --pretty=format: -- projects/anbud | sort | uniq -c | sort -rn`.
- `anbud.yml:3,18-24,44,55-58` · `auto-merge.yml:6-11,58-62,120-127,160-190` · `deploy.yml:8-20,100,110`
  · `guard-main.yml:3-6` · `validate.yml:7-10` · `.railway/railway.ts:15-17,23-24,33` · `Dockerfile:46`
- `migrate-or-die.ts:56-71` · `api/health/route.ts:7-15` · `check-migration-snapshot.sh:3-11` · `payload.config.ts:128-189,193-195,204-205` · `jobs/registry.ts:133-184` · `config/tracks.ts` (header) · `lib/llm.ts:80,156` · `crm/package.json:17`
- `cms.ts:1-3,22-26,33-48,95-101` · `next.config.ts:7-13,30` · `lib/types.ts:1-3` · `types-tilbud.ts:1-4` · `types-triage.ts:1` · `dashboard/package.json:15`
- Rå-dokument-lekkasjer: `chat.ts:330,354` · `henvendelser.ts:112,125` · `godkjenning.ts:67`
  · `leveranse.ts:166` · `okonomi.ts:119` · `prospekter.ts:67` · `kommentar.ts:97`
- `ARCHITECTURE.md:49-53` + §5 · `docs/lanes/plattform.md` · `2026-10-05-anbud-plattformstrategi.md` §1
- `git log`: 6cc89c2, 03e45c1 (#155), f42c00f (#136), 726a8b8 (#154), b8e9d1f (#140), #156.
