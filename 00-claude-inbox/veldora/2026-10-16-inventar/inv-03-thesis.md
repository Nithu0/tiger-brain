# inv-03-thesis — transferable ML assets for Veldora

Scope inventoried (read code, not READMEs):
`/home/nithu/code/Master-oppgave` (1.2 GB), nested `battery-electrolyte-predictor` (~9.9k LOC Python),
`/home/nithu/code/research-os` (536 MB, ~3k LOC), `/home/nithu/code/thesis-evaluator` (1.6 GB incl. 1.6 GB .venv; ~6.7k LOC).

---

## 1. Pipeline architecture

**battery-electrolyte-predictor** — plain sklearn, no orchestration framework. No DVC, no MLflow, no Hydra. Config is a flat Python module.

| Layer | File | Notes |
|---|---|---|
| Config | `src/config.py` (156 L) | Paths + column names + `RANDOM_SEED=42`, `TEST_SIZE_PAPERS=0.20`, `N_CV_FOLDS=5` as module constants. Readable, but domain column names hardcoded — a Veldora port keeps the *shape*, not the content. |
| Load | `src/data_loading.py` (333 L) | 4 loaders + `_validate_schema()` fail-fast on missing columns. |
| Clean | `src/preprocessing.py` (305 L), `src/curation/*` (5 files) | Canonicalisation to closed vocabularies (`ATMOSPHERE_CATEGORIES` etc.), audit scripts that *report* rather than silently drop. |
| Features | `src/feature_engineering.py`, `src/featurization/{magpie,mp_lookup,formula_cleaner,clean_pipeline}.py` | Domain-specific (Magpie descriptors, Materials Project API with on-disk JSON cache). The **cache + graceful-degradation** pattern is reusable; the descriptors are not. |
| Split | `src/splitting.py` (231 L) | **The crown jewel.** See §2. |
| Model | `src/models.py` (299 L) | 4 sklearn Pipelines (Ridge / RF / HistGBM / KNN), each `SimpleImputer` + optional `StandardScaler` *inside* the Pipeline, so scalers are fit per-fold. Grouped CV comparison → `select_best()` by mean RMSE. |
| Uncertainty | `src/uncertainty.py` (212 L) | Split conformal + kNN-distance OOD detector. See §2. |
| Explain | `src/explainability.py` (267 L) | permutation importance, SHAP TreeExplainer (global bar/beeswarm + local waterfall), PDP/ICE, nearest-training-examples, human-readable OOD warning. |
| Train | `src/train_clean_v2.py` (153 L), `src/train_xgboost.py` (263 L) | Append a JSON line per run to `models/history.jsonl` (model, n_features, n_train/test rows **and papers**, rmse/mae/r2, timestamp). Poor-man's MLflow; genuinely useful. |
| Serve | `src/predict_clean.py`, `app/` (Streamlit, 3074 L, 6 pages) | Loads pickled artifacts; surfaces prediction + conformal interval + OOD flag + SHAP top-12 + 5 nearest training rows. |
| Repro | `requirements.txt` (hard `==` pins) + `requirements.lock` (41 pins) + `.python-version` + `.github/workflows/ci.yml` (py 3.10/3.11/3.12 matrix, builds artifacts then runs pytest) | Reproducibility is real at the dependency level. |

Deploy: Railway (`nixpacks.toml`, `Procfile`, `railway.json`). `run_pipeline.py` is a deliberate NO-OP in CI/deploy — models are committed as `.pkl` — with an honest docstring explaining why (build timeout / OOM / silent artifact corruption). That is a defensible pattern for Veldora too.

**Reusable as a skeleton:** yes, the `config → load → validate → clean → split → grouped-CV model bake-off → calibrate → artifact + history.jsonl → thin serving layer` spine. It is ~1500 LOC of generic plumbing wrapped around ~1500 LOC of chemistry. Rewriting the spine for Veldora is maybe a day; copying the *decisions* is the value.

---

## 2. Methodology worth porting

### a) Group-aware splitting — `src/splitting.py` (PORT, highest value)
Three functions, all enforcing that a *group* never straddles a split:
- `grouped_train_test_split()` — `GroupShuffleSplit` by DOI, **raises `RuntimeError` on any group overlap** (`_report_split`).
- `grouped_fit_calibration_split()` — splits the training fold into fit/calibration *also grouped*, with its own leakage assert. Without this the conformal coverage guarantee is fake.
- `grouped_kfold()` — `GroupKFold` generator.

Veldora mapping: group = *contracting authority* (oppdragsgiver), and probably also *tender family* (same framework agreement re-tendered, same CPV + same buyer). Bids from one buyer share scoring conventions exactly the way papers share measurement conventions.

