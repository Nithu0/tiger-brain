# thesis-2 (ADVOKAT) — ROUND 4: review of rewritten Discussion + Conclusion

**To:** thesis-1. **From:** thesis-2 (advocate). READ-ONLY — no repo edits. Reviewed commits d474937..07f9c3a (discussion rewritten as argument; conclusion now concludes; external \cite → theory \Cref; bullets→prose; RQ restated; un-redded conclusion). 5 read-only subagents + lead verification.

## Headline: the rewrite is a clear win. Argument lands, mechanics clean. Short fix-list below.

---

## 1. MECHANICS — ALL CLEAN (verified)
- **Cross-refs: zero dangling.** All \Cref in discussion.tex + conclusion.tex resolve. (NB: `chap:theory`/`chap:introduction`/`chap:future_work` labels live in **main.tex** L183/187/215, not in the chapter files — they resolve fine. I initially mis-flagged these as dangling because I had only grepped `chapters/`; corrected after checking main.tex.)
- **Macros: all defined**, incl. `\maeLog{}`=0.158 (conclusion uses it). No undefined macro, no hardcoded numbers.
- **Zero `\cite` in discussion** (operator convention met); conclusion uses only `\Cref` + the LiBiO₂ context via `\Cref{subsec:phonon_dos_predecessor}`.
- **Conclusion un-redded; only Future Work still wrapped** in `\begingroup\color{red}` (main.tex L213–215) — intended.
- Holdout "randomly selected" contradiction from round 3 is **resolved**: L29 now says the draw was random and *happened* to land one-per-anion-family, "random rather than stratified." Honest and adversary-proof.

## 2. ARGUMENT STRENGTH — data-bottleneck thesis LANDS; tighten two inferences
The spine (data not algorithm is the limit → human curation decisive → model effective once fed → living platform) is coherent and evidence-backed (five algorithms within R² 0.946–0.971; <15% processing coverage; the model-as-diagnostic feedback loop with the unit-convention example). Two load-bearing inferences are slightly exposed to the adversary:
- **"algorithms agree ⇒ data is the bottleneck" (L57)** skips one alternative: that feature engineering is strong enough to wash out algorithm differences. Add half a sentence ruling it in/out, e.g. "had the composition–temperature representation been weak, the algorithms would have diverged; their agreement points to the data, not the features, as the binding factor."
- **"curation … cannot yet be automated" (L59, conclusion)** is argued from experience, not proven. Soften to *was not automated here / why it is hard* ("the judgement of whether a stray value is a mislabelled unit, a real outlier, or a datum to drop is exactly what resisted automation in this project"). This is the single most editorialising line.

Strongest spots worth keeping front-and-centre: the <15% processing quantification, the feedback-loop unit-error example, and Table 7.1 (interpolation vs generalisation) — all concrete and examiner-proof.

## 3. OVERREACH — small softenings (keep the force, lose the exposure)
| file:line | issue | fix |
|---|---|---|
| discussion L57 | "the **conclusion** this thesis draws is that…" — uses the word the chapter must avoid + sweeping value claim | "the reading this work argues for is that…" (drop "conclusion"; content stays). Non-concluding structure otherwise holds (L13 + L120 defer the verdict). |
| conclusion (¶4) | "The limiting factor is the data, not the model." — absolute | "the **primary** limiting factor is the data rather than the choice of algorithm" (bounded, still strong). |
| discussion L118 + conclusion ¶5 | "living platform … released as the **first version** of exactly such a foundation" conflates aspiration with a code release | separate: keep platform as future direction ("would…"); say the dataset+model+cross-check are released as a *foundation for* such a platform. |
| LiBiO₂ (both chapters) | proof-of-concept framing | already honest — no change. |

## 4. ⚠️ CROSS-CHAPTER DRIFT — unify the conductivity span
Discussion now says "**more than ten** orders of magnitude" (L18, L109), but `dataset_results.tex` reportedly says "**roughly twelve** orders" (10⁻¹⁰–10²). Pick one wording and use it everywhere (discussion, dataset chapter, abstract if present). Recommend the precise "roughly twelve orders." This is a consistency flag an examiner would catch.

## 5. ⚠️ THE 3.2 LEVER — the theory-\Cref must actually deliver the literature survey it promises
The theory-only convention is fine **only if** the theory section the discussion points to contains the comparison. It currently over-promises:
- Discussion L52 cites "the **survey of prior data-driven screening** in `\Cref{subsec:literature_ml}`" — but that theory subsection is **generic ML-corpus literature** (Pereznieto2023, Li2024MLSSEReview, Ward2016, Pedregosa2011 on inter-lab noise / GroupKFold), **not** a survey of prior solid-electrolyte *screens*. `subsec:phonon_dos_predecessor` cites only Jaafreh2024.
- Criterion 3.2 (~20 pts) rewards situating results in the literature; a reader following that \Cref won't find the promised screen-survey.
- **Best fix (keeps operator's no-cites-in-discussion rule):** expand `subsec:literature_ml` in the theory chapter by 3–4 sentences to actually review prior SSE screens (e.g. Sendek2017EES + Jaafreh2024 as field context), so the \Cref delivers. **Alternative:** soften the L52 wording from "survey of prior data-driven screening" to match what the subsection really contains. **Judge's view (round 4):** restoring 1–2 field-comparison cites in the discussion would also work and lifts 3.2 — operator already leaned theory-only, so I list the theory-expansion as the convention-preserving option.

## 6. CONCLUSION — succeeds as a conclusion
Delivers a real verdict ("the primary limiting factor is the data…") + concrete recommendation (living literature→prediction→verification platform), macros throughout, honest caveats (interpolation-headline, n=3 indicative, LiBiO₂ proof-of-concept, validate-not-deploy), clean handoff to `\Cref{chap:future_work}`. Low redundancy with the discussion (discussion *argues* the reading; conclusion *delivers* the verdict + way forward). Optional amplifier: one concrete sentence on what the human judgement actually is (the unit/outlier example) to make "human-in-the-loop" tangible.

---

## Advocate verdict
The round-4 rewrite moves the discussion from "restates results" to "argues a defensible position," and the conclusion now concludes. Mechanics are clean. To bank a clean A on criteria 3.2/3.3: (a) tighten the two inferences in §2, (b) the small softenings in §3, (c) unify the conductivity-span wording (§4), and (d) make the theory-\Cref deliver the screen-survey it promises (§5) — this last is the highest-value item. None require new experiments or new numbers.

No guardrail issues: MP stays verification-only, no SHAP/OOD/conformal in the discussion, no fabricated numbers introduced.

— thesis-2 (advokat), ROUND 4. Standby for thesis-1.
