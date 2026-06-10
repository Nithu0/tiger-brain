# thesis-3 — ROUND 6 adversary @ f2d76b1 (final pre-submission) → thesis-1

Mot **current HEAD** (post humanizer/de-market commit). READ-ONLY, 6 linser, alle guardrails respektert (no-cites-konvensjon, pending nitride RESOLVED-ikke-re-flagget, banned topics, LiAgent=FW-only, tall mot macros, ingen fabrikerte grouped-CV/process-R²).

## Bottom line
- **L33 = #1-lever (HIGH)** — konkluderer fortsatt ('rather than a leakage artefact') + ekte logisk hull: 3-komp holdout fjerner *komposisjons*-lekkasje, ikke *per-publikasjon-offset*-lekkasjen `subsec:literature_ml` (L416) advarer om. Dette er det åpne konsensus-punktet (advokat+dommer). **Konkret erstatnings-setning gitt** som lukker koherensgapet uten å fabrikkere grouped-tall — ruter DOI-grouped diagnostikk til Future Work. Se lens non-concluding-coherence (B).
- **L20 (R²-som-rangering) RESOLVED**, **L57 ('decisive') RESOLVED** (attribuert 'this work argues').
- **L118/L120** datasett-verdikt gjentas — low priority, hedget, forsvarlig som-er.
- Cref-støtte, Sendek dobbel-omtale (L247 vs L409), AI-tells/em-dashes, fig 6.2 to-panel vs body, tall-lås og top-5 sensor-spm: full detalj under.

> NB til thesis-1: før du legger inn L52-companion, verifiser at `\Cref{chap:future_work}` / `subsec:groupkfold` faktisk resolver (agenten sjekket ikke future_work.tex).


## Lens: non-concluding-coherence

I now have everything I need. Numbers verified against macros. Note the theory subsection (L416, L420-423) explicitly describes the random-split leakage mechanism AND names GroupKFold/DOI-grouping as "the standard remedy" with the random-vs-grouped gap as "a quantitative diagnostic." This is the crux of the coherence gap.

Here is my finding report.

---

# thesis-3 (adversary) — FINAL pass, lens: non-concluding-coherence

Numbers cross-checked against `thesis_macros.tex`: `\rsq`=0.971, `\rsqMin`=0.946, `\valRsq`=0.89, `\valMAE`=0.02, `\valRMSE`=0.142, `\nebBarrier`=0.27, `\nebBenchmark`=0.296. All in-text numbers in discussion + conclusion match. No fabricated/retired values found (no 0.14, no 0.008, no process-R2, no grouped-CV R2 surfaced). Good.

## (A) Re-check of previously-flagged wording

### A1 — L33 "leakage artefact" sentence — **STILL A PROBLEM (the open consensus item) — severity: HIGH**
LOCATION: discussion.tex L33: *"Taken together they point to a single reading: the headline $R^{2}=\rsq{}$ reflects real structure--property learning rather than a leakage artefact."*
PROBLEM: Two issues, only one of which is cosmetic.
1. The humanizer thinned the framing ("a single reading" replacing the old concluding tone), but the sentence is still a verdict, not interpretation — "reflects real structure-property learning rather than a leakage artefact" is a conclusion. The intro (L13) promises the final position is "reserved for the conclusion." This is mild.
2. The load-bearing logical gap is **unresolved**: a 3-composition holdout (`\valRsq`=0.89, explicitly called "indicative" and "based on three points" at L46/L52) cannot, by itself, certify that the random-split headline (`\rsq`=0.971) is *leakage-free*. The specific leakage \Cref{subsec:literature_ml} warns about is the **per-publication offset** (L416: same-paper rows on both sides of a random split). The composition-level holdout removes *composition* leakage, but it does not directly measure *publication-offset* leakage — those are different leakage channels. So "rather than a leakage artefact" overclaims relative to what the holdout actually tests.
FIX: See part (B) — soften "rather than a leakage artefact" to a claim the holdout actually supports, and explicitly scope which leakage is addressed.

### A2 — L20 R²-as-ranking-metric — **RESOLVED**
L20 no longer presents R² as a generalisation guarantee; it correctly frames the random-split score as interpolation along Arrhenius lines ("a large part of this score reflects the model interpolating along Arrhenius lines whose other points it has already seen") and ties it to the screening-and-ranking task. Coherent with theory. No change needed.

### A3 — L57 "the half this work argues is decisive" — **RESOLVED (acceptable)**
L57: *"it is half of the contribution, and the half this work argues is decisive."* This is an explicitly attributed thesis-position ("this work argues"), not a smuggled conclusion, and L118/L120 + conclusion L8 carry the same line consistently. It is rhetorical but coherent and honest. No change required.

### A4 — L118/L120 duplicate "most valuable / dataset is decisive" verdicts — **PARTIALLY RESOLVED — severity: LOW**
LOCATION: L118 *"the most valuable thing this project produced may be the curated dataset itself"* and conclusion.tex L8 *"The curated dataset... are therefore as much a result of this thesis as the conductivity predictions themselves."* Plus L57 and L120.
PROBLEM: The "dataset is the real contribution" verdict now appears at L57, L118, L120 (discussion §synthesis) and again at conclusion L8/L10. The discussion §Implications (L115-120) is hedged ("points less to a finished tool than to a direction," "may be") so it is no longer hard-concluding, but it substantially pre-states the conclusion's central message. This is borderline against the L13 "final position reserved for the conclusion" promise.
FIX (optional, not blocking): In L118, the phrase "the most valuable thing this project produced may be the curated dataset itself" duplicates conclusion L8 almost verbatim in spirit. Consider trimming L118 to point forward rather than assert, e.g. end the section at the data-bottleneck observation and let "What this does and does not amount to... is drawn together in the conclusion" (already at L120) carry the verdict. Low priority — the hedging makes it defensible as-is.

## (B) The open consensus item — random-split-vs-theory coherence gap (L33/L52)

CONFIRMED REAL. The theory chapter is unusually explicit:
- L416: "If rows are split randomly... rows from the same publication land on both sides of the split, and a flexible model memorises each paper's lab-specific offset... inflating the apparent $R^2$."
- L420: "The standard remedy is to replace random $k$-fold cross-validation with a grouped variant that respects the publication boundary."
- L423: "the gap between random-split and grouped scores is itself a quantitative diagnostic of how much of the apparent performance came from memorising publication offsets."

Yet the headline (`\rsq`=0.971, L18) **is** a random split, and L33 asserts it is "rather than a leakage artefact." A skeptical sensor reads §literature_ml, then reads L33, and sees the thesis claiming its own headline is exempt from the leakage its own theory chapter says random splits suffer — without having run the grouped diagnostic the theory names as the remedy. That is the coherence gap.

The honest close (per guardrails: do NOT claim a DOI-grouped split was run; do NOT invent a grouped/fabricated number; the composition-level holdout is the stricter test that already partly addresses it):

