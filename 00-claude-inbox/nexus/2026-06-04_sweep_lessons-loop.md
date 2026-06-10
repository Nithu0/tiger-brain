# LANE 5 sweep — agent_lessons learning loop end-to-end (2026-06-04)

Read-only audit, harsh-skeptic mode. Question: with `AGENT_LESSONS_ENABLED` + `LESSON_DERIVATION_ENABLED` flipping on now (injection + auto-promotion pending Karri), will the loop produce → flow → inject, or silently die?

## VERDICT

**Producer: WILL WORK.** Deriver will write `proposed` lessons (no schema/grant crash expected on the live DB).
**Flow (proposed→approved): MANUAL-ONLY, NOT auto.** Still no auto-promotion — exactly as documented. Approved only via Discord `!lesson approve <id>`.
**Injection: WILL SILENTLY DIE even after Karri flips `LESSON_INJECTION_ENABLED` and lessons are approved.** New dead point: `agent_role` mismatch between producer and consumer. The injection join can never match a derived lesson.

Net: flipping the two derivation flags now is safe and will populate `proposed` rows. But the *full* loop does NOT close — it dies at injection on a key mismatch that is NOT one of the 3 historically-documented dead points.

---

## (a) Producer — will it write, or silent no-op?

`scripts/firehose/derive-lessons.mjs`, triggered by `apps/worker/src/index.ts:229` setInterval at 04:00 UTC, gated on both flags (L230-231), idempotent per UTC date via `firm_state` key (success-only marker, L263-271).

