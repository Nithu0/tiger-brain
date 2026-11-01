# Observe-only prep: scalp_overlap + ORB flag-verification (2026-05-11)

## TL;DR

Both proposals require ONLY a Railway env-flag flip. No code change pending. Both flags exist + functional. Proposal docs moved from `proposed` → `approved-awaiting-operator-flip`.

## Verification

### Scalp-overlap

- **Flag:** `SCALP_OVERLAP_ENABLED`
- **Read site:** `apps/worker/src/firm/scalp-overlap/config.ts:32-34`
  ```ts
  export function isScalpOverlapEnabled(): boolean {
    return process.env.SCALP_OVERLAP_ENABLED === "true";
  }
  ```
- **Gate sites:**
  - `apps/worker/src/firm/scalp-overlap/scalp-manager.ts:211` — `if (!isScalpOverlapEnabled()) return noTrade("Scalp-overlap disabled");`
  - `apps/worker/src/firm/orchestrator.ts:339` — `if (isScalpOverlapEnabled()) { ... }`
  - `apps/worker/src/firm/strategy-snapshot.ts:31` — `enabled: isScalpOverlapEnabled()`
- **Code default (no env-var):** `false` (strict `=== "true"` check)
- **Production default:** `true` on Railway (operator-flipped). Strategy currently ACTIVE.
- **Rollback path:** flip Railway env to `false` → strategy stops emitting proposals on next cycle. `xauusd.scalp.state` snapshots still emit. Rollback to `true` in 30 sek.

### ORB

- **Flag:** `ORB_ENABLED`
- **Read site:** `apps/worker/src/firm/orb/config.ts:24-26`
  ```ts
  export function isOrbEnabled(): boolean {
    return process.env.ORB_ENABLED === "true";
  }
  ```
- **Gate sites:**
  - `apps/worker/src/firm/orb/range-detector.ts:84` — `const orbEnabled = isOrbEnabled();`
  - `apps/worker/src/firm/orb/orb-manager.ts:68` — `if (!isOrbEnabled()) return noTrade("ORB disabled");`
  - `apps/worker/src/firm/orchestrator.ts:318` — `if (isOrbEnabled() && orbRange?.state === "VALID") { ... }`
  - `apps/worker/src/firm/strategy-snapshot.ts:30` — `enabled: isOrbEnabled()`
- **Code default (no env-var):** `false`
- **Production default:** `true` per `foundation-gate.ts:227` (`ORB_ENABLED: "true"` in FLAG_EXPECTATIONS, operator-confirmed 22.4). Currently ACTIVE.
- **Rollback path:** flip Railway env to `false` → orb-manager returns `noTrade` immediately, range-detection continues for retrospektiv analyse. Rollback to `true` in 30 sek.

## Updates landed

- `docs/strategy/proposals/2026-05-11_scalp_overlap_observe_only.md` — status → `approved-awaiting-operator-flip` + implementation-note
- `docs/strategy/proposals/2026-05-11_orb_observe_only.md` — status → `approved-awaiting-operator-flip` + implementation-note
- `docs/ops/operator-decisions.md` — Karri-recommended emergency-flip entry (operator timing-decision)

## Operator-action

When ready, on Railway worker:
- `SCALP_OVERLAP_ENABLED=false`
- `ORB_ENABLED=false`

Per operator-prinsipp 1 + 5 — Claude reports + recommends, operator beslutter timing. No "OK kjør" trigger in this session for the flip itself.

## Re-activation order (per proposal docs)

1. regime-direction-gate live (proposal `regime_direction_gate.md`)
2. sl-cooldown live (proposal `sl_cooldown.md`)
3. session-block live (proposal `session_block_gate.md`)
4. For ORB: R:R-fix (TP ≥ 1.5× SL, separate proposal needed)
5. THEN flip flags back to `true`

## Out-of-scope (intentional)

- Did not touch Railway env (operator-gated)
- Did not push (operator-gated)
- Did not implement strategy-side code changes (no change needed)