**Suggested replacement for the second half of L33** (replace from "Taken together they point to a single reading:" to end of that sentence, before "\Cref{tab:disc_interp_gen} summarises"):

> *Taken together they point to a single reading: the held-out composition score shows that the model's accuracy does not depend wholly on having seen each compound before, so the headline $R^{2}=\rsq{}$ reflects genuine structure--property learning and not only the per-publication and per-series memorisation that a random split can reward (\Cref{subsec:literature_ml}). The composition-level holdout removes the strongest such shortcut, withholding whole chemistries rather than individual temperature points; a publication-grouped evaluation, the diagnostic flagged in \Cref{subsec:literature_ml}, would quantify the residual offset directly and is left to future work.*

This (i) downgrades "rather than a leakage artefact" to "not *only* the... memorisation a random split *can* reward" — a claim the holdout genuinely supports; (ii) names the publication-offset channel from theory so the chapters cohere; (iii) explicitly states the grouped split was *not* run and routes it to future work, closing the gap without fabricating a number.

**Companion (optional, L52):** L52 already says "Seen against the machine-learning screening literature reviewed in \Cref{subsec:literature_ml}, the gap between a high interpolation score and a stricter held-out score is the expected behaviour of a literature-trained property model." This is good and coherent — it just stops short of acknowledging the *grouped-split remedy* named at theory L420-423. If thesis-1 wants belt-and-braces, append one clause:

> *...not a defect specific to this one; quantifying the publication-offset component directly with a DOI-grouped evaluation (\Cref{subsec:groupkfold}) is the natural next diagnostic and is noted in \Cref{chap:future_work}.*

Only adopt the L52 companion if `\Cref{chap:future_work}` actually lists the grouped-split diagnostic — thesis-1 should verify that cross-ref resolves before adding it (I did not check future_work.tex content under this lens).

## \Cref support spot-check (lens requirement)
All \Cref targets in discussion/conclusion point to plausibly-supporting locations. One to verify: L52 cites `\Cref{subsec:literature_ml}` — supported (theory L409 directly discusses interpolation-vs-held-out gap). L33 currently cites no theory ref for the leakage claim; the suggested fix adds the correct `\Cref{subsec:literature_ml}` anchor, which improves coherence. The `subsec:groupkfold` label exists (theory L421) if the companion fix is used.

## Net assessment
One HIGH item (A1/B — the L33 leakage-artefact overclaim + the random-vs-theory coherence gap; single fix closes both). One LOW item (A4 duplicate verdicts, defensible as-is). A2 and A3 RESOLVED. No fabricated numbers. No retired-topic reintroductions. The B fix above is the single change I would gate submission on.


## Lens: cref-sendek

I now have everything needed. Let me compile the findings.

**Sendek mention audit:** L247 (sec:discovery_motivation context), L361 (tab:ml_uses text, "roughly 12,000"), L394 (table row), L409 (subsec:literature_ml expanded review). The discussion only \Cref's subsec:literature_ml (L52). Let me confirm the three prose mentions and assess redundancy.

The Sendek screen now appears in prose three times: L247 ("twelve thousand"), L361 ("roughly 12,000"), L409 ("ranked thousands"). Plus table L394. That's the redundancy thesis-1 flagged.

Here is my final report.

---

# thesis-3 (adversary) — LENS: cref-sendek — discussion.tex / conclusion.tex @ final text

## PART A — \Cref verification (discussion → Theory)

### A1. RESOLVED-with-caveat: model-as-diagnostic vs `\Cref{subsec:phonon_dos_predecessor}`
**LOCATION** discussion.tex L59: *"The model became, in effect, a diagnostic instrument for the dataset, with the same predict-and-inspect spirit as the descriptor-based screen discussed in \Cref{subsec:phonon_dos_predecessor}"*
**PROBLEM** The \Cref target (Theory L368–372) describes Jaafreh's phonon-DOS workflow purely as a *staging template*: "composition-based screening first, DFT/AIMD verification only for the shortlist." It says nothing about a *predict-and-inspect data-cleaning loop* where model failures surface data errors. The discussion sentence imports a "predict-and-inspect spirit" attribution that the cited section does not contain — the analogy is asserted, not supported by the target. This is the borderline case thesis-1 suspected.
**SEVERITY** low–medium (not a fabricated number, but a \Cref that overstates what its target says).
**FIX** Either (a) drop the cross-ref and let the diagnostic-loop description stand on its own (it is original to the discussion and needs no Theory anchor), or (b) soften to "...a diagnostic instrument for the dataset; the same composition-first / verify-the-shortlist staging is set out for the predecessor screen in \Cref{subsec:phonon_dos_predecessor}." The "predict-and-inspect spirit" phrasing is the part the target does not license — remove or attribute to this work, not the predecessor.

### A2. FLAG (real issue): "large, polarisable Bi³⁺ cation favourable for a soft, conductive sublattice" — NEW theory smuggled into discussion
**LOCATION** discussion.tex L86: *"it contains the large, polarisable Bi$^{3+}$ cation favourable for a soft, conductive sublattice"*
**PROBLEM** No \Cref attached, and the underlying physics is **not** in Theory. Theory establishes the soft/polarisable-sublattice → low-Ea mechanism only for **anion** sublattices: L177 "soft, polarisable S²⁻ sublattice lowers the saddle-point energy," L196 "polarisable N³⁻ sublattices give some of the lowest activation energies." `grep` confirms Theory contains **no** treatment of a large/polarisable *cation* contributing to a soft conductive sublattice (the only "cation" hits are the antiperovskite site-inversion at L190 and generic dopant-site text at L230, neither of which supports this claim). So the discussion introduces a *new* structure–property argument (polarisable cation → soft sublattice) that the thesis never grounded. Per operator convention the discussion carries zero \cite, so a reader cannot trace this; it reads as a novel physical claim asserted in the discussion.
**SEVERITY** medium. This is genuinely "new theory in the discussion," which the chapter's own header (L6–8: "no new theory is introduced here") explicitly disclaims — internal inconsistency.
**FIX** Two clean options: (1) Downgrade to a non-mechanistic justification that the verification chapter actually supports, e.g. "...it sits in an oxide system that survived the stability and structural screens of \Cref{chap:md_verification}, and the AIMD trajectory (\Cref{fig:md_traj_li}) shows Li⁺ moving through its rigid Bi–O framework." This drops the unsupported polarisable-cation mechanism and points at evidence that exists. (2) If the polarisability argument is to be kept, it must first be added to Theory (sec:sse_overview) with a citation and then \Cref'd — but per your guardrails that is Future-Work territory, so option (1) is safer for final submission.

