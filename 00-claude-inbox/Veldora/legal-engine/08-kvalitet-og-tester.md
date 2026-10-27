# Kvalitet og verifisering — Veldora-frist / projects/anbud (08)

Scope: testinventar, røyktester, skjemavalidering, eval, CI, determinisme, regresjonsvern.
Repo: `admin-1/legal-engine-map` = `origin/main` (`fae0ddd`). Alt under er LES ONLY, målt med kommandoer.

## 1. Testinventar

| Prosjekt | Rammeverk | Testfiler | `it(`/`test(` (presist, `grep -roE "\b(it|test)\("`) | `describe(` |
|---|---|---|---|---|
| `projects/anbud/crm` | vitest (`package.json`: `"test": "vitest run"`) | 255 (`find . -name "*.test.ts" \| grep -v node_modules \| wc -l`) | 2500 | 688 |
| `projects/anbud/dashboard` | node:test (`"test": "node --experimental-strip-types --no-warnings --test \"test/*.test.mjs\""`) | 47 | 615 | 246 |

`grep -rc "it(\|test(" --include="*.test.ts" src | awk -F: '{sum+=$2} END{print sum}'` gir 2647 for CRM / 621 for dashboard — høyere enn presist-tallet fordi `-c` teller TREFF-LINJER, ikke kall (linjer med flere kall på én linje telles én gang). Begge kommandoer kjørt, presist-tallet (`-roE`) er det jeg legger til grunn.

**Juridiske moduler uten test** (`src/lib/legal/*.ts` og `src/lib/klage/*.ts`, parret mot `*.test.ts`):
- `src/lib/legal/db.ts`, `embeddings.ts`, `log.ts`, `refs.ts`, `search.ts`, `kommentarVurderingStore.ts`
- `src/lib/klage/store.ts`
- (ikke reelle hull: `unbzip2-stream.d.ts` er en typedeklarasjon, `klage/__fixtures__/law.ts` er en fixture)

`src/lib/legal/kofa/**` (8 filer) har alle test. `src/lib/klage/**` har test på 12 av 13 egentlige moduler.

## 2. Røyktester (`scripts/smoke-*.ts`, CRM)

30 skript totalt (`ls scripts/smoke-*.ts | wc -l`). Kjøres via `scripts/royktest.sh` — IKKE av `npm test` (det er `vitest run`, rører dem ikke). Hver smoke nekter å kjøre mot en ekte base (regex-sjekk på `DATABASE_URL` mot railway/rlwy/amazonaws/neon.tech → exit 2).

| Avhengighet | Eksempler |
|---|---|
| Lokal, migrert, bruk-og-kast Postgres | alle 30 |
| Seedet admin (env `SEED_ADMIN_EMAIL/PASSWORD`) | `smoke-decision-guard.ts`, `smoke-konfig.ts` m.fl. |
| Nettverk (ekte, polite fetch) | `smoke-legal.ts` (api.lovdata.no), `smoke-kofa.ts` (klagenemndssekretariatet.no, robots.txt-sjekket) |
| Ingen LLM-nøkkel nødvendig | de fleste, inkl. `smoke-klage.ts`, `smoke-chat.ts`, `smoke-konfig.ts` |

**I CI:** ja — `royktest`-jobben i `.github/workflows/anbud.yml` kjører `scripts/royktest.sh` mot en `postgres:18-alpine`-service, blokkerende fra landing (ingen rådgivende-markør i jobbkommentaren → tas med i auto-merge-botens avledede sjekkliste). 28 av 30 kjører i CI; 2 skip med dokumentert grunn i `royktest.sh`:
- `smoke-market.ts` — krever innhentede kunngjøringer (`npm run worker:once`), tom CI-base.
- `smoke-legal.ts` — krever ingestet rettskildekorpus, tom CI-base.
Målt veggklokke på GitHub-runner: 504 s (run `38581301220`).

## 3. Skjemavalidering

`node scripts/validate.mjs` (repo-rot, les-only) kjørt nå — output: **`checked 60 file(s) against 16 schema(s), including 69 matrix row(s); all structured data valid`**.

