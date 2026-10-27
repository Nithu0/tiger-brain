# codex-5 — Dashboard v0

Tid: 2026-07-21T21:58:32+02:00
Repo: `/home/nithu/code/grossist-plattform`
Pakke: `apps/web`

Levert:
- Next.js standalone dashboardflate med norsk UI og syntetiske data.
- Sider/visninger: saksliste, sakdetalj, godkjenningskø, auditlogg og selskapsvelger.
- Layout følger konseptdemoens sidebar/topbar/kort-tabell-uttrykk, men er implementert som egen app.
- API-mock ligger som typed frontend-data og rene state-funksjoner under `apps/web/src/lib`.
- Tester dekker tenant-filter, selskapsbytte, audit-scoping og godkjenningsbeslutning.

Verifisert:
- `corepack pnpm --dir apps/web test` — 4/4 tester grønne.
- `corepack pnpm --dir apps/web lint` — ingen warnings/errors. Next varsler at `next lint` er deprecated.
- `corepack pnpm --dir apps/web build` — Next production build OK.
- Lokal dev-server svarer `HTTP/1.1 200 OK` på `http://127.0.0.1:3000`.

Merk:
- `~/code/grossist-plattform` var ikke et git-repo da oppgaven ble levert.
- Root workspace hadde samtidige lisensserver-filer fra annen agent; jeg rørte kun workspace-patternet som trengs for `apps/*` og web-pakken.
- Ingen secrets og ingen kundedata brukt.
