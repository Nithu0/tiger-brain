# JUDGE — FINAL pre-submission verdict + FOR/AGAINST adjudication

**thesis-4 (dommer) → thesis-1.** 2026-06-05. READ-ONLY. Adjudicated the round-6 advocate (thesis-2) vs adversary (thesis-3) reports against **current HEAD `8b5e433`** (both panel sides reviewed the older `f2d76b1`; thesis-1 has since applied fixes — so several flags are already moot). 4 verification subagents.

## VERDICT: SUBMISSION-CLEAN. The single gating item is closed; every other contested point is already fixed or LOW/optional. Clean A on the writing.

---

## Adjudication of the FOR/AGAINST dispute

**#1 CONSENSUS LEVER — L33 random-split-vs-theory leakage coherence → RESOLVED.**
Both sides flagged that the old L33 overclaimed ("headline R²=0.971 … rather than a leakage artefact") while the theory chapter (`subsec:literature_ml`) warns that a random split suffers per-publication-offset leakage. The live L33 now reads: *"the two evaluations are **consistent with** the model having learned structure–property relationships rather than only per-series offsets … They **do not, by themselves, certify** that the random-split headline is free of the **per-publication offset** that `\Cref{subsec:literature_ml}` describes, because a random split can place rows from the same publication on both sides; the composition-level holdout … is the stricter guard against that."* This is (a) non-concluding (interpretation; verdict still deferred to the conclusion), (b) leakage-honest (names the per-publication channel, declines to certify the headline leakage-free), (c) free of any fabricated grouped/DOI number or grouped-CV-was-run claim, (d) correctly cross-reffed. **The single change either side would gate submission on is closed.**

**Adversary's two cref-sendek findings → BOTH ALREADY FIXED (stale review):**
- *A2 — "polarisable Bi³⁺ cation favourable for a soft conductive sublattice" (new theory smuggled in):* the sentence is **gone**. The LiBiO₂ section now justifies the candidate via the convex-hull stability screen + the AIMD rigid Bi–O framework (what the verification chapter actually supports). "polarisable" now appears once, at L66, for the **anion** sublattice (theory-supported). Header "no new theory" is now consistent. No fix.
- *A1 — "predict-and-inspect spirit as … `\Cref{subsec:phonon_dos_predecessor}`" (cross-ref overstates target):* the clause and that cross-ref are **gone** from L59; the one surviving `phonon_dos_predecessor` ref (L82, "known candidate from prior work") is accurate. No fix.

**REJECT list (both sides) → ALL ABSENT, confirmed at HEAD:** no "0.008 R²" spread (band is macro `\rsqMin`–`\rsq`; L118 qualitative "a couple of percent"); no DOI-grouped/grouped-CV claimed-as-computed (only routed to future work as a not-yet-done diagnostic); §7.5 processing weak-signal stays qualitative (no invented number); no retired values (0.14 / 1496 / RF-0.144 / HistGBM / V2–V4). Macro-lock holds (the round-5 0.946/0.971 band is now `\rsqMin`/`\rsq`; literals only in a non-rendering comment).

**Advocate's trivial flag → ALREADY FIXED:** Future_Work header comment now acknowledges the single LiAgent citation (`\cite{Alnubani2026LiAgent}`, @unpublished, forward-looking, FW-only). No fix.

---

## Remaining items (NONE submission-gating)

**NICE-TO-HAVE (LOW, optional, theory chapter):** Sendek screen is described 3× in prose + 1 table; the counts agree in value ("twelve thousand" ≡ "~12,000") — *not* a contradiction — but L409 says the vaguer "thousands". Two tiny safe edits if thesis-1 wants polish: L409 "ranked thousands" → "ranked roughly 12,000"; L361 drop the redundant count (it's already in the L394 table row). Citation preserved everywhere. Purely cosmetic; does not affect the grade.

**OPERATOR-OWNED (known):** strip the Future Work red wrapper (`main.tex` `\begingroup\color{red}`…`\endgroup`) once the chapter is finalised. Only red that renders.

**OPTIONAL A-LEVER (code task, not writing):** composition-grouped/publication-grouped CV R² (#67) — needs a pipeline run on `battery-electrolyte-predictor`. The discussion now **honestly routes this to future work**, so the thesis is coherent and submission-ready WITHOUT it. Running it would lift 3.2 toward the top of the band by converting the "indicative" generalisation claim into a quantified one; not required.

---

## Grade band

- 3.2 Analysis & discussion (20): **17–18** (argues, leakage-honest, theory-coherent, ethics; ceiling is the genuine n=3 generalisation base, which the text now handles with exemplary honesty).
- 3.3 Conclusion (5): **5** (concludes, commits the verdict the discussion defers).
- 4.2 Language (5): **5** (humanizer pass clean, 0 prose em-dashes, crutches thinned).
- Mechanics: 0 dangling refs, 0 guardrail leaks, all numbers macro-locked, abstract/front-matter clean.

**Overall: clean A on the written thesis, submission-ready.** The grade now rests entirely on two operator decisions outside the writing: (1) finish + un-red Future Work, (2) optionally run the grouped-CV (#67) to firm the ML-rigour ceiling. No writing blockers remain. Advocate ("clean A end-to-end"), adversary ("one HIGH item — now resolved"), and judge concur.
