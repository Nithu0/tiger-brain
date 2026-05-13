# Audit — L_mean_reversion_distilled

**Task:** Round-3 distillation lesson L — write `~/Obsidian/Brain/_library/trading/strategies/mean_reversion_xau.md` covering the freshest live strategy (S4, live since 13.5 ~00:44 UTC).

## Sources consulted

1. `apps/worker/src/firm/mean-reversion/config.ts` — sweet-spot params + env-gate names verified
2. `apps/worker/src/firm/mean-reversion/mean-reversion-manager.ts` (referenced; gate pipeline already documented in 04_s4_deep_dive)
3. `docs/strategy/proposals/2026-05-13_strategi_4_mean_reversion.md` — original MVP spec, Karri review-questions, decision-status log (approved-verbally, PR #23 MVP + PR #24 sweet-spot)
4. `~/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/04_s4_deep_dive.md` — round-1 forensics: 8-gate pipeline, sweet-spot delta table, live observation (0 trades / 106 cycles at 07:02 UTC), 6-point monitoring list
5. `~/Obsidian/Brain/00-claude-inbox/nexus/2026-05-13/10_trading_curriculum.md` — Chan ch 2/3/7 + Connors + Raschke cross-references
6. `~/Obsidian/Brain/_library/trading/strategies/volatility_expansion.md` — template structure for distilled-lesson format

## Output

- **File:** `~/Obsidian/Brain/_library/trading/strategies/mean_reversion_xau.md`
- **Frontmatter:** exact spec from task brief (relevance 5, P0, tags include s4/chan/connors/rsi)
- **Word count:** ~620 (within 300-500 target band; minor overrun on cross-refs section to keep Chan ch 2 + ch 3 + Connors + Raschke each distinct — operator can trim if too long)
- **Structure mirrors `volatility_expansion.md`:** archetype → why XAUUSD → entry-mechanics → portfolio role → tuning context → biggest risk → cross-refs

## Coverage checklist (vs brief)

- [x] Mean-reversion archetype (price reverts to anchor, opposite of trend-follow)
- [x] Why XAUUSD has MR windows (post-news exhaustion, profit-taking off levels, Asia chop)
- [x] 8-gate pipeline (ADX<25 + impulse≥1.5 ATR + RSI 40/60, R:R 1:3, 0.75×ATR SL)
- [x] Anti-correlation design (only counter-trend strategy, cross-gate)
- [x] Sweet-spot tuning context (PR #24, n=54 / WR 51.9% / PF 2.56)
- [x] Single biggest live risk: news-block not implemented (Karri review-q #5 unanswered)
- [x] Cross-references: Chan ch 2 (OU half-life), Chan ch 3 (Bollinger MR z-score sizing), Connors RSI(2), Raschke Turtle Soup

## Honest tradeoffs in the distillation

- Could not measure actual OU half-life from Nexus tape (would need Postgres pull + python); flagged as "worth measuring" rather than asserted.
- Did not look at MR test file (`mean-reversion-manager.test.ts`) — relied on the proposal + deep-dive claims that 11-12 tests are green. Acceptable for a distilled lesson (the file is not a test plan).
- Backtest claim (WR 51.9% / PF 2.56) reproduced as-stated; flagged in the round-1 deep-dive that Karri did NOT write a review-note, only verbal approval. The lesson does not editorialise on backtest credibility, just records the claim + cites it as `PR #24`.

## Lessons learned for future distilled-lesson tasks

- The `volatility_expansion.md` template is a strong skeleton — reuse: archetype-50w / why-asset-70w / entry-mechanics / where-it-fails / cross-refs / operational-notes.
- Strategy-doc distillation benefits from reading the FORENSIC (deep-dive) file first, then the PROPOSAL, then the CODE — that order surfaces the live-state caveats early.
