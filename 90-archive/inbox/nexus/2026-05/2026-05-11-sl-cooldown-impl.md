---
type: implementation-note
project: nexus
date: 2026-05-11
status: implemented
default: off
proposal: docs/strategy/proposals/2026-05-11_sl_cooldown.md
reviewer: Karri
commit: 96b6cb9
---

# SL-cooldown — implementert env-gated default-off

Karri-forslag 11.5 landed. Per-strategi 60-min cooldown etter SL hit.
Ingen aktivering — operator må flippe `SL_COOLDOWN_ENABLED=true` på Railway.

## Hva gjør den

- Etter en strategi hits SL (`close_reason ∈ {OANDA_SL_TP, SL_HIT}` + negativ PnL):
  - `firm_state[sl_cooldown:<strategyId>] = { lastSlAt: ISO, lastTradeId: id }`
- Neste forsøk fra samme strategi:
  - blokkeres med `sl_cooldown_active (Xmin remaining)` til cooldown-vinduet utløper
- Vinner-close fra samme strategi clearer state umiddelbart (UPDATE → null-state)
- Survives worker restarts (firm_state-rad)

## Filer endret

- `apps/worker/src/firm/gates/sl-cooldown-gate.ts` (NEW) — gate-evaluator + state-skrivere
- `apps/worker/src/firm/gates/sl-cooldown-gate.test.ts` (NEW) — 21 tester (env-gating, blokk/allow, SQL-form, malformed state)
- `apps/worker/src/firm/strategy-blade.ts` — gate plugget inn FØR master kill-switch (kjører uavhengig av STRATEGY_BLADE_ENABLED)
- `apps/worker/src/firm/postmortem-hook.ts` — single ground-truth: SL-hit ⇒ recordSlHit, vinner ⇒ clearSlCooldown
- `docs/strategy/proposals/2026-05-11_sl_cooldown.md` — Status → implemented (env-gated, default-off)
- `.env.example` — SL_COOLDOWN_ENABLED + SL_COOLDOWN_MINUTES (kommentert ut)

## Commit + verifikasjon

- SHA: **96b6cb9**
- `cd apps/worker && npx tsc --noEmit` ✅ exitcode 0
- `npm test` ✅ 519/519 pass (≥ baseline 478)

## Hvor state lever

- Tabell: `firm_state`
- Key: `sl_cooldown:<strategyId>` (f.eks. `sl_cooldown:xau-scalp-overlap`)
- Value (TEXT, JSON-encoded): `{"lastSlAt":"<ISO>","lastTradeId":"<id>"}`
- Skrives av: `apps/worker/src/firm/postmortem-hook.ts` på hver close-rad

## Open Q's IKKE løst (per default valg)

- Q1: Per-strategi default valgt (Karri kan be om global — 1-PR-bytte)
- Q4: STALE_TRADE_EXIT med negativ PnL teller IKKE som SL (kun OANDA_SL_TP + SL_HIT). Lett å utvide i `isSlClose()`.

## Operator-flip

På Railway:
```
SL_COOLDOWN_ENABLED=true
SL_COOLDOWN_MINUTES=60
```

Instant rollback: sett `SL_COOLDOWN_ENABLED=false`.
