# wf lane: lesson-promo-threshold — 2026-06-08

**Verdict:** PROPOSAL doc delivered. No code. Branch `docs/wf-lesson-promo`, commit `dc5c477`.

## What was asked

Auto-promotion proposed→approved is built (PR #73, default OFF). It needs an
occurrence+confidence threshold decision before enabling. Analyze proposed
lessons + agent_lessons schema, draft concrete threshold recommendation +
guard rails as a proposal doc (Reviewer: Karri). Commit doc on branch. No code.

## What I found (the load-bearing parts)

### The code already has the thresholds wired
`scripts/firehose/auto-promote-lessons.mjs` implements eligibility:
`sample_size >= MIN_OBSERVATIONS` (def 20) AND `consistency >= MIN_CONSISTENCY`
(def 0.8), capped at `DAILY_CAP` (def 3). So the lane is NOT "build thresholds"
— it's "decide/justify the numbers + add missing guard rails". The proposal does
that.

### Live data (pulled over 443, DB was firewalled as expected)
- DB direct (`mcp__nexus-pg__query`) → `EHOSTUNREACH 66.33.22.236:58688`. Used
  `GET /firehose/overview` + `/firehose/lessons` instead (HTTP 200).
- Whole corpus: **3 proposed, 0 approved, 0 archived, 0 drifted.** All
  `anti_pattern`, all `xauusd`, all `sample_size=1`, consistency 0.667–0.778
  (none clears 0.80). So enabling the flag today = 0 promotions = behaviour-neutral.

### Finding A (most important) — `sample_size` is a run-vote counter, not trade count
`derive-lessons.mjs:276 proposeLesson()` inserts literal `sample_size=1` and only
`+1` per nightly run via `ON CONFLICT (fingerprint) DO UPDATE SET sample_size =
agent_lessons.sample_size + 1`. The actual trade count (`cluster.n`, e.g. 18)
lives ONLY in `confidence (= min(0.95, n/50))` and the rationale prose.

Consequence: `MIN_OBSERVATIONS=20` means "must be re-derived on 20 nightly runs"
(~3 weeks), NOT "20 trades". That's a defensible time-soak, but it treats an
18-trade and a 5-trade cluster identically once both soak 20 nights. So the
proposal adds a **separate trade-count floor**.

This is consistent with feature-flags.md calling sample_size a "voting
accumulator" — by-design, not a bug. But it must be a conscious decision.

## What the proposal recommends (Karri to confirm/revise)
1. KEEP defaults: min_obs 20 / consistency 0.80 / daily_cap 3.
2. GR-1 trade-floor: add `MIN_TRADES` (def 15). Impl (a) new `cluster_trades`
   column (preferred long-term) or (b) gate on `confidence >= 0.30` (= ~15 trades,
   zero-migration, ship now). Under (b): ids 1,2 pass, id 3 (~11 trades) filtered.
3. GR-2 anti_pattern-only first activation window (anti = caution direction =
   fail-safe; pattern could encourage entries = higher blast radius).
4. GR-3 max-age re-validation: `last_validated_at >= NOW()-45d`.
5. Question for Karri: exclude `OANDA_BACKFILL` close-reason clusters at derivation
   (id 2 is backfill = reconstructed history, low-quality evidence). Derivation
   logic is Karri's domain.
6. Confirm drift-detection runs on approved lessons before flip.

## Constraints honored
- No Railway flips. No push/merge. No strategy/gate/risk code touched.
- ai-1 owns ADX/regime — did not touch indicator code (read-only data pull only).
- Docs-only commit; husky pre-commit (tsc on staged workspace .ts) is a no-op for
  a markdown-only change. Did not bypass husky.

## Deliverable
`docs/strategy/proposals/2026-06-08_lesson-auto-promotion-threshold.md` on branch
`docs/wf-lesson-promo` (commit dc5c477).

## Follow-up tasks surfaced
- Karri review of the 6 decision points above (auto-send to Karri if filed in work
  hours per CLAUDE.md).
- After approval: code follow-up implementing GR-1b/GR-2/GR-3 as default-OFF env
  gates in auto-promote-lessons.mjs (separate gated branch).
- Investigate `OANDA_BACKFILL` clusters polluting the lesson corpus (id 2).
- Long-term: add `cluster_trades` column to agent_lessons so the trade-floor is
  exact, not confidence-derived.
