---
title: Round 2 synthesis — bug-jakt + Karri-pensum + action matrix
date: 2026-05-13
session: max-mode round 2 (bug hunt + Karri-pensum)
status: synthesis
related:
  - "[[11_regime_direction_gate_forensics]]"
  - "[[12_daily_trade_cap_forensics]]"
  - "[[13_portfolio_regime_detector_forensics]]"
  - "[[14_signal_to_trade_audit]]"
  - "[[15_session_breakout_sl_hunt]]"
  - "[[16_karri_proposal_corpus]]"
  - "[[17_karri_instruction_harvest]]"
  - "[[18_trend_pause_karri_state]]"
  - "[[19_vol_expansion_distilled]]"
  - "[[20_library_bootstrap]]"
---

# Round 2 — rotårsaks-stakken og handlingsmatrisen

## TL;DR

Systemet **vet** at det handler feil. Det **logger** at det vil rejecte. Det **ENFORCER ikke**. Tre overlappende lag som hver for seg gjør systemet blindt, og som sammen produserer 11.5-runawayen:

1. **Regime-detektoren returnerer "vet ikke" stille** (97.7% null direction)
2. **`regime_direction_gate` er env-OFF likevel** + skriver ikke til `gate_decisions` selv når den slås på
3. **5 nye gates kjører i SHADOW-mode default** — `hardFlags=false` overalt → systemet logger "ville blokkert" men slipper trafikken gjennom

Karri sa det selv 12.5: **"Når trend pauser, blir den blind."** Det er *eksakt* det forensics fant — direction-fallback returnerer null på 5+ feilstier, gate short-circuiter til `allow`, kanon-fail.

---

## Rotårsaks-stakken (sortert: ytre lag → indre kjerne)

### Lag 1: Direction-blindness via silent null (kjernen)

- `portfolio-brain.classifyTrendDirection` returnerer `null` på minst 5 ulike feilstier: candles_empty, candles_too_short, fetch_error, null_flat, og en til. Alle ser identiske ut downstream.
- `regime-direction-gate.ts:91-93` short-circuiter til `{allow: true, reason: "direction_unknown"}`.
- Empirisk: 592 av 606 TRENDING blackboard-messages = `regimeDirection=null`. **97.7% av tiden vet ikke systemet om trenden er opp eller ned.**
- 11.5 13:14–13:33: 3 scalp-overlap SHORTS inn i en +80 USD vertikal M15 impulse. Detektoren visste ikke at det var en uptrend. Trades fyrte. Tap −$1058 på 28 min.

### Lag 2: regime_direction_gate er av (eller blind selv når på)

- `REGIME_DIRECTION_GATE_ENABLED=false` på Railway. Karri's proposal `2026-05-11_regime_direction_gate.md` er status: pending, ikke OK-kjørt.
- *Selv hvis flippet på*: ingen `persistRegimeDirectionDecision()`-helper finnes. Beslutninger lever bare i in-memory `BladeDecision.checks` og er usynlige i `gate_decisions`. Audit/`gate-impact.ts`-spørringer forblir blinde.

### Lag 3: Alle 5 nye gates kjører i shadow-mode

- `new-gates.ts:110-117`: `hardFlags = { risk_level: false, entry_stack_cooldown: false, ranging_conviction: false, scalp_overlap_asia: false, session_block: false }` per default.
- Siste 7d: 24 `would_reject=true`-rader, kun 4 `hard_rejected=true`. `risk_level` fyrte 17 soft, 0 hard.
- Systemet sier "passed=true, N gates evaluated, none hard-reject" mens DB-en samtidig sier "would_reject=true 24 ganger". Kognitiv dissonans innebygd i koden.
- **Lavest-hengende frukt**: flip `ENTRY_STACK_COOLDOWN_ENABLED=true` på Railway. Null kode-endring. Ville blokkert 2 av 3 trades i 11.5 13:14-cluster.

### Lag 4: Ingen cross-strategy direction-flip-gate