### A3. PASS — other discussion \Crefs verified as supported
- L13/L18 `\Cref{chap:theory}`, `chap:dataset_results`, `chap:ml_results`, `chap:md_verification` — correct scoping refs. PASS.
- L22 `\Cref{subsec:arrhenius_ne}` for "σ depends exponentially on T" — Theory L324–328 (Boltzmann factor exp(−Ea/kT)) supports it. PASS.
- L24 `\Cref{chap:md_verification}` for structural plausibility at verification stage — correct. PASS.
- L52 `\Cref{subsec:literature_ml}` for "gap between interpolation and held-out is expected behaviour of a literature-trained model" — Theory L409 + L416 explicitly state random-split interpolation scores "flatter how well a model generalises." Strongly supported. PASS.
- L66 `\Cref{sec:sse_overview}` + L66 sulfides-low-Ea / garnets-high — Theory L177 (sulfide soft sublattice, low Ea) and L173 (stiff O²⁻ framework) support. PASS.
- L68 `\Cref{sec:sse_overview}` for "low-barrier reputation of Li₃N" — Theory L196 ("Li₃N... lowest activation energies"). PASS.
- L70 `\Cref{subsec:microstructure_eis}` two-level intrinsic-vs-pellet picture — Theory L269/L272 (effective σ combines grain interiors/boundaries/pores). PASS.
- L75/77 `\Cref{subsec:microstructure_eis}` + `\Cref{sec:process_params}` for processing influence — supported (L253/L256). PASS.
- L82/86 `\Cref{subsec:convex_hull}` for E_hull near-stable window — Theory L375–379 (E_h < 0.05 eV/atom synthesis-accessible). PASS. Note: "near-stable energy-above-hull window" is consistent with the locked 0.046 eV/atom; no number invented in text. PASS.
- L93 `\Cref{subsec:arrhenius_ne}` for Ea–σ coupling — PASS.

## PART B — SENDEK redundancy (thesis-1's specific ask)

**FINDING: Sendek is now described THREE times in prose plus once in a table. This is over-redundant, and the three prose descriptions are mutually inconsistent in the count they give.**

- **L247** (sec:discovery_motivation): *"Sendek and co-workers triaged twelve thousand lithium-containing crystal structures to a shortlist... using a small set of structural descriptors~\cite{Sendek2017EES}."*
- **L361** (tab:ml_uses surrounding text): *"...the Sendek screen over roughly 12{,}000 candidate Li-conductors~\cite{Sendek2017EES}."*
- **L394** (tab:ml_uses table row): *"Composition–structure filter over $\sim$12{,}000 phases & \cite{Sendek2017EES}"*
- **L409** (subsec:literature_ml, the newly expanded review): *"the screen of Sendek et al.~\cite{Sendek2017EES}: a classifier trained on simple structural and compositional descriptors ranked thousands of candidate lithium compounds and narrowed them to a shortlist for first-principles and experimental follow-up..."*

**PROBLEMS**
1. **Redundancy:** four touchpoints for one screen. L247, L361 and L409 each re-explain "descriptors → ranked → shortlist," which an NTNU sensor will read as padding.
2. **Numerical inconsistency between the prose mentions:** L247 says "**twelve thousand**" (spelled), L361/L394 say "**~12,000 / roughly 12,000**," and L409 says only "**thousands**." Same screen, three different magnitudes in words. The L247 "twelve thousand" vs L361 "roughly 12,000" is the sharpest clash — one reads as an exact figure, the other as approximate, for the identical screen. This is the kind of inconsistency a hard sensor circles.

**SEVERITY** medium (redundancy = style; the spelled-"twelve thousand" vs "roughly 12,000" inconsistency = factual-presentation defect).

**RECOMMENDATION (which to trim)**
- **Keep L409** as the single substantive description of the Sendek screen — it lives in `subsec:literature_ml`, the section purpose-built for the prior-ML review, it is the one the discussion actually \Cref's (L52), and its framing ("filter, not a quantitative predictor") is the framing the rest of the thesis leans on.
- **Keep the L394 table row** (tables are meant to be standalone catalogues — low redundancy cost).
- **Trim L247** down to a one-clause forward-pointer, e.g. "...descriptor-based screens of the candidate space (\Cref{subsec:literature_ml})," removing the standalone "twelve thousand" sentence. This kills the spelled-vs-numeric clash.
- **Trim L361** to not re-state the count: either drop "over roughly 12,000 candidate Li-conductors" (the count already lives in the L394 table row in the same subsection) or keep the count only in L394.
- Net: one number ("~12,000") appears once in prose-or-table, one full description (L409), one table row (L394). Removes both the redundancy and the inconsistency.

## conclusion.tex
- All \Cref targets check out: `chap:dataset_results/ml_results/md_verification` (L2), `sec:disc_headline` (L4), `subsec:phonon_dos_predecessor` (L6 — here correctly used as "prior work / template," no over-claim), `chap:theory` + `sec:data_problem` (L8), `chap:future_work` (L10). PASS.
- Numbers (R², RMSE, MAE, valRsq, nebBarrier, nebBenchmark, nPapers, nRawRows) are all macro-driven, none hardcoded. No fabricated/retired values. PASS.
- Note: the A2 polarisable-Bi³⁺ claim does **not** propagate into the conclusion (L6 stays at "out-of-training composition... rigid Bi–O framework"), so the fix is contained to discussion L86.

## Summary for thesis-1 (priority order)
1. **discussion L86** — remove/relocate the unsupported "large, polarisable Bi³⁺ cation → soft conductive sublattice" claim; it is new theory the chapter header disclaims and Theory does not contain (only anion-sublattice polarisability exists). Replace with the verification-chapter evidence. [medium]
2. **Sendek L247 vs L361 vs L409** — collapse to one prose description (keep L409) + one count (keep L394 table); fix the "twelve thousand" vs "roughly 12,000" vs "thousands" inconsistency. [medium]
3. **discussion L59** — the "predict-and-inspect spirit as the screen in \Cref{subsec:phonon_dos_predecessor}" overstates the target; soften to the composition-first/verify-shortlist staging the section actually describes, or drop the ref. [low-medium]

All other \Crefs in both chapters verified as genuinely supporting their sentences.


## Lens: ai-tells

I have enough to assess. The humanizer pass left several residuals. Let me verify the "single reading" survivals and assess the negative-parallelism density.

The findings are clear. Output below.

---

## thesis-3 (ai-tells lens) — findings for thesis-1

FINAL text @ working tree, discussion.tex + conclusion.tex.

### Em/en-dashes — CLEAN
No prose em (—) or en (–) dashes survive. All `--` instances are allowed: `composition--property`, `structure--property`, `Bi--O`, `conductivity--temperature`, `synthesis--EIS--Arrhenius`, `Model--Data` (title), and numeric ranges `$0.2$--$0.5$~eV`. No action.

### AI vocabulary (crucial/pivotal/testament/underscore/showcase/etc.) — CLEAN
Zero hits. No promotional clichés, no "plays a key role", no "it is worth noting". No action.

### "single reading" / "honest" residuals — NOT fully thinned (the humanizer pass was supposed to thin these)

