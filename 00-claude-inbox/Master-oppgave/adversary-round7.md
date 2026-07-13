# Adversary — ROUND 7 (FINAL pre-delivery)

Role: ADVERSARY (thesis-3 mandate), run from the thesis-2 pane per operator ("hjelp thesis 3, kjør på med alle 10 agenter").
Method: 10 read-only Explore subagents over disjoint areas + 2 self-verifications. READ-ONLY, no repo edits.
State reviewed: current committed tree @ `6be032b` (round-7 acks + Future_Work changes are committed, working tree clean).

---

## TL;DR

No compile-blockers, no broken refs/figures/macros, no stale superseded numbers, no dropped-prototype leakage into the compiled body. The thesis is submission-safe on mechanics. The remaining attack surface is **argumentative, not factual**: (1) composition-leakage in the headline split is acknowledged but not *quantified*; (2) the discussion makes three final-verdict statements that belong in the conclusion; (3) the "human curation is non-automatable" spine rests on anecdote; (4) the cite-free discussion is a deliberate operator convention but is also the single biggest grade-lever per the 20-pt criterion. Plus a handful of cheap polish fixes (one AI-tell, un-humanized acks paragraph, an uncited 93 % threshold).

Two agent findings were **false positives** — corrected below so nobody "fixes" a correct number.

---

## A. CORRECTIONS to raw agent output (do NOT action these)

