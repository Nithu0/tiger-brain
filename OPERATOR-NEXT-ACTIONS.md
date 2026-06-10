---
title: OPERATOR NEXT ACTIONS — post 60-agent sprint
date: 2026-05-25
status: live (updated as actions complete)
purpose: Prioritized + time-estimated checklist of what operator does next
related:
  - "[[00-CHEAT-SHEET]]"
  - "[[Runbook-Brain-Preflight-Checklist]]"
  - "[[2026-05-25-brain-upgrade-plan]]"
tags: [operator, checklist, next-actions]
---

# OPERATOR NEXT ACTIONS

> 60 sub-agenter har levert (30 A/B/C + D/E fase). Her er hva DU bør gjøre nå, prioritert + tidsestimert. Mark done with `- [x]`; file auto-syncs til tiger-brain så Karri ser progress.

## ⭐ SPRINT 1 SHIPPED 2026-05-25T17:00Z

See `[[SPRINT-1-SHIPPED-2026-05-25]]` for top-level marker.
See `[[SPRINT-2-PREP-2026-05-25]]` for what's next.

**Auto-completed during fase 12-15:**
- [x] Push 8 draft PRs (L-1) — 6 GREEN, 1 blocked (PR #49 sister-pkg deps), 1 NPM workspace-dep gap
- [x] PRESENCE.md fix (L-2)
- [x] brain-G3 worktree-default opt-in flag (L-3)
- [x] 24 missing frontmatter cleanup (L-4 + I-5)
- [x] 5 RED PRs lockfile-sync fixes (N-2 to N-6)
- [x] better-sqlite3 native binding rebuilt for Node 24 (O-1)
- [x] .nvmrc Node 20 pinning (O-2)
- [x] 14 local test failures resolved (O-3 confirmed)
- [x] Final brain push (N-10 = f926bea, sanity 8/8 GREEN)

**Operator-action remaining:**
- [ ] Merge sprint-1 PRs (~10) at your own pace — start with #57 (_template)
- [ ] After sister-pkgs merged, fix PR #49 by either dropping deps OR pushing follow-up commit
- [ ] Review specs v1.0.2 at convenience
- [ ] Flip brain-G3 default after 24-48h opt-in usage proves stable
- [ ] After code-1 lands MEM/RAG: activate brain-G4 + brain-G6 per checklist
- [ ] Push to 60% coverage (was 47.63%; recent +4 tests but room for more)

**New finding (fase 12-15):** local Node 24 vs CI Node 20 mismatch caused better-sqlite3 native-binding crashes + 14 local test failures. Now mitigated by O-1 (rebuild) + O-2 (`.nvmrc` pinned to Node 20). Re-run `nvm use` if you switch shells.

## P0 — Critical (do today)

### [ ] 1. Skim 30-agent audit (5 min)
- File: `[[2026-05-25-30-agent-audit]]`
- Why: forstå hva som faktisk landet i sprinten (7 specs, 6 folders, 3 MOC, 3 pilot-tasks, 2 nye packages, 2 bash-skripter)
- Output: mental model av nye systemet før du tar avgjørelser

### [ ] 2. Test brain-demo (15 min)
- File: `[[Runbook-Brain-Demo]]`
- Why: verifiser at end-to-end recall + skill-invoke + queue-drop fungerer på din maskin
- Output: confidence at systemet er operasjonelt før brain-G3/brain-G4/brain-G6-aktivering

### [x] 3. Push-gate decision on COMMIT_PLAN (30 min interactive) — DONE 2026-05-25 by L-1
- File: `~/code/command-center/COMMIT_PLAN_2026-05-25.md`
- Why: 7 PRs (PR 2-8, ingen separat PR 1) ready for review, alle lokalt grønne. ~5.1k linjer TS + 489 linjer bash uncommitted.
- Output: ✓ L-1 pushet PRs som drafts; operator-flow flyttet fra "push manuelt per OK kjør" til "review draft + mark ready when satisfied". Per-PR `git push` ikke lenger gate-blokkert.
- Recommended order (historisk): PR 2 (_template + .gitignore) → PR 3 (skill-registry) → PR 6 (rag-engine) → PR 4 (youtube) → PR 5 (github) → PR 8 (firm scripts) → PR 7 (agent poller, draft only)
- Operator-action nå: review draft-PRs i GitHub UI, klikk "Ready for review" når OK

### [ ] 3b. Verify Option C operator-gate naming decision (5 min) — NEW (fase 8/9)
- File: `[[2026-05-25-operator-gate-naming]]` (I-1)
- Why: H-10 reconcile pass valgte Option C (`infra-G*` vs `brain-G*` prefix-disambiguation). Operator må bekrefte før cascade til de resterende ~10 filene kjøres.
- Output: ACK Option C, eller flag alternativ. Påvirker P3 cascade-task.

## P1 — Important (do within 48h)

### [ ] 4. Read specs at v1.0.1+/v1.0.2 (~60 min)
- Files: `08-system-architecture/specs/*.md` (7 specs, 4865 lines)
- Why: validere arkitektur før code-1 starter videre implementasjon
- Output: feedback i `[[INTEGRATION_NOTES_v1.2]]` eller direkte i specs
- Priority order: RAG (mest novel) → MEMORY → AGENT_ORCH → SKILL_REG → YOUTUBE → GITHUB → OBSIDIAN_STRUCTURE

### [x] 5. Activate brain-G3 worktree-default (per checklist, 30 min) — DONE 2026-05-25 by L-3
- File: `[[Runbook-Brain-Preflight-Checklist]]` § brain-G3
- Why: enabler Conductor-style parallelle agent-lanes uten cwd-conflicts
- ✓ L-3 implementerte brain-G3-aktivering per preflight-checklist
- Risk: lav (rollback med `firm --legacy` på 1 sekund)
- Observe: 24-48h før brain-G4-flip (operator: monitor i 24-48h før vurdere G4)

### [ ] 6. Spec-review: cross-check INTEGRATION_NOTES_v1.2 (15 min)
- File: `[[INTEGRATION_NOTES_v1.2]]` (lukket 7 CRIT + 6 av 12 MED i fase 3)
- Why: se hva fase 3 fikset + hva som er deferred (6 MED + 38 wikilink-stubs igjen)
- Output: green-light for code-1 implementasjons-fase

### [x] 6a. Approve PRESENCE.md fix per I-8 (2 min: 1 min decision + 1 min apply) — DONE 2026-05-25 by L-2
- File: `[[presence-investigation-2026-05-25]]` (I-8)
- Why: PRESENCE.md har vært tom siden 2026-05-13; root cause = `firm-tab-init.sh` mangler ~5 linjer append. Option A (pane-side write) anbefalt; matcher spec + 0 ADR-001-brudd.
- Output: ✓ L-2 applisert Option A — 5-linjers append i `_bin/firm-tab-init.sh` så pane-side write populerer PRESENCE.md ved init

### [ ] 6b. Review I-3 spec YAML fixes (10 min spec re-read) — NEW (fase 8/9)
- File: `08-system-architecture/specs/*.md` (I-3 deliverable — sjekk frontmatter-fix patches)
- Why: I-3 ryddet spec YAML inkonsistenser; sanity-pass før code-1 fortsetter
- Output: ACK at frontmatter er gyldig på alle 7 specs

## P2 — Useful (this week)

### [ ] 7. Pilot YouTube ingest manually (10 min)
- Command: drop URL i `12-youtube/_queue/YYYY-MM-DDTHHMM-<slug>.url` + `/skill youtube-ingest url=<X>`
- Why: validere ingestion pipeline end-to-end før brain-G6 enables auto-pickup
- Output: 1 distillert note i `12-youtube/<channel>/`

### [ ] 8. Pilot GitHub discovery manually (10 min)
- Command: drop search i `13-github-repos/_queue/YYYY-MM-DDTHHMM-<slug>.md` + `/skill github-discover query=<X>`
- Why: validere discovery + license-guard på ekte repo (helst en GPL for å teste guard)
- Output: 1-3 scored repo-notes i `13-github-repos/`

### [ ] 9. Curate `_channels.yaml` + `_topics.yaml` (15 min)
- Files: `12-youtube/_channels.yaml`, `13-github-repos/_topics.yaml`
- Why: pre-loade trusted sources før brain-G6 batch-ingestion kicker inn
- Output: 5-10 entries per file (ML/AI/trading domains du faktisk følger)

### [ ] 10. After code-1 lander C1-2/3/4: activate brain-G4 nightly-distill (~30 min checklist)
- File: `[[Runbook-Brain-Preflight-Checklist]]` § brain-G4
- Depends: memory-engine + rag-engine implementert + Recall MRR ≥ 0.6 på eval-set
- Output: brain self-updates nightly (cron 03:00 lokal)

### [ ] 11. After brain-G4 stable 1 week: activate brain-G6 queue-watcher (30 min checklist)
- File: `[[Runbook-Brain-Preflight-Checklist]]` § brain-G6
- Depends: brain-G4 stable + manuelle piloter (#7 + #8) grønne + license-guard + anti-hype-filter verifisert
- Output: autonom queue-prosessering (URL/search drops → distilled notes innen 1h)

### [ ] 11a. Coverage push #1: ws.ts smoke tests (~1.5 hr) — NEW (fase 8/9)
- File: `[[coverage-gap-analysis-2026-05-25]]` (H-3); status per J-4 = in flight
- Why: `apps/api/src/ws.ts` 280 linjer, 11.28% coverage. Fastify+ws-client harness → forventet +2pp lines globalt.
- Output: ws.ts dekning fra 11% → ~80%; del av sprint mot 60% line-gate

### [ ] 11b. Coverage push #2: route handlers (~3.5 hr) — NEW (fase 8/9)
- File: `[[coverage-gap-analysis-2026-05-25]]` (H-3) §Quick wins
- Why: 9 route-filer (agents/audit/executor/git/github/health/projects/router/terminals) på 0%. Fastify-inject smoke-tester er billige; forventet +5-7pp lines globalt.
- Output: apps/api/src/routes/ fra 60.4% → >90%; T-2026-05-26-A landet

### [ ] 11c. Brain-decisions endpoint tests (~1 hr) — NEW (fase 8/9)
- File: J-5 deliverable (brain-decisions.spec.md i command-center)
- Why: `/api/brain/decisions` handler bruker nå `infra-G*` ids; eksisterende test passerer fordi `toContain("G3")` matcher substring — men dedikert test for nytt id-format mangler.
- Output: ny test-case som asserter `id === "infra-G3"` eksplisitt

### [ ] 11d. Workspace decision-stack-deliveries YAML outlier (operator-binding, manual) — NEW (fase 8/9)
- File: workspace decision-stack YAML (outlier flagged i fase 9)
- Why: operator-binding rule krever manuell håndtering — kan ikke auto-fikses
- Output: operator-skjønnsvurdering på outlier; manuell merge eller dokumentert avvik

## P3 — Nice to have (this month)

### [ ] 12. Re-run wikilink + content audits weekly
- Scripts: `~/Obsidian/Brain/scripts/brain-content-audit.sh` + wikilink-audit
- Why: catch drift tidlig; resolvere de 38 documented stubs gradvis
- Output: weekly reports i `08-system-architecture/`

### [ ] 13. Forward brain-upgrade til Karri (already sent via ai-1, follow up)
- Why: Karri kan ha spec-review feedback fra trading-perspektiv
- Output: nye findings → `[[INTEGRATION_NOTES_v1.3]]`

### [ ] 14. Schedule retrospective generation (per AGENT_ORCH spec)
- Cadence: Sunday 22:00 lokal
- Output: `09-retrospectives/YYYY-WNN.md` per week (W22 alleredd landet av B-7)

### [ ] 15. Spec v1.1 consolidation
- Slå sammen alle v1.0.x patcher til én sammenhengende v1.1 per spec
- Why: lettere onboarding for fremtidige reviewers (Karri, eller deg selv om 3 mnd)
- Output: 7 specs på v1.1, gamle v1.0.x flyttet til `90-archive/`

### [ ] 16. Implement Option C gate-cascade til resterende ~10 filer (~30 min) — NEW (fase 8/9)
- File: `[[2026-05-25-operator-gate-naming]]` §"Files NOT touched"; J-3 leverte partial cascade
- Why: H-10 reconcile prefikset bare brain-upgrade-plan + Runbook + brain.ts/spec. Resterende refs i 00-CONTROL-PANEL, 00-CHEAT-SHEET, brain-distill-daily skill, HOW-TO-DROP-* queue-readmes, Runbook-Brain-Demo, Runbook-Brain-Upgrade-Workflow, AGENT_ORCHESTRATION_SPEC trenger brain-G* prefiks.
- Output: alle aktive refs bruker `brain-G*` eller `infra-G*`; historiske inbox/audit-filer urørt

### [ ] 17. Curate `_channels.yaml` + `_topics.yaml` med ekte entries (15 min) — NEW (fase 8/9, replikerer #9 men flyttet til P3 for kuratering)
- Files: `12-youtube/_channels.yaml`, `13-github-repos/_topics.yaml`
- Why: pre-load trusted sources før brain-G6 batch-ingestion; lavere prioritet enn pilot-runs i #7/#8
- Output: 5-10 trusted entries per file (ML/AI/trading domener)

### [x] 18. Activate brain-G3 (worktree-default) etter preflight checklist — DONE 2026-05-25 by L-3 (samme som #5)
- File: `[[Runbook-Brain-Preflight-Checklist]]` § brain-G3 (renamed per I-1)
- Why: duplikat av #5 men med oppdatert naming (brain-G3) — sørg for å bruke brain-prefiks i logg/audit
- Output: ✓ brain-G3 aktivert av L-3; `firm --legacy` tilgjengelig som rollback

### [ ] 19. Reconcile wikilink methodology — extend brain-link-graph.sh (~1 hr) — NEW (fase 8/9)
- File: `[[wikilink-reconciliation-2026-05-25]]` (I-2) §Next steps
- Why: G-3 og H-9 telte forskjellig (0 vs 209 broken). Reconcile-rapport viser 78 ekte broken edges across 48 targets. Trenger `--stub-allow=<file>` + `--skip-placeholders` flags på `brain-link-graph.sh` så fremtidige audits gir sammenlignbare tall.
- Output: oppdatert script + 3-tall-rapport convention (`total_edges` / `documented_stubs` / `genuinely_broken`)

## Estimated total time

| Bucket | Time remaining | Window | Done by agents |
|---|---|---|---|
| Sprint 1 SHIPPED | 0 (auto) | done 2026-05-25T17:00Z | L/N/O fase 12-15 (~9 items + 5 RED PR fixes + Node 20 pin + native rebuild) |
| P0 | ~25 min (#1 skim 5 + #2 brain-demo 15 + #3b Option C ACK 5) | i dag | #3 push-gate (30 min) by L-1 |
| P1 | ~1h 25min (#4 specs 60 + #6 INTEGRATION_NOTES 15 + #6b spec YAML 10) | innen 48h | #5 brain-G3 (30 min) by L-3, #6a PRESENCE (2 min) by L-2 |
| P2 | ~7h aktiv (+5.5h coverage push) + ~1 uke wait for brain-G6 | denne uka | (ingen) |
| P3 | løpende (+ ~1.5h aktiv: cascade + script-flags; #18 dropped som duplikat) | denne måneden | #18 brain-G3 dup (samme som #5) by L-3 |
| Sprint-2 prep | per `[[SPRINT-2-PREP-2026-05-25]]` | ad-hoc | — |

Total aktiv tid P0+P1+P2 = ~8h 50min spread over en uke (coverage-push dominerer). P3 er bakgrunns-vedlikehold + småjobber. Fase 12 L-agents tok ~62 min av operator-load. Fase 13-15 N/O agents lukket 5 RED PRs + Node-version drift (added: 6 GREEN PRs out of 8 pushed, 1 deferred = PR #49).

## Skip if pressed

Hvis du har < 30 min i dag:
1. Gjør #1 (skim audit) — 5 min
2. Gjør #2 (test brain-demo) — 15 min
3. Defer alt annet til i morgen

Hvis du har < 5 min: bare les `[[00-CHEAT-SHEET]]` og noter at 7 PRs venter på OK kjør.

## Track progress

Mark done in this file: `- [x]` instead of `- [ ]`. Auto-syncs til tiger-brain så Karri ser samme state. For nye actions som dukker opp, append nederst under riktig P-bucket med dato-stempel.

## Related

- `[[00-CHEAT-SHEET]]` — fast-lookup for daglig drift
- `[[Runbook-Brain-Upgrade-Workflow]]` — daglig ops + common scenarios
- `[[Runbook-Brain-Preflight-Checklist]]` — gate-aktiverings-protokoll (brain-G3/brain-G4/brain-G6)
- `[[2026-05-25-brain-upgrade-plan]]` — full plan + status (§13)
- `[[2026-05-25-30-agent-audit]]` — sprint audit trail
- `[[INTEGRATION_NOTES_v1.1]]` — cross-spec verify findings (7 CRIT + 12 MED + 9 NIT)
- `~/code/command-center/COMMIT_PLAN_2026-05-25.md` — push-gate plan
- `[[2026-05-25-operator-gate-naming]]` — I-1 Option C decision (infra-G* vs brain-G*)
- `[[presence-investigation-2026-05-25]]` — I-8 root cause for tom PRESENCE.md
- `[[wikilink-reconciliation-2026-05-25]]` — I-2 G-3 vs H-9 reconcile (78 ekte broken)
- `[[coverage-gap-analysis-2026-05-25]]` — H-3 top-10 uncovered files + sprint plan

---

Sist oppdatert: 2026-05-25T17:00Z — v1.3, SPRINT 1 SHIPPED marker addert øverst. Fase 12-15 (L/N/O agents) lukket 9 auto-tasks: PR push (6 GREEN/1 deferred/1 NPM gap), PRESENCE fix, brain-G3 opt-in, 24 frontmatter, 5 RED PR lockfile-fixes, better-sqlite3 native rebuild (Node 24→20), .nvmrc Node 20 pinning, 14 lokale test failures lukket, final brain push (f926bea, sanity 8/8 GREEN). Operator-action: merge ~10 PRs, fix PR #49 etter sister-pkg merges, push mot 60% coverage, flip brain-G3 default etter 24-48h.
Sist oppdatert: 2026-05-25 — v1.2, markert fase 12 L-agent completions: #3 (L-1 push-gate as drafts), #5 (L-3 brain-G3 activation), #6a (L-2 PRESENCE.md fix), #18 (L-3, dup av #5). 4 items closed, ~62 min operator-load fjernet. Tidsestimat-tabell oppdatert med "Done by L-agents" kolonne.
Sist oppdatert: 2026-05-25 — v1.1, addert fase 8/9 items (Option C ACK, PRESENCE-fix, spec-fix re-read, coverage push x3, gate-cascade, wikilink-script-flags, kuratering). Additivt — ingen eksisterende items fjernet.