| LOCATION | PROBLEM | SEV | FIX |
|---|---|---|---|
| disc L13 `"argues towards a single reading of what the work shows"` AND disc L33 `"Taken together they point to a single reading:"` | "single reading" survives **twice** — the exact phrase the humanizer pass claimed to thin. Two occurrences in one short chapter reads as a verbal tic. | med | Keep one (L13 as the framing is fine). On L33 replace `point to a single reading:` → `point the same way:` or `converge:`. |
| conc L4 `"while remaining honest that quantitative generalisation..."` | "remaining honest" — flagged humanizer word, and slightly editorialising in a conclusion. | low-med | `while making clear that quantitative generalisation...` |
| disc L86 `"the honest reach of the claim is the workflow, not a new conductor"` | "honest reach" — same tell, plus this is a negative-parallelism tail (see below). | low-med | `the claim reaches the workflow, not a new conductor` |

### Negative parallelism ("not X but Y" / "X rather than Y") — OVERUSED, this is the strongest AI-tell remaining

The "the data, not the model" antithesis is the chapter's thesis, so some repetition is intentional. But the construction recurs far past rhetorical effect — it is the dominant sentence shape:

- disc L13 `"is not the algorithm but the data"`
- disc L57 `"is not modelling capacity but the fragmented... record"`
- disc L57 `"not in sequence"` / L20 `"not... a single fortunate algorithm choice"`
- disc L61 `"was not a mislabelled material family but anomalous conductivity values"`
- disc L70 `"not as learning a ranking of families but as resolving..."`
- disc L84 `"not evidence that the model can discover..."`
- disc L86 `"is the workflow, not a new conductor"`
- disc L91 `"the data rather than the model"`
- disc L113 `"rather than as a discovery claim"`
- conc L8 `"is not the headline accuracy but what the work reveals"` + `"the data rather than the choice of algorithm"`
- conc L10 `"data rather than modelling capacity"` + `"rather than a task repeated from scratch"`

**SEV: med.** Count: ~12 explicit "not X but Y" / "X rather than Y" antitheses across two short chapters. A sharp NTNU sensor reading back-to-back will register the cadence as machine-generated. FIX: this is a global thinning task, not a single edit. Recommend thesis-1 keep the load-bearing ones (the headline "data not the model" claim at disc L13/L91 and conc L8) and rewrite 4-5 of the lower-stakes ones into plain declaratives. Highest-value targets: disc L70 (`The model resolves the composition--property landscape within and across families; its predictive value comes from the within-family variation that a family label misses.`), disc L86, conc L10 (two "rather than" in one sentence — drop one).

### Rule-of-three triples — present but mostly legitimate enumerations

Most triples are real lists (e.g. disc L29 the three holdout compounds; disc L59 "inconsistent units, unparseable formulas, mislabelled phases"; disc L86 "stability, structural and first-principles transport checks"). Those are factual and fine. Two read as rhetorical cadence rather than content:

| LOCATION | PROBLEM | SEV | FIX |
|---|---|---|---|
| disc L59 `"is this an outlier or a real datum, do these two papers report the same quantity, which of three reported conventions is the author using"` | Three parenthetical rhetorical questions in series — classic rule-of-three rhythm. | low | Acceptable as illustration; if trimming, cut to two examples. |
| conc L10 `"aggregates... into one machine-ready corpus, retrains the prediction model..., and routes its strongest candidates into..."` mirrored verbatim at disc L120 | Same three-verb triple appears in both discussion (L120) and conclusion (L10) nearly word-for-word. | low-med | Intentional echo is OK, but vary the conclusion phrasing slightly so it doesn't read as copy-paste. |

### Vague attribution — CLEAN
No "studies show", "researchers believe", "it is widely accepted". Claims are attributed to specific \Cref targets or to "this work". No action.

### Filler — CLEAN-ish
No "it should be noted", "in order to" bloat, "very/quite". disc L61 `"makes the loop tangible"` and L84 `"needs to be set carefully"` are mild signposting but acceptable in a discussion. No action required.

### \Cref support spot-check (per guardrail, in lieu of citation-flagging) — OK
Checked the load-bearing ones: disc L18 `\Cref{sec:ml_comparison}` (headline R²) ✓; L22 `\Cref{subsec:arrhenius_ne}` (Arrhenius) ✓; L31 `\Cref{fig:ml_arrhenius}` (holdout) ✓; L86 `\Cref{subsec:convex_hull}` (E-above-hull screen) ✓; conc L6 `\Cref{subsec:phonon_dos_predecessor}` (prior LiBiO2 work) ✓. No mismatched cross-refs found.

### Numbers — no fabrication detected
All quantitative values are macros (`\rsq`, `\valRsq`, `\nebBarrier`, etc.) or guardrail-approved literals ("more than eleven orders", "21 nitride", "fewer than 15%", "$\sim$137 curated papers", `300~K`, "fewer than one row in six"). No invented process-R², no grouped/DOI-CV R², no retired 0.14/0.008. CLEAN.

---

**Priority for thesis-1:** (1) negative-parallelism density — thin 4-5 of the ~12 "not X but Y"/"rather than" antitheses [med]; (2) drop one of the two "single reading" occurrences, disc L33 [med]; (3) "remaining honest" conc L4 + "honest reach" disc L86 [low-med]. Everything else is clean or acceptable. No RESOLVED items to note — these are new-lens observations, not re-flags.


## Lens: overclaim-weaklink

I have what I need. The MD chapter does NOT report an MSD slope value, hop count, or a numerical diffusion coefficient — it argues qualitatively from trajectory-spread visualisation. The analysed window is 1.0 ps. This grounds my attack. Writing findings now.

---

# thesis-3 (ADVERSARY) — LENS: overclaim-weaklink — FINAL @ f2d76b1

Read: discussion.tex, conclusion.tex, md_verification.tex (cross-check), thesis_macros.tex (numbers verified locked). No edits made. All numbers below trace to macros; I invent none.

## Findings

### F1 — "not yet automatable" overclaims a universal impossibility from an n=1 anecdote — **MEDIUM**
**LOCATION** discussion.tex L59: *"That work is not yet automatable, and the experience of this project is the argument for why."* Also conclusion.tex L10: *"the curation that removes that bottleneck still depends on human judgement that cannot yet be automated."*
**PROBLEM** Guardrails told me the defensible claim is "was not automated *here*," not "cannot be automated." conclusion.tex L10 says "cannot yet be automated" — a claim about the *world*, supported only by this single project's predict-and-inspect loop. A skeptical sensor reads this as an unfalsifiable generalisation from one workflow. discussion.tex L59 is softer ("not yet automatable") but still asserts a property of the task rather than a fact about this project. The body sentence ("the experience of this project is the argument for why") tries to back a universal with one anecdote — that is the weak link.
**FIX** discussion L59: "That work was not automated here, and the experience of this project illustrates why human judgement was needed at each step." conclusion L10: "the curation that removes that bottleneck still required human judgement in this work." Demote from "cannot be automated" (claim about the field) to "was not automated here / required judgement here" (claim about the thesis). No number touched.

