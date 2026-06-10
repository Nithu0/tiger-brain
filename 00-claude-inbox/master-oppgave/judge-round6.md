# JUDGE — ROUND 6: whole-thesis submission-readiness audit

**thesis-4 (dommer) → thesis-1.** 2026-06-05. READ-ONLY: edited nothing. 7 disjoint subagents across ALL chapters + main.tex + front-matter (proactive — no new dispatch yet; discussion+conclusion done at round 5, thesis-1 since moved to Future Work / numbering / metadata). Citation convention noted as DELIBERATE (theory-only) per round-5 dispatch — NOT re-flagged.

## VERDICT: GREEN — submission-ready bar one operator-owned wrapper + one optional A-lever.

The thesis is clean. No surprise red/draft text, no dangling refs, no guardrail leaks, no stale numbers, no placeholders in any compiled file. Both must-fixes from round 5 (the "twelve orders" alignment + hardcoded 0.946/0.971) should still be confirmed applied — they were in discussion.tex; not re-audited here, flag to verify.

---

## 1. Red/draft markers — 0 MUST-CLEAR (dominant gate is GREEN)
- **Only red that renders:** Future Work chapter wrapper, `main.tex:216` `\begingroup\color{red}` → `:220` `\endgroup`. **KNOWN-PENDING** (operator finalising the chapter). To clear at submission: delete lines 216 + 220 + comment banner 212–214/221.
- **Conclusion wrapper: REMOVED** ✓. **md_verification 3 red author-questions: CLEARED** ✓. **dataset_results.tex:37 `\sv{[Pending data]}`: RESOLVED** ✓ — `tab:family_counts` now populated (the filtered family file landed; 21-nitride reconcile done).
- Everything else flagged by grep is a false positive (the `\sv` macro definition at main.tex:32 has zero call sites; "red" = oxygen atom colour in md_verification; "draft" = LLM-DB-construction prose in theory).

## 2. Future Work chapter — PASS (8.5/10)
Forward-looking only; no smuggled results, no re-derived theory. The **LiAgent co-authored platform** is honestly attributed via `\cite{Alnubani2026LiAgent}` (@unpublished, operator named among 4 authors, "submitted to J. Power Sources") and is the coherent payoff of the discussion's living-platform thread. **Guardrails correctly contained here:** SHAP/OOD/conformal appear only as forward-looking, group-pursued refinements (L51–53), never named, never claimed done. Each discussion limitation → a future direction (clean mapping). British, no AI-isms, `\Cref` resolve.
- Minor polish (optional): L49 dup of the Eₐ-availability fact + §Multi-Output/§Eₐ-Extension overlap (merge or cross-ref); L39 present-tense "LiAgent collects, filters…" → "is designed to…" (only near-overclaim clause).

## 3. Cross-ref integrity after restructure — PASS
0 dangling refs (all 71 targets resolve), 0 duplicate labels. The 32 `\subsection*`→`\subsection` conversion is clean — all numbered, all `\Cref` resolve, no prose depends on a heading being unnumbered. fig 6.2 two-panel (`fig:md_cell`, unit cell + supercell) consistent. No `??` will compile.

## 4. Guardrails (whole thesis) — CLEAN, 0 leaks
No SHAP/OOD-method/conformal/GroupKFold-headline/MP-as-feature/polymer/R²≈0.14/HistGBM/V3-V4 presented as completed work anywhere. Feature rep consistent everywhere: **145 Magpie + measurement temperature = 146**, MP only at LiBiO₂ verification (mp-1205315 + convex hull). Inorganic single-phase consistent. No prototype narrative (final pipeline 4407/342/0.971 throughout).

## 5. Front-matter / abstract — CLEAN
Abstract reflects final framing + numbers (all match macros: 6555/187/452/4407/342/146, R²=0.971, holdout 0.89, NEB 0.27 vs 0.296), incl. the data-is-the-bottleneck thesis. Title consistent + on-scope. Supervisor (Kotiba Hamad) / TMM4960 / MTP present, no placeholders in compiled files. Acknowledgments clean (librarian removal left no residue). List of Symbols/Abbreviations present + accurate.
- Minor (cosmetic): `E_h` upright subscript in List of Symbols vs italic `E_h` in body — unify (body form is more frequent).

## 6. FOR/AGAINST adjudication — advocate's disc:L52 flag = REFUTED
thesis-2 (round-4) flagged disc L52 ("survey of prior screening studies" → `subsec:literature_ml`) as a promise-mismatch. **FALSE ALARM.** The target section explicitly names Sendek et al. (the canonical 12,000-candidate screen), surveys the screening line, AND establishes the interpolation-vs-held-out gap the sentence leans on. All 5 high-stakes discussion `\Cref`s deliver what their sentence promises (soft-anion→sse_overview, nitride→sse_overview, data-fragmentation→data_problem, predecessor→phonon_dos_predecessor). PASS — no fix. (thesis-1 may stand down on that item.)

---

## THE ONE REMAINING GRADE LEVER (operator/code decision)

**Composition-grouped CV R² — STILL OPEN.** Generalisation evidence remains ONLY the n=3 holdout (R²_log=0.89); no grouped-CV number landed (the five-fold CV at ml_results.tex:30 is random row-level, for model selection). This is the single decisive A-vs-B lever on the ML core: it converts the "indicative" generalisation claim into a quantified one (lifts 3.2 toward 19, clears 2.2 off 🟡). **It needs a PIPELINE RUN on `battery-electrolyte-predictor` (RUBRIC #67) — not a writing fix, outside the panel's read-only scope.** Operator decision: worth a run before submission? If not feasible, the thesis is honest about the gap (avoids a fail) but the ML-rigour ceiling stays high-B.

## SUBMISSION CHECKLIST (what's left)
1. **MUST:** strip Future Work red wrapper (main.tex:216–220) once the chapter is finalised. [operator-owned]
2. **MUST (verify):** confirm round-5 discussion must-fixes landed ("roughly twelve orders" + macro-ised band 0.946/`\rsq`).
3. **A-LEVER (optional, code task):** grouped-CV R² run (#67). The only thing between high-B and clean-A on the ML core.
4. **POLISH (non-blocking):** Future Work L39/L49; `E_h` notation; the round-5 SHOULD-list (drop "very", soften repeated "data not model" refrain).

**Bottom line:** Body chapters 1–8 are submission-clean and A-capable. The grade now hinges on (a) finishing + un-redding Future Work, and (b) the operator's call on the grouped-CV run. No other blockers.
