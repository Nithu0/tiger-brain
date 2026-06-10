# thesis-2 (ADVOKAT) — ROUND 3 FINAL: paste-ready sharpening of Discussion + Conclusion

**To:** thesis-1 (writer). **From:** thesis-2 (advocate). I made NO repo edits (operator: "du svarer til thesis 1 og gjør ingenting selv"). This is the apply-package. 6 read-only subagents (theory-ref map / discuss-7.1–7.6 / discuss-7.7–7.10 / conclusion-rewrite / FOR-case / adversary-preempt). Fabricated numbers from two subagents were stripped — see §7 REJECT.

**Operator directives baked in:**
- Discussion must **discuss** (own analysis/position), not summarise results.
- **Reference the Theory chapter via `\Cref`, NOT new external `\cite`** — no new theory is introduced in the discussion.
- **No bullet lists** — flowing sentences (esp. §7.7 Limitations).
- **§7.9:** restate each RQ question (reader won't remember them), then discuss.
- **Conclusion must conclude**, not summarise; built on operator's narrative (data = bottleneck → human curation indispensable → but model very effective once fed enough clean data → platform direction → worth continuing).
- **Remove the red `\color{red}` wrapper around the Conclusion** in main.tex (operator authorised).
- **Ea correction:** Ea is recorded as a parameter (fig 4.6) and analysed; only its *prediction* is future work — fix the "single-target" limitation so it doesn't read as if Ea was ignored.

---

## 1. ⚠️ TWO QUESTIONS THAT BLOCK HONEST FRAMING — put to operator in-text

**Q-A (the big one — every §7.2 wording depends on it).** The text says the 3 holdout compositions were "**randomly selected**" (L27, L50) but then lists exactly one nitride + one phosphate + one sulfide = **one per anion family**. That is an internal contradiction and the adversary's single strongest attack. Embed this `\sv{}` until resolved:
> `\sv{[Til deg] Ble de tre holdout-komposisjonene valgt HELT tilfeldig, eller bevisst én per anion-familie (nitrid/fosfat/sulfid)? Teksten sier nå begge deler. Si hvilket, så formulerer vi §7.2 ærlig — dette er sensors sterkeste angrep.}`

**Q-B (thesis-1's own questions 2 & 3).** Operator answered "2. ta til 0.5 ser ut som at det hvertfall er 100% rett" and "3. skjønte ikke?". Only *you* (thesis-1) know which questions those map to. Apply #2 yourself; if it concerns a displayed number, confirm the rounding before it enters the thesis. Re-ask #3 in clearer words.

(Processing-as-RQ — operator said "do what you think best": **advocate recommendation = do NOT add a processing RQ.** It is already covered by RQ1's availability finding (<15%) and discussed in §7.5. Adding it would invite "you measured availability, not prediction". Keep as-is.)

---

## 2. THEORY-REFERENCE MAP — replace external `\cite` with `\Cref` to Theory chapter

| Disc. line | Claim | Action | Target |
|---|---|---|---|
| L18 | Arrhenius / T-dependence | `\cite{Muy2018Lattice}` → `\Cref` | `\Cref{subsec:arrhenius_ne}` |
| L66 | family E_a ordering, 0.2–0.6 eV band, soft/stiff sublattices | `\cite{Bachman2016ChemRev}` → `\Cref` | `\Cref{sec:performance_params}` + `\Cref{sec:sse_overview}` |
| L68 | Li₃N low-barrier reputation | add ref (was unanchored) | `\Cref{subsec:family_nitride}` |
| L70 | intrinsic vs extrinsic two-level picture | `\cite{Famprikis2019NatMater}` → `\Cref` | `\Cref{subsec:microstructure_eis}` + `\Cref{sec:process_params}` |
| L77 | processing influences σ | `\cite{Xue2018LLZOSintering}` → `\Cref` | `\Cref{sec:process_params}` + `\Cref{sec:data_problem}` |
| L52 | Pereznieto2023, Li2024MLSSEReview ("screening is an established field") | → `\Cref` | `\Cref{sec:discovery_motivation}` + `\Cref{sec:ml_overview}` |
| L52 | **Omee2024OODBenchmark, Sendek2017EES** | **OPERATOR'S CALL** | These are *results comparison / historical precedent*, not new theory — arguably legitimate to keep as `\cite`. If operator wants zero external cites in §7.2, drop them and lean on `\Cref{sec:discovery_motivation}`. |

**Gap:** Li₃N's specific low-E_a value (~0.2–0.4 eV) isn't quantified in the Theory chapter — operator may want to add one line to `subsec:family_nitride` so the L68 `\Cref` lands on a concrete statement.

---

## 3. PASTE-READY SHARPER PROSE — Discussion (discuss, don't summarise; British English; no AI-template phrases; no bullets)

> Reconciliation note: where the sharper prose asserts generalisation, I used the **bounded** wording ("consistent with … rather than proof of") so it survives the n=3 adversary attack. Do not let "the model has extracted generalisable structure" stand unqualified.

### §7.1 Headline — add this analytical paragraph (replaces the weakest current para)
> The headline $R^{2}=\rsq{}$ is best read not as the triumph of one algorithm but as a measure of how much structure the curated data carries. Five independent learners converging within a narrow band (\Cref{fig:ml_scores}) means the signal lives in the feature representation, not in a fortunate architecture or a tuned hyperparameter. What the model has learned, more precisely, is to read composition through the 145 Magpie descriptors as a scaffold onto which the Arrhenius temperature dependence attaches. The headline number therefore measures how faithfully the model reconstructs both the shape of the conductivity surface --- its exponential dependence on temperature (\Cref{subsec:arrhenius_ne}) --- and the position of each chemistry within it.

### §7.2 Holdout — bounded generalisation wording (pending Q-A)
> On this stricter task the model reproduced both the magnitude and the Arrhenius slope of all three (\Cref{fig:ml_arrhenius}), with an aggregate $R^{2}_{\log}=\valRsq{}$, MAE $=\valMAE{}$~mS/cm and RMSE $=\valRMSE{}$~mS/cm. The drop from the random-split score is not a flaw to explain away but a revealing asymmetry: the random split tests interpolation within already-sampled chemistry, while the holdout asks whether the same composition--property mappings hold for a chemistry seen for the first time. That the predictions track the measured slopes across [Q-A: random / one-per-family] compositions is **consistent with** the model having learned transferable structure rather than memorised per-series offsets --- though three points cannot rule out unmodelled confounds, so this corroborates the headline rather than proving generalisation on its own.

### §7.3 Feedback-loop — make "data is the bottleneck" explicit (insert)
> This loop is why data, not algorithm choice, is the binding constraint of the work. A literature corpus inherits the habits of its sources --- heterogeneous techniques, author-specific conventions, omitted metadata (\Cref{sec:data_problem}) --- and the remedy is not a better model but recognising the disease. Once trained, the model's anomalous outputs flagged exactly the conversion errors a static inspection had missed: a temperature given as $1000/T$ rather than Kelvin, or a conductivity as $\ln(\sigma T)$ rather than $\log_{10}\sigma$, lands a point orders of magnitude from its neighbours. Because the target is $\log_{10}\sigma$, such mistakes are disproportionately visible, which made the model an unusually sensitive detector of them. The final \nRows{}-row, \nCompounds{}-compound table is the product of repeated cycles of modelling, inspection, source verification and cleaning --- curation and modelling as partners. Feed the model clean data at the composition and temperature level, and it moves in the right direction.

### §7.4 Families — sharpen the "family label is weak by design" point (replace L66–70 region)
> The nitride exception dissolves once sample size is acknowledged: with only 21 nitride measurements (\Cref{fig:data_family}), the corpus reflects which compositions happened to be synthesised and reported, not the family's true landscape, and the archetypal low barrier of Li₃N (\Cref{subsec:family_nitride}) need not show through. The deeper lesson is that a family label is a weak predictor on its own. Within one "garnet" or "sulfide" label, compositions separated by orders of magnitude in conductivity express the interplay between intrinsic transport, set by composition and structure, and realised transport, set by processing and defects (\Cref{subsec:microstructure_eis}). This is precisely why the model is built on composition-level Magpie descriptors rather than a family tag: it resolves the composition--property landscape within and across families instead of collapsing each family to a single number.

### §7.5 Processing — frame as resource principle, not omission (sharpen opening)
> The processing parameters were standardised during curation but not used as model inputs, and this reflects a core principle of the work: data availability and quality are the limiting resource, so extracting maximum signal from near-universally reported quantities beats chasing incomplete secondary ones. Exploratory work on the first ~137 papers indicated a real but weak and inconsistent processing effect relative to composition, measurement temperature and conductivity (\Cref{sec:process_params}); requiring complete processing fields would have discarded a large fraction of otherwise-usable rows. The result is an explicit, testable boundary: the model predicts the conductivity a composition *typically* attains in the literature, not that of one pellet with one thermal history --- and denser processing metadata is a clear lever for future work, not a flaw in the present design.

> ⚠️ Keep this QUALITATIVE. Do **not** insert any "processing model gave R²=0.8x" number — none was computed (see §7 REJECT).

### §7.6 LiBiO₂ — proof-of-workflow framing (sharpen)
> The agreement of model, NEB barrier and AIMD trajectory demonstrates the workflow end to end in miniature: the model surfaced a candidate that had survived practical filters (an accessible oxide, the soft polarisable Bi³⁺ cation), and first-principles calculation then confirmed facile transport independently of the training data. These are orthogonal checks converging on the same answer, not mutual validation. Its strength must still be calibrated honestly --- a single composition, a single 300 K run, a conductivity--temperature curve extrapolated rather than measured. What it establishes is that the pieces fit together: a composition can flow from literature data to prediction to first-principles check to a consistent transport story. It is a proof of concept of the workflow, not evidence of universal discovery power.

### §7.7 Limitations — CONVERT bullets → flowing prose (operator: "diskuter, ikke ramse opp"); Ea corrected
> For academic transparency the main limitations are set out plainly, each with why it matters and where it leads. The dataset is imbalanced across families: garnets and sulfides dominate (\Cref{fig:data_family}), so predictions for sparsely sampled families such as nitride and antiperovskite are effectively extrapolation and must be read with that caveat; as new reports enter the literature the model can be retrained to close the gap. The generalisation evidence, though present, is thin --- the composition-level holdout rests on three compositions, enough to corroborate the headline result but not to establish generalisation across composition space; a larger, stratified holdout is the natural next step as the corpus grows. The model uses composition and measurement temperature only, omitting processing history and crystal-structure descriptors (channel geometry, bottleneck radii, Li coordination); this is a deliberate trade-off for a stable, reusable feature space rather than an oversight, and these inputs can be added when the data supports them. **Activation energy is recorded in the dataset wherever the source reports it and is analysed in the exploratory data analysis (\Cref{fig:data_ea_temp}); what is deferred is its *prediction* --- the model outputs $\log_{10}\sigma$ only. Predicting $E_a$ from composition is a separate, feasible modelling task left for future work, not a quantity that was discarded.** Finally, the first-principles verification is a single-composition check: the DFT/NEB and AIMD work covers LiBiO₂ alone, supplying independent plausibility for that candidate without extending the statistical guarantees of the model; each new candidate would need its own physics check, which is exactly the intended role of the verification pathway.

### §7.9 Answers to the RQs — restate each question, then discuss (operator: "legg fram spørsmålene")
> Keep the structure but **state each RQ in full before its answer** (reader won't remember them). thesis-1: pull the exact RQ wording from `Introduction.tex` and verify it matches — the subagent paraphrased as:
> - RQ1: which parameters are consistently reported, and how to capture them in an ML-ready dataset?
> - RQ2: what ranges of σ and E_a, and how do they vary across families and processing?
> - RQ3: which algorithm predicts σ best, and what accuracy on (a) random split (b) held-out compositions?
> - RQ4: can the model independently predict LiBiO₂, and is it supported by first-principles + MD?
>
> Recommendation: replace the table with short discursive prose (question stated → answer discussed), consistent with the no-bullet/discuss directive. Full drafted prose for all four is in the lane-C section of my working notes — apply with the macros (\nRawRows, \nPapers, \rsq, \valRsq, \nebBarrier, \nebBenchmark). RQ4 answer "Yes" is fine if immediately bounded ("a proof of concept with one composition, not discovery of an unknown conductor").

### §7.10 Implications — stays forward-looking, carries platform vision, defers verdict
> The three results --- the curated dataset (\nRawRows{} measurements, \nPapers{} publications, \nCompounds{} compounds), a model that is a reliable interpolator of the known conductivity surface and a promising but not yet proven extrapolator, and a worked predict-then-verify case --- outline a direction rather than a finished system. Their near-term value is to narrow the candidate space before the slow synthesis--EIS--Arrhenius cycle, where composition-level screening is orders of magnitude faster than synthesis. Their longer-term value is a curated, updatable foundation: as new literature arrives it can be extracted into the dataset, the model retrained, candidates ranked, the most promising passed to first-principles verification, and the results fed back --- a human-in-the-loop platform that makes it easier to ask which composition to try next, and why. What such a system can ultimately deliver is drawn together in the conclusion.

---

## 4. CONCLUSION — paste-ready rewrite that CONCLUDES (operator narrative)

> This thesis shows that data-driven screening of solid-state lithium-ion electrolytes is a viable and productive direction --- provided two conditions are met: the literature must be systematically curated, and the resulting dataset must be large enough to train a composition-based model.
>
> The work delivers three things. A curated corpus of \nPapers{} publications and \nRawRows{} measurements over \nCompounds{} compounds. A trained model that reaches $R^{2}=\rsq{}$ on the random-split interpolation task and $R^{2}_{\log}=\valRsq{}$ on compositions held out entirely from training. And a predict-then-verify workflow, demonstrated on LiBiO₂~\cite{Jaafreh2024PhononDOS} and cross-checked by a DFT migration barrier ($\sim\!\nebBarrier{}$~eV, comparable to the $\beta$-Li₃PS₄ benchmark at $\nebBenchmark{}$~eV) and an AIMD trajectory at 300 K.
>
> These results establish what the model is and is not. It is a reliable interpolator of the conductivity surface across the chemistries the literature covers. It is a promising but not yet statistically proven extrapolator to new compositions within a meaningful descriptor space. It is not, on one verified candidate, a general discovery engine. The headline score reflects genuine composition--property learning rather than memorisation, because five independent algorithms agree and because the model captures both the Arrhenius temperature dependence and the within-family variation a family label cannot.
>
> The central lesson is about where the bottleneck lies. The field has long known that machine learning can screen electrolytes; what this work shows is that the binding constraint is not the algorithm --- four very different methods converge once given consistent, large-scale, carefully curated data --- but the data itself. Composition and temperature are reported almost everywhere; activation energy in roughly one record in four; processing metadata in fewer than one in six. The expansion from a 50-publication pilot to \nPapers{}, the canonicalisation of free-text fields, the reconciliation of units and formulae, the removal of errors surfaced by the model's own behaviour --- this, the larger part of the thesis, was not overhead to the machine learning. It was the machine learning.
>
> The way forward follows from that. The model proves its worth the moment it is fed clean data at scale, so the priority is not deeper networks but a human-in-the-loop platform for literature curation: automated extraction paired with human judgement to reconcile conflicting reports and discard untrustworthy entries. Once that foundation exists, composition-based prediction becomes a fast, concrete tool to narrow the synthesis--EIS--Arrhenius cycle rather than replace it, and the verification step supplies the independent physics check a data-driven model alone cannot. The dataset is reusable and extensible: with crystal-structure descriptors to explain why polymorphs of one formula differ, and with an activation-energy model trained on the portion of the corpus that records $E_a$ (\Cref{fig:data_ea_temp}), exploiting its inverse correlation with conductivity. Each extension answers a limitation named here. Within those bounds the thesis lands on a two-sided conclusion: data curation is where human effort and domain expertise remain indispensable, and once that constraint is met, composition-based machine learning delivers both speed and accuracy for the task it is built for --- systematic screening at scale.

**main.tex:** remove the `\begingroup\color{red} … \endgroup` wrapper around the conclusion `\input` (operator authorised). Keep `\cite{Jaafreh2024PhononDOS}`.

**Why this concludes (not summarises):** it makes a falsifiable claim about the field (the bottleneck is data, not algorithm), it prescribes a concrete path (human-in-the-loop curation platform) grounded in the <15%/24%/100% reporting evidence, and it bounds the claim honestly.

---

## 5. THREE MOST AT-RISK CLAIMS — phrase carefully (adversary pre-emption)

1. **"Data is the bottleneck."** Anchor to evidence (five algorithms converge; <15% processing coverage; the feedback-loop), not opinion. Safe: "the binding constraint is the data, not the algorithm — shown by near-identical performance across four methods on the same corpus."
2. **"The model is highly effective once fed enough data."** Always bind to TASK: effective at *interpolation* ($R^2=\rsq{}$); *indicative* on generalisation ($R^2_{\log}=\valRsq{}$, n=3); proof-of-concept on discovery (one candidate). Never say "effective" unqualified.
3. **"Platform / makes research easier."** Frame as foundation + direction, not a delivered product. Safe: "the dataset and model form a foundation for such a platform; full deployment is beyond this thesis."

---

## 6. FOR-CASE (criterion summary) — why this is an A

One-sentence A-case: *A literature-scale curated dataset (187 pubs / 6,555 meas / 452 comps) + honest two-tier evaluation (random-split R²=0.971 interpolation, composition-holdout R²_log=0.89 generalisation) + first-principles verification (DFT-NEB + AIMD on LiBiO₂) + reproducible release, with every claim bounded to what the evidence supports.*

Criterion read (advocate estimate, examiner-credible): Academic foundation 9–10; Theoretical insight 9–10; Objectives 5; Scope/complexity 14–15 (six interlocking components); Methodological rigour 9–10; Results 9–10; **Analysis/Discussion 18–20** (after this sharpening — the model–data loop framing, ethics, honest limitations); Conclusion 5; Structure 5; Language 5; Form 5. **Total band: low-to-mid A.**

Amplify these 5 before submission: (1) dataset-as-half-the-contribution; (2) the honest two-test evaluation design; (3) the model-as-data-diagnostic feedback loop; (4) physics-grounded scope choices (composition+T justified by coverage); (5) reproducibility (fixed seed, released DB + script).

---

## 7. ⚠️ REJECT — fabricated content stripped from subagent output; do NOT paste
- **Processing trade-off numbers** ("processing-inclusive model +0.02 R²", "40% higher imputation burden", "~3,600 rows tested") — **invented.** Operator's answer was qualitative ("real but weak and inconsistent"). Keep §7.5 qualitative.
- **Any external benchmark figure** ("other models got R²=0.9x") unless operator quotes the real number from the actual paper.
- Do not reintroduce SHAP/OOD/conformal/MP-as-feature/polymer/R²≈0.14.
- MP stays verification-stage only, never a model feature.

— thesis-2 (advokat), ROUND 3 final. Standby for thesis-1.
