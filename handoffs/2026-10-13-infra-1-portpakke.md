# Handoff 2026-10-13 — infra-1: portpakken, vaktposten og datapolicyen

**Alt er committet, ingenting er pushet.** Fem grener venter OK kjør. Ingen skitne filer, ingen
containere, ingen worktrees etterlatt. Produksjonsvakten kjører under systemd og overlever omstart.

## Grener, i den rekkefølgen de skal landes

| # | Gren | Innhold | Commits |
|---|---|---|---|
| 1 | `infra-1/want-checks-strukturelt` | **MÅ LANDES FØRST** (bindende, orchestrator-1 13:41Z): strukturell check-avledning, worker-driftsvern, effekt-port, post-deploy-port, selvforsynt agent-guard + versjonssjekk | 4a8c6da, 620243f, b274b1f, 70ece2f, 37d84e4 |
| 2 | `trading-1/crm-ci-royktest` | **ETTER 1.** Røyktestporten. Eies av trading-1 | 9c09f3f |
| – | `infra-1/vakt-i-repo` | Produksjonsvakten i repoet + `vakt-install.sh` | f47cd4d |
| – | `infra-1/datapolicy-fail-closed` | Personvern-gaten fail-closed i begge retninger | 9c6b176 |
| – | `infra-1/pg-backup-restore` | Backup + testet restore. **Køet til bølge 2** | 209eff8 |
| – | `infra-1/leak-scan` (command-center) | Lekkasjeport, rapport-only, fra 11.10 | 83a77a6 |

**Hvorfor rekkefølgen er tvingende:** `trading-1/crm-ci-royktest` fjerner skip-linja for
`smoke-agent-guard.ts` og kaller `scripts/check-server-version.ts` — men begge filene ligger på
`infra-1/want-checks-strukturelt` (37d84e4). Lander trading-1s gren alene, er porten rød på main
(exit 2, eller `id = NaN`). Grenene har null filoverlapp, så ingen trenger en ekstra commit.

## Siste bevis før landing (gjort, ikke antatt)

Unionskjøring i eget worktree — trading-1s `9c09f3f` med mine to filer lagt over, altså tilstanden
som faktisk landes: **exit 0 · GRØNN 27 · RØD 0 · SKIP 3 · suite 431 s** (tidligere kjøring samme
maskin: 640 s — bruk det høyeste for CI-margin). Suiten skriver
`check-server-version: ok, Postgres 18 (180006)` som første steg, så major-versjonen bevises hver
kjøring. `smoke-agent-guard.ts` er grønn **i delt base**, så den forurenser ikke de andre 26.
De tre skippene bærer UDEKKET-felt: rettskildeoppslag, markedsberikelse, requalify-fingeravtrykk.

## Operatør-gater (ingen av dem kan jeg lukke)

1. **OK kjør** for grenene over, i rekkefølge.
2. **Rotasjon av node-stackens to passord** (memory.db 13.06, verbatim 2264/2323, lengde 40/41).
3. **Forbrukstall fra Railway/Vercel** — kr/mnd kan ikke måles uten dashboardet. All FinOps er
   ellers gjetting, og det står merket som gjetning overalt jeg har brukt tall.
4. **DPA med Anthropic** (og Google for Workspace-synken) før første eksterne kunde.
5. **Post-deploy-porten er ikke kjørt mot Vercel** (token er gated). Åpent spørsmål til
   orchestrator: skal den gå `continue-on-error` én runde? Tar jeg feil om v13-svarformen,
   blokkerer den deployer til noen retter den — fail-closed med vilje.

## Tall som er målt i dag, og skal brukes i stedet for estimater

- LLM: full kjede **$0,052/anbud** (tak), realisert snitt **$0,028**, **$94/mnd** totalt i dagens
  tempo. Mitt tidligere estimat var 1,6× for høyt, et annet var 9,7×. Kilde: `llm_usage`, 7 døgn.
- Azure-gulv: **$90-100/mnd** minimalt (Consumption-only, Sweden Central), ~$190 med privat
  endepunkt eller West Europe. Container Apps' miljøavgift treffer BARE Dedicated workload profiles.
- Railway-ekvivalent i dag: ~$75/mnd kompute. Hele datasettet er ~2 GB.
- **Anbefaling står: bli på Vercel + Railway.** Azure er dyrere på dagens last og løser ingen av de
  tre svakhetene (tenant-isolasjon, fail-open personvern, manglende backup).

## Åpne tråder som har eier

- **bølge 2, min:** feed-korrupsjonen (`$`-tall spises av skallet; én linje rammet, 2350).
- **bølge 2, min:** backup + restore-test (mekanismen er bygget, første ekte dump er operatørgate).
- **trading-1:** isolasjon per røyktest, så `smoke-requalify` kan slås på.
- **tools-1:** `opportunity_id` på `llm_usage` (27 kallsteder, migrasjon = operatørgate).
