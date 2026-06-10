# Lessons pipeline — end-to-end trace (READ/VERIFY ONLY)

Date: 2026-06-07
Live HEAD: `2b2d2ce` (Merge PR #72, 2026-06-07 11:00)
Channel: nexus-pg MCP (read-only Postgres) + live API over 443 + repo code.

## TL;DR

The learning loop is flipped ON (worker has `AGENT_LESSONS_ENABLED`, `LESSON_DERIVATION_ENABLED`, `LESSON_INJECTION_ENABLED` all `=true`), but it is **not flowing to any live decision**. It is broken at **three** independent welds, only one of which you flagged:

1. **DERIVATION IS DEAD (new).** The daily 04:00 UTC deriver subprocess has exited code=1 **17 days in a row (2026-05-22 → 2026-06-07)**. No new lessons have been derived since. The last *successful* run marker is 2026-05-13.
2. **APPROVAL WELD (the one you flagged).** 0 lessons are approved. Auto-promotion (PR #73) is OPEN/unmerged and the code doesn't exist on main; `LESSON_AUTO_PROMOTE_ENABLED` is not even set on the worker. Only path live is manual `!lesson approve` — never used.
3. **STALE ROWS CAN'T INJECT EVEN IF APPROVED.** The 3 existing proposed rows are pre-fix: tagged `agent_role="lesson-deriver-stats"` (won't match consumers) AND all below the 0.5 min-confidence injection floor (0.36/0.36/0.22).

So: even if you manually approved all 3 today, injection would still emit nothing.

## 1. agent_lessons counts by status (live DB)

```
proposed : 3
approved : 0
archived : 0
drifted  : 0
```

All 3 proposed rows created **2026-05-21** (one batch); nothing since.

| id | agent_role | type | conf | WR cluster | status |
|----|------------|------|------|------------|--------|
| 1 | lesson-deriver-stats | anti_pattern | 0.36 | TRENDING/unknown/OANDA_SL_TP 33% | proposed |
| 2 | lesson-deriver-stats | anti_pattern | 0.36 | UNKNOWN/UNKNOWN/OANDA_BACKFILL 22% | proposed |
| 3 | lesson-deriver-stats | anti_pattern | 0.22 | UNKNOWN/unknown/OANDA_SL_TP 36% | proposed |

DERIVED: yes, but only the May-21 batch — proposed rows are **NOT growing** (deriver broken since, see §4).
APPROVED: **zero**.

API surface note: `/learning` and `/firehose` return **404 on the live API** (not deployed). `/calibration/status` works (200) and reports `proposed:3, approved:0` — but its `*FlagEnabled` fields read the **API** process env (all `false`), NOT the worker. The worker is where the flags are actually `true`. Don't read calibration flag fields as loop state.

## 2. The approval weld (confirmed)

- approved count = **0**. Confirmed against DB, not just the endpoint.
- Auto-promotion: PR **#73 `feat/lessons-auto-promote`** is **OPEN, mergedAt=null**. Code lives only on that branch; `grep` for `LESSON_AUTO_PROMOTE`/`autoPromote` on main = nothing.
- Worker env has `AGENT_LESSONS_ENABLED`, `LESSON_DERIVATION_ENABLED`, `LESSON_INJECTION_ENABLED` = true; **no `LESSON_AUTO_PROMOTE_ENABLED` set at all**.
- Only live proposed→approved path is manual `!lesson approve` (Discord → `AgentLessonsClient.approve()`, client.ts:111). Never invoked → 0 approved.

Your statement holds: injection is on but **starved at the approval weld**. With 0 approved, `buildLessonContext()` returns `""` and injects nothing.

## 3. Is injection actually wired? (yes — and the TARGET fix IS live)

- `risk-advisor.ts:~112` and `trade-critic.ts:~67` both call `buildLessonContext(ctx.db, NAME, "xauusd")` in a `Promise.all`, drop result into `buildPrompt(...)`. Wiring is real.
- `buildLessonContext` (injection.ts) gates on `isInjectionEnabled()` = `AGENT_LESSONS_ENABLED && LESSON_INJECTION_ENABLED` (both true on worker → passes), then `listApprovedFor(agentRole, domain, validityDays)`.
- `listApprovedFor` (client.ts:142) filters: `status='approved' AND agent_role=$1 AND domain=$2 AND last_validated_at > NOW() - INTERVAL '<validityDays> days'`. Then injection.ts applies `confidence >= 0.5` (default) and `slice(0,8)`.
- **TARGET-role fix `3a37500` (Jun 6) IS an ancestor of live HEAD `2b2d2ce`** and is in `origin/main`. New derived rows would be tagged `risk-advisor` / `trade-critic` (fan-out, default `LESSON_TARGET_ROLES`), so they WOULD match consumers.

Would an approved lesson reach the prompt now? Conditionally yes — **only for NEW lessons** derived post-fix. The 3 stale rows would NOT, because: (a) old `lesson-deriver-stats` tag ≠ consumer name, and (b) confidence 0.22–0.36 < 0.5 floor. The `approve()` mutation does refresh `last_validated_at=NOW()`, so the 30-day validity window is not the blocker — the tag + confidence are.

## 4. NEW BREAK: derivation subprocess failing 17 days straight

Worker spawns `node scripts/firehose/derive-lessons.mjs` once/day at 04:00 UTC (index.ts:~231), gated on both flags (pass). It records a `firm_state` marker:

- Success markers exist **through 2026-05-13** (`firehose:derive_lessons:<date>`).
- **`:failed` markers with `exitCode:1` every day 2026-05-22 → 2026-06-07 (17 days).**
- exit=1 comes from the script's own `main().catch(...)` fatal handler — so the subprocess DID spawn and run (not a spawn/ENOENT error; those would write `spawnError`/`childError`, which are absent).

What I ruled out as the cause:
- Script + `lib/fingerprint.mjs` present in repo; `COPY scripts/firehose` is in the worker Dockerfile (line 31, added `61afd28` 2026-05-13) → ships in image.
- Schema OK: `simulated_orders` exists with all columns the query needs (`portfolio_regime_at_entry`, `session_at_entry`, `close_reason`, `market`, `pnl`, `closed_at`, `status`).
- The `fetchClusters` query runs clean against live DB via MCP and TODAY returns 2 qualifying clusters (≥5 samples), incl. an anti-pattern (TRENDING/unknown/OANDA_SL_TP, 7 trades, 14% WR, -2108 PnL). So if it ran, it WOULD propose.
- Per-row `proposeLesson` errors are caught individually → can't cause exit=1.

Remaining uncaught-throw candidates inside `main()`: `client.connect()` or `client.end()` (the SELECT is verified-good). The actual error text is only in **Railway Worker stderr** (`[derive-lessons] fatal: ...`), which I cannot pull over 443 — the failure marker stores only `exitCode`, not stderr. **Operator action needed:** check Railway Worker logs around any 04:0x UTC for the `[derive-lessons] fatal:` line to get the exact error. Most probable: a DB connect/TLS/`DATABASE_URL` issue in the subprocess env, or a pg driver issue — NOT a query/schema/COPY problem.

## Verdict

Loop is ON but **stalled, and worse than "stalled at approval"** — it's broken at the *upstream* derivation step too:

```
[trades] -> DERIVE (BROKEN 17d, exit 1) -> [3 stale proposed, pre-fix] -> APPROVE (0, no auto-promote) -> INJECT (wired+live, but nothing approved) -> prompt
              ^^^ break #1 (new)             ^^^ break #3 (stale rows)      ^^^ break #2 (you flagged)
```

Nothing is reaching a live trade decision.

## Exactly what unblocks it (in order)

1. **Fix derivation first (highest leverage, infra — Claude-ownable).** Get the `[derive-lessons] fatal:` stderr from Railway Worker logs, fix the subprocess error, confirm a green `firehose:derive_lessons:<date>` success marker + new `risk-advisor`/`trade-critic`-tagged proposed rows appear. Without this, there are no fresh, correctly-tagged, inject-eligible lessons to approve — approving the 3 stale ones is a dead end (wrong tag + sub-0.5 confidence).
2. **Then open the approval weld.** Two options:
   - **Manual:** `!lesson approve <id>` per lesson via Discord. Zero deploy. But operator-in-the-loop forever. Note: this is a trade-altering switch (lesson-injection into agent prompts) → per prinsipp 6 it gates through **Karri** before activation.
   - **Auto:** merge **PR #73** + set `LESSON_AUTO_PROMOTE_ENABLED=true` on the worker. Also a trade-altering activation → **Karri-gated**. #73 is the Karri-spec auto-promotion, default OFF.
3. Injection itself needs **no further work** — it's wired (risk-advisor + trade-critic), live (3a37500 in HEAD), and flagged on. It will fire the moment an approved, correctly-tagged, ≥0.5-confidence, ≤30-day-old lesson exists.

## Boundary note (prinsipp 6 / learning-infra vs strategy)

- Break #1 (derivation subprocess) = pure infra/observability, does NOT alter trade decisions → Claude-ownable fix, run freely.
- Breaks #2/#3 = approving lessons / merging #73 / `LESSON_AUTO_PROMOTE_ENABLED` = trade-altering (lesson injection into agent prompts) → **Karri-gated** before activation, per the surviving half of prinsipp 6.
