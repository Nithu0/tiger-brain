---
date: 2026-05-11
project: nexus
type: fix-session
status: implemented-behind-flag
needs-review: karri
---

# Funnel-drain fix — env-gated, default OFF

## What landed

- **Commit:** `649e0e5` (local only, NOT pushed)
- **Files:**
  - `apps/worker/src/firm/strategy-execution.ts` — added `envBool` helper + `FUNNEL_DRAIN_PROPOSALS` flag + branched proposal-read loop
  - `.env.example` — new "Strategy execution funnel" section with the flag
  - `docs/strategy/proposals/2026-05-11_funnel_drain.md` — Karri-review proposal
  - `docs/strategy/proposals/README.md` — added to active-list index

## What it does

When `FUNNEL_DRAIN_PROPOSALS=true`:
```ts
const proposals = await board.read(cfg.topic, 100, 60); // all unprocessed
```

When `FUNNEL_DRAIN_PROPOSALS=false` (default — current behavior):
```ts
const proposals = [await board.latest(cfg.topic, 60)].filter(Boolean); // legacy
```

Dedup via the existing `processedSignalIds` Set (bounded 1000, FIFO-trim 200) handles overlap between cycles. mini-Blade gate still runs per-proposal — no risk-envelope change per trade, just trade-frequency.

## Why env-gated

Bug-or-feature borderline. The silent drop is unintended, but a frequency-up shift is strategy-impact per CLAUDE.md. Operator-prinsipp 1 (rapporter, ikke handle) + Karri-protokoll → flag-gate, default OFF, await review.

## Verification

- `cd apps/worker && npx tsc --noEmit` — clean
- `npx tsx --test src/firm/strategy-execution.test.ts` — 5/5 pass (flag off; no behavior change for existing tests)
- Drain-mode itself has no dedicated test yet — should add before flipping the flag

## Estimated impact (when flag flipped on)

| Strategi | Proposals/dag | Latest-only fanget | Estimated drop |
|---|---|---|---|
| `xau-orb` | ~9 | ~7 | ~22% |
| `xau-scalp-overlap` | ~14 | ~9 | ~36% |
| `xau-session-breakout` | ~6 | ~5 | ~17% |
| `xau-volatility-expansion` | ~4 | ~4 | ~0% |

→ ~240 droppede over 30d, ~5% gate-pass-rate → **+12 trades / 30d** (grovt anslag fra audit, ikke backtest).

## Recommendation: hold Discord-ping to Karri for now

Reasoning:
1. Proposal is **non-urgent** — flag is OFF, no live impact today.
2. Karri har 2 åpne proposals fra 05-08 (`break_even_trigger_lower`, `risk_pct_clamp`) som ikke er reviewed enda — stacker vi en tredje samme uke uten å stille spørsmål om volum, blir det støy fremfor signal.
3. Proposalen åpner et bedre spørsmål for ham (q1: shadow-data først, eller flipp direkte?) som er verdt en sammenheng-kontekst, ikke en standalone ping.

**Forslag:** la operatør pakke alle 3 åpne proposals i én Discord-melding ved neste sjekkpunkt — gir Karri en review-batch i stedet for tre separate notifikasjoner. Eller vent til 1-2 av de eksisterende er reviewed først.

Si fra hvis du vil pinge nå likevel — fanger Karri-webhook-URL fra `reference_strategy_reviewer.md`.

## Push status

- **Not pushed.** Awaiting operator "OK kjør" gate.
- Other unrelated working-tree changes are still uncommitted (analytics.ts, followups.ts, managers.ts, strategy-blade.test.ts, doc updates) — I did not touch those.

## Open follow-ups

- [ ] Add drain-mode unit test before flag-flip (e.g. emit 3 proposals on same topic, assert all 3 evaluated under flag=true, only 1 under flag=false)
- [ ] Decide w/ Karri: shadow-data-first or direct flip
- [ ] If shadow-first: build a small "funnel_audit_shadow" counter (A0-style agent, ~30 min) that logs "ville-vært-drained" proposal IDs over 7 days for calibration
