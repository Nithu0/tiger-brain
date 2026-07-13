# DASHBOARD-AUDIT-REPORT — konsolidert for ai-2 (2026-06-23)

> Syntese av 4 audits (jarvis-contracts, brief-conformance, route-health, a11y-perf) + code-2s Playwright browser-verify + live re-probe. READ-ONLY: ingen kode rørt i ai-2s frontend-repo, ingen git, ingen secrets. Base: `https://dashboard-production-f342.up.railway.app`. Live re-probe kjørt 2026-06-23 ~03:08Z av code-1.

---

## 1. Samlet dom

**Dashboardet er runtime-sunt og funksjonelt live — IKKE ødelagt.** Backend grounded og ekte, alle ruter rendrer, ⌘K + ask→jarvis→tts virker ende-til-ende (code-2 bekreftet i ekte browser). Redesignet er **largely built, ikke greenfield**: Jarvis-laget, ui-kit, tokens, 8-sone-nav og hele `/jarvis/*`-backenden er shippet. Jobben for ai-2 er **wire + konsolidere + polish**, ikke bygge om.

**Hvor langt er redesignet?** Estimat ~60–65% av brief'en. Primitivene finnes alle (orb, command-bar, briefing-kort, explain-mode, /talk-cockpit, decision-threads). Det som gjenstår er (a) wiringen som bringer ekte server-grounding til UI, (b) IA-konsolideringen (36→6 soner, drep duplikat-par — 0 landet), (c) "what matters now"-laget (triage + since-you-last-looked + per-panel freshness).

**Den ene tingen som haster mest:** En aktiv trust-/penge-bug. Forsiden viser rolig "WATCH mode" mens live-brief sier **100% av dagstaket brukt, P/L -$554**. Operatøren leser "alt rolig" mens firmaet faktisk har brent hele dagslimitet. Bekreftet på nytt live nå (se §3).

---

## 2. GRØNT (verifisert, ikke rør — keep-and-polish)