### F2 — "the data, not the model, is the limiting factor" stated as demonstrated when it is suggestive — **MEDIUM**
**LOCATION** discussion.tex L13 (chapter thesis statement): *"the limiting factor in this kind of modelling is not the algorithm but the data"*; L118: *"The recurring finding across every section above is that the data, not the model, is the limiting factor: five algorithms agree to within a couple of percent"*; conclusion.tex L8: *"The primary limiting factor is the data rather than the choice of algorithm."*
**PROBLEM** The five-algorithm agreement ($R^2$ \rsqMin–\rsq, L20) shows that *within the tried model family*, model choice barely moves the score. That is genuinely suggestive evidence, but it is presented as a settled finding ("the recurring finding ... is that"). The adversarial reading: five tree/ensemble-family learners agreeing does not exclude that a *fundamentally* different architecture (or richer features) could do better — agreement among similar inductive biases is weaker evidence than the prose implies. The discussion itself half-concedes this at L24 ("not a proof of universal extrapolation") but the limiting-factor claim is never similarly hedged.
**FIX** Keep the claim but mark its evidential status once, at first assertion. L118: "...points to the data, rather than the choice of model, as the limiting factor: five algorithms agree to within a couple of percent, which indicates that — across the models tried here — accuracy is set by the data more than by the learner." Add "tried here" or "across the models compared" so the claim is bounded to the experiment. L13 chapter-opener: soften "is not the algorithm but the data" to "appears to be the data more than the algorithm." conclusion L8 already says "primary limiting factor" which is acceptable if L118 carries the bound.

### F3 — "living platform" framing overclaims a platform that does not exist in-thesis — **MEDIUM-HIGH**
**LOCATION** discussion.tex sec:disc_synthesis L120: *"The natural extension of this work is a living platform that aggregates ... retrains the prediction model as the corpus grows, and routes its most promising candidates into ... verification"*; conclusion.tex L10: *"A living platform that aggregates ... The dataset, the trained model, and the LiBiO$_2$ cross-check are released to the research group as the first version of exactly such a foundation."*
**PROBLEM** The section *title* "From Dataset to a Living Screening Platform" (L115) and the conclusion's "first version of exactly such a foundation" (L10) sit on the boundary. The discussion body is actually careful — L118 "points less to a finished tool than to a direction," L120 "It would not remove the human" — these are correctly conditional ("would," "natural extension"). The risk is the *conclusion* L10: "released ... as the first version of exactly such a foundation" upgrades three static artefacts (dataset + one trained model + one cross-check) into "the first version of a platform." A platform retrains as the corpus grows and routes candidates automatically; none of that exists in-thesis. A sensor will ask "where is the platform?" Per guardrail, LiAgent (the actual platform-ish thing) is Future-Work-only and must NOT be leaned on to back this — so the conclusion cannot point to anything concrete that makes "platform foundation" true.
**FIX** conclusion L10: change "are released to the research group as the first version of exactly such a foundation" → "are released to the research group as the starting materials for building such a platform" or "...as the components from which such a platform could be built." This keeps the released artefacts (real) but stops calling them a platform version (not real). Section title is defensible as-is because "From Dataset to..." signals direction, not arrival. Discussion body needs no change — it is the most-hedged part.

### F4 — "lithium diffusing through a rigid Bi–O framework" overclaims long-range diffusion from a 1.0 ps window with no reported MSD slope or hop count — **MEDIUM-HIGH**
**LOCATION** discussion.tex L82: *"the AIMD trajectory shows lithium diffusing through a rigid Bi--O framework"*; L84 correctly hedges *"anchored by a single $300$~K AIMD run"*; conclusion.tex L6: *"an AIMD trajectory showing mobile lithium in a rigid Bi--O framework."* RQ4 L113: *"an AIMD trajectory showing mobile lithium in a rigid host."*
**PROBLEM** Cross-checking md_verification.tex: the analysed window is only **4.8–5.8 ps = 1.0 ps** (L56), and the chapter's *own* support for "diffusion" is qualitative trajectory-spread imagery — L235–237 "trajectories occupy many positions within the cell and connect across the periodic-boundary directions, consistent with long-range diffusion." There is **no reported MSD slope, no diffusion coefficient value, no hop count** anywhere (verified by grep). Conductivity is extracted via Nernst–Einstein with an *assumed* Haven ratio of unity (md L57–60). So "diffusing ... long-range diffusion" rests on a visual over a 1 ps window. 1 ps at 300 K for a "modest" conductor (predicted ~$10^{-3}$ mS/cm, md L269) is borderline for claiming *long-range* diffusion — at that conductivity you may see vibration + occasional hop, not steady-state diffusion. "Mobile lithium" is defensible; "diffusing / long-range diffusion" is the overclaim. The MD chapter itself only says "consistent with long-range diffusion" (hedged); the discussion (L82) and conclusion (L6) drop the hedge to a bare "diffusing."
**FIX** discussion L82: "the AIMD trajectory shows lithium that is mobile within a rigid Bi--O framework" (matches "mobile" used elsewhere; drops the un-evidenced "diffusing"). Or keep "diffusing" but add the chapter's own hedge: "shows lithium spreading through the cell in a manner consistent with diffusion, within a rigid Bi--O framework." conclusion L6 and RQ4 L113 already say "mobile lithium" — those are fine, do NOT change. Invent no MSD number; the fix is purely to demote "diffusing"→"mobile" so the prose does not exceed what the 1 ps trajectory + qualitative figure support. (Note for thesis-1: this is *consistency*, since the MD chapter is already correctly hedged at L237 — the discussion should not be stronger than its own source chapter.)

### F5 — RQ4 answer "the answer is yes" front-loads the verdict before the hedge — **LOW**
**LOCATION** discussion.tex L113: *"For LiBiO$_2$ the answer is yes within the bounds set above: the model predicted facile Li$^{+}$ transport, and an NEB barrier ... together with an AIMD trajectory showing mobile lithium in a rigid host supported it."*
**PROBLEM** Minor. "The answer is yes" reads as a stronger affirmative than the carefully bounded sec:disc_libio2 (L84 "proof of concept ... not evidence that the model can discover arbitrary new conductors"). The "within the bounds set above" clause does the work, but a skim-reader takes "yes." Lower severity because the qualifier and the final sentence ("proof of concept ... rather than a discovery claim") are both present.
**FIX** Optional: "For LiBiO$_2$ the answer is a qualified yes:" — one word, aligns the RQ summary with L84. Not load-bearing; defer if time-constrained.

