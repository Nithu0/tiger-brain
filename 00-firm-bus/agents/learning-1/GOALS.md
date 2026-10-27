# learning-1 — GOALS

## Aktivt mål (2026-08-17)

**Ukentlig "lærer systemet?"-rapport + GPU-lane i drift.** Første deterministiske rapport til feed (metrikker i onboarding-notatet §4), og når operatør flipper GPU-flaggene: verifiser første prod-trening/scoring-pass (`meta_label_gpu_models`-rad + `mlmgpu_`-scores) + A/B logistisk-vs-xgboost.

## Fullført 11.10 (Veldora/Solar Consulting, code-1-dispatch)
- **Triage-læringskjeden verifisert mot prod** (rapport: `00-claude-inbox/Veldora/2026-10-11_triage-laering.md`).
  9 beslutninger, profil n=2, grense 30, nattlig cron ok siden 05.10, debounce 7/10.
  Svakeste ledd: `endpoints/triage.ts:120` (`profileN: profile?.n ?? decidedCount`) — telleren
  står stille mens operatøren jobber. Diff foreslått til code-1, IKKE utført.
- Sidefunn meldt: Anthropic-kvote tom (LLM-jobber feiler), Google-token `invalid_grant`.

## Fullført 19.08
- **Ukespuls #1 levert** (00-claude-inbox/nexus/2026-08-19_learning-1-weekly-pulse-01.md) + `scripts/ops/learning-pulse.sql` (deterministisk, repeterbar).
- **Trener-kadens-bug funnet+fikset:** 5/30 dager pga 05:30–05:59-vindu mot timetick. Branch fix/meta-label-trainer-cadence (4b8b444), 2401/2401, VENTER OK KJØR for push. Verifiser 21.08: firm_state `meta_label:train:2026-08-20/21`.

## Fullført 17.08 (operatør OK kjør)
- **GPU-trening + live prediksjon LEVERT: PR #281** (10.08-ordren). Moduler deployet + E2E på boksen (129 labels, CUDA, brierSkill −0.17 = ærlig no-signal ved dagens n). Batch-scoring utenfor trading-syklusen. 10 review-funn fikset. Flag-gated OFF — flip-liste i PR.

## Fullført 14.08
- VERIFY-BY 01.08 (read-only): META_LABEL-wiring VERIFISERT live (156 labels, nattlig trener, 468 scores/24t) — men alle modeller "no-signal" + trener-hull 23.07→13.08. SAFE_AUTO_APPLY: 0 applied siden 26.06 (sample-gate holder alt, vindu faller 29→19).

## Kø
- Ukespuls #2 (neste uke, samme SQL). Når forensics er merget: legg til forensics-verdikt/uke.
- Eskalering: 2 oneshot-SQL venter fortsatt (NB: thesis-normaliseringen er IKKE trener-blokkerende — thesis_quality_score er ikke en trener-feature; gjelder scorer-fallback + firm_memory).
- forensics→lessons-kobling når trading-1s branches er merget.

## PARKERT 2026-10-13 (Veldora strategiråd runde 1)

**Hva var i gang:** Ukespuls #2 (deterministisk SQL, ikke startet), forensics→lessons-kobling
(venter på trading-1 merge — blokkert av andre, ikke av meg), og oppfølging av triage-funnet
fra 11.10: `projects/anbud` `endpoints/triage.ts:120` `profileN: profile?.n ?? decidedCount`.

**MÅ gjøres før noe annet (begrunnelse):**
1. `profileN`-diffen er FORESLÅTT, ikke utført — den er meldt til code-1 og ligger ikke halvferdig
   noe sted. Ingen fare. Men den er forutsetningen for at profil-læringen i Veldora i det hele tatt
   teller riktig, så den må inn FØR noen måler kvalitet på triage-rangeringen.
2. Anthropic-kvote tom + Google-token `invalid_grant` (meldt 11.10): så lenge disse står,
   feiler LLM-jobbene i Veldora stille. Operatør-gate.

**Trygt å parkere:** ukespuls #2, GPU-lane-verifisering (flagg er OFF), A/B logistisk-vs-xgboost.
Alt er flag-gated OFF og ingenting står halvveis i prod.

**Ingenting halvferdig og farlig etterlatt.** Ingen uncommittede endringer i Veldora (les-only),
ingen åpne branches fra meg som venter på push utover `fix/meta-label-trainer-cadence` (4b8b444,
grønn, venter OK kjør — ufarlig å la stå).
