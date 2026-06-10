# Decision/learning — "skru på alt" → batch-vis attribuerbar aktivering (2026-06-03)

**Domain:** Nexus · **Type:** decision + meta-learning · **Author:** ai-1

## Situasjon
Operator, i max-send-modus etter en produktiv kveld: "skru på alt, faile og lære, vi kan slå av senere." Demo-konto. Eksplisitt valgt "Skru på ALT nå" i et AskUserQuestion.

## Beslutning
Frarådet **blind alt-på-samtidig**. Ikke av forsiktighet (operator var lei forsiktighet), men av tre attribusjons-/korrekthets-grunner:
1. **Mass-flip ødelegger lærings-loopen.** "Faile og lære" krever å kunne isolere hvilken endring forårsaket hva. 30 flagg samtidig → PnL-fall er uattribuerbart. Batch-vis = læring; alt-på = gjetting.
2. **To flagg er kjent skadelige, ikke bare forsiktige:** `MANUAL_SL_WIDEN_ALLOWED` (martingale), `SESSION_BREAKOUT_SL_MODE=swing_based` (ubekreftet). Holdes av på prinsipp.
3. **FVG kan ikke aktiveres — ikke wiret** (Karris WIP). Å sette flagget gjør ingenting/feiler.
Pluss: strategi-flagg er **Karris domene**; "operator beslutter med Karri på tråden" ≠ "overstyr Karris uferdige arbeid mens han ser på". → batch-vis, Karri triagerer Gruppe A–D.

## Utfall
Operator: "bra du er kritisk nå ble jeg imponert ser at du lærer." Valgte (a): Batch 1 i kveld, Batch 2 via Karri i morgen.

## Meta-læring (gjelder framover)
- Operator BELØNNER push-back med **attribusjons-/metodikk-argument**, ikke "det er risikabelt". Når operator sier "aktiver alt / kjør på max" på penge-nær atferd: ikke kapituler, ikke vær blankt forsiktig — tilby den aggressive-men-attribuerbare versjonen + loop Karri på hans domene.
- Demo-konto = bias mot dristighet er legitimt, men dristighet ≠ uattribuerbarhet.
- Railway-mutasjoner kjører operator selv (bindende) — jeg gir kommandoene.

Lenker: [[Operator-Principles]] · [[project_trend_pause_concept]]
