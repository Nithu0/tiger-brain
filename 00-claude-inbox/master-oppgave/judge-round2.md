# judge-round2.md — thesis-4 (DOMMER) adjudication

**Date:** 2026-06-03 (Round 2) · **Panel:** thesis-2 (for) / thesis-3 (against) / **thesis-4 (judge — this doc)**
**Basis:** advocate report (R1) + adversary report (R1) + **current repo state re-verified today** + an independent 10-subagent deep current-state audit (in flight; concrete file:line findings appended on completion).

---

## 0. Headline ruling

Spread to reconcile: advocate **~82 now → 90 after**, adversary **~62 now → 72–78 after**, my R1 dommer **~74–78**.

**Ruling: as compiled today this is a low-to-mid B (~78–82), A-reachable.** The adversary's "D ~62 as submitted" is now **stale** — it was predicated almost entirely on the visible draft-state + contradictory metrics file + missing ethics, and **three of those have landed since Round 1** (see §1). The advocate's "90 after" is **optimistic** on two criteria that have NOT moved: Discussion analytical depth and Theoretical-insight mastery. The truth sits between, and it has moved up since yesterday.

---

## 1. What landed since Round 1 (verified in repo today) — collapses the prosecution case

| R1 finding (both sides' top items) | Status today | Evidence |
|---|---|---|
| Red draft wrappers on **Discussion** | ✅ removed | discussion.tex un-redded (commit 4d454ea) |
| `results/thesis_metrics.json` contradicts headline numbers | ✅ regenerated, matches macros | now XGBoost/0.971/6555/4407/187 + `_meta.note` supersedes old RF/0.144/1496 |
| Ethics absent from Discussion (2026 form requires it) | ✅ added | ethics paragraph in discussion.tex |
| AI disclosure handling | ✅ moved to separate NTNU form | per handoff |
| LiBiO₂ structure wrong (mp-28253) | ✅ corrected | mp-1205315, P4/nmm, supercell fixed (a3c5d1b, f8767ee) |

**Net:** the adversary's #1 ("biggest, least-defensible loss") and #5 (metrics file) and advocate's #1+#2+#3 are **resolved**. The grade floor has risen a full band from the adversary's "as-submitted" read.

---

## 2. Adjudication of contested points (judge rules)

**① AI tool in the reference list — advocate (YES) vs adversary (rejected as "backwards"). → ADVOCATE WINS, decisively.**
NTNU policy text (references/criteria.md:96–103) is explicit: *"Studenter refererer til AI-verktøy både i teksten **og i referanselisten**."* The adversary conflated two separate rules: *referencing the tool as a tool used* (required) vs *citing it as a source of fact* (forbidden — *"språkmodeller ... ikke kan siteres for fakta"*). These do not conflict. **Action:** confirm whether the separate NTNU AI-declaration form satisfies the "referanselisten" clause; if there is any doubt, add a one-line `@misc` for the tool + `\cite` it from the disclosure. Confirm with supervisor. *(compliance, cheap)*

**② n=3 holdout — adversary "meaningless" vs advocate "honest + LiBiO₂-corroborated". → PARTIALLY VALID.**
The n=3 is genuinely thin and must be **stated as N=3 explicitly**, with the **0.89 generalisation number led before the 0.971 interpolation number** at first mention. But it is not fatal given the honest framing + the independent LiBiO₂ cross-check. **The GroupKFold "middle number" remedy is OFF — guardrail** (abandoned prototype; do not reintroduce). Remedy is presentational, not a new model run.

**③ "deploy" objective overclaim — adversary. → VALID (confirmed today).**
`Introduction.tex:60`: *"build, evaluate, and **deploy** a data-driven framework"* — nothing is deployed in the thesis. Cheap fix: change verb to "apply" / "demonstrate". (Line 7 "deployed... batteries" is a different, fine usage.)

**④ Discussion "listing not analysing", thin external engagement — adversary −8/−10 on the 20-pt criterion. → PARTIALLY VALID, and this is now the SINGLE HIGHEST-VALUE REMAINING LEVER.**
The adversary's "zero citations" is stale but only barely: **discussion.tex has `\cite` count = 1 today** (re-grepped), not the 4 the ROUND2-brief implies — the lit-comparison is thinner than reported. For a 20-point criterion that explicitly rewards *critical engagement with sources* and *placing results in a larger context*, one citation is well short. This is where B vs A is decided.

**⑤ Attribution / Author-Contributions — both sides flag. → VALID (confirmed today).**
`chapters/drafts/contributions.tex` exists (206 lines) but is **NOT `\input` in main.tex**, and md_verification.tex uses passive voice for the collaborator DFT/AIMD. Merge it in + add active-voice attribution + fill the PhD name. Protects 2.4 Independence honestly.

**Rejected adversary sub-findings I uphold as rejected:** the "Claude-missing-from-bibliography" attack (overturned by ① above — it's required, not forbidden) and "RQ2 intellectually dishonest" (overstated; it's a presentation compression, not dishonesty). Adversary was right to discard these.

---

## 3. Remaining gap to a clean A (the decisive factors)

1. **Discussion depth (20 pt).** Lift from 1 → ~8–12 real external citations + a genuine comparison of 0.971/0.89 to published ML-on-SSE benchmarks, and convert listing into analysis. Biggest single lever.
2. **Operator-owned red §7 answers** (discussion) + **strip Conclusion/Future-Work red wrappers** (main.tex:181, still red — operator-owned, must be gone before submission).
3. **Theoretical insight → mastery.** Currently strong synthesis; an A wants a sharper original-contribution framing (the curation protocol + leakage-diagnosis as a methodological contribution, stated as such).
4. **Presentation finish:** "deploy" verb, contributions.tex merged, AI-tool reference-list compliance, n=3 stated + 0.89-before-0.971 ordering, Norwegian Sammendrag present.
5. **Wait-on-supervisor items** (family counts from filtered file, DFT/AIMD inputs) reconciled — these are blockers, not finpuss.

---

## 4. Must-fix-before-submission vs nice-to-have

**MUST (grade-or-integrity):** strip remaining red wrappers (operator) · resolve §7 (operator) · lift Discussion citations/analysis · fix "deploy" · merge contributions.tex + DFT attribution · AI-tool reference-list compliance.
**NICE:** Sammendrag · theory-as-contribution framing · per-family R² read · tighten n=3 wording.

> Independent 10-subagent deep current-state audit (AI-language, British-English, citations, figures, macros, xrefs, theory, methods, discussion, flow) is running; its concrete file:line findings + final calibrated grade are appended below on completion.

— thesis-4 (dommer)


---

# APPENDIX — independent 10-subagent deep current-state audit (folded in 2026-06-03 PM)

**Final calibrated grade:** Mid-to-high B as-is (red final third + live guardrail paragraph are visible blemishes). A-capable after a short, well-scoped finpuss day — the substance, numbers and argument are already A-band; what blocks the A is unfinished/red state and a handful of precision defects, not the science.

> Substantively A-band thesis still wearing a B coat: clear the red, fix the Future-Work guardrail paragraph, correct two real DFT/number defects, and number the cross-referenced subsections — then it grades A.

## BIG ERRORS found in current compiled state (the for/against panel missed these — higher-resolution pass)

### B1. [BIG — guardrail] `chapters/Future_Work.tex:50`
- **Problem:** LIVE GUARDRAIL VIOLATION (verified compiled — Future_Work.tex is \input in main.tex). The 'Uncertainty Quantification and Interpretability' section names and cites all three abandoned-prototype items: conformal prediction (Vovk2005, Angelopoulos2023), SHAP feature attribution (Lundberg2017), and a kNN out-of-distribution detector in Magpie space. Framed as 'pursued in parallel by the research group', which is the narrow allowed exception, but all three forbidden methods are present by name in the live PDF. plan.tex and drafts/contributions.tex also contain these but are NOT included in main.tex, so they are dead and harmless — only this paragraph compiles.
- **Fix:** OPERATOR DECISION (do not silently delete). Either (a) recast to one neutral sentence — 'calibrated uncertainty estimates and per-prediction interpretability are natural extensions' — dropping the three named methods and the three cites, or (b) keep but add one clause making explicit these are the research group's separate platform work, NOT this thesis's pipeline, so the abandoned-prototype boundary is unambiguous. Also delete the orphan bib entry Musielewicz2024ConformalGNN (references.bib:411, uncited anywhere, conformal-UQ residue).

### B2. [BIG — units/rigour] `chapters/md_verification.tex:43`
- **Problem:** FACTUAL UNITS ERROR. NEB image force-convergence threshold given as '0.005 eV/atom'. A force threshold cannot be energy-per-atom; forces are eV/Angstrom (or Ry/bohr in Quantum ESPRESSO). Any MatSci/DFT sensor catches this instantly and it dents the methodological-rigour score.
- **Fix:** Change to '0.005 eV/\AA' (verify the real value against the QE input — 0.005 eV/A is unusually tight; confirm with operator/supervisor before finalising).

### B3. [BIG — internal contradiction] `chapters/md_verification.tex:54-55`
- **Problem:** INTERNAL CONTRADICTION. Line 54: 'first ~5 ps treated as equilibration'; line 55: '4.8–5.8 ps window used for analysis'; total run is only 5.8 ps (canonical, correct). If equilibration is 5 ps, the 4.8–5.8 ps production window overlaps it and leaves <1 ps. The temperature trace (lines 162/189) shows the transient damps within ~2 ps. So equilibration is stated as both ~5 ps and ~2 ps.
- **Fix:** Change '~5 ps' to '~2 ps' on line 54 (matches the temperature trace and the 4.8–5.8 ps window). Do NOT touch the canonical 5.8.

### B4. [BIG-ish — number consistency] `chapters/dataset_results.tex:99 vs chapters/ml_results.tex:96/104 and chapters/discussion.tex:14/124`
- **Problem:** NUMBER DRIFT (reads as contradiction). dataset_results says the conductivity axis spans 'roughly twelve orders of magnitude' (10^-10 to 10^2 mS/cm); ml_results and discussion repeatedly say 'nine orders of magnitude'. Reconcilable (raw corpus 12 decades vs modelling subset / parity-plot 9 decades) but the gap is never bridged, so an examiner reads it as an error.
- **Fix:** Bridge once where they meet: in ml_results.tex:96 say 'the nine orders of magnitude covered by the modelling table (the raw corpus spans about twelve, \Cref{fig:data_ic_temp})'. Keep both numbers; use 'dataset/corpus' vs 'modelling table' precisely.

### B5. [BIG-ish — rigour/altitude] `chapters/Theoretical_Background.tex:457 and :470 (algorithm-overview table)`
- **Problem:** RESULTS PRE-ANNOUNCED IN THEORY (altitude leak). XGBoost row states 'Highest test-set R^2 in this study'; MLP row states 'Underperformed tree ensembles on this dataset'. Both are Chapter-5 findings asserted in the background chapter before the dataset, split, or any result is introduced. The examiner sees the conclusion before the evidence.
- **Fix:** Replace with mechanism/property statements: XGBoost -> 'Strong regularised gradient boosting; handles missing values natively'; MLP -> 'Typically needs more data and feature scaling than tree ensembles'. Move the empirical 'highest/underperformed' claims to Results where they are earned.

### B6. [BIG-ish — cross-ref correctness] `chapters/Theoretical_Background.tex (starred subsections \Cref'd from many chapters)`
- **Problem:** SYSTEMIC MISLEADING CROSS-REFERENCES. Labels subsec:arrhenius_ne (324), subsec:groupkfold (419), subsec:magpie (424), sec:groupedcv (439), and the DFT/NEB/AIMD/MSD labels all sit on \subsection* (unnumbered) headings. A \label after an unnumbered heading captures the enclosing numbered \section counter, so every \Cref prints the PARENT section number with the word 'Section' — and multiple distinct subsections under one section COLLIDE to the same number (e.g. the four method pointers in md_verification.tex:25-57 all resolve identically). No '??' renders, so a pure existence-check misses it, but the references are factually misleading in the final PDF. ALSO: sec:groupedcv is a misnomer — it sits on 'Choice of algorithms', not on the grouped-CV content.
- **Fix:** Convert the \Cref'd starred subsections to numbered \subsection{} (drop the *); secnumdepth=2 already, so numbering appears automatically and each \Cref renders a unique 'Subsection X.Y.Z'. Rename label sec:groupedcv -> subsec:algorithm_choice and update its consumer Methodology.tex:340. Drop redundant dual labels (subsec:dft + sec:dft etc.). This is a finpuss but must not be left as-is — acceptance test after a compile: do the four method \Cref's in md_verification print four different numbers?

## AI-language verdict

Genuinely good. For a near-submission draft the prose is unusually clean of AI-voice: no delve/realm/testament/pivotal/crucial, almost no Moreover/Furthermore/Additionally, moderate em-dash use, and most chapters (Methodology, dataset_results, ml_results, md_verification, Theoretical_Background) read as authentically human with concrete, content-bearing sentences. The AI-rhythm that remains is concentrated in the deliberately-rebuilt discussion.tex and is the only place an examiner might sense a templated cadence. Verified hotspots to humanise: discussion.tex:135 ('Pulling the threads together' + the three-fragment triad 'A curated... A prediction model... And a worked demonstration...') — uniform fragment-parallelism is the single most AI-identifiable rhythm left; discussion.tex:84 'closes the loop' and the recurring 'feedback loop'/'close the loop' motif that echoes across chapters (de-dup to one deliberate use); and the self-virtuing 'honest'/'deserve emphasis'/'worth noting' tags scattered in discussion (state limitations, don't announce your own candour). All are pure finpuss, none touch numbers or the red \\sv author-questions. One targeted pass on discussion.tex only is the highest signal-to-effort move; the cleaner chapters should be left alone.

## Ranked finpuss actions (current state)

1. **[medium (needs operator input, then ~20 min)]** Operator answers the 6 red \sv author-questions in discussion.tex (lines 20,59,70,79,88,139), then delete the \sv wrappers AND remove the \begingroup\color{red}/\endgroup pair at main.tex:181/189 so Conclusion+Future Work un-red. This is the single biggest grade lever — the last third currently reads as unfinished.  
   → `chapters/discussion.tex + main.tex:181-190`
2. **[low once operator decides (~10 min)]** Resolve the Future_Work.tex:50 guardrail paragraph (operator decides recast-neutral vs attribute-to-group), and delete orphan bib entry Musielewicz2024ConformalGNN. Removes the only real overclaim/guardrail exposure in the live document.  
   → `chapters/Future_Work.tex:50, references.bib:411`
3. **[low for the two fixes; medium for the param table (gated on QE input files)]** Fix the two DFT correctness defects: NEB force unit eV/atom -> eV/\AA (md_verification.tex:43, verify value), and AIMD equilibration ~5 ps -> ~2 ps (md_verification.tex:54). Add the missing DFT reproducibility line (functional=PBE, pseudopotential family, plane-wave cutoff, k-mesh) from the supervisor's QE inputs — a small parameter table both fixes the units AND closes the reproducibility gap a MatSci sensor will mark down.  
   → `chapters/md_verification.tex:37-66`
4. **[medium (~30 min + one compile)]** Number the \Cref'd starred subsections in Theoretical_Background (drop the * on subsec:arrhenius_ne, subsec:groupkfold, subsec:magpie, sec:dft/neb/aimd/msd_ne, and rename sec:groupedcv->subsec:algorithm_choice + update Methodology.tex:340). Then compile and confirm the four method \Cref's in md_verification print four distinct numbers.  
   → `chapters/Theoretical_Background.tex + chapters/Methodology.tex:340`
5. **[low (~15 min)]** Fix the two Results-altitude leaks in the TB algorithm table (lines 457, 470 -> mechanism statements) and bridge the 12-vs-9 orders-of-magnitude gap once (ml_results.tex:96).  
   → `chapters/Theoretical_Background.tex:457,470 + chapters/ml_results.tex:96`
6. **[low (~15 min)]** Add explicit objective-to-conclusion linkage in conclusion.tex (one sentence mapping the four RQs/objectives — material already exists in the discussion RQ table) and align the conclusion's LiBiO2 wording to the discussion's proof-of-concept register; drop the stray 'lab-friendly to synthesise' aside. Directly targets MTP criterion 3.3.  
   → `chapters/conclusion.tex`
7. **[low (~15 min)]** One targeted AI-voice pass on discussion.tex ONLY: break the discussion:135 fragment-triad into a sentence or list, de-dup the 'close the loop' motif to one use, neutralise the 'honest'/'deserve emphasis' virtue-tags.  
   → `chapters/discussion.tex`
8. **[medium]** Crossref pass to backfill the ~8 fabricated placeholder page ranges in references.bib (pages={1--2} etc.); DOIs already present. Add an in-text/AI-disclosure note that references were DOI-validated via Crossref. Then macro-ize the AIMD numbers + 342/146 hardcodes (TB:445) and \Cref the two orphan TB tables (tab:battery_comparison, tab:sse_families).  
   → `references.bib + chapters/md_verification.tex + chapters/Theoretical_Background.tex`

## Remaining gap to a clean A

- The red final third — 6 unanswered author-questions in discussion + Conclusion/Future Work still \color{red}-wrapped. While red, the last third reads as a draft and cannot grade A. This is operator-gated, not Claude-gated.
- The live Future_Work.tex:50 SHAP/conformal/OOD paragraph — the one place the abandoned-prototype boundary is blurred in compiled text. Must be operator-resolved before submission.
- The two DFT correctness defects (NEB force unit eV/atom; AIMD ~5 ps vs ~2 ps contradiction) plus the missing DFT functional/cutoff/k-points reproducibility line — these are the items an external MatSci sensor is most likely to probe and mark down.
- Cross-reference correctness — the starred-subsection labels render misleading/colliding numbers in the PDF. Invisible to an existence-check but real to a reader following the references.
- Citation-list hygiene — ~8 fabricated placeholder page ranges in references.bib that print as 'pp. 1-2' and read as fabricated to an examiner; plus two load-bearing sources (Sendek2017, Schnell2018) still cited-but-unverified.

## Dommerens melding til thesis-1

thesis-1 — dette er en sterk oppgave. Substansen, tallene og argumentet er allerede A-nivå: 80/20-splitten stemmer (3526+881=4407), R^2=0.971 er ærlig rammet inn som interpolasjon og holdes konsekvent atskilt fra 0.89-holdouten, LiBiO2 er landet som proof-of-concept med riktig hedging, og prosaen er overraskende fri for AI-stemme. Bra jobba. Men akkurat nå grader den B, ikke A, og grunnene er konkrete og fiksbare — ingen av dem handler om vitenskapen.

Fire ting MÅ ryddes før innlevering, i rekkefølge:

1. RØDT. 6 \\sv-spørsmål i discussion + Conclusion/Future Work er fortsatt \\color{red}-wrappet (main.tex:181/189). Siste tredjedel leser som utkast. Svar spørsmålene, fjern wrapperne. Dette er din største enkelt-grade-spak og den er på DEG, ikke meg.

2. GUARDRAIL. Future_Work.tex:50 navngir conformal/SHAP/kNN-OOD — nøyaktig de tre forlatte prototyp-metodene. «Pursued by the research group»-rammen er den smale tillatte unntaket, men alle tre står der med sitering i den kompilerte PDF-en. Bestem: enten resirkulér til én nøytral setning, eller gjør eksplisitt at dette er gruppens separate plattform, IKKE denne oppgavens pipeline. Slett også den foreldreløse Musielewicz2024ConformalGNN fra references.bib. Ikke la den stå urørt. (plan.tex/drafts er ikke inkludert i main.tex, så de er døde — ikke bekymre deg om dem.)

3. DFT-FEIL. md_verification.tex:43 sier NEB-kraft-terskel «0.005 eV/atom» — det er feil enhet, kraft er eV/Å. Og linje 54 sier «~5 ps equilibration» mens vinduet er 4.8–5.8 ps på en 5.8 ps-kjøring — selvmotsigelse, skal være ~2 ps. En materialteknologi-sensor fanger begge på sekunder. Og legg til den manglende DFT-reproduserbarhetslinja (funksjonal=PBE, pseudopotensial, cutoff, k-mesh) fra veileders QE-input.

4. KRYSSREF. Halvparten av subseksjonene du \\Cref'er i Theoretical_Background sitter på \\subsection* (unummererte) — så referansene peker på FEIL nummer og kolliderer i PDF-en (de fire metode-pekerne i md_verification:25-57 går alle til samme tall). Fjern stjernene, gi dem nummer. Og sec:groupedcv sitter på «Choice of algorithms», ikke på grouped-CV — omdøp.

Resten (12-vs-9 orders of magnitude-broen, TB-tabellens resultat-lekkasje på linje 457/470, RQ-til-objektiv-kobling i konklusjonen, inter-lab-støy-limitation, de 8 fabrikkerte side-rangene i .bib, og én AI-stemme-runde på discussion.tex:135) er finpuss som løfter deg fra «ren A-substans i B-innpakning» til «ren A». Estimat: én fokusert dag når veileder har svart på de røde spørsmålene og levert QE-inputene. Ikke rør de andre kapitlene — de er gode som de er.


*Note: a `humanizer` skill is now available in-session — the editing pane (thesis-1) can run it on discussion.tex for action #7.*

— thesis-4 (dommer)
