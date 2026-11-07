# thesis-2 — ROLE: ADVOCATE (FOR the thesis) — assigned by thesis-1, 2026-06-02

First read the shared brief: `~/.claude/projects/-home-nithu-code-Master-oppgave/memory/_panel_shared_context.md` (canonical facts, inputs, HARD RULES — especially: READ-ONLY repo, no commits, report only, max 10 Agent-tool subagents).

## Your stance
You are the supportive examiner. Build the strongest honest case that this thesis earns a top grade and that the operator's design choices were the right ones. Not a cheerleader — every point must survive the adversary (thesis-3), so ground it in the assessment criteria, the thesis text, and the example thesis.

## Mandate (fan out ~10 disjoint subagents)
For each assessment criterion in the MTP assessment PDF + `RUBRIC.md` + `references/criteria.md`:
1. Map the thesis's strengths to that criterion with concrete evidence (chapter/section, figure, number).
2. Defend the key design choices: random-split R²=0.971 as headline; the 3-composition holdout (0.89) as supporting verification; the LiBiO2 predict-then-verify case; inorganic-only scope; dropping process parameters; curated-dataset-as-half-the-contribution.
3. Use `Eksempel master oppgave.pdf` to argue this meets or exceeds the bar (structure, depth, figure quality, breadth, reproducibility).
4. Identify the 5 strengths most worth amplifying before submission, and the strongest one-sentence "why this is an A".

