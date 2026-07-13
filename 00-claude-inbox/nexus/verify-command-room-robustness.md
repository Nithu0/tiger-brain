# /command-room — robusthet på ny flate (degrade / a11y / perf)

**Dato:** 2026-06-23
**Metode:** READ-ONLY curl mot LIVE prod (SSR-markup-nivå). Ingen browser, ingen git, ingen redigering av ai-2 sin frontend. code-2 kjører browser/Playwright-verifisering parallelt — denne rapporten er curl/contract/delta.
**Base:** https://dashboard-production-f342.up.railway.app
**Scope:** #181 3D-orb, #182 /command-room, #183 /api/chief.

---

## TL;DR

/command-room **degraderer pent** og er **overraskende a11y-solid** for en WebGL-/voice-first-flate. Hele styrerom-UI-en (tekst, agent-roster, logger, paneler) renderes som ekte SSR-HTML — three.js-orbene er rent dekorative og lazy-loadet, så en bruker uten WebGL/JS ser fortsatt innhold, ikke blank canvas. Ingen blokkerende funn. Tre konkrete quick-wins under (mest perf-payload og en liten animate-gating-luke).

---

## (a) Graceful degradation — GOOD

- **SSR rendrer full innhold.** Strippet tekst fra /command-room viser hele boardroomet: nav, kommandobar, alle 11 agenter (Nexus Commander/Aurelia/Castellan/Orin/Vesper/Ferro/Lumen/Atlas/Sage/Warden/Echo med Ask/Dispatch/Logs), Market/Strategy/Decision/Logs/Risk/System/Positions-paneler, improvement-queue, bug-radar. Alt finnes uten JS.
- **Ingen `<canvas>` i SSR** (0 stk) og **ingen `three`/`webgl`-streng i markup** — orbene monteres client-side. Det betyr: ingen blank-canvas-felle for no-WebGL-brukere. Orb = progressiv forbedring, ikke avhengighet.
- **Orb-chunk er IKKE i initial preload** (ingen three/orb/webgl i de 21 preloadede chunkene) → lazy-loadet. Bra for både degradering og perf.
- **Caveat:** Ingen `<noscript>`-fallback på noen av sidene (0 på både / og /command-room). SSR-innholdet er der, men interaktive deler (kommandobar, voice, agent-dispatch) krever JS. Akseptabelt for et internt dashboard; verdt en bevisst beslutning, ikke en bug.

## (b) Reduced-motion-gating på de nye orbene — GOOD, med én liten luke

- **62 motion-reduce-treff** i /command-room: 55× `motion-reduce:transition-none`, 6× `motion-reduce:animate-none`, 1× `motion-reduce:hover:scale-100`.
- Mic-visualizeren (bar-equalizer) har `motion-reduce:transition-none` på hver bar → height-animasjonen stopper ved reduced-motion. Bekreftet gating på den nye voice-komponenten.
- **Luke:** `animate-pulse` (8×) og `animate-spin` (1×) er **ikke** motion-reduce-gated. Disse er loading-skeleton/spinner (transient «loading…»-states), så lav severity — men streng prefers-reduced-motion-policy bør dekke dem også.
- three.js-orbenes interne RAF-animasjon kan ikke verifiseres fra SSR (kjører i client-JS). **code-2 bør bekrefte i browser at orbene faktisk respekterer `prefers-reduced-motion` ved mount** — markup-gatingen dekker bare CSS-transitions, ikke WebGL-render-loopen.

## (c) A11y for voice-first-økten — STRONG

