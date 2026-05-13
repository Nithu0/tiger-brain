# Granular postmortem features audit — 3 dormant columns

**Date:** 2026-05-13
**Scope:** `postmortems.entry_score`, `postmortems.execution_score`, `postmortems.cleanliness`
**Status:** 49/49 rows have all 3 columns NULL since first row (2026-05-01).
**Origin:** all 3 columns added in same commit as the table (e551ff2 — 2026-04-29).

---

## Per-column verdict

### 1. `entry_score` (NUMERIC) — **CONDITIONAL (dead branch)**

- **Writer** (`postmortem-hook.ts:191`) reads `scores["entry-window"]`.
- **Source** (`postmortem.ts:430-460`) populates `deptScores` only with keys: `"technical-analyst"`, `"pulse"`, and per-challenge agent. **The key `"entry-window"` is never set anywhere in repo** (verified with `grep` across all .ts + git history `-S`).
- The writer line is reachable but reads a key that never exists → always NULL.

### 2. `execution_score` (NUMERIC) — **CONDITIONAL (dead branch)**

- Same pattern as entry_score. Writer reads `scores["execution-quality"]`; that key is also never set in `deptScores`. Note that `"execution-quality"` *does* exist as a firm-agent role (`fill-quality.ts:98` — "Forge desk"), but postmortem.ts never injects it into `deptScores`.

### 3. `cleanliness` (TEXT) — **CONDITIONAL (dead branch)**

- Writer (`postmortem-hook.ts:172`): `const [classification, cleanliness] = (pmResult.failureClass ?? "UNKNOWN").split(" / ")`.
- `pmResult.failureClass` is the `FailureClass` enum — single token (e.g. `"RIGHT_THESIS_BAD_EXECUTION"`). **No `" / "` ever in it.** The composite `${failureClass} / ${managementClass}` string is built only for log lines (postmortem.ts:474) and the blackboard thesis (postmortem.ts:573), not put into `pmResult.failureClass`.
- Meanwhile `pmResult.managementClass` is exposed as its own field (`postmortem.ts:602`) — the writer simply ignores it.

---

## Recommended dispositions

### cleanliness — **1-LOC bug-fix candidate (file as fix, no proposal needed)**

Replace at `postmortem-hook.ts:172,188`:
```ts
const classification = pmResult.failureClass ?? "UNKNOWN";
// ...
managementResult.managementClass ?? pmResult.managementClass ?? null,   // pass the field directly
```
Concrete edit: drop the `.split(" / ")`, use `pmResult.managementClass` for the `$5` bind. Restores intended behaviour (`bug fix that restores intended behaviour` → no Karri proposal per CLAUDE.md). After fix: column starts filling with `CLEAN`/`STALE_TRADE_CUT_LATE`/`DEGRADATION_MISSED`/etc. (7 values from `position-management/classifier.ts`). Backlog for Karri C4 reframe: pair `classification × managementClass` cross-tab is a strong sizing signal.

### entry_score & execution_score — **Feature opportunity, not a bug**

Wiring these would require `postmortem.ts` to actually grade the entry window and execution quality. Hooks already exist:
- `executionWindowScore` is computed at postmortem.ts:486 (passed to firm_memory.evidence but not deptScores).
- A `fill-quality` (Forge) firm-agent exists but doesn't feed deptScores either.

**Disposition:** Surface as **feature opportunity for Karri postmortem-feedback C4 reframe** — these granular scores could feed sizing logic (entry-window grade is already a free signal we throw away). Two clean wires:
1. `deptScores["entry-window"] = executionWindowScore` at postmortem.ts:~487 (1 line, free).
2. `deptScores["execution-quality"] = ...` would need a new grader (Forge digest or close-vs-entry slippage). Larger.

Item (1) is itself a 1-LOC bug-fix candidate — the score is already computed.

---

## TL;DR

All 3 columns are **conditional / dead-branch**, not orphan and not planned-but-empty. Two of three (`cleanliness` and `entry_score`) can be wired with 1-LOC each from data that already exists in `pmResult`/`executionWindowScore`. `execution_score` needs a real grader and is the only true feature-opportunity ask for Karri.

**Recommend:** ship `cleanliness` + `entry_score` wiring as a single bug-fix commit (restores intended behaviour, no proposal). File `execution_score` grading as a postmortem-feedback C4 sub-item for Karri review.

**Files touched if wiring:**
- `apps/worker/src/firm/postmortem-hook.ts` (lines 172, 188)
- `apps/worker/src/firm/postmortem.ts` (line ~487 to add deptScores["entry-window"])
