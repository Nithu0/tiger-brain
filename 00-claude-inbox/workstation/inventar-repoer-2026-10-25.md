# Inventar: repoer og worktrees (workstation-migrering)

Generert 2026-10-25, kun lesing (ingen fetch/push/commit). Remote-URL fra `git remote get-url origin`.

Forbehold: "unpushed" = commits på lokale branches som ikke er nådd av noen remote-tracking-ref (`git log --branches --not --remotes`). Uten fersk fetch kan remote-refs være utdaterte, og squash-mergede branches teller som unpushed selv om innholdet er på GitHub. Verifiser med `git fetch` + `gh pr list --state merged` før du kasserer noe.

## Sammendrag
- Hoved-repoer: 28 (inkl. /home/nithu/code selv og Brain), worktrees: 100
- Uten remote: se egen seksjon
- .env*-filer (ekskl. .env.example): 81

## Hoved-repoer

| Path | Remote | Branch | Uncommitted | Unpushed (totalt) | Branches med unpushed | Stash |
|---|---|---|---|---|---|---|
| /home/nithu/code | **INGEN REMOTE** | (detached) | 0 | 0 |  | 0 |
| /home/nithu/Obsidian/Brain | git@github.com:Nithu0/tiger-brain.git | main | 390 | 0 |  | 0 |
| /home/nithu/code/AS | **INGEN REMOTE** | main | 17 | 17 | main(17)  | 0 |
| /home/nithu/code/Master-oppgave | ssh://git@ssh.github.com:443/Nithu0/Master-oppgave.git | main | 0 | 2 | backup-humanizer-72bba0a(2)  | 0 |
| /home/nithu/code/Master-oppgave/battery-electrolyte-predictor | git@github.com:Nithu0/battery-electrolyte-predictor.git | node-migration-battery | 1 | 0 |  | 0 |
| /home/nithu/code/Personlig | https://github.com/Nithu0/Personlig.git | node-migration-personlig | 6 | 0 |  | 0 |
| /home/nithu/code/Renseri | https://github.com/Nithu0/Renseri.git | main | 0 | 2 | chore/main-guard(1) fix/ship-auto-merge-guard(1)  | 0 |
| /home/nithu/code/Søking fulltid | **INGEN REMOTE** | feat/soknadsagent | 0 | 8 | feat/soknadsagent(8) main(4) node-migration-soking(6)  | 0 |
| /home/nithu/code/Terra | https://github.com/Solar-Consulting/Terra.git | main | 0 | 1 | org-flytting(1)  | 0 |
| /home/nithu/code/Terra/aurora | https://github.com/Solar-Consulting/aurora.git | main | 0 | 0 |  | 0 |
| /home/nithu/code/Terra/nova | https://github.com/Solar-Consulting/nova.git | main | 0 | 0 |  | 0 |
| /home/nithu/code/Terra/solar-consulting | https://github.com/Nithu0/Solar-Consulting.git | main | 0 | 0 |  | 0 |
| /home/nithu/code/Veldora | https://github.com/Nithu0/Veldora.git | feat/secure-age | 7 | 597 | admin-1/adr-terskel-frist(1) admin-1/terskel-frist(4) adr-0017-mote-hovedflate(2) anbud-triage-learning-status(2) anbud/verdi-backfill-job(1) anbud/verdi-ekstraksjon(1) anbud/verdi-promotering(2) b2-konkurransegrunnlag(1) b2-redteam-datasett(4) b23-eval(2) b23-konkurranseagent(6) b32-bands(2) b32-ov ... | 0 |
| /home/nithu/code/_refs/awesome-systematic-trading | https://github.com/wangzhe3224/awesome-systematic-trading.git | master | 0 | 0 |  | 0 |
| /home/nithu/code/_refs/claude-trading-skills | https://github.com/tradermonty/claude-trading-skills.git | main | 0 | 0 |  | 0 |
| /home/nithu/code/_refs/nautilus_trader | https://github.com/nautechsystems/nautilus_trader.git | develop | 0 | 0 |  | 0 |
| /home/nithu/code/_refs/pysystemtrade | https://github.com/pst-group/pysystemtrade.git | develop | 0 | 0 |  | 0 |
| /home/nithu/code/ai-assistent | https://github.com/Nithu0/ai-assistent.git | feat/hle-import-resilience | 25 | 67 | backup/ai-1-pre-rebase-2026-05-21(11) docs/ops-brief-reversi-0608(5) docs/reconcile-2026-06-05(1) docs/t7-doc-reconcile(5) docs/wf-lesson-promo(1) feat/cloud-alerts-v2(1) feat/command-room-backend(1) feat/hle-labels-counterfactual(1) feat/hle-purged-eval(2) feat/hle-strategy-profiler(2) feat/jarvis- ... | 5 |
| /home/nithu/code/aslisten-crm | https://github.com/Nithu0/aslisten-crm.git | feat/jobbko-saksloft | 4 | 2 | feat/facebook-lead-motor(1) worktree-agent-a11017eb2fd82ad50(1)  | 0 |
| /home/nithu/code/call-center-ai-demo | https://github.com/Nithu0/call-center-ai-demo.git | main | 1 | 1 | main(1)  | 0 |
| /home/nithu/code/callcenter.js-mcp | https://github.com/gerkensm/callcenter.js-mcp | main | 2 | 0 |  | 0 |
| /home/nithu/code/command-center | https://github.com/Nithu0/command-center.git | orchestrator-1/omnigent-claude-path | 3 | 13 | code-1/brain-autonomy-systemd(1) code-2/brain-runtime(2) feat/data-1-trade-forensics-ingest(2) feat/muse-engine(3) feat/wf-replenish-8-yt-to-memory(1) fix/git-index-lock(1) merge/firm-v2-to-main(2) tools-1/f2-gates(1)  | 6 |
| /home/nithu/code/grossist-plattform | **INGEN REMOTE** | main | 56 | 2 | main(2)  | 0 |
| /home/nithu/code/leadgen-mvp | https://github.com/Nithu0/leadgen-mvp.git | main | 0 | 0 |  | 0 |
| /home/nithu/code/leadgen-pipeline | **INGEN REMOTE** | main | 0 | 8 | main(8)  | 0 |
| /home/nithu/code/leadgen-platform | **INGEN REMOTE** | main | 0 | 5 | main(5)  | 0 |
| /home/nithu/code/research-os | git@github.com:Nithu0/research-os.git | node-migration-research-os | 5 | 0 |  | 0 |
| /home/nithu/code/vendor/telegram-mcp | https://github.com/chigwell/telegram-mcp | (detached) | 0 | 0 |  | 0 |

