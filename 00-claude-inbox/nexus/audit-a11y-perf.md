# A11y + perf quick-wins audit — live Jarvis dashboard (2026-06-23)

> READ-ONLY markup-/SSR-nivå-audit av prod (`https://dashboard-production-f342.up.railway.app`). curl + HTML/CSS-analyse, ingen browser-render. Bygger på code-2s browser-verify (home+ask rene, hydration OK, health-pill RED = worker-heartbeat 5m stale) — gjentar ikke det. Funn-only; ai-2s lane, null skriving i deres repo.
>
> Ruter sjekket: `/` (55 KB), `/talk` (50 KB), `/system` (58 KB). Tokens lest fra `_next/static/chunks/3iq2jhsc11at6.css`.

## TL;DR
Baseline er **mye bedre enn typisk**. `motion-reduce:`-gating er gjennomgående (55/44/53 forekomster på de tre rutene), orb-knappene HAR `aria-label`, `<html lang>` er satt, gzip er på, kun 1 font preloades. Brief-bekymringen om at orb-libs mangler `prefers-reduced-motion` ser ut til å være håndtert i Nexus-implementasjonen allerede (ingen rå animasjon uten guard funnet i SSR). De reelle gjenværende quick-wins er **kontrast på sekundærtekst** og **et par missing labels / landmarks**. Perf er stort sett ren; største bilen er render-blocking CSS-precedence + manglende skip-link.

---

## TOP A11Y QUICK-WINS (rangert)

### 1. Kontrast: "dim"-tekst og ⌘K-hint feiler WCAG AA klart  (HØYEST)
Målte ratioer (mot bg `#0a0e14` / panel):
- `#484f58` dim-tekst på bg = **2.33:1** (knapp "Show evidence"-stil sekundærtekst). AA krever 4.5:1 (normal) / 3:1 (large). **Feiler.**
- ⌘K-hint `<kbd>` `#374151` på `#0d1117` = **1.84:1**. **Feiler hardt** — nesten usynlig.
- `border #21262d`/`#1f2937` på bg = 1.3:1 — under 3:1 for UI-component-grenser (WCAG 1.4.11). Mange kortgrenser/inputs er dermed under terskel.

Fix (billig, token-nivå, ingen rebuild): løft `#484f58`→ minst `#6e7681` (~3.7:1) eller bruk `--muted #8b949e` (6.29:1, allerede AA) for all faktisk tekst; reserver de dimmeste hexene KUN for disabled-state. Bump ⌘K `<kbd>`-tekst til `--muted`. For grenser, hev til `#30363d`+ der grensen er eneste skille-signal.
Bra nytt: `--text` (12.5:1), `--muted` (6.3:1), gull `--accent #d4af37` (9.2:1), ok/warn (8.8–9.0:1) er alle solide. `err #ea3943` (4.76) og `blocked #a855f7` (4.89) er så vidt over AA — OK, men ikke bruk dem på small text under 4.5.

### 2. Ingen skip-link + ett `<main>` uten kobling
`<main class="pl-[220px] pt-11">` finnes (bra — landmark er der), men ingen "skip to content"-lenke før den 25+-lenkers sidebar. Tastatur/skjermleser-bruker må tabbe gjennom hele nav på hver rute. Legg til en `sr-only focus:not-sr-only` skip-link som første fokuserbare element → `#main`. Én komponent, ingen layout-endring.

### 3. Lucide-ikoner mangler `aria-hidden` (41 av 44 på home)
Kun 3/44 SVG-er har `aria-hidden="true"`. De fleste sitter ved siden av tekst, så de blir dobbel-opplest av skjermlesere ("activity ... Market pulse"). Quick-win: sett `aria-hidden="true"` (eller `focusable="false"`) default på lucide-wrapperen. Ikon-only knapper (orb, health-pill) er allerede dekket av `aria-label` — bra; dette gjelder dekorative ikoner ved tekst.

### 4. `<button>` collapse-headers i sidebar mangler `aria-expanded`
8 gruppe-toggle-knapper (`flex w-full items-center justify-between ... text-muted`) på både home og /system — disse er expand/collapse-seksjoner uten `aria-expanded`/`aria-controls`. Skjermleser annonserer ikke åpen/lukket-tilstand. Legg til `aria-expanded={open}`. Trivielt.

### 5. Heading-hierarki er nesten riktig — verifiser ingen hopp
Home: 1×h1, 3×h2 — rent. /system: 1×h1, 4×h2 — rent. /talk: 1×h1, 2×h2 — rent. Ingen h3+ funnet, så hvis det finnes visuelle under-overskrifter rendret som `<div>`/`<p>` (sannsynlig i kort), mister skjermleser struktur. Lav prioritet, men sjekk at kort-titler er ekte headings der de fungerer som seksjonstitler.

