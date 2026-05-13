---
title: 10-agent sweep synthesis — strategiforståelse + RAG-grunnlag
date: 2026-05-13
session: max-mode sweep
status: synthesis
related:
  - "[[01_s1_deep_dive]]"
  - "[[02_s2_deep_dive]]"
  - "[[03_s3_deep_dive]]"
  - "[[04_s4_deep_dive]]"
  - "[[05_cross_strategy_regime]]"
  - "[[06_trade_log_audit]]"
  - "[[07_obsidian_inventory]]"
  - "[[08_rag_architecture]]"
  - "[[09_ingestion_tooling]]"
  - "[[10_trading_curriculum]]"
---

# 10-agent sweep — synthesis

## TL;DR (les denne hvis du har 2 min)

1. **Premissen "S1-S4 har god baseline men taper nå" er empirisk feil.** S1, S3, S4 har **null live trades**. S2 har 1 firm-attributed trade. De siste tapene kommer fra **legacy** `xau-volatility-expansion` og `xau-session-breakout` (predecessoren til S2). Firm-strategiene har ennå ikke fått sjansen til å bevise eller motbevise noe.
2. **Karri's trend-pause-hypotese er kvantitativt bekreftet** på legacy-dataene: counter-day-trades −$5 954 (35% WR) vs with-day +$2 261 (42% WR). 11.5 var lærebok-eksemplet — alle 4 strategier (inkl. legacy) shortet 9 ganger inn i en +$76 uptrend-dag, −$2 638 på én dag. En fungerende trend-pause-filter ville reddet ~75% av cluster-tapene siden 26.4.
3. **`regime_direction_gate` viser null firings i `gate_decisions` siste 14d.** Enten ikke deployet eller helt stille. Karri/operator bør verifisere før det legges til nye lag. `daily_trade_cap` fyrer 8× men blokkerer 0 — også verdt en sjekk.
4. **RAG-anbefaling: ikke bygg vector-DB.** Lag `~/Obsidian/Brain/_library/trading/` med håndkurerte 200-500 ords-leksjoner + INDEX.md + skill-fil. Vector-stores er over-engineering for én bruker. Re-evaluer ved ~30 leksjoner.
5. **P0-pensum (les først):** Raschke *Street Smarts*, Carver *Systematic Trading*, Fisher *Logical Trader* + Crabel *Short Term Price Patterns*, Chan *Algorithmic Trading*. Alle treffer en konkret Nexus-arketype eller direkte Karri-spørsmålet.

---

## Strategi-track: hva tapene egentlig forteller

### Hvem taper egentlig?

Trade-log audit (siste 27d firm-attributed data):

- All-time: **WR 37.3%, PF 0.87, −$1 476 på 67 trades**. Ingen "god baseline" å rope hjem om — disse strategiene har ennå ikke vist seg.
- Ukentlig: W17 +$1 888 (40.7% WR), W18 +$437, **W19 −$3 801 (8.3% WR)**. Z-test siste 7d vs forrige 90d: z=−2.13, p≈0.033 — signifikant, men borderline (N=30 vs 37).
- Eneste strategi med PF≥1 over hele perioden: `xau-volatility-expansion`. ORB-legacy: 0/5.

86 closed rader har `strategy_id=NULL` (legacy pre-tagging) og ble ekskludert — så bildet er fortsatt litt skjevt.

### S1-S4 individuelt (overraskelsen)

| Strat | Modul | Trades | Status | Headline |
|---|---|---|---|---|
| S1 | `xau-trend-following` | 0 | Live 11.5 22:54 UTC | 844 reject-evaluations; 55% session-block, 27% vol-below-min. Har ikke tapt en krone fordi den ikke har handlet. |
| S2 | `xau-breakout-continuation` | 1 firm + 14 legacy | Ny modul live 12.5 | Legacy `xau-session-breakout` står for −$663 siste 30d (WR 30.8%, langt under 35-45% spec). 6 SL-hits dominerer skaden. |
| S3 | `xau-pullback-continuation` | 0 | Live 11.5 22:21 UTC | 844 cycles, alle rejecter på filter 1-3. 59 `pullback_too_deep` rejects — fingeravtrykk av trend-reversaler, ikke pullbacks. **S3 abstainet korrekt** på 11-12.5 katastrofedager. |
| S4 | `xau-mean-reversion` | 0 | Live 13.5 (i dag) | 106 cycles, alle session-gate-rejected (Asia/London-prep ved audit-tid). Gate 5-7 (ADX/impulse/RSI) ikke verifisert live ennå. |