16 schema under `data/schemas/`: buyer, reference-case, qualification-taxonomy-map, kommentar-ref, terskelverdi, product, feedback, requirement, qualification-requirement, capability, procurement, supplier, cpv, data-source, opportunity, award.

**Slipper gjennom uvalidert:** `validate.mjs` validerer statiske JSON-filer under `data/` (inkl. `data/legal/terskelverdier.json` og `data/legal/kommentar-regler.json` mot egne schema) — IKKE den levende CRM-basen (Postgres), IKKE det ingestede rettskildekorpuset fra Lovdata/KOFA, og ikke KOFA-avgjørelser. Validering av produksjonsdata skjer ikke her.

## 4. Eval

| Script | Måler | Nettverk/modell? | Siste registrerte tall |
|---|---|---|---|
| `scripts/eval-legal.ts` | Retrieval-metrics + (med nøkkel) sitat-presisjon/recall mot `eval/legal-gold.json` (45 spørsmål) | DB obligatorisk; modellkall valgfritt | Ingen rapportfil funnet i repo — kjøres manuelt, ingen siste-kjøring-artefakt |
| `scripts/eval-scope-categories.ts` | Hvor mange ja/nei/undersøk-triage-saker scope-kategoriene fanger/mister | Nei — leser kun en JSON-eksport | `eval/SCOPE-KATEGORIER-19OKT.md`: målt mot produksjon 2026-10-13 (kode `6cc89c2`) — 105 beslutninger (30 ja/69 nei/6 undersøk); de 3 foreslåtte scopene dekker 3 av 30 ja |
| `scripts/calibration-backtest.ts` | Bakover-kalibrering av ~50 historiske tildelinger (deterministisk, ingen LLM) | Leser produksjon read-only (Payload Local API), skriver kun JSON-rapport | **ALDRI kjørt mot produksjon** — skriptets eget STATUS-felt (`calibration-backtest.ts:7-9`): sandkassen har ingen DB-rute til prod, kun typesjekket |
| `scripts/eval-typesafe/**` | Reranker-kvalitet (TypeSafe Jev Noul vs. baseline FTS) | Ja — modellkall (Jev/Haiku/Sonnet) | `results/summary.json`: generert 2026-10-06; baseline FTS MRR 0.63, Jev-rerankede varianter MRR 0.75–0.79, 860 kall / 0 failures |

Ingen av de fire er koblet til CI eller vitest (målt: `grep -rn "eval-legal\|eval-scope-categories\|calibration-backtest\|eval-typesafe" .github/workflows/*.yml` → tomt; `grep -rl "legal-gold" src` → tomt).

## 5. CI (`.github/workflows/`)

| Workflow | Trigger | Kjører | Blokkerer merge? |
|---|---|---|---|
| `validate.yml` | push main, PR | `node scripts/validate.mjs`, `node scripts/secure.mjs check` (plaintext-sperre), auto-merge/deploy-gate selvtester; + `website` (claims/kontrast/typecheck/lint/build) | Ja (avledet) |
| `anbud.yml` | push main / PR på `projects/anbud/**`, + `workflow_dispatch` | `crm` (tsc, vitest, build), `migrasjonssnapshot` (schema-drift), `royktest` (28/30 smoke mot migrert PG18), `dashboard` (tsc, lint, node:test, build) | Ja, alle 4 (royktest blokkerer fra landing, ingen rådgivende-markør) |
| `agents.yml` | cron (~10x/dag Oslo-tid), PR, `workflow_dispatch` | Agent-registeret (Slack/Anthropic, no-op uten secrets) + PR: `node --test "automation/**/*.test.mjs"` | Ja (`test`-jobben, avledet) |
| `guard-main.yml` | push main | Reviderer push (force-push/ukjent pusher → issue), venter på og rapporterer validate/crm/dashboard-resultat | **Nei** — ren rapport, "STOPPER ingenting" |
| `auto-merge.yml` | `workflow_run` på `[validate, anbud, agents]`, `pull_request_target`, `workflow_dispatch` | Boten selv: avleder obligatoriske sjekker strukturelt fra jobbnøkler i workflow-filene (`.github/scripts/expected-checks.py`, scoped til PR-ens endrede filer), squash-merger når alt grønt | Er selve porten |
| `deploy.yml` | push main, `workflow_dispatch` | Vercel-deploy + `verify-vercel-deploy.sh` (venter på READY) | Nei (post-merge) |
| `daily.yml`, `linear-done.yml`, `linear-website-tasks.yml`, `slack-channels.yml` | cron/push/dispatch | Linear/Slack-synk | Nei, ikke i auto-merge sin `workflow_run`-liste |

