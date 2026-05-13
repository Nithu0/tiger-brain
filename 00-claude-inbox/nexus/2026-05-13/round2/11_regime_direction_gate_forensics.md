# regime_direction_gate forensics — verdict + fix

**Verdict: A (gate is deployed in code, but env-flag is OFF in production — gate body never executes, so no `gate_decisions` rows are written).**

**One-sentence root cause:** `REGIME_DIRECTION_GATE_ENABLED` is unset on Railway worker (default `false`), so `strategy-blade.ts:133` short-circuits before the gate ever evaluates or logs anything.

**Single concrete fix-action:** Flip `REGIME_DIRECTION_GATE_ENABLED=true` on Railway worker (operator action — I cannot flip env vars). NOTE: this flips the gate from dormant to **hard-rejecting**; there is no soft-log/observe-only mode for this gate. Get Karri's explicit OK first per proposal status `pending`.

---

## Evidence

### 1. Gate code exists and is wired

- File: `apps/worker/src/firm/gates/regime-direction-gate.ts` (114 lines, pure logic, env-gated at line 63–65 via `isRegimeDirectionGateEnabled()`).
- Wired in `apps/worker/src/firm/strategy-blade.ts:133`:
  ```ts
  if (isRegimeDirectionGateEnabled()) {
    try {
      const portfolioMsg = await input.board.latest("xauusd.portfolio.context", 600);
      ...
      const decision = evaluateRegimeDirectionGate({ ... });
      if (decision.decision === "reject") { ... return finalize(...) }
      checks.push({ name: "regime_direction", passed: true, ... });
    }
  }
  ```
- Runs independent of `STRATEGY_BLADE_ENABLED` (same pattern as `sl_cooldown` and `daily_trade_cap`).

### 2. Env-flag is default OFF, no production override

- `.env.example:134`: `# REGIME_DIRECTION_GATE_ENABLED=false` (commented).
- `regime-direction-gate.ts:64`: `boolEnv("REGIME_DIRECTION_GATE_ENABLED", false)`.
- `docs/ops/phase-status.md:70`: marked TIER 1, current value `false`, awaiting "OK kjør".
- Proposal `docs/strategy/proposals/2026-05-11_regime_direction_gate.md`: **Status `pending`** (Karri review). Implementation landed env-gated default-off per operator-prinsipp #4.

### 3. Logging path is NOT broken — other gates write fine

Last 30d in `gate_decisions`:

| gate_name | rows | first_seen | last_seen |
|---|---:|---|---|
| risk_level | 1987 | 2026-04-20 | 2026-05-12 17:35Z |
| scalp_overlap_asia | 1987 | 2026-04-20 | 2026-05-12 17:35Z |
| ranging_conviction | 1987 | 2026-04-20 | 2026-05-12 17:35Z |
| entry_stack_cooldown | 1965 | 2026-04-20 | 2026-05-12 17:35Z |
| daily_trade_cap | 8 | 2026-05-12 14:00Z | 2026-05-12 17:35Z |
| session_block | 8 | 2026-05-12 14:00Z | 2026-05-12 17:35Z |
| **regime_direction_gate** | **0** | — | — |

The four "new_gates" write via `persistGateDecisions()` in `strategy-blade.ts:309` whenever `STRATEGY_BLADE_NEW_GATES=true`. `daily_trade_cap` writes via dedicated `persistDailyCapDecision()` at `strategy-blade.ts:181`. Both fire only when their flag is ON (8 rows on 12.5 confirms `DAILY_TRADE_CAP_ENABLED=true` and `SESSION_BLOCK_ENABLED=true` were flipped that day).

### 4. regime_direction_gate has NO soft-log path

Unlike `daily_trade_cap` (which has `persistDailyCapDecision` called once the flag is on), the `regime_direction_gate` block in `strategy-blade.ts:133-165` only `checks.push(...)` to the in-memory decision array. **It never inserts a row in `gate_decisions`**, even when the flag is on. Allow/reject decisions only surface via the `BladeDecision.checks` returned to the caller (i.e. logged via the surrounding decision packet, not as a discrete gate_decisions audit row).

This means: even if the operator flips `REGIME_DIRECTION_GATE_ENABLED=true`, the `gate_decisions` table will still show 0 rows for `regime_direction_gate` unless a `persistRegimeDirectionDecision()` helper is added (mirror of `persistDailyCapDecision`).

---

## Recommendation

**Two-step fix:**

1. **Operator (Karri-gated):** Flip `REGIME_DIRECTION_GATE_ENABLED=true` on Railway worker. This activates the hard reject. Per proposal, expected to block ~$2-3k of counter-trend mean-reversion damage / 30d.

2. **Claude (separate small commit, observability — no behaviour change):** Add `persistRegimeDirectionDecision()` mirroring `persistDailyCapDecision()` so the gate writes to `gate_decisions` for audit/gate-impact joins. Currently the gate is invisible to `foundation-monitor.ts:127` and `gate-impact.ts:95` even when it's running. This is a logging gap, not a logic bug.

**Status:** Trend-pause proxy is verifiably broken — operator's intuition correct. The proxy mitigation Karri asked about is implemented in code but never executed in production. Single env flag flip restores it; observability commit can land in parallel.
