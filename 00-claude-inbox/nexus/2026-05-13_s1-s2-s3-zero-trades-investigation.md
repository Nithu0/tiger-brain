---
date: 2026-05-13
type: investigation
project: nexus
status: open
reviewer: karri
---

# S1/S2/S3 zero-trades investigation (7-day data)

## TL;DR

All three strategies are correctly wired + enabled + evaluating every cycle (1,103 state-rows each in last 7d). They are **NOT broken** — they're rejecting at indicator-level **before** ever emitting signals. **Root cause: dual session-gate + ADX/vol-expansion floors cull >99.9% of cycles.**

Only **2 proposals total** in 3,312 cycles (S2 only, both on 12.5). S1 + S3 have emitted **zero** signals to the blackboard.

---

## Wiring confirmation (clean)

| Step | Strategy | Orchestrator | Config flag | Live state-row count (7d) |
|---|---|---|---|---|
| 1f | S1 Trend-Following | `orchestrator.ts:388-400` | `TREND_FOLLOWING_ENABLED=true` | 1,103 |
| 1g | S2 Breakout-Continuation | `orchestrator.ts:402-414` | `BREAKOUT_CONTINUATION_ENABLED=true` | 1,103 |
| 1h | S3 Pullback-Continuation | `orchestrator.ts:416-428` | `PULLBACK_CONTINUATION_ENABLED=true` | 1,103 |
| 1i | S4 Mean-Reversion | `orchestrator.ts:430+` | `MEAN_REVERSION_ENABLED=true` | 367 (only enabled night 13.5) |

Identical 1,103 counts = strategies fire on every cycle. The evaluator is being called.

**Caveat:** env-vars `TREND_FOLLOWING_ENABLED` / `BREAKOUT_CONTINUATION_ENABLED` / `PULLBACK_CONTINUATION_ENABLED` are NOT documented in `.env.example`. Per handoff doc they are set on Railway directly. Live state-row count proves the flags are on.

---

## Where they're dying — reject-reason breakdown (last 7d)

### S1 Trend-Following (1,103 cycles, 0 proposals)
| Bucket | n | % |
|---|---|---|
| session_blocked (mostly OVERLAP_ACTIVE) | 274 | 24.8 |
| session_not_allowed | 262 | 23.8 |
| **adx_too_low (< 22)** | **255** | **23.1** |
| **vol_expansion_below_min (< 1.05)** | **229** | **20.8** |
| pullback_too_deep (> 0.8 ATR) | 59 | 5.3 |
| no_chase / no_trend / other | ~24 | 2.2 |
| **proposals** | **0** | **0** |

### S2 Breakout-Continuation (1,103 cycles, 2 proposals on 12.5)
| Bucket | n | % |
|---|---|---|
| session_not_allowed (ASIA_OBSERVE, etc.) | 385 | 34.9 |
| session_blocked | 274 | 24.8 |
| **no_valid_range** | **214** | **19.4** |
| **no_clean_breakout** | **192** | **17.4** |
| in_cooldown | 36 | 3.3 |
| **proposals** | **2** | **0.2** |

### S3 Pullback-Continuation (1,103 cycles, 0 proposals)
| Bucket | n | % |
|---|---|---|
| session_not_allowed (incl. ASIA_OBSERVE) | 385 | 34.9 |
| session_blocked (mostly OVERLAP_ACTIVE) | 274 | 24.8 |
| **vol_expansion_below_min (< 1.05)** | **193** | **17.5** |
| **adx_too_low (< 20)** | **192** | **17.4** |
| pullback_too_deep (> 2.0 ATR) | 59 | 5.3 |
| **proposals** | **0** | **0** |

### Aggregate (3,312 cycles across S1-S3)
- session-rejected: **1,857 (56.1%)** — never reach indicator check
- reached indicator check + rejected: 1,453 (43.9%)
- **proposals emitted: 2 (0.06%)**

---

## Three-bullet finding per strategy

