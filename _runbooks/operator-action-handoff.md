---
type: runbook
project: nexus
created: 2026-05-21
updated: 2026-05-21
owner: claude (keeps this live)
---

# Operator-action handoff — når Claude trenger at DU gjør noe

Dette dokumentet finnes fordi operator ba om det (2026-05-21): "forklar
meg bedre når jeg skal fikse ting for deg." Claude **eier** denne fila og
oppdaterer den. To deler:

1. **Faste kategorier** — hva Claude *aldri* kan gjøre selv, og den
   nøyaktige handlingen du tar. Endrer seg sjelden.
2. **Åpne handoffs akkurat nå** — Claude oppdaterer denne lista hver
   sesjon. Tom liste = ingenting venter på deg.

Regel Claude følger når den gir deg en handoff: **alltid HVOR + HVA + HVORFOR.**
Hvilken terminal/fil, den eksakte teksten å lime/skrive, og hvorfor det
er gated. Hvis en handoff under mangler én av de tre — be Claude fylle inn.

---

## Del 1 — Faste kategorier (hvorfor Claude ikke kan, hva du gjør)

| # | Kategori | Hvorfor Claude ikke kan | Hva DU gjør |
|---|---|---|---|
| 1 | **Push til `main`** | Ikke en kapabilitets-blokk — `git push origin main` kjører fint via Bash (verifisert 21.5). Gated kun av operator-prinsipp 5: Claude må ha din eksplisitte "OK kjør" først. | Si "OK kjør" → Claude pusher selv via Bash. (Eldre handoff `! git push origin main` virker også, men er ikke lenger nødvendig.) |
| 2 | **Railway env-flagg** | Claude har ikke tilgang til Railway-dashboard / kan ikke mutere prod-env. | Railway → riktig service → Variables → sett/endre flagg → service redeployer selv. Claude gir deg eksakt `KEY=value`. |
| 3 | **DB-writes (backfill, UPDATE, migrasjon)** | `nexus-pg-rw` MCP er read-only i praksis; writes er irreversible. | Railway → Postgres-service → Connect → Query → lim inn `BEGIN…COMMIT`-blokk Claude har skrevet → inspiser verifiserings-SELECT → `COMMIT` eller `ROLLBACK`. |
| 4 | **Destruktiv git** | `stash drop`, `branch -D`, `git push --force`, sletting — irreversibelt, operator-gated per CLAUDE.md. | Claude gir deg den eksakte kommandoen; du kjører den (i terminal eller via `! `). |
| 5 | **Eksterne meldinger uten trigger** | Sending til Discord/Karri/e-post uten "OK kjør"-trigger er gated. Unntak: proposals auto-sendes til Karri 09–17 CET. | Du sier "send" / Claude sender i auto-vinduet. Utenfor: Claude holder til neste morgen. |
| 6 | **Interaktiv innlogging** | `gcloud auth login`, OAuth-flyt o.l. krever din terminal. | Skriv `! <kommando>` i prompten — kjører interaktivt i sesjonen. |
| 7 | **Strategi/risk-endring** | Penge-impact går gjennom Karri-review (CLAUDE.md-protokoll). | Claude skriver proposal i `docs/strategy/proposals/`; du sender til Karri; du bekrefter "Karri-approved" før Claude implementerer. |
| 8 | **Installere brede verktøy / betale for tiers** | Broad-permission installs + betalte tiers er operator-gated. | Claude foreslår; du godkjenner/installerer. (Du har forhåndsgodkjent betaling når det fjerner blockers.) |

**"OK kjør"-gaten:** før *hver* push venter Claude på at du eksplisitt sier
"OK kjør" / "kjør på" e.l. Ingen unntak — selv i max-mode.

---

## Del 2 — Åpne handoffs akkurat nå

Sist oppdatert: **2026-05-25T10:30Z** av ai-1 (full-system improvement sweep, 10-agent).

### ✅ Gjort i 25.5-sveip (lokale auto-fixes, ikke pushet enda)
- 3 BLOCKED → VERIFIED i learning-ledger: regression-predictor non-zero (count=4), strategy_id null_pct=0% post-22.5, lesson-subprocess `:failed` markers (4 stk) — PG-tunnel åpen i dag.
- `agent_lessons` REOPENED-rotårsak korrigert: IKKE env-flagg (cron fyrer på workeren), men subprocess exitCode 1 i `derive-lessons.mjs` 4 dager på rad. Trenger Railway-worker-logs.
- AUTO-fix: /health weekend-aware (heartbeat-tolerance 600s → 5400s når WEEKEND) — fjerner false-positive `worker.ok=false`.
- AUTO-fix: 5 firehose-skripter wrappet `console.error(err)` via `sanitizeForCommit()` — fjerner risiko for DATABASE_URL/credential-leak til logs.
- AUTO-fix: `apps/api/src/routes/intelligence.ts:225` returnerte raw err.message til public API → erstattet med generisk "AI analysis temporarily unavailable".
- AUTO-fix: `docs/ref/firm-modules.md` oppdatert 16→30 sub-dirs.
- Memory-hygiene: 3 stale obsidian-MCP-referanser fjernet (MCP disconnected 25.5).

### ✅ Gjort i 24.5-sveip (forrige)
- Karri C3 gate VERIFIED, memory test-count reconciled, weekend-throttle false-positive dokumentert.

### 🔴 Venter på deg nå (operator-flips, ingen Claude-kapabilitet)