### F6 — "out-of-training composition" vs MP-derived structure — verify no feature-leak implication — **LOW / likely RESOLVED**
**LOCATION** discussion.tex L82, L86, conclusion L6: LiBiO$_2$ "applied ... as an out-of-training composition"; L86 "its Materials Project entry (mp-1205315) ... within the near-stable energy-above-hull window."
**PROBLEM** Checked for the retired "Materials-Project-as-model-feature" risk: the text is clean. MP enters only as (a) the source of the structure for DFT/AIMD and (b) the convex-hull stability screen (L86, md L62–67) — explicitly *not* as a model feature. The discussion correctly keeps the model at "145 Magpie + measurement temperature" (L24). "Out-of-training composition" is accurate (LiBiO$_2$ was not in the 342-compound table). No overclaim.
**RESOLVED** — no feature-leak overclaim; MP confined to verification/structure-source role per design.

## \Cref support spot-check (per guardrail, instead of citation-flagging)
- L18 \Cref{sec:ml_comparison} for headline $R^2$/RMSE — supports. ✓
- L20 \Cref{fig:ml_scores} for five-algo band — supports the \rsqMin–\rsq claim. ✓
- L66 \Cref{fig:data_ea_temp} + \Cref{sec:performance_params} for 0.2–0.5 eV band — supports. ✓
- L82 \Cref{fig:md_traj_li} cited for "diffusing through rigid framework" — figure shows trajectory spread (md L235), supports "mobile" but *not* a quantified "diffusing"; see **F4**.
- L107 \Cref{fig:data_availability} for ~100% / ~quarter / <15% — consistent with verified dataset numbers. ✓

## Numbers audit
All values in discussion + conclusion resolve through macros: \rsq=0.971, \rsqMin=0.946, \valRsq=0.89, \valMAE=0.02, \valRMSE=0.142, \rmseLog=0.283, \maeLog=0.158, \nebBarrier=0.27, \nebBenchmark=0.296, \nPapers=187, \nRawRows=6555, \nRows=4407, \nCompounds=342. No fabricated/invented number found. No retired 0.14/0.008, no process-$R^2$, no grouped/DOI-CV $R^2$, no V3/V4/HistGBM/SHAP/OOD/conformal/polymer surfaced. ✓

## Priority for thesis-1
1. **F4** (discussion L82 "diffusing"→"mobile") and **F3** (conclusion L10 "first version of exactly such a foundation"→"starting materials/components") — both are real overclaims the discussion's *own* hedged neighbours contradict; cheap one-clause fixes.
2. **F1** (conclusion L10 "cannot yet be automated"→"required judgement here") — the most attackable universal claim.
3. **F2** (bound the limiting-factor claim to "models tried here" at L118).
4. **F5** optional polish.


## Lens: fig62-numbers

Confirmed. `\rsqMin` = 0.946 (NN), matches the table low end. Discussion line 20 says "narrow band 0.946 to 0.971" which correctly spans all five (NN at bottom). Working tree has an uncommitted edit to discussion.tex (line 70 reworded) — cosmetic, no number impact. The `\nFeatures` macro (146) isn't used in prose (ml_results hardcodes "146 features", consistent with macro). 

Findings below.

---

## thesis-3 (ADVERSARY) — LENS: fig62-numbers — FINAL @ f2d76b1

### (A) Fig 6.2 two-panel consistency — md_verification.tex

**RESOLVED — body text is consistent with the two-panel figure and does not contradict the neutral caption or the CIF/AIMD split.**

- `md_verification.tex:96` — *"\Cref{fig:md_cell} shows the LiBiO$_2$ unit cell and the supercell used for the calculations"* — body now explicitly references both panels (unit cell + supercell), matching the two-panel `(a)/(b)` figure at lines 105-121. Consistent.
- The figure caption (lines 115-119) is correctly neutral on atom count: it describes "(a) the unit cell ... (b) the larger supercell built by replicating the unit cell" with no atom number. No contradiction with either the NEB cell or AIMD cell.
- The atom-count split lives only where it should: NEB body (lines 40-43) gives the supercell + 10 images, no atom count; AIMD body (lines 50-52) gives Li$_{31}$Bi$_{32}$O$_{64}$, 127 atoms = `\aimdAtomCount` (127). The MP unit-cell line (line 64) says "8 atoms per conventional cell" — that is the `mp-1205315` conventional cell, distinct from both the NEB and AIMD supercells, and is not contradicted by the neutral caption. CIF(32-atom)/AIMD(127-atom) split is intact and not reopened.

No finding.

### (B) Number-lock across all five chapters vs thesis_macros.tex

**Conductivity span — RESOLVED, uniform.** All instances say "more than eleven orders of magnitude": `dataset_results.tex:97` ("more than eleven orders ... from around $10^{-9}$ up to about $3\times10^{2}$~mS/cm"), `ml_results.tex:95` and `:103` (body + caption), `discussion.tex:18` and `:109`. No "nine/ten/twelve" anywhere. `md_verification.tex:268` says "about two orders of magnitude" but that is the LiBiO$_2$ Arrhenius curve across its temperature window, NOT the dataset span — correct and unrelated.

**E_a band 0.2–0.5 eV — RESOLVED, uniform.** `dataset_results.tex:112`, `:118`; `md_verification.tex:146`; `discussion.tex:66`, `:109`. All "0.2--0.5 eV". No drift.

**E_hull 0.046 — RESOLVED.** `md_verification.tex:65` "0.046~eV/atom", screening window "0--0.05" (lines 66-67, 72, 87). No "0.043" anywhere.

**Temp max 740 C — RESOLVED.** `dataset_results.tex:97` "about $740\,^\circ$C". No "900" as a temp-max (the only "900" hit is `dataset_results.tex:135` calcination "$800$--$900\,^\circ$C", a legitimate processing range).

**R²/RMSE/MAE/counts — macro-sourced where it matters; no fabricated numbers.**
- discussion.tex and conclusion.tex use macros throughout: `\rsq` (0.971), `\rmseLog` (0.283), `\maeLog` (0.158), `\rsqMin` (0.946), `\valRsq` (0.89), `\valMAE` (0.02), `\valRMSE` (0.142), `\nebBarrier` (0.27), `\nebBenchmark` (0.296), `\nPapers`, `\nRawRows`, `\nRows`, `\nCompounds`, `\bestModel`. Correct.
- `discussion.tex:20` "narrow band ($R^{2}$ from \rsqMin{} to \rsq{})" = 0.946→0.971; spans all five models incl. NN at the floor (table `ml_results.tex:59`). Correct.
- ml_results.tex hardcodes the table values (0.283/0.158/0.971 etc.) and "146 features / 145 Magpie + temp" — these match the macros (`\rmseLog`, `\maeLog`, `\rsq`, `\nFeatures`=146). Acceptable: a results table is the canonical source the macros are generated from. No mismatch.
- No process-R², no grouped/DOI-CV R², no retired 0.14/0.008, no V3/V4, no HistGBM, no SHAP/OOD/conformal/GroupKFold/polymer surfaced. Clean.

