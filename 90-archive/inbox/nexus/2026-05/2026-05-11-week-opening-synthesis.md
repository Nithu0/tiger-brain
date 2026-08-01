---
date: 2026-05-11
type: synthesis
project: nexus
agent: main-thread
sources:
  - 2026-05-11-memory-audit.md
  - 2026-05-11-vault-gaps.md
  - 2026-05-11-pnl-bleed-analysis.md
  - 2026-05-11-code-debt.md
  - 2026-05-11-foundation-gate-path.md
  - 2026-05-11-agent-activation-readiness.md
  - 2026-05-11-followups-sweep.md
  - 2026-05-11-recon-audit.md
  - 2026-05-11-doc-drift.md
  - 2026-05-11-strategy-regime-fit.md
---

# Uke-åpnings-syntese — 2026-05-11

20 agenter (2 runder × 10) har gravd. Plattformen er **frisk** (`/health` = 200 OK, build 3ab8b61a, recon drift 0, balance $92646). Det er en **observabilitets-/wiring-krise** under panseret som forklarer hele PnL-blødningen.

## Tre kryssende temaer

### 1. Metadata-strip-pathen er rotårsaken til alt
Alle nye trades har **NULL** for `strategy_id`, `execution_source`, `portfolio_regime_at_entry`, `entry_conviction_score`, `atr_at_entry`. Konsekvenser:
- Position management fyrer **aldri** på losers (break_even_applied=false, management_events=[] på alle 16 røde dager-trades)
- Regime-aware gates er silent **no-op** for 99% av live volum
- PnL-attribuering er umulig — kan ikke si hvilken strategi som tapte
- "XAUUSD Auto"-bot driver alt; 4 firm-strategier (orb/scalp-overlap/session-breakout/vol-expansion) har **tusenvis av signaler men 0 closed trades** — signal→order-funnelen kollapser oppstrøms

**Dette er rotårsaken til -$2089 blødningen.** Postmortem-agent har auto-tagget alle 16 losers som `RIGHT_THESIS_BAD_EXECUTION` med "no lifecycle events".

### 2. `.env.example`-drift er en gjentakende risiko-vektor
- **59 env-flags** brukt i koden, **3 dokumentert** i `.env.example`
- `STRATEGY_BLADE_*`-familien (gate-silence-incidenten 24.4 → 11.5) var en direkte konsekvens
- `env-vars.md` har 2 wrong names (`TWELVE_DATA_KEY` → faktisk `MARKET_DATA_API_KEY`, `NEWSAPI_KEY` → `NEWS_API_KEY`)
- `feature-flags.md` missing 50+ flags

### 3. Foundation gate er 1 commit unna 🟢
- Regel 1, 3, 4 GREEN (bekreftet i dag — gate_decisions skriver 12 rader/24h, 1951+ evals)
- Regel 2 TEKNISK 🟢 / FUNKSJONELT 🔴 (POSITION_MANAGEMENT_ENABLED=true men management fyrer ikke pga metadata-strip)
- Regel 5 RØD pga 3 overdue claude-followups (kan ryddes i én commit)

## Punch-list

### 🔴 Røde — denne uka

| # | Tiltak | Eier | Estimat |
|---|---|---|---|
| 1 | Diagnostisere metadata-strip-pathen — hvor blir `strategy_id`/`execution_source`/`portfolio_regime_at_entry` strippet? Trace én vol-expansion-trade fra signal → order-router → simulated_orders | Claude + git blame | 2h |
| 2 | Fikse regime-stamping på `simulated_orders.portfolio_regime_at_entry` for XAUUSD Auto-pathen | Claude (etter rotårsak) | 1-2h |
| 3 | Diagnostisere signal→order-funnel-kollapsen for orb/scalp/session-breakout (tusenvis signal, 0 orders) | Claude | 1h |

### 🟡 Gule — bør ryddes

| # | Tiltak | Eier | Estimat |
|---|---|---|---|
| 4 | Synk 59 manglende env-flags til `.env.example` med docstrings | Claude (én PR) | 2h |
| 5 | Followups-cleanup: slett 3 verifiserbart-ferdige (legacy-disabled, postmortem-catchup, review-duplicate-trades), split oanda-two-way → ny narrow followup | Claude (én PR) | 30min |
| 6 | Stripp `OANDA_BACKFILL`-rader fra PnL-dashboard ($10.8k historical-noise) | Claude | 1h |
| 7 | Rename `lastBackfillIso` → `lastBackfillRowIso` + add `lastSyncCycleIso` (misvisende metric) | Claude | 30min |
| 8 | GRANT SELECT på `oanda_sync_drift` til read-only PG-rolle | Operator (SQL) | 5min |
| 9 | Doc-fix: rename `TWELVE_DATA_KEY` / `NEWSAPI_KEY` i `env-vars.md`, oppdater `firm-modules.md` til riktig modul-count | Claude | 30min |

### 🟢 Cognitive-OS / Obsidian

| # | Tiltak | Eier | Estimat |
|---|---|---|---|
| 10 | Backfill 5 kritiske MOC-leaf-noder (Operator-Nithu, Distillation-Hook, Session-Start-Hook, Obsidian-Bridge, Truth-Hierarchy) | Claude | 30min |
| 11 | Memory cleanup: merge `user-orchestration-style` → `user_personality`, arkivere 2 session-summaries | Claude | 15min |
| 12 | Aktivere `macro-event` firm-agent (lavest-risiko av silent fire) | Operator | 5min (Railway flag) |

### Karri / strategi-spor

- Discord sendt 11.5 med alle 3 proposals (HTTP 204 ✓). Venter på review.
- Foundation-gate-blokken skal være ryddet før strategi-implementasjon uansett.

## Bottom line

Plattformen fungerer. Trading-loopen er teknisk grønn. Men **firm-intelligensen er silent off på 99% av live volum** fordi metadata-stripping skjer et sted i pipeline. Det betyr at hver strategi-justering vi gjør (break-even-trigger, risk-clamp, gates) er sandkasse-eksperimenter som ikke når faktisk live-trading.

**Anbefalt #1 i kveld:** Tiltak 1 (diagnostisere metadata-strip-pathen). Alt annet kommer etter den.

---
Linked to: [[Nexus-MOC]], [[Foundation-Gate]], [[gate-silence-2026-05-08]], [[Operator-Principles]]
