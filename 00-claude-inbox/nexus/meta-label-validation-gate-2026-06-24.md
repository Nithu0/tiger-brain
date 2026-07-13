# Go-live validation gate for the meta-label model — research brief for ai-1 + Karri proposal

_thesis-2 (acting researcher), 2026-06-24. Deep-research: 22 sources, 101 claims → 24 confirmed / 1 refuted (3-vote adversarial), 13 synthesized. Domain-guard: AFML is the operator-curated canon for this (`_library/trading/sources/2026-06-01_xauusd-systematic-sourcing.md`). Advisory only — flips are Karri's. Slots into `docs/strategy/proposals/2026-06-23_go-live-trade-altering-activation.md` as the "validation gate" section._

## Reconciled against your actual code first (so you don't rebuild what's done)
Your `apps/worker/src/firm/meta-label/` already implements the AFML **data + CV backbone** correctly — credit where due:
- **Triple-barrier labeler** (`triple-barrier.ts`, cites AFML ch.3) ✓
- **Purged + embargoed K-fold CV** (`eval-cli.ts`/`eval-refresh.ts`, `--k 5 --embargo 0.02`, `evaluateMetaLabel`) ✓
- **Calibration eval** — Brier skill, ECE, log-loss, reliability; nightly `eval-refresh`; **shadow-only** `scorer.ts` (no live influence) ✓

So `meta_label_models=0` is a **scheduling/data-starvation** gap (trainer not wired to a scheduler), **not** a methodology gap. The genuine go-live-gate gaps are narrower:

| # | Gap (confirmed absent in code) | Why it blocks go-live |
|---|---|---|
| **G1** | **Economic acceptance metric.** Current verdict = Brier/ECE (calibration quality). | A well-calibrated P(win) ≠ a profitable gate. The proposal's "deflated-Sharpe/PF on purged-CV" **does not exist in code yet**. |
| **G2** | **Deflated Sharpe + PBO + MinTRL + CPCV.** Only single purged-k-fold; no combinatorial paths, no multiple-testing correction. | Many engines/thresholds were trialed → naive Sharpe is selection-biased upward. |
| **G3** | **Sample-uniqueness/concurrency weighting** (AFML ch.4) — `grep` shows none in `train-model.ts`. | Overlapping triple-barrier labels fit unweighted → model over-counts concurrent outcomes (non-IID leakage). |
| **G4** | **Clean-baseline / off-policy protocol** for the feedback loop. | The model would be validated on trades it caused — circular. |

---

## Acceptance-threshold table (put this in the Karri proposal)

| Metric | Method | Pass bar | Source |
|---|---|---|---|
| **Purge + embargo** | Purged K-fold; embargo = max triple-barrier holding horizon | leakage-free folds (mandatory) | AFML Ch.7 §7.4.1–7.4.2 (ISBN 9781119482086) |
| **Backtest paths** | **CPCV** (combinatorial purged CV) not walk-forward | distribution of OOS Sharpes, not one number | AFML Ch.12 §12.4–12.5 |
| **Deflated Sharpe (DSR)** | DSR vs SR₀ = E[max Sharpe] over **effective** N trials | **DSR > 0.95** | Bailey & López de Prado 2014, SSRN 2460551 / davidhbailey.com/dhbpapers/deflated-sharpe.pdf |
| **PBO** | CSCV (best-IS ranks below median OOS) | **PBO < 0.5** (stricter advisable at this N) | Bailey/Borwein/LdP/Zhu 2017, SSRN 2326253, *J. Computational Finance* 20(4) |
| **Sample adequacy** | **MinTRL** | report it; **expect ~86 labels to FAIL** → sample-adequacy red flag | SSRN 1821643 (MinTRL origin) + 2460551 |
| **Sample weights** | avg-uniqueness + return-attribution + time-decay; sequential bootstrap for bagging | applied before any fit | AFML Ch.4 §4.4–4.7 |
| **Online monitor** | anytime-valid **e-process** on PIT (not repeated fixed-sample tests) | rollback when e-process ≥ 1/α | Johari "Always Valid Inference" arXiv:1512.04922; Balsubramani-Ramdas UAI 2016 arXiv:1506.03486 |