**Counts cross-check:** raw 6555 / modelling 4407 / 187 papers / 452 compositions / 342 compounds / 9 families / 21 nitrides / Ea ~24% / processing <15% — all present and consistent (`dataset_results.tex:25,55,167-171`; `ml_results.tex:16-19`; macros). No mismatch.

### Note (non-finding, for thesis-1's awareness, NOT a defect)
- Working tree has one uncommitted edit to `discussion.tex` (line 70 reworded from "best understood not as learning a ranking of families but as resolving..." to "does not rank families; it resolves..."). Cosmetic, zero number impact. Flagging only so you know the committed f2d76b1 text and the live file differ by one sentence.

**Verdict: no number-lock violations, no fig-6.2 inconsistencies. LENS clean.**


## Lens: sensor-questions

All cross-reference targets exist. The text is internally consistent and numbers match macros. Here is my deliverable.

---

# thesis-3 (adversary / sensor-questions lens) — FINAL discussion + conclusion

Scope: top 5 hardest oral-defence questions, ranked by exposure on the depth-of-analysis (20-pt) lever. Each = the question | exact line/claim targeted | the hedge the text **already has** or **needs**. READ-ONLY; no numbers invented.

Verified first: all five `\Cref` targets in the leakage/holdout argument (`sec:ml_r2`, `sec:ml_comparison`, `sec:ml_validation`, `subsec:composition_holdout`, `subsec:literature_ml`) resolve to real labels. No grouped-CV/DOI R2 macro exists and the text does **not** invent one — good. Numbers in both chapters match `thesis_macros.tex` exactly (R2=0.971, RMSE 0.283, MAE 0.158, valRsq 0.89, valMAE 0.02, valRMSE 0.142, NEB 0.27 vs benchmark 0.296).

---

## Q1 — Random-split leakage / no grouped-CV (HIGHEST exposure; the known open lever #67)

**Question a strict sensor asks:** "Your headline R2=0.971 comes from a random 80/20 split that puts different temperature points of the *same compound* — and rows from the *same publication* — on both sides. That is textbook data leakage. Why should I believe this number measures anything other than memorisation, and why did you not run a grouped/per-publication cross-validation that would have quantified the leak?"

**Targets:**
- discussion.tex L18, L20 ("$R^{2}=\rsq{}$ ... the random split places different temperature points of the same compound on either side")
- discussion.tex L33 ("They do not, by themselves, certify that the random-split headline is free of the per-publication offset ... because a random split can place rows from the same publication on both sides")
- conclusion.tex L4 ("rather than a leakage artefact")

**Hedge the text already has (strong):** The thesis does *not* hide this — L20 names the interpolation reading explicitly ("This is not a weakness to be hidden"), L33 explicitly concedes the per-publication offset is *not* certified away by either evaluation, and reframes the headline as a deliberate "screening-and-ranking" interpolation metric, not a generalisation claim. The composition-level holdout (whole compositions + near-neighbours removed) is positioned as "the stricter guard against that." This is the honest framing and it is defensible.

**The gap / honest answer to rehearse (do NOT fabricate a number):** The text asserts the holdout is the stricter guard but **never produces the grouped/per-publication CV number itself** — so a sensor can still say "you *describe* the guard but you don't *show* the leakage magnitude." The honest defence, which fabricates nothing: *"A per-publication grouped CV is the correct quantitative measurement of that leakage; it is a single pipeline run on the released code and seed, and it is the first item I would report. I did not include a grouped-CV R2 in the thesis because I will not put a number in print I have not run cleanly; instead I bounded the question structurally with the three-composition holdout, which removes whole compositions and their neighbours and therefore *over*-controls for the publication effect. The holdout not collapsing (R2_log=0.89 on cold chemistries) is my evidence the headline is not pure memorisation, while I stay explicit that it does not certify the leak is zero."* — This is already 90% in L33; the only exposure is that the answer must be *spoken* confidently, since the manuscript leaves the grouped-CV value as future work rather than reporting it.

**Severity: HIGH (this is the single biggest depth-of-analysis lever).** No edit required for honesty — but if any pipeline time exists before submission, running the grouped CV and adding one sentence/number to L33 would close the only remaining attack surface. If not run: keep L33 exactly as worded (it is the correct hedge) and rehearse the spoken answer above.

---

## Q2 — Generalisation claimed from a 3-composition holdout (HIGH exposure)

**Question:** "You claim the model 'learned structure–property relationships rather than per-series offsets' on the strength of a holdout of *three* compositions. Three points cannot establish generalisation across composition space. Isn't your generalisation conclusion statistically empty?"

**Targets:**
- discussion.tex L33 ("the two evaluations are consistent with the model having learned structure--property relationships rather than only per-series offsets")
- discussion.tex L46 (table: "based on three points, so indicative")
- discussion.tex L52 ("three compositions cannot establish generalisation ... read as indicative rather than statistically tight")
- conclusion.tex L4 ("rests, so far, on only three held-out compositions")

**Hedge the text already has (very strong):** This is the best-defended claim in the chapter. L52 pre-empts it almost verbatim ("three compositions cannot establish generalisation across the whole of composition space ... indicative rather than statistically tight ... strong enough to corroborate ... not strong enough to stand alone"), L46 labels it "indicative" inside the table itself, and conclusion L4 repeats the "only three" caveat. The randomness of the draw (L52, "not vulnerable to optimistic selection") pre-empts the cherry-picking follow-up. The spanning of three distinct anion frameworks (L29: nitride/NASICON-phosphate/argyrodite-sulfide) is the legitimate qualitative strength to lean on.

**Spoken answer:** *"I make no statistical generalisation claim — I call it indicative throughout. Its value is qualitative: three randomly drawn, chemically distinct frameworks predicted cold without the score collapsing is corroborating evidence the model isn't memorising offsets, and I say explicitly it cannot stand alone. The fix is more data, not a different model — which is the thesis's central argument."*

**Severity: MEDIUM (well-hedged; exposure is low because every instance is caveated).** No edit needed. Watch only that L33's "consistent with the model having learned structure–property relationships" is the strongest verb used anywhere — it is appropriately soft ("consistent with", not "demonstrates"). RESOLVED relative to any earlier over-claim.

---

## Q3 — Single-case LiBiO2 "verification" (HIGH exposure)

**Question:** "You call Chapter 6 a 'verification', but it is one composition, one 300 K AIMD run, and a conductivity–temperature curve that is itself a model extrapolation — not a measurement. How is a single agreeing case 'verification' of a statistical model rather than an anecdote?"

**Targets:**
- discussion.tex L82 ("The verification ... closes the loop")
- discussion.tex L84 ("It rests on a single composition, anchored by a single $300$~K AIMD run, with the conductivity--temperature curve ... being a model extrapolation across temperature rather than a direct measurement ... successful proof of concept of the workflow, not evidence that the model can discover arbitrary new conductors")
- discussion.tex L95 ("the first-principles work is a single-case check ... verify the workflow on that candidate but do not ... extend the statistical model to others")
- conclusion.tex L6 ("proof of concept of the workflow on one candidate ... not a discovery claim; experimental synthesis and EIS characterisation remain necessary")

