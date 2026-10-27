# Horizon cutover: sjekkliste for ett vindu

tools-1, 2026-10-27. Bygger på `horizon-repo-plan.md`. Status: **steg 0–1 gjort**, cutover venter på operatørens go.

## Gjort (ingen prod-påvirkning)

- `github.com/Solar-Consulting/horizon` er opprettet (privat). Importen er reproduserbar med `~/code/horizon-patch/importer.sh <mappe>`, som kjører filter-repo, 2 patcher og tre-hash-sjekk. Siste kjøring var fra kilde-main 6e38cb1 med 258 commits, og tre-hashen for crm og dashboard var identisk.
- Patcher: 0001 stier (workflows, railway.ts, legal-speil, taxonomy-test), 0003 relative stier til rotfiler. (0002 ubuntu-24.04 er utgått: Solar-Consulting #331 er merget og følger med i importen.)
- Prøvekjørt 2026-10-27 fra kilde 398376b: ren import, 262 commits. Simulert merge inn i horizon/main gir konflikt bare i de tre workflow-filene, fordi samme fiks står på begge sider. `read-tree`-steget under løser det.
- Variablene `VERCEL_ORG_ID` og `VERCEL_PROJECT_ID_ANBUD_VELDORA` er kopiert til horizon.

## Før vinduet (operatøren)

- [ ] **Railway GitHub-app** installert på org `Solar-Consulting`, med tilgang til `horizon`. FACT: i dag er bare appen `claude` installert på org. Uten Railway-appen feiler kildebyttet.
- [ ] Secrets i horizon: `gh secret set ANTHROPIC_API_KEY -R Solar-Consulting/horizon` og `gh secret set VERCEL_TOKEN -R Solar-Consulting/horizon`.
- [ ] Vercel-appen trengs **ikke**: `anbud-veldora` har `git.deploymentEnabled: false` og deployes med CLI og token fra Actions.

## Vinduet (~1 t, tools-1 kjører, orchestrator-1 varsler frys)

| # | Steg | Verifisering | Rollback |
|---|---|---|---|
| 1 | **Frys** `projects/anbud` i Solar-Consulting (firm-bus). Noter frosset SHA `S`. | Ingen åpne anbud-PR-er venter på merge | Opphev frysen |
| 2 | `importer.sh ~/code/horizon-final` fra `S`. I `~/code/horizon`: `git fetch ~/code/horizon-final HEAD:import && git merge --no-ff --no-commit import; git read-tree --reset -u import && git commit` (merge-commit der treet er nøyaktig importens; ingen force). Push. | `git rev-parse HEAD^{tree}` = importens tre. Tre-hash for crm og dashboard = `S`. CI i horizon er grønn | Ingenting i prod er endret |
| 3 | **Railway worker**: `connect-service-source` repo `Solar-Consulting/horizon`, branch `main`. Så `update-service`: rotmappe `crm`, watch `/crm/**`. Byttet bygger med en gang. | Deploy SUCCESS på horizon-SHA. Ny `agent_runs`-rad fra worker innen neste sveip (:25). Jobbkø uten feil | Koble tilbake til `Nithu0/Solar-Consulting` med rot `projects/anbud/crm`, eller redeploy forrige deploy i Railway |
| 4 | **Railway crm**: samme bytte. Healthcheck `/api/health` porter, så gammel instans tjener til ny er frisk. migrate-or-die er no-op (samme migreringer). | SUCCESS, `/api/health` 200, innlogging i dashbordet virker | Som 3 |
| 5 | **Vercel** `anbud-veldora`: `rootDirectory` `projects/anbud/dashboard` → `dashboard` (prosjektinnstilling). Kjør horizon `deploy.yml` (`workflow_dispatch`). | Prod-URL svarer, `/login` 200, en mulighetsside laster | Vercel «Promote» forrige deploy, og rot tilbake |
| 6 | **Gammel repo** (PR i Solar-Consulting, én push): fjern raden `anbud-veldora` i `deploy.yml`, slett `.github/workflows/anbud.yml`, fjern anbud-porten i `auto-merge.yml` og MIRRORS i `validate.mjs`, erstatt `projects/anbud/` med README-stub → horizon. **Må merges i samme vindu som steg 5**, ellers bygger gammel deploy.yml med feil rot. | CI grønn i Solar-Consulting | Revert-PR |
| 7 | Opphev frysen. Firm: nye worktrees fra horizon, stier i CLAUDE.md og minne, `run-triage-baseline.sh` brukes fra `~/code/horizon/crm`, og command-center sitt prosjektregister oppdateres. | Første ordinære PR i horizon merges av auto-merge | – |
| 8 | Etter 14 dager: slett stubben (operatør-gated). | – | git-historikk |

Ikke i vinduet: `railway config apply` (se under).

## Railway-variabler mot `railway.ts` (bare navn)

Gjør config til sannheten etter overgangen: legg til navnene under som `preserve()` i `railway.ts`, kjør `config plan`, og sammenlign planen med null endringer før noen kjører `apply`.

**worker:** 35 på tjenesten, 14 i railway.ts.
- Mangler i railway.ts (22): AWARDS_DEDUP_APPLY, AWARDS_HISTORY_MAX_PER_RUN, AWARDS_INCLUDE_HISTORY, COMPETITION_AGENT_ENABLED, GOOGLE_WORKSPACE_ACCOUNT, GOOGLE_WORKSPACE_CREDENTIALS_B64, KJOPERRESEARCH_ENABLED, KRAVAGENT_ENABLED, LEARNING_REPORT_ENABLED, LLM_DAILY_CAP_USD_JUDGE_TRIAGE, LLM_DAILY_CAP_USD_RESEARCH_BUYER, LLM_MODEL_EXTRACT_THRESHOLD, MONITOR_AGENT_ENABLED, PARTNER_SPOR_ENABLED, REPURCHASE_SIGNAL_ENABLED, SYSTEMSKIFTE_ENABLED, TILBUDSSKRIVER_ENABLED, TRIAGE_ASSESS_ENABLED, TYPESAFE_API_KEY, WEB_PUSH_PRIVATE_KEY, WEB_PUSH_PUBLIC_KEY, WEB_PUSH_SUBJECT.
- I railway.ts, men ikke satt på tjenesten (1): **SCORING_LOOKALIKE**. Lookalike-scoringen fra Horizon er derfor av i prod. Det kan være meningen, men det bør avklares med Tintun.

**crm:** 29 på tjenesten, 6 i railway.ts.
- Mangler i railway.ts (23): ANTHROPIC_API_KEY, AWARDS_DEDUP_APPLY, AWARDS_HISTORY_MAX_PER_RUN, AWARDS_INCLUDE_HISTORY, COMPETITION_AGENT_ENABLED, CONTACT_FORM_SECRET, DOKUMENTARKIV_ENABLED, KJOPERRESEARCH_ENABLED, KRAVAGENT_ENABLED, LEARNING_REPORT_ENABLED, LLM_DAILY_CAP_USD_RESEARCH_BUYER, LLM_MODEL, LLM_MODEL_EXTRACT_THRESHOLD, MONITOR_AGENT_ENABLED, PARTNER_SPOR_ENABLED, REPURCHASE_SIGNAL_ENABLED, SYSTEMSKIFTE_ENABLED, TILBUDSSKRIVER_ENABLED, TYPESAFE_API_KEY, WEB_PUSH_PRIVATE_KEY, WEB_PUSH_PUBLIC_KEY, WEB_PUSH_SUBJECT, WHATSAPP_VERIFY_TOKEN.
- I railway.ts, men ikke på tjenesten: ingen.

Railway-ID-er: prosjekt `anbud` 2675f463-91bf-4a31-94b9-e9978e73de4c, worker d12ea033-efda-49e8-b8ae-6f3c1ff8b5b2, crm 97be535c-8fd4-4b65-9b85-4115ceffa09f, miljø production f7a4c942-e81e-47d5-8e85-53b6a72b19cb.