## Worktrees gruppert per hoved-repo

### /home/nithu/code/Veldora/.git  (97 worktrees)
Remote: https://github.com/Nithu0/Veldora.git ; delt stash: 0

| Worktree | Branch | Uncommitted |
|---|---|---|
| /home/nithu/code/SC-rename | chore/slack-linear-rename | 0 |
| /home/nithu/code/Veldora-agent0 | infra-1/agent-0-cache-vakt | 0 |
| /home/nithu/code/Veldora-agentstd | learning-1/agentstandard | 0 |
| /home/nithu/code/Veldora-anbud | fix/anbud-sporsmal | 0 |
| /home/nithu/code/Veldora-auto | fix/deploy-vercel-git-metadata | 0 |
| /home/nithu/code/Veldora-b2 | b2-konkurransegrunnlag | 0 |
| /home/nithu/code/Veldora-b23 | b23-eval | 0 |
| /home/nithu/code/Veldora-b23b | b23b-realistisk | 0 |
| /home/nithu/code/Veldora-b23b-t1 | tools-1/b23b-realistisk | 0 |
| /home/nithu/code/Veldora-b2rt | b2-redteam-datasett | 0 |
| /home/nithu/code/Veldora-b32 | (detached) | 0 |
| /home/nithu/code/Veldora-checks | infra-1/auto-merge-verifiser-foer-deploy | 0 |
| /home/nithu/code/Veldora-ci | trading-1/dedup-fiks | 0 |
| /home/nithu/code/Veldora-ci-minutter | orchestrator-1/ci-minutter | 0 |
| /home/nithu/code/Veldora-dok | fix/anbud-dokumentdekning | 0 |
| /home/nithu/code/Veldora-dok-pipe | trading-1/dokument-pipe | 0 |
| /home/nithu/code/Veldora-domene | chore/domene-solarconsulting | 0 |
| /home/nithu/code/Veldora-dps-t1 | tools-1/dps-panel | 0 |
| /home/nithu/code/Veldora-e2e | tools-1/e2e-kgv | 0 |
| /home/nithu/code/Veldora-eformsnb | infra-1/eforms-nob-navn | 0 |
| /home/nithu/code/Veldora-eval2-t1 | tools-1/kjoperresearch-3-resultat | 0 |
| /home/nithu/code/Veldora-frist | admin-1/legal-engine-map | 0 |
| /home/nithu/code/Veldora-gws | feat/anbud-whatsapp | 0 |
| /home/nithu/code/Veldora-hidden-t1 | tools-1/hidden-topics | 0 |
| /home/nithu/code/Veldora-horizon-t1 | feat/horizon-redesign | 0 |
| /home/nithu/code/Veldora-hyyr | learning-1/hyyr-droppet | 0 |
| /home/nithu/code/Veldora-import | (detached) | 5 |
| /home/nithu/code/Veldora-instruks | docs/agent-instruks | 0 |
| /home/nithu/code/Veldora-kjoper | tools-1/kjoperresearch | 0 |
| /home/nithu/code/Veldora-komp | komp-intervju | 0 |
| /home/nithu/code/Veldora-kriterier | infra-1/kriterier-navn-beskrivelse | 0 |
| /home/nithu/code/Veldora-lanes | (detached) | 1 |
| /home/nithu/code/Veldora-lastopp | tools-1/dokumenter-last-opp | 0 |
| /home/nithu/code/Veldora-loopschema | (detached) | 0 |
| /home/nithu/code/Veldora-los | tools-1/dokumentlos | 0 |
| /home/nithu/code/Veldora-meny | sc-meny-lukkbar | 0 |
| /home/nithu/code/Veldora-mote | fix/migrasjon-down | 0 |
| /home/nithu/code/Veldora-nokkelord | learning-1/nokkelord-cv | 0 |
| /home/nithu/code/Veldora-nt | sc-nt-ted-plassholder | 0 |
| /home/nithu/code/Veldora-nullstill | infra-1/history-vinduer-nullstill | 0 |
| /home/nithu/code/Veldora-orch | (detached) | 0 |
| /home/nithu/code/Veldora-partner-t1 | tools-1/partnere-panel | 0 |
| /home/nithu/code/Veldora-pris | sc-07-prismodell | 0 |
| /home/nithu/code/Veldora-prisagent | learning-1/prisagent | 0 |
| /home/nithu/code/Veldora-pubapi | infra-1/doffin-public-api-sok | 0 |
| /home/nithu/code/Veldora-rad | strategy/ai-plattform-rad | 1 |
| /home/nithu/code/Veldora-radar | fix/anbud-solenergi-track-false-positives | 1 |
| /home/nithu/code/Veldora-radar-verdi | anbud/verdi-ekstraksjon | 0 |
| /home/nithu/code/Veldora-redteam | learning-1/redteam-agent | 0 |
| /home/nithu/code/Veldora-requeue | requeue-failed | 0 |
| /home/nithu/code/Veldora-research | research/myhre-kommentar | 1 |
| /home/nithu/code/Veldora-royk2 | infra-1/royk-onboarding | 0 |
| /home/nithu/code/Veldora-ruting | tools-1/model-routing-defaults | 47 |
| /home/nithu/code/Veldora-sc01 | sc-01-historikk | 4 |
| /home/nithu/code/Veldora-sc01b | sc-01b-lesere | 0 |
| /home/nithu/code/Veldora-sc02 | wip/paal-1-natt3 | 3 |
| /home/nithu/code/Veldora-sc03 | sc-03-treningsdata | 2 |
| /home/nithu/code/Veldora-sc03c | sc-03c-queue-learn | 0 |
| /home/nithu/code/Veldora-sc03d | sc-03d-prekvensiell | 0 |
| /home/nithu/code/Veldora-sc04 | sc-04-modell | 0 |
| /home/nithu/code/Veldora-sc04-agenter | (detached) | 0 |
| /home/nithu/code/Veldora-sc04-krav | sc-04-hendelseskjede-maling | 1 |
| /home/nithu/code/Veldora-sc04-lovdata | sc-04-prodjobber | 0 |
| /home/nithu/code/Veldora-sc04-skriver | sc-04-laeringslokke | 0 |
| /home/nithu/code/Veldora-sc05 | sc-05-regelmotor | 0 |
| /home/nithu/code/Veldora-sc06 | sc-06-etter-maling | 0 |
| /home/nithu/code/Veldora-sc06e | sc-06-etter | 0 |
| /home/nithu/code/Veldora-sc07 | sc-07b-avkutting-056 | 0 |
| /home/nithu/code/Veldora-scope | feat/anbud-scope-categories | 1 |
| /home/nithu/code/Veldora-scopes | tre-scopes-tall | 0 |
| /home/nithu/code/Veldora-seed | sc-seed-e2e-admin | 0 |
| /home/nithu/code/Veldora-seedfix | seed-admin-migrate | 0 |
| /home/nithu/code/Veldora-skjul | skjul-skygge | 0 |
| /home/nithu/code/Veldora-smoke | infra-1/royk-egenskaper | 0 |
| /home/nithu/code/Veldora-smoketilbud | tools-1/smoke-tilbud-robust | 0 |
| /home/nithu/code/Veldora-stale | infra-1/stale-vindu-vakt | 0 |
| /home/nithu/code/Veldora-steg1 | infra-1/steg1-rapport | 0 |
| /home/nithu/code/Veldora-team | team-oppgaver | 0 |
| /home/nithu/code/Veldora-tedkrit | infra-1/ted-kriterier | 0 |
| /home/nithu/code/Veldora-tedsort | infra-1/ted-iterasjon-usortert | 0 |
| /home/nithu/code/Veldora-tek | tek-register | 0 |
| /home/nithu/code/Veldora-tek-t1 | tools-1/teknologiregister | 0 |
| /home/nithu/code/Veldora-tek2-t1 | tools-1/teknologi-uten-integrator | 0 |
| /home/nithu/code/Veldora-tek3-t1 | tools-1/teknologi-d-sitat | 0 |
| /home/nithu/code/Veldora-terra | terra-flyttet | 0 |
| /home/nithu/code/Veldora-tools | tools-1/verktoylag | 0 |
| /home/nithu/code/Veldora-triage-a | feat/anbud-triage-data | 0 |
| /home/nithu/code/Veldora-triage-b | feat/anbud-triage-learning | 0 |
| /home/nithu/code/Veldora-triage-c | feat/anbud-triage-veiledning | 0 |
| /home/nithu/code/Veldora-triage-d | feat/anbud-triage-agents | 0 |
| /home/nithu/code/Veldora-triage-e | feat/anbud-triage-integrasjon | 0 |
| /home/nithu/code/Veldora-triage-eval | learning-1/triage-vurderer-eval | 0 |
| /home/nithu/code/Veldora-triage-test-eval | learning-1/triage4-test-eval | 0 |
| /home/nithu/code/Veldora-triage4-eval | learning-1/triage4-eval | 0 |
| /home/nithu/code/Veldora-triagevurd | learning-1/triage-vurderer | 0 |
| /home/nithu/code/Veldora-union | infra-1/union-verify-f4cb3f0 | 0 |
| /home/nithu/code/Veldora-vercel | ops/vercel-ingen-preview | 0 |