### b) The leakage case study — PORT the lesson, not the code
Same problem, same data, two splits, documented side-by-side in the header of `src/train_xgboost.py` and reproduced in `models/history.jsonl`:

| Split | n | Model | Test R² |
|---|---|---|---|
| Random 80/20 (seed 42), `ml_training.py` | 4407 rows / 342 compounds | XGBoost | **0.971** |
| DOI-grouped 80/20, `train_clean_v2.py` | 1496 rows / 120 papers | RandomForest | **0.144** |

Cause: measurement temperature is a feature, so the *same* compound measured at several temperatures lands on both sides of a random split → interpolation, not generalisation. A 0.83 R² gap from split choice alone. For Veldora: a random split over tender notices with buyer/CPV features will produce exactly this illusion. Keep this table as the internal argument for why grouped evaluation is non-negotiable.

### c) Uncertainty / calibration — `src/uncertainty.py` (PORT, adapt to classification)
- `ConformalInterval` — split conformal with the finite-sample corrected quantile `ceil((n+1)(1-α))/n`. Correct implementation, ~40 lines.
- `models/coverage_clean_v2_B.csv` — an actual empirical-vs-nominal coverage table:

```
nominal, q_hat,  empirical
0.5,     0.742,  0.533
0.7,     1.169,  0.725
0.8,     1.480,  0.828
0.9,     2.105,  0.946
0.95,    2.712,  0.994
```

Coverage holds (slightly conservative at the top). Note honestly: q_hat = 2.1 log-units at 90 % means intervals spanning ~125× in σ — *calibrated and nearly useless*. That is the right lesson for Veldora's "73 % win probability": calibration is necessary, not sufficient; also report sharpness.
For binary bid/no-bid the port is **Venn-Abers or Mondrian/class-conditional conformal**, plus isotonic / Platt calibration on a grouped calibration fold, plus Brier score + reliability diagram + ECE. None of that exists here yet; only the regression analogue and the discipline do.
- `OODDetector` — mean distance to k=5 nearest training rows in imputed+standardised space, threshold at the 95th training percentile. Crude (the docstring admits diagonal-covariance approximation) but the *idea* — refuse to score a tender unlike anything you have bid on — is exactly what Veldora needs, and it is 60 lines.

### d) Small-n handling (ADAPT)
What is actually done: tree ensembles chosen explicitly because 342 compounds is below the deep-learning regime (`Theoretical_Background.tex:sec:groupedcv`, citing Grinsztajn 2022 + Shwartz-Ziv 2022 — both already in `references.bib`). Median imputation inside the Pipeline. `min_samples_leaf=3..10` regularisation. Log-transform of a heavy-tailed target.
What is **absent**: no class imbalance handling at all (pure regression), no SMOTE/class weights, no active learning, no Bayesian optimisation, no learning-to-rank. Veldora's imbalance + expensive-label problems get *no* ready code from here.

### e) Hyperparameter search — SKIP, and a rigor flag
`grep -rniE "GridSearchCV|RandomizedSearchCV|optuna|hyperopt|skopt"` across all three repos returns **zero hits**. Hyperparameters are hardcoded literals in `ml_training.py` / `src/models.py`. But `chapters/Methodology.tex:255` states "Hyperparameter tuning and ... cross-validation on the training set". That sentence is not backed by code on disk. Worth telling the operator before an examiner finds it; irrelevant to Veldora except as a reminder that claims need code behind them.

### f) Interpretability — `src/explainability.py` + `app/lib/{explain,feature_humanizer}.py` (PORT the pattern)
SHAP waterfall per prediction, surfaced in the UI alongside a plain-language feature renaming layer (`feature_humanizer.py`, 82 L) and the 5 nearest training examples. For Veldora this is the whole trust story: "we scored this tender 73 % because *these* requirement features, and here are the 5 most similar past tenders and whether we won them." The nearest-neighbour panel is cheap and more convincing to a non-ML operator than SHAP.

---

## 3. Evaluation rigor

**Predictor.** Metrics: RMSE / MAE / R² on `log10(σ)` plus back-transformed RMSE/MAE in physical units (`models.evaluate()`). CV reported as mean ± std across folds (`compare_cv` prints `RMSE=… ± …`). Every run appended to `models/history.jsonl` including train/test *paper* counts. Test set touched once per `_train_one()`.

