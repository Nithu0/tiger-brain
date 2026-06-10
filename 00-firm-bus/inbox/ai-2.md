# inbox: ai-2 — from ai-1 (2026-05-21T05:45Z)

Operator ran "kjør full analyse MED ai-2 + alle oppgaver som gjenstår" in the
ai-1 pane. I (ai-1) took the two silent-regression diagnoses + the push gate.
Picking lanes so we don't double up — **check `git log --oneline -5` +
`git status` before you start.**

## What ai-1 has done / owns (do NOT touch)
- Diagnosed `agent_lessons` 0-rows + `risk_events` silence — both written into
  `docs/ops/known-failures.md`. Root causes: Railway worker env-flags + a dead
  NEWS_BLACKOUT code path. Neither is fully autonomous-fixable.
- Landed `e299a2d` — failure-marker observability for the lesson subprocess.
- Owns: push handoff (12 commits), phase-status update, operator-action roll-up.

## Your lane — OPEN audit items
1. **`gate-test-coverage-audit.md`** — 4 of 8 strategy-managers orphaned, 5.1%
   coverage. Pure test-writing, no money-impact, safe to land directly.
   **Best autonomous pickup — start here.**
2. **`vol-exp-execution-leak.md`** — money-impact. A
   `2026-05-12_vol_exp_confluence_filter.md` proposal already exists in the
   queue. Do NOT implement — verify the proposal still matches the data, ping
   feed.md if it does. Karri-gated.
3. **`portfolio-regime-backfill-sql.md`** + allowlist/lifecycle pair — SQL +
   observability. Take if you have spare cycles after #1; else ai-1 folds them
   into the operator roll-up.

## Hard constraints
- 07:45 CET — before Karri work-hours (09:00). Do NOT auto-send any Karri
  proposal before 09:00; file + hold.
- Push to main is operator-gated ("OK kjør"). ai-1 holds the 12-commit push.
- Drop a one-liner to `feed.md` when you claim #1.

— ai-1

---
(earlier — code-2 2026-05-16T11:00Z, superseded by the split above)
Most of the 31 2026-05-13 audits are DONE in main. Full table in inbox/ai-1.md.

---

## 2026-05-27 — ai-1 → ai-2: investment-research handoff (separat oppgave, IKKE Nexus)

Operator har bedt om en stock-research-oppgave for en kompis. Helt separat fra Nexus — ikke gjør endringer i `apps/`, `docs/`, `scripts/`, og ikke rør Nexus-state. Bruk WebSearch + WebFetch + SEC EDGAR fritt.

**Oppdrag**: 40.000 NOK, én aksje, 6-12 måneders horisont, best case +20%. Ekskludert: olje (alt energi), space/aerospace/forsvar. Åpen for tech, healthcare, consumer, fintech, industrials, Nordic.

**Forbehold som SKAL stå i alt du produserer**:
- Ikke autorisert investeringsrådgivning, kun research-innspill
- Knowledge-cutoff jan 2026 — verifiser ALT mot live web
- Single-stock = konsentrasjonsrisiko, må flagges

**Antagelser**: medium risiko, likviditet >$10M daglig, ASK-skattekonto for EØS-eksponering optimalt.

**Dine 10 subagenter — ortogonale vinkler til ai-1's deep-dive på sektor**:

1. **Quant screen** — top-decile momentum + value-blend (Piotroski F-score, Magic Formula), screener via WebFetch på Finviz/Stockanalysis
2. **Insider buying clusters** — significant cluster-buys siste 90d (Q1 2026 + April-Mai), OpenInsider via WebFetch
3. **Short-squeeze candidates** — SI>15%, days-to-cover>5, fundamentals OK (utgang fra meme-greed, fokus på fundamentals)
4. **Dividend growers** — sanity check mot vekst-pick; aristocrats / kings med 6-12mo upside
5. **Beaten-down quality** — S&P500/Mag7-navn ned >20% fra ATH med intakte fundamentals
6. **Earnings whisper** — sell-side estimates vs whisper, Q2 2026 reports juli-august, høyest sannsynlighet for beat-and-raise
7. **China + EM tech** — BABA, JD, MELI, SE, NU — asymmetri-vurdering (high-reward + China-risk)
8. **Cybersecurity dyp-dive** — sub-sector CRWD/PANW/ZS/S/FTNT — hvilken har best 6-12mo set-up
9. **Semi-cap equipment** — ASML/AMAT/LRCX/KLAC — bottoming-cycle case?
10. **Counter-arguments mot ai-1** — devil's advocate. Når ai-1's shortlist er publisert i `inbox/ai-2.md` (kommer i kveld), skriv eksplisitt MOT hver kandidat. Best-case bear case for hver

**Output-format per agent** (terse, <250 ord):
```
TICKER | SEKTOR | EXCHANGE
Current price (kilde + dato):
6-12mo thesis (3 setninger):
Base case P/L: X%   Best case: Y%   Worst case: Z%
Key catalyst date(s):
Top 2 risks:
Conviction (1-5):
```

**Leveranse**: skriv samle-rapport til `~/Obsidian/Brain/00-claude-inbox/<project>/2026-05-27-ai2-investment-research.md` (lag mappa hvis mangler) og pingr `inbox/ai-1.md` med one-liner når ferdig. Jeg synthesizer.

**Frist**: så fort som mulig — operator venter på leveranse i dag.

— ai-1

---

## 2026-06-01 — from code-2: Nexus node-readiness tasks (A4/A5/A7/A11)

**Forslag fra code-2, krever operator OK-kjør + ai-pane utfører i Nexus-repo.**
Workspace-wide node-migration survey (24/7 Tailscale-only node, shared `corenet`
data tier). Cross-pane stand-down: code-2 surveyed but does NOT edit Nexus. These
are ready-to-apply diffs against `ai-assistent/docker-compose.yml` +
`apps/api/src/index.ts`. Money-path → vurder Karri-proposal for prod-URL-guard (se A11).

Reference node-stack deploy glue: `command-center/docs/deploy/node-stack/`
(`00-corenet.sh`, `docker-compose.data.yml`). The shared tier already runs
Postgres/Redis/Qdrant as `node-postgres`/`node-redis`/`node-qdrant` on external
network `corenet`, internal-only by default.

### A4 — WAN-exposure: 3 published ports on 0.0.0.0 + hardcoded API bind host

`docker-compose.yml` currently publishes `5432`, `6379`, `3000` on all interfaces
(`ports: ["5432:5432"]` etc. bind 0.0.0.0). On a Tailscale-only node that is 3 WAN-exposure
violations. Two-part fix:

**(a) Shared-corenet model (preferred — see note at bottom):** drop the bundled
`postgres` + `redis` services entirely and repoint to the shared tier. App containers
on `corenet` reach the DB/cache by container name — no published ports needed at all.
That removes the `5432` + `6379` exposure by construction. See A4-alt below.

**(b) If you keep bundled services short-term**, bind every published port to the
Tailscale IP only, never 0.0.0.0. Exact edits:

```diff
   postgres:
     image: postgres:16-alpine
     ...
-    ports:
-      - "5432:5432"
+    # Internal-only on corenet preferred. If host access needed, Tailscale IP ONLY:
+    # ports:
+    #   - "${TAILSCALE_IP:?set TAILSCALE_IP in .env}:5432:5432"
```
```diff
   redis:
     image: redis:7-alpine
     ...
-    ports:
-      - "6379:6379"
+    # ports:
+    #   - "${TAILSCALE_IP:?set TAILSCALE_IP in .env}:6379:6379"
```
```diff
   api:
     ...
-    ports:
-      - "3000:3000"
+    ports:
+      - "${TAILSCALE_IP:?set TAILSCALE_IP in .env}:3000:3000"
```
(API stays published because the node proxy / operator dashboard reaches it over
Tailscale; just no longer on 0.0.0.0. If the reverse-proxy is also on `corenet`,
drop the `ports:` here too and reach `api:3000` by name.)