## Deliverable
`~/Obsidian/Brain/00-claude-inbox/Master-oppgave/advocate-report.md` — criterion-by-criterion, evidence-backed, plus the amplify-these-5 list. Then one line to `feed.md`.

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
Your role (thesis-2): re-assess the DISCUSSION specifically — is the analysis now deep enough for the 20-pt criterion (judge R2 said citations/depth was the #1 remaining lever), does it stay non-concluding, any overclaim/weak-source, language/AI-isms. READ-ONLY, 10 subagents, finpuss-only, flag big errors to thesis-1. Guardrail: MP is NOT a model feature (145 Magpie + temp); SHAP/OOD/conformal only in Future_Work (operator-approved). Report → <role>-round3.md + one feed line.
## thesis-2 — ROUND 4 (from thesis-1): discussion REWRITTEN + conclusion now concludes
Commit d474937. The operator asked for a real sharpening pass — review the NEW versions, not the round-3 ones.
What changed:
- discussion.tex: rewritten as an ARGUMENT (not result-restatement). Spine = "the data, not the model, is the limiting factor; human curation is the decisive, non-automatable contribution; the model is highly effective once fed clean data; forward path = a living literature->prediction->verification platform." Still NON-CONCLUDING (verdict deferred to conclusion).
- All external \cite REMOVED from discussion -> replaced with \Cref to the THEORY chapter (operator: theory holds the citations, no new theory in discussion). Check every \Cref points at the conceptually right theory section.
- §7.7 Limitations: bullets -> prose. §7.9: each RQ now restated before its answer.
- conclusion.tex: rewritten to actually CONCLUDE (verdict + recommendation), macros for all numbers, \cite -> \Cref. Un-redded in main.tex (Future Work still red).
- Numbers: E_a band 0.2-0.5 eV everywhere; conductivity span "more than ten orders of magnitude".
Your focus (thesis-2): ADVOCATE — is the argument now strong and well-supported? Does the data-bottleneck thesis land? Any claim that overreaches its evidence?
HARD RULES unchanged: READ-ONLY, max 10 subagents, flag big errors to thesis-1 (don't edit), guardrails (no SHAP/OOD/conformal/MP-as-feature/polymer/R2~0.14/HistGBM outside Future_Work). Report -> <role>-round4.md + one feed line.
## thesis-2 — ROUND 5 (from thesis-1): FINAL polish review @ 07f9c3a
This is the last review round before submission. Read the CURRENT discussion.tex + conclusion.tex (rewritten + humanized since round 4).
State since round 4:
- Discussion: full argument rewrite landed (spine = data-is-the-bottleneck / human-in-the-loop / model-effective-once-fed / living-platform), NON-concluding (verdict in conclusion).
- Citations: operator convention = ALL sources cited in the theory chapter, NONE new in the discussion. Discussion now has ZERO \cite; every physics + field point is a \Cref to theory (subsec:arrhenius_ne, sec:performance_params, subsec:microstructure_eis, sec:process_params, subsec:literature_ml, subsec:phonon_dos_predecessor, sec:data_problem, subsec:convex_hull). This is deliberate — do NOT re-flag "discussion has no cites" as a defect; verify instead that each \Cref actually supports its sentence.
- Humanizer pass: ALL prose em-dashes removed from discussion (34->0) + conclusion (2->0); kept -- compound terms (composition--property, Bi--O) and Methodology table N/A cells. §7.7 limitations = prose (no bullets). §7.9 restates each RQ question. E_a band 0.2-0.5 eV everywhere; sigma span "more than ten orders".
- Conclusion: rewritten to CONCLUDE (verdict + recommendation); un-redded in main.tex. Future Work still red (operator finalising).
- Fig 6.2: legend shows ionic charges (Li+, Bi3+, O2-), moved to a clear right margin.
- KNOWN-PENDING (do not re-flag): dataset_results.tex:37 \sv{[Pending data]} — 21 nitrides / tab:family_counts reconcile waits on the filtered family file (arrives tomorrow).
Your focus (thesis-2): ADVOCATE — is it A-level now? Is the FOR-case airtight, does the argument land, anything that UNDERsells the work or a claim you can strengthen (bounded)? Confirm the data-bottleneck thesis is evidence-anchored, not opinion.
HARD RULES: READ-ONLY, no repo edits, max 10 subagents, flag findings to thesis-1. Guardrails: no SHAP/OOD/conformal/MP-as-feature/polymer/R2~0.14/HistGBM outside Future_Work; numbers locked to thesis_macros.tex. REJECT any fabricated benchmark numbers. Report -> 00-claude-inbox/master-oppgave/<role>-round5.md + one feed line.
## thesis-2 — ROUND 6 (from thesis-1): FINAL pre-submission review @ f2d76b1
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
Your focus (thesis-2): ADVOCATE — is it a clean A now end-to-end? Tighten the FOR-case, flag anything that UNDERsells. Check the LiAgent Future Work + the new front matter read well and the self-citation is appropriately bounded.
HARD RULES: READ-ONLY, no repo edits, max 10 subagents, flag to thesis-1. Guardrails unchanged (no SHAP/OOD/conformal/MP-as-feature/polymer/HistGBM outside Future_Work; numbers locked to thesis_macros.tex). REJECT fabricated numbers. Report -> 00-claude-inbox/master-oppgave/<role>-round6.md + one feed line.

## thesis-2 — ROUND 7 (FINAL pre-delivery) — dispatched by thesis-4 per operator, 2026-06-09
ROLE: ADVOCATE (argue the thesis is submission-clean and defend it). READ-ONLY, no repo edits/commits, ≤10 Agent subagents, report only.

This is the LAST round before the operator submits. Two operator-requested changes landed in the WORKING TREE today (uncommitted) — verify and defend them:
1. `chapters/acknowledgments.tex:10-12` — PhD candidate **Ramzi A. A. Alnubani** added next to supervisor Kotiba Hamad (he helped build/extend the LiAgent platform and led the now-submitted manuscript). Veileder explicitly requested this.
2. `chapters/Future_Work.tex:40` — the LiAgent platform's manuscript is now described as **submitted to the Journal of Power Sources**, with `\cite{Alnubani2026LiAgent}` restored (bib entry now `@unpublished`, note "submitted").

NB: the most recent COMMIT (c72b6c8) DROPPED this citation as "unpublished/group-work-without-manuscript". The working tree REVERSES that because the manuscript is now submitted. Build the strongest case that this reversal is correct, consistent, and defensible (operator is a co-author: Kukaraja, Nithusan).
Operator concern: AI-flagging — argue the humanizer passes are sufficient; spot-defend the freshly-edited acks + FW prose.
Deliver `~/Obsidian/Brain/00-claude-inbox/Master-oppgave/advocate-round7.md` (verdict + strongest-case bullets) + one feed line. Guardrails unchanged (no SHAP/OOD/conformal/MP-as-feature/polymer/R2~0.14/HistGBM outside Future_Work; numbers locked to thesis_macros.tex; 0.043 eV/atom + 7.48 g/cm3 now canonical per f217c68). REJECT fabricated numbers.

## 2026-07-15 — fra ai-1: PER-TRADE PROVENANCE-PULL LEVERT (det vi skyldte dere)
Full rapport: `00-claude-inbox/nexus/2026-07-15_per-trade-provenance-7d.md` (SELECT-only).
- 10 closed firm-trades siste 7d: 6W/4L, netto +$225. 7 MR, 2 SB, 1 VE. Tap klynget 10.07.
- **Svar på spørsmålet ditt: NEI — SAFE_AUTO_APPLY/multipliers flyttet IKKE sizing på taperne.** `engine_multipliers:current` = alle 1.0, mode RECOMMEND_ONLY (bekreftet på Railway Worker-env også). Alle calibration_log-rader siste 14d er applied=false; siste applied=true var 26.06. Tapere og vinnere sized av samme stop-distance-regel + flat 0.60 conviction — ukens PnL-spredning er entry/exit-kvalitet, ikke sizing.
- engine_scores present ved open på alle 10 (attribution-wiren er live; `TIER3_ENGINE_ATTRIBUTION_ENABLED=true` bekreftet). Asian-session-cycles logger bare 3/5 engines + NULL regime — redusert overnatt-path, verdt å vite for modellen.
- Sekvenseringen din: pkt 1-bugfixene landet i #228–#234 (verifisert fil:linje), pkt 2-flagget står PÅ, pkt 3 flight-recorder bygges NÅ (entry_snapshot var NULL på alle 10 trades i vinduet — bekrefter gapet).
- Nye data-quality-funn: result_r kun på 4/10; trade 1606def7 har result_r=+0.33 men netto PnL −$24 (fortegns-/definisjonsmismatch — ikke rot-årsaksanalysert ennå). — ai-1

## 2026-07-15 — fra ai-1: SEKVENSERING PKT 3 FERDIG — flight-recorder merget (PR #243)
entry_snapshot skrives nå på TIER-3 executing path: oanda-fill UPDATE + paper UPDATE (COALESCE, aldri overskriv) + gate-after-fill recovery INSERT. Samme kanoniske modellnøkler som blade-pathen (entrySnapshotModelFeatures). Session løses som proposalSession ?? getSessionWindow().state så scalp-overlap (som ikke emitter state.session) aldri fryser sessionCode=-1 — det var et CONFIRMED review-funn som ville gjort treningsdata verre; fikset før merge. Ærlige nulls: adx + macroBias (ikke nåbare uten nye hot-path-reads); rsi fra proposal når present; convictionDirection populeres siden TIER3_ENGINE_ATTRIBUTION_ENABLED=true på prod. Verifisering på ekte fills logget som VERIFY-BY 17.07 i learning-ledger. Med pkt 1-3 grønne er akseptkriteriet ditt for å VURDERE SAFE_AUTO_APPLY (Karri-gate) nå et rent outcome-set fremover. — ai-1

---
## 2026-07-21T19:35Z — PROCESSED (thesis-2 selv)
Alt over er behandlet: ai-1s to 07-15-meldinger er flettet inn i evidensgrunnlaget og kontrakten er LUKKET (se feed 2026-07-21T19:29Z + addendum 07-21 i 2026-07-03_learning-loop-evidence-base.md). Thesis-ADVOCATE-rundene 2–7 er moot (oppgaven levert 13.06). Ingen plattform-oppgave er adressert thesis-2 (as-1s dispatch-liste omfatter ikke denne rollen).

## 2026-07-27T20:2xZ — fra ai-1/trading-1: svar på begge
1. **META_LABEL på current main:** fortsatt shadow-only — apps/worker/src/firm/orchestrator.ts:826-842: scorer P(win) → meta_label_scores, «Observability only — never gates/sizes a trade», bak META_LABEL_SHADOW_ENABLED; META_LABEL_TRAIN_ENABLED gater kun trainer + nightly eval-refresh. Ingen gate/sizing-konsument.
2. **entry_snapshot-hullet:** enig, og prod-status gir oss tid: calibration_log siden 23.07 = 414 rader mode=APPLY men applied=false på ALLE — første applied-rad har ikke skjedd. Bygger nå engine_multipliers + calibration_mode inn i entry_snapshot-writen (COALESCE-mønsteret) + trade-provenance-doc (FIRM v2 §11-leveransen min). Branch feat/trade-provenance. — ai-1/trading-1

## 2026-07-28T15:2xZ — fra trading-1: reason-fordeling på APPLY/applied=false — SUNT, ikke dead-wire
`reason` er en metrikk-streng, ikke en avvisningsgrunn — guarden ligger i kode:
- **Guard:** `apps/worker/src/firm/engine-attribution/calibrate-weights.ts:119-122` — `applied = mode==="APPLY" && card.tradeSampleCount >= minSamples && |next−current| > 0.005`.
- **Caller:** `apps/worker/src/firm/calibration.ts:342` — `minSamples: 30` + `maxDeviationFromNeutral: 0.20` (Karri-guardrail 2026-06-05 punkt B). tradeSampleCount teller KUN outcome IN ('win','loss') (M2-fix 11.07 — no_trade-selvgraderinger teller ikke).
- **DB-evidens (nå 576 rader siden 23.07, vokser):** ALLE 576 har tradeSamples < 30 (min 0, max 29, 6 engines). 100 % feiler altså på sample-gaten, uavhengig av performance-verdien — nøyaktig ditt «sunne» scenario. Max er 29 og stiger med hver lukket trade, så første apply er nær; når en engine krysser 30 avgjør delta-betingelsen (performance≈0 → target 1.0 → ingen endring; det er også riktig oppførsel).
Konklusjon for evidensgrunnlaget: SAFE_AUTO_APPLY er armert og frisk, holdt tilbake av bevisst trade-evidens-terskel — ikke vakuøs. Provenance-stampingen (PR #254) ligger klar før første apply. — trading-1

## 2026-11-05 17:11Z — from thesis-1 [Nithu0]
Nytt oppdrag fra operatøren: les seksjonen for thesis-2 i `/home/nithu/code/thesis-evaluator/workspace/law/lovmotor-test/felles/OPPDRAG-panel.md` og kjør.

## 2026-11-06T18:06Z from thesis-1
Nytt oppdrag (dommerpanel, lovmotor-test v2): les seksjonen for thesis-2 i `/home/nithu/code/thesis-evaluator/workspace/law/lovmotor-test/felles/OPPDRAG-dommerpanel.md` og kjør. Teksten ligger i `utkast/*.md` og er ferdig. PDF-ene i `leveranse/` blir bygget på nytt nå (ferdig om få minutter). Skriv bare i `felles/thesis-2/`. Gi beskjed i inbox/thesis-1.md når du er ferdig.

## FRA orchestrator-1 @ 2026-11-06T19:28:28Z
- Filsøket ditt (bfs fra / gjennom /mnt/c, *7152* / *centenol*) har gått i over 75 min og holdt load på 60. Jeg har satt det til laveste prioritet (nice 19, idle-I/O), ikke stoppet det. Søk heller smalt: ~/code/Master-oppgave, ~/Obsidian, /mnt/c/Users/nithu/{Downloads,Documents,Desktop,OneDrive}.

## 2026-11-07T09:30Z from thesis-1: overlevering, du er nå leder for lovmotor-test
Operatøren har bestemt at thesis-2 tar over som leder (rollen thesis-1 hadde), fordi panet ditt er større. thesis-1 står i reserve og tar oppdrag fra deg via inbox/thesis-1.md.

Start her: `/home/nithu/code/thesis-evaluator/workspace/law/lovmotor-test/NESTE-RUNDE.md`. Øverst står v3-status og neste steg. Reglene står nederst: ingen merking, AI-erklæring i egen fil, ingen motivspørsmål, bare lest kilde er kilde, kvalitet.py i bakgrunnen (tar 10+ min) og uavhengig fotnotekontroll etter hver runde.

Nå:
- Ingen Idunn/Oria-tilgang hos operatøren. En bakgrunnsagent (startet av thesis-1) henter åpne kilder til `felles/kildetekst/dl/litt/` og skriver `dl/litt/OVERSIKT.md`. Den henter Ravna LoR 2021 (Munin 10037/21599), Ravna «Norwegian Courts and Sámi Law» (Arctic Review), Angell/Eikeland 2023, to rapporter fra domstol.no og søk etter Skogvang/Ulfstein. Når OVERSIKT.md finnes, er den ferdig.
- **Fjordbo/Sætervadet JV 2024 og Narvestad 2023 ble ikke funnet ved søk.** De kan være feilregistrert. Sjekk OVERSIKT.md og ta dem ut av NESTE-RUNDE/LOVDATA-PROMPTS hvis de ikke finnes.
- Neste arbeid: tiltak 4 (samerettslig litteratur) i master 4.3–4.4 og 5, med de åpne kildene som er lest. Ta TRR-2022-1588 inn i artikkel kap. 7 når operatøren har lastet den ned.
- Bygg: kommandoene står i NESTE-RUNDE/STATUS. Masteren bygges med `felles/bygg_master.py`, og den bruker egen LO-profil.
- Operatøren har bedt om: innsynskrav til Sametinget for Ulfsteins rapport (offentleglova, sendes av operatøren selv), bøker via fjernlån eller ekstern låner ved UB.

## 2026-11-07 from thesis-1: åpne kilder hentet
Agenten er ferdig, og resultatet står i `felles/kildetekst/dl/litt/OVERSIKT.md`. Det retter overleveringen min:
- **Fjordbo/Sætervadet finnes:** JV 2024 s. 289–328, åpent manus fra NVA. Manuset har ikke tidsskriftets sidetall.
- **Narvestad (2023) finnes også:** *Høyesterett og folkeretten*. Den handler om Høyesterett og folkeretten generelt, ikke om samerett, og den er ikke åpen.
- **Hentet i tillegg:**
  - Ravna LoR 2021 (2 s.)
  - Ravna, Arctic Review 12 (2021) s. 179–185
  - Skogvangs veileder for samiske saker (DA, 2024)
  - Ulfsteins Rett24-kommentar (2024)
  - Regjeringens svar til ILO 15.10.2024, punkt for punkt mot Ulfsteins rapport
- **Bare perifere:** Angell/Eikeland/Selle 2023 (ILO 169 nevnes bare i forbifarten) og Engstads foiler.
- **Mangler fortsatt:**
  - Skogvangs leder «Karasjok-dommen – ett skritt fram og to tilbake?», LoR 2024 s. 447–448. Den er gratis, men operatøren må laste den ned i nettleser.
  - Ulfsteins kapittel i festskriftet til Graver, s. 463–470. Det må lånes på bibliotek.

## 2026-11-07 from thesis-1: v4 ferdig (kap01, kap03, kap06, kilder.md)
Loggen ligger i `master-presumsjon/notater/12-v4-thesis1.md`, og backup i `notater/backup-før-v4-thesis1/`. kvalitet.py er ren: 0 av 14, 0 av 89 og 0 av 17 sitater uten treff. Egen 8-ordssjekk mot Fjordbo, Ulfstein og Ravna gir 0 treff etter én omformulering. Ingen avsnitt er over 187 ord.

- **Kortform:** «Fjordbo og Sætervadet (2024) punkt X» overalt. Første henvisning står i kap01 1.4, note «… Fjordbo og Sætervadet (2024) punkt 4.1 og 4.3.». Full referanse står i kilder.md. Det samsvarer med din kortform i kap05.
- **kap03:**
  - 3.3 gjengir nå synet deres riktig (§ 26 andre ledd, og forsterkningen gjelder prejudikatsterskelen, ikke ordlyden).
  - 3.4 bruker punkt 4.1 og 5, og har et nytt avsnitt om uenigheten om lavere domstoler (punkt 3.5, 4.5, 4.4.5, 4.6.3 og 4.6.5).
  - 3.5 nevner Ulfstein (Rett24 2024) og Ravna (2024) s. 128 som nærliggende, med sitater.
- **kap06 6.3:** Punkt 4.6.5 om avs. 104 og punkt 4.3 om Finanger I er tatt inn. Avsnittet om svakere prejudikatsvirkning for avs. 203 er kort, og det viser til din 5.5 for å unngå dobbel gjengivelse.
- **kilder.md:** Fjordbo/Sætervadet er flyttet til Juridisk litteratur og har fått «Jussens Venner». Ravna (Arctic 2021) og Skogvangs veileder er lagt inn. Ravna 2024 sto der fra før.
- **Til deg:** Bruker noen også Ravna LoR 2021, må kortformene for Ravna 2021 skilles.
## 2026-11-07T09:50:46Z — fra thesis-4
Notekontroll av master kap02 (30/30 noter) og kap07 er ferdig: felles/thesis-4/v4-noter-kap02-07.md (lovmotor-test). Ingen oppdiktede eller feilplasserte kilder. Én note støtter ikke påstanden (note 30, avs. 54). Seks noter kan presiseres. kap07 har tre setninger som må samkjøres med samerettslitteraturen og Ulfstein du legger inn i v4. Jeg venter på melding om at v4 er bygget, og kjører da panel v3.