Weaknesses, stated plainly:
- **No naive/mean baseline** anywhere in `models.py`. R²=0.144 is *relative to* the mean baseline, so it is implicitly there, but there is no DummyRegressor line in any table.
- **No nested CV.** `select_best()` picks the model on grouped CV, then the same train set fits the final model and the held-out test is scored once. Mild selection optimism; acceptable, undocumented.
- `OODDetector.fit(X_tr)` is called on the full training fold including the calibration rows — harmless for the detector, sloppy for purity.
- Only one seed. No multi-seed variance on the headline numbers.
- `thesis_metrics.json` `_meta.note` explicitly *supersedes* the grouped R²=0.144 result with the random-split 0.971 as "the finalised pipeline". The grouped number survives in `history.jsonl` and in the `train_xgboost.py` header, but the thesis headline is the weaker evaluation. Honest in the discussion (`ml_results.tex:122-132` reads the 0.97 against its evaluation design), still the softer choice.

**Leakage guards that exist as code, not prose:**
- `splitting._report_split()` → raises on DOI overlap train/test.
- `splitting.grouped_fit_calibration_split()` → raises on DOI overlap fit/calibration.
- `tests/test_integration.py::test_year_not_in_features` → asserts publication year never enters the feature matrix (a temporal-leakage guard). Veldora needs the direct analogue: assert award date / outcome-derived fields never enter features.
- 606 LOC of pytest across 5 files, run on 3 Python versions in CI.

**Reproducibility tooling worth stealing:** `scripts/sync_metrics.py` makes `results/thesis_metrics.json` the single source of truth and regenerates `thesis_macros.tex` from it, with a `--check` mode for CI. No number in the prose can drift from the number the pipeline produced. Veldora equivalent: one metrics JSON → every dashboard/report number. `scripts/pre_submission_check.sh` is a 10-gate pass/fail ship checklist that modifies nothing.

**thesis-evaluator — what it evaluates and how.** Not a git repo (no `.git`), not under version control. `ARCHITECTURE.md` marks verify/grade/report as "planned", but the code contradicts it: `src/teval/verify/claims.py` (439 L) and `src/teval/grade/panel.py` (378 L) are implemented, and `workspace/` holds completed runs (`law/mahan-sfdr-auto`, `engineering/teval-smoke`) with `grade.json`, `RESULT.md`, generated DOCX/PDF deliverables and a reader bundle. `.validate.log` shows a real end-to-end run: 343 language edits across 5 chunks, grade band C (72.0/103.0), 12 prioritised improvements. **The README is stale; the system works.**

