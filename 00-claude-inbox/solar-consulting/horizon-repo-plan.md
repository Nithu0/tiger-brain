# Plan: Horizon (projects/anbud) i eget repo `Solar-Consulting/horizon`

tools-1, 2026-10-25. **Bare plan, ingenting er utført.** Kilde: `Nithu0/Solar-Consulting` main `f6995ec`, lest read-only.
FACT = målt i repoet eller API-et nå. ASSUMPTION = ikke verifisert. UNKNOWN = må avklares.

## 1. Utgangspunkt (FACT)

- **Historikk:** 245 av 358 commits på main rører `projects/anbud`, alle som squash-merger med «(#NNN)» i meldingen. Pakken er 45,5 MiB. Det er **ingen åpne anbud-PR-er** (bare #323, som er website).
- **Railway** (`.railway/railway.ts`): `crm` og `worker` bygger samme Dockerfile fra `github("Nithu0/Solar-Consulting", { branch: "main", rootDirectory: "projects/anbud/crm" })` med `watchPatterns: ["/projects/anbud/crm/**"]`. `migrate-or-die` ligger i image-et (Dockerfile CMD). Worker skal ha nøyaktig 1 replika.
- **Vercel** (`anbud-veldora`): `git.deploymentEnabled: false`. Deploy skjer fra `deploy.yml` med `vercel deploy --prod` fra repo-roten, og prosjektets `rootDirectory = projects/anbud/dashboard` er satt i Vercel. Samme workflow deployer også `website` (`veldora-web`).
- **Actions:** `anbud.yml` (ci for crm og dashboard, migrasjonssnapshot, royktest, e2e, schemas, nattlig cron 02:15Z), `auto-merge.yml` (har en egen anbud-port på stien `projects/anbud/`), `deploy.yml`, `guard-main.yml`, `validate.yml` og `.github/scripts/test-expected-checks.py`.
- **Secrets i repoet:** `ANTHROPIC_API_KEY` (royktest trenger den, ellers hopper 11 agent-tasks over seg selv), `VERCEL_TOKEN`, `LINEAR_API_KEY` og `SLACK_BOT_TOKEN`. **Variabler:** `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID_ANBUD_VELDORA`, `VERCEL_PROJECT_ID_VELDORA_WEB`, `LINEAR_TEAM_KEY` og `SLACK_DEFAULT_CHANNEL`. Railway-hemmelighetene ligger på Railway og påvirkes ikke.
- **CODEOWNERS:** finnes ikke. Branch protection og rulesets gir **403** (privat repo på gratisplan), så ingen regel håndheves i dag. `guard-main` er bare et revisjonsspor.
- **Koblinger på tvers som må kuttes:**
  1. `data/legal/{kommentar-regler,terskelverdier}.json` er kanoniske, og kopier ligger i `crm/src/config/`. `scripts/validate.mjs` (MIRRORS) sjekker at de er like.
  2. `crm/.../taxonomyMap.test.ts` leser `scripts/taxonomy-map.mjs` og `data/schemas/qualification-taxonomy-map.json` fra repo-roten.
  3. `scripts/ship.sh` har egne crm- og dashbord-grener.
  4. `website/lib/contact-crm.ts` snakker bare HTTP med CRM-en, så den er uberørt.

## 2. Git-historikk: `git filter-repo`, ikke subtree split

`subtree split` tar bare én mappe. Vi trenger også `.railway/` og arbeidsflyten, og vil flate ut stiene. Anbefaling:

```
git clone --no-local <Solar-Consulting> horizon-import && cd horizon-import
git filter-repo \
  --path projects/anbud/ --path .railway/ --path .github/workflows/anbud.yml \
  --path data/legal/kommentar-regler.json --path data/legal/terskelverdier.json \
  --path data/schemas/qualification-taxonomy-map.json --path scripts/taxonomy-map.mjs \
  --path-rename projects/anbud/: \
  --path-rename data/legal/:legal/ \
  --message-callback 're.sub(rb"\(#(\d+)\)", rb"(Nithu0/Solar-Consulting#\1)", message)'
```

- Resultat i roten av `horizon`: `crm/`, `dashboard/`, `docs/`, `scripts/`, `team/`, `CLAUDE.md`, `ARCHITECTURE.md`, `.railway/` og `legal/`.
- `--message-callback` gjør at «(#123)» peker til den gamle PR-en, ikke til en tilfeldig PR i det nye repoet.
- **Bevis på at koden er identisk:** `git rev-parse <ny-sha>:crm` skal være lik `git rev-parse f6995ec:projects/anbud/crm`, og tilsvarende for `dashboard`. Er tre-hashene like, er det samme kode og samme migreringer.
- Etter import følger én commit med stiendringer: workflow-stier, `railway.ts` (`rootDirectory: "crm"`, `watchPatterns: ["/crm/**"]`), taxonomy-testen (`scripts/` og `legal/`-stier lokalt), og at MIRRORS-sjekken flyttes inn i horizon (`legal/*.json` == `crm/src/config/*.json`).

## 3. Railway (crm + worker)

- **Krav (UNKNOWN):** Railways GitHub-app må være installert i org `Solar-Consulting` med tilgang til `horizon`. Det krever org-eier.
- **Bytt kilde** i Railway (dashbord eller CLI, per tjeneste): repo `Solar-Consulting/horizon`, branch `main`, rotmappe `crm`, watch pattern `/crm/**`. Byttet alene gir ingen ny deploy (ASSUMPTION, verifiseres på `worker` først). Den gamle deployen fortsetter å kjøre.
- **Ikke kjør `config apply`** under flyttingen. `railway.ts` lister ikke alle env-variablene som er satt (for eksempel `KJOPERRESEARCH_ENABLED`, `LLM_DAILY_CAP_USD_RESEARCH_BUYER`, `PARTNER_SPOR_ENABLED`, `COMPETITION_AGENT_ENABLED`, `KRAVAGENT_ENABLED`). Om `apply` fjerner variabler som ikke er listet, er UNKNOWN. IaC-fila rettes og planlegges (`config plan`) i en egen runde etterpå.
- **Første deploy fra horizon:** manuell redeploy av samme kode. `migrate-or-die` er da en no-op, siden migreringene er identiske (tre-hash). Healthcheck `/api/health` porter `crm`. Worker drenerer i 100 s, og det er aldri to replikaer.
- **Verifiser:** begge tjenestene har SUCCESS på horizon-SHA-en, `/api/health` svarer 200, og det kommer en ny `agent_runs`-rad fra worker innen neste sveip (read-only SQL).

## 4. Vercel (dashbordet)

- Endre `anbud-veldora` sin `rootDirectory` fra `projects/anbud/dashboard` til `dashboard`. Kjør så `deploy.yml` i horizon (`workflow_dispatch`).
- **Samtidig**, i samme vindu: fjern raden `anbud-veldora` fra matrisen i Solar-Consulting sin `deploy.yml`. Ellers bygger den gamle workflowen med feil rot ved neste push.
- Horizon trenger secret `VERCEL_TOKEN` og variablene `VERCEL_ORG_ID` og `VERCEL_PROJECT_ID_ANBUD_VELDORA`. Bare navnene står her; operatøren setter verdiene.
- **Rollback:** i Vercel, «Promote» forrige produksjonsdeploy (umiddelbart), og sett `rootDirectory` tilbake.

## 5. GitHub Actions i horizon

- **`ci.yml`** (fra `anbud.yml`): stier `crm/**`, `dashboard/**` og `.github/workflows/**`. Jobbene og nattlig cron (02:15Z) er de samme.
- **`auto-merge.yml`:** anbud-porten på sti fjernes, fordi hele repoet nå er anbud, og lista med obligatoriske checks justeres. `test-expected-checks.py` tas med.
- **`deploy.yml`:** bare dashbord-jobben.
- **Secrets og variabler i horizon:** `ANTHROPIC_API_KEY`, `VERCEL_TOKEN`, `VERCEL_ORG_ID` og `VERCEL_PROJECT_ID_ANBUD_VELDORA`. Slack og Linear trengs ikke.
- **UNKNOWN:** hvilken plan org `Solar-Consulting` har, og dermed Actions-minutter for private repoer. Med gratisplan er det 2 000 min/mnd og ingen branch protection.

## 6. CODEOWNERS og regler

- Foreslått `CODEOWNERS` i horizon: `crm/src/migrations/**` og `legal/**` → operatøren, og `dashboard/**` → Tintun. Merk at på privat gratisplan håndheves verken CODEOWNERS eller branch protection. Da er de veiledende. Håndheving krever Team-plan (UNKNOWN, operatørens valg).
- Regelen om én migrerings-PR om gangen (`CLAUDE.md` §2) følger med uendret.

## 7. Hva blir igjen i Solar-Consulting

- `website`, `automation`, `data/sources` og `data/schemas` (unntatt taxonomy-kartet, som horizon får en kopi av), `legal/procurement`, strategi og beslutninger.
- **Opprydnings-PR** (etter verifisert overgang):
  - Slett `anbud.yml`, anbud-porten i `auto-merge.yml`, anbud-raden i `deploy.yml`, MIRRORS i `validate.mjs` og crm/dash-grenene i `ship.sh`.
  - Erstatt `projects/anbud/` med en README-stub som peker til `Solar-Consulting/horizon`.
  - `data/legal/README.md` peker til `horizon/legal/` som kanonisk.
- Den gamle `projects/anbud`-mappa beholdes uendret og frosset i **14 dager** for rollback. Selve slettingen er operatørens beslutning.

## 8. Rekkefølge (null nedetid) og rollback

| # | Steg | Påvirker prod? | Rollback |
|---|---|---|---|
| 0 | Operatøren oppretter et tomt, privat `Solar-Consulting/horizon`, installerer Railways og Vercels GitHub-app på org, og setter secrets og variabler | Nei | – |
| 1 | Prøvekjøring: `filter-repo`, push til gren `import`, sjekk tre-hashene, CI grønn i horizon | Nei | Slett grenen |
| 2 | Frys anbud på firm-bus (ingen merges i `projects/anbud`, varslet frys ~1 t) | Nei | Opphev frysen |
| 3 | Endelig `filter-repo` fra frosset SHA → `horizon/main`, så stiendrings-commit og CI grønn | Nei | – |
| 4 | Railway `worker`: bytt kilde og redeploy, verifiser én agent-kjøring | Kort drenering (100 s), jobbene ligger i kø | Kilde tilbake til `Nithu0/Solar-Consulting` + `projects/anbud/crm`, eller redeploy forrige deploy i Railway |
| 5 | Railway `crm`: samme, healthcheck-portet | Nei (gammel instans tjener til ny er frisk) | Som 4 |
| 6 | Vercel: `rootDirectory` → `dashboard`, deploy fra horizon, fjern anbud-raden i gammel `deploy.yml` | Nei | Promote forrige deploy og sett rot tilbake |
| 7 | Slå på auto-merge og nattlig cron i horizon, slett `anbud.yml` i Solar-Consulting | Nei | Gjenopprett fila (den ligger i git) |
| 8 | Opphev frysen. Firmaet flytter worktrees, `CLAUDE.md`-stier, minne, baseline-skript og command-center sitt prosjektregister (`packages/shared/src/projects.ts`) | Nei | – |
| 9 | Etter 14 dager: slett frosset `projects/anbud` (operatør-gated) | Nei | Git-historikken beholder den |

Total tid er anslått til ~3 t forberedelse og ~1 t frys (ASSUMPTION).

## 9. Avklaringer før start (til orchestrator-1 eller operatøren)

1. Org-plan for `Solar-Consulting`: gratis eller Team? Det avgjør Actions-minutter og om regler kan håndheves.
2. Hvem installerer Railways og Vercels GitHub-app på org (krever org-eier)?
3. Flate stier (`crm/`, `dashboard/`, anbefalt) eller beholde `projects/anbud/`? Flate stier krever stiendrings-commiten over.
4. Skal kanonisk `legal/` (juristens regelfiler) flytte til horizon (anbefalt, bare CRM bruker dem i kode), eller bli igjen med en kopi-sjekk på tvers av repoer?
