---
date: 2026-05-13
type: investigation
project: nexus
status: open
---

# sl_cooldown gate is evaluating but never recording to `gate_decisions`

## TL;DR

The SL-cooldown gate IS evaluating on every entry attempt and IS arming/clearing
state via the postmortem-hook (hence the 2 `firm_state` rows). But the
entry-evaluation path in `strategy-blade.ts` has **no `gate_decisions` INSERT**
— neither for pass nor for reject. This is a pure persistence omission; the
gate logic itself works. Fix is ~30 lines: add a `persistSlCooldownDecision()`
helper mirroring `persistDailyCapDecision()` and call it inside the existing
`if (isSlCooldownEnabled())` block.

## Evidence

### 1. Entry-evaluation path (strategy-blade.ts:96–125)

`apps/worker/src/firm/strategy-blade.ts` lines 96–125 contains the only
entry-side call to `evaluateSlCooldown`. The block:

- Reads `firm_state` via `evaluateSlCooldown()` (gate logic — works fine).
- Pushes a `MiniBladeCheck` onto the in-memory `checks` array (used for the
  decision object returned to the strategy + for log lines).
- On reject: returns early via `finalize()`.
- On pass: continues to next gate.

**There is no `persistSlCooldownDecision()` / `recordGateDecision()` / `INSERT
INTO gate_decisions` anywhere in this block** — and no such helper is even
defined in the file. Contrast with the two gates *immediately below* it:

- `regime_direction` (lines 134–172) calls `persistRegimeDirectionDecision()`
  every evaluation (line 147), defined at lines 440–472.
- `daily_trade_cap` (lines 183–213) calls `persistDailyCapDecision()` every
  evaluation (line 188), defined at lines 397–429.

Both use the exact same INSERT shape:
```
INSERT INTO gate_decisions (id, decision_cycle_id, symbol, gate_name,
  would_reject, hard_rejected, reason, context) VALUES (...)
```

### 2. SL-event write path (the part that IS working)

`apps/worker/src/firm/postmortem-hook.ts` lines 131–161 is the
**bookkeeping** path, NOT the entry-evaluation path:

- Runs once per newly closed trade, inside the postmortem loop.
- On SL close → `recordSlHit(db, strategyId, tradeId, closedAt)` which
  UPSERTs into `firm_state` under key `sl_cooldown:<strategyId>`.
- On winning close → `clearSlCooldown()` (UPSERT with `lastSlAt: null`).

This is completely separate from `evaluateSlCooldown()`. The two `firm_state`
rows (`sl_cooldown:xau-session-breakout` @19:57Z,
`sl_cooldown:xau-volatility-expansion` @17:21Z) prove this path works.

### 3. Gate definition (sl-cooldown-gate.ts)

`apps/worker/src/firm/gates/sl-cooldown-gate.ts` exports:

- `evaluateSlCooldown()` — pure logic, returns `{ allowed, reason, detail }`.
  Does NOT touch `gate_decisions`.
- `recordSlHit()` / `clearSlCooldown()` — both UPSERT to `firm_state`, not
  `gate_decisions`.

So the gate module itself has no persistence-to-`gate_decisions` concept at
all. This was an oversight at landing time — the daily_trade_cap +
regime_direction proposals (filed AFTER sl_cooldown) both included the
persist helper from the start, but sl_cooldown's pattern predates them.

### 4. Comparison to session_block (which IS recording)

`session_block` lives inside `gates/new-gates.ts` (lines 194–211) — it's one
of the gates returned in `bundle.evaluations` and gets persisted via
`persistGateDecisions(db, cycleId, bundle, ctx)` in strategy-blade.ts:316.
That's why every cycle records a `session_block` row even when the gate
passes — the bundle-persist loop writes one row per evaluation.

`sl_cooldown` doesn't go through `new-gates.ts` and isn't in any bundle, so
it gets no persist call.

## Minimal fix (single file, ~30 lines)

Mirror `persistDailyCapDecision` (strategy-blade.ts:397–429):

1. Add a small `persistSlCooldownDecision(db, cycleId, strategyId, direction, decision)`
   helper next to `persistDailyCapDecision` in `strategy-blade.ts`.
2. Inside `if (isSlCooldownEnabled())` block (line 96), after the
   `evaluateSlCooldown` call, fire-and-forget the persist (`.catch(() => {})`),
   regardless of pass/fail — same pattern as the other two gates.
3. Context payload should include `strategyId`, `direction`, `path:
   "strategy_blade"`, and the gate's `detail` field (which carries
   remaining-minutes / "no prior SL" / etc.).
4. `would_reject == hard_rejected` because we only persist when the flag is
   on (no soft-log-while-disabled mode for this gate currently — matches
   daily_trade_cap behaviour).

No schema change. No new env var. No behaviour change for trading. Existing
tests don't need updating (none of them currently assert on a
`gate_decisions` write for sl_cooldown).

## Files referenced

- `/home/nithu/code/ai-assistent/apps/worker/src/firm/strategy-blade.ts` (lines 96–125, 397–472)
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/gates/sl-cooldown-gate.ts`
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/postmortem-hook.ts` (lines 131–161)
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/gates/new-gates.ts` (lines 194–211, 230–280 — session_block + persist pattern)

## Status

Open. Read-only diagnosis — no code edits made per operator instruction.
Awaiting operator decision: fix as bug (no proposal needed — restoring
intended audit-trail behaviour) or file as a quick proposal.
