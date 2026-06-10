# thesis-4 (DOMMER) — ROUND 3 FULL FINDINGS (all 7 lanes)

Companion to `judge-round3.md` (the ranked verdict). This file = **every finding from all 7 read-only subagents**, organised for line-by-line editing. READ-ONLY: thesis-4 made no edits. Target: `chapters/discussion.tex` @ commit 4bef3b6.

Severity key: **BIG** = fix before submission · **should** = quality/B→A · **nit** = optional · **REJECT** = do not apply (fabrication/scope).

---

## A. MASTER LINE-BY-LINE TABLE (every flagged line, all lanes merged)

| Line | Lane(s) | Severity | Finding | Action |
|---|---|---|---|---|
| 4–7 | mechanical | should | Header comment "whole chapter is currently rendered in red" is STALE (only L22 is red now) | Update or delete comment |
| 9 | non-concluding | clean | Intro disclaimer "final position reserved for the conclusion" — good, holds up | keep |
| 14 | accuracy | should | "nine orders of magnitude" — dataset_results says raw data spans ~twelve; test set ~nine | Clarify "nine orders in the test set" |
| 16 | non-concluding | borderline | "The headline number is the measure of how well that task is solved." | Mild: "thus measures how well that task is solved in this evaluation regime" (optional) |
| 18 | citation, mechanical | should | Arrhenius/T-dependence claim uncited; `\Cref{subsec:arrhenius_ne}` points at a `\subsection*` (unnumbered) | Add `\cite{Muy2018Lattice}`; verify subsection numbered or use `\nameref` |
| 20 | language | STRONG-TELL | "Read this way, the high R²..." | Delete "Read this way, " |
| 20 | language | STRONG-TELL | "The fair reading is therefore that the model captures..." | → "The model therefore captures..." |
| 20 | language | borderline | "...it is supplied at the verification stage" (passive) | → "Independent structural plausibility is supplied..." (optional) |
| 22 | mechanical, accuracy, adjudicate | **BIG** | Leftover red `\sv{[Til deg]}` MP-as-feature note. Prose itself is correct (MP only at verification). | OPERATOR confirms framing + delete block (submission blocker) |
| 27 | adjudicate (FOR E3) | **BIG** | "three **randomly selected** compositions" then lists one nitride/one phosphate/one sulfide = one-per-anion-family. Internal contradiction vs Methodology's deliberate design. | OPERATOR states what was actually done; reword L27 + L50 to match. Adversary's prime attack. |
| 31 | non-concluding | **BIG** | "Taken together they support a single **conclusion**: the headline R²... reflects real structure–property learning" — uses the very word the chapter must avoid | → "point to a single reading: ... real structure–property learning rather than a leakage artefact" |
| 48,50 | accuracy | clean | Holdout caveat "indicative / based on three points / not strong enough to stand alone" — correctly bounded | keep |
| 50 | adjudicate (FOR E3) | **BIG** | "selected at random rather than hand-picked" — second half of the L27 contradiction | reword with M1 |
| 52 | citation | BIG-LEVER | ALL 4 cites (Pereznieto2023, Li2024MLSSEReview, Omee2024OODBenchmark, Sendek2017EES) sit in this one sentence; 7 other sections cite nothing | Distribute cites (see section B) |
| 52–53 | adjudicate | should | Cites are named but not analytically engaged ("listing not analysing") | Add 1–2 sentences comparing this work's holdout to prior ML-screen generalisation (no invented numbers) |
| 59 | mechanical | should | Hardcoded "4,407-row" — macro `\nRows{}` exists | → `\nRows{}-row` |
| 60 | citation | should | "model run on pilot data exposed problems" — feedback-loop-as-practice uncited | Add `\cite{Jaafreh2024PhononDOS}` |
| 66 | citation, accuracy | BIG-LEVER | Family E_a ordering (sulfides low / garnets high, 0.2–0.6 eV band) uncited; physically consistent w/ Theory | Add `\cite{Bachman2016ChemRev}` |
| 68 | citation, depth | should | Li₃N "low-barrier reputation" has NO matching bib key; nitride deviation noted but not explained mechanistically | Confirm Li₃N cited in Theory or add source; optional +1 sentence on *why* (coordination / publication bias) |
| 70 | citation | BIG-LEVER | Two-level intrinsic/extrinsic transport picture uncited | Add `\cite{Famprikis2019NatMater}` |
| 70 vs 72 | mechanical | nit | Redundant: both make "family label is a weak predictor" point | Condense (optional) |
| 72 | language | MILD-TELL | "The lesson for the model follows directly." | Delete; start next sentence at "Because conductivity varies..." |
| 72 | language | borderline | "not as learning a ranking... but as resolving..." (negative parallelism, 2nd in para) | optional tighten |
| 77 | citation, accuracy | should | "processing clearly influences measured conductivity" uncited; "<one row in six" matches <15% (consistent) | Add `\cite{Xue2018LLZOSintering}` (verify it supports a sintering/processing claim) |
| 81 | language | MILD-TELL | "In practice this prioritisation let the dataset grow..." | Delete "In practice " |
| 86 | accuracy | clean | NEB ~0.27 eV vs β-Li₃PS₄ 0.296 eV (Muy2018); single 300K AIMD — all bounded, matches md_verification | keep |
| 90 | language | STRONG-TELL | "The bounded reading is the right one: the predict-then-verify pipeline..." (echoes "fair reading" L20) | Delete "The bounded reading is the right one: " |
| 90 | language | borderline | "which is what makes it a fair test" (weak nominalisation) | → "making it a fair test" (optional) |
| 90 | accuracy | clean | mp-1205315 + energy-above-hull window framing matches md_verification; MP correctly at screening stage only | keep |
| 95–103 | depth | should | Limitations are a bare bullet list; A-level wants 2–3 reflective sentences each (why it matters + mitigation) | Convert to short prose (nice-to-have N1) |
| 110–132 | non-concluding, adjudicate | borderline | §7.9 "Answers to the RQs" table; RQ4 answered "Yes." Possible pre-emption of conclusion / redundancy | STRUCTURAL DECISION for operator: keep if conclusion synthesises (not repeats); RQ4 already bounded — do NOT over-hedge |
| 137 | language | MILD-TELL | "Read together, the three results outline..." (echoes "Read this way" L20) | Delete "Read together, " |
| 139 | non-concluding | **BIG** | "these pieces sketch the core architecture of an expandable screening platform" reads as a deliverable verdict | → "outline a possible direction: a curated data foundation, a trained model, and a verification pathway" |

