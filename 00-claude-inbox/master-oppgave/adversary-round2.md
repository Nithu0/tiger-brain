# thesis-3 — ADVERSARY ROUND 2 (deepest pre-submission critical pass)

**Date:** 2026-06-03 · **Role:** AGAINST (harshest sensor) · **Panel:** t2=for / **t3=against** / t4=judge
**Method:** 10 disjoint read-only sub-examiners (language×3, source-integrity, source-coverage, figures, numbers/tables, coherence, MTP-2026 regrade, LaTeX/form) + 1 synthesiser. ~1.0M tokens, 556 tool-calls. Every finding re-verified against the live files. **Diagnose-only — no repo edits.**
**Benchmark example thesis identified:** Mjanger 2025 (Na-Mn hexacyanoferrate), an A-grade thesis (~89/100 on the rubric).

> Prosecution brief: deliberately harsh, credits only what survives verification.

---

## HEADLINE: prosecution grade **B / ~85–87**, conditional on 3 submission-state blockers → **A−/B+ (~88–91)** once cleared

**Big upward revision vs my prior D→C+/B−.** After reading the real files: the science is sound, citation integrity is clean, the generalisation gap is handled with genuine maturity, and my own earlier "deploy objective unmet" finding is now **dead** (line 60 was changed to "validate" at commit `46deb95`). **No BLOCKER-level *scientific* error exists.** What remains is (a) three submission-state blockers the operator already knows, and (b) one pervasive macro-discipline hygiene failure.

## (1) BIG ERRORS — BLOCKER (submission-state; operator must clear before Inspera)

All three are operator-owned/known, but each is grade-band-threatening if shipped:

- **`main.tex:181,189`** — Conclusion + Future Work still wrapped in `\begingroup\color{red}...\endgroup` → two whole chapters render red. The wrapper-removal (not the prose) is a hard pre-submission gate.
- **`discussion.tex:20,59,70,79,88,139`** — seven `\sv{[Spørsmål til deg]}` author-questions, red, in the 20-point Discussion. You're answering these personally; flagging only that **all** must be resolved + `\sv{}` stripped. Any one left visible = "non-final thesis".
- **`dataset_results.tex:37`** — `[Pending data]` flag: `fig:data_family` (re-filtered) vs `tab:family_counts` + Ch.4 totals (old 6,555 file). Known, supervisor-blocked. Visible data-consistency defect if it ships unreconciled.

## (2) MAJOR (point-costing) — ranked, agent-safe (number-neutral) fixes

1. **Macro-discipline failure — the dominant systemic issue.** `discussion.tex` is fully macro-driven (`\rsq`, `\valRsq`, `\valMAE`, `\bestModel`…); **`Abstract`, `conclusion`, `ml_results`, `Methodology` hardcode the same canonical numbers.** Verified instances: `Abstract.tex:13-14,22-24,29-30,38`; `conclusion.tex:14-16,31,36-37`; `ml_results.tex:18,69,77-78,123,136`; `Methodology.tex` captions. **Fix:** swap each literal for its existing macro (`\nRawRows`, `\nPapers`, `\nCompositionsRaw`, `\nRows`, `\nCompounds`, `\nFeatures`, `\rsq`, `\rmseLog`, `\maeLog`, `\valRsq`, `\valMAE`, `\valRMSE`). **Change no values.** Directly violates the "numbers LOCKED to macros" principle; every number-touching lens found it independently.
2. **`ml_results.tex:170`** — figure caption labels predictions `(``AI'')`. XGBoost is a regression model; "AI" is scope-inflating. → `(``Predicted'')` or `(``Model'')`.
3. **`Methodology.tex:339-344` + `:242`** — present tense in a past-tense methods section ("span", "is included", "uses", "is seeded", "are not used"). → past tense. *(Apply by string match — lens line-numbers drift by ~1.)*
4. **`Theoretical_Background.tex:372`** — mixed dash conventions in one sentence (`data-driven--then--first-principles ... --- ...`). Reads careless/automated. → rewrite to drop nested dashes.

**Down-graded to advisory (NOT scored MAJOR):** the four "reframe the generalisation caveat to look stronger" findings (`Abstract:33-41`, `discussion:133-140`, `ml_results:120-140`). The honest framing is verified and is a **strength** — counselling you to invert emphasis risks the integrity that earns marks. Optional emphasis polish only.

## (3) FINPUSS (grouped — for editor agents / humanizer skill)

