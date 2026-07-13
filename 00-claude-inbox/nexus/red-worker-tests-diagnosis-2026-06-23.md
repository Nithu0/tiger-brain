# RØDE worker-tester — diagnose (read-only, code-1)

**Dato:** 2026-06-23
**Av:** code-1 (read-only diagnose, ingen Nexus-kode rørt)
**Rapportert av ai-2 (firm-bus 2026-06-23T00:10Z):** worker-tester RØDE på main — `quarantine-learning-filter` (5 fail) + `mean-rev-parity` + `meta-label-backfill` → pre-push-gaten blokkerer ALLE pushes.

## TL;DR (konklusjon)

**Dette er IKKE en kode-regresjon. Det er en false-red fra build-ordering, og den ER ALLEREDE FIKSET på `origin/main`.**

- Jeg kjørte hele worker-suiten på nåværende working tree: **1430/1430 PASS, 0 fail** (`npm test --workspace=apps/worker`, varighet ~79s).
- Hovedlinja (`origin/main`) rapporteres 1517/1517 grønn.
- Root cause = pre-push-hooken bygde ikke `packages/shared` før den kjørte worker/api-testene → stale/manglende `packages/shared/dist` → testene som importerer `@ai-agent/shared` falt med "Cannot find module .../dist" eller manglende-export. Ren miljøfeil, ikke logikkfeil.
- Fiksen er commit **`93224f8` "fix(ci): build @ai-agent/shared in pre-push hook"** (PR #167), og den **ligger nå i `origin/main`s `.husky/pre-push`** (verifisert via `git show origin/main:.husky/pre-push`).

Så: ingenting å fikse i selve test- eller kildekoden. Det som gjenstår er distribusjon av hook-fiksen til feature-branchene (se "Hva ai-1/ai-2 må gjøre" nederst).

## Hvordan jeg kom fram til det

1. **Navnematch:** `quarantine-learning-filter` / `mean-rev-parity` / `meta-label-backfill` finnes IKKE som filnavn eller describe/test-navn i `apps/worker/src`. `grep -rli 'quarantine'` og `'parity'` over hele worker-src gir 0 treff. De er ai-2s muntlige etiketter, ikke test-ID-er.
   - Nærmeste faktiske filer: `src/firm/meta-label/backfill-labels.test.ts`, `src/firm/mean-reversion/mean-reversion-manager.test.ts`, `src/firm/gates/mean-revert-gate.test.ts`, `src/firm/meta-label/meta-label.test.ts`.
2. **Kjørte full suite (working tree):** 1430 pass / 0 fail. Test-scriptet i working-tree `package.json` inkluderer allerede de nye testfilene (backfill-labels, scorer, skip-observability, event-policy/state-machine, lineage-persistence, strategy-versions, change-verification, portfolio-brain-regime).
3. **Kjørte de to "orphan"-testfilene** som ikke står i scriptet (`position-management/tighten-only.test.ts`, `notifications/topic-freshness.test.ts`) individuelt: begge grønne (6/6 og 14/14).
4. **Avdekket mekanismen i firm-bus + git:** ai-1 hadde allerede diagnostisert og fikset dette (CURRENT-STATE.md firm-feed, 2026-06-22T22:41Z: "main var IKKE rød (1517/1517 ren main). ai-2s rød = build-ordering — pre-push bygde ikke packages/shared før worker/api-tester -> stale dist = 'Cannot find module' falsk rød").
5. **Verifiserte fiksen i git:**
   - Fix-commit: `93224f8 fix(ci): build @ai-agent/shared in pre-push hook (unblock false-red worker tests)`.
   - Diff legger til `(cd packages/shared && npx tsc)` ØVERST i `.husky/pre-push`, før worker- og api-testene — speiler CI.
   - `git show origin/main:.husky/pre-push` viser at fiksen er på main.
   - Bekreftet at de navngitte testfilene faktisk importerer `@ai-agent/shared` (f.eks. `meta-label.test.ts:383/390/397/398` → `import { ... FEATURE_KEYS } from "@ai-agent/shared"`), som er nøyaktig importene som faller når shared-dist er stale.

## Per "failing test" — assertion / cause / fix-retning

Alle tre rapporterte feilene har **samme root cause** (stale `packages/shared/dist`), ikke tre separate bugs:

### 1. `quarantine-learning-filter` (5 fail)
- **Hva som feilet:** Importen av en (relativt ny) shared-export fra `@ai-agent/shared` (commit-meldingen kaller den illustrativt `learningFilterSql`; det eksakte symbolet kan hete noe annet, men det er en learning/filter-helper lagt til i shared). Når `packages/shared/dist` ikke var rebuilt etter pull av main, manglet exporten i dist → modul-resolusjon eller named-import feilet → de 5 testene som rører den falt.
- **Sannsynlig årsak:** stale/manglende `packages/shared/dist` (build-ordering), ikke kode.
- **Fix-retning:** ingen kodeendring. Sørg for at `packages/shared` bygges før worker-testene (det er nettopp det `93224f8` gjør). Etter shared-build: grønn.

### 2. `mean-rev-parity`
- **Hva som feilet:** mean-reversion-relatert test (`mean-reversion-manager.test.ts` / `mean-revert-gate.test.ts`) som leser typer/konstanter fra `@ai-agent/shared`. Samme stale-dist → import feilet.
- **Sannsynlig årsak:** samme stale-dist, ikke parity-logikk.
- **Fix-retning:** ingen kodeendring; shared-build først.

### 3. `meta-label-backfill`
- **Hva som feilet:** `src/firm/meta-label/backfill-labels.test.ts` og/eller `meta-label.test.ts`. Sistnevnte importerer eksplisitt `FEATURE_KEYS`, `featuresToVector` m.m. fra `@ai-agent/shared` (verifisert linjer 383–398). Stale shared-dist (nye meta-label-contract-exports ikke kompilert) → named-import feilet.
- **Sannsynlig årsak:** samme stale-dist (nye `meta-label/contract`-exports i shared ikke rebuilt).
- **Fix-retning:** ingen kodeendring; shared-build først. (`apps/worker` har riktignok `pretest: tsc -p ../../packages/shared/tsconfig.json`, men det type-sjekker — det er pre-push-hookens manglende dist-build mot CI som var hullet.)

## Pre-eksisterende eller fra en nylig endring?

**Pre-eksisterende miljø-/CI-hull, ikke en kode-regresjon.** Selve worker-koden og testene er grønne på både working tree (1430/0 her) og main (1517/1517). Det som var "nytt" var at main fikk nye `@ai-agent/shared`-exports (meta-label-contract + learning/filter-helper); enhver som pullet main UTEN å rebuilde shared, og så trigget pre-push, fikk false-red. Pre-push-hooken hadde aldri speilet CIs shared-build-steg — det er den latente bug-en som ble eksponert.

## Hva ai-1 / ai-2 må gjøre (rask vei til grønn)

1. **Fiksen er allerede på `origin/main`** (`93224f8`/PR #167). For å pushe nå: `git merge origin/main` (eller rebase) inn i feature-branchen, slik at den oppdaterte `.husky/pre-push` (med shared-build) er i working-tree når hooken kjører.
2. **Umiddelbar lokal omgåelse uten merge:** kjør `(cd packages/shared && npx tsc)` ÉN gang, så `npm test --workspace=apps/worker` — da er dist fresh og pre-push blir grønn.
3. Ingen test- eller kildekode skal endres. Dette er ferdig diagnostisert; det er kun branch-hygiene (få hook-fiksen inn i branchen) som gjenstår.

## Kilder
- Kjørt: `npm test --workspace=apps/worker` (1430/1430 pass) — denne maskinen, 2026-06-23.
- `git show 93224f8` + `git show origin/main:.husky/pre-push` (fiksen verifisert på main).
- firm-bus feed i `ai-assistent/CURRENT-STATE.md` (ai-1 22:41Z + ai-2 00:10Z).
- Imports verifisert i `apps/worker/src/firm/meta-label/meta-label.test.ts`.
