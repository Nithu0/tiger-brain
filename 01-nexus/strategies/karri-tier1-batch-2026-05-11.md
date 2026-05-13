---
type: strategy-batch-overview
subsystem: karri-review-queue
batch_date: 2026-05-11
batch_pr: "Nithu0/ai-assistent#1"
batch_merge_commit: b22cb8d
source_doc: docs/ops/strategy-analysis-day-2026-05-11.md
reviewer: Karri
status: merged-awaiting-activation
---

# Karri TIER 1 batch — 2026-05-11

Canonical overview of the 5 TIER 1 strategy proposals pushed via PR #1 (`b22cb8d`) after Karri's evening review-runde 2026-05-11. All 5 stem from the same source: dagens tap-analyse (`docs/ops/strategy-analysis-day-2026-05-11.md`, 995 linjer).

Each proposal landed default-OFF behind its own env-flag. Claude implements 4 of these in parallel as env-gated default-off commits. Activation in prod awaits operator "OK kjør" per proposal.

## The 5 proposals

| # | Proposal | Tier | Estimert impact | Env-flag (default `false`) | Type |
|---|---|---|---|---|---|
| 1 | `regime_direction_gate` | TIER 1 | +$2–3k/30d beskyttelse | `REGIME_DIRECTION_GATE_ENABLED` | Pre-trade gate |
| 2 | `session_block_gate` | TIER 1 | **−$3683 spart over 19 trades** (sterkeste enkelt-fix) | `SESSION_BLOCK_ENABLED` | Pre-trade gate |
| 3 | `sl_cooldown` | TIER 1 | $1023 spart historisk | `SL_COOLDOWN_ENABLED` | Per-strategi cooldown |
| 4 | `scalp_overlap_observe_only` | TIER 1 (emergency) | Stopper dagens $1058-bløding | `SCALP_OVERLAP_OBSERVE_ONLY` | Emergency stop |
| 5 | `orb_observe_only` | TIER 1 (emergency) | Stopper ORB-bløding | `ORB_OBSERVE_ONLY` | Emergency stop |

## Per-proposal one-line summary

### 1. `regime_direction_gate`

Dagens 8 trades: 6 av 8 SHORT mens marked steg $75 (klar opp-trend). Strategiene mangler trend-direction-signal — regime sier kun "TRENDING", ikke "UP"/"DOWN". Forslag: utvide regime-klassifisering med `TRENDING_UP` / `TRENDING_DOWN` (H4-EMA-slope eller 4h close-move), blokker counter-trend mean-reversion-signaler.

Filer: `docs/strategy/proposals/2026-05-11_regime_direction_gate.md`

### 2. `session_block_gate`

Postmortems over 19 trades viser: `OVERLAP_ACTIVE` (16 trades, −$2151 net) og `NY_OPENING_RANGE` (3 trades, −$1532 net, **−$511/trade**) er konsistent tap-sessions. `LONDON_ACTIVE`, `NY_CONTINUATION`, `ASIA_OBSERVE` er konsistent profitable. Dagens: 7 av 8 trader i tapssessions (alle tapte). Hard pre-trade gate som blokker entries i tap-sessions.

Filer: `docs/strategy/proposals/2026-05-11_session_block_gate.md`

### 3. `sl_cooldown`

Dagens scalp-overlap fyrte 3 SHORTs på 19 min (13:14, 13:19, 13:33), alle SL hit. Strategien rakk ikke å lese første tap før den gjentok feilen. 60-min cooldown per strategi etter SL hit, reset ved (a) 60 min eller (b) første vinner-close.

Filer: `docs/strategy/proposals/2026-05-11_sl_cooldown.md`

### 4. `scalp_overlap_observe_only`

Emergency env-flag stop for `xau-scalp-overlap`-strategi som tapte $1058 på 19 min i dag. Setter strategi til observe-only mens regime-direction-gate + session-block-gate utvikles. Default OFF — operator kan flippe en flagg på Railway uten kode-deploy.

Filer: `docs/strategy/proposals/2026-05-11_scalp_overlap_observe_only.md`

### 5. `orb_observe_only`

Emergency env-flag stop for `xau-orb`. Mønster fra dagen (−$398) gjentar seg over flere dager. Observe-only-mode tar strategi ut av execution-pathen mens andre fixes lander.

Filer: `docs/strategy/proposals/2026-05-11_orb_observe_only.md`

## Implementation plan (Claude-side, parallell)

4 av 5 implementeres i parallelle env-gated default-off commits:

1. `regime_direction_gate` — utvide `regime.ts` + ny gate i `strategy-blade.ts`
2. `session_block_gate` — ny gate i `strategy-blade.ts` som leser `session_at_entry`-klassifikator
3. `sl_cooldown` — cooldown-state i `strategy-execution.ts`
4. `scalp_overlap_observe_only` ELLER `orb_observe_only` — én av to observe-only flagg-paths (begge er trivielle config-gates)

Hver landes som default-off så vi kan deploye uten å endre prod-atferd. Operator flipper flagg per proposal når Karri/operator har OK'd activation.

## Aktiverings-rekkefølge (anbefalt)

Per impact-analyse:

1. `session_block_gate` først (sterkeste enkelt-fix, lavest risiko fordi det er ren blokk)
2. `sl_cooldown` deretter (forhindrer tapsstreams uten å endre selve strategien)
3. `regime_direction_gate` (krever regime-klassifikator-utvidelse, mest kode)
4. observe-only flaggene som backstop hvis #1-3 ikke stopper bløding raskt nok

## Foundation gate-impact

**Ingen.** Foundation gate (5/5 🟢 per 11.5T13:33Z) er ikke avhengig av strategy-side endringer. Disse proposalene er strategy/risk-arbeid og påvirker ikke gate-tilstand.

## Carry-over: 4 actionable + 1 architecture stadig åpne

- `conviction_quartile_position_sizing`
- `funnel_drain`
- `postmortem_size_down_feedback`
- `vol_expansion_throttle_review` (HIGH RELEVANCE — vol-exp tapte $1,179 i dag)
- `processed_signals_persistence` (arkitektur, design-level)

## Links

- Source tap-analyse: `docs/ops/strategy-analysis-day-2026-05-11.md`
- Phase-status entry: `docs/ops/phase-status.md` → "11.5 runde 9"
- Karri reviewer ref: memory `reference_strategy_reviewer.md`
- Related: [[Strategy-Scalp-Overlap]], [[Strategy-ORB]], [[Strategy-Vol-Expansion]], [[SNAPSHOT]], [[foundation-gate-state]]
