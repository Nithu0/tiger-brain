# Regime-direction-gate implementation — 2026-05-11

**Status:** implementert, env-gated default-off, klart for operator-flip
**Proposal:** `docs/strategy/proposals/2026-05-11_regime_direction_gate.md` (Karri)
**Commit:** `4c51309` (NB: feilmerket pga parallell-batch git race; diffen er
korrekt — se `f0189eb` for doc-note)

## Hva ble implementert

Blokker counter-trend mean-reversion-entries i TRENDING-regime:

- SHORT + TRENDING_UP → reject
- LONG + TRENDING_DOWN → reject

Treffer kun strategier i `MEAN_REVERSION_STRATEGIES`:
- `xau-scalp-overlap`
- `xau-vol-expansion`
- `xau-volatility-expansion` (registry-navn-variant)

Breakout-strategier (ORB, session-breakout) er **eksplisitt unntatt** — de kan
rettmessig fyre mot trend.

## Filer

| File | Hva |
|---|---|
| `apps/worker/src/firm/regimes.ts` | Ny `RegimeDirection` type (UP/DOWN/null) |
| `apps/worker/src/firm/regime-direction.ts` | Klassifikator (close_move + ema_slope) |
| `apps/worker/src/firm/regime-direction.test.ts` | 12 unit-tester for klassifikator |
| `apps/worker/src/firm/portfolio-brain.ts` | `classifyRegime` fetcher H4-candles + publiserer `regimeDirection` |
| `apps/worker/src/firm/gates/regime-direction-gate.ts` | Gate-logikken |
| `apps/worker/src/firm/gates/regime-direction-gate.test.ts` | 12 unit-tester for gate |
| `apps/worker/src/firm/strategy-blade.ts` | Wire-in (uavhengig av STRATEGY_BLADE_ENABLED) |
| `apps/worker/src/firm/strategy-blade.test.ts` | 4 integrasjonstester |
| `.env.example` | Doc + flag |
| `docs/strategy/proposals/2026-05-11_regime_direction_gate.md` | Status: implemented |

## Backward compat (kritisk!)

- `xauusd.portfolio.context.state.regime` forblir uendret (`"TRENDING"` / `"RANGING"` / …)
- Direction publiseres som **separat felt** `regimeDirection: "UP" | "DOWN" | null`
- Eksisterende consumers som `resolveRegimeKey()` og `regimeFitFor()` bruker `.includes("trend")` → uendret atferd
- `parseMarketRegime()` mapper kun kjente strenger → uendret (unknown for nye verdier hvis noen ble lagt til)
- DB-kolonne `portfolio_regime_at_entry` påvirkes ikke (skriver fortsatt `"TRENDING"`)

## Verifisering

- `npx tsc --noEmit` (apps/worker): clean
- `npm test`: 523/523 grønne (var 496 før; +27 nye tester)
- Pre-commit tsc-hook: OK

## Operator-aktivering

På Railway worker:
```
REGIME_DIRECTION_GATE_ENABLED=true
```

Valgfritt (default = close_move):
```
REGIME_DIRECTION_METHOD=ema_slope
```

**Rollback:** sett `REGIME_DIRECTION_GATE_ENABLED=false` → instant. Ingen DB-endringer, ingen migrations.

## Estimert impact (per Karri proposal)

Beskytter ~$2-3k / 30d basert på historikk:
- Vol-exp SHORT/TRENDING: 3 trades, 1W/2L, −$1191
- Dagens scalp-katastrofe (11.5): 6/8 mot trend, −$1898 net
- 10.5 (TREND 96%): 9 trades, 1W/7L, −$2111

## Vil ikke blokkere

- Vol-exp SHORT/NOISY_CHAOTIC (+$2342 historisk) — IKKE TRENDING, ingen blokk
- ORB / session-breakout uansett retning — eksplisitt unntatt
- TRENDING + null direction (uavklart signal) — fail open

## Åpne spørsmål til Karri

Per proposal § "Open questions" — fortsatt åpne, ikke truffet i implementasjonen:
1. Skal vi ha en "neutral"-tilstand (flat slope)? Per nå: null = allow.
2. Suksess-måling for 7-dagers post-aktivering: WR ≥ 45%, ingen enkeltdag-tap > $1000?

## Parallel-batch hazard observert

Min commit landet med feil melding (`chore(env): document SL_COOLDOWN_*`) på grunn av at en parallell terminal traff git samtidig. Diffen ved 4c51309 er likevel korrekt regime-direction-gate-implementasjon. Lærdom: når flere terminaler står på `.env.example` samtidig kan commit-meldinger byttes. For neste gang: enten serialisere `.env.example`-edits, eller alltid bekrefte commit-melding via `git log -1` rett etter commit.
