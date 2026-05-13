# Karri instruction harvest — chronological corpus

**Type:** primary source, direct quotes only (no interpretation)
**Sibling:** `16_karri_proposal_corpus.md` (interpretation lives there)
**Scope:** code comments, commit messages, proposal-doc bodies, memory files, Obsidian notes — everything beyond the proposal `Reviewer: Karri` line itself.
**Harvest date:** 2026-05-13

---

## Topic-pivoted index

- `[#trend-pause]` — entries 12-may-A, 12-may-B, mem-trend-pause
- `[#regime]` — entries 11-may-C, 11-may-D, 12-may-A, code-regime-dir
- `[#gate]` — entries 11-may-A, 11-may-C, 11-may-D, 12-may-D, code-session, code-cap, code-cooldown
- `[#sl]` — entries 11-may-B, 11-may-E, code-cooldown
- `[#sizing]` — entries 11-may-F, 11-may-G, 08-may-A
- `[#evidence-bar]` — entries 11-may-D, 11-may-H, batch-overview, regime-direction-Q5
- `[#strategy-spec]` — entries 12-may-S1, 12-may-S2, 12-may-S3, code-trend, code-breakout, code-pullback
- `[#mean-reversion]` — entries 13-may-A, 13-may-B, mem-trend-pause
- `[#vocabulary]` — entries 12-may-S3, 12-may-S1, batch-overview
- `[#workflow]` — entries auto-send, reviewer-ref, runbook
- `[#sweet-spot-override]` — entries 11-may-handoff, code-S3-adx, code-S4-impuls

---

## Chronological log

### Workflow setup — established 2026-05-08

**reviewer-ref / `~/.claude/projects/-home-nithu-code-ai-assistent/memory/reference_strategy_reviewer.md`**
Quote: "Operator's teammate Karri owns strategy/risk on the Nexus project. Use his name in proposal Reviewer fields and Discord routing. Established 2026-05-08."
Summary: Karri is the strategy/risk reviewer; all money-impact proposals route through him.
Tag: `[#workflow]`

**reviewer-ref (continued)**
Quote: "Strategy proposal docs: set `Reviewer: Karri` in the frontmatter. Discord messages about strategy/risk: address `Yo Karri` or similar casual NO/EN mix matching operator's style."
Summary: Address Karri casually, mixed NO/EN; he's not a formal stakeholder voice.
Tag: `[#workflow]` `[#vocabulary]`

---

### 08-may-A — 2026-05-08, `docs/strategy/proposals/2026-05-08_deprecate_simulated_orders_strategy_id_desk.md`

Quote: "> Karri: please review only the `desk` half. The strategy_id half is moot."
Summary: Claude flags scope to Karri — review only the `desk` column proposal, not the `strategy_id` half which is already moot.
Tag: `[#workflow]`

---

### 11-may-A — 2026-05-11, `docs/strategy/proposals/2026-05-11_funnel_drain.md` (line 99-113)

Quote: "Spørsmål til Karri" header followed by gate-specific clarifications. "...mini-Blade gater fremdeles hver enkelt proposal individuelt, så risiko-konvolutten endrer seg ikke per trade — bare antallet trades som faktisk når brokeren."
Summary: When something is "bug-or-feature" borderland, gate it behind env-flag default-off and explicitly book Karri's vurdering before flipping.
Tag: `[#gate]` `[#workflow]`

---

### 11-may-B — 2026-05-11, `docs/strategy/proposals/2026-05-11_sl_cooldown.md` (line 91)

