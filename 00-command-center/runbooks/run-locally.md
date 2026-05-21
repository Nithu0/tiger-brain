---
tags: [command-center, runbook]
type: runbook
created: 2026-05-16
---

# Run command-center locally

Prereq: Node >= 20.

## First-run

```bash
cd /home/nithu/code/command-center
cp .env.example .env       # edit only if non-default ports/host
npm install                # installs all workspaces
npm run dev                # API :3100 + Web :3200 in parallel
```

Then open `http://localhost:3200`.

## Verify endpoints

```bash
curl http://localhost:3100/api/health
curl http://localhost:3100/api/projects
curl http://localhost:3100/api/git/status
curl http://localhost:3100/api/terminals/presence
curl http://localhost:3100/api/terminals/feed?limit=10
```

All should return JSON. `/api/health` should report `{ "status": "ok" }`.

## Propose a command (Slice 1 — no execution)

```bash
curl -X POST http://localhost:3100/api/commands/propose \
  -H 'content-type: application/json' \
  -d '{"userIntent":"check git status of Nexus","generatedCommand":"git status","project":"ai-assistent"}'
```

Returns the proposal with `riskLevel` auto-classified. Approve/reject via UI; `BLOCKED` cannot be approved (API 403).

## Stop

`Ctrl+C` in the `npm run dev` terminal stops both api and web.
