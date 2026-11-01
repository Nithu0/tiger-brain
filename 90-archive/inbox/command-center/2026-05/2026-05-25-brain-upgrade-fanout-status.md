---
title: Brain-upgrade C1 fan-out + Phase 14b/c status
date: 2026-05-25
author: code-1
project: command-center
status: in-progress
tags: [command-center, brain-upgrade, phase-14, fan-out]
---

# Brain-upgrade C1 fan-out + Phase 14b/c status (2026-05-25)

## TL;DR
- 17+ draft PRs landed on Nithu0/command-center after operator MAX trigger
- All 10 C1-N brain-upgrade lanes scaffolded (skeletons; LLM-backed logic operator-gated)
- Phase 14a (api on Railway) stable + serving
- Phase 14b (apps/agent local poller) scaffolded + apps/api endpoints landed
- Phase 14c (web on Railway) — 3 single-service attempts FAILED; 2-service alt landed (PR #16)

## PR map (17+)
[generate from `gh pr list` output — group by lane: C1-N, Phase 14b, Phase 14c, Docs/Tooling]

## Live deploy
- URL: https://command-center-production-7da5.up.railway.app
- Status: Phase 14a (cd6b563 or earlier — diag-Dockerfile 7cd4059 failed Oct 2026-05-25T13:07Z)
- /api/health: db:ok, status:degraded (firmBus/brain/workspace all "missing" — expected hosted-mode; PR #6 reclassifies these as "ok" with "hosted-no-bus" label)

## Operator decisions pending
1. Merge order for 17 PRs (PR #16 from a60ef326 has the matrix)
2. 14c architecture: stick with single-service + need Railway log OR adopt 2-service (PR #16)
3. SKILL_REGISTRY_CONTRACT.md (PR #15) — code-2 ACK pending before merge
4. BRAIN_WEB_API_CONTRACT.md (PR #17) — code-2 ACK pending before C2-10 UI work
5. lockfile-fix PRs (a263baf6 was working on #1, #2, #4, #5 sequentially)
6. Backfill activation (BACKFILL_DISTILL_TASKS=1) — operator decides when

## Cross-pane coordination
- code-2 dispatched C1-1..C1-10 to inbox/code-1.md at 11:30Z; ACK'd via inbox/code-2.md
- Schema contracts (SKILL + BRAIN_WEB) await code-2 sign-off
- code-2 owns C2-N lane: youtube-ingest, github-discovery, skill-registry pkg, brain web UI

## Architecture artifacts created
- docs/contracts/SKILL_REGISTRY_CONTRACT.md (PR #15)
- docs/contracts/BRAIN_WEB_API_CONTRACT.md (PR #17)
- docs/ADR-005-... (PR ~#18 in flight — Slice 15 plan agent)
- docs/PR_MERGE_ORDER.md (PR ~#19 in flight — merge-order agent)
- docs/runbooks/BRAIN_UPGRADE_ACTIVATION.md (PR ~#20 in flight — runbook agent)

## Next session priorities
1. Check Railway log for actual 14c failure (operator must share)
2. If 2-service preferred: provision Railway Service B per ADR-004 §revised
3. Land merge order from PR_MERGE_ORDER.md
4. Wire real LLM in C1-2 distill (Haiku) once operator OKs cost
