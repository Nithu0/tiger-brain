---
title: Karri handoff — command-center 21+ PRs in flight
date: 2026-05-25
author: code-1
project: command-center
status: review-ready
audience: karri
tags: [command-center, handoff, brain-upgrade]
---

# Karri handoff — 21+ PRs in flight

## Brief
21 draft PRs on github.com/Nithu0/command-center after operator MAX trigger. Most are brain-upgrade C1-N skeletons (LLM-backed logic operator-gated for cost), plus Phase 14b apps/agent + alt-arch for Phase 14c.

## What you might want to look at
- **docs/PR_MERGE_ORDER.md** (PR #20) — recommended merge sequence + conflict matrix
- **docs/contracts/SKILL_REGISTRY_CONTRACT.md** (PR #15) — schema for /api/brain/skills — needs your sign-off if you have opinions
- **docs/contracts/BRAIN_WEB_API_CONTRACT.md** (PR #17) — frontend consumption contract
- **docs/ADR-005-multi-machine-fan-out.md** (PR #19) — Slice 15 architecture, includes karri-laptop as one of 3 agents
- **docs/runbooks/BRAIN_UPGRADE_ACTIVATION.md** (PR #21) — how to flip switches

## Setup if you want to run apps/agent on karri-laptop
Per docs/runbooks/BRAIN_UPGRADE_ACTIVATION.md §3:
1. Get bearer token from POST /api/auth/login (use AUTH_PASSWORD_KARRI from operator)
2. Create /etc/systemd/system/cc-agent.service (sample in apps/agent/README.md)
3. Set CC_API_URL, CC_AGENT_TOKEN, CC_MACHINE_ID=karri-laptop
4. systemctl --user enable --now cc-agent

## No action required from you right now
Operator wanted to know everything was code-complete. The skeletons are ready; production activation needs operator OK kjør per the runbook.

## Phase 14c status
3 single-service attempts FAILED on Railway. 2-service alt landed as PR #16. We need either operator to share Railway build log (so we can debug single-service) OR operator to provision Railway Service B per ADR-004 § revised.
