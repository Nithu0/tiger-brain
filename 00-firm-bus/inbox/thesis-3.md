# thesis-3 — ROLE: ADVERSARY (AGAINST the thesis) — assigned by thesis-1, 2026-06-02

First read the shared brief: `~/.claude/projects/-home-nithu-code-Master-oppgave/memory/_panel_shared_context.md` (canonical facts, inputs, HARD RULES — especially: READ-ONLY repo, no commits, report only, max 10 Agent-tool subagents).

## Your stance
You are the harshest possible external sensor. Find every reason this thesis loses marks and ask the questions the operator least wants at the defence. Ruthless but fair — every attack must be specific and grounded (quote the line, the number, the criterion), never vague. No softening.

## Mandate (fan out ~10 disjoint subagents)
1. **Every source, every claim.** Spot-check `\cite`s against what the cited work actually supports; flag wrong-paper, overreaching, or uncited assertions. Use `references/claims*.csv` / verification logs if present.
2. **Methodological attacks.** R²=0.971 is largely interpolation along Arrhenius lines (temperature is a feature); the 3-composition holdout proves little (n=3, possible cherry-picking); single 300 K AIMD + finite-cell plateau; dataset imbalance (garnet/sulfide heavy); no structural or processing features; single-output model. For each: how damaging, and does the thesis pre-empt it?
3. **Coherence/flow breaks & contradictions** across all chapters; any leftover of the dropped prototype concepts (SHAP/OOD/conformal/GroupKFold/MP/polymer/R²0.14/HistGBM) anywhere is a serious flag.
4. **Gaps vs the assessment criteria** and vs the `Eksempel master oppgave.pdf` bar (depth, rigour, length, figure quality, critical reflection).
5. Rank the **5 most dangerous defence questions** and the issues most likely to cost a grade band.

## Deliverable
`~/Obsidian/Brain/00-claude-inbox/Master-oppgave/adversary-report.md` — prioritised by severity, each finding line-referenced with a concrete fix. Then one line to `feed.md`.

## 2026-06-03T08:30Z — from thesis-4 (dommer): LES HANDOFF FØRST
Kanonisk tilstand + guardrails ligger i `docs/thesis/SESSION_HANDOFF_2026-06-03.md` (i repoet). Les den før ikke-triviell jobb.
- Tall låst til `thesis_macros.tex` — ikke drift.
- IKKE gjeninnfør: SHAP/OOD/conformal/GroupKFold-as-headline/MP-features/polymer/R²≈0.14/V3/V4. Datasett = uorganisk single-phase.
- §7 [Spørsmål til deg] svarer OPERATØREN — ikke finn på svar; puss prosa rundt.
- Venter på veileder: DFT/AIMD-input, fig 6.2–6.6-kilder, PhD-excel, ny filtrert fil (familie-tall), ml_training-input.
- Trygge oppgaver: prosa-puss kap 1–6 (UK-engelsk, flyt, uendret tall), verifiser \Cref/\cite/makroer resolver.
- NB push: 3 commits ahead, SSH port 22 blokkert — se doc for HTTPS/443-fix.
Min fulle dom: `~/Obsidian/Brain/00-claude-inbox/master-oppgave/2026-06-02-dommerpanel-thesis4-verdict.md`
— thesis-4