**Implikasjon:** når operator sier "strategiene taper", refererer det til portefølje-aggregat — som domineres av legacy vol-expansion + session-breakout. S1/S3 har null skin in the game. S4 er for fersk. Det betyr også at vi *ikke kan* fixe noe ved å tune S1-S4 — vi må enten:
- vente på live data (S3 anbefaler 14d til 26.5 før vurdering),
- eller adressere legacy-bleed direkte.

### Trend-pause-hypotesen (Karri): kvantifisert

Cross-strategy regime-analyse på siste 90d:

- **Counter-day-direction trades:** −$5 954, 35% WR
- **With-day-direction trades:** +$2 261, 42% WR
- **TRENDING-regime trades:** 13 stk, 15.4% WR, −$3 573 — *selv with-day var 0/5 (−$1 997)*
- Det betyr at hypotesen treffer **direction** *og* **timing-inside-trend** — proxy gate på direction alene fanger ikke alt.

11.5 illustrerer perfekt: alle 4 strategier (inkludert legacy) fyrte 9 trades short inn i en +$76 uptrend-dag, alle med `portfolio_regime=TRENDING`. Det er ikke uavhengige feil — det er felles blindsone.

Estimat: en fungerende trend-pause-detektor ville reddet ~$3 573 (75%) av post-26.4 cluster-tap. Resterende $1 997 krever entry-timing-logikk utover bare retning.

> **Operator-decision:** dette er Karri-territorium. Ikke implementer noe. Send synthesis-en til ham hvis du vil ha hans neste-steg.

### Et signal som er stille men burde ikke være det

`gate_decisions`-tabellen siste 14d viser **null rows** for `regime_direction_gate`. `daily_trade_cap` viser 8 firings men 0 blokker. Enten:
- gates er ikke deployet (env-flagg av?),
- gates er deployet men logging mangler/feiler,
- gates fyrer aldri på live trafikk (terskler feilkalibrert).

Anbefalt: én diagnose-spørring til ops før nye lag legges til. Detaljer i [[05_cross_strategy_regime]].

---

## RAG / hjerne-track: konkret vei videre

### Anbefalt arkitektur (motsatt av hva man kanskje gjetter)

**Ikke bygg vector-DB. Bygg curated leksjons-mappe.**

Begrunnelse:
- Du er én bruker. Claude Code leser allerede filer on-demand via obsidian-mcp.
- Den ekte flaskehalsen er kildekvalitet, ikke retrieval-algoritme. En 300-siders bok dumpet i Chroma gir ikke smartere svar — den gir mer støy.
- Distillerings-prosessen (lese → skrive 300 ords leksjon) er der læringen skjer. For deg *og* for meg.
- Ingen pipeline = ingen sync-drift, ingen vedlikehold.

**Konkret struktur** (sammenstilt fra agent 7, 8, 9):

```
~/Obsidian/Brain/_library/
├── trading/
│   ├── INDEX.md                 # MOC, oppdateres manuelt
│   ├── concepts/                # 200-500w destillerte begreper
│   ├── strategies/              # 200-500w destillerte strategi-arketyper
│   ├── lessons/                 # 200-500w "dette lærte jeg av X"
│   └── sources/                 # frontmatter-stubs per kilde, raw-pekere
├── raw/                         # rå PDF→md output (gitignored)
└── youtube/                     # rå transcripts (gitignored eller selektivt)
```

**Frontmatter-template** (per leksjon):
```yaml
---
title: <leksjon-tittel>
source: <bok eller YT-tittel>
author: <forfatter>
source_type: book | youtube | paper | blog
relevance_to_nexus: 1-5
claude_priority: P0 | P1 | P2
tags: [library, <medium>, <topic>]
status: raw | distilled | promoted
---
```

