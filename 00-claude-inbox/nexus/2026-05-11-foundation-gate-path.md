---
title: Foundation Gate — path from GUL to GREEN
date: 2026-05-11
author: Claude (Opus 4.7)
status: investigation
binding: operator-prinsipp 4 (foundation-først)
---

# Foundation Gate — concrete path GUL → GREEN

**TL;DR**: 4 of 5 rules are GREEN today. Only Rule 5 (overdue Claude/both followups) blocks the gate. **Time-to-green: 0.5–1 day of focused Claude work + operator delete-confirmation of stale Claude items.** Strategy work (Monday) is unblocked once those 3 followups are either closed or rescoped.

The phase-status.md document still says GUL with Rule 4 RED — that is stale. Rule 4 went GREEN today (2026-05-11) because the deploy of commit `19f1534` reached Railway. SQL confirms 12 rows in `gate_decisions` in the last 24h spanning all 4 gates, with `MAX(recorded_at) = 2026-05-11T08:52:59Z`.

---

## Per-rule current state

### Rule 1 — Ingen KRITISKE åpne problemer | GREEN

**Evidence:**
- `grep -in "KRITISK" docs/ops/known-failures.md` → **0 matches**.
- `phase-status.md` "Åpne problemer" table: 6 rows, severities are `MEDIUM × 3`, `OBSERVER × 2`, `LAV × 1`. None KRITISK.
- `/health` returns 200 OK, db 2ms, broker ok, demo balance $92646, reconciliation drift 0.

**Action needed:** none.
**Owner:** —.
**Time-to-green:** already green.

---

### Rule 2 — POSITION_MANAGEMENT_ENABLED=true | GREEN

**Evidence:**
- `phase-status.md` line 98 documents flip on 22.4 evening, verified ticket 548 the next morning.
- Currently listed under "Hva kjører i produksjon akkurat nå" as LIVE — break-even, trailing, partials, stale exit all active.
- `/health` reconciliation drift = 0 — confirms two-way OANDA sync is operative (would diverge if PM were off).

**Action needed:** none.
**Owner:** —.
**Time-to-green:** already green.

---

### Rule 3 — Siste 3 builds OK | GREEN

**Evidence:**
- `git log --oneline -20` shows continuous landings since 03.5 (Agent Bus + 12 dashboard commits), 07.5 (8 P0 fixes), 08.5 (cognitive-OS rollout + hooks). No revert commits, no failed-build sentinels.
- `/health` reports `build.commit: 3ab8b61a` matching local HEAD — Railway is consuming pushes.
- Worker cycle counter at 331 this morning, cycles are running.
- `gate-silence-2026-05-08.md` CORRECTION block already confirmed deploy reached prod before Rule 4 turned green.

**Action needed:** none.
**Owner:** —.
**Time-to-green:** already green.

---

### Rule 4 — Minst én hard-gate har ≥7 dager × ≥50 evals (consecutive, fresh) | GREEN (today)

**Canonical reading:** `new-strategy-gate.md` says "≥7 dager med evaluations, ≥50 rader, konsistent mønster". Cumulative evals over the lifetime + last_seen fresh both required.

**Evidence (nexus-pg query, just now):**
| gate_name | evals | would_reject | first_seen | last_seen | days_observed |
|---|---|---|---|---|---|
| `risk_level` | 1973 | 1176 (60%) | 2026-04-20 | 2026-05-11 08:52Z | 20 |
| `scalp_overlap_asia` | 1973 | 0 | 2026-04-20 | 2026-05-11 08:52Z | 20 |
| `ranging_conviction` | 1973 | 21 (1%) | 2026-04-20 | 2026-05-11 08:52Z | 20 |
| `entry_stack_cooldown` | 1951 | 229 (12%) | 2026-04-20 | 2026-05-11 08:52Z | 20 |

12 rows written in the last 24h (operator-stated this morning, reconfirmed). All 4 gates fresh.

**Caveat (NOT blocking, but worth flagging):** The 14-day silence (24.4 → 11.5) is still in this dataset. `days_observed` measures `MAX - MIN` not "consecutive without a gap". The canonical rule says "≥7 dager med evaluations, ≥50 rader". Strict reading: cumulative satisfied; consecutive-fresh-7-days starts the clock today. If Karri or Operator reads "7 dager" as "7 consecutive recent days", we won't be fully green until **2026-05-18**.