**Language / register / AI-isms (low density — one copy-edit pass, NOT a rewrite):**
- `discussion.tex:14` "It says that" → "This indicates that"; `:16` "land within"→"fall within", "single fortunate algorithm choice"→"the choice of any single algorithm"; `:29` "leakage artefact"→"data-leakage bias".
- `Theoretical_Background.tex:264` "plays a distinctive role"→concrete verb; `:303` passive "It is measured by EIS"→active; `:339` "A caveat is essential"→direct; `:229-232` robotic "X fixes Y" parallelism→vary.
- `Introduction.tex:18` "AI/ML" first-use unexpanded → expand once.
- Vague quantifiers (number-neutral, signpost to existing table/macro): `dataset_results.tex:101,137-138`, `ml_results.tex:193-194`.

**Dash/style:** `discussion.tex:137`, `Methodology.tex:170-171` (bare `---` at line start) → normalise to inline ` --- `.

**Figures / form:**
- `Methodology.tex:80` includegraphics → `Images/Skjermbilde 2025-12-09 195824.png`. Raw screenshot filename in a thesis = professionalism flag. Rename publication-safe + update ref.
- `discussion.tex:124` `\Cref{...}` missing spaces after commas — cosmetic.
- `Future_Work.tex` section headers lack `\label` (none cross-referenced) — pattern consistency only.
- `references.bib:411-420` `Musielewicz2024ConformalGNN` uncited → delete (it's a conformal entry; removal is guardrail-clean).

**Sourcing transparency (sources exist, just signpost):** `Abstract.tex:47` add `\cite{Muy2018Lattice}` to the 0.296 eV benchmark; `Introduction.tex:56` strengthen that the first-principles work was supervisor/PhD-performed (mirrors `ai_disclosure`). Do NOT invent the four-factor-maturity / 50–100 meV citations — leave as-is if no clean source.

## (4) THE 5 MOST DANGEROUS DEFENCE QUESTIONS

1. **"Your headline R²=0.971 is interpolation — temperature is a feature and other temperature points of the same composition are in training. What does it prove about a genuinely new material?"** *(Pre-empted at `discussion.tex:14-29`, but be ready to defend why 0.971 — not 0.89 — leads the Abstract.)*
2. **"Generalisation rests on n=3 randomly-selected compositions. How do you defend a claim across 9 families / 452 compositions from 3 points — and how do you know those 3 aren't near-siblings of training rows?"** *(Thesis says "indicative"; examiner will press on cherry-pick risk and confidence interval.)*
3. **"LiBiO₂: one composition, one 300 K AIMD, NEB 0.27 eV vs 0.296 eV — inside DFT error (±0.05 eV). Why is that 'validation' and not a consistency check on a single candidate from your supervisor's prior work?"**
4. **"The DFT/AIMD was done by the computational collaboration. What is *your* contribution vs the supervisor/PhD — and where is the Author-Contributions statement?"** *(`chapters/drafts/contributions.tex` (206 lines) still NOT merged into `main.tex`; attribution lives only in `ai_disclosure`. Real 2.4-independence exposure.)*
5. **"You call processing the 'single largest curation effort' then discard it as too sparse (<15%). If processing drives conductivity and you predict the literature average, isn't your target ill-defined and part of your residual just unmodelled processing?"** *(Also viable: "Magpie is composition-only — two polymorphs → identical features. How do you predict a structure-sensitive property?")*

## (5) GENUINELY STRONG (conceded honestly)

- **Citation integrity is clean** — all `\cite` resolve; the 4 discussion citations used correctly; problem citations (Hikima2020, Kucinskis2022) already purged; audited verification pipeline disclosed. No wrong-paper risk in active text.
- **Generalisation-gap handling is the intellectual high point** (`discussion.tex:14-29`) — honestly separates 0.971 interpolation from 0.89 holdout, builds a stricter test, refuses to oversell. Criterion-3.2 maturity.
- **Scope discipline correct** — inorganic single-phase bounded (`Introduction.tex:70-80`); zero forbidden-prototype machinery in active text.
- **AI-language density is LOW**, concentrated in one chapter (Theoretical_Background). Intro/Methodology/Abstract are clean.

## (6) FINDINGS I DISCARD — for the judge (thesis-4)

- **❌ FALSE: "deploy objective unmet" (coherence lens, `Introduction.tex:60`).** Verified: line 60 reads "build, evaluate, and **validate**" (commit `46deb95`). The lens read a stale mid-run version. Thesis delivers build+evaluate+validate. Discard entirely. *(This was my own prior-round finding too — now obsolete.)*
- **⚠️ DOWNGRADE: the four "reframe to hide the generalisation caveat" MAJORs** → advisory only (overselling risk; see §2).
- **Line-number drift:** Methodology present-tense is real but at `:339-344`/`:242`; apply by string, not line number.

— thesis-3 (adversary)
