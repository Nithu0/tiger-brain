---
tags: [project, command-center, ops, moc]
type: moc
created: 2026-05-16
---

# command-center

Workspace-wide control plane. Standalone repo at `/home/nithu/code/command-center/`.

One dashboard + command queue to see and eventually drive every project, terminal, and AI agent under `/home/nithu/code` and the Obsidian Brain. Not Nexus-specific, not thesis-specific.

**Status:** Slices 1-10 (code) complete — dashboard, AI router, execution, real-time, PWA + push, agent system, GitHub, cross-machine sync, developer flow (Slice 9), mobile-first nav + Brain Layer (Slice 10). All landed 2026-05-21; repo pushed to private github.com/Nithu0/command-center.
**Open:** only operator-gated Slice 8 infra — Litestream binary install, S3 credentials, read replica on Karri's second machine. Per `docs/ROADMAP.md`.
**Repo:** under git since 2026-05-21, pushed to private **github.com/Nithu0/command-center**.

## Quick run

```bash
cd /home/nithu/code/command-center
cp .env.example .env
npm install
npm run dev    # API :3100 + Web :3200
```

Then open `http://localhost:3200`. See [[runbooks/run-locally]] for verification.

## In this folder

- [[project-card]] — one-page card (status, stack, ports, owner)
- [[ADRs/README|ADRs]] — architecture decision records (verbatim mirrors)
- [[runbooks/README|runbooks]] — run-locally, swap-to-postgres, audit-dump, code-2 handoff
- [[prompts/README|prompts]] — operator-edited desk persona overrides
- [[audit/README|audit]] — daily SQLite audit_log dumps land here (Slice 3+)
- [[lessons/README|lessons]] — retros and friction notes

## Source of truth

Code + canonical docs live in `/home/nithu/code/command-center/`. This brain folder is context, decisions-mirror, runbooks, and retros. Do not duplicate code here.
