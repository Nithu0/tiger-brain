# Karri-dispatch — Nexus strategi/risk-beslutninger (2026-06-08, fra ai-1)

> **Karri: lim hele denne inn i din Claude i ai-assistent-repoet og kjør på.** Alt er
> konkret (file:line, tall, beslutning). Ingen re-etterforskning nødvendig. Alle er
> strategi/risk = ditt domene. ai-1 har gjort lærings-infra-delen; dette er bryterne/logikken
> bare DU eier. Bygg default-OFF der det endrer trade-beslutninger; operator flipper Railway.

## Kontekst (kort)
17-dagers lærings-loop-død er root-causet + fikset (#80: derive-lessons spawnet feil sti,
MODULE_NOT_FOUND — trivielt, ikke DB). Loopen begynner å produsere lekser fra 04:00 UTC i natt.
Når den gjør det, blir punkt 1 + 2 under umiddelbart relevante. Full bakgrunn:
`00-claude-inbox/nexus/2026-06-08/06_MASTER-BACKLOG.md` + `01-nexus/Nexus-Capability-Evolution.md`.

---

## 1. ORB_ONLY_MODE blokkerer ALL kalibrering (autotune kan aldri fyre)
- **Fakta:** `orchestrator.ts:741` skipper `runCalibration` når `ORB_ONLY_MODE=true`. Og `engine_scores`
  (som autotune trenger som input) skrives kun av `recordCycleSnapshot()` i `bladeApproval()`
  (`managers.ts:693`) — ALSÅ bak `!orbOnlyMode`. Begge døde 2026-04-25 da flagget landet (`8abb4bb`).
- **`ORB_ONLY_MODE` er et feilnavn nå:** live-driverne er TIER-3 (trend-following/breakout-cont/etc),
  `ORB_ENABLED=false`. TIER-3 kjører via `runStrategyExecution` (orchestrator.ts:594) FØR gaten.
  Reell effekt av flagget = "bypass firm-decision-path + kalibrering/attribusjon".
- **Anbefalt (Option 2, ren lærings-infra, ingen trade-endring):** flytt `runCalibration`-kallet UT av
  `!orbOnlyMode`-gaten + produser `engine_scores` på TIER-3-stien. `SAFE_AUTO_APPLY` (allerede ±20%/min30
  bounds, #68) gater fortsatt via deg. Alternativ 1 = `ORB_ONLY_MODE=false` (gjør alt i ett, men
  re-aktiverer Prism/Blade som live trade-sti → trenger din vurdering).
- **Din beslutning:** Option 1 vs 2 vs behold. Så bygger din Claude det.

## 2. Confidence-floor vs auto-promote-misalignment (2. stille blokk etter krasjen)
- **Fakta:** injection-floor er `minConfidence=0.5` (`injection.ts:53`). Derivert confidence =
  `min(0.95, n/50)` (`derive-lessons.mjs`, ren sample-size-proxy) → trenger n≥25 for å klare floor.
  Auto-promote gater på `consistency≥0.8` (annen metrikk, fra outcome_score). → en lekse kan bli
  APPROVED men aldri INJISERT.
- **Fix (du velger, rører trade-prompts):** align — enten senk `minConfidence` (env-styrt), ELLER gate
  injection på samme consistency-notion, ELLER slutt å beregne confidence som n/50.

## 3. MEMORY_RECALL_ENABLED=false — firm_memory skrives, leses aldri
- firm_memory skrives ved hver close (postmortem-hook), men `MEMORY_RECALL_ENABLED=false` → leses aldri
  tilbake i beslutninger. Død vekt. **Din beslutning:** re-enable recall (trade-påvirkende) ELLER stopp
  de døde skrivingene.

## 4. Aggregat circuit-breaker før live-kapital
- Dagens breaker (`strategy-execution.ts`, #61/#67) er PER-TRADE (clamp 80u/300% notional). 04-21-blowupen
  var 3 SAMTIDIGE ~12%-trades (~1690% aggregat) — per-trade-clamp fanger ikke clusteret.
- **Bygg:** portfolio-notional/aggregat-eksponerings-tak ved order-chokepointet. Proposal-stubb finnes:
  `docs/strategy/proposals/2026-06-01_hard-position-size-circuit-breaker.md`. Ikke haster (demo) men før live.

## 5. Arkiver 3 døde lekser (cleanup)
- id 1,2,3 i `agent_lessons` er døde: feil role-tag (`lesson-deriver-stats`, pre-3a37500-fix) + conf < 0.5.
  Kan aldri injiseres. SQL (kjør via nexus-pg-rw etter din OK):
```sql
UPDATE agent_lessons SET status='archived'
 WHERE id IN (1,2,3) AND status='proposed' AND agent_role='lesson-deriver-stats';
-- forvent UPDATE 3; reversibelt med status='proposed'
```

## 6. Verifiser vol-exp no-chase faktisk er på
- Din godkjenning 28.5 (`2026-05-28_volexp_no_chase_activation.md`, "ready"). Mot −$4.1k vol-exp-bleed.
  Bekreft `VOL_EXP_NO_CHASE_ENABLED=true` faktisk satt på **Worker**-servicen (funnel ser ikke filter-flagg).

---
**Når du har bestemt 1–3: si fra til operator/ai-1, så flipper han Railway + ai-1 verifiserer live.**
Risiko-invarianter som IKKE skal brytes: tighten-only SL (ingen widening i auto-loop), build-default-OFF
for alt trade-endrende, REPORT-only på health (ingen auto-disable).
