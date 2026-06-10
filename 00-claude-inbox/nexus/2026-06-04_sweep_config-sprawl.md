# LANE 6 — Config/flag sprawl + danger audit (2026-06-04)

Read-only audit. Repo `/home/nithu/code/ai-assistent`, branch `node-migration-nexus`.
Source-of-truth docs: `docs/ops/railway-worker-var-inventory.md` (230 Railway Worker vars,
commit `3f35f2a`) + `docs/ref/feature-flags.md`. Code: `apps/worker/src/`.

Operator frustration framing: too many kill-switches that hard-fail. This sweep
maps the silent-inert traps, the default-bites, the dead weight, the parse
inconsistency, and the 2026-06-03 learning-intent contradictions.

---

## (d) FIRST — the boolean-parse conventions (root cause of most silent traps)

There are **THREE** conventions in worker code, plus a 4th near-miss helper-name:

### Convention 1 — strict helper (`envBool` / `boolEnv`), SAFE
```ts
const raw = (process.env[name] ?? "").trim().toLowerCase();
if (raw === "") return fallback;
return raw === "true" || raw === "1" || raw === "yes";
```
- Defined **~13 times, copy-pasted** under two names: `envBool` (strategy-blade, news-router,
  spread-gate, vol-expansion/config, daily-loss-cap, reverse-at-sl, gates/{daily-trade-cap,
  sl-cooldown,mean-revert}, strategy-execution, …) and `boolEnv` (gates/new-gates,
  gates/daily-trade-cap-gate:65, +1). **Bodies are byte-identical** → no correctness divergence,
  but 13 copies of the same fn is maintainability debt. Trims + lowercases + accepts true/1/yes.
  This is the one to standardize on.

### Convention 2 — `!== "false"` (default-ON, lenient)
Used for things that should default on. Two sub-variants:
- **Normalized** (good): `(process.env.X ?? "true").trim().toLowerCase() !== "false"`
  — shadow-log.ts:54, position-management/rules.ts:94 (LET_RUN), bot-manager.agent.ts:112-113.
- **Raw, NOT normalized** (fragile): `raw !== "false" && raw !== "0" && raw !== "no"`
  — postmortem-hook:46, drift-monitor:76, raw-data-persistence:78, discord.service:21,
  position-management/manager:398, trading-manager.agent:51. These default ON and only
  the literal lowercase `false/0/no` turns them off → `FALSE`, ` false` (trailing space),
  `False` all leave the feature **ON**. For default-on report/persist switches that's a
  fail-safe direction (you keep collecting data), so low risk — but it's inconsistent.
- **Bare, no default, no normalize**: `process.env.ORB_REQUIRE_RETEST !== "false"`,
  `SESSION_BREAKOUT_ONE_TRADE !== "false"`, `BC_REQUIRE_CONFIRMATION_CANDLE !== "false"`,
  `FIRM_AGENTS_FALLBACK_ENABLED !== "false"`. Same fail-on-typo-stays-ON behaviour.

### Convention 3 — bare inline `=== "true"` (default-OFF, FRAGILE) ← **the dangerous one**
`process.env.X === "true"` with **no `.trim()`, no `.toLowerCase()`**. ~45 call sites.
**Every strategy master-switch and every learning/agent master-switch uses this form:**
`ORB_ENABLED`, `ORB_ONLY_MODE`, `SESSION_BREAKOUT_ENABLED`, `SCALP_OVERLAP_ENABLED`,
`VOL_EXPANSION_ENABLED`, `MEAN_REVERSION_ENABLED`, `TREND_FOLLOWING_ENABLED`,
`BREAKOUT_CONTINUATION_ENABLED`, `PULLBACK_CONTINUATION_ENABLED`, `FVG_FILTER_ENABLED`,
`AGENT_BUS_ENABLED`, `FIRM_AGENTS_ENABLED`, all 10 `FIRM_AGENT_*_ENABLED`,
`AGENT_DISCORD_DELIVERY_ENABLED`, `AGENT_LESSONS_ENABLED`, `LESSON_INJECTION_ENABLED`,
`AGENT_KNOWLEDGE_ENABLED`, `KNOWLEDGE_INJECTION_ENABLED`, `FIRM_RESEARCH_DRAINER_ENABLED`,
`AGENT_TRIGGER_PUBLISH_ENABLED`, `OANDA_SYNC_ENABLED`, `USE_OANDA_BALANCE`,
`SPLIT_TECHNICAL_SIGNALS`, `REGIME_SLTP_ENABLED`, `FIRM_BLADE_PAUSED`, `STRUCTURE_INCLUDE_TECH_DIR`.

