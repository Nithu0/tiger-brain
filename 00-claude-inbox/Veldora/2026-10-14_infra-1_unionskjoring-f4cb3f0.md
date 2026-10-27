# Unionskjøring: royktest-porten mot main f4cb3f0 — infra-1, 2026-10-14

Kjørt fordi kjøringen fra 13.10 (431 s, 27-0-3) målte en annen kilde: trading-1s gren lå fire
commits bak main, og #158/#160/#161 rører nettopp `crm/src` som røyktestene tester.

## Tilstand som ble kjørt

- `~/code/Veldora-union` = `origin/main` **f4cb3f0** + de tre filene fra
  `origin/trading-1/crm-ci-royktest` (`f143cc2`): `.github/workflows/anbud.yml`,
  `projects/anbud/crm/scripts/royktest.sh`, `projects/anbud/crm/scripts/smoke-scope-backfill.ts`.
- Null filoverlapp: `git log origin/trading-1/crm-ci-royktest..origin/main -- <de tre>` er tom,
  så dette ER rebase-resultatet, ikke en tilnærming.
- `node_modules` symlenket fra `Veldora-radar` (verifisert komplett: docx, web-push,
  unbzip2-stream, tsx). Ingen dep-endring mellom radar og main, bare et script-felt.
- Base: `postgres:18-alpine` i engangscontainer, lokal port, `payload migrate`.

## Resultat

```
check-server-version: ok, Postgres 18 (180006)
GRØNN: 27  RØD: 0  SKIP: 3
EXIT=0  VEGGKLOKKE=400s
```

Veggklokke på denne maskinen: 400 s nå, 431 s 13.10, 640 s første kjøring. Bruk **640 s** som
CI-margin — en GitHub-runner er tregere, og `timeout-minutes: 30` i jobben holder uansett.

## De 27 grønne (navngitt denne gangen — loggen gikk til fil)

- smoke-agent-guard.ts
- smoke-bevis.ts
- smoke-brief.ts
- smoke-chat.ts
- smoke-clarify.ts
- smoke-decision-guard.ts
- smoke-feilsjekk.ts
- smoke-ingest-db.ts
- smoke-innboks.ts
- smoke-klage.ts
- smoke-klassifisering.ts
- smoke-kofa.ts
- smoke-kommentar.ts
- smoke-kompetanse.ts
- smoke-konfig.ts
- smoke-legal-ask.ts
- smoke-leveranse.ts
- smoke-okonomi.ts
- smoke-plattform.ts
- smoke-qualification.ts
- smoke-rammeavtale.ts
- smoke-rapport.ts
- smoke-salg.ts
- smoke-scope-backfill.ts
- smoke-scoring.ts
- smoke-sources.ts
- smoke-tilbud.ts

## De 3 skippene, med UDEKKET-feltene porten selv skriver ut

- `smoke-legal.ts` — krever ingestet rettskildekorpus, tom CI-base.
  UDEKKET: rettskildeoppslag mot anskaffelsesloven og FOA.
- `smoke-market.ts` — krever innhentede kunngjøringer (`npm run worker:once`), tom CI-base.
  UDEKKET: markeds- og kjøperberikelse.
- `smoke-requalify.ts` — grønn isolert, rød i delt base (`payload_jobs`-kontaminering), venter
  isolasjon per test (trading-1 eier). UDEKKET: at endret registerfakta flytter fingeravtrykket og
  køer qualify-requirements.

30 skript totalt, 27 kjørt, 3 skippet. `smoke-agent-guard.ts` er grønn i den delte basen — det var
den reelle risikoen ved å slå den på, og den er nå målt mot f4cb3f0, ikke bare mot 9c09f3f.

## Avledet checkliste (expected-checks.py fra main, mot unionens anbud.yml)

- PR som rører `projects/anbud/crm/**`: `crm, migrasjonssnapshot, royktest, dashboard, schemas, website`
- PR som bare rører `README.md`: `schemas, website`

Ingen `# auto-merge: advisory`-markør finnes i grenen, så porten er blokkerende fra merge-øyeblikket.
Det er sluttilstanden orchestrator-1 ratifiserte 13.10 — men «fjern markøren» har ingenting å fjerne,
og trading-1s egen PR blir den første som må ha porten grønn.

## Gjenstår (ikke mitt å lukke)

1. trading-1: åpne PR for `crm-ci-royktest`, og rett de tre foreldede tekststedene først
   (`anbud.yml:57`, `anbud.yml:61-63`, `royktest.sh:46-49` — alle sier «4 skip»/agent-guard-skip
   som ikke lenger finnes).
2. infra-1 (meg), etter merge: bekreft at `royktest` faktisk står i check-runs på main, og at
   `check-server-version` skriver Postgres 18 i den ekte main-kjøringen — ikke bare i yaml-en.

Rålogg: `2026-10-14_infra-1_unionskjoring-f4cb3f0.rawlog.txt` (samme mappe).
