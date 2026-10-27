# F2-kandidatjakt — behovsdrevet sweep (tools-1, 2026-08-19)

4 parallelle researchers: (A) behovsanalyse på tvers av alle laner (feed/STATE/GOALS),
(B) premiss-sjekk fetch-MCP, (C) offisielt MCP-register + kuraterte lister, (D) Docker-katalog
(web — verifisert via docker/mcp-registry) + npm + gh. Alt read-only; ingenting installert.
Registry-nedslag: §9b (F2-kull) + §1/§2-flips, commit på main.

## 1. fetch-verdicten: DEPRECATED (snudde den planlagte LIVE-flippen)

infra-1 reparerte docker-mcp-plugin i dag (v0.43.3, user-dir install — apt-churn-sikret) og ba om
LIVE-flip av fetch-docker. Premiss-sjekken (B) sier nei, med belegg:

- **Null funksjonell avhengighet.** Ingen skript/runbook/skill i repo eller Brain kaller fetch-MCP-en
  — 20+ grep-treff er alle inventar/status-omtale. Nexus' eget tool-inventar (22.06) bekrefter:
  web/fetch-verktøy «appear in NO inventory».
- **21 kall totalt noensinne**, alle i ÉN thesis-sesjon 23.-24. juni (rå sesjonslogger, tool_use-records).
  Null kall i hele perioden fetch-docker faktisk var LIVE (28.07→medio aug). Ingen savnet den på 3 uker nede.
- **Full dekning fra LIVE-verktøy:** WebFetch/WebSearch (innebygd i alle paner/subagenter/executors),
  curl/wget/httpie for verbatim + plain-HTTP + localhost, playwright-MCP for JS-sider. Residual unik
  verdi av mcp/fetch ≈ null.
- **Negativ nettoverdi:** global config → gateway + container (default 1 CPU/2 GB) per pane × 8 mot
  RAM-taket, for null bruk.

**Toolkit-plugin-en beholdes og er flippet LIVE** — den bærer container-sandbox-testbenken (reell verdi).
Kun fetch-radene er DEPRECATED. Bonus-fix: `karri-bootstrap.sh` provisjonerte den døde uvx-fetchen til
nye maskiner — fjernet.

Rest (operatørvalg, ikke utført): fjerne fetch+fetch-docker-radene i `~/.claude.json`; rydde profiler
`cc-fetch`/`cc_test_fetch` + image `mcp/fetch` (433 MB).

## 2. F2-shortlist (registry §9b har full tabell)

**Hovedhull: sqlite-lanen.** 4 laner (data-1, learning-1, trading-1, paal-1) gjør ad-hoc-SQL mot
better-sqlite3-baser via engangs node-scripts; oneshot-SQL står i operatør-kø i ukevis.

1. **sqlite-utils** (simonw, 2153★, CLI) — testes FØRST via `uvx` (ingen install): `query --json` → jq.
   Hypotese: dekker 90 % (lese-inspeksjon) uten ny MCP-prosess i RAM-budsjettet.
2. **DBHub** (bytebase, 3378★) — sqlite-MCP m/read-only-modus/row-limit/timeout. Sandbox-test kun hvis
   MCP-verktøykall faktisk trengs. Reserve: mcp-sqlite-tools (spences10, 19★, ung).
3. **Twelve Data MCP** (vendor-offisiell, offisielt register) — XAUUSD spot/OHLC/indikatorer for nexus.
   Gate: verifiser XAU/USD i gratis-tieret først; API-nøkkel = operatør; info/analyse, aldri execution.
4. **Context7** (upstash, 61k★, remote) — versjonsriktig biblioteksdocs, anti-hallusinasjon. Kun
   bibliotek+tema i queries, aldri kode/PII.
5. **yq v4** (mikefarah, 16k★) — YAML/TOML-hullet i jq/rg-klassen. Install = operatør-gate.

0-funn bekreftet: GPU/Vast-monitor, systemd/journald-MCP, CRM-MCP, Docker-katalog-delta siden 28.07,
yt-dlp-komplement. Forkastet m/begrunnelse i §9b (yfinance, Alpha Vantage, serena, m.fl.).

## 3. Behovsanalysen (A) — funn utenfor min lane (til orientering, eies av navngitte laner)

- **LLM-kost-metering/betalt-fallback-varsling** (infra-1/learning-1 — dokumentert i egne STATE-filer;
  to hendelser med dager av stille betalt forbruk etter 8b-dødsfall).
- **Ubackupede repoer** (paal-1/admin-1): grossist-plattform uten remote, refi-doc-agent uten git —
  størst enkelt-tapsrisiko i hele bildet; venter operatør-beslutning siden 28.07.
- **project_state.md-råte** (2 mnd stale i command-center + ai-assistent) — agentene planlegger mot
  utdatert virkelighet; kandidat for gen+--check-mønsteret.
- **Operatør-gate-køen** (≥8 åpne ventepunkter spredt over GOALS/STATE/inbox) — aggregert
  «venter på deg»-visning med alder ville hindre ukers råtning; naturlig orchestrator-1/admin-1-sak.
- **Verktøy-doctor på kadens:** begge stille dødsfall (uvx-fetch, docker-mcp-plugin) ble funnet ved
  tilfeldighet. tools-doctor.sh + gen --check finnes — mangler bare timer + morgenbrief-linje.
  Foreslås som infra-1-timer (report-only); tools-1 eier innholdet.

## 4. Neste (tools-1)

Nytt aktivt mål: **sandbox-test av sqlite-lanen** per SANDBOX-TEST-PROTOCOL — sqlite-utils via uvx mot
KOPI av command-center.db/memory.db (fase 1-premiss: dekker CLI-en de faktiske spørringsmønstrene fra
lane-behovene?), deretter DBHub kun hvis MCP-flaten trengs.

— tools-1
