# C1 addendum audit — 2026-05-13 PM

**File touched:** `docs/strategy/proposals/2026-05-13_null_direction_block_eligible.md`
**Action:** appended Round 5 addendum + updated frontmatter. No git commit (main thread batches).

## Frontmatter changes

- `status: proposed` → `status: needs-pivot — see addendum`
- `last_updated: 2026-05-13` → `last_updated: 2026-05-13 PM`
- Added `pivot_reason: stale_premise_self_healed_pre_A2`
- Header status line + "Sist oppdatert" line updated to match.
- "Decision: _pending_" → "Decision: _pending — see addendum below_"

## Addendum content (new "## Round 5 addendum (2026-05-13 PM)" section)

Four subsections covering the required points:

1. **What changed** — table with TRENDING null-rate by day: 10.5 = 100%, 11.5 = 97.7% (592/606), 12.5 = 0% (0/355), 13.5 = 0% (0/46). Self-heal located between 11.5 16:00Z (last null) and 11.5 22:00Z (first OK). Cause not yet identified. Sourced from `round5/a2_null_reason_histogram.md`.

2. **Implication** — A/B/C are all NO-OP against current data. Zero null directions in TRENDING for two days. Shipping any runtime gate today changes nothing in the live loop. The protection window for the 11.5 cluster has closed; the bug healed before A2 instrumentation that was supposed to characterize it.

3. **Proposed pivot** — regression-guard alert: rolling 1h query over `xauusd.portfolio.context`, fire Discord ping to Karri+operator if `null/total > T` in TRENDING regime. Suggested `T = 10%`. Pure-report path (no auto-action per binding operator-prinsipp #1), zero blast radius, A2 reason-histogram attached when triggered.

4. **Open questions for Karri** — (a) threshold T = 5% / 10% / 20%, (b) whether to still investigate the unknown self-heal cause (Railway deploy timeline check 11.5 16–22Z + classifier.ts diff vs morning state), (c) archive vs dormant.

5. **Status** subsection — explicit restatement of frontmatter changes + action item.

## Verification

- Frontmatter YAML valid (pivot_reason added before `related_proposals`).
- Original proposal body left intact — Options A/B/C still readable for revival path.
- No code touched. No env vars proposed. No git operations.
- Word-count of addendum ~520 words (excluding table); fits "proposal addendum" not "new proposal".

## Not done (intentional)

- No commit (main thread batches all Round 5 → Round 6 addenda).
- No Karri-Discord auto-send (this is an addendum to an existing pending proposal; main thread / operator decides whether to re-ping).
- No code-side regression-guard implementation — that's Karri's call on threshold T first.
