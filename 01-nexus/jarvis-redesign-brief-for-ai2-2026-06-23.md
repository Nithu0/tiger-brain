# Jarvis frontend-redesign — research-pakke for ai-2 (2026-06-23)

> Operatør-brief (full redesign-spec) levert til ai-1; dashboard er ai-2s lane → pakket her. Grunnet i live-verifisering + design/UX-research + audit av hva som ALT finnes. ai-1 implementerer IKKE frontend.


## Kjernedom
Dashboardet er LARGELY BUILT (Jarvis-lag + ui-kit + tokens + /jarvis-backend shippet). Redesign = (a) IA-konsolidering 36→6 soner + drep ~5 duplikat-rute-par, (b) wire live /jarvis/ask + /jarvis/brief (swap-punkter dokumentert — størst konkret vinning), (c) gjør WATCH/tom-tilstand intensjonell + 'Needs Attention Now'-triage + 'since you last looked', (d) design-polish (orb-as-status, explain-why-everywhere, ⌘K-that-acts, decision-timeline). Respekterer 'ikke bygg om det som funker'.


## Backend-contracter LIVE for ai-2 å wire (verifisert 200 på prod)
- GET/POST /jarvis/ask → {action: JarvisAction, answer, evidence?, asOf, source} (swap-punkt: resolveIntentRemote i intent-router.ts)
- GET /jarvis/brief → JarvisBriefing + spoken (TTS-klar)
- GET /jarvis/why-no-trade → DecisionThread-shape
- LOCAL_LLM_BASE_URL-seam først → pek på code-1 GPU når oppe


---

## browser-verify live dashboard (playwright)
**All 6 routes render HTTP 200 with no React-crash markers; Jarvis layer (orb /talk, command bar, briefing, Explain Mode, Mission Control) is live in markup — but browser MCP was locked by a sibling firm pane, so this is curl/SSR-grounded, not screenshot-grounded.**

## Browser MCP unavailable — fell back to curl + SSR HTML

The Playwright MCP could not be used: the shared Chrome profile (`/home/nithu/.cache/ms-playwright-mcp/mcp-chrome-7fdd7b7`) is held by another firm pane's chrome (pid 1502919). Every `browser_navigate` returned `Browser is already in use ... use --isolated`. Killing it would disrupt that pane, so I did not. **No screenshots were captured.** All findings below are from `curl` (HTTP status + full server-rendered HTML), which is strong for "does it render / crash / what's the structure" but cannot confirm animation, hydration-time behavior, or live-data widgets that render client-side.

ai-2: if you need screenshots, run the MCP with `--isolated` (separate profile) or from a pane where no other chrome is attached.

## Per-route results (curl, 2026-06-23 ~00:48Z)

| Route | HTTP | `<title>` | SSR content | Real Next.js error marker (`__next_error__`/`digest`) |
|---|---|---|---|---|
| `/` (Mission Control) | 200 | Nexus — XAUUSD Investment Operating System | 3717 chars, full UI | 0 |
| `/talk` | 200 | **Talk to Nexus** (own title) | 916 chars, orb cockpit | 0 |
| `/analytics` | 200 | Nexus — … | 460 chars (client-rendered, "Loading…") | 0 |
| `/live-reasoning` | 200 | Nexus — … | 2411 chars, rich SSR | 0 |
| `/system` | 200 | Nexus — … | 1784 chars, full settings UI | 0 |
| `/positions` | 200 | Nexus — … | 477 chars (client-rendered) | 0 |

**No #161 / React #185 class crash detected on any route, including `/system`.** The "500" and "This page could not" strings I initially flagged are false positives: "500" = Tailwind color classes (`green-500`), and "This page could not be found" = the standard Next.js 404 boilerplate embedded in the RSC payload (`notFound` branch), not a rendered error. Zero `__next_error__` / `nextjs-portal` / `digest` markers anywhere — the SSR pass is clean. (Caveat: client hydration errors wouldn't show in SSR HTML; only a real browser confirms those. But the build is rendering real, content-rich markup on every route.)

## Jarvis layer — confirmed present in markup

