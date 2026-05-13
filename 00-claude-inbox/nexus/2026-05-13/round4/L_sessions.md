# Round 4 / L — session_windows concept distilled

**Output**: `_library/trading/concepts/session_windows.md` (~640 words incl frontmatter; body ~560 words).

## Sources used

- `docs/ref/session-thresholds.md` — threshold table per session, cold-start scope, DST rule.
- `apps/worker/src/firm/session-window.ts` — full state machine (11 states), `getBaselineSessionThresholds()`, `getSessionCadence()`, London-local DST-aware boundary detection.
- `apps/worker/src/firm/cold-start-config.ts` — `FIRM_COLD_START_MODE`, `FIRM_COLD_START_THRESHOLD_DELTA` (default −13, bounds [−20, 0]).
- Sibling strategy docs in `_library/trading/strategies/`: `scalp_overlap.md`, `session_breakout.md`, `orb_xau.md`, `volatility_expansion.md`, `mean_reversion_xau.md` — each contributed its session-mapping line.
- Sibling concept: `foundation_gate_tier3.md` for tone/format consistency.

## Coverage check vs brief

- [x] Three primary sessions with London-local clock + DST handoff behavior
- [x] XAUUSD per-session character (Asia=compression, London=breakout, NY=continuation OR reversal)
- [x] Overlap windows (London-NY, Asia-London) — when volume + edge concentrate
- [x] DST handoff weeks — explicit elevated-risk callout for first 3 trading days
- [x] Cold-start deltas — both threshold delta + faster cadence in ORB windows
- [x] Strategy → session mapping for all 5 (ORB, scalp-overlap, session-breakout, vol-expansion, S4)
- [x] Cross-refs: Raschke "Holy Grail", Fisher ACD, sibling concepts, code files, ops docs

## Notable distillations / non-obvious points

1. **Session state is London-local, not UTC.** The doc emphasizes this because hardcoded UTC hours silently break during DST handoffs — a real prior bug per `critical-rules.md` #2.
2. **Cold-start delta is asymmetric.** Only `marketThesis` + `entryThesis` get loosened on primary windows; `executionWindow` + `invalidationQuality` are never touched. This nuance isn't visible in the strategy docs.
3. **OVERLAP_ACTIVE is non-contiguous** in code: 12:00–14:30 AND 15:00–16:00, split by `NY_OPENING_RANGE`. Documented as one logical window with the split called out.
4. **S4 (mean-reversion) blocks Asia despite Asia being theoretically S4's home.** Code-level decision (volume too thin to confirm RSI extremes); flagged in doc as "theoretically … but live evidence …".

## No issues flagged

- No conflicts with sibling docs; all session-mapping lines cross-checked.
- No proposal-worthy findings (this is pure distillation).
- File written, frontmatter validated against template.
