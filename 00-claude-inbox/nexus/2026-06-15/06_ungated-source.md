# Ungated "External (OANDA)" bleed — SOURCE determination

Date: 2026-06-15
Investigator: ai (read-only incident analysis)
Scope: origin/main code + nexus-pg (read-only) + /diagnostic/broker + /health

## VERDICT

**(b) — firm orders losing bot_id attribution.** NOT external/manual, NOT legacy path, NOT backfill-import-of-old-trades-mislabeled-as-recent.

The "External (OANDA)" / `bot_id IS NULL` rows are the firm's OWN `xau-fvg` and
`xau-mean-reversion` trades. Every one passed the blade gate (`approved=true`),
was placed on OANDA by the firm, opened AND stopped out inside a single
oanda-sync interval, and was therefore re-imported by the *closed-trade backfill*
path — which **hardcodes `bot_id = NULL`** and stamps `close_reason='OANDA_EXTERNAL'`.
The "external/ungated" appearance is a **labeling bug in one INSERT**, not a real
second execution stream.

## Are these real OANDA fills?

Yes — real fxpractice fills on account `101-004-39026976-001` (verified
/diagnostic/broker, 200 OK, balance €88,880.80). The 8 NULL-bot trade ids
(1391, 1496, 1560, 1566, 1572, 1578, 1584, 1612) sit in the SAME sequential
OANDA id series as the correctly-attributed `oanda_import_*` rows (1397, 1401,
1429, 1435 …) — one execution stream, the firm.

## Evidence

### 1. The NULL-bot rows since 2026-06-01 (8 rows, all losers)

| id | size | opened | hold | pnl | execution_source |
|---|---|---|---|---|---|
| oanda_backfill_1612 | 61 | 06-15 17:34 | 2.1m | -312.33 | oanda_backfill:**xau-fvg:blade_match_469ms** |
| oanda_backfill_1584 | 63 | 06-12 01:53 | 1.8m | -219.57 | oanda_backfill:xau-fvg:blade_match_313ms |
| oanda_backfill_1578 | 63 | 06-12 00:52 | 0.8m | -109.99 | oanda_backfill:xau-fvg:blade_match_220ms |
| oanda_backfill_1572 | 65 | 06-11 02:03 | 0.9m | -309.69 | oanda_backfill:xau-fvg:blade_match_296ms |
| oanda_backfill_1566 | 65 | 06-11 01:02 | 0.2m | -174.04 | oanda_backfill:xau-fvg:blade_match_261ms |
| oanda_backfill_1560 | 51 | 06-09 14:16 | 0.5m | -172.88 | oanda_backfill:xau-mean-reversion:blade_match_260ms |
| oanda_backfill_1496 | 47 | 06-05 02:31 | 3.7m | -129.97 | oanda_backfill:xau-mean-reversion:blade_match_414ms |
| oanda_backfill_1391 | 158 | 06-01 00:13 | 1.8m | -456.34 | oanda_backfill:xau-fvg:blade_match_308ms |

NULL-bucket total: **-$1,884.81 across 8 trades, 100% losers.**
Every `execution_source` carries `blade_match_NNNms` → `lookupBladeAttribution`
DID find a firm blade_decision within the ±2s window. These are gated firm trades.

### 2. Each NULL row maps to an `approved=true` blade_decision at the same instant

- backfill_1612 opened 17:34:04.516 ← blade `3352b731…` xau-fvg approved 17:34:04.047 (469ms) ✓
- backfill_1391 opened 00:13:27.130 ← blade `22b234bb…` xau-fvg approved 00:13:26.822 (308ms) ✓
- backfill_1584 ← blade `38b9a8db…` 01:53:26.920 (313ms) ✓ … (all 8 match)

The latencies (220–469ms) match the firm's real approve→fill latency band, same
as the import rows.

### 3. NULL rows and firm-attributed rows are the SAME trade type

`oanda_import_*` rows (bot_id SET) and `oanda_backfill_*` rows (bot_id NULL) are
both xau-fvg / xau-mean-reversion, both `blade_match`, overlapping size ranges
(imports include 86, 114, 158 units; size is NOT the discriminator — the incident's
"47–158 vs ~25–35" was comparing against an outdated typical size). All
`oanda_import_*` rows attribute to bot `9b2f966c` ("XAUUSD Auto"). The ONLY thing
that differs in the NULL rows is the bot_id column.

The real discriminator is **hold time + outcome**: the NULL rows all opened AND
closed inside one sync interval (sub-4-min, all stop-outs). The open-import
(section 5) never saw them open → only the closed-trade backfill (section 7)
caught them. Survivorship: fast stop-outs close before sync; winners ride longer,
get observed open, and become correctly-attributed `oanda_import_*`. That's why
the NULL bucket looks like pure bleed (8/8 losers) while the firm-attributed
bucket is +$1,735 net.

### 4. Ruled out the other paths

- **(a) Legacy path** — RULED OUT. All 8 XAUUSD bots are `status='paused'`
  (bot-cycle gates on `=== 'running'` → dead). trading-manager has a kill-switch
  (`LEGACY_XAUUSD_EXECUTION_ENABLED=false`, prod) that rejects every XAUUSD
  signal before placeOandaOrder. And legacy trades would have NO `blade_match`
  attribution — these all do. Cannot be legacy.