1. **Drop foreldet stash** (fra 21.5) — kat. 4 (valgfritt, ren opprydding).
   - HVOR: terminal eller `! ` i prompten.
   - HVA: `git stash drop stash@{0}`
   - HVORFOR: utdatert inline-utkast av `/firm/signal-rejections` (landet som egen route i `7274d45`).

2. **Pull Railway worker-logs for derive-lessons crash** — kat. 2 (NY rotårsak per 25.5).
   - HVOR: Railway → **worker** service → Logs → filter på `derive-lessons` rundt 04:51Z UTC.
   - HVA: finn stack-trace for daglig exitCode 1 (siste 4 dager: 22.5, 23.5, 24.5, 25.5 alle `:failed`).
   - HVORFOR: cron FYRER på workeren (env-flagg ER aktive), men subprocess i `scripts/firehose/derive-lessons.mjs` krasjer deterministisk. Eneste exitCode 1-path er line 220-223 (uncaught fatal i main). Sannsynlige rotårsaker (ranked):
     1. **Schema-mismatch i fetchClusters SQL (line 58-78)** — `simulated_orders` kolonner: `portfolio_regime_at_entry`, `session_at_entry`, `close_reason`, `pnl`, `closed_at`, `market`, `status`. Hvis en kolonne er renamed/manglende → PG throw → exit 1.
     2. **client.connect() failure** (line 183) — stale/rotated DATABASE_URL creds.
     3. **lessonFingerprint-import** (line 28) — hvis `./lib/fingerprint.mjs` mangler i Railway-bundle (Dockerfile copy-issue).
   - Bonus-diagnostikk operator kan kjøre fra Railway PG Connect:
     ```sql
     SELECT key, value, updated_at FROM firm_state
     WHERE key LIKE 'firehose:derive_lessons:%'
     ORDER BY updated_at DESC LIMIT 10;
     -- Forventet: 4 stk `:failed`-keys (22.5-25.5). value-kolonnen kan inneholde grunnen.
     ```
   - Når stack-trace funnet: Claude tar fix på den lokale skript-pathen.

3. **2 approved-awaiting-operator-flip proposals** (klare, ikke haster) — kat. 2.
   - `2026-05-11_orb_observe_only.md` → flip Railway `ORB_ENABLED=false` (observe-only-modus).
   - `2026-05-11_scalp_overlap_observe_only.md` → flip Railway `SCALP_OVERLAP_ENABLED=false`.
   - HVORFOR: begge er Karri-godkjent (negative WR/PnL data); flippene tar dem fra aktive til shadow-observasjon uten kode-endring.

### 🟡 Klar når du vil (ikke haster)

4. **Backfill-SQL: A5 + metadata-strip** (fra 21.5) — kat. 3.
   - HVOR: Railway → Postgres → Connect → Query.
   - HVA: lim inn de to `BEGIN…COMMIT`-blokkene i
     `docs/ops/2026-05-16_backfill-batch.md`, sjekk verifiserings-SELECT, COMMIT.
   - HVORFOR: fyller `portfolio_regime_at_entry` (36 rader) +
     `strategy_id`/`execution_source` (~138 rader) retroaktivt. Idempotent.

5. **Run strategy_id residual backfill** — kat. 3.
   - HVOR: terminal i denne repo-en, eller `! `.
   - HVA: `DATABASE_URL=<prod-url> CONFIRM=YES node scripts/oneshot/run-backfills-21may.mjs`
     (commit `28242f0` la til runneren fordi nexus-pg-rw MCP starter alle tx `READ ONLY`).
   - HVORFOR: ~86 historiske rader mangler `strategy_id` (post-fix `1dd9d6a` stopper nye NULLs men forfaller ikke gamle). Idempotent — no-op hvis allerede kjørt.

### 🟢 Browser-eye-check (kun du kan)

6. **Verifiser dashboard-charts render i ekte browser** (VERIFY-BY 26.5 i learning-ledger).
   - HVOR: åpne dashboard-URL i Edge/Chrome.
   - HVA: åpne `/`, `/charts`, `/validation`; se etter at canvas/SVG-charts faktisk tegnes + null console-errors (F12).
   - HVORFOR: SSR-shellen er bekreftet ren via WebFetch (200, ingen build-errors), men klient-JS som tegner charts kan WebFetch ikke teste.

### ⚪ Venter på Karri (du er budbringer)

7. **22 proposed-items i Karri-kø** (5 er H14-validert klynge fra 16.5, 8 dager gamle — høyest hevarm).
   I dag er **søndag** → auto-send-vinduet er INAKTIVT. **Mandag 09 CET (25.5)**: ai-1 sender en bundle-ping til Karri med H14-batchen (BC/MR/SB/TF/volexp konfig + reaktivering). Du trenger ikke gjøre noe; jeg fyrer auto.

8. **NEWS_BLACKOUT independent-emit** (REOPENED i learning-ledger). Karri-proposal eksisterer ikke ennå; jeg vil skrive en når learning-cluster-rapporten er ute.

---

## Hvordan Claude holder denne fila live

- Ved hver sesjon-start: les Del 2, fjern det som er gjort, legg til nytt.
- Når Claude gir deg en muntlig handoff i chatten → samme punkt skal stå her.
- Når en kategori i Del 1 endrer seg (ny MCP gir Claude tilgang) → oppdater tabellen.
- Relatert: phase-status (`docs/ops/phase-status.md`), `feedback_access_proactivity` memory.