- **80 aria-label**, semantisk presise: «Command input», «Send command», «Microphone idle», «Talk to Nexus» (3×), «Chief — focus the command bar», «Open Nexus assistant», «System health pill», «Spatial zones», + per-agent «Ask/Dispatch/Logs» (22× hver).
- **4× `aria-live="polite"`** på `role="status"`-regioner (Meeting/transcript-paneler) → streaming-transcript blir annonsert til skjermlesere. Live-region finnes.
- **Mic = `role="img"` + `aria-label="Microphone idle"`** → equalizeren er korrekt eksponert som statisk bilde med tilstand, ikke støy.
- **Keyboard-path: STERK.** 95 ekte `<button>` (kun 16 `div role="button"`), **249 focus-visible/focus:ring/focus:outline-treff**, 38 tabindex. Kommandobaren har ⌘K-snarvei. Voice-features er nåbare via ekte knapper.
- **177 aria-hidden** → dekorativt (svg-ikoner/orb-host) er skjult for AT. Riktig mønster.
- Liten merknad: 16 `div role="button"` bør verifiseres for keydown-handlers (Enter/Space) i browser — `role=button` på div krever manuell key-håndtering. code-2-lane.

## (d) Perf-risiko — MODERAT (payload), LAV (bundle/WebGL)

- **SSR-payload: /command-room 175 KB vs / 57 KB, /talk 51 KB, /cockpit 43 KB, /agents 48 KB** → 3–4× tyngre rå-HTML. Men **gzip-wire: 15,2 KB vs 8,5 KB home** — reell overføring er grei.
- **JS-bundle-delta er liten:** 21 unike preloadede chunks vs 20 på home. Tyngden ligger i inline RSC/HTML for det rike boardroomet, ikke i ekstra JS. Bra.
- **«3 samtidige WebGL-kontekster»:** kan ikke telles fra SSR (0 canvas i markup; monteres client-side). **MÅ verifiseres i browser av code-2.** Risiko er reell hvis 3 separate `<canvas>`-WebGL-kontekster kjører RAF samtidig på lav-end/integrert GPU eller laptop på batteri. Anbefal: del én delt renderer/scene, eller pause off-screen orber via IntersectionObserver.
- 175 KB inline HTML parses på main-thread før hydrering → kan gi en TBT-spike på treg CPU. code-2 sin Playwright-kjøring bør fange TTI/TBT.

---

## Konkrete quick-wins (alle ai-2-lane — kun forslag)

1. **Utvid reduced-motion til orb-render-loopen.** Sjekk `window.matchMedia('(prefers-reduced-motion: reduce)')` i three.js-mount og frys/sakk RAF-loopen. CSS-gatingen dekker bare transitions, ikke WebGL.
2. **Pause off-screen WebGL-kontekster.** IntersectionObserver → stopp RAF når en orb ikke er synlig; vurder én delt renderer for 3 orber i stedet for 3 kontekster. Senker GPU/batteri-trykk.
3. **Legg `motion-reduce:animate-none` på `animate-pulse`/`animate-spin`** (9 skeleton/spinner-states) for konsekvent reduced-motion-policy.
4. **(valgfri) `<noscript>`-banner** med «Aktiver JavaScript for kommandobar + voice» — SSR-innholdet vises uansett, men setter forventning for no-JS-brukere.
5. **(vurder) Trim 175 KB inline SSR** hvis TBT er høy i browser-måling — f.eks. defer tunge paneler under fold. Lav prioritet siden gzip-wire kun er 15 KB.

---

## Delta mot tidligere audit (DASHBOARD-AUDIT-REPORT.md)

- **R1/G1 trust-bug står fortsatt på HOME (ikke fikset):** / sin SSR viser fremdeles statisk «Nexus is in WATCH mode. Market read pending. No-trade bias holds…» — ikke wiret til live (live = -$554/100% daily loss iht. brief). Helse-pill = `bg-warn`. Briefingen er fortsatt avledet/statisk, ikke live. **Utenfor /command-room-scope, men bekreftet at den ikke er løst.**
- **R5 døde 404-ruter:** `/operator-console`, `/broker-bots`, `/decision-threads`, `/trade-explorer` → fremdeles **404**. `/learning-loop` → nå **200** (én av de tidligere fikset/lagt til).
- **/api/chief (#183):** ikke testet her (POST/contract-test ligger utenfor read-only markup-scope; egen contract-sjekk anbefales).

---

*Read-only prod-sjekk. Ingen kode endret. Browser-/WebGL-kontekst-telling + orb-RAF-reduced-motion + role=button keydown gjenstår for code-2 sin Playwright-lane.*