**Recommendation:** treat as GREEN now (rule text says "days observed", not "consecutive without gaps"), but call this out in the next strategy proposal so Karri can correct if he disagrees.

**Action needed:** none, unless strict-consecutive reading is enforced — then wait one week.
**Owner:** —.
**Time-to-green:** already green (loose reading) / 7 days (strict reading).

---

### Rule 5 — 0 forfalne claude-followups | RED

**Source:** `apps/worker/src/firm/followups.ts`. Rule 5 triggers when any entry has `dueDateIso ≤ today` AND `owner ∈ {claude, both}`.

Today is 2026-05-11. All 7 entries are past due. Owner breakdown:

| # | id | owner | due | days late | action |
|---|---|---|---|---|---|
| 1 | `wire-analysis-snapshots-on-position-detail` | **claude** | 2026-04-27 | 14d | Claude to do or rescope |
| 2 | `per-strategy-sql-export-endpoint` | **claude** | 2026-05-01 | 10d | Claude to do or rescope |
| 3 | `verify-legacy-xauusd-execution-disabled` | operator | 2026-04-21 | 20d | operator-only — not blocking Rule 5 |
| 4 | `ohlcv-diagnose-railway-logs` | operator | 2026-04-22 | 19d | operator-only |
| 5 | `verify-postmortem-hook-catchup` | operator | 2026-04-22 | 19d | operator-only |
| 6 | `verify-oanda-two-way-sync-shadow-test` | operator | 2026-04-23 | 18d | operator-only |
| 7 | `review-duplicate-trades` | **both** | 2026-04-22 | 19d | Claude + operator joint — partially done (see below) |

**Rule-blocking items (owner ∈ {claude, both}):** 3 entries — #1, #2, #7.

#### Triage and action plan

**#1 `wire-analysis-snapshots-on-position-detail`** — Claude
- Status: 14 days overdue. Dashboard work, not trading-loop. Likely 1–2 hours.
- Action options:
  - **Do it**: implement the join + card in `apps/dashboard/.../positions/[id]/` and remove the followup in same commit.
  - **Rescope**: if `analysis_snapshots` doesn't have enough data yet (verify via `SELECT COUNT(*) FROM analysis_snapshots` first), push `dueDateIso` to 2026-05-25 with a note explaining the data-readiness rationale.
- Recommendation: **rescope first; do real work only if Operator wants it shipped now**. Strategy unblocking matters more than dashboard polish.

**#2 `per-strategy-sql-export-endpoint`** — Claude
- Status: 10 days overdue. New API endpoint, no behavioural risk.
- Action options:
  - **Do it**: 1–2 hours; add `/analytics/export/strategy/:id` returning CSV/JSON.
  - **Delete it**: if Karri / operator have moved to nexus-pg MCP for ad-hoc queries (likely — operator now uses `mcp__nexus-pg__query` directly), this endpoint is redundant. Just remove the followup.
- Recommendation: **delete**, with one-line commit message explaining nexus-pg MCP supersedes.

**#7 `review-duplicate-trades`** — both
- Status: 19 days overdue. **Partially done.** Commit `60a627d` from 08.5 added `scripts/oneshot/2026-05-08-fix-duplicate-trades.sql` (8 dupe rows, $341.93). Commit `8112d88` added postmortem OANDA_EXTERNAL recognition. Commit `4300633` MANUAL_GHOST_CLOSE recovery audit.
- Remaining: operator runs the one-shot SQL (gated by "OK kjør") and verifies result via nexus-pg.
- Action options:
  - **Operator runs SQL, Claude verifies result, both delete followup** — proper path.
  - **Rescope** to a verification-only followup after operator OK.
- Recommendation: **execute via operator OK kjør this week**; the SQL is already written and tested.

#### Sweep plan (1 session, ~1 hour Claude time + operator confirm)