**Two math traps the reviewer must catch:**
1. **N = EFFECTIVE independent trials**, not raw variant count. Cluster correlated engine/threshold variants (ONC/hierarchical) before counting — overstating N over-deflates, understating it inflates the pass rate. Karri must *see* the clustering.
2. The worked DSR example: an annualized **Sharpe of 2.5 over 5y daily data FAILS** the 95% gate at N≈100 trials (DSR≈0.90), would pass at N≈46. With your many engines/thresholds, this is the **binding constraint** — not the model's raw skill.

---

## Ordered validation protocol (shadow → trade-altering)

1. **Wire the trainer to a scheduler** (your G-fix; shadow, none-risk) → produce ≥1 model so the eval has something to grade.
2. **Add the economic eval (G1+G2):** convert P(win) decisions into a returns series **inside CPCV folds**, compute Sharpe per path → **DSR** (with disclosed effective-N + SR dispersion across ALL trialed variants) + **PBO via CSCV** + **MinTRL**. This is the new acceptance layer next to the existing Brier/ECE.
3. **Add sample-uniqueness weighting (G3)** to `train-model.ts` before refitting (AFML Ch.4).
4. **Keep a model-independent shadow/baseline stream (G4):** evaluate forward, model OFF on a control slice, so the gate is judged on trades the model did **not** cause. Off-policy evaluation (OPE) on logged trades gives **bounds, not a clean point estimate**, and only asymptotically — so it *supports but cannot replace* forward shadow eval (Kallus & Zhou NeurIPS 2020 arXiv:2002.04518; Zhan et al. KDD 2021 arXiv:2106.02029).
5. **Only flip when the statistical gate genuinely clears.** At ~86 labels with many trials, expect it **not** to — the honest posture is **shadow-only until N grows**. A single naive train/test pass is explicitly insufficient (PBO paper). External power precedent: 34 folds / d=0.17 → ~12% power, ~540 test periods needed for 80% (arXiv:2512.12924 — illustrative, not your system).
6. **Online apply (SAFE_AUTO_APPLY, 0.70–1.20 multipliers):** bound + monitor with an anytime-valid e-process on PIT calibration; auto-rollback on breach. Any repeated fixed-sample test on an unbounded stream eventually false-alarms (Law of Iterated Logarithm).

## The feedback loop, named (for the proposal's "strategisk vurdering")
When the model's outputs alter the trades it's later judged on, that's a **performative-prediction** confound (Perdomo et al., ICML 2020, arXiv:2002.06673 — cite for *problem-framing only*). Directional defense (not a literal numeric guarantee — the bound assumes a fixed covariate marginal intraday XAU violates): keep a **large clean/exogenous evaluation fraction** and **bound per-step miscalibration** (Taori & Hashimoto, ICML 2023, arXiv:2209.03942).

## ⚠️ Do NOT cite (refuted 1-2)
The stronger performative-prediction claim that *"calibration against past/shadow outcomes is the wrong target"* — **refuted**. Shadow/baseline evaluation remains valid and is in fact the recommended clean baseline. Don't let it be used to argue *against* shadow eval.

## Open questions ai-1/Karri must answer (gate can't be finalized without these)
1. **Effective N** (independent trials after clustering) — determines if DSR>0.95 is even achievable.
2. **Embargo length** = your actual max triple-barrier holding horizon (set it from realized label-overlap span; `META_LABEL_HORIZON_H` default 24h is the starting point).
3. Commit the **numeric thresholds** (DSR>0.95, PBO<0.5, a MinTRL the 86 labels fail) + the **graduation rule** (N growth + sustained shadow outperformance) that flips shadow→live.
4. **Does the auto-tuner re-ingest model-influenced outcomes** into training/calibration? If yes, the feedback bound bites — quantify the clean shadow fraction and hold it above a floor.

_Full verified-claim JSON + all 22 sources: `tasks/w3h48yqqc.output`. Source strength: AFML + DSR/PSR/PBO papers are primary/authoritative; feedback-loop/OPE papers apply by analogy (diagnose, don't prescribe a trading gate); PITMonitor is 2026 single-author — rely on it for the monitor, cite LIL/always-valid for the load-bearing theory._
