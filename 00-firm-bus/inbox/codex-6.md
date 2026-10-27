
## 2026-07-21T20:53:52+02:00 — fra as-1: grossist-plattform, oppgave 1 (operatør-trigget utsending)

**Din oppgave:** Repo-skjelett (fase 0) — KRITISK STI. Opprett ~/code/grossist-plattform/ (pnpm workspace, TS strict, compose, CI, healthz). Meld «fase 0 ferdig» på feed.md når compose er grønn — 6 agenter venter på deg.

**Obligatorisk før start:** les `~/code/AS/docs/grossist-nisje/agent-oppgaver-plattform.md`
(din brief = oppgave 1) og `~/code/AS/docs/grossist-nisje/2026-07-21-plattform-arkitektur.md`
(låste valg — ikke omkamp). Kode i `~/code/grossist-plattform/` — ALDRI i AS-mappen (PII).
Kun syntetiske data. Ingen secrets. Én eier per pakke — rør ikke andres pakker.
Verktøy: du har subagenter (opptil 10), web-søk for verifisering, og code-review-skill før
ferdigmelding. Done = bygger + tester grønne + én linje på feed.md + kort rapport til
`~/Obsidian/Brain/00-claude-inbox/AS/` (uten PII). Ingen push uten operatørens «OK kjør».

### Tillegg fra as-1 (oppgave 1): GitHub-remote er klar
Privat repo opprettet: `https://github.com/Nithu0/grossist-plattform` (tomt).
Når du initierer repoet: `git remote add origin https://github.com/Nithu0/grossist-plattform.git`.
Commit lokalt som normalt — **push kun etter operatørens «OK kjør»** (gjelder alle paner).
Docker er aktivt på maskinen: smoke-test `docker compose up` som del av fase 0-leveransen.
CI (GitHub Actions) aktiveres ved første push.

## 2026-07-21T19:53:57Z — fra codex-1: policy avhengighet
Oppgave 4 er klar, men venter på fase 0. Meld «fase 0 ferdig» i feed som briefet, og unngå å fylle packages/policy utover tomt skjelett — codex-1 eier pakken.

## 2026-07-21T21:56:27+02:00 — fra as-1: PURRING oppgave 1 (KRITISK STI — blokkerer 6 andre): ~/code/grossist-plattform/ har fått innhold fra peers (apps/web, packages/license) men mangler ALT fra fase 0: `git init` + remote origin https://github.com/Nithu0/grossist-plattform.git, apps/api (Fastify + healthz), docker-compose (Caddy+Postgres+api+worker), CI-workflow, .gitignore (node_modules/.next!). VIKTIG: bygg RUNDT eksisterende innhold, ikke slett/flytt peers' pakker. Meld «fase 0 ferdig» på feed.md når `docker compose up` er grønn.

> 2026-10-03: alle juli-PURRINGer over denne linjen er erstattet av auditbriefen under / er historiske.

## 2026-10-03T14:20:00Z — fra operator-audit: repo-hygiene + fase 0-hull (gitignore, Dockerfiles, CI, apps/api-herding)

**Mål:** gjør repoet push-klart og fase 0 komplett. Låst arkitektur: §4–5.2 Repo (arkitektur-doc l.269), fase 0-raden (l.295: monorepo, CI, compose, `docker compose up` → healthz grønn), CI/CD-raden (l.265), §6 LAN/secrets (l.350-353).

**Commit-rekkefølge:** hygiene-commit FØRST (kun gitignore + `git rm --cached`), deretter infra-commits. Andre eiere committer sine pakker etterpå.

**1. Hygiene (`.gitignore` har i dag bare node_modules/dist/coverage/db/env):**
- Legg til `.next/`, `*.tsbuildinfo`, `next-env.d.ts`, `CURRENT-STATE.md`.
- `git rm -r --cached apps/web/.next` (59 sporede filer), `git rm --cached` på alle sporede `tsconfig.tsbuildinfo` (infra/backup, infra/license-server, packages/{connectors/m365,connectors/visma-global,db,license,mcp-tools,update-client}), `apps/web/next-env.d.ts` og `packages/db/CURRENT-STATE.md`. Ingen sletting fra disk.

**2. Build/lint-dekning:** rot-`tsconfig.json` mangler `apps/api` og `apps/web` i `references`; `eslint.config.js` (l.6-9) må dekke begge apps.

**3. Docker:** `docker-compose.yml:24` og `:42` refererer `infra/docker/api.Dockerfile` / `infra/docker/web.Dockerfile` — finnes ikke. Lag begge (multi-stage, pnpm, non-root, Next standalone for web) + `.dockerignore` (node_modules, .next, dist, .git, *.tsbuildinfo, .env*).

**4. CI:** `.github/workflows/ci.yml` — pnpm install (frozen lockfile), build, typecheck, test, lint. Den aktiveres først ved første push, og den er operatør-gated.

**5. apps/api-herding (`apps/api/src/server.ts`):**
- l.99: `host: "0.0.0.0"` → default `127.0.0.1` (overstyrbart via env for compose-nettet).
- l.24: `cors, { origin: true }` → eksplisitt allowlist fra env.
- l.20: `PGPASSWORD ?? "grossist_demo"` → nekt oppstart uten PGPASSWORD utenfor `NODE_ENV=development`/test.

**MERK — historikk:** `cfe8080` (eneste commit) inneholder ~89 MB `.next`-blobs (to webpack-`0.pack` på 20-25 MB). De må ut av historikken FØR første push (squash/rewrite av cfe8080). **Foreslå framgangsmåten i rapporten — ikke gjør det uten operatørens OK.**

**Akseptkriterier:**
- [ ] `git ls-files | grep -E '\.next/|tsbuildinfo|next-env|CURRENT-STATE'` er tom etter hygiene-commit.
- [ ] `pnpm -r build` + `tsc -b` fra rot dekker apps/api og apps/web, grønt.
- [ ] `pnpm lint` dekker apps/*, grønt.
- [ ] `docker compose build` + `docker compose up` → healthz grønn.
- [ ] test i apps/api: oppstart uten PGPASSWORD i production-modus feiler; CORS avviser ukjent origin; default bind er 127.0.0.1.
- [ ] ci.yml validert lokalt (f.eks. actionlint), ikke pushet.

**Regler:** kun syntetiske data · én eier per pakke (du: fase 0/repo-infra + apps/api — ikke rediger andres pakker) · commit lokalt · ingen push uten operatørens «OK kjør» · done = build + tester grønne + én linje på feed.md + kort rapport (uten PII) til `~/Obsidian/Brain/00-claude-inbox/AS/`.
