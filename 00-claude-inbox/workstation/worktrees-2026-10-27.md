# Worktrees uten pane — klassifisering 27.10.2026

_tools-1, oppdrag fra orchestrator-1 08:48Z. Kun lest; ingenting fjernet eller endret. Fetch kjørt mot origin for Veldora, ai-assistent, command-center og aslisten-crm før klassifisering._

**150 worktrees uten pane** (listen har vokst siden 08:46): **(a) 84** kan fjernes · **(b) 5** pushet, ikke merget · **(c) 34** har ulagret arbeid · **hovedcheckouter 27** (kan ikke fjernes, men har ulagret arbeid før PC-flyttingen — se egen tabell).

## Viktigst før PC-flyttingen
- **Brain-repoet (`~/Obsidian/Brain`) har 394 ekte uncommitted, og siste commit er fra 13.07.** Git-synken av Brain ser ut til å ha stått siden juli. Alt i Brain siden da finnes bare på denne maskinen.
- **Hovedcheckouter med commits som ikke er på noen remote:** AS 17 (har ingen remote, krypteres lokalt med vilje), horizon-import 255 (tools-1s filter-repo-import, forventet og kan gjenskapes), Søking fulltid 8, leadgen-pipeline 8, leadgen-platform 5, grossist-plattform 2 (+51 uncommitted), Veldora 2 (+7 uncommitted, feat/secure-age, eier ukjent) og call-center-ai-demo 1.
  - NB: bare Veldora, ai-assistent, command-center og aslisten-crm ble fetchet. For de andre er «ikke på noen remote» målt mot sist kjente remote-refs.
- **(c)-listen:** 19 grener har commits bare lokalt og ingen PR, de fleste i ai-assistent fra mai–juni. Resten er grener der commitene er merget, men usporede filer (SQL-baseline, eval-filer, `.quarantine/`) ligger igjen.

## Slik er det avgjort
- **Innholdet er i main:** enten er HEAD en forfar av `origin/<default>`, eller `git merge-tree origin/<default> HEAD` gir nøyaktig main-treet (fanger squash-merge), eller en merget PR har samme HEAD-sha som worktreet, eller `git cherry` viser at alle commits allerede finnes i main.
- **Ekte uncommitted** teller ikke støy: `node_modules`-symlinker, `.next/`, `*.tsbuildinfo`, `__pycache__`, `.venv/`, `next-env.d.ts`, `.claude/settings.local.json`, `.claude/worktrees/`, `*.log` og den maskingenererte `CURRENT-STATE.md`. Støyen står i klammer.
- **Ulagret i PII-repoer** (AS, Personlig, Søking fulltid, aslisten-crm): bare tall, ikke filnavn. Brain-repoet synkes til GitHub.
- **(a)** = innholdet er i main og ingen ekte uncommitted. **(b)** = alle commits på origin, ingen ekte uncommitted, ikke merget. **(c)** = upushede commits uten PR, eller ekte uncommitted. Står det «squash-merget» i (c), er commitene trygge, og det er bare de usporede filene som er ulagret.
- Fjerning av (a) krever `git worktree remove --force` der det bare er støy (usporede filer stopper ellers kommandoen). Grenene beholdes.

## (c) Ulagret arbeid — ikke rør (34)

