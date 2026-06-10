# Build / Deploy Reconcile — Nexus main

Date: 2026-06-07
Repo: /home/nithu/code/ai-assistent
Scope: READ/ANALYSIS ONLY. Confirm deployed==intended; find stranded fixes; dispose node-migration-nexus; PR #73 status.

---

## TL;DR

- **Is everything intended deployed? NO.** Live build `2b2d2ce` IS current origin/main HEAD (deployed==current ✓). But several functional fixes from my session exist ONLY on the `node-migration-nexus` branch and were never re-landed on main — they are stranded. Plus PR #73 (the learning-loop closer) is still OPEN.
- **node-migration-nexus disposition:** mostly superseded, but NOT safe to delete yet — it holds 3 genuinely-stranded recent fixes (data-honesty observability, runnable-backtest, N+1 perf) plus older never-landed code. Rescue the 3, then archive.

---

## 1. Live build == origin/main HEAD — CONFIRMED ✓

- `origin/main` HEAD = `2b2d2cef5289cf4c777a9d0e4ac1b24529523740` = `2b2d2ce`.
- `2b2d2ce` = Merge PR #72 (config hardening), merged 2026-06-07 09:00 UTC.
- Deployed build matches current origin/main. No drift between deployed and tip.

## 2. Key features ON main — verified by content grep on origin/main

| Feature | PR | On main? | Evidence |
|---|---|---|---|
| Hard position-size circuit breaker | #61 | YES | `2e5cdbf`, merged via `0f4cb44` |
| Breaker clamps (not reject) + scalp risk% ceiling 1.5 | #67 | YES | `184bf7b` / `72d94ba` |
| Calibration SAFE_AUTO_APPLY bounds (≥30 samples, ±20%) | #68 | YES | `5f309a7` / `3ee2dba` |
| risk_level_at_entry backfill on imports | #69 | YES | `b6f3919` / `1293dc3` |
| Lessons TARGET-role tagging (injection reach) | #71 | YES | `3a37500` on main |
| Karri 2026-06-05 proposal decisions | #70 | YES | `7ad3d35` / `34f7bff` |
| Infra backlog (size=0 backfill, multiplier observability) | #71 | YES | `95b9096`, `d4c2506`, `16cecbb` |

All Karri risk/calibration work is on main and deployed.

### My session ("land-session-on-main") — PR #65 landed only 8 of the commits

PR #65 merged these 8 (all present on main):
1. risk_level population (shadow outcome filter + sizing characterization) — `7266953` ✓
   - NOTE: this is the *visibility* half. The *write-side* risk_level_at_entry population came separately via #69 `b6f3919` (also on main). So "risk_level population" = LANDED.
2. staleness probe + Polygon fallback (resilience, default OFF) — `e3223cd` ✓
3. polygon fallback (same commit `e3223cd`) ✓
4. shadow labels — partially: the `/learning` + `/shadow/forward-test` endpoints landed (`0764868`, `4f4cd06`) ✓, BUT the explorer/risk-snapshot honesty rework did NOT (see stranded below).
5. event-policy / staleness probe — `e3223cd` ✓
6. learning-loop primers + shadow forward-test — `4f4cd06` ✓
7. OANDA-computed ADX/ATR fallback (event-policy probe sibling) — `2085fd7` ✓
8. backtest repoint to ohlcv_candles + M1 backfill — `42062e8` ✓
9. prinsipp-6 rescind doc — `d122bc1` ✓

### STRANDED — my fixes that did NOT make it to main

These exist on `node-migration-nexus` only. Confirmed absent from origin/main by distinctive-string grep:

1. **`2bf96ba` — honest /explorer/weaknesses + sane expectancy clamp + shadow win/loss labels** — STRANDED.
   - Adds `apps/api/src/lib/weaknesses-firm-activity.ts` (+test) — NOT on main (`git ls-tree` confirms file absent).
   - Reworks `apps/api/src/routes/explorer.ts` with "data-honesty (2026-06-04)" markers — main's explorer.ts has ZERO `data-honesty` markers.
   - Poison-outlier exclusion in `risk-snapshot.ts` (the +6.233R-at-31.7%-WR impossible-expectancy fix) — main's `risk-snapshot.ts` has its OWN earlier expectancy calc (from `f5fcfac`, the 6-transparency-endpoints PR) but NOT the poison-exclusion logic; string "poisoned outliers" absent from all of main.
   - shadow.ts win/loss label change — stranded with the rest.
   - 690 insertions across 8 files, all stranded. This is the single biggest stranded chunk and it is functional observability (REPORT-only, no trade impact → safe to land freely per learning-infra boundary).

2. **`c6a6b03` — make ORB replay runnable on existing 15min data + actionable empty-data error + runbook** — STRANDED.
   - Main has `42062e8` (repoint runner to ohlcv_candles) but NOT this commit's runner.ts rework, the actionable empty-data message, the runner.test.ts (172 lines), or `docs/ops/backtest-runbook.md`. String "actionable" / "Empty-data path" absent from main scripts.
   - These two backtest commits overlap in intent but are different content. The "runnable + clear error + runbook" half is stranded.