**Auto-merge-boten** erstatter native branch protection (repoet er privat på GitHub Free). Kjente hull dokumentert i filen selv: `agents.yml` manglet i `workflow_run`-lista til 13.10 (stille, ikke rød); `migrasjonssnapshot`-jobben manglet i en tidligere hardkodet sjekkliste i ~1 måned (PR #154 landet rødt grønt).

## 6. Determinisme — regnestykke vs. modell

**Regnestykke vinner (ingen gjetting):**
- `src/lib/legal/helligdager.ts:11-24` — `forskyvFrist` returnerer alltid BÅDE opprinnelig og forskjøvet dato med `hjemmel: null`, `status: 'ANTAKELSE'`; kun jurist kan sette `FACT`.
- `src/lib/klage/deadlines.ts:52` og `:96` — `lawMissing` fylles og `status: 'ukjent'` når ingen korpus-chunk finnes, i stedet for å gjette en frist.
- `src/lib/deadlines.ts:75,87` — `status: 'insufficient'` når færre enn 2 kilder å sammenligne.
- `src/lib/legal/answer.ts:3-6` — sitat-validator: hver setning må sitere et verbatim utdrag fra lagret chunk-tekst, ingen fuzzy-matching, én feil ⇒ `usikkert`.
- `src/lib/citationJudge.ts:3-7` — kodeflagg (endret modalverb, tallavvik) avviser UTEN modellkall; modell brukes kun i gråsonen (score 0.1–0.9).

**Modellen har siste ord:**
- `src/lib/legal/ask.ts:172,177` — `complete({...json:true})` + reparasjonskall; modellen komponerer selve svarteksten (valideres deterministisk etterpå, men innholdet er modellens).
- `src/lib/qualification/semanticJudge.ts:90,98` — LLM-dommer avgjør semantisk støtte / terskel-ekstraksjon.
- `src/lib/qualification/llmClassifier.ts:66` — LLM klassifiserer kravtype direkte.
- `src/lib/qualification/failJudge.ts:38` — LLM-dommer avgjør fail-sjekk.
- `src/lib/citationJudge.ts` (via `typesafeFor`/Claude-eskalering) — modellens verdikt i gråsonen; men merk `:7`: «en verdikt sender aldri noe videre til en bruker — den sender det til et menneske, aldri en juridisk konklusjon».

## 7. Regresjonsvern for juss

Delvis. `eval/legal-gold.json` FINNES — 45 spørsmål med `expected`-id-lister (forventet hjemmel/kilde) — men kjøres ALDRI automatisk:
- `grep -rl "legal-gold" src --include="*.ts"` → tomt (ingen vitest-import)
- `grep -rn "eval-legal" .github/workflows/*.yml` → tomt (ingen CI-jobb)

Kun manuell kjøring: `node --env-file=.env --import tsx scripts/eval-legal.ts`. Sitat-valideringslogikken (`citationJudge.ts`, `answer.ts`) ER vitest-testet (`src/lib/citationJudge.test.ts`, `src/lib/legal/answer.test.ts`) — men det tester formatregler (sitat-match, antall setninger), ikke om riktig hjemmel faktisk ble hentet. **Et faktisk feil juridisk svar (riktig format, feil hjemmel) ville IKKE fanges automatisk** (målt: gullsettet er frakoblet CI).

---

*Skrevet av kartleggingsagent, 2026-10-15. Alle tall målt direkte i repoet, kommandoer oppgitt inline.*