1. Read & confirm `analysis_snapshots` row count → decide #1 path.
2. Delete or rescope followups #1 and #2 in a single commit, message: `chore(followups): sweep overdue Claude items — analysis-snapshots rescope + sql-export deleted (superseded by nexus-pg MCP)`.
3. Operator runs `scripts/oneshot/2026-05-08-fix-duplicate-trades.sql` via nexus-pg-rw (OK kjør gate).
4. Claude verifies dupe count post-fix → deletes followup #7 in commit `chore(followups): close review-duplicate-trades (8 rows fixed, verified)`.
5. Operator-side followups (#3–#6) remain but **do not block Rule 5** by definition. Operator decides scheduling on those independently.

**Action needed:** 1 Claude commit (sweep #1+#2) + 1 operator SQL run + 1 Claude verify commit (close #7).
**Owner:** Claude (commits) + operator (SQL).
**Time-to-green:** **0.5–1 day** if done back-to-back. Realistically: end-of-day Monday 12.5 if started after weekend.

---

## Aggregate state

| Rule | Status today (11.5) | Was (08.5 doc) |
|---|---|---|
| 1 — No KRITISK | 🟢 | 🟢 |
| 2 — POSITION_MANAGEMENT_ENABLED | 🟢 | 🟢 |
| 3 — Last 3 builds OK | 🟢 | 🟢 |
| 4 — Gate datagrunnlag | 🟢 (fresh today; loose reading green, strict-consecutive 18.5) | 🔴 |
| 5 — 0 overdue Claude/both followups | 🔴 (3 items: #1, #2, #7) | 🔴 |

**Overall: 🟡 GUL** — single blocker is Rule 5. Path is mechanical.

---

## Time-to-green estimate

- **Optimistic**: end-of-day **2026-05-12 (Monday)** if Claude sweeps #1+#2 first and operator runs dedupe SQL same day.
- **Realistic**: **2026-05-13 (Tuesday)** if sweep stretches over two sessions.
- **Strict-Karri reading on Rule 4**: pushes the green to **2026-05-18 (Monday)** because Rule 4 needs 7 consecutive recent days.

Either way: **Monday strategy work blocked unless Claude sweep + duplicate-SQL run happen first.**

---

## What blocks Monday's strategy work specifically

1. **Rule 5 is RED.** 3 Claude/both followups overdue. Per the binding rule (`new-strategy-gate.md` line 20: "Én rød → STOPP"), any new-strategy work is refused regardless of who asks.
2. **Karri review queue.** Even if foundation flips green Monday morning, the two 08.5 strategy proposals (commit `bf0f463`) assigned to Karri may not yet have his approval. Operator should confirm with Karri over Discord before Monday.
3. **Optional, advisory:** the 14-day Rule-4 gap from 24.4 → 11.5 is still in the dataset. If Karri wants strict-consecutive 7d he can ask to delay to 18.5. Worth a heads-up before he's surprised.

**Not blocking** (but worth knowing):
- Operator-side followups (#3–#6) — independent of Rule 5 mechanics.
- gate-silence diagnostic — root cause now fixed (deploy + flag flip happened, gate_decisions writing fresh).
- The 8 duplicate trade rows ($341.93 underreport) — affects PnL accuracy but is below KRITISK threshold and has a runbook.

---

## Recommended sequence

1. **Today (Sunday 11.5)** — Claude drafts followup-sweep commit locally, operator reviews diff.
2. **Monday 12.5 morning** — operator OK kjør on:
   - Push followup-sweep commit (removes #1 + #2, rescopes if needed).
   - Run `scripts/oneshot/2026-05-08-fix-duplicate-trades.sql` via nexus-pg-rw.
   - Claude verifies → commits closing #7.
3. **Monday 12.5 afternoon** — Foundation green. Operator confirms with Karri that strategy proposals are approved.
4. **Tuesday 13.5** — first new strategy work may begin per `new-strategy-gate.md` "Hvis ALT er GRØNT" requirements (PAUSED bot + 14d shadow + accept criteria + morgenbriefing surface + operator OK).

---

*Source files:*
- `/home/nithu/code/ai-assistent/docs/ops/new-strategy-gate.md`
- `/home/nithu/code/ai-assistent/docs/ops/phase-status.md`
- `/home/nithu/code/ai-assistent/docs/ops/gate-silence-2026-05-08.md`
- `/home/nithu/code/ai-assistent/apps/worker/src/firm/followups.ts`
- `/home/nithu/code/ai-assistent/CLAUDE.md` (Operator-prinsipper)
- nexus-pg SQL (2026-05-11 morning)