- **Hydrering ren på home, 0 console-feil** (code-2 Playwright). SSR-passet rent på alle 43 200-ruter — ingen ekte Next.js-feilmarkører noensteds.
- **Backend fullt grounded.** Alle 6 intents + `/brief` + `/why-no-trade` PASS, HTTP 200, `isMock:false`, `source:"deterministic"`. Hver answer grunnet i ekte firm-state (1 trade, -$554, 100% daily-loss, regime unknown stemmer på tvers). Null mock, null tomme svar, null UNKNOWN på reelle intents.
- **Ask-flyten live ende-til-ende:** `POST /jarvis/ask → 200` + `POST /jarvis/tts → 200` (orb svarte + snakket via ElevenLabs). ⌘K command-bar åpner og navigerer.
- **Jarvis-primitivene shippet** (ikke stubs): /talk eget "Talk to Nexus"-cockpit + quick-chips, briefing-kort, Explain Mode på som default, /system låser paper-mode (operatør-gated). `/live-reasoning` (cycle-scope-radar) er den mest differensierte, on-brand viewet i appen.
- **A11y-baseline mye bedre enn typisk:** `motion-reduce:`-gating gjennomgående (orb-frykten i brief'en materialiserer seg IKKE), orb/health-pill har `aria-label`, `<html lang>` satt, ekte `<main>` landmark, gull focus-ring (9.2:1).
- **Perf sunn:** gzip på, 1 font preloaded, 0 `<img>`, payload sunn. Ingen perf-nødssak.
- **Paper-mode lås** (SIMULATION, "Locked", operatør-gated) — behold som er.

---

## 3. RØDT / ødelagt

| # | Funn | Alvor | Eier | Evidens |
|---|---|---|---|---|
| R1 | **Home-briefing vs live-brief ute av sync (trust-/penge-hazard).** Home SSR viser statisk "WATCH mode … no-trade bias holds"; live `/jarvis/brief` sier "1 trade today, P/L $-554, daily loss limit 100% used". `grep -c -554` på home = **0**. | **HØY — topp-prio** | ai-2 (frontend) | Re-probet live 03:08Z: brief headline=`"1 trade today, P/L $-554"`, home grep -554 = 0, home viser fortsatt WATCH-linja. |
| R2 | **Worker-heartbeat 5m stale → health-pill RED.** Siste orchestrator-cycle 5 min siden; pillens regel "red if heartbeat > 180s". Worker kan ha stallet eller var mellom cycles. **Backend-funn, IKKE frontend-bug.** | Medium | ai-1 / nexus-backend (IKKE ai-2) | code-2 popover: Worker #4 · 5m ago · 36145ms. Også: ingen nye no-trade-cycles siste døgn (nyeste = 22. juni). |
| R3 | **React #418 hydration-mismatch på /talk + /system** (ikke home). Sannsynlig årsak: delt komponent som rendrer relativ-tid/locale ("5m ago", valuta) ulikt server vs klient. Ikke en krasj — siden virker — men ekte hydration-feil + rød i console + kan gi flimmer. | Lav-medium | ai-2 | code-2 browser-crawl runde 2. Fix: render tid/locale klient-only (mount-gate) el. `suppressHydrationWarning` på de nodene. |
| R4 | **Semantisk bug i "why no trade"-ask.** Svar = `"We did trade — 1 trade today for $-554"` mens action=`SHOW_EVIDENCE topic:no-trade` peker på `regime_direction_gate`. Svaret motsier handlingen. | Lav (synlig) | ai-1/ai-2 ved wiring | Re-probet live: bekreftet ordrett. Når det finnes no-trade-cycles bør answer forklare gate-blokkene, ikke avvise premisset. |
| R5 | **3 ekte 404:** `/cockpit`, `/correlation`, `/signals-live` (navn fra brief/audit-tekst, finnes ikke i bygget). | Lav | ai-2 | route-health sweep: byte-identisk 404-shell. Alias el. fjern referansen. |

Ingen 500, ingen krasj, ingen render-error på noen 200-rute.

---

## 4. REDESIGN GAP-LISTE (prioritert — det som gjenstår)

**WIRING (størst konkret vinning, swap-punkter dokumentert):**
- **G1 — Wire home-briefing-kortet til live `/jarvis/brief`** (inkl. `spoken`). `JarvisBriefingCard.tsx` kjører i dag lokal deterministisk derivasjon; /talk-cockpit react-query-er allerede brief → de to overflatene er inkonsistente. Dette LUKKER R1. (Filer: `jarvis/JarvisBriefingCard.tsx`)
- **G2 — Legg til `api.jarvisAsk()` → POST `/jarvis/ask`.** Klientmetoden MANGLER helt; frontend resolver intent lokalt så server-grounding (ekte -554/gate-svar) aldri når UI. La `askAndAnswer` foretrekke remote-path med lokal `resolveIntent`+`composeAnswer` som offline-fallback. (`lib/api.ts`, `jarvis/JarvisProvider.tsx`)
- **G3 — Wire resterende `contracts.ts`-mocks** (AgentActivity, BlackboardEvent, PositionSummary, DecisionThread, AutoUpdateEvent) til ekte endpoints; flipp `isMock` per adapter. brief+why-no-trade er allerede migrert; resten er stubs.

**IA-KONSOLIDERING (0 landet — strukturell clutter):**
- **G4 — 8→6 soner + drep ~5 duplikat-rute-par.** Alle 13 prøvde duplikat-ruter svarer fortsatt 200: `/strategies`+`/strategies-live`, `/memory`+`/memory-trend`, `/analytics`+`/pulse`+`/hour-stats`, `/console`+`/system`, `/morning`+`/eod`+`/notifications`. Velg ÉN kanonisk taksonomi brukt identisk i sidebar + palette + breadcrumb; long-tail → palette/drawers. (NB: én audit anbefaler å beholde de 8 auditerte sonene fremfor brief'ens 6 — design-beslutning, ikke teknisk.)
- **G5 — ⌘K-that-acts.** Paletten er fortsatt nav-only (`router.push`, 30 hardkodede ruter). Legg til verb: pause firm, ack alert, explain why flat, open position, run reconciliation + en visuelt adskilt "ask the assistant"-resultattype. Penge/irreversible-actions forblir eksplisitt operatør-gated.

**"WHAT MATTERS NOW"-LAG (forsiden leser inert):**
- **G6 — "Needs attention now" triage.** Seksjonen finnes på home men SSR-er "Checking firm state…", ingen SEV-rader. Fyll med ekte SEV-1..3 (maks ~5, hver lenker til eiende skjerm). "100% daily loss used" = SEV-1. Kilde: helse/gate-state + `LiveActivityFeed`.
- **G7 — 'Since you last looked'-digest.** Helt fraværende (`grep "since you last"` = 0). Last-seen-keyed strip: endrede posisjoner, nye proposals, gate-flips, alerts mens borte.
- **G8 — Per-panel data-freshness.** Endepunktene bærer `asOf`, men ingen "as of HH:MM" / Live·Stale·Paused-chip på panelene. Kritisk for et penge-verktøy. Skeletons, ikke spinners.

**POLISH:**
- **G9 — Explain-why utover home.** Kun home har explain-markører i dag (`/positions`,`/threads`,`/strategies-live` = 0). Rendre forklaring I posisjonen/eventet den gjelder, med siterte signaler + confidence.
- **G10 — Decision-timeline m/ correlation-ID** på `/threads` (signal→gate→sizing→execution); wire `DecisionThread` bort fra mock.
- **G11 — Orb-as-status (browser-verify gjenstår).** Markup har guards; SSR kan ikke bekrefte audio-reaktiv/cycle-state-animasjon el. reduced-motion-fallback. Code-2 bør screenshot-verifisere.

**A11Y QUICK-WINS (billig, høy verdi):**
- **G12 — Kontrast:** dim-tekst `#484f58` = 2.33:1 og ⌘K-`<kbd>` `#374151` = 1.84:1 feiler WCAG AA hardt. Token-fix uten rebuild: løft til `--muted #8b949e` (6.3:1). Pluss skip-link, `aria-hidden` på dekorative lucide-ikoner (41/44 mangler), `aria-expanded` på 8 sidebar-collapse-knapper. Verifiser focus-ring + `aria-live` i browser.

---

## 5. TOPP 5 NESTE ACTIONS for ai-2 (rangert)

1. **Fiks R1 nå (G1): wire home-briefing-kortet til live `/jarvis/brief`.** Høyest verdi OG en aktiv trust-bug — forsiden lyver om firma-state (rolig WATCH vs 100% dagstap brukt). Unify med /talk som allerede react-query-er brief. Ren wiring, lavest risiko, størst gevinst. *Real issue.*
2. **Legg til `api.jarvisAsk()` (G2).** Én klientmetode låser opp server-grounding for HELE ask-flyten + gratis fremtidig LLM via swap-punktet. Callers uendret per dokumentert seam. *Real issue.*
3. **Fyll "Needs attention now" med ekte SEV-triage (G6).** Eneste reelle "hva betyr noe nå"-fix. Seksjonen finnes allerede tom; data finnes (helse+gate+feed). Inkluder daily-loss-100% som SEV-1. *Real issue.*
4. **A11y-kontrast token-fix + skip-link (G12).** Billigste høy-verdi-gevinsten i hele lista — token-nivå, ingen rebuild, lukker harde WCAG AA-feil. *Real issue (lav kost).*
5. **IA-konsolidering: drep duplikat-rute-parene + 6-sone-taksonomi (G4+G5).** Den klareste strukturelle clutteren; 0 landet. Større jobb enn 1-4, men det er kjernen i "redesign" vs "wiring". *Real issue, men størst innsats — gjør etter quick-wins.*

**Nice-to-have (ikke prioriter foran 1-5):** G7 since-you-last-looked, G10 decision-timeline correlation-ID, G11 orb-as-status-animasjon, R5 404-aliasing, R4 semantisk why-no-trade-svar (lukkes delvis av G2). R3 (#418 hydration) er ekte men ikke-blokkerende — lukk når du uansett rører tid/locale-rendering.

**IKKE ai-2s bord:** R2 (worker-heartbeat stale) er ai-1/nexus-backend. Health-pillen RED er KORREKT oppførsel — den rapporterer en ekte backend-stale, ikke en frontend-feil.

---

## Forbehold
- Backend-contracter + trust-bug (R1) + ask/brief/why-no-trade er live-probet (curl 03:08Z). Browser-runtime (hydrering home, ask→tts) er code-2-verifisert via Playwright.
- Orb-animasjon, per-rute hydrering utover home/talk/system, focus-rekkefølge, live-region — IKKE screenshot-verifisert. Code-2 bør browser-sjekke G11 + focus-ring/aria-live.
