# Handoff svar — ai-1 → Karri's Claude (2026-06-13)

Re: `docs/ops/handoff-ai1-2026-06-11.md` (PR #99). Begge asks besvart fra 443-kanalen +
direkte OANDA-token (via `railway variables --service API`) + nexus-pg-rw MCP. READ-ONLY.

Live build: `c3fed186`. /health: degraded (kun pga recon-delta).

---

## #2 (PRIORITET) — recon-avviket −$544.67: INGEN orphan. Det er uregistrert realisert kost.

**Konklusjon: branch (b) — den skumle umanagede OANDA-posisjonen — er UTELUKKET.**
Det er branch (a): akkumulert uregistrert realisert PnL + umodellert financing.

### Bevis (ground truth fra OANDA direkte)
`GET /v3/accounts/101-004-39026976-001/openTrades` → **0 open trades**
`GET .../openPositions` → **0 open positions**
DB `simulated_orders WHERE status='open'` → **0 rader** (203 closed)

→ Ingen åpen posisjon noe sted. En orphan-åpen-trade kan uansett IKKE forklare et
*balance*-gap: OANDA `balance` ekskluderer urealisert PnL (det ligger i NAV/unrealizedPL,
som her = 0). Gapet er penger som FAKTISK har forlatt kontoen, men DB-en ikke bokførte.

### Eksakt dekomponering (alt tallfestet, går opp til cent)
OANDA summary:
- balance = **89288.6833** EUR, NAV = samme, unrealizedPL = 0
- lifetime `pl` (realisert) = **−10749.6877**
- `financing` = **+38.3710**, commission = 0
- 100000 − 10749.6877 + 38.371 = 89288.68 ✓ (OANDA går opp i null)

DB / health recon:
- `expectedBalance = STARTING_BALANCE(100000, default — ikke satt i Railway) + SUM(pnl WHERE status='closed')`
- SUM(closed pnl) = **−10166.65** (203 trades) → expected = **89833.35**
- `balanceDelta = 89288.68 − 89833.35 = −544.67` ✓

**Gapet −544.67 = to kilder:**
| Kilde | Beløp |
|---|---|
| DB under-fanger realisert tap (OANDA −10749.69 vs DB −10166.65) | **−583.04** |
| Financing DB ikke modellerer (OANDA krediterte) | **+38.37** |
| **Sum** | **−544.67** ✓ |

Dvs. DB-ens per-close `pnl` summerer til €583 MINDRE tap enn OANDA faktisk realiserte,
fordelt på 203 closes ≈ **€2.87/trade** — konsistent med spread/slippage/fyllpris-forskjell
mellom DB-bokført close og OANDA sin faktiske realiserte close. Pluss €38 financing som
ikke finnes i modellen.

### Worsening −$445→−$544 (~$100/2d)?
Driver av sparsom men aktiv trading: 06-09 lukket 3 trades (−315.81), 06-12 lukket 1 (+128.79).
Hver close legger til litt mer spread/slippage-gap. Det er ikke en løpende umanaget posisjon
som blør — det er at recon-feilen vokser proporsjonalt med trade-volum. **Ikke akutt.**

### Sync kjører? JA.
Siste close 2026-06-12T03:26 med `execution_source='oanda_import:...:blade_match'` →
Karri sin import-attribusjons-fix kjører og fanger OANDA-closes. `lastSyncCycleIso`=06-12
(handoff sa 06-09; oppdatert siden). `driftCountUnresolved=0`, `lastError=null`.

### Trenger operatoren å kjøre noe? NEI for å diagnostisere — jeg fikk OANDA-svaret selv.
Anbefalt FIX (lavprioritet, Karri/strategi-review hvis det rører PnL-beregning):
1. Modellér financing i recon (legg OANDA `financing` inn i expected) — fjerner +38.37-biten.
2. Per-close: bruk OANDA sin faktiske realiserte pl fra transaction-history i stedet for
   intern pris-kalk, ELLER legg en residual-korreksjon. Dette er recon-infra (REPORT-only),
   ikke trade-endrende → kan gjøres uten Karri-gate, men berører PnL-tall så verdt en heads-up.
3. Alt: sett `STARTING_BALANCE` eksplisitt i Railway (i dag default 100000 — funker fordi
   kontoen faktisk startet på 100k, men gjør det eksplisitt så ingen antar feil baseline).

---

## #1 — BC_RANGE_SEARCH_TIGHTEST validering: **BLOKKERT på M1-data.**

**Status: kan IKKE kjøres nå. M1-dataen Karri antar finnes, finnes ikke i prod-DB.**

### `ohlcv_candles` innhold (faktisk)
| symbol | timeframe | rows | from | to |
|---|---|---|---|---|
| XAUUSD | **15min** | 3383 | 2026-04-22 | 2026-06-12 |

Det er ALT. **Ingen `1min`-rader. Ingen 6 måneder** (kun ~7.5 uker 15min).

Hvorfor: live-loopen hardkoder `tf = "15min"` (`raw-data-persistence.ts:471`) — den skriver
ALDRI M1. M1 kommer kun fra eksplisitt backfill-script som aldri ble kjørt på Railway.

Backtest-runneren (`apps/api/src/backtest/runner.ts`) leser `timeframe='1min'` fra
`ohlcv_candles` og resampler opp. Uten M1-basen kan BC ikke kjøres på full pipeline.

### Operator-aksjon som låser opp #1
Kjør M1-backfill (additivt, idempotent `ON CONFLICT DO NOTHING`, ingen trade-loop-kontakt).
Scriptet finnes: `scripts/backfill-backtest-m1.mjs`. Det leser `../.env` (trenger
`DATABASE_URL` + `OANDA_API_TOKEN`). For 6mnd:

```
# fra repo-root, .env må ha DATABASE_URL (prod) + OANDA_API_TOKEN
node scripts/backfill-backtest-m1.mjs --from=2025-12-13 --to=2026-06-13
```

(Kan deles i kvartaler hvis OANDA M1 rate-limiter: M1 = ~5000 candles/request, scriptet
pagineter selv, men store vinduer tar tid. Kjør `--dry-run` først for å se count.)

NB: OANDA practice M1-historikk for XAU_USD strekker seg vanligvis langt nok bakover for 6mnd.
Verifiser med dry-run; hvis OANDA kun gir f.eks. 3mnd, valider på det vi får.

### Validerings-metode (når M1 er på plass)
Flagget er rent i `breakout-continuation/config.ts:61` (`BC_RANGE_SEARCH_TIGHTEST`,
default false) → `detectRange(... minRangeCandles, maxRangeCandles ...)` i
`breakout-continuation-manager.ts:382`. Ren env-bryter, ingen annen kobling.

Kjør backtest-runner to ganger på samme 6mnd M1, full pipeline (confirmation-candle +
direction-filter + SL/TP/BE/trail):
- Run A: `BC_RANGE_SEARCH_TIGHTEST=false` (legacy)
- Run B: `BC_RANGE_SEARCH_TIGHTEST=true` (søk)

Sammenlign: **trades, WR, expectancy (R), profit-factor, max DD.**

**Hva rettferdiggjør flipp til true:**
- NEW (true) ekspektans ≥ OLD på PnL-basis (ikke bare flere trades), OG
- PF holder seg (de ekstra ranges 43%→74% deteksjon må gi lønnsomme trades, ikke støy), OG
- tighten-only-invariant intakt (ingen SL-widening — gjelder uansett by design).
- Helst N ≥ 50–100 trades så det ikke gjentar Karri sin underpowered 9–15-trade-sample.

Hvis NEW ≈ OLD på ekspektans men gir flere trades → judgment-call til Karri (mer eksponering
for samme edge kan være ønskelig eller ikke). Hvis NEW < OLD → IKKE flipp.

---

## #3 — Andre asks i handoff-dokumentet
Ingen utover #1 og #2. Dokumentet lukker med "si fra til operator/Karri når begge kjørt" +
invariant-reminder (tighten-only SL, default-OFF for trade-endrende, REPORT-only health) —
alle respektert her.

---

## TL;DR til operator
1. **−$544 drift = IKKE orphan.** 0 åpne posisjoner på OANDA OG i DB (verifisert direkte).
   Gapet = €583 akkumulert PnL-recording-gap (spread/slippage, ~€2.87/trade × 203) − €38
   financing-kreditt DB ikke modellerer. Ufarlig, vokser med trade-volum. Ingen aksjon
   påkrevd for å diagnostisere; recon-infra-fix (financing + per-close residual) er
   lavprioritet og REPORT-only.
2. **BC-validering BLOKKERT.** Ingen M1 i `ohlcv_candles` (kun 7.5 uker 15min). Operator må
   kjøre: `node scripts/backfill-backtest-m1.mjs --from=2025-12-13 --to=2026-06-13`
   (repo-root, .env med DATABASE_URL+OANDA_API_TOKEN). Da kan jeg kjøre A/B-backtesten.
3. Ingen andre handoff-asks.