### /home/nithu/code/ai-assistent/.git  (2 worktrees)
Remote: https://github.com/Nithu0/ai-assistent.git ; delt stash: 5

| Worktree | Branch | Uncommitted |
|---|---|---|
| /home/nithu/code/.wt/ai-fsc | fix/forensics-summaries-cursor-us | 1 |
| /home/nithu/code/jarvis-wt | feat/jarvis-auto-greeting | 1 |

### /home/nithu/code/command-center/.git  (1 worktrees)
Remote: https://github.com/Nithu0/command-center.git ; delt stash: 6

| Worktree | Branch | Uncommitted |
|---|---|---|
| /home/nithu/code/cc-leakscan | infra-1/leak-scan | 0 |

## Uten remote (kan ikke klones fra GitHub)
- /home/nithu/code (branch (detached), uncommitted 0, unpushed 0)
- /home/nithu/code/AS (branch main, uncommitted 17, unpushed 17)
- /home/nithu/code/Søking fulltid (branch feat/soknadsagent, uncommitted 0, unpushed 8)
- /home/nithu/code/grossist-plattform (branch main, uncommitted 56, unpushed 2)
- /home/nithu/code/leadgen-pipeline (branch main, uncommitted 0, unpushed 8)
- /home/nithu/code/leadgen-platform (branch main, uncommitted 0, unpushed 5)