**Skill-fil** (`~/.claude/skills/trading-knowledge/SKILL.md`): trigges på trading-domene-spørsmål, ruter Claude gjennom INDEX → tag-filtrert leksjon → bredere vault.

### Ingestion-verktøy (når du faktisk skal lese inn noe)

- **PDF**: `pipx install marker-pdf` (LLM-assistert layout, håndterer tabeller/footnotes/charts). Fallback til mistral OCR for skannede bøker.
- **YouTube**: `yt-dlp --write-auto-subs` som default (gratis, raskt). `faster-whisper` for transcripts uten subs eller dårlig lyd.
- **EPUB**: `pandoc -f epub -t gfm`.
- **Chunking**: én fil per kapittel. Forfatteren har allerede gjort jobben.

### Pensum-prioritet (P0 — start her)

| Bok | Hvorfor for Nexus |
|---|---|
| **Raschke & Connors — *Street Smarts*** | Turtle Soup = failed-breakout-fade-pattern, direkte input til trend-PAUSE vs trend-FLIP. Holy Grail = regime-gated continuation. Høyest signal/side. |
| **Robert Carver — *Systematic Trading*** | Forecast-combination math for multi-strategy ensemble (du har 4 strategier uten formell Carver-skalering). Filter-speed-kombinasjoner (16/64, 32/128) = direkte trend-pause-mekanikk. |
| **Mark Fisher — *Logical Trader*** + **Toby Crabel — *Short Term Price Patterns*** | Fisher = ACD-rammeverket bak ORB-arketypen. Crabel = empirisk mønster-katalog (NRn, stretch, opening-range). Les parallelt. Crabel er out-of-print → trenger PDF. |
| **Ernest Chan — *Algorithmic Trading*** | S4-validering: ch 2 (OU half-life), ch 3 (Bollinger MR med z-score sizing), ch 7 (HMM regime-switching). Skip equities-pairs-materialet. |

P1+ i [[10_trading_curriculum]].

---

## Anbefalte neste-steg (operator-decisions)

I prioritet:

1. **Send headlinen til Karri.** Trend-pause-hypotesen er kvantitativt bekreftet, og `regime_direction_gate` har null firings — han bør se dette før nye proposals.
2. **Diagnose-spørring på gate-firings.** Verifiser om `regime_direction_gate` deployet og om logging fungerer. Detaljer i [[05_cross_strategy_regime]].
3. **Vent 14d på S1/S3/S4 før noen vurdering.** Targets: S3 26.5, S1 26.5, S4 27.5. Ikke loosen filtre for å "få trades".
4. **Adresser legacy-bleed.** Når S2 (`xau-breakout-continuation`) er moden, vurder å skru av `xau-session-breakout`. Krever proposal.
5. **RAG-grunnlag (kan starte umiddelbart, ingen avhengigheter):**
   - Lag `_library/trading/` med 4 undermapper + tom `INDEX.md`.
   - Pek på fra `ai-assistent/CLAUDE.md`.
   - `pipx install marker-pdf`, kjør én bok end-to-end manuelt før noe automatiseres.
   - Skriv første 5 leksjoner for hånd fra én P0-kilde (Raschke). Bevis workflow før skalering.

---

## Hva agent-dropene IKKE dekker (åpne spørsmål)

- Cross-strategy-rapport flagget at `daily_trade_cap` fyrer 8× men blokkerer 0 — uavklart om det er konfigurasjons-bug eller tilsiktet.
- S4 sweet-spot (PR #24) har kun verbal Karri-approval, ikke skriftlig review-notat. Hvis live-data avviker fra backtest, har vi ingen baseline-doc.
- Vault er git-repo; `.gitignore` for `_library/raw/` bør avklares før vi dumper hundrevis av MB med PDF-output inn.
- 86 closed trades med `strategy_id=NULL` er ekskludert fra audit. Mulighet for backfill?

---

*Genererert 2026-05-13 fra 10 parallelle agent-drops. Kilder lenket øverst.*