---

## B. CITATION PLAN (lane 1 — the #1 grade lever; all keys already in references.bib)

| Section | Line | Claim needing an anchor | Suggested existing-bib key |
|---|---|---|---|
| 7.4 | 66 | family E_a ordering / 0.2–0.6 eV band | `Bachman2016ChemRev` |
| 7.4 | 70 | intrinsic vs extrinsic two-level transport | `Famprikis2019NatMater` |
| 7.1 | 18 | Arrhenius exponential T-dependence | `Muy2018Lattice` |
| 7.3 | 60 | model-as-data-diagnostic / ML-screening precedent | `Jaafreh2024PhononDOS` |
| 7.5 | 77 | processing → conductivity | `Xue2018LLZOSintering` (verify support first) |
| 7.4 | 68 | Li₃N low-barrier reputation | **NO bib key** — confirm cited in Theory or add source |

Target ≈ 5 well-placed cites: lifts the discussion criterion from "thin/assertion-heavy" to "adequately situated." Lane-1 estimate: ~14–16/20 → ~17–18/20. Do not pad for count.

---

## C. NON-CONCLUDING RULING (lane 2)

- **Holds overall.** Intro disclaimer + reframed §7.10 title ("Implications") are good.
- **Two BIG crossings:** L31 ("support a single conclusion") and L139 ("sketch the core architecture of an expandable screening platform"). Both soften easily (M4).
- **One structural question:** §7.9 RQ-table. Ruling = BORDERLINE, operator's call — keep if conclusion synthesises rather than repeats; RQ4's bounded "Yes." is acceptable.