- **Command bar**: global, placeholder "Ask Nexus what matters now…" with ⌘K affordance, present in the shell on every page (appears 3x in root). No `placeholder=` attr extracted (likely a contenteditable/custom input, not a native `<input placeholder>`).
- **Orb cockpit `/talk`**: distinct route + title "Talk to Nexus". SSR text: "Click the orb to talk, or type. Ask for a chart, the market pulse, the best strategy, positions, or why we're not trading — it appears on the stage." Quick-action chips rendered server-side: **Show gold chart · Market pulse · Best strategy · Positions · Why no trade · Briefing**. Empty-stage state: "Nothing on stage yet." Orb element is in markup ("Tap to talk"); whether it *animates* needs a real browser.
- **Briefing card** (home): "Jarvis briefing" card renders a real synthesized line — "Nexus is in WATCH mode. Market read pending. No-trade bias holds: no candidate has crossed its conviction floor." with actions **Show evidence · Open decision thread**.
- **Mission Control (home)**: "Command Center — Live oversight of the autonomous firm." Status strip: All systems OK · PnL +$0.00 · Bots 0/0 · Open Positions 0 · Regime — · Broker —. Market Pulse card (NEUTRAL, 0% strength, "unknown setup", "Analyzing thesis…"). Auto-update feed ("Offline / Quiet — no events"). Firm equity 30-day chart (DEMO). System mode banner: **WATCH** with actions Start briefing · Explain current state · Open decision thread · View risk.
- **Explain Mode**: confirmed on `/system` — "Explain mode on by default — Start each screen with the explain…".
- **`/system` settings**: Trading mode = SIMULATION / paper, **Locked** ("no one-click switch to live capital … operator-gated backend change") — good, matches operator safety posture. Voice: off by default, mic never auto-opens; STT/TTS show "Not supported in this browser — text only" (that's the curl UA; real browser may differ). TTS engine toggle Browser/ElevenLabs.
- **`/live-reasoning`**: rich — "latest cycle · per-strategy evaluator state · gate flow · why-no-trade", H1 firm chart, Economic Calendar, and a **Cycle Scope radar** ("a ping travels out through strategies → gates → decision → execution … Green=trade opened, amber=proposed not taken, red=blocked by gate, grey=quiet round"). This is the most differentiated, on-brand view in the app.

## Clutter / UX rough edges (the real redesign signal)

- **Nav is large and deep: 41 `<a>` links on home, 21 on `/system`.** Routes seen: `/ /analytics /backtest /bots /broker /calibration /console /eod /explorer /firm-agents /fusion /hour-stats /journal /managers /memory /memory-trend /morning /notifications /positions /providers /pulse /readiness /registry /reviews /risk /signals /strategies /strategies-live /talk /team /threads /validation /weaknesses` plus `/audit /jobs /system`. That's ~36 distinct destinations.
- It IS grouped (SSR shows group labels: **Overview, Trading, Learning Loop, Operator Console, System**), so it's not flat chaos — but the surface area is huge. Several near-duplicate pairs invite consolidation: `/strategies` vs `/strategies-live`, `/memory` vs `/memory-trend`, `/analytics` vs `/pulse` vs `/hour-stats`, `/console` vs `/system`, `/morning` vs `/eod` vs `/notifications`. This is the clearest clutter to attack in a redesign.
- Home does double duty as both Mission Control AND a link hub to 36 pages — competing with the Jarvis "ask, it appears on the stage" paradigm. The brief's vision (Jarvis answers, surfaces the right view) is partially realized on `/talk` but the home page still leans "dashboard-of-everything."
- `/analytics` and `/positions` SSR almost nothing (just shell + "Loading…") — heavy client-side fetch. Fine functionally, but means first paint is empty; a redesign should consider SSR/streaming for these so they don't feel dead on load.

## Current state vs redesign-brief Mission Control vision — gap list

1. **Realized**: orb cockpit, global command bar, briefing card, Explain Mode, Mission Control status strip, cycle-scope radar, paper-mode lock. The Jarvis primitives all exist and render server-side — this is past the "scaffolding" stage.
2. **Gap — two competing IAs**: a Jarvis "stage" model (`/talk`) and a classic 36-link nav coexist. Brief wants Jarvis to be the front door; today the mega-nav still dominates the chrome on every page.
3. **Gap — empty/quiet everywhere**: PnL $0, 0 bots, NEUTRAL pulse, "Offline" feed, "Quiet — no events", "Analyzing thesis…". This is demo/paper reality, but visually the Mission Control reads as inert. Redesign should make the WATCH/no-trade state feel intentional and information-dense (why no trade, what would trigger one) rather than a wall of zeros.
4. **Gap — route consolidation**: ~5 near-duplicate route pairs. The vision implies fewer, smarter surfaces reachable via the orb, not 36 manual destinations.
5. **Unverified (needs real browser)**: orb animation, command-bar query flow (I could NOT test typing "why no trade" — browser was locked), voice, hydration-time console errors, and whether the briefing/pulse cards populate with live data after hydration. **These are the highest-value things for ai-2 to screenshot-verify before redesigning.**

### Top actionable
For ai-2, concrete next steps:

1. BROWSER WAS LOCKED — I have no screenshots and could NOT test the command-bar query flow ("why no trade"), orb animation, or hydration errors. Re-run Playwright MCP with `--isolated` (separate chrome profile) so it doesn't collide with the 8 firm panes sharing `/home/nithu/.cache/ms-playwright-mcp/mcp-chrome-7fdd7b7`. This is the single biggest gap in this verification.

2. Good news for redesign baseline: all 6 routes return 200 and SSR clean content with ZERO real Next.js error markers — no #161/React-#185-class crash, including /system (the route that crashed before). Build is runtime-healthy at the SSR level.

3. Jarvis layer is genuinely shipped (not stubs): /talk has its own "Talk to Nexus" title + orb + quick-action chips (Show gold chart, Market pulse, Best strategy, Positions, Why no trade, Briefing); home has a Jarvis briefing card with a synthesized WATCH-mode line + "Show evidence / Open decision thread"; Explain Mode is on by default; /system locks paper-mode (operator-gated). Treat these as keep-and-polish, not rebuild.

4. Primary clutter target: 41 nav links on home / ~36 distinct routes. It IS grouped (Overview / Trading / Learning Loop / Operator Console / System) but huge. Consolidate near-duplicates: /strategies vs /strategies-live, /memory vs /memory-trend, /analytics vs /pulse vs /hour-stats, /console vs /system, /morning vs /eod vs /notifications.

5. Core IA tension to resolve in the redesign: the Jarvis "ask → it appears on the stage" model (/talk) competes with a classic 36-link mega-nav present on every page. Brief wants Jarvis as the front door; pick one dominant paradigm.

6. /analytics and /positions SSR nothing but a shell + "Loading…" (client-fetch) — empty first paint; consider SSR/streaming in the redesign.

---

## design inspiration (web/youtube/social)
**18+ cited, function-checked design patterns for the Nexus gold control center — orb-as-status, ⌘K that acts, a "what matters now" hero, severity-coded feed, traceable decision timeline, and contextual "explain why" AI — all dark/amber/calm with motion gated behind prefers-reduced-motion**

## Design inspiration digest — Nexus gold control center

Scope: dark mode, gold/amber + subtle cyan AI accents, premium/calm (not gaming neon, not chaotic sci-fi), readable, `prefers-reduced-motion` honored. Every idea below is sanity-checked for FUNCTION, not decoration. I've flagged the few that risk being eye-candy.

Color/contrast baseline to honor across all of it (multiple sources agree): avoid pure black `#000000` (harsh) and pure white text (visual vibration) — use a dark gray/navy base (~`#0d1117`/`#121212`) with off-white text (~`#E0E0E0`), accents used sparingly. Sources: [Lollypop trading app guide](https://lollypop.design/blog/2026/june/trading-app-design/), [Qodequay dark mode](https://www.qodequay.com/dark-mode-dashboards), [UX Design Institute dark mode](https://www.uxdesigninstitute.com/blog/dark-mode-design-practical-guide/).

---

### ORB / VOICE (the "Jarvis" element)

**1. Orb state = system state, not decoration.** The orb should encode listening / thinking / speaking AND firm-cycle state (idle, running cycle, trade fired, gate-blocked) through distinct, low-energy animations — breathing for idle, gentle amplitude modulation reacting to real audio for voice, a slow pulse for "cycle running." This is the audio-reactive pattern in production orb libs ([orb-ui by alexanderqchen](https://github.com/alexanderqchen/orb-ui), [voice-reactive orb in React](https://medium.com/@therealmilesjackson/building-a-voice-reactive-orb-in-react-audio-visualization-for-voice-assistants-2bee12797b93)). FUNCTION CHECK: passes — the orb becomes an ambient status indicator you read peripherally, not a logo. Map states to amber (active/working) and a cyan tint only for "AI is reasoning/speaking" so the rare cyan reads as "the assistant is thinking."
*Adversarial note:* the multi-blob multicolor gradient orbs in fan JARVIS builds ([my-jarvis](https://github.com/harsh-raj00/my-jarvis), [jarvis_ai](https://github.com/eadmin2/jarvis_ai)) are pure spectacle. Borrow the single audio-reactive sphere; reject the particle-storm boot sequences.

**2. Calm material, not glow-blast.** The Spline/OpenAI orb tutorial gets the premium look from translucency: glossy translucent material, tuned opacity/blur/thickness, soft calming color — not neon emission. Source: [Spline + OpenAI voice assistant](https://www.jackredley.design/articles/how-to-create-an-ai-voice-assistant-using-spline-and-openai). FUNCTION CHECK: this is the difference between "premium calm" and "gaming neon" the brief demands — it's a direct lever.

**3. Reduced-motion fallback is mandatory and easy here.** None of the orb sources implement `prefers-reduced-motion` (I verified — it's absent). So this is a gap Nexus must fill itself: when reduced-motion is set, swap the breathing/ripple for a static orb with a small state dot or a single opacity step on state change. FUNCTION CHECK: passes — state is still legible without motion. This is the one place the references are weak; treat it as a known TODO, not a solved pattern.

**4. The orb anticipates; it doesn't always-on broadcast.** Jayse Hansen's actual Iron Man HUD principle: the AI "anticipates graphical feedback needs based on context, task purpose and urgency" and the diagnostic widget expands/collapses to the tier needed. Source: [Jayse Hansen FUI portfolio](https://jayse.tv/v2/?portfolio=hud-2-2). Borrow: the orb surfaces a one-line "what it's doing/why" on hover or when something notable happens, and stays quiet otherwise. The minimalist-JARVIS critique reinforces this — the canonical movie HUD is "overly cluttered" and a good redesign is "seamless, minimal, nearly invisible," surfacing only essential info at the right time. Source: [Redesigning JARVIS UX](https://medium.com/fictional-products-for-fictional-worlds/redesigning-the-jarvis-ux-a-minimalist-approach-to-a-genius-system-208b39113e8d).

---

### COMMAND BAR

**5. ⌘K does things, not just finds things.** Standard pattern: a command palette is for *doing*, distinct from search; ⌘K (or ⌘⇧P) is the expected shortcut. For Nexus: "pause firm," "show last 5 gate-blocks," "explain why no trade today," "open EURUSD position," "run reconciliation." Sources: [UX Patterns command palette](https://uxpatterns.dev/patterns/advanced/command-palette), [Mobbin command palette glossary](https://mobbin.com/glossary/command-palette), [Medium command palette UX](https://medium.com/design-bootcamp/command-palette-ux-patterns-1-d6b6e68f30c1).

**6. Scoped/contextual commands are where it earns its keep.** Solomon: "knowing what the user will want in a given situation is where the super powers come from" — on a position page offer "close / adjust SL / explain entry"; during a running cycle offer "skip / show gate trace." Surface popular + recent commands before any typing. Sources: [Designing Command Palettes (Solomon)](https://solomon.io/designing-command-palettes/), [Pencil & Paper dashboards](https://www.pencilandpaper.io/articles/ux-pattern-analysis-data-dashboards). FUNCTION CHECK: strong — context-scoped actions cut clicks on the exact workflows an operator repeats.

**7. Natural-language query as a first-class palette result type.** Since Nexus has an AI assistant, the bar can route a typed question ("why are we flat?") to the assistant and render the answer inline, alongside literal command matches. Decide the handoff boundary explicitly (execute inline vs. close + focus a view) — VS Code does inline, Obsidian closes-and-focuses; both valid. Source: [Solomon](https://solomon.io/designing-command-palettes/). FUNCTION CHECK: passes if the bar visually separates "commands" from "ask the assistant" so it doesn't feel like a gimmick chatbox.

---

### MISSION CONTROL HERO ("what matters now")

**8. Critical metrics upper-left, max ~5 elements per view.** Natural scan path puts the highest-priority KPI top-left; cap visible elements to ~5 and push secondary data to lighter weights at the edges. For Nexus the hero answers: are we trading, P&L today, open risk, last decision, system health. Source: [Smashing real-time dashboards](https://www.smashingmagazine.com/2025/09/ux-strategies-real-time-dashboards/). FUNCTION CHECK: core — this is the "what matters now" hero the brief wants.

**9. Connect every metric to an action / a "why."** Don't show numbers in a vacuum — pair them with thresholds, indicators, and a next step (color-coded badge or CTA tied to the insight, explaining the *why* and the *what to do*). Source: [Smashing](https://www.smashingmagazine.com/2025/09/ux-strategies-real-time-dashboards/), [Allclonescript 20 principles](https://medium.com/@allclonescript/20-best-dashboard-ui-ux-design-principles-you-need-in-2025-30b661f2f795). FUNCTION CHECK: this is the spine of "dashboard that explains itself."

**10. Binary status indicators over ambiguous gauges.** "Trading / Paused," "Broker OK / Stale," "Reconciled / Drift" — clear on/off states with supporting context beat fuzzy dials and remove interpretation overhead. Source: [Smashing](https://www.smashingmagazine.com/2025/09/ux-strategies-real-time-dashboards/). FUNCTION CHECK: strong for an ops control room.

**11. Data-freshness is a first-class UI element.** Show "Data as of 10:42", Live/Stale/Paused status, and skeleton placeholders (not spinners) while loading; on outage show last cached snapshot with its timestamp rather than a blank. Source: [Smashing](https://www.smashingmagazine.com/2025/09/ux-strategies-real-time-dashboards/). FUNCTION CHECK: essential for a live trading system — a stale number presented as live is a real money risk, so this is functional, not cosmetic.

---

### FEED (severity-coded activity)

**12. Color + icon + label for severity, never color alone.** Red/orange = critical/negative, green/blue = positive/stable, gray = background; always redundant-code with an icon or text (1-in-12 men are color-blind). Source: [Smashing](https://www.smashingmagazine.com/2025/09/ux-strategies-real-time-dashboards/), [Saurav Kumar audit trail](https://www.sauravkumar.com/2025/05/09/key-considerations-for-audit-trail-for-an-application/). FUNCTION CHECK: accessibility + fast triage — clearly functional.

**13. Sortable/filterable card grid by severity, recency, relevance.** Feed entries as consistent cards you can filter — operator can collapse to "critical only" during volatility. Source: [Smashing](https://www.smashingmagazine.com/2025/09/ux-strategies-real-time-dashboards/). FUNCTION CHECK: passes.

**14. Micro-animation as change-signal, 200–300ms, function-only.** Fade-in on a new number, gentle pulse on a metric that changed, smooth reorder when the feed re-ranks — all under ~300ms so it signals "this just changed" without distraction. Source: [Smashing](https://www.smashingmagazine.com/2025/09/ux-strategies-real-time-dashboards/), and Hansen's "motion as information" (transitions communicate state change, never decorate) [Jayse Hansen](https://jayse.tv/v2/?portfolio=hud-2-2). FUNCTION CHECK: passes *only* if each animation marks a real state change; gate all of it behind `prefers-reduced-motion`.

---

### DECISION TIMELINE

**15. Pick the right "visual grammar" per tempo — and Nexus needs three.** The four audit grammars: List (scan high-volume), Detail (explain, evidence-grade), Timeline (reveal progression/causality), Aggregated (interpret patterns). A trade decision is best as Timeline → drill to Detail; the cycle log is List; analytics is Aggregated. Match the layout to "the tempo of the user's world." Source: [Designing the Audit Trail (Niedringhaus)](https://medium.com/@dnied/designing-the-audit-trail-how-systems-remember-5c833814deec). FUNCTION CHECK: core to a system whose selling point is explainability.

**16. Structured event schema → before/after + correlation IDs.** Each decision event carries actor, action, decision/policy, before/after change, context, and a correlation_id so a trade can be traced end-to-end (signal → gates → sizing → execution). Source: [Swept AI audit trail](https://www.swept.ai/ai-audit-trail), [Niedringhaus](https://medium.com/@dnied/designing-the-audit-trail-how-systems-remember-5c833814deec). FUNCTION CHECK: this is the data backbone that lets "explain why" actually work — high value for Nexus specifically given its gate/cycle architecture.

---

### STRATEGY / POSITION CARDS

**17. Delta indicators + sparklines, latest point highlighted.** Each card shows direction arrow + % delta (▲ +3.2%) and a compact axis-less sparkline (7–30 day window) with the latest point dotted. Source: [Smashing](https://www.smashingmagazine.com/2025/09/ux-strategies-real-time-dashboards/). FUNCTION CHECK: dense, glanceable, functional.

**18. Progressive disclosure: summary card → expand to detail.** Borrow Hansen's radial "expand/collapse to whatever tier of info is required" and the dashboard collapsible-section pattern: card shows P&L + status; expand for entry rationale, gate trace, risk. Sources: [Jayse Hansen](https://jayse.tv/v2/?portfolio=hud-2-2), [Smashing](https://www.smashingmagazine.com/2025/09/ux-strategies-real-time-dashboards/), [UXPin dashboard principles](https://www.uxpin.com/studio/blog/dashboard-design-principles/). FUNCTION CHECK: this is how you get Bloomberg-grade density without clutter.

---

### EXPLAIN MODE

**19. AI insight lives at the point of action, contextually — never as a separate panel.** Embed the AI signal/explanation into the specific position/event it concerns, not a competing notification layer or isolated "AI dashboard." Sources: [Lollypop AI trading UX](https://lollypop.design/blog/2025/june/ai-stock-trading-ux-design-revolution/), [dredyson AI trading dashboards](https://dredyson.com/how-ai-powered-ui-ux-generation-can-supercharge-quant-research-dashboards-and-trading-interfaces-a-complete-step-by-step-guide-for-algorithmic-traders-python-developers-and-financial-engineers-buil/). FUNCTION CHECK: directly addresses "bring it alive" without adding noise.

**20. "Explain Why" + cited sources + confidence, never black-box.** Every AI statement cites which signals fed it ("based on 3+ corroborating signals") and shows a confidence level; differentiate high-confidence from exploratory. Pair with an interactive "Why this alert?" tooltip exposing the trigger logic. Sources: [Lollypop](https://lollypop.design/blog/2025/june/ai-stock-trading-ux-design-revolution/), [Smashing](https://www.smashingmagazine.com/2025/09/ux-strategies-real-time-dashboards/). FUNCTION CHECK: this is what makes the AI feel trustworthy vs gimmicky — the single most important "alive" pattern, and it aligns with Nexus's explainability ethos.

**21. Voice/text/pointing onboarding ("Hey Dashboard").** Academic-grade pattern: a multimodal in-dashboard assistant (voice + text + pointing/lasso to a chart) gives *situated* explanations of what a chart means, plus a contextual radial menu of features. Source: ["Hey Dashboard!" arXiv 2510.12386](https://arxiv.org/html/2510.12386v1). FUNCTION CHECK: ambitious but the borrowable nugget is small and practical — let the operator point/click any tile and ask "what is this?" and have the assistant explain it in place. That's the literal "dashboard that explains itself."

**22. Empty states as onboarding moments.** No trades yet / market closed / no alerts → show what the populated view will look like + a clear next step, instead of a blank pane. Source: [Smashing](https://www.smashingmagazine.com/2025/09/ux-strategies-real-time-dashboards/), [uxstudio dashboard design](https://www.uxstudioteam.com/ux-blog/dashboard-design). FUNCTION CHECK: passes — turns dead screens into orientation.

---

### MOTION (cross-cutting)

**23. Motion is information or it's off.** Every animation must mark a real state change (Hansen: collapsing a panel *reveals* the next state; it's never decorative). Keep durations 200–400ms. Gate ALL of it behind `prefers-reduced-motion` with a legible static fallback. Sources: [Jayse Hansen](https://jayse.tv/v2/?portfolio=hud-2-2), [Smashing](https://www.smashingmagazine.com/2025/09/ux-strategies-real-time-dashboards/). This is the brief's "animations must have function" rule restated by the actual Iron Man UI designer — use it as the acceptance test for every motion PR.

---

### What I couldn't verify / open questions

- **No single great YouTube walkthrough surfaced** for a dark amber/gold AI-trading dashboard specifically. The YouTube results were generic dark-mode dashboard tutorials ([Adobe XD dark dashboard](https://www.youtube.com/watch?v=oy68uWEo8GU), [light/dark dashboard build](https://www.youtube.com/watch?v=n3hkpnOFr0A)) — useful for technique, not for the gold/Jarvis aesthetic. If the operator wants moving-image references, Behance/Dribbble searches for "trading terminal" ([Behance](https://www.behance.net/search/projects/trading%20terminal), [Dribbble bloomberg-terminal](https://dribbble.com/search/bloomberg-terminal)) are better visual hunting grounds than YouTube.
- **Bloomberg's own "concealing complexity" article was 403-blocked** (paywall/bot-block). The density+command-driven principles above come from the redesign-concept summaries and the FUI/dashboard sources, not Bloomberg's primary text. Medium confidence on attributing those specific techniques to Bloomberg.
- **`prefers-reduced-motion` in orb libs: confirmed absent.** Treat as Nexus's own build work, not a copyable pattern.
- Confidence overall: high on the dashboard/feed/explain/motion patterns (multiple converging sources incl. the Smashing 2025 piece); medium on the orb specifics (mostly dev libs + fan projects, only Hansen is authoritative FUI).

### Top actionable
For ai-2, in priority order:

1. ORB AS STATUS (not logo): single audio-reactive translucent sphere; amber = active/working, rare cyan tint = "AI reasoning/speaking"; breathing idle, amplitude-modulated on voice, slow pulse on cycle-running. Build a `prefers-reduced-motion` fallback yourself (static orb + state dot) — the reference libs don't ship one. Refs: orb-ui (github.com/alexanderqchen/orb-ui), Spline+OpenAI tutorial, Jayse Hansen FUI.

2. EXPLAIN-WHY EVERYWHERE (highest "alive" payoff, fits Nexus's explainability ethos): every AI statement cites its signals + shows confidence; "Why this alert?" tooltip exposes trigger logic; AI insight rendered IN the position/event it concerns, never a separate panel. Refs: Lollypop AI-trading UX, Smashing 2025.

3. MISSION CONTROL HERO: critical KPIs top-left, ≤5 elements, every metric paired with a threshold + next-step CTA; binary status chips (Trading/Paused, Broker OK/Stale, Reconciled/Drift); first-class data-freshness ("as of 10:42", Live/Stale/Paused, skeletons not spinners, cached snapshot on outage). Ref: Smashing real-time dashboards.

4. ⌘K THAT DOES THINGS: scoped/contextual commands (pause firm, explain why flat, close position, run reconciliation) + a "ask the assistant" result type visually separated from literal commands; surface recent+popular before typing. Refs: Solomon command palettes, Mobbin, UX Patterns.

5. DECISION TIMELINE with correlation IDs: trade = Timeline→Detail drill-down; event schema carries before/after + correlation_id so signal→gates→sizing→execution is traceable end-to-end. Refs: Niedringhaus audit-trail, Swept AI.

6. MOTION ACCEPTANCE TEST: every animation marks a real state change, 200–400ms, all gated behind prefers-reduced-motion with a legible static fallback. Reject decorative particle/boot-sequence sci-fi. Ref: Jayse Hansen "motion as information", Smashing.

Caveat: no strong gold/amber YouTube walkthrough exists — point ai-2 at Behance/Dribbble "trading terminal" for moving visual refs instead.

---

## UX patterns: self-explanatory complex dashboards
**14 cited UX patterns to make Nexus self-explanatory: lead with a triage feed + "what changed", collapse 50 routes into 6 zones via command-palette + drawers, kill fake-data-without-label, and label every stale/empty state.**

## What I'm answering

How to make a data-dense expert trading dashboard self-explanatory and less cluttered. Grounded in the actual Nexus dashboard, which today has **50+ routes** and an **8-group sidebar with ~45 items** (`apps/dashboard/src/components/Sidebar.tsx:19-128`) — the clutter is structural, not cosmetic. There's already a working `CommandPalette.tsx` (modal, ⌘K, nav-only — 30 hardcoded routes) and a `LiveActivityFeed.tsx`, so several patterns below are upgrades to existing code rather than greenfield.

Note up front: the brief's 6 zones (Mission Control / Strategy Lab / Positions / Market Intelligence / AI Agents / System) do **not** match the current 8 sidebar groups (Command / XAUUSD / Trading / Strategy / Agents / System / More + the palette's own "Markets/More" taxonomy). That mismatch is itself a finding — the IA needs one canonical 6-zone model, used identically in sidebar, palette, and breadcrumbs.

Confidence: high on the patterns and product precedents (well-documented); medium on exact Nexus screen mapping (I read the route list + sidebar + palette, not every page body).

---

## Prioritized patterns (most leverage first)

### 1. Severity/triage feed — "what needs attention now"
**Pattern:** A short, ranked list of things that need a human, classified by severity (SEV-1..3 / P1..P3). Keep the level count small — "defining a limited number of levels is essential for effective triage" ([PagerDuty](https://support.pagerduty.com/main/docs/incident-priority)). Datadog's tiered alerts route by urgency so low-priority noise doesn't get the same weight as a page ([Datadog](https://www.datadoghq.com/blog/tiered-alerts-urgency-aware-alerting/)).
**Does it well:** PagerDuty incident list, Datadog monitor view.
**Nexus zone:** Mission Control (top of `/`). This is the single highest-leverage fix for "hard to know what matters now." Source it from the existing `LiveActivityFeed` + health/gate state. Cap at ~5 items; each row deep-links to the owning screen (Positions / Strategy Proposals / System).
**Do:** 3 severity levels max, each item one sentence + a "go fix" link, sort by severity then recency. **Don't:** show every event (that's a feed, not triage — "a widget that shows every entry to every user is a feed, not a communication tool" [frill/ReleasePad framing](https://www.releasepad.io/blog/in-app-changelog-widgets-build-vs-buy/)); don't auto-disable anything off the back of it (operator-prinsipp 1 — report, don't act).

### 2. "Since you last looked" digest
**Pattern:** A changelog/activity digest of what changed since the user's last session, keyed off a stored last-seen timestamp; a dot/badge signals "something new" ([UX Patterns activity feed](https://uxpatterns.dev/patterns/social/activity-feed); [Flows in-app changelog](https://flows.sh/examples/in-app-changelog)). Frequent small entries beat infrequent comprehensive ones for perceived freshness.
**Does it well:** Linear's inbox, GitHub's "what you missed."
**Nexus zone:** Mission Control header strip — changed positions, new strategy proposals awaiting Karri, gate flips, alerts fired while away.
**Do:** make it dismissible and scoped to the operator. **Don't:** dump a raw event log; summarize ("3 positions closed, +$X; 1 proposal pending review").

### 3. Six zones in the sidebar, everything else in the palette
**Pattern:** Command palettes "solve the tension between feature-rich applications and clean interfaces" and let you "build features that could never warrant a button or a dropdown … so you can avoid cluttering the UI" ([Superhuman](https://blog.superhuman.com/how-to-build-a-remarkable-command-palette/); [Medium UX Patterns](https://medium.com/design-bootcamp/command-palette-ux-patterns-1-d6b6e68f30c1)). Cmd+K is now standard across Linear/Vercel/GitHub/Slack/Raycast.
**Does it well:** Linear (sidebar shows ~6 things; everything else is ⌘K).
**Nexus zone:** System-wide IA. Collapse the 8 groups / 45 items into the 6 canonical zones; demote the long tail (jobs, registry, correlation, hour-stats, map, integrations, workflows…) to palette-only.
**Do:** one zone taxonomy reused in sidebar + palette + breadcrumb. **Don't:** keep a "More" bucket (current `Sidebar.tsx:122` — that's the clutter admitting defeat). The 50 routes don't all need a nav home.

### 4. Command palette = actions, not just navigation
**Pattern:** Palette should run commands and skip the linear IA, not merely jump pages — "you aren't limited by screen real estate" ([Superhuman](https://blog.superhuman.com/how-to-build-a-remarkable-command-palette/)). The current `CommandPalette.tsx` only does `router.push` (line 95-99).
**Does it well:** Raycast (keyboard-first action launcher), Linear (create/assign/toggle from ⌘K).
**Nexus zone:** all zones. Add verbs: "ack alert," "toggle shadow view," "open proposal," "jump to position #." This lets you delete on-screen buttons that don't earn their pixels.
**Do:** fuzzy match + show the keybind. **Don't:** put irreversible/money actions (real trades, gate flips) behind a fast fuzzy match — those stay explicit and confirmed (operator safety gates).

### 5. Stale-data + last-updated badge on every panel; label all synthetic data
**Pattern:** When re-fetching cached data, "show the already available data instead of a spinner" plus a second indicator for background activity ([LogRocket](https://blog.logrocket.com/ui-design-best-practices-loading-error-empty-state-react/)). Stale-while-revalidate with a visible age.
**Does it well:** Datadog (every graph has a time/freshness context).
**Nexus zone:** all six — but critical for Positions, Market Intelligence, System. Add a `last updated Xs ago` chip; flip to a "STALE" treatment past a threshold.
**Do — and this is the brief's named anti-pattern:** any sample/placeholder/synthetic number must carry a visible "DEMO/SAMPLE" label. In a money tool, an unlabeled fake number is a trust-destroyer and a decision hazard. **Don't:** render zeros or fabricated values that look real while loading — use skeletons instead (below).

### 6. Skeletons over spinners; informational/action empty states
**Pattern:** Skeleton screens "tell the user what to expect, reduce perceived loading time by ~30%, and prevent layout shift," and suit feeds/dashboards; spinners are for short blocking actions ([Onething](https://www.onething.design/post/skeleton-screens-vs-loading-spinners); [Carbon](https://carbondesignsystem.com/patterns/loading-pattern/)). Empty states should say why it's empty + what to do next ([Eleken](https://www.eleken.co/blog-posts/empty-state-ux); [Pencil&Paper](https://www.pencilandpaper.io/articles/empty-states)).
**Nexus zone:** every data screen. "No open positions" should say *why* (market closed? gates blocking?) and link to the gate state, not just render a blank table.
**Do:** match skeleton shape to real layout. **Don't:** show a spinner for a multi-panel dashboard load.

### 7. Contextual drawers instead of new tabs/pages for detail
**Pattern:** Drawers suit high-volume detail and "more complex interactions while maintaining a contextual connection to the primary task"; tabs are for content you switch between *repeatedly*; modals are for concise, focused confirm/explain ([Adobe Spectrum slideouts](https://developer.adobe.com/commerce/admin-developer/pattern-library/containers/slideouts-modals-overlays); [GitLab Pajamas drawer](https://design.gitlab.com/components/drawer/)). "Avoid drawers if users need to switch between sections repeatedly — use tabs instead."
**Does it well:** Linear issue drawer, GitLab.
**Nexus zone:** Positions (click a trade → side drawer with lineage/reasoning, don't route to `/explorer`), AI Agents (agent detail drawer), Strategy Lab (proposal drawer). This kills a big slice of the 50 routes — many of them are detail views that should be drawers off a list.
**Do:** keep the list visible behind the drawer (master-detail). **Don't:** reach for a modal when the operator needs to compare drawer content against the page (modals block that).

### 8. Decision/timeline narrative over raw tables
**Pattern:** "KPI dashboards summarize data but rarely explain why results change or how to respond … context and narrative turn dashboard views into decisions" ([ThoughtSpot](https://www.thoughtspot.com/data-trends/best-practices/data-storytelling); [IWU](https://www.indwes.edu/articles/2026/01/data-storytelling-managers-dashboards-into-decisions)). Frame each view around what happened / why / what to do.
**Does it well:** financial "what moved and why" briefings; Stripe's narrative reporting.
**Nexus zone:** Live Reasoning (`/live-reasoning`), Decision Threads (`/threads`), EOD (`/eod`), Narrative Replay (`/replay` already leans this way). Lead with the story; relegate the raw table to a "show raw data" drawer toggle.
**Do:** one sentence of interpretation per chart. **Don't:** open these screens on a dense grid the operator has to decode every time.

### 9. "Explain mode" coachmark toggle (not a forced tour)
**Pattern:** Coachmarks are toggleable annotation overlays — an "explain mode" you flip on and off ([Treehouse onboarding patterns](https://teamtreehouse.com/library/user-onboarding/onboarding-patterns-product-explanation)). Static upfront tours are "passive observation" and weak for complex tools ([Appcues](https://www.appcues.com/blog/product-tours-ui-patterns)); prefer contextual, progressive explanation.
**Does it well:** Figma/Notion contextual help toggles.
**Nexus zone:** every zone, but most valuable in Strategy Lab and AI Agents where jargon density is highest (conviction, fusion, triple-barrier, meta-label). A `?` toggle reveals inline "what is this / why it matters" without permanently spending screen space.
**Do:** off by default (operator is an expert), persistable. **Don't:** force a multi-step walkthrough on load — that's clutter for a daily user.

### 10. Progressive disclosure as the default density rule
**Pattern:** Show critical info first, hide depth behind expanders/drill-downs; IDEs expand advanced options as expertise is detected. Reported 30-50% faster initial task completion while keeping 70-90% feature discoverability ([UXPin](https://www.uxpin.com/studio/blog/what-is-progressive-disclosure/); [IxDF](https://ixdf.org/literature/topics/progressive-disclosure); [Algolia](https://www.algolia.com/blog/ux/information-density-and-progressive-disclosure-search-ux)).
**Nexus zone:** all. Each tile = headline number + trend; click/expand for the table. Directly attacks "too many tables without explanation."
**Do:** summary → expand. **Don't:** confuse progressive disclosure with hiding the one number the operator opened the screen for.

### 11. Information hierarchy: one primary metric per zone, above the fold
**Pattern:** Structure so a decision-maker quickly sees what's happening, why, and what to do; each visualization supports one key point, laid out as a logical path ([Cluster](https://clusterdesign.io/data-analysis-dashboards-storytelling/); [Bismart](https://blog.bismart.com/en/data-storytelling-cuadros-de-mando)).
**Nexus zone:** Mission Control especially. Today `/` competes with `/console`, `/cockpit`, `/managers`, `/pulse` for "the overview" — pick one primary landing answer (account state + needs-attention), push the rest down.
**Do:** one hero answer per zone. **Don't:** open with a wall of equal-weight tiles (the current "everything is a nav item" problem rendered as panels).

### 12. Keyboard-first + accessible focus, no keyboard traps
**Pattern:** WCAG 2.1 AA — all functionality keyboard-operable (2.1.1), visible focus indicators (2.4.7), no traps (2.1.2); move focus to main heading on route change; modals must Escape-out ([W3C 2.4.3](https://www.w3.org/TR/UNDERSTANDING-WCAG20/navigation-mechanisms-focus-order.html); [Vispero](https://vispero.com/resources/managing-focus-and-visible-focus-indicators-practical-accessibility-guidance-for-the-web/)). The palette already does ⌘K/Esc/arrow nav (`CommandPalette.tsx:72-112`) — extend that discipline app-wide.
**Nexus zone:** all. A keyboard-first operator tool should be fully driveable without a mouse.
**Do:** visible focus rings, focus to drawer on open + back to trigger on close. **Don't:** trap focus in a drawer with no Escape; don't trigger actions on focus (WCAG 3.2.1).

### 13. Respect prefers-reduced-motion
**Pattern:** Animations/smooth scroll can harm motion-sensitive users; gate them behind `prefers-reduced-motion` ([yanandcoffee](https://www.yanandcoffee.com/2020/05/08/accessible-smooth-scrolling-and-focus-management-solutions/)). The dashboard uses framer-motion (`CommandPalette.tsx:5,131-145`) with scale/translate/blur transitions.
**Nexus zone:** all (palette, drawers, feed). Wrap motion in a reduced-motion check.
**Do:** instant or fade-only when reduced-motion is set. **Don't:** ship neon-pulse/animated-gradient UI — the brief explicitly flags neon as an anti-pattern, and constant motion reads as a toy, not an instrument.

### 14. Voice input as enhancement, never the primary path
**Pattern:** Web Speech `SpeechRecognition` has **no Firefox support** (disabled behind a flag), needs the `webkitSpeechRecognition` prefix on Safari, is **cloud-dependent** (Chrome→Google, Safari→Apple, Edge→Azure), has inconsistent accuracy and no uptime guarantee. Best practice: always provide a fallback input, disclose recording, allow manual transcript correction ([MDN](https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognition); [caniuse](https://caniuse.com/speech-recognition); [AssemblyAI](https://www.assemblyai.com/blog/speech-recognition-javascript-web-speech-api)).
**Nexus zone:** AI Assistant / command palette mic.
**Do:** feature-detect `window.SpeechRecognition || window.webkitSpeechRecognition`, hide the mic if absent, keep the text field as the real interface, let the user edit the transcript before it runs. **Don't:** put a money action one mis-transcription away from execution; don't make voice the only way to do anything.

---

## What to explicitly avoid (brief's anti-patterns, reinforced)
- **Too many tabs/nav items** → 6 zones in sidebar; long tail in palette + drawers (patterns 3, 4, 7).
- **Neon / constant motion** → muted instrument palette, reduced-motion gate (pattern 13).
- **Fake data without a label** → mandatory DEMO/SAMPLE tag + skeletons while loading, never fabricated-looking numbers (patterns 5, 6). Highest-stakes one for a trading tool.
- **Unclear buttons** → label by outcome, route ambiguous/rare actions into the command palette where they get a description and keybind (pattern 4).

## Open questions / not verified
- I did not read every page body, so the exact current state of empty/stale handling per screen is unknown — the mapping above is from routes + sidebar + palette.
- Whether a `last-seen` timestamp is already persisted anywhere (needed for patterns 2 and the "new" badge) — not checked.
- The 6-zone names are the brief's; reconciling them with the existing 8 groups is a design decision, not something I can settle from the code alone.
- The effectiveness figures (30-50% faster, ~30% perceived load reduction) come from vendor/design blogs, not primary research — treat as directional, not hard numbers.

Sources:
- https://www.uxpin.com/studio/blog/what-is-progressive-disclosure/
- https://ixdf.org/literature/topics/progressive-disclosure
- https://www.algolia.com/blog/ux/information-density-and-progressive-disclosure-search-ux
- https://blog.superhuman.com/how-to-build-a-remarkable-command-palette/
- https://medium.com/design-bootcamp/command-palette-ux-patterns-1-d6b6e68f30c1
- https://support.pagerduty.com/main/docs/incident-priority
- https://www.datadoghq.com/blog/tiered-alerts-urgency-aware-alerting/
- https://uxpatterns.dev/patterns/social/activity-feed
- https://flows.sh/examples/in-app-changelog
- https://www.releasepad.io/blog/in-app-changelog-widgets-build-vs-buy/
- https://developer.adobe.com/commerce/admin-developer/pattern-library/containers/slideouts-modals-overlays
- https://design.gitlab.com/components/drawer/
- https://www.thoughtspot.com/data-trends/best-practices/data-storytelling
- https://www.indwes.edu/articles/2026/01/data-storytelling-managers-dashboards-into-decisions
- https://clusterdesign.io/data-analysis-dashboards-storytelling/
- https://teamtreehouse.com/library/user-onboarding/onboarding-patterns-product-explanation
- https://www.appcues.com/blog/product-tours-ui-patterns
- https://www.eleken.co/blog-posts/empty-state-ux
- https://www.pencilandpaper.io/articles/empty-states
- https://carbondesignsystem.com/patterns/loading-pattern/
- https://www.onething.design/post/skeleton-screens-vs-loading-spinners
- https://blog.logrocket.com/ui-design-best-practices-loading-error-empty-state-react/
- https://www.w3.org/TR/UNDERSTANDING-WCAG20/navigation-mechanisms-focus-order.html
- https://vispero.com/resources/managing-focus-and-visible-focus-indicators-practical-accessibility-guidance-for-the-web/
- https://www.yanandcoffee.com/2020/05/08/accessible-smooth-scrolling-and-focus-management-solutions/
- https://developer.mozilla.org/en-US/docs/Web/API/SpeechRecognition
- https://caniuse.com/speech-recognition
- https://www.assemblyai.com/blog/speech-recognition-javascript-web-speech-api

Relevant Nexus files: `apps/dashboard/src/components/Sidebar.tsx`, `apps/dashboard/src/components/CommandPalette.tsx`, `apps/dashboard/src/components/LiveActivityFeed.tsx`, `apps/dashboard/src/components/TopNav.tsx`, `apps/dashboard/src/app/page.tsx`.

### Top actionable
For ai-2, in priority order:
1. Build a "Needs Attention Now" triage feed at the top of Mission Control (SEV-1..3, max ~5 items, each links to the source screen). This is the single highest-leverage fix for "hard to know what matters now." Reuse existing LiveActivityFeed.tsx as the data source.
2. Add a "Since you last looked" digest strip (changed positions, new proposals, gate flips, fired alerts) keyed off a stored last-seen timestamp. Re-engagement pattern, cheap to build.
3. Collapse the 8 sidebar groups (~45 items in Sidebar.tsx) into the 6 named zones (Mission Control / Strategy Lab / Positions / Market Intelligence / AI Agents / System). Everything else moves into the command palette, not the sidebar.
4. Upgrade CommandPalette.tsx from nav-only to actions + nav (it currently only routes — add "run", "toggle shadow view", "ack alert" style commands so it absorbs buttons that don't deserve sidebar space).
5. Add a global stale/last-updated badge to every data panel (timestamp + "stale" state when fetch age exceeds threshold) and a hard rule: any synthetic/sample data must carry a visible "DEMO/SAMPLE" label. The brief's fake-data-without-label anti-pattern is a trust-killer in a money tool.
6. Replace raw tables on decision-heavy screens (Live Reasoning, Decision Threads, EOD) with a timeline/narrative view that says what happened, why, and what to do — table stays as a "show raw" drawer toggle.
7. Add an "Explain mode" toggle (coachmark overlay) instead of an upfront product tour — power-operator stays uncluttered by default, turns on annotations on demand.
Lower priority but cheap: prefers-reduced-motion guard on the framer-motion animations, visible focus rings, voice input must degrade gracefully (Web Speech API has no Firefox support and is cloud-dependent — keep the text field as the primary path, mic as enhancement).

---

## current dashboard component audit
**Dashboard is largely built — Jarvis layer, ui-kit, tokens, 8-zone nav, and backend /jarvis/* all shipped; main gap is wiring frontend to the live /jarvis/ask endpoint**

## Dashboard audit (off `origin/main`, head `da37541`)

The dashboard is **far more built-out than the brief assumes**. The Jarvis layer, the ui-kit, the design tokens, the 8-zone nav, and even the backend `/jarvis/*` contracts are all SHIPPED. ai-2 should **wire + extend**, not rebuild.

### (a) Design system / tokens — DONE, canonical
- `apps/dashboard/tailwind.config.ts` is THE palette (semantic names backed by terminal hex). Gold `accent #d4af37` = primary/active/focus only; cyan `ai #58a6ff` = Jarvis/AI layer only (orb ring, waveform). `ok/warn/err/blocked`, `chart1/2/3`, one radius (5px), `mono-tabular` font, three one-shot keyframes (`shimmer`, `glow-in`, `glow-in-ai`, all `motion-safe:`-gated). Legacy `terminal-*`/`pl-*` aliases still resolve.
- Mirrored in `apps/dashboard/src/app/globals.css`. North-star doc referenced: `command-center/docs/design/FRONTEND-GUIDELINES.md`.
- `apps/dashboard/src/components/ui/README.md` documents the full token table + a "definition of done / banned patterns" checklist (no gradients, no glassmorphism, no rounded-2xl, no font-bold, no framer entrance choreography, motion budget ~150ms). **ai-2 must follow this checklist.**

### (b) ui-kit primitives — DONE (`apps/dashboard/src/components/ui/`)
`PageShell, PageHeader, SectionHeader, Card/Panel, StatTile, DataTable, Badge, StatusDot, EmptyState, DrillNavigator, ChartFrame (+axes/tooltip/grid/CHART_COLORS), PriceChartFrame, cn`. All exported from `ui/index.ts`. There is a smoke test (`__smoke__.tsx`). DrillNavigator already implements URL-driven overview→detail drill with breadcrumb + Esc-pop (pilot: `/strategies`).

### (c) Jarvis layer — DONE and deep (`apps/dashboard/src/components/jarvis/`)
- **State machine:** `JarvisProvider` exposes `dispatch(action)`, `ask(text)` (sync resolve→dispatch), and `askAndAnswer(text)` (the full loop: resolveIntent → dispatch → composeAnswer → speak). Mounted globally in `app/layout.tsx` via `<JarvisProvider>` + `<JarvisLayer>` (orb + drawer).
- **Intent router:** `intent-router.ts` `resolveIntent()` — deterministic regex/slash-command resolver returning a typed `JarvisAction` union (NAVIGATE/OPEN_DRAWER/EXPLAIN_PAGE/RUN_BRIEFING/FILTER/SHOW_EVIDENCE/START_TOUR/TOUR_CONTROL/UNKNOWN). 9 slash commands. Explicit "LLM swap-point" comments. Server has a verbatim mirror (`apps/api/src/routes/jarvis-intent.ts`).
- **Answer engine:** `answer-engine.ts` `composeAnswer()` — deterministic branches that read LIVE endpoints (`api.firmMarketState`, `api.riskSnapshot`, `api.positionStats`, **`api.jarvisBrief`, `api.jarvisWhyNoTrade`**) + `llmAnswer()` fallback delegating to `api.askAssistant` (`/assistant/ask`).
- **Command bar:** the existing `components/CommandPalette.tsx` (in TopNav) is the designated command bar — not a competing input.
- **Orb / drawer / cockpit:** `JarvisOrb`, `JarvisDrawer`, `JarvisLayer`, plus full `/talk` cockpit (`ConversationCockpit.tsx` + `app/talk/page.tsx`, `content-router.ts resolveStage`). Cockpit already react-queries `jarvisBrief` + `jarvisWhyNoTrade` (30s) and routes voice/typed input through `askAndAnswer`.
- **Briefing card:** `JarvisBriefingCard.tsx` — currently **deterministic, derived from already-fetched home-page data** (deriveSystemMode + `/operator/regime` + `/analytics/strategies` + `/firm/risk-snapshot`). It does NOT call `/jarvis/brief` (the cockpit does; the card does not).
- **AutoUpdateFeed:** `buildFeed()` is a pure client-side derivation over already-fetched source objects (no new endpoint). Tested/deterministic by design.
- **Explain Mode:** `ExplainModeOverlay`, `PageExplanationHeader`, `page-explanations.ts`, `page-registry.ts`, `page-explanations` lookups — DONE.
- **Voice:** full layer — `useVoice`, `VoiceControls`, `VoiceEntryPrompt`, `useMicPermission`, `voice-settings.ts` (TTS engines). Server TTS at `/jarvis/tts`.
- **Tour/onboarding:** `JarvisTour`, `tour-steps.ts`, `Onboarding`, `useOnboarding`.
- **Contracts:** `contracts.ts` — typed UI contracts + `mock*()` adapters, every mock flagged `isMock:true`. NOTE: these mocks are the *original* scaffold; the real wiring has since moved into `answer-engine`/`api.ts` for brief + why-no-trade. The `contracts.ts` mocks (MarketState, AgentActivity, BlackboardEvent, PositionSummary, DecisionThread, AutoUpdateEvent, etc.) are still mostly UNWIRED stubs.

### (d) Pages / routes / nav — DONE
~85 routes under `app/`. `Sidebar.tsx` already organizes them into **8 canonical sections**: Overview / Trading / Strategy / Backtest & Prediction / Learning Loop / Agents / Market / Ops (note: operator brief says "6-zone IA" — current is 8). `MissionControlHero` (deriveSystemMode, pure/deterministic), `MarketPulse`, `JarvisBriefingCard`, `AutoUpdateFeed` all compose on the home page (`app/page.tsx`). TopNav has CommandPalette + MarketStateInline + PnlTickerInline.

### (e) Backend wiring — endpoints LIVE; frontend partially wired
**Backend routes EXIST and are registered** in `apps/api/src/index.ts`: `jarvis-ask.ts` (GET+POST `/jarvis/ask`, LLM-swap, returns `{action, answer}`), `jarvis-brief.ts` (GET `/jarvis/brief`, includes additive `spoken` TTS field), `jarvis-why-no-trade.ts` (GET, gate-decision reasoning + directional bias), `jarvis-tts.ts`, `jarvis-intent.ts` (server mirror). All have tests (incl. 401-unauth).
**Frontend api.ts wires:** `jarvisBrief()`, `jarvisWhyNoTrade()`, `firmMarketState()`, `askAssistant()`. 
**Frontend api.ts MISSING:** `jarvisAsk()` — there is NO client method hitting POST `/jarvis/ask`. The frontend resolves intent locally (`resolveIntent` + `composeAnswer`) instead of the server's grounded `/jarvis/ask`. **This is the single biggest wiring gap.**

### EXISTS / PARTIAL / MISSING table

| Component (operator wishlist) | Status | Where |
|---|---|---|
| AppShell | EXISTS | `app/layout.tsx` (Providers+Sidebar+TopNav+JarvisLayer) |
| NexusTopBar | EXISTS | `components/TopNav.tsx` |
| Sidebar | EXISTS (8 zones) | `components/Sidebar.tsx` |
| JarvisOrb | EXISTS | `jarvis/JarvisOrb.tsx` |
| CommandBar | EXISTS | `components/CommandPalette.tsx` (designated bar) |
| JarvisDrawer | EXISTS | `jarvis/JarvisDrawer.tsx` |
| BriefingCard | PARTIAL (deterministic, not on `/jarvis/brief`) | `jarvis/JarvisBriefingCard.tsx` |
| MissionControlHero | EXISTS (pure deriveSystemMode) | `jarvis/MissionControlHero.tsx` |
| MarketPulseCard | EXISTS | `components/MarketPulse.tsx`; drawer panel `market-pulse` |
| DecisionTimeline | PARTIAL | `app/firm-timeline`, `app/threads`, drawer `decision` panel; contracts `DecisionThread` mock unwired |
| ExplainModeOverlay | EXISTS | `jarvis/ExplainModeOverlay.tsx` + page-explanations |
| AutoUpdateFeed | EXISTS (client-derived) | `jarvis/AutoUpdateFeed.tsx` |
| ConversationCockpit (/talk) | EXISTS | `jarvis/ConversationCockpit.tsx`, `app/talk` |
| Voice layer | EXISTS | `jarvis/useVoice / VoiceControls / VoiceEntryPrompt` |
| Tour/Onboarding | EXISTS | `jarvis/JarvisTour / Onboarding` |
| ui-kit primitives | EXISTS (full set) | `components/ui/*` |
| Design tokens (gold/cyan) | EXISTS (canonical) | `tailwind.config.ts` + `globals.css` |
| `api.jarvisAsk()` → `/jarvis/ask` | MISSING | not in `lib/api.ts` |
| contracts.ts live wiring (agents/blackboard/positions/decision/auto-update) | MISSING (still mocks) | `jarvis/contracts.ts` |

### Already-DONE operator asks (do NOT redo)
- Design system, tokens, gold+cyan separation, banned-pattern checklist.
- Full ui-kit + DrillNavigator drill-down pattern.
- Jarvis provider/orb/drawer/command bar/briefing card/AutoUpdateFeed/Explain Mode/contracts/`/talk` cockpit — all shipped.
- Voice (STT+TTS) + tour/onboarding.
- 8-zone sidebar IA + MissionControlHero + MarketPulse composed on home.
- Backend `/jarvis/ask|brief|why-no-trade|tts` — live, tested, registered; brief carries `spoken`.
- `jarvisBrief()` + `jarvisWhyNoTrade()` already consumed by answer-engine and `/talk`.

### Genuine gaps vs the brief
1. **No `api.jarvisAsk()` client method** → frontend never calls the server's grounded `/jarvis/ask`; it resolves intent locally. Wiring this is the highest-leverage move (gets server-side grounding + future real LLM for free, callers unchanged per the documented swap-point).
2. **JarvisBriefingCard is deterministic/local**, not reading `/jarvis/brief` (the cockpit does; the home card doesn't) — unify so both use the live brief + its `spoken` field.
3. **contracts.ts mocks still unwired**: AgentActivity, BlackboardEvent, PositionSummary, DecisionThread, AutoUpdateEvent, MarketState — these `mock*()` stubs (flagged `isMock`) need real adapters. The brief + why-no-trade contracts already migrated out; the rest didn't.
4. **IA mismatch**: operator brief says 6-zone, current sidebar is 8-zone — reconcile (likely keep 8, it's the audited canonical set).

### Top actionable
1. Add `api.jarvisAsk(text)` in `apps/dashboard/src/lib/api.ts` hitting POST `/jarvis/ask` (returns `{action, answer, spoken}`), then make `askAndAnswer` in `jarvis/JarvisProvider.tsx` prefer the remote path with the existing local `resolveIntent`+`composeAnswer` as instant/offline fallback — the swap-point is already documented in intent-router.ts/answer-engine.ts so no other caller changes.
2. Unify `jarvis/JarvisBriefingCard.tsx` to consume `api.jarvisBrief()` (incl. its `spoken` field) like `/talk` already does, instead of the local deterministic derivation.
3. Wire the remaining `contracts.ts` mocks to real endpoints: AgentActivity→`firmAgentsOverview`, BlackboardEvent→`firmBlackboard`/`agentEvents`, PositionSummary→positions+`riskSnapshot`, DecisionThread→`/threads`, AutoUpdateEvent→learning-ledger; flip `isMock` to false per adapter.
4. Follow `components/ui/README.md` "definition of done" checklist (canonical tokens only, no gradients/glassmorphism/rounded-2xl/font-bold, motion ≤150ms) for any new UI; build on existing ui-kit + DrillNavigator, do not hand-roll.
5. Reconcile the 6-zone brief vs the live 8-zone `Sidebar.tsx` (Overview/Trading/Strategy/Backtest/Learning/Agents/Market/Ops) — likely keep the audited 8.