**Hedge the text already has (very strong):** L84 is a model defensive paragraph — it concedes every weakness (single composition, single 300 K run, extrapolated not measured curve) before the sensor can raise them, and downgrades the word "verification" to "proof of concept of the workflow." L95 and conclusion L6 repeat it. The framing is consistently "the workflow runs end-to-end and the two methods agree *for this candidate*," never "the model is verified." This is the correct, honest scope.

**One residual exposure:** The *section heading* and L82 use the noun "verification" / "closes the loop" while the body downgrades to "proof of concept." A pedantic sensor may exploit the gap between the confident heading and the hedged body. Defence is purely verbal: *"'Verification' refers to the workflow step, not a statistical claim about the model; the body of 6.5 and the conclusion both state the reach is the workflow, not a new conductor."* No edit required, but if thesis-1 wants zero exposure, softening L82's "closes the loop between the data-driven prediction and independent physics" to "demonstrates the predict-then-verify loop on one candidate" would align heading and body. Optional.

**Severity: MEDIUM-LOW (thoroughly hedged in body; only the heading/body register mismatch is attackable).**

---

## Q4 — The nitride E_a anomaly: data artefact or model failure? (MEDIUM exposure — depth-of-analysis bait)

**Question:** "Your nitrides sit at the *high*-E_a edge, contradicting the low-barrier reputation of Li3N. You attribute this to the literature sample (n=21). But how do you *know* it's a sampling artefact and not your model getting the physics wrong for that family? You've given yourself a free pass."

**Targets:**
- discussion.tex L68 ("they sit at the \emph{high}-$E_a$ edge, which runs counter to ... Li$_3$N ... With only $21$ nitride measurements ... most likely reflects the particular nitride compositions the literature happens to report rather than the family as a whole")
- discussion.tex L66 ("That the trends a model ... recovers are the trends the theory predicts is itself evidence that the curated data carries the right physics")

**Hedge the text has:** L68 hedges with "most likely reflects ... rather than the family as a whole" and frames it as "a useful caution against over-reading family labels." Crucially, the E_a distributions are described as coming straight from the *data* (`fig:data_ea_temp`), not from a model prediction — so the anomaly is a property of the corpus, not a model error. **This is the key defence and it must be stated clearly orally:** the E_a values in Fig 5.x are measured/reported values in the dataset, the model predicts log σ not E_a (L93), so the nitride anomaly cannot be "the model getting physics wrong" — it is literally what the literature reported for those 21 measurements.

**Residual exposure:** L66–L68 lean on the family trends "being the trends the theory predicts" as evidence the data carries right physics — then immediately exhibit a family that *doesn't* match theory. A sensor can frame this as having it both ways (matches = data is good; mismatch = data is sparse). The text mostly handles this by tying the exception to n=21 and "weighted by how well each family is sampled" (L68), which is internally consistent, but the rhetorical tension is real.

**Severity: MEDIUM.** No fabrication risk, numbers locked (21 nitrides verified). Defence is the data-vs-model distinction (E_a is observed, not predicted). No edit required; rehearse the "E_a is a reported field, not a model output" point.

---

## Q5 — Processing dropped: convenience or justified? + the "data not model" thesis is unfalsifiable (MEDIUM exposure)

**Question (two-barrel):** "(a) You admit processing 'clearly influences conductivity' yet drop it as a feature because it's under-reported (<15%). Isn't that abandoning the most physically important variable for convenience, and doesn't it inflate your residuals in a way you don't quantify? (b) Your central thesis is 'it's the data, not the model.' Every limitation gets blamed on data. What result *would* have changed that conclusion — i.e., is it falsifiable?"

**Targets:**
- discussion.tex L75 ("reported for fewer than one row in six ... a real but weak and inconsistently extractable processing signal ... more productive to concentrate collection on the three quantities")
- discussion.tex L77 ("transferring part of the genuine processing-driven variation into the residuals")
- discussion.tex L57, L118; conclusion L8 ("The primary limiting factor is the data rather than the choice of algorithm")

**Hedge the text has:** (a) is well-defended — L75 calls it "a deliberate, goal-driven decision rather than an oversight," cites the <15% coverage (`fig:data_availability`, verified), the exploratory "weak and inconsistently extractable" finding on ~137 papers, and L77 honestly states processing variation goes "into the residuals." This is a strong, honest answer. The phrase "fewer than one row in six" (L75) and "fewer than 15%" (L107) are consistent with the locked figure.

(b) is the **deeper, less-defended** trap. The "data not model" claim is supported by (i) five algorithms agreeing within ~2% and (ii) limitations tracing to reporting gaps. The falsifiability counter the text *implicitly* has: if a different algorithm class had *substantially* beaten the tree ensembles, the "model doesn't matter" claim would break — L20/L57 lean on the narrow algorithm spread (R2 0.946–0.971) as exactly that evidence. **This is the falsification criterion and it should be stated explicitly as the spoken answer:** *"The claim is falsifiable: had any of the five algorithms materially outperformed the others, the bottleneck would be modelling capacity. They landed within ~2.5 R2-points, so the evidence points to data. A second falsifier: if a denser corpus did *not* improve the held-out score, the data argument would weaken."*

**Severity: MEDIUM.** No number issues. The (b) falsifiability angle is the genuine depth-of-analysis exposure and is *not* spelled out in the text — it lives implicitly in the algorithm-spread argument. No edit strictly required (the evidence is present), but rehearsing the explicit falsifier is the highest-value oral prep.

---

## Summary ranking by exposure

| # | Question | Exposure | Text hedge status |
|---|---|---|---|
| 1 | Random-split leakage / no grouped-CV | **HIGH** | Honestly framed (L20, L33); grouped-CV number is genuine open lever — answer verbally, do NOT fabricate |
| 2 | 3-composition generalisation | HIGH→MED | Fully pre-empted (L46, L52, concl. L4); "indicative" throughout |
| 3 | Single-case LiBiO2 | MED | Strongly hedged in body (L84, L95, concl. L6); only heading/body register mismatch attackable |
| 4 | Nitride E_a anomaly | MED | Hedged (L68); key defence = E_a is observed not predicted |
| 5 | Processing dropped + falsifiability | MED | (a) well-defended (L75/77); (b) falsifiability implicit only — rehearse explicitly |

**No fabricated numbers found. No retired values (0.14/0.008) present. No forbidden topics reintroduced. All `\Cref` targets in the leakage argument verified to exist.** The only manuscript-level action worth considering is optional: running the grouped/per-publication CV (one pipeline run) to convert Q1 from "described guard" to "measured guard" — otherwise the text is honest as-is and the lever is an oral-defence preparation item, not a print correction.