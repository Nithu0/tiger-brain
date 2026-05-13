---
date: 2026-05-13
type: investigation
project: nexus
status: open
---

# regime_direction_gate — hvorfor null rader i gate_decisions

## TL;DR

Env-flagget sjekkes korrekt og gaten _evaluerer_ — bevist via 8 `blade_decisions.checks`-rader 12.5 med `name: "regime_direction"`. Men `persistRegimeDirectionDecision()` (SQL-INSERT mot `gate_decisions`) eksisterte **ikke** før commit `deb7075` (2026-05-13 09:35 CET, i morges). Derfor null rader i 7-d-auditen. Persistensen er nå mergede til main; deploy må verifiseres.

## Bevis

### 1. Env-flagget sjekkes og gaten kjører
`apps/worker/src/firm/strategy-blade.ts:134` viser standard `if (isRegimeDirectionGateEnabled()) { ... }`-blokk som kaller `evaluateRegimeDirectionGate()` med regime + regimeDirection hentet fra `xauusd.portfolio.context`.

Bevist via `blade_decisions` (alle 12.5 14:00–17:35 UTC):
```
strategy=xau-session-breakout direction=short approved=true
checks[1] = {"name":"regime_direction","passed":true,"reason":"not_mean_reversion_strategy"}
```
8 rader fra 4 strategier (vol-expansion, session-breakout, breakout-continuation, session-breakout) med varianter `with_trend` / `not_mean_reversion_strategy` / `regime_not_trending`. Operator-flippet `REGIME_DIRECTION_GATE_ENABLED=true` var altså aktivt i Railway 12.5 ettermiddag.

### 2. Persistens-call eksisterer i koden — men ble lagt til 13.5 i morges
```
git log -S "persistRegimeDirectionDecision" --oneline
deb7075 feat(observability): gate persist + null-direction reasons + session-breakout ATR
```
Commit-tidspunkt: **2026-05-13 09:35:25 +0200**.

Den opprinnelige gate-implementasjonen (`4c51309` "feat(gates): regime-direction-gate per Karri proposal 11.5") landet env-flagget + ren logikk, men **ingen DB-write**. `regime-direction-gate.ts` har literalt kommentaren `No DB / blackboard reads — caller supplies regime + direction. Pure logic.`

### 3. Schema er villig
```
SELECT DISTINCT gate_name FROM gate_decisions:
  daily_trade_cap, entry_stack_cooldown, ranging_conviction,
  risk_level, scalp_overlap_asia, session_block
```
Ingen CHECK-constraint på `gate_name`. Ingen unique-constraint som blokkerer. Tabellen aksepterer hvilken som helst tekst — `regime_direction_gate` ville landet uten problem **hvis** INSERTet ble kjørt.

### 4. Daily-cap-kontrollgruppen
`daily_trade_cap` (Karri 12.5) ble lagt til samtidig som regime-direction (begge env-gated default off), men den **inkluderte** persistens fra første commit (`b8195b9`). Resultat: 8 `gate_decisions`-rader 12.5 14:00–17:35 UTC. Bekrefter at INSERT-pathen er sunn — det var bare regime-direction som manglet kallet.

## Hvorfor 7-d-auditen er tom

| Periode | Forklaring |
|---|---|
| 11.5 dag → 12.5 ettermiddag | Persist-funksjonen fantes ikke i koden. Operator hadde ikke flippet flagget enda. |
| 12.5 ~14:00–17:35 UTC | Flagget aktivt på Railway, gaten evaluerer (synlig i `blade_decisions.checks`), men ingen INSERT mot `gate_decisions` — koden manglet kallet. |
| 12.5 17:35 UTC → nå | Markeder stengt → ingen entry-proposals → ingen `evaluateStrategySignal`-kjøringer. Forventet weekend-stillhet (også `blade_decisions` stopper her). |
| 13.5 09:35 CET → fremover | `deb7075` mergede til main. Når Railway redeployer + markedet åpner mandag, bør rader begynne å komme. |

## Minimal fiks

**Ingen kode-endring trengs** — `deb7075` har allerede fikset det. Det som gjenstår er:

1. Verifiser at Railway har redeployet `main` siden `deb7075` (sjekk `/health` build-SHA eller deploy-logg).
2. Når marked åpner mandag 19.5 (eller asia-sesjon søndag kveld 18.5), forvent at `gate_decisions` får rader med `gate_name='regime_direction_gate'`.
3. Hvis null rader etter første XAUUSD-cycle med en mean-reversion-strategi i TRENDING-regime → re-investiger (insert-feil i Railway-logs, eller flagget falt ut av Railway-env).

## Sjekkpunkt-spørringer (kjør på mandag)

```sql
-- skal gi >0 hvis fixen lever:
SELECT COUNT(*) FROM gate_decisions
WHERE gate_name='regime_direction_gate'
  AND recorded_at > '2026-05-13 07:35:00+00';

-- forventer denne distribusjonen (basert på 24-h portfolio.context):
-- HIGH_VOLATILITY (267 msgs, ikke trending → allow:regime_not_trending)
-- RANGING (189, ikke trending → allow:regime_not_trending)
-- TRENDING DOWN (131) + TRENDING UP (71) = 202 msgs der gaten faktisk får jobb
```

## Sidekommentar

Round-2-commit-meldingen i `deb7075` sier eksplisitt _"A1 persist regime_direction_gate decisions to gate_decisions table — mirrors persistDailyCapDecision pattern."_ Så dette ble identifisert og fikset av forrige sesjon. Min undersøkelse her bekrefter at fixen er korrekt og dekker root cause.