## D. SCIENTIFIC SOUNDNESS (lane 3) — SOUND, 0 critical
All numbers resolve to macros / canonical facts (R²=0.971, RMSE 0.283, MAE 0.158 log; holdout R²_log 0.89 / MAE 0.02 / RMSE 0.142 mS/cm; 21 nitrides; <15% processing; NEB 0.27 vs 0.296). Holdout & LiBiO₂ honestly bounded. MP never claimed as a model feature. Only substantive item: "nine vs twelve orders" wording (L14).

## E. MECHANICAL (lane 5) — QUALIFIED PASS
- All 26 `\Cref` targets resolve; all 11 macros defined.
- L18, L27 `\Cref` → `\subsection*` (unnumbered): confirm numbered or use `\nameref`.
- L59 hardcoded "4,407" → `\nRows{}`.
- L4–7 stale header comment.
- L70/72 minor redundancy.

## F. DEPTH vs A-BAR + Eksempel-master (lane 6)
- Discussion-criterion estimate: **B+/low-A (~16–18/20)**, sections 7.1/7.2/7.3/7.5/7.6/7.8/7.9 at A; 7.4 (nitride not explained) and 7.7 (bullets not prose) at B+.
- Needle-movers to clean A: nitride mechanistic sentence (N3), limitations as prose (N1), distributed cites (M2).
- ⚠️ This lane also proposed fabricated benchmark numbers + new subset experiments — see REJECT.

## G. ADJUDICATION of FOR/AGAINST round-2 vs current (lane 7)
| Finding | Source | Ruling | Note |
|---|---|---|---|
| "discussion has 1 cite" | judge-R2 | OVERSTATED on count (=4), concern LIVE | distribution still thin → M2 |
| Holdout "randomly selected" vs one-per-family | FOR E3 | **LIVE** | M1 — internal contradiction |
| MAE 0.02 vs RMSE 0.142 (7×, n=3) under-disclosed | FOR E1 | partially LIVE | hedged but not explained; optional N6 |
| 6 of 7 §7 author-questions | adversary/judge R2 | FIXED | 1 remains (L22) → M3 |
| Ethics section missing | judge R2 | FIXED | §7.8 landed, substantive |
| "deploy" objective | judge R2 | FIXED | Intro now "validate" (out of disc scope) |
| LiBiO₂ structure mp-28253→mp-1205315 | judge R2 | FIXED | matches md_verification |
| Numbers/macros drift | FOR | CLEAN | zero mismatches |
| LiBiO₂ "discover new conductors" overclaim | adversary | NEVER-VALID in current text | bounded throughout |
| Conclusion/Future_Work red wrappers (main.tex:181-189) | R2 | LIVE but OUT of discussion scope | operator finalises those chapters |
| Future_Work.tex:50 names conformal/SHAP/OOD | judge R2 | LIVE, operator decision | out of discussion scope; guardrail-adjacent |

## H. ⚠️ REJECT LIST — do NOT apply (fabrication / scope)
- Specific benchmark numbers "Sendek R²≈0.94", "Pereznieto R²=0.88" — **invented by the subagent.** If a benchmark is wanted, operator must quote real reported metrics from the actual papers.
- "Trained models with/without processing → R²=0.81 vs 0.88" subset experiment + OOD descriptor-distance values — **invented.** Presenting as done work = misconduct. Processing-exclusion stays qualitative.
- Lane-2's push to rename §7.9 and hedge RQ4 — declined (over-hedges a correctly-bounded answer).

---

**Bottom line for thesis-1:** apply M1–M4 + the 6 language deletions + distribute the 5 cites = discussion to a clean A, no new experiments, all tonight. Nice-to-haves N1/N3 add polish. Watch the REJECT list — two subagents tried to smuggle in fabricated numbers.

— thesis-4, ROUND 3 full findings