### 6. Tiny fonts: `text-[9px]` / `text-[10px]` (21× på home)
9px ⌘K-kbd + 10px uppercase-labels er under komfortabel lesbarhet og forsterker kontrast-problemet (#374151 @ 9px = praktisk usynlig). Ikke en hard WCAG-feil (ingen min-size-krav i AA), men kombinert med lav kontrast er det reelt uleselig. Hev de minste til 11px der de bærer informasjon.

---

## TOP PERF QUICK-WINS (rangert)

### 1. Render-blocking CSS er hele Tailwind-bundelen (74 KB rå / 14 KB gzip)
Én `<link rel="stylesheet" data-precedence="next">` laster hele `3iq2jhsc11at6.css` blocking. 14 KB gzip er ikke ille, men det er én blocking round-trip før first paint. Quick-win uten rebuild er begrenset (Next styrer dette), men: verifiser at `cache-control` på CSS-chunken er immutable/long (HTML-dokumentet selv er `max-age=0, must-revalidate` — riktig for SSR, men sjekk at statiske chunks får lang TTL). Lengre sikt: PurgeCSS/Tailwind-content-trimming hvis bundelen vokser.

### 2. `/analytics` og `/positions` SSR-er nesten ingenting ("Loading…")
Bekreftet fra code-2/brief: tom first paint, alt klient-fetchet. Ikke en markup-quick-win, men billig forbedring = render skeletons (ui-kit har `EmptyState`/skeleton-mønster) i SSR i stedet for "Loading…", så siden ikke føles død. Ingen ny endpoint nødvendig.

### 3. Payload + scripts er sunne — ikke rør
- HTML 55 KB (gzip on, `vary: Accept-Encoding` korrekt satt).
- Kun **1 font** preloades (woff2, `crossorigin`) — bra, ingen font-flod.
- 28 script-tags men det er Next.js chunk-split (`fetchPriority="low"` på preload-script — riktig).
- Kun 6 `__next_f.push` inline-payload-kall, ingen oppblåst inline-JSON.
- 0 `<img>` (alle ikoner inline SVG) → ingen ulastet/alt-løst bilde-gjeld, ingen LCP-bilde-risiko.
Konklusjon: ingen perf-nødssak. Fokuser innsats på a11y-kontrast.

### 4. Favicon/icon lastes med cache-buster query — minor
`/icon.svg?icon.1rl436upsvlyq.svg` — fingerprintet, greit. Ingen handling.

---

## Hva som er BRA (ikke rør — unngå regresjon)
- `motion-reduce:transition-none` + `motion-safe:` keyframe-gating gjennomgående. `animate-pulse`/`animate-spin` finnes men `animate-none`-overstyringer er på plass. Brief-frykten ("orb-libs har ingen reduced-motion") materialiserer seg IKKE i SSR — orb-knappen bruker `focus-visible:ring` + `motion-reduce:hover:scale-100`.
- Orb (`aria-label="Talk to Nexus"`) + assistant-trigger (`aria-label="Open Nexus assistant"`) + health-pill (`aria-label="System health pill"` + `title`) — alle ikon-only-kontroller er labelet.
- `focus-visible:ring-2 ring-accent/60` på primær-kontroller (gull-ring = 9.2:1, godt synlig). Men kun 8 `focus-visible` mot 50 interaktive elementer på home → ikke alle lenker/knapper har eksplisitt ring; verifiser at default-ring ikke er fjernet på de øvrige (`outline-none` uten erstatning = WCAG 2.4.7-feil). **Sjekk dette i browser** — kan ikke avgjøres fra SSR alene.
- gzip + korrekt `vary`, `<html lang="en">`, ekte `<main>` landmark.

## Ikke verifiserbart fra SSR (for ai-2 i browser)
- Faktisk fokus-ring på de ~42 kontrollene uten eksplisitt `focus-visible`-klasse (har `outline-none` blitt erstattet?).
- Orb-animasjon under `prefers-reduced-motion: reduce` (markup har guards, men kjøre-tid bekreftelse mangler).
- Fokus-rekkefølge gjennom sidebar→main→command-bar, og om command-bar/drawer fanger fokus (keyboard trap, WCAG 2.1.2).
- Live-region (`aria-live`) på auto-update-feed + Jarvis-svar — fant ingen `aria-live` i SSR; hvis svar dukker opp uten annonsering, er det et skjermleser-gap.

---

### Rangert sammendrag
**A11y:** (1) løft dim/⌘K-tekst-kontrast (2.3:1→AA) — størst, ren token-fix; (2) skip-link; (3) `aria-hidden` på dekorative lucide-ikoner; (4) `aria-expanded` på sidebar-collapse-knapper; (5) verifiser fokus-ring + aria-live i browser.
**Perf:** stort sett rent (gzip on, 1 font, 0 img, sunn payload). Eneste reelle: (1) skeleton-SSR for /analytics + /positions sin tomme first paint; (2) bekreft lang cache-TTL på statiske chunks. Ingen perf-nødssak — a11y-kontrast er den høyest-verdi, lavest-kost gevinsten.