## Branches med unpushed commits per repo (hoved-repoer)

### Veldora
- admin-1/adr-terskel-frist (1)
- admin-1/terskel-frist (4)
- adr-0017-mote-hovedflate (2)
- anbud-triage-learning-status (2)
- anbud/verdi-backfill-job (1)
- anbud/verdi-ekstraksjon (1)
- anbud/verdi-promotering (2)
- b2-konkurransegrunnlag (1)
- b2-redteam-datasett (4)
- b23-eval (2)
- b23-konkurranseagent (6)
- b32-bands (2)
- b32-overvaker (5)
- backup/feat-anbud-triage-veiledning-abef709 (4)
- chore/dev-flow (5)
- chore/lukk-047 (1)
- chore/rename-solar-consulting (3)
- chore/slack-linear-rename (1)
- docs/agent-instruks (1)
- docs/strategi-plattform (3)
- eval/typesafe (1)
- feat/033-skal-krav-avvik (2)
- feat/034-035-040-feilsjekk-regler (1)
- feat/036-046-prising (2)
- feat/037-041-tilbudskvalitet (2)
- feat/042-043-kvalifikasjon-kontrakt (1)
- feat/044-045-klage (1)
- feat/048-juristvurderinger-i-crm (1)
- feat/ai-jev-vurderinger (4)
- feat/ai-live-hjelper (2)
- feat/ai-ruting-kost (2)
- feat/anbud-autodeploy (1)
- feat/anbud-brief (1)
- feat/anbud-chat (1)
- feat/anbud-crm (3)
- feat/anbud-juristvurderinger (1)
- feat/anbud-kompetanse (1)
- feat/anbud-kvalifikasjon (5)
- feat/anbud-marked (1)
- feat/anbud-mote-trening-live (1)
- feat/anbud-motemodus (2)
- feat/anbud-nyheter (1)
- feat/anbud-prioritet (2)
- feat/anbud-scope-categories (1)
- feat/anbud-tilbud (1)
- feat/anbud-triage-agents (1)
- feat/anbud-triage-data (1)
- feat/anbud-triage-integrasjon (2)
- feat/anbud-triage-learning (1)
- feat/anbud-triage-ui (1)
- feat/anbud-triage-veiledning (4)
- feat/anbud-whatsapp (1)
- feat/anbud-workspace-sync (1)
- feat/auto-innboks (5)
- feat/auto-leveranse (5)
- feat/auto-okonomi (5)
- feat/auto-plattform (5)
- feat/auto-rapport (5)
- feat/auto-salg (5)
- feat/automatisering-plan (1)
- feat/domene-solarconsulting (1)
- feat/ekspertkommentar (2)
- feat/epost-varsler (5)
- feat/horizon-redesign (76)
- feat/intervju-konfig (4)
- feat/jur-assistent (2)
- feat/jur-feilsjekk (6)
- feat/jur-kofa (7)
- feat/klage-innsyn (3)
- feat/kval-avklaring-kilder (2)
- feat/kval-bevisarkiv (3)
- feat/kval-eforms-utlop (3)
- feat/kval-klarhet (6)
- feat/kval-klassifisering (2)
- feat/kval-okonomi (4)
- feat/secure-age (2)
- feat/tilbud-godkjenning (2)
- feat/web-team (3)
- fix/anbud-051-solar-vertical-false-positives (1)
- fix/anbud-brief-ikke-leste-dokumenter (1)
- fix/anbud-calibration-backtest (1)
- fix/anbud-cv-parse (2)
- fix/anbud-dokumentdekning (1)
- fix/anbud-dokumentdekning-pr (1)
- fix/anbud-duplicate-twin-triage (1)
- fix/anbud-eforms-award-criteria-framework (1)
- fix/anbud-jurist-kvittering (1)
- fix/anbud-kommentar-feillogging (1)
- fix/anbud-kommentar-vurder-konvolutt (1)
- fix/anbud-login-mobil-touch (1)
- fix/anbud-market-prior-calibration (1)
- fix/anbud-noise-keywords-soft-filter (1)
- fix/anbud-rfi-notice-type (1)
- fix/anbud-scope-backfill (2)
- fix/anbud-scope-coverage-gaps (1)
- fix/anbud-solenergi-track-false-positives (1)
- fix/anbud-sporsmal (1)
- fix/ci-node-24 (1)
- fix/deploy-timeout (1)
- fix/deploy-vercel-git-metadata (1)
- fix/error-digest-visible (1)
- fix/helper-llm-error-messages (1)
- fix/jur-avkuttet-svar (1)
- fix/jur-eskalering-budsjett (1)
- fix/jur-fjernede-setninger (1)
- fix/jur-sitatsjekk-kalibrering (1)
- fix/jur-synonymer (1)
- fix/migrasjon-down (1)
- fix/secure-dokumentsperre (1)
- fix/vercel-author-block (1)
- infra-1/049-migreringssnapshot (3)
- infra-1/049-snapshot-port (1)
- infra-1/049a-migrering (1)
- infra-1/advisory-markor-anker (1)
- infra-1/agent-0-cache-vakt (6)
- infra-1/agent-0-sloyfe (2)
- infra-1/anbud-vakt-prod-monitor (6)
- infra-1/auto-merge-verifiser-foer-deploy (1)
- infra-1/datapolicy-fail-closed (1)
- infra-1/doffin-public-api-sok (1)
- infra-1/eforms-nob-navn (1)
- infra-1/history-vinduer-nullstill (1)
- infra-1/kriterier-navn-beskrivelse (2)
- infra-1/loop-output-schema (2)
- infra-1/pg-backup-restore (1)
- infra-1/royk-egenskaper (1)
- infra-1/royk-onboarding (1)
- infra-1/stale-vindu-vakt (2)
- infra-1/steg1-rapport (1)
- infra-1/ted-iterasjon-usortert (1)
- infra-1/ted-kriterier (2)
- infra-1/union-verify-f4cb3f0 (1)
- infra-1/vakt-i-repo (1)
- infra-1/want-checks-strukturelt (5)
- infra/royktest-anthropic-key (1)
- issues/050-053-moteoppgaver (1)
- komp-intervju (1)
- learning-1/agentstandard (1)
- learning-1/hyyr-droppet (1)
- learning-1/hyyr-vilkar (1)
- learning-1/nokkelord-cv (2)
- learning-1/prisagent (3)
- learning-1/redteam-agent (2)
- learning-1/triage-baseline (9)
- learning-1/triage-vurderer-eval (1)
- learning-1/triage4-eval (1)
- learning-1/triage4-test-eval (1)
- ops/vercel-ingen-preview (1)
- orchestrator-1/ci-minutter (1)
- pr-123 (1)
- requeue-failed (1)
- research/borg-strategi (1)
- research/myhre-kommentar (1)
- sc-01-historikk (19)
- sc-01b-lesere (1)
- sc-02-brreg-tak (1)
- sc-02-down-fiks (2)
- sc-02-dps-espd (1)
- sc-02-dps-motor (1)
- sc-02-etter-maaling (1)
- sc-02-etter-raaarkiv (1)
- sc-02-eval-natt2 (1)
- sc-02-gjenkjop (1)
- sc-02-historikk-sperre (1)
- sc-02-it-hovedcpv (2)
- sc-02-it-svak-flertall (1)
- sc-02-pre-main-rebase-616d0ed (22)
- sc-02-pre-rebase-a1b0f03 (3)
- sc-02-raaarkiv-awards (2)
- sc-02-radar-passert (1)
- sc-02-reroot (1)
- sc-02-systemskifte-visning (1)
- sc-02-tildelinger (5)
- sc-02-verdi-tak (1)
- sc-03-treningsdata (5)
- sc-03c-queue-learn (1)
- sc-03d-prekvensiell (1)
- sc-04-agenter (5)
- sc-04-driftsvakt (1)
- sc-04-hendelseskjede (1)
- sc-04-hendelseskjede-maling (1)
- sc-04-incumbent-gruppe (1)
- sc-04-kontrakt-24 (3)
- sc-04-kontraktsrekker (1)
- sc-04-kontraktsrekker-resultat (1)
- sc-04-kravagent (3)
- sc-04-kravagent-avstemming (11)
- sc-04-kravagent-dokeval (2)
- sc-04-kravagent-ensidig (2)
- sc-04-kravagent-kobling (9)
- sc-04-kravagent-recall (3)
- sc-04-kravagent-runde2 (3)
- sc-04-kravagent-runde3 (2)
- sc-04-kravagent-side (2)
- sc-04-kunnskapsgraf (1)
- sc-04-laeringslokke (1)
- sc-04-leverandoridentitet (1)
- sc-04-ligatur (1)
- sc-04-lovdata (2)
- sc-04-lovhenv-a (1)
- sc-04-lovhenv-b (1)
- sc-04-migrate-retry (1)
- sc-04-migrate-som-prod (1)
- sc-04-modell (5)
- sc-04-partnerspor (1)
- sc-04-prisagent-prereg (1)
- sc-04-prisagent-v2 (3)
- sc-04-prisagent-v3 (1)
- sc-04-prisagent-v3-resultat (1)
- sc-04-prodjobber (2)
- sc-04-royk-contract (1)
- sc-04-royk-migrert (1)
- sc-04-sakssystem-krav (1)
- sc-04-systemskifte (1)
- sc-04-systemskifte-kilde (1)
- sc-04-systemskifte-resultat (1)
- sc-04-tilbudsskriver (2)
- sc-04-tilbudsskriver-eval (4)
- sc-04-tilbudsskriver-v2 (2)
- sc-04-utrull-filter (2)
- sc-05-regelmotor (9)
- sc-06-dokumenter (4)
- sc-06-etter (1)
- sc-06-etter-maling (1)
- sc-07-tilbud (1)
- sc-07b-avkutting-056 (4)
- sc-meny-lukkbar (2)
- sc-nt-ted-plassholder (1)
- sc-seed-e2e-admin (2)
- seed-admin-migrate (1)
- skjul-skygge (1)
- team-oppgaver (1)
- terra-flyttet (2)
- test/anbud-rute-port-utenfor-app (1)
- tools-1/b23b-realistisk (1)
- tools-1/dokumenter-last-opp (1)
- tools-1/dokumentlos (5)
- tools-1/dps-panel (1)
- tools-1/e2e-kgv (8)
- tools-1/hidden-topics (2)
- tools-1/kjoperresearch (8)
- tools-1/kjoperresearch-3 (2)
- tools-1/kjoperresearch-3-resultat (2)
- tools-1/model-routing-defaults (5)
- tools-1/partnere-panel (1)
- tools-1/smoke-tilbud-robust (1)
- tools-1/teknologi-d-sitat (1)
- tools-1/teknologi-uten-integrator (2)
- tools-1/teknologiregister (3)
- tools-1/verktoylag (2)
- trading-1/crm-ci-royktest (6)
- trading-1/dedup-fiks (1)
- trading-1/dedup-maaling (2)
- trading-1/requalify-isolasjon (1)
- tre-scopes-tall (1)
- wip/data-1-prisagent-v4 (2)
- wip/paal-1-natt3 (1)