**Bite:** when operator types `TRUE`, `True`, `1`, `yes`, or accidentally adds a trailing
space in the Railway UI, the flag reads **false → feature stays OFF, silently**. There is
NO warning. This is precisely the "I flipped it and nothing happened" failure mode. The
strict helper (Conv 1) would have caught all of these — but the master switches don't use it.

### Convention 3b — `CALIBRATION_MODE` exact-match (FRAGILE, learning-critical)
`firm/calibration.ts:44` — `VALID_CALIBRATION_MODES.includes(raw)` with **no trim/upper**.
Valid values are UPPERCASE (`RECOMMEND_ONLY`, `SAFE_AUTO_APPLY`, `OFF`, `SHADOW_COMPARE`).
`recommend_only`, ` SAFE_AUTO_APPLY`, `safe_auto_apply` all fail the match and **fall back to
`RECOMMEND_ONLY`**. Fail-safe direction (never silently auto-applies), but if operator/Karri
later types `safe_auto_apply` expecting autotune, it silently won't apply — a learning trap.

---

## (a) Contradictory / double-gate flags (two flags must BOTH be true → silent-inert traps)

Ranked by how money-near / learning-near the silent failure is.

1. **Discord delivery — TRIPLE gate** (the canonical trap, memory `discord_delivery_dual_gate`):
   firm-agent ping fires only if `FIRM_AGENTS_ENABLED=true` AND the per-agent
   `FIRM_AGENT_*_ENABLED=true` AND `AGENT_DISCORD_DELIVERY_ENABLED=true` AND
   `DISCORD_LEGACY_ENABLED=true`. discord-bridge.ts:62 has a one-shot warn for the
   delivery+legacy mismatch (good), but NOT for the master/per-agent layers.
   **Contradiction with production:** feature-flags.md shows `DISCORD_LEGACY_ENABLED`
   default `true` / **production `false`** → as configured, every firm-agent Discord ping
   is dropped at the legacy gate. If operator flips `AGENT_DISCORD_DELIVERY_ENABLED=true`
   today, pings still won't arrive until legacy is also flipped on.

2. **agent_lessons injection — double gate (money-near):** `LESSON_INJECTION_ENABLED` does
   nothing unless `AGENT_LESSONS_ENABLED=true` too (injection.ts:35-36). Both default OFF.
   This is the trade-altering learning switch — both must be true AND approved lessons must
   exist in DB. Easy to flip one and conclude "learning is on" when it's inert.