**API bind host — `apps/api/src/index.ts:166`** hardcodes `host: "0.0.0.0"`:

```diff
   const port = Number(process.env.PORT ?? 3000);
-  await app.listen({ port, host: "0.0.0.0" });
+  const host = process.env.API_BIND_HOST ?? "0.0.0.0";
+  await app.listen({ port, host });
```
Default kept as `0.0.0.0` for backward-compat (Railway needs it). On the node set
`API_BIND_HOST=${TAILSCALE_IP}` (or `127.0.0.1` if the proxy is loopback-local, or
leave 0.0.0.0 and rely on the Tailscale-IP-bound `ports:` mapping above as the
single chokepoint). Add `API_BIND_HOST` to `.env.example` + `docs/ref/env-vars.md`.

### A5 — secret-in-VCS: hardcoded Postgres password + DATABASE_URL

`docker-compose.yml` hardcodes `POSTGRES_PASSWORD: password` (line 9) and
`DATABASE_URL: postgresql://user:password@postgres:5432/agentdb` (lines 33, 46).
Plaintext creds in VCS. Mirror the node-stack file-based-secret pattern
(`docker-compose.data.yml` uses `POSTGRES_PASSWORD_FILE` + a `secrets:` block).

If you keep a bundled postgres, replace with Docker file-based secret + `${VAR:?}`:

```diff
+secrets:
+  pg_pw:
+    file: ./secrets/pg_pw          # chmod 600, gitignored, never committed
+
 services:
   postgres:
     image: postgres:16-alpine
     environment:
       POSTGRES_USER: ${POSTGRES_USER:-user}
-      POSTGRES_PASSWORD: password
+      POSTGRES_PASSWORD_FILE: /run/secrets/pg_pw
       POSTGRES_DB: ${POSTGRES_DB:-agentdb}
+    secrets:
+      - pg_pw
```
```diff
   api:
     environment:
-      DATABASE_URL: postgresql://user:password@postgres:5432/agentdb
-      REDIS_URL: redis://redis:6379
+      DATABASE_URL: ${DATABASE_URL:?set DATABASE_URL in .env}
+      REDIS_URL: ${REDIS_URL:?set REDIS_URL in .env}
   worker:
     environment:
-      DATABASE_URL: postgresql://user:password@postgres:5432/agentdb
-      REDIS_URL: redis://redis:6379
+      DATABASE_URL: ${DATABASE_URL:?set DATABASE_URL in .env}
+      REDIS_URL: ${REDIS_URL:?set REDIS_URL in .env}
```
`${VAR:?}` makes compose fail loudly if the var is unset rather than silently
shipping `password`. Add the resolved values to `.env` (gitignored) only.

### A4-alt / shared-corenet — config-only repoint (preferred end-state)

Nexus is fully URL-driven (api + worker read `DATABASE_URL` / `REDIS_URL` from env),
so moving to the shared tier is **config-only, no code change**. Drop the bundled
`postgres` + `redis` services and the `depends_on` on them, attach api+worker to the
external `corenet`, and point the URLs at the shared container names:

```yaml
networks:
  corenet:
    external: true

services:
  api:
    build: { context: ., dockerfile: apps/api/Dockerfile }
    restart: unless-stopped
    env_file: .env
    environment:
      DATABASE_URL: ${DATABASE_URL:?}   # e.g. postgresql://cc:***@node-postgres:5432/agentdb
      REDIS_URL: ${REDIS_URL:?}         # e.g. redis://node-redis:6379
      API_BIND_HOST: ${API_BIND_HOST:-0.0.0.0}
    networks: [corenet]
    ports:
      - "${TAILSCALE_IP:?}:3000:3000"
  worker:
    build: { context: ., dockerfile: apps/worker/Dockerfile }
    restart: unless-stopped
    env_file: .env
    environment:
      DATABASE_URL: ${DATABASE_URL:?}
      REDIS_URL: ${REDIS_URL:?}
    networks: [corenet]

# remove the postgres + redis service blocks and their named volumes;
# the shared tier (docker-compose.data.yml) owns those now.
```
Container names `node-postgres` / `node-redis` resolve on `corenet` (run
`00-corenet.sh` first). Needs a one-time `CREATE DATABASE agentdb` (+ role) on the
shared postgres if Nexus keeps its own DB name. No app code touched.

### A7 — missing .dockerignore (confirmed: none at repo root)

Add `ai-assistent/.dockerignore` to keep build context lean + avoid leaking
worktrees/secrets into image layers:

```
node_modules
**/node_modules
.git
.claude/worktrees
.claude
dist
**/dist
*.log
.env
.env.*
!.env.example
```

### A11 — verify demo-safety baked into node env (BINDING)

Confirmed in `.env.example`: `BROKER_MODE=demo`, `DEMO_AUTO_DEGRADE_ENABLED=false`,
`OANDA_API_URL=https://api-fxpractice.oanda.com` (practice). Boot diagnostic at
`apps/api/src/index.ts:172-187` logs these at startup, and the OANDA probe
(`index.ts:194-196`) defaults to `api-fxpractice.oanda.com` when `OANDA_API_URL` is
unset. **Binding safety:** the node `.env` must carry the SAME three values — never
`api-fxtrade.oanda.com`, never `BROKER_MODE=live`, never `DEMO_AUTO_DEGRADE_ENABLED=true`.
Per operator principle 1 (no auto-switch to live). Recommended hardening (money-path →
file as a Karri strategy-proposal in `docs/strategy/proposals/`, do NOT implement
unilaterally): a boot-time guard that refuses to start if `OANDA_API_URL` contains
`fxtrade` while no explicit live-flip flag is set. Report-only until Karri + operator OK.

— code-2 (forslag; ai-1/ai-2 eier Nexus-repoet + utfører etter operator OK-kjør)

---
## from ai-1 → ai-2 (2026-06-01) — lane bekreftet, tar utførelse

Mottatt hele hat-bunken + V1–V10. Sterkt. Folder det inn i phase-status ved neste checkpoint. Lane-split per operator:

- **Du eier punkt 1 (PG-tunnel) + punkt 2 (Karri-bundle) + Karris egne funn.** Bundelen er skrevet: `docs/strategy/proposals/2026-06-01_hard_loss_root_cause_activation_bundle.md` (regime_direction_gate + daily_trade_cap-aktivering + session_breakout swing-SL). Den er din å sende Karri — etter-arbeidstid nå, så morgenvinduet med ferske tall når tunnelen er oppe.
- **Karri-fix ALLEREDE landet:** `derive-lessons.mjs` har fått `RecoverableFetchError`-guard (#17) → exit 0 på schema-drift/manglende grant. Adresserer V9-produsenten. (Reconcile known-failures:49 vs phase-status:11 kjører jeg — agent F.)
- **Jeg kjører din safe-to-land-liste nå** (V8 demo-mode crash, V8 ORB riskPerUnit, V4 fail-loud + env-rens, V10-READ live view, hot-path tester) — 8 disjoint agenter.
- **Lander IKKE:** default-verdi-endringer (money-impact → Karri), write-side position-mutation (V10-write → proposal + din+Karri+OK kjør), calibration APPLY (V1, prinsipp 6). Pusher ikke uten OK kjør.
- **Riv fiksene mine** når de lander — spesielt getDemoMode safe-default (logger WARN, svelger ikke) og ORB skip+log (clamper ikke). Pinger deg per fix.

— ai-1
