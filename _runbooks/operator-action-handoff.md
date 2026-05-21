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

Sist oppdatert: **2026-05-21T06:50Z** av ai-1.

### 🔴 Venter på deg nå

1. **Push 5 commits til main** — kat. 1.
   - HVOR: Claude-prompten (denne panen).
   - HVA: si "OK kjør" — Claude pusher selv via Bash.
   - HVORFOR: 4 AUTO-bug/observability-fixes (oanda-sync dedup, SL/TP-
     persistering, retention-regresjonstester, webhook f&f + advisory-locks)
     + 1 phase-status-doc. 860/860 worker-tester grønt, tsc rent. Trenger "OK kjør".
   - Hovedbatchen fra rebasen (16+3 commits) er allerede pushet av en peer-pane.
   - Hvis avvist: en peer-pane pushet i mellomtiden — Claude rebaser på nytt.

2. **Drop foreldet stash** — kat. 4 (valgfritt, ren opprydding).
   - HVOR: terminal eller `! ` i prompten.
   - HVA: `git stash drop stash@{0}`
   - HVORFOR: `stash@{0}` er et utdatert inline-utkast av `/firm/signal-rejections`
     som allerede landet som egen route-fil i `7274d45`. Ufarlig å droppe.
     (`stash@{1}` `pre-rebase-06may` — la stå, ikke verifisert.)

### 🟡 Klar når du vil (ikke haster)

3. **Backfill-SQL: A5 + metadata-strip** — kat. 3.
   - HVOR: Railway → Postgres → Connect → Query.
   - HVA: lim inn de to `BEGIN…COMMIT`-blokkene i
     `docs/ops/2026-05-16_backfill-batch.md`, sjekk verifiserings-SELECT, COMMIT.
   - HVORFOR: fyller `portfolio_regime_at_entry` (36 rader) +
     `strategy_id`/`execution_source` (~138 rader) retroaktivt. Idempotent.

4. **Railway env-flagg** — kat. 2. Claude lager eksakt flagg-liste når du ber om det
   (ENTRY_STACK_COOLDOWN, SCALP_OVERLAP, ORB-mode m.fl. — se phase-status).

### ⚪ Venter på Karri (ikke deg, men du er budbringer)

5. ~16 strategy-proposals i `proposed`-tilstand, ureviewet. Auto-send til Karri
   skjer 09–17 CET. Du trenger ikke gjøre noe med mindre du vil purre.

---

## Hvordan Claude holder denne fila live

- Ved hver sesjon-start: les Del 2, fjern det som er gjort, legg til nytt.
- Når Claude gir deg en muntlig handoff i chatten → samme punkt skal stå her.
- Når en kategori i Del 1 endrer seg (ny MCP gir Claude tilgang) → oppdater tabellen.
- Relatert: phase-status (`docs/ops/phase-status.md`), `feedback_access_proactivity` memory.
