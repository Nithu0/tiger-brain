---
title: Nexus — Capability Evolution Log
tags: [nexus, capability, self-improvement, learning, automation, retrospective]
type: capability-log
status: living
updated: 2026-06-08
---

# Nexus — Capability Evolution Log

> **Purpose (for the brain):** a durable record of HOW Nexus has become better — the tools
> it gained, the strategies it adopted, the reusable ideas it proved, and the concrete
> improvements shipped. The brain reads this to understand its own trajectory so it can
> drive its own future improvement. Append new gains here; don't let improvements go
> unrecorded — un-recorded gains can't compound. See [[feedback_automate_and_brain_self_improvement]].

## How to read this
Each section accumulates over time. The **Improvement log** is dated and append-only.
The **Tools / Strategies / Patterns** sections are living catalogs of current capability.

---

## 🛠 Tools the system gained

| Tool | What it does | Where | Why it mattered |
|---|---|---|---|
| **443 self-diagnose pipeline** | Crashing subprocess captures redacted stderr → firm_state `:failed` marker → `GET /firehose/derive-status` exposes it over HTTPS/443 | `firehose-error-capture.ts` (#76), `firehose.ts` derive-status (#79) | DB ports + SSH are firewalled on this network; this is how the system diagnoses its OWN failures without Railway log access. **Found the 17-day crash.** |
| **nexus-watch** | Read-only client watch: health, daily-loss, kill-switches, gate-100%-reject, expectancy/PF drift, lesson growth, **derive-failure alarm**. Cron'd (UTC), pings Discord on ALARM, REPORT-only | `scripts/ops/nexus-watch.sh`, `~/.nexus-ops/`, crontab | Automated external watchdog — a dead worker can't page about its own death; this can. |
| **Cloud-side anomaly alerts** | Worker-side hard-loss / loss-cap / loss-streak / activation-health Discord alerts | `loss-and-activation-monitor.ts` (fab56f3), default-OFF | In-loop, fires even when the operator's machine is off. Complements nexus-watch (client-side). |
| **Lesson auto-promotion** | proposed→approved without manual `!lesson approve`, gated: N≥20 obs + consistency≥0.8 + daily cap 3, default-OFF | `scripts/firehose/auto-promote-lessons.mjs` (#73) | Closes the learning-loop weld point — without it, injection is inert (0 approved ever reaches a decision). |
| **Position-size circuit breaker** | Clamps trade to max(80u / 300% notional), data-calibrated from 173 real trades, default-ON | `strategy-execution.ts` (#61/#67, Karri) | The actual blowup guard — would have clamped the Apr-21 106-unit kill to ~56u. |
| **Honest observability** | `/explorer/weaknesses` reads the firm heartbeat (not dead legacy tables); expectancy clamps degenerate result_r | `explorer.ts` + `weaknesses-firm-activity.ts` + `risk-snapshot.ts` (#74) | The trust dashboard had been LYING ("no bots running"); now it reflects reality. |

## 📈 Strategies / risk posture adopted
- **Sizing is the dominant loss lever, not stops.** Forensics on 194 real trades: strip the one Apr-21/22 blowup and the book is break-even (PF 1.03). The hard losses were ONE oversizing event, not a structural edge problem or tight stops. → fix = a hard size cap, not stop-tuning. [[feedback_sl_widening_is_martingale]]
- **Tighten-only invariant** in position management (`isBetterStop()`); widening a stop = martingale, refused in the auto-loop. Manual operator widening is hard-gated + audited.
- **Regime/risk gates** (regime-direction, daily-trade-cap, sl-cooldown, mean-revert-block) — bite live; depend on `INDICATOR_OANDA_FALLBACK_ENABLED` for non-null regime.
- **Continuous learning** (prinsipp 6 rescinded 2026-06-03): derive→promote→inject + SAFE_AUTO_APPLY autotune (±20%/min30 bounds, Karri). Trade-altering switches still gate via Karri.

## 💡 Reusable ideas / patterns proven
- **Attributable batched activation > blind flip.** Flipping every dormant flag at once makes failures unattributable → destroys the learn-loop. Activate in isolated batches with 24-48h observation. [[feedback_batched_activation_over_blind]]
- **Self-diagnose when the network is closed.** When DB/SSH are firewalled (443-only), build the diagnosis INTO the system (capture→persist→expose-over-443) instead of needing log access. This single pattern cracked the 17-day outage.
- **Fail-loud over silent-die.** Subprocesses/gates that fail should write a visible marker + LOUD log, never exit silently. The derive crash hid for 17 days precisely because it was silent.
- **Build default-OFF, activate gated.** Claude builds the mechanism behaviour-neutral; operator flips Railway; strategy/risk values go through Karri. Lets infra land fast without money-impact.
- **Automate the recurring.** Anything I'd re-do by hand (post-deploy checks, watches) becomes a cron/routine. [[feedback_automate_and_brain_self_improvement]]

## 📅 Improvement log (append-only)

### 2026-06-13 — book→AI roadmap scoped + gate-A/B verdict (Karri collaboration maturing)
- **The firm-of-Claudes loop is working:** ai-1 finds → Karri's Claude fixes → ai-1 verifies. In the 3-day gap Karri landed the exact items ai-1 flagged: the strategy-id bug (`xau-mean-reversion` added to the mean-reversion block-list, #101) and the NOISY_CHAOTIC over-classification (price-relative ATR thresholds, #102/#103). The firm is trading again; the "0 trades for 3 days" was the over-classification, now cleared.
- **Gate-loosening A/B verdict (adversarial):** risk_level_high YES (Wilson CI [63,93]% clears break-even; already a zero-risk shadow A/B — no live flip needed). mean_revert_block DEFER (Wilson CI lower bound below break-even; the +0.52R is a cross-strategy aggregation artifact concentrated on session-breakout, while on real mean-reversion the gate correctly prevented losses — loosening re-admits the 04-21 post-impulse tail). **Lesson: a positive aggregate R can be an artifact of pooling across strategies; always decompose by strategy before acting.**
- **Book→AI roadmap (Karri's 5-book mapping) scoped by a 10-agent sweep.** #1 leverage = **meta-labeling** (predict P(win) of the firm's OWN signal, not direction — robust on the thin ~150-trade sample, plugs into the existing conviction + sizing seams). Quick-wins (Claude-infra, shadow, default-OFF): min-R:R gate (the ONE Trading-in-the-Zone principle with zero coverage — execution accepts any tpPoints>0), event-risk gate (the BLACKOUT logic is built but the calendar behind it is stale → it computes CLEAR straight through a real FOMC), market-structure POC/VAH/VAL fact (the `structure` conviction engine is currently FAKED — adapter reads a topic with no publisher), VPA analyzer (tick-volume IS persisted to ohlcv_candles.volume and never read — the codebase wrongly believes it has no volume).
- **The master prompt maps onto the EXISTING Prism conviction + gate stack** — not a parallel system. Net build ≈ 1 fact-publisher + 1 ML wiring + 2 gates. **Lesson: a "new AI architecture" ask is usually a few additions to the existing pipeline — find the half-wired slots (the faked structure engine) before building parallel machinery.**
- **Honest data limits surfaced:** spot gold has no real volume (tick-volume is a usable effort proxy, not full Wyckoff); heavy from-scratch directional ML is sample-starved — which is exactly why meta-labeling-on-existing-signals beats a fresh model now.

### 2026-06-10 — the ADX "P0" was a PHANTOM (and the discipline that caught it)
- A "P0: ADX null → all regime gates blind" had been carried in the backlog for days and drove a flag flip + a 10-agent sweep. **It was false.** A new `/operator/regime` endpoint (#94, built this round) settled it over 443 in one pull: `adx=24.93, adxSource=twelvedata, fallbackActive=false`. ADX was never null — Twelve Data supplies it; the OANDA fallback isn't even needed. `regimeDirection=null` because the regime is genuinely NOISY_CHAOTIC (ADX<30 = not trending) — correct behaviour, not a bug.
- **The real problem it masked:** the firm is gated into paralysis — 0 trades for 3 days — because regime=NOISY_CHAOTIC/extreme-vol makes `risk_level` reject ~95% of cycles. And `regime_direction_gate` never bites due to a strategy-id bug (`xau-mean-reversion` missing from the `MEAN_REVERSION_STRATEGIES` block-list). Both routed to Karri.
- **Meta-lesson (binding):** never propagate an unverified premise across sessions/agents. Multiple agents asserted "ADX null" for days from code-reading + stale data; one purpose-built observability endpoint disproved it in seconds. When a claim drives money-near action, BUILD THE PROBE THAT CONFIRMS IT before acting on it. Observability-to-verify beats theory-to-assume. (This is why `/operator/regime`, derive-status, nexus-watch exist — extend the pattern.)
- Also landed: Karri executed dispatch #2 (#91 confidence rewrite `consistency×min(1,n/8)` + auto-promote 20→8 + aggregate-breaker fail-OPEN→fail-CONSERVATIVE; #92 risk-gate narrowed to high+extreme). Learning loop now code-complete. Shadow forward-test resolver fixed (#95) → real win/loss/R validation signal.

### 2026-06-09 — derive fix VERIFIED + learning loop's real ceiling found
- **17-day crash confirmed dead:** derive-lessons succeeded 2026-06-09 04:22 UTC (first success since 2026-05-13); 2 correctly-tagged proposed lessons produced. The #80 path fix worked. nexus-watch ran overnight, correctly HEALTHY (no false alarm).
- **Karri's Claude executed the paste-ready dispatch** (#86/#87): calibration decoupled from ORB_ONLY (now runs + engine_scores flow, RECOMMEND_ONLY), injection floor aligned 0.50→0.40, aggregate breaker added (default-OFF), 3 dead lessons archived. "Paste into your Claude and run" worked end-to-end across two operators.
- **Adversarial verification (judge) found 3 things — all now batched back to Karri:** (a) the aggregate breaker FAILS-OPEN on a DB error (wrong direction for a safety brake guarding exactly a query-burst cluster); (b) engine_scores still coupled to ORB_ONLY via recordCycleSnapshot; (c) **the real learning ceiling** — derived `confidence = n/50` + auto-promote `n≥20` are STRUCTURALLY unreachable at the live ~2 trades/day rate (buckets plateau n≈5–8 in a rolling 30d window), so continuous learning injects ~nothing. Mechanically complete + correctly wired (`buildLessonContext` IS called from risk-advisor + trade-critic), but thresholds don't match the data rate. Fix proposed to Karri: confidence on signal-strength × gentle-volume, lower MIN_OBSERVATIONS, keep consistency≥0.8 as the guard.
- **Meta-lesson:** "the loop is wired" ≠ "the loop will learn." Thresholds must be calibrated to the actual data rate, or a correct loop is silently muted. Verify capability against real volume, not just code paths.

### 2026-06-08 — the 17-day learning-loop outage, root-caused + fixed
- **Symptom:** lesson-derivation exited code=1 every night since 2026-05-22; 0 new lessons; "learning" was a façade despite flags reading ON.
- **Diagnosis path (the meta-win):** built stderr-capture (#76) + derive-status endpoint (#79) → pulled the crash over 443 → `MODULE_NOT_FOUND: /app/apps/worker/scripts/firehose/derive-lessons.mjs`.
- **Root cause:** trivial — worker spawned the script with `cwd=/app/apps/worker` but the Dockerfile copies scripts to `/app/scripts/firehose` (WORKDIR /app). A path mismatch, not DB/schema (which everyone had assumed).
- **Fix (#80):** `resolveFirehoseScript()` candidate-path resolution + fail-loud. Proof expected on the next 04:00 UTC run.
- **Lesson:** firehose subprocess paths are cwd-fragile; the self-diagnose pipeline is what made a silent 17-day failure visible. [[project_fvg_karri_wip]]

### 2026-06-03 → 06-08 — activation arc
- Operator flipped all learning/risk flags ("alt er flippa") — verification showed it was largely **cosmetic**: stale prod build + flags unset on the worker + 4 independent loop breaks. Made it real: merged the code (#73/#74/#76/#79/#80), got the flags actually set + ORB_ONLY=false (calibration unblocked), redeployed.
- Shipped: honest dashboard, sane expectancy, circuit breaker live, risk_level populated, anomaly alerts, auto-promo, self-diagnose, nexus-watch automation.

## 🔭 Open frontier (next self-improvement) — as of 2026-06-09
- **#1 blocker — confidence formula vs data rate** (Karri): `n/50` + `n≥20` unreachable at ~2 trades/day → learning injects nothing. Recalibrate to signal-strength. THIS is what gates the loop now, not wiring.
- **Aggregate breaker fail-open direction** (Karri): make it fail-conservative + set `MAX_PORTFOLIO_NOTIONAL_PCT` before enabling.
- **engine_scores↔ORB_ONLY coupling** (Karri): wire TIER-3 through `recordCycleSnapshot` so calibration survives the flag.
- Autotune computes correctly now (RECOMMEND_ONLY) → activating `SAFE_AUTO_APPLY` is the next trade-altering step (Karri).
- `MEMORY_RECALL_ENABLED=false` — firm_memory written but never read (Karri decision: recall vs stop writes).
- `VOL_EXP_NO_CHASE_ENABLED` unverified on Worker (+ needs `VOL_EXPANSION_ENABLED=true`).
- Real validation signal: `shadow_signals` works; shadow forward-test + ORB backtest need fixes.
- risk_level gate saturating (3/6 cycles hard-reject → foundation RED) — is it too aggressive? (Karri).

### 2026-06-13 — gold-price threshold-drift root-caused; 2 shadow knowledge-modules landed
- **The real 0-trades root cause (NOT ADX, NOT "choppy market"):** gold ran $2000→$4214 (2.1×) while absolute-dollar volatility thresholds stayed tuned for $2000. `classifyRegime` (atr>12→extreme→NOISY_CHAOTIC, >7→high) mis-tagged ~32% of normal cycles as chaotic; `runRiskAnalysis` (atr>10→high) drove RISK_LEVEL_HARD_GATE → foundation RED → ~95% reject → 0 trades. Karri/ai-1 fixed via price-relative %-thresholds behind `ATR_PCT_THRESHOLDS_ENABLED` (#102/#103, now LIVE). Verified live: regime RANGING (not NOISY_CHAOTIC), risk_level gate 3/3 pass, firm trading again.
- **ai-2 self-correction (honest):** across several watch cycles I reported "0 trades is correct, NOISY_CHAOTIC = genuinely choppy market." That was WRONG — it was a calibration-drift bug, not real chop. As the adversary I should have questioned why a $2000-era threshold was firing on $4214 gold. Logged so the brain doesn't repeat the swallow.
- **2 knowledge-modules landed (ai-1-assigned, ai-2-built, both Phase-1 observability, default-OFF, behaviour-neutral):**
  - **market-structure** (#106, *Mind Over Markets* / Auction Market Theory): TPO + tick-volume session profile → POC/VAH/VAL/Initial-Balance/dayType, publishes a FACT to the SHADOW topic `xauusd.analysis.structure.shadow` (the conviction adapter already reads the live `.structure` topic and fakes it from EMAs — Phase 2 flips to the real fact, Karri-gated). `MARKET_STRUCTURE_ENABLED=false`. 11 tests.
  - **volume-price / VPA** (#107, Anna Coulling VPA): effort-vs-result + climax + volume-trend + sweep-on-volume + breakout-volume-confirm from OANDA tick-volume (persisted to `ohlcv_candles.volume` every cycle but never read until now). vpaScore -100..+100. FACT `firm.volume-price.state`. Honest ceiling logged: tick-volume is a proxy, not exchange volume; no order-flow/delta. `VPA_ANALYSIS_ENABLED=false`. 13 tests.
- **New capability — coordinated parallel firm:** ai-1 + ai-2 ran ~30 agents across two panes simultaneously without collision by (a) a clean lane split (ai-1 = worker/orchestrator/regime/recon + roadmap gates; ai-2 = read-only adversary + the 2 assigned modules), (b) read-only sweeps never touch files, (c) sequential merge of the two module PRs with additive conflict-resolution (both touched `analysis-agents.ts` + worker `package.json` — kept both registrations), verified combined 1256/1256 green before merge.
- **Adversary-sweep capability proven:** a 10-domain read-only workflow (diagnose → adversarial verify-per-finding → synthesize by owner) produced 8 verified findings (false positives + audit-dupes killed in the verify stage). Top latent finding: calibration session-threshold APPLY path is dead code — logs `applied=true` (SAFE_AUTO_APPLY) with zero runtime effect, silently corrupting the learning feedback (RECOMMEND_ONLY default = no live harm yet). Handed to ai-1/Karri.
- **Meta-lesson:** absolute-dollar thresholds silently drift as the underlying re-prices — a whole CLASS of latent bugs (regime, risk, range-gates, FVG gap/distance). The fix pattern is price-relative %-scaling behind a default-OFF flag (`scaleAtrThreshold` + `ATR_THRESHOLD_REF_PRICE`). When a threshold is in raw $, ask "what % was that at tuning-time vs now?" before trusting any gate built on it. Complements the earlier meta-lesson ("the loop is wired ≠ the loop will learn").

## 2026-06-15 — Læringsloop-foundation: fra "måler" mot "lærer" (ultracode, 14-agent workflow)

**Utløser:** operator-revisjon (10-agent) konkluderte at systemet MÅLER men ikke LÆRER — loopens andre halvdel (hypotese→backtest→versjon→sammenligning→verifisering) var død/stubbet/av. Konvergerte med ai-2 sin 98-agent edge-mining: lineage/attribusjon er meta-blockeren.

**Levert (branch infra/learning-loop-foundation, 15 commits, 1427/1427 worker grønt, alt default-OFF, ingen trade-endring):**
1. **Lineage-join fikset** — orchestrator publiserer ÉN cycle-id (cycle-context.ts) stamplet på shadow_signals/gate_decisions/market_snapshots → signal↔markedstilstand joiner nå 1:1 (var 0 treff). Trade-lineage persisteres ved skriving.
2. **strategy_versions** — append-only param-versjon-register (keystone: "slo v2 v1?" blir besvarbart).
3. **hypotheses-tabell + strukturert derive** — loss-clusters → falsifiserbare hypoteser (problem/data/endring/test/kriterium/rollback), firma-filtrert.
4. **Verifikasjons-arm** — change_verifications måler om en landet endring faktisk hjalp (lukker loop-lenke 13).
5. **meta-label firma-filter** — labeler trener ikke lenger på de 124 import-radene.
6. **management-skip-tripwire** — fant ekte stille skip-bug (f551c17-klasse): MGMT_RAN 67%WR/+3.9k vs NO_MGMT 7%/-1.7k; observability-fiks (selve "manage på stale pris" → Karri).
7. **Off-site backup + ekstern uptime-monitor** — scripts kjøreklare, operator provisjonerer bøtte.

**Mønster som funket:** worktree-isolerte bygg-agenter off origin/main (unngikk dirty shared tree + live ai-2-pane) + adversarisk verifikasjon per bygg + sekvensiell union-merge av meg + full suite i hovedtreet før OK-kjør. Adversarisk verifikator fanget: ødelagt package.json fra union-resolver, feilcommittede node_modules-symlinker, og at lineage-endringen gjorde import-rader result_r-bærende (→ la firma-filter på 4 lærings-lesere).

**Læring:** "loopen er wired" ≠ "loopen lærer". Måling uten versjonering+verifisering er observasjon, ikke læring. GPU/hardware løser ingenting her — det var data-disiplin + schema + wiring hele veien.

### Oppfølging samme dag — LANDET på main (PR #121, abe264c), CI grønt
Worktree-gotcha verdt å huske for framtidige parallell-workflows: isolerte worktrees med **symlinket** node_modules får workspace-pakker (@ai-agent/shared) til å resolve til HOVEDsjekkutens packages/shared — ikke worktreets egen. Hvis hovedsjekkuten står på en gammel branch, mangler nye shared-eksporter (her BLOWUP_BOUNDARY_DATE fra #119) → falske test-500 lokalt mens CI er grønt. Fiks: ekte `npm install` i integreringsworktreet før verifisering/push, IKKE symlink for workspace-pakker. Lærdom: verifiser i et miljø der workspace-resolution er ekte før du stoler på en grønn/rød suite. (Adversarisk verifikator fanget også: union-merge-resolver ødela package.json-JSON, og feilcommittede node_modules-symlinker — verifiser maskinell konfliktløsning med en JSON-parse, ikke bare fravær av <<<< markører.)

## 2026-06-19T23:09Z — Læringsloopens armer KOBLET (PR #131, Karris infra-audit)
Karri (+ hans Claude) gjorde en prod-DB-verifisert infra-audit: loopen observerte men handlet ikke — flere armer var bygd men aldri wiret. Reframe: firma-attribuerte strategier er +$2,475; "tapet" var orphan-lekkasje (fikset #122). 6-agent ultracode-workflow wiret: (1) engine_scores trade_id-stamp #87 — TIER-3-opens stamper nå, var bypasset ved pivoten 24.4 → autotune optimerte på tomhet; (2) change-verification i cycle; (3) strategy_versions boot-reconcile; (4) meta-label labeler-schedule + train; (5) durabel quarantine-kolonne; (6) config-drift+CALIBRATION_MODE-audit. Alt shadow/default-OFF, worker 1473/api 152 grønt.
Lærdom som holdt fra sist: integrer i fersk worktree med EKTE npm install + bygg packages/shared (dist/.d.ts trengs for tsc, ellers TS2307 @ai-agent/shared) — symlink gir falske feil. Verifikator fanget 5 uregistrerte test-filer (agenter la til .test.ts men ikke i package.json-registret) + én reduce-type (0|1 vs number). Ny samarbeidsmodell: Karri flipper egne Railway-variabler + har egen Claude i delt Discord-kanal.

## 2026-06-20 — LÆRINGSLOOPEN STRUKTURELT LUKKET (PR #135)
De to siste døde lenkene koblet: hypothesis->backtest->versjon-gate (offline, HYPOTHESIS_GATE_ENABLED default OFF) + per-strategi backtest-dispatch + /learning/loop-status. Loopen er nå komplett ende-til-ende: derive -> strukturert hypotese -> backtest -> kandidat-versjon -> change-verification -> (menneske/Karri approve) -> live. Gaten auto-approver ALDRI.
Dommer-momentet som holdt: adversarisk verifikasjon droppet 2 av 5 bygg — shared-decision-core (fidelityHonest=FALSE: live mean-reversion-refaktor hvis backtest-gevinst ikke landet + ekvivalens ikke bevist) og backtest-results-store (dvalende + ekte Pool-transaksjons-bug). Å droppe en live-path-refaktor hvis gevinst ikke materialiserte = riktig, selv om den "var ferdig". Backtest-generatorene er ærlig merket re-implementering (forutsier ikke live ennaa) — fidelity-oppgraderingen (delt live==backtest-core) er bevisst utsatt til egen verifisert PR. worker 1482/api 172 grønt. Lærdom bekreftet igjen: integrer i fersk worktree m/ ekte npm install + bygg packages/shared før tsc.

## 2026-06-21 — Verifiserte åpne hull lukket + ai-2 hjulpet (PR #136)
Triage-først (ikke oppdiktet arbeid): verifiserte mot main at #117 bot_id-stamp + #131 strategy_versions ALLEREDE var landet → redoet dem ikke. To ekte hull gjensto + fidelity-gapet:
1. Orphan-KLASSE (ai-2 handoff): post-OANDA-row-insert-feil orphaner ikke lenger fylt trade → ORPHANED_FILL risk_event + oanda-sync-reconcile adopterer. #122 fjernet utløser, dette lukker klassen.
2. Breaker-bypass: SIZE_CAP_BYPASS risk_event gjør 80u-cap-bypass på backfill/import-stiene synlig (ai-2s 158u-funn). Observasjon; rutingen er Karri-proposal.
3. Hjalp ai-2: MR backtest-fidelity via delt decision-core (outcome-b — backtest bruker live-speilet kjerne, characterization-tester, INGEN live-fil rørt). Den trygge versjonen av det jeg droppet i #135.
Dommer-mønster: verifiser at "åpne" tasks faktisk er åpne FØR du bygger (2 av 4 antatt-åpne var fikset). Ærlig fidelity igjen: Filter 5/6 ikke speilet — disclosed, ikke overclaim. worker 1507/api 172 grønt.