### ai-assistent
- backup/ai-1-pre-rebase-2026-05-21 (11)
- docs/ops-brief-reversi-0608 (5)
- docs/reconcile-2026-06-05 (1)
- docs/t7-doc-reconcile (5)
- docs/wf-lesson-promo (1)
- feat/cloud-alerts-v2 (1)
- feat/command-room-backend (1)
- feat/hle-labels-counterfactual (1)
- feat/hle-purged-eval (2)
- feat/hle-strategy-profiler (2)
- feat/jarvis-intents-onboarding (1)
- feat/truth-attribution (1)
- feat/truth-corrupt-stop-flag (2)
- feat/truth-cost-capture (2)
- feat/truth-engine-stamp-prodfix (1)
- feat/truth-freshness-monitor (1)
- feat/twelvedata-sunset-oanda-only (1)
- feat/wf-knowledge-ingest-channel-expand (2)
- feat/wf-knowledge-ingest-llm-distill (3)
- feat/wf-replenish-3-reddit-oauth (3)
- fix/envbool-unify (1)
- fix/flag-parse-followup (1)
- fix/forensics-original-sl-tp1-peak (1)
- fix/forensics-summaries-cursor-us (1)
- fix/health-weekend (1)
- fix/import-size-persistence (1)
- fix/learning-multiplier-observability (1)
- fix/lessons-agent-role (1)
- fix/meta-label-trainer-cadence (1)
- fix/regression-predictor-attribution (5)
- fix/wf-panel-truth (1)
- fix/wf-replenish-1-strategy-states-adx-from-h1 (3)
- fix/wf-replenish-2 (2)
- fix/wf-replenish-2-mr-adx-surface (3)
- fix/wf-replenish-4-strategy-stale-flag (3)
- followup/audit-allowlist-trim (2)
- followup/firm-signal-rejections-endpoint (1)
- followup/health-cycles-per-hour (1)
- followup/peak-price-true-backfill (3)
- followup/strategy-state-publisher-fields (3)
- followup/thesis-score-join (1)
- integrate/t6-t11 (6)
- integration-probe-jarvis (6)
- main (4)
- test/api-routes (1)
- worktree-agent-aee75bbc695278a80 (1)
- worktree-wf_109a4b08-118-2 (2)
- worktree-wf_109a4b08-118-3 (2)

