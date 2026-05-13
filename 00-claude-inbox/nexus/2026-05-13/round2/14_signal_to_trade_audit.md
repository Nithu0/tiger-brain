# Signal → Trade lifecycle audit (round 2, 14)

**Date scope**: 2026-05-06 → 12 (7 days closed losers). **Trade source**: `simulated_orders` (no `trades` table; that's the canonical name despite the schema label).

---

## Headline failure step: **GATING. All meaningful gates run in shadow-mode** — `would_reject=true, hard_rejected=false`. The blade reads the bundle, sees "0 hard rejects", and ships every signal that survives `event_policy` + `extreme/blackout` risk_veto. The DB has the warning. Nothing on the path consumes it.

Code proof: `apps/worker/src/firm/gates/new-gates.ts:110-117`

```
hardFlags = {
  risk_level:          boolEnv("RISK_LEVEL_HARD_GATE_ENABLED", false),
  scalp_overlap_asia:  boolEnv("SCALP_OVERLAP_ASIA_BLOCK", false),
  ranging_conviction:  boolEnv("RANGING_CONVICTION_GATE_ENABLED", false),
  entry_stack_cooldown: boolEnv("ENTRY_STACK_COOLDOWN_ENABLED", false),
  session_block:       boolEnv("SESSION_BLOCK_ENABLED", false),
}
```

Every gate's hardRejected = `wouldReject && hardFlags[name]`. With flags OFF, hardRejected is always false. `strategy-blade.ts:319` then writes `new_gates: passed=true, "N evaluated, none hard-reject"` — a tautology.

DB confirms: last 7 days, 84 gate_decisions rows. `would_reject=true` 24×. `hard_rejected=true` only 4× (all `session_block` — and somehow that one *is* on, but never blocked these trades because the strategies don't pass `session_at_entry` correctly; 4 of 5 audited trades have `session_at_entry="unknown"`).

Compounding bug: `risk_veto` check in strategy-blade.ts:257 outputs `{passed:true, reason:"risk=high"}`. The string carries the warning but the boolean lets it through. Pure observability theater.

---

## Three concrete trades

### 1) The scalp-overlap stair (worst pattern, 11.5 cluster)

Within **19 minutes** the same strategy fired 3 SHORTS at successively **higher entry prices** while price climbed:

| time | entry | SL | size | mins-since-last-same-dir | gate verdict |
|---|---|---|---|---|---|
| 13:14:31 | 4720.15 | 4727.36 | 46 | 179 | cooldown OK, risk_level=high (soft) |
| 13:19:59 | 4727.04 | 4736.41 | 45 | **5.5** | cooldown would_reject (5min<15min) — soft only |
| 13:33:04 | 4734.70 | 4745.43 | 43 | **13.1** | cooldown would_reject (13min<15min) — soft only |

All three filled, all three hit SL, **−$1,058 in 28 min** on a single thesis ("RSI overbought in overlap"). The cooldown gate did its job — it told the system "no, you just did this". The blade overrode it because `ENTRY_STACK_COOLDOWN_ENABLED=false`. Where the system *should* have caught it: gate#2 evaluation at 13:19 — explicit `stack_cooldown_5min_lt_15min` written to DB, ignored by caller.

### 2) The direction flip (574c5e3d, vol-expansion LONG at 14:12)

39 min after the last scalp SHORT got stopped (price now 4729), vol-expansion fires a **LONG** at 4729.39 — *into the same chop that just stopped 3 shorts*. Same bot, same hour, opposite direction. There is no cross-strategy correlation gate. `cooldown` is per-direction-per-strategy only (`minutesSinceLastSameDirTrade`), so the system has no awareness that the bot just took 3 trades in the opposite direction. Result: SL hit at 4713, −$527.

Where it should have caught it: a missing gate. **`cross_strategy_direction_flip`** doesn't exist. Karri's "trend-pause-bevissthet" note (12.5 memory) names exactly this pathology.

### 3) The ORB london short (7eebe4f7, 10:15)

`strategy_blade` checks pass with `risk_veto: passed=true, reason="risk=high"` literally written to the row. ATR + range fields all NULL on entry. `session_at_entry="unknown"` even though `decision_cycle_id='orb-london-2026-05-11'` says London. Instrumentation gap: ORB writes its decision but doesn't backfill `session_high/low_at_entry`, `range_size_usd`, `range_percentile_at_entry`, `thesis_quality_score`, `conviction_*` — so postmortem has nothing to learn from.

---

## Other findings worth noting

- **`risk_level_at_entry='high'`** on 13 of last 30 closed trades. Of those 13, **2 winners, 11 losers, −$3,200**. Sizing was not reduced — `size` and `original_size` columns show no degrade. risk_level high → trade fires at full size with verbal warning logged only.
- **0 winners** on xau-orb, xau-scalp-overlap last 7 days. xau-volatility-expansion 6W/14L = 30% hit rate (theoretical break-even at ~33% on 2R; we're below).
- `trade_strategy_snapshots` empty for these cycles → "would_fire shadow" never wrote for the actually-fired blades (snapshot path only writes for *non-fired* strategies). Postmortem on losers can't compare "what other strategies were saying at this moment".
- `trade_lineage` empty for these orders. The decision chain is **not** being persisted despite the table existing.

---

## Highest-leverage fix (one toggle)

**Flip `ENTRY_STACK_COOLDOWN_ENABLED=true` on Railway**. This is the single highest-EV change: it would have blocked trades 2 and 3 in the cluster (−$765 of −$1,058) with zero new code, just a config flip. The gate is already wired, evaluated, and persisting decisions correctly — it's literally one env var away from being active.

Then in order of leverage:
1. `RISK_LEVEL_HARD_GATE_ENABLED=true` OR (better) introduce sized-degrade-on-high (size×0.5 when risk=high) instead of binary block.
2. Build `cross_strategy_direction_flip` gate: block any signal whose direction is opposite the last-3-fired-trades within N minutes (handles the 14:12 LONG).
3. Backfill `trade_lineage` writes from strategy-blade.ts post-fire — without this, postmortem has no fingerprints.
4. Fix `session_at_entry="unknown"` writes in xau-orb/scalp/session-breakout paths — currently 4 of 5 audited trades blind on session.

The system is doing 90% of the right work: gates are coded, decisions are logged with `would_reject` reasons, the bundle is computed. The last 10% — actually consuming `would_reject` — is what's missing. The signals aren't broken; the enforcement is.

**Files**:
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/gates/new-gates.ts:110-117` (hardFlags defaults)
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/strategy-blade.ts:257,316-319` (risk_veto + new_gates checks)
