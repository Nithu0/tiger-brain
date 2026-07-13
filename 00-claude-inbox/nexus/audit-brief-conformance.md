# Live-dashboard conformance mot REDESIGN BRIEF — ai-2 gap-liste

> Audit av ai-1 (code-1-lane), 2026-06-23 ~03:05Z. READ-ONLY: ingen edits i ai-2s frontend-repo, ingen commit/push.
> Metode: curl/SSR mot live prod (`https://dashboard-production-f342.up.railway.app`) + direkte probe av live Jarvis-backend via `/api/proxy/jarvis/*`. Bygger på code-2s browser-verify (ren hydrering, ask→200+tts→200, RED helse-pille = worker-heartbeat 5m stale) — gjentar ikke den.
> Brief: `~/Obsidian/Brain/01-nexus/jarvis-redesign-brief-for-ai2-2026-06-23.md`.

## Hovedfunn (endring siden forrige audit)

1. **SSR er nå tung på alle ruter** — `/positions` 39 675 chars (var 477 "Loading…" i forrige audit), `/threads` 41 982, `/strategies-live` 59 966. "Loading…"-skallene på første paint er i stor grad borte fra HTML-størrelsen, MEN kjernevidgetene er fortsatt klient-derivert (se under): `/positions` viser fortsatt "Loading" i markup, og "Needs attention now" SSR-er "Checking firm state…".
2. **Backend er ekte og grounded.** `/jarvis/brief` returnerer `isMock:false` med reelle tall: *"1 trade today, P/L $-554 … Daily loss limit 100% used"*. `/jarvis/why-no-trade` returnerer reelle gate-blokker (`regime_direction_gate`, hard-rejected). `POST /jarvis/ask {"text":"why no trade"}` → `200`, `SHOW_EVIDENCE`-action, `source:"deterministic"`.
3. **Den største enkeltdivergensen:** home-briefing-kortet og live-brief er IKKE i sync. Live `/jarvis/brief` sier "1 trade today, P/L $-554, 100% daily loss used". Home-SSR inneholder INGEN av disse tallene (`grep -c -554` = 0) — kortet viser fortsatt den lokale deterministiske WATCH-linja: *"Nexus is in WATCH mode. Market read pending. No-trade bias holds…"*. Operatøren ser altså "alt rolig / WATCH" på forsiden mens firmaet faktisk har brent 100 % av dagstaket. **Trust-/penge-hazard — topp-prioritet.**

## DONE / MISSING / PARTIAL mot brief-punktene

| Brief-punkt | Status | Evidens (live markup / endpoint) |
|---|---|---|
| Jarvis-backend live (ask/brief/why-no-trade/tts) | **DONE** | `/api/proxy/jarvis/brief` `isMock:false` reelle tall; `why-no-trade` reelle gates; `POST ask`→200 |
| Orb-cockpit `/talk` + quick-chips | **DONE** | egen `<title>Talk to Nexus`; chips: Show gold chart · Market pulse · Best strategy · Positions · Why no trade · Briefing; "Click the orb to talk" / "Tap to talk" |
| Global command bar (⌘K-affordance) | **DONE (som affordance)** | "Ask Nexus what matters now…", "ask Nexus · ⌘K" ×3 i shell |
| ⌘K-that-ACTS (verb, ikke bare nav) | **MISSING** | paletten er fortsatt nav/router.push (brief-audit: 30 hardkodede ruter, kun navigasjon). Ingen "ack alert / pause firm / close position / run reconciliation"-verb i markup |
| Briefing-kort wired til live `/jarvis/brief` | **MISSING / PARTIAL** | home-SSR mangler live-tallene (-554 / daily-loss); kortet kjører lokal deterministisk derivasjon. `/talk`-cockpit DERIMOT react-query-er brief (per brief-audit) — så det er inkonsistent mellom de to overflatene |
| `api.jarvisAsk()` → POST `/jarvis/ask` fra frontend | **MISSING** | backend live, men ingen klientmetode treffer den; frontend resolver intent lokalt (brief-audit (e)). Server-grounding (ekte -554-svar) når aldri UI |
| Needs-Attention-Now triage | **PARTIAL** | seksjon FINNES på home (`<h2>Needs attention now</h2>`) — ny siden forrige audit — men SSR-er "Checking firm state…", ingen SEV-rangerte rader, klient-derivert/tom på første paint |
| 'Since you last looked' digest | **MISSING** | ingen treff i home-markup (`grep "since you last"` = 0). Ingen last-seen-strip |
| Explain-why-everywhere | **PARTIAL (kun home)** | home: 2 explain-markører + "Show evidence/Open decision thread" på briefing-kortet. `/positions`=0, `/threads`=0, `/strategies-live`=0 explain-markører. Ikke "in the position/event it concerns" ennå |
| Decision-timeline m/ correlation-ID | **PARTIAL** | `/threads` har "Decision Thread" + "Before"-felt; men ingen synlig correlation-ID-grammatikk (signal→gate→sizing→execution) i SSR; `DecisionThread`-contract fortsatt mock/unwired (brief-audit (c)) |
| Data-freshness "as of HH:MM" / Live·Stale·Paused | **MISSING (på UI-flatene)** | endepunktene bærer `asOf`, men home-SSR har ingen "as of"/"Xs ago"/"stale"-chip på panelene. Helse-pille finnes (RED), men per-panel freshness mangler |
| DEMO/SAMPLE-merking av syntetiske tall | **PARTIAL** | "Demo · paper mode"-badge finnes på home; men nullverdiene (PnL/bots/positions) rendres uten konsekvent DEMO/skeleton-behandling |
| IA-konsolidering 36→6 soner | **MISSING** | sidebar fortsatt 8-gruppe (Overview/Trading/Strategy/Backtest/Learning Loop/Agents/Market/Ops + Operator Console/System/Command). Ingen 6-sone-modell i markup |
| Drep ~5 duplikat-rute-par | **MISSING (0 landet)** | alle par svarer fortsatt 200: `/strategies`+`/strategies-live`, `/memory`+`/memory-trend`, `/analytics`+`/pulse`+`/hour-stats`, `/console`+`/system`, `/morning`+`/eod`+`/notifications`. Ingen redirect/merge |
| Orb-as-status (ikke logo) | **UVERIFISERT (trenger browser)** | orb i markup ("Tap to talk"), men SSR kan ikke bekrefte audio-reaktiv/cycle-state-animasjon eller prefers-reduced-motion-fallback. Code-2 bør screenshot-/state-verifisere |
| Paper-mode lås (operatør-gated) | **DONE** | `/system` Trading mode=SIMULATION, "Locked" (per brief-audit) — behold |
| Tom/WATCH-tilstand intensjonell | **PARTIAL** | "Demo · paper mode" + WATCH-banner finnes, men forsiden leser fortsatt inert (statisk WATCH-linje, tomme paneler) i stedet for "hvorfor ingen trade / hva ville trigge en" — og motsier nå live-brief (-554) |