### command-center
- code-1/brain-autonomy-systemd (1)
- code-2/brain-runtime (2)
- feat/data-1-trade-forensics-ingest (2)
- feat/muse-engine (3)
- feat/wf-replenish-8-yt-to-memory (1)
- fix/git-index-lock (1)
- merge/firm-v2-to-main (2)
- tools-1/f2-gates (1)

### aslisten-crm
- feat/facebook-lead-motor (1)
- worktree-agent-a11017eb2fd82ad50 (1)

### Renseri
- chore/main-guard (1)
- fix/ship-auto-merge-guard (1)

### Terra
- org-flytting (1)

### Master-oppgave
- backup-humanizer-72bba0a (2)

### AS
- main (17)

### Søking fulltid
- feat/soknadsagent (8)
- main (4)
- node-migration-soking (6)

### grossist-plattform
- main (2)

### leadgen-pipeline
- main (8)

### leadgen-platform
- main (5)

### call-center-ai-demo
- main (1)

## Ikke-git-mapper under /home/nithu/code
| Mappe | Størrelse (ekskl. node_modules) | Filer | Merknad |
|---|---|---|---|
| _logs | 4K | 0 | tom |
| _scratch | 4K | 0 | tom |
| _refs | 1.1G | 8441 | 4 klonede upstream-repoer (har remote, kan re-klones; hopp over) + CURRENT-STATE.md |
| lavera-site | 3.0M | 18 | statisk site, ingen git: GitHub eller USB |
| refi-doc-agent | 147M | 6347 | ingen git, kode: lag repo eller USB |
| thesis-evaluator | 1.6G | 39668 | ingen git (mest node_modules/venv?): sjekk, kode til GitHub, data via USB |
| vendor | 4.2M | 86 | vendor/telegram-mcp er egen klon (upstream chigwell/telegram-mcp), resten usikkert |
| node_modules (toppnivå) | - | 616 | regenererbar, hopp over |
| (løse filer) | 13 MB | - | litestream-0.5.8-linux-x86_64.deb (re-nedlastbar), 2603.13017v1.pdf, png-skjermbilder, conv.sh, docx.py, CLAUDE.md (CLAUDE.md/CURRENT-STATE.md/.mcp.json tilhører workspace-repoet /home/nithu/code uten remote) |