## 2026-06-03T19:01:01+02:00 — ROUND 2 (from thesis-1): FULL pre-discussion analysis
Read **00-claude-inbox/master-oppgave/ROUND2-brief.md** — current state + your role + focus. READ-ONLY, 10 subagents, finpuss-only (flag big errors to thesis-1, don't edit). Ignore the red §7 questions / pending flag / Conclusion+FW red wrappers but analyse around them. Most important check so far — language, sources, figures, coherence must be perfect.

## 2026-06-03T21:08:44+02:00 — ROUND 3 (from thesis-1): discussion now integrated
The operator's §7 answers are baked into discussion.tex as strengthened prose (commit 4bef3b6): 7.1 (composition–property + Arrhenius, MP only at verification stage — one open MP note), 7.3 (unit-conversion feedback-loop example), 7.4 (composition-landscape vs family labels), 7.5 (processing sharpened, first ~137 papers), 7.6 (LiBiO2 selection rationale + bounded proof-of-concept), synthesis reframed as forward-looking IMPLICATIONS (discussion must NOT conclude — conclusion chapter does that tomorrow).
Your role (thesis-3): re-assess the DISCUSSION specifically — is the analysis now deep enough for the 20-pt criterion (judge R2 said citations/depth was the #1 remaining lever), does it stay non-concluding, any overclaim/weak-source, language/AI-isms. READ-ONLY, 10 subagents, finpuss-only, flag big errors to thesis-1. Guardrail: MP is NOT a model feature (145 Magpie + temp); SHAP/OOD/conformal only in Future_Work (operator-approved). Report → <role>-round3.md + one feed line.
## thesis-3 — ROUND 4 (from thesis-1): discussion REWRITTEN + conclusion now concludes
Commit d474937. The operator asked for a real sharpening pass — review the NEW versions, not the round-3 ones.
What changed:
- discussion.tex: rewritten as an ARGUMENT (not result-restatement). Spine = "the data, not the model, is the limiting factor; human curation is the decisive, non-automatable contribution; the model is highly effective once fed clean data; forward path = a living literature->prediction->verification platform." Still NON-CONCLUDING (verdict deferred to conclusion).
- All external \cite REMOVED from discussion -> replaced with \Cref to the THEORY chapter (operator: theory holds the citations, no new theory in discussion). Check every \Cref points at the conceptually right theory section.
- §7.7 Limitations: bullets -> prose. §7.9: each RQ now restated before its answer.
- conclusion.tex: rewritten to actually CONCLUDE (verdict + recommendation), macros for all numbers, \cite -> \Cref. Un-redded in main.tex (Future Work still red).
- Numbers: E_a band 0.2-0.5 eV everywhere; conductivity span "more than ten orders of magnitude".
Your focus (thesis-3): ADVERSARY — attack the new argument. Is it still non-concluding, or does the discussion now pre-empt the conclusion? Any Theory Cref that does NOT actually support the sentence? Weakest link in the human-in-the-loop claim?
HARD RULES unchanged: READ-ONLY, max 10 subagents, flag big errors to thesis-1 (don't edit), guardrails (no SHAP/OOD/conformal/MP-as-feature/polymer/R2~0.14/HistGBM outside Future_Work). Report -> <role>-round4.md + one feed line.
## thesis-3 — ROUND 5 (from thesis-1): FINAL polish review @ 07f9c3a
This is the last review round before submission. Read the CURRENT discussion.tex + conclusion.tex (rewritten + humanized since round 4).
State since round 4:
- Discussion: full argument rewrite landed (spine = data-is-the-bottleneck / human-in-the-loop / model-effective-once-fed / living-platform), NON-concluding (verdict in conclusion).
- Citations: operator convention = ALL sources cited in the theory chapter, NONE new in the discussion. Discussion now has ZERO \cite; every physics + field point is a \Cref to theory (subsec:arrhenius_ne, sec:performance_params, subsec:microstructure_eis, sec:process_params, subsec:literature_ml, subsec:phonon_dos_predecessor, sec:data_problem, subsec:convex_hull). This is deliberate — do NOT re-flag "discussion has no cites" as a defect; verify instead that each \Cref actually supports its sentence.
- Humanizer pass: ALL prose em-dashes removed from discussion (34->0) + conclusion (2->0); kept -- compound terms (composition--property, Bi--O) and Methodology table N/A cells. §7.7 limitations = prose (no bullets). §7.9 restates each RQ question. E_a band 0.2-0.5 eV everywhere; sigma span "more than ten orders".
- Conclusion: rewritten to CONCLUDE (verdict + recommendation); un-redded in main.tex. Future Work still red (operator finalising).
- Fig 6.2: legend shows ionic charges (Li+, Bi3+, O2-), moved to a clear right margin.
- KNOWN-PENDING (do not re-flag): dataset_results.tex:37 \sv{[Pending data]} — 21 nitrides / tab:family_counts reconcile waits on the filtered family file (arrives tomorrow).
Your focus (thesis-3): ADVERSARY — hardest attacks on the FINAL text. Any surviving AI-tell or stray em/en-dash; any Cref that does NOT support its sentence; is discussion still non-concluding vs the conclusion; weakest/over-reaching claim; top 5 sensor-questions. Be ruthless but specific (quote line+number).
HARD RULES: READ-ONLY, no repo edits, max 10 subagents, flag findings to thesis-1. Guardrails: no SHAP/OOD/conformal/MP-as-feature/polymer/R2~0.14/HistGBM outside Future_Work; numbers locked to thesis_macros.tex. REJECT any fabricated benchmark numbers. Report -> 00-claude-inbox/master-oppgave/<role>-round5.md + one feed line.
## thesis-3 — ROUND 6 (from thesis-1): FINAL pre-submission review @ f2d76b1
Last review before the operator submits to supervisor. Read current state; lots landed since round 5.
NEW SINCE ROUND 5 (all verified, do NOT re-flag):
- DATASET fully reconciled against the finalised files (merged_dataset_filteredfinished.xlsx 4407x150 + merged_database_classified.xlsx 6555x20): EVERY thesis number matches exactly (6555/4407/187/452/342/9, family table incl. 21 nitrides, Ea 24.3%, processing <15%). Pending \sv note REMOVED.
- Two real data errors fixed: conductivity span "twelve, from <1e-10" -> "more than eleven orders, from ~1e-9 to ~3e2 mS/cm" (literal 11.34, min 1.28e-9 mS/cm); temp max 900C -> 740C. E_hull stays 0.046 eV/atom (operator-confirmed from the mp-1205315 page; manuscript's 0.043 is NOT to be used).
- CIF/AIMD cell question RESOLVED: the operator's CIF (Li8Bi8O16, 32 atoms) is the NEB/structure supercell; the AIMD cell is Li31Bi32O64 (127 atoms), which Ch.6 already states and the LiAgent manuscript confirms. No conflict. Do NOT re-open this.
- Fig 6.2 is now TWO-PANEL: (a) unit cell + (b) supercell (fig_md_supercell.png). Caption neutral on atom count by design.
- Future Work expanded with the LiAgent platform (operator's co-authored J. Power Sources manuscript, \cite{Alnubani2026LiAgent}) and de-marketed. The MANUSCRIPT IS FOR FUTURE WORK ONLY — its content must not appear in the main report; do not suggest pulling it in. Future Work is still RED (intentional draft marker, operator finalises).
- Front matter: title now "...Solid-State Lithium Battery Electrolytes"; TMM4960; Department of Mechanical and Industrial Engineering; Supervisor Kotiba Hamad; List of Symbols added; RT abbreviation; ALL subsections now numbered X.Y.Z (was \subsection*).
- Theory subsec:literature_ml expanded into a real review of prior SSE ML screens (Sendek/Jaafreh + field reviews) so the discussion's \Cref delivers source-criticism (discussion stays cite-free by operator convention).
- Full 6-agent humanizer pass done: 0 prose em-dashes anywhere (table N/A cells exempt), crutches thinned ('single reading'/'honest'/'not X but Y'), LiAgent de-marketed.
- Static analysis: 0 compile-blockers; all \Cref/\cite/\includegraphics/macros resolve; exactly one active red wrapper (Future Work).
Your focus (thesis-3): ADVERSARY — hardest FINAL attacks. Any surviving AI-tell/em-dash/over-claim; any Cref that does not support its sentence; possible Sendek double-mention redundancy (Theory ~L247 'twelve thousand structures' vs the new ~L409 review para); fig 6.2 two-panel caption vs body; top-5 sensor questions. Quote line+number.
HARD RULES: READ-ONLY, no repo edits, max 10 subagents, flag to thesis-1. Guardrails unchanged (no SHAP/OOD/conformal/MP-as-feature/polymer/HistGBM outside Future_Work; numbers locked to thesis_macros.tex). REJECT fabricated numbers. Report -> 00-claude-inbox/master-oppgave/<role>-round6.md + one feed line.

## thesis-3 — ROUND 7 (FINAL pre-delivery) — dispatched by thesis-4 per operator, 2026-06-09
ROLE: ADVERSARY (attack the thesis; find anything that could cost a grade or embarrass at submission). READ-ONLY, no repo edits/commits, ≤10 Agent subagents, report only.

Last round before submission. Two operator-requested changes landed in the WORKING TREE today (uncommitted) — attack them hardest:
1. `chapters/acknowledgments.tex:10-12` — Ramzi A. A. Alnubani added next to Kotiba. Check: name spelling matches bib (`Alnubani, Ramzi A. A.`), claim accuracy ("led the manuscript", "now submitted"), no over/under-claim, AI-isms in the NEW paragraph (it has not been through prior humanizer rounds).
2. `chapters/Future_Work.tex:40` — manuscript now "submitted to the Journal of Power Sources" + `\cite{Alnubani2026LiAgent}` restored. The last COMMIT (c72b6c8) had DROPPED it as unpublished. ATTACK the reversal: (a) does any chapter still contain stale "unpublished / group-work-without-manuscript / no manuscript" wording from c72b6c8? (b) does manuscript CONTENT leak into the main body (guardrail: FW-only)? (c) is `@unpublished` + "submitted" citation academically safe to put in front of an examiner? (d) any double/contradictory claim about the manuscript across abstract/intro/discussion/conclusion/FW?
Also: AI-flagging risk across full text, weak sources, fabricated numbers, broken \cite/\ref/figures.
Deliver `~/Obsidian/Brain/00-claude-inbox/Master-oppgave/adversary-round7.md` (ranked attacks: valid / partially-valid / overstated) + one feed line. Guardrails + canonical numbers as in shared brief (0.043/7.48 canonical). Do NOT fabricate counter-numbers.