- **E_hull 0.043 / density 7.48 g/cm³** (`md_verification.tex:71`) is **CORRECT** per the round-7 canonical (`0.043/7.48`, and the text rightly notes 0.043 is metastable). Agent-1 flagged it against the **stale** `memory/_panel_shared_context.md` (7.09/0.046). → Fix the memory file, not the thesis.
- **SHAP / conformal / HistGBM / V3 / V4 in `plan.tex`** — `plan.tex` is **not `\input` anywhere in `main.tex`** (verified). It never reaches the PDF. Not a guardrail breach. (Optional hygiene: delete or clearly mark `plan.tex` as a non-compiled scratch file so a future reader doesn't mistake it.)

---

## B. VALID findings, ranked by grade/defence risk

### 1. [HIGH — methodological] Composition leakage in the random 80/20 split is acknowledged but never quantified
The headline **R²=0.971** comes from a row-level split with temperature as a feature, so the same composition sits in train and test at different T. The thesis is honest that this is "an interpolation score" (`ml_results.tex:119-137`, `Methodology.tex:258-272`, `discussion.tex:15-25`) — good. But it **never states the magnitude**: what fraction of test rows belong to a composition seen in training? "For many compounds" is vague. This is the most likely examiner pounce and the cheapest to close.
→ **Fix:** add one sentence/number in Methodology or ML Results, e.g. "X % of test rows share a composition with the training set." A datapoint, not a re-run. (Owner: needs the pipeline → battery-electrolyte-predictor, not this repo.)

### 2. [HIGH — scope] Discussion pre-empts the conclusion's verdict in three places
Discussion is supposed to stay non-concluding (round-4+ design). These three sentences deliver a final verdict:
- `discussion.tex:57` — "where the scientific value of a project like this now sits"
- `discussion.tex:118` — "the most valuable thing this project produced may be the curated dataset itself"
- `discussion.tex:120` — "the curation judgement … arguably becomes the central scientific contribution"
→ **Fix (flag to thesis-1 / operator):** either soften to evidence-framing ("the results point to …") or accept the overlap. There is also a hedge mismatch: discussion says "may be" (118) while `conclusion.tex:8` states it as settled ("are therefore as much a result"). Align the certainty.

### 3. [MED — defence] The "not yet automatable" human-in-the-loop claim is anecdote-backed
`discussion.tex:59-61` argues curation judgement can't be automated, evidenced by an early model run exposing unit/format errors a static inspection missed. But unit confusion (σ vs log σ vs ln(σT); S/cm vs mS/cm) is largely **deterministic** and a validator could catch it. No counterfactual vs an LLM-assisted pipeline is given.
→ **Examiner Q (rehearse):** "If you'd fed raw PDFs to an LLM and human-verified only high-uncertainty rows, would the dataset be materially worse, and on what quantitative basis?" Soften "not yet automatable" → "still required human verification in this work," or split the genuinely-judgement step from the automatable cleanup.

### 4. [MED — strategic, operator decision] Cite-free discussion vs the 20-pt "place results in a wider context" criterion
By operator convention the discussion has **zero `\cite`** (all `\Cref` to theory — verified, 8/8 Crefs support their sentences). That convention is internally clean, **but** the assessment criterion explicitly rewards positioning results against external/competing work, and the prior judge already named citations/depth the #1 lever. The cite-free choice may itself cost a band on a 20-pt item.
→ **Operator call:** this is a deliberate convention, not a bug — but worth a conscious decision. If unwilling to add cites in the discussion, ensure the theory chapter's `subsec:literature_ml` carries enough explicit comparison that the `\Cref`s deliver real source-criticism.

### 5. [MED — optics] `@unpublished` self-citation of the group manuscript in front of an examiner
`Alnubani2026LiAgent` (student is 2nd author) cited in `Future_Work.tex:40` + acks. Confined to Future Work, no content leak into the body (verified) — that's the right containment. Residual risk: examiner reads citing one's own unpublished group paper as padding.
→ **Fix:** keep it FW-only (already done); optionally date the note (`Manuscript submitted June 2026 to Journal of Power Sources`). Rehearse the "it's context/future-work, not a thesis contribution" line.

### 6. [MED — source] 93 % relative-density threshold not in the verified corpus
`Theoretical_Background.tex:267` — "above 93 % of theoretical … practical threshold" cites `ApEnergy2025SSBReview`; verification log found no PDF passage stating 93 %.
→ **Fix:** add a page/figure locator or de-quantify ("above a critical relative density").

### 7. [MED — depth] Results chapters are thin; no per-family error breakdown
ML Results (~1.4k words) and Dataset Results (~1.5k) are lean vs the example thesis, and there is **no per-family R²/MAE** to back the "data, not model, is the limit" spine or to rebut "the model just memorises garnet/sulfide." Dataset imbalance is acknowledged (`dataset_results.tex:67-68`, `discussion.tex:88-95`) but not quantified by error.
→ **Fix (highest-yield depth add):** one subsection + figure of test error vs per-composition data density / by family. Directly arms attacks #1, #3 and the imbalance question.

### 8. [LOW — AI-tell] One surviving inflated phrase
`discussion.tex:113` — "This **stands as** a proof of concept" → "This is a proof of concept." (Forensic sweep otherwise clean: em-dashes only in comments; `--` compound terms and table N/A cells correctly exempt.)

### 9. [LOW — un-humanized acks] The Alnubani paragraph hasn't had a humanizer pass
`acknowledgments.tex:10-12`: name spelling matches the bib exactly ("Ramzi A. A. Alnubani") ✓; "led the manuscript" justified by first-authorship ✓. But: "platform **that this thesis feeds into**" is awkward; "**now submitted for publication**" dangles and (unlike `Future_Work.tex:40`) does **not** name the Journal of Power Sources — inconsistent.
→ **Fix:** e.g. "…who built and extended the LiAgent platform that incorporates this thesis's dataset and model, and who led the accompanying manuscript, now submitted to the Journal of Power Sources."

---

## C. CLEAN (attacked, held up — do not re-flag)

- **Static integrity:** 277 `\cite` keys all defined; 89 `\Cref`/labels all resolve; 28 `\includegraphics` all exist (case-correct); all macros defined; no duplicate labels; only intentional red wrapper = Future Work.
- **Numbers ↔ macros:** every hard-coded figure matches `thesis_macros.tex`; family counts sum to 6555; no stale `mp-28253` / `Ibam` / `2.04` / "twelve orders" / `900 °C` / `R²≈0.14` anywhere.
- **No dropped-prototype leakage** into any compiled chapter (the only hits are in non-compiled `plan.tex`).
- **Abstract ↔ body** consistent; no over-promise. LiBiO₂ framed as proof-of-concept throughout.
- **Fig 6.2** two-panel caption is deliberately atom-count-neutral and does **not** contradict the body's Li₃₁Bi₃₂O₆₄ / 127-atom statement; panel (a)/(b) labels match the text.
- **Sendek** appears 4× in Theory but each serves a distinct function (motivation / taxonomy / table / methods deep-dive) — layering, not redundancy.
- **Methodological honesty:** single-300 K AIMD, n=3 holdout, composition-only features all carry explicit "indicative / proof-of-concept / order-of-magnitude" caveats. Attacks land on *missing quantification*, not on overclaim.

---

## D. Top-5 defence questions to rehearse

1. **"R²=0.971 is just Arrhenius interpolation on compositions you've already seen."** → report both metrics; headline = screening/interpolation score by design, holdout R²=0.89 is the generalisation guard. (Strengthen by quantifying the train/test composition overlap — see B1.)
2. **"You only validated on LiBiO₂, a known conductor from the paper that motivated it — circular."** → not a discovery claim; predict-then-verify workflow runs end-to-end and *reproduces* known transport. Quote `discussion.tex:84-86`.
3. **"n=3 holdout is anecdotal."** → conceded as "indicative not statistically tight"; the three span distinct anion frameworks; it's data-limited, not model-limited. (Add bootstrap CI if time.)
4. **"What happened to the 2,148 dropped measurements (6555→4407)?"** → formula-parseability filter only, family-agnostic; conductivity+T present in ~all rows. Quote `Methodology.tex:216-224`.
5. **"How does a 0.27 eV NEB barrier + 1 ps AIMD give you a room-temperature conductivity?"** → it doesn't; AIMD is a mobility plausibility check, conductivity comes from the model. Quote `discussion.tex:84-85`, `md_verification.tex:57-65`.

---

## E. Recommended pre-submission order (by yield/effort)
1. B8 + B9 (AI phrase + acks rewrite) — 10 min, zero risk.
2. B2 (discussion non-concluding) + hedge alignment — operator call, 20 min.
3. B6 (93 % cite) — 10 min.
4. B1 + B7 (quantify composition overlap + per-family error) — needs a pipeline run in `battery-electrolyte-predictor`; highest defensive payoff.
5. B4 (cite-free discussion) — conscious operator decision, not a quick edit.

Also: update `memory/_panel_shared_context.md` to the round-7 canonical (0.043/7.48) so future panels don't re-raise the false positive.