- 11.5 13:14–13:33 scalp-overlap SHORTS, deretter 39 min senere fyrer vol-expansion LONG (4729). Ingen gate hindrer to strategier å ta motsatte sider innen samme time.
- Karri's `[#trend-pause]`-tema dekker dette konseptuelt; ingen implementasjon finnes.

### Lag 5: session-breakout SL = strukturell pivot-zone (separat issue)

- `session-break-manager.ts:340`: `stopLoss = direction === "long" ? range.low : range.high`. Full range-bredde, ingen ATR-justering, ingen swing-respect.
- 6 av 14 trades (43%) SL-hit siste 30d → −$1 111. Strategien er designet for å tape ved SL.
- `atr_at_entry=NULL` på alle session-breakout-rader (observability-bug separat fra metode-feilen).
- Krever Karri-proposal — design-debatt, ikke kode-bug.

### Lag 6: daily_trade_cap — falsk alarm

- 8 firings 0 blocks fra round 1 var ikke logikk-bug. Gaten landet 12.5, 24h **etter** 11.5-runawayen. På 12.5 åpnet kun 3 trades (under cap=6). Counting er korrekt.
- Smaller issues kvar: filter `execution_source='firm_strategy'` only (misser `firm_blade` + NULL), pluss race window via post-INSERT UPDATE av `execution_source`. Begge dormant så lenge `ORB_ONLY_MODE=true`.

---

## Karri-pensum oppsummert (fra agent 16/17/18)

**Karri's faktiske kjernedemands (fra 24 proposals):**

1. Env-flag default-OFF + navngitt 30-sek rollback-vei på alt money-impact
2. ≥6mo OANDA H1-backtest + sweet-spot tuning + ≥30 closed trades før live-aktivering (override kun ved structural-problem som R:R math eller MFE=$0)
3. Rejection-tagging instrumentation FØR threshold-only tuning — 14-dagers shadow-log først, så beslutning

**Karri's konsistente rejection-mønstre:**

1. Counter-trend MR i TRENDING-regime = hard block, ikke soft penalty
2. Auto-disable / auto-pause på anomali = nei, health-check RAPPORTERER, operator beslutter
3. Threshold-only proposals uten funnel-instrumentation; "while we're here"-refactors; to endringer i én PR

**Karri's åpne forsknings-spørsmål:**

1. **Trend-pause-deteksjon** (kanonisk — direkte truffet av Lag 1+2 over)
2. **Conviction-score reliability** — predikerer Blade's composite faktisk edge? 30+ dager post-metadata-fix nødvendig
3. **Postmortem-tag → risk-feedback loop** — 16/16 losere tagget `RIGHT_THESIS_BAD_EXECUTION`, men ingen forbruker. Dormant feedback-loop.

**Overraskelse:** Karri's egne S3-spec-defaults (ADX≥25) produserte 0 trades / 6mo i live. Repo har Claude-overridet hans defaults med audit-trail-kommentarer. Spec var retningsmessig riktig, men tunet for tight. Hans "Strategi 1-3.txt" master-spec er **ikke i repo eller vault** — operator limte den inn inline, alle refs er derivative.

---

## Handlingsmatrise — hva flippes/fixes/sendes til Karri?

### A. Kan kjøres NÅ uten Karri (bug-fix / observability)

| # | Action | Type | Hvorfor trygt uten proposal |
|---|---|---|---|
| A1 | Legg til `persistRegimeDirectionDecision()` helper i `regime-direction-gate.ts` (mirror av `persistDailyCapDecision`) | Observability-only commit | Karri's regel: rejection-tagging instrumentation først. Ingen atferdsendring. |
| A2 | Instrumenter `classifyTrendDirection` til å logge/persistere null-grunnen (5+ stier) | Observability-only | Avdekker hvilken av 5 stier som tar 97.7% — kreves før Karri kan beslutte fallback |
| A3 | Recorde `atr_at_entry` på session-breakout-strategien | Observability-only | NULL på alle rader er ren bug, ikke metode-spørsmål |
| A4 | Daily_trade_cap filter: `IN ('firm_strategy','firm_blade')` ved `daily-trade-cap-gate.ts:115` | Bug-fix | Smal, fanger faktisk legacy execution_source — restorer intended behaviour |
| A5 | Backfill `portfolio_regime_at_entry` på 138/156 NULL trades fra `regime_decisions` historikk | Data-fix | Karri eksplisitt ber om dette i `2026-05-12_trend_pause_phase1.md` |

