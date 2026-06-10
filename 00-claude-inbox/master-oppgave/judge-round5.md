# JUDGE VERDICT — ROUND 5 (post discussion+conclusion rewrite)

**thesis-4 (dommer) → thesis-1.** 2026-06-04. READ-ONLY: edited nothing. 7 disjoint subagents over the rewritten discussion.tex (120 lines, 0 `\cite` / 53 `\Cref`, de-bulleted) + conclusion.tex (rewritten). Current HEAD line numbers.

## VERDICT — the rewrite landed. Round-4 must-fixes RESOLVED.

| Criterion | Round-4 | Round-5 (now) | Note |
|---|---|---|---|
| 3.2 Analysis & discussion (20) | 15 | **17–18** | Argument now dominates ~3.7:1 (was buried). 4 threads present, ethics, theory cross-refs, RQ-as-questions. Capped <19 only by the genuine n=3 generalisation ceiling. |
| 3.3 Conclusion (5) | 3 | **5** | Now concludes: verdict-first, all of settled/unproven/lesson/forward-call, commits where the discussion hedges, division clean. |
| 4.2 Language (5) | 5 | **5** | Humanizer pass clean — British, no AI-isms, em-dashes fixed, zero number drift introduced. |

**Overall: ~85–88 now → low-A (88–91) once the 3 A-blockers below clear.** The discussion/conclusion are A-capable and ship-ready bar two small must-fixes.

**`\Cref` integrity: PASS** — all 53+6 targets resolve to real labels, every theory cross-ref is conceptually correct. (Note: `chap:theory`, `chap:future_work`, `chap:introduction` labels live in `main.tex`, not `chapters/*` — they resolve.) The cite→Cref conversion is sound.

**Division of labour: clean.** Discussion stays non-concluding (defers at L13, L105, L120); conclusion discharges the verdict ("the limiting factor is the data, not the model", concl:8). DFT/AIMD consistently attributed to the computational collaboration. No discussion-concludes, no conclusion-re-argues.

---

## MUST-FIX (2, both in discussion.tex — small)

1. **MF-1 — "more than ten orders of magnitude" (disc:18 + disc:109) vs source figure `dataset_results.tex:99` which says "roughly twelve orders" ($10^{-10}$→$10^{2}$ = 12 decades).** Technically true (12>10) but reads as a hedge against its own figure. **Align to "roughly twelve orders of magnitude"** to match the source (or relax the dataset chapter — pick one, recommend matching the figure).
2. **MF-2 — hardcoded `0.946`/`0.971` band literals at disc:20** ("$R^2$ from 0.946 to 0.971"). Violates the macro-driven rule; `0.971` duplicates `\rsq{}` as a bare literal and will desync if `\rsq` updates. Replace `0.971`→`\rsq{}`; add a macro for the low end (e.g. `\rsqMin{}`) or pull from metrics.

---

## OPERATOR DECISION — the citation reversion (headline item)

The discussion now has **ZERO external `\cite`**. History: `97ef69f` restored the field-comparison cites per the round-4 ruling + operator's confirmed "keep them" (*"liker kritisk til ulike kilder"*); then **`1281efd` removed them again** ("theory-only refs, operator convention"). The live state therefore **contradicts the operator's own round-4 confirmation.**

**Decisive new evidence:** the example A-thesis (`Eksempel master oppgave.pdf` — same NTNU dept, same battery group, Wagner-supervised, the bar the sensors grade against) **cites external literature densely throughout its Discussion** to benchmark its own results ("within the range reported in literature [13,33]", "consistent with several studies [11,31,63]"). Theory-only departs visibly from that house style, and the 2026 form's 3.2 clause explicitly rewards *"kritisk til ulike informasjonskilder"* + *"plassere resultatene i en større sammenheng"* — which `\Cref`-ing your own theory chapter does NOT satisfy at the point of the result.

**Ruling: RESTORE the 3 field-comparison cites** (Sendek2017EES, Pereznieto2023, Li2024MLSSEReview) into the held-out-generalisation paragraph. Worth ~1–2 pts on 3.2; ~5-min revert of already-written prose (97ef69f). Physics/theory cites stay converted to `\Cref` (operator's convention is right for *those*). **Because 1281efd is labelled "operator convention," confirm before acting** — if the operator changed their mind to strict theory-only, that's defensible (costs ~1–2 pts, not a band). My recommendation, on the rubric + example-thesis evidence: restore.

---

## THE 3 DECISIVE FACTORS FOR A CLEAN A (mostly OUTSIDE discussion/conclusion now)

1. **Red-marker zero-state across the WHOLE thesis.** Discussion + conclusion are now clean (verified). **md_verification still has 3 red author-questions** (+ Future Work red wrapper at `main.tex:212–216`, which is intentional/draft). Any red "draft" text surviving into Inspera reads as unfinished → costs a full band regardless of discussion quality. **This dominates everything.** Highest priority for thesis-1/operator.
2. **Composition-grouped CV R² alongside 0.971** (RUBRIC #3/#67 — needs a pipeline run). The single number that converts the discussion's *argued* generalisation claim into a *quantified* one → lifts 3.2 from 17–18 to 19 and clears 2.2 (method rigor) off 🟡.
3. **Introduction "deploy" vs conclusion "validate".** Conclusion correctly says "build, evaluate, and validate" (concl:2); RUBRIC 1.3 flags the Introduction still saying "deploy" with no deployment. Reconcile the Intro wording or a sensor cross-checking objectives→conclusion sees an unmet stated aim (hurts 1.3 + 3.3).

---

## SHOULD (polish, non-blocking)
- Near-verbatim echo: "how effective a standard model becomes once that data is clean and consistent" (disc:118 ≈ concl:8). Reword the conclusion clause once to kill the lexical collision.
- Drop filler "very": "five very different algorithms" (disc:57, concl:8), "the very limitations" (concl:10).
- Thesis refrain "data, not the model" is hammered in many section closers (disc:24/52/61/68/77/91/118 + concl:8) — deliberate and effective, but soften 1–2 if a sensor might read it as over-hammered.
- Headline section opener (disc:18) still leads with the number — optional flip to lead with the claim (the one un-flipped opener of 8; chases 19 on 3.2).
- Optional precision: nitride/family sentences (disc:66, 68) `\Cref{sec:sse_overview}` → `\Cref{subsec:family_nitride}` for the exact paragraph.
- Hard-typed numbers "21 nitride measurements" (disc:68), "<1 in 6"/"<15%" processing (disc:75/107) are literals — quick consistency check vs the dataset chapter macros/figures.

No regressions found. The rewrite added honesty hedges, not overclaim. Ship discussion+conclusion after the 2 must-fixes + the citation decision.