- **(c) External/manual** — RULED OUT. Every row has a matching approved
  blade_decision and `blade_match` source. The firm placed them.
- **(d) Mislabeled old backfill** — RULED OUT. `opened_at` are genuinely recent
  (06-01 → 06-15, one fired TODAY) and align to live blade_decisions of the same
  timestamp.

## Root cause (code, origin/main)

`apps/worker/src/firm/oanda-sync.ts:743 backfillClosedTrades()` →
INSERT at **line 833**, value list line **841: `bot_id = NULL` hardcoded**, with
`close_reason='OANDA_EXTERNAL'`.

Contrast the sibling open-import path (section 5, same file line ~459-505): it
does `SELECT id FROM bots WHERE market='XAUUSD' ORDER BY created_at LIMIT 1` and
writes that as bot_id. The backfill path was never given the same bot_id lookup —
it predates the attribution work and still writes NULL + the `OANDA_EXTERNAL`
sentinel that makes firm trades look like outside activity.

Consequence: these rows fall outside any `bot_id`-scoped or
`execution_source NOT LIKE 'oanda_backfill%'` query — including, per the incident,
the circuit-breaker / attribution dashboards. The losses are real and they ARE
gated firm trades; they're just invisible to firm-scoped accounting.

## Two distinct problems — separate them

1. **Attribution/visibility bug (INFRA, ai-1).** The backfill INSERT must set
   bot_id like section 5 does, and stop stamping `OANDA_EXTERNAL` /
   `oanda_backfill` when a `blade_match` attribution was found. This is the
   `bot_id IS NULL` mystery and the recon-delta wobble. NOT a strategy change.

2. **The actual money loss (Karri).** Even fully attributed, xau-fvg is bleeding
   on fast intrabar stop-outs (sub-4-min, large size, near-100% loss rate on the
   ones that round-trip inside a sync interval; backfill bucket -$1,885, and the
   correctly-attributed bucket carries -$2,936 gross losses too). xau-fvg is
   Karri's WIP (per project_fvg_karri_wip memory). The trade behaviour /
   sizing / SL placement is a strategy question for Karri — do NOT touch sizing
   or gates from infra.

## EXACT FIX

### Lane 1 — INFRA (ai-1), safe, no behaviour change, no Karri/operator gate

In `apps/worker/src/firm/oanda-sync.ts` `backfillClosedTrades()` (~line 824-865):

1. Before the INSERT, resolve a bot_id the same way section 5 does:
   `SELECT id FROM bots WHERE market='XAUUSD' ORDER BY created_at LIMIT 1`
   (→ `9b2f966c`), and bind it in place of the literal `NULL` at line 841.
2. Mirror the import path's `close_reason` / `execution_source` /
   `strategy_id` choice: when `attribution.strategy` is set (blade_match found),
   do NOT write the `OANDA_EXTERNAL` / `oanda_backfill` sentinels — write the
   strategy + a `oanda_backfill:<strategy>:<method>` source consistent with the
   open-import path (the source already does this; the `close_reason` and bot_id
   are what's wrong). Keep `OANDA_EXTERNAL` ONLY for the genuine
   `attribution.strategy == null` case.
3. One-time historical repair (gated DB write — needs operator "OK kjør"):
   backfill bot_id + reclassify the 8 existing rows so circuit-breaker/recon
   stop seeing phantom external activity:
   ```sql
   UPDATE simulated_orders
   SET bot_id = '9b2f966c-09a9-46ec-bc6e-c7ae50fe1708',
       close_reason = 'OANDA_SL_TP'
   WHERE bot_id IS NULL
     AND execution_source LIKE 'oanda_backfill:%blade_match%';
   ```
   (verify count = 8 first; this is the operator-gated piece.)

This closes the false "ungated" signal. It does NOT stop the loss — it makes the
loss correctly attributed to xau-fvg so the firm's own circuit-breaker/accounting
sees it.

### Lane 2 — KARRI (strategy)

xau-fvg (his WIP) is taking fast large-size stop-outs. Route to Karri: the loss
is directional/timing on fvg entries, not an infra bug and not SL-distance
(do not widen stops — martingale). File under strategy proposal if any
sizing/gate/SL change is contemplated.

### Operator

Only the one-time UPDATE (lane-1 step 3) needs operator "OK kjør" (DB write).
Broker account itself is healthy; no manual OANDA action required.

## Bottom line for the bleed

The bleed is **real firm xau-fvg losses**, not outside activity. The "ungated /
External (OANDA)" framing was an artifact of the backfill INSERT writing
`bot_id=NULL` + `OANDA_EXTERNAL`. They DID pass the gates (blade approved). So:
- The circuit-breaker bypass is partly illusory for accounting, but REAL in one
  sense: fast same-interval stop-outs may also bypass live in-loop risk checks
  that key off the open simulated_orders row — worth Karri confirming whether the
  daily-loss / cooldown logic counts trades it never observed as open. (The
  06-02 14:00 blade_decision shows `sl_cooldown_active` referencing
  `oanda_import_1435`, so cooldown DOES fire off imported rows — but only once the
  row exists; a trade that round-trips before any sync cycle is invisible to
  cooldown until backfill, i.e. after it already lost.)
- Fix attribution now (infra), route the strategy loss to Karri.
