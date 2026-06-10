# thesis-3 — Adversarial Review Verdict (CRITICAL examiner)

**Date:** 2026-06-02 · **Panel:** thesis-2 (for) / **thesis-3 (against — this report)** / thesis-4 (judge)
**Method:** 10 hostile sub-examiners, one per MTP-2026 rubric dimension, each reading the real `chapters/*.tex` against `references/criteria.md` + the MTP assessment PDF + *Eksempel master oppgave.pdf* as the bar. Findings reconciled into one verdict; cross-checked by re-grepping the source.
**Workflow:** `wjqrfbxeu` (11 agents, ~1.13M tokens, 421 tool-calls).

> Stance disclaimer: this is the *prosecution* brief. It is deliberately harsh and credits only what it must. The supportive case is thesis-2's; the balance call is thesis-4's.

---

## OVERALL (prosecution estimate): **D, ~62/100** as submitted — but a **C→B, ~72–78** after 3 mechanical fixes

The underlying work is **not failable**: a real 6,555-measurement / 187-publication curated dataset, a five-model comparison, and an honest leakage diagnosis. The grade is bled out by **state-of-submission** problems and **discussion depth**, not by the science.

| Rubric | Max | Points lost (prosecution) | Why |
|---|---:|---:|---|
| 4. Presentation | 15 | −8 to −10 | Core chapters submitted as visible DRAFT |
| 3.2 Analysis & discussion | 20 | −8 to −10 | **Zero** external citations; listing not analysing |
| 1.2 Theoretical insight | 10 | −4 | Competent synthesis, no theoretical mastery/contribution |
| 2.4 Independence | 5 | −2 to −3 | No Author-Contributions statement; DFT/AIMD attribution ambiguous |
| 3.1 Results | 10 | −2 | N=3 generalisation; stale contradictory metrics file in repo |
| 1.3 Objectives | 5 | −1 to −2 | Unmet "deploy" objective; RQ2 compound-question only half-answered |

---

## TOP 5 — fail-or-downgrade, ranked by grade impact (all CONFIRMED by re-grep)

1. **Core chapters submitted as visible draft.** `main.tex:145–156` wraps Discussion/Conclusion/Future Work in `\begingroup\color{red}`; `main.tex:140` comment says "still in draft and awaiting review." Binary, visible on first flip-through. **Single biggest, least-defensible loss.** (4.1/4.2)
2. **Discussion has zero external citations.** `discussion.tex` → `grep -c "\cite"` = **0** over 134 lines. Rubric 3.2 explicitly: *"Er kandidaten kritisk til ulike informasjonskilder?"* No comparison to prior ML-SSE results, no placement in larger context. (3.2)
3. **Ten embedded supervisor-questions, mid-narrative, in Norwegian.** `discussion.tex:20,50,59,70,79,88,134` (7×) + `md_verification.tex:131,241,270` (3×). e.g. discussion.tex:88 asks the supervisor how hard to push the LiBiO₂ claim. An English thesis where the author asks the supervisor what to conclude → integrity + independence signal. (4.2 + 2.4)
4. **Stated "deploy" objective never delivered.** `Introduction.tex:60`: "build, evaluate, and **deploy**…" — no deployment/integration/API section exists. Overstates completed scope. (1.3)
5. **Generalisation rests on N=3 + a stale contradictory metrics file.** `ml_results.tex:149` R²=0.89 on three compositions; `results/thesis_metrics.json:28` carries `holdout_r2=0.144`, `best_model="Random Forest"`, `raw_rows=1827` — contradicts the thesis's 0.89 / XGBoost / 6555. JSON is an admitted uncited placeholder, but it ships in the repo and surfaces in due-diligence. (3.1)

## CROSS-CUTTING (multi-dimension)

- **Repo-artefact vs text metric mismatch** — thesis_metrics.json (1827 rows/148 papers/RF/0.144) vs text (6,555 measurements/187 pubs/XGBoost/0.971). Thesis prose is *internally* consistent (macros `\nPapers`/`\nRawRows`), so this is **hygiene, not text-level fraud** — but touches 3.1, 2.2, integrity.
- **Claims-outrun-evidence** — "promising extrapolator to new chemistries" (`discussion.tex:127–135`) on one LiBiO₂ case + N=3, while the same chapter disclaims that three compositions "cannot establish generalisation." Hedge-then-affirm contradiction recurs in 3.1/3.2/1.3.
- **Attribution opacity** — Ch.6 DFT/AIMD in passive voice ("were performed"); only `ai_disclosure.tex:113–121` reveals supervisor/PhD authorship "where indicated," but no indication appears in `md_verification.tex`. 206-line `chapters/drafts/contributions.tex` exists but is NOT in `main.tex`.

## THE ONE THING THAT MOST THREATENS THE GRADE

**The draft state of the submission.** Every other weakness is arguable on merits; this is binary and visible on first flip-through, and it bleeds into Independence (author on record asking the supervisor what to conclude). **Fix this one thing → grade moves a full band.**

## GENUINELY STRONG (conceded — so the judge trusts the attacks)

- **The dataset is a real contribution** — 6,555 measurements / 187 pubs / 452 compositions, ~4× the pilot, documented curation. Substantive, original.
- **Honest leakage diagnosis** — thesis itself flags R²=0.971 as interpolation (`ml_results.tex:136`) and reports the 0.89 composition-holdout drop. Self-critical and correct.
- **AI disclosure is exemplary** — `ai_disclosure.tex` states Claude "cannot be cited" and "No AI tool is cited as a source of fact." This is NTNU-*compliant*.

## TWO SUB-EXAMINER FINDINGS I REJECT (handed to the judge as discarded)

- ❌ **"Claude missing from bibliography violates NTNU rules"** (sub #9) — **backwards.** NTNU says LLMs *cannot* be cited for fact; not putting a non-citable tool in the reference list is correct. Discard.
- ⚠️ **"RQ2 silently omits processing / intellectually dishonest"** (sub #2) — **overstated.** `discussion.tex:72–80` (§7.4) explicitly explains processing was excluded (<1-in-6 coverage). Real weakness is the *answer table* compressing it — a synthesis/presentation issue, not dishonesty. Downgrade to minor.
- (Two "Test/test" placeholder entries from failed agents = 0 pts, excluded.)

## FASTEST PATH OFF D (mechanical, ~1 day)

1. Strip the `\color{red}` draft wrappers (`main.tex:145–156`). **+full band.**
2. Resolve/delete all 10 `[Spørsmål til deg]` / `[To supervisor]` tags — replace with the author's own committed position.
3. Add 8–12 citations to `discussion.tex` (Li2024MLSSEReview, Pereznieto2023, phonon-DOS work) + one paragraph comparing R²=0.971 to published SSE-ML benchmarks.
4. Delete or header-stamp `results/thesis_metrics.json` as non-canonical.
5. Merge `chapters/drafts/contributions.tex` into `main.tex`; add active-voice DFT/AIMD attribution in `md_verification.tex`.
6. Lead headline metrics with R²=0.89 (generalisation) before R²=0.971 (interpolation); label 0.971 as interpolation at first mention.

— thesis-3 (critical examiner)
