# Portfolio Brain perf fix — Map lookup

**Date:** 2026-05-11
**Commit:** 48cd5a610acc6a9bd71fbf4c8415a654fe75a2f3
**File:** `apps/worker/src/firm/portfolio-brain.ts`
**Per:** perf-audit-2026-05-11

## What changed

Replaced `Array.find()` inside nested loop with a single `Map` construction + O(1) `.get()` lookups.

### Before

```ts
for (const reg of MANAGER_REGISTRY) {
  for (const strat of reg.strategies) {
    const p = perfRows.find(r => r.strategy === strat);  // O(n) per strat
    if (p) { ... }
  }
}
```

### After

```ts
const perfMap = new Map<string, typeof perfRows[number]>(perfRows.map(r => [r.strategy, r]));
for (const reg of MANAGER_REGISTRY) {
  for (const strat of reg.strategies) {
    const p = perfMap.get(strat);  // O(1)
    if (p) { ... }
  }
}
```

## Impact

- ~15 linear searches per cycle (5 managers × 3 strategies × O(n)) → single Map build + 15 O(1) gets.
- Estimated 1–2ms saved per `runPortfolioBrain()` call.
- No behavior change — identical lookup semantics, same `if (p)` branch.

## Lines touched

`apps/worker/src/firm/portfolio-brain.ts:298-303` — added Map construction line, changed `perfRows.find(...)` → `perfMap.get(strat)`.

Net diff: +2 / -1.

## Verification

- `npx tsc --noEmit` — clean (no output).
- `npm test` — 428/428 pass, 0 fail, ~2.38s.

## Not pushed

Awaiting "OK kjør" per binding rule.
