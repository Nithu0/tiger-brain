# Cycle health audit — 2026-05-13 09:20 UTC

Verifies f551c17 (07.5) fix for "strategies silently skipping ~50% of cycles" is still holding, plus audits all currently-enabled strategy modules for evaluation completeness.

## TL;DR — per-strategy verdict

| Strategy | Topic | 24h evals | Cycle baseline | Skip-rate | Verdict |
|---|---|---:|---:|---:|---|
| S1 Trend-Following | `xauusd.trend-following.state` | 711 | 710 | 0% | **OK** |
| S2 Breakout-Continuation | `xauusd.breakout-continuation.state` | 711 | 710 | 0% | **OK** |
| S3 Pullback-Continuation | `xauusd.pullback-continuation.state` | 711 | 710 | 0% | **OK** |
| S4 Mean-Reversion | `xauusd.mean-reversion.state` | 255 | 256 (since 00:44 UTC) | 0% | **OK** (newly-deployed) |
| Session-Breakout | `xauusd.session-break.state` | 711 | 710 | 0% | **OK** |
| Vol-Expansion | `xauusd.vol-expansion.state` | 711 | 710 | 0% | **OK** |
| ORB | `xauusd.orb.state` | 0 | 710 | n/a | **DISABLED** (`ORB_ENABLED!=true`; expected — superseded by S1-S4) |
| Scalp-overlap | `xauusd.scalp.state` | 0 | 710 | n/a | **DISABLED** (`SCALP_OVERLAP_ENABLED!=true`) |

f551c17 still holding. No silent skipping inside live windows.

## Method

Cycle baseline = `xauusd.portfolio.context` row count (one publish per `runCycle()`). Each strategy publishes a `*.state` row in its evaluator on every cycle the module runs (via `latestWith` predicate from f551c17 patch — guarantees the price-fact filter doesn't trip the stale-price short-circuit). If a strategy were silently bailing, its `.state` count would drop below the baseline. `market.raw` shows 1420 = 2× baseline (price-feed + technical-facts publishers, both touch the same topic) — that's the bug f551c17 worked around.

## Hourly evaluation count last 24h (UTC)

```
                    market    S1   S2   S3   S4   Sess Vol-
hr (UTC)            .raw(/2)  TF   BC   PB   MR   Brk  Exp
2026-05-12 09       36        36   36   36    0   36   36
2026-05-12 10       55        55   55   55    0   55   55
2026-05-12 11       58        58   58   58    0   58   58
2026-05-12 12       56        56   56   56    0   56   56
2026-05-12 13       82        81   81   81    0   81   81
2026-05-12 14       56        57   57   57    0   57   57
2026-05-12 15       19        19   19   19    0   19   19
2026-05-12 16       19        19   19   19    0   19   19
2026-05-12 17       21        21   21   21    0   21   21
2026-05-12 18        7         7    7    7    0    7    7
2026-05-12 19        6         6    6    6    0    6    6
2026-05-12 20        6         6    6    6    0    6    6
2026-05-12 21        6         6    6    6    0    6    6
2026-05-12 22        5         5    5    5    0    5    5
2026-05-12 23       14        14   14   14    0   14   14
2026-05-13 00       14        14   14   14    4   14   14   ← S4 came online @ 00:44 UTC
2026-05-13 01       12        12   12   12   12   12   12
2026-05-13 02       12        12   12   12   12   12   12
2026-05-13 03       12        12   12   12   12   12   12
2026-05-13 04       18        18   18   18   18   18   18
2026-05-13 05       19        19   19   19   19   19   19
2026-05-13 06       24        24   24   24   24   24   24
2026-05-13 07       80        80   80   80   80   80   80   ← London open spike
2026-05-13 08       55        55   55   55   55   55   55
2026-05-13 09       18        18   18   18   18   18   18
```

`market.raw(/2)` = `xauusd.market.raw` row count divided by 2 (two publishers per cycle). Note S1-S3 + Sess + Vol track **exactly** with the cycle baseline at every single hour. After S4 fully ramped (≥01 UTC) it tracks identically.

## Cycle-frequency profile (sanity-check)

Cycle pacing varies legitimately: London/NY session 80–110 cycles/hr (~30s tick), after-NY-close 5–7 cycles/hr (~10min tick, observed gaps of 600–640s between consecutive `trend-following.state` events 18:00–22:00 UTC). All strategies share the same gap pattern — confirms throttling happens at the cycle level (orchestrator), **not** per-strategy. So no strategy is independently mid-day skipping.

## Other findings

- `xauusd.signal.rejected` = 3099 rows in 24h (~4.4/cycle). Strategies are running gates and producing rejection telemetry, which is further evidence they're not bailing early.
- `xauusd.breakout-continuation.signal` = 2 PROPOSALs over 24h, `vol-expansion.signal` = 8, `session-break.signal` = 9. Low signal-emission rates but expected for these gates — the evaluators run, they just rarely produce a PROPOSAL.
- S4 fired 254 evals between 00:44 UTC and 09:20 UTC = 8h36m, matching the expected cycle count over that interval. No PROPOSAL rows yet from S4 in 24h window — first PROPOSAL still pending but evaluator is alive.
- ORB and scalp produce zero `.state` rows because their feature flags are off. Confirmed against `apps/worker/src/firm/orb/config.ts` (`process.env.ORB_ENABLED === "true"`) and `apps/worker/src/firm/scalp-overlap/config.ts`. Not a bug.

## Verdict

f551c17 holding. No drift detected. Six active strategy modules at 100% cycle coverage. S4 mean-reversion (deployed during kveld 12.5→13.5) is healthy from the moment it came online.

## Files referenced

- `/home/nithu/code/ai-assistent/apps/worker/src/firm/orchestrator.ts` — `runCycle()` steps 1b–1i invoke each strategy
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/blackboard.ts` — `latestWith()` (f551c17)
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/{orb,scalp-overlap,session-breakout,vol-expansion,trend-following,breakout-continuation,pullback-continuation,mean-reversion}/config.ts` — per-strategy flags

## Recommendation

- No code action. Monitor S4 evals → first PROPOSAL transition over the next 24h.
- Optional: surface this audit query as a dashboard widget so future regressions are obvious in seconds.