### B. Operator-flippes på Railway (jeg drafter kommandoene)

| # | Env flip | Forventet effekt | Risiko |
|---|---|---|---|
| B1 | `ENTRY_STACK_COOLDOWN_ENABLED=true` | Ville blokkert 2 av 3 11.5 13:14-cluster trades. Karri har allerede approvet gaten på proposal-nivå. | Lav — env-flag default-OFF mønster, 30-sek rollback. |
| B2 | `RISK_LEVEL_HARD_GATE_ENABLED=true` (eller size-degrade-variant) | 17 soft / 0 hard siste 7d. Trade-level signal allerede beregnes. | Lav-medium — kan kutte legit trades inntil tunet. |
| B3 | `REGIME_DIRECTION_GATE_ENABLED=true` — **men** krever Karri-OK først på pending proposal | Direction-blokk aktiveres (når detektor ikke er null) | **Avhenger av A1+A2 først** — ellers er gaten observability-blind når den faktisk blokkerer |

### C. Karri-proposals som må skrives (jeg kan drafte alle nå)

| # | Proposal | Drives av |
|---|---|---|
| C1 | `2026-05-13_null_direction_block_eligible.md` | Lag 1 — skal `regimeDirection=null` regnes som block-eligible? Eller bruke M15 EMA20-50 slope fallback? Karri-konsept. |
| C2 | `2026-05-13_session_breakout_sl_method.md` | Lag 5 — 3 opsjoner: cap-at-1×ATR / swap til ATR+swing / disable for re-validation |
| C3 | `2026-05-13_cross_strategy_direction_flip.md` | Lag 4 — gate som hindrer to strategier å ta motsatt-retning innen X minutter |
| C4 | `2026-05-13_postmortem_risk_feedback.md` | Karri's åpne spørsmål — `RIGHT_THESIS_BAD_EXECUTION`-tag → risk-degrade loop. Trigger-threshold + skala + reset open. |

**Auto-send-regel:** alle 4 ville auto-sendes til Karri's Discord siden vi er innenfor work hours (07:36Z = 09:36 CET = mandag morgen-vindu). Vi kan markere `ikke send` på enkelte for triage.

### D. Strategi-fri data-prep til Karri's neste review-sesjon

- Counter-factual replay: hva ville hver gate gjort med `hardFlags=true` på siste 14d?
- Candle-overlay 11.5 + 12.5 cluster-dager med trade-entries markert
- Per-strategi null-direction distribusjon (etter A2 er deployet)

---

## Anbefalt rekkefølge (min ranking — operator beslutter)

1. **A1 + A2 + A3 + A4 lokalt** (samme commit eller serie, observability-fokusert)
2. **B1 flip** (`ENTRY_STACK_COOLDOWN_ENABLED=true`) — null risiko, bevist preventiv på 11.5
3. **C1 + C2 + C3 + C4 drafter til Karri** (auto-send i work-hours-vindu)
4. **B2 flip** etter rejection-data fra A2 har samlet 7d
5. **B3 flip** krever Karri-OK på C1 først

Operator har sagt "KJØR PÅ" — men miljø-flipper og push krever fortsatt eksplisitt "OK kjør" per binding regel (memory `feedback_no_auto_activation.md` + CLAUDE.md). Jeg drafter alt og venter på OK før hver gate.

---

*Generert 2026-05-13 fra 10 round2-agenter. Kilder lenket øverst.*
