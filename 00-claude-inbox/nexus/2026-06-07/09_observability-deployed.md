# Observability fixes — deploy verification (live channel)

**Date:** 2026-06-07
**Live/deployed commit:** `2b2d2ce` (main HEAD)
**Verification:** read-only — fresh 443 pulls + nexus-pg read + git topology
**Verdict:** the session's headline fix commit was NEVER merged to main. 2 of 4 fixes are NOT deployed; 2 partially/fully landed via *sibling* commits.

---

## ROOT CAUSE (read this first)

The fix the brief attributes to "#65" is commit **`2bf96ba`**
("fix(observability): honest /explorer/weaknesses + sane expectancy + shadow win/loss labels", 2026-06-04 22:54).

`2bf96ba` is **NOT an ancestor of main**. It lives only on branch
**`node-migration-nexus`** (a stale scratch branch: 25 ahead / 65 behind main).
`git merge-base --is-ancestor 2bf96ba HEAD` → **NO**.

PR **#65** that DID merge to main was `scratch/land-session-on-main` (merge `7a1625e`).
It carried the *adjacent* observability work (shadow forward-test endpoint, blackboard
staleness probe, shadow outcome-filter) but **did not** carry the explorer.ts honest-
weaknesses rewrite, the risk-snapshot degenerate-R clamp, or the
`weaknesses-firm-activity.ts` firm-heartbeat helper. Those 690 lines are stranded
on `node-migration-nexus`.

Files in `2bf96ba` that never reached main:
- `apps/api/src/routes/explorer.ts` (+102 — honest weaknesses) — **stranded**
- `apps/api/src/lib/weaknesses-firm-activity.ts` (+117, firm heartbeat reader) — **absent on main**
- `apps/api/src/routes/risk-snapshot.ts` (+71 — degenerateExcluded clamp) — **stranded**
- `apps/api/src/routes/shadow.ts` (+6 — outcome filter) — *this 6-line bit DID land separately via `7266953`*

---

## Per-fix results

### 1. Honest /explorer/weaknesses — DEPLOYED: **NO** / CORRECT: **NO**

Fresh live pull still emits the false weaknesses:
- `[high] Data Freshness: Last signal is 2862 min old` → "Check if bots are running"
- `[high] Operations: No bots are currently running — platform is idle`

Main's `explorer.ts` (last touched **2026-05-13**, `f5fcfac`) still queries the dead
legacy tables: `signals` (line 208), `jobs` (221), `bots` (258). No firm-heartbeat read.
The liveness/idle check STILL falsely says "no bots running / stale signals".
The firm-heartbeat helper (`weaknesses-firm-activity.ts`) is absent from main entirely.

### 2. Expectancy clamp — DEPLOYED: **NO (the clamp)** / number happens to be sane

- Live `/firm/risk-snapshot` → `rDistribution.expectancy = -0.443R`, avgR -0.443, winRate 0.16, totalTrades 25.
- No longer +6.49R — but the sane value comes from the **pre-existing** `oanda_backfill`
  row exclusion (already on main), NOT the new clamp.
- `degenerateExcluded` field is **ABSENT** from the live payload
  (`rDistribution` keys: totalTrades, avgR, expectancy, winRate, buckets).
- Main's risk-snapshot has **zero** degenerate handling. The MAX_PLAUSIBLE_ABS_R
  ceiling / ≥106R catch / `degenerateExcluded` count exist only in stranded `2bf96ba`.
- **Risk:** if a degenerate placeholder-stop row (tiny SL distance → huge result_r)
  reappears, the +6.49R-class blowup can recur — the guard that was supposed to prevent
  it isn't deployed.
- Note: brief expected "~+0.10R region". Actual is **-0.443R** (winRate 0.16 — genuinely losing window), not a clamp artifact.

### 3. Shadow win/loss labels — DEPLOYED: **YES** / CORRECT: **YES**

The 6-line outcome filter (`outcome IN ('tp_hit','sl_hit')`) landed on main separately
via `7266953` (in #65). Live results non-zero and labelled:
- `/shadow/per-strategy?days=30`: e.g. xau-mean-reversion 5 wins / 8 losses (win_rate 0.385),
  xau-breakout-continuation 2/0, xau-fvg 0/4. tp_hit/sl_hit counts populate correctly.
- `/shadow/comparison` and `/shadow/forward-test` both return 200 with data
  (forward-test enabled=true, rows pending — would_fire 0 so far).

### 4. Event-policy staleness probe — DEPLOYED: **YES** / behaving correct: **YES**

- Probe code `topic-freshness.ts` is on main (`e3223cd`, #65), wired into
  `notifications/detector.ts:758`, gated behind `TOPIC_FRESHNESS_ALERT_ENABLED`.
- Flag default OFF (returns null unless true/1/yes). On Worker the var is **MISSING**
  → default OFF → **no alert fires yet** (as intended).
- `ORB_ONLY_MODE` is **PRESENT** on Worker → event.policy producer (bladeApproval) dormant.
- DB confirms: `xauusd.event.policy` last published **2026-04-24**, now **43.6 days stale**
  (3089 rows total). Brief's "~40d stale" confirmed. Producer dead under ORB_ONLY_MODE = expected.

---

## Still-wrong on the live dashboard (action items)

1. **`/explorer/weaknesses` lies** — shows "no bots running" + "stale signals 2862 min"
   on every load. These feed the trust/weaknesses UI. NOT FIXED on live.
2. **`degenerateExcluded` clamp missing** from `/firm/risk-snapshot` — the +6.49R guard
   is not deployed; current sane -0.443R is incidental (backfill exclusion), not the clamp.

## Recommended remediation (operator-gated — do NOT execute without "OK kjør")

The fix exists and is tested (`2bf96ba` also added risk-snapshot.test.ts +148,
shadow.test.ts +166, weaknesses-firm-activity.test.ts +109). It is stranded on a
65-commits-behind branch, so a straight merge is unsafe. Recommend **cherry-picking
just the 3 stranded pieces** (explorer.ts rewrite + weaknesses-firm-activity.ts +
risk-snapshot degenerate clamp + their tests) onto a fresh branch off main, typecheck,
run apps/api tests, PR. Pure observability/honesty — no trade-decision change — so it
does not need Karri (per learning-infra-vs-strategy boundary). Push still gates on "OK kjør".