| Sti | Repo | Gren | Sist commit | Grunnlag | Ulagret |
|---|---|---|---|---|---|
| `~/code/Veldora-import` | Veldora | `(løs HEAD)` | 2026-10-18 | 5 ekte uncommitted | ?? projects/anbud/crm/eval/strategi-api-dekning-2026-10-19.txt, ?? projects/anbud/crm/scripts/baseline/dps-soknad-krav.sql, ?? projects/anbud/crm/scripts/baseline/intervju-import-sjekk.sql, ?? projects/anbud/crm/scripts/baseline/intervju-import-sjekk2.sql, ?? projects/anbud/crm/scripts/baseline/strategi-api-dekning.sql [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora-radar` | Veldora | `fix/anbud-solenergi-track-false-positives` | 2026-10-12 | commits squash-merget i PR #156; bare 1 ekte uncommitted er ulagret | ?? .quarantine/ |
| `~/code/Veldora-research` | Veldora | `research/myhre-kommentar` | 2026-10-09 | commits squash-merget i PR #104; bare 1 ekte uncommitted er ulagret | ?? CETP-2026-00058.zip |
| `~/code/Veldora-sc01` | Veldora | `sc-01-historikk` | 2026-10-17 | commits squash-merget i PR #187; bare 4 ekte uncommitted er ulagret | ?? projects/anbud/crm/scripts/baseline/backfill-fremdrift.sql, ?? projects/anbud/crm/scripts/baseline/backfill-vindu-status.sql, ?? projects/anbud/crm/scripts/baseline/jobb-varighet.sql, ?? projects/anbud/crm/scripts/baseline/tender-dekning.sql |
| `~/code/Veldora-sc02` | Veldora | `sc-02-reroot-kept` | 2026-10-27 | commits squash-merget i PR #336; bare 3 ekte uncommitted er ulagret | ?? projects/anbud/crm/.sc02-mkuser.mts, ?? projects/anbud/crm/.sc02-runjob.mts, ?? projects/anbud/crm/.sc02-skifte.mts |
| `~/code/Veldora-sc03` | Veldora | `sc-03-treningsdata` | 2026-10-16 | commits squash-merget i PR #173; bare 2 ekte uncommitted er ulagret | ?? projects/anbud/crm/eval/profil-avvik-2026-10-16.txt, ?? projects/anbud/crm/scripts/baseline/profil-avvik.sql [støy: 2 — ?? projects/anbud/crm/node_modules, ?? projects/anbud/dashboard/node_modules] |
| `~/code/Veldora-sc04-krav` | Veldora | `sc-04-slett-persondata` | 2026-10-27 | commits squash-merget i PR #337; bare 2 ekte uncommitted er ulagret | ?? projects/anbud/crm/scripts/baseline/kunnskapsgraf-2026-10-19.sql, ?? projects/anbud/crm/scripts/baseline/persondata-inventar.sql [støy: 1 — ?? projects/anbud/dashboard/node_modules] |
| `~/code/Veldora-scope` | Veldora | `feat/anbud-scope-categories` | 2026-10-12 | commits squash-merget i PR #144; bare 1 ekte uncommitted er ulagret | ?? projects/anbud/crm/.quarantine/ |
| `~/code/Veldora-skjul` | Veldora | `skjul-skygge` | 2026-10-22 | 1 commit(s) bare lokalt, ingen PR | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/.wt/ai-fsc` | ai-assistent | `fix/forensics-summaries-cursor-us` | 2026-09-21 | 1 commit(s) bare lokalt, ingen PR | [støy: 1 — ?? node_modules] |
| `~/code/ai-assistent/.claude/worktrees/agent-a2e5311cddb8a7dcb` | ai-assistent | `docs/t7-doc-reconcile` | 2026-06-08 | 1 commit(s) bare lokalt, ingen PR |  |
| `~/code/ai-assistent/.claude/worktrees/agent-a33c1ed3d46c91ec3` | ai-assistent | `fix/regression-predictor-attribution` | 2026-06-08 | 1 commit(s) bare lokalt, ingen PR |  |
| `~/code/ai-assistent/.claude/worktrees/agent-a7852d1d201c565ec` | ai-assistent | `followup/thesis-score-join` | 2026-05-13 | 1 commit(s) bare lokalt, ingen PR |  |
| `~/code/ai-assistent/.claude/worktrees/agent-ab2d90420cb053a55` | ai-assistent | `feat/book-ai-quickwins-integration` | 2026-06-13 | 10 ekte uncommitted | M. apps/worker/package.json, M. apps/worker/src/firm/analysis-agents.ts, D. apps/worker/src/firm/market-structure/config.ts, D. apps/worker/src/firm/market-structure/index.ts, D. apps/worker/src/firm/market-structure/market-structure-analyzer.ts, D. apps/worker/src/firm/market-structure/market-structure.test.ts, D. apps/worker/src/firm/volume-price/config.ts, D. apps/worker/src/firm/volume-price/index.ts |
| `~/code/ai-assistent/.claude/worktrees/agent-ad7c195da5b0f7f33` | ai-assistent | `feat/admin-m1-backfill` | 2026-06-13 | 9 ekte uncommitted | M. apps/api/package.json, M. apps/api/src/index.ts, D. apps/api/src/routes/firm-structure-vpa.test.ts, D. apps/api/src/routes/firm-structure-vpa.ts, M. apps/api/src/routes/health.test.ts, M. apps/api/src/routes/health.ts, M. apps/dashboard/src/app/live-reasoning/page.tsx, D. apps/dashboard/src/components/StructureVpaPanel.tsx |
| `~/code/ai-assistent/.claude/worktrees/agent-ae215245cd8081cbd` | ai-assistent | `followup/audit-allowlist-trim` | 2026-05-13 | 2 commit(s) bare lokalt, ingen PR |  |
| `~/code/ai-assistent/.claude/worktrees/agent-ae8aec53dd08ab620` | ai-assistent | `followup/strategy-state-publisher-fields` | 2026-05-13 | 3 commit(s) bare lokalt, ingen PR |  |
| `~/code/ai-assistent/.claude/worktrees/agent-af6b1faec8b70c20e` | ai-assistent | `integrate/t6-t11` | 2026-06-08 | 2 commit(s) bare lokalt, ingen PR |  |
| `~/code/ai-assistent/.claude/worktrees/trainer-cadence` | ai-assistent | `fix/meta-label-trainer-cadence` | 2026-08-19 | 1 commit(s) bare lokalt, ingen PR | [støy: 2 — ?? CURRENT-STATE.md, ?? apps/worker/CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/wf_109a4b08-118-2` | ai-assistent | `worktree-wf_109a4b08-118-2` | 2026-06-23 | 2 commit(s) bare lokalt, ingen PR |  |
| `~/code/ai-assistent/.claude/worktrees/wf_288fbbcd-c41-1` | ai-assistent | `feat/truth-layer-integration` | 2026-06-24 | 1 ekte uncommitted | M. apps/worker/src/firm/strategy-execution.test.ts |
| `~/code/ai-assistent/.claude/worktrees/wf_396e626f-4a3-4` | ai-assistent | `docs/wf-lesson-promo` | 2026-06-08 | 1 commit(s) bare lokalt, ingen PR |  |
| `~/code/ai-assistent/.claude/worktrees/wf_396e626f-4a3-7` | ai-assistent | `fix/wf-panel-truth` | 2026-06-08 | 1 commit(s) bare lokalt, ingen PR |  |
| `~/code/ai-assistent/.claude/worktrees/wf_9f403c2c-165-1` | ai-assistent | `feat/truth-cost-capture` | 2026-06-23 | 2 upushede commit(s); 2 ekte uncommitted | M. apps/worker/src/firm/strategy-execution.test.ts, M. apps/worker/src/firm/strategy-execution.ts |
| `~/code/ai-assistent/.claude/worktrees/wf_9f403c2c-165-2` | ai-assistent | `feat/truth-attribution` | 2026-06-23 | 1 commit(s) bare lokalt, ingen PR |  |
| `~/code/ai-assistent/.claude/worktrees/wf_9f403c2c-165-3` | ai-assistent | `feat/truth-engine-stamp-prodfix` | 2026-06-23 | 1 commit(s) bare lokalt, ingen PR |  |
| `~/code/ai-assistent/.claude/worktrees/wf_9f403c2c-165-4` | ai-assistent | `feat/truth-corrupt-stop-flag` | 2026-06-23 | 2 upushede commit(s); 5 ekte uncommitted | M. apps/worker/src/firm/postmortem-r-multiple.test.ts, M. apps/worker/src/firm/postmortem-r-multiple.ts, M. apps/worker/src/firm/postmortem.test.ts, M. apps/worker/src/firm/postmortem.ts, M. scripts/oneshot/2026-06-23_quarantine-corrupt-stops.sql |
| `~/code/ai-assistent/.claude/worktrees/wf_9f403c2c-165-5` | ai-assistent | `feat/truth-freshness-monitor` | 2026-06-23 | 1 commit(s) bare lokalt, ingen PR |  |
| `~/code/ai-assistent/.claude/worktrees/wf_d7625a71-9fb-2` | ai-assistent | `feat/hle-purged-eval` | 2026-06-26 | 2 commit(s) bare lokalt, ingen PR |  |
| `~/code/ai-assistent/.claude/worktrees/wf_d846ab33-107-3` | ai-assistent | `worktree-wf_d846ab33-107-3` | 2026-06-22 | 6 ekte uncommitted | .M apps/dashboard/src/app/globals.css, .M apps/dashboard/src/components/jarvis/AutoUpdateFeed.tsx, .M apps/dashboard/src/components/jarvis/JarvisOrb.tsx, .M apps/dashboard/src/components/jarvis/MissionControlHero.tsx, .M apps/dashboard/tailwind.config.ts, ?? apps/dashboard/src/components/jarvis/motion-utils.ts |
| `~/code/jarvis-wt` | ai-assistent | `feat/jarvis-auto-greeting` | 2026-06-24 | 1 ekte uncommitted | .M .claude/settings.json |
| `~/code/aslisten-crm/.claude/worktrees/agent-a11017eb2fd82ad50` | aslisten-crm | `worktree-agent-a11017eb2fd82ad50` | 2026-10-14 | 1 commit(s) bare lokalt, ingen PR |  |
| `~/.cache/cc-wt-muse` | command-center | `feat/muse-engine` | 2026-09-26 | 3 commit(s) bare lokalt, ingen PR |  |
| `~/.cache/cc-wt-tfingest` | command-center | `feat/data-1-trade-forensics-ingest` | 2026-09-21 | 2 commit(s) bare lokalt, ingen PR |  |

## (b) Pushet, ikke merget — ikke rør (5)

| Sti | Repo | Gren | Sist commit | Grunnlag | Ulagret |
|---|---|---|---|---|---|
| `~/code/Veldora-b23b` | Veldora | `b23b-realistisk` | 2026-10-18 | alle commits ligger på origin, ikke merget | — |
| `~/code/Veldora-pris` | Veldora | `sc-07-prismodell` | 2026-10-17 | alle commits ligger på origin, ikke merget | — |
| `~/code/ai-assistent/.claude/worktrees/agent-aeea8373bceb87b92` | ai-assistent | `(løs HEAD)` | 2026-06-08 | alle commits ligger på origin, ikke merget | — |
| `~/.cache/cc-wt-f4b` | command-center | `f4b-rebase` | 2026-08-19 | alle commits ligger på origin, ikke merget | [støy: 11 — ?? node_modules, ?? packages/book-ingest/node_modules, ?? packages/brain-orchestrator/node_modules, ?? packages/brain-worker/node_modules, ?? packages/github-discovery/node_modules, ?? packages/memory-engine/node_modules] |
| `~/code/command-center/.claude/worktrees/f4b` | command-center | `feat/data-1-f4b` | 2026-08-19 | alle commits ligger på origin, ikke merget | — |

## Hovedcheckouter — kan ikke fjernes; sjekk ulagret før PC-flyttingen (27)

| Sti | Repo | Gren | Sist commit | Grunnlag | Ulagret |
|---|---|---|---|---|---|
| `~/code/AS` | AS | `main` | 2026-07-21 | 17 commit(s) ikke på noen remote; 16 ekte uncommitted | (PII-repo: filnavn utelatt) [støy: 1 — (utelatt)] |
| `~/code/Master-oppgave` | Master-oppgave | `main` | 2026-07-28 | rent | [støy: 1 — .M CURRENT-STATE.md] |
| `~/code/Master-oppgave/battery-electrolyte-predictor` | Master-oppgave/battery-electrolyte-predictor | `node-migration-battery` | 2026-06-03 | rent | [støy: 1 — ?? CURRENT-STATE.md] |
| `~/Obsidian/Brain` | Obsidian/Brain | `main` | 2026-07-13 | 394 ekte uncommitted | .M 00-DASHBOARD.md, .M 00-claude-inbox/nexus/2026-07-03_learning-loop-evidence-base.md, .M 00-firm-bus/feed.md, .M 00-firm-bus/inbox/ai-1.md, .M 00-firm-bus/inbox/ai-2.md, .M 00-firm-bus/inbox/as-1.md, .M 00-firm-bus/inbox/code-1.md, .M 00-firm-bus/inbox/code-2.md |
| `~/code/Personlig` | Personlig | `node-migration-personlig` | 2026-06-03 | 5 ekte uncommitted | (PII-repo: filnavn utelatt) [støy: 1 — (utelatt)] |
| `~/code/Renseri` | Renseri | `main` | 2026-09-25 | rent |  |
| `~/code/Søking fulltid` | Søking fulltid | `feat/soknadsagent` | 2026-07-28 | 8 commit(s) ikke på noen remote |  |
| `~/code/Terra` | Terra | `main` | 2026-10-27 | rent |  |
| `~/code/Terra/aurora` | Terra/aurora | `main` | 2026-10-25 | rent |  |
| `~/code/Terra/nova` | Terra/nova | `main` | 2026-10-24 | rent |  |
| `~/code/Terra/solar-consulting` | Terra/solar-consulting | `main` | 2026-10-24 | rent |  |
| `~/code/Veldora` | Veldora | `feat/secure-age` | 2026-09-15 | 2 commit(s) ikke på noen remote; 7 ekte uncommitted | .M .githooks/pre-commit, .M .gitignore, ?? .claude/, ?? ASSET-INVENTAR.md, ?? market/competitors/, ?? research/2026-09-23-solarconsulting-erverv-og-solmarkedet.md, ?? research/energikartlegging/ |
| `~/code/ai-assistent` | ai-assistent | `main` | 2026-10-27 | 19 ekte uncommitted | ?? .github/manusscript.pdf, ?? .github/manusscript.pdf:Zone.Identifier, ?? .playwright-mcp/, ?? apps/api/src/routes/firm-memory-strategy-states.test.ts, ?? cr-local-boot.jpeg, ?? cr-prod-boot.jpeg, ?? docs/ops/2026-06-08_operator-action-brief.md, ?? docs/strategy/proposals/2026-06-08_remove-reversi.md [støy: 3 — ?? CURRENT-STATE.md, ?? apps/api/CURRENT-STATE.md, ?? apps/worker/CURRENT-STATE.md] |
| `~/code/aslisten-crm` | aslisten-crm | `main` | 2026-10-27 | rent |  |
| `~/code/aurora` | aurora | `main` | 2026-10-25 | rent |  |
| `~/code/call-center-ai-demo` | call-center-ai-demo | `main` | 2026-06-23 | 1 commit(s) ikke på noen remote; 1 ekte uncommitted | ?? project_state.md |
| `~/code/callcenter.js-mcp` | callcenter.js-mcp | `main` | 2025-10-02 | 1 ekte uncommitted | .M .gitignore [støy: 1 — ?? CURRENT-STATE.md] |
| `~/code/command-center` | command-center | `main` | 2026-10-27 | rent |  |
| `~/code/drift` | drift | `main` | 2026-10-27 | rent |  |
| `~/code/grossist-plattform` | grossist-plattform | `main` | 2026-10-11 | 2 commit(s) ikke på noen remote; 51 ekte uncommitted | .M packages/audit/migrations/0001_audit.sql, .M packages/audit/package.json, .M packages/audit/src/hash.ts, .M packages/audit/src/schema.ts, .M packages/audit/tsconfig.json, .M packages/db/migrations/company/0001_init.sql, .M packages/db/src/db.ts, .M packages/db/src/hardening.ts [støy: 25 — .M apps/web/.next/cache/webpack/client-development/1.pack.gz, .M apps/web/.next/cache/webpack/client-development/index.pack.gz, .M apps/web/.next/cache/webpack/client-development/index.pack.gz.old, .M apps/web/.next/cache/webpack/server-development/0.pack.gz, .M apps/web/.next/cache/webpack/server-development/index.pack.gz, .M apps/web/.next/prerender-manifest.json] |
| `~/code/horizon` | horizon | `main` | 2026-10-27 | rent |  |
| `~/code/horizon-import` | horizon-import | `main` | 2026-10-27 | 255 commit(s) ikke på noen remote |  |
| `~/code/leadgen-mvp` | leadgen-mvp | `main` | 2026-06-22 | rent |  |
| `~/code/leadgen-pipeline` | leadgen-pipeline | `main` | 2026-06-26 | 8 commit(s) ikke på noen remote |  |
| `~/code/leadgen-platform` | leadgen-platform | `main` | 2026-06-23 | 5 commit(s) ikke på noen remote |  |
| `~/code/research-os` | research-os | `node-migration-research-os` | 2026-06-03 | 4 ekte uncommitted | ?? data/.research_os.db-litestream/, ?? data/raw/_ocr_backups/, ?? data/research_os.db-shm, ?? data/research_os.db-wal [støy: 1 — ?? CURRENT-STATE.md] |
| `~/code/workstation` | workstation | `main` | 2026-10-27 | rent |  |

## (a) Kan fjernes — venter på ja fra orchestrator-1 (84)

| Sti | Repo | Gren | Sist commit | Grunnlag | Ulagret |
|---|---|---|---|---|---|
| `~/code/SC-rename` | Veldora | `chore/slack-linear-rename` | 2026-10-04 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-adr23` | Veldora | `adr-0023-organisasjon` | 2026-10-26 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-adr24` | Veldora | `adr-0024-sertifikat` | 2026-10-27 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-anbud` | Veldora | `fix/anbud-sporsmal` | 2026-10-04 | squash-merget i PR #52 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-auto` | Veldora | `fix/deploy-vercel-git-metadata` | 2026-10-08 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-b2` | Veldora | `b2-konkurransegrunnlag` | 2026-10-17 | squash-merget i PR #198 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-b23` | Veldora | `b23-eval` | 2026-10-18 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-b2rt` | Veldora | `b2-redteam-datasett` | 2026-10-18 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-b32` | Veldora | `(løs HEAD)` | 2026-10-18 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-dok` | Veldora | `fix/anbud-dokumentdekning` | 2026-10-11 | alle 1 commits finnes allerede i main (git cherry) | — |
| `~/code/Veldora-domene` | Veldora | `chore/domene-solarconsulting` | 2026-09-25 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-e2e` | Veldora | `(løs HEAD)` | 2026-10-25 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-gws` | Veldora | `feat/anbud-whatsapp` | 2026-10-04 | squash-merget i PR #59 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-horizon-t1` | Veldora | `feat/horizon-redesign` | 2026-10-19 | squash-merget i PR #227 (samme HEAD), remote-grenen er slettet | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora-instruks` | Veldora | `docs/agent-instruks` | 2026-10-17 | squash-merget i PR #190 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-komp` | Veldora | `komp-intervju` | 2026-10-17 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora-lanes` | Veldora | `(løs HEAD)` | 2026-10-11 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? CURRENT-STATE.md] |
| `~/code/Veldora-loopschema` | Veldora | `(løs HEAD)` | 2026-10-27 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora-meny` | Veldora | `sc-meny-lukkbar` | 2026-10-17 | squash-merget i PR #192 (samme HEAD), remote-grenen er slettet | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora-mote` | Veldora | `fix/migrasjon-down` | 2026-10-06 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-nt` | Veldora | `sc-nt-ted-plassholder` | 2026-10-16 | squash-merget i PR #180 (samme HEAD), remote-grenen er slettet | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora-orch` | Veldora | `(løs HEAD)` | 2026-10-20 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora-rad` | Veldora | `strategy/ai-plattform-rad` | 2026-10-12 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? CURRENT-STATE.md] |
| `~/code/Veldora-radar-verdi` | Veldora | `anbud/verdi-ekstraksjon` | 2026-10-11 | squash-merget i PR #131 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-requeue` | Veldora | `requeue-failed` | 2026-10-17 | squash-merget i PR #195 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-sc01b` | Veldora | `sc-01b-lesere` | 2026-10-17 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-sc03c` | Veldora | `sc-03c-queue-learn` | 2026-10-16 | squash-merget i PR #177 (samme HEAD), remote-grenen er slettet | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora-sc03d` | Veldora | `sc-03d-prekvensiell` | 2026-10-16 | squash-merget i PR #181 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-sc04` | Veldora | `sc-04-modell` | 2026-10-16 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-sc04-agenter` | Veldora | `(løs HEAD)` | 2026-10-18 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora-sc04-lovdata` | Veldora | `sc-04-prodjobber` | 2026-10-17 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-sc04-skriver` | Veldora | `sc-04-laeringslokke` | 2026-10-18 | squash-merget i PR #252 (samme HEAD), remote-grenen er slettet | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora-sc05` | Veldora | `sc-05-regelmotor` | 2026-10-16 | squash-merget i PR #178 (samme HEAD), remote-grenen er slettet | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora-sc06` | Veldora | `sc-06-etter-maling` | 2026-10-17 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-sc06e` | Veldora | `sc-06-etter` | 2026-10-17 | squash-merget i PR #185 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-sc07` | Veldora | `sc-07b-avkutting-056` | 2026-10-16 | squash-merget i PR #176 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-scopes` | Veldora | `tre-scopes-tall` | 2026-10-17 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-seed` | Veldora | `sc-seed-e2e-admin` | 2026-10-17 | squash-merget i PR #204 (samme HEAD), remote-grenen er slettet | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora-seedfix` | Veldora | `seed-admin-migrate` | 2026-10-17 | squash-merget i PR #215 (samme HEAD), remote-grenen er slettet | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora-team` | Veldora | `team-oppgaver` | 2026-10-21 | squash-merget i PR #304 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-tek` | Veldora | `(løs HEAD)` | 2026-10-27 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-terra` | Veldora | `terra-flyttet` | 2026-10-25 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora-triage-a` | Veldora | `feat/anbud-triage-data` | 2026-10-04 | squash-merget i PR #54 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-triage-b` | Veldora | `feat/anbud-triage-learning` | 2026-10-04 | squash-merget i PR #55 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-triage-c` | Veldora | `feat/anbud-triage-veiledning` | 2026-10-11 | squash-merget i PR #117 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-triage-d` | Veldora | `feat/anbud-triage-agents` | 2026-10-04 | squash-merget i PR #58 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-triage-e` | Veldora | `feat/anbud-triage-integrasjon` | 2026-10-04 | squash-merget i PR #57 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora-vercel` | Veldora | `ops/vercel-ingen-preview` | 2026-10-17 | squash-merget i PR #216 (samme HEAD), remote-grenen er slettet | — |
| `~/code/Veldora/.claude/worktrees/agent-a10ef515441a87b40` | Veldora | `feat/048-juristvurderinger-i-crm` | 2026-10-11 | squash-merget i PR #113 (samme HEAD), remote-grenen er slettet | [støy: 1 — ?? projects/anbud/crm/node_modules] |
| `~/code/Veldora/.claude/worktrees/agent-a1f22cb5ccc04b1e8` | Veldora | `test/anbud-rute-port-utenfor-app` | 2026-10-11 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora/.claude/worktrees/agent-a28aedba5f33d2843` | Veldora | `feat/044-045-klage` | 2026-10-10 | squash-merget i PR #107 (samme HEAD), remote-grenen er slettet | [støy: 2 — ?? projects/anbud/crm/node_modules, ?? projects/anbud/dashboard/node_modules] |
| `~/code/Veldora/.claude/worktrees/agent-a3951620f647d1b4e` | Veldora | `feat/034-035-040-feilsjekk-regler` | 2026-10-11 | squash-merget i PR #111 (samme HEAD), remote-grenen er slettet | [støy: 2 — ?? projects/anbud/crm/node_modules, ?? projects/anbud/dashboard/node_modules] |
| `~/code/Veldora/.claude/worktrees/agent-a42d9cc56e4d4b49b` | Veldora | `feat/036-046-prising` | 2026-10-11 | squash-merget i PR #108 (samme HEAD), remote-grenen er slettet | [støy: 2 — ?? projects/anbud/crm/node_modules, ?? projects/anbud/dashboard/node_modules] |
| `~/code/Veldora/.claude/worktrees/agent-a4b1a960ed19898a9` | Veldora | `feat/042-043-kvalifikasjon-kontrakt` | 2026-10-11 | squash-merget i PR #115 (samme HEAD), remote-grenen er slettet | [støy: 2 — ?? projects/anbud/crm/node_modules, ?? projects/anbud/dashboard/node_modules] |
| `~/code/Veldora/.claude/worktrees/agent-a644363e2c4f31809` | Veldora | `fix/anbud-login-mobil-touch` | 2026-10-11 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/Veldora/.claude/worktrees/agent-a652aabfcb28c9696` | Veldora | `feat/037-041-tilbudskvalitet` | 2026-10-11 | squash-merget i PR #109 (samme HEAD), remote-grenen er slettet | [støy: 2 — ?? projects/anbud/crm/node_modules, ?? projects/anbud/dashboard/node_modules] |
| `~/code/Veldora/.claude/worktrees/agent-a8f75ad6e3e969bba` | Veldora | `feat/anbud-juristvurderinger` | 2026-10-11 | squash-merget i PR #112 (samme HEAD), remote-grenen er slettet | [støy: 1 — ?? projects/anbud/dashboard/node_modules] |
| `~/code/Veldora/.claude/worktrees/agent-ae82ab702d36f0895` | Veldora | `fix/anbud-kommentar-vurder-konvolutt` | 2026-10-11 | squash-merget i PR #114 (samme HEAD), remote-grenen er slettet | — |
| `~/code/.wt/ai-settings` | ai-assistent | `chore/claude-settings-bypass` | 2026-10-27 | innholdet er i main (merge endrer ingenting) | [støy: 2 — ?? apps/worker/node_modules, ?? node_modules] |
| `~/code/ai-assistent/.claude/worktrees/agent-a10c92af692b04f27` | ai-assistent | `feat/learning-rag-local-embeddings` | 2026-07-11 | innholdet er i main (merge endrer ingenting) | [støy: 2 — ?? CURRENT-STATE.md, ?? apps/worker/CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/agent-a2a0963de11d3fa00` | ai-assistent | `feat/llm-cost-meter-and-deep-routing` | 2026-07-13 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/agent-a6e071eae1e36a6cc` | ai-assistent | `feat/hle-dataset-builder` | 2026-07-11 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/agent-a719bdefc6bb36777` | ai-assistent | `feat/strategy-lab-api` | 2026-07-13 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? apps/api/CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/agent-aa4a84dbd7d2415cd` | ai-assistent | `feat/local-llm-gpu-wiring-rebased` | 2026-07-11 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? apps/worker/CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/agent-aaea4ea2b67d78958` | ai-assistent | `followup/health-cycles-per-hour` | 2026-05-13 | alle 1 commits finnes allerede i main (git cherry) | — |
| `~/code/ai-assistent/.claude/worktrees/agent-ab9f2d78b1385a176` | ai-assistent | `feat/heartbeat-cadence-observability` | 2026-07-11 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/agent-abb37aaed6fb14a20` | ai-assistent | `fix/learning-label-correctness` | 2026-07-11 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? apps/worker/CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/agent-ac570c8919e8c81bc` | ai-assistent | `followup/firm-signal-rejections-endpoint` | 2026-05-13 | alle 1 commits finnes allerede i main (git cherry) | — |
| `~/code/ai-assistent/.claude/worktrees/agent-ac5c5a542a0b095ec` | ai-assistent | `feat/tier3-entry-snapshot` | 2026-07-15 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/agent-aea6249aa99145936` | ai-assistent | `fix/thesis-score-scale` | 2026-07-15 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? apps/worker/CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/agent-afc0ea94fa44eb8c6` | ai-assistent | `feat/jarvis-conversational` | 2026-07-13 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/ai1-token-alias` | ai-assistent | `fix/local-llm-token-alias` | 2026-07-13 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/dashboard-simplify-pages` | ai-assistent | `feat/dashboard-simplify-pages` | 2026-07-21 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/ai-assistent/.claude/worktrees/design-system-foundation` | ai-assistent | `feat/design-system-foundation` | 2026-06-21 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/ai-assistent/.claude/worktrees/gpu-meta-label-training` | ai-assistent | `feat/gpu-meta-label-training` | 2026-08-17 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/jarvis-voice-guide` | ai-assistent | `feat/jarvis-voice-guide` | 2026-06-22 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/ai-assistent/.claude/worktrees/p11-gpu-bearing-load` | ai-assistent | `worktree-p11-gpu-bearing-load` | 2026-07-27 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/wf_109a4b08-118-1` | ai-assistent | `(løs HEAD)` | 2026-06-23 | alle 2 commits finnes allerede i main (git cherry) | — |
| `~/code/ai-assistent/.claude/worktrees/wf_109a4b08-118-3` | ai-assistent | `worktree-wf_109a4b08-118-3` | 2026-06-23 | alle 2 commits finnes allerede i main (git cherry) | — |
| `~/code/ai-assistent/.claude/worktrees/wf_7aa90374-a49-1` | ai-assistent | `feat/truth-layer-integration` | 2026-06-24 | innholdet er i main (merge endrer ingenting) | [støy: 1 — ?? CURRENT-STATE.md] |
| `~/code/ai-assistent/.claude/worktrees/wf_d7625a71-9fb-1` | ai-assistent | `feat/hle-strategy-profiler` | 2026-06-26 | alle 2 commits finnes allerede i main (git cherry) | — |
| `~/code/aslisten-crm-drift` | aslisten-crm | `(løs HEAD)` | 2026-10-27 | innholdet er i main (merge endrer ingenting) | — |
| `~/code/aslisten-crm/.claude/worktrees/agent-a56bb5b939055cf34` | aslisten-crm | `revisjon-pr37` | 2026-10-03 | innholdet er i main (merge endrer ingenting) | [støy: 1 — (utelatt)] |
| `~/.cache/cc-wt-evalchk` | command-center | `(løs HEAD)` | 2026-07-27 | innholdet er i main (merge endrer ingenting) | [støy: 11 — ?? node_modules, ?? packages/book-ingest/node_modules, ?? packages/brain-orchestrator/node_modules, ?? packages/brain-worker/node_modules, ?? packages/github-discovery/node_modules, ?? packages/memory-engine/node_modules] |


## Opprydding utført 2026-10-27T09:02Z (ja fra orchestrator-1 08:56Z)

Alle 84 i (a) er fjernet med `git worktree remove --force`. **Alle grener er beholdt.** Rett før fjerning ble hver av dem sjekket på nytt: fortsatt (a) eller samme HEAD som i PR-sjekken, ingen ekte uncommitted, og ikke cwd for noen kjørende prosess. Ingen ble hoppet over, og ingen feilet.

| Fjernet sti | Repo | Gren (beholdt) |
|---|---|---|
| `~/code/SC-rename` | Veldora | `chore/slack-linear-rename` |
| `~/code/Veldora-adr23` | Veldora | `adr-0023-organisasjon` |
| `~/code/Veldora-adr24` | Veldora | `adr-0024-sertifikat` |
| `~/code/Veldora-anbud` | Veldora | `fix/anbud-sporsmal` |
| `~/code/Veldora-auto` | Veldora | `fix/deploy-vercel-git-metadata` |
| `~/code/Veldora-b2` | Veldora | `b2-konkurransegrunnlag` |
| `~/code/Veldora-b23` | Veldora | `b23-eval` |
| `~/code/Veldora-b2rt` | Veldora | `b2-redteam-datasett` |
| `~/code/Veldora-b32` | Veldora | `(løs HEAD)` |
| `~/code/Veldora-dok` | Veldora | `fix/anbud-dokumentdekning` |
| `~/code/Veldora-domene` | Veldora | `chore/domene-solarconsulting` |
| `~/code/Veldora-e2e` | Veldora | `(løs HEAD)` |
| `~/code/Veldora-gws` | Veldora | `feat/anbud-whatsapp` |
| `~/code/Veldora-horizon-t1` | Veldora | `feat/horizon-redesign` |
| `~/code/Veldora-instruks` | Veldora | `docs/agent-instruks` |
| `~/code/Veldora-komp` | Veldora | `komp-intervju` |
| `~/code/Veldora-lanes` | Veldora | `(løs HEAD)` |
| `~/code/Veldora-loopschema` | Veldora | `(løs HEAD)` |
| `~/code/Veldora-meny` | Veldora | `sc-meny-lukkbar` |
| `~/code/Veldora-mote` | Veldora | `fix/migrasjon-down` |
| `~/code/Veldora-nt` | Veldora | `sc-nt-ted-plassholder` |
| `~/code/Veldora-orch` | Veldora | `(løs HEAD)` |
| `~/code/Veldora-rad` | Veldora | `strategy/ai-plattform-rad` |
| `~/code/Veldora-radar-verdi` | Veldora | `anbud/verdi-ekstraksjon` |
| `~/code/Veldora-requeue` | Veldora | `requeue-failed` |
| `~/code/Veldora-sc01b` | Veldora | `sc-01b-lesere` |
| `~/code/Veldora-sc03c` | Veldora | `sc-03c-queue-learn` |
| `~/code/Veldora-sc03d` | Veldora | `sc-03d-prekvensiell` |
| `~/code/Veldora-sc04` | Veldora | `sc-04-modell` |
| `~/code/Veldora-sc04-agenter` | Veldora | `(løs HEAD)` |
| `~/code/Veldora-sc04-lovdata` | Veldora | `sc-04-prodjobber` |
| `~/code/Veldora-sc04-skriver` | Veldora | `sc-04-laeringslokke` |
| `~/code/Veldora-sc05` | Veldora | `sc-05-regelmotor` |
| `~/code/Veldora-sc06` | Veldora | `sc-06-etter-maling` |
| `~/code/Veldora-sc06e` | Veldora | `sc-06-etter` |
| `~/code/Veldora-sc07` | Veldora | `sc-07b-avkutting-056` |
| `~/code/Veldora-scopes` | Veldora | `tre-scopes-tall` |
| `~/code/Veldora-seed` | Veldora | `sc-seed-e2e-admin` |
| `~/code/Veldora-seedfix` | Veldora | `seed-admin-migrate` |
| `~/code/Veldora-team` | Veldora | `team-oppgaver` |
| `~/code/Veldora-tek` | Veldora | `(løs HEAD)` |
| `~/code/Veldora-terra` | Veldora | `terra-flyttet` |
| `~/code/Veldora-triage-a` | Veldora | `feat/anbud-triage-data` |
| `~/code/Veldora-triage-b` | Veldora | `feat/anbud-triage-learning` |
| `~/code/Veldora-triage-c` | Veldora | `feat/anbud-triage-veiledning` |
| `~/code/Veldora-triage-d` | Veldora | `feat/anbud-triage-agents` |
| `~/code/Veldora-triage-e` | Veldora | `feat/anbud-triage-integrasjon` |
| `~/code/Veldora-vercel` | Veldora | `ops/vercel-ingen-preview` |
| `~/code/Veldora/.claude/worktrees/agent-a10ef515441a87b40` | Veldora | `feat/048-juristvurderinger-i-crm` |
| `~/code/Veldora/.claude/worktrees/agent-a1f22cb5ccc04b1e8` | Veldora | `test/anbud-rute-port-utenfor-app` |
| `~/code/Veldora/.claude/worktrees/agent-a28aedba5f33d2843` | Veldora | `feat/044-045-klage` |
| `~/code/Veldora/.claude/worktrees/agent-a3951620f647d1b4e` | Veldora | `feat/034-035-040-feilsjekk-regler` |
| `~/code/Veldora/.claude/worktrees/agent-a42d9cc56e4d4b49b` | Veldora | `feat/036-046-prising` |
| `~/code/Veldora/.claude/worktrees/agent-a4b1a960ed19898a9` | Veldora | `feat/042-043-kvalifikasjon-kontrakt` |
| `~/code/Veldora/.claude/worktrees/agent-a644363e2c4f31809` | Veldora | `fix/anbud-login-mobil-touch` |
| `~/code/Veldora/.claude/worktrees/agent-a652aabfcb28c9696` | Veldora | `feat/037-041-tilbudskvalitet` |
| `~/code/Veldora/.claude/worktrees/agent-a8f75ad6e3e969bba` | Veldora | `feat/anbud-juristvurderinger` |
| `~/code/Veldora/.claude/worktrees/agent-ae82ab702d36f0895` | Veldora | `fix/anbud-kommentar-vurder-konvolutt` |
| `~/code/.wt/ai-settings` | ai-assistent | `chore/claude-settings-bypass` |
| `~/code/ai-assistent/.claude/worktrees/agent-a10c92af692b04f27` | ai-assistent | `feat/learning-rag-local-embeddings` |
| `~/code/ai-assistent/.claude/worktrees/agent-a2a0963de11d3fa00` | ai-assistent | `feat/llm-cost-meter-and-deep-routing` |
| `~/code/ai-assistent/.claude/worktrees/agent-a6e071eae1e36a6cc` | ai-assistent | `feat/hle-dataset-builder` |
| `~/code/ai-assistent/.claude/worktrees/agent-a719bdefc6bb36777` | ai-assistent | `feat/strategy-lab-api` |
| `~/code/ai-assistent/.claude/worktrees/agent-aa4a84dbd7d2415cd` | ai-assistent | `feat/local-llm-gpu-wiring-rebased` |
| `~/code/ai-assistent/.claude/worktrees/agent-aaea4ea2b67d78958` | ai-assistent | `followup/health-cycles-per-hour` |
| `~/code/ai-assistent/.claude/worktrees/agent-ab9f2d78b1385a176` | ai-assistent | `feat/heartbeat-cadence-observability` |
| `~/code/ai-assistent/.claude/worktrees/agent-abb37aaed6fb14a20` | ai-assistent | `fix/learning-label-correctness` |
| `~/code/ai-assistent/.claude/worktrees/agent-ac570c8919e8c81bc` | ai-assistent | `followup/firm-signal-rejections-endpoint` |
| `~/code/ai-assistent/.claude/worktrees/agent-ac5c5a542a0b095ec` | ai-assistent | `feat/tier3-entry-snapshot` |
| `~/code/ai-assistent/.claude/worktrees/agent-aea6249aa99145936` | ai-assistent | `fix/thesis-score-scale` |
| `~/code/ai-assistent/.claude/worktrees/agent-afc0ea94fa44eb8c6` | ai-assistent | `feat/jarvis-conversational` |
| `~/code/ai-assistent/.claude/worktrees/ai1-token-alias` | ai-assistent | `fix/local-llm-token-alias` |
| `~/code/ai-assistent/.claude/worktrees/dashboard-simplify-pages` | ai-assistent | `feat/dashboard-simplify-pages` |
| `~/code/ai-assistent/.claude/worktrees/design-system-foundation` | ai-assistent | `feat/design-system-foundation` |
| `~/code/ai-assistent/.claude/worktrees/gpu-meta-label-training` | ai-assistent | `feat/gpu-meta-label-training` |
| `~/code/ai-assistent/.claude/worktrees/jarvis-voice-guide` | ai-assistent | `feat/jarvis-voice-guide` |
| `~/code/ai-assistent/.claude/worktrees/p11-gpu-bearing-load` | ai-assistent | `worktree-p11-gpu-bearing-load` |
| `~/code/ai-assistent/.claude/worktrees/wf_109a4b08-118-1` | ai-assistent | `(løs HEAD)` |
| `~/code/ai-assistent/.claude/worktrees/wf_109a4b08-118-3` | ai-assistent | `worktree-wf_109a4b08-118-3` |
| `~/code/ai-assistent/.claude/worktrees/wf_7aa90374-a49-1` | ai-assistent | `feat/truth-layer-integration` |
| `~/code/ai-assistent/.claude/worktrees/wf_d7625a71-9fb-1` | ai-assistent | `feat/hle-strategy-profiler` |
| `~/code/aslisten-crm-drift` | aslisten-crm | `(løs HEAD)` |
| `~/code/aslisten-crm/.claude/worktrees/agent-a56bb5b939055cf34` | aslisten-crm | `revisjon-pr37` |
| `~/.cache/cc-wt-evalchk` | command-center | `(løs HEAD)` |

## Repoer uten remote og lokale commits, sikret 2026-10-27T09:07Z (oppdrag fra orchestrator-1 09:05Z)

| Repo | Hva er gjort | GitHub | Ikke sendt (ligger bare lokalt + USB-backup) |
|---|---|---|---|
| grossist-plattform | Remote lagt til. 2 lokale commits + WIP (51 endringer) pushet som `tools-1/lokal-arbeid`. `main` = første commit. 94,6 MB `.next/`/tsbuildinfo filtrert ut før første push. | PR #1, ikke merget (operatørens) | Byggeartefakter. Ufiltrert lokal historikk på taggen `backup/lokal-main-2026-10-27`. |
| call-center-ai-demo | Den lokale commiten 551f852 pushet som `tools-1/elevenlabs-convai`. | PR #1, ikke merget | `project_state.md` (usporet, ikke rørt). Lokal main er fortsatt 1 foran origin/main til PR-en er merget. |
| leadgen-pipeline | Privat repo opprettet, remote lagt til, main pushet (8 commits). | Nithu0/leadgen-pipeline (privat) | `input/`, `data/`, `output/` (gitignored: ekte skattelister, brreg-cache, resultater). |
| leadgen-platform | Privat repo opprettet. Pushet fra en filtrert klone (5 commits) **uten** `packages/connectors/src/enrich/sources/n1881.test.ts`. | Nithu0/leadgen-platform (privat) | **n1881.test.ts (tvilstilfelle):** et 1881-HTML-fixture «verifisert mot live DOM» med telefonnumre (bl.a. 906 56 634, 55 18 88 88) og 1881-oppførings-ID-er som kan være ekte. Navn og adresser er plassholdere. I tillegg `leadgen.db*` og `.verify/` (gitignored). |
| Søking fulltid, AS | Ikke rørt (bare USB, etter beskjed). | — | Alt |

**Skann** (hele historikken, alle blobs; verdier ble aldri skrevet ut):
- **Hemmeligheter:** ingen ekte. Treffene var dummy-passord i tester, et syntetisk fixture, public ElevenLabs-agent-id og «sk-reserv…» (ord).
- **Persondata:** sample-CSV-ene er syntetiske (generiske navn, oppdiktede orgnr 912345678/923456789/934567890). NB: én historisk versjon av `input/skatteliste_sample.csv` og `docs/eksempel-input.csv` i leadgen-pipeline kobler oppdiktede navn og formue til ekte selskaper (Ferd AS, Aker ASA) med rolle «Eier/styreleder». Det er ingen ekte person, men det er verdt å vite.
- E-post og telefon i `pipeline.test.ts` og `contact.test.ts` er åpenbare testverdier (a@b.no, 412 34 567, 911 22 333, 900 00 000).

**Lokalt vs GitHub for leadgen-platform:** lokal historikk har n1881.test.ts, GitHub-kopien har den ikke. Det gir ulike SHA-er, så den lokale checkouten har *ikke* fått remote. Lokal er kilden, og backup-local tar hele repoet (står i NO_REMOTE_REPOS). leadgen-pipeline har fått remote og følger origin/main.

**backup-local NO_REMOTE_REPOS** inneholder fortsatt grossist-plattform, leadgen-pipeline og leadgen-platform, så den ignorerte dataen følger med på USB selv om repoene nå har remote. Den nevner også `lavera-site` og `refi-doc-agent`, som ikke finnes under ~/code på denne maskinen.
