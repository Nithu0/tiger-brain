# Aktiverings-plan — Batch 2 for Karri (handoff, send 2026-06-04 morgen)

**Fra:** ai-1 (operator-dispatched) · **Status:** SENT to Karri Discord 2026-06-03 (operator-triggered, HTTP 204) — awaiting his KJØR/VENT/ALDRI · **Reviewer:** Karri

## Kontekst

Operator (2026-06-03 kveld): "skru på alt — tror Karri har lagd alt av en grunn, bare ikke fått aktivert mens han venter på resultater. På tide å faile og lære istedenfor å være forsiktig. Vi kan slå av senere." Demo-konto → begrenset nedside.

ai-1 frarådet **blind alt-på-samtidig** (kan ikke attribuere feil = ingen læring; to flagg er kjent skadelige; FVG ikke wiret). Operator aksepterte batch-vis attribuerbar aktivering.

**Batch 1 (operator flipper i kveld, ops-klarert):** `DAILY_TRADE_CAP_ENABLED`, `REGIME_DIRECTION_GATE_ENABLED`, `MANUAL_POSITION_CONTROL_ENABLED` (Worker+API).

## Batch 2 — Karri triagerer hver: KJØR / VENT / ALDRI

Alle proposal-bakede, default-off i dag. Anbefalt rekkefølge = lavest risiko + høyest attribuerbarhet først. **Flipp i grupper med 1 dags mellomrom** så hver gruppes effekt er målbar i PnL/gate_decisions.

### Gruppe A — silent-bug-fikser (høyest verdi, lavest risiko)
- `FUNNEL_DRAIN_PROPOSALS=true` — fikser ~29 % proposal-drop (`strategy-execution.ts:113`, proposal 2026-05-11_funnel_drain). Anbefalt KJØR først.
- `STRATEGY_BLADE_NEW_GATES=true` (når `STRATEGY_BLADE_ENABLED=true`) — slutter å begrave session/risk/ranging-gates stille (`strategy-blade.ts:335`).

### Gruppe B — gates Karri allerede har bygd
- `SL_COOLDOWN` (proposal 2026-05-11) — 60min cooldown etter SL.
- `SESSION_BLOCK` gate (2026-05-11_session_block_gate).
- `NULL_DIRECTION_BLOCK` / `CROSS_STRATEGY_DIRECTION_FLIP` (2026-05-13).

### Gruppe C — vol-exp filtre (vol-exp er −$4.1k/26% WR — disse skal demme opp)
- `VOL_EXP_NO_CHASE`, confluence-filter, mean-revert-block, break-even-on-1R (2026-05-12_vol_exp_*).

### Gruppe D — TF/strategi-tuning
- `TF_ADX` 22→20 (2026-05-13), H14 optimal-configs (2026-05-16_*_optimal_config: sb/tf/bc/mr/volexp).

### HOLDES AV selv i aggressiv modus (ai-1 nekter, ikke Karri-valg)
- `MANUAL_SL_WIDEN_ALLOWED` — martingale.
- `SESSION_BREAKOUT_SL_MODE != range_edge` — swing_based ubekreftet, trenger 6mo-backtest.
- `calibration_auto_apply_loop` (RECOMMEND_ONLY→APPLY) — prinsipp 6, stor beslutning, separat.
- `FVG_*` — ikke wiret (Karris pågående arbeid).

## Ask til Karri
Marker hver gruppe KJØR/VENT/ALDRI + ev. rekkefølge. ai-1 lager flipp-kommandoene; operator flipper (Railway = operator-gate). Etter hver gruppe: 24t observasjon på gate_decisions + PnL før neste.