### S1 Trend-Following
- Wiring + flag OK. Evaluator runs every cycle.
- **ADX threshold (22) blocks 23% of cycles even when session-allowed.** XAU has been chopping below 22 ADX for most of the past 7d.
- **vol_expansion floor (1.05) blocks another 21%** — recent ATR has been below 5d avg most of the week. Together with ADX they cut >50% of in-session evaluations.

### S2 Breakout-Continuation
- Wiring + flag OK. Only strategy that emitted signals (2 PROPOSALs on 12.5 at 15:00 + 16:01, both SHORT, ADX 25-27, atrRatio 1.30-1.46).
- **`no_valid_range` (19.4%) + `no_clean_breakout` (17.4%) are the real bottleneck after session filter.** Compression-then-breakout pattern hasn't formed cleanly.
- Both proposals fired on 12.5 — the tap-day. Means S2 was "ready" exactly when continuation got crushed. `gate_decisions` shows only soft (hard_rejected=false) decisions for `xau-breakout-continuation`, so likely either passed downstream or was blocked by a cap/cooldown — worth a follow-up trace on cycle IDs `5d34b905…` and `36620964…`.

### S3 Pullback-Continuation
- Wiring + flag OK. Evaluator runs every cycle.
- **Same ADX + vol_expansion squeeze as S1** (17.4% + 17.5%). `pullback_too_deep` rejections seen up to 7.6× ATR — those are post-impulse extreme retracements way past the 2.0 ATR cap.
- S3 has the **most-restrictive session list** of the three (only LONDON_ACTIVE + NY_CONTINUATION — no ASIA_OBSERVE), hence the largest `session_not_allowed` bucket (34.9%).

---

## Why S4 fires and S1-S3 don't

| Strategy | Allowed sessions | ADX requirement | Vol-exp floor |
|---|---|---|---|
| S1 TF | LONDON_ACTIVE + NY_CONT + ASIA_OBSERVE | ≥ 22 | ≥ 1.05 |
| S2 BC | LONDON_ACTIVE + NY_CONT | range-driven (~20 implicit) | implicit in range |
| S3 PC | LONDON_ACTIVE + NY_CONT | ≥ 20 | ≥ 1.05 + pullback gate |
| S4 MR | LONDON_ACTIVE + NY_CONT | **ADX ≤ 25** (counter-trend!) | impulse-driven |

**S4 inverts the ADX gate** (trades when ADX < 25 = ranging/chop), which is exactly the regime XAU has been in. S1-S3 require ADX > 20-22 = trending — and the market hasn't been trending.

---

## Most likely root cause (1 sentence)

**Market regime mismatch: XAU has been ranging/chopping (ADX < 20-22, ATR below 5d avg) for ~7 days, which is the exact opposite of what S1-S3 require by design.** They are not broken — they're correctly refusing to trade in their hostile regime. Karri's 4-strategy portfolio thesis is working as designed; this week's regime is S4-friendly and S1-S3-hostile.

---

## What I did NOT change

- No env-flag modifications
- No threshold tuning
- No strategy code changes

## Suggested operator-decisions (for Karri)

1. **Verify regime expectation:** Was the 6mo backtest WR/PF achieved in mixed regimes? If yes, current dry-spell is normal portfolio behaviour.
2. **Consider regime-conditional activation:** S1-S3 already have `vol_expansion_below_min` and `adx_too_low` gates — these effectively self-disable in chop. That's by design. **No action needed unless drought extends past 14 days.**
3. **Document env flags in `.env.example`** for the three strategy flags (currently undocumented; relies on tribal knowledge from handoff doc).
4. **Follow-up trace:** confirm whether the 2 S2 proposals on 12.5 (cycle IDs `5d34b905…` + `36620964…`) actually opened positions or were stopped further downstream (daily_trade_cap / scalp_overlap / position-management).

---

## Source data

- `mcp__nexus-pg__query` on `blackboard` table, last 7d, `xauusd.{trend-following,breakout-continuation,pullback-continuation}.state` topics
- `apps/worker/src/firm/orchestrator.ts:388-428` (Step 1f/1g/1h wiring)
- `apps/worker/src/firm/{trend-following,breakout-continuation,pullback-continuation}/config.ts`
- `docs/ops/2026-05-13_evening_handoff.md` (env-flag truth source)