3. **agent_lessons derivation — double gate + escape hatch:** `LESSON_DERIVATION_ENABLED`
   needs `AGENT_LESSONS_ENABLED=true` too (derive-lessons.mjs:51-52), OR `FIREHOSE_FORCE=true`
   bypasses both. No proposed lessons are ever produced until both are on → injection (#2)
   can never have anything to inject. Ordering dependency that isn't enforced or surfaced.

4. **agent_knowledge injection — double gate, UNDOCUMENTED:** `AGENT_KNOWLEDGE_ENABLED` AND
   `KNOWLEDGE_INJECTION_ENABLED` both required (agent-knowledge/injection.ts:30-31). Neither
   flag appears in the inventory doc OR feature-flags.md → invisible double-gate.

5. **Strategy-Blade sub-gates inert without master:** `STRATEGY_BLADE_FORGE_CHECK/RISK_VETO/
   EVENT_POLICY/NEW_GATES` only evaluate when `STRATEGY_BLADE_ENABLED=true`. Master defaults
   OFF → **all four hard-gates bypassed, proposals go straight to execution.** NOTE the
   nuance: sl-cooldown / daily-trade-cap / regime-direction / mean-revert gates run
   INDEPENDENTLY of the master (their own flags), so partial protection exists, but the
   Forge exposure cap + Shield risk veto + news-blackout veto are master-gated.

6. **firm-agents two-layer:** `FIRM_AGENTS_ENABLED` (master) AND each `FIRM_AGENT_*_ENABLED`
   (index.ts tickFirmAgents:loop). Master off → all 10 agents silent no-op. Per-agent off
   → that agent reports `status: "disabled"`. Both default OFF.

---

## (b) Defaults that BITE given "system should be learning + trading now"

- **`DISCORD_LEGACY_ENABLED` prod=`false`** — see #1. Silences firm-agent Discord output the
  operator may believe is on. Highest-friction default.
- **All strategy masters default OFF** (`*_ENABLED === "true"`). Expected (OFF-by-default
  design), but combined with Conv-3 fragility, a flip that "looks set" can read false.
- **`STRATEGY_BLADE_ENABLED` default OFF** — the cross-strategy exposure cap + risk veto +
  news-blackout veto are OFF by default. For a system "trading now" in demo, this means
  proposals from any enabled strategy skip those three hard-gates.
- **`CALIBRATION_MODE` default `RECOMMEND_ONLY`** — correct per prinsipp 6 (SAFE_AUTO_APPLY
  is Karri-gated), but the learning *capture/recommend* path is on. Good. No bite, but the
  exact-match parse (3b) is a latent trap when SAFE_AUTO_APPLY is eventually authorized.
- **Default-ON report switches use the lenient `!== "false"` raw form** (postmortem-hook,
  drift-monitor, raw-data-persistence). Fail-safe (data keeps flowing per prinsipp 2), so
  these bite in the *safe* direction. Fine to leave.

---

## (c) Dead flags

**Confirmed dead (inventory's own delete-list — 0 code refs, verified):**
`NEWS_SKIP_PRE_EVENT_MIN`, `QSTASH_API_KEY`, `TF_NO_TREND_LONG_OVERRIDE_ADX`,
`TF_REQUIRE_M1_REVERSAL_CONFIRM`.

**Documented but NOT in code (doc-only / reserved):**
`PRISM_SYNTHESIS_ENABLED` — feature-flags.md:84 labels it "reserved / implicit-on"; 0 code
refs. Honest in the doc, but it reads as a real flag in a table → prune or clearly mark.

**Read by code but ABSENT from the 230-var inventory** (so inventory's "199 read by code"
undercounts; these run on code defaults because they're not set on Railway):
`CALIBRATION_MODE` (!), `AGENT_KNOWLEDGE_ENABLED`, `KNOWLEDGE_INJECTION_ENABLED`,
`FIRM_BLADE_PAUSED`, `LET_RUN_ENABLED`, `SHADOW_LOG_ENABLED`, `DRIFT_MONITOR_ENABLED`,
`STATUS_REPORT_ENABLED`, `RAW_DATA_PERSIST_ENABLED`, `DAILY_MORNING_BRIEFING_ENABLED`,
`FIRM_AGENTS_FALLBACK_ENABLED`, `FIRM_AGENTS_TICK_BUDGET_SEC`, `BOT_MANAGER_AUTO_PAUSE_ENABLED`.
Not bugs (defaults are sane) but the inventory is not a complete map — it's a snapshot of
Railway-*set* vars, not code-*read* vars. CALIBRATION_MODE being absent is notable: the
2026-06-03 central learning switch isn't pinned on Railway.

**Cosmetic:** inventory doc lists `ENTRY_STACK_COOLDOWN_ENABLED` twice (line 50, §22).

---

## (e) Learning/calibration/risk flags vs 2026-06-03 activation intent

Prinsipp 6 (rescinded 2026-06-03): learn CONTINUOUSLY; learning-infra that does NOT alter
trade decisions (capture/derive/observability/shadow/dashboards) runs freely + immediately.
Only trade-altering switches (lesson injection into prompts + `CALIBRATION_MODE=SAFE_AUTO_APPLY`)
still gate via Karri.

Contradictions / gaps with that intent:
- **Capture/derive learning infra is STILL OFF by default**: `AGENT_LESSONS_ENABLED=false`,
  `LESSON_DERIVATION_ENABLED=false`. Per prinsipp 6 the *derivation/proposal* side (writes
  `proposed` lessons, changes no decisions) is exactly the infra that should run freely now —
  yet it's gated off, and the double-gate (#3) means nothing is being captured. Injection
  (#2) correctly stays Karri-gated. So the intent is: derivation ON, injection OFF-pending-Karri.
  Current state has BOTH off → not learning continuously yet.
- **`CALIBRATION_MODE=RECOMMEND_ONLY`** matches intent (recommend/observe freely, no
  auto-apply). Aligned. But it's not set on Railway (relies on code default) — fine, just note it.
- **`agent_knowledge` (RAG injection) entirely undocumented** and double-gated off. If this
  is meant to be part of continuous learning, it's invisible to ops.

---

## PRIORITIZED DANGER LIST

| # | Severity | Danger | Where |
|---|---|---|---|
| D1 | HIGH | Strategy + learning MASTER switches parse via bare `=== "true"` (no trim/lowercase). `TRUE`/`1`/`yes`/trailing-space silently reads OFF, no warning. Operator "flipped it, nothing happened". | ~45 sites; all `*_ENABLED` masters |
| D2 | HIGH | Discord firm-agent delivery is a 4-layer gate; prod `DISCORD_LEGACY_ENABLED=false` drops every ping. Only the delivery+legacy layer warns. | discord-bridge.ts:62; feature-flags.md:10 |
| D3 | MED-HIGH | Continuous-learning intent (prinsipp 6) unmet: lesson derivation double-gated OFF → zero `proposed` lessons captured. | derive-lessons.mjs:51; agent-lessons/client.ts:26 |
| D4 | MED | `STRATEGY_BLADE_ENABLED=false` default bypasses Forge exposure cap + risk veto + news-blackout veto for all proposals. | strategy-blade.ts:91 |
| D5 | MED | `CALIBRATION_MODE` exact-match parse: `safe_auto_apply` (lowercase) silently falls back to RECOMMEND_ONLY — latent trap when autotune is later authorized. | calibration.ts:44 |
| D6 | LOW-MED | `agent_knowledge` double-gate (`AGENT_KNOWLEDGE_ENABLED`+`KNOWLEDGE_INJECTION_ENABLED`) undocumented in both inventory + feature-flags. Invisible. | agent-knowledge/injection.ts:30 |
| D7 | LOW | Inventory undercounts code-read flags (CALIBRATION_MODE etc. absent); ENTRY_STACK_COOLDOWN_ENABLED dup; PRISM_SYNTHESIS_ENABLED doc-only. | inventory + feature-flags |
| D8 | LOW | 13 copy-pasted identical `envBool`/`boolEnv` helpers; two names, one behaviour. Drift risk if one ever edited. | repo-wide |

## PROPOSED MINIMAL CONSOLIDATION (infra-only, no behaviour change)

1. **One shared `envBool` in a util** (e.g. `firm/util/env.ts`), import everywhere. Replace
   the 13 copies AND the ~45 bare `=== "true"` master-switch sites with `envBool("X", false)`.
   This alone kills D1 + D5 + D8: trims, lowercases, accepts true/1/yes, fail-safe default.
   Pure refactor, behaviour-identical for correctly-typed values, only *more* forgiving for
   typos. Worth a `tsc` + test pass; no strategy change → no Karri gate.
2. **Startup flag-echo log line**: on boot, log the resolved boolean of every master switch
   (`ORB_ENABLED=true`, `FIRM_AGENTS_ENABLED=false`, …) so a mis-typed flip is visible in the
   first 5 Railway log lines instead of silently inert. Observability only.
3. **Gate-chain warnings** (extend the discord-bridge pattern): warn-once when a child flag
   is on but its required parent is off — `LESSON_INJECTION_ENABLED` w/o `AGENT_LESSONS_ENABLED`,
   `KNOWLEDGE_INJECTION_ENABLED` w/o `AGENT_KNOWLEDGE_ENABLED`, any `FIRM_AGENT_*` w/o
   `FIRM_AGENTS_ENABLED`, any `STRATEGY_BLADE_*` sub-gate w/o master.
4. **Doc hygiene**: delete the 4 dead vars from Railway (operator action); drop the
   ENTRY_STACK dup; mark PRISM_SYNTHESIS_ENABLED as not-implemented; add the 13 code-read /
   not-inventoried flags (esp. CALIBRATION_MODE, AGENT_KNOWLEDGE_*) to feature-flags.md.

---

## NEW TASKS

- **[infra]** Create `firm/util/env.ts` exporting one `envBool(name, fallback)` (the existing
  strict body). Replace 13 local copies + ~45 bare `process.env.X === "true"` master-switch
  reads with it. tsc + worker tests green. Behaviour-neutral refactor. (Fixes D1, D5, D8.)
- **[infra]** Add a boot-time "resolved flags" log line listing every master switch's parsed
  boolean, so silent mis-typed flips are visible immediately. (Fixes D1 symptom.)
- **[infra]** Add warn-once gate-chain mismatch logging for the 4 parent/child double-gates
  (lessons, knowledge, firm-agents, strategy-blade), mirroring discord-bridge.ts:62. (Fixes D2/D3/D6 visibility.)
- **[infra]** Doc cleanup: dedup ENTRY_STACK_COOLDOWN_ENABLED, mark PRISM_SYNTHESIS_ENABLED
  not-implemented, add the ~13 code-read-but-uninventoried flags (CALIBRATION_MODE,
  AGENT_KNOWLEDGE_ENABLED, KNOWLEDGE_INJECTION_ENABLED, …) to feature-flags.md + inventory. (Fixes D6/D7.)
- **[operator]** Delete 4 confirmed-dead Railway vars: NEWS_SKIP_PRE_EVENT_MIN, QSTASH_API_KEY,
  TF_NO_TREND_LONG_OVERRIDE_ADX, TF_REQUIRE_M1_REVERSAL_CONFIRM. (Operator-gated; names only.)
- **[operator]** Decide on `DISCORD_LEGACY_ENABLED`: if firm-agent Discord pings are wanted,
  it must be `true` alongside `AGENT_DISCORD_DELIVERY_ENABLED`. Currently prod=false → all
  firm-agent pings dropped. (Fixes D2 root.)
- **[Karri]** Continuous-learning activation per prinsipp 6: confirm turning ON
  `AGENT_LESSONS_ENABLED` + `LESSON_DERIVATION_ENABLED` (capture/derive — does NOT alter trades,
  so should run freely now). Keep `LESSON_INJECTION_ENABLED` OFF until Karri reviews injected-prior
  semantics. Needs ≥30d post-epoch closed trades for the WR thresholds to be meaningful. (Fixes D3.)
- **[Karri]** Clarify whether `agent_knowledge` RAG injection (AGENT_KNOWLEDGE_ENABLED +
  KNOWLEDGE_INJECTION_ENABLED) is in-scope for continuous learning and whether it's trade-altering
  (it injects into agent prompts → likely money-near, Karri-gated like lessons). (Resolves D6 policy.)
