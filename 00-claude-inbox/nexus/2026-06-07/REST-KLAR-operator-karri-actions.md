# Rest gjort klar — operator/Karri-handlinger (2026-06-07, ai-1)

"Ta det meste nå og gjør resten klart." Dette er resten — alt gated, klart til ett klikk / én paste.

## ✅ Tatt nå (ai-1, landet på main)
- **PR #74 merget** (`ab16d22`) — honest /explorer/weaknesses + expectancy-clamp. Dashboardet slutter å lyve ved neste deploy.
- **PR #73 merget** (`03bda72`) — lessons auto-promotering (default-OFF, Karris spec). Koden er nå reell; `LESSON_AUTO_PROMOTE_ENABLED` er ikke lenger placebo.
- **PR #76 åpen** — derive-lessons selv-diagnose: fanger redaktert stderr inn i `:failed`-markøren så krasjen blir pullbar over 443. (Merges når CI grønn.)

## ⏳ Gjør reell-listen — det som faktisk aktiverer ting

### 1. Derivation-krasjen (ROT-blocker — ingen lekser produseres uansett)
- **HVORFOR:** derive-lessons.mjs exit-1 nattlig i 17 dager. Til den fikses produseres 0 nye lekser → injection/auto-promo har ingenting å jobbe med.
- **HVA (etter #76 deployer):** vent på neste 04:00 UTC-kjøring, så **pull `firm_state`-nøkkelen** `firehose:derive_lessons:<dato>:failed` (over 443) — den inneholder nå `stderrTail` med ekte stack. Send den til meg → jeg fikser rotårsaken.
- Alternativt nå: operator grep Railway Worker-logg ~04:0x UTC for `[derive-lessons] fatal:`.

### 2. Railway-flipp som gjenstår (operator)
- `LESSON_AUTO_PROMOTE_ENABLED=true` — først NÅ meningsfull (kode på main etter #73). Men inert til derivation (1) produserer lekser. Flipp etter (1) er fikset.
- **Verifiser at worker faktisk fikk lærings-flaggene:** `/calibration/status` ekko-er API-prosessens env, ikke workerens. Agent fant loopen inert. Bekreft på worker-siden: sett (om ikke satt) `AGENT_LESSONS_ENABLED`, `LESSON_DERIVATION_ENABLED`, `LESSON_INJECTION_ENABLED` på **Worker**-servicen spesifikt.

### 3. Karri-beslutning: ORB_ONLY_MODE blokkerer all kalibrering
- **HVORFOR:** `orchestrator.ts:724` skipper `runCalibration` helt under `ORB_ONLY_MODE`. Så `CALIBRATION_MODE=SAFE_AUTO_APPLY` er no-op mens ORB_ONLY er på — autotune kan aldri fyre. Karris ±20%-bounds er korrekte men nås aldri.
- **Beslutning Karri:** er ORB_ONLY_MODE tilsiktet fortsatt? Hvis autotune skal virke, må enten ORB_ONLY av, eller kalibrering tillates under ORB_ONLY.

### 4. vol-exp no-chase (Karri-godkjent 28.5, "ready" — høyest-verdi u-flippede)
- **HVORFOR:** vol-exp bløler −$4.1k/26% WR; no-chase-filteret skal demme det. Agent kunne ikke bekrefte at flagget er satt (funnel ser ikke filter-flagg).
- **HVA:** bekreft `VOL_EXP_NO_CHASE_ENABLED=true` på Worker. Hvis ikke satt → flipp.

### 5. Aggregat circuit-breaker (Karri, før live-kapital)
- Dagens breaker er per-trade-only. 04-21-blowupen var 3 samtidige ~12%-trades. Karri: portfolio-notional-tak før live kapital. (Proposal-stoff, ikke implementert.)

## 📅 Mandag re-verifisering (når flippene faktisk testes)
Markedet var stengt i helg → 0 sykluser siden flip. Etter London open mandag, pull + sjekk:
```
bash pull-nexus-data.sh
```
- `gate_decisions` hvor `gate_name='risk_level_hard_gate' AND hard_rejected>0` → biter risk-gaten? (forventet ~60% would_reject).
- Worker-logg/`circuit-breaker … CLAMPED` → clamper breakeren oversized?
- `/calibration/status` `multipliersSource` non-null + `applied=true` innen ±20% → kjører autotune (kun hvis ORB_ONLY løst, pkt 3).
- agent_lessons proposed-count vokser (krever derivation fikset, pkt 1).
- `risk_snapshot` expectancy/winRate vs baseline (−0.44R/16%) — ingen flip-indusert forverring.
**Ikke godkjenn noen lekse de første 48t** — så autotune (når den kjører) er attribuerbar separat fra injection.

## 🗂 Strandet (lavere prioritet, cherry-pick senere)
- `c6a6b03` backtest-15min-runbar + runbook · `a9e54f3` oanda N+1. På node-migration-nexus (PR #60, 25 foran/65 bak). Cherry-pick til main ved behov, så arkiver PR #60.