3. **`a9e54f3` — perf(oanda-sync): batch N+1 layer-1 lookup in backfillClosedTrades** — STRANDED.
   - "N+1 fix" / "layer-1 batched idempotency" strings absent from main. Main got a *different* oanda-sync idempotency hardening (`e91731a`, NULL-oanda_trade_id twins) but not this N+1 batch. Pure perf, safe to land.

## 3. node-migration-nexus disposition

- Diverged from main at **`28242f0`** (2026-05-23). Currently **25 commits ahead, 65 behind** origin/main.
- Open as **PR #60** (state OPEN, base main) — never merged.
- Two tiers of unique commits:

**Tier A — recent session work, genuinely stranded, WORTH RESCUING (REPORT/perf-only, no Karri gate):**
- `2bf96ba` data-honesty observability (explorer/weaknesses/expectancy/shadow) — biggest, most valuable
- `c6a6b03` runnable ORB backtest + runbook
- `a9e54f3` oanda-sync N+1 batch perf

**Tier B — older node-migration backlog (May 24-25), never landed as code, effectively superseded/abandoned:**
- `685164a` operator-control live close/modify-SL/TP (adds positions.ts route + operator-control.ts lib) — only the *proposal doc* exists on main, code never landed. Karri-gated (write-side, money-near) — do NOT auto-rescue; re-propose if still wanted.
- `7110e5c` session-breakout selectable SL mode — only proposal doc on main. Strategy change → Karri.
- `cc02426` regime-direction null-reason logging + flat-band — only proposal docs on main. Strategy-adjacent → Karri.
- `c387dcb` worker tests (decision-cycle/portfolio-brain/briefing) — test files absent from main. Could rescue (tests only) but may not apply cleanly after 65 commits of drift.
- `310831c` hard-loss-sweep (demo-mode empty-resultset crash guard, orb-manager degenerate-range riskPerUnit guard, fail-loud gates) — main's demo-mode.ts does NOT have the crash guard; orb-manager has no "degenerate range" guard. Mixed: the crash guard + riskPerUnit=0 guard are defensive bug-fixes worth a look, but bundled with strategy-adjacent gate changes. Triage before lifting.
- `9006592` derive-lessons recoverable exit-0 fix — main's derive-lessons.mjs lacks "no lessons to derive" / "Recoverable" handling. Small robustness fix, could rescue. (Note: PR #73 also touches derive-lessons.mjs — coordinate.)
- `1871260`, `ba855dd`, `1370ea2`, `6e0d103`, `66baa89`, `ec657b2` — security/docs/compose/sandbox sweeps; node-migration infra, mostly obsolete or doc-only.

**Recommendation:** node-migration-nexus is NOT fully superseded — Tier A holds 3 real fixes. Cherry-pick/re-implement Tier A onto fresh branches off main, then close PR #60 and archive the branch. Tier B: leave for explicit operator/Karri decision; do not bulk-rescue. Branch is too far behind (65 commits) to merge wholesale.

## 4. PR #73 status

- **OPEN**, base main, head `feat/lessons-auto-promote`, single commit `d991310`, **MERGEABLE** (clean).
- Title: feat(lessons): auto-promotion proposed→approved (default OFF, Karri 2026-06-05 spec).
- Adds `scripts/firehose/auto-promote-lessons.mjs` (+test, +14 tests), edits `derive-lessons.mjs`, docs `feature-flags.md`. +580/-1.
- What merging adds: gated auto-promotion of derived lessons proposed→approved, so `LESSON_INJECTION_ENABLED` stops being inert-without-a-human. Promotes only when sample_size ≥ 20 AND sign-consistency ≥ 0.8, capped 3/day, run after derive in the 04:00 UTC firehose flow. Default OFF → exactly today's behaviour, zero DB calls when off.
- **Gate:** money-near (auto-promoted lessons become injectable into agent prompts → trade-altering once activated). Per prinsipp 6 (post-rescind) the *code can land default-OFF freely*, but **activation = Karri + operator**. Merging the PR (default OFF) is safe; flipping `LESSON_AUTO_PROMOTE_ENABLED=true` is the gated step.
- Note: #73's `derive-lessons.mjs` edit overlaps the stranded `9006592` derive-lessons fix on node-branch — reconcile if rescuing 9006592.

---

## Answers to the 4 questions

1. Live `2b2d2ce` == origin/main HEAD: **YES** (deployed==current).
2. Stranded fixes (mine): **`2bf96ba`** (data-honesty observability — biggest), **`c6a6b03`** (runnable backtest + runbook), **`a9e54f3`** (N+1 perf). Older Tier-B node code (operator-control, session-breakout SL, regime null-reason, hard-loss-sweep guards, derive-lessons exit-0, worker tests) also never landed but is pre-session backlog — triage, mostly Karri-gated or obsolete.
3. node-migration-nexus: **still diverged (25 ahead / 65 behind, diverged 2026-05-23, = open PR #60).** NOT fully superseded — rescue Tier A (3 commits), then close #60 + archive. Do not merge wholesale.
4. PR #73: **OPEN, mergeable, default-OFF, safe to merge.** Adds gated lesson auto-promotion (closes the inject-without-human gap). Code-land is free; activation gates via Karri+operator.
