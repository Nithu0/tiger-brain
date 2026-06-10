# Lesson-quality path — closing the learning loop (2026-06-08)

Read/analysis only. No DB mutated. Source: `data/pull/firehose_overview.json` + code on `main`.

## TL;DR

- **Do the 3 stale lessons inject?** No. They fail on BOTH role-tag and confidence (and status — they're `proposed`, never `approved`). Triple-blocked.
- **Will future ones inject?** Depends. The role-tag fix (`3a37500`) is on `main`, so fresh lessons get tagged `risk-advisor` / `trade-critic` and the status path is now automatable via auto-promote. BUT there is a **second silent block**: the 0.5 confidence floor vs the `min(0.95, n/50)` confidence formula means a cluster needs **n ≥ 25 trades** before any lesson clears injection — and auto-promote (consistency ≥ 0.8) can approve lessons that still sit *below* the floor, so they'd be approved-but-never-injected.
- **Cleanup:** archive the 3 stale lessons (gated SQL below).

---

## 1. Injection filters — verified

Two independent filters, all must pass for a lesson to reach an agent prompt.

**`AgentLessonsClient.listApprovedFor()`** (`apps/worker/src/firm/agent-lessons/client.ts:142`):
```sql
WHERE status='approved'
  AND agent_role = $1            -- $1 = consuming agent's own NAME
  AND domain = $2
  AND last_validated_at > NOW() - INTERVAL '<validityDays> days'
```

**`buildLessonContext()`** (`apps/worker/src/firm/agent-lessons/injection.ts:45`):
- `minConfidence = opts.minConfidence ?? 0.5` → `.filter(l => (l.confidence ?? 0) >= minConfidence)`
- Gated by `AGENT_LESSONS_ENABLED && LESSON_INJECTION_ENABLED` (both default OFF).

**Call sites** pass NO `opts`, so the **0.5 default applies**:
- `risk-advisor.ts:114` → `buildLessonContext(ctx.db, NAME, "xauusd")`, `NAME = "risk-advisor"`
- `trade-critic.ts:69`  → `buildLessonContext(ctx.db, NAME, "xauusd")`, `NAME = "trade-critic"`

**The 3 stale lessons fail on every axis:**

| id | agent_role | status | confidence | injects? |
|----|-----------|--------|-----------|----------|
| 1 | `lesson-deriver-stats` | proposed | 0.360 | NO — role≠consumer, status≠approved, conf<0.5 |
| 2 | `lesson-deriver-stats` | proposed | 0.360 | NO — same |
| 3 | `lesson-deriver-stats` | proposed | 0.220 | NO — same |

`listApprovedFor("risk-advisor", …)` / `("trade-critic", …)` returns **zero rows** because `agent_role='lesson-deriver-stats'` matches neither. Even if their status were flipped to `approved`, the role mismatch alone kills them; even past that, conf 0.36/0.22 < 0.5. Dead three ways.

## 2. The TARGET-role fix (`3a37500`) — confirmed, future-only

Commit `3a37500` (Sat Jun 6, on `main`) changed `derive-lessons.mjs`:
- `agent_role` is now the **consuming/target** role, fanned out one row per role.
- `DEFAULT_TARGET_ROLES = ["risk-advisor", "trade-critic"]` (`derive-lessons.mjs:45`), override via `LESSON_TARGET_ROLES`.
- Deriver identity moved to `proposer_id` (`derive-lessons-stats-<host>`).
- `fingerprint` now includes the role, so per-role rows dedupe/vote independently.

So **new** derived lessons WILL carry `agent_role ∈ {risk-advisor, trade-critic}` and thus pass the role filter. The fix does nothing for the 3 stale rows (they were written 2026-05-21 with the old hardcoded tag) — they are dead and must be cleaned out, not relied on.

## 3. Cleanup recommendation — archive the 3 stale lessons (GATED)

They can never inject and they pollute the proposed-queue / dashboards / digest counts. Recommend archiving. **Operator/Karri-gated** (it's a DB write; trade-influencing table). Propose, do not run:

```sql
-- Archive the 3 stale 2026-05-21 deriver-stats lessons (wrong role tag,
-- sub-floor confidence). Tightly scoped by the legacy role tag + proposer.
UPDATE agent_lessons
   SET status = 'archived'
 WHERE id IN (1, 2, 3)
   AND status = 'proposed'
   AND agent_role = 'lesson-deriver-stats'
   AND proposer_id = 'derive-lessons-stats-unknown';
-- Expect: UPDATE 3
```

Run via `mcp__nexus-pg-rw__query` once operator approves (matches operator-prinsipp 3 small-curation, but it touches the lessons table so still gate it). Reversible: `SET status='proposed'` on the same ids.

After fix + activation, fresh lessons replace these with correct tags. For strong, lopsided patterns the auto-promote path (consistency ≥ 0.8, sample_size ≥ 20) can move `proposed → approved` automatically — so the status axis is no longer a permanent manual block.

## 4. Confidence floor 0.5 vs derived confidence — SECOND SILENT BLOCK (flag to Karri)

This is the real finding. There are **two different "how good is this lesson" scores**, computed differently, gating at different stages:

- **Injection** filters on `confidence` ≥ **0.5** (`injection.ts:53`).
- **Auto-promote** filters on `consistency` ≥ **0.8** (`auto-promote-lessons.mjs`), where consistency is derived from `outcome_score` (= win-rate lopsidedness), **NOT** from `confidence`.

`derive-lessons.mjs:122,140` computes:
```js
confidence: Math.min(0.95, cluster.n / 50)
```
So confidence is purely a **sample-size proxy** (cluster trade count / 50), unrelated to how strong the WR signal is. To clear the 0.5 injection floor a single cluster needs **n ≥ 25 trades**.

The two gates can disagree:
- A clean anti-pattern with WR=15% over n=20 → consistency=0.85 (≥0.8, **auto-promote approves it**) but confidence=0.40 (**< 0.5, injection drops it**). Result: an approved lesson that never injects — a *silent* second block, exactly the shape of the role-tag bug, just one stage later.
- Conversely a weak-signal cluster with WR=45% over n=30 → confidence=0.60 (clears floor) but consistency=0.55 (auto-promote correctly rejects) — fine, the floor isn't the bottleneck there.

**Will real derived lessons clear 0.5?** Only those built from clusters of ≥25 trades in a single (regime, session, close_reason) bucket. Given XAUUSD demo volume and 3-way bucketing, many genuinely strong patterns will sit at n=10–24 → confidence 0.20–0.48 → **approved by auto-promote but blocked at injection.** So yes: with derivation fixed, the floor is plausibly the next thing that makes "nothing injects" even though the loop looks wired.

**Recommended fix (Karri-gated — it changes what reaches trade-decision prompts):** make the injection floor consistent with the promotion logic. Options, in order of preference:
1. Lower `minConfidence` default to ~0.3 AND/OR pass an explicit `{ minConfidence }` at the two call sites behind an env (e.g. `LESSON_INJECTION_MIN_CONFIDENCE`, default lower) — keeps it rollback-safe per operator-prinsipp.
2. Better: gate injection on the **same consistency notion** auto-promote already uses (lopsided WR), so "approved ⇒ injectable" holds by construction and the two stages can't silently disagree.
3. At minimum: change `confidence` in `derive-lessons.mjs` to fold in signal strength, not just `n/50`, so it stops being a pure sample-size proxy that fights the floor.

This is a strategy/learning-switch-adjacent change (it alters what enters risk-advisor/trade-critic prompts → trade decisions), so per CLAUDE.md it goes through a `docs/strategy/proposals/` doc to Karri before activation. I did not implement.

---

## Answers to the three asks

1. **Do the 3 stale lessons inject?** No — blocked on role-tag, confidence, AND status (proposed). Triple-dead. Archive them.
2. **Will future ones inject?** Depends. Role-tag fixed (`3a37500`, on main) and status automatable via auto-promote — but the **0.5 confidence floor vs `n/50` confidence formula** is a second silent block: needs n≥25-trade clusters, and auto-promote can approve sub-floor lessons that then never inject. Flag to Karri.
3. **Cleanup SQL:** the gated `UPDATE … SET status='archived' WHERE id IN (1,2,3) …` above (run via nexus-pg-rw after operator OK).