Merk: /home/nithu/code er selv et git-repo uten remote (detached HEAD, 0 commits unpushed fordi ingen remote); workspace-CLAUDE.md, .mcp.json, .claude/, .codex/, .agents/, .omnigent/ lever kun lokalt: USB eller eget repo.

## PII / kun USB
- /home/nithu/code/AS: regnskap, lønnsslipper, kvitteringer, skattemelding (PII). Lokalt git-repo uten remote, 17 commits kun lokalt. USB kun, ALDRI GitHub. Størrelse ~108 MB (+78 MB .venv som kan droppes).
- /home/nithu/code/Søking fulltid: CV, profil, søknader (PII), repo uten remote (feat/soknadsagent 8, main 4, node-migration-soking 6 unpushed). Inneholder video-CV-er > 50 MB. USB (eller privat repo).
- /home/nithu/code/Personlig: personlig data (mat/trening/helse); har GitHub-remote, men sjekk om privat repo.
- /home/nithu/code/Master-oppgave/.quarantine/referanse-docs (116 MB): sjekk.

## Store untracked/ignorerte data (>50 MB, USB)
- research-os/data/raw/pdfs: 342 MB (research-os/data totalt 360 MB), gitignored litteratur-PDFer.
- Søking fulltid/profil/video cv.mp4 og Søking fulltid/maler/cv/Video_cv.mp4 (>50 MB hver).
- Master-oppgave/.quarantine/referanse-docs: 115 MB.
- Regenererbare (hopp over): alle node_modules, .venv (Master-oppgave/battery-electrolyte-predictor 960 MB, call-center-ai-demo 484 MB, Søking fulltid/agent 253 MB, AS 78 MB), .next-cacher (aslisten-crm 203 MB, Renseri 131 MB, Veldora/website 106 MB m.fl.).
- Veldora/.claude/worktrees: 2.5 GB, 10 agent-worktrees (registrert i git worktree list). Regenererbare hvis branchene er pushet; ellers ta med branch-ene via GitHub.
- ~/Obsidian/Brain: 56 MB + .git 10 MB; remote git@github.com:Nithu0/tiger-brain.git, men **390 uncommitted filer** (Obsidian Git-plugin synker ikke alt). Kjør sync før flytting.
- Utenfor scope men relevant: memory.db (Brain) og systemd user-units ligger utenfor /code, ta separat.

## .env*-filer (kun stier, innhold ikke lest) - USB
Totalt 81 (ekskl. .env.example). Av disse i worktrees (Veldora-*): 9.