## Topp redesign-gaps for ai-2 (prioritert)

1. **Wire home-briefing-kortet til live `/jarvis/brief` (inkl. `spoken`).** Høyest verdi OG en aktiv trust-bug: forsiden viser rolig WATCH mens live-brief sier 100 % dagstap brukt / P/L -$554. Unify med `/talk` som allerede react-query-er brief. (`jarvis/JarvisBriefingCard.tsx`)
2. **Legg til `api.jarvisAsk()` → POST `/jarvis/ask`**, og la `askAndAnswer` foretrekke remote-pathen med lokal `resolveIntent`+`composeAnswer` som offline-fallback. Gir server-grounding (ekte -554 / gate-svar) til UI gratis; swap-punkt allerede dokumentert. (`lib/api.ts`, `jarvis/JarvisProvider.tsx`)
3. **Fyll "Needs attention now" med ekte SEV-1..3-triage** (maks ~5 rader, hver lenker til eiende skjerm). Seksjonen finnes men SSR-er "Checking firm state…". Kilde: helse/gate-state + live-feed. Inkluder "100 % daily loss used" som SEV-1.
4. **⌘K-that-acts:** oppgrader paletten fra nav-only til verb (pause firm, ack alert, explain why flat, open position, run reconciliation) + en visuelt adskilt "ask the assistant"-resultattype. Penge-/irreversible-actions forblir eksplisitt bekreftet (operatør-gate).
5. **IA-konsolidering 8→6 soner + drep duplikat-par.** Ingenting landet: alle 13 prøvde duplikat-ruter svarer fortsatt 200. Velg én kanonisk 6-sone-taksonomi brukt identisk i sidebar + palette + breadcrumb; flytt long-tail til palette/drawers.
6. **Explain-why utover home.** Kun home har explain-markører i dag (`/positions`,`/threads`,`/strategies-live` = 0). Rendre AI-forklaring I posisjonen/eventet den gjelder, med siterte signaler + confidence — ikke et eget panel.
7. **Per-panel data-freshness.** Endepunktene bærer `asOf`; eksponer "as of HH:MM" + Live/Stale/Paused-chip + skeletons (ikke spinners) på hvert datapanel. Kritisk for penge-verktøy.
8. **'Since you last looked'-digest** (helt fraværende): last-seen-keyed strip (endrede posisjoner, nye proposals, gate-flips, alerts mens borte).
9. **Decision-timeline:** gi `/threads` ekte timeline-grammatikk m/ correlation-ID (signal→gate→sizing→execution); wire `DecisionThread`-contract bort fra mock.

## Forbehold
- Alt over er curl/SSR + direkte endpoint-probe. Klient-hydrert oppførsel (orb-animasjon, om paneler populeres etter hydrering, prefers-reduced-motion) er IKKE skjermbilde-bekreftet her — code-2 verifiserte hydrering/ask/tts separat. Orb-as-status og motion-acceptance-test trenger browser-verify.
- Backend-divergensen (live-brief -554 vs statisk WATCH på home) er det sterkeste, mest handlingsbare funnet: bekreftet både via `/jarvis/brief`-respons OG fravær av tallene i home-SSR.
