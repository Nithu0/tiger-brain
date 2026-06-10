# Trade-ledger diagnose — 2026-06-01

**Status: BLOCKED — Postgres-tunnelen er nede. Ingen trade-for-trade-data tilgjengelig.**

## Hva som skjedde

`mcp__nexus-pg__query` feiler på alle kall med:

```
MCP error -32603: connect EHOSTUNREACH 66.33.22.236:58688
```

Tre forsøk (ping, count, schema-list) — alle EHOSTUNREACH. Dette er ikke
auth-feil eller tom tabell; det er at host 66.33.22.236:58688 ikke er nåbar
fra denne maskinen (tunnel/proxy nede, eller IP/port endret). Operator-fix:
sjekk at PG-tunnelen/SSH-forwarden kjører, eller at MCP-serverens host:port
i config matcher gjeldende Railway-proxy.

## Fallback-sjekk i repoet

- Ingen committed CSV/dump/seed med ekte closed-trade-utfall finnes.
- Backtest-scriptene (`scripts/backtest-*.mjs`, `scripts/backtest-strategies.mjs`)
  henter **live OANDA-candles** (krever `OANDA_API_TOKEN` + `OANDA_ACCOUNT_ID`)
  og simulerer — de leser ikke ekte `simulated_orders`-utfall. De kan derfor
  ikke svare på "hvor lekker pengene i de faktiske closed trades".
- Eneste kilde til faktiske per-trade-utfall = `simulated_orders` i Postgres.

**Konklusjon: trade-for-trade-ledger kan ikke produseres før tunnelen er oppe.**

---

## Verifisert skjema (klart til kjøring når tunnelen er oppe)

Kolonner i `simulated_orders` (fra `packages/shared/src/db/schema.ts`) som
dekker ALLE dimensjonene operator ba om:

| Dimensjon | Kolonne(r) |
|---|---|
| P&L | `pnl`, `result_r` |
| Strategi | `strategy_id`, `desk`, `execution_source`, `entry_type` |
| Retning | `direction` |
| Regime ved entry | `regime_at_entry`, `portfolio_regime_at_entry`, `risk_level_at_entry` |
| SL/TP-distanse | `entry_price`, `stop_loss`, `take_profit`, `atr_at_entry`, `range_size_usd` |
| Hold-tid | `opened_at`, `closed_at` |
| Utfall | `status`, `close_reason` |
| Conviction | `conviction_total`, `conviction_direction`, `conviction_timing`, `thesis_quality_score` |
| Cycle-kobling | `decision_cycle_id` (→ join `cycle_states` for regimeDirection / with-vs-counter-trend) |

### Query 1 — full trade-for-trade-ledger
```sql
SELECT
  id, opened_at, closed_at,
  EXTRACT(EPOCH FROM (closed_at - opened_at))/60       AS hold_min,
  strategy_id, desk, execution_source, direction,
  regime_at_entry, portfolio_regime_at_entry,
  entry_price, stop_loss, take_profit, close_price,
  ABS(entry_price - stop_loss)                          AS sl_dist_usd,
  ABS(take_profit - entry_price)                        AS tp_dist_usd,
  atr_at_entry, range_size_usd,
  status, close_reason, pnl, result_r,
  decision_cycle_id
FROM simulated_orders
WHERE status = 'closed' OR closed_at IS NOT NULL
ORDER BY opened_at;
```

### Query 2 — P&L per strategi
```sql
SELECT strategy_id,
       count(*) n,
       round(sum(pnl),2) pnl_sum,
       round(avg(pnl),2) pnl_avg,
       sum((pnl>0)::int) wins, sum((pnl<0)::int) losses,
       round(avg(result_r),3) avg_r
FROM simulated_orders WHERE closed_at IS NOT NULL
GROUP BY strategy_id ORDER BY pnl_sum;
```

### Query 3 — P&L per regime
```sql
SELECT COALESCE(portfolio_regime_at_entry, regime_at_entry) regime,
       count(*) n, round(sum(pnl),2) pnl_sum, round(avg(pnl),2) pnl_avg
FROM simulated_orders WHERE closed_at IS NOT NULL
GROUP BY 1 ORDER BY pnl_sum;
```

### Query 4 — SL-distanse-bucket: er SL diskriminator vinner vs taper? (hypotese a)
```sql
SELECT width_bucket(ABS(entry_price-stop_loss), 0, 20, 10) bucket,
       round(min(ABS(entry_price-stop_loss)),2) lo,
       round(max(ABS(entry_price-stop_loss)),2) hi,
       count(*) n, round(avg(pnl),2) pnl_avg, round(sum(pnl),2) pnl_sum,
       round(avg((pnl>0)::int)::numeric,2) win_rate
FROM simulated_orders WHERE closed_at IS NOT NULL AND stop_loss IS NOT NULL
GROUP BY bucket ORDER BY bucket;
-- + sammenlign avg(sl_dist) for winners vs losers:
-- SELECT pnl>0 AS winner, avg(ABS(entry_price-stop_loss)) FROM simulated_orders
-- WHERE closed_at IS NOT NULL GROUP BY 1;
```

### Query 5 — klynger tap ved dag-start / etter restart? (hypotese b)
```sql
SELECT EXTRACT(HOUR FROM opened_at AT TIME ZONE 'Europe/Oslo') hour_cet,
       count(*) n, round(sum(pnl),2) pnl_sum, round(avg(pnl),2) pnl_avg
FROM simulated_orders WHERE closed_at IS NOT NULL
GROUP BY 1 ORDER BY 1;
-- og første-trade-av-dagen vs resten:
-- WITH r AS (SELECT *, row_number() OVER (PARTITION BY date(opened_at) ORDER BY opened_at) rn
--            FROM simulated_orders WHERE closed_at IS NOT NULL)
-- SELECT rn=1 AS first_of_day, count(*), avg(pnl) FROM r GROUP BY 1;
```

### Query 6 — 5 verste enkelttap + fellestrekk
```sql
SELECT id, opened_at, strategy_id, direction,
       COALESCE(portfolio_regime_at_entry,regime_at_entry) regime,
       ABS(entry_price-stop_loss) sl_dist, close_reason, pnl, result_r, atr_at_entry
FROM simulated_orders WHERE closed_at IS NOT NULL
ORDER BY pnl ASC LIMIT 5;
```

---

## Når tunnelen er oppe — kjør Query 1–6, fyll inn tabellene her, og oppdater
oppsummeringen i parent-rapporten. Per nå: **ingen tall, kun blokk-årsak.**