```
.wt/ai-fsc/.envrc
AS/.env
Master-oppgave/battery-electrolyte-predictor/.env
Renseri/.env.local
Veldora-anbud/projects/anbud/crm/.env
Veldora-anbud/projects/anbud/dashboard/.env.local
Veldora-lanes/projects/anbud/crm/.env
Veldora-lanes/website/.env.local
Veldora-prisagent/projects/anbud/crm/.env
Veldora-redteam/projects/anbud/crm/.env
Veldora-sc02/projects/anbud/crm/.env
Veldora-sc06/projects/anbud/crm/.env
Veldora-triagevurd/projects/anbud/crm/.env
Veldora/.claude/worktrees/agent-a10ef515441a87b40/projects/anbud/crm/.env
Veldora/.claude/worktrees/agent-a28aedba5f33d2843/projects/anbud/crm/.env
Veldora/.claude/worktrees/agent-a3951620f647d1b4e/projects/anbud/crm/.env
Veldora/.claude/worktrees/agent-a42d9cc56e4d4b49b/projects/anbud/crm/.env
Veldora/.claude/worktrees/agent-a4b1a960ed19898a9/projects/anbud/crm/.env
Veldora/.claude/worktrees/agent-a652aabfcb28c9696/projects/anbud/crm/.env
Veldora/.env
Veldora/website/.env.local
ai-assistent/.claude/worktrees/agent-a10c92af692b04f27/.envrc
ai-assistent/.claude/worktrees/agent-a2a0963de11d3fa00/.envrc
ai-assistent/.claude/worktrees/agent-a2e5311cddb8a7dcb/.envrc
ai-assistent/.claude/worktrees/agent-a33c1ed3d46c91ec3/.envrc
ai-assistent/.claude/worktrees/agent-a6e071eae1e36a6cc/.envrc
ai-assistent/.claude/worktrees/agent-a719bdefc6bb36777/.envrc
ai-assistent/.claude/worktrees/agent-a7852d1d201c565ec/.envrc
ai-assistent/.claude/worktrees/agent-aa4a84dbd7d2415cd/.envrc
ai-assistent/.claude/worktrees/agent-aaea4ea2b67d78958/.envrc
ai-assistent/.claude/worktrees/agent-ab2d90420cb053a55/.envrc
ai-assistent/.claude/worktrees/agent-ab9f2d78b1385a176/.envrc
ai-assistent/.claude/worktrees/agent-abb37aaed6fb14a20/.envrc
ai-assistent/.claude/worktrees/agent-ac570c8919e8c81bc/.envrc
ai-assistent/.claude/worktrees/agent-ac5c5a542a0b095ec/.envrc
ai-assistent/.claude/worktrees/agent-ad7c195da5b0f7f33/.envrc
ai-assistent/.claude/worktrees/agent-ae215245cd8081cbd/.envrc
ai-assistent/.claude/worktrees/agent-ae8aec53dd08ab620/.envrc
ai-assistent/.claude/worktrees/agent-aea6249aa99145936/.envrc
ai-assistent/.claude/worktrees/agent-aeea8373bceb87b92/.envrc
ai-assistent/.claude/worktrees/agent-af6b1faec8b70c20e/.envrc
ai-assistent/.claude/worktrees/agent-afc0ea94fa44eb8c6/.envrc
ai-assistent/.claude/worktrees/ai1-token-alias/.envrc
ai-assistent/.claude/worktrees/dashboard-simplify-pages/.envrc
ai-assistent/.claude/worktrees/design-system-foundation/.envrc
ai-assistent/.claude/worktrees/gpu-meta-label-training/.envrc
ai-assistent/.claude/worktrees/jarvis-voice-guide/.envrc
ai-assistent/.claude/worktrees/p11-gpu-bearing-load/.envrc
ai-assistent/.claude/worktrees/trainer-cadence/.envrc
ai-assistent/.claude/worktrees/wf_109a4b08-118-1/.envrc
ai-assistent/.claude/worktrees/wf_109a4b08-118-2/.envrc
ai-assistent/.claude/worktrees/wf_109a4b08-118-3/.envrc
ai-assistent/.claude/worktrees/wf_288fbbcd-c41-1/.envrc
ai-assistent/.claude/worktrees/wf_396e626f-4a3-4/.envrc
ai-assistent/.claude/worktrees/wf_396e626f-4a3-7/.envrc
ai-assistent/.claude/worktrees/wf_7aa90374-a49-1/.envrc
ai-assistent/.claude/worktrees/wf_9f403c2c-165-1/.envrc
ai-assistent/.claude/worktrees/wf_9f403c2c-165-2/.envrc
ai-assistent/.claude/worktrees/wf_9f403c2c-165-3/.envrc
ai-assistent/.claude/worktrees/wf_9f403c2c-165-4/.envrc
ai-assistent/.claude/worktrees/wf_9f403c2c-165-5/.envrc
ai-assistent/.claude/worktrees/wf_d7625a71-9fb-1/.envrc
ai-assistent/.claude/worktrees/wf_d7625a71-9fb-2/.envrc
ai-assistent/.claude/worktrees/wf_d846ab33-107-3/.envrc
ai-assistent/.env
ai-assistent/.env.local
ai-assistent/.envrc
aslisten-crm/.env.local
call-center-ai-demo/.env
callcenter.js-mcp/.env
cc-leakscan/docs/deploy/node-stack/.env.node.example
command-center/.claude/worktrees/brain-reconcile/docs/deploy/node-stack/.env.node.example
command-center/.claude/worktrees/distill-deadletter/docs/deploy/node-stack/.env.node.example
command-center/.claude/worktrees/f4b/docs/deploy/node-stack/.env.node.example
command-center/.claude/worktrees/telegram-mcp-pilot/docs/deploy/node-stack/.env.node.example
command-center/.env
command-center/.envu
command-center/docs/deploy/node-stack/.env.node.example
jarvis-wt/.envrc
leadgen-mvp/.env
research-os/.env
```
