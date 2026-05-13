# Daily trade-cap gate — implementert 2026-05-12

**Commit:** `b8195b9` (gate code) + `aad7d1b` (proposal-doc update)
**Karri proposal:** `docs/strategy/proposals/2026-05-12_daily_trade_cap.md`
**Status:** implemented (env-gated, default-off)

## Hva ble levert

Cross-strategy hard cap på antall firm-strategy trades per UTC-dag. Default 6. Resetter automatisk ved UTC-midnatt via `date_trunc('day', NOW() AT TIME ZONE 'UTC')`.

### Datagrunnlag (Karris analyse)

- 152 trades / 25 dager
- 6 av 7 dager med ≥8 trades endte i tap (kumulativt −$13,225)
- Katastrofedager: 21.4 (10 trades, −$7,119), 22.4 (8 trades, −$3,722), 11.5 (8 trades, −$1,893)
- Vinner-day grenseverdi: 6 trades (3.5 = +$2,096)
- Distribusjon: 4-6 trades/dag = +$580 snitt (sweet spot), 7-9 = −$1,230, 10+ = −$2,426

## Files touched

- **NY** `apps/worker/src/firm/gates/daily-trade-cap-gate.ts` — pure async-fn, fail-open. Eksporterer `evaluateDailyTradeCap`, `isDailyTradeCapEnabled`, `dailyTradeCap`.
- **NY** `apps/worker/src/firm/gates/daily-trade-cap-gate.test.ts` — 16 tester (env parsing, threshold-grenser, fail-open på DB-feil, SQL-shape pin).
- **EDIT** `apps/worker/src/firm/strategy-blade.ts` — wire gate inn etter SL-cooldown + regime-direction, før `isEnabled()` early-return. Kjører uavhengig av `STRATEGY_BLADE_ENABLED`. Persisterer `daily_trade_cap`-rad til `gate_decisions` når flagget er på (både would_reject og hard_rejected dekt).
- **EDIT** `apps/worker/package.json` — la til test-fil i `npm test` enumerationen.
- **EDIT** `.env.example` — dokumenterte `DAILY_TRADE_CAP_ENABLED` + `DAILY_TRADE_CAP` i ny seksjon.
- **EDIT** `docs/strategy/proposals/2026-05-12_daily_trade_cap.md` — Status: implemented + commit-SHA + implementation notes.

## SQL som teller

```sql
SELECT COUNT(*)::bigint AS count
  FROM simulated_orders
 WHERE opened_at >= date_trunc('day', NOW() AT TIME ZONE 'UTC')
   AND execution_source = 'firm_strategy'
```

`execution_source = 'firm_strategy'` ekskluderer legacy-trades + backfill-imports (svarer på Karris åpne spørsmål #4).

## Verify

- `cd apps/worker && npx tsc --noEmit` → exit 0 (clean)
- `npm test` → **539 pass, 0 fail** (var 523, +16 nye tester)

## Operator-flip når Karri godkjenner

Railway envs:
```
DAILY_TRADE_CAP_ENABLED=true
DAILY_TRADE_CAP=6      # valgfri override (default 6, range 1-20)
```

Rollback: `DAILY_TRADE_CAP_ENABLED=false` → instant. Ingen kode-revert nødvendig.

## Observability

Når flagget er på (selv som "test-flip" et øyeblikk for å varme opp logger):
- Hver rejection logges som `daily_trade_cap_reached (N/CAP firm-strategy trades opened so far (UTC day))` i strategy-blade `checks`-arrayet.
- `gate_decisions`-tabell får én rad per cycle med `gate_name='daily_trade_cap'`, `would_reject`, `hard_rejected`, `context` (count, cap, detail, strategyId, direction).
- For impact-rapport: query `gate_decisions WHERE gate_name='daily_trade_cap' AND hard_rejected=true` for å se hvor ofte cap traff.

## Karris åpne spørsmål — hva implementeringen svarer

1. **Er 6 riktig terskel?** → 6 implementert som default. Tunbart via `DAILY_TRADE_CAP` uten deploy.
2. **Hard vs soft cap?** → Hard. (Soft krever conviction-sizing som ikke er live.)
3. **Per-strategi vs total?** → Total cross-strategy. Per-strategi-caps kjører fortsatt parallelt.
4. **Inkluderer ghost-trades/imports?** → Nei. SQL-filter `execution_source = 'firm_strategy'`.
5. **Race condition på trade #7?** → DB-COUNT er sist-vinneren. Ikke advisory-lock. Karri kan flagge hvis dette blir et reelt problem.
6. **Suksess-måling etter 14 dager med cap aktiv?** → `gate_decisions WHERE gate_name='daily_trade_cap' AND hard_rejected=true` GROUP BY date — gir både frekvens og cycle-IDene som ble kappet (for å backtest om noen vinnere ble kappet).

## Avhengigheter / synergier

- **SL-cooldown** (11.5, commit `07f5d00`) — løser samme grunnproblem fra annet vinkel (per-strategi).
- **Regime-direction-gate** (11.5, commit `4c51309`) — kapper mot-trend direkte.
- **Session-block** (11.5) — kapper tap-sessions.

Daily-trade-cap er komplementært — den catcher cross-strategy-overtrading uavhengig av session/regime.

## Push-status

NO push (per operator-instruks). Awaits "OK kjør" → `git push origin main` (hands-off via `!`-prefix).
