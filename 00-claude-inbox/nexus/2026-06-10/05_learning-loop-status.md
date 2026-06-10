# Learning-loop status — 2026-06-10

Source: `/firehose/derive-status` + `/firehose/overview` (data/pull pulled 14:30 UTC) + git log main + code read.
Mode: READ/VERIFY only.

## TL;DR

- **Derive healthy today: YES.** 2026-06-10 04:47 UTC succeeded. `latestSuccessDate=2026-06-10`. No new `:failed` marker today.
- **Lesson counts:** proposed 4, approved 0, archived 3, drifted 0. Lessons are being produced daily again (2 new on 06-09, 2 new on 06-10).
- **Confidence ceiling: STILL the binding blocker.** Unchanged. Clusters plateau small (n=6-7), confidence 0.12-0.14, formula still `min(0.95, n/50)`. Nothing reaches injection or auto-promote.
- **Karri recalibration (dispatch #2): NOT landed.** No commit on main since 2026-06-09 touches the confidence formula, inject floor, or `LESSON_AUTO_PROMOTE_MIN_OBSERVATIONS`.

## 1. Derive-status

The #80 fix holds. After a run of failures 06-04→06-08 (06-08 was the `MODULE_NOT_FOUND: derive-lessons.mjs` path bug, now fixed), derive has succeeded two days straight:

| Date (UTC) | Result |
|---|---|
| 2026-06-10 04:47 | SUCCESS |
| 2026-06-09 04:22 | SUCCESS |
| 2026-06-08 04:12 | FAILED (module-not-found — the bug #80/#76 addressed) |
| 2026-06-04..07 | FAILED (exit 1) |

`failureCount=5, successCount=2, latestSuccessAt=2026-06-10T04:47:21Z`. No failed marker for today → nexus-watch correctly silent.

## 2. Lesson production + thresholds

New lessons ARE being produced each successful day:
- 06-09: ids 4,5 (risk-advisor + trade-critic), TRENDING/unknown-session/OANDA_SL_TP, 14.3% WR over 7 trades, conf **0.140**, sample_size 1.
- 06-10: ids 6,7 (same fan-out), 16.7% WR over 6 trades, conf **0.120**, sample_size 1.

All 4 proposed are anti_patterns on the same cluster shape (TRENDING regime, unknown session, SL/TP close — the loss-prone segment). `lessons_last_7d=4`.

Distance to the gates:
- **Inject floor:** code default `minConfidence = 0.5` (injection.ts:53). Live lessons sit at 0.12-0.14 → ~0.36 below the floor. (Even a 0.40 floor variant would still exclude them.)
- **Auto-promote bar:** requires `sample_size >= 20` (LESSON_AUTO_PROMOTE_MIN_OBSERVATIONS, default 20). `sample_size` = cross-run vote count (ON CONFLICT increment on recurring fingerprint), currently 1 per lesson. None approaching 20.
- approved = 0 → nothing is injectable even if injection were flipped on.

## 3. Confidence-formula ceiling — STILL the binding blocker

`buildLessonForCluster` (derive-lessons.mjs:217/235): `confidence: Math.min(0.95, cluster.n / 50)`. To reach the 0.5 inject floor a cluster needs n=25 trades of one (regime,session,close_reason) signature. With XAUUSD demo flow the clusters plateau at n≈6-8, pinning confidence at ~0.12-0.16. **The earlier finding holds exactly** — observed conf 0.12 and 0.14 on the two fresh runs.

Two compounding starvation points, both unchanged:
1. **confidence** (`n/50`) gates injection — clusters too small to ever clear 0.5.
2. **sample_size** (cross-run fingerprint votes) gates auto-promote at ≥20 — only increments when the identical cluster recurs day-over-day; sits at 1.

Net: lessons are captured and visible (observability working), but **zero can influence trades** under current formulas. This is exactly the Karri item.

## 4. Has Karri landed the recalibration? NO

`git log main` since 2026-06-09: no commit touches the confidence formula, inject floor, or auto-promote min-observations. Most recent learning-adjacent commit is `bdd773e` (2026-06-08) — tests + the derive-lessons exit-75 transient-failure guard + documenting the `LESSON_AUTO_PROMOTE_*` env defaults (MIN_OBSERVATIONS=20, MIN_CONSISTENCY=0.8, DAILY_CAP=3). That is hardening/observability, not a recalibration of the formula. The `min(0.95, n/50)` line and the `0.5` inject default are both untouched.

Dispatch #2 (confidence-formula recalibration) is still **OUTSTANDING with Karri**. Until it lands, the learning loop runs end-to-end on the capture/derive/observe side but remains decoupled from trade decisions — which also keeps it inside the learning-infra-vs-strategy boundary (no trade-altering switch is live).

## Recommendation (report-only, not auto-actioned)

- Loop is healthy on the carry side; no action needed on derive itself.
- The blocker is purely the formula calibration, which is Karri's. Worth a Discord nudge: "derive green 2 days, 4 proposed anti_patterns all at conf 0.12-0.14 / sample_size 1 — confidence-formula recalibration (dispatch #2) still gates injection + auto-promote; nothing reaches the floor."