- Subprocess inherits worker env (`env: { ...process.env }`, index.ts L255) → runs as the worker's **master** `DATABASE_URL`, not `claude_readonly`. So the `42501 insufficient_privilege` RecoverableFetchError path is **not** a risk for the deriver (grants only matter if it ran as the read-only role; it doesn't). `grants.sql` is irrelevant to the producer.
- `simulated_orders` core columns (`status`, `closed_at`, `market`, `pnl`) all exist in base `CREATE TABLE` (schema.ts L68-83), applied at boot via `DB_MIGRATIONS` (index.ts L48). The 3 dimension columns (`portfolio_regime_at_entry`, `session_at_entry`, `close_reason`) are added by idempotent ALTERs (schema.ts L470/490/683) AND are COALESCE-guarded by the `presentColumns` probe (derive L91-123) — a missing dim col degrades to `'UNKNOWN'`, never crashes.
- So `RecoverableFetchError` (the documented #17 ~04:51Z exit-1 → exit-0 silent-no-op) should NOT fire on the current live schema. If it ever does, the honest caveat from phase-status holds: exit 0 writes a *success* marker, so a schema-drift day looks like a clean no-op unless someone greps `[derive-lessons] recoverable:`.
- Remaining benign no-op: if no (regime,session,close_reason) cluster reaches `MIN_SAMPLE=5` with WR ≤0.40 or ≥0.60, zero lessons are proposed. Correct behavior, not a bug — but operators should expect "0 new" until enough post-epoch closed trades accumulate (feature-flags.md L63 already warns: confirm ≥30d closed trades first).

**Producer conclusion: writes `proposed` rows as designed once trade volume + WR spread exist.**

## (b) proposed→approved gap

Still open, exactly as phase-status L25 documents. Only transition to `approved`:
- `AgentLessonsClient.approve()` (client.ts L110-124) — called by NOBODY in the worker.
- Discord `!lesson approve <id>` (discord-listener.mjs L157-179) — manual operator action, requires the listener process running + `DATABASE_URL`.

No auto-promotion anywhere (grep for `promote`/`autoPromot` → empty). `listApprovedFor` (client.ts L141) reads only `status='approved'`. So `proposed` rows are read by nobody until a human approves. This is by design (money-near gate) but means the loop does not self-close.

## (c) Injection — do approved lessons reach the prompts?

Call sites ARE wired (contrary to the stale phase-status L24 note, which talks about the *knowledge* module, not lessons):
- `risk-advisor.ts:113` → `buildLessonContext(ctx.db, NAME, "xauusd")`, `NAME = "risk-advisor"`
- `trade-critic.ts:68` → `buildLessonContext(ctx.db, NAME, "xauusd")`, `NAME = "trade-critic"`
- Both `.catch(() => "")` so a failure degrades silently to empty string (graceful, but also hides the bug).
- `isInjectionEnabled()` gate (injection.ts L33) correctly requires both `AGENT_LESSONS_ENABLED` + `LESSON_INJECTION_ENABLED`.

**NEW DEAD POINT — `agent_role` mismatch (silent dead flag, dual-gate pattern):**
- Producer hardcodes `agent_role = "lesson-deriver-stats"` (derive-lessons.mjs L211).
- `listApprovedFor(agentRole, domain, …)` filters `WHERE agent_role = $1` (client.ts L141-149).
- risk-advisor asks for `agent_role='risk-advisor'`; trade-critic for `'trade-critic'`.
- **No produced lesson will ever have `agent_role IN ('risk-advisor','trade-critic')`.** Even with injection ON and lessons approved, `listApprovedFor` returns `[]` → `buildLessonContext` returns `""` → nothing reaches the prompt. The loop dies at the SQL join, silently.
- Why tests don't catch it: `injection.test.ts:9` uses `agentRole: "risk-advisor"` fixtures, so the formatter/filter test passes — it never exercises the deriver's actual output role. Integration gap masked by a unit test.
- `domain` is fine: `xauusd` on both sides (derive L46, call sites pass `"xauusd"`).

## (d) Flag-name consistency

**Consistent. No mismatch.** `AGENT_LESSONS_ENABLED`, `LESSON_DERIVATION_ENABLED`, `LESSON_INJECTION_ENABLED` all agree across derive-lessons.mjs, injection.ts, client.ts, worker index.ts, and feature-flags.md (L62-64). The dual-gate that bites here is NOT a flag name — it is the `agent_role` data-key mismatch in (c).

---

## NEW TASKS

1. **[Karri/infra] Fix the `agent_role` injection mismatch — the loop's true dead end.** Decide the contract: either (i) deriver writes per-consumer roles (loop over `['risk-advisor','trade-critic']`, or a shared sentinel like `'firm-shared'` that both consumers query), or (ii) `listApprovedFor` / `buildLessonContext` query a fixed producer role (`'lesson-deriver-stats'`) regardless of caller. Option (ii) is the smaller diff and keeps one global lesson pool. This is a wiring fix (no threshold/decision-logic change) BUT it directly controls whether money-near injection works → loop in Karri since it gates what risk-advisor/trade-critic are told. Add an integration test that runs deriver output through `listApprovedFor` (not a hand-built fixture) so the role contract can't silently drift again.

2. **[Karri/operator] Build the auto-promotion path (proposed→approved).** Still entirely manual (Discord-only). If continuous learning is the goal (prinsipp 6 rescinded), proposed lessons need a promotion rule (e.g. sample_size ≥ N + confidence ≥ X + age). This IS trade-altering (it decides which lessons reach prompts) → Karri-gated per the learning-infra/strategy boundary. Until built, every derived lesson sits inert unless a human runs `!lesson approve`.

3. **[infra] Stop the silent-degrade from hiding the join bug.** The `.catch(() => "")` at both call sites + the deriver's `recoverable → exit 0 → success marker` mean a fully-broken injection looks healthy. Add a one-line observability counter (e.g. log/`firm_state` "lessons injected: N for role R" when `LESSON_INJECTION_ENABLED` and approved>0 but filtered=0) so a zero-match join is visible, not silent. No behavior change → not Karri-gated.

4. **[infra] Correct stale phase-status note.** `docs/ops/phase-status.md` L24 describes injection-off via the *knowledge* module (`KNOWLEDGE_INJECTION_ENABLED`); the lessons path uses `LESSON_INJECTION_ENABLED` and the call sites ARE wired. Update so the documented "3 dead points" reflect: (1) producer-crash GUARDED, (2) no auto-promotion STILL OPEN, (3) injection wired BUT dead on agent_role mismatch (new).

5. **[operator] Safe to flip derivation now.** Flipping `AGENT_LESSONS_ENABLED` + `LESSON_DERIVATION_ENABLED` is low-risk: only writes `proposed` rows, changes no trade decisions. Expect "0 new" until post-epoch closed-trade volume builds. Do NOT expect any prompt effect until tasks #1 + #2 land + Karri flips `LESSON_INJECTION_ENABLED`.
