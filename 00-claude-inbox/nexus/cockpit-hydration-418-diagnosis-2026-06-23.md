# Cockpit hydration #418 — diagnosis (READ-ONLY, for ai-2)

**Date:** 2026-06-23
**By:** code-1 (read-only diagnosis, no source edits)
**Symptom:** Live prod `dashboard-production-f342.up.railway.app` throws exactly 1 console error — Minified React **#418** = hydration **text-content mismatch** (server-rendered text ≠ client-rendered text on the initial render).
**App:** `~/code/ai-assistent/apps/dashboard` (Next.js app-router, all pages `"use client"`).

---

## Setup facts that constrain the diagnosis

- **No SSR data hydration.** `src/lib/providers.tsx` makes a fresh `QueryClient` per mount; there is **no** `HydrationBoundary` / `dehydrate` / `initialData` / prefetch anywhere (grep is clean). So every `useQuery` is `undefined` during SSR **and** during the first client render. Those values therefore **match** at hydration — async-data text is NOT the #418 source by itself.
- The #418 source must be a value that the **single SSR render** computes differently from the **first client render**, independent of async data. That means: `new Date()` / `Date.now()` / `getHours()` / locale/timezone formatting / `Math.random()` / `localStorage`-derived text rendered **synchronously** in the first pass.
- `<body suppressHydrationWarning>` is set in `layout.tsx` but that only suppresses body-attribute diffs, not deep text mismatches in children.

---

## Most likely culprit (rank 1) — `/morning` greeting block

**File:** `src/app/morning/page.tsx`
**Lines 52–53 and 65:**

```
const now = new Date();
const greeting = now.getHours() < 12 ? "Good morning" : now.getHours() < 18 ? "Good afternoon" : "Good evening";
...
<h1>{greeting} — Morning Command</h1>
<p>{now.toLocaleDateString("en-US", { weekday, year, month, day })}</p>
```

This is the textbook #418: `new Date()` is evaluated **synchronously in render**, with **no data dependency and no mounted guard**, so it renders text on the very first SSR pass. Server computes `getHours()` against the **Railway container clock/timezone (UTC)**; the browser hydrates against the **operator's local timezone (CET/CEST)**. Across the noon/18:00 boundaries the greeting string differs; `toLocaleDateString` can differ on the date itself near midnight UTC. Guaranteed text mismatch when the two timezones straddle a boundary.

> Caveat: the task says the error is on orb-home `/`. The greeting lives on `/morning`, not `/`. If "orb-home" in the report actually means the morning/orb landing surface, this IS the bug. **ai-2 should confirm which route throws** (the error route is in the un-minified stack / which page was open). If it's `/morning`, fix this first.

**Fix direction:** compute the greeting + date **client-side only** — `const [now, setNow] = useState<Date|null>(null); useEffect(() => setNow(new Date()), [])` and render a stable placeholder (or empty) until mounted. Or pin a fixed timezone via `Intl.DateTimeFormat(..., { timeZone: "Europe/Oslo" })` so server and client agree. `suppressHydrationWarning` on just that `<h1>`/`<p>` is the cheap escape hatch but masks rather than fixes.

---

## Rank 2 — relative-time ("Xs/Xm/Xh ago") rendered from `Date.now()` in render

These render once data arrives. With no SSR hydration the FIRST paint is empty (data `undefined`), so they are a **weaker** #418 candidate than rank 1 — but if any of these queries resolve from an in-flight cache during the still-hydrating window, the server "0s ago" vs client "3s ago" diff trips #418. All compute `Date.now()` directly in render with **no mounted guard**:

- `src/components/LiveActivityFeed.tsx` — `timeAgo(iso)` (line 101, uses `Date.now()`) rendered at **line 247**. **This panel IS on orb-home `/`** (imported in `src/app/page.tsx:13`). Strongest rank-2 candidate for the `/` route.
- `src/components/AgentDebatePanel.tsx` — lines 139–151 (`Date.now()` → "Xs/Xm/Xh/Xd ago"). Also imported on `/` (`page.tsx:12`).
- `src/components/CycleScope.tsx` — lines 131/138/164 (`Date.now()` fallback + `ageMs = Date.now() - ...`). Imported on `/` (`page.tsx:14`).
- `src/app/morning/page.tsx` — `timeSince()` lines 12–17.
- `src/components/StructureVpaPanel.tsx:223` — `{ageLabel(fact.ageSeconds)} ago` is **safe**: it uses a server-supplied `ageSeconds` number, not `Date.now()` in render, so server and client render identical text. Not a culprit.

**Fix direction:** gate relative-time behind a mounted flag (render the absolute timestamp or a dash until `useEffect` sets `mounted`), or compute `now` once in state and never during the synchronous render path.

---

## Rank 3 — no-locale `.toLocaleString()` (number formatting drift)

Number formatting with **no explicit locale** uses the runtime default: server (Node on Railway, `C`/`en-US`) formats `1,234.56`; browser (operator likely `nb-NO`) formats `1 234,56`. Data-gated so first-paint is empty, but trips #418 if data is present during hydration.

- `src/app/page.tsx:220` — `{account.currency} {Number(account.NAV).toLocaleString()}` — **no locale arg**, on orb-home `/`. Real risk.
- `src/app/page.tsx:140` — `new Date(overviewQ.dataUpdatedAt).toLocaleTimeString()` — no locale; gated behind `stale` (needs `dataUpdatedAt > 0`, false first-paint) so low risk.
- `src/components/SystemHealthIndicator.tsx:223` — `.toLocaleString()` no-locale (data-gated).

**Safe (explicit locale, do not touch):** `NumericValue.tsx:91`, `PnlTicker.tsx:57`, `EquityCurve.tsx:56` all pass `"en-US"` → deterministic.

**Fix direction:** pass an explicit locale to every `.toLocaleString()/.toLocaleTimeString()` that renders into SSR'd text (`"en-US"`), matching the codebase's existing convention.

---

## Cleared as NOT the cause

- `src/components/TopNav.tsx` — reads `localStorage` correctly inside `useEffect` with state init `null` (proper mounted-guard). The localStorage value drives a numeric unread **badge count**, not first-paint text. Clean.
- `src/components/MarketStateHeader.tsx`, `PnlTicker.tsx` — no Date/random/locale-drift in render. Clean.
- No `Math.random()` in any rendered component.

---

## Recommended action for ai-2 (fastest path)

1. **Confirm the throwing route** from the stack. If `/morning` → fix rank 1 (greeting `new Date()` → useEffect+mounted). That alone likely clears #418.
2. If the route is genuinely orb-home `/` → fix rank 2 `LiveActivityFeed.timeAgo` (mounted guard) **and** rank 3 `page.tsx:220` no-locale `toLocaleString` (add `"en-US"`).
3. Lowest-effort blanket option if a single text node is the only offender: `suppressHydrationWarning` on that exact element — but prefer the mounted-guard fix for time/locale text.