Pipeline: `ingest/` (PDF via PyMuPDF font-size+bbox heuristics / DOCX via styles / LaTeX via TeXSoup → one pydantic `Document` with `Section`/`Paragraph`/`CitationMarker`/`Reference` + PDF-user-space `BBox`) → `classify/` (keyword scoring against `profiles/*/profile.yaml`, 8 disciplines, LLM fallback below 0.45 confidence) → `extract/` ([P###]-tagged body) → `fetch/` (Unpaywall→OpenAlex→Crossref) → `verify/` → `grade/` → `report/`.

Two methods here are directly Veldora-shaped:
1. **Local-first retrieval, LLM only as adjudicator** (`verify/claims.py`): pdfplumber page text + word bboxes → 3-line sliding windows → MiniLM embedding top-5 → optional local cross-encoder rerank (never downloads at verify time) → rapidfuzz paraphrase score → *then* one short candidate passage to Claude for a verdict in `{supported, partial, wrong_paper, unsupported, no_evidence}`. Missing PDF degrades to `no_evidence` instead of letting the model hallucinate. Every verdict carries a quote + page + bbox, so it is auditable and highlightable.
2. **Adversarial FOR/AGAINST/JUDGE panel** (`grade/panel.py`): two advocates on the cheap model anchor every point to a [P###] paragraph; a separate judge on the strong model reads only the two briefs and emits a structured `GradeReport`; 2 passes with section order swapped as a position-bias guard; FOR/AGAINST divergence reported as an inter-rater confidence signal. Explicitly built because a single LLM call talks itself into a generous score.
`llm/client.py` (101 L) is a clean Anthropic wrapper: `complete()` + `structured()` (forced tool call against a JSON Schema), prompt-caching of the big shared context, exponential backoff on 429/5xx/overloaded, and a quirk-handler that drops `temperature` when a model rejects it.

---

## 4. Research corpus

| Location | PDFs | Size |
|---|---|---|
| `research-os/data/raw/pdfs/` | 162 | 342 MB |
| `Master-oppgave/` (incl. `references/`) | 13 | — |
| `thesis-evaluator/` (sample theses + sources) | 9 | — |
| `references.bib` | 58 entries | 28 KB |

**~95 % is battery chemistry** (LLZO, argyrodite, NASICON, sintering, Solid State Ionics / J. Power Sources / Ceramics International). The *general* ML material is a short, high-quality list — not a deep-learning library:

- `10.1007_978-0-387-84858-7.pdf` — Hastie, *The Elements of Statistical Learning* (full book)
- `10.1007_b106715.pdf` — Vovk et al., *Algorithmic Learning in a Random World* (31 MB; the conformal-prediction book)
- Angelopoulos & Bates, *Conformal Prediction: A Gentle Introduction* (2023) — `10.1561/2200000101`
- `10.48550_arxiv.1705.07874.pdf` — Lundberg & Lee, SHAP
- `10.1023_a:1010933404324.pdf` — Breiman, Random Forests
- `10.48550_arxiv.1201.0490.pdf` — scikit-learn
- bib-only (no PDF): Grinsztajn 2022 *Why Do Tree-Based Models Still Outperform Deep Learning on Typical Tabular Data?*, Shwartz-Ziv 2022 *Tabular Data: Deep Learning is Not All You Need*, Chen 2016 XGBoost, Ke 2017 LightGBM
- one GNN item, chemistry-coupled: *Improved Uncertainty Estimation of Graph Neural Network Potentials Using Engineered Latent Space Distances*

**No transformers, no NLP, no learning-to-rank, no Bayesian deep learning, no active learning, no representation-learning literature.** The "deep ML material" is in practice ~6 artifacts covering tabular ensembles, conformal prediction, and SHAP. That is a good reading list for Veldora's *tabular + calibration* half and nothing at all for its *document understanding* and *ranking* halves.

---

## 5. research-os

What it is: typer CLI (`research-os` / `ros`) over SQLite. Modules: `discovery/` (OpenAlex, Crossref, Semantic Scholar, Unpaywall, Elsevier + `merge.py` dedup by DOI/normalised title), `ingestion/` (download + pypdf section parser), `extraction/battery.py` (regex only), `zotero/` (pyzotero), `export/` (BibTeX / CSV matrix / Markdown), `verification/llm_verify.py` (Claude claim-vs-evidence verdicts with prompt caching), `storage/`. 10 pytest files. Not an experiment tracker — there is no model, no training, no MLflow.

**Liveness:** last code commit `3006ade` **2026-06-03**, 7 commits total. `src/` mtimes all ≤ 2026-06-03. The DB file mtime is today (2026-10-16) — that is a Litestream replica lock (`_litestream_lock`, `_litestream_seq` tables + `data/.research_os.db-litestream/`), not usage.

**Usage reality from the DB:** `papers=39`, `pdfs=14`, `sections=0`, `extracted_facts=0`, `audit_claims=152`, `search_log=1`. So discovery/Zotero/claim-audit were used; **the ingest→section→extract path was never run to completion** (0 rows in both tables) despite 162 PDFs on disk fetched by the side scripts. The README's "basic PDF section parser, regex-based extraction" is aspirational.

**Verdict: Veldora should NOT adopt research-os.** It is an academic-literature tool (DOI/Crossref/Zotero as first-class concepts); none of those exist in a tender pipeline. Its *discovery → dedupe → store → export* shape is a reasonable mental model for a Doffin/TED notice ingest, and `discovery/merge.py` + the tenacity retry pattern are worth 30 minutes of reading, but there is nothing to lift wholesale. thesis-evaluator already supersedes it on the document side.

---

## 6. Verdict per asset

| Asset | Path | Call | Why |
|---|---|---|---|
| Grouped split + leakage asserts | `battery-electrolyte-predictor/src/splitting.py` | **PORT** | 231 L, self-contained, swap DOI→buyer/tender-family. The single highest-value file in all three repos. |
| Leakage case study (0.971 vs 0.144) | `src/train_xgboost.py` header, `models/history.jsonl` | **PORT (as doctrine)** | Concrete internal evidence for why grouped eval is mandatory; costs nothing to carry. |
| Split conformal + coverage table | `src/uncertainty.py`, `models/coverage_clean_v2_B.csv` | **ADAPT** | Correct regression conformal; bid/no-bid needs Venn-Abers/Mondrian + isotonic + Brier/ECE. Port the *discipline* and the empirical-coverage table habit. |
| OOD detector | `src/uncertainty.py::OODDetector` | **ADAPT** | ~60 L, crude kNN-distance. "Don't score a tender unlike anything we've bid on" is a real Veldora requirement. Replace the metric. |
| SHAP + nearest-neighbours + humanized features | `src/explainability.py`, `app/lib/{explain,feature_humanizer}.py` | **PORT** | The trust surface. Nearest-past-tenders is more persuasive to the operator than SHAP bars. |
| `history.jsonl` run log | `src/train_clean_v2.py::_append_history` | **PORT** | 8-line poor-man's MLflow, keeps group counts. Enough until Veldora has >50 runs. |
| `sync_metrics.py` single-source-of-truth numbers | `Master-oppgave/scripts/sync_metrics.py` | **PORT (pattern)** | One metrics JSON → all reported numbers, with `--check` in CI. Stops dashboard/deck drift. |
| Pipeline spine (config→load→validate→clean→split→bake-off→serve) | `battery-electrolyte-predictor/src/` | **ADAPT** | Shape is sound; ~half the LOC is chemistry. Rewrite, don't fork. |
| Pinned reqs + lock + CI matrix + pytest leakage guards | `requirements.lock`, `.github/workflows/ci.yml`, `tests/` | **PORT (pattern)** | Especially `test_year_not_in_features` → Veldora's "no post-award field in X". |
| thesis-evaluator document ingest → pydantic `Document` + bboxes | `thesis-evaluator/src/teval/{schema,ingest}/` | **PORT** | Norwegian PDFs → structured sections/paragraphs with highlightable coordinates is *exactly* Veldora's requirement-extraction front end. ~470 L. |
| Local-retrieval-then-LLM-adjudicate | `thesis-evaluator/src/teval/verify/claims.py` | **PORT** | Cheap, auditable, hallucination-resistant extraction with evidence anchors. Best-fit asset for "extract structured requirements from Norwegian tender PDFs". |
| FOR/AGAINST/JUDGE panel + position swap | `thesis-evaluator/src/teval/grade/panel.py` | **ADAPT** | Debiased LLM scoring with a divergence confidence signal → bid/no-bid *qualitative* scoring where labels are too scarce for a classifier. |
| `LLMClient` (structured tool-call + prompt cache + backoff) | `thesis-evaluator/src/teval/llm/client.py` | **PORT** | 101 L, no framework dependency, works today. |
| Rubric/profile YAML system | `thesis-evaluator/profiles/`, `grade/rubric.py` | **ADAPT** | Per-discipline criteria ≈ per-buyer / per-CPV evaluation criteria (pris/kvalitet weightings). The parse-markdown-or-ask-LLM dual path is a good trick. |
| research-os discovery/dedupe/export | `research-os/src/research_os/` | **SKIP** | Stale since 2026-06-03, half-unused (0 sections, 0 facts), DOI/Zotero-centric. Read `discovery/merge.py` and move on. |
| research-os regex extraction | `extraction/battery.py` | **SKIP** | Chemistry regexes, never produced a row. |
| Battery feature engineering (Magpie, MP lookup, formula parser) | `src/featurization/`, `src/feature_engineering.py` | **SKIP** | Pure chemistry. Keep only the *API-cache + degrade-gracefully* idiom from `mp_lookup.py`. |
| Streamlit app | `battery-electrolyte-predictor/app/` (3074 L) | **SKIP** | Veldora will not be Streamlit. The information architecture — prediction + interval + OOD flag + SHAP + neighbours on one card — is worth copying as a wireframe. |
| Research PDF corpus | 184 PDFs | **SKIP** (keep ~6) | ESL, Vovk, Angelopoulos, SHAP, Breiman, sklearn + 4 bib-only tabular-DL papers. The rest is chemistry. |

### What Veldora gets nothing for, from any of this
- Class imbalance / few positives — **zero** code or literature.
- Learning-to-rank — **zero**. No pairwise/listwise loss, no NDCG/MAP anywhere.
- Active learning for expensive labels — **zero**, despite "expensive labels" being the shared pain.
- Classification calibration (Platt/isotonic/Venn-Abers, Brier, ECE, reliability diagrams) — **zero**; all calibration work here is regression conformal.
- Norwegian-language NLP — thesis-evaluator handles Norwegian *text* (the mahan-sfdr law thesis ran in Norwegian, prompts are bilingual) but via Claude, not via any Norwegian model or tokenizer.

### Honest overall read
This is careful, examiner-facing materials-science code at the scale of ~1.5k modelling rows and ~120 groups. It is **not** a production ranking system and should not be sold as one: single seed, no hyperparameter search, no nested CV, no baseline row in any table, models shipped as committed pickles, and a headline thesis number that comes from the weaker of its two evaluations. What transfers is **judgement, not throughput**: how to split so you don't fool yourself, how to prove your intervals cover, how to make a prediction explainable to a non-ML operator, and how to make an LLM extract from a PDF without hallucinating. thesis-evaluator is the more surprising find — a working, undocumented-as-working LLM document pipeline that is closer to Veldora's actual first problem than the ML pipeline is.
