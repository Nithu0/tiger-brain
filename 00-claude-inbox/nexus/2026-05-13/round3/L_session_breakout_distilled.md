# L_session_breakout — distilled lesson audit

**Output**: `~/Obsidian/Brain/_library/trading/strategies/session_breakout.md` (~580 words excl. frontmatter; sits slightly over the 300–500 target because the SL-flaw + 3-option proposal both needed to be in one place for future reference).

**Sources consumed**:

1. `apps/worker/src/firm/session-breakout/session-break-manager.ts` — confirmed SL = opposite range edge at lines 349, no ATR coupling in SL math (ATR only captured for observability).
2. `apps/worker/src/firm/session-breakout/config.ts` — confirmed windows (London 08–12, NY 14:30–19:30), range bounds $3–$80, sweet $8–$25, `tpRMultiple = 1.5`, `oneTradePerWindow`, `maxTradesPerDay = 2`.
3. `docs/ops/archive/tier3-deploy-26april.md` — original 90d backtest (WR 45.9%, +$440); walk-forward W3 –$236 already flagged as overfit at deploy; combined avg R 0.03.
4. `~/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/round2/15_session_breakout_sl_hunt.md` — 6 SL-hit table, worst case 08.5 NY long –$564 weekend-gap anatomy, `atr_at_entry = NULL` observability gap.
5. `docs/strategy/proposals/2026-05-13_session_breakout_sl_method.md` — three options (cap / swap / disable), sequencing requirement (A3 lands first), env-flag `SESSION_BREAKOUT_SL_MODE`, Karri reviewing.

**Key claims in the lesson + provenance**:

- "SL = opposite range edge, ATR only for observability" → `session-break-manager.ts:339-344` + config.ts comment "Not used for SL/TP".
- "One ATR of mean reversion = SL hit" → round2 doc's $35-range = $35-risk ≈ NY-session ATR claim.
- "Winners and losers have overlapping SL distances $30–$72" → round2 doc.
- Fisher ACD contrast (SL = noise-multiple beyond entry, never opposite edge) → general ACD knowledge, not cited in source files. Flagged explicitly as Fisher's literature position.
- Crabel cross-ref (stops at ORR fractions, not full prior-day range) → general literature; complements the volatility_expansion.md sibling lesson which already cites Crabel.

**Not in the lesson (deliberately)**:

- Specific ticket IDs (#2ad8de2c, #1147 etc) — these are operational artifacts, not library-grade.
- The A3 observability patch implementation details — those live in round3/A3_atr_at_entry_session_breakout.md.
- Discussion of regime-direction-gate as a partial mitigation — that's portfolio-level, not strategy-archetype-level.

**Style notes**: followed the volatility_expansion.md sibling's structure (What it is / Why XAUUSD / Entry trigger / Where it fails / Cross-references / Operational notes) but inserted a dedicated "Structural flaw" section and a "Pending C2 proposal" section because the SL methodology debate is the load-bearing reason this lesson exists.

**Open**: lesson can be tightened to ~450 words by collapsing the proposal-options block to one paragraph if operator wants; left expanded so future Claude sessions can read it standalone without re-opening the proposal doc.
