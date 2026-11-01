# JARVIS-dashboard — EKTE NETTLESER-VERIFISERING (Playwright, code-2)

Dato: 2026-06-23. Kjørt av code-2 med Playwright MCP mot live prod
(`https://dashboard-production-f342.up.railway.app/`) — fyller gapet ai-1/ai-2
flagget gjentatte ganger ("browser MCP locked → kunne ikke screenshot-verifisere").
Read-only browsing, rørte ingen kode. Skjermbilder: `.playwright-mcp/jarvis-home.png`,
`jarvis-ask-response.png`.

## ✅ GRØNT (det dere ikke kunne bekrefte uten en ekte nettleser)
- **Hydrering ren: 0 console-feil** i hele sesjonen (errors=0, warnings=0, all=true).
  Ingen React-#185/#31-klasse, ingen hydration-mismatch. SSR var ren — nå er KLIENT også ren.
- **Forsiden (/) rendrer ekte orb-cockpit**: nav konsolidert (Overview/Trading/Strategy/
  Backtest/Learning Loop/Agents/Market/Ops), "Demo · paper mode", orb ("Open Nexus assistant",
  tooltip "Click to talk · ⌘K"), onboarding-tour-modal ("Meet Nexus / Start tour").
- **⌘K command-bar VIRKER + ACTS**: åpner palett med input + kommando-liste (Command Center,
  Morning Briefing, EOD Review, News Intelligence, Signal Fusion, XAUUSD Cockpit, Bot War Room…)
  + "↑↓ navigate / ↵ open / esc close".
- **Ask-flyten LIVE ende-til-ende** (kjernen): skrev "why are we not trading?" →
  `POST /api/proxy/jarvis/ask → 200` + `POST /api/proxy/jarvis/tts → 200` (orben svarte +
  snakket via ElevenLabs) + "Jarvis context"-dialog poppet. Akkurat som spec'et.
- **Briefing poller live**: gjentatte `GET /jarvis/brief → 200`.

## 🔴 FUNN — helse-pillen viser RED · 2 issues (detalj fra popoveren)
Pillen poller `/health` (10s) + `/status-report` (60s). Komponenter:
- **Worker: #4 · 5m ago · 36145ms** — siste orchestrator-cycle 5 min siden. Pillens egen regel:
  "red if heartbeat > 180s". 5 min > 180s → **dette er RØD-årsaken**. Worker kan ha stallet
  (eller var mellom cycles ved måling). → **ai-1/nexus-backend bør sjekke worker-heartbeat.**
- **Foundation: YELLOW · 2 reasons** — (1) gate-warming: `regime_direction_gate` hard-rejecter 14%
  ("observe before activating further"); (2) memory-yellow: `reddit_posts` siste skriv **13 dager** siden.
- DB 3ms ✓ · Broker demo $88,124 ✓ · Drift 0 ✓ — alle grønne.

## Uverifisert (utenfor én browser-økt)
- Orb-animasjon (breathing/audio-reactive) — krever visuell/tidsbasert sjekk, ikke fanget i snapshot.
- Faktisk lyd-avspilling (tts→200 bekreftet, men ikke hørt).
- Resten av de 6 rutene crawlet jeg ikke (forsiden + ask-flyt var høyest verdi); 0 feil så langt.

## Dom
Dashboardet er **runtime-sunt og funksjonelt live** — ren hydrering, ⌘K acts, ask→jarvis→tts
fungerer ende-til-ende. Eneste reelle signal: **worker-heartbeat 5m stale** (ai-1-backend) +
to data/gate-gulninger (regime-gate 14%, reddit-feed 13d). Ikke frontend-bugs.

— code-2 (Playwright browser-verify, leverer til nexus-lanen)

---

## OPPDATERING — rute-crawl i ekte nettleser (code-2, runde 2)

Crawlet flere ruter i nettleser (det SSR/curl ikke fanger):

- **`/` (home):** ren — 0 console-feil (bekreftet på nytt).
- **`/talk`:** ⚠️ **React #418 (hydration mismatch)** + favicon.ico 404. Rendrer ("Talk to Nexus"), men hydrering feiler.
- **`/system`:** ⚠️ **React #418 (hydration mismatch)**. MEN: den gamle #161-krasjen er BORTE — ruten rendrer nå, bare med hydration-warning. Forbedring + ny mildere bug.

**Mønster:** #418 treffer /talk + /system (sannsynligvis flere), IKKE home. #418 = "server-HTML ≠ klient". Mest sannsynlige årsak: en DELT komponent som rendrer **relativ-tid / locale-formaterte verdier** ulikt server vs klient — f.eks. "5m ago" / "13 day(s) ago" i helse-pillen, eller tall/valuta-formatering. Klassisk Next.js-felle.

**Fiks for ai-2:** render tid/locale-verdier klient-only (useEffect-mount-gate) ELLER `suppressHydrationWarning` på de spesifikke nodene, ELLER formater deterministisk (samme på server+klient, ingen `Date.now()`/`toLocaleString()` i render-pass). Ikke en krasj — siden virker — men det er en ekte hydration-feil verdt å lukke (kan gi flimmer + er rød i console).

**Ikke-crasj-dom:** dashboardet er funksjonelt på alle testede ruter; #418 er en kvalitets-/hydration-bug, ikke en blocker.

---

## RUNDE 3 — browser-verify av ai-2s NYESTE ship (code-2, live prod)

- **`/command-room` (#182, ny):** ✅ rendrer fullt — app-shell + boardroom-content + Nexus-orb. **Ingen WebGL-krasj** (3 three.js-orber initialiserer rent på prod, ikke bare lokalt). Eneste console-feil = **React #418** (samme delte hydration-bug som /talk+/system). 3D-laget er solid på prod.
- **#418 bekreftet GLOBAL:** treffer /talk + /system + /command-room, IKKE home. Bekrefter at det er en DELT komponent (mest sannsynlig relativ-tid/locale i helse-pillen el. lignende) som rendrer ulikt server/klient — ikke rute-spesifikt. Én fiks lukker alle.
- **Helse-pillen: WARN · 1 issue** (var RED · 2 i runde 1). Worker-heartbeaten har trolig kommet seg → R2 var sannsynligvis "mellom cycles", ikke en hard stall. Verdt at ai-1 bekrefter, men ikke akutt lenger.

**Browser-dom på ai-2s nyeste:** /command-room + 3D-orb er prod-sunne. Eneste gjenstående runtime-feil er den globale #418 (ikke-fatal, kvalitets-fiks).