Quote (Karri's hypothesis embedded as analysis convergence): "Tap1 ('manglende cooldown / state memory') og tap2 ('ingen pause etter feil regime') begge identifiserer dette."
Quote (open Q for Karri): "Per-strategi eller global cooldown? ... Tap2-analyse foreslo global (konservativ). Hvilken vil du ha?"
Summary: SL-cooldown framed as Karri-known failure mode ("loss compounding", "memory loop"); cooldown duration + scope (per-strategi vs global) is explicitly Karri's call.
Tag: `[#sl]` `[#gate]`

---

### 11-may-C — 2026-05-11, `docs/strategy/proposals/2026-05-11_regime_direction_gate.md` (lines 17, 79)

Quote: "Foreslår: utvide regime-klassifisering med `TRENDING_UP` / `TRENDING_DOWN` (via H4-EMA-slope eller 4h close-move), og legge til hard pre-trade gate som blokker counter-trend mean-reversion-signaler."
Quote (open Q for Karri): "Trend-direction-metode: H4-EMA-slope eller 4h close-move? Eller noe annet (slow Aroon, daily HL-bias)?"
Summary: Karri's frame — regime-classification needs direction (`UP`/`DOWN`), and the canonical method-choice is his call.
Tag: `[#regime]` `[#gate]`

---

### 11-may-D — 2026-05-11, `docs/strategy/proposals/2026-05-11_regime_direction_gate.md` (line 101)

Quote: "Sample size: 28 vol-exp + 4 scalp-overlap matchede trades. Mønstret er konsistent på tvers, men under 30+ dager grense (operator-prinsipp #6). Vi ber om Karri-approval basert på konvergens av 3 uavhengige analyser + akutt katastrofe i dag, ikke pure statistisk signifikans."
Summary: Karri's evidence bar — convergence of 3 independent analyses + acute incident is a valid override for the operator's 30-days statistical-significance rule.
Tag: `[#evidence-bar]` `[#regime]`

---

### 11-may-E — 2026-05-11, `docs/strategy/proposals/2026-05-11_session_block_gate.md` (lines 17, 92)

Quote: "Estimert impact (basert på 19d historikk): Eliminerer −$3683 over 19 trades. Sterkeste enkelt-fix vi har identifisert."
Quote (open Q): "NY_OPENING_RANGE har sample 3. Trygt å blokke? Min vurdering: ja, $-511/trade er for grovt selv på 3 — men du eier vurderingen."
Summary: Karri owns the small-sample call; Claude does not auto-extend block-list, only proposes.
Tag: `[#gate]` `[#evidence-bar]`

---

### 11-may-F — 2026-05-11, `docs/strategy/proposals/2026-05-11_conviction_quartile_position_sizing.md` (lines 11, 45, 52)

Quote: "Filer nå for å booke Karri-vurdering på quartile-grenser, scale-faktor-fordeling og om scoren er pålitelig nok å scale på."
Quote: "Fase 2 (etter 30d data — Karri-review): Quartile-grenser settes empirisk per strategi (ikke globalt). Hver strategi får sin egen mapping."
Quote: "Fase 3 (etter Karri-OK — implementer scaler): `effective_risk_pct = base_risk_pct * conviction_multiplier[quartile]`, hvor multiplier-defaults er `{Q1: 0.5, Q2: 0.75, Q3: 1.0, Q4: 1.25}`."
Summary: Karri owns quartile boundaries + scale-factor defaults + the "is the score reliable enough" call; sizing changes are 3-phase observe → review → activate.
Tag: `[#sizing]` `[#evidence-bar]`

---

### 11-may-G — 2026-05-11, `docs/strategy/proposals/2026-05-11_postmortem_size_down_feedback.md` (lines 11, 55, 57)

Quote: "Trenger Karri-OK på (a) trigger-betingelse, (b) scale-down-faktor, (c) reset-logikk."
Quote: "Step 3: live scaler (kun etter Karri-OK på 14d shadow-data)."
Summary: Three-knob sizing-feedback (trigger / factor / reset) — each knob is Karri-decision; shadow-data for 14 days before live.
Tag: `[#sizing]`

---

### 11-may-H — 2026-05-11, `docs/strategy/proposals/2026-05-11_vol_expansion_throttle_review.md` (lines 9, 13, 37, 61)

Quote: "UPDATED 2026-05-11: Data baseline expanded since original audit ... Hypothesis (throttle is too strict) may still hold but supporting case needs Karri's re-evaluation against current funnel."
Quote: "Forslag: ingen threshold-endring nå, men instrument `vol_expansion_rejection_reasons` i 14 dager før vi tar stilling."
Quote: "Step 2 (etter 14d data): Karri-review av rejection-distribusjonen."
Summary: When data changes the picture, instrument first, decide later. Karri reads the rejection-distribution, no auto-throttle change.
Tag: `[#evidence-bar]` `[#gate]`

---

### 11-may-I (kveld) — 2026-05-11, `Obsidian/Brain/01-nexus/strategies/karri-tier1-batch-2026-05-11.md`

Quote (batch source-attribution): "Canonical overview of the 5 TIER 1 strategy proposals pushed via PR #1 (`b22cb8d`) after Karri's evening review-runde 2026-05-11. All 5 stem from the same source: dagens tap-analyse (`docs/ops/strategy-analysis-day-2026-05-11.md`, 995 linjer)."
Quote (Karri's activation order): "Per impact-analyse: 1. session_block_gate først (sterkeste enkelt-fix, lavest risiko fordi det er ren blokk). 2. sl_cooldown deretter (forhindrer tapsstreams uten å endre selve strategien). 3. regime_direction_gate (krever regime-klassifikator-utvidelse, mest kode). 4. observe-only flaggene som backstop hvis #1-3 ikke stopper bløding raskt nok."
Summary: Karri's prioritization heuristic — ren-blokk first, behaviour-shift later, observe-only as backstop only.
Tag: `[#gate]` `[#workflow]`

---

### 11-may-J (kveld) — `Obsidian/Brain/00-claude-inbox/nexus/2026-05-11-karri-morning-discord-queued.md` (lines 88-99)

Karri Q embedded in pending Discord draft (Claude to him): "regime_direction_gate — Trenger TRENDING_UP/TRENDING_DOWN-klassifisering — bekrefter du H4-EMA-slope er riktig metode?"
"session_block_gate — Er OVERLAP_ACTIVE + NY_OPENING_RANGE riktig default-list, eller skal vi inkludere flere?"
"sl_cooldown — 60 min OK eller skal det være variabel per strategi?"
Summary: Open Karri-questions queued for next-morning Discord — method, block-list, knob-tuning are all his calls.
Tag: `[#regime]` `[#gate]` `[#sl]`

---

### Auto-send rule — 2026-05-11, `~/.claude/projects/.../memory/feedback_auto_send_karri.md`

Quote: "Operator authorized 2026-05-11 to auto-send strategy proposals to Karri via Discord without per-message confirmation, when Karri is 'på jobb' (normal work hours)."
Quote: "When a new strategy/risk proposal is filed and Karri's review is needed, send the Discord embed directly during work hours (Nordic business hours, roughly 09:00–17:00 CET / 07:00–15:00 UTC). NO per-message confirmation required."
Summary: Auto-send during 09-17 CET; outside window, queue and send next morning.
Tag: `[#workflow]`

---

### 12-may-A — 2026-05-12, `docs/strategy/proposals/2026-05-12_daily_trade_cap.md` (lines 12, 17, 26)

Quote: "Per-strategi `maxTradesPerDay`-caps eksisterer ... men det finnes ingen cross-strategy total cap. Teoretisk kan systemet ta opp til ~15 trades/dag. Historisk data viser at dager med 8+ trades konsistent korrelerer med tap."
Quote: "6 av 7 dager med ≥8 trades endte i tap. Total tap fra disse dagene: −$13 225 av totalt −$9572."
Quote: "Foreslår: hard cross-strategy daily trade-cap på 6 trades per UTC-dag."
Summary: Cross-strategy total cap matters; per-strategi caps don't compose right. Cap=6 is the inflection point in 152-trade data.
Tag: `[#gate]` `[#evidence-bar]`

---

### 12-may-B — 2026-05-12, `~/.claude/projects/.../memory/project_trend_pause_concept.md`

Quote: "Hypothesis (Karri 12.5 katastrofedag-analyse): All 3 verste dager (21.4, 22.4, 6.5) deler samme rotproblem — boten gjenkjenner ikke trend-pause/konsolidering, og flipper retning under pausen, catches false reversal."
Quote: "Why: Sterk H1+ trend → kort pause / range-bound → bot leser pause som mean-reversion opportunity → fyrer counter-trend → trend gjenopptas → trade SL'es."
Quote: "Don't propose your own implementation — Karri is reviewing this concept."
Summary: Karri's headline 12.5 hypothesis — trend-pause-blindhet is the root cause across legacy + TIER 3. regime_direction_gate + daily_trade_cap are proxies until a dedicated detector exists. Claude must not auto-build a detector.
Tag: `[#trend-pause]` `[#regime]` `[#mean-reversion]`

---

### 12-may-S1 — 2026-05-12, `docs/strategy/proposals/2026-05-12_strategi_1_trend_following_core.md`

Quote (Karri's CORE-strategy frame): "Implementasjon av Karri sin CORE-strategi: regime-driven trend-following med volatilitetskonfirmasjon, pullback continuation entry, og strenge filter mot chop/counter-trend."
Quote (strategy negative-space — what NOT to do, per Karri's spec):
"Strategien SKAL IKKE: Fade momentum; Shorte sterke uptrends; Kjøpe falling knives; Trade chop; Trade 'billige reversals'."
Quote (10-filter pipeline summary): EMA20/50 + ADX≥25 + ATR-expansion 1.15× + session-whitelist + cooldown + daily cap + direction-loss-protection + no-chase + pullback depth + rejection candle.
Summary: Karri's S1 — trend-following via pullback continuation, with 10 hard filters and an explicit "SKAL IKKE"-list. SL 1.5×ATR, TP initial 3R + trail 1×ATR.
Tag: `[#strategy-spec]` `[#vocabulary]`

---

### 12-may-S2 — 2026-05-12, `docs/strategy/proposals/2026-05-12_strategi_2_breakout_continuation.md`

Quote (Karri's framing): "Ikke 'range breakout gambler' — likviditets- og ekspansjonsstrategi."
Quote (3-phase model): "Markeder gjennom 3 faser: 1. Compression (energi bygges) 2. Trigger (breakout) 3. Expansion (trend eller flush). Strategien trader fase 2→3."
Quote (expected WR/payoff per Karri spec): "Win-rate forventet 35-45%, høyere R-payoff (per spec)" vs S1's 45-55%.
Summary: S2 — compression-then-expansion via breakout + retest, asymmetric R-payoff, expects lower WR.
Tag: `[#strategy-spec]` `[#vocabulary]`

---

### 12-may-S3 — 2026-05-12, `docs/strategy/proposals/2026-05-12_strategi_3_pullback_continuation.md`

Quote: "Implementasjon av Karri sin 'mest stabile alpha'-strategi."
Quote (core principle, direct from Karri spec): "Core prinsipp: 'Buy weakness in strength, sell strength in weakness.'"
Quote (spec verbatim section 12): "Vi fader IKKE expansion — vi venter på expansion, deretter kjøper pullback innenfor samme directional regime."
Quote (spec quote — pullback continuation definition): "'Pullback Continuation = trading the second leg of a trend after volatility expansion, only when structure confirms continuation and entry is made on discounted retracement.'"
Quote (edge mechanism, Karri spec section 12): "Denne strategien tjener penger fordi: 1. Smart money behaviour: institusjoner kjøper ikke topp — de akkumulerer på pullbacks. 2. Liquidity retraces: stops tas i pullback, entries fylles billig. 3. Momentum continuation: trend + vol-exp = persistence."
Summary: S3 is Karri's "mest stabile alpha". The spec gives explicit edge-rationale (smart-money + liquidity + continuation) and a one-line trading creed.
Tag: `[#strategy-spec]` `[#vocabulary]` `[#mean-reversion]`

---

### 12-may-D — 2026-05-12, `docs/strategy/proposals/2026-05-12_vol_exp_mean_revert_block.md`

Quote: "Markedet falt $58 ($4700→$4642) i 90 min, deretter reverserte $40 opp = klassisk mean-reversion after impulse. Begge vol-exp SHORTs fyrte etter at impulsen var nesten over og ble fanget i reversen. Vol-exp er strukturelt blindt for 'post-impulse-fase'."
Quote: "Mean-reversion var STATISTISK FORVENTET etter $58 fall. Vol-exp så ATR-spike og signalte 'continue down' — feil retning gitt at impulsen allerede var fullført."
Summary: Karri's failure-mode coinage — "post-impulse blind" vol-exp; foundation for cross-strategy mean-revert gating.
Tag: `[#mean-reversion]` `[#vocabulary]` `[#gate]`

---

### 11-may-handoff (sweet-spot override) — 2026-05-12 00:59, `docs/ops/2026-05-11_evening_handoff.md` (line 39)

Quote: "Karri's originale defaults var altfor strenge — S3 produserte 0 trader på 6 mnd. Vi tuned hver strategi via parameter-sweep + composite-test mot OANDA H1 (2867 candles fra 2025-11-12 til 2026-05-11)."
Quote: "S3 er den klart sterkeste. PF 6.38 reflekterer 'mest stabil alpha' som Karri-spec lovet."
Summary: Karri's specs were directionally right but quantitatively too tight; backtest-derived sweet-spot tuning beat the spec defaults on real data.
Tag: `[#sweet-spot-override]` `[#strategy-spec]`

---

### 12-may-Q — code: `apps/worker/src/firm/pullback-continuation/config.ts` (line 46-48)

Quote: "// Sweet-spot 2026-05-12: 20 (was 25; Karri's 25 produced 0 trades over 6mo) adxPeriod: envInt('PC_ADX_PERIOD', 14, 5, 50), adxMin: envFloat('PC_ADX_MIN', 20, 10, 60),"
Summary: Code-level audit-trail of Karri default overrides; original ADX≥25 produced 0 trades.
Tag: `[#sweet-spot-override]`

---

### 13-may-A — 2026-05-13, `docs/strategy/proposals/2026-05-13_strategi_4_mean_reversion.md`

Quote: "Alle 5 eksisterende strategier (S1/S2/S3 + Vol-Exp + Session-Breakout) er CONTINUATION-strategier. På mean-revert-dager (11.5 + 12.5 = 2 av siste 10 trading-dager) fyrer de alle i feil retning og taper. S4 = mean-reversion-strategi som fyrer COUNTER-TREND etter store impulser — komplementerer porteføljen."
Quote: "Akademisk: Etter store impulser i intradag-marked er sannsynligheten for mean-reversion statistisk høyere enn fortsettelse i ~70% av tilfellene (PROFITABLE-papers fra 2010-2020 forskning)."
Summary: Karri-frame — portfolio diversification beats more-of-the-same; S4 is the counter-side hedge against katastrofedag.
Tag: `[#mean-reversion]` `[#strategy-spec]`

---

### 13-may-B — 2026-05-13, S4 proposal (status block)

Quote: "Decision: approved-verbally 2026-05-13 (Karri som boss-operator-rolle)"
Quote: "Sweet-spot tuning: PR #24 (merged til main). Live activation: MEAN_REVERSION_ENABLED=true på Railway 2026-05-13 (etter sweet-spot funn på 54 trader/6mo backtest)."
Summary: S4 verbally approved by Karri acting in boss-operator capacity; verbal-approval still tracked in proposal status for audit trail (per "approved-verbally" convention).
Tag: `[#mean-reversion]` `[#workflow]`

---

### 13-may-Q — code: `apps/worker/src/firm/mean-reversion/config.ts` (lines 80-89)

Quote: "Allowed sessions — sweet-spot 2026-05-13. Backtest viste at LONDON_ACTIVE også gir lønnsomt mean-revert-volum (S4 har 54 trader på 6 mnd med både NY + London vs 12 trader med kun NY). Karri kan utvide videre (OVERLAP) etter live-data."
Summary: Karri is explicitly named as the future owner of session-list expansion (OVERLAP candidate); Claude does not extend autonomously.
Tag: `[#sweet-spot-override]` `[#mean-reversion]`

---

### 13-may-Q2 — code: `apps/worker/src/firm/mean-reversion/config.ts` (lines 11-12)

Quote: "Strategy is OFF by default — set MEAN_REVERSION_ENABLED=true to activate. KREVER KARRI-REVIEW FØR LIVE."
Summary: All-caps Karri-gate baked directly into module header — a binding code-comment guard.
Tag: `[#workflow]` `[#mean-reversion]`

---

### Daily-cap evidence framing — code: `apps/worker/src/firm/gates/daily-trade-cap-gate.ts` (lines 6-17)

Quote (Karri's 152-trade backtest summary, in code comment):
```
Trades/day | Days | Avg PnL
1-3        | 8    | -$76
4-6        | 4    | +$580   ← sweet spot
7-9        | 5    | -$1230
10+        | 3    | -$2426  ← catastrophe band
```
Quote: "6 of 7 days with ≥8 trades ended in losses (cumulative −$13,225). Vinner-day grenseverdi was 6 trades (3.5: 6 trades, +$2,096)."
Summary: Karri's 152-trade backtest baked permanently into the gate module's header as the load-bearing rationale; "sweet spot" / "catastrophe band" vocabulary.
Tag: `[#evidence-bar]` `[#gate]` `[#vocabulary]`

---

## Open Karri questions still unresolved (per-proposal review-notes still empty)

The literal text `(Karri fyller inn her)` appears in:
- 2026-05-08_break_even_trigger_lower.md
- 2026-05-11_regime_direction_gate.md (line 118)
- 2026-05-11_session_block_gate.md (line 100)
- 2026-05-11_sl_cooldown.md (line 120)
- 2026-05-11_scalp_overlap_observe_only.md (line 88)
- 2026-05-11_orb_observe_only.md (line 86)
- 2026-05-11_conviction_quartile_position_sizing.md (line 101)
- 2026-05-11_postmortem_size_down_feedback.md (line 105)
- 2026-05-11_vol_expansion_throttle_review.md (line 106)
- 2026-05-11_funnel_drain.md (line 118)
- 2026-05-11_processed_signals_persistence.md (line 95)
- 2026-05-12_daily_trade_cap.md (line 144)
- 2026-05-12_strategi_{1,2,3}_*.md (all three pending)
- 2026-05-12_vol_exp_break_even_on_1r.md (line 74)
- 2026-05-13_strategi_4_mean_reversion.md (line 102)

Karri has not directly filled in the Review-notes section in any of these — all decisions to date have come via operator-relayed verbal approval ("approved-verbally"). Karri's voice in this corpus is therefore inferred from: (a) Claude's framing of Karri-spec, (b) operator commit messages, (c) batch-attribution docs, (d) the `Strategi 1-3.txt`-derived strategy specs.

## Source provenance notes

- `Strategi 1-3.txt` (the canonical Karri-authored spec for S1/S2/S3) is referenced by all three 2026-05-12 strategy proposals as "Karri spec 12.5" but the file itself is not in the repo or vault — operator passed it to Claude inline. The strategy specs in `apps/worker/src/firm/{trend-following,breakout-continuation,pullback-continuation}/config.ts` are derivative.
- Karri Discord webhook hits HTTP 204 — proposals are landing. No reply transcripts are in the vault (Discord channel not mirrored).
- All `Karri-side` handoff headers (`Forfatter: Claude (Karri-side, ...)`) are Claude self-identifying which seat he's sitting in for the session, not Karri-authored content.
