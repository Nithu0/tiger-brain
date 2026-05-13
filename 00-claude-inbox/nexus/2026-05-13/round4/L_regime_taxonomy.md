# L — regime taxonomy doc landed

**Wrote**: `_library/trading/concepts/regime_taxonomy.md` (~720 words, P0).

## Sources read
- `docs/ref/regimes.md` — canonical market vs risk axis split
- `apps/worker/src/firm/regimes.ts` — `MarketRegime` enum + helpers
- `apps/worker/src/firm/portfolio-brain.ts:136-234` — `classifyRegime()` thresholds (ADX 30 → TRENDING, ATR > 12 → NOISY_CHAOTIC, etc.)
- `apps/worker/src/firm/regime-direction.ts` — A2 null-reason tags (9 paths)
- `apps/worker/src/firm/gates/regime-direction-gate.ts` — Karri's gate logic
- `_library/trading/concepts/trend_pause_detection.md` — pause-within-trend distinction

## Doc covers
1. Market vs risk regime as two orthogonal axes (per docs/ref/regimes.md).
2. Five operational market regimes with detection signatures (ADX-driven for trend/range, ATR-driven for vol).
3. Direction sub-axis (UP/DOWN/null) and the 9 A2 null-reason tags.
4. Strategy→regime fitness matrix from `MANAGER_REGISTRY` + S4 overlay.
5. TRENDING + mean-rev = 11.5 13:14 disaster; -$5 954 over 90d.
6. Karri's gate concept: not "block all mean-rev in TRENDING" — block only counter-trend with direction known.
7. Cross-refs to Carver, Chan ch7, and the trend-pause-detection sister doc.

## Discrepancy flagged in-doc
`firm/regimes.ts` MarketRegime type has 7 values (TRENDING/RANGING/BREAKOUT/MIXED_NO_EDGE/NOISY_CHAOTIC/HIGH_VOLATILITY/unknown). `portfolio-brain.ts` uses a slightly different working set (adds LOW_VOLATILITY/EVENT_DRIVEN, no BREAKOUT in `classifyRegime`). I noted this honestly rather than pretending it's clean 5. Worth a follow-up cleanup commit but not a blocker — gate-logic consumers all parse through `parseMarketRegime` which normalises to the canonical enum.

## What I did NOT do
- Did NOT propose detector designs for trend-pause (Karri-owned, per binding memory).
- Did NOT touch the proxy gates or activation state.
- Did NOT recommend Railway env flips.
